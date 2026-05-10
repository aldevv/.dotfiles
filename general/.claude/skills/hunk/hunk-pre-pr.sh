#!/usr/bin/env bash
# PreToolUse hook for Bash(gh pr create:*) and Bash(glab mr create:*).
#
# Two-phase flow that drives review work through the *parent* Claude session
# (no `claude -p` subagent), so review uses the same context, prompt cache,
# and conversation. Exactly ONE user-visible prompt per PR/MR creation: the
# Phase-2 Allow/Deny UI prompt. No multiple confirmations.
#
#   Phase 1 (no sentinel): open Hunk in a new tmux window, drop a [pending]
#     placeholder, pre-compute the diff, set the sentinel, return
#     permissionDecision: "deny" with the review brief in additionalContext.
#     The parent session is told to clear the placeholder, apply comments
#     only if the diff has complex flows or difficult paths, then retry.
#
#   Phase 2 (sentinel fresh): clear sentinel + diff file, return
#     permissionDecision: "ask" so the user gets a single Allow/Deny UI
#     prompt. Allow → PR/MR is created; Deny → stops here, no PR/MR.
set -euo pipefail

[[ -n "${TMUX:-}" ]] || exit 0

# Defensive: if anything spawned by this hook ever runs `gh pr create` /
# `glab mr create`, the env var stops re-entry.
[[ "${HUNK_HOOK_ACTIVE:-}" == "1" ]] && exit 0
export HUNK_HOOK_ACTIVE=1

# Hooks receive the tool input as JSON on stdin:
#   {"tool_name":"Bash","tool_input":{"command":"..."},"permission_mode":"...",...}
hook_input="$(cat 2>/dev/null || true)"
tool_command="$(printf '%s' "$hook_input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
permission_mode="$(printf '%s' "$hook_input" | jq -r '.permission_mode // "default"' 2>/dev/null || echo default)"

# Split the command on whitespace-bounded shell separators (`&&`, `||`, `;`)
# and inspect each segment, so chained forms like `cd /path && gh pr create`
# are recognised, while substrings inside string literals
# (`echo "gh pr create"`) are still rejected — those segments start with
# `echo`, not `gh`.
env_prefix='^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*'
tool_label=""
artifact_label=""
while IFS= read -r seg; do
  [[ -z "$seg" ]] && continue
  if printf '%s' "$seg" | grep -qE "${env_prefix}glab[[:space:]]+mr[[:space:]]+create([[:space:]]|$)"; then
    tool_label="glab mr create"
    artifact_label="MR"
    break
  fi
  if printf '%s' "$seg" | grep -qE "${env_prefix}gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)"; then
    tool_label="gh pr create"
    artifact_label="PR"
    break
  fi
done < <(printf '%s\n' "$tool_command" | sed -E 's/[[:space:]]+(\&\&|\|\|)[[:space:]]+/\n/g; s/[[:space:]]*;[[:space:]]+/\n/g')
[[ -n "$tool_label" ]] || exit 0

# Best-effort: if the command starts with `cd <path> &&` (or similar), cd
# there so the rest of the hook (git rev-parse, diff, etc.) runs in the
# target repo. Claude Code spawns the hook in its own cwd (the project
# root), not the about-to-run command's effective cwd.
if [[ "$tool_command" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
  cd_target="${BASH_REMATCH[1]}"
  cd_target="${cd_target#\"}"; cd_target="${cd_target%\"}"
  cd_target="${cd_target#\'}"; cd_target="${cd_target%\'}"
  [[ -d "$cd_target" ]] && cd "$cd_target" 2>/dev/null || true
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[[ -n "$repo_root" ]] || exit 0

base_branch="$(git -C "$repo_root" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
base_branch="${base_branch#origin/}"
[[ -n "$base_branch" ]] || base_branch=main

range="origin/${base_branch}...HEAD"
[[ -n "$(cd "$repo_root" && git diff --stat "$range" 2>/dev/null)" ]] || exit 0

repo_name="$(basename "$repo_root")"
branch_name="$(cd "$repo_root" && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[[ -n "$repo_name" && -n "$branch_name" ]] || exit 0
window_name="hunk-${repo_name}-${branch_name}"
session_name="$(tmux display-message -p '#{session_name}')"

state_root="${XDG_RUNTIME_DIR:-/tmp}/hunk-state"
mkdir -p "$state_root"
state_key="$(printf '%s' "${session_name}-${window_name}" | tr '/ ' '__')"
sentinel="$state_root/$state_key.sentinel"
diff_file="$state_root/$state_key.diff"
sentinel_ttl=600

# Phase 2: review applied — surface ONE Allow/Deny prompt and we're done.
if [[ -f "$sentinel" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$sentinel" 2>/dev/null || echo 0) ))
  if (( age < sentinel_ttl )); then
    rm -f "$sentinel" "$diff_file"
    jq -nc --arg artifact "$artifact_label" '
      {hookSpecificOutput:{
        hookEventName:"PreToolUse",
        permissionDecision:"ask",
        permissionDecisionReason:("Review applied — inspect the hunk window and approve to create the " + $artifact + ".")
      }}
    '
    exit 0
  fi
  rm -f "$sentinel" "$diff_file"
fi

# Phase 1: open hunk if not already open, compute diff, deny + brief.
# Dedupe priority:
#   1. `hunk session list` — covers ANY pane/window already running hunk
#      for this repo (works for both the new-window and split-pane paths).
#   2. Named window match — covers the brief startup gap before the hunk
#      session registers (~1s).
# Layout choice: if the current window has only one pane, split right (less
# window churn for casual use). Otherwise open a new named window.
already_open=0
if hunk session list 2>/dev/null | grep -qF "$repo_root"; then
  already_open=1
elif tmux list-windows -t "$session_name" -F '#{window_name}' 2>/dev/null \
       | grep -Fxq "$window_name"; then
  already_open=1
fi
if (( ! already_open )); then
  pane_count="$(tmux display-message -p '#{window_panes}' 2>/dev/null || echo 0)"
  if [[ "$pane_count" == "1" ]]; then
    tmux split-window -h -t "$session_name" -c "$repo_root" \
      "hunk diff '$range'" 2>/dev/null || true
  else
    tmux new-window -t "$session_name" -n "$window_name" \
      "cd '$repo_root' && hunk diff '$range'" 2>/dev/null || true
  fi
fi

git -C "$repo_root" diff --no-color "$range" > "$diff_file" 2>/dev/null || true
[[ -s "$diff_file" ]] || { rm -f "$diff_file"; exit 0; }

touch "$sentinel"

# The parent Claude session takes ~20-60s to read the diff, compose review
# comments, and apply them. During that window the Hunk TUI looks empty and
# the user assumes the hook is broken (and may close it, killing the
# session). Drop a `[pending]` placeholder comment as soon as the Hunk
# session registers so the window has visible content immediately. The
# parent session removes the placeholder before applying real comments.
placeholder_summary="[pending] AI review in progress…"
placeholder_rationale="The main Claude session is composing review comments now. Real comments will replace this placeholder when they are ready (typically 20–60s). Leave this hunk window open."
(
  for _ in $(seq 1 15); do
    sleep 1
    hunk session list 2>/dev/null | grep -qF "$repo_root" || continue
    first_file="$(hunk session review --repo "$repo_root" --json 2>/dev/null \
      | jq -r '.review.selectedFile.path // empty')"
    [[ -n "$first_file" ]] || break
    jq -nc --arg f "$first_file" --arg s "$placeholder_summary" --arg r "$placeholder_rationale" \
      '{comments:[{filePath:$f,hunkNumber:1,summary:$s,rationale:$r}]}' \
      | hunk session comment apply --repo "$repo_root" --stdin >/dev/null 2>&1
    break
  done
) </dev/null >/dev/null 2>&1 & disown

review_brief=$(cat <<EOF
A Hunk TUI session is open in tmux window "$window_name" for $repo_root (range $range). The pre-computed diff is at $diff_file — read it with: cat $diff_file.

Comments are reserved for **complex flows or difficult paths** only. The bar is high: a comment must explain something a careful reader would still find non-obvious after reading the function. Default to applying nothing.

Apply a comment ONLY when the diff contains:
- Complex flows — multi-step coordination, non-obvious state transitions, recursion, async patterns, fan-out/await, retry loops with subtle conditions. One brief shape-of-the-flow comment at the entry point ("this fans out N tasks then awaits all, retrying any that return WouldBlock"); never per-step narration.
- Difficult paths — non-obvious invariants the reader has to hold in their head, subtle ordering requirements, workarounds for specific bugs/platform quirks, or control-flow edges that are easy to misread.

DO NOT comment on: behavioral changes obvious from the diff, cross-file invariants/rollout footguns/test gaps/env-var changes (those belong in the PR description, not the hunk session), pure renames, signature widening, comment-only edits, generated files, or anything a careful read makes obvious.

If \`hunk session list\` shows no session for $repo_root yet, wait 2s and retry up to 3 times.

STEP 1 — REMOVE THE PLACEHOLDER (always, regardless of whether you have comments to apply):

  hunk session comment list --repo $repo_root --json | \\
    jq -r '.comments[] | select(.summary | startswith("[pending]")) | .id' | \\
    while read -r cid; do hunk session comment rm "" "\$cid" --repo $repo_root; done

  (The empty positional is required: hunk's rm command takes [sessionId] then <commentId> as positionals; --repo replaces session lookup but leaves the first positional slot needing an empty string.)

STEP 2 — DECIDE:

- If the diff has NO complex flows and NO difficult paths: apply nothing. The placeholder is already gone from step 1; the hunk window stays clean. Briefly tell the user the diff was straightforward and no review comments were warranted.

- If the diff DOES have complex flows or difficult paths: apply ALL of them in ONE batch via JSON on stdin. Map files to 1-based hunk indices via the @@ -X,Y +A,B @@ headers (the Nth hunk in a file's diff is hunkNumber: N):

    printf '%s' '{"comments":[{"filePath":"path/to/file","hunkNumber":1,"summary":"one-line headline","rationale":"shape of the flow / why-it-matters"}]}' | hunk session comment apply --repo $repo_root --stdin

STEP 3 — Re-run \`$tool_label\` with the same arguments. The hook will then surface a single Allow/Deny UI prompt for the $artifact_label. Do NOT ask the user via AskUserQuestion or chat first — the hook prompt IS the user confirmation. One prompt, one decision.

Do not modify files, push commits, or run tests. The hook will clean up the diff file.
EOF
)

reason="Review the diff in hunk before opening the $artifact_label. Follow the brief in additionalContext to compose and apply review comments to the hunk session, then re-attempt \`$tool_label\` — the hook will then prompt for confirmation."

jq -nc --arg reason "$reason" --arg ctx "$review_brief" '
  {hookSpecificOutput:{
    hookEventName:"PreToolUse",
    permissionDecision:"deny",
    permissionDecisionReason:$reason,
    additionalContext:$ctx
  }}
'
exit 0
