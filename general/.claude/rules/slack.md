# Slack rules

## CRITICAL: No Slack write operations
**Whenever Slack access is available (any MCP server or CLI wrapper), write operations are absolutely forbidden.** This includes posting messages, replying in threads, creating canvases, or any other action that changes state in a Slack workspace.

Read-only access stays allowed: searching messages/files, reading channel history and thread replies, listing/looking up channels and users, downloading channel history.

A `slack-write-block.sh` hook enforces this mechanically (denies matching Bash commands and any `mcp__*slack*` tool call that doesn't look read-only), but the rule holds regardless of whether the hook is present on a given machine.
