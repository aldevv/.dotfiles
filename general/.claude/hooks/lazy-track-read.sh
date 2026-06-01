#!/usr/bin/env bash
# PostToolUse hook for Read.
#
# When Claude reads a file under any `.claude/lazy/` directory, drop a marker
# in ~/.cache/claude-lazy-reminder/<session_id>/ so the PreToolUse reminder
# can skip it on subsequent Write/Edit calls.
set -euo pipefail

input=$(cat)

[[ "$input" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] || exit 0
sid="${BASH_REMATCH[1]}"

[[ "$input" =~ \"file_path\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] || exit 0
fp="${BASH_REMATCH[1]}"

# Only track files under a .claude/lazy/ directory.
[[ "$fp" == *"/.claude/lazy/"* ]] || exit 0

state_dir="$HOME/.cache/claude-lazy-reminder/$sid"
[[ -f "$state_dir" ]] && rm -f "$state_dir"
mkdir -p "$state_dir"
: > "$state_dir/${fp//\//_}"
