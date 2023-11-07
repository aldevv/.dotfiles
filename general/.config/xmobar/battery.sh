#!/bin/bash

charging=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep state | cut -d: -f2 | tr -d " ")
battery="$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | awk '/percentage/{print $2}' | tr -d '%\n')"
if [[ $charging == "charging" || $charging == "pending-charge" ]]; then charge_symbol="充電"; else charge_symbol="放電"; fi

echo "${battery}${charge_symbol}"

if [[ $battery =~ ^[0-9]$ ]] && [[ $charging != "charging" ]]; then
	notify-send "Low Battery☄️"
fi
