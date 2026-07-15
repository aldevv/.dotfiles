#!/usr/bin/env bash
# Fast-forward the local PR branch when a foreign contributor (anyone other
# than the operator's own gh account) pushes commits to one of the operator's
# own in-review PRs. The caller decides who counts as "foreign"; this script
# just ff-merges pull/<N>/head.
#
# Called by Step 3 step 6 of the auto-new-day sweep AFTER foreign commits are
# detected on a ticket. Safe to call regardless of bucket (quiet / approved /
# actionable), so the operator's local checkout stays in sync with what the
# teammate pushed even when the sweep does not dispatch a window for that
# ticket.
#
# Best-effort: any failure logs and exits 0 so the sweep continues.
#
# Usage: pull-foreign-commits.sh <repo-dir> <pr-num> <pr-branch> [--log <path>]

set -o pipefail

REPO_DIR="${1:-}"
PR_NUM="${2:-}"
PR_BRANCH="${3:-}"
LOG=""
shift 3 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --log) LOG="${2:-}"; shift 2 ;;
    *)     shift ;;
  esac
done

log() {
  if [ -n "$LOG" ]; then
    mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
    printf '[%s] %s\n' "$(date -Iseconds)" "$*" >>"$LOG" 2>/dev/null || true
  fi
}

if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR" ]; then
  log "skip: repo-dir missing ($REPO_DIR)"
  exit 0
fi
if [ -z "$PR_NUM" ] || [ -z "$PR_BRANCH" ]; then
  log "skip: pr-num/pr-branch missing (num=$PR_NUM branch=$PR_BRANCH)"
  exit 0
fi

cd "$REPO_DIR" || { log "skip: cd failed ($REPO_DIR)"; exit 0; }

if ! err=$(git fetch origin "pull/${PR_NUM}/head" 2>&1); then
  log "fetch failed for $PR_BRANCH (#$PR_NUM): $err"
  exit 0
fi

new_sha=$(git rev-parse FETCH_HEAD 2>/dev/null || true)
if [ -z "$new_sha" ]; then
  log "no FETCH_HEAD after fetch for $PR_BRANCH (#$PR_NUM)"
  exit 0
fi

current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || true)

if [ "$current_branch" = "$PR_BRANCH" ]; then
  old_sha=$(git rev-parse HEAD 2>/dev/null || true)
  if [ "$old_sha" = "$new_sha" ]; then
    log "$PR_BRANCH: already at $new_sha, nothing to pull"
    exit 0
  fi
  stash_ref=""
  if [ -n "$(git status --porcelain)" ]; then
    stash_msg="auto-new-day pre-pull $(date -Iseconds)"
    if ! err=$(git stash push --include-untracked -m "$stash_msg" 2>&1); then
      log "$PR_BRANCH: stash failed, skipping ff-merge: $err"
      exit 0
    fi
    stash_ref=$(git rev-parse -q --verify stash@{0} 2>/dev/null || true)
    log "$PR_BRANCH: stashed dirty tree as $stash_ref (\"$stash_msg\")"
  fi
  if ! err=$(git merge --ff-only "$new_sha" 2>&1); then
    log "$PR_BRANCH: non-ff (local diverged from remote), skipping: $err"
    if [ -n "$stash_ref" ]; then
      if ! perr=$(git stash pop 2>&1); then
        log "$PR_BRANCH: stash left in place ($stash_ref); pop failed: $perr"
      else
        log "$PR_BRANCH: stash popped after failed ff"
      fi
    fi
    exit 0
  fi
  log "$PR_BRANCH: ff-merged $old_sha -> $new_sha"
  if [ -n "$stash_ref" ]; then
    if ! perr=$(git stash pop 2>&1); then
      log "$PR_BRANCH: ff-merge applied, but stash pop conflicted; stash preserved at $stash_ref, resolve with 'git stash pop': $perr"
    else
      log "$PR_BRANCH: stash popped cleanly onto new HEAD"
    fi
  fi
else
  old_sha=$(git rev-parse "refs/heads/$PR_BRANCH" 2>/dev/null || true)
  if [ "$old_sha" = "$new_sha" ]; then
    log "$PR_BRANCH: ref already at $new_sha, nothing to pull"
    exit 0
  fi
  if ! err=$(git update-ref "refs/heads/$PR_BRANCH" "$new_sha" "$old_sha" 2>&1); then
    if ! err=$(git update-ref "refs/heads/$PR_BRANCH" "$new_sha" 2>&1); then
      log "$PR_BRANCH: update-ref failed: $err"
      exit 0
    fi
  fi
  log "$PR_BRANCH: ref updated ${old_sha:-<new>} -> $new_sha (branch not checked out)"
fi

exit 0
