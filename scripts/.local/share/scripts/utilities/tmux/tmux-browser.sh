#!/usr/bin/env bash

read -r -p "Enter port [3000]: " port
[[ -z $port ]] && port=3000

if command -v brave-browser; then
	brave-browser --new-window "http://localhost:$port"
else
	firefox --new-window "localhost:$port"
fi
