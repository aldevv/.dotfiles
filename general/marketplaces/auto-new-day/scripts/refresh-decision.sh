#!/usr/bin/env bash
# Decide what to do about an existing window in one of the AUTO-* dispatch
# sessions (AUTO-inreview, AUTO-inprogress, AUTO-inreview-others)
# given the state snapshot recorded at the last dispatch vs the current state.
#
# The four possible decisions:
#   dispatch     window does not exist; spawn fresh (caller falls through to
#                tmux-dispatch.sh).
#   skip         window exists, nothing meaningful has changed since the
#                snapshot was taken.
#   poke         window exists, child claude is still running in the pane,
#                and new comments/reviews have arrived since the snapshot.
#                Caller rewrites the dispatch JSON and sends a follow-up
#                user-turn into the pane with `tmux send-keys`.
#   replace     window exists, child claude has exited (pane is a shell)
#                AND something changed (sha or feedback). Caller kills the
#                window and falls through to tmux-dispatch.sh for a clean
#                re-spawn.
#
# A SHA change WITHOUT new feedback while claude is running is treated as
# claude's own progress and produces `skip`. We never interrupt a working
# child for its own commits.
#
# Usage:
#   refresh-decision.sh \
#     --session SESSION --window WIN \
#     [--snapshot-sha SHA] \
#     [--snapshot-pr-comment-at ISO] \
#     [--snapshot-pr-review-at ISO] \
#     [--snapshot-linear-comment-at ISO] \
#     [--current-sha SHA] \
#     [--current-pr-comment-at ISO] \
#     [--current-pr-review-at ISO] \
#     [--current-linear-comment-at ISO]
#
# Empty / unset snapshot fields are treated as "epoch" (everything counts as
# newer). Empty current fields are treated as "no data" (nothing to compare).
# ISO timestamps are compared lexicographically — RFC 3339 / ISO 8601 sort
# correctly that way as long as both sides use the same offset format.
#
# Output (single line on stdout):
#   dispatch
#   skip      <reason>
#   poke      <reason>
#   replace   <reason>
# Always exits 0; errors print to stderr and fall back to `skip` (safer than
# accidentally clobbering work on a tmux glitch).

set -u

SESSION=""
WIN=""
S_SHA=""
S_PR_COMMENT=""
S_PR_REVIEW=""
S_LINEAR_COMMENT=""
C_SHA=""
C_PR_COMMENT=""
C_PR_REVIEW=""
C_LINEAR_COMMENT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --session)                   shift; SESSION=${1:-} ;;
    --window)                    shift; WIN=${1:-} ;;
    --snapshot-sha)              shift; S_SHA=${1:-} ;;
    --snapshot-pr-comment-at)    shift; S_PR_COMMENT=${1:-} ;;
    --snapshot-pr-review-at)     shift; S_PR_REVIEW=${1:-} ;;
    --snapshot-linear-comment-at) shift; S_LINEAR_COMMENT=${1:-} ;;
    --current-sha)               shift; C_SHA=${1:-} ;;
    --current-pr-comment-at)     shift; C_PR_COMMENT=${1:-} ;;
    --current-pr-review-at)      shift; C_PR_REVIEW=${1:-} ;;
    --current-linear-comment-at) shift; C_LINEAR_COMMENT=${1:-} ;;
    *) echo "refresh-decision.sh: unknown arg: $1" >&2; echo "skip  (bad-args)"; exit 0 ;;
  esac
  shift
done

if [ -z "$SESSION" ] || [ -z "$WIN" ]; then
  echo "refresh-decision.sh: missing --session or --window" >&2
  echo "skip  (bad-args)"; exit 0
fi

# Does the window exist?
if ! tmux has-session -t "$SESSION" 2>/dev/null \
     || ! tmux list-windows -t "$SESSION" -F '#{window_name}' 2>/dev/null | grep -qx "$WIN"; then
  echo "dispatch"
  exit 0
fi

# Compare snapshot vs current. Empty snapshot string = epoch (anything is newer).
# Empty current string = "we don't have current data for this signal"; ignore.
is_newer() {  # $1=current, $2=snapshot
  local cur=$1 snap=$2
  [ -n "$cur" ] || return 1
  [ -n "$snap" ] || return 0     # snapshot empty + current present = newer
  [ "$cur" \> "$snap" ]
}

feedback_changed=0
reason_parts=()
if is_newer "$C_PR_COMMENT" "$S_PR_COMMENT"; then
  feedback_changed=1; reason_parts+=("pr-comment $C_PR_COMMENT")
fi
if is_newer "$C_PR_REVIEW" "$S_PR_REVIEW"; then
  feedback_changed=1; reason_parts+=("pr-review $C_PR_REVIEW")
fi
if is_newer "$C_LINEAR_COMMENT" "$S_LINEAR_COMMENT"; then
  feedback_changed=1; reason_parts+=("linear-comment $C_LINEAR_COMMENT")
fi

sha_changed=0
if [ -n "$C_SHA" ] && [ -n "$S_SHA" ] && [ "$C_SHA" != "$S_SHA" ]; then
  sha_changed=1
  reason_parts+=("sha $S_SHA->$C_SHA")
fi

# Probe pane state in a single tmux call.
# Fields:
#   pane_current_command  - does it contain "claude"? -> child still running
#   pane_in_mode          - 1 when operator is in copy/search/scroll mode; don't disturb
#   pane_pid              - foreground process pid (for pane_activity_age math below)
pane_state=$(tmux list-panes -t "${SESSION}:${WIN}" \
  -F '#{pane_current_command}|#{pane_in_mode}|#{pane_pid}' 2>/dev/null | head -n1)
pane_cmd=${pane_state%%|*}
rest=${pane_state#*|}
pane_in_mode=${rest%%|*}
pane_pid=${rest##*|}

case "$pane_cmd" in
  *claude*) child_running=1 ;;
  *)        child_running=0 ;;
esac

# Recent operator activity (seconds since the pane's foreground process started
# accepting input). When the operator has been typing in the fallback shell
# within the last 60s, bail out of any destructive action -- their work would
# be lost on kill-window.
activity_age=999999
if [ -n "$pane_pid" ] && [ "$pane_pid" -gt 0 ] 2>/dev/null; then
  started=$(ps -o lstart= -p "$pane_pid" 2>/dev/null)
  if [ -n "$started" ]; then
    started_epoch=$(date -d "$started" +%s 2>/dev/null || echo "")
    if [ -n "$started_epoch" ]; then
      activity_age=$(( $(date +%s) - started_epoch ))
    fi
  fi
fi

reason="${reason_parts[*]:-no-change}"

if [ "$child_running" = 1 ]; then
  if [ "$feedback_changed" = 1 ]; then
    if [ "$pane_in_mode" = "1" ]; then
      echo "skip  $reason (child running, pane in copy/search mode)"
    else
      echo "poke  $reason"
    fi
  else
    # Either nothing changed, or only sha (claude's own progress). Don't disturb.
    echo "skip  $reason (child running)"
  fi
else
  if [ "$feedback_changed" = 1 ] || [ "$sha_changed" = 1 ]; then
    if [ "$activity_age" -lt 60 ] 2>/dev/null; then
      echo "skip  $reason (child exited but operator activity within ${activity_age}s)"
    else
      echo "replace  $reason (child exited)"
    fi
  else
    echo "skip  $reason"
  fi
fi
