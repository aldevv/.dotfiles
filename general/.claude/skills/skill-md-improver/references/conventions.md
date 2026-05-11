# Skill conventions reference

Distilled from `~/CLAUDE.md`'s "Skills" section. Backs angle-1 (frontmatter / triggering) and angle-5 (portability / guardrails) of `skill-md-improver`. Read this before fanning out so the critics' rules match the user's project-wide conventions.

**When to read this**: during step 1 (gather context). Pass the relevant rules into the angle-1 and angle-5 agent prompts so they critique against this baseline.

---

## Standard layout

```
~/.claude/skills/<skill-name>/
├── SKILL.md          # required — frontmatter + workflow prose
├── scripts/          # optional — helper scripts (.py / .sh / .ts)
└── references/       # optional — markdown the skill reads at runtime
```

- **`SKILL.md`** — the entrypoint. Frontmatter + workflow. Don't bloat past ~200 lines.
- **`scripts/`** (plural) — executable helpers the skill invokes. Idempotent, executable bit set.
- **`references/`** (plural) — markdown files the skill READS during a run — lookup tables, decision trees, voice training, append-only logs. Anything the skill cites verbatim or learns from.
- A pure-prose skill is just `SKILL.md`. Add folders only when needed.

---

## Frontmatter checklist

- **`name`** — matches the folder name exactly.
- **`description`** — the trigger prompt. Must:
  - Spell out concrete signals (phrases users actually say) that should cause Claude to invoke this skill.
  - Disambiguate from sibling skills that share triggers — name them and say which wins on contested triggers and why.
  - Include "Do NOT trigger" cases when there are confusable scenarios.
- **`argument-hint`** — required when the skill takes positional args. Document each argument's valid values (enums, env names, etc.).

`skill-creator:skill-creator` is the canonical referee for description triggering accuracy and overlap detection.

---

## Required properties — every skill must be:

### Portable

- No hardcoded paths outside `$HOME`, `$WORK`, `$PROJECTS`, `$CODE`, or project roots.
- Prefer `~/` and env vars (from `~/.machine_metadata`: `id`, `os`) over absolute paths or hostnames.
- OS differences live behind `case "$os" in linux|arch) ... ;; macOS|darwin) ... ;; esac` — not separate per-OS skills.
- No secrets, machine IDs, or personal identifiers embedded in skill body — pull from env / direnv / `~/.machine_metadata`.
- External binaries the skill calls must exist on every target machine (per the ansible role) OR be declared as preconditions in the frontmatter description.

### Composable

- Delegate to another skill when the other skill already covers a branch of the flow — never duplicate.
- Composition patterns:
  - **Delegation** (one direction) — caller detects a condition, hands control to a more-general skill. Callee doesn't know it was delegated to. Example: `sync-dotfiles` → `sync-dotfiles-full` on 30-day / uninitialized-submodule threshold.
  - **Sub-invocation** (caller resumes) — caller runs a sub-skill for one step, then continues. Example: `disputes-replicate-quavo-view` → `disputes-check-quavo-view-source` as a pre-replication gate.
  - **Handshake flag** (decoupled) — skill touches `/tmp/.<skill-name>-ok` on success; a hook or another skill consumes it. Use when Claude-run validation needs to gate an imperative step.
- When two steps inside one skill share non-trivial logic (secret scan, metadata load, restow), extract to a helper under `scripts/` rather than duplicating inline.

### Reviewed before landing

For non-trivial edits (new steps, changed delegation, renamed frontmatter), invoke `skill-creator:skill-creator` to verify description triggering accuracy and rule out overlap with sibling skills. Trivial edits (typos, reformatting, table updates) skip the review.

---

## Skill vs. lib helper — when to promote

A helper script under `lib/` (inside a hook) is a candidate for promotion to a full skill when:

- It's invokable on its own and represents a user-facing unit of work.
- You'd plausibly run it manually, not just as part of a hook.
- It's relevant at multiple lifecycle points (plan time and MR time).
- It hits external systems (APIs, Confluence, Snowflake) and the result can be cached across runs.

Promotion target: `~/.claude/skills/<name>/` with its own `SKILL.md` and `scripts/<name>.{sh,py}`. Wire the hook (if any) to handshake via a `/tmp/.<skill-name>-ok` flag.

---

## Common smells (cross-reference)

Worked Bad → Better entries live in `avoid.md`. Smells the angle critics should look for:

- Description that says only "use this for X" without naming the trigger phrases.
- Description that omits "Do NOT trigger" when a sibling skill shares triggers.
- Steps that reference reference-file content without saying *when* to load them.
- Helpers documented in the body but missing from `scripts/` or `lib/`.
- Reference files mixing antipatterns and positive recipes — split them.
- A skill with `scripts/` containing one tiny helper that should have stayed inline.
- A skill that copy-pastes logic instead of delegating to a sibling that already covers the branch.
