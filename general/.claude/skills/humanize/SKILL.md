---
name: humanize
description: Rewrite a drafted message (PR/MR comment, ticket/issue comment, chat reply, short note) so it reads like a person wrote it, not an LLM: shorter, plainer, cohesive. Triggers on "/humanize", "humanize this", "make this sound human", "make this less robotic", "this sounds like an LLM", "shorten this comment", "simplify this reply", "tighten this up", or when another skill needs a final style pass on a drafted body before showing or posting it. Works on any short human-facing text: PR/MR comments, Linear/Jira/GitHub issue comments, Slack-style replies, commit-message bodies, brief status updates. Not for long-form docs, READMEs, or formal writing, those want plain-language editing, not slack-voice compression.
---

# humanize

Take a drafted message and cut it down to how a person would actually write it: short, plain, one point, then stop.

## When to use

- The user pastes a draft and asks to shorten, simplify, or humanize it.
- Another skill (`add-comment`, a chat reply, a commit-message helper) needs a final style pass on a drafted body before showing it to the user or posting it.
- A draft reads long, hedgy, or list-shaped and needs compressing.

Skip for READMEs, formal docs, or anything meant to read like a memo or spec. Those want clarity, not slack-voice compression.

## Voice

Read like a tired engineer typing a reply, not a memo.

- **As short as possible.** The ideal reply is one word ("done", "fixed", "yep", "agreed"). Cut every sentence that isn't doing the one job of closing the thread or making the one point.
- **Stop once the point's out.** No trailing qualifier ("just want to check...", "just making sure"), no restating the same point differently, no listing every other place it also applies. If a second point genuinely matters, it's its own sentence, or its own message, not a tail glued onto this one.
- **Write for a reader with zero context.** Assume they haven't seen the investigation. Drop internal acronyms, API, product, and permission names they wouldn't already use (say "Workday doesn't tell us which users are AI agents", not "agents run as ASUs, not ISUs"). Hand over exact settings only once they've asked for them.
- **Plain words.** "matters" not "is load-bearing". "before the loop" not "prior to iteration".
- **Simple grammar.** Short sentences. No semicolons. No nested "which" clauses. One idea per sentence.
- **Contractions.** i'd, doesn't, isn't, can't.
- **No greetings, no sign-offs.** No "hey", "hi", "thanks for the look", "let me know if".
- **No em dashes or double-hyphens.** A period or comma instead.
- **No formal hedges.** Skip "happy to revisit", "open to other approaches", "appreciate the feedback".
- **No AI-slop vocabulary.** `no-op`, `leverage`, `robust`, `seamless(ly)`, `streamline(d)`, `unlock(s)`, `harness` (verb), `delve`, `utilize`, `intricate`, `tapestry`, `realm`, `landscape`, `journey` (metaphor), `dive into`. Full list and reasoning: `~/.dotfiles/general/.claude/rules/writing-style.md`. Say what the thing actually does instead: not "the pop is a no-op now", but "the pop does nothing now, X isn't in the body anymore".
- **No unusual noun shortenings.** Spell out `caps`/`impl` as `capabilities`/`implementation`. Widely-recognized ones stay (`docs`, `auth`, `env`, `repo`, `config`, `sync`, `api`).
- **Backticks for code identifiers**, when the message references one: function/type/package/method/variable names, error codes, gRPC codes, HTTP statuses, JSON fields, config keys, CLI flags, file paths. Don't backtick a generic noun phrase ("the auth flow").
- **Lowercase starts by default**, including PR/MR comments, chat replies, and status updates (bullets too). Keep sentence case only for a ticket comment addressed to a wider audience, or where the surrounding thread is already capitalized.
- **Rarely, one subtle slip.** At most one per message, and often none. Make it the kind people don't notice: a missing apostrophe ("dont", "its" for "it's"), a skipped comma, no final period. No misspelled words. Never in names, numbers, code identifiers, ids, or anything someone might copy.
- **Never add reasons or benefits the draft doesn't state.** No "so that", "which means", "making it easier to". If you're unsure what something means, say less, not more.
- **Plain words that stay accurate.** Swap jargon for the reader's term ("login key", not "SSH key"), never for a vivid but wrong image ("sold out" for "the provider had no capacity").
- **Vary the shape.** The same sentence pattern on every line ("X. now Y. released."), "also" openers, and lists of three all read as an LLM.

## Confirming a fix that's already applied

When the point of the reply is "yes, that's handled" (a fix that landed, a guard already in place, a suggestion already followed), default to a single word: "done", "fixed", "already there". The reviewer sees the code at the anchor line, restating what it does is the diff's job, not the reply's.

Bad (restates what the anchor already shows):

> already guarded here, breaks the loop once `i >= len(tokens)`.

Good:

> done.

Only add detail past "done" when the reviewer genuinely can't see it from the anchor: the fix landed in a different file, there's a follow-up still owed, or it isn't actually done and you're explaining why not.

## Bad vs good

Robot:

> first hit per location goes one-by-one to GetJSON. that's 30 sequential roundtrips on a 30-location page. could batch it with GetManyJSON before the loop, the old 3-phase code already did.

Human:

> could batch this with a GetManyJSON over the distinct ids before the loop. the old code was already doing that.

What changed: dropped the magnitude detail, dropped the long subordinate clause, dropped the colon-and-list rhythm. Same point, half the words.

## Workflow

1. **Read the draft** and find the one point it's making (the position, the fix, the question). If it's making more than one point, that's a sign it should be separate messages, flag this rather than silently picking one to keep.
2. **Cut**, in this order: greetings/sign-offs, formal hedges, restated points, magnitude/detail that doesn't change the point, subordinate clauses that just explain more of the same thing.
3. **Rewrite what's left** in the voice above: short sentences, plain words, contractions, no AI-slop vocab, backticks on code identifiers.
4. **Produce two lengths when useful**: the full rewrite, and a "shorter" cut roughly half the length, for the caller to pick. Skip the shorter pass if the rewrite is already one sentence.
5. **Keep every claim's strength honest.** Compression must never upgrade an inference into a verdict. If the input hedges ("i don't think this holds"), the output keeps the hedge ("doesn't look right"), never flattens it to an assertion ("this doesn't hold") just to save words.
6. **Return the rewrite**, not a description of what changed. A caller invoking this mid-workflow wants text ready to use, not a diff or a rationale.

## Common failure modes

- Sounding like an LLM: em dashes, "I'd be happy to", "let me know if", any greeting.
- Big words: "load-bearing", "non-trivial", "in steady state", "geographically".
- Long sentences: if there's a semicolon, split it.
- Over-explaining: one sentence of "why" is the max.
- Compressing away a hedge: shortening "i don't think this holds because X" to "this doesn't hold" changes the meaning. Don't.

## Voice-training corpus

Real posted comments (deduped, with `(×N)` use counts) live at [`references/examples.md`](references/examples.md). Skim it before a draft, reuse phrasings that fit, and avoid ones with a high count. After a caller posts a comment, record it:

```bash
python3 ~/.claude/skills/humanize/scripts/record_example.py \
  --category "<heading>" \
  --body "<exact posted text>"
```

Same text in the same category bumps `(×N)`; new text appends a new bullet under `## Answers`.

## Used by

- `add-comment` runs every PR/MR comment draft through this skill before showing it in the qa pane, then layers its own review-specific rules (backticks, no internal-tooling refs, doc-link preservation) on top, and records posted comments here via `record_example.py`.
