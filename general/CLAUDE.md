# Claude Code Configuration

## Machine connection notes
Per-machine connection info, SSH aliases, and deploy recipes live in `~/CLAUDE-machines.md` (gitignored, machine-local). Read it when the user mentions `mac`, `titan`, or other host aliases, or asks how to push code/configs between machines.

## CRITICAL: Memory Files
**NEVER create memory files.** Do not write to `~/.claude/projects/*/memory/` or create any `MEMORY.md` or memory files of any kind. The user does not use the memory system.

## Code organization
**Prefer many small files over one monolithic file.** Group by responsibility (state, IPC, platform shims, lifecycle, install, autocmds, etc.) — one folder per coarse unit, one file per concern. When a module starts mixing concerns or pushing past a few hundred lines, split it; don't wait for it to balloon. The split applies to any language: a Lua plugin gets `lua/<name>/init.lua` + sibling files, a Python tool gets `pkg/__init__.py` + submodules, a Go service gets per-concern packages. This rule overrides any "single-file plugin" / "keep it small" notes in older project READMEs or `CLAUDE.local.md` files — surface the conflict, update the project doc, then split.

## Worktrees
Worktrees live at `~/worktrees/<repo>/<branch>` (managed by the `wt` helper at `$UTILITIES/stuff-git/wt`). Two rules when working in one:

- **Mirror the main checkout's `.envrc`.** Worktrees inherit `.git` but NOT working-tree files like `.envrc`, so dev-env hooks defined there don't follow you in. When work starts in a worktree, copy `.envrc` from the main checkout (and run `direnv allow` once). If the main repo has no `.envrc`, do nothing — there's nothing to mirror.
- **Promote repeated dev-binary build sequences to `.envrc`.** If the same multi-step build (e.g. `bun run build:bin && install -m 0755 dist/<repo> ~/.local/bin/<repo>-dev`) gets run more than a couple of times and the project has no Makefile target / `bin/` script for it, define it as an alias or shell function in `.envrc` (e.g. `<repo>-dev() { ... }`). Add it to **both** the main checkout's `.envrc` and every active worktree's copy so the command is available everywhere on `cd`. Don't pollute the project's source — `.envrc` stays gitignored and per-checkout.

## CRITICAL: Playwright Browser Issues
**NEVER ask the user to do anything with the browser.** Use the Playwright MCP plugin tools directly — they handle browser launch automatically.
- **NEVER delete** `~/.cache/ms-playwright/mcp-chrome-*` — contains Okta session data
- If browser is frozen or errors out: call `browser_close`, then retry — Chrome relaunches automatically

## Development Environment
- **Repos**: `~/repos` - Git repositories
- **Projects**: `$PROJECTS` - Active project work
- **Code**: `$CODE` - Code directory
- **Dotfiles**: `~/.dotfiles` - Configuration management

## Key Configurations
- **Neovim**: `~/.config/nvim/init.lua` (main config at `.v`)
- **Zsh**: `~/.config/zsh/.zshrc` (`.z`)
- **Tmux**: `~/.config/tmux/tmux.conf` (`.t`)
- **Aliases**: `~/.config/.aliases` (`.a`)

## Automation & Tools
- **Ansible**: `~/.local/share/ansible/local.yml` (`.an`)
  - Uses role-based structure with core/auth roles
  - Tasks organized in `tasks/` directory by category (system/, install/, build/)
  - Variables for environment paths (WORK, PROJECTS, CODE, etc.)
- **Scripts**: `$SCRIPTS` - Custom scripts directory
- **Automation**: `$AUTOMATION` - Automation scripts
- **Utilities**: `$UTILITIES` - Utility programs

## Build Environment
- **Builds**: `$BUILDS` - Build outputs
- **Suckless**: `$SUCKLESS` - Suckless tools (dwm, st)
- **QMK**: `~/qmk_firmware` - Keyboard firmware

## Commands to Remember
- **Lint/Typecheck**: Check project for standard commands (npm run lint, ruff, etc.)
- **Auto-suspend**: Managed via systemd service `xautolock@kanon.service`
- **Stow**: Use `cd ~/.dotfiles && stow <folder>` to manage symlinks
- **Shortcuts**: File shortcuts in `~/.config/shortcuts/sf`, dir shortcuts in `sd`
- **Personal Push**: `personal-push-all` or `dgpA` - pushes changes from main folders (notes|wiki|dotfiles|ansible)

## Work Environment
- **Work Directory**: `$WORK` - Work-related projects
- **Work Aliases**: `~/.config/.aliases_work` (`.aw`)
- **Work Startup**: `~/.config/.startup_work` (`.sw`)

## Skills

### Location
- **Default**: `$HOME/.claude/skills/<skill-name>/SKILL.md` — use this for all skills unless the skill is tightly coupled to a specific project. User-level skills must live under `~/.dotfiles/general/.claude/skills/<skill-name>/` and be stowed into `~/.claude/skills/` via GNU Stow, so they're versioned and available on every machine after `personal-push-all`.
- **Project-specific** (rare): `.claude/skills/<skill-name>/SKILL.md` inside the repo — only when the skill depends on files, tooling, or context that only makes sense within that one project.
- **Standard layout — every skill folder follows this shape**:

  ```
  ~/.claude/skills/<skill-name>/
  ├── SKILL.md          # required — frontmatter + workflow prose
  ├── scripts/          # optional — helper scripts (`.py`, `.sh`, `.ts`...)
  └── references/       # optional — markdown the skill reads at runtime
  ```

  - **`scripts/`** (plural). Helper scripts the skill invokes. Use `scripts/` to mirror the `lib/` naming used by hooks; reads as "the scripts this skill runs," not "a library of reusable code." Keep them executable + idempotent.
  - **`references/`** (plural). Markdown files the skill READS during a run — voice training, examples logs, lookup tables, decision trees the LLM follows. Anything the skill cites verbatim or learns from. Distinct from `scripts/` (executable helpers) and from external links (web docs aren't checked in). Append-only logs (e.g. `examples.md` with use counts) belong here too.
  - Add a folder only when the skill needs it. A pure-prose skill is just `SKILL.md`.

### Required properties — every skill I create must be:

**1. Portable.** Works on any machine where the dotfiles are stowed, without edits. That means:
  - No hardcoded paths outside `$HOME`, `$WORK`, `$PROJECTS`, `$CODE`, or project roots; prefer `~/` and env vars from `~/.machine_metadata` (`id`, `os`) over absolute paths or hostnames
  - OS differences live behind `case "$os" in linux|arch) ... ;; macOS|darwin) ... ;; esac` guards, not separate skills
  - No secrets, machine IDs, or personal identifiers embedded in the skill body — pull them from env (via direnv in the repo, or `~/.machine_metadata` for persistent machine data)
  - External binaries referenced in the skill must exist on every machine per the `ansible/` role, or be explicitly declared as a precondition in the frontmatter description

**2. Composable.** A skill should delegate to another skill when the other skill already covers a branch of its flow — never duplicate the logic. Composition patterns I use:
  - **Delegation** (single direction): the caller detects a condition and hands control to a more-general skill; the callee never needs to know it was delegated to. Example: `sync-dotfiles` → `sync-dotfiles-full` when the 30-day / uninitialized-submodule threshold fires.
  - **Sub-invocation** (caller resumes after callee): the caller runs a sub-skill for a specific step, then continues its own flow. Example: `disputes-replicate-quavo-view` calls `disputes-check-quavo-view-source` as a pre-replication gate, then resumes with replication.
  - **Handshake flag** (decoupled): a skill touches `/tmp/.<skill-name>-ok` on success; a hook or another skill consumes it. Use when Claude-run validation needs to gate an imperative step (e.g. `/validate-requirements` ↔ `pre-mr-check-hook`).
  - Inside a skill, when two steps share non-trivial logic (secret scan, metadata load, restow), extract the shared logic to a helper under `scripts/` rather than duplicating it inline.

**3. Reviewed with the `skill-creator` plugin before landing.** Whenever I create a new skill *or* make a non-trivial edit to an existing one (new steps, changed delegation, renamed frontmatter), I invoke `skill-creator:skill-creator` to review it — it checks description triggering accuracy, step coherence, and whether the skill duplicates or overlaps with an existing one. Trivial edits (typos, reformatting, updating a table) do not require this review.

### Skill frontmatter checklist
- `name` — matches the folder name
- `description` — the trigger prompt. Spell out the concrete signals that should cause Claude to invoke this skill; if a sibling skill shares triggers, say which one wins and why. `skill-creator` is the referee for this.
- `argument-hint` — required when the skill takes positional args; document each argument's valid values (enums, env names, etc.)

## Hook conventions
Applies to every Claude Code repo (project-level hooks in `.claude/hooks/`) and to user-level hooks in `~/.claude/hooks/`. Follow this layout when creating, renaming, or reorganizing hooks.

### Naming
- **Registered hook names use the form `<event>-<purpose>`**, e.g. `pre-mr-check`, `pre-plan-check`, `post-commit-lint`. The event prefix matches the Claude Code hook event abbreviated to something readable.
- **Only files registered in `settings.json` are "hooks"**. Sub-scripts and helpers are NOT hooks — don't give them the `-hook` suffix or the hook naming pattern. If a piece of logic is reused across an MR lifecycle (plan-time nudge → MR-time enforcement), it's a **skill**, not a hook helper; put it under `.claude/skills/` and let the hook handshake with it via a `/tmp/.<skill-name>-ok` flag.
- **Inside a hook's folder, the entrypoint is just `hook.sh` / `hook.py`** — the folder name already disambiguates. Don't write `pre-mr-check/pre-mr-check.sh`.

### Folder layout
Each registered hook gets its own folder:

```
.claude/hooks/
├── README.md           # required — directory-level index of hooks
├── <hook-name>/
│   ├── README.md       # required — see "Hook README structure" below
│   ├── hook.sh         # or hook.py — the entrypoint registered in settings.json
│   └── lib/            # optional — helpers called only by this hook
│       ├── README.md   # required whenever lib/ exists — see "lib/README.md structure" below
│       ├── <helper-1>.py
│       └── <helper-2>.py
└── <other-hook-name>/
    ├── README.md
    └── hook.sh
```

- **`.claude/hooks/README.md`** — required. Directory-level index listing every hook with event, trigger, purpose, and a link to the hook's own README. See "Directory README structure" below.
- **`hook.sh` / `hook.py`** — the file referenced by the `command:` field in `settings.json`. One per folder.
- **`lib/`** — only if the hook has true hook-internal helpers (formatting shims, pattern scanners, anything tightly coupled to hook logic). Helpers live under the owning hook, not a shared `.claude/hooks/lib/`.
- **`lib/README.md`** — required whenever `lib/` exists. Describes each helper, which hook step uses it, and why it lives as a lib helper rather than a skill.
- **Per-hook `README.md`** — required for every hook.

### When helpers become skills
If a helper script is invokable on its own and represents a user-facing unit of work (validation, report, lookup), it's a skill, not a lib helper. Signs:
- You'd plausibly want to run it manually, not just as part of the hook
- It's relevant at multiple lifecycle points (plan time and MR time)
- It hits external systems (APIs, Confluence, Snowflake) and the result can be cached across runs
Promote it to `.claude/skills/<name>/` with its own `SKILL.md` and `scripts/<name>.py`. Wire the hook to handshake with the skill via a `/tmp/.<skill-name>-ok` flag that the skill touches on success and the hook consumes.

### Directory README structure
`.claude/hooks/README.md` is the entry point for someone browsing the hooks directory. It should include:
1. One-paragraph scope — what this directory is, how hooks get registered (link to `settings.json`)
2. **Hooks in this repo** table — columns: `Hook` (link to its folder), `Event`, `Activates when`, `Purpose`. One row per registered hook.
3. Layout convention — a concise tree showing `hook.sh` + `README.md` + optional `lib/`, with a pointer to these home-level conventions
4. "Adding a new hook" — short checklist: create folder, register in settings.json, add a row to the table, create `lib/README.md` if a `lib/` emerges
5. Related — cross-references to `.claude/skills/`, the rule that there's no shared `.claude/hooks/lib/`, and user-level hooks in `~/.claude/hooks/`

### Hook README structure
Each hook's `README.md` should include, in this order:
1. Header — event, activates-when condition, entrypoint path, registration file
2. Steps — numbered list of what the hook does
3. Helpers (`lib/`) — table listing each helper, which step uses it, purpose. Omit if none. This table is a summary; the full per-helper detail lives in `lib/README.md`.
4. Handshake flags — if the hook waits on skill flags, document each: path, writer (which skill), what it guarantees, behavior when missing
5. Exit codes — table of 0/1/2 meanings for this hook
6. Known gotchas — rule exclusions, trust-dialog requirements, anything non-obvious

### lib/README.md structure
Whenever `lib/` exists, it must contain a `README.md` with:
1. One-paragraph intro — scope of this lib (hook-scoped helpers, not for direct user invocation, reuse across hooks is not the goal)
2. Helpers table — columns: `File`, `Used in hook.sh step`, `What it does`, `Why it lives here (not as a skill)`. The last column is load-bearing — it forces the author to justify each helper against the skill-promotion criteria.
3. Invocation — the canonical argument shape and exit-code convention (usually `0 = pass, 1 = fail, 2 = skip`)
4. "Adding a new helper" — short checklist: drop script here, wire up in `../hook.sh`, update both READMEs, re-check the skill-promotion criteria before committing

### Entrypoint script header
Every `hook.sh` / `hook.py` begins with a comment block containing:
1. One-line description of what the hook does
2. When it fires
3. Numbered steps (matching the README)
4. A **Helpers (lib/):** block listing each lib file and which step uses it — so anyone editing the hook sees immediately what it calls out to without opening `lib/`
5. Pointer to the README: `See <hook-name>/README.md for detail.`

### Rules of thumb
- **New hook** → new folder under `.claude/hooks/` with `hook.sh` + `README.md` + (optional) `lib/` + `lib/README.md`. Register the folder path in `settings.json` AND add a row to `.claude/hooks/README.md`.
- **Hook grows a helper** → drop it in the hook's `lib/` subfolder. Update the `hook.sh` header comment, the Helpers table in the hook README, AND the `lib/README.md` row.
- **Helper used by multiple hooks** → it's almost certainly a skill. Promote it to `.claude/skills/<name>/scripts/`.
- **Never suffix helpers with `-hook`** — that suffix is reserved for entrypoints registered in `settings.json`.

## Reference Files
Reference docs live under `~/.claude/files/` (dotfiles source: `~/.dotfiles/general/.claude/files/`). Read these before guessing or asking, when relevant:
- **`~/.claude/files/hook-debugging.md`** — debugging Claude Code hooks. Read when a hook isn't behaving (silent exits, matcher confusion, `set -e` aborts, manual test recipe, output JSON shape).

## Commits & PRs
- **NEVER** mention Claude or add `Co-Authored-By: Claude` in commit messages or PR descriptions


## Notes
- Uses environment variables for key paths (check shortcuts in `~/.config/shortcuts/`)
- Dotfiles are symlinked from `~/.dotfiles/` using GNU Stow
- Prefers systemd services over autostart desktop files
- System uses `xautolock` (not systemd-logind) for user-input-only idle detection
- **IMPORTANT**: Do not touch work-related files/directories unless explicitly requested
- **CRITICAL**: when I tell you to save the changes in my dotfiles, I mean these folders, and
    to use the personal-push-all command
  - `~/.dotfiles/` (dotfiles)
  - `~/notes/` (personal notes)
  - `~/wiki/` (personal wiki)
  - `~/.local/share/ansible/` (ansible configs)
  - This command commits AND pushes changes from all personal folders
