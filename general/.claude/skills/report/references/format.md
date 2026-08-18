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

## Addressed-feedback table (shared, both variants)

Whenever a closing block reports on comments that existed BEFORE this run, a human reviewer's PR
comment, a bot's suggestion, or your own prior automated-review pass, and this run's diff addresses
(or fails to address) them, render them with this exact table. One home for the shape; Variant A
item 3 and Variant B item 2 both point here instead of keeping their own copy.

Columns, in order: **`Addressed | Reviewer | Comment | Fix | Verified | e2e`**

- **Addressed** — `✅ today` when a commit landed IN THIS RUN resolves the comment (signals there's
  a fresh commit the operator needs to push), plain `✅` when it was already resolved before this run
  (an earlier commit already pushed, or the item never needed code — a reply/explanation is enough),
  or `❌` when still open. This column exists so the operator can scan straight down it and know
  whether anything here is waiting on a push. Never conflate "addressed" with "posted a GitHub
  reply" — those are independent; `✅`/`✅ today` tracks the underlying fix, not whether a reply went
  out.
- **Reviewer** — the commenter's name or login (`FeliLucero1`, `github-actions[bot]`, `luisina-santos`),
  or `you` for a comment you (the automated reviewer) left on an earlier pass. Never blank; the table
  exists to attribute each fix to whoever asked for it.
- **Comment** — the comment, quoted VERBATIM. No paraphrase. Truncate with `…` only when the raw
  comment is long enough to break the table's readability; the full text still lives in the Hunk note
  (`diff-note-format.md`) or the PR thread itself, so nothing is lost by shortening it here.
- **Fix** — one clause, led by a status glyph: `✅ <what changed>` (fixed), `🟡 <what changed / what's
  left>` (partial), `❌ not fixed — <why>` (open), or `💬 <gist of the reply>` (answered, no code
  change). A `❌`/`🟡` row (or a `💬` you don't accept as resolving it) MUST also appear as a current
  finding in the findings table (Variant A item 6) — an unresolved comment is a live finding, not
  just history.
- **Verified** — `<confidence>% ✓N`, the same convention as every other finding
  (`~/.dotfiles/general/.claude/rules/review.md`): N = independent checks that confirmed the fix is
  correct (a second read, build/lint, a second agent's pass, a live/mock run). `✓0` is an honest
  "only I checked this," not a failure — never inflate N to avoid writing it.
- **e2e** — `live` / `mock` / `unit-test` / `none`: the highest tier actually run for THIS fix
  specifically, not for the run as a whole. Write `none` when nothing beyond a code read or a static
  check backed this particular fix, even if some other part of the change was tested live.

One row per comment being tracked; never merge two into one row, and never drop a row because the
fix looks trivial. The table is the attribution record, not a filtered highlight reel.

---

## Variant A — Review verdict (`## Review verdict`)

In order:
1. **`Review type:`** `first-review` | `re-review` — the FIRST line, on its own, with the bold label so it's unmissable. The operator must never have to guess whether the whole diff or just a delta was examined. On a re-review, append ` — reviewed only the <N> new commits since my last pass (<range>); did NOT re-review the rest of the PR`, AND you MUST also emit the `Prior comments` block (item 3). A re-review that doesn't announce itself as one and account for the prior comments is malformed.
2. `Recommendation: APPROVE | APPROVE WITH NOTES | COMMENT | REQUEST CHANGES` + ` — <one plain clause>`. A decision, not a hedge. These name the GitHub review action YOU (the reviewer) would submit, not an instruction to the author: `COMMENT` = leave notes without approving or blocking (neutral); `REQUEST CHANGES` = block until fixed. Pick the button you'd click. On a re-review the clause must reference the prior comments (e.g. `APPROVE — all 2 prior comments resolved, nothing new`).
   - **Re-review decision rule:** once every prior comment is addressed (`✅`, or a `💬` reply you accept), the default recommendation is **APPROVE** — the reviewer got what they asked for. Only downgrade to `COMMENT`/`REQUEST CHANGES` if something in the NEW commits since your last pass is itself a genuine BLOCKER/MAJOR must-fix. Do NOT hold on: a prior comment that's now resolved, a pre-existing issue you already knew about last pass and didn't block on, or a low-confidence/needs-live-verification concern (raise those as `COMMENT` notes, don't block). If there are no new commits at all and the comments are addressed, APPROVE.
3. **`Prior comments (<N>):`** — RE-REVIEW ONLY and REQUIRED whenever you left comments on an earlier pass, OR other reviewers left comments on the PR that a re-review can check for resolution (both count — this isn't limited to your own prior findings). (First-review, or a re-review where none exist: write `Prior comments: none left last pass` and skip the table.) Lead with a tally (`2 addressed, 0 open`), then the shared **Addressed-feedback table** (above) — one row per comment, `Reviewer` naming who left it (`you` for your own prior pass, the actual login for anyone else). This block is the whole point of a re-review; never fold it into prose, and never omit it because the findings table looks complete. Any row whose `Fix` reads `❌`/`🟡` (or a `💬` you don't accept) MUST also appear as a current finding in item 6 — an unfixed comment is a live finding, not history.
4. `Verified how: <one clause>` — what you actually ran (build/test/repro/doc-fetch) vs only read. Be honest; never imply e2e when you only read.
5. `Comments: <...>` — per the wrapper's posting model (e.g. `<D> drafted (in <path>), 0 posted` when the skill never posts).
6. `Findings: <nB> BLOCKER, <nMaj> MAJOR, <nMin> MINOR, …` (tally, or `none`), then a table with EXACT columns `Sev | Conf | ✓N | File:line | Finding`. `Conf` and `✓N` are BOTH required on every row. The `Finding` cell is the crisp one-phrase defect headline from `diff-note-format.md` §2 (`GrantableTo contains a non-principal resource type`), NOT a sentence that re-explains it. Under the table, name what the `✓N` checks were per finding, and the "why not higher" line for any sub-80% multi-validated finding (see `diff-note-format.md` §2-3).
7. `Why: <one sentence>` — the headline finding, or "no blocking findings".
8. `### Recommended actions` — universal rule 4. First bullet restates the recommendation as a runnable next step.

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
2. `## Reviewer feedback addressed` — REQUIRED whenever this run was given a `pr_feedback` payload
   (or equivalent: a dispatch JSON `feedback[]` array, an explicit PR-comment fix request) with one
   or more entries, in EVERY invocation mode (manual and dispatch alike) — not gated on
   `$AUTO_NEW_DAY_DATE_DIR`. Omit the section entirely when there was no reviewer feedback to
   address this run. This is the section operators scan first: the shared **Addressed-feedback
   table** (above), one row per comment this run addressed. Print it here even if `/report` already
   showed the same table earlier in the same response (right after opening Hunk) — the closing block
   must be self-contained (universal rule 3), so don't make the operator scroll up to find it.
3. `## Summary` — 2-4 bullets: what was done and WHY, merged into one (bullets, not a prose
   paragraph). This is the only "why" in the block; there is no separate Why line. Plain and
   skimmable; the full write-up stays in the context/report file (universal rule 2).
4. `## Ready to push` — **zero commits this run → `N/A — no code changes this run`, no `<N>%` and no
   Yes/No glyph.** "Ready to push" is a question about a diff; with nothing to push, Yes and No are
   both category errors, not just the wrong answer. Reserve the Yes/No verdict below for runs that
   landed ≥1 commit.
   Otherwise, lead with the **ready-to-push confidence** `<N>%` (how ready the change is
   for a PR: correctness + e2e + docs/scope; EXCLUDES CI-pipeline risk like lint-version drift,
   metadata-regen, and `sync-test`/integration, which routinely fail in the PR and get corrected
   there — never dock the number for them). Then the push/hold call, and, when a PR was opened this
   run, its status. The reasoning already lives in `## Summary`.
   - `✅ Yes — <N>%` = the change is READY for a PR and you are recommending it be pushed: ≥1 new
     commit AND complete + e2e-verified + no unresolved blocker. Readiness is independent of whether
     THIS skill auto-pushed. Append the push disposition: `· PR created 🚀 <url>` if the run pushed
     (push gate fired, or explicit operator push); `· held for operator (<why>)` when ready but not
     pushed, e.g. below the auto-push gate or a dispatch `never-push` instruction. Being below the
     auto-push confidence gate, or held by a dispatch, does NOT downgrade this to `No`; the change is
     still ready, it just was not auto-pushed.
   - `⛔ No — <N>%, <short blocker>` = the change is NOT ready to push: no new commit this run, an
     e2e blocker, or an unresolved concern that should stop a push. Rule of thumb: if your
     `### Recommended actions` tell the operator to push it, this line is `✅ Yes`, never `⛔ No`.
   - The rocket emoji is an explicit operator-requested exception to the global no-emoji rule; keep it
     on the PR-created status. Whether a skill auto-pushes at a confidence threshold is the SKILL's
     decision (e.g. fix-bug-work pushes at ≥95%), not this format's — this section only renders the
     number and the outcome.
   - `fix-bug`-backed runs append a `Confidence: <N>%` line here (composite / per-symptom; lead with
     it if the skill's own contract says so).
5. `## Live tenant tested` — one line: `✅ Yes` (e2e tier `live`) OR `❌ No — <tier / reason>` (`mock` /
   `unit-test` / `blocked`; `❌ No — no code changes this run` when nothing changed). Keep the required
   `e2e: <tier> — <observation>` line if the skill mandates one.
6. `## Lazy-gaps` — one line, ONLY when the run invoked the `lazy-gaps` skill (the own-work dispatch
   flows do). State whether gaps were found and addressed: `N rule(s) added (<file>, <file>); M
   covered, K skipped`, or `none — all findings already covered`, or `not run — <reason>`. Omit this
   section entirely for skills that never run lazy-gaps (e.g. the standalone report skill).
7. `### Recommended actions` — universal rule 4. When `Ready to push: ⛔ No`, the FIRST bullet is the
   exact decision/step the operator must take to unblock (e.g. `you: decide X vs Y — options in
   <context path>`). When `✅ Yes`, the first bullet is the push step (`you: push \`<sha>\` — nothing
   else owed`).

No prose walkthrough after (universal rule 2); the context file holds the full detail.

---

## Emoji note
`✅` / `⛔` / `❌` are status glyphs used deliberately in this block for at-a-glance scanning of the
push/verify decision. They are the only emoji this block uses; do not add others.
