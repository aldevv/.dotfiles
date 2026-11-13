#!/bin/bash

# https://rmsol.de/2020/05/08/zoom-i3block-dnd/

# MS Teams by changing the xwininfo name to "teams.microsoft.com is sharing your screen."

if xwininfo -name as_toolbar >/dev/null 2>&1 || xwininfo -name "teams.microsoft.com" >/dev/null 2>&1; then
	if ! [ -f "/tmp/zoom.lock" ]; then
		touch /tmp/zoom.lock
		notify-send -u "low" -t 3000 Zoom "Sharing mode activated"
		# for notification to appear, sleep
		sleep 6
		dunstctl set-paused true
	fi
else
	if [ -f "/tmp/zoom.lock" ]; then
		rm /tmp/zoom.lock
		dunstctl set-paused false
	fi
fi

# Claude icon: orange while Claude "Done" notifications are on, grey when muted.
# Left click toggles them (notify.sh toggle-done), right click pops dunst history.
if [[ -e "${XDG_CACHE_HOME:-$HOME/.cache}/claude-notify/done-muted" ]]; then
	icon="claude_off.xpm"
else
	icon="claude_on.xpm"
fi

echo '<action=`'"$HOME"'/.claude/hooks/notify.sh toggle-done` button=1><action=`dunstctl history-pop` button=3><icon='"${icon}"'/></action></action>'
