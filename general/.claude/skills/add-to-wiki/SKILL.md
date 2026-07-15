---
name: add-to-wiki
description: Save a note, recipe, or how-to into the personal wiki under $WIKI (typically ~/.local/share/wiki). Decides the right path inside the existing folder topology, appends to an existing markdown file when there's a natural fit, creates a new file when there isn't, and respects the wiki's markdown conventions (# top-level heading, ## subheadings, fenced code blocks, backticks for inline code). Triggers on "/add-to-wiki", "add to my wiki", "add this to the wiki", "save in my wiki", "save this in my wiki", "save this in the wiki", "note this in my wiki", "wiki this", "put this in the wiki", "remember this in my wiki <path/subject>", or any explicit ask to persist a note in the personal wiki tree. Do NOT trigger for CLAUDE.md saves (use `claude-md-save`), for project docs that belong inside a repo, for ephemeral memory, or for `~/notes/` (this skill targets $WIKI specifically). On contested triggers, "save in my claude" wins for CLAUDE.md and "save in my wiki" wins for the wiki — read the user's phrasing literally.
argument-hint: [path/inside/wiki.md] | [section <heading>]
---

# add-to-wiki

Persist a note in the personal wiki the user has stowed under `$WIKI`. The wiki is markdown, hand-curated, and organized by topic-folders. This skill respects the existing topology instead of inventing parallel structure.

## When to run

Explicit user trigger only:
- `/add-to-wiki` (with or without an explicit path argument)
- "add this to my wiki"
- "save in my wiki"
- "wiki this"
- "save this in the wiki under <X>"

Do NOT trigger for:
- "save in my claude" / "save in CLAUDE.md" → use `claude-md-save`.
- Project docs (READMEs, CLAUDE.md inside repos) → edit the project directly.
- `~/notes/` and ad-hoc note dirs that aren't the wiki — this skill is scoped to `$WIKI`.
- Auto-memory (`~/.claude/projects/*/memory/`) — disabled by user policy.

## Step 1. Resolve the wiki root

```bash
WIKI="${WIKI:-$HOME/.local/share/wiki}"
[ -d "$WIKI" ] || { echo "ERROR: \$WIKI=$WIKI does not exist" >&2; exit 1; }
```

If `$WIKI` is unset and the fallback path doesn't exist, stop with a one-line error. Never silently create `~/.local/share/wiki/` — that's the operator's call. Note: `$WIKI` is often a symlink (stow), so use `find -L` (or pass the resolved path) when searching the tree, otherwise `find` returns 0 hits.

## Step 2. Pick the destination

Order of precedence:

1. **User-provided path.** If the trigger phrase contains a path like `notes/ai/claude/automation.md` or the operator answered an earlier question with one, honor it verbatim. Resolve it under `$WIKI`. Create any missing parent dirs (`mkdir -p`).
2. **Existing file match by topic.** Search the wiki tree for files whose name or H1 (`# Topic`) matches the topic the operator handed you. Use `rg --type md -l '<topic-substring>'` and `find -L $WIKI -iname '<topic>*.md'`. If exactly one obvious hit exists, propose that file and a heading inside it.
3. **Existing folder match by topic.** If no file matches but a folder does (e.g. user is saving a Claude automation note and `$WIKI/notes/ai/claude/` already exists), propose `<that folder>/<topic-slug>.md`.
4. **Walk the topology to find a good parent.** Inspect the wiki layout (`find -L $WIKI -maxdepth 3 -type d`) and pick the closest semantic match. Common parents on this user's wiki: `notes/technologies/programs/`, `notes/technologies/devops/`, `notes/ai/<vendor>/`, `notes/life/`, `notes/work/`, `personal/`, `cheatsheets/<topic>/`, `projects/`. Tools → `notes/technologies/programs/<tool>.md`. AI tooling → `notes/ai/<vendor>/<topic>.md`. Concept notes → existing topic file.
5. **Ask before inventing a new top-level folder.** If steps 1-4 don't fire and the only option is a brand-new top-level category, ask the operator with the candidate path AND the closest existing alternative.

Before any write, print: `dest: <absolute path>  (mode: append|create)`. Operator can interrupt and redirect.

## Step 3. Build the content

Markdown conventions on this wiki (verified against neighbor notes — `notes/technologies/programs/bash.md`, `git.md`, `copilot.md`):

- New file starts with `# <Topic>` as the H1 on line 1. Don't add front-matter or other directives unless a neighbor file in the chosen folder uses them.
- Sections are `## Heading`. Subheadings nest `###`, `####`, etc. Reserve `#` for the file's single H1.
- **Multi-line code, configs, command examples → fenced code blocks with a language tag:**

  ```bash
  echo hello
  ```

  Never use `#+BEGIN_SRC ... #+END_SRC` (legacy org-mode; the wiki has been migrated). Always pick a sensible language tag (`bash`, `python`, `go`, `yaml`, `ini`, `json`, `text`, ...).
- **Inline code, paths, command names, flags → markdown backticks (`` `cmd` ``).** The neighbor notes also accept bare text without any markup when the line is clearly a command or path; pick backticks when the surrounding prose makes the inline token ambiguous, bare text otherwise. **Do NOT use `=verbatim=` or `~code~`** — those are legacy org-mode markers and the wiki no longer uses them.
- Tables use markdown pipe syntax with a `|---|---|` separator row:

  ```
  | col1 | col2 |
  |------|------|
  | a    | b    |
  ```

- Inline links: bare URLs on their own line are fine (the neighbor notes just drop `https://...` above the related prose). Use `[label](path.md)` for wiki-internal cross-references (relative paths from the file's own directory).
- Plain words, no emojis, no AI-slop vocabulary (`leverage`, `seamless`, `streamline`, etc. — see `~/.dotfiles/general/.claude/rules/writing-style.md`).

Before writing, peek at one or two neighbor `.md` files in the chosen folder and match their density / cadence. Some folders favor very terse note-style entries; others use full prose. Match what's already there.

If the operator gave you content, use it verbatim (lightly reformatted into markdown). If they gave you a topic and asked you to write it, draft the note in their voice: terse, plain words, no fluff.

## Step 4. Append vs create

- **Create** when the file doesn't exist. Write the `# <Topic>` H1, blank line, then a `## Section` with the content under it.
- **Append** when the file exists. Decide between:
  - **New top-level section** (`## New section`) if the content is a distinct topic. Add a blank line above.
  - **New subsection under an existing heading** (`### Subsection under Heading`) if the operator named a parent.
  - **Inline addition** to an existing section if the content extends a paragraph or list already there.

Default to "new top-level section" unless the operator's phrasing maps to an existing heading. Append-only: never reorder, reflow, or rewrite existing content. Other authors' lines are not yours to police.

## Step 5. Update the wiki index (optional)

If the wiki has a top-level index file (`$WIKI/notes/wiki.md` or similar) AND you just created a NEW file at a top-level or new folder, propose adding a link to the index:

```md
- [Claude automation](ai/claude/automation.md)
```

Don't auto-edit the index. Show the line you'd add and ask the operator to drop it in themselves (the index is typically hand-curated and prone to ordering preferences).

## Step 6. Confirm and stop

After writing, print:

```
wrote <N> lines to <path>
preview:
  <first 3 lines + last 2 lines>
```

Do NOT open the file in an editor automatically. Don't `git add` or commit in `$WIKI` — the wiki has its own sync rhythm (per the user's `sync-dotfiles` skill if the wiki is stowed, or `personal-push-all` for the broader sweep).

## Edge cases

- **Wiki is a git submodule or has unsaved changes.** Don't touch git state. The user runs their own sync.
- **The topic is huge.** If the operator pastes thousands of lines, ask whether to drop a fenced code block or split across sections.
- **The file would shadow an existing one with a different name (e.g. `claude.md` vs `claude-code.md`).** Surface the conflict and ask.
- **Operator hands you a URL.** Quote the URL verbatim under an `## External` heading; don't fetch it. The wiki is for the operator's notes, not auto-imported web content.
- **Operator says "wiki" but means GitLab/Confluence/Notion.** Disambiguate before writing — `add-to-wiki` is filesystem-scoped to `$WIKI`.
- **You see `.org` files in the tree.** The wiki was migrated from org-mode to markdown. If any `.org` files are left, they were missed by the migration — flag them to the operator instead of writing more `.org`.

## Sibling skills

- `claude-md-save` — saves a rule into CLAUDE.md / CLAUDE.local.md / `.claude/lazy/*.md`. Wins when the user says "save in my claude" or talks about a rule for future sessions.
- `Notion:create-page` — for the operator's Notion workspace, not the filesystem wiki.
- `sync-dotfiles` / `sync-dotfiles-full` — push the wiki + dotfiles upstream. Suggest running it after a batch of wiki edits if the user asks "did this save?" or "is this synced?".
