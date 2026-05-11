---
name: md-preview
description: Render a markdown file in a browser via `mdp` (https://github.com/aldevv/md-preview). Requires `mdp` on `$PATH`. Use in two situations. (1) User explicitly asks to see markdown rendered — triggers on "/md-preview", "/md-preview <path>", "open this in mdp", "open <file> in mdp", "render <file> in markdown", "show me this as rendered markdown", "preview the README", "view the docs in browser", or any equivalent phrasing. (2) Claude has produced substantial markdown content (a doc draft, a runbook, a long report, a summary with multiple sections / tables / code blocks) and a rendered preview would serve the user better than dumping raw markdown into chat — proactively invoke in that case after a quick "I'll open this in mdp" line. Accepts either a path to an existing `.md` file (Mode B) or no arg (Mode A — render content the skill writes from current context). Do NOT trigger for short markdown snippets that read fine in chat (a few lines, a single table, a single short list), for code-only responses, for content the user is iterating on quickly (rendering breaks the feedback loop), or to set up always-on auto-render hooks — this skill stays per-invocation by design. There is no plan-mode coupling; this is general-purpose markdown viewing.
argument-hint: [path]   # optional. Pass an existing `.md` path to render that file directly. Omit to write content from context into a tempfile and render that.
allowed-tools:
  - Bash
  - Read
  - Write
---

# md-preview

Open a markdown file in a browser via `mdp`. Use when the user wants to read markdown rendered, or when you've produced enough markdown that rendering is friendlier than a raw dump.

**User input**: $ARGUMENTS

## Preconditions

Stop and tell the user if any fail:

- `command -v mdp >/dev/null` — `mdp` must be on `$PATH`. Missing? Point at `https://github.com/aldevv/md-preview` (`install.sh` handles `go install` and release tarballs).
- If `$ARGUMENTS` is non-empty: it must be a path to an existing file.

## Files

- `$(mdp skill path)` — bundled reference shipped inside the `mdp` binary. Documents invocation modes, spawn semantics, the tempfile convention, and the security guard rails. Read with `cat "$(mdp skill path)"` for canonical detail.

## Two modes

**Mode A** (no arg) — write content from the current context to a tempfile, then render it.
**Mode B** (path arg) — render the file at `$ARGUMENTS` directly.

## Mode A: render generated content

Use when you've assembled markdown the user should see rendered (a doc draft, a long report, runbook, summary, an approved plan they want to re-view, etc).

1. Decide which markdown to render — the most recent substantial markdown content you've produced or that the user pointed at without giving a file path.
2. Write it verbatim to `/tmp/mdp-claude.md` using the Write tool. Stable path: re-invocations overwrite cleanly so the user can reload the same browser tab. Don't reformat, don't add a title.
3. Spawn `mdp`:
   ```bash
   mdp /tmp/mdp-claude.md
   ```
   `mdp` detaches and returns immediately. Do not background it with `&`.
4. Tell the user it opened in their browser. If the content was a draft awaiting a decision, ask the question explicitly after the render — don't conflate "rendered" with "approved".

## Mode B: render existing file

1. Resolve `$ARGUMENTS` to an absolute path:
   ```bash
   readlink -f "$ARGUMENTS"
   ```
2. Spawn:
   ```bash
   mdp <abs-path>
   ```
3. Done.

## Notes

- The preview is static. To get auto-refresh on edits, the user can run `mdp watch <file>` themselves in another terminal (blocks, so the skill doesn't use it).
- One-shot `mdp <file>` always opens a fresh browser tab. The stable `/tmp/mdp-claude.md` keeps the source tidy but the browser doesn't dedupe windows; users reload the existing tab manually after re-invocation.
- If the user wants every long markdown response to auto-render in `mdp`, that's a hook (via `update-config`), not this skill. This skill stays per-invocation by design.
