---
name: slack-request-review
description: Draft a short Slack message asking a channel to review a PR/MR, in the same shape the team already uses, learned from a cached examples file of real review requests. Triggers on "/slack-request-review", "ask for a review in slack", "slack message to request review", "how do I request a review for this in slack", "ping the team for a review", "need reviewers on this MR", "post in #<channel> asking for review", "draft a slack message for the review", or just "ask the team to look at this MR". Drafts only, never posts. Use `add-comment` for comments on the PR/MR itself, and `humanize` to reword a Slack draft that already exists.
argument-hint: "[PR/MR URL or number] [channel name, no #]"
---

# slack-request-review

Write the Slack message that asks for a review of a PR/MR, matching how people in the target channel already ask. **Draft only: never post to Slack.** The operator sends it.

## Examples file

Real review requests live in a per-channel file outside source control. `<channel>` is the bare channel name, lowercase, no `#`:

```
${XDG_CACHE_HOME:-~/.cache}/slack-request-review/<channel>.md
```

Layout: a `# Review requests in #<channel>` header, then `## Mine` (the operator's own messages, their voice) and `## Team` (everyone else), one `- ` bullet per message. It can contain anything, including work names, because it never lands in a repo.

## Workflow

1. **Pick the channel.** Use the argument. Without one, and if exactly one examples file exists, use it. Otherwise ask which channel.
2. **Load or build the examples file.** Age = the file's mtime.
   - **Fresh (30 days or less):** use it.
   - **Missing or stale:** read 200+ messages of channel history (page if needed) with whatever read-only Slack access exists, an MCP server or a CLI. Find the operator's Slack user id (a whoami call, or a hit on their own name).
     - If the tool returned JSON, save it to a temp file and run `python3 ~/.claude/skills/slack-request-review/scripts/extract_examples.py <file> --channel <channel> --self-id <id>`.
     - If it returned text, pick out the messages that link a PR/MR yourself and write the file in the layout above.
   - **Read failed:** if a stale file exists, use it and say "examples are N days old". If there's no file, ask the operator for one of: how to get read access to the channel (tool, login, or the channel id if the name won't resolve), or a few pasted example messages to save in the layout above. Don't guess the format.
3. **Get the PR/MR facts** with `gh pr view` / `glab mr view`: URL, title, ticket id, what it does in one phrase, draft state. If it's still a draft, say so, since a review request on a draft usually wants it marked ready first.
4. **Draft the message.** Copy the most common shape from the file. Prefer `## Mine` for wording and casing. If `## Mine` is empty, use the `## Team` shape only.
   - Opener, one phrase on what the PR/MR does, then the link.
   - Several PRs/MRs: one bullet each, same as the examples do.
   - Add a `CC: @person` line only when a specific person must approve.
   - Leave out emojis even if the examples use them.
5. **Style pass.** Run the draft through `humanize`, but keep the opener and layout the examples show (a "hello team" opener stays if that's the channel norm). Give a normal and a shorter version.
6. **Return the draft** in a quote block. Do not call any Slack write tool.

## Refreshing

When the operator says the examples are stale, or asks to add a channel, rerun step 2 for that channel. Delete a channel's file to forget it.
