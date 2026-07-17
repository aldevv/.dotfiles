# Dispatch closing contract — context pager pane + closing report

Single source of truth for the two end-of-run behaviors every auto-new-day-dispatched skill owes the operator: a **context pager pane** and a **closing report block**. Symlinked into each dispatched skill's `references/` dir (same as `dispatch-resume.md`). The auto-new-day dispatch sends a bare slash (`/<skill> <url>`); the skill self-applies everything here from the `$AUTO_NEW_DAY_*` env, so nothing is injected into the tmux window.

## When this runs

ONLY when the skill is running under an auto-new-day dispatch, i.e. `$AUTO_NEW_DAY_DATE_DIR` is set. Skip the whole file for manual/interactive invocations (the operator is present; no pager, no machine-readable closing block needed).

Two profiles, keyed by which env var the bootstrap exported:
- **own-work** (`$AUTO_NEW_DAY_TICKET` set) — fix-bug-work, impl-work, newconnector. Pager is built from the Linear ticket; closing block is `## Changes made`.
- **review** (`$AUTO_NEW_DAY_WINDOW` set) — pr-code-review-work. Pager is built from the PR + linked ticket; closing block is `## Review verdict`.

Do these as the FINAL steps of the run, AFTER `/report` (own-work) or the answer-draft pane is open (review — `pr-code-review-work` never posts and never asks to post; see its "CRITICAL: Close model").

## 1. Context pager pane (best-effort)

Skip silently if `$TMUX` is unset, or `less`/`fold` is missing. The closing report block (section 2) is still mandatory even when the pager is skipped.

Key derivation:
- own-work: `KEY="$AUTO_NEW_DAY_TICKET"`, brief at `$AUTO_NEW_DAY_DATE_DIR/dispatch/$KEY.brief.md`.
- review: `KEY="review-$AUTO_NEW_DAY_WINDOW"`, brief at `$AUTO_NEW_DAY_DATE_DIR/dispatch/$KEY.brief.md`.

Build the brief:
- **own-work:** fetch the ticket via Linear MCP `get_issue` (id = `$AUTO_NEW_DAY_TICKET`); capture `title`, `description`. Shape: `# <ticket>: <title>` → `## TLDR` → `## Ticket description` → `---` + `linear url: <url>`.
- **review:** `gh pr view <prUrl> --json title,author,body,headRefName,baseRefName,url` (prUrl from `$AUTO_NEW_DAY_DATE_DIR/dispatch/review-$AUTO_NEW_DAY_WINDOW.json`); if a Linear ticket is linked (payload `linearUrl` or PR body), fetch it via `get_issue`, else ticket section = `n/a`. Shape: `# <repo>#<num>: <title>` → metadata (pr url / author / branch) → `## TLDR` → `## PR description` → `## Ticket description`.

TLDR rules (both): 1-3 sentences OR 2-5 bullets, each line < 85 chars, no lead-in prose. own-work answers what breaks / where / what the fix looks like; review answers what changes / why / what to look for.

Open the pager below YOUR pane (capture your own pane id FIRST so concurrent peer windows don't stack their pagers in the operator's focused window):

```bash
B="$AUTO_NEW_DAY_DATE_DIR/dispatch/<KEY>.brief.md"
CLAUDE_PANE="$TMUX_PANE"
tmux split-window -t "$CLAUDE_PANE" -v -p 30 "zsh -lc \"export MDP_TARGET='$B'; fold -sw 85 '$B' | less -R\""
tmux select-pane -t "$CLAUDE_PANE"
```

`-t "$CLAUDE_PANE"` is required (without it tmux targets the client's active pane, and concurrent peers stack pagers in one window). `MDP_TARGET` is required so the pager's Colemak `M`-binding runs `mdp` on the original brief.md instead of less's `-` stdin marker (content is piped through `fold`).

## 2. Closing report block — last block of the run-ending response, EXACTLY ONCE

Print it as the very last thing in the FIRST response that closes the dispatched run, once. On later follow-up turns answer normally with NO trailing block. Never omit it on the closing turn; a "No"/negative line with a reason is what tells the operator the run was real.

### own-work → Variant B

**The block's sections, ordering, glyphs, and the "each is its own `##` section" rule are defined ONCE in `~/.claude/skills/report/references/format.md` → Variant B. Follow it verbatim; do NOT restate the format here.** This section adds only the dispatch-specific reason phrasings and the Recommended-actions category menu below.

Dispatch reason phrasings for Variant B's sections:
- `## Summary` (2-4 sentences, what + why merged) → e.g. `Removed the per-membership GetUser lookup per <reviewer>; the grant is now built from the user ID already in hand, which fixes the hard-fail on stale 404s.`
- `## Ready to push` → `✅ Yes` (no inline why — the reasoning lives in `## Summary`) OR `⛔ No — <short blocker>`, e.g. `⛔ No — operator needs to decide retry-on-429 vs fail-fast`.
- `## Live tenant tested` → `❌ No — no code changes this run` when the run committed nothing.
- Blocked case: `## Ready to push` = `⛔ No — <blocker>`, `## Live tenant tested` = `❌ No — <blocker>`, and `## Summary` names the blocker.

Then the Variant B `### Recommended actions` list: 2-4 bullets, most-important first, pitched at the DECISION level, not the mechanics. Each bullet answers "what kind of follow-up does the operator owe here" — the category of action, so they can triage at a glance without reading the context file. Lead each bullet with the category in bold, then one short clause of specifics (target + where the detail lives). The recurring categories:

- **Reply to the reviewer** — a comment is answered in code / needs a written response. `**Reply to <reviewer>** — the fix answers their question; draft reasoning is in the Hunk note.`
- **Make a code change** — more work is needed before this is done. `**More code needed** — <what's still unimplemented>; see context file.`
- **Push** — nothing else owed, just ship it. `**Just push** — \`<sha>\` is complete and verified, no open questions.`
- **Make a judgment call** — a decision only the operator can make (design, policy, a flagged rule conflict). `**Your call** — <the decision>, options in the context file.`
- **Verify** — something the operator should confirm before trusting it. `**Verify live** — I couldn't reach a tenant; <what to check>.`

Pick the categories that actually apply; don't force all five. If the only follow-up is to push, that's ONE bullet, not a padded list. If there's genuinely nothing, one bullet: `**Nothing** — <one-line why>.` Keep exact shas / paths / commands as the trailing specifics, never as the headline.

The block is the full Variant B set of `##` sections — `## Changes made` (a bullet per change with `file:line`; NEVER an empty header — it is a section with bullets, not the block title), `## Summary` (2-4 bullets, not a prose paragraph), `## Ready to push`, `## Live tenant tested`, `## Lazy-gaps` (own-work dispatch runs always invoke lazy-gaps, so this line is required: `N rule(s) added (<file>, <file>); M covered, K skipped`, or `none — all findings already covered`, or `not run — <reason>`) — followed by `### Recommended actions`. Do NOT collapse it to a bare title + status lines.

**Do NOT print a prose "Detail" / breakdown / walkthrough section after the block.** No re-listing of build/vet/lint output, no restated reasoning, no artifact-path dump beyond what the recommended actions reference. The context file (`$AUTO_NEW_DAY_DATE_DIR/dispatch/<TICKET>.context.md`) already holds the full write-up; the closing response is the Variant B sections + recommended actions, nothing more.

### review → `## Review verdict` (Variant A)

**Shape + ordering are defined once in `~/.claude/skills/report/references/format.md` → Variant A (and the marker/table in `diff-note-format.md`). Follow it.** This section adds only the auto-new-day-specific criteria (the exact recommendation thresholds below). Lead with the two lines the operator actually needs — is this the whole PR or a delta, and do you approve — in plain words. Everything else is backup detail below them.

- `Review type: first-review | re-review`. For a re-review, append ` — reviewed only the <N> new commits since my last pass (<short-range>); did NOT re-review the rest of the PR`. This is line 1 so the operator never has to guess whether the whole diff or a delta was examined.
- `Recommendation: APPROVE | COMMENT | REQUEST CHANGES` followed by ` — <one plain-English clause>`. These name the GitHub review action YOU (the reviewer) would submit, not an instruction to the author to pause. Decide it, don't hedge. Criteria:
  - `APPROVE` — no BLOCKER/MAJOR findings AND (re-review only) every prior review comment is resolved. Maps to `gh pr review --approve`. Say so: `APPROVE — delta resolves all N prior comments, nothing new`.
  - `REQUEST CHANGES` — >=1 unaddressed BLOCKER or MAJOR that must be fixed before merge. Maps to `gh pr review --request-changes`. Name it: `REQUEST CHANGES — <finding> must be fixed first`.
  - `COMMENT` — nothing blocking, but you are NOT approving: only MINOR/NIT or open questions worth raising. Maps to `gh pr review --comment` (neutral, no approval). `COMMENT — one minor + one question, your call whether to block`.
- `Verified how: <one clause>` — e.g. `static source read of the 6-file delta; build/tests NOT re-run this pass` or `built + ran unit tests + traced runtime path`. Be honest about what you did and did NOT run; never imply e2e when you only read.
- `Comments: <D> drafted (awaiting you in <answer-draft path>), 0 posted` — `pr-code-review-work` never posts; the operator posts from the answer-draft pane. `0 posted` is always correct on the closing turn.
- `Findings: <nB> BLOCKER, <nMaj> MAJOR, <nMin> MINOR, <nL> LOW, <nN> NIT` (the severity tally), followed by a short table with one row per finding and these EXACT columns: `Sev | Conf | ✓N | File:line | Finding`. The `Conf` and `✓N` columns are BOTH required on every row — a confidence % with no `✓N` beside it is malformed. REQUIRED, MUST NOT be dropped: `~/.dotfiles/general/.claude/rules/review.md` mandates a confidence % and `✓N` on every finding, and this block is itself a findings report.
  - `✓N` = the number of INDEPENDENT validations that confirmed the finding. In subagent mode N = verifier subagents; in `--no-subagents` / auto-new-day mode (no subagents) N = sequential validations you actually ran — doc sources cross-checked, build/test runs, runtime-path traces, repros. **Name what the N validations were** in a line under the table (e.g. `#1 ✓3 = NR docs + docs-wide search + Stitchflow guide + mock code-read`), so `✓3` is auditable, not asserted. Don't inflate N; count only checks you performed.
  - `✓0` is allowed ONLY for a trivial nit; any BLOCKER/MAJOR/MINOR is `✓1`+.
  - **Sub-80% + multi-validated → justify the ceiling.** Any finding with confidence < 80% AND `✓2`+ (or `✓K/N`) MUST carry a one-line "why not higher" under the table, naming the residual uncertainty the checks could not close (e.g. `#1: why not higher — docs may be incomplete; live schema could differ`). A `✓1` sub-80% finding is self-explanatory and doesn't need it.
  - Full format spec (marker, table, Hunk note, report block): `~/.claude/skills/report/references/format.md` (+ `diff-note-format.md`).
  - Zero findings → `Findings: none`. For a re-review with no new findings, add one line under the table mapping each prior comment to its fix (or a `resolution-map` reference in the brief) so "all resolved" is auditable, not asserted.
- `Why: <one short sentence>` (headline finding, or "no blocking findings").

Then a `### Recommended actions` list: 2-5 bullets, most-important first, each a concrete imperative addressed to the operator naming the exact target (command / reviewer / path). The child never posts, so every action is something the OPERATOR does. The FIRST bullet MUST restate the approve/hold decision as an action the operator can take right now:
- approve → `Approve on GitHub yourself: \`gh pr review <num> --approve\`.`
- request-changes → `Do NOT approve yet — <finding> needs a fix; post the drafted comment(s) from <answer-draft path>.`
- comment → `Post the <N> drafted comment(s) from <answer-draft path>, or approve as-is — your call.`
If a green-gate confirmation is still owed (static read only), add a bullet: `Optional: run \`go build ./... && go test ./...\` before you approve.` If there is genuinely nothing else to do, that single first bullet stands alone.

Never collapse the review verdict to just Recommendation/Comments/Why — the Review-type line, the explicit approve / comment / request-changes decision, the per-finding severity + confidence + `✓N` detail, and the Recommended actions list all belong in this block, not only in an earlier summary. Do NOT bury the recommendation under the findings table: the operator reads top-down and must see "re-review" and "approve or not" before any table.

## Resume note

On a resume (the dispatch-resume fast-path fired because a prior manifest exists), you did NOT add new commits this run: re-open the pager on the prior `artifacts.brief`, and print the closing block with the negative line (`Ready to push: No` / `Comments: 0 posted …`) plus `Why: resumed from prior manifest <path>; …`.
