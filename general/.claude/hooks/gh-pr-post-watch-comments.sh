#!/usr/bin/env bash
# PostToolUse hook for `gh pr create *`, `glab mr create *`, and `git push [*]`.
# After a push, polls the PR's automated review comments. When a review is
# posted that is tied to HEAD_SHA at script start (github: last_reviewed_sha
# in the comment marker; gitlab: comment created after WATCH_START while the
# MR head is still HEAD_SHA) AND it has actionable findings (Blocking > 0 OR
# Suggestions > 0), it:
#   - sends a purple notify-send so the operator sees a PR-review touch
#   - opens a new tmux window in a fresh git worktree on a throwaway branch
#     (pr-review-fix-<short_sha>) with monitor-bell enabled
#   - launches a Claude session whose prompt instructs it to fix locally on
#     the throwaway branch and STOP (never push without operator confirmation).
#
# Wiring lives in ~/.claude/settings.json. All gating is also enforced
# in-script via the shared prelude so a misfire is cheap (exits in ms):
#   - duplicate event (same stdin hash across N matchers) -> exit
#   - tool exit_code != 0 -> exit
#   - git push --tags / --delete / --dry-run / --mirror / --all -> exit
#   - branch is default/protected (main/master/...) -> exit
#   - PR/MR not in OPEN state (merged/closed) -> exit
#   - author of PR is not the current gh/glab user -> exit
#   - another watcher already holds the per-PR flock -> exit
#   - fixer window for this PR already exists in tmux -> exit (recursion guard)
#   - PR head moves off HEAD_SHA before the spawn -> exit
#   - worktree creation fails -> exit (do not fall back to main checkout)
#
# Disable per-invocation:
#   PR_COMMENT_WATCH_AUTOFIX=0  -> still poll + notify, do not spawn fixer.
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

# shellcheck source=lib/gh-pr-watch-prelude.sh
. "$HOME/.claude/hooks/lib/gh-pr-watch-prelude.sh"

prelude_dedup_event "pr-comments" || exit 0
prelude_should_proceed || exit 0

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

# Skip merged/closed PRs/MRs early — saves the 20-minute polling loop.
prelude_pr_is_open "$URL" || exit 0

# Recursion guard: if a fixer window for this PR head sha already exists in tmux, skip.
# Promoted from the bottom of the script to here so we bail before the poll.
REPO_BASENAME=$(basename "$REPO_DIR")
HEAD_SHA=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")
if [ -z "$HEAD_SHA" ]; then
  echo "could not resolve HEAD sha — exiting"
  exit 0
fi
SHORT_SHA=$(printf '%s' "$HEAD_SHA" | cut -c1-8)
WINDOW_NAME="AUTO-COMMENT-FIX:${REPO_BASENAME}#${SHORT_SHA}"
if command -v tmux >/dev/null 2>&1 && tmux list-windows -a -F '#W' 2>/dev/null | grep -Fxq "$WINDOW_NAME"; then
  echo "fixer window '$WINDOW_NAME' already exists in tmux — exiting (recursion guard)"
  exit 0
fi

# One active watcher per (cwd, branch, PR).
prelude_acquire_pr_lock "pr-comments" "$URL" || exit 0
echo "LOCK_FILE: $LOCK_FILE"

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

echo "HEAD_SHA: $HEAD_SHA"

NOTIFY_TITLE="watching comments" \
NOTIFY_BODY="$URL
log: $LOG" \
NOTIFY_SOUND="Pop" \
NOTIFY_URGENCY="low" \
NOTIFY_BG="#f9a825" \
  "$HOME/.claude/hooks/notify.sh" custom || true

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

# REPO_BASENAME/PR_NUM/WINDOW_NAME computed near the top for the early
# recursion guard; re-check here in case another fixer window appeared
# during the polling loop.
if tmux list-windows -a -F '#W' 2>/dev/null | grep -Fxq "$WINDOW_NAME"; then
  echo "fixer window '$WINDOW_NAME' appeared during poll — exiting (recursion guard)"
  exit 0
fi

# Final head-still-matches guard: between the comment match and the spawn, a
# new push could have moved the PR head. Don't apply old feedback to a new
# commit; let the newer push's watcher take over.
case "$PLATFORM" in
  github)
    LATE_HEAD=$(cd "$REPO_DIR" && gh pr view "$URL" --json headRefOid --jq '.headRefOid // ""' 2>/dev/null || echo "")
    ;;
  gitlab)
    LATE_HEAD=$(cd "$REPO_DIR" && glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}" 2>/dev/null \
                 | jq -r '.sha // ""' 2>/dev/null || echo "")
    ;;
esac
if [ -n "$LATE_HEAD" ] && [ "$LATE_HEAD" != "$HEAD_SHA" ]; then
  echo "PR head moved to $LATE_HEAD (was $HEAD_SHA) before spawn — newer push will handle, exiting"
  exit 0
fi

# Spawn the fixer in a fresh worktree so concurrent fixers and the operator's
# main checkout never clobber each other. The fixer's branch is throwaway; the
# operator integrates its commits back into the PR branch.
if ! prelude_create_fix_worktree "$REPO_DIR" "$HEAD_SHA" "pr-review-fix"; then
  echo "could not create fixer worktree — skipping fixer spawn"
  exit 0
fi

PR_BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "the PR branch")

REVIEW_FILE="$LOG_DIR/pr-comments-review-$(date +%Y%m%d-%H%M%S)-$$.md"
printf '%s\n' "$REVIEW_BODY" > "$REVIEW_FILE"
echo "review body saved to $REVIEW_FILE"

case "$PLATFORM" in
  github) PR_VERB="PR" ;;
  gitlab) PR_VERB="MR" ;;
esac

read -r -d '' FIXER_PROMPT <<EOF || true
A reviewer bot left feedback on ${URL} for commit ${HEAD_SHA}.
Blocking: ${BLOCKING}. Suggestions: ${SUGGESTIONS}.

The full review body is saved to: ${REVIEW_FILE}

You are running in a fresh git worktree at ${WT_PATH}, on a throwaway branch
${FIX_BRANCH} that was created off ${HEAD_SHA} (the exact commit the bot
reviewed). The operator's main checkout still has ${PR_BRANCH} checked out
elsewhere — do NOT switch branches and do NOT touch their working tree.

Your job:
1. Confirm pwd is ${WT_PATH} and \`git rev-parse --abbrev-ref HEAD\` prints ${FIX_BRANCH}. If not, stop and tell the user.
2. Read ${REVIEW_FILE} and the cited code locations.
3. For EACH finding (blocking AND suggestion), classify it as either:
     (a) CLEAR — the fix is obvious, low-risk, and doesn't require a judgment call.
     (b) AMBIGUOUS — multiple reasonable fixes, design tradeoff, or insufficient context.
4. Apply ALL applicable fixes locally. Build/test (e.g. \`go build ./... && go test ./... -count=1\` for Go).
5. Commit locally on ${FIX_BRANCH}. Separate small commits per finding is fine, or one cohesive commit. Stage only the files you actually changed. Never \`git add -A\`.
6. Print a short summary of: what you changed, which findings were CLEAR vs. AMBIGUOUS, why each AMBIGUOUS item is ambiguous, and (for any phantoms) where you found the bot was wrong. Ring the tmux bell (\`printf '\\a'\`).
7. Ask the user with AskUserQuestion whether to merge ${FIX_BRANCH} into ${PR_BRANCH}. If they say yes, run \`git -C ${REPO_DIR} merge --no-edit ${FIX_BRANCH}\`. On success, tell them the merge landed and remind them to push from ${REPO_DIR} themselves. On failure (dirty working tree in the main checkout, merge conflict, anything else), report the exact git output and stop — do NOT retry, do NOT \`git merge --abort\` and retry, do NOT push. If they say no, leave the fix branch in place.
8. End your turn. Do NOT push. Do NOT loop back waiting for further input.

Hard rules:
- NEVER push. The operator pushes; you don't.
- Treat every finding as a real claim. Verify it against the code before fixing; if you find the bot is wrong, say so explicitly in the summary instead of "fixing" a phantom.
- One pass only. After the merge prompt, end your turn.
- Never switch branches, never force-push, never rebase, never amend, never \`git add -A\`.
- The only merge you may perform is the single \`git merge --no-edit ${FIX_BRANCH}\` invocation in step 7, only if the user said yes.
- Never skip hooks (--no-verify) or bypass signing.
- Never touch vendor/ or generated files unless that IS the fix.

Operator's main checkout: ${REPO_DIR}
PR branch (operator's checkout): ${PR_BRANCH}
Fix branch (your worktree): ${FIX_BRANCH}
Worktree: ${WT_PATH}

Output: under 200 words at the end, summarize what you changed and whether the merge into ${PR_BRANCH} ran. Confirm you did NOT push.
EOF

echo "spawning fixer in tmux session=${TARGET_SESSION} window=${WINDOW_NAME} cwd=${WT_PATH}"
if tmux new-window -t "${TARGET_SESSION}:" -n "${WINDOW_NAME}" -c "${WT_PATH}" "claude $(printf '%q' "$FIXER_PROMPT")"; then
  tmux set-window-option -t "${TARGET_SESSION}:${WINDOW_NAME}" monitor-bell on 2>/dev/null || true
  echo "fixer launched, monitor-bell enabled"
else
  echo "tmux new-window failed (rc=$?) — fixer not launched"
fi

exit 0
