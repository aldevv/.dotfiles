---
name: mdp-plan
description: Render the current Claude plan in a browser via `mdp` (https://github.com/aldevv/md-preview) so the user can review it as proper markdown, then re-call `ExitPlanMode` so the user gets the accept/reject prompt again now that they've seen the rendered version. Requires `mdp` on `$PATH`. Triggers when the user is in plan mode (Claude has just called `ExitPlanMode`) and asks to "open the plan in a markdown window", "open the plan in mdp", "show this plan in markdown", "preview the plan", "render the plan", "see the plan rendered", "/mdp-plan", or any equivalent phrasing signalling they want to review the plan rendered as markdown before deciding. Also accepts `/mdp-plan <path>` to render any markdown file (no plan re-prompt; that mode is just sugar over `mdp <path>`). Do NOT trigger for general "open this file in mdp" or "preview my README" requests with no plan-mode context — call `mdp <file>` directly, this skill is overkill. Do NOT install a hook or set up always-on plan preview — this skill is intentionally per-invocation, the user opts in each time they want it.
argument-hint: [path]   # optional. Omit to render the current Claude plan; pass an existing `.md` path to render that file directly.
allowed-tools:
  - Bash
  - Read
  - Write
---

# mdp-plan

Open the current Claude plan in `mdp` so the user can review it as rendered markdown, then re-call `ExitPlanMode` so they can accept or reject the plan now that they've seen it.

**User input**: $ARGUMENTS

## Preconditions

Check these first. If any fail, stop and tell the user what's missing.

- `command -v mdp >/dev/null` — `mdp` must be on `$PATH`. Missing? Point the user at `https://github.com/aldevv/md-preview` (`install.sh` handles both `go install` and release tarballs).
- If `$ARGUMENTS` is non-empty: it must point to an existing file.

## Files

- `$(mdp skill path)` — bundled reference shipped with the `mdp` binary. Documents invocation modes, spawn semantics, the tempfile convention, and the security guard rails. Read with `cat "$(mdp skill path)"` if you want the canonical detail on driving `mdp`.

## Two modes

**Mode A** (no arg) — render the most recent plan, then re-prompt.
**Mode B** (with path) — render the file at `$ARGUMENTS`, no re-prompt.

## Mode A: plan preview

1. Find the most recent plan content. It's the `plan` field of the most recent `ExitPlanMode` tool call in this conversation. If there isn't one (the user invoked this skill outside plan mode), stop and say: "I haven't presented a plan yet. Enter plan mode first, or pass a path: `/mdp-plan <file>`."
2. Write the plan verbatim to `/tmp/mdp-claude-plan.md` using the Write tool. Stable path: re-invocations overwrite, browser tab reloads cleanly. Don't shell-escape, don't reformat, don't add a title.
3. Spawn `mdp`:
   ```bash
   mdp /tmp/mdp-claude-plan.md
   ```
   `mdp` already detaches and returns immediately. Do not background it with `&`.
4. Tell the user the plan opened in their browser and that you're re-prompting now.
5. Call `ExitPlanMode` again with the exact same `plan` content. The user reviews in the browser, then accepts or rejects in Claude. Don't tweak the plan between renders unless the user asked for an edit.

## Mode B: arbitrary file

1. Resolve `$ARGUMENTS` to an absolute path (`realpath` or `readlink -f`).
2. Spawn:
   ```bash
   mdp <abs-path>
   ```
3. Done. No re-prompt; the user just wanted a render.

## Notes

- The preview is static. If the user edits the plan content in a follow-up turn and re-invokes this skill, the file rewrites and they reload the tab. If they want auto-refresh on edits, they can run `mdp watch /tmp/mdp-claude-plan.md` themselves in another terminal (blocks; not appropriate for the skill to background).
- If the user wants every `ExitPlanMode` to auto-open in `mdp` without asking, that's a PreToolUse hook, not this skill. Tell them they can wire one up via `update-config`; this skill stays per-invocation by design.
- One-shot `mdp <file>` always spawns a fresh browser tab. There's no "is mdp already running on this file" check; re-invocations just open another tab. The stable tempfile path keeps the HTML overwriting cleanly, but the browser doesn't dedupe windows.
