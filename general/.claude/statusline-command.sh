#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Get git info (skip optional locks to avoid blocking)
git_info=""
if git -C "$cwd" --no-optional-locks rev-parse --git-dir &>/dev/null; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if git -C "$cwd" --no-optional-locks diff-index --quiet HEAD -- 2>/dev/null; then
      status="✓"
    else
      status="✗"
    fi
    git_info="($branch$status)"
  fi
fi

# Build the prompt
# Format: [ <hostname?> pwd: ~/path (git-branch✓) ] model-name
# Hostname only shown when inside an SSH session.

host_segment=""
if [ -n "$SSH_CONNECTION" ]; then
  host_segment=$(printf '\033[1;34mssh:%s \033[0;37m' "$(hostname -s)")
fi

printf '\033[1;34m[ %s\033[0;37mpwd: %s\033[1;32m%s\033[1;34m ] \033[1;37m%s\033[0m' \
  "$host_segment" "$cwd" "$git_info" "$model"
