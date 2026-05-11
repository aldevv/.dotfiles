---
name: hunk
description: Analyze a diff, compose review notes that explain complex flows or difficult paths, then open a Hunk session in a new tmux window with the notes already attached. Use when the user types `/hunk`, `/hunk-review`, asks to "open hunk", "review with hunk", "show changes in hunk", or wants to review a PR/branch/commit interactively.
argument-hint: [target]   # e.g. "main...feature", "HEAD~1", "origin/master..HEAD", "--pr 581", omit for current-branch vs upstream default
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - AskUserQuestion
---

# Hunk

Open the Hunk TUI and attach review notes for any complex flows or
difficult paths in the diff. Default to applying nothing: comments are
reserved for things a careful reader would still find non-obvious.

**User input**: $ARGUMENTS

## Parallelism rules

Fire as much as possible in parallel. The workflow is structured as three
rounds, where everything within a round goes in a single message with
parallel tool calls. Inter-round work is serial only because later rounds
need earlier rounds' outputs (range, pane count, diff text).

The rounds:

1. **Discovery** (parallel): bundled skill, repo root, default branch, pane count, hook-prompt state, (if PR arg) `gh pr view`.
2. **Open + read** (parallel): full diff, open Hunk in tmux, verify session.
3. **Apply** (sequential within the round): `comment apply` then `navigate`. These race if parallel.

## Round 1 — Discovery (everything parallel)

Fire ALL of these in a single message:

- `cat "$(hunk skill path)"` (bundled session-control reference, the source of truth for `hunk session ...` semantics)
- `git rev-parse --show-toplevel`
- `git symbolic-ref --short refs/remotes/origin/HEAD` (faster than `git remote show origin`; the default branch is `${out#origin/}`)
- `tmux display-message -p '#{window_panes}'` (drives split-vs-new-window in Round 2)
- `test -f "$HOME/.cache/hunk/state.json" && cat "$HOME/.cache/hunk/state.json" || echo MISSING` (Round 4 prompt state)
- If `$ARGUMENTS` looks like a PR number (`--pr N` / `pr N` / bare `N`): also fire `gh pr view <N> --json baseRefName,headRefName,headRepository`

If `$TMUX` is unset (you're not inside tmux), tell the user to run Hunk in a tmux session first and stop. `tmux display-message` in Round 1 will fail loudly if there's no server.

Resolve `<RANGE>` from `$ARGUMENTS`:

| `$ARGUMENTS` | `<RANGE>` |
|---|---|
| empty | `origin/<default>...HEAD` |
| `HEAD~1`, `main..feature`, `origin/master..HEAD`, etc. | pass through verbatim |
| `--pr N` / `pr N` / numeric `N` | `origin/<base>...<head>` from `gh pr view` |
| (working-tree review, no commits) | no range; use `hunk diff` / `git diff` with no args |
| (staged review) | `hunk diff --staged` / `git diff --staged` |

## Round 2 — Open Hunk + read diff (parallel)

Once `<RANGE>` is known, single message with these in parallel:

- `git diff --no-color <RANGE>` (full diff for you to read; serves double duty as the emptiness check, no separate `--stat` call needed)
- Open Hunk in tmux. Pick from Round 1's pane count:
  - 1 pane → `tmux split-window -h "cd <REPO_ROOT> && hunk diff <RANGE>"`
  - >1 panes → `tmux new-window -t "$(tmux display-message -p '#{session_name}')" -n "hunk-$(basename <REPO_ROOT>)-$(git -C <REPO_ROOT> rev-parse --abbrev-ref HEAD)" "cd <REPO_ROOT> && hunk diff <RANGE>"`
  - If the user said "open in a new window" even with one pane, skip the conditional and go straight to `new-window`.
- `sleep 2 && hunk session list` (gives Hunk time to register, then confirms the session is live)

Both `split-window` and `new-window` auto-switch focus to the new pane/window.

If the diff returns empty, tell the user and stop. The Hunk window will be empty too; either close it (`tmux kill-pane -t <pane>`) or leave it for the user.

## Round 3 — Apply (or skip)

Read the diff. Decide whether it contains complex flows or difficult paths (see "Comment scope"). Then:

**If real comments to apply** — fire these two SEQUENTIALLY (do not parallelize: navigate races apply and may find nothing):

```bash
cat <<'JSON' | hunk session comment apply --repo <REPO_ROOT> --stdin
{
  "comments": [
    {"filePath": "path/to/file.go", "hunkNumber": 1, "summary": "...", "rationale": "..."}
  ]
}
JSON
```

```bash
hunk session navigate --repo <REPO_ROOT> --next-comment
```

Map files → 1-based hunk indices from the `@@ -X,Y +A,B @@` headers in the diff text. If `comment apply` rejects on a path/hunk mismatch, fall back to `hunk session review --repo <REPO_ROOT> --json` to confirm structure (the JSON shape is `.review.files[].path` and `.review.files[].hunks[]`), then retry.

**If nothing worth commenting on** — clear any `[pending]` placeholder (the pre-PR/MR hook drops one; `/hunk` usually doesn't) and stop:

```bash
hunk session comment list --repo <REPO_ROOT> --json | \
  jq -r '.comments[] | select(.summary | startswith("[pending]")) | .commentId' | \
  while read -r cid; do hunk session comment rm "" "$cid" --repo <REPO_ROOT>; done
```

The empty positional is required: `hunk session comment rm` takes `[sessionId]` then `<commentId>` as positionals; `--repo` replaces session lookup but leaves the first slot needing an empty string.

Tell the user the diff was straightforward and no review comments were warranted.

## Round 4 — One-time hook-install prompt

You already loaded `$HOME/.cache/hunk/state.json` in Round 1.

- File exists → skip this step entirely (already asked once).
- File missing → ask once via AskUserQuestion:

  Question: "Install a PreToolUse hook that auto-runs `hunk` right before any `gh pr create` or `glab mr create`? Hunk opens in a new tmux window and the parent Claude session fills it with review comments for any complex flows in the diff (or clears the placeholder if there's nothing complex)."

  Options:
  1. **Yes, install it** — write the hook script + register in settings.json
  2. **No, skip** — record the decision so we don't ask again
  3. **Ask me later** — do NOT write state; re-asks next run

On **Yes**, fire these two in parallel:

```bash
mkdir -p "$HOME/.claude/hooks" && \
  ln -sf "$HOME/.claude/skills/hunk/hunk-pre-pr.sh" \
         "$HOME/.claude/hooks/hunk-pre-pr.sh"
```

```bash
mkdir -p "$HOME/.cache/hunk" && \
  printf '{"hookInstalled": true, "promptedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$HOME/.cache/hunk/state.json"
```

Then read `$HOME/.claude/settings.json` and add **two** `PreToolUse` entries under `hooks` matching `Bash(gh pr create:*)` and `Bash(glab mr create:*)`, both calling the same script. If a matcher entry for `Bash` already exists, append to its `hooks` array instead of duplicating the matcher object.

On **No**:
```bash
mkdir -p "$HOME/.cache/hunk" && \
  printf '{"hookDeclined": true, "promptedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$HOME/.cache/hunk/state.json"
```

On **Ask me later**: do not write state.

## Comment scope — only complex flows and difficult paths

**The bar is high.** Default to applying nothing.

Apply when:

- **Complex flows** — fan-out/await, retry loops with subtle conditions, async patterns, recursion, non-obvious state transitions. One brief shape-of-the-flow note at the entry point ("this fans out N tasks then awaits all, retrying any that return WouldBlock"). Never per-step narration.
- **Difficult paths** — a non-obvious invariant the reader has to hold in their head, a subtle ordering requirement, a workaround for a specific bug or platform quirk, a control-flow edge that's easy to misread.

Do NOT comment on:

- Behavioral changes obvious from the diff itself (return-shape changes, new branches a careful reader will catch).
- Cross-file invariants, rollout footguns, test gaps, env-var changes. Those belong in the PR description, not in Hunk.
- Pure renames, signature widening, comment-only changes, generated files.
- Anything a careful read of the function makes obvious.

## Tone — short, informal, plain words

When you do apply a comment:

- **Match length to complexity.** A simple observation gets a one-line rationale. A genuinely complex flow can get two or three sentences. Don't pad simple things with caveats, restatements, or background. If the rationale repeats the summary in longer words, cut the rationale.
- **Plain words.** Write like you'd tell a colleague over chat. Lowercase, contractions, fragments are fine. Skip "moreover", "thus", "ensure that", "deliberately maintains", "asymmetric invariant", "subsequently", "in order to".
- `summary` is a chat-line headline (~80 chars, no period). `rationale` is the "why" in one or two sentences. Don't restate the summary.

### Be unambiguous about who you're talking to

A Hunk note is read by the reviewer (and possibly the PR author). It's NOT a code comment, NOT a TODO for future-you, and NOT an instruction the reviewer can act on. So avoid bare imperatives like "don't unify these" or "remember to X" — the reviewer can't tell whether you're telling them, the PR author, or some hypothetical future maintainer, and they can't act on any of those.

Instead:

- **Explain what the code is doing and why** (informational — the most common case). Phrase as "this works like X because Y", or open with "intentional:" / "heads-up:" if the thing might look like a bug at first glance.
- **Flag something the PR author should change** (actionable). Phrase as "this should be X" or "would [the PR author] mind doing Y here". Say it's a suggestion if it's a suggestion.
- If you find yourself writing an imperative aimed at no one in particular, it's a code comment, not a review note. Drop it.

### Don't narrate the act of reviewing

Write the observation, not a description of the act of writing it. Cut:

- "flagging this so…"
- "noting that…"
- "calling this out because…"
- "just FYI…"
- "for the reviewer's awareness…"

The comment **is** the flag/note/call-out — saying "I am flagging this" is the same kind of noise as "I am writing this paragraph". A reviewer doesn't need to be told that the comment exists; they're reading it.

If you need a one-word signal that a note is informational and needs no action, the compact options are `intentional:`, `heads-up:`, or just letting the explanation speak for itself.

Direct consequence: if you write a note describing a deliberate-looking-weird thing, end with the *consequence of getting it wrong* rather than meta-talk. "unifying these would break X" is better than "flagging so future-me doesn't unify these."

### Worked example

The diff: an install function checks `paths.mdp_bin()` (in-tree only) while the runtime resolver `paths.resolve_mdp()` accepts in-tree OR `$PATH`. The asymmetry is deliberate.

Bad (formal, jargon, redundant):
> "Install check is in-tree-only; runtime resolve falls back to $PATH. Keep them asymmetric."
> "M.run() short-circuits on paths.mdp_bin() (not mdp_available()) on purpose: :MdPreviewInstall must always produce the self-contained..."

Bad-but-better (informal, but ambiguous — who is "don't unify" aimed at?):
> "install always grabs the in-tree copy; runtime takes whatever's around. don't unify these with `mdp_available()`."

Still bad (meta-narration — "flagging" describes the act of commenting):
> rationale ends with: "flagging so it doesn't look like a bug worth unifying later."

Still too long (correct content, but padded for a simple observation):
> summary: "intentional: install short-circuits on in-tree only, runtime resolver takes in-tree OR $PATH"
> rationale: "the check here is `paths.mdp_bin()`, not `paths.mdp_available()`. if install also short-circuited on a global `mdp`, `:MdPreviewInstall` would silently do nothing for anyone who'd already `go install`'d the binary, so they'd never get the self-contained in-tree copy. `resolve_mdp()` at runtime accepts either, so those users still work without re-installing. unifying the two checks would break the install step for them."

Good (chat-line, length matches complexity):
> summary: "intentional: install checks in-tree only, runtime takes either"
> rationale: "if install short-circuited on global `mdp` too, users with a pre-existing `go install` would never get the in-tree copy. `resolve_mdp()` still handles them at runtime."

## Hook script

The shipped script lives next to this `SKILL.md` at `hunk-pre-pr.sh` (single source of truth, distributed via `/sync-dotfiles`). Read it when you need to know exactly what runs:

```bash
cat "$HOME/.claude/skills/hunk/hunk-pre-pr.sh"
```

It fires for both `Bash(gh pr create:*)` and `Bash(glab mr create:*)`, and the body is git-only (uses `origin`'s default branch as the base), so it works for either provider.

What it does at a glance:

1. Bails if not inside tmux.
2. Finds the repo root and `origin`'s default branch.
3. Bails if there's no diff between `HEAD` and the remote default branch.
4. Opens `hunk diff <range>` in a new tmux window or pane.
5. Background: waits up to 15s for the session to register, then drops a single `[pending] AI review in progress…` comment so the user has visible signal during the ~20–60s the parent session takes to compose comments.
6. Returns `permissionDecision: "deny"` with a brief telling the parent session to read the diff, decide complex-vs-trivial, clear the placeholder, apply real comments (or none), then re-run the PR/MR command.
7. On retry the hook surfaces an Allow/Deny prompt.

To make the hook **block** PR/MR creation until the user closes Hunk, change the final `exit 0` to `exit 2`.

## Agent notes visibility

If the user reports "I don't see the comments", they likely have `agent_notes = false` in their `~/.config/hunk/config.toml`. Reload with the flag so existing comments show up:

```bash
hunk session reload --repo <REPO_ROOT> -- diff --agent-notes <RANGE>
```

**WARNING**: `reload` clears all live comments. Re-apply the batch afterwards.

## Common arguments → command mapping

| User says | Command to run |
|---|---|
| `/hunk` (no arg) | `hunk diff <remote-default>...HEAD` |
| `/hunk HEAD~1` | `hunk diff HEAD~1` |
| `/hunk --pr 30` | resolve via `gh pr view`, `hunk diff <base>...<head>` |
| `/hunk main..feature` | `hunk diff main..feature` |
| (working tree changes) | `hunk diff` (no args) |
| (staged changes) | `hunk diff --staged` |

## Reference — bundled hunk session skill

The bundled skill `cat "$(hunk skill path)"` (already loaded in Round 1) is the source of truth. Key reminders:

- `--repo <path>` selects sessions by their loaded repo root.
- `comment apply` requires `--stdin` for batch JSON.
- `comment apply` payload items must specify `filePath` + `summary` + one target (`hunk`, `hunkNumber`, `oldLine`, `newLine`).
- `navigate` requires `--file` plus exactly one of `--hunk` / `--new-line` / `--old-line`, OR a relative `--next-comment` / `--prev-comment`.
- `reload` needs `--` before the nested Hunk command.
