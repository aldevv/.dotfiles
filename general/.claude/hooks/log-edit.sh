#!/usr/bin/env bash
# PostToolUse hook for Write|Edit|NotebookEdit.
# Records every file modification to ~/.cache/agent-edits/log.tsv (override
# with $AGENT_EDITS_LOG) so the `agent-edits` CLI can fzf-pick across recent
# edits. Backgrounds the work
# (including the git branch resolve) so Claude isn't blocked on the hook.
#
# Log columns (tab-separated):
#   1. unix timestamp
#   2. session id
#   3. git branch at edit time (empty if not in a repo)
#   4. claude cwd
#   5. absolute file path
set -euo pipefail

input=$(cat)

{
  [[ "$input" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] || exit 0
  sid="${BASH_REMATCH[1]}"

  if [[ "$input" =~ \"file_path\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    fp="${BASH_REMATCH[1]}"
  elif [[ "$input" =~ \"notebook_path\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    fp="${BASH_REMATCH[1]}"
  else
    exit 0
  fi

  if [[ "$input" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    cwd="${BASH_REMATCH[1]}"
  else
    cwd=""
  fi

  branch=$(git -C "$(dirname "$fp")" branch --show-current 2>/dev/null || true)
  ts=$(date +%s)

  log="${AGENT_EDITS_LOG:-$HOME/.cache/agent-edits/log.tsv}"
  mkdir -p "$(dirname "$log")"
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$sid" "$branch" "$cwd" "$fp" >> "$log"
} </dev/null >/dev/null 2>&1 &
disown
exit 0
