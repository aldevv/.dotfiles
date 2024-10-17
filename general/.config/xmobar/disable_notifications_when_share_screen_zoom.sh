#!/bin/bash

# https://rmsol.de/2020/05/08/zoom-i3block-dnd/

# MS Teams by changing the xwininfo name to "teams.microsoft.com is sharing your screen."

if xwininfo -name as_toolbar >/dev/null 2>&1 || xwininfo -name "teams.microsoft.com" >/dev/null 2>&1; then
  if ! [ -f "/tmp/zoom.lock" ]; then
    touch /tmp/zoom.lock
    notify-send -u "low" -t 3000 Zoom "Sharing mode activated"
    # for notification to appear, sleep
    sleep 3
    dunstctl set-paused true
    echo ""
  else
    echo ""
  fi

else
  if [ -f "/tmp/zoom.lock" ]; then
    rm /tmp/zoom.lock
    dunstctl set-paused false
  fi
  echo ""
fi
