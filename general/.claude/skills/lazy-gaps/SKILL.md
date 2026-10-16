---
name: lazy-gaps
description: Audit a batch of lessons (PR-review comments, bug findings, post-mortem notes) against the governing CLAUDE.md and .claude/lazy/*.md files, then save what is missing. Classifies each item COVERED-AND-CORRECT, COVERED-BUT-WRONG-OR-OUTDATED, or NOT-COVERED, and writes the worthwhile gaps short and grep-friendly into the lazy file whose trigger fits, creating a new file when none does. Triggers on "/lazy-gaps", "audit lazy gaps", "are these documented in lazy", "save these review notes as rules", "check if my lazy files cover X". Also self-invoke without being asked (1) at the tail of a PR-feedback fix run, once the commit and /report have landed, and (2) after a bug-fix PR against previously-shipped code, since the fix itself is evidence a rule was missing. Do NOT use to edit a skill body or hook (edit those directly), to store machine-local recipes or credentials (CLAUDE.local.md), or to restructure a file wholesale (claude-md-simplify).
argument-hint: "[source: dispatch-JSON path | PR URL | ticket URL | free text, one item per line] [scope: work|all|auto, default auto]"
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
- One-off oddities that won't repeat across projects.

## Input formats

`<source>` (passed via $ARGUMENTS):

| Form | Example | Skill reads |
|---|---|---|
| Dispatch JSON path | `<dispatcher-dir>/dispatch/ENG-1491.json` | the `feedback[]` array |
| PR URL | `https://github.com/acme/widget-api/pull/29` | `gh pr view` + `gh api .../pulls/<n>/comments` |
| Ticket URL | `https://tracker.example.com/issue/ENG-1491` | the ticket body + comments via the tracker's MCP |
| Free text | `404 on delete should count as success. Validate config flags at startup.` | one item per line / semicolon |
| Empty | (nothing) | ask the operator for items |

If the source contains items the skill can't normalize into a one-line statement (vague rambling, multiple ideas per line), ask the operator to restate before continuing.

`<scope>` controls which rule files the audit walks:

(`$WORK` below is the workspace root: a shared parent tree with its own `CLAUDE.md` and `.claude/lazy/`, e.g. an employer folder like `~/work`.)

| Value | Walks |
|---|---|
| `work` | `$WORK/CLAUDE.md` + `$WORK/.claude/lazy/*.md` only |
| `all` | the work files, plus global `~/CLAUDE.md` + `~/.claude/lazy/**/*.md` |
| `auto` (default) | ancestor walk from cwd: work files when inside `$WORK/`, global otherwise |

Callers that always run inside the workspace tree pass `scope=work`.

**CRITICAL: a named target or scope never narrows classification.** Every run sorts each item into its own tier and saves it there, even when the caller names one file (e.g. "update `CLAUDE.local.md`") or one scope:

| Tier | Home |
|---|---|
| Repo-only (one project's third-party quirks, test-account recipes, config modes) | that repo's `CLAUDE.local.md` / repo-local lazy files |
| Workspace (true for every repo under a shared parent tree: tooling, browser-automation/credential recipes, shared dev-environment flows, shared SDK behavior) | that tree's `.claude/lazy/*.md` (e.g. `$WORK/.claude/lazy/`) |
| Org-level fact the operator states (company events, priority shifts) | that tree's `CLAUDE.md` (see Step 4 exception) |
| Universal (any codebase, any employer) | global `~/.claude/lazy/**` |

The named target receives only the items that belong in it. A run that writes every lesson into the one file the caller named, and audits nothing else, is the failure this rule prevents.

## Workflow

### 1. Build the item list

Normalize the source into a flat list. Each item is one rule candidate: a single concrete behaviour the next agent should follow (or avoid). Examples:

- `delete must treat 404 as success, not an error`
- `config flags are validated at startup, never lazily on first use`
- `every HTTP client wrapper doc comment names <METHOD> /path + required permission`
- `argument-validation errors map to the API's invalid-argument error code`

If two PR comments boil down to the same rule, dedupe to one item.

**Session sweep (when the source is a session or free-text summary).** Also scan the session itself for lessons the caller didn't list: a documented recipe that failed and needed a workaround (a COVERED-BUT-WRONG candidate), a tool behavior that surprised (a secret leaking into a snapshot, a command matching its own shell), a helper script improvised to get past a blocker, a flow step that moved. Add each as an item and tier it like the rest.

### 2. For each item, audit coverage

Start by building the knowledge tree: `python3 ${CLAUDE_SKILL_DIR:-~/.claude/skills/lazy-gaps}/scripts/knowledge-tree.py [repo-path]`. It prints JSON, built fresh from disk, of every tier (global, workspace, repo): each rule file with its `Read when` trigger and `##`/`###` headings, plus `kind` (`claude-md`, `lazy`, `rule`, `script`). Use it to pick candidate files per tier by trigger and headings, then grep and read those files. Never cache or hand-edit this JSON; rerun it instead.

Walk the lazy index and `$WORK/CLAUDE.md`. Grep for the most distinctive 1-3 keywords (function names, type names, vendor-specific terms). Read the matching section in full when you get a hit.

Classify into one of three buckets:

- **COVERED-AND-CORRECT** — already documented, says the right thing. Note the file:line for the audit trail; no edit needed.
- **COVERED-BUT-WRONG-OR-OUTDATED** — a rule exists but contradicts the new lesson (or shows a now-anti-pattern example, or names the wrong helper / endpoint / convention). Plan a surgical edit.
- **NOT-COVERED** — no relevant rule anywhere.

The audit is read-only at this phase. Do not edit yet.

### 3. For NOT-COVERED items, judge importance

Ask: would a fresh agent (or a different project's PR) plausibly trip this same wire again?

KEEP (worth a rule) if any of:
- The same shape of mistake has now been raised twice (this PR + any prior commit / lesson the operator can recall).
- The vendor/SDK convention is non-obvious to anyone who hasn't built something similar.
- It's a CRITICAL portfolio rule (auth, error handling, permission metadata, push safety).
- Multiple projects expose the same surface (HTTP client wrappers, argument validation, delete idempotency) and a rule applied workspace-wide would catch it.

SKIP (not worth a rule) if any of:
- Vendor-specific edge case unlikely to repeat (e.g. "Acme returns 200 with body `null` only on Tuesdays").
- Already obvious from `~/CLAUDE.md` or a global rule.
- Personal preference of one reviewer with no consensus.
- Documents in code (a function name + signature already says what the rule is).

### 4. Plan the edits

**CRITICAL: decide SCOPE before picking a file.** A rule that is only true inside ONE repo's checkout (its Helm chart, build, CI, file layout, deploy cells, service-specific values, per-repo conventions) is REPO-SCOPED and must land in that repo's own `<repo>/.claude/lazy/<topic>.md`, registered in a repo-local `<repo>/CLAUDE.md` Detail-files index. Do NOT put a repo-specific rule in a shared `$WORK/.claude/lazy/*` file: that loads it for every unrelated workspace session AND buries it where the next agent working that repo won't look. A rule is WORKSPACE-SCOPED (shared `$WORK/.claude/lazy/*`) only when it genuinely applies across multiple repos. Creating the repo-local `CLAUDE.md` + `.claude/lazy/` structure from scratch is expected when the repo has none yet — that is the correct move, not a reason to fall back to a shared file. When the scope is genuinely ambiguous, `claude-md-save` (Step 6) owns the final call; pass it the scope you concluded so it confirms or corrects.

For each KEEP item (and every COVERED-BUT-WRONG item), pick a target (or targets, see below) WITHIN the chosen scope. Preference order:

1. **Update the closest matching lazy file in place** — the right choice only when an existing file at the CORRECT SCOPE already has a fitting trigger. Do not reach for a shared-scope file just because it is the closest existing one; scope-correctness beats proximity. Append to the most relevant existing section, or add one short bullet to a "Common Mistakes" / "Gotchas" list. **Trigger match beats topical proximity.** A file named after a TOOL or FEATURE (`tracker.md`, `go-services.md`) is not a natural home for a cross-cutting JUDGMENT-CALL rule (when to stop implementing and escalate, when to reject a request, when a behavior needs a design decision) just because the example that surfaced it happened to involve that tool. Test it: would this rule's `**Read when**` fire regardless of which tool or project is involved? If yes, and no existing file's trigger already names that judgment call, it fails test 1 even when one file sits right next to the topic — move to test 2 or 3.
2. **Add a new top-level section to an existing lazy file** — when the item is a new sub-topic of an existing file at the correct scope (e.g. a new `### 404 on Delete` section under `api-clients.md`'s idempotency block).
3. **Create a brand-new lazy file** — when no existing lazy file AT THE CORRECT SCOPE is a natural home, or when the topic has its own trigger distinct from any current file. This is the default for a repo-scoped rule when the repo has no matching lazy file yet. Justification bar: the item has a clear `**Read when**` trigger that a fresh agent can recognize (a specific file path, a command, an error string, a user phrase — see `~/.claude/lazy/trigger-authoring.md`). Register the new file in the governing CLAUDE.md for its scope (repo-local `<repo>/CLAUDE.md` for repo-scoped rules, `$WORK/CLAUDE.md` for workspace-scoped) under a `## Detail files (load on demand)` index with that trigger. **Do NOT gate this option on "5+ projects will touch it" or "5+ rules land at once".** A single well-triggered rule that has no home already justifies a new lazy file — a wasted lazy load is fine, a rule buried in the wrong file (or wrong scope) is not. **Two or more audited items sharing a theme that no existing file's trigger names** (e.g. several "stop and escalate instead of implementing" lessons landing in one audit) is a strong signal for a new file, even when a topically-adjacent file exists — see the trigger-match test in option 1.

**CRITICAL: one gap can need MORE THAN ONE home. Do not add it to one file and call it done.** A rule often governs several work-surfaces that load through DIFFERENT triggers. If it lands in only the first file, an agent working a surface covered by a different trigger never sees it, and the same mistake recurs. For every KEEP / COVERED-BUT-WRONG item:

1. **List every distinct surface the rule constrains** (e.g. test fixtures, docs, source comments, config.yaml, CI workflows, error strings). One item, possibly many surfaces.
2. **Map each surface to the lazy file whose `**Read when**` trigger fires there.** Fixtures → `testing.md`; docs → `docs.md`; HTTP config → `http-config.md`; CI → `pipelines.md`; and so on. When two surfaces map to two different files, the rule needs a presence in BOTH.
3. **Full rule in the PRIMARY home** (the surface where the mistake most often originates), plus a **one-line cross-reference** in each other triggered file (`See <file> → <section>` per the `$WORK/CLAUDE.md` "link, don't copy" convention). Duplicate the whole rule only when it is a single short sentence and a cross-ref would be more friction than the copy. A wrong rule fixed in one file but left stale in another is the same COVERED-BUT-WRONG bug: fix every copy.

Worked shape: "no customer data in a public repo" constrains fixtures (`testing.md`), docs runbooks (`docs.md`), and source comments (any Go file). Primary home `testing.md`; a one-line cross-ref bullet in `docs.md` so a docs-only edit still surfaces it. One surface, one file → one edit; several surfaces, several files → several edits.

**CRITICAL: `$WORK/CLAUDE.md` is not a save target for new rules.** Do NOT append new bullets, sections, or paragraphs to `$WORK/CLAUDE.md`. Every KEEP item lands in an existing lazy file or a new lazy file. Even portfolio-wide CRITICAL rules go into a lazy file — the Detail-files index in `$WORK/CLAUDE.md` names the trigger, so `**Read when:** working in any repo under the workspace` is legitimate for a rule that truly applies every turn. If the rule doesn't fit any existing lazy file's trigger, that's the signal to CREATE a new one, not to inline it in CLAUDE.md.

Two exceptions: (a) a COVERED-BUT-WRONG edit that surgically rewrites an existing wrong line already inside `$WORK/CLAUDE.md` (see Step 6); (b) an org-level fact the operator states that changes priorities for every work session (a company event, a project becoming top priority). Add (b) as a short `## CRITICAL:` section near the top plus a table-of-contents entry, 2-3 sentences, pointing to the repo-local file for details. Anything else is off-limits.

**Helper scripts.** When a saved rule depends on a script the session improvised (a one-shot secret server, a receiver, a log parser), save the script to the tier's `.claude/scripts/` (e.g. `$WORK/.claude/scripts/`, or `~/.claude/scripts/` for global rules) with a 2-3 line docstring, and point the rule at that path. A rule that says "use the helper" with no saved helper is unusable next session.

**When `$WORK/CLAUDE.md` looks too big or a section reads as out-of-place**, treat that as a signal to extract or move content into a lazy file (delegate to `claude-md-simplify` — see Sibling skills), not to keep piling on inline.

### CRITICAL: as small as possible while still clear

Every entry has a HARD size budget, enforced, not aspirational. Default to the SHORTEST entry that still stands alone; when in doubt, err too terse. Draft, then cut, then count.

- **Bullet in an existing list**: 1 sentence, max 2 lines. No snippet.
- **New sub-section in an existing lazy file**: 6 lines of prose is the CEILING, not the target, aim for 3-4. Plus at most ONE minimal snippet (5-10 lines, only the load-bearing shape). Anything explainable in prose stays as prose.
- **Worked case / new pattern**: 12-20 lines TOTAL including snippet. If the draft is longer, cut the snippet to the smallest shape that shows the pattern (drop repeated fields, drop non-load-bearing lines), or split into two sub-sections when they're independently useful.
- **New lazy file**: when no existing file's trigger fits, or when the topic has its own distinct load moment. See Step 4 for the trigger-fit bar. A single well-triggered rule is enough justification.

**Mandatory count + trim pass (do NOT skip).** After drafting each entry, COUNT its prose lines. Over the budget above → you MUST cut until it fits; the only alternative is stating in the Step 7 report the specific reason every surviving line is load-bearing (rare, and the burden is on you to justify it, not on the reader to tolerate it). Density counts too: one paragraph cramming 5+ clauses is over budget even inside the line count. Enforce ONE fact per sentence and DELETE, on sight:
- mechanism / internals the rule doesn't need ("it calls X which calls Y", "returns a plain `*http.Client`" when the point is just "no code is attached"),
- why-it-happens narration and any clause a grep of the named symbol would answer,
- repetition ("as noted above..."), meta-narration ("added because..."), commit-message context, ceremony ("worth noting that", "it should be pointed out"),
- restated framing / analogies ("the same trap as ...") that don't tell the reader what to DO.

Keep a sentence ONLY if losing it changes what the reader does. Everything else is tax. If the trimmed rule still needs the mechanism to be actionable, that is the rare load-bearing case, keep the one clause and say so in the report.

Style directives:

- **CLEAR.** State the rule as a directive: "use X", "every Y must Z", "never do W". Not "consider", "you might want to", "in some cases". If the rule has exceptions, list them in the same breath.
- **GREP-FRIENDLY.** Name the SDK helper, the vendor field, the annotation type, the error code. Future agents grep for these strings. Keep the file:line pointer that anchors the rule; drop everything else.
- **NO EM-DASHES.** Use commas, periods, parens. (Global writing-style rule.)
- **NO META-NARRATION.** "added because the reviewer flagged this" belongs in the commit message, not the rule. Rules state what to do, not the history of why we wrote them down.

For COVERED-BUT-WRONG edits, prefer rewriting the wrong line in place rather than appending a new contradicting rule. If the wrong rule has authority (e.g. a documented example shows the anti-pattern), fix the example too.

### 5. Apply by default, don't ask

**Default: apply every KEEP + WRONG edit without asking.** Invoking this skill IS the authorization. The operator asked for rules to be saved; making them confirm the save again is friction they already paid for. This holds in interactive sessions too, not just `AUTO-` dispatch. Report what landed in Step 7 and let them correct it there, editing a saved rule is cheap and they can see the diff.

Creating a new lazy file is NOT on its own a reason to ask. Pick the filename and trigger, state them in the report, move on.

**Ask only when the audit surfaced a genuine judgment call the operator owns**, narrow set:

- Two targets are defensible and the choice changes whether the rule fires at all (not merely which file it sits in), and the audit can't break the tie.
- The lesson contradicts a rule the operator wrote deliberately, so applying it would overrule a decision rather than fill a gap.
- An item might not be a rule at all (arguably a one-off), and saving it would add noise the operator has to live with every load.

When one of those fires, ask ONE `AskUserQuestion` covering just the contested items and apply the rest regardless. Never block the whole batch on one uncertain entry.

**Never ask when dispatched under an `AUTO-` tmux session** (`AUTO-inreview`, `AUTO-inprogress`, `AUTO-inreview-others`, `AUTO-ready-to-merge`), or when `$AUTO_NEW_DAY_DATE_DIR` is set. These run unattended and a question blocks the dispatch forever. Detect with `tmux display-message -p '#S' 2>/dev/null` and match `^AUTO-`. In that mode even the narrow judgment-call cases above get auto-applied; note them in the report as needing review.

### 6. Apply edits

**CRITICAL: every new-rule add goes through `claude-md-save`. Never use raw `Edit` / `Write` for a NOT-COVERED-KEEP item.**

Invoke `claude-md-save` once per NOT-COVERED-KEEP item with the trimmed rule text from Step 4. This applies to bullets, new sub-sections, new worked-cases, and new lazy files alike — anything that ADDS content. `claude-md-save` owns symlink resolution, section-picking, `CLAUDE.local.md` fallback, lazy-index registration in the parent CLAUDE file, `.git/info/exclude` writes, and the work/global/project scope decision. Duplicating any of that here rots the moment `claude-md-save` gains a step.

`claude-md-save` re-runs its own target decision; when its choice differs from the target the audit picked in Step 4, surface the divergence in the Step 7 report so the operator can decide whether to move the entry. For the common case (scope=work + a rule that grep-audits into a specific lazy file), both skills land on the same target.

**Only exception** — COVERED-BUT-WRONG edits use surgical `Edit` calls, because `claude-md-save` is append-only and cannot rewrite an existing line in place. Anchor the `old_string` on the wrong text and swap it. Do not use this exception for anything else.

After every edit (delegated or direct), confirm the file still parses: the lazy-index entry exists if a new file was added, the `**Read when**` trigger is grammatical, no broken markdown fences.

Do NOT commit. `$WORK/.claude/` is not a git repo, so work-scope edits are live once written; never tell the operator to commit them. Only repo-local lazy files (inside a real git checkout) have a commit for the operator to own.

### 7. Report

Print a tight summary:

- N items audited.
- N already-covered (cited file:line).
- N wrong-or-outdated (cited the edit per file).
- N net-new entries (cited every file + section each landed in; when an item needed multiple homes, list the primary AND each cross-ref file, so a partial save is visible).
- N skipped as not-worth-a-rule (one-line reason each, so the operator can disagree).
- **Per tier:** one line each for repo, workspace, `$WORK/CLAUDE.md`, and global, naming what landed or `none (<why>)`. A tier with no line reads as "never audited".

End with a `Changes made` block: `Verdict: Yes | No` + one-line `Why:`.

## Anti-patterns

- **Oversize entries.** A sub-section past its 6-line ceiling, a dense paragraph cramming 5+ clauses (over budget even within the line count), a worked case past 20 lines, a snippet reproducing a whole config block when 6 lines show the shape, prose that repeats the snippet or explains mechanism/internals the rule doesn't need. Count the lines, cut to the shortest entry that still stands alone.
- **Bypassing `claude-md-save`** for NOT-COVERED-KEEP adds. The only Edit-tool exception is COVERED-BUT-WRONG (rewrite in place). Anything that ADDS content goes through the save skill.
- **Padded rules.** "It is generally considered best practice to..." → delete and write "use X."
- **Rule-by-attribution.** "Per <reviewer>'s review, ..." → state the rule, not the source.
- **Adding new content to `$WORK/CLAUDE.md`.** New rules land in a lazy file (existing or new). The only edits allowed on `$WORK/CLAUDE.md` are a surgical rewrite of an existing wrong line (COVERED-BUT-WRONG) and an operator-stated org-level fact (Step 4 exception (b)).
- **Single-target runs.** Writing every lesson into the one file the caller named and never auditing the other tiers. Tier every item first (see the scope rule under Input formats). If a rule "must apply every turn," its lazy file trigger says so, `$WORK/CLAUDE.md` itself does not accumulate content.
- **Piling into an existing lazy file when the topic doesn't fit its trigger.** If a rule's natural trigger differs from every existing lazy file's `**Read when:**`, that's the signal to create a new lazy file, not to shoehorn the rule into the closest wrong home. Trigger fit beats file-count minimalism.
- **Saving a repo-specific rule into a shared workspace lazy file.** A rule only true inside one repo (its chart, build, CI, deploy cells, file layout) belongs in that repo's `<repo>/.claude/lazy/<topic>.md` + repo-local `CLAUDE.md` index, NOT in `$WORK/.claude/lazy/*`. Create the repo-local structure when it's absent; that's the correct move, not overhead to avoid. Scope-correctness beats reusing the closest existing shared file.
- **One-and-done when a gap spans multiple triggers.** Adding a rule to one lazy file and stopping, when the rule governs surfaces that load through different triggers (fixtures + docs + CI, etc.). The unaddressed files leave the same mistake reachable. Map every constrained surface to its file and land the rule (full or cross-ref) in each (Step 4).
- **Rules that restate `~/CLAUDE.md`.** Don't re-encode global writing-style or git-safety rules into work-scope files. Point to them by name.
- **Burying the rule in a code example.** The rule must be readable as prose first; the snippet is the illustration.
- **Forgetting the index.** A new lazy file that isn't registered in `$WORK/CLAUDE.md`'s `## Detail files (load on demand)` index won't get loaded on trigger. Always register.

## Worked example

Input: a PR review with 6 comments (1× 404-on-delete, 1× doc comments on HTTP client wrappers, 1× argument helper, 1× SDK helper, 1× error prefix, 1× invalid-argument code).

Audit result:
- 404-on-delete → NOT-COVERED-KEEP (workspace-wide; delete paths repeat across every project). Target: append to `api-clients.md` idempotency section.
- HTTP-client doc comments → NOT-COVERED-KEEP (every project ships an HTTP client package). Target: append to `api-clients.md` client section.
- Argument helper for resource IDs → COVERED-BUT-WRONG (`handlers.md` examples used raw strings). Target: fix examples + add one bullet to Common Mistakes.
- SDK getter helpers → COVERED-BUT-WRONG (`handlers.md` showed raw map access). Same target.
- `<project>:` error prefix → COVERED-BUT-WRONG (`$WORK/CLAUDE.md` had a different prefix). Target: fix the line.
- Invalid-argument code on validation errors → NOT-COVERED-KEEP (every handler validates arguments). Target: append to `handlers.md` + Common Mistakes.

5 edits, no new lazy file. Skill applies all five without asking, then reports.

## Sibling skills

- `claude-md-save` — invoked by Step 6 above to actually write NOT-COVERED-KEEP entries. Owns symlink resolution, target-file decision, section-picking, lazy-index registration, and gitignore. Also usable directly when the operator has a single rule to save ("save this in my claude") and doesn't need the audit pass.
- `claude-md-simplify` — restructure / trim an oversized CLAUDE.md or lazy file. Different problem; this skill ADDS rules and fixes wrong ones, simplify CONSOLIDATES.
- `trigger-improver` — once a lazy file's `**Read when**` clause exists, this skill tunes the wording to fire correctly. Use after `lazy-gaps` creates the entry, if its triggers don't match real queries.
