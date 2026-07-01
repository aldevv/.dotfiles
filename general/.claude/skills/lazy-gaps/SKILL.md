---
name: lazy-gaps
description: Audit a set of PR-review comments / bug findings / lessons against $HOME/work/CLAUDE.md + $HOME/work/.claude/lazy/*.md. For each item, decide COVERED-AND-CORRECT / COVERED-BUT-WRONG-OR-OUTDATED / NOT-COVERED, judge whether the gap is worth a rule, then update an existing lazy file or create a new one. Entries land SHORT and CLEAR. Triggers on "/lazy-gaps", "audit lazy gaps", "are these documented in lazy", "save these review notes as rules", "check if my lazy files cover X". AUTO-INVOKE at the tail of a PR-feedback fix run (after the commit + `/hunk` land) when the operator says "save the rules" or "document these in lazy". Do NOT trigger for skill-body edits (use the relevant skill directly), for connector-specific notes that belong in `CLAUDE.local.md`, or to bulk-rewrite a lazy file (that's `claude-md-simplify`).
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

For each KEEP item (and every COVERED-BUT-WRONG item), pick a target. Preference order:

1. **Update the closest matching lazy file in place** — usually the right choice. Append to the most relevant existing section, or add one short bullet to a "Common Mistakes" / "Gotchas" list.
2. **Add a new top-level section to an existing lazy file** — when the item is a new sub-topic of an existing file (e.g. a new `### 404 on Revoke` section under `golang-connectors.md`'s idempotency block).
3. **Add a tightly-scoped paragraph to `~/work/CLAUDE.md`** — only for portfolio-wide CRITICAL rules that must load on every run.
4. **Create a brand-new lazy file** — last resort. Justification required: the item is broad (5+ connectors will touch it), has a clear `**Read when**` trigger, and no existing file is a natural home. New files MUST be registered in `~/work/CLAUDE.md`'s `## Detail files (load on demand)` index with a precise `**Read when**` clause.

Drafted entry must obey:

- **SHORT.** Aim for 1-3 sentences plus at most one small code snippet. Reviewers read these dozens of times; every word that doesn't change behaviour is a tax.
- **CLEAR.** State the rule as a directive: "use X", "every Y must Z", "never do W". Not "consider", "you might want to", "in some cases". If the rule has exceptions, list them in the same breath.
- **GREP-FRIENDLY.** Name the SDK helper, the vendor field, the annotation type, the gRPC code. Future agents grep for these strings.
- **NO EM-DASHES.** Use commas, periods, parens. (Global writing-style rule.)
- **NO META-NARRATION.** "added because luisina flagged this" belongs in the commit message, not the rule. Rules state what to do, not the history of why we wrote them down.

For COVERED-BUT-WRONG edits, prefer rewriting the wrong line in place rather than appending a new contradicting rule. If the wrong rule has authority (e.g. a documented example shows the anti-pattern), fix the example too.

### 5. Confirm before editing

Show the operator one `AskUserQuestion` with the planned set. The question lists per item:

- `<short rule statement>`
- Verdict: COVERED-AND-CORRECT / COVERED-BUT-WRONG / NOT-COVERED-KEEP / NOT-COVERED-SKIP
- Target file:section (or "new file: ...")
- Verbatim text that will land (for KEEP + WRONG)

Two options:
- **Apply all KEEP + WRONG edits.**
- **Revise** (operator names which items to drop, retarget, or rewrite).

If creating a new lazy file is in the plan, surface the proposed filename + `**Read when**` trigger explicitly and ask for sign-off on those alone (separate question or inline).

### 6. Apply edits

Delegate the actual file modification to the `claude-md-save` skill — one invocation per NOT-COVERED-KEEP item. Do NOT run raw `Edit` calls for new-rule adds. `claude-md-save` owns the shared plumbing: symlink resolution, section-picking, `CLAUDE.local.md` fallback, lazy-index registration in the parent CLAUDE file, `.git/info/exclude` writes, and the work/global/project scope decision. Duplicating any of that here rots the moment `claude-md-save` gains a step.

For each NOT-COVERED-KEEP item, invoke the skill with the distilled rule text. `claude-md-save` re-runs its own target decision; when its choice differs from the target the operator approved in Step 5, surface the divergence in the Step 7 report so the operator can decide whether to move the entry. For the common case (scope=work + a rule that grep-audits into a specific lazy file), both skills land on the same target.

For COVERED-BUT-WRONG items, keep using surgical `Edit` calls. `claude-md-save` is append-only, it does not rewrite an existing line in place, so an outdated rule needs a direct edit anchored on the wrong text.

After every edit (delegated or direct), confirm the file still parses: the lazy-index entry exists if a new file was added, the `**Read when**` trigger is grammatical, no broken markdown fences.

Do NOT commit. The operator owns the commit.

### 7. Report

Print a tight summary:

- N items audited.
- N already-covered (cited file:line).
- N wrong-or-outdated (cited the edit per file).
- N net-new entries (cited the file + section).
- N skipped as not-worth-a-rule (one-line reason each, so the operator can disagree).

End with the `Changes made` block from the auto-new-day pattern: `Verdict: Yes | No` + one-line `Why:`.

## Anti-patterns

- **Padded rules.** "It is generally considered best practice to..." → delete and write "use X."
- **Rule-by-attribution.** "Per luisina's review, ..." → state the rule, not the source.
- **Creating a new lazy file for one bullet.** Append to the closest existing file instead. New files exist when a topic has 5+ rules.
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
