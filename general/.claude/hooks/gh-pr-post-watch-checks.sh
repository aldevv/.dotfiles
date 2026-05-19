#!/usr/bin/env bash
# PostToolUse hook for `gh pr create *`, `glab mr create *`, and `git push [*]`.
# Watches CI on the open PR/MR for the current branch and, on failure:
# notifies the user AND spawns a Claude session in a new tmux window to
# attempt a one-shot fix.
#
# Platform detection:
#   - URL pattern github.com/.../pull/<n>      → GitHub (gh)
#   - URL pattern .../merge_requests/<n>       → GitLab (glab)
# For PR-create / MR-create commands, the URL is parsed from stdout.
# For `git push`, the URL is looked up via `gh pr list` (then `glab mr list`)
# for the current branch in the tool's cwd; if no PR/MR exists yet, the hook
# exits silently.
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

REPO_DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // ""')
if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR" ]; then
  REPO_DIR=$(pwd)
fi
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

# Dedup: only one watcher per (URL, HEAD-SHA) pair. The PR-create hook and a
# concurrent git-push hook would otherwise both watch the same pipeline.
LOCK_DIR="/tmp/pr-watch-locks-$(id -u)"
mkdir -p "$LOCK_DIR"
HEAD_SHA=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
LOCK_KEY=$(printf '%s|%s' "$URL" "$HEAD_SHA" | sha256sum | cut -c1-16)
LOCK_FILE="$LOCK_DIR/$LOCK_KEY.lock"
echo "LOCK_FILE: $LOCK_FILE (url=$URL sha=$HEAD_SHA)"

if [ -f "$LOCK_FILE" ]; then
  OTHER_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
  if [ -n "$OTHER_PID" ] && kill -0 "$OTHER_PID" 2>/dev/null; then
    echo "another watcher (pid=$OTHER_PID) is already watching this (URL, SHA) — exiting"
    exit 0
  fi
  echo "stale lock for dead pid=$OTHER_PID — taking over"
fi
echo "$$" > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT INT TERM

# Classify platform by URL pattern.
case "$URL" in
  *github.com*/pull/*)         PLATFORM=github ;;
  */-/merge_requests/*|*/merge_requests/*) PLATFORM=gitlab ;;
  *) echo "unknown platform for URL — exiting"; exit 0 ;;
esac
echo "PLATFORM: $PLATFORM"

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
      STATUS="fail"
      FAILED=$(printf '%s\n' "$OUT" | awk -F'\t' '$2 == "fail" || $2 == "cancel" { print $1 }' | paste -sd, -)
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
    i=0
    while [ "$i" -lt 480 ]; do
      MR_JSON=$(cd "$REPO_DIR" && glab mr view "$MR_NUM" --output json 2>/dev/null || echo '{}')
      PIPELINE_STATUS=$(printf '%s' "$MR_JSON" | jq -r '.head_pipeline.status // .pipeline.status // ""')
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

case "$(uname -s)" in
  Darwin)
    if command -v terminal-notifier >/dev/null 2>&1; then
      terminal-notifier -title "$NOTIFY_TITLE" -message "$NOTIFY_BODY" -open "$URL" -sound "$NOTIFY_SOUND" -sender com.apple.Terminal || true
    elif command -v osascript >/dev/null 2>&1; then
      AS_TITLE=${NOTIFY_TITLE//\"/\\\"}
      AS_BODY=${NOTIFY_BODY//\"/\\\"}
      osascript -e "display notification \"$AS_BODY\" with title \"$AS_TITLE\" sound name \"$NOTIFY_SOUND\"" || true
    fi
    ;;
  *)
    if command -v notify-send >/dev/null 2>&1; then
      # The bgcolor/frcolor hints are dunst-specific; harmless on other notifiers.
      notify-send -u "$NOTIFY_URGENCY" -a claude-code \
        -h "string:bgcolor:$NOTIFY_BG" \
        -h "string:frcolor:$NOTIFY_BG" \
        -h "string:fgcolor:#ffffff" \
        "$NOTIFY_TITLE" "$NOTIFY_BODY" || true
    fi
    ;;
esac

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
WINDOW_NAME="ci-fix:${REPO_BASENAME}"

# Platform-specific tooling hints baked into the prompt.
case "$PLATFORM" in
  github)
    CHECKOUT_CMD="gh pr checkout ${URL}"
    BRANCH_QUERY="gh pr view ${URL} --json headRefName --jq .headRefName"
    LOG_CMD="gh run view <id> --log-failed | tail -200"
    RERUN_CMD="gh run rerun <id> --failed"
    REWATCH_CMD="gh pr checks ${URL} --watch --fail-fast --interval 15"
    ;;
  gitlab)
    CHECKOUT_CMD="glab mr checkout ${URL##*/}"
    BRANCH_QUERY="glab mr view ${URL##*/} --output json | jq -r .source_branch"
    LOG_CMD="glab ci view <job-id>  # or 'glab ci trace <job-id>' for raw logs"
    RERUN_CMD="glab ci retry <job-id>"
    REWATCH_CMD="glab ci status --branch \$(git branch --show-current) --live"
    ;;
esac

read -r -d '' FIXER_PROMPT <<EOF || true
A CI failure was detected on ${URL} (platform: ${PLATFORM}). Failing checks/jobs: ${FAILED}.

Your job is to attempt a single, minimal fix.

Workflow:
1. Confirm you are in the right repo: pwd should be ${REPO_DIR}. If not, cd there. Make sure HEAD is the PR/MR branch (${BRANCH_QUERY}; if not checked out, run ${CHECKOUT_CMD}).
2. For each failing check/job, fetch its failed log lines: ${LOG_CMD}.
3. Diagnose the root cause. Apply the SMALLEST possible fix. Do not refactor, do not rework architecture, do not touch unrelated files.
4. If the failure looks like a flake (intermittent timeout, network blip, vendor-side outage, no clear code-level cause), do NOT edit code. Re-run via ${RERUN_CMD} and stop.
5. Build/test locally for whatever language the repo uses (e.g. \`go build ./... && go test ./... -count=1\` for Go).
6. Commit with a short imperative message ("fix <thing>"). Stage only the files you actually changed. Never use \`git add -A\`. Push to the PR/MR branch.
7. Re-watch CI: ${REWATCH_CMD}. If it succeeds, summarize what changed and exit. If it fails again, STOP and tell the user — do not loop.

Hard rules:
- Never open a new PR or MR. Never change reviewers, labels, or assignees.
- Never rebase or force-push. Never merge.
- Never touch vendor/ or generated files unless that IS the bug.
- Never skip hooks (--no-verify) or bypass signing.
- One fix attempt total. If the second watch fails, hand control back to the user.

URL: ${URL}
Failing (comma-separated): ${FAILED}
Hook log for context: ${LOG}
EOF

echo "spawning fixer in tmux session=${TARGET_SESSION} window=${WINDOW_NAME}"
if tmux new-window -t "${TARGET_SESSION}:" -n "${WINDOW_NAME}" -c "${REPO_DIR}" "claude $(printf '%q' "$FIXER_PROMPT")"; then
  echo "fixer launched"
else
  echo "tmux new-window failed (rc=$?) — fixer not launched"
fi

exit 0
