#!/usr/bin/env bash
# PreToolUse hook for Bash(gh pr create:*) and Bash(glab mr create:*).
# Opens Hunk in a new tmux window for the current branch vs its base, then
# spawns a backgrounded `claude -p` subagent that reads the diff and pushes
# AI-generated review comments into the live Hunk session via
# `hunk session comment apply`. Informational — exits 0 so PR/MR creation
# proceeds in parallel.
set -euo pipefail

[[ -n "${TMUX:-}" ]] || exit 0

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

base_branch="$(cd "$repo_root" && git remote show origin 2>/dev/null \
  | sed -n 's/.*HEAD branch: //p')"
[[ -n "$base_branch" ]] || base_branch=main

range="origin/${base_branch}...HEAD"
[[ -n "$(cd "$repo_root" && git diff --stat "$range" 2>/dev/null)" ]] || exit 0

tmux new-window -t "$(tmux display-message -p '#{session_name}')" \
  -n hunk-pre-pr \
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
