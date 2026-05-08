#!/usr/bin/env bash
# PreToolUse hook for Bash(gh pr create:*) and Bash(glab mr create:*).
#
# Three-phase flow that drives review work through the *parent* Claude session
# (no `claude -p` subagent), so review uses the same context, prompt cache,
# and conversation. Phase 2 branches by `permission_mode` because
# bypassPermissions auto-allows `permissionDecision: "ask"` — meaning the UI
# prompt would never appear and the PR would silently get created.
#
#   Phase 1 (no sentinels): open Hunk in a new tmux window, drop a [pending]
#     placeholder, pre-compute the diff, set sentinel.phase1, return
#     permissionDecision: "deny" with the review brief in additionalContext.
#     The parent session is told to compose comments, apply them, then retry.
#
#   Phase 2 (sentinel.phase1 fresh):
#     - default mode: return permissionDecision: "ask" so the user gets a
#       literal Allow/Deny UI prompt. Cleanup happens here.
#     - bypassPermissions mode: return permissionDecision: "deny" with a
#       reason instructing the assistant to confirm in conversation, then set
#       sentinel.phase2 so the *next* retry is allowed.
#
#   Phase 3 (sentinel.phase2 fresh, bypass-only): allow silently. The user
#     has already confirmed in conversation. Cleanup happens here.
set -euo pipefail

[[ -n "${TMUX:-}" ]] || exit 0

# Defensive: if anything spawned by this hook ever runs `gh pr create` /
# `glab mr create`, the env var stops re-entry.
[[ "${HUNK_REVIEW_HOOK_ACTIVE:-}" == "1" ]] && exit 0
export HUNK_REVIEW_HOOK_ACTIVE=1

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

state_root="${XDG_RUNTIME_DIR:-/tmp}/hunk-review-state"
mkdir -p "$state_root"
state_key="$(printf '%s' "${session_name}-${window_name}" | tr '/ ' '__')"
sentinel_phase1="$state_root/$state_key.phase1"
sentinel_phase2="$state_root/$state_key.phase2"
diff_file="$state_root/$state_key.diff"
sentinel_ttl=600

# Phase 3 (bypass-only): user confirmed in conversation, allow silently.
if [[ -f "$sentinel_phase2" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$sentinel_phase2" 2>/dev/null || echo 0) ))
  if (( age < sentinel_ttl )); then
    rm -f "$sentinel_phase2" "$diff_file"
    exit 0
  fi
  rm -f "$sentinel_phase2"
fi

# Phase 2: review applied, time to confirm.
if [[ -f "$sentinel_phase1" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$sentinel_phase1" 2>/dev/null || echo 0) ))
  if (( age < sentinel_ttl )); then
    rm -f "$sentinel_phase1"
    if [[ "$permission_mode" == "bypassPermissions" ]]; then
      # Bypass auto-allows "ask" — force conversation confirmation via deny.
      # Phase 3 will allow on the next retry.
      touch "$sentinel_phase2"
      jq -nc --arg artifact "$artifact_label" --arg tool "$tool_label" '
        {hookSpecificOutput:{
          hookEventName:"PreToolUse",
          permissionDecision:"deny",
          permissionDecisionReason:("Review applied — bypassPermissions mode is active, so an Allow/Deny UI prompt would auto-allow. Use the AskUserQuestion tool to surface a structured prompt with the question \"Inspect the hunk window — ready to create the " + $artifact + "?\" and two options: \"Yes, create it\" (retry `" + $tool + "` once; the hook will allow it) and \"No, cancel\" (do nothing). Do not ask via plain chat — use AskUserQuestion so the user gets a clear chip-style choice.")
        }}
      '
    else
      rm -f "$diff_file"
      jq -nc --arg artifact "$artifact_label" '
        {hookSpecificOutput:{
          hookEventName:"PreToolUse",
          permissionDecision:"ask",
          permissionDecisionReason:("Review applied — inspect the hunk window and approve to create the " + $artifact + ".")
        }}
      '
    fi
    exit 0
  fi
  rm -f "$sentinel_phase1" "$diff_file"
fi

# Phase 1: open hunk window if not already open, compute diff, deny + brief.
if ! tmux list-windows -t "$session_name" -F '#{window_name}' 2>/dev/null \
       | grep -Fxq "$window_name"; then
  tmux new-window -t "$session_name" -n "$window_name" \
    "cd '$repo_root' && hunk diff '$range'" 2>/dev/null || true
fi

git -C "$repo_root" diff --no-color "$range" > "$diff_file" 2>/dev/null || true
[[ -s "$diff_file" ]] || { rm -f "$diff_file"; exit 0; }

touch "$sentinel_phase1"

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

Compose 3–7 high-signal review comments only: behavioral changes, complex flows (one brief shape-of-the-flow comment at the entry point — fan-out/await, state transitions, async/recursion — not per-step narration; skip if a careful read makes it obvious), cross-file invariants, rollout footguns, test gaps. Skip mechanical changes (renames, signature widening, comment-only edits, generated files). Map files to 1-based hunk indices via the @@ -X,Y +A,B @@ headers (the Nth hunk in a file's diff is hunkNumber: N).

If \`hunk session list\` shows no session for $repo_root yet, wait 2s and retry up to 3 times.

BEFORE applying real comments, remove the hook's placeholder: run \`hunk session comment list --repo $repo_root --json\`, find every comment whose summary starts with \`[pending]\`, and \`hunk session comment rm "" <id> --repo $repo_root\` each one. (The empty positional is required: hunk's rm command takes [sessionId] then <commentId> as positionals; --repo replaces the session lookup but leaves the first positional slot needing to be filled with an empty string.)

Then apply ALL real comments in ONE batch via JSON on stdin:

printf '%s' '{"comments":[{"filePath":"path/to/file","hunkNumber":1,"summary":"one-line headline","rationale":"why-it-matters"}]}' | hunk session comment apply --repo $repo_root --stdin

After the comments are applied, re-run \`$tool_label\` with the same arguments. The hook will then either surface an Allow/Deny UI prompt (default permission mode) or deny again with instructions to ask the user in conversation (bypassPermissions mode). Either way, the $artifact_label is only created after explicit user approval.

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
