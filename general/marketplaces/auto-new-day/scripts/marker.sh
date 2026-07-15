#!/usr/bin/env bash
# Dispatch-marker operations for the auto-new-day skill.
# One marker file per ticket per bucket signals "already dispatched in a
# previous sweep; do not re-dispatch until the marker is removed".
#
# Usage:
#   marker.sh check  <marker-path>
#       Exit 0 if the marker file exists. Exit 1 otherwise.
#       Used by Steps 7.1 / 7b.1 / 7c.1 to skip already-dispatched tickets.
#
#   marker.sh write  <marker-path> <ticket-id> <title> <linear-url> <session> <window> <plan-md>
#       mkdir -p the parent dir then write the marker file. Overwrites
#       silently if the marker already exists.
#       Used by Steps 7.2 / 7b.2 / 7c.2 on real-run dispatch.
#
#   marker.sh remove <marker-path>
#       rm -f the marker file. Always exits 0; a missing file is fine
#       (operator may have removed it manually).
#       Used by Step 8 archive when a ticket leaves active status.
#
#   marker.sh is-abandoned <marker-path> <repo-dir> <branch> [--hours N] [--manifest <path>] [--no-manifest-hours N]
#       Exit 0 if the marker EXISTS but the dispatched child appears to have
#       crashed before completing. Two recovery paths:
#         (A) crash-before-commit: file is older than --hours (default 168 /
#             one week, matching gc-stale-windows) AND <branch> has no commits
#             in <repo-dir> newer than the marker file.
#         (B) crash-post-commit-pre-manifest: --manifest <path> was passed AND
#             that file does NOT exist AND <branch> has commits newer than the
#             marker AND marker age > --no-manifest-hours (default 24). The
#             child clearly made progress but failed to write the completion
#             manifest; treat as crashed and recover after one day rather
#             than waiting the full --hours window.
#       Exit 1 otherwise (marker missing, marker fresh on both paths, manifest
#       present, or path (A)'s "no activity" doesn't hold).
#       Caller pairs this with `check`: if check=exists AND is-abandoned=true,
#       treat the marker as recoverable and re-dispatch.

set -u

die() { echo "marker.sh: $*" >&2; exit 1; }

# $1=path
cmd_check() {
  local marker_path=$1
  [ -f "$marker_path" ]
}

# $1=path, $2=ticket-id, $3=title, $4=ticket-url, $5=session, $6=window, $7=plan-md
cmd_write() {
  local marker_path=$1 ticket=$2 title=$3 ticket_url=$4 session=$5 window=$6 plan=$7
  mkdir -p "$(dirname "$marker_path")"
  cat > "$marker_path" <<EOF
# auto-new-day dispatch marker

ticket:        $ticket
title:         $title
ticket url:    $ticket_url
session:       $session
window:        $window
dispatched at: $(date -Iseconds)
sweep run:     $plan
EOF
}

# $1=path
cmd_remove() {
  local marker_path=$1
  rm -f "$marker_path"
}

# $1=path, $2=repo-dir, $3=branch, $4=hours, $5=manifest-path-or-empty, $6=no-manifest-hours
cmd_is_abandoned() {
  local marker_path=$1 repo_dir=$2 branch=$3 hours=$4 manifest_path=$5 no_manifest_hours=$6
  [ -f "$marker_path" ] || return 1
  local marker_epoch now_epoch age_seconds
  marker_epoch=$(stat -c %Y "$marker_path" 2>/dev/null || stat -f %m "$marker_path" 2>/dev/null)
  [ -n "$marker_epoch" ] || return 1
  now_epoch=$(date +%s)
  age_seconds=$(( now_epoch - marker_epoch ))

  # Branch newest commit epoch, 0 if no repo / no branch.
  local newest_commit_epoch=0
  if [ -d "$repo_dir/.git" ] && git -C "$repo_dir" rev-parse --verify "$branch" >/dev/null 2>&1; then
    newest_commit_epoch=$(git -C "$repo_dir" log -1 --format=%ct "$branch" 2>/dev/null || echo 0)
  fi

  # Path (A): crash-before-commit. Marker is old AND branch has no progress since.
  if [ "$age_seconds" -ge $(( hours * 3600 )) ] \
     && [ "$newest_commit_epoch" -le "$marker_epoch" ]; then
    return 0
  fi

  # Path (B): crash-post-commit-pre-manifest. Manifest is expected but absent,
  # branch HAS commits since the marker, and the marker is older than the
  # shorter no-manifest threshold (default 24h). The child clearly committed
  # but failed to write the resume manifest; recover earlier than path (A).
  if [ -n "$manifest_path" ] && [ ! -f "$manifest_path" ] \
     && [ "$newest_commit_epoch" -gt "$marker_epoch" ] \
     && [ "$age_seconds" -ge $(( no_manifest_hours * 3600 )) ]; then
    return 0
  fi

  return 1
}

case "${1:-}" in
  check)  shift; [ $# -eq 1 ] || die "check: need <marker-path>"; cmd_check "$@" ;;
  write)  shift; [ $# -eq 7 ] || die "write: need 7 args (path, ticket, title, linear-url, session, window, plan-md)"; cmd_write "$@" ;;
  remove) shift; [ $# -eq 1 ] || die "remove: need <marker-path>"; cmd_remove "$@" ;;
  is-abandoned)
    shift
    hours=168
    no_manifest_hours=24
    manifest_path=""
    args=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --hours)              shift; hours=${1:-168} ;;
        --no-manifest-hours)  shift; no_manifest_hours=${1:-24} ;;
        --manifest)           shift; manifest_path=${1:-} ;;
        *) args+=("$1") ;;
      esac
      shift
    done
    [ "${#args[@]}" -eq 3 ] || die "is-abandoned: need <marker-path> <repo-dir> <branch> [--hours N] [--manifest <path>] [--no-manifest-hours N]"
    cmd_is_abandoned "${args[0]}" "${args[1]}" "${args[2]}" "$hours" "$manifest_path" "$no_manifest_hours"
    ;;
  ""|-h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) die "unknown subcommand: $1 (try check | write | remove | is-abandoned)" ;;
esac
