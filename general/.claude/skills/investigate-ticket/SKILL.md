---
name: investigate-ticket
description: Gather everything needed to scope a dev/feature ticket (a Story or Task, NOT a bug report) before writing any code — pulls the full ticket from whatever tracker is connected (Jira, Linear, GitHub/GitLab Issues, etc.), finds sibling/duplicate tickets in other projects (often carry the real spec), searches Slack or whatever team-chat tool is connected, read-only, for prior discussion and DMs (not just the "obvious" channel), checks the real team/ownership of named collaborators, locates the actual owning code (in the current repo, or a sibling repo if named), finds existing conventions (naming, tests, config patterns) in that code before proposing anything new, and checks any connected wiki/docs tool for runbooks. Produces a findings doc: confirmed facts each linked to its source, open questions, and a draft message to collaborators (never sent automatically). Triggers on "/investigate-ticket", "help me scope this ticket", "figure out what this ticket needs before I start", "gather context on this ticket before I write code", or a pasted ticket URL/key when the ask is about requirements-gathering. Distinct from find-bug, which owns anything phrased as "investigate this ticket"/"root cause this" when the ticket describes something broken/failing — find-bug wins whenever there's an actual bug, error, or incident, even if the user says "investigate." This skill only fires for tickets where nothing is broken yet, the work just needs to be scoped. Also distinct from investigate (a knowledge-lookup question with no ticket attached).
argument-hint: [ticket-key-or-url]   # e.g. PROJ-123 or the full ticket URL; if omitted, ask the operator which ticket
---

# investigate-ticket

Scope a dev/feature ticket before touching code: figure out what's actually being asked, what's already been decided, who really owns the code, and what's still genuinely open. The output is a findings doc the operator can act on, not a narrated research session — every claim in it needs a source link.

This skill is intentionally generic — it has no fixed tracker, chat tool, or workspace layout baked in. It discovers what's actually connected and adapts. Don't hardcode a specific product name, URL, or directory convention into this file; if you catch yourself wanting to, that detail belongs in a project's own `CLAUDE.md`/`.claude/lazy/*` instead, not here.

## Step 0: figure out what's connected

Before anything else, work out what tools are actually available this session:

- **Ticket tracker**: whatever MCP tools are connected for Jira, Linear, GitHub Issues, GitLab Issues, etc. If a ticket URL was pasted, its domain tells you which one. If only a bare key was given (e.g. `PROJ-123`) and multiple trackers are connected, ask which one.
- **Team chat**: check for a connected Slack (or similar) MCP server/CLI via `ListMcpResourcesTool` or by trying a read-only search call. If nothing is connected, say so plainly and skip Step 3 rather than guessing at a tool that isn't there.
- **Docs/wiki**: Confluence, Notion, a GitHub wiki, or a `docs/` folder in the repo — whatever's actually reachable.

If a tool the operator expects to be there isn't connected, tell them instead of silently skipping it.

## Step 1: pull the ticket

Get the full description and comments, not just the summary — summaries are frequently stale compared to what got hashed out in comments. Note who else is named as a reviewer/collaborator; don't take "work with X and Y" at face value yet (Step 4 checks who they actually are).

## Step 2: find sibling/duplicate tickets

Search by the ticket's exact title text across other projects/trackers the operator has access to. A sibling ticket owned by a different team often carries the actual technical spec that the operator's own ticket only summarizes or references. If the chat tool unfurls ticket links (many do), a Slack/chat search for the ticket's own key can also surface the sibling — see Step 3.

## Step 3: search team chat broadly — read-only, always

**Never post a message as part of this skill.** Search and read only, regardless of what write capability the connected tool exposes. If it can search, use it; if it can also read channel/thread history or DMs, use that too — but assume you cannot post, reply, or react, even if the tool would technically let you.

- Search unrestricted by channel/date first, then narrow. The real discussion is often in a DM or small group thread between the people actually doing the work, not the "obviously relevant" public channel.
- Search for: the ticket key, any sibling ticket key, and domain-specific terms from the ticket (field names, feature names, system names).
- Follow promising threads for full context when the tool supports it. If a specific scope/permission is missing for one conversation type (e.g. group DMs), fall back to a plain search scoped to that conversation — search often still reaches DMs/group DMs even without full history access.
- When you find a concrete claim (a field name, an ID, an owning team), search again for it specifically — corroborating or contradicting messages from unrelated threads are common. One hit is a lead, not a confirmed fact.

## Step 4: check collaborators' real team/ownership

Don't assume a name dropped in the ticket is a peer reviewer. Search for that person's recent activity and see which channels/repos they actually show up in. This changes what you ask them — a question to a peer ("can you help me find X") is different from a question to the actual code owner ("what's my role here, and what do you expect me to write").

## Step 5: locate the actual code

Start in the current repository. Grep for the literal feature/endpoint name (use a search subagent for anything beyond a quick grep, so it doesn't fill the main context with raw output). If nothing turns up here:

- Check team chat for repo links, dashboard tags naming a service, or an "who owns this" thread — these name the real repo.
- **If the real code lives in a different repo that isn't checked out locally, ask the operator before cloning it.** Don't assume where their other repos live or what naming convention they use for a workspace directory — ask, or clone next to the current repo if that's the obvious default.

## Step 6: find existing conventions before proposing new code

In the target repo, grep for how the same *kind* of thing is already done elsewhere (config flags, naming patterns, test structure for the same file/module). **Check multiple examples before calling something "the convention."** One matching hit is a data point, not a rule — a broader grep often shows several inconsistent patterns, and the honest answer is "here's the range, most common is X."

## Step 7: check docs/wiki for runbooks

Search whatever docs/wiki tool is connected for the operational how-to (the mechanics of a config/flag system, an access-request process, etc.) before assuming the operator has to figure it out themselves — this kind of thing is often already written down somewhere.

## These steps loop, they don't run once in order

Steps 2-7 feed each other. A code search (Step 5) that turns up nothing is itself the signal to check team chat (Step 3); chat then names the real repo, which sends you back to Step 5 to locate/clone it and Step 6 to check its conventions; a runbook (Step 7) found mid-way can answer something you were about to ask a collaborator (Step 4). Keep the findings doc (Step 8) open and update it after every step — don't treat this as a fixed pipeline run once top to bottom.

## Step 8: write the findings doc as you go

Structure:

```markdown
# <TICKET-KEY> - <short title>

## Confirmed findings
- **<claim>**: <one line>. Source: [<link text>](<url>)
- ...

## Open questions
- <question a human still needs to decide/confirm>

## Draft message to <collaborators>
> <short, plain-language draft — no filler, no unverified claims>
```

Use a real link for every confirmed finding, not a paraphrase of "someone said." If a finding overturns an earlier one in the same doc (e.g. "actually not X, it's Y" after a broader search), replace it — don't leave the stale claim next to the correction.

## Step 9: draft, don't send

Any chat message drafted from this research goes through the operator for review before sending — use the `qa` skill to surface it in a pane if available, and `humanize` for a style pass. This skill never sends chat messages itself. Posting a comment to the ticket tracker follows whatever write-approval convention the operator otherwise uses for that tracker — show the exact text and wait for explicit go-ahead first regardless.

## CRITICAL: don't skip the "is this actually a convention" check

The single most common mistake in this flow is generalizing from one matching example (a config key, a header field, a detection mechanism) into "the pattern used here" without checking whether other examples in the same codebase actually agree. Grep broadly before stating a convention as fact.
