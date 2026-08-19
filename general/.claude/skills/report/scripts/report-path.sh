#!/usr/bin/env bash
# $1=ticket-slug (e.g. ITH-500951-start-500)
# Creates the folder and prints $HOME/reports/<date>/[<status>/]<slug>/report-<N>.md
#
# Under an auto-new-day dispatch session the folder carries a status segment from
# the session name (AUTO-inreview -> inreview), so the tree doubles as a board.
# Normal operator sessions get no status segment.

set -uo pipefail

slug=${1:?usage: report-path.sh <ticket-slug>}
root="$HOME/reports/$(date +%F)"

STATUSES=(inprogress inreview inreview-others ready-to-merge)

session=$(tmux display-message -p '#S' 2>/dev/null || true)
status=""
for s in "${STATUSES[@]}"; do
	[[ $session == "AUTO-$s" ]] && status=$s && break
done
# Dispatched but tmux name unreadable: assume the earliest stage rather than
# silently dropping the report into the operator-session layout.
[[ -z $status && -n ${AUTO_NEW_DAY_DATE_DIR:-} ]] && status=inprogress

if [[ -n $status ]]; then
	dest="$root/$status/$slug"
	# One folder per ticket per day. When the stage advances, carry the existing
	# reports along instead of starting a second folder somewhere else. If both
	# locations somehow exist, leave them alone and let the operator reconcile.
	if [[ ! -d $dest ]]; then
		for s in "${STATUSES[@]}"; do
			[[ $s == "$status" ]] && continue
			if [[ -d "$root/$s/$slug" ]]; then
				mkdir -p "$(dirname "$dest")"
				mv "$root/$s/$slug" "$dest"
				break
			fi
		done
	fi
else
	dest="$root/$slug"
fi

mkdir -p "$dest"

n=1
while [[ -e "$dest/report-$n.md" ]]; do n=$((n + 1)); done
echo "$dest/report-$n.md"
