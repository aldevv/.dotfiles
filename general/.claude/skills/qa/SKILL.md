---
name: qa
description: Open an editable questions-and-answers / draft-review file in a sibling tmux pane (or a fresh $TERMINAL window when not in tmux) so the operator can edit answers in their own editor, then say "done" to hand the edited file back. The exact file format is defined by the CALLER. This skill only handles writing the temp file, opening it, reusing/appending on repeat, and re-reading it on "done". Triggers on "/qa", "open a q&a pane", "open a q&a file", "open an editable review file", "give me a pane to edit answers", or when another skill needs an editable temp file surfaced in a pane. This is the mechanic that add-comment (and similar draft-review skills) delegate to for the pane/terminal + temp-file plumbing. Precondition: either inside tmux, or $TERMINAL and $EDITOR are set. Do NOT use for posting PR/MR comments (that's add-comment) or for opening a diff-review TUI (that's hunk).
---

# qa

Surface an editable temp file (questions + answers, drafts, anything) in the operator's editor without leaving the current session, then read back their edits.

The **caller owns the format**. This skill does not parse or impose any structure on the file. It handles four mechanical jobs:

1. write the composed content to a temp file,
2. open it in the operator's editor (tmux pane, or a fresh terminal),
3. reuse the same pane and append on a repeat call within the session,
4. re-read the file when the operator says "done" and hand the contents back to the caller.

## Contract

A caller (a skill, or the operator directly) provides:

- **content**: the full text the file should contain. The caller composes it in whatever format it wants: a how-to header + Q/A blocks, YAML-ish bullets, plain prose, anything. qa writes it verbatim.
- **slug**: a short label for the filename (e.g. `add-comment-drafts-pr-14`, `spec-questions`). Lowercase, no spaces.
- **how "done" is interpreted**: the caller re-parses the edited file after "done" and acts on it. qa just returns the bytes.

qa returns: the temp file path, and (on "done") the edited contents.

## Workflow

1. **Pick the file path.** `/tmp/qa-<slug>-<TIMESTAMP>.md`. The `.md` extension gives free syntax highlighting for the common header + `---`-delimited-block shape. If this is a repeat call within the same session for the same logical file (the caller is appending), reuse the existing path instead of minting a new one (glob `/tmp/qa-<slug>-*.md`, pick the newest within the last hour, append the new content to it).

2. **Write the content.** Use the `Write` tool to put the caller's composed content at that path. Do not add or reformat anything. The format is the caller's.

3. **Open it.** Run the helper:

   ```bash
   ~/.claude/skills/qa/scripts/open-qa-pane.sh /tmp/qa-<slug>-<TS>.md
   ```

   - **Inside tmux** it opens next to the caller's pane (`$TMUX_PANE`): a fresh right-hand pane at 70% width by default. When a pane already sits to the caller's right (an `A | B` layout with the caller as A), it stacks qa on top of that right pane B instead, so the caller keeps full height. It uses `$VISUAL`/`$EDITOR` (falling back to `nvim`).
   - **Not in tmux** it opens a fresh `$TERMINAL` window running the editor on the file.
   - On a repeat call for the same file, if the pane is still open it just focuses it (the caller's earlier append already updated the on-disk content, so the editor shows it after a reload). It never opens a second pane for the same file.
   - If not in tmux and `$TERMINAL` is unset, the helper exits 3 and prints a message. Fall back to whatever the caller specifies (for add-comment that's an `AskUserQuestion` with the verbatim bodies).

4. **Tell the operator, in one line:** edit the file, then say "done" (or the caller's chosen keyword like "post") in this pane. Then wait, do not poll the file.

5. **On "done", re-read the file** with `Read` and hand the contents to the caller to parse. The edited file is the source of truth; whatever the operator changed, deleted, or left is what the caller acts on.

6. **Clean up** when the caller is finished with the batch: `rm -f /tmp/qa-<slug>-<TS>.md`.

## Notes

- **Never open the file in a new tmux window.** A pane keeps the caller and the draft on one screen so the operator can edit and answer in place. The helper only ever splits a pane (or, outside tmux, opens a terminal).
- **One file per invocation, many blocks.** When a caller hands qa several items at once, they go in ONE file. When items arrive one at a time in the same session, append to the existing file and reuse the pane (step 1 + step 3 reuse).
- **The helper is format-blind.** It takes a path and opens it. All format decisions (headers, block separators, which field is editable, what "SKIP" means) live in the caller's skill.
- **Advisory to callers: blank-line-separate the fields the operator EDITS so they're paragraph-deletable.** qa does not impose format, but the operator edits in vim/less, so a caller should put a blank line above each field the operator will change or drop, making it its own paragraph (droppable with `dap` instead of hunting line ranges). Display-only fields the operator won't touch can pack together with no blank lines. (add-comment does this: `file`/`kind`/`comment`/`context` grouped, then a blank line before each of `shorter_answer` and `answer`.)

## Callers

- **add-comment** delegates its "Tmux-pane draft mode" plumbing here: it composes the drafts file (its own block format) and calls the helper to surface it, then parses the edited file itself.
- Any future draft/review/questionnaire skill that wants an editable file in a pane should call the helper rather than re-implementing the split logic.
