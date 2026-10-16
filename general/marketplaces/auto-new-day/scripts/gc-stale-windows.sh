#!/usr/bin/env bash
# Close every AUTO-* tmux window created before today, so the sweep never stacks
# more than one day of windows. Before closing, each window's Claude conversations
# are logged (session id, cwd, transcript, resume command) to
# $AUTO_NEW_DAY_STATE_DIR/closed-windows.md so nothing is lost.
#
# A window's creation time is its oldest pane process start (tmux 3.7 has no
# window_created format). Windows whose Claude is still "busy" are kept, as is the
# session holding the calling pane (the sweep itself).
#
# Usage: gc-stale-windows.sh [--dry-run]
# Output: one line per window: closed | kept-busy | would-close
# Exit 0 always (best-effort cleanup; never aborts the sweep).

set -u

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

STATE_DIR="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}"
LOG="$STATE_DIR/closed-windows.md"
SESSIONS_DIR="$HOME/.claude/sessions"
TODAY=$(date +%F)
NOW=$(date +%s)
SELF_SESSION=""
[ -n "${TMUX_PANE:-}" ] && SELF_SESSION=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null)

day_of() { date -d "@$1" +%F 2>/dev/null || date -r "$1" +%F 2>/dev/null; }

# Echo "<sessionId> <status> <cwd>" for the live Claude attached to a tmux pane id.
claude_in_pane() {
  local pane=$1 f pid
  for f in "$SESSIONS_DIR"/*.json; do
    [ -f "$f" ] || continue
    jq -e --arg p ".$pane" '(.tmux // "") | endswith($p)' "$f" >/dev/null 2>&1 || continue
    pid=$(jq -r '.pid' "$f")
    kill -0 "$pid" 2>/dev/null || continue
    jq -r '"\(.sessionId) \(.status // "unknown") \(.cwd)"' "$f"
  done
}

while IFS=$'\t' read -r session win win_id session_created; do
  case "$session" in AUTO-*) ;; *) continue ;; esac
  [ "$session" = "$SELF_SESSION" ] && continue

  oldest=0
  while read -r pane_pid; do
    age=$(ps -o etimes= -p "$pane_pid" 2>/dev/null | tr -d ' ')
    [ -n "$age" ] && [ "$age" -gt "$oldest" ] && oldest=$age
  done < <(tmux list-panes -t "$win_id" -F '#{pane_pid}' 2>/dev/null)
  created=$(( oldest > 0 ? NOW - oldest : session_created ))
  created_day=$(day_of "$created")
  [[ "$created_day" < "$TODAY" ]] || continue

  convs=()
  is_busy=0
  while read -r pane; do
    while read -r sid status cwd; do
      [ -n "$sid" ] || continue
      [ "$status" = "busy" ] && is_busy=1
      transcript=$(ls "$HOME"/.claude/projects/*/"$sid".jsonl 2>/dev/null | head -1)
      convs+=("  - claude \`$sid\` in \`$cwd\`: resume with \`cd $cwd && claude --resume $sid\`; transcript \`${transcript:-not found}\`")
    done < <(claude_in_pane "$pane")
  done < <(tmux list-panes -t "$win_id" -F '#{pane_id}' 2>/dev/null)

  if [ "$is_busy" = 1 ]; then
    echo "kept-busy ${session}:${win}  (created $created_day, claude still busy)"
    continue
  fi
  if [ "$DRY_RUN" = 1 ]; then
    echo "would-close ${session}:${win}  (created $created_day, ${#convs[@]} claude conversation(s))"
    continue
  fi

  mkdir -p "$STATE_DIR"
  {
    echo "- $(date -Iseconds) closed \`${session}:${win}\` (created $created_day)"
    [ ${#convs[@]} -eq 0 ] && echo "  - no live claude conversation in this window"
    printf '%s\n' "${convs[@]}"
  } >> "$LOG"
  tmux kill-window -t "$win_id" 2>/dev/null \
    && echo "closed   ${session}:${win}  (created $created_day, logged to $LOG)" \
    || echo "failed   ${session}:${win}  (kill-window returned non-zero)"
done < <(tmux list-windows -a -F $'#{session_name}\t#{window_name}\t#{window_id}\t#{session_created}' 2>/dev/null)

exit 0
