#!/usr/bin/env bash
# PostToolUse hook for `gh pr create *`, `glab mr create *`, and `git push [*]`.
# Watches CI on the open PR/MR for the current branch and, on failure tied to
# the commit that triggered this hook (HEAD at script start):
# notifies the user AND spawns a Claude session in a new tmux window in a
# fresh git worktree on a throwaway branch (ci-fix-<short_sha>) to attempt a
# one-shot fix. The fixer is forbidden from pushing; the operator integrates
# the commit back into the PR branch.
#
# Wiring lives in ~/.claude/settings.json. All gating below is also enforced
# in-script via the shared prelude so a misfire is cheap (exits in ms):
#   - duplicate event (same stdin hash across N matchers) -> exit
#   - tool exit_code != 0 -> exit
#   - git push --tags / --delete / --dry-run / --mirror / --all -> exit
#   - branch is default/protected (main/master/...) -> exit
#   - PR/MR not in OPEN state (merged/closed) -> exit
#   - author of PR is not the current gh/glab user -> exit
#   - another watcher already holds the per-PR flock -> exit
#   - failing checks are not tied to HEAD_SHA at script start -> exit
#   - worktree creation fails -> exit (do not fall back to main checkout)
#
# Disable per-invocation:
#   PR_WATCH_AUTOFIX=0  -> still watch + notify, but do not spawn the fixer.
#
# Logs to ~/.claude/hooks/logs/pr-watch-<timestamp>.log.

set -u

LOG_DIR="$HOME/.claude/hooks/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/pr-watch-$(date +%Y%m%d-%H%M%S)-$$.log"
exec >>"$LOG" 2>&1

echo "=== gh-pr-post-watch-checks.sh started at $(date -Iseconds) ==="
echo "PWD: $(pwd)"

INPUT=$(cat)

# shellcheck source=lib/gh-pr-watch-prelude.sh
. "$HOME/.claude/hooks/lib/gh-pr-watch-prelude.sh"

prelude_dedup_event "pr-watch" || exit 0
prelude_should_proceed || exit 0

prelude_resolve_repo_dir
echo "REPO_DIR: $REPO_DIR"

TOOL_CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
echo "TOOL_CMD: $TOOL_CMD"

STDOUT_TEXT=$(printf '%s' "$INPUT" | jq -r '.tool_response.stdout // ""')

# Try stdout first (create commands print the URL).
URL=$(printf '%s' "$STDOUT_TEXT" \
  | grep -Eo 'https://[^ ]+/(pull|merge_requests)/[0-9]+' \
  | head -n1)

# Fallback: lookup an open PR/MR for the current branch.
if [ -z "$URL" ]; then
  if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    if [ -n "$BRANCH" ] && [ "$BRANCH" != "HEAD" ]; then
      echo "looking up PR/MR for branch '$BRANCH' in $REPO_DIR"
      ORIGIN_URL=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
      case "$ORIGIN_URL" in
        *github.com*)
          if command -v gh >/dev/null 2>&1; then
            URL=$(cd "$REPO_DIR" && gh pr list --head "$BRANCH" --state open --json url --jq '.[0].url // ""' 2>/dev/null || true)
          fi
          ;;
        *gitlab*)
          if command -v glab >/dev/null 2>&1; then
            URL=$(cd "$REPO_DIR" && glab mr list --source-branch "$BRANCH" --opened --output json 2>/dev/null \
                    | jq -r '.[0].web_url // ""' 2>/dev/null || true)
          fi
          ;;
        *)
          # Unknown host — try gh, then glab.
          if command -v gh >/dev/null 2>&1; then
            URL=$(cd "$REPO_DIR" && gh pr list --head "$BRANCH" --state open --json url --jq '.[0].url // ""' 2>/dev/null || true)
          fi
          if [ -z "$URL" ] && command -v glab >/dev/null 2>&1; then
            URL=$(cd "$REPO_DIR" && glab mr list --source-branch "$BRANCH" --opened --output json 2>/dev/null \
                    | jq -r '.[0].web_url // ""' 2>/dev/null || true)
          fi
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

# Classify platform by URL pattern.
case "$URL" in
  *github.com*/pull/*)         PLATFORM=github ;;
  */-/merge_requests/*|*/merge_requests/*) PLATFORM=gitlab ;;
  *) echo "unknown platform for URL — exiting"; exit 0 ;;
esac
echo "PLATFORM: $PLATFORM"

# For gitlab the open-state and author-guard helpers in the prelude need these.
if [ "$PLATFORM" = "gitlab" ]; then
  HOST=$(printf '%s' "$URL" | sed -E 's|^https?://([^/]+)/.*$|\1|')
  PROJ_PATH=$(printf '%s' "$URL" | sed -E 's|^https?://[^/]+/(.+)/-/merge_requests/[0-9]+.*$|\1|')
  MR_IID=$(printf '%s' "$URL" | sed -E 's|^.*/merge_requests/([0-9]+).*$|\1|')
  PROJ_PATH_ENC=$(printf '%s' "$PROJ_PATH" | jq -sRr '@uri')
fi

# Verify the push actually targeted this PR (repo and branch).
prelude_verify_push "$URL" "$PLATFORM" "$REPO_DIR" || exit 0

# Skip merged/closed PRs/MRs early — saves the long CI poll.
prelude_pr_is_open "$URL" || exit 0

# One active watcher per (cwd, branch, PR). flock kills concurrent watchers
# from sibling matchers and from subsequent re-pushes on the same PR.
prelude_acquire_pr_lock "pr-watch" "$URL" || exit 0
HEAD_SHA=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
echo "LOCK_FILE: $LOCK_FILE (url=$URL sha=$HEAD_SHA)"

# --- Author guard ---
# Only watch PRs/MRs the current user opened. Prevents misfires when reviewing
# someone else's PR locally (e.g. `gh pr checkout` + `git push` suggestion).
PR_AUTHOR=""
ME=""
case "$PLATFORM" in
  github)
    if command -v gh >/dev/null 2>&1; then
      PR_AUTHOR=$(cd "$REPO_DIR" && gh pr view "$URL" --json author --jq '.author.login // ""' 2>/dev/null || true)
      ME=$(gh api user --jq '.login // ""' 2>/dev/null || true)
    fi
    ;;
  gitlab)
    if command -v glab >/dev/null 2>&1; then
      MR_NUM_GUARD=$(echo "$URL" | grep -Eo '[0-9]+$')
      PR_AUTHOR=$(cd "$REPO_DIR" && glab mr view "$MR_NUM_GUARD" --output json 2>/dev/null \
                    | jq -r '.author.username // ""' 2>/dev/null || true)
      ME=$(glab api user 2>/dev/null | jq -r '.username // ""' 2>/dev/null || true)
    fi
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

NOTIFY_TITLE="watching CI" \
NOTIFY_BODY="$URL
log: $LOG" \
NOTIFY_SOUND="Pop" \
NOTIFY_URGENCY="low" \
NOTIFY_BG="#f9a825" \
  "$HOME/.claude/hooks/notify.sh" custom || true

# --- Watch CI ---
STATUS="" # "pass" | "fail" | "skip"
FAILED=""
case "$PLATFORM" in
  github)
    if ! command -v gh >/dev/null 2>&1; then
      echo "gh not on PATH — cannot watch GitHub PR"
      exit 0
    fi
    OUT=$(gh pr checks "$URL" --watch --fail-fast --interval 15 2>&1)
    RC=$?
    echo "gh pr checks exited with rc=$RC"
    echo "--- gh pr checks output ---"
    echo "$OUT"
    echo "---------------------------"
    if [ "$RC" -eq 0 ]; then
      STATUS="pass"
    elif ! printf '%s\n' "$OUT" | awk -F'\t' '$2 == "fail" || $2 == "cancel" { found=1 } END { exit !found }'; then
      # Real failure rows are tab-separated; tool errors print a single line.
      echo "no failed-check rows — treating as tool error, not notifying"
      exit 0
    else
      # Tie failures to the commit that triggered this hook. Another push may
      # have moved the PR head while gh pr checks --watch was running; that
      # new commit will get its own watcher.
      NEW_HEAD=$(cd "$REPO_DIR" && gh pr view "$URL" --json headRefOid --jq '.headRefOid // ""' 2>/dev/null || echo "")
      if [ -n "$NEW_HEAD" ] && [ "$NEW_HEAD" != "$HEAD_SHA" ]; then
        echo "PR head moved to $NEW_HEAD (was $HEAD_SHA) — newer push has its own watcher, exiting"
        exit 0
      fi
      NWO=$(printf '%s' "$URL" | sed -E 's|^https?://[^/]+/([^/]+/[^/]+)/.*$|\1|')
      SHA_FAILED=$(gh api "repos/$NWO/commits/$HEAD_SHA/check-runs?per_page=100" \
        --jq '.check_runs[] | select(.conclusion == "failure" or .conclusion == "cancelled" or .conclusion == "timed_out") | .name' \
        2>/dev/null | paste -sd, -)
      if [ -z "$SHA_FAILED" ]; then
        SHA_FAILED=$(gh api "repos/$NWO/commits/$HEAD_SHA/status" \
          --jq '.statuses[] | select(.state == "failure" or .state == "error") | .context' \
          2>/dev/null | paste -sd, -)
      fi
      if [ -z "$SHA_FAILED" ]; then
        echo "watch reported failures but none are tied to HEAD_SHA=$HEAD_SHA — exiting"
        exit 0
      fi
      STATUS="fail"
      FAILED="$SHA_FAILED"
    fi
    ;;

  gitlab)
    if ! command -v glab >/dev/null 2>&1; then
      echo "glab not on PATH — cannot watch GitLab MR"
      exit 0
    fi
    MR_NUM=$(echo "$URL" | grep -Eo '[0-9]+$')
    if [ -z "$MR_NUM" ]; then
      echo "could not extract MR number from $URL"
      exit 0
    fi
    echo "polling glab mr view $MR_NUM in $REPO_DIR"
    PIPELINE_STATUS=""
    PIPELINE_SHA=""
    i=0
    while [ "$i" -lt 480 ]; do
      MR_JSON=$(cd "$REPO_DIR" && glab mr view "$MR_NUM" --output json 2>/dev/null || echo '{}')
      PIPELINE_STATUS=$(printf '%s' "$MR_JSON" | jq -r '.head_pipeline.status // .pipeline.status // ""')
      PIPELINE_SHA=$(printf '%s' "$MR_JSON" | jq -r '.head_pipeline.sha // .pipeline.sha // ""')
      if [ -n "$PIPELINE_SHA" ] && [ "$PIPELINE_SHA" != "$HEAD_SHA" ]; then
        echo "head pipeline sha=$PIPELINE_SHA != HEAD_SHA=$HEAD_SHA — newer push has its own watcher, exiting"
        exit 0
      fi
      case "$PIPELINE_STATUS" in
        success)              STATUS="pass"; break ;;
        failed|canceled)      STATUS="fail"; break ;;
        running|pending|preparing|created|scheduled|waiting_for_resource|manual|"") sleep 15 ;;
        *)                    sleep 15 ;;
      esac
      i=$((i+1))
    done
    echo "glab pipeline status: $PIPELINE_STATUS"
    if [ "$STATUS" = "fail" ]; then
      FAILED=$(cd "$REPO_DIR" && glab ci status --branch "$BRANCH" 2>/dev/null \
                | awk '/failed/ { print $1 }' \
                | paste -sd, -)
      if [ -z "$FAILED" ]; then
        FAILED="(pipeline failed; could not enumerate failed jobs)"
      fi
    fi
    ;;
esac

if [ -z "$STATUS" ]; then
  echo "watch did not resolve to pass/fail — exiting"
  exit 0
fi
echo "status: $STATUS, failed: $FAILED"

# --- Notify ---
if [ "$STATUS" = "pass" ]; then
  NOTIFY_TITLE="PR CI passed"
  NOTIFY_BODY="$URL
all checks green
log: $LOG"
else
  NOTIFY_TITLE="PR CI failed"
  NOTIFY_BODY="$URL
failing: $FAILED
spawning fixer in new tmux window
log: $LOG"
fi

if [ "$STATUS" = "pass" ]; then
  NOTIFY_URGENCY=low
  NOTIFY_BG="#2e7d32"   # green
  NOTIFY_SOUND=Glass
else
  NOTIFY_URGENCY=critical
  NOTIFY_BG="#c62828"   # red
  NOTIFY_SOUND=Basso
fi

NOTIFY_TITLE="$NOTIFY_TITLE" \
NOTIFY_BODY="$NOTIFY_BODY" \
NOTIFY_SOUND="$NOTIFY_SOUND" \
NOTIFY_URGENCY="$NOTIFY_URGENCY" \
NOTIFY_BG="$NOTIFY_BG" \
  "$HOME/.claude/hooks/notify.sh" custom || true

# --- Spawn fixer ---
if [ "$STATUS" != "fail" ]; then
  echo "status=$STATUS — no fixer needed"
  exit 0
fi
AUTOFIX="${PR_WATCH_AUTOFIX:-1}"
if [ "$AUTOFIX" != "1" ]; then
  echo "PR_WATCH_AUTOFIX=$AUTOFIX — skipping fixer spawn"
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
SHORT_SHA=$(printf '%s' "$HEAD_SHA" | cut -c1-8)
WINDOW_NAME="AUTO-CI-FIX:${REPO_BASENAME}#${SHORT_SHA}"

# Spawn the fixer in a fresh worktree so concurrent fixers and the operator's
# main checkout never clobber each other. The fixer's branch is throwaway; the
# operator integrates its commits back into the PR branch.
if ! prelude_create_fix_worktree "$REPO_DIR" "$HEAD_SHA" "ci-fix"; then
  echo "could not create fixer worktree — skipping fixer spawn"
  exit 0
fi

PR_BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "the PR branch")

# Platform-specific tooling hint baked into the prompt.
case "$PLATFORM" in
  github) LOG_CMD="gh run view <id> --log-failed | tail -200" ;;
  gitlab) LOG_CMD="glab ci view <job-id>  # or 'glab ci trace <job-id>' for raw logs" ;;
esac

read -r -d '' FIXER_PROMPT <<EOF || true
A CI failure was detected on ${URL} (platform: ${PLATFORM}) for commit ${HEAD_SHA}.
Failing checks/jobs: ${FAILED}.

You are running in a fresh git worktree at ${WT_PATH}, on a throwaway branch
${FIX_BRANCH} that was created off ${HEAD_SHA} (the same commit the failing CI
ran against). The operator's main checkout still has ${PR_BRANCH} checked out
elsewhere — do NOT switch branches and do NOT touch their working tree.

Your job is to attempt a single, minimal fix.

Workflow:
1. Confirm pwd is ${WT_PATH} and \`git rev-parse --abbrev-ref HEAD\` prints ${FIX_BRANCH}. If not, stop and tell the user.
2. For each failing check/job, fetch its failed log lines: ${LOG_CMD}.
3. Diagnose the root cause. Apply the SMALLEST possible fix. Do not refactor, do not rework architecture, do not touch unrelated files.
4. If the failure looks like a flake (intermittent timeout, network blip, vendor-side outage, no clear code-level cause), do NOT edit code or re-run anything. Stop and tell the user it looks like a flake.
5. Build/test locally for whatever language the repo uses (e.g. \`go build ./... && go test ./... -count=1\` for Go).
6. Commit locally on ${FIX_BRANCH} with a short imperative message ("fix <thing>"). Stage only the files you actually changed. Never use \`git add -A\`.
7. Print a short summary of what you changed and ring the tmux bell (\`printf '\\a'\`).
8. Ask the user with AskUserQuestion whether to merge ${FIX_BRANCH} into ${PR_BRANCH}. If they say yes, run \`git -C ${REPO_DIR} merge --no-edit ${FIX_BRANCH}\`. On success, tell them the merge landed and remind them to push from ${REPO_DIR} themselves. On failure (dirty working tree in the main checkout, merge conflict, anything else), report the exact git output and stop — do NOT retry, do NOT \`git merge --abort\` and retry, do NOT push. If they say no, leave the fix branch in place.
9. End your turn. Do NOT push. Do NOT re-run CI. Do NOT loop back waiting for further input.

Hard rules:
- Never push. Never open a new PR or MR. Never change reviewers, labels, or assignees.
- Never switch branches, never rebase, never force-push, never amend.
- The only merge you may perform is the single \`git merge --no-edit ${FIX_BRANCH}\` invocation in step 8, only if the user said yes.
- Never touch vendor/ or generated files unless that IS the bug.
- Never skip hooks (--no-verify) or bypass signing.
- One fix attempt total. After the merge prompt, end your turn.

URL: ${URL}
Operator's main checkout: ${REPO_DIR}
PR branch (operator's checkout): ${PR_BRANCH}
Fix branch (your worktree): ${FIX_BRANCH}
Worktree: ${WT_PATH}
Failing (comma-separated): ${FAILED}
Hook log for context: ${LOG}
EOF

echo "spawning fixer in tmux session=${TARGET_SESSION} window=${WINDOW_NAME} cwd=${WT_PATH}"
if tmux new-window -t "${TARGET_SESSION}:" -n "${WINDOW_NAME}" -c "${WT_PATH}" "claude $(printf '%q' "$FIXER_PROMPT")"; then
  echo "fixer launched"
else
  echo "tmux new-window failed (rc=$?) — fixer not launched"
fi

exit 0
