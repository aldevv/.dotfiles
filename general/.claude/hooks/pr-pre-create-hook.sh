#!/usr/bin/env bash
# PreToolUse hook for Bash `gh pr create`.
#
# Cross-machine glue. The actual reminder body lives in a machine-local
# skill named `pr-pre-create` (under ~/.claude/skills/pr-pre-create/).
# This hook just nudges Claude to invoke that skill before the PR. If
# the skill doesn't exist on the current machine, the suggestion is a
# silent no-op (Claude sees it isn't in the available-skills list and
# ignores it).
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")

case "$cmd" in
  "gh pr create"*) ;;
  *) exit 0 ;;
esac

jq -c -n --arg msg "Before running \`gh pr create\`: invoke the \`pr-pre-create\` skill (Skill tool, skill name \`pr-pre-create\`). It contains the machine-specific pre-PR checklist for this host. If \`pr-pre-create\` isn't in the available-skills list, no pre-PR steps are required on this machine." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $msg}}'
