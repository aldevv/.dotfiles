# Slack rules

## CRITICAL: No Slack write operations

**Whenever Slack access is available (any MCP server or CLI wrapper), write operations are absolutely forbidden.** This includes posting messages, replying in threads, scheduling messages, creating or editing canvases, adding reactions, creating conversations, or any other action that changes state in a Slack workspace. A Slack write is outward-facing and cannot be reliably unsent; it is never authorized as a side effect of a task.

Read-only access stays allowed: searching messages/files, reading channel history and thread replies, listing/looking up channels and users, reading canvases/files.

For the Slack MCP specifically:
- **Forbidden** (write tools): `slack_send_message`, `slack_send_message_draft`, `slack_schedule_message`, `slack_create_canvas`, `slack_update_canvas`, `slack_create_conversation`, `slack_add_reaction`, and any other tool that posts, sends, schedules, creates, edits, deletes, or reacts.
- **Allowed** (read-only): `slack_search_public_and_private`, `slack_search_public`, `slack_search_channels`, `slack_search_users`, `slack_search_emojis`, `slack_read_channel`, `slack_read_thread`, `slack_read_canvas`, `slack_read_file`, `slack_read_user_profile`, `slack_list_channel_members`, `slack_get_reactions`.

A `slack-write-block.sh` hook enforces this mechanically (denies matching Bash commands and any `mcp__*slack*` tool call that doesn't look read-only), but the rule holds regardless of whether the hook is present on a given machine.

If a task seems to need a Slack write, stop and ask me to send it myself.

## Exception: my-notifications replies

Slack writes are approved when they come from the `my-notifications` repo (`aldevv/my-notifications`), i.e. `slack-reply` posting a message I confirmed by tapping Send on the phone: a thread reply (`th:`), a new DM message (`dm:`), or a new channel message (`ch:`):
- G (SoFi Slack, Mac): `slack-reply g` posts through `sofi-mcp-cli`.
- C (ConductorOne Slack, titan): `slack-reply c` runs headless `claude -p` with `MY_NOTIFICATIONS_SLACK_REPLY=1`, which `slack-write-block.sh` lets through for `mcp__claude_ai_Slack__slack_send_message` only.

That includes running `slack-reply` (or its test chain) to test a reply to my own self-DM when I ask for it. Any other Slack write stays forbidden; never post with `sofi-mcp-cli` directly or set `MY_NOTIFICATIONS_SLACK_REPLY` in an interactive session to work around the hook.

**If you are the headless run that `slack-reply c` started** (your system prompt says so, you have no shell, and your only tools are `slack_send_message` plus Slack read tools), you ARE the approved path: post the confirmed message exactly as instructed, as a thread reply or a new message as the prompt says. The hook only lets `slack_send_message` through when `slack-reply` set the env var, so an interactive session can't use this.

**Also allowed:** a channel I allowlisted for bot requests in a work-scope rules file (the work tree's lazy Slack notes). There, posting a request to that channel's bot is allowed, only with the exact message text I approved, and nothing else (no replies to people, no reactions, no edits, no other channels).
