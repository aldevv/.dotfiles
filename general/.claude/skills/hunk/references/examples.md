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

## How to update this file

When the operator says "that's a good note" or "that's a bad note" about a specific Hunk note in the current session:

1. Extract the summary + rationale of the note they named.
2. Genericize: strip ticket IDs, vendor names, error codes, field names — replace with `<TICKET>` / `<VENDOR>` / `<VENDOR_ERR_A>` / etc. Keep the shape intact.
3. Add a new entry under `## Good examples` or `## Bad examples`. Number sequentially (G3, G4, B3, B4, ...).
4. Include a one-sentence "why the operator liked it" (or flagged it) paraphrased from what they said.
5. If the operator gave a corrected version alongside the flag, also save the corrected version under Good with a cross-reference.

Never move a Bad example to Good (or vice versa) without an explicit operator statement — the entries are stable evidence, not editable opinions.
