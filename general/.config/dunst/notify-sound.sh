#!/bin/sh
# Dunst rule script: play a notification sound.
# Dunst invokes this as: notify-sound.sh <appname> <summary> <body> <icon> <urgency>
# Notification content is never interpolated into shell, only $5 is read and
# matched against a fixed allowlist. Exits 0 on missing players or theme files
# so dunst keeps working on machines without audio support.

urgency=${5:-NORMAL}

case "$urgency" in
    CRITICAL) event=dialog-warning; file=dialog-warning.oga ;;
    *)        event=message;        file=message.oga ;;
esac

if command -v canberra-gtk-play >/dev/null 2>&1; then
    canberra-gtk-play -i "$event" >/dev/null 2>&1 &
    exit 0
fi

fallback=/usr/share/sounds/freedesktop/stereo/$file
if [ -r "$fallback" ] && command -v paplay >/dev/null 2>&1; then
    paplay "$fallback" >/dev/null 2>&1 &
fi

exit 0
