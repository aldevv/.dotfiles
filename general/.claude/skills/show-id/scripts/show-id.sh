#!/usr/bin/env bash
#
# Print the current Claude Code session id, OR — when run from a plain
# interactive terminal with no live session in this directory — open an fzf
# picker of past conversations and print the chosen one's id.
#
# "Current" works because the active conversation is the transcript being
# appended to right now, so the newest .jsonl in this cwd's project dir is it.
set -euo pipefail

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
. "$(dirname "$self")/lib.sh"

maybe_preview "$@"

# Compute interactivity here, in the top-level shell, so it reflects the real
# stdout (a terminal vs a pipe) rather than resolve_id's captured stdout.
interactive=0
[ -t 1 ] && interactive=1

id=$(resolve_id "$interactive") || {
	echo "show-id: no conversations found for $(pwd)" >&2
	echo "show-id: checked $dir (are you inside a Claude Code project dir?)" >&2
	exit 1
}
[ -n "$id" ] || exit 0 # picker cancelled

printf '%s\n' "$id"
