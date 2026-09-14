#!/usr/bin/env bash
#
# Print the current Claude Code session (conversation) id.
#
# There is no env var for the session id during an interactive run, but the
# active conversation is the transcript being appended to right now, so the
# newest .jsonl in this cwd's project dir is the current session. Its filename
# (minus .jsonl) is the id.
set -euo pipefail

# honor CLAUDE_CONFIG_DIR override; default ~/.claude
cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Claude Code slugs the cwd by turning every non-alphanumeric char into '-'
slug=$(pwd | sed 's/[^a-zA-Z0-9]/-/g')
dir="$cfg/projects/$slug"

# newest transcript = current session
newest=$(ls -t "$dir"/*.jsonl 2>/dev/null | head -1 || true)
if [[ -z "$newest" ]]; then
	echo "show-id: no session transcript found for $(pwd)" >&2
	echo "show-id: checked $dir (are you inside a Claude Code session here?)" >&2
	exit 1
fi

basename "$newest" .jsonl
