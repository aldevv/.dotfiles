#!/usr/bin/env bash

read -r -p "Enter port [3000]: " port
[[ -z $port ]] && port=3000
firefox --new-window "localhost:$port"
