# Slack rules

## CRITICAL: Slack MCP is READ-ONLY

**Never invoke any write or mutating tool on the Slack MCP (`claude.ai Slack`, or any Slack MCP).** Posting to Slack is outward-facing and cannot be reliably unsent; it is never authorized as a side effect of a task.

- **Forbidden** (all write tools): `slack_send_message`, `slack_send_message_draft`, `slack_schedule_message`, `slack_create_canvas`, `slack_update_canvas`, `slack_create_conversation`, `slack_add_reaction`, and any other Slack tool that posts, sends, schedules, creates, edits, deletes, or reacts.
- **Allowed** (read-only): `slack_search_public_and_private`, `slack_search_public`, `slack_search_channels`, `slack_search_users`, `slack_search_emojis`, `slack_read_channel`, `slack_read_thread`, `slack_read_canvas`, `slack_read_file`, `slack_read_user_profile`, `slack_list_channel_members`, `slack_get_reactions`.

If a task seems to need a Slack write, stop and ask me to send it myself.
