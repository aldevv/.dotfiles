#!/usr/bin/env bash

if command -v pomo &>/dev/null; then
	out="$(pomo)"
	if [ -z "$out" ]; then
		exit 0
	fi
	echo "$out  |"
fi
