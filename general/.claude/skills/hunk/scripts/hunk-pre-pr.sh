#!/usr/bin/env bash
# PreToolUse hook for Bash `gh pr create` and `glab mr create` invocations.
#
# Drives review work through the *parent* Claude session (no `claude -p`
# subagent), so review uses the same context, prompt cache, and conversation.
# The flow is 2-phase in default-ish modes and 3-phase in bypassPermissions,
# because `permissionDecision: "ask"` is silently auto-allowed in bypass.
#
#   Phase 1 (no sentinel): open Hunk in a new tmux window, drop a [pending]
#     placeholder, pre-compute the diff, write sentinel=1, return
#     permissionDecision: "deny" with the review brief in additionalContext.
#
#   Phase 2 (sentinel=1):
#     - default-ish modes: clear sentinel + diff file, return
#       permissionDecision: "ask" so the user gets an Allow/Deny UI prompt.
#     - bypassPermissions: advance sentinel to 2, return "deny" with a reason
#       that instructs the parent to call AskUserQuestion (since "ask" would
#       silently auto-allow in this mode).
#
#   Phase 3 (sentinel=2, only reached from bypassPermissions): clear sentinel
#     + diff file and exit 0 with no decision. The user already confirmed via
#     the Phase-2 AskUserQuestion. Returning no permissionDecision lets later
#     PreToolUse hooks (e.g. pre-mr-check) still run and block on their own
#     checks; an explicit "allow" here would prevent them from blocking.
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

# Best-effort: cd to the last `cd <path>` in the chained command so the rest
# of the hook (git rev-parse, diff) runs in the target repo. Claude Code
# spawns the hook in the session cwd, not the about-to-run command's
# effective cwd. Handles `cd` at any segment position and expands `~` /
# `$HOME` without eval.
cd_target=$(printf '%s\n' "$tool_command" \
  | grep -oE '(^|[[:space:]]|;|&&|\|\|)cd[[:space:]]+[^[:space:]&;|]+' \
  | tail -n1 | sed -E 's/^.*cd[[:space:]]+//')
cd_target="${cd_target#\"}"; cd_target="${cd_target%\"}"
cd_target="${cd_target#\'}"; cd_target="${cd_target%\'}"
case "$cd_target" in
  '~')       cd_target="$HOME" ;;
  '~/'*)     cd_target="$HOME/${cd_target#'~/'}" ;;
  '$HOME')   cd_target="$HOME" ;;
  '$HOME/'*) cd_target="$HOME/${cd_target#\$HOME/}" ;;
esac
[[ -n "$cd_target" && -d "$cd_target" ]] && cd "$cd_target" 2>/dev/null || true

# Skip inside auto-new-day dispatched tmux sessions. The dispatch skills
# (`fix-bug-work`, `impl-connector`, `newconnector`, `pr-code-review-work`)
# already run `/hunk` themselves before returning control, so re-opening
# Hunk on `gh pr create` / `glab mr create` is redundant.
case "$(tmux display-message -p '#{session_name}' 2>/dev/null || true)" in
  AUTO-inreview|AUTO-inprogress|AUTO-inreview-others) exit 0 ;;
esac

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[[ -n "$repo_root" ]] || exit 0

base_branch="$(git -C "$repo_root" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
base_branch="${base_branch#origin/}"
[[ -n "$base_branch" ]] || base_branch=main

range="origin/${base_branch}...HEAD"
[[ -n "$(cd "$repo_root" && git diff --stat "$range" 2>/dev/null)" ]] || exit 0

repo_name="$(basename "$repo_root")"
branch_name="$(cd "$repo_root" && git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[[ -n "$repo_name" && -n "$branch_name" ]] || exit 0
window_name="hunk-${repo_name}:${branch_name}"
session_name="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
[[ -n "$session_name" ]] || exit 0

state_root="${XDG_RUNTIME_DIR:-/tmp}/hunk-state"
mkdir -p "$state_root"
state_key="$(printf '%s' "${session_name}-${window_name}" | tr '/ ' '__')"
sentinel="$state_root/$state_key.sentinel"
diff_file="$state_root/$state_key.diff"
sentinel_ttl=600

current_phase=""
if [[ -f "$sentinel" ]]; then
  age=$(( $(date +%s) - $(stat -f %m "$sentinel" 2>/dev/null || stat -c %Y "$sentinel" 2>/dev/null || echo 0) ))
  if (( age < sentinel_ttl )); then
    current_phase="$(cat "$sentinel" 2>/dev/null || true)"
  else
    rm -f "$sentinel" "$diff_file"
  fi
fi

# Phase 3 (bypassPermissions only): user already confirmed via
# AskUserQuestion in Phase 2. Exit 0 with no decision so later PreToolUse
# hooks (pre-mr-check, etc.) still run and can block.
if [[ "$current_phase" == "2" ]]; then
  rm -f "$sentinel" "$diff_file"
  exit 0
fi

# Phase 2: review applied. Branch on permission_mode.
if [[ "$current_phase" == "1" ]]; then
  if [[ "$permission_mode" == "bypassPermissions" ]]; then
    printf '2' > "$sentinel"
    reason="bypassPermissions mode auto-allows \"ask\", so this hook can't show an Allow/Deny UI prompt directly. Call AskUserQuestion with question=\"Create the $artifact_label?\" and options=[\"Yes, create it\", \"No, abort\"]. On \"Yes\", re-run \`$tool_label\` with the same arguments; on \"No\", stop."
    jq -nc --arg r "$reason" '
      {hookSpecificOutput:{
        hookEventName:"PreToolUse",
        permissionDecision:"deny",
        permissionDecisionReason:$r
      }}
    '
    exit 0
  fi
  rm -f "$sentinel" "$diff_file"
  jq -nc --arg artifact "$artifact_label" '
    {hookSpecificOutput:{
      hookEventName:"PreToolUse",
      permissionDecision:"ask",
      permissionDecisionReason:("Review applied. Inspect the hunk window and approve to create the " + $artifact + ".")
    }}
  '
  exit 0
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

printf '1' > "$sentinel"

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

TONE — when you do apply a comment:
- Short. One or two sentences max. If you need more, split it or drop it.
- Informal, plain language. No jargon, no hedges, no ceremony. Write like you'd explain it to a colleague over chat. Lowercase, contractions, fragments are fine.
- \`summary\` is the headline (~80 chars, no period needed). \`rationale\` is the "why" in one or two short sentences — don't restate the summary.

If \`hunk session list\` shows no session for $repo_root yet, wait 2s and retry up to 3 times.

STEP 1 — REMOVE THE PLACEHOLDER (always, regardless of whether you have comments to apply):

  hunk session comment list --repo $repo_root --json | \\
    jq -r '.comments[] | select(.summary | startswith("[pending]")) | .commentId' | \\
    while read -r cid; do hunk session comment rm "\$cid" --repo $repo_root; done

  (With --repo, hunk's rm command takes exactly one positional: the <commentId>. The two-form signature is "<session-id> <commentId>" OR "<commentId> --repo <path>".)

STEP 2 — DECIDE:

- If the diff has NO complex flows and NO difficult paths: apply nothing. The placeholder is already gone from step 1; the hunk window stays clean. Briefly tell the user the diff was straightforward and no review comments were warranted.

- If the diff DOES have complex flows or difficult paths: apply ALL of them in ONE batch via JSON on stdin. Map files to 1-based hunk indices via the @@ -X,Y +A,B @@ headers (the Nth hunk in a file's diff is hunkNumber: N):

    printf '%s' '{"comments":[{"filePath":"path/to/file","hunkNumber":1,"summary":"one-line headline","rationale":"shape of the flow / why-it-matters"}]}' | hunk session comment apply --repo $repo_root --stdin

STEP 3 — STOP and let the user review Hunk.

Tell the user in chat:
- What you applied (or that you chose to skip — one short sentence on why).
- That the Hunk TUI window "$window_name" is open and ready for their review.
- That you'll re-run \`$tool_label\` ONLY after they confirm they're done looking at Hunk.

Wait for an affirmative reply from the user (e.g. "go", "lgtm", "create the $artifact_label") before re-running \`$tool_label\`. Do NOT re-run immediately — the user needs wall-clock time to actually look at the Hunk window in tmux, and the gap between your "applied" report and a re-run is what prevents them from reviewing.

When the user confirms, re-run \`$tool_label\` with the same arguments. The hook will then surface a single Allow/Deny UI prompt for the $artifact_label as the final confirmation gate.

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
