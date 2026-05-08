#!/usr/bin/env bash
# PreToolUse hook for Bash(gh pr create:*) and Bash(glab mr create:*).
# Opens Hunk in a new tmux window for the current branch vs its base, then
# spawns a backgrounded `claude -p` subagent that reads the diff and pushes
# AI-generated review comments into the live Hunk session via
# `hunk session comment apply`. Informational — exits 0 so PR/MR creation
# proceeds in parallel.
set -euo pipefail

[[ -n "${TMUX:-}" ]] || exit 0

# Recursion guard: the backgrounded `claude -p` subagent below inherits this
# env var, so if it (or anything it spawns) ever runs `gh pr create` /
# `glab mr create`, this hook re-fires and exits here instead of spawning
# another window + subagent. Only protects within a single process tree —
# the lock file below handles serial retries from fresh subprocesses.
[[ "${HUNK_REVIEW_HOOK_ACTIVE:-}" == "1" ]] && exit 0
export HUNK_REVIEW_HOOK_ACTIVE=1

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[[ -n "$repo_root" ]] || exit 0

base_branch="$(cd "$repo_root" && git remote show origin 2>/dev/null \
  | sed -n 's/.*HEAD branch: //p')"
[[ -n "$base_branch" ]] || base_branch=main

range="origin/${base_branch}...HEAD"
[[ -n "$(cd "$repo_root" && git diff --stat "$range" 2>/dev/null)" ]] || exit 0

repo_name="$(basename "$repo_root")"
branch_name="$(cd "$repo_root" && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
# Bail if either component is empty — a name like "hunk--dev" or "hunk-foo-"
# isn't useful and would defeat dedupe.
[[ -n "$repo_name" && -n "$branch_name" ]] || exit 0
window_name="hunk-${repo_name}-${branch_name}"
session_name="$(tmux display-message -p '#{session_name}')"

# Persistent dedupe: parent claude often retries `gh pr create` serially
# (e.g. on auth prompts), and each retry is a fresh subprocess so the
# recursion-guard env var doesn't carry over. The tmux-window check below
# only catches the retry if the previous window is still alive — if `hunk
# diff` exited or the user closed it, the next retry would re-open. Use an
# atomic mkdir lock with a TTL so retries within a 10-min window are no-ops.
lock_root="${XDG_RUNTIME_DIR:-/tmp}/hunk-review-locks"
mkdir -p "$lock_root"
lock_key="$(printf '%s' "${session_name}-${window_name}" | tr '/ ' '__')"
lock_dir="$lock_root/$lock_key"
lock_ttl=600

# Clear stale lock so we can re-open after the TTL.
if [[ -d "$lock_dir" ]]; then
  lock_age=$(( $(date +%s) - $(stat -c %Y "$lock_dir" 2>/dev/null || echo 0) ))
  (( lock_age >= lock_ttl )) && rmdir "$lock_dir" 2>/dev/null || true
fi
# mkdir is atomic — only the first concurrent invocation succeeds.
mkdir "$lock_dir" 2>/dev/null || exit 0

# Belt-and-suspenders: even if the lock was just acquired, skip if a window
# with this name already exists (e.g. lock TTL expired but the user kept the
# window open).
if tmux list-windows -t "$session_name" -F '#{window_name}' 2>/dev/null \
     | grep -Fxq "$window_name"; then
  exit 0
fi

tmux new-window -t "$session_name" \
  -n "$window_name" \
  "cd '$repo_root' && hunk diff '$range'" 2>/dev/null || true

# Background subagent: read the diff, compose review comments, apply them
# to the live session. Skipped if `claude` isn't on PATH.
if command -v claude >/dev/null 2>&1; then
  log_dir="$HOME/.claude/hooks/logs"
  mkdir -p "$log_dir"
  log_file="$log_dir/hunk-review-pre-pr.log"

  prompt="A Hunk TUI session is open in another tmux window for repo \
$repo_root, range $range. Read the bundled hunk skill once: \
\$(cat \"\$(hunk skill path)\"). Read $HOME/.claude/skills/hunk-review/SKILL.md \
and follow its 'Comment style' section. Read the diff: \
git -C $repo_root diff --no-color $range. Compose review comments — only \
high-signal items (behavioral changes, cross-file invariants, rollout \
footguns, test gaps); skip mechanical changes. Map files to 1-based hunk \
indices via the @@ -X,Y +A,B @@ headers. If 'hunk session list' shows no \
session yet for $repo_root, wait briefly and retry. Apply comments in one \
batch: pipe JSON of shape {\\\"comments\\\":[{\\\"filePath\\\":...,\\\"hunkNumber\\\":...,\\\"summary\\\":...,\\\"rationale\\\":...}]} \
to: hunk session comment apply --repo $repo_root --stdin. Do not modify \
files, push commits, or run tests. Exit silently when done."

  (
    cd "$repo_root"
    nohup claude \
      -p "$prompt" \
      --dangerously-skip-permissions \
      --no-session-persistence \
      --output-format text \
      >> "$log_file" 2>&1
  ) </dev/null >/dev/null 2>&1 & disown
fi

exit 0
