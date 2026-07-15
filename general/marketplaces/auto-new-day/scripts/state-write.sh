#!/usr/bin/env bash
# state-write.sh
# Serialize concurrent writes to the auto-new-day state.json across sweeps.
# Reads the desired JSON content from stdin, flocks a sibling lock file, writes
# to state.json.partial, fsyncs, then mv-promotes over state.json.
#
# Usage:
#   cat new-state.json | state-write.sh [<state-json-path>]
#
# Defaults to $AUTO_NEW_DAY_STATE_DIR/state.json (fallback ~/.local/state/auto-new-day)
# when no path argv is given.
# Exits 0 on success, non-zero on failure (lock timeout, write error, malformed
# JSON). On failure the prior state.json is untouched.
#
# Lock policy: 30-second wait via `flock -w 30`. Two sweeps firing in the same
# minute (cron + manual) will serialize; the later writer sees the earlier
# writer's state.json. They MUST recompute and merge if they care; this script
# is intentionally last-write-wins. Use it where the writer already holds the
# semantically-correct full state.json content (Step 8 always does — it has
# just computed the active-tickets + done-archive set in memory).

set -u

STATE_PATH=${1:-"${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}/state.json"}
LOCK_PATH="${STATE_PATH}.lock"
PARTIAL="${STATE_PATH}.partial"

mkdir -p "$(dirname "$STATE_PATH")" 2>/dev/null || true

exec 9>"$LOCK_PATH" || { echo "state-write.sh: cannot open lock file $LOCK_PATH" >&2; exit 2; }
if ! flock -w 30 9; then
  echo "state-write.sh: timed out waiting for lock on $LOCK_PATH" >&2
  exit 3
fi

# Buffer stdin into the partial file. Refuse to promote a non-parseable payload.
cat > "$PARTIAL" || { echo "state-write.sh: write to $PARTIAL failed" >&2; exit 4; }
if ! command -v jq >/dev/null 2>&1; then
  echo "state-write.sh: jq not on PATH; refusing to promote unvalidated payload" >&2
  rm -f "$PARTIAL"
  exit 5
fi
if ! jq -e . "$PARTIAL" >/dev/null 2>&1; then
  echo "state-write.sh: input is not valid JSON; aborting" >&2
  rm -f "$PARTIAL"
  exit 6
fi

# fsync via dd + conv=fsync so the partial is durable before the rename.
dd if="$PARTIAL" of="$PARTIAL" conv=notrunc,fsync count=0 2>/dev/null || true

mv -f "$PARTIAL" "$STATE_PATH" || { echo "state-write.sh: mv $PARTIAL -> $STATE_PATH failed" >&2; exit 7; }

# Lock fd auto-closes on exit; explicit close is paranoia.
exec 9>&-
exit 0
