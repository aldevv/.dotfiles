#!/bin/sh
video=$(ls -t $HOME/Downloads/*.mkv  | sed 's/^.*\///g' | fzf  -i)
[ ! -z "$video" ] && mpv "$HOME/Downloads/$video" 2>/dev/null
