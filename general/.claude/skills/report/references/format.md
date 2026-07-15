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
1. **Decision clearly labeled.** The decision the operator needs (approve? / ready to push?) lives in
   its OWN clearly-labeled section so it's found at a glance, never buried inside a findings table or
   a narrative. Variant A leads with it (`Recommendation`); Variant B (own-work, operator preference)
   leads with the mechanical `## Changes made` and a short `## Summary`, with `## Ready to push` right
   after — still its own section, still skimmable.
2. **No long prose walkthrough.** Do NOT append a "Detail" / blow-by-blow "here's everything I did"
   section. A short `## Summary` (2-4 bullets: what was done + why) is allowed in Variant
   B; anything longer lives in the context/report file. The closing block stays status + summary +
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

## Variant B — Own-work "Changes made"

Each piece is its OWN top-level `##` section — never fold the push/verify status or the summary as
lines under "Changes made". Sections in THIS order (own-work leads with the raw detail, then the
summary, then the decision — operator preference):

1. `## Changes made` — ONLY the actual changes: a bullet per change, each citing `file:line` (or
   `file` + function). It matters least for the decision, so it leads and gets skimmed past. When
   nothing changed this run (resume from prior manifest, all items blocked), one bullet saying so
   (e.g. `- no code changes this run (resumed from prior manifest)`). NEVER emit the `## Changes
   made` header with nothing under it — it is a section with its own bullets, not the block title.
   Every run has at least one bullet here (a real change, or the no-change bullet).
2. `## Summary` — 2-4 bullets: what was done and WHY, merged into one (bullets, not a prose
   paragraph). This is the only "why" in the block; there is no separate Why line. Plain and
   skimmable; the full write-up stays in the context/report file (universal rule 2).
3. `## Ready to push` — one line: `✅ Yes` OR `⛔ No — <short blocker>`. The push/hold call at a glance;
   the reasoning already lives in `## Summary`, so no inline why is needed on `✅ Yes`.
   - `✅ Yes` = ≥1 new commit AND complete + e2e-verified + no unresolved blocker.
   - `⛔ No` = no new commit this run, or a blocker the operator must resolve first (name it inline).
   - `fix-bug`-backed runs append a `Confidence: <N>%` line here (composite / per-symptom; lead with
     it if the skill's own contract says so).
4. `## Live tenant tested` — one line: `✅ Yes` (e2e tier `live`) OR `❌ No — <tier / reason>` (`mock` /
   `unit-test` / `blocked`; `❌ No — no code changes this run` when nothing changed). Keep the required
   `e2e: <tier> — <observation>` line if the skill mandates one.
5. `## Lazy-gaps` — one line, ONLY when the run invoked the `lazy-gaps` skill (the own-work dispatch
   flows do). State whether gaps were found and addressed: `N rule(s) added (<file>, <file>); M
   covered, K skipped`, or `none — all findings already covered`, or `not run — <reason>`. Omit this
   section entirely for skills that never run lazy-gaps (e.g. the standalone report skill).
6. `### Recommended actions` — universal rule 4. When `Ready to push: ⛔ No`, the FIRST bullet is the
   exact decision/step the operator must take to unblock (e.g. `you: decide X vs Y — options in
   <context path>`). When `✅ Yes`, the first bullet is the push step (`you: push \`<sha>\` — nothing
   else owed`).

No prose walkthrough after (universal rule 2); the context file holds the full detail.

---

## Emoji note
`✅` / `⛔` / `❌` are status glyphs used deliberately in this block for at-a-glance scanning of the
push/verify decision. They are the only emoji this block uses; do not add others.
