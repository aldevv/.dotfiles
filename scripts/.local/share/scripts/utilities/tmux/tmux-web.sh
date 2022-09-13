#!/bin/bash

read -r -p "Enter Query: " query

tmux neww bash -c "$UTILITIES/search/? $query"
tmux swap-window -t -1
