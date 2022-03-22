#!/usr/bin/env bash
selected=$(cat $UTILITIES/tmux/tmux-cht-languages $UTILITIES/tmux/tmux-cht-command | fzf --no-preview)
if [[ -z $selected ]]; then
	exit 0
fi

read -p "Enter Query: " query

if grep -qs "$selected" $UTILITIES/tmux/tmux-cht-languages; then
	query=$(echo $query | tr ' ' '+')
	tmux neww bash -c "echo \"curl cht.sh/$selected/$query/\" & curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
else
	tmux neww bash -c "curl -s cht.sh/$selected~$query | less"
fi
