#!/usr/bin/env bash
[ -n "$TMUX_PANE" ] || exit 0
w=$(tmux display-message -p -t "$TMUX_PANE" '#{?window_active,,#{window_id}}' 2>/dev/null)
[ -n "$w" ] && tmux set-option -w -t "$w" @claude-done 1 >/dev/null 2>&1
exit 0
