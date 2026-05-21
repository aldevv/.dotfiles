#!/usr/bin/env bash
# PostToolUse hook for `gh pr create *`, `glab mr create *`, and `git push [*]`.
# After a push, polls the PR's automated review comments. When a review is
# posted for the current HEAD with actionable findings (Blocking Issues > 0
# OR Suggestions > 0), it:
#   - sends a purple notify-send so the operator sees a PR-review touch
#   - opens a new tmux window with monitor-bell enabled
#   - launches a Claude session whose prompt instructs it to:
#       clear-cut -> fix + push
#       ambiguous -> fix but do NOT push, ring the tmux bell, wait for input
#
# REQUIRED settings.json wiring (PostToolUse, Bash matcher). Keep these 3
# entries and only these 3. Do NOT add `gh pr view *`, `gh pr checks *`,
# `gh pr edit *`, or any read-only command. That re-introduces the misfire
# where the hook latches onto a PR you were just inspecting.
#   - if: "Bash(gh pr create *)"     timeout: 3600  async: true
#   - if: "Bash(git push *)"         timeout: 3600  async: true
#   - if: "Bash(glab mr create *)"   timeout: 3600  async: true
#
# Runs in parallel with gh-pr-post-watch-checks.sh; uses a distinct lock key.
# Both GitHub PRs and GitLab MRs are supported; reviews are matched by the
# `last_reviewed_sha` HTML-comment marker in the body, not by author.
#
# AUTHOR GUARD. Prevents the "reviewing a friend's PR and the hook almost
# fixed CI for them" misfire. After URL resolution, the hook verifies the
# PR author equals the current `gh` / `glab` user; if not, it exits silently.
# Fail-closed: if either side cannot be resolved, the hook also exits. There
# is intentionally no env-var bypass. Spawn a fresh claude session manually
# if you really need to auto-fix someone else's PR.
#
# Disable per-invocation:
#   - PR_COMMENT_WATCH_AUTOFIX=0  -> still poll + notify, do not spawn fixer.
#
# Logs to ~/.claude/hooks/logs/pr-comments-<timestamp>.log.

set -u

LOG_DIR="$HOME/.claude/hooks/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/pr-comments-$(date +%Y%m%d-%H%M%S)-$$.log"
exec >>"$LOG" 2>&1

echo "=== gh-pr-post-watch-comments.sh started at $(date -Iseconds) ==="
echo "PWD: $(pwd)"

INPUT=$(cat)

REPO_DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // ""')
if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR" ]; then
  REPO_DIR=$(pwd)
fi
echo "REPO_DIR: $REPO_DIR"

STDOUT_TEXT=$(printf '%s' "$INPUT" | jq -r '.tool_response.stdout // ""')

URL=$(printf '%s' "$STDOUT_TEXT" \
  | grep -Eo 'https://[^ ]+/(pull|merge_requests)/[0-9]+' \
  | head -n1)

if [ -z "$URL" ]; then
  if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    if [ -n "$BRANCH" ] && [ "$BRANCH" != "HEAD" ]; then
      ORIGIN_URL=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
      case "$ORIGIN_URL" in
        *github.com*|*conductorone*)
          command -v gh >/dev/null 2>&1 && \
            URL=$(cd "$REPO_DIR" && gh pr list --head "$BRANCH" --state open --json url --jq '.[0].url // ""' 2>/dev/null || true)
          ;;
        *gitlab*)
          command -v glab >/dev/null 2>&1 && \
            URL=$(cd "$REPO_DIR" && glab mr list --source-branch "$BRANCH" --opened --output json 2>/dev/null \
                    | jq -r '.[0].web_url // ""' 2>/dev/null || true)
          ;;
        *)
          command -v gh >/dev/null 2>&1 && \
            URL=$(cd "$REPO_DIR" && gh pr list --head "$BRANCH" --state open --json url --jq '.[0].url // ""' 2>/dev/null || true)
          ;;
      esac
    fi
  fi
fi

if [ -z "$URL" ]; then
  echo "no PR/MR URL resolved — exiting"
  exit 0
fi
echo "URL: $URL"

case "$URL" in
  *github.com*/pull/*) PLATFORM=github ;;
  */-/merge_requests/*|*/merge_requests/*) PLATFORM=gitlab ;;
  *) echo "unknown platform for URL — exiting"; exit 0 ;;
esac
echo "PLATFORM: $PLATFORM"

case "$PLATFORM" in
  github)
    if ! command -v gh >/dev/null 2>&1; then
      echo "gh not on PATH — exiting"; exit 0
    fi
    ;;
  gitlab)
    if ! command -v glab >/dev/null 2>&1; then
      echo "glab not on PATH — exiting"; exit 0
    fi
    HOST=$(printf '%s' "$URL" | sed -E 's|^https?://([^/]+)/.*$|\1|')
    PROJ_PATH=$(printf '%s' "$URL" | sed -E 's|^https?://[^/]+/(.+)/-/merge_requests/[0-9]+.*$|\1|')
    MR_IID=$(printf '%s' "$URL" | sed -E 's|^.*/merge_requests/([0-9]+).*$|\1|')
    PROJ_PATH_ENC=$(printf '%s' "$PROJ_PATH" | jq -sRr '@uri')
    echo "host=$HOST proj=$PROJ_PATH iid=$MR_IID"
    ;;
esac

# --- Author guard ---
# Only watch PRs/MRs the current user opened. Prevents misfires when reviewing
# someone else's PR locally (e.g. `gh pr checkout` + `git push` suggestion).
PR_AUTHOR=""
ME=""
case "$PLATFORM" in
  github)
    PR_AUTHOR=$(cd "$REPO_DIR" && gh pr view "$URL" --json author --jq '.author.login // ""' 2>/dev/null || true)
    ME=$(gh api user --jq '.login // ""' 2>/dev/null || true)
    ;;
  gitlab)
    PR_AUTHOR=$(cd "$REPO_DIR" && glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}" 2>/dev/null \
                  | jq -r '.author.username // ""' 2>/dev/null || true)
    ME=$(glab api user 2>/dev/null | jq -r '.username // ""' 2>/dev/null || true)
    ;;
esac
echo "author_guard: pr_author='$PR_AUTHOR' me='$ME'"
if [ -z "$ME" ] || [ -z "$PR_AUTHOR" ]; then
  echo "could not resolve PR author or current user — exiting (fail-closed)"
  exit 0
fi
if [ "$PR_AUTHOR" != "$ME" ]; then
  echo "PR authored by '$PR_AUTHOR', not '$ME' — exiting (not my PR)"
  exit 0
fi

HEAD_SHA=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")
if [ -z "$HEAD_SHA" ]; then
  echo "could not resolve HEAD sha — exiting"
  exit 0
fi
echo "HEAD_SHA: $HEAD_SHA"

LOCK_DIR="/tmp/pr-comments-locks-$(id -u)"
mkdir -p "$LOCK_DIR"
LOCK_KEY=$(printf '%s|%s' "$URL" "$HEAD_SHA" | sha256sum | cut -c1-16)
LOCK_FILE="$LOCK_DIR/$LOCK_KEY.lock"
echo "LOCK_FILE: $LOCK_FILE"

if [ -f "$LOCK_FILE" ]; then
  OTHER_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
  if [ -n "$OTHER_PID" ] && kill -0 "$OTHER_PID" 2>/dev/null; then
    echo "another comment-watcher (pid=$OTHER_PID) already watching — exiting"
    exit 0
  fi
fi
echo "$$" > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT INT TERM

# --- Poll for a review note of this commit ---
# Markers differ across platforms:
#   github: <!-- review-state: {"last_reviewed_sha": "<sha>", ...} -->
#           Body has "Blocking Issues: N" and "Suggestions: N".
#   gitlab: <!-- ai-review-bot --> (no SHA in marker; freshness via created_at)
#           Body has "**Findings:** N issue(s) found" and "**Verdict:** ...".
# Override the gitlab bot username if your project access token uses a
# different name: GITLAB_REVIEW_BOT=other-bot.
GITLAB_REVIEW_BOT="${GITLAB_REVIEW_BOT:-sa-mr-bot-mr-bot}"
WATCH_START_EPOCH=$(date +%s)
REVIEW_BODY=""
BLOCKING=0
SUGGESTIONS=0
ATTEMPTS=40   # ~20 minutes at 30s
i=0
while [ "$i" -lt "$ATTEMPTS" ]; do
  case "$PLATFORM" in
    github)
      PR_HEAD=$(cd "$REPO_DIR" && gh pr view "$URL" --json headRefOid --jq '.headRefOid // ""' 2>/dev/null || echo "")
      ;;
    gitlab)
      PR_HEAD=$(cd "$REPO_DIR" && glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}" 2>/dev/null \
                 | jq -r '.sha // ""' 2>/dev/null || echo "")
      ;;
  esac
  if [ -n "$PR_HEAD" ] && [ "$PR_HEAD" != "$HEAD_SHA" ]; then
    echo "PR head moved to $PR_HEAD (was $HEAD_SHA) — newer watcher will handle, exiting"
    exit 0
  fi

  case "$PLATFORM" in
    github)
      COMMENTS_JSON=$(cd "$REPO_DIR" && gh pr view "$URL" --json comments 2>/dev/null || echo '{}')
      BODY=$(printf '%s' "$COMMENTS_JSON" | jq -r --arg sha "$HEAD_SHA" '
        (.comments // [])
        | map(select(.author.login == "github-actions" and (.body // "" | contains("\"last_reviewed_sha\": \"" + $sha + "\""))))
        | last
        | (.body // "")
      ')
      ;;
    gitlab)
      # Pipe glab -> jq directly: GitLab notes occasionally contain NUL bytes
      # (system notes referencing binary diffs etc.), which truncate bash
      # variables silently and break later jq parse. The pipe avoids a
      # variable round-trip.
      # Strip fractional-second suffix from created_at so fromdateiso8601 accepts it.
      BODY=$(cd "$REPO_DIR" && glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}/notes?sort=desc&per_page=50" 2>/dev/null \
              | jq -r --argjson start "$WATCH_START_EPOCH" --arg user "$GITLAB_REVIEW_BOT" '
        map(select(
          .author.username == $user
          and ((.body // "") | contains("<!-- ai-review-bot -->"))
          and ((.body // "") | contains("Code Review Summary"))
          and (((.created_at // "1970-01-01T00:00:00Z") | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) > $start)
        ))
        | first
        | (.body // "")
      ')
      ;;
  esac
  if [ -n "$BODY" ] && [ "$BODY" != "null" ]; then
    REVIEW_BODY="$BODY"
    break
  fi
  i=$((i+1))
  sleep 30
done

if [ -z "$REVIEW_BODY" ]; then
  echo "no matching pr-review comment found for $HEAD_SHA after $ATTEMPTS attempts — exiting"
  exit 0
fi

case "$PLATFORM" in
  github)
    BLOCKING=$(printf '%s' "$REVIEW_BODY" | grep -Eo 'Blocking Issues:[* ]*[0-9]+' | head -n1 | grep -Eo '[0-9]+' | head -n1)
    SUGGESTIONS=$(printf '%s' "$REVIEW_BODY" | grep -Eo 'Suggestions:[* ]*[0-9]+' | head -n1 | grep -Eo '[0-9]+' | head -n1)
    ;;
  gitlab)
    # GitLab bot has a single "Findings: N" count plus a Verdict.
    # Verdict-driven mapping: Request changes -> all blocking; Approve -> all suggestion.
    FINDINGS=$(printf '%s' "$REVIEW_BODY" | grep -Eo '\*\*Findings:\*\*[[:space:]]*[0-9]+' | head -n1 | grep -Eo '[0-9]+' | head -n1)
    FINDINGS=${FINDINGS:-0}
    VERDICT=$(printf '%s' "$REVIEW_BODY" | grep -Eo '\*\*Verdict:\*\*[[:space:]]*[A-Za-z][A-Za-z ]*' | head -n1 | sed -E 's/.*Verdict:\*\*[[:space:]]*//' | tr -d '\r')
    case "$VERDICT" in
      "Request changes"*|"Block"*|"Reject"*) BLOCKING=$FINDINGS; SUGGESTIONS=0 ;;
      "Approve"*) BLOCKING=0; SUGGESTIONS=$FINDINGS ;;
      *) BLOCKING=0; SUGGESTIONS=$FINDINGS ;;
    esac
    echo "gitlab review: findings=$FINDINGS verdict=\"$VERDICT\""
    ;;
esac
BLOCKING=${BLOCKING:-0}
SUGGESTIONS=${SUGGESTIONS:-0}
echo "review found: blocking=$BLOCKING suggestions=$SUGGESTIONS"

if [ "$BLOCKING" -eq 0 ] && [ "$SUGGESTIONS" -eq 0 ]; then
  echo "review reports no actionable items — exiting"
  exit 0
fi

# --- Notify (purple = PR-review touch) ---
if [ "$BLOCKING" -gt 0 ]; then
  NOTIFY_TITLE="PR review: $BLOCKING blocking"
else
  NOTIFY_TITLE="PR review: $SUGGESTIONS suggestion(s)"
fi
NOTIFY_BODY="$URL
blocking=$BLOCKING suggestions=$SUGGESTIONS
spawning fixer in new tmux window
log: $LOG"
NOTIFY_BG="#8e24aa"   # purple

NOTIFY_TITLE="$NOTIFY_TITLE" \
NOTIFY_BODY="$NOTIFY_BODY" \
NOTIFY_SOUND="Submarine" \
NOTIFY_URGENCY="normal" \
NOTIFY_BG="$NOTIFY_BG" \
  "$HOME/.claude/hooks/notify.sh" custom || true

# --- Spawn fixer ---
AUTOFIX="${PR_COMMENT_WATCH_AUTOFIX:-1}"
if [ "$AUTOFIX" != "1" ]; then
  echo "PR_COMMENT_WATCH_AUTOFIX=$AUTOFIX — skipping fixer spawn"
  exit 0
fi
if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not on PATH — skipping fixer spawn"
  exit 0
fi
if ! command -v claude >/dev/null 2>&1; then
  echo "claude not on PATH — skipping fixer spawn"
  exit 0
fi
if [ -z "${TMUX:-}" ] && ! tmux has-session 2>/dev/null; then
  echo "no tmux session attached or running — skipping fixer spawn"
  exit 0
fi

if [ -n "${TMUX:-}" ]; then
  TARGET_SESSION=$(tmux display-message -p '#S' 2>/dev/null || true)
fi
if [ -z "${TARGET_SESSION:-}" ]; then
  TARGET_SESSION=$(tmux list-sessions -F '#S' 2>/dev/null | head -n1)
fi
if [ -z "${TARGET_SESSION:-}" ]; then
  echo "could not resolve a tmux target session — skipping fixer spawn"
  exit 0
fi

REPO_BASENAME=$(basename "$REPO_DIR")
WINDOW_NAME="pr-review:${REPO_BASENAME}"

REVIEW_FILE="$LOG_DIR/pr-comments-review-$(date +%Y%m%d-%H%M%S)-$$.md"
printf '%s\n' "$REVIEW_BODY" > "$REVIEW_FILE"
echo "review body saved to $REVIEW_FILE"

case "$PLATFORM" in
  github)
    PR_VERB="PR"
    BRANCH_HINT="gh pr view ${URL} --json headRefName --jq .headRefName; gh pr checkout ${URL} if needed"
    ;;
  gitlab)
    PR_VERB="MR"
    BRANCH_HINT="glab mr view ${MR_IID} --output json | jq -r .source_branch; glab mr checkout ${MR_IID} if needed"
    ;;
esac

read -r -d '' FIXER_PROMPT <<EOF || true
A reviewer bot left feedback on ${URL} for commit ${HEAD_SHA}.
Blocking: ${BLOCKING}. Suggestions: ${SUGGESTIONS}.

The full review body is saved to: ${REVIEW_FILE}

Your job:
1. Confirm you are in ${REPO_DIR} on the ${PR_VERB} branch (${BRANCH_HINT}).
2. Read ${REVIEW_FILE} and the cited code locations.
3. For EACH finding (blocking AND suggestion), classify it as either:
     (a) CLEAR — the fix is obvious, low-risk, and doesn't require a judgment call.
     (b) AMBIGUOUS — multiple reasonable fixes, design tradeoff, or insufficient context.
4. Apply ALL applicable fixes locally. Build/test (e.g. \`go build ./... && go test ./... -count=1\` for Go).
5. Decide based on the mix of findings:
   - If EVERY actionable item was CLEAR: commit (separate small commits per finding is fine, or one if cohesive), push to the ${PR_VERB} branch, and exit. Do not ask the user.
   - If ANY actionable item was AMBIGUOUS: commit locally if you wrote code, but DO NOT push. Print a short summary of: what you changed, why each ambiguous item is ambiguous, and what you need from the user. Then ring the tmux bell by printing the BEL character (\`printf '\\a'\`). Wait for the user.

Hard rules:
- Treat every finding as a real claim. Verify it against the code before fixing; if you find the bot is wrong, say so explicitly in the summary instead of "fixing" a phantom.
- One pass only. If the bot's next review still complains, do not loop; hand back to the user.
- Never force-push, never rebase, never amend, never \`git add -A\`.
- Never skip hooks (--no-verify) or bypass signing.
- Never touch vendor/ or generated files unless that IS the fix.

Output: under 200 words at the end, summarize what you changed and whether you pushed.
EOF

echo "spawning fixer in tmux session=${TARGET_SESSION} window=${WINDOW_NAME}"
if tmux new-window -t "${TARGET_SESSION}:" -n "${WINDOW_NAME}" -c "${REPO_DIR}" "claude $(printf '%q' "$FIXER_PROMPT")"; then
  tmux set-window-option -t "${TARGET_SESSION}:${WINDOW_NAME}" monitor-bell on 2>/dev/null || true
  echo "fixer launched, monitor-bell enabled"
else
  echo "tmux new-window failed (rc=$?) — fixer not launched"
fi

exit 0
