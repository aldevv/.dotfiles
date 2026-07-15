#!/usr/bin/env bash
# mark_done.sh
# Called by children (fix-bug-work, impl-work, newconnector, pr-code-review-work)
# at the end of a completed run — OR by the operator manually — to explicitly signal
# "this ticket/PR is done, drop it from the next sweep".
#
# What it does:
#   1. Removes the in-repo dedupe marker under `.<bucket>/<key>.md`.
#   2. Removes state.json.tickets[<key>] (own-work) or state.json.reviewedPRs[<pr-url>]
#      (reviews) via scripts/state-write.sh (atomic rewrite).
#   3. Removes today's dispatch manifest at $DATE_DIR/dispatch/<manifest-base>.done.json
#      so a same-day re-dispatch is a fresh dispatch, not a stale-manifest resume.
#   4. Appends an audit line to ~/.cache/auto-new-day-sweep/mark-done.log.
#   5. When --forever: writes a permanent record at ~/work/.auto-new-day/done/<key>.done.json
#      that triage.sh treats as an unconditional discard. Without --forever, the drop is
#      soft: if the PR / branch state genuinely changes later (new commits from someone
#      else, new comments), triage.sh's discovery layer re-derives from ground truth and
#      the ticket can resurface.
#
# The soft-default is the right call for children calling this at end-of-run — most of
# the time we want the next sweep to re-derive from ground truth, only surfacing again
# if a reviewer actually replies or a teammate pushes. --forever is the "don't ever
# bother me about this again" hammer.

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

BUCKET=""
KEY=""
PR_URL=""
REPO_DIR=""
OUTCOME=""
REASON=""
FOREVER=0
STATE_DIR="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}"
DATES_DIR="$STATE_DIR/dates"
STATE_JSON="$STATE_DIR/state.json"
DONE_DIR="$STATE_DIR/done"
LOG_FILE="$HOME/.cache/auto-new-day-sweep/mark-done.log"
TODAY=$(date +%Y-%m-%d)

usage() {
  cat <<'EOF'
Usage: mark_done.sh --bucket <inreview|inprogress|inreview-others> --key <k> [options]

Required:
  --bucket <b>            Which sweep bucket the work belongs to
  --key <k>               Ticket ID (inreview/inprogress) OR window name (inreview-others)

Recommended:
  --outcome <text>        Short label — "pushed", "approved", "reviewed", "merged", ...
  --reason <text>         One-line justification for the audit log

Optional:
  --pr-url <url>          PR URL (required for inreview-others state.json cleanup)
  --repo-dir <path>       Local repo dir (used to resolve the in-repo marker path)
  --forever               Permanent discard — write ~/work/.auto-new-day/done/<key>.done.json
                          so triage.sh treats this key as done forever
  --state-json <path>     state.json path  (default ~/work/.auto-new-day/state.json)
  --dates-dir <path>      dates dir path   (default ~/work/.auto-new-day/dates)
  --today <YYYY-MM-DD>    Override "today"

Exit codes:
  0    ok
  1    bad args
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --bucket)     BUCKET="${2:-}";     shift 2 ;;
    --key)        KEY="${2:-}";        shift 2 ;;
    --pr-url)     PR_URL="${2:-}";     shift 2 ;;
    --repo-dir)   REPO_DIR="${2:-}";   shift 2 ;;
    --outcome)    OUTCOME="${2:-}";    shift 2 ;;
    --reason)     REASON="${2:-}";     shift 2 ;;
    --forever)    FOREVER=1;           shift 1 ;;
    --state-json) STATE_JSON="${2:-}"; shift 2 ;;
    --dates-dir)  DATES_DIR="${2:-}";  shift 2 ;;
    --today)      TODAY="${2:-}";      shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "mark_done.sh: unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$BUCKET" in
  inreview|inprogress|inreview-others) : ;;
  *) echo "mark_done.sh: --bucket must be one of: inreview inprogress inreview-others" >&2; exit 1 ;;
esac
[ -n "$KEY" ] || { echo "mark_done.sh: --key is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "mark_done.sh: jq missing" >&2; exit 1; }

# Compute paths per bucket.
case "$BUCKET" in
  inreview)
    if [ -n "$REPO_DIR" ] && [ -d "$REPO_DIR" ]; then
      MARKER_PATH="$REPO_DIR/.inreview/$KEY.md"
    else
      MARKER_PATH="$STATE_DIR/markers/inreview/$KEY.md"
    fi
    MANIFEST_BASE="$KEY"
    ;;
  inprogress)
    if [ -n "$REPO_DIR" ] && [ -d "$REPO_DIR" ]; then
      MARKER_PATH="$REPO_DIR/.inprogress/$KEY.md"
    else
      MARKER_PATH="$STATE_DIR/markers/inprogress/$KEY.md"
    fi
    MANIFEST_BASE="$KEY"
    ;;
  inreview-others)
    if [ -n "$REPO_DIR" ] && [ -d "$REPO_DIR" ]; then
      MARKER_PATH="$REPO_DIR/.inreview-others/$KEY.md"
    else
      MARKER_PATH="$STATE_DIR/markers/inreview-others/$KEY.md"
    fi
    MANIFEST_BASE="review-$KEY"
    ;;
esac

# 1. Remove the in-repo dedupe marker (both the flat one and today's per-date copy).
removed_marker=0
if [ -f "$MARKER_PATH" ]; then
  rm -f "$MARKER_PATH"
  removed_marker=1
fi
per_date_marker="$(dirname "$MARKER_PATH")/$TODAY/$KEY.md"
[ -f "$per_date_marker" ] && rm -f "$per_date_marker" || true

# 2. Remove state.json entry for this key (atomic rewrite via state-write.sh).
removed_state=0
if [ -f "$STATE_JSON" ]; then
  case "$BUCKET" in
    inreview|inprogress)
      have=$(jq --arg t "$KEY" 'has("tickets") and (.tickets|has($t))' "$STATE_JSON" 2>/dev/null || echo false)
      if [ "$have" = "true" ]; then
        jq --arg t "$KEY" 'del(.tickets[$t])' "$STATE_JSON" \
          | "$SCRIPTS_DIR/state-write.sh" >/dev/null 2>&1 && removed_state=1
      fi
      ;;
    inreview-others)
      if [ -n "$PR_URL" ]; then
        have=$(jq --arg u "$PR_URL" 'has("reviewedPRs") and (.reviewedPRs|has($u))' "$STATE_JSON" 2>/dev/null || echo false)
        if [ "$have" = "true" ]; then
          jq --arg u "$PR_URL" 'del(.reviewedPRs[$u])' "$STATE_JSON" \
            | "$SCRIPTS_DIR/state-write.sh" >/dev/null 2>&1 && removed_state=1
        fi
      fi
      ;;
  esac
fi

# 3. Remove today's dispatch manifest so a same-day re-dispatch is fresh.
today_manifest="$DATES_DIR/$TODAY/dispatch/$MANIFEST_BASE.done.json"
removed_manifest=0
if [ -f "$today_manifest" ]; then
  rm -f "$today_manifest"
  removed_manifest=1
fi

# 4. --forever: write a permanent discard record.
forever_written=0
if [ "$FOREVER" = "1" ]; then
  mkdir -p "$DONE_DIR"
  # Use the KEY as filename base (works for both ticket ids and window names).
  perm="$DONE_DIR/$KEY.done.json"
  jq -n \
    --arg key      "$KEY" \
    --arg bucket   "$BUCKET" \
    --arg prUrl    "$PR_URL" \
    --arg outcome  "$OUTCOME" \
    --arg reason   "$REASON" \
    --arg markedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{key:$key, bucket:$bucket, prUrl:$prUrl, outcome:$outcome, reason:$reason, markedAt:$markedAt, forever:true}' \
    > "$perm"
  forever_written=1
fi

# 5. Audit log.
mkdir -p "$(dirname "$LOG_FILE")"
{
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] mark-done bucket=$BUCKET key=$KEY outcome=${OUTCOME:-} reason=${REASON:-} \
forever=$FOREVER removed_marker=$removed_marker removed_state=$removed_state removed_manifest=$removed_manifest \
forever_written=$forever_written"
} >> "$LOG_FILE"

# Print summary to stdout for the caller.
echo "mark-done ok: bucket=$BUCKET key=$KEY removed_marker=$removed_marker removed_state=$removed_state removed_manifest=$removed_manifest forever=$FOREVER"
