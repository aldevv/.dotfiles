#!/usr/bin/env bash
# PreToolUse hook for Bash `glab mr create`.
#
# Cross-machine glue. The actual reminder body lives in a machine-local
# skill named `pre-mr` (under ~/.claude/skills/pre-mr/). This hook just
# nudges Claude to invoke that skill before the MR. If the skill doesn't
# exist on the current machine, the suggestion is a silent no-op (Claude
# sees it isn't in the available-skills list and ignores it).
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")

case "$cmd" in
  "glab mr create"*) ;;
  *) exit 0 ;;
esac

jq -c -n --arg msg "Before running \`glab mr create\`: invoke the \`pre-mr\` skill (Skill tool, skill name \`pre-mr\`). It contains the machine-specific pre-MR checklist for this host. If \`pre-mr\` isn't in the available-skills list, no pre-MR steps are required on this machine." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $msg}}'
