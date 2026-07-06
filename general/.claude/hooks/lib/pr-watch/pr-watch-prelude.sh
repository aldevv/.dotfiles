#!/usr/bin/env bash
# Shared prelude for pr-watch.sh and the lib/pr-watch/* watchers.
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
  local exit_code tool_cmd branch default_branch push_output

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
    push_output=$(printf '%s' "$INPUT" | jq -r '(.tool_response.stdout // "") + "\n" + (.tool_response.stderr // "")')
    if printf '%s' "$push_output" | grep -qiE 'everything[[:space:]]+up.?to.?date'; then
      echo "git push was a no-op (Everything up-to-date) — exiting"
      return 1
    fi
  fi

  prelude_resolve_repo_dir

  if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    default_branch=$(git -C "$REPO_DIR" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||' || echo "")
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

# Resolve the actual repo dir the command is operating in.
# INPUT.cwd is Claude's session cwd at fire time, which does NOT follow `cd`
# inside the bash subshell. If the user ran `cd ~/.dotfiles && git push` while
# Claude's session was rooted in a different repo, INPUT.cwd points to the
# wrong tree and the watcher misfires on that tree's open PR. Honor the last
# `cd <path>` in the command when present; fall back to INPUT.cwd otherwise.
# Sets the global REPO_DIR.
prelude_resolve_repo_dir() {
  local cwd_field tool_cmd cd_path
  cwd_field=$(printf '%s' "$INPUT" | jq -r '.cwd // ""')
  tool_cmd=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')

  cd_path=$(printf '%s\n' "$tool_cmd" \
    | grep -oE '(^|[[:space:]]|;|&&|\|\|)cd[[:space:]]+[^[:space:]&;|]+' \
    | tail -n1 \
    | sed -E 's/^.*cd[[:space:]]+//')

  if [ -n "$cd_path" ]; then
    case "$cd_path" in
      '~') cd_path="$HOME" ;;
      '~/'*) cd_path="$HOME/${cd_path#'~/'}" ;;
      '$HOME') cd_path="$HOME" ;;
      '$HOME/'*) cd_path="$HOME/${cd_path#\$HOME/}" ;;
    esac
    if [ -d "$cd_path" ]; then
      REPO_DIR="$cd_path"
      return 0
    fi
  fi

  if [ -n "$cwd_field" ] && [ -d "$cwd_field" ]; then
    REPO_DIR="$cwd_field"
    return 0
  fi
  REPO_DIR=$(pwd)
  return 0
}

# Verify a git push event actually targeted the resolved PR. Parses the push
# output (the `To <remote>` line and the `<src> -> <dst>` ref-update lines) and
# checks BOTH: the pushed-to owner/repo matches the PR's owner/repo, and the
# PR's head branch is among the branches just pushed. Without this, the watcher
# misfires on pushes to a different repo or to a different branch in the same
# repo when another branch happens to have an open PR.
#
# Args: $1 = URL (resolved PR URL), $2 = PLATFORM (github|gitlab), $3 = REPO_DIR.
# No-op for non-git-push triggers (gh pr create / glab mr create resolve the URL
# from stdout directly, so the push-target check doesn't apply).
# Returns 1 if the push went elsewhere.
prelude_verify_push() {
  local url=$1 platform=$2 repo_dir=$3
  local tool_cmd push_output push_remote_raw push_repo pushed_branches
  local pr_repo pr_head_repo pr_head mr_num pr_view src_project_id

  tool_cmd=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
  if ! printf '%s' "$tool_cmd" | grep -qE '(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)'; then
    return 0
  fi

  push_output=$(printf '%s' "$INPUT" | jq -r '(.tool_response.stdout // "") + "\n" + (.tool_response.stderr // "")')
  push_remote_raw=$(printf '%s' "$push_output" | grep -E '^To ' | head -n1 | sed -E 's/^To +//')
  push_repo=$(printf '%s' "$push_remote_raw" \
    | sed -E 's|^git@||; s|^https?://||; s|^ssh://([^/]+@)?||' \
    | sed -E 's|^([^/:]+):|\1/|' \
    | sed -E 's|\.git$||' \
    | sed -E 's|^[^/]+/||')

  pushed_branches=$(printf '%s' "$push_output" | awk '{
    for (i=1; i<=NF; i++) if ($i == "->") print $(i+1)
  }')

  case "$platform" in
    github)
      pr_repo=$(printf '%s' "$url" | sed -E 's|^https?://github\.com/([^/]+/[^/]+)/.*|\1|')
      if command -v gh >/dev/null 2>&1; then
        # Fetch head ref + head-repo owner/name in one call so fork-based PRs
        # (push target is the fork, base repo is upstream) still validate.
        pr_view=$(gh pr view "$url" --json headRefName,headRepository,headRepositoryOwner 2>/dev/null || true)
        pr_head=$(printf '%s' "$pr_view" | jq -r '.headRefName // ""' 2>/dev/null || true)
        pr_head_repo=$(printf '%s' "$pr_view" \
          | jq -r 'if (.headRepositoryOwner.login // "") != "" and (.headRepository.name // "") != ""
                   then "\(.headRepositoryOwner.login)/\(.headRepository.name)"
                   else "" end' 2>/dev/null || true)
      fi
      ;;
    gitlab)
      pr_repo=$(printf '%s' "$url" | sed -E 's|^https?://[^/]+/(.+)/-/merge_requests/[0-9]+.*|\1|')
      mr_num=$(printf '%s' "$url" | grep -Eo '[0-9]+$')
      if command -v glab >/dev/null 2>&1 && [ -n "$mr_num" ]; then
        pr_view=$(cd "$repo_dir" && glab mr view "$mr_num" --output json 2>/dev/null || true)
        pr_head=$(printf '%s' "$pr_view" | jq -r '.source_branch // ""' 2>/dev/null || true)
        # If the MR is from a fork, source_project_id differs from the target
        # project; resolve it to a path so push-repo matching still works.
        src_project_id=$(printf '%s' "$pr_view" | jq -r '.source_project_id // empty' 2>/dev/null || true)
        if [ -n "$src_project_id" ] && [ -n "${HOST:-}" ]; then
          pr_head_repo=$(glab api --hostname "$HOST" "projects/$src_project_id" 2>/dev/null \
                          | jq -r '.path_with_namespace // ""' 2>/dev/null || true)
        fi
      fi
      ;;
  esac

  # Lowercase the comparison so case-insensitive hosts (GitHub) don't trip on
  # capitalization drift in user/org names.
  local push_repo_lc pr_repo_lc pr_head_repo_lc
  push_repo_lc=$(printf '%s' "$push_repo" | tr '[:upper:]' '[:lower:]')
  pr_repo_lc=$(printf '%s' "$pr_repo" | tr '[:upper:]' '[:lower:]')
  pr_head_repo_lc=$(printf '%s' "$pr_head_repo" | tr '[:upper:]' '[:lower:]')

  if [ -n "$push_repo_lc" ] && [ -n "$pr_repo_lc" ] \
      && [ "$push_repo_lc" != "$pr_repo_lc" ] \
      && [ "$push_repo_lc" != "$pr_head_repo_lc" ]; then
    if [ -n "$pr_head_repo_lc" ]; then
      echo "push target '$push_repo' matches neither PR base '$pr_repo' nor PR head '$pr_head_repo' — exiting"
    else
      echo "push target '$push_repo' does not match PR repo '$pr_repo' — exiting"
    fi
    return 1
  fi
  if [ -n "$pr_head_repo_lc" ] && [ "$push_repo_lc" = "$pr_head_repo_lc" ]; then
    echo "push target '$push_repo' matches PR head repo (fork workflow); continuing"
  fi

  if [ -n "$pushed_branches" ] && [ -n "$pr_head" ]; then
    if ! printf '%s\n' "$pushed_branches" | grep -Fxq "$pr_head"; then
      echo "PR head branch '$pr_head' was not in pushed branches ($pushed_branches) — exiting"
      return 1
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
# Requires `flock` on $PATH (linux: built-in; macOS: `brew install flock`).
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

# Pre-seed Claude Code's per-project trust state for $1=worktree path, so the
# fresh `claude` we spawn inside it doesn't pause on the workspace-trust dialog
# (there's no interactive-mode flag to skip it; the state lives in ~/.claude.json
# under .projects[<path>]). Also flips hasClaudeMdExternalIncludesApproved so the
# linked CLAUDE.md doesn't re-prompt about its external @-includes. flock keeps
# us race-safe against any other claude/hook concurrently mutating the file.
# $1=worktree path. Best-effort: missing jq / missing ~/.claude.json -> silent skip.
prelude_trust_worktree() {
  local wt=$1
  local config="$HOME/.claude.json"
  local lock="/tmp/claude-json-trust-$(id -u).lock"
  [ -z "$wt" ] && return 0
  [ -f "$config" ] || return 0
  command -v jq >/dev/null 2>&1 || { echo "[trust] jq not on PATH — skip"; return 0; }
  command -v flock >/dev/null 2>&1 || { echo "[trust] flock not on PATH — skip"; return 0; }

  (
    exec 9>"$lock"
    flock -w 5 9 || { echo "[trust] could not acquire lock on $lock — skip"; exit 0; }
    local tmp
    tmp=$(mktemp "${config}.XXXXXX")
    if jq --arg p "$wt" '
          .projects[$p] = ((.projects[$p] // {}) + {
            hasTrustDialogAccepted: true,
            hasClaudeMdExternalIncludesApproved: true,
            hasClaudeMdExternalIncludesWarningShown: true
          })
        ' "$config" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$config"
      echo "[trust] seeded hasTrustDialogAccepted=true for $wt"
    else
      rm -f "$tmp"
      echo "[trust] jq edit of $config failed — skip"
    fi
  )
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
