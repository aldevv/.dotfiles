#!/usr/bin/env bash
# archive-prior-session.sh
# Rename a tmux session that was first created on a calendar day BEFORE today,
# postfixing it with that creation date (AUTO-inreview -> AUTO-inreview-2026-09-08),
# so a fresh sweep on a new day never reuses or overrides the previous day's
# session. Same-day sessions are left untouched: within one sweep the first
# window creates the session and later windows add to it, and a same-day re-run
# or date-replay still dedupes against the live session as before.
#
# Called by tmux-dispatch.sh / rtm-window.sh right before they create-or-reuse a
# session, so the archival is a no-op on every path except "a new day found
# yesterday's session still around".
#
# Usage: archive-prior-session.sh <session-name>
# Prints one status line: archived <newname> | kept | absent
set -u

SESSION=${1:-}
[ -n "$SESSION" ] || { echo "failed: missing <session>" >&2; exit 1; }

# `=name` forces an exact match; without it tmux treats the target as a prefix.
tmux has-session -t "=$SESSION" 2>/dev/null || { echo "absent"; exit 0; }

# Creation epoch of the session. Read it by exact name from list-sessions:
# `display-message -t =name` returns empty on some tmux builds (3.7b), and an
# unanchored `-t name` prefix-matches (AUTO-inreview -> AUTO-inreview-others).
created=$(tmux list-sessions -F '#{session_name} #{session_created}' 2>/dev/null \
  | awk -v s="$SESSION" '$1 == s { print $2; exit }')

# Format epoch -> YYYY-MM-DD. GNU date first (Linux), BSD date second (macOS).
day_of() { date -d "@$1" +%F 2>/dev/null || date -r "$1" +%F 2>/dev/null; }
created_day=$(day_of "$created")
today=$(date +%F)

# Unknown/unparseable creation time, or created today, or somehow future-dated
# (clock skew): leave it alone. ISO dates compare lexically == chronologically.
[ -n "$created_day" ] || { echo "kept"; exit 0; }
[[ "$created_day" < "$today" ]] || { echo "kept"; exit 0; }

# Suffix -2, -3, ... if an archive for that day already exists (two prior-day
# sweeps, or a manual rename already took the plain -<date> name).
target="$SESSION-$created_day"
if tmux has-session -t "=$target" 2>/dev/null; then
  n=2
  while tmux has-session -t "=$target-$n" 2>/dev/null; do n=$((n + 1)); done
  target="$target-$n"
fi

if tmux rename-session -t "=$SESSION" "$target" 2>/dev/null; then
  echo "archived $target"
else
  echo "failed: rename $SESSION -> $target" >&2
  exit 1
fi
