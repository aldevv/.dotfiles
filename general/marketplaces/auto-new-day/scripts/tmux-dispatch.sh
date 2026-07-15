#!/usr/bin/env bash
# Spawn (or skip) one auto-new-day dispatch window inside the given tmux session.
# Dedupes by window name. Creates the session on the first window of the sweep,
# adds windows to it for subsequent calls. After spawning, types the slash
# invocation into claude so the child runs immediately.
#
# Usage:
#   tmux-dispatch.sh <session> <window-name> <cwd> <bootstrap-cmd> <slash-invocation> [--log <path>]
#
# Args:
#   session          tmux session name (e.g. AUTO-inreview).
#   window-name      unique window name within the session.
#   cwd              working directory for the new window.
#   bootstrap-cmd    bash command run as the window's pane command. Should
#                    end by `exec`ing an interactive shell so the pane stays
#                    open after the bootstrap finishes.
#   slash-invocation full claude invocation including --dangerously-skip-permissions
#                    and the "/<skill> ..." argv, e.g.
#                    `claude --dangerously-skip-permissions "/fix-bug ..."`.
#   --log <path>     (optional) `tmux pipe-pane` the new window's output to
#                    <path> so the operator can `tail -F` instead of attaching.
#                    Parent dir is created if missing. Ignored when the window
#                    already exists (skipped path).
#
# Outputs one status line on stdout:
#   spawned     # new session or new window created and slash command sent
#   skipped     # window already exists in the session; nothing changed
#   failed: ... # tmux operation returned non-zero; reason follows

set -u

SESSION=""
WIN_NAME=""
CWD=""
BOOTSTRAP_CMD=""
SLASH_INVOCATION=""
LOG_PATH=""
positional=()
while [ $# -gt 0 ]; do
  case "$1" in
    --log) shift; LOG_PATH=${1:-} ;;
    *)     positional+=("$1") ;;
  esac
  shift
done
SESSION=${positional[0]:-}
WIN_NAME=${positional[1]:-}
CWD=${positional[2]:-}
BOOTSTRAP_CMD=${positional[3]:-}
SLASH_INVOCATION=${positional[4]:-}

die() { echo "failed: $*"; exit 1; }
[ -n "$SESSION" ]          || die "missing <session>"
[ -n "$WIN_NAME" ]         || die "missing <window-name>"
[ -n "$CWD" ]              || die "missing <cwd>"
[ -n "$BOOTSTRAP_CMD" ]    || die "missing <bootstrap-cmd>"
[ -n "$SLASH_INVOCATION" ] || die "missing <slash-invocation>"

# session existence + per-window dedupe
session_exists=0
tmux has-session -t "$SESSION" 2>/dev/null && session_exists=1

if [ "$session_exists" = 1 ] && tmux list-windows -t "$SESSION" -F '#{window_name}' | grep -qx "$WIN_NAME"; then
  echo "skipped"
  exit 0
fi

# spawn
if [ "$session_exists" = 0 ]; then
  tmux new-session -d -s "$SESSION" -n "$WIN_NAME" -c "$CWD" "$BOOTSTRAP_CMD" \
    || die "tmux new-session $SESSION:$WIN_NAME"
else
  tmux new-window -t "${SESSION}:" -n "$WIN_NAME" -c "$CWD" "$BOOTSTRAP_CMD" \
    || die "tmux new-window $SESSION:$WIN_NAME"
fi

# Pipe the pane's output to a per-window log so the operator can tail -F
# instead of attaching. Truncate (`cat >`) on a fresh spawn so multi-day
# same-named windows don't grow without bound; the skip path bails earlier,
# so an existing window's log is never touched here.
if [ -n "$LOG_PATH" ]; then
  mkdir -p "$(dirname "$LOG_PATH")"
  tmux pipe-pane -o -t "${SESSION}:${WIN_NAME}" "cat > '$LOG_PATH'" \
    || die "tmux pipe-pane $SESSION:$WIN_NAME -> $LOG_PATH"
fi

# Brief wait so send-keys doesn't fire before the pane's shell prompt is ready.
sleep 0.3

# Launch the slash command. The invocation must already be fully quoted by
# the caller — passing it through send-keys verbatim avoids the bracketed-
# paste race that a two-step type-then-Enter sequence introduces.
tmux send-keys -t "${SESSION}:${WIN_NAME}" "$SLASH_INVOCATION" C-m \
  || die "tmux send-keys $SESSION:$WIN_NAME"

echo "spawned"
