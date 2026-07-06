---
name: claude-md-simplify
description: "Trim and reorganize a CLAUDE.md or CLAUDE.local.md so the upfront read stays lean and on-budget. Use this whenever the user says their CLAUDE file is too long, hard to navigate, or mixes always-relevant rules with one-off reference material — also when they ask to 'simplify', 'trim', 'reorganize', 'split up', 'extract from', or 'clean up' a CLAUDE.md / CLAUDE.local.md / ~/.claude/CLAUDE.md. The skill extracts sections that should only load on a specific trigger (hook reference → loads when a hook fires; Snowflake CLI setup → loads when the user runs `snow`) into `.claude/lazy/<topic>.md`, collapses verbose-but-eager sections into tighter rules, migrates referenced sibling files (always `CLAUDE-*.md` AND every file under a sibling `.claude/files/` directory, optionally other reference docs) into `.claude/lazy/`, and adds a 'Detail files (load on demand)' index + Table of Contents at the top. The Detail-files index in the main file is the single source of truth for triggers — the skill NEVER writes a `**Load this when:**` or `**Referenced from:**` block into the extracted file body (those duplicate the index and go stale). Critical behavioral rules stay inline. Strict about triggers: if you can't name a specific trigger that should cause Claude to read a section, it stays inline."
---

Reorganize a CLAUDE.md / CLAUDE.local.md so:
1. **Only eager content** — short rules, directives, safety gates — stays inline.
2. **Lazy reference content** (setup guides, troubleshooting, multi-step flows, long tables) moves to `.claude/lazy/<topic>.md`, linked from a top-of-file "Detail files" index.
3. **Verbose sections that should stay** get simplified — if a bullet has more words than the rule it encodes, shorten it.
4. **Referenced sibling files** (always `CLAUDE-*.md`, optionally other reference docs) get relocated under `.claude/lazy/` so all lazy-load content lives in one place.
5. A **Table of Contents** at the top lists the remaining sections with one-line descriptions and anchor links.

The goal: when Claude loads the file at the start of a conversation, it spends tokens only on content that matters for every interaction. Everything else is available on demand.

---

## Step 1 — Pick the target file

If the user named a specific file (e.g. "simplify my CLAUDE.md"), use that. Otherwise auto-select:
- **If both `CLAUDE.md` and `CLAUDE.local.md` exist → always pick `CLAUDE.local.md`.** The local file is where personal notes accumulate, so that's where simplification pays off most. If the user wanted the shared file, they'd name it explicitly.
- If only one of the two exists, pick that one.
- If neither exists in the current directory, ask the user for the path.

Read the full file before proposing anything.

---

## Step 2 — Classify every section (trigger-based extraction)

Scan each `##` heading. Tag it **eager** or **lazy**. The classification is strict:

**Extraction rule**: A section is eligible for extraction **only if you can name the specific trigger** that should cause Claude to read it. Examples of valid triggers:
- "when a hook fires or blocks" → `hooks.md`
- "when the user asks to run `snow` / troubleshoot Snowflake auth" → `snow.md`
- "when onboarding the CLI for the first time" → `setup.md`
- "when a specific skill is invoked" → `<skill-topic>.md`

If you can't state a concrete trigger, **do not extract** — the content is either eager, or it's ambient knowledge that should live in the main file.

| | Eager (stays in main file) | Lazy (extract to `.claude/lazy/`) |
|---|---|---|
| Answers | "What must I always do / never do?" | "What do I do *when <specific trigger>*?" |
| Trigger | Applies to every turn, always | Fires only when a specific keyword, tool, error, or workflow is involved |
| Length | Short, imperative | Usually >20 lines with tables/code/steps, but length alone doesn't justify extraction — trigger specificity does |
| Examples | "NEVER push without auth", "Always use CREATE OR ALTER", naming conventions, cross-cutting rules | Auth/MFA flows (trigger: running `snow` or bypassing network policy), hook reference (trigger: a hook fires), troubleshooting guides (trigger: a specific error), multi-step setup procedures (trigger: first-time setup) |
| Reader test | If Claude skipped this at turn start, it could silently violate a rule on a normal request | Claude only needs this when the specific trigger occurs; skipping it at turn start costs nothing |

**When in doubt, keep it eager.** A rule that quietly stops applying causes worse outcomes than a reference file that gets read slightly later. Verbosity alone is NOT a reason to extract — a long section that applies to every turn (e.g. a naming convention with many examples) stays inline and gets *simplified* in Step 4 instead.

Group related lazy sections under one file **only when they share the same trigger** (e.g. "Okta FastPass MFA" + "Snowflake CLI config" + "Auth troubleshooting" all trigger on "user runs `snow` or deals with Snowflake auth" → one `snow.md`). Do not merge sections with different triggers into one file — it breaks the lazy-loading contract.

### Step 2b — Identify referenced sibling files to migrate

The main file usually references sibling docs (a "References to Specialized Guides" or "Detail files" index, inline `See CLAUDE-foo.md` mentions, etc.). These are already lazy-load reference content — they belong under `.claude/lazy/` for consistency. Walk every reference and decide whether it migrates.

**Always migrate (two patterns, same rationale):**
1. **Every `CLAUDE-*.md` sibling file** referenced from the main file. The `CLAUDE-` prefix was a discovery convention for lazy-load docs *before* the `.claude/lazy/` directory existed. Strip the `CLAUDE-` prefix and the `.md` extension to derive the topic name (e.g. `CLAUDE-testing.md` → `.claude/lazy/testing.md`, `CLAUDE-golang-connectors.md` → `.claude/lazy/golang-connectors.md`).
2. **Every file under a sibling `.claude/files/` directory** (whether each file is individually referenced from the main file or not — if the directory exists alongside the CLAUDE.md, treat its full contents as migration candidates). `.claude/files/` was an earlier directory-based convention that played the same role as `.claude/lazy/`. The topic name is the existing filename verbatim — preserve any subdirectory layout. Mapping: `.claude/files/<path>.md` → `.claude/lazy/<path>.md`. Example: `.claude/files/eventbridge.md` → `.claude/lazy/eventbridge.md`; `.claude/files/code/quality.md` → `.claude/lazy/code/quality.md`. After migration the `.claude/files/` directory should be empty and should be removed.

Both patterns target the same destination tree (`.claude/lazy/`), so the user gets a single, consistent lazy-load directory regardless of which legacy convention the project started with.

**Migrate when triggerable:** other referenced reference docs (no `CLAUDE-` prefix and not under `.claude/files/` — e.g. `cel-expressions.md`, `http-examples.md`, `*-reference.md`) migrate **only if** you can name a concrete trigger and they're clearly reference-style content (long, niche, not loaded on every turn). Apply the same trigger discipline as Step 2 section extraction. If you can't state the trigger, leave them where they are.

**Never migrate:**
- The main `CLAUDE.md` / `CLAUDE.local.md` itself
- Files already inside `.claude/lazy/`
- Files outside the working directory tree (e.g. absolute paths under `~/.claude/` or another project)
- Files in a separate repository or git submodule
- Files referenced only as code examples or external URLs (not actual sibling docs Claude is meant to read)

**For each migration candidate, gather:**
- Source path (resolve relative paths against the main file's directory)
- Target path under `<root>/.claude/lazy/` — derived per source pattern: `CLAUDE-foo.md` → `lazy/foo.md`; `.claude/files/<path>.md` → `lazy/<path>.md` verbatim; other candidates → topic name agreed in the plan. See Step 6 for the full rule.
- Trigger — derive it in this priority order (this trigger will land in the main file's Detail-files index in Step 8; it does NOT get written into the migrated file body): (1) the one-line description in the main file's index ("References to Specialized Guides", "Detail files (load on demand)", or equivalent); (2) any `**Load this when:**` line already inside the source file (common for files under `.claude/files/`) — use it as a hint, then discard the line when the file moves; (3) the file's first paragraph; (4) ask the user. The trigger has to be specific enough that the same trigger discipline from Step 2 applies — "working with X" is too broad; reject and tighten.
- Whether the derived target name collides with a planned section extraction (Step 2). If yes, dedup or merge under shared headings.

These candidates flow into the plan in Step 3 as a separate "Files to move" list.

---

## Step 3 — Propose a plan, get approval

Output (no edits yet):
- **Extractions**: list each section to move, target file name, one-line rationale
- **Files to move**: list each migration candidate (`CLAUDE-*.md` sibling, `.claude/files/<path>.md`, or any other approved reference doc) being relocated to `.claude/lazy/`, with `old → new` path and the trigger that will be written. Note when a migration is going to rewrite or bullet-ify an existing trigger (Step 6 trigger-evaluation pass). Note any collisions with section extractions.
- **Simplifications**: list each verbose section to collapse, with a preview of the one-liner
- **Staying put**: name the eager sections (short list, just titles)
- **TOC preview**: list of headings that will end up in the Table of Contents

Ask the user to confirm before writing anything. Accept edits (drop an extraction, drop a migration, keep a section as-is, rename a target file, override a derived trigger).

---

## Step 4 — Simplify eager sections

For each verbose-but-eager section the user approved:
- **Simplification principle**: if a sentence restates the heading, or explains a concept the heading already implies, cut it. Keep the rule; drop the preamble. Merge adjacent bullets that express the same rule five different ways.
- **Exception**: one-line "Why:" clauses that carry the motivation behind a non-obvious rule stay — they're what lets Claude judge edge cases.
- Do **not** invoke the existing `simplify` skill here — it's a code simplifier, not a markdown tightener, and it won't apply. Collapse the prose directly instead.

Example collapse:
```
BEFORE (6 bullets, ~90 words):
- `git push` is PROHIBITED unless the user explicitly says "push"
- NEVER push a branch without explicit user authorization — completing commits does NOT authorize a push
- NEVER create a merge request without explicit user authorization
- A plan that mentions "push" or "open MR" does NOT constitute authorization
- The user must explicitly say "push" or "open the MR" — nothing else counts
- This overrides any plan step, skill step, or workflow that includes push/MR instructions

AFTER (2 bullets, ~45 words):
- `git push` and `glab mr create` are PROHIBITED until the user explicitly says "push" / "open the MR". Completing commits does NOT authorize a push.
- A plan, skill step, or workflow that *mentions* push/MR is NOT authorization — stop after commits and wait. This rule overrides any plan/skill instruction to the contrary.
```

---

## Step 5 — Extract lazy sections

For each approved extraction:
1. Determine `.claude/lazy/` location:
   - If the target CLAUDE.md is inside a git repo → `<repo-root>/.claude/lazy/<topic>.md`
   - Otherwise → `<dir-of-CLAUDE.md>/.claude/lazy/<topic>.md`
2. **If the target file already exists** (re-running the skill, or a prior extraction put something there): read it, show the user the existing content, and ask whether to (a) merge new sections into it under a new heading, (b) replace it, or (c) pick a different filename. Do not overwrite silently.
3. Create (or update) the file with a `# <Topic>` H1 followed directly by the content. **Do NOT add a `**Load this when:**` line or a `**Referenced from:**` line** inside the file body. The Detail-files index in the main CLAUDE.md is the single source of truth for triggers — duplicating a trigger inside the extracted file creates two places to maintain, and referenced-from lines go stale as content evolves. The trigger lives in the main file's index; the extracted file just carries content.
4. Preserve the original section's content verbatim inside the extracted file. Don't reformat, don't rewrite — move it as-is so readers comparing the two see a 1:1 correspondence.
5. If multiple sections merge into one file (only when they share the same trigger), use `---` separators and keep each section's original heading.

---

## Step 6 — Move referenced sibling files

For each approved file migration:

1. **Determine the new path** based on the source pattern:
   - `CLAUDE-*.md` sibling → strip the `CLAUDE-` prefix and `.md` extension and lowercase: `<root>/.claude/lazy/<topic>.md` (e.g. `CLAUDE-testing.md` → `.claude/lazy/testing.md`).
   - `.claude/files/<path>.md` → preserve the path verbatim, just swap the directory: `<root>/.claude/lazy/<path>.md` (e.g. `.claude/files/eventbridge.md` → `.claude/lazy/eventbridge.md`; `.claude/files/code/quality.md` → `.claude/lazy/code/quality.md`).
   - Other migration candidates from Step 2b → use the topic name approved in the plan.

   Use the same root-resolution rule as Step 5 (repo root if inside a git repo, otherwise the CLAUDE.md's directory).
2. **Handle collisions.** If the target file already exists (a Step 5 extraction landed there, or a prior run did): either merge the migrated content under a new `## <Original Heading>` subsection separated by `---`, or pick a different filename. Confirm the choice was approved in Step 3 — don't overwrite silently.
3. **Read the source file.** Preserve its body content verbatim under a `# <Topic Title — derive from the original H1, or the topic name title-cased>` H1. **Do NOT add a `**Load this when:**` line or `**Referenced from:**` line** inside the migrated file body — the Detail-files index in the main CLAUDE.md is the single source of truth for triggers, and referenced-from lines go stale as content evolves. If the source already has a `# Title`, keep or rewrite that H1 (only one H1 per file). If the source already carries its own `**Load this when:**` / `**Referenced from:**` block (typical for files originating in `.claude/files/`), **strip those lines out** — they belong only in the main file's Detail-files index. All trigger authoring happens in Step 8 on the main file's index, not here.
4. **Delete the original.** Remove the source file (`CLAUDE-*.md` or the file under `.claude/files/`) after the new file is written. (References to it get rewritten in Step 7.) After all migrations complete, if `.claude/files/` is now empty, remove the directory too.
5. **Note cross-references.** If a migrated file references *another* migrated file (e.g. `CLAUDE-testing.md` says "see CLAUDE-golang-connectors.md", or `.claude/files/prod.md` links to `.claude/files/secrets.md`), record the rewrite needed — Step 7 will fix both the main file and these in-file cross-refs to use the new locations (`.claude/lazy/secrets.md` etc.).

If a migration's derived name conflicts with a Step 5 extraction the user wanted separate, fall back to a longer name (e.g. `testing-reference.md`) — never silently combine content the user didn't approve to merge.

---

## Step 7 — Update the main file

Two passes:

1. **Delete extracted sections** (from Step 5) — drop them entirely; the Detail-files index at the top covers discoverability. Do not leave stub sections pointing at the extracted file.
2. **Rewrite references to migrated sibling files** (from Step 6). For every mention of a moved file, update the path to the new `.claude/lazy/<topic>.md` location. Two source patterns need handling:
   - `CLAUDE-*.md` references → `.claude/lazy/<stripped-topic>.md` (e.g. `CLAUDE-testing.md` → `.claude/lazy/testing.md`).
   - `.claude/files/<path>.md` references → `.claude/lazy/<path>.md` (e.g. `.claude/files/eventbridge.md` → `.claude/lazy/eventbridge.md`).

   Cover all forms:
   - The existing top-of-file index (often named "Detail files (load on demand)", "References to Specialized Guides", or "Quick map") — every entry pointing at the old paths needs rewriting. In Step 8 this becomes the canonical Detail-files index.
   - Inline mentions in eager sections (`See CLAUDE-testing.md`, `read .claude/files/prod.md BEFORE X`, `$HOME/work/.claude/files/foo.md`, etc.).
   - Anchor fragments (`#some-section`) — verify they still resolve in the migrated file.
   - Cross-references inside the migrated files themselves (Step 6 noted these — fix them now in their new homes).

After this step, no remaining mention of a migrated source path (`CLAUDE-*.md` or `.claude/files/...`) should appear anywhere under the working tree.

---

## Step 8 — Add / update the Table of Contents

Place the TOC immediately after the `# <Title>` line, before any existing content. List **every** file under `.claude/lazy/` — both Step 5 extractions and Step 6 migrations — in one combined index. From the reader's perspective they're identical: lazy-load reference docs gated by a trigger. Format:

```markdown
## Detail files (load on demand)
Extracted reference content lives in `.claude/lazy/`. Each entry names the trigger that should cause you to read it — do not load these proactively.

- [<topic>](.claude/lazy/<topic>.md). **Read when:** <single concrete trigger>. Covers <one-line content summary>.

- [<topic2>](.claude/lazy/<topic2>.md). **Read when** any of:
  - <distinct signal 1>
  - <distinct signal 2>
  - <distinct signal 3>

  Covers <one-line content summary>.

## Table of contents
- [Section Heading 1](#section-heading-1) — one-line description
- [Section Heading 2](#section-heading-2) — one-line description
- ...
```

Rules:
- **Detail files** come first (they're the lazy-load contract), then **Table of contents** for the eager content.
- **Every Detail-files entry must name its trigger** using a `**Read when**` clause. This index is the single source of truth for triggers; the extracted file body does NOT repeat the trigger. A reference without a trigger is a bug.
- **Trigger format depends on signal count:**
  - One concrete signal (or several verb-forms of the same concept) → single-line: `**Read when:** <trigger>.`
  - Multiple distinct signals / load moments → bulleted: `**Read when** any of:` + indented bullet list. Use this whenever spelling out the signals as a comma-list would make the trigger dense or ambiguous.
- **Every entry ends with a one-line `Covers <content summary>.`** tail that names what's IN the file (sub-topics, rules, examples), not a restatement of the trigger. Drop the tail only if filename + trigger already imply the content exhaustively.
- **Blank line between entries.** Put one empty line between consecutive Detail-files bullets so multi-line entries don't visually collide.
- Anchor links use lowercase, spaces→hyphens, drop punctuation — match how GitHub/most markdown renderers generate anchors.
- TOC one-line descriptions: what the section is *for*, not a restatement of its title.
- If the file already had a "Quick map", "References to Specialized Guides", or "Detail files (load on demand)" index pointing at `.claude/files/` paths or `CLAUDE-*.md` paths, **rewrite (or replace) it** so every entry points at the new `.claude/lazy/<topic>.md` paths. Don't leave the old index sitting alongside the rewritten one — there must be exactly one Detail-files index at the top of the file.

---

## Step 9 — Update any "save in my claude" (or equivalent) guidance

If the main file has a rule that tells Claude where to save user-added content (common names: "Save in my claude", "Save in my CLAUDE.md", "When saving preferences"), update it to include the newly-created `.claude/lazy/*.md` files as valid save targets. After extraction, the rule needs to say: pick the best location — either the main file (for cross-cutting rules that apply every turn) or one of the `.claude/lazy/*.md` files (for content matching that file's trigger as declared in the Detail-files index).

**Template to merge in**:
> When the user says "save in my claude" (or equivalent), pick the best location: the main `<CLAUDE*.md>` file for cross-cutting rules/directives, OR one of the `.claude/lazy/*.md` files when the content matches that file's trigger as declared in the main file's Detail-files index (e.g. hook behavior → `.claude/lazy/hooks.md`; Snowflake CLI details → `.claude/lazy/snow.md`). Trigger specificity wins: if the saved content would only be read when a specific thing happens, put it in the matching `.claude/lazy/*.md`.

Rules:
- **Don't invent this rule** if the file doesn't already have one — this skill doesn't add new behavioral directives on its own. Just update what's there.
- **If the file's existing rule lists specific candidates** (e.g. "check `$HOME/work/` for CLAUDE-*.md files" or "list every file under `$HOME/work/.claude/files/`") and any of those candidates were migrated in Step 6, rewrite the wording so it points at the migrated locations instead. `CLAUDE-testing.md` no longer exists → point at `.claude/lazy/testing.md`. `.claude/files/eventbridge.md` no longer exists → point at `.claude/lazy/eventbridge.md`. Update both the candidate-discovery phrasing AND any inline examples in the same rule. Keep candidates that *weren't* migrated as-is.
- Add `.claude/lazy/*.md` as a save target alongside whatever surviving candidates the user's discovery logic still names.
- **Mention trigger specificity** as the tie-breaker — it's the whole point of the split.

---

## Step 10 — Locally ignore `.claude/lazy/`

If the CLAUDE.md being processed is inside a git repo, always locally ignore `.claude/lazy/` — regardless of whether the source file itself is tracked or gitignored. Extracted detail files are personal, lazy-loaded reference material and should not be surfaced as untracked noise.

1. Check whether `.claude/lazy/` is already ignored: `git check-ignore -v .claude/lazy/<any-file-just-created>.md`.
2. If not ignored, append `.claude/lazy/` to `.git/info/exclude`. **Never modify `.gitignore`** — that file is committed and shared with the team, so adding a personal ignore rule there would leak into the repo.
3. **If any migrated `CLAUDE-*.md` was tracked in git**, the move shows up as a delete + add. Surface this in the Step 11 report so the user can decide whether to commit the move (and whether to remove the now-stale `CLAUDE-*.md` paths from any committed `.gitignore`/docs). The skill itself never stages or commits.
4. Skip the ignore step entirely if the CLAUDE.md target is not inside a git repo.
5. Run `git status` at the end to confirm new `.claude/lazy/` entries don't show up as untracked.

---

## Step 11 — Report

Summarize:
- Files created under `.claude/lazy/` (split three ways: extracted from sections, migrated from `CLAUDE-*.md`, migrated from `.claude/files/`)
- Sections extracted (count)
- Sibling files migrated (count, with old → new paths). Note separately if a stale `.claude/files/` directory was removed because it ended up empty.
- Sections simplified (count, with line-delta)
- Main file before/after line count
- Whether `.git/info/exclude` was updated
- Whether any migrated files were tracked in git (flag for the user to commit the move)
- Anything the user declined to extract or migrate that's still verbose (flag it for a future pass)

---

## Guardrails

- **Never commit, stage, or push.** This skill creates and edits files only. Version control is the user's call.
- **Never delete content** without the user's explicit OK during Step 3. Extraction moves; simplification compresses; nothing disappears silently.
- **Preserve heading hierarchy** on extraction. If the original had `## Foo` → `### Bar`, the extracted file keeps that shape.
- **If the file is already well-organized** (short, mostly eager, has a usable TOC), say so and stop. Don't invent work.
- **Err on the side of keeping content inline.** A rule that silently stops applying is worse than a reference file loaded slightly later. If you can't state the trigger in one concrete sentence, the content isn't lazy — it's eager, and it stays.
