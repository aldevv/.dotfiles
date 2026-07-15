#!/usr/bin/env bash
# Garbage-collect stale windows in the three AUTO-* dispatch tmux sessions
# (AUTO-inreview, AUTO-inprogress, AUTO-inreview-others).
# A window is "stale" when its per-window log file (under
# ~/.cache/auto-new-day-sweep/children/) hasn't been written to in N hours
# (default: 168, i.e. one week). That means the child claude finished or
# crashed long ago and the pane is now just a quiet shell waiting forever.
#
# Action: ARCHIVE-RENAME rather than kill. Renames `<original>` to
# `<original>-stale-<YYYYMMDD>` so the window stays attachable. The next
# sweep will see it under the renamed name and is free to archive-rename a
# second time, but it won't re-spawn dispatch into a window that's been
# renamed (dispatch dedupe is by `<original>` name, not the renamed one).
# After two GC passes the operator can `tmux kill-window` manually if they
# no longer care.
#
# Usage:
#   gc-stale-windows.sh [--hours N] [--log-dir DIR] [--dry-run]
#
# Defaults:
#   --hours    168   (one week)
#   --log-dir  $HOME/.cache/auto-new-day-sweep/children
#   --dry-run  off (prints what it would do without renaming)
#
# Output (one line per window inspected, real-run only):
#   archived  AUTO-inreview:CXH-1234-baton-foo -> CXH-1234-baton-foo-stale-20260630  (log idle 31h)
#   skipped   AUTO-inprogress:CXH-5555-newconnector  (log idle 4h, fresh)
#   no-log    AUTO-inreview-others:baton-bar-17  (no log; cannot decide; left alone)
#
# Exit 0 always (best-effort cleanup; never aborts the sweep).

set -u

HOURS=168
LOG_DIR="$HOME/.cache/auto-new-day-sweep/children"
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --hours)    shift; HOURS=${1:-168} ;;
    --log-dir)  shift; LOG_DIR=${1:-$LOG_DIR} ;;
    --dry-run)  DRY_RUN=1 ;;
    *) echo "gc-stale-windows.sh: unknown arg: $1" >&2; exit 0 ;;
  esac
  shift
done

THRESHOLD=$(( HOURS * 3600 ))
NOW=$(date +%s)
TODAY=$(date +%Y%m%d)

for session in AUTO-inreview AUTO-inprogress AUTO-inreview-others; do
  tmux has-session -t "$session" 2>/dev/null || continue

  while IFS= read -r win; do
    # Skip windows already renamed by an earlier GC pass.
    case "$win" in *-stale-*) continue ;; esac

    log_path="$LOG_DIR/${session}-${win}.log"
    if [ ! -f "$log_path" ]; then
      echo "no-log   ${session}:${win}  (no log; cannot decide; left alone)"
      continue
    fi

    log_mtime=$(stat -c %Y "$log_path" 2>/dev/null || stat -f %m "$log_path" 2>/dev/null)
    [ -n "$log_mtime" ] || { echo "no-log   ${session}:${win}  (stat failed)"; continue; }

    idle=$(( NOW - log_mtime ))
    idle_hours=$(( idle / 3600 ))
    if [ "$idle" -lt "$THRESHOLD" ]; then
      echo "skipped  ${session}:${win}  (log idle ${idle_hours}h, fresh)"
      continue
    fi

    new_name="${win}-stale-${TODAY}"
    if [ "$DRY_RUN" = 1 ]; then
      echo "would-archive ${session}:${win} -> ${new_name}  (log idle ${idle_hours}h)"
    else
      if tmux rename-window -t "${session}:${win}" "$new_name" 2>/dev/null; then
        echo "archived ${session}:${win} -> ${new_name}  (log idle ${idle_hours}h)"
      else
        echo "failed   ${session}:${win} -> ${new_name}  (rename returned non-zero)"
      fi
    fi
  done < <(tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null || true)
done

exit 0
