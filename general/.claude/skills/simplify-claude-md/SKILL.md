---
name: simplify-claude-md
description: "Trim and reorganize a CLAUDE.md or CLAUDE.local.md so the upfront read stays lean and on-budget. Use this whenever the user says their CLAUDE file is too long, hard to navigate, or mixes always-relevant rules with one-off reference material — also when they ask to 'simplify', 'trim', 'reorganize', 'split up', 'extract from', or 'clean up' a CLAUDE.md / CLAUDE.local.md / ~/.claude/CLAUDE.md. The skill extracts sections that should only load on a specific trigger (hook reference → loads when a hook fires; Snowflake CLI setup → loads when the user runs `snow`) into `.claude/files/<topic>.md` with a `**Load this when:** <trigger>` line, collapses verbose-but-eager sections into tighter rules, and adds a 'Detail files (load on demand)' index + Table of Contents at the top. Critical behavioral rules stay inline. Strict about triggers: if you can't name a specific trigger that should cause Claude to read a section, it stays inline."
---

Reorganize a CLAUDE.md / CLAUDE.local.md so:
1. **Only eager content** — short rules, directives, safety gates — stays inline.
2. **Lazy reference content** (setup guides, troubleshooting, multi-step flows, long tables) moves to `.claude/files/<topic>.md`, linked from a top-of-file "Detail files" index.
3. **Verbose sections that should stay** get simplified — if a bullet has more words than the rule it encodes, shorten it.
4. A **Table of Contents** at the top lists the remaining sections with one-line descriptions and anchor links.

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

| | Eager (stays in main file) | Lazy (extract to `.claude/files/`) |
|---|---|---|
| Answers | "What must I always do / never do?" | "What do I do *when <specific trigger>*?" |
| Trigger | Applies to every turn, always | Fires only when a specific keyword, tool, error, or workflow is involved |
| Length | Short, imperative | Usually >20 lines with tables/code/steps, but length alone doesn't justify extraction — trigger specificity does |
| Examples | "NEVER push without auth", "Always use CREATE OR ALTER", naming conventions, cross-cutting rules | Auth/MFA flows (trigger: running `snow` or bypassing network policy), hook reference (trigger: a hook fires), troubleshooting guides (trigger: a specific error), multi-step setup procedures (trigger: first-time setup) |
| Reader test | If Claude skipped this at turn start, it could silently violate a rule on a normal request | Claude only needs this when the specific trigger occurs; skipping it at turn start costs nothing |

**When in doubt, keep it eager.** A rule that quietly stops applying causes worse outcomes than a reference file that gets read slightly later. Verbosity alone is NOT a reason to extract — a long section that applies to every turn (e.g. a naming convention with many examples) stays inline and gets *simplified* in Step 4 instead.

Group related lazy sections under one file **only when they share the same trigger** (e.g. "Okta FastPass MFA" + "Snowflake CLI config" + "Auth troubleshooting" all trigger on "user runs `snow` or deals with Snowflake auth" → one `snow.md`). Do not merge sections with different triggers into one file — it breaks the lazy-loading contract.

---

## Step 3 — Propose a plan, get approval

Output (no edits yet):
- **Extractions**: list each section to move, target file name, one-line rationale
- **Simplifications**: list each verbose section to collapse, with a preview of the one-liner
- **Staying put**: name the eager sections (short list, just titles)
- **TOC preview**: list of headings that will end up in the Table of Contents

Ask the user to confirm before writing anything. Accept edits (drop an extraction, keep a section as-is, rename a target file).

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
1. Determine `.claude/files/` location:
   - If the target CLAUDE.md is inside a git repo → `<repo-root>/.claude/files/<topic>.md`
   - Otherwise → `<dir-of-CLAUDE.md>/.claude/files/<topic>.md`
2. **If the target file already exists** (re-running the skill, or a prior extraction put something there): read it, show the user the existing content, and ask whether to (a) merge new sections into it under a new heading, (b) replace it, or (c) pick a different filename. Do not overwrite silently.
3. Create (or update) the file. **The first two lines after the `# <Title>` must be a trigger block** so Claude knows when to load it:
   ```markdown
   # <Topic>

   **Load this when:** <specific trigger in one line — the same trigger you identified in Step 2>.
   **Referenced from:** `<source-file>.md`
   ```
   Examples of good trigger lines:
   - `**Load this when:** a hook fires or blocks, or when running a Quavo replication/recreation skill.`
   - `**Load this when:** the user runs the \`snow\` CLI, hits a Snowflake auth error, or asks about Okta FastPass / network-policy bypass.`
   Bad trigger lines (too vague — reject and tighten):
   - `**Load this when:** needed.`
   - `**Load this when:** working with Snowflake.` (too broad — every turn could "work with Snowflake")
4. Preserve the original section's content verbatim inside the extracted file. Don't reformat, don't rewrite — move it as-is so readers comparing the two see a 1:1 correspondence.
5. If multiple sections merge into one file (only when they share the same trigger), use `---` separators and keep each section's original heading.

---

## Step 6 — Update the main file

Replace extracted sections with nothing (delete them — the link index at the top covers discoverability). Do not leave stub sections pointing at the extracted file; the TOC already does that.

---

## Step 7 — Add / update the Table of Contents

Place the TOC immediately after the `# <Title>` line, before any existing content. Format:

```markdown
## Detail files (load on demand)
Extracted reference content lives in `.claude/files/`. Each entry names the trigger that should cause you to read it — do not load these proactively.

- [<topic>](.claude/files/<topic>.md) — **read when:** <specific trigger, e.g. "a hook fires or blocks, or when running a Quavo replication skill">
- [<topic2>](.claude/files/<topic2>.md) — **read when:** <specific trigger>

## Table of contents
- [Section Heading 1](#section-heading-1) — one-line description
- [Section Heading 2](#section-heading-2) — one-line description
- ...
```

Rules:
- **Detail files** come first (they're the lazy-load contract), then **Table of contents** for the eager content.
- **Every Detail-files entry must name its trigger** using a `**read when:** <trigger>` clause. This mirrors the `**Load this when:**` line inside the extracted file — the two must agree. A reference without a trigger is a bug.
- Anchor links use lowercase, spaces→hyphens, drop punctuation — match how GitHub/most markdown renderers generate anchors.
- TOC one-line descriptions: what the section is *for*, not a restatement of its title.
- If the file already had a "Quick map" or similar index, replace it with the TOC — don't leave both.

---

## Step 8 — Update any "save in my claude" (or equivalent) guidance

If the main file has a rule that tells Claude where to save user-added content (common names: "Save in my claude", "Save in my CLAUDE.md", "When saving preferences"), update it to include the newly-created `.claude/files/*.md` files as valid save targets. After extraction, the rule needs to say: pick the best location — either the main file (for cross-cutting rules that apply every turn) or one of the `.claude/files/*.md` files (for content matching that file's `**Load this when:**` trigger).

**Template to merge in**:
> When the user says "save in my claude" (or equivalent), pick the best location: the main `<CLAUDE*.md>` file for cross-cutting rules/directives, OR one of the `.claude/files/*.md` files when the content matches that file's `**Load this when:**` trigger (e.g. hook behavior → `.claude/files/hooks.md`; Snowflake CLI details → `.claude/files/snow.md`). Trigger specificity wins: if the saved content would only be read when a specific thing happens, put it in the matching `.claude/files/*.md`.

Rules:
- **Don't invent this rule** if the file doesn't already have one — this skill doesn't add new behavioral directives on its own. Just update what's there.
- **If the file's existing rule lists specific CLAUDE*.md candidates** (e.g. "check `$HOME/work/` for CLAUDE-*.md files"), keep those and add `.claude/files/*.md` alongside them. The user's existing discovery logic still matters.
- **Mention trigger specificity** as the tie-breaker — it's the whole point of the split.

---

## Step 9 — Locally ignore `.claude/files/`

If the CLAUDE.md being processed is inside a git repo, always locally ignore `.claude/files/` — regardless of whether the source file itself is tracked or gitignored. Extracted detail files are personal, lazy-loaded reference material and should not be surfaced as untracked noise.

1. Check whether `.claude/files/` is already ignored: `git check-ignore -v .claude/files/<any-file-just-created>.md`.
2. If not ignored, append `.claude/files/` to `.git/info/exclude`. **Never modify `.gitignore`** — that file is committed and shared with the team, so adding a personal ignore rule there would leak into the repo.
3. Skip entirely if the CLAUDE.md target is not inside a git repo.
4. Run `git status` at the end to confirm the new files don't show up as untracked.

---

## Step 10 — Report

Summarize:
- Files created under `.claude/files/`
- Sections extracted (count)
- Sections simplified (count, with line-delta)
- Main file before/after line count
- Whether `.git/info/exclude` was updated
- Anything the user declined to extract that's still verbose (flag it for a future pass)

---

## Guardrails

- **Never commit, stage, or push.** This skill creates and edits files only. Version control is the user's call.
- **Never delete content** without the user's explicit OK during Step 3. Extraction moves; simplification compresses; nothing disappears silently.
- **Preserve heading hierarchy** on extraction. If the original had `## Foo` → `### Bar`, the extracted file keeps that shape.
- **If the file is already well-organized** (short, mostly eager, has a usable TOC), say so and stop. Don't invent work.
- **Err on the side of keeping content inline.** A rule that silently stops applying is worse than a reference file loaded slightly later. If you can't state the trigger in one concrete sentence, the content isn't lazy — it's eager, and it stays.
