# Hunk-note examples — good and bad, curated

This file is a running list of concrete Hunk notes the operator has explicitly labeled **good** or **bad**. Every entry is generic (no work-specific ticket IDs, vendor names, or repo names). Each notes WHAT the operator said, WHY (in one line), and the note text so you can pattern-match on shape when applying a new note.

Rules for this file:
- **The operator's judgment is the source of truth.** Only add / move entries when the operator explicitly says a specific note is good or bad. Don't self-nominate.
- **Genericize before saving.** Replace project-specific tokens: ticket IDs → `<TICKET>`, vendor names → `<VENDOR>`, error codes → `<VENDOR_ERR_A>` / `<VENDOR_ERR_B>`, operation names → `<op>`, field names → `<field>`. Keep the shape of the sentence; strip only the identifying data.
- **Save the summary line, the rationale, and the operator's reason** verbatim (as best you remember). One entry per accepted example.

Consulting order at Round 3:
1. Read `references/review-guidance.md` for the rules.
2. Read THIS file for concrete good/bad shapes on record.
3. Draft your note, self-test it, apply.

## Good examples

### G1 — no-action call-to-inaction, names the consequence of reverting

Anchor: on the load-bearing changed line (the specific line whose revert would reintroduce the bug), not on a nearby comment or the top of the diff.

```
summary:   no action needed — this line is the <TICKET> fix
rationale: <VENDOR_ERR_A> is a generic "<generic-message>" trailer that <VENDOR> appends to every failed <op>. matching it (the old code) treated every failure — <example non-matching case 1>, <case 2>, anything — as a <specific case>. <VENDOR_ERR_B> is the actual "<real signal>" signal, and matching it here is what fixes the false positive.
```

Why the operator liked it (paraphrased): the summary answers the reader's first question ("do I need to do something?") in plain English, no jargon prefix. The rationale explains the mechanism (what `<VENDOR_ERR_A>` actually is, why the old match was wrong, what the OLD code would have done wrong). The consequence of reverting lives inside the mechanism explanation itself ("matching it treated every failure as duplicate"), not spelled out as a redundant closing sentence.

Reusable shape:
- Summary: `no action needed — this line is the <TICKET> fix`.
- Rationale: mechanism-first — "what's actually happening in the vendor API / algorithm / config", with the WHAT-THE-OLD-CODE-DID-WRONG naturally implying the consequence. No trailing "revert this and X breaks" sentence; if the mechanism explanation doesn't make the consequence clear on its own, the mechanism explanation is the problem, not a missing closer.

### G2 — present-tense mechanism, no reference to the pre-fix code (corrected form of B3)

Anchor: on the changed line itself.

```
summary:   no action needed — a <STATUS> here means the record already exists
rationale: <endpoint> returns <STATUS> only for an already-exists conflict (<spec>), so the connector maps it to already-exists. reading a field off the body would silently never match, the runtime delivers the body as a raw string not an object, so the status alone is the check.
```

Why it works (contrast with B3): every clause describes what the code in front of the reader DOES, in the present tense. No "old read", no "fell through", no "don't add X back" — a reviewer on a `+` line can't see the pre-fix code, so history-of-the-bug narration gives them nothing to land on. The load-bearing "don't read the body" point survives as a present-tense reason ("reading a field off the body would silently never match"), which is also the consequence.

### G3 — PR-feedback note where the fix DECLINED the request: leads with a status block + explicit "your call" (corrected form of B4)

Anchor: on the changed line the decision concerns.

```
summary:   <REVIEWER> CR (needs your call): I declined to <reviewer-ask>; reply or override
rationale: fixed: no (I declined the requested change)
done: no (needs you to act on the PR thread)
reason: <one-line why the reviewer's ask is unsafe/wrong here>

This note is NOT a code change for you to make. It flags a decision that needs your call.

They asked: "...<verbatim reviewer suggestion>"

Why I declined: <present-tense mechanism + the consequence of doing what they asked>. Live-tested: <result>, no regression.

Your call: post this reasoning as the reply defending <approach-kept>, OR override me and <do the reviewer's ask>. Full write-up in <TICKET>.context.md.

<PR-link>
```

Why it works (contrast with B4): a PR-feedback note where the fix REJECTED the reviewer's request is the highest-ambiguity case, the reader can't tell if it's "done", "informational", or "a code edit for them". Leading with the `fixed/done/reason` status block answers that in the first three lines, the explicit "NOT a code change for you to make" kills the wrong reading, and the closing "Your call: A or B" tells the operator exactly what decision is theirs.

## Bad examples

### B1 — jargon tag opener, no action-or-inaction signal

```
summary:   heads-up: <VENDOR_ERR_B> is the real duplicate signal; <VENDOR_ERR_A> is a generic wrapper
rationale: <VENDOR> appends <VENDOR_ERR_A> "<generic message>" to ANY failed <op>, not just duplicates. <VENDOR_ERR_B> is the actual "<specific signal>" signal that <method> now matches.
```

Why the operator flagged it (paraphrased): "heads-up:" is jargon that assumes the reader knows the convention. Reader can't tell whether they need to do something. The rationale states raw facts about the API but never says "revert this and X breaks" — it's trivia, not a call-to-inaction. Fails the self-test: "if the reader ignores this note and reverts the line, ___" answers "nothing measurable from this note alone".

Fix: rewrite the summary as `no action needed — this line is the <TICKET> fix`; add a "reverting this line brings <TICKET> back" sentence to the rationale.

### B2 — trivia disguised as a heads-up

```
summary:   intentional: match <VENDOR_ERR_B>, not <VENDOR_ERR_A>
rationale: swap this back to <old_name> (<VENDOR_ERR_A>) and every failed <op> — <case 1>, <case 2>, anything — gets reported to <PLATFORM> as a duplicate. that's <TICKET>. <VENDOR_ERR_A> is <VENDOR>'s generic "<generic message>" trailer, not the duplicate signal.
```

Why the operator flagged it (paraphrased): the CONSEQUENCE was there in the rationale ("swap this back and X happens"), but the SUMMARY still used "intentional:" — a terse jargon opener that assumes the reader knows the convention. The reader can't tell from the summary alone whether action is needed.

Fix: promote the consequence into the summary or use a plain-English action-tag summary ("no action needed — <what this line is>"), keep the rationale as-is.

### B3 — narrates the history of the bug instead of what the line does

```
summary:   leave as-is — <STATUS> alone is the signal, don't add a body check back
rationale: the runtime gives the error body to JS as a raw string, so the old body.<field> read always missed and every <STATUS> fell through to a hard failure. a <STATUS> on <endpoint> is always <condition> (<spec>).
```

Why the operator flagged it (paraphrased): "I don't understand this." The note is written for someone who already read the pre-fix code. A reviewer lands on a `+` line and sees "don't add a body check back", "the old body.<field> read", "every <STATUS> fell through" — all past-tense narration of a bug they never saw. It explains the history of how the fix was reached, not what the current line does. Violates review-guidance "explain the code, not the history of how you got here".

Fix: rewrite present-tense, describing what the line does now (see G2). Keep the load-bearing "don't read the body" point as a present-tense reason, drop every "old / back / fell through" reference.

### B4 — PR-feedback note that doesn't say whether it's informational or a request to act

```
summary:   <REVIEWER>: kept <approach-kept>; <reviewer-suggestion> is unsafe here
rationale: they said: "...<verbatim reviewer suggestion>"

Verified against <SDK>: <mechanism>. <consequence>. Live-tested: <result>, no regression.

<PR-link>
```

Why the operator flagged it (paraphrased): "I don't know if the note is informational, or if it's asking me to change anything." The summary and rationale describe what was done and why, but never signal the note's INTENT, is it done, is it a code edit for the reader, or is it a decision awaiting the reader's call? For a PR-feedback note where the fix declined the reviewer's ask, that ambiguity is worst: the reader can't tell the request was rejected, not satisfied.

Fix: lead with a `fixed / done / reason` status block, state plainly "NOT a code change for you to make", and close with an explicit "Your call: A or B" (see G3).

## How to update this file

When the operator says "that's a good note" or "that's a bad note" about a specific Hunk note in the current session:

1. Extract the summary + rationale of the note they named.
2. Genericize: strip ticket IDs, vendor names, error codes, field names — replace with `<TICKET>` / `<VENDOR>` / `<VENDOR_ERR_A>` / etc. Keep the shape intact.
3. Add a new entry under `## Good examples` or `## Bad examples`. Number sequentially (G3, G4, B3, B4, ...).
4. Include a one-sentence "why the operator liked it" (or flagged it) paraphrased from what they said.
5. If the operator gave a corrected version alongside the flag, also save the corrected version under Good with a cross-reference.

Never move a Bad example to Good (or vice versa) without an explicit operator statement — the entries are stable evidence, not editable opinions.
