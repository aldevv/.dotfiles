#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
week_resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Get git info (skip optional locks to avoid blocking)
git_info=""
if git -C "$cwd" --no-optional-locks rev-parse --git-dir &>/dev/null; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    green=$'\033[1;32m'
    red=$'\033[1;31m'
    if git -C "$cwd" --no-optional-locks diff-index --quiet HEAD -- 2>/dev/null; then
      status_seg="${green}✓"
    else
      status_seg="${red}✗"
    fi
    sync_seg=""
    if git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' &>/dev/null; then
      counts=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
      if [ -n "$counts" ]; then
        behind=${counts%%$'\t'*}
        ahead=${counts##*$'\t'}
        if [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ]; then
          sync_seg="${red}⇅"
        elif [ "${ahead:-0}" -gt 0 ]; then
          sync_seg="${red}↑${ahead}"
        elif [ "${behind:-0}" -gt 0 ]; then
          sync_seg="${red}↓${behind}"
        fi
      fi
    else
      sync_seg="${red}?"
      [ "$status_seg" = "${green}✓" ] && status_seg=""
    fi
    git_info="(${branch}${status_seg}${sync_seg}${green})"
  fi
fi

# Build the prompt
# Format: [ <hostname?> pwd: ~/path (git-branch✓) ] model-name
# Hostname only shown when inside an SSH session.

host_segment=""
if [ -n "$SSH_CONNECTION" ]; then
  host_segment=$(printf '\033[1;34mssh:%s \033[0;37m' "$(hostname -s)")
fi

week_segment=""
if [ -n "$week_pct" ]; then
  reset_suffix=""
  if [ -n "$week_resets_at" ]; then
    days_left=$(( (week_resets_at - $(date +%s) + 86399) / 86400 ))
    [ "$days_left" -lt 0 ] && days_left=0
    reset_suffix=$(printf ' resets in %sd' "$days_left")
  fi
  week_segment=$(printf ' \033[0;37m%s%%%s' "$week_pct" "$reset_suffix")
fi

printf '\033[1;34m[ %s\033[0;37mpwd: %s\033[1;32m%s\033[1;34m ] \033[1;37m%s%s\033[0m' \
  "$host_segment" "$cwd" "$git_info" "$model" "$week_segment"
