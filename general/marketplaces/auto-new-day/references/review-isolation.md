# Review isolation, diff-first scope, and the severe-findings loop

Shared contract for every skill that reviews or validates code: the review and validation phases of `fix-bug` and `impl`, `pr-code-review`, and any domain pack skill that cites this file. It overrides a skill's older "run it sequentially in the main session" wording for `--no-subagents`.

## 1. Every reviewer runs in a fresh context

A review written by a context that already holds the implementation (the plan, the debugging trail, the author's reasoning) or earlier review passes is biased toward agreeing with them. So:

- **Reviewers are always `Agent(...)` spawns, never inline work in the main session.** That holds with or without `--no-subagents`.
- **What `--no-subagents` changes is the count, not the isolation.** Default mode keeps one agent per lens. With `--no-subagents` / `NO_SUBAGENTS=1`, spawn **one** isolated reviewer agent that runs every lens one after another inside its own context. It costs about one review's worth of tokens and never sees the main session.
- **The reviewer prompt carries only:** the diff file path, the changed-file list (section 4), the ticket or PR title and description, the project rules the skill already loads (CLAUDE.md and the triggered lazy files), the lens briefs, and the severe-findings examples (section 5). Never include: the implementation plan, investigation notes, the main session's reasoning, a summary of what the change "is supposed to" fix beyond the ticket text, or another reviewer's findings.
- The main session is only the coordinator. It builds prompts, collects results, and synthesizes. It does not add its own findings to the review.

## 2. Every validator runs in a fresh context

A validator that saw the reviewer's reasoning (or wrote the code) confirms instead of checking.

- **Validators are always `Agent(...)` spawns, distinct from the reviewer agent and from each other.** That holds with or without `--no-subagents`.
- **The validator prompt carries only:** the claim as one sentence, its `file:line` anchor, the diff path, and the check to run (doc fetch, code path trace, local reproduction, spec quote). Leave out the reviewer's confidence, its argument, other validators' verdicts, and the severe-findings examples (they bias toward "yes, severe").
- **With `--no-subagents`**, a validation pass is **one** fresh validator agent that checks the whole finding list. Run `VALIDATION_PASSES` (default 3, `passes=<N>` clamps to 2..5) passes as separate agents, never inline. Do not give pass N the verdicts of passes 1..N-1.
- **`✓N` counts independent validator agents that agreed.** A same-session recheck counts for nothing. If a pass flips a verdict, surface the disagreement and lower the confidence, never average it away.

### Allowed exceptions

- A skill may be stricter than section 4 (for example "never flag unchanged code" on a teammate's PR).
- Tools that always run their own isolated fan-out regardless of `--no-subagents` (a vendor-managed review skill, an adversarial multi-finder sweep) satisfy this contract. They only cost more.
- An adversarial cross-check between two validators (B challenges A, an arbiter reconciles) is allowed **only after** each one has written its own independent verdict. Only those first verdicts count toward `✓N`.

## 3. Nesting fallback

Subagents cannot spawn subagents. The coordinator (top-level session) spawns reviewers and validators directly. A reviewer never spawns its own validators. If the skill is already running inside a subagent and cannot spawn, do the work inline, and mark every finding `✓0 (not isolated)` and the review `isolation: none` in its report, so nobody mistakes it for a verified review.

## 4. Diff-first scope

- Build the scope once: `git diff --name-only <base>...HEAD` (or `gh pr diff <N> --name-only` for a PR), minus generated and vendored files. Order it with the most-changed files first (`git diff --numstat`).
- Review the changed files first and spend most of the effort there. Read unchanged files only to understand a changed line (callers, interfaces, the function a hunk sits in).
- **Every finding cites a changed line** (`file:post-image-line` plus the one-line `+` excerpt).
- Code the PR didn't touch earns a finding only when the diff makes it worse (a new caller of a broken helper, a changed contract it relies on). Tag it `pre-existing` and list it after the in-diff findings. Never let it outrank them.
- On a recheck, the lines changed since the last reviewed SHA come first; the full diff is still the authority on what is in scope.

## 5. Severe findings become few-shot examples

The reviews learn from the severe issues they catch and the severe issues people catch for us.

### Where the examples live

The nearest **existing** `.claude/review-examples/severe.md`, walking up from the repo root (stop at `$HOME`), resolving symlinks. If none exists, use `~/.claude/review-examples/severe.md`, creating it with the header below on the first record. A project family that wants its own set creates `<parent>/.claude/review-examples/severe.md` once (a worktree parent can symlink to it). These files hold real code excerpts, so keep them out of public repos and public dotfiles. Header:

```markdown
# Severe review findings (few-shot examples)

Appended by review and fix skills per `auto-new-day/references/review-isolation.md` section 5. Newest first. Edit freely; reviewers read the top 20 entries.
```

### When to record

- **Our own review:** a finding at the top two tiers of the skill's scale (BLOCKER/MAJOR, Critical/High, Blocking) that survived validation with at least 2 agreeing validator agents (`✓2` or better).
- **Someone flagged it for us:** a human or review bot on a PR we authored marked a change severe: a stated Blocking/Critical/High/Major (or a red-tier bot glyph), or a CHANGES_REQUESTED review tied to a specific line. Record it when the fix worker addresses it, after judging that it's real. A finding judged false is never recorded.
- Recording is local bookkeeping. Unattended runs do it without asking. It never posts anything.

### Entry format

Prepend (newest first) one entry:

```markdown
### <short pattern name> · <severity> · <source: own-review | <login> | <bot-name>>
- Seen: <N> · last <YYYY-MM-DD> · <PR or commit link>
- Pattern: <one line: what kind of change produces the bug>
- Edge case: <the specific input or state that triggers it, concrete>
- Why severe: <one or two lines: the real-world consequence>
- Bad:
  ```<lang>
  <at most 8 lines, the offending code>
  ```
- Fix: <one line, or at most 4 lines of code>
```

Dedupe by pattern: if an entry with the same pattern exists, bump `Seen`, update `last` and the link, and refine the edge case if the new one is sharper. Don't add a second copy. Keep at most 60 entries; past that, drop the entry with the lowest `Seen` and the oldest `last`. Keep entries project-neutral in wording, except for the code excerpt itself.

### How reviewers use them

Paste the top 20 entries into every reviewer agent prompt (not validators) under this heading:

> **Past severe findings (few-shot).** These are real bugs this project's reviews caught. Look for the same pattern and edge case in the diff. Only flag one when a changed line actually exhibits it; don't force a match.
