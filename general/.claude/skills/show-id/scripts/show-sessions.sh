#!/usr/bin/env bash
#
# List this directory's Claude Code conversations, newest first, one per line:
#   <session-id><TAB><date>  <title>
#
# Same rows the fzf picker shows, but printed plainly so it's greppable — handy
# for finding a past conversation in a folder without an interactive picker.
set -euo pipefail

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
. "$(dirname "$self")/lib.sh"

rows=$(list_sessions)
if [ -z "$rows" ]; then
	echo "show-sessions: no conversations found for $(pwd)" >&2
	echo "show-sessions: checked $dir (are you inside a Claude Code project dir?)" >&2
	exit 1
fi
printf '%s\n' "$rows"
