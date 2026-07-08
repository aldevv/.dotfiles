#!/usr/bin/env bash
# open-qa-pane.sh <file>
# Open <file> in the operator's editor for an editable Q&A / draft review.
# Inside tmux: split a sibling pane next to the caller. Outside tmux: launch a
# fresh $TERMINAL window running the editor. Reuses an existing pane if one is
# already showing this file (so a caller can append blocks and re-open without
# spawning a second pane). The file path must not contain spaces (callers
# generate it under /tmp, so this holds).
set -euo pipefail

file="${1:?usage: open-qa-pane.sh <file>}"
editor="${VISUAL:-${EDITOR:-nvim}}"

# marker keyed on the file path so a repeat call for the same file reuses the pane
marker_dir="${TMPDIR:-/tmp}/qa-panes"
mkdir -p "$marker_dir"
key=$(printf '%s' "$file" | cksum | awk '{print $1}')
marker="$marker_dir/$key"

if [ -n "${TMUX:-}" ]; then
	# TMUX_PANE anchors every call on the caller's pane, not the operator's current view
	anchor="${TMUX_PANE:?TMUX set but TMUX_PANE empty}"

	# already open this session? focus it and stop.
	if [ -f "$marker" ]; then
		existing=$(cat "$marker")
		if tmux list-panes -a -F '#{pane_id}' | grep -qx "$existing"; then
			tmux select-pane -t "$existing" 2>/dev/null || true
			echo "reused pane $existing"
			exit 0
		fi
	fi

	# where to land: if a pane already sits to the caller's right (an A|B layout
	# with the caller as A), stack qa on top of that right pane B so the caller
	# keeps full height. Otherwise open a fresh right-hand pane at 70%.
	read -r caller_right window_width < <(tmux display-message -t "$anchor" -p '#{pane_right} #{window_width}')
	if [ "$caller_right" -lt "$((window_width - 1))" ]; then
		# pick pane B: the one just past the caller's right edge (smallest pane_left
		# greater than caller_right; tie-break to the topmost). Robust to border width.
		right_pane=$(tmux list-panes -t "$anchor" -F '#{pane_left} #{pane_top} #{pane_id}' |
			awk -v cr="$caller_right" '$1 > cr {print $1, $2, $3}' |
			sort -n -k1,1 -k2,2 | head -1 | awk '{print $3}')
		if [ -n "$right_pane" ]; then
			# -b puts the new pane above B; qa on top, B below.
			new_pane=$(tmux split-window -v -b -l 60% -t "$right_pane" -P -F '#{pane_id}' "$editor $file")
		else
			new_pane=$(tmux split-window -v -l 60% -t "$anchor" -P -F '#{pane_id}' "$editor $file")
		fi
	else
		new_pane=$(tmux split-window -h -l 70% -t "$anchor" -P -F '#{pane_id}' "$editor $file")
	fi
	printf '%s' "$new_pane" >"$marker"
	echo "opened pane $new_pane"
	exit 0
fi

# not in tmux: open the editor in a fresh terminal window.
term="${TERMINAL:-}"
if [ -z "$term" ]; then
	echo "not in tmux and \$TERMINAL is unset; open $file in your editor manually" >&2
	exit 3
fi
# -e (run this command) is honored by kitty, alacritty, xterm, urxvt, and friends.
# setsid + background detaches it so this script returns immediately.
setsid "$term" -e "$editor" "$file" >/dev/null 2>&1 &
echo "launched $term with $editor $file"
