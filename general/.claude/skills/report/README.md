# report

Open the [Hunk](https://github.com/modem-dev/hunk) TUI as a tmux pane next to Claude, with review notes for a diff already attached. Use it to read a branch, PR, or commit interactively instead of scrolling a wall of review prose. Needs tmux and the `hunk` CLI.

## Use it

Type `/report`, or ask to "open hunk" / "review with hunk" / "show changes in hunk". Optional target argument:

- `/report` — current branch vs its upstream default
- `/report HEAD~1` — last commit
- `/report --pr 30` (or `pr 30`, or a bare `30`) — a specific PR
- `/report main..feature` — an explicit range

Claude reads the diff, decides what is genuinely non-obvious, attaches notes in Hunk, and jumps you to the first one. If nothing needs a note, it still leaves one `Feature Explanation:` note at the top so you have a starting point.

## Flow

```
Round 1  discover ──► Round 2  open + read ──► Round 3  apply ──► Round 4  (once) hook prompt
   │                     │                        │
 range, repo root,    git diff  +  split a      attach notes:
 default branch,      hunk pane (70%) off       orientation, per-reviewer,
 PR meta, feedback    Claude's pane, poll       complex-flow. validate every
 payload              until the session is up   anchor lands on a real +/- line
```

Fast path: when a caller (like `pr-code-review`) hands over a ready-made comment batch, Rounds 2 and 3 collapse into one, every supplied comment lands (no filtering on the hunk side).

## Who does what

| Concern | Owner |
|---------|-------|
| Resolve the range, read the diff, decide what to flag | **report** |
| Split the tmux pane, poll until the session is live | **report** |
| `hunk session ...` semantics (apply, navigate, reload) | **hunk CLI** (`$(hunk skill path)` is the source of truth) |
| Pre-supplied comment batch (what to include) | **the caller** (e.g. `pr-code-review`) |
| Note voice, what counts as worth a note | `references/review-guidance.md` + `references/examples.md` |

## Notes

- Only splits a pane, never a new window. Break it out yourself with `<prefix> !` if you want it standalone.
- Every note anchors to a real changed line (`newLine` / `oldLine`), never a bare hunk position. A validator rejects the batch if an anchor misses.
- This skill is also the home of the shared review output-format references that other review skills follow.
- Not for: PR-review prose with no TUI (use `code-review`), posting to an existing thread (use `add-comment`), or when you are not inside tmux.
