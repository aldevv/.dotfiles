#!/usr/bin/env bash
# Shared prelude for gh-pr-post-watch-{checks,comments}.sh.
# Source this file; do not exec it.
# Callers must have $INPUT (raw JSON stdin) set before calling these helpers.
#
# Functions:
#   prelude_should_proceed   - exit-fast gates (exit_code, --tags/delete/dry-run,
#                              default-branch push, no upstream). Returns 1 to bail.
#   prelude_dedup_event PFX  - atomic mkdir keyed on stdin hash. Kills the
#                              N-matcher fan-out (3 if: clauses → 1 winner).
#                              Returns 1 if another instance already won.
#   prelude_acquire_pr_lock PFX URL - flock on (cwd, branch, PR-num). Held for
#                              the lifetime of the script. Returns 1 if held.
#   prelude_pr_is_open URL   - returns 0 iff the PR/MR is open (not merged/closed).
#                              Requires PLATFORM and (for gitlab) HOST/PROJ_PATH_ENC/MR_IID.
#   prelude_create_fix_worktree DIR SHA PREFIX - create/attach a worktree for a
#                              fixer to operate in. Sets FIX_BRANCH and WT_PATH.
#                              Returns 1 if no worktree could be created.

# Exit silently if the tool itself failed, if the command is one we should
# never watch (tag pushes, deletes, dry-runs, mirror/all, ci-skip), or if
# the current branch is the repo's default branch.
prelude_should_proceed() {
  local exit_code tool_cmd repo_dir branch default_branch

  exit_code=$(printf '%s' "$INPUT" | jq -r '.tool_response.exit_code // 0')
  case "$exit_code" in
    0|null|"") ;;
    *) echo "tool exited non-zero (rc=$exit_code) — exiting"; return 1 ;;
  esac

  tool_cmd=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')

  if ! printf '%s' "$tool_cmd" | grep -qE '(^|[[:space:]]|[;&|]|&&|\|\|)(git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create|glab[[:space:]]+mr[[:space:]]+create)([[:space:]]|$)'; then
    echo "tool_cmd does not contain git push / gh pr create / glab mr create — exiting"
    return 1
  fi

  if printf '%s' "$tool_cmd" | grep -qE '(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)'; then
    if printf '%s' "$tool_cmd" | grep -qE -- '(^|[[:space:]])(--tags|--delete|--dry-run|--mirror|--all)([[:space:]]|$)'; then
      echo "git push variant ignored (tags/delete/dry-run/mirror/all) — exiting"
      return 1
    fi
    if printf '%s' "$tool_cmd" | grep -qE -- '-o[[:space:]]+ci\.skip'; then
      echo "git push -o ci.skip — exiting"
      return 1
    fi
    if printf '%s' "$tool_cmd" | grep -qE 'git[[:space:]]+push[[:space:]][^|;&]*[[:space:]]:[^[:space:]]'; then
      echo "git push refspec deletion (:branch) — exiting"
      return 1
    fi
  fi

  repo_dir=$(printf '%s' "$INPUT" | jq -r '.cwd // ""')
  [ -d "$repo_dir" ] || repo_dir=$(pwd)
  if git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    default_branch=$(git -C "$repo_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||' || echo "")
    if [ -n "$branch" ]; then
      case "$branch" in
        HEAD)
          echo "detached HEAD — exiting"; return 1 ;;
        "$default_branch"|main|master|trunk|develop)
          echo "branch '$branch' is default/protected — exiting"; return 1 ;;
      esac
    fi
  fi

  return 0
}

# Atomic-mkdir dedup on a hash of the full stdin. Multiple if: clauses on the
# same Bash tool call produce identical stdin, so only one mkdir wins. Loser
# instances exit silently. The marker is GC'd ~5 minutes later by a detached
# subshell; lingering markers are harmless.
prelude_dedup_event() {
  local prefix=$1
  local key dir
  key=$(printf '%s' "$INPUT" | sha256sum | cut -c1-32)
  dir="/tmp/${prefix}-events-$(id -u)"
  mkdir -p "$dir"
  if ! mkdir "$dir/$key" 2>/dev/null; then
    echo "duplicate event for $prefix (key=$key) — exiting"
    return 1
  fi
  ( sleep 300; rmdir "$dir/$key" 2>/dev/null ) &
  disown 2>/dev/null || true
  return 0
}

# Acquire a flock on (cwd, branch, PR-number). One active watcher per PR.
# Caller passes the URL; lock is held for the lifetime of the script via fd 9.
prelude_acquire_pr_lock() {
  local prefix=$1 url=$2
  local repo_dir branch pr_num key dir
  repo_dir=$(printf '%s' "$INPUT" | jq -r '.cwd // ""')
  [ -d "$repo_dir" ] || repo_dir=$(pwd)
  branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  pr_num=$(printf '%s' "$url" | grep -Eo '(pull|merge_requests)/[0-9]+' | grep -Eo '[0-9]+' | head -n1)
  key=$(printf '%s|%s|%s' "$repo_dir" "$branch" "$pr_num" | sha256sum | cut -c1-16)
  dir="/tmp/${prefix}-prlocks-$(id -u)"
  mkdir -p "$dir"
  LOCK_FILE="$dir/$key.lock"
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    echo "another $prefix watcher holds $LOCK_FILE (cwd=$repo_dir branch=$branch pr=$pr_num) — exiting"
    return 1
  fi
  echo "$$" >&9 2>/dev/null || true
  return 0
}

# Create (or attach to) a worktree for a fixer to operate in, so concurrent
# fixers and the operator's main checkout never clobber each other.
# Inputs: $1=repo dir, $2=HEAD sha to base off, $3=prefix (e.g. "ci-fix").
# Sets FIX_BRANCH and WT_PATH on success. Returns 1 if no worktree could be
# created — caller MUST skip the fixer in that case (do not fall back to the
# main checkout; that's what the worktree is meant to protect).
prelude_create_fix_worktree() {
  local repo_dir=$1 head_sha=$2 prefix=$3
  local repo_root repo_name short_sha wt_home f
  repo_root=$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null || echo "$repo_dir")
  repo_name=$(basename "$repo_root")
  short_sha=$(printf '%s' "$head_sha" | cut -c1-8)
  wt_home="${WT_HOME:-$HOME/worktrees}"
  FIX_BRANCH="${prefix}-${short_sha}"
  WT_PATH="$wt_home/$repo_name/$FIX_BRANCH"

  if [ -d "$WT_PATH" ] && git -C "$WT_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "worktree $WT_PATH already exists — reusing"
    return 0
  fi

  mkdir -p "$(dirname "$WT_PATH")"
  if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$FIX_BRANCH"; then
    if git -C "$repo_root" worktree add "$WT_PATH" "$FIX_BRANCH" 2>&1; then
      echo "attached worktree $WT_PATH to existing branch $FIX_BRANCH"
      return 0
    fi
    echo "git worktree add (attach) failed for $WT_PATH"
    return 1
  fi

  if ! git -C "$repo_root" worktree add -b "$FIX_BRANCH" "$WT_PATH" "$head_sha" 2>&1; then
    echo "git worktree add (-b) failed for $WT_PATH"
    return 1
  fi
  echo "created worktree $WT_PATH on new branch $FIX_BRANCH from $head_sha"
  for f in .envrc CLAUDE.md CLAUDE.local.md; do
    if [ -e "$repo_root/$f" ] && [ ! -e "$WT_PATH/$f" ]; then
      ln -s "$repo_root/$f" "$WT_PATH/$f" 2>/dev/null || true
    fi
  done
  if [ -e "$repo_root/.claude" ] && [ ! -e "$WT_PATH/.claude" ]; then
    ln -s "$repo_root/.claude" "$WT_PATH/.claude" 2>/dev/null || true
  fi
  return 0
}

# Check the PR/MR is OPEN (not merged or closed). Requires PLATFORM set.
# For gitlab, also requires HOST, PROJ_PATH_ENC, MR_IID.
prelude_pr_is_open() {
  local url=$1 state
  case "$PLATFORM" in
    github)
      state=$(gh pr view "$url" --json state --jq '.state // ""' 2>/dev/null || echo "")
      [ "$state" = "OPEN" ] && return 0
      echo "PR state=$state (not OPEN) — exiting"
      return 1
      ;;
    gitlab)
      state=$(glab api --hostname "$HOST" "projects/${PROJ_PATH_ENC}/merge_requests/${MR_IID}" 2>/dev/null \
                | jq -r '.state // ""' 2>/dev/null || echo "")
      [ "$state" = "opened" ] && return 0
      echo "MR state=$state (not opened) — exiting"
      return 1
      ;;
  esac
  return 1
}
