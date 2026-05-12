# Lazy-load index (Detail files section)

**Load this when:** writing or improving a `CLAUDE.md` or `SKILL.md` that has tangential context (conventions, lookup data, workflow detail) which only matters in a specific phase or for a specific command, and should not always-load on every session.

## The pattern

Near the top of the `CLAUDE.md` / `SKILL.md` (after the H1 and any always-on critical rules), add a `## Lazy load` section. Each entry follows this shape:

```
- [<name-or-path>](<path>). **Read when:** <specific trigger>.
```

- The `[]` display text is whichever reads better (short name, or the full path).
- The `()` target is the on-disk path. The link is clickable in any markdown viewer; the path is still legible as plain text.
- Open the section with one sentence reminding the reader that entries are on-demand. Example: "Each file has a specific trigger. Do not pre-load; pull it in only when its trigger fires."

Concrete example (a CLAUDE.md):

```
## Lazy load

Each file has a specific trigger. Do not pre-load; pull it in only when its trigger fires.

- [.claude/files/hook-conventions.md](.claude/files/hook-conventions.md). **Read when:** creating or reorganizing a Claude Code hook.
- [.claude/files/skills.md](.claude/files/skills.md). **Read when:** creating, editing, or auditing a skill.
- [.claude/files/cli-commands.md](.claude/files/cli-commands.md). **Read when:** running `baton` / `go run ./cmd/...` for grant, revoke, actions, or ticketing.
```

## What makes a good `**Read when:**` trigger

The clause names a concrete phase, command, file pattern, or condition. "When relevant" and "for more context" are not specific enough.

Good:
- "Read when: creating or reorganizing a Claude Code hook."
- "Read when: implementing or modifying connector actions (`actions.go`, `BatonActionSchema`, `--invoke-action`)."
- "Read when: the user mentions `mac`, `titan`, or another machine alias."
- "Read when: computing per-criterion scores in Phase 2 and you need the full rubric."

Bad:
- "Read when: relevant."
- "For more context."
- "When in doubt."
- "When the user asks about it."

## When to extract a section into a detail file

A section in `CLAUDE.md` / `SKILL.md` should be extracted (moved to `.claude/files/<topic>.md` and linked from the parent's Detail files index) when:
- It only matters for a specific named phase, command, or file pattern.
- The parent file is over ~100 lines and the section is not a behavioral rule that must always fire.
- A reader can name the concrete trigger that should cause it to load.

Keep inline (do not extract):
- Critical behavioral rules that must apply on every session (NEVER-style prohibitions, writing-style bans, the readability rule).
- Short pointers under ~5 lines (the extraction overhead costs more than it saves).
- Anything where you can't name a precise trigger; without a trigger, "load on demand" collapses to "load always."
