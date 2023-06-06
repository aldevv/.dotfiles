#!/bin/bash
# MUTE=$(pulseaudio-ctl full-status | awk '{print $2}')
# VOLUME=$(pulseaudio-ctl full-status | awk '{print $1}')
#
# if [ "$MUTE" = "yes" ]; then
#     echo "<fc=#696B71><fn=3></fn></fc> "
# elif [ "$VOLUME" -eq 0 ]; then
#     echo "<fc=#696B71><fn=3></fn></fc>   "
# elif [ "$VOLUME" -lt 77 ]; then
#     echo "<fc=#DFDFDF><fn=3></fn></fc>  "
# else
#     echo "<fc=#DFDFDF><fn=3></fn></fc>"
# fi
printf "%s音" $(amixer -D pulse sget Master | awk -F"[][]" '/\[[0-9]/{ print $2 }' | sed 1q | tr -d "%")
