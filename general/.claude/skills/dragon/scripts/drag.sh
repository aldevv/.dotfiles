#!/bin/bash
# Usage: drag.sh <file>...
# Opens one dragon window that drags every given file together (--all), stays on top, and closes
# after the drop. Closes any dragon windows still open from earlier calls first, so only the
# current set is on screen. Runs detached so the caller returns right away.
set -euo pipefail

[ $# -gt 0 ] || {
	echo "usage: drag.sh <file>..." >&2
	exit 2
}
command -v dragon >/dev/null || {
	echo "dragon not found on PATH" >&2
	exit 1
}
for f in "$@"; do
	[ -e "$f" ] || {
		echo "missing: $f" >&2
		exit 1
	}
done

for pid in $(ps -eo pid=,comm= | awk '$2 == "dragon" {print $1}'); do
	kill "$pid" 2>/dev/null || true
done

setsid dragon --all --and-exit --on-top "$@" >/dev/null 2>&1 </dev/null &
disown
echo "dragon: $# file(s) ready to drag as one"
