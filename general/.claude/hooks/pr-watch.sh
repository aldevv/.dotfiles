#!/usr/bin/env bash
# PostToolUse hook for `gh pr create *`, `glab mr create *`, and `git push [*]`.
# After a push, runs two parallel watches against the open PR/MR:
#   1. CI checks/pipelines on the commit that triggered this hook (HEAD_SHA).
#   2. Automated review-bot comments tied to HEAD_SHA.
# Each watch independently spawns its own Claude fixer in its own throwaway
# worktree when it fires (ci-fix-<sha> for CI, pr-review-fix-<sha> for
# comments). They can run concurrently because the worktrees never collide.
#
# Wiring lives in ~/.claude/settings.json (or ~/.claude/settings.local.json).
# All gating below is enforced in-script via the shared prelude:
#   - duplicate event (same stdin hash across N matchers) -> exit
#   - tool exit_code != 0 -> exit
#   - git push --tags / --delete / --dry-run / --mirror / --all -> exit
#   - branch is default/protected -> exit
#   - PR/MR not open -> exit
#   - author of PR is not the current gh/glab user -> exit
#   - another watcher already holds the per-PR lock -> exit
#   - any AUTO-{CI,COMMENT}-FIX window for this PR head sha exists -> exit
#
# Disable per-invocation:
#   PR_WATCH_AUTOFIX=0  -> still watch + notify, but do not spawn the fixer.
#
# Requires:
#   - flock on $PATH (linux: built-in; macOS: `brew install flock`).
#     The per-PR lock acquisition relies on it; without flock the hook exits
#     before doing any work.
#
# Logs to ~/.claude/hooks/logs/pr-watch-<timestamp>.log.

set -u

LOG_DIR="$HOME/.claude/hooks/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/pr-watch-$(date +%Y%m%d-%H%M%S)-$$.log"
exec >>"$LOG" 2>&1

if ! command -v flock >/dev/null 2>&1; then
  echo "flock not on PATH — install it (macOS: 'brew install flock'; linux: usually built-in) and retry"
  NOTIFY_TITLE="pr-watch.sh: flock missing" \
  NOTIFY_BODY="install with: brew install flock
log: $LOG" \
  NOTIFY_SOUND="Basso" \
  NOTIFY_URGENCY="critical" \
  NOTIFY_BG="#c62828" \
    "$HOME/.claude/hooks/notify.sh" custom 2>/dev/null || true
  exit 0
fi

echo "=== pr-watch.sh started at $(date -Iseconds) ==="
echo "PWD: $(pwd)"

INPUT=$(cat)

# shellcheck source=lib/pr-watch/pr-watch-prelude.sh
. "$HOME/.claude/hooks/lib/pr-watch/pr-watch-prelude.sh"
# shellcheck source=lib/pr-watch/pr-watch-ci.sh
. "$HOME/.claude/hooks/lib/pr-watch/pr-watch-ci.sh"
# shellcheck source=lib/pr-watch/pr-watch-comments.sh
. "$HOME/.claude/hooks/lib/pr-watch/pr-watch-comments.sh"

prelude_dedup_event "pr-watch" || exit 0
prelude_should_proceed || exit 0

prelude_resolve_repo_dir
echo "REPO_DIR: $REPO_DIR"

TOOL_CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
echo "TOOL_CMD: $TOOL_CMD"

STDOUT_TEXT=$(printf '%s' "$INPUT" | jq -r '.tool_response.stdout // ""')

# --- Resolve PR/MR URL ---
URL=$(printf '%s' "$STDOUT_TEXT" \
  | grep -Eo 'https://[^ ]+/(pull|merge_requests)/[0-9]+' \
  | head -n1)

lookup_pr_url_by_head() {
  local ref="$1"
  [ -z "$ref" ] && return 0
  [ "$ref" = "HEAD" ] && return 0
  local origin_url
  origin_url=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
  case "$origin_url" in
    *github.com*|*conductorone*)
      command -v gh >/dev/null 2>&1 && \
        (cd "$REPO_DIR" && gh pr list --head "$ref" --state open --json url --jq '.[0].url // ""' 2>/dev/null) || true
      ;;
    *gitlab*)
      command -v glab >/dev/null 2>&1 && \
        (cd "$REPO_DIR" && glab mr list --source-branch "$ref" --opened --output json 2>/dev/null \
                | jq -r '.[0].web_url // ""' 2>/dev/null) || true
      ;;
    *)
      local url_gh=""
      command -v gh >/dev/null 2>&1 && \
        url_gh=$(cd "$REPO_DIR" && gh pr list --head "$ref" --state open --json url --jq '.[0].url // ""' 2>/dev/null || true)
      if [ -n "$url_gh" ]; then
        printf '%s\n' "$url_gh"
      elif command -v glab >/dev/null 2>&1; then
        (cd "$REPO_DIR" && glab mr list --source-branch "$ref" --opened --output json 2>/dev/null \
                | jq -r '.[0].web_url // ""' 2>/dev/null) || true
      fi
      ;;
  esac
}

if [ -z "$URL" ] && git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  URL=$(lookup_pr_url_by_head "$BRANCH")

  if [ -z "$URL" ]; then
    # Extract the destination refspec from `git push <url> HEAD:<remote-ref>`.
    # Per-token match; URL tokens like `git@host:path` fail the ref char class.
    DEST_REF=$(printf '%s\n' "$TOOL_CMD" | awk '
      { for (i=1; i<=NF; i++)
          if ($i ~ /^[+]?(HEAD|[[:alnum:]_./-]+):[[:alnum:]_./-]+$/) {
            n = split($i, parts, ":"); print parts[n]
          }
      }' | tail -n1)
    if [ -n "$DEST_REF" ]; then
      echo "trying refspec-based lookup: DEST_REF=$DEST_REF"
      URL=$(lookup_pr_url_by_head "$DEST_REF")
    fi
  fi
fi

if [ -z "$URL" ]; then
  echo "no PR/MR URL resolved -- exiting"
  exit 0
fi
echo "URL: $URL"

case "$URL" in
  *github.com*/pull/*) PLATFORM=github ;;
  */-/merge_requests/*|*/merge_requests/*) PLATFORM=gitlab ;;
  *) echo "unknown platform for URL -- exiting"; exit 0 ;;
esac
echo "PLATFORM: $PLATFORM"

case "$PLATFORM" in
  github)
    if ! command -v gh >/dev/null 2>&1; then echo "gh not on PATH -- exiting"; exit 0; fi
    ;;
  gitlab)
    if ! command -v glab >/dev/null 2>&1; then echo "glab not on PATH -- exiting"; exit 0; fi
    HOST=$(printf '%s' "$URL" | sed -E 's|^https?://([^/]+)/.*$|\1|')
    PROJ_PATH=$(printf '%s' "$URL" | sed -E 's|^https?://[^/]+/(.+)/-/merge_requests/[0-9]+.*$|\1|')
    MR_IID=$(printf '%s' "$URL" | sed -E 's|^.*/merge_requests/([0-9]+).*$|\1|')
    PROJ_PATH_ENC=$(printf '%s' "$PROJ_PATH" | jq -sRr '@uri')
    echo "host=$HOST proj=$PROJ_PATH iid=$MR_IID"
    ;;
esac
export HOST PROJ_PATH_ENC MR_IID

prelude_verify_push "$URL" "$PLATFORM" "$REPO_DIR" || exit 0
prelude_pr_is_open "$URL" || exit 0

REPO_BASENAME=$(basename "$REPO_DIR")
HEAD_SHA=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")
if [ -z "$HEAD_SHA" ]; then
  echo "could not resolve HEAD sha -- exiting"
  exit 0
fi
SHORT_SHA=$(printf '%s' "$HEAD_SHA" | cut -c1-8)

# Recursion guard: any active fixer window for this head sha means the prior
# watcher already handled it.
if command -v tmux >/dev/null 2>&1 && \
   tmux list-windows -a -F '#W' 2>/dev/null \
     | grep -E "^AUTO-(CI|COMMENT)-FIX:${REPO_BASENAME}#${SHORT_SHA}\$" >/dev/null; then
  echo "fixer window for ${REPO_BASENAME}#${SHORT_SHA} already exists -- exiting (recursion guard)"
  exit 0
fi

prelude_acquire_pr_lock "pr-watch" "$URL" || exit 0
echo "LOCK_FILE: $LOCK_FILE (url=$URL sha=$HEAD_SHA)"

# --- Author guard ---
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
  echo "could not resolve PR author or current user -- exiting (fail-closed)"
  exit 0
fi
if [ "$PR_AUTHOR" != "$ME" ]; then
  echo "PR authored by '$PR_AUTHOR', not '$ME' -- exiting (not my PR)"
  exit 0
fi

BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
PR_BRANCH="${BRANCH:-the PR branch}"

# --- Resolve tmux target session (used by both fixers) ---
TARGET_SESSION=""
if command -v tmux >/dev/null 2>&1; then
  if [ -n "${TMUX:-}" ]; then
    TARGET_SESSION=$(tmux display-message -p '#S' 2>/dev/null || true)
  fi
  if [ -z "$TARGET_SESSION" ]; then
    TARGET_SESSION=$(tmux list-sessions -F '#S' 2>/dev/null | head -n1)
  fi
fi
echo "TARGET_SESSION: ${TARGET_SESSION:-<none>}"

# --- "Watching" notification (single, combined) ---
NOTIFY_TITLE="watching CI + comments" \
NOTIFY_BODY="$URL
log: $LOG" \
NOTIFY_SOUND="Pop" \
NOTIFY_URGENCY="low" \
NOTIFY_BG="#f9a825" \
  "$HOME/.claude/hooks/notify.sh" custom || true

export REPO_DIR REPO_BASENAME URL PLATFORM HEAD_SHA SHORT_SHA BRANCH PR_BRANCH \
       TARGET_SESSION LOG LOG_DIR

# --- Run both pipelines in parallel ---
echo "starting ci + comments watches in parallel"
( watch_ci ) &
CI_PID=$!
( watch_comments ) &
COMMENTS_PID=$!
echo "ci pid=$CI_PID comments pid=$COMMENTS_PID"

wait "$CI_PID"        2>/dev/null; CI_RC=$?
wait "$COMMENTS_PID"  2>/dev/null; COMMENTS_RC=$?
echo "ci finished rc=$CI_RC, comments finished rc=$COMMENTS_RC"

exit 0
