#!/usr/bin/env bash
# PreToolUse hook. Blocks Slack write operations (posting messages, creating
# canvases) no matter which CLI or MCP wrapper is used. Read-only Slack
# access (search, history, thread replies, user/channel lookups, channel
# downloads) stays allowed.
set -euo pipefail

input=$(cat)
tool_name=$(jq -r '.tool_name // ""' <<<"$input")
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")

REASON="Slack write operations are forbidden (posting messages, creating canvases). Read-only Slack access (search, history, lookups, downloads) is fine."

deny() {
  jq -c -n --arg reason "$REASON" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

if [[ "$tool_name" == "Bash" ]]; then
  if grep -qi 'slack' <<<"$cmd"; then
    if grep -qiE 'chat-post-message|chatpostmessage|canvasescreate|conversationscanvasescreate' <<<"$cmd"; then
      deny
    fi
  fi
  exit 0
fi

# Future-proofing: a native Slack MCP server's tools would show up as
# mcp__<server>__<toolName>. Default-deny unless the tool name looks read-only.
if [[ "$tool_name" == mcp__* ]] && grep -qi 'slack' <<<"$tool_name"; then
  if ! grep -qiE 'search|list|info|history|repl(y|ies)|lookup' <<<"$tool_name"; then
    deny
  fi
fi

exit 0
