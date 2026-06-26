# Skills (conventions and layout)
## Location

- **Default**: `$HOME/.claude/skills/<skill-name>/SKILL.md`. Use this for all skills unless the skill is tightly coupled to a specific project. User-level skills must live under `~/.dotfiles/general/.claude/skills/<skill-name>/` and be stowed into `~/.claude/skills/` via GNU Stow, so they're versioned and available on every machine after a sync.
- **Project-specific** (rare): `.claude/skills/<skill-name>/SKILL.md` inside the repo, only when the skill depends on files, tooling, or context that only makes sense within that one project.
- **Standard layout** (every skill folder follows this shape):

  ```
  ~/.claude/skills/<skill-name>/
  ├── SKILL.md          # required: frontmatter + workflow prose
  ├── scripts/          # optional: helper scripts (.py, .sh, .ts...)
  └── references/       # optional: markdown the skill reads at runtime
  ```

  - **`scripts/`** (plural). Helper scripts the skill invokes. Use `scripts/` to mirror the `lib/` naming used by hooks; reads as "the scripts this skill runs," not "a library of reusable code." Keep them executable and idempotent.
  - **`references/`** (plural). Markdown files the skill READS during a run: voice training, examples logs, lookup tables, decision trees the LLM follows. Anything the skill cites verbatim or learns from. Distinct from `scripts/` (executable helpers) and from external links (web docs aren't checked in). Append-only logs (e.g. `examples.md` with use counts) belong here too.
  - Add a folder only when the skill needs it. A pure-prose skill is just `SKILL.md`.

## Required properties (every skill I create must be)

**1. Portable.** Works on any machine where the dotfiles are stowed, without edits. That means:
- No hardcoded paths outside `$HOME`, `$WORK`, `$PROJECTS`, `$CODE`, or project roots; prefer `~/` and env vars from `~/.machine_metadata` (`id`, `os`) over absolute paths or hostnames
- OS differences live behind `case "$os" in linux|arch) ... ;; macOS|darwin) ... ;; esac` guards, not separate skills
- No secrets, machine IDs, or personal identifiers embedded in the skill body; pull them from env (via direnv in the repo, or `~/.machine_metadata` for persistent machine data)
- External binaries referenced in the skill must exist on every machine per the `ansible/` role, or be explicitly declared as a precondition in the frontmatter description

**2. Composable.** A skill should delegate to another skill when the other skill already covers a branch of its flow; never duplicate the logic. Composition patterns I use:
- **Delegation** (single direction): the caller detects a condition and hands control to a more-general skill; the callee never needs to know it was delegated to. Example: `sync-dotfiles` -> `sync-dotfiles-full` when the 30-day or uninitialized-submodule threshold fires.
- **Sub-invocation** (caller resumes after callee): the caller runs a sub-skill for a specific step, then continues its own flow. Example: `disputes-replicate-quavo-view` calls `disputes-check-quavo-view-source` as a pre-replication gate, then resumes with replication.
- **Handshake flag** (decoupled): a skill touches `/tmp/.<skill-name>-ok` on success; a hook or another skill consumes it. Use when Claude-run validation needs to gate an imperative step (e.g. `/validate-requirements` <-> `pre-mr-check-hook`).
- Inside a skill, when two steps share non-trivial logic (secret scan, metadata load, restow), extract the shared logic to a helper under `scripts/` rather than duplicating it inline.

**3. Reviewed with the `skill-creator` plugin before landing.** Whenever I create a new skill or make a non-trivial edit to an existing one (new steps, changed delegation, renamed frontmatter), I invoke `skill-creator:skill-creator` to review it. It checks description triggering accuracy, step coherence, and whether the skill duplicates or overlaps with an existing one. Trivial edits (typos, reformatting, updating a table) do not require this review.

## Skill frontmatter checklist
- `name`: matches the folder name
- `description`: the trigger prompt (max 1024 characters). Keep it concise and to the point — as small and easy-to-understand as possible for compatibility. Spell out the concrete signals that should cause Claude to invoke this skill; if a sibling skill shares triggers, say which one wins and why. `skill-creator` is the referee for this.
- `argument-hint`: required when the skill takes positional args; document each argument's valid values (enums, env names, etc.)
