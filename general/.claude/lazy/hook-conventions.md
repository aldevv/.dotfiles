# Hook conventions

**Load this when:** the user asks to create, rename, reorganize, or audit a Claude Code hook (project-level `.claude/hooks/` or user-level `~/.claude/hooks/`).

Applies to every Claude Code repo (project-level hooks in `.claude/hooks/`) and to user-level hooks in `~/.claude/hooks/`.

## Naming
- **Registered hook names use the form `<event>-<purpose>`**, e.g. `pre-mr-check`, `pre-plan-check`, `post-commit-lint`. The event prefix matches the Claude Code hook event abbreviated to something readable.
- **Only files registered in `settings.json` are "hooks"**. Sub-scripts and helpers are NOT hooks; don't give them the `-hook` suffix or the hook naming pattern. If a piece of logic is reused across an MR lifecycle (plan-time nudge -> MR-time enforcement), it's a **skill**, not a hook helper; put it under `.claude/skills/` and let the hook handshake with it via a `/tmp/.<skill-name>-ok` flag.
- **Inside a hook's folder, the entrypoint is just `hook.sh` / `hook.py`**. The folder name already disambiguates. Don't write `pre-mr-check/pre-mr-check.sh`.

## Folder layout
Each registered hook gets its own folder:

```
.claude/hooks/
├── README.md           # required: directory-level index of hooks
├── <hook-name>/
│   ├── README.md       # required: see "Hook README structure" below
│   ├── hook.sh         # or hook.py: the entrypoint registered in settings.json
│   └── lib/            # optional: helpers called only by this hook
│       ├── README.md   # required whenever lib/ exists: see "lib/README.md structure" below
│       ├── <helper-1>.py
│       └── <helper-2>.py
└── <other-hook-name>/
    ├── README.md
    └── hook.sh
```

- **`.claude/hooks/README.md`**: required. Directory-level index listing every hook with event, trigger, purpose, and a link to the hook's own README. See "Directory README structure" below.
- **`hook.sh` / `hook.py`**: the file referenced by the `command:` field in `settings.json`. One per folder.
- **`lib/`**: only if the hook has true hook-internal helpers (formatting shims, pattern scanners, anything tightly coupled to hook logic). Helpers live under the owning hook, not a shared `.claude/hooks/lib/`.
- **`lib/README.md`**: required whenever `lib/` exists. Describes each helper, which hook step uses it, and why it lives as a lib helper rather than a skill.
- **Per-hook `README.md`**: required for every hook.

## When helpers become skills
If a helper script is invokable on its own and represents a user-facing unit of work (validation, report, lookup), it's a skill, not a lib helper. Signs:
- You'd plausibly want to run it manually, not just as part of the hook
- It's relevant at multiple lifecycle points (plan time and MR time)
- It hits external systems (APIs, Confluence, Snowflake) and the result can be cached across runs

Promote it to `.claude/skills/<name>/` with its own `SKILL.md` and `scripts/<name>.py`. Wire the hook to handshake with the skill via a `/tmp/.<skill-name>-ok` flag that the skill touches on success and the hook consumes.

## Directory README structure
`.claude/hooks/README.md` is the entry point for someone browsing the hooks directory. It should include:
1. One-paragraph scope: what this directory is, how hooks get registered (link to `settings.json`)
2. **Hooks in this repo** table with columns `Hook` (link to its folder), `Event`, `Activates when`, `Purpose`. One row per registered hook.
3. Layout convention: a concise tree showing `hook.sh` + `README.md` + optional `lib/`, with a pointer to these home-level conventions
4. "Adding a new hook": short checklist: create folder, register in settings.json, add a row to the table, create `lib/README.md` if a `lib/` emerges
5. Related: cross-references to `.claude/skills/`, the rule that there's no shared `.claude/hooks/lib/`, and user-level hooks in `~/.claude/hooks/`

## Hook README structure
Each hook's `README.md` should include, in this order:
1. Header: event, activates-when condition, entrypoint path, registration file
2. Steps: numbered list of what the hook does
3. Helpers (`lib/`): table listing each helper, which step uses it, purpose. Omit if none. This table is a summary; the full per-helper detail lives in `lib/README.md`.
4. Handshake flags: if the hook waits on skill flags, document each: path, writer (which skill), what it guarantees, behavior when missing
5. Exit codes: table of 0/1/2 meanings for this hook
6. Known gotchas: rule exclusions, trust-dialog requirements, anything non-obvious

## lib/README.md structure
Whenever `lib/` exists, it must contain a `README.md` with:
1. One-paragraph intro: scope of this lib (hook-scoped helpers, not for direct user invocation, reuse across hooks is not the goal)
2. Helpers table with columns `File`, `Used in hook.sh step`, `What it does`, `Why it lives here (not as a skill)`. The last column is load-bearing: it forces the author to justify each helper against the skill-promotion criteria.
3. Invocation: the canonical argument shape and exit-code convention (usually `0 = pass, 1 = fail, 2 = skip`)
4. "Adding a new helper": short checklist: drop script here, wire up in `../hook.sh`, update both READMEs, re-check the skill-promotion criteria before committing

## Entrypoint script header
Every `hook.sh` / `hook.py` begins with a comment block containing:
1. One-line description of what the hook does
2. When it fires
3. Numbered steps (matching the README)
4. A **Helpers (lib/):** block listing each lib file and which step uses it, so anyone editing the hook sees immediately what it calls out to without opening `lib/`
5. Pointer to the README: `See <hook-name>/README.md for detail.`

## Rules of thumb
- **New hook**: new folder under `.claude/hooks/` with `hook.sh` + `README.md` + (optional) `lib/` + `lib/README.md`. Register the folder path in `settings.json` AND add a row to `.claude/hooks/README.md`.
- **Hook grows a helper**: drop it in the hook's `lib/` subfolder. Update the `hook.sh` header comment, the Helpers table in the hook README, AND the `lib/README.md` row.
- **Helper used by multiple hooks**: it's almost certainly a skill. Promote it to `.claude/skills/<name>/scripts/`.
- **Never suffix helpers with `-hook`**: that suffix is reserved for entrypoints registered in `settings.json`.
