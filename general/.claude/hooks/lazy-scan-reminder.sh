#!/usr/bin/env bash
# PreToolUse hook for Write / Edit / NotebookEdit.
#
# Tracks which lazy files (under any .claude/lazy/ in scope) Claude has loaded
# this session. Reminder fires while at least one lazy file is still unloaded,
# and lists the unloaded ones so the next edit can pull them in if a trigger
# applies. PostToolUse (lazy-track-read.sh) records loads; PreCompact
# (lazy-scan-reset.sh) wipes the per-session state.
#
# Scope: walk cwd -> / collecting every `.claude/lazy/**/*.md`, plus
# $HOME/.claude/lazy if cwd is outside $HOME.
set -euo pipefail

input=$(cat)

if [[ "$input" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  sid="${BASH_REMATCH[1]}"
else
  sid="unknown"
fi

if [[ "$input" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  cwd="${BASH_REMATCH[1]}"
else
  cwd="$PWD"
fi

state_dir="$HOME/.cache/claude-lazy-reminder/$sid"

# Migration: legacy state was a regular file at this path. Promote to a dir.
[[ -f "$state_dir" ]] && rm -f "$state_dir"

# Enumerate lazy files via ancestor walk from cwd.
lazy_files=()
dir="$cwd"
seen_home=0
while [[ -n "$dir" && "$dir" != "/" ]]; do
  if [[ -d "$dir/.claude/lazy" ]]; then
    while IFS= read -r f; do
      lazy_files+=("$f")
    done < <(find -L "$dir/.claude/lazy" -type f -name '*.md' 2>/dev/null)
  fi
  [[ "$dir" == "$HOME" ]] && seen_home=1
  dir="${dir%/*}"
done
# Include global lazy dir if the walk didn't already cover it.
if [[ $seen_home -eq 0 && -d "$HOME/.claude/lazy" ]]; then
  while IFS= read -r f; do
    lazy_files+=("$f")
  done < <(find -L "$HOME/.claude/lazy" -type f -name '*.md' 2>/dev/null)
fi

# Compute unloaded set. Marker file name = path with "/" -> "_".
unloaded=()
for f in "${lazy_files[@]}"; do
  marker="${f//\//_}"
  [[ -f "$state_dir/$marker" ]] && continue
  unloaded+=("$f")
done

# Fast exit when everything is loaded.
[[ ${#unloaded[@]} -eq 0 ]] && exit 0

# Slow path.
mkdir -p "$state_dir"

# GC stale session dirs (>7 days).
find "$HOME/.cache/claude-lazy-reminder" -mindepth 1 -maxdepth 1 -type d -mtime +7 \
  -exec rm -rf {} + 2>/dev/null || true

list=""
for f in "${unloaded[@]}"; do
  list+="- $f"$'\n'
done

read -r -d '' MSG <<EOF || true
PRE-EDIT REMINDER: these lazy files have NOT been loaded in this session yet. For each one, check its **Read when** clause in the relevant CLAUDE.md (global ~/CLAUDE.md plus any project / ancestor-walk CLAUDE.md / CLAUDE.local.md) and load it if its trigger fires on the current work:
$list
After a compaction summary, treat every lazy file as evicted and re-read every triggered file, the summary preserves the fact of reading, not the content.
EOF

jq -c -n --arg msg "$MSG" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $msg}}'
