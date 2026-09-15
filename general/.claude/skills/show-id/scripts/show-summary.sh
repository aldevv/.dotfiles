#!/usr/bin/env bash
#
# Print a conversation's id and its summary on two lines:
#   <session-id>
#   <summary>
#
# With no argument it resolves the id like show-id (current session when one is
# live / non-interactive, else an fzf picker of past conversations). With an
# explicit <id> it skips the picker and summarizes that conversation directly.
set -euo pipefail

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
. "$(dirname "$self")/lib.sh"

maybe_preview "$@"

if [ -n "${1:-}" ]; then
	id=$1
	[ -f "$dir/$id.jsonl" ] || {
		echo "show-summary: no conversation $id for $(pwd) (checked $dir)" >&2
		exit 1
	}
else
	# Compute interactivity here, in the top-level shell, so it reflects the real
	# stdout (a terminal vs a pipe) rather than resolve_id's captured stdout.
	interactive=0
	[ -t 1 ] && interactive=1

	id=$(resolve_id "$interactive") || {
		echo "show-summary: no conversations found for $(pwd)" >&2
		echo "show-summary: checked $dir (are you inside a Claude Code project dir?)" >&2
		exit 1
	}
	[ -n "$id" ] || exit 0 # picker cancelled
fi

printf '%s\n%s\n' "$id" "$(summary_for "$id")"
