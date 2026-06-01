#!/usr/bin/env bash
# PreCompact hook. Wipes the per-session lazy-load tracking state so that the
# first Write/Edit after the compaction summary re-fires the reminder with the
# full unloaded set (every lazy file is effectively evicted from context).
set -euo pipefail

input=$(cat)

[[ "$input" =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] || exit 0
rm -rf "$HOME/.cache/claude-lazy-reminder/${BASH_REMATCH[1]}"
