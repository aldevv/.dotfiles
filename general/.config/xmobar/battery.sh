#!/bin/bash

battery="$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | awk '/percentage/{print $2}' | tr -d '%\n')$(if [[ $charging == 'charging' ]]; then echo '充電'; else echo '放電'; fi)"
charging=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep state | cut -d: -f2 | tr -d " ")
if [[ $battery =~ ^[0-9]電 ]] && [[ $charging != "charging" ]]; then notify-send "Low Battery"; fi
echo "$battery"
