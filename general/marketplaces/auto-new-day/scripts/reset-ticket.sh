#!/usr/bin/env bash
# reset-ticket.sh
# Operator escape hatch. Atomically removes every artifact tied to a ticket so
# the next sweep dispatches it fresh:
#   - flat in-repo marker (all three buckets: .inreview, .inprogress, .inreview-others)
#   - per-date in-repo marker copies (every <DATE>/ subdir under each bucket)
#   - $DATE_DIR marker mirror (today's date dir only)
#   - dispatch payload + completion manifest + blocked.md for today's date dir
#   - state.json entry (drops the ticket from active state.json; the next
#     sweep's Step 8 will treat it as a fresh discovery)
#
# Does NOT touch /done/<TICKET>.json (the audit trail). Does NOT touch tmux
# windows -- the operator should kill the window if they want a fully clean
# re-dispatch.
#
# Usage:
#   reset-ticket.sh CXH-1234            # nuke today's artifacts + state.json
#   reset-ticket.sh CXH-1234 --date <d> # nuke <d>'s artifacts + state.json
#   reset-ticket.sh --dry-run CXH-1234  # show what WOULD be removed; touches nothing
#
# Always safe to re-run; missing files are fine.

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_ROOT="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}"
STATE_JSON="$STATE_ROOT/state.json"
WORKING_ROOT="${AUTO_NEW_DAY_WORKING_ROOT:-$PWD}"

DRY_RUN=0
TICKET=""
DATE_PHRASE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --date)       shift; DATE_PHRASE=${1:-} ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    -*) echo "reset-ticket.sh: unknown flag: $1" >&2; exit 2 ;;
    *)  if [ -z "$TICKET" ]; then TICKET=$1; else echo "reset-ticket.sh: extra arg: $1" >&2; exit 2; fi ;;
  esac
  shift
done

[ -n "$TICKET" ] || { echo "reset-ticket.sh: need a ticket id (e.g. CXH-1234)" >&2; exit 2; }

if [ -n "$DATE_PHRASE" ]; then
  TARGET_DATE=$("$SCRIPTS_DIR/resolve-date.sh" $DATE_PHRASE) || exit 1
else
  TARGET_DATE=$(date +%Y-%m-%d)
fi
DATE_DIR="$STATE_ROOT/dates/$TARGET_DATE"

# Discover affected file paths first; remove them in one pass so dry-run can
# print exactly what a real run would do.
declare -a TARGETS=()

# In-repo markers (flat + per-date copy) across all three buckets, every repo
# under the working root, all dates under each bucket.
shopt -s nullglob
for repo in "$WORKING_ROOT"/*/; do
  for bucket in .inreview .inprogress .inreview-others; do
    flat="${repo%/}/$bucket/${TICKET}.md"
    [ -f "$flat" ] && TARGETS+=("$flat")
    for dated in "${repo%/}/$bucket"/*/"${TICKET}.md"; do
      [ -f "$dated" ] && TARGETS+=("$dated")
    done
  done
done
# Fallback marker dir (used for newconnector tickets where the repo doesn't
# exist yet).
fallback="$STATE_ROOT/markers/inprogress/${TICKET}.md"
[ -f "$fallback" ] && TARGETS+=("$fallback")
for dated in "$STATE_ROOT"/markers/inprogress/*/"${TICKET}.md"; do
  [ -f "$dated" ] && TARGETS+=("$dated")
done

# Today's date-dir artifacts.
for kind in markers/inreview markers/inprogress markers/inreview-others; do
  p="$DATE_DIR/$kind/${TICKET}.md"
  [ -f "$p" ] && TARGETS+=("$p")
done
for ext in json done.json blocked.md; do
  p="$DATE_DIR/dispatch/${TICKET}.${ext}"
  [ -f "$p" ] && TARGETS+=("$p")
done

# State.json entry. Use a temp file + state-write.sh so concurrent sweeps
# don't torn-write.
HAVE_STATE_ENTRY=0
if [ -f "$STATE_JSON" ] && command -v jq >/dev/null 2>&1; then
  if jq -e --arg t "$TICKET" '.tickets // {} | has($t)' "$STATE_JSON" >/dev/null 2>&1; then
    HAVE_STATE_ENTRY=1
  fi
fi

echo "reset-ticket.sh: ticket=$TICKET date=$TARGET_DATE dry-run=$DRY_RUN"
echo "  filesystem artifacts (${#TARGETS[@]}):"
for t in "${TARGETS[@]+"${TARGETS[@]}"}"; do
  echo "    $t"
done
if [ "$HAVE_STATE_ENTRY" = 1 ]; then
  echo "  state.json: tickets[\"$TICKET\"] (will be removed)"
else
  echo "  state.json: no entry for $TICKET"
fi

if [ "$DRY_RUN" = 1 ]; then
  echo "dry-run; not removing"
  exit 0
fi

for t in "${TARGETS[@]+"${TARGETS[@]}"}"; do
  rm -f "$t" 2>/dev/null || echo "warn: failed to rm $t" >&2
done

if [ "$HAVE_STATE_ENTRY" = 1 ]; then
  tmp=$(mktemp)
  if jq --arg t "$TICKET" 'del(.tickets[$t])' "$STATE_JSON" > "$tmp"; then
    "$SCRIPTS_DIR/state-write.sh" < "$tmp" || echo "warn: state-write.sh failed (state.json may be unchanged)" >&2
  else
    echo "warn: jq failed to strip $TICKET from state.json" >&2
  fi
  rm -f "$tmp"
fi

echo "reset complete; next sweep will rediscover $TICKET as fresh"
