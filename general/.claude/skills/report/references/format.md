# Closing report / verdict format (canonical, shared)

The single spec for the block a skill prints at the END of a run: the review verdict
(`pr-code-review`, `pr-code-review-work`) or the own-work "Changes made" report (`fix-bug-work`,
`impl-connector`, `newconnector`). Every such skill follows this — no private copies. The Hunk
notes that roll up into this block are defined in the sibling `diff-note-format.md`.

## Universal rules (both variants)

0. **Written for a human, skimmed in seconds.** Short, plain, to the point. Cut every sentence that
   doesn't change what the operator does next. Prefer a status glyph + one clause over a paragraph.
   Emojis are welcome where they speed understanding (✅ ⛔ ❌ for status; a leading 🔴/🟠/🟡 for
   BLOCKER/MAJOR/MINOR if it helps scanning) — never decorative, never more than one per line.
1. **Decision first.** The FIRST lines are the decision the operator needs (approve? / ready to
   push?) plus a one-clause reason. Never bury the decision under a findings table or a narrative.
2. **No prose walkthrough.** Do NOT append a "Detail" / breakdown / "here's everything I did"
   section. The full write-up lives in the context/report file. The closing block is status +
   recommended actions, nothing more.
3. **Print once**, as the last thing in the run-ending response. Follow-up turns: answer normally,
   no trailing block.
4. **Recommended actions call out what the OPERATOR must do.** Every action the operator owes is
   spelled out and visibly flagged (lead the bullet with the action verb + a `you:` / `Action:`
   cue where it isn't obvious), most-important first, each naming the exact target (sha / command /
   reviewer / path). If there's genuinely nothing to do, one bullet saying so.

---

## Variant A — Review verdict (`## Review verdict`)

In order:
1. `Review type: first-review | re-review` (re-review: append ` — reviewed only the <N> new commits since my last pass (<range>); did NOT re-review the rest`).
2. `Recommendation: APPROVE | APPROVE WITH NOTES | HOLD (comment) | HOLD (request-changes)` + ` — <one plain clause>`. A decision, not a hedge.
3. `Verified how: <one clause>` — what you actually ran (build/test/repro/doc-fetch) vs only read. Be honest; never imply e2e when you only read.
4. `Comments: <...>` — per the wrapper's posting model (e.g. `<D> drafted (in <path>), 0 posted` when the skill never posts).
5. `Findings: <nB> BLOCKER, <nMaj> MAJOR, <nMin> MINOR, …` (tally, or `none`), then a table with EXACT columns `Sev | Conf | ✓N | File:line | Finding`. `Conf` and `✓N` are BOTH required on every row. Under the table, name what the `✓N` checks were per finding, and the "why not higher" line for any sub-80% multi-validated finding (see `diff-note-format.md` §2-3).
6. `Why: <one sentence>` — the headline finding, or "no blocking findings".
7. `### Recommended actions` — universal rule 4. First bullet restates approve/hold as a runnable next step.

Re-review with no new findings: add a line mapping each prior comment to its fix so "all resolved" is auditable.

---

## Variant B — Own-work "Changes made" (`## Changes made`)

Status lines, decision first:

- `Ready to push: ✅ Yes — <short why>` OR `Ready to push: ⛔ No — <short why>`.
  - `✅ Yes` = ≥1 new commit AND complete + e2e-verified + no unresolved blocker. The why names what
    landed, e.g. `✅ Yes — fixed the pagination drain in ListUsers`.
  - `⛔ No` = no new commit this run, or a blocker the operator must resolve first. The why names the
    open decision, e.g. `⛔ No — operator needs to decide retry-on-429 vs fail-fast before this ships`.
  - The inline why is REQUIRED on both; it's the one-line justification for the push/hold call.
- `Confidence: <N>%` — for `fix-bug`-backed runs, the composite/ per-symptom confidence (lead with it if the skill's own contract says so).
- `Live tenant tested: ✅ Yes` (e2e tier `live`) OR `❌ No — <tier / reason>` (`mock` / `unit-test` / `blocked`; `❌ No — no code changes this run` when nothing changed). Keep the required `e2e: <tier> — <observation>` line if the skill mandates one.
- `### Recommended actions` — universal rule 4. When `Ready to push: ⛔ No`, the FIRST bullet is the exact decision/step the operator must take to unblock (e.g. `you: decide X vs Y — options in <context path>`). When `✅ Yes`, the first bullet is the push step (`you: push \`<sha>\` — nothing else owed`).

No prose walkthrough after (universal rule 2); the context file holds the full detail.

---

## Emoji note
`✅` / `⛔` / `❌` are status glyphs used deliberately in this block for at-a-glance scanning of the
push/verify decision. They are the only emoji this block uses; do not add others.
