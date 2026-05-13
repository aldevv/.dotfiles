# Claude Code Configuration

## Lazy load

A `CLAUDE.md` (or `SKILL.md`) may include a "Lazy load" section near the top listing files that should be read on demand, only when a specific trigger fires, rather than eagerly on every session. Each entry pairs a path with a `**Read when:**` clause naming its trigger. Pull a file in only when its trigger matches the current context.

By convention (universal, not specific to this file), lazy-loaded detail files always live in a sibling `.claude/files/` directory: next to the parent `CLAUDE.md`, at the project root for repo-level files, or under `~/.claude/files/` for the global user-level file. For this CLAUDE.md that resolves to `~/.claude/files/` (dotfiles source: `~/.dotfiles/general/.claude/files/`):

- [`~/.claude/files/skills.md`](.claude/files/skills.md). **Read when:** creating, editing, or auditing a skill. Covers location, layout, portability/composability requirements, frontmatter checklist.
- [`~/.claude/files/hook-conventions.md`](.claude/files/hook-conventions.md). **Read when:** creating or reorganizing a Claude Code hook. Covers naming, folder layout, README structure, when a helper becomes a skill.
- [`~/.claude/files/hook-debugging.md`](.claude/files/hook-debugging.md). **Read when:** a hook isn't behaving (silent exits, matcher confusion, `set -e` aborts, manual test recipe, output JSON shape).

## Table of Contents
- [Lazy load](#lazy-load)
- [Machine connection notes](#machine-connection-notes)
- [CRITICAL: Memory Files](#critical-memory-files)
- [CRITICAL: Readability](#critical-readability)
- [CRITICAL: Work files boundary](#critical-work-files-boundary)
- [CRITICAL: Saving dotfiles changes](#critical-saving-dotfiles-changes)
- [CRITICAL: Writing style](#critical-writing-style)
- [Code organization](#code-organization)
- [Worktrees](#worktrees)
- [CRITICAL: Playwright Browser Issues](#critical-playwright-browser-issues)
- [Development Environment](#development-environment)
- [Key Configurations](#key-configurations)
- [Automation & Tools](#automation--tools)
- [Build Environment](#build-environment)
- [Commands to Remember](#commands-to-remember)
- [Work Environment](#work-environment)
- [Code style](#code-style)
- [Commits & PRs](#commits--prs)
- [Notes](#notes)

## Machine connection notes
Per-machine connection info, SSH aliases, and deploy recipes live in `~/CLAUDE-machines.md` (gitignored, machine-local). Read it when the user mentions `mac`, `titan`, or other host aliases, or asks how to push code/configs between machines.

## CRITICAL: Memory Files
**NEVER create memory files.** Do not write to `~/.claude/projects/*/memory/` or create any `MEMORY.md` or memory files of any kind. The user does not use the memory system.

## CRITICAL: Readability
**Readability is priority #1.** Apply clean-code practices only when they make the code easier to read, not as ends in themselves.
- **Long or hard-to-grasp `if` conditions get extracted to a named predicate function.** `if isEligibleForRefund(order) { ... }` reads better than five chained boolean clauses. Same rule for switch/case guards, `while`/`for` loop conditions, and nested ternaries: name the predicate.
- **Prefer many small named functions over one long function with inline comments.** A well-named function call is self-documenting; a comment above an inline block isn't.
- **Don't refactor for purity alone.** DRY, SRP, Hexagonal, dependency injection are fine when they make a specific reader's life easier here. If a refactor adds indirection a future reader has to chase without paying for itself in clarity, skip it. Three similar lines is better than a premature abstraction.
- **When in conflict, readability wins.** If a "clean" pattern obscures what the code does, the pattern is wrong for this spot.

## CRITICAL: Work files boundary
**Do not touch work-related files or directories unless explicitly requested.** Includes `$WORK`, `~/.config/.aliases_work`, `~/.config/.startup_work`, and any work-tagged repo. If a request is ambiguous about whether something is work-related, ask before touching it.

## CRITICAL: Saving dotfiles changes
When the user says "save the changes in my dotfiles" (or any equivalent), they mean these folders:
- `~/.dotfiles/` (dotfiles)
- `~/notes/` (personal notes)
- `~/wiki/` (personal wiki)
- `~/.local/share/ansible/` (ansible configs)

**Prefer the `sync-dotfiles` skill** for the dotfiles repo specifically; it's faster (skips submodules) and delegates to `sync-dotfiles-full` on the monthly threshold or when a submodule is uninitialized. Fall back to `personal-push-all` only when the user explicitly asks for the broader notes/wiki/ansible sweep in addition to dotfiles.

## CRITICAL: Writing style
**Forbidden punctuation: em-dash (`—`) and double-hyphen (`--`).** Do not use either in any user-facing text, commit messages, PR descriptions, READMEs, comments, docs, or chat replies. They make writing sound robotic. Rewrite with a comma, period, parenthesis, or colon instead. CLI flags like `--flag` are fine; the ban is on em-dashes and double-hyphens used as prose punctuation.

**Forbidden: emojis.** Do not use emojis anywhere (chat, commits, PRs, READMEs, comments, docs, file contents). Applies even if the surrounding text or an existing file already uses them. Only exception: the user explicitly asks for an emoji in this turn.

## Code organization
**Prefer many small files over one monolithic file.** Group by responsibility (state, IPC, platform shims, lifecycle, install, autocmds, etc.). One folder per coarse unit, one file per concern. When a module starts mixing concerns or pushing past a few hundred lines, split it; don't wait for it to balloon. The split applies to any language: a Lua plugin gets `lua/<name>/init.lua` + sibling files, a Python tool gets `pkg/__init__.py` + submodules, a Go service gets per-concern packages. This rule overrides any "single-file plugin" or "keep it small" notes in older project READMEs or `CLAUDE.local.md` files: surface the conflict, update the project doc, then split.

## Worktrees
Worktrees live at `~/worktrees/<repo>/<branch>` (managed by the `wt` helper at `$UTILITIES/stuff-git/wt`). Two rules when working in one:

- **Mirror the main checkout's `.envrc`.** Worktrees inherit `.git` but NOT working-tree files like `.envrc`, so dev-env hooks defined there don't follow you in. When work starts in a worktree, copy `.envrc` from the main checkout (and run `direnv allow` once). If the main repo has no `.envrc`, do nothing; there's nothing to mirror.
- **Promote repeated dev-binary build sequences to `.envrc`.** If the same multi-step build (e.g. `bun run build:bin && install -m 0755 dist/<repo> ~/.local/bin/<repo>-dev`) gets run more than a couple of times and the project has no Makefile target / `bin/` script for it, define it as an alias or shell function in `.envrc` (e.g. `<repo>-dev() { ... }`). Add it to **both** the main checkout's `.envrc` and every active worktree's copy so the command is available everywhere on `cd`. Don't pollute the project's source: `.envrc` stays gitignored and per-checkout.

## CRITICAL: Playwright Browser Issues
**NEVER ask the user to do anything with the browser.** Use the Playwright MCP plugin tools directly; they handle browser launch automatically.
- **NEVER delete** `~/.cache/ms-playwright/mcp-chrome-*`. Contains Okta session data.
- If browser is frozen or errors out: call `browser_close`, then retry. Chrome relaunches automatically.

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
- **Save dotfiles**: prefer the `sync-dotfiles` skill (fast, smart about submodules). `personal-push-all` / `dgpA` is the broader sweep across notes|wiki|dotfiles|ansible. See `## CRITICAL: Saving dotfiles changes` above.

## Work Environment
- **Work Directory**: `$WORK` - Work-related projects
- **Work Aliases**: `~/.config/.aliases_work` (`.aw`)
- **Work Startup**: `~/.config/.startup_work` (`.sw`)

## Code style

**Everything in this section is a RULE, not a guideline.** Apply without exception unless an explicit exception is given in the current turn. "I thought it would be cleaner" is not an exception.

### Comments
Default to writing zero comments. Only add one when it explains a complex flow, a hidden invariant, a non-obvious WHY, or a workaround. Never write narrative comments that restate the code, summarize a function's purpose, document obvious sequencing, or reference the current task/PR/caller. If removing a comment wouldn't actively confuse a future reader, do not write it. Applies to existing comments too: when touching code, if a comment restates what the next line already says, trim it.

When a comment is justified, keep it to **one short, plain-English line**. No multi-line function-header docstrings unless the flow is truly complex (subtle invariants, surprising ordering, platform workarounds). The bar is high, and three-clause sentences with semicolons are a smell. When in doubt, **delete the comment** and trust the reader.

## Commits & PRs
- **NEVER** mention Claude or add `Co-Authored-By: Claude` in commit messages or PR descriptions

## Notes
- Uses environment variables for key paths (check shortcuts in `~/.config/shortcuts/`)
- Dotfiles are symlinked from `~/.dotfiles/` using GNU Stow
- Prefers systemd services over autostart desktop files
- System uses `xautolock` (not systemd-logind) for user-input-only idle detection
