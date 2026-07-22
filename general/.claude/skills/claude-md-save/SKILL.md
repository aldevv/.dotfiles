---
name: claude-md-save
description: "Save a rule, preference, or directive into the right CLAUDE.md / CLAUDE.local.md / .claude/lazy/*.md file. Triggers on 'save in my claude', 'save this in claude', 'add this to my claude', 'save this rule', 'remember this in my CLAUDE.md', 'save this so we don't repeat this mistake', or any phrasing expressing intent to persist a rule. CRITICAL: fires even when the save phrase is BUNDLED with other actions (e.g. 'fix X, and save this in my claude'). Presence ANYWHERE in the message activates the skill. Never inline-edit a CLAUDE file directly. Do NOT trigger for reading/auditing CLAUDE files (use `claude-md-simplify` for restructuring, `claude-md-management:revise-claude-md` for rewrites), or for the global `~/.claude/CLAUDE.md` unless the user says 'global claude'. 'save in my claude' means CLAUDE files only, NEVER auto-memory (disabled)."
---

Save a user-stated rule or preference into the correct CLAUDE file for the current project, choosing the most specific and appropriate target file automatically.

## Decision order (where to save)

1. **Existing `.claude/lazy/<topic>.md`** — if the entry's topic matches the `**Load this when:**` / `**Read when:**` trigger of an existing lazy file. Most specific target: the rule only loads when relevant.
2. **New `.claude/lazy/<topic>.md`** — if the user explicitly asks for a new file, OR if the skill judges a new file is warranted (see "When to create a new lazy file" below). When created, the file must also be registered in the parent CLAUDE file's lazy-load index.
3. **`CLAUDE.local.md`** — if the file exists in the current directory. Local files are gitignored by convention, so project-personal rules belong here.
4. **`CLAUDE.md`** — if `CLAUDE.local.md` doesn't exist, and `CLAUDE.md` is either not tracked by git, or the user explicitly names it. If `CLAUDE.md` is git-tracked and there's no local alternative, create `CLAUDE.local.md` and save there instead.

Never save to `~/.claude/CLAUDE.md` (global) unless the user says "global claude" or "my global claude".

### Scope disambiguation (when the user doesn't specify)

"Save in my claude" without a qualifier is ambiguous. Resolve scope before choosing a target file. The decisive question is **not** "is this principle reusable?" but **"where was the agent working when this lesson surfaced?"** A reusable principle still belongs in the project CLAUDE.md when the lesson came up while editing that project's files — that's where future agents will need it.

**Check work scope first** (see "Work claude scope" below): if the content references your employer's infrastructure, credentials, tooling, or repos (the work cloud-auth/SSO flow, the work identity provider, work MFA secrets, a work-only product or service name, the work issue tracker, or anything under `$WORK` / `~/work`), it is work-scoped no matter which directory you are in. Work wins over both project and global, so resolve it before applying the project/global leanings below.

**Identify the working-context project, not just cwd.** The user's cwd may differ from where the edits happened (e.g. they ran `nvim` from `~/work` but the files being edited live under `~/.config/nvim/`). Build a candidate-project list:

1. From cwd, walk ancestors looking for the first `CLAUDE.md` (project root).
2. From the last 10–20 file paths the agent has Read/Edited/Written this session, walk each path's ancestors looking for a `CLAUDE.md`.
3. The "working-context project" is the CLAUDE.md most frequently matched by step 2 (or the cwd one if step 2 is empty). If two projects tie, pick the one whose files were edited most recently.

**Lean toward project (the working-context project)** when any of these hold:
- The user says "in this project", "for this repo", or similar.
- The content names project-specific symbols, paths, conventions, or tools that only make sense inside that project.
- **The rule was learned while editing files in that project — even if the principle is reusable elsewhere.** A nvim-specific lesson learned while editing `~/.config/nvim/*` belongs in `~/.config/nvim/CLAUDE.md`, not global, because that's where the next agent editing nvim config will read context from. The "reusability" of a principle is not by itself a reason to prefer global.
- The project's CLAUDE.md has a natural section for the rule (existing or new) — concrete homes beat abstract ones.

**Lean toward global** only when ALL of these hold:
- The working-context project is **none** (no CLAUDE.md in cwd or recently-edited-file ancestors), OR the working-context project is itself the global dotfiles tree (`~/.dotfiles/general/`).
- The content is universal, not editor/tool/language-specific (e.g. "always write a test before a fix" is universal; "check nvim runtime ftplugins before customizing" is editor-specific).
- A matching global lazy file already exists for the topic AND no equally-specific project home exists.

When leaning project, prefer the working-context project's CLAUDE.md (or its `.claude/lazy/`) over global. Run the project scan (Commands A-C in Step 2) against THAT project's path, not just cwd.

**Heuristic check (worked examples):**
- "Check nvim runtime before writing custom keybinds" while editing `~/.config/nvim/*` → `~/.config/nvim/CLAUDE.md` (nvim-specific home). NOT global, even though the principle generalizes.
- "Always git-rebase before merging" while in any repo → global (`~/.dotfiles/general/.claude/rules/git.md` or `lazy/code/code.md`); applies everywhere.
- "Use json.Number for all baton API IDs" → work scope (`$WORK/CLAUDE.md`).
- "Add type hints to every function in this repo" while in `~/projects/foo/` → `~/projects/foo/CLAUDE.md`.

When leaning global, run the global lazy scan (Command D in Step 2) alongside the project scan to find an existing match before deciding. If a global lazy file matches the topic, that is the target — not a new project file. **But still confirm the working-context project doesn't have a better home first.**

### Work claude scope

Work-related rules belong in the work CLAUDE tree, never in the project repo you happen to be sitting in, never global, never a machine-local notes file. Detect work scope from the **content**, not the cwd. A rule is work-scoped when it references your employer's infrastructure, credentials, systems, or repos rather than a personal project. Any one signal is enough:

- Work auth or credentials: the work cloud-provider login/SSO flow, the work identity/SSO provider, work MFA or OTP secrets, work-only service accounts or roles.
- Work paths: anything under `$WORK` / `~/work`, including `~/work/.envrc`.
- Work systems: a product, service, repo, internal tool, issue tracker, or wiki that exists only inside your employer, not in a personal project.
- Anything the work-boundary rule in `~/CLAUDE.md` protects.

When work scope is detected, all paths shift:

| What | Path |
|------|------|
| CLAUDE file | `$WORK/CLAUDE.md` |
| Lazy dir | `$WORK/.claude/lazy/` |
| Code-topic lazy files | `$WORK/.claude/lazy/code/<topic>.md` |
| Helper scripts the rule needs | `$WORK/.claude/scripts/` |

**Precedence**: work detection wins over project and global. If the content is work-scoped, save to `$WORK/CLAUDE.md` (or a `$WORK/.claude/lazy/` file) even when the user is in an unrelated repo and just says "save in my claude". Resolve the lazy-load index inside `$WORK/CLAUDE.md` exactly as you would for project or global scope.

**Helper scripts**: when a work rule references a script (an auth flow, a deploy helper), the script lives under `$WORK/.claude/scripts/`, never under `~/.claude/scripts/` or the project. Point the saved rule at that path.

**Skip Step 6c and Step 8** (the project `.git/info/exclude` steps): the `$WORK/.claude/` tree manages its own versioning.

### Global claude scope

When the user says "global claude" or "my global claude", all paths shift:

| What | Path |
|------|------|
| CLAUDE file | `~/.dotfiles/general/CLAUDE.md` |
| Lazy dir | `~/.dotfiles/general/.claude/lazy/` |
| Code-topic lazy files | `~/.dotfiles/general/.claude/lazy/code/<topic>.md` |

**`code/` subdirectory rule**: any lazy file whose topic is a code practice (style, quality, comments, design, debugging, naming, testing, architecture) goes under `code/<topic>.md`, not directly under `lazy/<topic>.md`. Check the existing `code/` dir (`code.md`, `design.md`, `debugging.md`) — new code-practice files join that group. Quality + naming + comments + shell rules already live together in `code.md`; only spin up a new file if the topic is genuinely separate (a new debugging-style narrow concern, not just a sub-section of style).

**Skip Step 5c** (gitignore) for global — the dotfiles repo versions everything in `~/.dotfiles/general/`.

**Skip Step 7** (CLAUDE.local.md gitignore) — not applicable at global scope.

### When to create a new lazy file

Create a new `.claude/lazy/<topic>.md` only when **all** of the following hold:

- A concrete, specific trigger can be named (not "when coding" — something like "editing any `.go` file" or "running `docker` commands").
- The topic is clearly distinct from every existing lazy file (no partial-match alternative).
- Either the user explicitly asks for a new file, **or** the content is substantial enough (multiple related rules, a reference table, a multi-step procedure) that inlining it would bloat the parent file.

Default to the parent CLAUDE file when in doubt. One rule never justifies its own file. A universal rule (applies every turn) belongs inline, not lazy.

---

## Step 1 — Extract what the user wants to save

Before running any file commands, re-read the user's message and identify:

- **The rule or directive** — the exact behavior to encode. Be precise: "always use feature/ prefix for branch names" not "branch naming".
- **Scope** — explicit ("global claude" → global, "this project's claude" → project) or ambiguous ("save in my claude"). For ambiguous cases, apply the "Scope disambiguation" rules above and note which signals you found.
- **Topic tags** — one or two words that describe the domain: `git`, `branches`, `comments`, `testing`, `style`, `auth`, `deployment`, `hooks`, etc.

If the user's phrasing is ambiguous (e.g. "save what we just agreed on"), re-read the 3–5 most recent turns to identify the concrete decision. Do not ask the user to repeat it.

---

## Step 2 — Survey the project

If the content is work-scoped (see "Work claude scope"), set:
```
root=$WORK
lazy_dir=$WORK/.claude/lazy
claude_file=$WORK/CLAUDE.md
```
Else if the user said "global claude" or "my global claude", set:
```
root=~/.dotfiles/general
lazy_dir=~/.dotfiles/general/.claude/lazy
claude_file=~/.dotfiles/general/CLAUDE.md
```
Otherwise set `root=$(pwd)`, `lazy_dir=$root/.claude/lazy`, and find the CLAUDE file per the decision order.

Run these commands in parallel (substituting the resolved paths above). When scope is ambiguous, also run Command D:

**Command A** — find candidate CLAUDE files (project scope only; skip for global):
```bash
cwd=$(pwd)
echo "=== CLAUDE files ==="
[ -f "$cwd/CLAUDE.local.md" ] && echo "CLAUDE.local.md: exists" || echo "CLAUDE.local.md: absent"
[ -f "$cwd/CLAUDE.md" ]       && echo "CLAUDE.md: exists"       || echo "CLAUDE.md: absent"
if [ -f "$cwd/CLAUDE.md" ]; then
  git -C "$cwd" ls-files --error-unmatch CLAUDE.md 2>/dev/null && echo "CLAUDE.md: git-tracked" || echo "CLAUDE.md: not git-tracked"
fi
```

**Command B** — list existing lazy files with their triggers:
```bash
lazy_dir="${LAZY_DIR:-$(pwd)/.claude/lazy}"
if [ -d "$lazy_dir" ]; then
  find "$lazy_dir" -name "*.md" | sort | while IFS= read -r f; do
    rel="${f#$lazy_dir/}"
    trigger=$(grep -m1 -E '^\*\*(Load|Read) this when\*\*|\*\*(Load|Read) when\*\*' "$f" 2>/dev/null | head -1 | sed 's/^\*\*[^*]*\*\*[: ]*//')
    echo "$rel | ${trigger:-<no trigger line found>}"
  done
else
  echo "no lazy/ directory"
fi
```

**Command C** — read the lazy-load index from the CLAUDE file:
```bash
claude_file="${CLAUDE_FILE:-$(pwd)/CLAUDE.md}"
[ -f "$claude_file" ] || claude_file="$(pwd)/CLAUDE.local.md"
echo "=== $(basename $claude_file) lazy section ==="
awk '/^## (Detail files|Lazy load)/,/^## [^#]/' "$claude_file" 2>/dev/null | head -60
```

**Command D** — global lazy files (run when scope is ambiguous):
```bash
global_lazy=~/.dotfiles/general/.claude/lazy
if [ -d "$global_lazy" ]; then
  find "$global_lazy" -name "*.md" | sort | while IFS= read -r f; do
    rel="${f#$global_lazy/}"
    trigger=$(grep -m1 -E '^\*\*(Load|Read) this when\*\*|\*\*(Load|Read) when\*\*' "$f" 2>/dev/null | head -1 | sed 's/^\*\*[^*]*\*\*[: ]*//')
    echo "$rel | ${trigger:-<no trigger line found>}"
  done
else
  echo "no global lazy/ directory"
fi
```

---

## Step 3 — Match topic to a target file

Using the topic tags from Step 1 and the lazy-file lists from Step 2:

1. **If scope is ambiguous**, apply the disambiguation signals from Step 1. If leaning global, scan Command D results first — a matching global lazy file wins over any project target.

2. **Scan existing triggers** (project or global, per resolved scope): a match is confident when 2+ keywords from the topic appear in the trigger, or when the trigger clearly names the domain.

3. **Consider a new lazy file** if no existing file matches. Apply the "When to create a new lazy file" criteria from the top of this skill. If all conditions hold, plan to create `.claude/lazy/<topic>.md` (derive `<topic>` as a short lowercase slug, e.g. `git`, `docker`, `testing`). Otherwise fall back to the parent CLAUDE file.

4. **Pick the final target** following the decision order at the top (adjusted for resolved scope):
   - Existing global lazy file match (when leaning global) → that file.
   - Existing project lazy file match → that file.
   - New lazy file warranted → `.claude/lazy/<topic>.md` (new, in resolved scope).
   - `CLAUDE.local.md` exists → that file.
   - `CLAUDE.md` not git-tracked → that file.
   - Else → create `CLAUDE.local.md`.

5. **Pick a section** inside the target file. The bar for reusing an existing section is high: the heading must name the same concept as the rule, not just a related one. Ask: would a reader scanning headings expect to find this rule under that heading? If no, create a new `## <Topic>` section. Examples of a bad reuse: a "squash before merging" rule under `## Commits` (commits and merging are adjacent but different), a "logger utility" rule under `## Code style` (too broad). When in doubt, new section.

State the resolved scope (project/global and why), the chosen target, whether it's new or existing, and the section before continuing.

---

## Step 4 — Distill the content

Lazy files store ideas and behaviors for future agents, not session transcripts. Before writing:

- **Smallest entry that stays clear and cohesive.** Fewest words that fully convey the rule. After drafting, cut every sentence that doesn't add information a future agent needs to act on. One-sentence rule, one sentence; don't pad with rationale, examples, or edge cases the user didn't ask for.
- **Bullets when they help, not by default.** Bullets fit lists of distinct items, alternatives, or steps. A single thought is a sentence, not a one-bullet list. Two short sentences usually beat two bullets. Decide per entry.
- **Generic, not project-specific.** No project names, file paths, symbol names, or codebase details. The entry must make sense to an agent on a different repo.
- **No code blocks unless the pattern needs one.** Smallest example that makes it concrete, a few lines at most.
- **Extract the idea, not the example.** Write the behavior the session illustrated. A 3-5 line example may follow as illustration, never as the main content.
- **Final pass:** "Can I cut another sentence without losing meaning?" If yes, cut it.

## Step 5 — Read the target file

**Resolve symlinks first.** The Edit tool refuses to write through symlinks. Before reading or editing any target file, resolve its real path:

```bash
resolved=$(readlink -f "$target_file")
```

Use `$resolved` for all subsequent Read and Edit calls (not the original path). If `readlink -f` returns the same path, no symlink was involved — proceed normally.

Read the full target file (at the resolved path) before editing. If it doesn't exist yet (new lazy file or new CLAUDE.local.md), skip this step.

---

## Step 6 — Create a new lazy file (only if Step 3 decided one is needed)

Skip this step if the target is an existing file.

**6a — Determine the file path.**

- **Global scope, code-practice topic** (style, quality, comments, design, debugging, naming, testing, architecture): place at `~/.dotfiles/general/.claude/lazy/code/<topic>.md`.
- **Global scope, other topic**: place at `~/.dotfiles/general/.claude/lazy/<topic>.md`.
- **Project scope**: place at `.claude/lazy/<topic>.md` relative to `$cwd`.

Then create the file. Do NOT add a `**Load this when:**` or `**Referenced from:**` header inside the file: the trigger lives in the parent CLAUDE index (Step 6b), and repeating it in the file just makes it longer. Match the existing lazy files, which open straight into content:

```markdown
# <Topic Title>

## <Section heading matching the entry's domain>

<entry>
```

The trigger goes in the index entry (Step 6b), and must satisfy the "good triggers" criteria: tied to file paths, commands, syntax, or explicit user phrases. State it in one concrete sentence (or a short bullet list if multiple distinct signals).

**6b — Register the file in the parent CLAUDE file's lazy-load index.**

Find the primary CLAUDE file (prefer `CLAUDE.local.md` if it exists, else `CLAUDE.md`). Locate the "Lazy load", "Detail files", or equivalent index section. Add an entry for the new file using the format already present in that section. If the section uses the `**Read when**` bullet format, match it exactly:

```markdown
- [`.claude/lazy/<topic>.md`](.claude/lazy/<topic>.md). **Read when:** <same trigger as the file header>.
  Covers <one-line content summary>.
```

If the parent file has no lazy-load index section yet, add one before the Table of Contents (or before the first `##` section if there is no ToC):

```markdown
## Lazy load

- [`.claude/lazy/<topic>.md`](.claude/lazy/<topic>.md). **Read when:** <trigger>.
  Covers <one-line content summary>.
```

**6c — Git-ignore the new lazy file** if inside a project git repo.

Skip entirely for global scope (`~/.dotfiles/general/`) — the dotfiles repo versions that directory intentionally.

For project scope:
```bash
cwd=$(pwd)
if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
  exclude="$(git -C "$cwd" rev-parse --git-dir)/info/exclude"
  grep -qF '.claude/lazy/' "$exclude" 2>/dev/null || echo '.claude/lazy/' >> "$exclude"
  echo "added .claude/lazy/ to .git/info/exclude"
fi
```

Skip if `.claude/lazy/` is already gitignored.

---

## Step 7 — Write the entry (existing target files)

Skip this step if Step 6 already wrote the entry into a newly created lazy file.

Format the entry using the distilled content from Step 4:

- **Bullet points.** Always. Match the style of surrounding content; don't introduce prose blocks into a bullet-list section.
- **Imperative tone**: "Always X", "Never Y", "Use Z when W".
- **No justification**: don't explain why it was saved or reference the session.
- **One blank line** before and after when inserting into an existing section.
- **New section**: add a new `## <Topic>` section (2–4 word heading) at the bottom of the file when no existing section is a direct match. Don't force an entry into an adjacent topic.

If the target file doesn't exist yet (new `CLAUDE.local.md`), create it with:
```markdown
# Project notes

## <Topic>

<entry>
```

---

## Step 8 — Locally ignore CLAUDE.local.md if newly created

If this run created a new `CLAUDE.local.md` inside a git repo, add it to `.git/info/exclude`:

```bash
cwd=$(pwd)
if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
  exclude="$(git -C "$cwd" rev-parse --git-dir)/info/exclude"
  grep -qxF 'CLAUDE.local.md' "$exclude" 2>/dev/null || echo 'CLAUDE.local.md' >> "$exclude"
  echo "added CLAUDE.local.md to .git/info/exclude"
fi
```

Skip if the file already existed, is already gitignored, or there is no git repo.

---

## Step 9 — Report

One short paragraph:
- Target file chosen and why (existing lazy match / new lazy file / local file / CLAUDE.md / created new).
- Section used or created.
- If a new lazy file was created: the trigger line chosen and the index entry added to the parent CLAUDE file.
- The exact text that was saved (quoted).

Nothing else.

---

## Guardrails

- **Never write to memory files.** "Save in my claude" targets CLAUDE files only (CLAUDE.md, CLAUDE.local.md, .claude/lazy/*.md). Never write to auto-memory files (memory/ directories, .claude/projects/*/memory/, or any file that serves the auto-memory system). The user has auto-memory disabled.
- **Never overwrite content** — only append to or insert into sections. Never truncate a file.
- **New lazy files are opt-in, not default.** Default to the parent CLAUDE file unless the "When to create a new lazy file" bar is met. A single rule never justifies its own file.
- **Never commit, stage, or push.** File edits only.
- **Never write to `~/.claude/CLAUDE.md`** unless the user explicitly says "global".
- **Work-scoped content goes to `$WORK`, nowhere else.** Never save a work rule (see "Work claude scope") into the project repo you happen to be in, into global, or into a machine-local notes file. Helper scripts a work rule references live in `$WORK/.claude/scripts/`, not `~/.claude/scripts/`.
- If two lazy files partially match the topic, prefer the more specific trigger. If still tied, prefer the parent CLAUDE file over creating a third.
- If the user includes a CRITICAL label ("this is critical", "make it a critical rule"), prefix the entry with `**CRITICAL:**` in the file.
- If a new lazy file is created, the index registration in Step 5b is mandatory — a lazy file with no pointer from the parent is invisible to agents loading context.
