#!/usr/bin/env bash
out="$(pomo-notify)"
if [ -z "$out" ]; then
  exit 0
fi
echo "$out  |"
