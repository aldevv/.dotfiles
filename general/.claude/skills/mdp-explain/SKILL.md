---
name: mdp-explain
description: Explain something in short, plain, informal terms as a markdown doc that favors diagrams, then open it in the browser via mdp. Use when the user wants a quick simple explainer they can look at rendered, not a raw chat dump. Triggers on "/mdp-explain", "/mdp-explain <topic>", "explain this in mdp", "make an mdp explainer for X", "explain X simply and open it", "create a simple doc explaining X and open in mdp", "eli5 this as a doc", "give me a plain-english writeup of X in the browser". The thing to explain comes from $ARGUMENTS or, if empty, the most recent substantial thing in context (a ticket, plan, system, diff, error). Distinct from md-preview: md-preview only renders markdown that already exists or that you hand it verbatim; mdp-explain AUTHORS a fresh simplified explainer first (short, informal, diagram-first), then delegates the render to md-preview. If the user just wants to view existing markdown, use md-preview instead. Do NOT trigger for full technical specs, formal docs, or long reports (this is the short casual version), or when the user wants the content inline in chat rather than rendered. Requires mdp on $PATH.
argument-hint: [topic]   # optional. What to explain. Omit to explain the most recent substantial thing in context.
allowed-tools:
  - Bash
  - Read
  - Write
  - Skill
---

# mdp-explain

Turn something into a short, plain-English explainer that leans on diagrams, then open it rendered in the browser. The point is a doc a busy teammate can skim in 30 seconds, not a spec.

**User input**: $ARGUMENTS

## Precondition

- `command -v mdp >/dev/null` must pass. Missing? Tell the user and point at `https://github.com/aldevv/md-preview`. Stop here.

## Step 1: pick the subject

- If `$ARGUMENTS` is non-empty, that is the subject.
- If empty, use the most recent substantial thing in context: the ticket, plan, system, diff, or error you were just working on. If it is genuinely ambiguous, ask one short question; otherwise proceed.

## Step 2: write the explainer

Author fresh markdown. Optimize for "understood in one skim." Rules:

- **Lead with one line**: what this is / what we are trying to do, in plain words.
- **Diagrams first.** Prefer a `mermaid` block (`flowchart`, `sequenceDiagram`, or `stateDiagram`) over paragraphs whenever a relationship, flow, or before/after can be drawn. Aim for at least one diagram; two is fine. Keep each diagram small (a handful of nodes).

- **Highlight nodes with `stroke`, never a pale `fill`.** mdp renders dark by default, and node label text inherits the theme's light color. Setting a light fill (`#ffe0e0`, `#fff4d0`, any pastel) puts light text on a light box and the label becomes unreadable. Outline the node instead and leave the fill alone, which also survives someone reading it with `-t light`:

  ```
  style B stroke:#e06c75,stroke-width:2px
  style C stroke:#e5c07b,stroke-width:2px
  ```

  Red/orange stroke for the failing node, yellow for the suspicious one, and nothing at all for ordinary steps. If a node genuinely needs a filled background, pick a dark tint and set the text color explicitly in the same rule (`fill:#3a2020,color:#fff`), never a fill on its own.
- **Short on commentary, not on specifics.** Cut every sentence that does not change what the reader does next. But an exact command, path, group name, ARN, snippet, or the name of the person/channel to ask *is* what changes their next action, so it always earns its place. Trim narration, never the actionable detail. Length follows necessity.
- **Informal.** Talk like a teammate on Slack. Analogies are welcome ("a bouncer that checks ID"). No jargon without a plain gloss.
- **A little code is fine.** The reader is an engineer. When a single line or a small code block (a command, a config snippet, a key function call) says it faster than prose, include it. Keep it to the smallest snippet that lands the point; don't paste whole files.
- **Recommended actions**, when the subject implies work to do. A numbered list, ordered so the lowest-risk thing that unblocks people comes first. One line each, concrete enough to act on (the actual command, index, file, or setting), not "investigate further". Skip the section entirely when the subject is purely explanatory and there's nothing to act on; an empty "Next steps: TBD" is noise.
- **Show your source for any load-bearing claim.** Cite the thing that proves it: `file.py:32`, a ticket key, a commit, a README heading, a config key. A reader who doubts one line should be able to check it without asking. Tables are good for "N examples of the same pattern".
- **Separate verified from inferred.** If you tested or read it, say so plainly. If you guessed, label the guess and say how to confirm it. Never let an inference read as established fact.
- **End with gotchas / open items** if any exist, as a short bullet list. Silent failure modes (a setting that shadows another, a green check that proves nothing) belong here.

**If the subject is a todo / action list**, each item answers four things or it isn't done:

1. **What to do**, as a verb, not a topic.
2. **Where / who**: the repo, file, channel, group, or person. Named, not "the platform team".
3. **The exact artifact**, when there is one: the command to run, the block to paste, the message to send. Ready to copy, no assembly.
4. **What's actually blocking it**, and whether it blocks anything else.

Do not write an item you have not pinned down. Go read the repo, the README, the CODEOWNERS, or the commit history first, then write it. "Ask platform" is a placeholder, not an instruction.

**If the user comes back asking for more detail**, treat it as a defect in items 1-4 above, not a request for more prose. Find the specifics you skipped and go get them.
- Follow the user's writing-style rules: no emojis, no em-dashes or double-hyphens as prose punctuation, none of the banned slop vocabulary.

### Last section: a copiable handoff prompt

Close the doc with a fenced block the reader can copy straight into a fresh Claude session to start the work. mdp puts a hover copy icon on code blocks, so a fenced block is the copiable unit; prose is not.

```markdown
## Hand this to a Claude agent

​```text
<the prompt>
​```
```

The reader is handing this to an agent with **none of this conversation's context**, so the prompt has to stand on its own:

- Name the task in the first line, imperatively.
- Give absolute paths to the evidence (this doc, any report files) and tell the agent to read them first. That's what keeps the prompt short without losing the detail.
- List the concrete steps from Recommended actions, in order.
- Carry the constraints across: which environment, read-only vs write, what needs human approval before it runs, anything that must not be touched.
- State how the agent knows it worked.
- No placeholders. `<FILL THIS IN>` in a block meant for copying defeats the point; if you don't know a value, say where to find it.

Use `text` (not `bash`) as the fence language when the content is a prompt rather than a script, so nobody pastes it into a shell by mistake.

Skip this section when there is no work to hand off, same rule as Recommended actions. A doc that only explains a concept doesn't need one.

Write it to a per-subject tempfile so multiple explainers coexist without clobbering each other, while re-runs of the *same* subject still overwrite cleanly and reload the same browser tab:

- Default path: `/tmp/mdp-explain-<slug>.md`, where `<slug>` is a short kebab-case slug of the subject (e.g. "Slack notification relay" becomes `slack-notification-relay`): lowercase, spaces to dashes, drop punctuation, keep it to a few words.
- Need guaranteed uniqueness (same slug, but a separate doc you don't want overwritten)? Append a short random suffix: `/tmp/mdp-explain-<slug>-$(uuidgen | cut -c1-8).md` (or any short token like `x7k2`).
- If the user clearly wants a keeper (named a destination, or it explains a specific ticket/project worth saving), write to that path instead and mention where it landed.

## Step 3: render it

Delegate the render to the `md-preview` skill (it owns the `mdp` invocation, detach semantics, and preconditions). Invoke `md-preview` with the file path from Step 2 (its Mode B). Do not re-implement `mdp <file>` here.

## Step 4: report

One line: what you explained and that it is open in the browser. If the subject was ambiguous and you made a call, say which call you made.
