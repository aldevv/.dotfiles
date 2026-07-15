#!/usr/bin/env bash
# resolve-date.sh
# Parse a free-form date phrase ("today", "yesterday", "june 16", "2026-06-16",
# "last friday", "2 days ago") into a canonical YYYY-MM-DD.
#
# Prints the resolved date to stdout on success (exit 0).
# On parse failure, prints an actionable error to stderr and exits 1.
# Bare invocation (no args) prints TODAY (so callers can default cleanly).

set -u

PHRASE="${*:-}"
TODAY=$(date +%Y-%m-%d)

if [ -z "$PHRASE" ]; then
  echo "$TODAY"
  exit 0
fi

if RESOLVED=$(date -d "$PHRASE" +%Y-%m-%d 2>/dev/null); then
  echo "$RESOLVED"
  exit 0
fi

cat >&2 <<EOF
ERROR: could not parse '$PHRASE' as a date.
Try one of:
  today
  yesterday
  june 16
  last friday
  2 days ago
  2026-06-16
EOF
exit 1
