#!/usr/bin/env bash
# triage.sh
# Per-candidate dispatch decision for the auto-new-day morning sweep.
# Emits ONE of these on stdout:
#
#   dispatch
#   resume <path-to-manifest-copied-into-today's-date-dir>
#   skip <one-line reason>
#   discard <case-name> <one-line detail>
#
# Called from SKILL.md Steps 7.1 / 7b.1 / 7c.1 per candidate. Replaces
# the inline discard + resume walk with one deterministic script call.
#
# Bucket-specific logic:
#
#   inreview          own actionable PRs (fix-bug-work dispatches)
#     discard cases : ticket-left-status, reassigned, pr-merged, pr-closed
#     resume        : marker exists + prior manifest + local HEAD unchanged
#                     + branch NOT pushed
#
#   inprogress        own unstarted-impl tickets
#     discard cases : ticket-left-status, reassigned, pr-merged (linked PR)
#     resume        : marker exists + prior manifest + local HEAD unchanged
#                     + branch not pushed + no PR linked yet
#
#   inreview-others   teammate PRs queued for /pr-code-review-work
#     discard cases : pr-merged, pr-approved-by-authoritative-approver
#     resume        : marker exists + prior manifest + PR branchSha unchanged
#
# When emit=discard, this script removes the in-repo marker file. state.json
# cleanup is deferred to the sweep's Step 8 archive or to mark_done.sh.
#
# When emit=resume, this script copies the prior manifest into today's
# `$DATES_DIR/<TODAY>/dispatch/` so the child's Step 0 fast-path picks it up.

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Approver GitHub logins whose APPROVED review clears a PR. The engine passes
# them space-separated via AUTO_NEW_DAY_APPROVERS; empty is legal (no PR ever
# auto-clears). Login match is authoritative; the name fallback stays disabled
# unless AUTO_NEW_DAY_APPROVERS_NAME_RE is set.
read -ra APPROVERS_LOGIN <<<"${AUTO_NEW_DAY_APPROVERS:-}"
APPROVERS_NAME_RE="${AUTO_NEW_DAY_APPROVERS_NAME_RE:-}"

BUCKET=""
KEY=""
PR_URL=""
REPO_DIR=""
BRANCH=""
LINEAR_STATUS=""
LINEAR_ASSIGNEE=""
ME_LINEAR=""
FORCE=0
STATE_DIR="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}"
STATE_JSON="$STATE_DIR/state.json"
DATES_DIR="$STATE_DIR/dates"
TODAY=$(date +%Y-%m-%d)

usage() {
  cat <<'EOF'
Usage: triage.sh --bucket <inreview|inprogress|inreview-others> --key <k> [options]

Required:
  --bucket <b>            Which sweep bucket
  --key <k>               Ticket ID (inreview/inprogress) OR window name (inreview-others)

Options:
  --pr-url <url>          PR URL if applicable (drives merged/closed/approval checks)
  --repo-dir <path>       Local repo dir (for git checks)
  --branch <name>         Working branch (for cherry / push detection)
  --linear-status <s>     Current Linear status (for own-work discard cases)
  --linear-assignee <a>   Current assignee id/login/name (for reassignment discard)
  --me-linear <id>        Current user's Linear id (compared vs --linear-assignee)
  --state-json <path>     Path to state.json  (default ~/work/.auto-new-day/state.json)
  --dates-dir <path>      Path to dates dir   (default ~/work/.auto-new-day/dates)
  --today <YYYY-MM-DD>    Override "today"    (default: today's date)
  --force                 Bypass discard+resume; always emit "dispatch"

Exit codes:
  0    normal (one of dispatch|resume|skip|discard)
  1    bad args / missing deps
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --bucket)          BUCKET="${2:-}";           shift 2 ;;
    --key)             KEY="${2:-}";              shift 2 ;;
    --pr-url)          PR_URL="${2:-}";           shift 2 ;;
    --repo-dir)        REPO_DIR="${2:-}";         shift 2 ;;
    --branch)          BRANCH="${2:-}";           shift 2 ;;
    --linear-status)   LINEAR_STATUS="${2:-}";    shift 2 ;;
    --linear-assignee) LINEAR_ASSIGNEE="${2:-}";  shift 2 ;;
    --me-linear)       ME_LINEAR="${2:-}";        shift 2 ;;
    --state-json)      STATE_JSON="${2:-}";       shift 2 ;;
    --dates-dir)       DATES_DIR="${2:-}";        shift 2 ;;
    --today)           TODAY="${2:-}";            shift 2 ;;
    --force)           FORCE=1;                    shift 1 ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "triage.sh: unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$BUCKET" in
  inreview|inprogress|inreview-others) : ;;
  *) echo "triage.sh: --bucket must be one of: inreview inprogress inreview-others" >&2; exit 1 ;;
esac
[ -n "$KEY" ] || { echo "triage.sh: --key is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "triage.sh: jq missing" >&2; exit 1; }

# --force short-circuit.
if [ "$FORCE" = "1" ]; then
  echo "dispatch"
  exit 0
fi

# Permanent-discard check: if mark_done.sh --forever wrote a record for this key,
# honor it unconditionally (short of --force above). This is the operator's "never
# bother me about this again" hammer.
FOREVER_MARK="$STATE_DIR/done/$KEY.done.json"
if [ -f "$FOREVER_MARK" ] && [ "$(jq -r '.forever // false' "$FOREVER_MARK" 2>/dev/null)" = "true" ]; then
  reason=$(jq -r '.reason // .outcome // "marked done forever"' "$FOREVER_MARK" 2>/dev/null)
  echo "discard forever $reason"
  exit 0
fi

# Compute marker + manifest paths per bucket.
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

# Load state.json snapshot for this key.
SNAPSHOT_JSON="null"
if [ -f "$STATE_JSON" ]; then
  case "$BUCKET" in
    inreview|inprogress)
      SNAPSHOT_JSON=$(jq --arg t "$KEY" '.tickets[$t].dispatch.snapshot // null' "$STATE_JSON" 2>/dev/null || echo "null")
      ;;
    inreview-others)
      SNAPSHOT_JSON=$(jq --arg u "$PR_URL" '.reviewedPRs[$u].dispatch.snapshot // null' "$STATE_JSON" 2>/dev/null || echo "null")
      ;;
  esac
fi

# Fetch gh pr view once, cache. Empty string when no PR_URL or fetch fails.
PR_JSON=""
if [ -n "$PR_URL" ]; then
  PR_JSON=$(gh pr view "$PR_URL" --json state,mergedAt,closedAt,reviews,headRefOid,updatedAt,createdAt 2>/dev/null || echo "")
fi

emit_dispatch() { echo "dispatch"; exit 0; }
emit_resume() { echo "resume $1"; exit 0; }
emit_skip() { echo "skip $1"; exit 0; }

emit_discard() {
  local case_name="$1" detail="$2"
  rm -f "$MARKER_PATH" 2>/dev/null || true
  echo "discard $case_name $detail"
  exit 0
}

# ------------------------------------------------------------------
# Discard cases per bucket
# ------------------------------------------------------------------

# Ticket-left-status (own-work only). Accept forms roughly matching Step 2's
# "name contains 'review' or 'progress'".
if [ -n "$LINEAR_STATUS" ]; then
  case "$BUCKET" in
    inreview)
      case "$LINEAR_STATUS" in
        *[Rr]eview*|Validation|Rollout|"Pending Acceptance") : ;;
        *) emit_discard "ticket-left-status" "ticket now in status $LINEAR_STATUS" ;;
      esac
      ;;
    inprogress)
      case "$LINEAR_STATUS" in
        *[Pp]rogress*|Doing|Started) : ;;
        *) emit_discard "ticket-left-status" "ticket now in status $LINEAR_STATUS" ;;
      esac
      ;;
  esac
fi

# Reassigned (own-work only).
if [ "$BUCKET" != "inreview-others" ] && [ -n "$ME_LINEAR" ] && [ -n "$LINEAR_ASSIGNEE" ] && [ "$LINEAR_ASSIGNEE" != "$ME_LINEAR" ]; then
  emit_discard "reassigned" "reassigned to $LINEAR_ASSIGNEE"
fi

# PR merged / closed (any bucket with a PR).
if [ -n "$PR_JSON" ]; then
  pr_state=$(echo "$PR_JSON" | jq -r '.state // ""')
  pr_merged_at=$(echo "$PR_JSON" | jq -r '.mergedAt // ""')
  pr_closed_at=$(echo "$PR_JSON" | jq -r '.closedAt // ""')
  if [ "$pr_state" = "MERGED" ] || { [ -n "$pr_merged_at" ] && [ "$pr_merged_at" != "null" ]; }; then
    emit_discard "pr-merged" "PR $PR_URL merged at $pr_merged_at"
  fi
  if [ "$BUCKET" = "inreview" ] && [ "$pr_state" = "CLOSED" ]; then
    emit_discard "pr-closed" "PR $PR_URL closed at $pr_closed_at without merging"
  fi
fi

# Approved-by-authoritative-approver (inreview-others only).
if [ "$BUCKET" = "inreview-others" ] && [ -n "$PR_JSON" ]; then
  approver=""
  for login in "${APPROVERS_LOGIN[@]}"; do
    match=$(echo "$PR_JSON" | jq -r --arg l "$login" '
      [.reviews[]? | select(.state == "APPROVED") | .author.login] | index($l) | tostring')
    if [ -n "$match" ] && [ "$match" != "null" ]; then
      approver="$login"; break
    fi
  done
  if [ -z "$approver" ] && [ -n "$APPROVERS_NAME_RE" ]; then
    approver=$(echo "$PR_JSON" | jq -r '
      [.reviews[]? | select(.state == "APPROVED") | .author.name] | .[]?' \
      | grep -iE "$APPROVERS_NAME_RE" | head -1 || true)
  fi
  if [ -n "$approver" ]; then
    emit_discard "pr-approved" "approved by $approver"
  fi
fi

# Age cap (inreview-others only). Skip teammate PRs opened more than
# AUTO_NEW_DAY_MAX_PR_AGE_DAYS ago (0/unset = no cap), UNLESS we engaged with
# this PR before it crossed that age. "Engaged before the cutoff" = an earlier
# review-manifest date OR a recorded reviewedPRs dispatch, timestamped before
# createdAt+cap. A PR we started reviewing while fresh stays in the sweep as it
# changes; a stale one we never touched drops out.
MAX_PR_AGE_DAYS="${AUTO_NEW_DAY_MAX_PR_AGE_DAYS:-0}"
if [ "$BUCKET" = "inreview-others" ] && [ -n "$PR_JSON" ] && [ "${MAX_PR_AGE_DAYS:-0}" -gt 0 ] 2>/dev/null; then
  pr_created_at=$(echo "$PR_JSON" | jq -r '.createdAt // ""')
  created_epoch=$(date -d "$pr_created_at" +%s 2>/dev/null || echo 0)
  now_epoch=$(date +%s)
  cutoff_epoch=$((created_epoch + MAX_PR_AGE_DAYS * 86400))
  if [ "$created_epoch" -gt 0 ] && [ "$now_epoch" -ge "$cutoff_epoch" ]; then
    engaged_before=0
    # earliest review-manifest date dir for this PR (first time we reviewed it)
    if [ -d "$DATES_DIR" ]; then
      for d in $(ls -1 "$DATES_DIR" 2>/dev/null | sort); do
        [ -f "$DATES_DIR/$d/dispatch/$MANIFEST_BASE.done.json" ] || continue
        first_epoch=$(date -d "$d" +%s 2>/dev/null || echo 0)
        if [ "$first_epoch" -gt 0 ] && [ "$first_epoch" -lt "$cutoff_epoch" ]; then engaged_before=1; fi
        break
      done
    fi
    # fallback: a reviewedPRs dispatch recorded before the cutoff also proves engagement
    if [ "$engaged_before" = "0" ] && [ -f "$STATE_JSON" ]; then
      disp_at=$(jq -r --arg u "$PR_URL" '.reviewedPRs[$u].dispatchedAt // ""' "$STATE_JSON" 2>/dev/null)
      disp_epoch=$(date -d "$disp_at" +%s 2>/dev/null || echo 0)
      if [ "$disp_epoch" -gt 0 ] && [ "$disp_epoch" -lt "$cutoff_epoch" ]; then engaged_before=1; fi
    fi
    if [ "$engaged_before" = "0" ]; then
      age_days=$(((now_epoch - created_epoch) / 86400))
      emit_discard "pr-too-old" "PR opened ${age_days}d ago (> ${MAX_PR_AGE_DAYS}d cap), never reviewed while fresh"
    fi
  fi
fi

# ------------------------------------------------------------------
# Marker + is-abandoned check
# ------------------------------------------------------------------

if [ ! -f "$MARKER_PATH" ]; then
  emit_dispatch
fi

if "$SCRIPTS_DIR/marker.sh" is-abandoned "$MARKER_PATH" "$REPO_DIR" "$BRANCH" 2>/dev/null; then
  emit_dispatch
fi

# ------------------------------------------------------------------
# inreview-others: new commits since last review → re-review.
# A teammate PR that was touched since our last review (head SHA moved off
# the recorded snapshot) is a re-review candidate per Step 2c, not a skip.
# Re-dispatch a fresh review instead of resuming the old Hunk or skipping.
# An unchanged PR falls through to the resume/skip logic below.
# ------------------------------------------------------------------
if [ "$BUCKET" = "inreview-others" ]; then
  snap_sha=$(echo "$SNAPSHOT_JSON" | jq -r '.branchSha // ""')
  cur_sha=$(echo "$PR_JSON" | jq -r '.headRefOid // ""')
  if [ -n "$snap_sha" ] && [ -n "$cur_sha" ] && [ "$snap_sha" != "$cur_sha" ]; then
    emit_dispatch
  fi
fi

# ------------------------------------------------------------------
# Prior manifest search
# ------------------------------------------------------------------

PRIOR_MANIFEST=""
if [ -d "$DATES_DIR" ]; then
  for d in $(ls -1 "$DATES_DIR" 2>/dev/null | sort -r); do
    if [ "$d" = "$TODAY" ]; then continue; fi
    m="$DATES_DIR/$d/dispatch/$MANIFEST_BASE.done.json"
    if [ -f "$m" ]; then PRIOR_MANIFEST="$m"; break; fi
  done
fi

if [ -z "$PRIOR_MANIFEST" ]; then
  emit_skip "marker exists at $MARKER_PATH (no prior manifest; pass --force to re-dispatch)"
fi

# ------------------------------------------------------------------
# Resume state comparison
# ------------------------------------------------------------------

resume_ok=1

case "$BUCKET" in
  inreview|inprogress)
    if [ -n "$REPO_DIR" ] && [ -d "$REPO_DIR" ]; then
      snap_sha=$(echo "$SNAPSHOT_JSON" | jq -r '.branchSha // ""')
      cur_sha=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")
      if [ -n "$snap_sha" ] && [ -n "$cur_sha" ] && [ "$snap_sha" != "$cur_sha" ]; then
        resume_ok=0
      fi
    fi
    if [ "$BUCKET" = "inreview" ] && [ -n "$REPO_DIR" ] && [ -n "$BRANCH" ]; then
      # Branch pushed? All local commits now on origin → no resume.
      if git -C "$REPO_DIR" ls-remote --exit-code origin "refs/heads/$BRANCH" >/dev/null 2>&1; then
        ahead=$(git -C "$REPO_DIR" cherry "origin/$BRANCH" 2>/dev/null | grep -c "^+" || true)
        # cherry returns lines starting with + for local-only, - for upstream-only.
        if [ "${ahead:-0}" = "0" ]; then
          resume_ok=0
        fi
      fi
    fi
    if [ "$BUCKET" = "inprogress" ] && [ -n "$PR_URL" ]; then
      # PR linked now — moved out of unstarted-impl.
      resume_ok=0
    fi
    ;;
  inreview-others)
    snap_sha=$(echo "$SNAPSHOT_JSON" | jq -r '.branchSha // ""')
    cur_sha=$(echo "$PR_JSON" | jq -r '.headRefOid // ""')
    if [ -n "$snap_sha" ] && [ -n "$cur_sha" ] && [ "$snap_sha" != "$cur_sha" ]; then
      resume_ok=0
    fi
    ;;
esac

if [ "$resume_ok" = "1" ]; then
  today_dir="$DATES_DIR/$TODAY/dispatch"
  mkdir -p "$today_dir"
  today_manifest="$today_dir/$MANIFEST_BASE.done.json"
  cp "$PRIOR_MANIFEST" "$today_manifest"
  emit_resume "$today_manifest"
fi

emit_skip "marker exists at $MARKER_PATH (state changed since prior dispatch; pass --force to re-dispatch)"
