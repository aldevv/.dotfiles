#!/bin/sh
cd "$SCRIPTS"
# name=$(fzf --layout=reverse)

name=$(fd . -t f $APPS $UTILITIES $AUTOMATION $OS/Build-Programs/ | fzf --preview='bat --color always {}')
[ -n "$name" ] && nvim "$name"
