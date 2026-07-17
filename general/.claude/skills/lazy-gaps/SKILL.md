---
name: lazy-gaps
description: Audit a set of PR-review comments / bug findings / lessons against $HOME/work/CLAUDE.md + $HOME/work/.claude/lazy/*.md. For each item, decide COVERED-AND-CORRECT / COVERED-BUT-WRONG-OR-OUTDATED / NOT-COVERED, judge whether the gap is worth a rule, then update an existing lazy file or create a new one. Entries land SHORT and CLEAR. Triggers on "/lazy-gaps", "audit lazy gaps", "are these documented in lazy", "save these review notes as rules", "check if my lazy files cover X". AUTO-INVOKE (1) at the tail of a PR-feedback fix run (after the commit + `/report` land) when the operator says "save the rules" or "document these in lazy", and (2) after any bug-fix PR is created in a Baton connector for previously-shipped code (bug ticket filed against a feature the operator already merged, e.g. CXH-1980 / CXH-1981 landing on the shipped CXH-752 impl). The fix itself is evidence a rule was missing, so audit before ending the turn even without an explicit ask. Do NOT trigger for skill-body edits (use the relevant skill directly), for connector-specific notes that belong in `CLAUDE.local.md`, or to bulk-rewrite a lazy file (that's `claude-md-simplify`).
argument-hint: "[source] [scope=work|all|auto]" — `source` is either a path to a dispatch JSON (`~/work/.auto-new-day/dispatch/<TICKET>.json`), a PR URL whose comments you want audited, or free text describing each item one per line. `scope` controls which lazy files the audit walks: `work` = only `$HOME/work/CLAUDE.md` + `$HOME/work/.claude/lazy/*.md`; `all` = work files plus the global `~/CLAUDE.md` + `~/.claude/lazy/**/*.md`; `auto` (default) = walk ancestors from cwd (work files when inside `$HOME/work/`, global otherwise). `fix-bug-work` always passes `scope=work`. Empty source = ask the operator.
---

# lazy-gaps

Close the loop on a PR review (or any batch of lessons): every actionable item either becomes a rule the next dispatched run picks up automatically, or gets logged as "intentionally not worth a rule". Either way the operator never relearns the same thing twice.

## When this skill earns its cost

Use after:
- A PR-feedback fix run lands (the dispatched feedback was real-world, distilled by reviewers, likely to repeat).
- A bug post-mortem produces concrete dos/don'ts.
- A vendor-API gotcha hits during build/test (timeouts, undocumented codes, field-name drift).
- A CI failure exposes a missing rule.

Do NOT use for:
- Personal credentials or per-trial recipes (those belong in `CLAUDE.local.md`).
- Restructuring an entire lazy file (use `claude-md-simplify`).
- Editing a skill body or hook (edit it directly).
- One-off oddities that won't repeat across connectors.

## Input formats

`<source>` (passed via $ARGUMENTS):

| Form | Example | Skill reads |
|---|---|---|
| Dispatch JSON path | `~/work/.auto-new-day/dispatch/CXH-1491.json` | the `feedback[]` array |
| PR URL | `https://github.com/ConductorOne/baton-foo/pull/29` | `gh pr view` + `gh api .../pulls/<n>/comments` |
| Linear ticket URL | `https://linear.app/conductorone/issue/CXH-1491` | the ticket body + comments via the linear MCP |
| Free text | `404 on revoke should be GrantAlreadyRevoked. ResourceIdField for synced refs.` | one item per line / semicolon |
| Empty | (nothing) | ask the operator for items |

If the source contains items the skill can't normalize into a one-line statement (vague rambling, multiple ideas per line), ask the operator to restate before continuing.

## Workflow

### 1. Build the item list

Normalize the source into a flat list. Each item is one rule candidate: a single concrete behaviour the next agent should follow (or avoid). Examples:

- `revoke must return GrantAlreadyRevoked on 404`
- `user_id action args use ResourceIdField with AllowedResourceTypeIds`
- `every pkg/client/ HTTP wrapper doc comment names <METHOD> /path + required permission`
- `argument-validation errors wrap with status.Error(codes.InvalidArgument, ...)`

If two PR comments boil down to the same rule, dedupe to one item.

### 2. For each item, audit coverage

Walk the lazy index and `$HOME/work/CLAUDE.md`. Grep for the most distinctive 1-3 keywords (function names, type names, vendor-specific terms). Read the matching section in full when you get a hit.

Classify into one of three buckets:

- **COVERED-AND-CORRECT** — already documented, says the right thing. Note the file:line for the audit trail; no edit needed.
- **COVERED-BUT-WRONG-OR-OUTDATED** — a rule exists but contradicts the new lesson (or shows a now-anti-pattern example, or names the wrong helper / endpoint / convention). Plan a surgical edit.
- **NOT-COVERED** — no relevant rule anywhere.

The audit is read-only at this phase. Do not edit yet.

### 3. For NOT-COVERED items, judge importance

Ask: would a fresh agent (or a different connector's PR) plausibly trip this same wire again?

KEEP (worth a rule) if any of:
- The same shape of mistake has now been raised twice (this PR + any prior commit / lesson the operator can recall).
- The vendor/SDK convention is non-obvious to anyone who hasn't shipped a similar connector.
- It's a CRITICAL portfolio rule (auth, error wrapping, gRPC codes, capability annotations, push safety).
- Multiple connectors expose the same surface (HTTP wrapper docs, action arg fields, revoke idempotency) and a rule applied portfolio-wide would catch it.

SKIP (not worth a rule) if any of:
- Vendor-specific edge case unlikely to repeat (e.g. "Acme returns 200 with body `null` only on Tuesdays").
- Already obvious from `~/CLAUDE.md` or a global rule.
- Personal preference of one reviewer with no consensus.
- Documents in code (a function name + signature already says what the rule is).

### 4. Plan the edits

For each KEEP item (and every COVERED-BUT-WRONG item), pick a target (or targets, see below). Preference order:

1. **Update the closest matching lazy file in place** — usually the right choice. Append to the most relevant existing section, or add one short bullet to a "Common Mistakes" / "Gotchas" list.
2. **Add a new top-level section to an existing lazy file** — when the item is a new sub-topic of an existing file (e.g. a new `### 404 on Revoke` section under `golang-connectors.md`'s idempotency block).
3. **Create a brand-new lazy file** — when no existing lazy file is a natural home, or when the topic has its own trigger distinct from any current file. Justification bar: the item has a clear `**Read when**` trigger that a fresh agent can recognize (a specific file path, a command, an error string, a user phrase — see `~/.claude/lazy/trigger-authoring.md`). Register the new file in `~/work/CLAUDE.md`'s `## Detail files (load on demand)` index with that trigger. **Do NOT gate this option on "5+ connectors will touch it" or "5+ rules land at once".** A single well-triggered rule that has no home already justifies a new lazy file — a wasted lazy load is fine, a rule buried in the wrong file is not.

**CRITICAL: one gap can need MORE THAN ONE home. Do not add it to one file and call it done.** A rule often governs several work-surfaces that load through DIFFERENT triggers. If it lands in only the first file, an agent working a surface covered by a different trigger never sees it, and the same mistake recurs. For every KEEP / COVERED-BUT-WRONG item:

1. **List every distinct surface the rule constrains** (e.g. test fixtures, docs, source comments, config.yaml, CI workflows, error strings). One item, possibly many surfaces.
2. **Map each surface to the lazy file whose `**Read when**` trigger fires there.** Fixtures → `testing.md`; docs → `docs.md`; HTTP config → `http-connectors.md`; CI → `pipelines.md`; and so on. When two surfaces map to two different files, the rule needs a presence in BOTH.
3. **Full rule in the PRIMARY home** (the surface where the mistake most often originates), plus a **one-line cross-reference** in each other triggered file (`See <file> → <section>` per the `~/work/CLAUDE.md` "link, don't copy" convention). Duplicate the whole rule only when it is a single short sentence and a cross-ref would be more friction than the copy. A wrong rule fixed in one file but left stale in another is the same COVERED-BUT-WRONG bug: fix every copy.

Worked shape: "no customer data in a public repo" constrains fixtures (`testing.md`), docs runbooks (`docs.md`), and source comments (any Go file). Primary home `testing.md`; a one-line cross-ref bullet in `docs.md` so a docs-only edit still surfaces it. One surface, one file → one edit; several surfaces, several files → several edits.

**CRITICAL: `~/work/CLAUDE.md` is not a save target for new rules.** Do NOT append new bullets, sections, or paragraphs to `~/work/CLAUDE.md`. Every KEEP item lands in an existing lazy file or a new lazy file. Even portfolio-wide CRITICAL rules go into a lazy file — the Detail-files index in `~/work/CLAUDE.md` names the trigger, so `**Read when:** working in any baton connector` is legitimate for a rule that truly applies every turn. If the rule doesn't fit any existing lazy file's trigger, that's the signal to CREATE a new one, not to inline it in CLAUDE.md.

The ONLY exception is a COVERED-BUT-WRONG edit that surgically rewrites an existing wrong line already inside `~/work/CLAUDE.md` (see Step 6). Adding new content is off-limits.

**When `~/work/CLAUDE.md` looks too big or a section reads as out-of-place**, treat that as a signal to extract or move content into a lazy file (delegate to `claude-md-simplify` — see Sibling skills), not to keep piling on inline.

### CRITICAL: as small as possible while still clear

Every entry has a hard size budget. Draft, then cut.

- **Bullet in an existing list**: 1 sentence, max 2 lines. No snippet.
- **New sub-section in an existing lazy file**: 3-6 lines of prose, plus at most ONE minimal snippet (5-10 lines, only the load-bearing shape). Anything explainable in prose stays as prose.
- **Worked case / new pattern**: 12-20 lines TOTAL including snippet. If the draft is longer, cut the snippet to the smallest shape that shows the pattern (drop repeated fields, drop non-load-bearing lines), or split into two sub-sections when they're independently useful.
- **New lazy file**: when no existing file's trigger fits, or when the topic has its own distinct load moment. See Step 4 for the trigger-fit bar. A single well-triggered rule is enough justification.

**Mandatory trim pass.** After drafting each entry, delete every sentence that doesn't change what a reader will DO. Ban: repetition ("as noted above..."), meta-narration ("added because..."), context prose that could live in the commit message, ceremony phrases ("worth noting that", "it should be pointed out"). If cutting a sentence loses information the reader must have, keep it; otherwise it's tax.

Style directives:

- **CLEAR.** State the rule as a directive: "use X", "every Y must Z", "never do W". Not "consider", "you might want to", "in some cases". If the rule has exceptions, list them in the same breath.
- **GREP-FRIENDLY.** Name the SDK helper, the vendor field, the annotation type, the gRPC code. Future agents grep for these strings. Keep the file:line pointer that anchors the rule; drop everything else.
- **NO EM-DASHES.** Use commas, periods, parens. (Global writing-style rule.)
- **NO META-NARRATION.** "added because luisina flagged this" belongs in the commit message, not the rule. Rules state what to do, not the history of why we wrote them down.

For COVERED-BUT-WRONG edits, prefer rewriting the wrong line in place rather than appending a new contradicting rule. If the wrong rule has authority (e.g. a documented example shows the anti-pattern), fix the example too.

### 5. Confirm before editing

**CRITICAL: never ask when dispatched under an `AUTO-` tmux session.** If the current tmux session name starts with `AUTO-` (auto-new-day dispatch: `AUTO-inreview`, `AUTO-inprogress`, `AUTO-inreview-others`, `AUTO-ready-to-merge`), OR `$AUTO_NEW_DAY_DATE_DIR` is set, SKIP the `AskUserQuestion` entirely and auto-apply every KEEP + WRONG edit. These sessions run unattended; a question blocks the dispatch forever. Detect with `tmux display-message -p '#S' 2>/dev/null` and bail on the prompt when it matches `^AUTO-`. Record the auto-applied set in the Step 7 report instead of asking.

Otherwise (interactive session), show the operator one `AskUserQuestion` with the planned set. The question lists per item:

- `<short rule statement>`
- Verdict: COVERED-AND-CORRECT / COVERED-BUT-WRONG / NOT-COVERED-KEEP / NOT-COVERED-SKIP
- Target file:section (or "new file: ..."). List EVERY target when the item needs more than one home (primary + each cross-ref file), not just the first.
- Verbatim text that will land (for KEEP + WRONG)

Two options:
- **Apply all KEEP + WRONG edits.**
- **Revise** (operator names which items to drop, retarget, or rewrite).

If creating a new lazy file is in the plan, surface the proposed filename + `**Read when**` trigger explicitly and ask for sign-off on those alone (separate question or inline).

### 6. Apply edits

**CRITICAL: every new-rule add goes through `claude-md-save`. Never use raw `Edit` / `Write` for a NOT-COVERED-KEEP item.**

Invoke `claude-md-save` once per NOT-COVERED-KEEP item with the trimmed rule text from Step 4. This applies to bullets, new sub-sections, new worked-cases, and new lazy files alike — anything that ADDS content. `claude-md-save` owns symlink resolution, section-picking, `CLAUDE.local.md` fallback, lazy-index registration in the parent CLAUDE file, `.git/info/exclude` writes, and the work/global/project scope decision. Duplicating any of that here rots the moment `claude-md-save` gains a step.

`claude-md-save` re-runs its own target decision; when its choice differs from the target the operator approved in Step 5, surface the divergence in the Step 7 report so the operator can decide whether to move the entry. For the common case (scope=work + a rule that grep-audits into a specific lazy file), both skills land on the same target.

**Only exception** — COVERED-BUT-WRONG edits use surgical `Edit` calls, because `claude-md-save` is append-only and cannot rewrite an existing line in place. Anchor the `old_string` on the wrong text and swap it. Do not use this exception for anything else.

After every edit (delegated or direct), confirm the file still parses: the lazy-index entry exists if a new file was added, the `**Read when**` trigger is grammatical, no broken markdown fences.

Do NOT commit. The operator owns the commit.

### 7. Report

Print a tight summary:

- N items audited.
- N already-covered (cited file:line).
- N wrong-or-outdated (cited the edit per file).
- N net-new entries (cited every file + section each landed in; when an item needed multiple homes, list the primary AND each cross-ref file, so a partial save is visible).
- N skipped as not-worth-a-rule (one-line reason each, so the operator can disagree).

End with the `Changes made` block from the auto-new-day pattern: `Verdict: Yes | No` + one-line `Why:`.

## Anti-patterns

- **Oversize entries.** Worked-case sections that spill past 20 lines, snippets that reproduce a whole config block when 6 lines show the shape, prose that repeats what the snippet shows. Cut the snippet, cut the prose.
- **Bypassing `claude-md-save`** for NOT-COVERED-KEEP adds. The only Edit-tool exception is COVERED-BUT-WRONG (rewrite in place). Anything that ADDS content goes through the save skill.
- **Padded rules.** "It is generally considered best practice to..." → delete and write "use X."
- **Rule-by-attribution.** "Per luisina's review, ..." → state the rule, not the source.
- **Adding new content to `~/work/CLAUDE.md`.** New rules land in a lazy file (existing or new). The only edit allowed on `~/work/CLAUDE.md` is a surgical rewrite of an existing wrong line (COVERED-BUT-WRONG). If a rule "must apply every turn," its lazy file trigger says so, `~/work/CLAUDE.md` itself does not accumulate content.
- **Piling into an existing lazy file when the topic doesn't fit its trigger.** If a rule's natural trigger differs from every existing lazy file's `**Read when:**`, that's the signal to create a new lazy file, not to shoehorn the rule into the closest wrong home. Trigger fit beats file-count minimalism.
- **One-and-done when a gap spans multiple triggers.** Adding a rule to one lazy file and stopping, when the rule governs surfaces that load through different triggers (fixtures + docs + CI, etc.). The unaddressed files leave the same mistake reachable. Map every constrained surface to its file and land the rule (full or cross-ref) in each (Step 4).
- **Rules that restate `~/CLAUDE.md`.** Don't re-encode global writing-style or git-safety rules into work-scope files. Point to them by name.
- **Burying the rule in a code example.** The rule must be readable as prose first; the snippet is the illustration.
- **Forgetting the index.** A new lazy file that isn't registered in `~/work/CLAUDE.md`'s `## Detail files (load on demand)` index won't get loaded on trigger. Always register.

## Worked example

Input: dispatch JSON for CXH-1491 with 6 PR-comment items (1× 404-on-revoke, 1× doc-comments on HTTP wrappers, 1× ResourceIdField, 1× SDK helpers, 1× error prefix, 1× InvalidArgument).

Audit result:
- 404-on-revoke → NOT-COVERED-KEEP (portfolio-wide; revoke paths repeat across every connector). Target: append to `golang-connectors.md` idempotency section.
- HTTP-wrapper doc comments → NOT-COVERED-KEEP (every connector ships a `pkg/client/`). Target: append to `golang-connectors.md` client section.
- ResourceIdField on synced-resource args → COVERED-BUT-WRONG (`actions.md` examples used `StringField`). Target: fix examples + add one bullet to Common Mistakes.
- `actions.GetStringArg` / `GetResourceIDArg` → COVERED-BUT-WRONG (`actions.md` showed `args.Fields[...]`). Same target.
- `baton-<connector>:` error prefix → COVERED-BUT-WRONG (`~/work/CLAUDE.md:344` had `<connector>-connector:`). Target: fix the line.
- `status.Error(codes.InvalidArgument, ...)` on arg validation → NOT-COVERED-KEEP (portfolio; every action has arg validation). Target: append to the new `actions.md` section + Common Mistakes.

5 edits, no new lazy file. Operator approves; skill applies; reports.

## Sibling skills

- `claude-md-save` — invoked by Step 6 above to actually write NOT-COVERED-KEEP entries. Owns symlink resolution, target-file decision, section-picking, lazy-index registration, and gitignore. Also usable directly when the operator has a single rule to save ("save this in my claude") and doesn't need the audit pass.
- `claude-md-simplify` — restructure / trim an oversized CLAUDE.md or lazy file. Different problem; this skill ADDS rules and fixes wrong ones, simplify CONSOLIDATES.
- `trigger-improver` — once a lazy file's `**Read when**` clause exists, this skill tunes the wording to fire correctly. Use after `lazy-gaps` creates the entry, if its triggers don't match real queries.
