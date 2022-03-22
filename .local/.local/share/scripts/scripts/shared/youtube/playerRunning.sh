#!/bin/sh
running=$([[ -z $(pgrep mpv) ]] && echo 1 || echo 0)
echo $running
