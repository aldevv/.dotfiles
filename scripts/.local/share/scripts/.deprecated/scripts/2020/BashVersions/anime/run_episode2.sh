#!/bin/bash
video=$(ls $HOME/Downloads/*mkv  | sed 's/^.*\///g' | dmenu -i -l 30)
[[ -z "$video" ]] || mpv "$HOME/Downloads/$video" 2>/dev/null



