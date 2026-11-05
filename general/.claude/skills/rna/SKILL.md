---
name: rna
description: Recommended next actions. One short numbered list of the actual next actions, each marked done/failed/pending/operator-only with an emoji, plus a bold line saying whether code work or testing is still pending, written for an operator with zero context on the work. Triggers on "/rna", "rna", "recommended next actions", "what's next", "what should I do next", "is there work pending", "what's left". Use at any point in a session, including right after a long autonomous run. Not for detailed reports or review findings (use the report or review skills), PR/ticket status tables, or periodic status reports. This is the short version a busy person reads in ten seconds.
---

# rna

Tell the operator what happens next, in words a person with no context understands in ten seconds.

## 1. Gather the facts

From this session's transcript first. If it's thin (fresh session, after compaction), also check `git status`, `git log -5`, and any notes, TODO, or blocked files the work left in the repo or scratchpad.

Sort every open item into one bucket:

- **Done.** Only if a tool call in this session actually did it and it succeeded. Never count planned or half-done work.
- **Needs the operator.** A decision they personally own (not one another team owns), an approval for something outward-facing (posting, pushing, opening a PR, deleting), access only they have, or a heavy action they asked to confirm first.
- **Claude can do.** Anything reachable with the tools at hand.
- **Just do it, don't list it.** Follow-through on work that's already finished needs no yes: resolving a review thread whose fix is pushed, committing and pushing your own edits to the operator's skills or rule files. Do these before drafting, then count them as Done.

## 2. Draft

Fixed shape, nothing else:

```
<ticket id + title, or the feature name if there's no ticket>
<one line: what the work does, in plain words>
**<work left: "⏳ code work left" | "⏳ testing left" | "⏳ code work and testing left" | "✅ code and testing done">**

1. <emoji> <action>
2. <emoji> <action>

<one line: "want me to start on X?", X = the top item Claude can do>
```

Emoji per item: ✅ done, ❌ failed (say what failed in a few words), ⏳ still to do, 👤 only the operator can do it (a send, push, PR, or a decision they own).

Rules:

- **Zero context.** Say what a thing is, not its internal name. "the setting that turns on quick updates", not the constant. Use ids or file paths only when the operator needs them to act. The ticket id and title at the top are always included.
- **Name every system by its real name.** Never "our app", "the app", "the tool", "the service", "the platform" when more than one system is involved. Say which one, by the name the operator uses for it.
- **No bare "it" or "switch it on".** Every item names the thing it acts on and, for a decision, who decides and what changes. "ask the <named system> owners to let <named system> check <named vendor> for changes every few minutes", not "get the ok to switch it on".
- **A reply or comment item says what it answers.** Name who asked, what they asked for in plain words, and what was done about it, so the reply's text makes sense on its own. "reply to the review bot, which asked us to say in the docs that the user name must match exactly: tell it that's done", not "write that "done." reply".
- **One numbered list of actions, nothing else.** No "needs you" / "i can do next" sections, no prose paragraphs. Number items so the operator can answer "do 2 and 4".
- **The bold work-left line is mandatory.** It must say plainly whether code work or testing is still pending for the ticket, so the operator knows at a glance without reading the list.
- **👤 is only what the operator alone can do.** A decision another team owns is not the operator's: list "draft the ask to <team>" as ⏳ instead, and mark only the send 👤 if it's outward-facing.
- **5 items max, one line each.** Pick the ones that matter most. Fewer is fine.
- **Nothing pending?** Say so in one line and stop.
- **No caveats, no history, no how-it-works.** If the operator wants more, they'll ask.

## 3. Humanize

Run the draft through the `humanize` skill, telling it the reader has zero context and to keep the header lines, the numbered list and the emoji, only tightening the wording. Show the result as the reply. Don't show the pre-humanize draft.
