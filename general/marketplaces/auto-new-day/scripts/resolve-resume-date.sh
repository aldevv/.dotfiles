#!/usr/bin/env bash
# resolve-resume-date.sh
# Print the date (YYYY-MM-DD) of the most recent saved dispatch plan so
# `--resume` can replay it without the operator remembering which day it was.
#
# Looks for $STATE_DIR/dates/<DATE>-create.md, ignoring the dry-run copies
# (<DATE>-dryrun-create.md), and prints the newest DATE to stdout (exit 0).
# Prints an actionable message to stderr and exits 1 when no plan exists.
#
# STATE_DIR comes from $AUTO_NEW_DAY_STATE_DIR, else the default state dir.
#
#   --self-check   run an in-temp-dir assertion of the pick logic, then exit.

set -u

STATE_DIR="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}"

# Print the newest non-dry-run create.md date under $1/dates, or nothing.
latest_plan_date() {
	local dates_dir=$1/dates
	[ -d "$dates_dir" ] || return 0
	# List real (non-dryrun) create.md files, strip to the YYYY-MM-DD prefix,
	# sort lexically (ISO dates sort chronologically), take the newest.
	find "$dates_dir" -maxdepth 1 -name '*-create.md' ! -name '*-dryrun-create.md' -printf '%f\n' 2>/dev/null |
		sed -n 's/^\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)-create\.md$/\1/p' |
		sort |
		tail -n 1
}

if [ "${1:-}" = "--self-check" ]; then
	tmp=$(mktemp -d)
	trap 'rm -rf "$tmp"' EXIT
	mkdir -p "$tmp/dates"
	touch "$tmp/dates/2026-08-31-create.md" \
		"$tmp/dates/2026-09-10-create.md" \
		"$tmp/dates/2026-09-10-dryrun-create.md" \
		"$tmp/dates/2026-11-02-dryrun-create.md"
	got=$(latest_plan_date "$tmp")
	[ "$got" = "2026-09-10" ] || {
		echo "self-check FAILED: expected 2026-09-10, got '$got'" >&2
		exit 1
	}
	[ -z "$(latest_plan_date "$tmp/empty")" ] || {
		echo "self-check FAILED: missing dir should print nothing" >&2
		exit 1
	}
	echo "self-check OK"
	exit 0
fi

DATE=$(latest_plan_date "$STATE_DIR")
if [ -z "$DATE" ]; then
	echo "ERROR: no saved dispatch plan found under $STATE_DIR/dates/ (nothing to resume)." >&2
	exit 1
fi
echo "$DATE"
