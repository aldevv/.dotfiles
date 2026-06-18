#!/usr/bin/env bash
# PreToolUse hook for Bash `gh pr create`.
#
# Cross-machine glue. The actual reminder body lives in a machine-local
# skill named `pre-pr` (under ~/.claude/skills/pre-pr/). This hook just
# nudges Claude to invoke that skill before the PR. If the skill doesn't
# exist on the current machine, the suggestion is a silent no-op (Claude
# sees it isn't in the available-skills list and ignores it).
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")

case "$cmd" in
  "gh pr create"*) ;;
  *) exit 0 ;;
esac

jq -c -n --arg msg "Before running \`gh pr create\`: invoke the \`pre-pr\` skill (Skill tool, skill name \`pre-pr\`). It contains the machine-specific pre-PR checklist for this host. If \`pre-pr\` isn't in the available-skills list, no pre-PR steps are required on this machine." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $msg}}'
