# Slack rules

## CRITICAL: No Slack write operations

**Whenever Slack access is available (any MCP server or CLI wrapper), write operations are absolutely forbidden.** This includes posting messages, replying in threads, scheduling messages, creating or editing canvases, adding reactions, creating conversations, or any other action that changes state in a Slack workspace. A Slack write is outward-facing and cannot be reliably unsent; it is never authorized as a side effect of a task.

Read-only access stays allowed: searching messages/files, reading channel history and thread replies, listing/looking up channels and users, reading canvases/files.

For the Slack MCP specifically:
- **Forbidden** (write tools): `slack_send_message`, `slack_send_message_draft`, `slack_schedule_message`, `slack_create_canvas`, `slack_update_canvas`, `slack_create_conversation`, `slack_add_reaction`, and any other tool that posts, sends, schedules, creates, edits, deletes, or reacts.
- **Allowed** (read-only): `slack_search_public_and_private`, `slack_search_public`, `slack_search_channels`, `slack_search_users`, `slack_search_emojis`, `slack_read_channel`, `slack_read_thread`, `slack_read_canvas`, `slack_read_file`, `slack_read_user_profile`, `slack_list_channel_members`, `slack_get_reactions`.

A `slack-write-block.sh` hook enforces this mechanically (denies matching Bash commands and any `mcp__*slack*` tool call that doesn't look read-only), but the rule holds regardless of whether the hook is present on a given machine.

If a task seems to need a Slack write, stop and ask me to send it myself.
