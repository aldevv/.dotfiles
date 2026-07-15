#!/usr/bin/env bash
# bootstrap-window.sh
# Per-window bootstrap for auto-new-day's tmux dispatches.  Runs as the first
# command in a freshly-spawned tmux pane, sets up the per-window env (guards,
# git config, branch checkout), then `exec`s the operator's login shell so the
# pane stays usable as a terminal after claude exits.
#
# Two profiles:
#
#   --profile own-work
#     - Prepends $GUARDS_DIR/bin to $PATH (gh write-shim takes effect)
#     - Unsets GH_TOKEN / GITHUB_TOKEN / GH_HOST
#     - Used by AUTO-inreview and AUTO-inprogress dispatches
#
#   --profile review
#     - Does NOT prepend any guards/bin to $PATH (residual; pr-code-review-work
#       never posts, so no shim is installed for this profile)
#     - Leaves GH_TOKEN / GITHUB_TOKEN intact
#     - Used by AUTO-inreview-others dispatches
#
# In both profiles:
#   - $AUTO_NEW_DAY_DATE_DIR and $AUTO_NEW_DAY_SNAPSHOT_CMD are exported so the
#     generic /fix-bug / /pr-code-review snapshot-hook contract fires.
#   - $GUARDS_DIR/hooks is wired as core.hooksPath (pre-push block) and
#     remote.origin.pushurl is overridden to a sentinel non-URL, IF --repo-dir
#     is supplied and points at an existing git repo.
#   - .envrc is sourced if present.
#   - The PR branch is fetched and checked out IF --pr-num and --pr-branch are
#     both supplied.
#   - The pane ends with `exec "$USER_SHELL" -l`, deriving the shell from
#     /etc/passwd (NOT $SHELL — `bash -lc` resets that to /bin/bash).
#
# Args (all required unless noted):
#   --date-dir <path>     Per-date archive dir (sets $AUTO_NEW_DAY_DATE_DIR)
#   --profile own-work|review
#                         own-work resolves guards to ~/work/.auto-new-day/guards/own-work/
#                         review   resolves guards to ~/work/.auto-new-day/guards/review/
#   --repo-dir <path>     Optional. If present, cd into it, source .envrc,
#                         wire git guards. Skipped for newconnector dispatches
#                         where no repo exists yet.
#   --pr-num <N>          Optional, paired with --pr-branch. Triggers fetch+checkout.
#   --pr-branch <name>    Optional. Local branch name to fetch into.
#   --ticket <ID>         Optional. Sets $AUTO_NEW_DAY_TICKET so the child can
#                         find its own completion manifest at
#                         $AUTO_NEW_DAY_DATE_DIR/dispatch/<TICKET>.done.json.
#                         Use this OR --window, not both.
#   --window <NAME>       Optional. Sets $AUTO_NEW_DAY_WINDOW for review-session
#                         windows; manifest path is
#                         $AUTO_NEW_DAY_DATE_DIR/dispatch/review-<NAME>.done.json.
#   --final-cwd <path>    Required. Where to `cd` before `exec`-ing the shell.
#                         For own-work in a checked-out PR: the repo dir.
#                         For newconnector: $HOME/work.
#                         For review session: $HOME/work (so /pr-code-review-work
#                         is discoverable at the parent of .claude/skills/).
#
# Exits 1 with a clear error on bad args or git-work failures (so tmux-dispatch
# surfaces "failed" in the create.md results).  Always ends with exec, never
# returns to the caller.

set -u

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

DATE_DIR=""
PROFILE=""
REPO_DIR=""
PR_NUM=""
PR_BRANCH=""
TICKET=""
WINDOW=""
FINAL_CWD=""
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --date-dir)    DATE_DIR="${2:-}"; shift 2 ;;
    --profile)     PROFILE="${2:-}"; shift 2 ;;
    --repo-dir)    REPO_DIR="${2:-}"; shift 2 ;;
    --pr-num)      PR_NUM="${2:-}"; shift 2 ;;
    --pr-branch)   PR_BRANCH="${2:-}"; shift 2 ;;
    --ticket)      TICKET="${2:-}"; shift 2 ;;
    --window)      WINDOW="${2:-}"; shift 2 ;;
    --final-cwd)   FINAL_CWD="${2:-}"; shift 2 ;;
    --force)       FORCE=1; shift ;;
    -h|--help)     usage ;;
    *)             echo "bootstrap-window.sh: unknown arg: $1" >&2; usage ;;
  esac
done

[ -n "$DATE_DIR" ]   || { echo "bootstrap-window.sh: --date-dir required" >&2; exit 1; }
[ -n "$FINAL_CWD" ]  || { echo "bootstrap-window.sh: --final-cwd required" >&2; exit 1; }
if [ -n "$TICKET" ] && [ -n "$WINDOW" ]; then
  echo "bootstrap-window.sh: --ticket and --window are mutually exclusive" >&2
  exit 1
fi

# Guards are shared across every dispatch of the same profile (the shim and
# pre-push hook contents never vary per-ticket).  Both shared dirs are created
# once per machine by `install-guards.sh` and refreshed idempotently at every
# sweep-start (Step 1c) so updates to the shim/hook flow in.
STATE_DIR="${AUTO_NEW_DAY_STATE_DIR:-$HOME/.local/state/auto-new-day}"
export AUTO_NEW_DAY_SCRIPTS_DIR="${AUTO_NEW_DAY_SCRIPTS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
case "$PROFILE" in
  own-work)
    GUARDS_DIR="$STATE_DIR/guards/own-work"
    ;;
  review)
    GUARDS_DIR="$STATE_DIR/guards/review"
    ;;
  *) echo "bootstrap-window.sh: --profile must be 'own-work' or 'review' (got: '$PROFILE')" >&2; exit 1 ;;
esac

# --- env ---
export AUTO_NEW_DAY_DATE_DIR="$DATE_DIR"
export AUTO_NEW_DAY_SNAPSHOT_CMD='"$AUTO_NEW_DAY_SCRIPTS_DIR/snapshot-inrepo.sh" --to "$AUTO_NEW_DAY_DATE_DIR" --repo "$(pwd)"'

# Identity for completion-manifest save/load. Exactly one of these is set
# (the args parser rejected both). Empty when the dispatching system isn't
# tracking per-window manifests (the global skills' fast-path no-ops).
if [ -n "$TICKET" ]; then
  export AUTO_NEW_DAY_TICKET="$TICKET"
elif [ -n "$WINDOW" ]; then
  export AUTO_NEW_DAY_WINDOW="$WINDOW"
fi

# Forwards the sweep's --force into the dispatched child. dispatch-resume.md's
# Step 0 reads this and bypasses the same-day fast-path so the child does real
# work even when a prior manifest is on disk.
if [ "$FORCE" = "1" ]; then
  export AUTO_NEW_DAY_FORCE=1
fi

# Oh-my-zsh auto-update check would block on an interactive prompt when zsh
# launches via `exec`. Disable BEFORE the exec so the child inherits.
export DISABLE_AUTO_UPDATE=true
export DISABLE_UPDATE_PROMPT=true

if [ "$PROFILE" = "own-work" ]; then
  export PATH="$GUARDS_DIR/bin:$PATH"
  unset GH_TOKEN GITHUB_TOKEN GH_HOST
fi
# For --profile review: PATH and gh tokens stay as-is (residual). pr-code-review-work
# never posts; findings go to Hunk + an answer-draft file for the operator to post.

# Resolve a path for blocked.md so per-repo setup failures surface in the
# operator's morning report instead of vanishing into a dead pane.
blocked_path() {
  local key=${TICKET:-${WINDOW:-}}
  [ -n "$key" ] || { echo ""; return; }
  mkdir -p "$DATE_DIR/dispatch" 2>/dev/null || true
  if [ -n "$TICKET" ]; then
    echo "$DATE_DIR/dispatch/${TICKET}.blocked.md"
  else
    echo "$DATE_DIR/dispatch/review-${WINDOW}.blocked.md"
  fi
}

write_blocked() {
  local reason="$1" detail="$2"
  local path
  path=$(blocked_path)
  if [ -n "$path" ]; then
    {
      echo "# bootstrap blocked"
      echo
      echo "when:   $(date -Iseconds)"
      echo "reason: $reason"
      echo
      echo '```'
      printf '%s\n' "$detail"
      echo '```'
    } >> "$path"
  fi
  echo "bootstrap-window.sh: $reason" >&2
  printf '%s\n' "$detail" >&2
}

# --- per-repo setup ---
if [ -n "$REPO_DIR" ]; then
  if [ ! -d "$REPO_DIR" ]; then
    write_blocked "--repo-dir does not exist" "$REPO_DIR"
  else
    cd "$REPO_DIR"
    if [ -f .envrc ]; then
      envrc_err=$(. ./.envrc 2>&1 >/dev/null)
      envrc_rc=$?
      if [ "$envrc_rc" -ne 0 ]; then
        write_blocked ".envrc failed to source (rc=$envrc_rc)" "$envrc_err"
      fi
    fi
    git config --local remote.origin.pushurl 'no-push://auto-new-day-blocks-this' >/dev/null 2>&1 || true
    git config --local core.hooksPath "$GUARDS_DIR/hooks" >/dev/null 2>&1 || true

    if [ -n "$PR_NUM" ] && [ -n "$PR_BRANCH" ]; then
      fetch_err=$(git fetch origin "pull/${PR_NUM}/head:${PR_BRANCH}" -f 2>&1)
      fetch_rc=$?
      if [ "$fetch_rc" -ne 0 ]; then
        write_blocked "git fetch pull/${PR_NUM}/head failed (rc=$fetch_rc)" "$fetch_err"
      else
        co_err=$(git checkout "$PR_BRANCH" 2>&1)
        co_rc=$?
        if [ "$co_rc" -ne 0 ]; then
          write_blocked "git checkout ${PR_BRANCH} failed (rc=$co_rc)" "$co_err"
        else
          git pull --ff-only origin "$PR_BRANCH" >/dev/null 2>&1 || true
        fi
      fi
    fi
  fi
fi

# --- final cwd + exec the operator's login shell ---
# `bash -lc` (the caller's outer wrapper) resets $SHELL=/bin/bash for the
# subprocess, so we can't trust $SHELL here. Derive from /etc/passwd instead.
USER_SHELL=$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7 || true)
[ -n "$USER_SHELL" ] || USER_SHELL=/bin/bash

cd "$FINAL_CWD"
exec "$USER_SHELL" -l
