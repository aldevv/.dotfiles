#!/usr/bin/env bash

read -r -p "Enter port [3000]: " port
[[ -z $port ]] && port=3000

if command -v brave-browser; then
	setsid brave-browser --new-window "http://localhost:$port" &>/dev/null
else
	setsid firefox --new-window "localhost:$port" &>/dev/null
fi
