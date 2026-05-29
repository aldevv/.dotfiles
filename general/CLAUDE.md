# Claude Code Configuration

## Lazy load

A `CLAUDE.md` (or `SKILL.md`) may include a "Lazy load" section near the top listing files that should be read on demand, only when a specific trigger fires, rather than eagerly on every session. Each entry pairs a path with a `**Read when:**` clause naming its trigger. Pull a file in only when its trigger matches the current context.

### Good vs bad triggers

Every `**Read when:**` clause must be broad enough to catch every situation it should fire on AND concrete enough that the match is unambiguous. Err broader: a wasted load is fine, a silently-missed load is not.

**Completeness beats brevity.** A good trigger carries all the information Claude needs to recognize the load moment, even if that takes multiple lines or a bulleted list. Don't truncate a trigger to fit a one-liner if the result loses signals. A complex file with many entry points gets a complex trigger; that's fine.

**Good triggers tie to observable signals:**
- file paths or extensions about to be edited (`editing any .go file`, `editing pkg/config/config.go`)
- commands about to run (`running ANY gh subcommand`, `running pass otp`)
- syntactic content in the tool call (`Write/Edit with //, #, /* in new content`)
- specific tool calls (`before any gh pr create`)
- explicit user phrases (`given a Linear ticket URL/ID`)

**Bad triggers rely on introspection or abstract categories:**
- `implementing a feature` (no signal, too abstract)
- `working with PRs` (vague self-categorization)
- `about to add a comment` (introspective, fires too late: Claude has already composed the comment in the Edit payload before the trigger registers)
- `considering whether X applies` (only loads after the work is done)
- `when in doubt, read this` (no concrete moment to anchor to)

**Fix recipe when a trigger is ignored:** replace the introspective phrasing with the file/tool/syntax signal that was actually observable at the moment the trigger should have fired.

### Files

By convention (universal, not specific to this file), lazy-loaded detail files always live in a sibling `.claude/lazy/` directory: next to the parent `CLAUDE.md`, at the project root for repo-level files, or under `~/.claude/lazy/` for the global user-level file. For this CLAUDE.md that resolves to `~/.claude/lazy/` (dotfiles source: `~/.dotfiles/general/.claude/lazy/`):

- [`~/.claude/lazy/skills.md`](.claude/lazy/skills.md). **Read when** any of:
  - creating, editing, or auditing a skill
  - editing any `SKILL.md` file or anything under a `.claude/skills/` directory

  Covers location, layout, portability/composability requirements, frontmatter checklist.

- [`~/.claude/lazy/hooks.md`](.claude/lazy/hooks.md). **Read when** any of:
  - editing hook entries in any `settings.json` / `settings.local.json` / plugin `hooks/hooks.json`
  - editing the `hooks:` block in a skill or agent frontmatter
  - writing or editing any script under `~/.claude/hooks/` (or a project-local `.claude/hooks/`)
  - the user mentions a Claude Code hook event by name (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart`, `Notification`, etc.)
  - diagnosing a Claude Code hook that fires when it shouldn't, misses when it should, exits silently, hangs, or has a `set -e` script aborting unexplained

  Covers `matcher` vs `if:` filtering, the fail-open behaviour on complex Bash commands, silent-exit traps, decision-control output shape per event, exit-code-vs-JSON rules, async hooks, the `bypassPermissions` "ask" trap, manual test recipe, recursion guard, and the in-script positive-gate pattern.

- [`~/.claude/lazy/code/quality.md`](.claude/lazy/code/quality.md). **Read when** any of:
  - writing new code (naming, extraction, choice of literal vs constant)
  - modifying or refactoring existing code
  - reviewing or auditing code for quality issues

  Covers naming, function extraction, hardcoded strings, magic separators.

- [`~/.claude/lazy/code/design.md`](.claude/lazy/code/design.md). **Read when** any of:
  - creating a new source file (`Write` of a path that doesn't exist)
  - splitting one file into multiple
  - moving functions or types between files
  - adding a new package or module
  - the user asks where logic should live or how to structure something

  Covers separation of responsibilities and the works-then-readable-then-optimized priority.

- [`~/.claude/lazy/code/comments.md`](.claude/lazy/code/comments.md). **Read when** any of:
  - writing, editing, or removing any code comment (`//`, `#`, `/*`, docstrings)
  - reviewing existing comments to trim

  Covers forbidden/justified examples, docstring rules, and header-comment guidance.

- [`~/.claude/lazy/code/debugging.md`](.claude/lazy/code/debugging.md). **Read when** any of:
  - user says "debug", "can't see what's happening", "print the AST/IR/tree", "dump", or "how do I see what X contains"
  - adding observability, tracing, or dump helpers to any pipeline, compiler, transpiler, or interpreter
  - creating a file named `debug.go`, `dump.go`, `_string.go`, or similar
  - a debugging session is stuck because the internal representation is opaque

  Covers the principle that cheap String()/Dump helpers and a gated logger are load-bearing infrastructure, with a concrete compiler example, a checklist for what to add and where, and when to escalate to GDB/dlv when observability alone isn't enough.

- [`~/.claude/rules/git.md`](.claude/rules/git.md). **Read when** any of:
  - about to write "ready for PR", "ready for MR", "ready to ship", "ready to merge", "you can open the PR/MR", "good to go", "no blockers", or any equivalent readiness phrase
  - before running `gh pr create` / `glab mr create` / `git push` on a branch that's about to be reviewed

  Covers the PR/MR-readiness honesty rule: static checks aren't testing; if you can't run it end-to-end, say so explicitly.

## Table of Contents
- [Lazy load](#lazy-load)
- [Machine connection notes](#machine-connection-notes)
- [CRITICAL: No premature breakpoints during autonomous drive](#critical-no-premature-breakpoints-during-autonomous-drive)
- [CRITICAL: Editing this file](#critical-editing-this-file)
- [CRITICAL: Work files boundary](#critical-work-files-boundary)
- [CRITICAL: Saving dotfiles changes](#critical-saving-dotfiles-changes)
- [CRITICAL: Writing style](#critical-writing-style)
- [CRITICAL: Comments](#critical-comments)
- [CRITICAL: Playwright Browser Issues](#critical-playwright-browser-issues)
- [Code organization](#code-organization)
- [Worktrees](#worktrees)
- [Development Environment](#development-environment)
- [Key Configurations](#key-configurations)
- [Automation & Tools](#automation--tools)
- [Build Environment](#build-environment)
- [Commands to Remember](#commands-to-remember)
- [Work Environment](#work-environment)
- [Commits & PRs](#commits--prs)

## Machine connection notes
Per-machine connection info, SSH aliases, and deploy recipes live in `~/CLAUDE-machines.md` (gitignored, machine-local). Read it when the user mentions `mac`, `titan`, or other host aliases, or asks how to push code/configs between machines.

## CRITICAL: No premature breakpoints during autonomous drive
**When autonomous-drive is active, NEVER end a turn at a "natural breakpoint".** Autonomous-drive is active when ANY of the following holds:
- Campaign file has `autonomous: true` frontmatter and `status: active`
- User said any of: "continue", "keep going", "don't stop", "drive until done", "make sessions longer", "I don't want to manually touch this", "until you are done"
- `/loop`, `/daemon`, or `/citadel:do continue` is the invocation that started the work

While active, keep iterating inside the same response until exactly one of:
- Context budget tightens to within ~15% of the cap
- A documented circuit breaker fires (3+ consecutive failures on the same approach, fundamental architectural conflict, gate stays red across two fix cycles)
- The user interrupts the turn

**Forbidden during autonomous-drive:** turn-ending summaries ("Session N closed", "Wave concluded"), asking "want me to keep going?", listing future strategies in the response body, declaring a stopping point because the next batch of work would need a strategy change. If a strategy change is needed, MAKE the strategy change and execute it. The next bounded piece of work always exists; find it and emit the next tool call.

**Why:** the user has repeatedly said sessions stop too early. The session right before this rule landed stopped after 5 commits, wrote a summary, asked the user to pick a next strategy. The user replied "makes these sessions longer, I don't want to manually touch this chat ever". This rule exists to prevent that pattern.

**How to apply:** after every commit during autonomous-drive, the very next text should announce the next bounded action, not summarize the previous one. Tool calls follow immediately. Status updates (one sentence each) are fine; sectioned summaries are not.

## CRITICAL: Editing this file
**Before adding any rule, command, or note to this file, grep the whole file for the topic first.** Past sessions have introduced duplicates because they added a new entry without checking what was already documented. If a section already covers it, edit that section in place. Never create a parallel copy in a different section. When a rule must be visible from multiple contexts, link with `See ## Section Name` rather than copying the content. After editing, scan the ToC and section headings for topic overlap.

**When the user asks to add a rule that's already documented, treat it as a signal the existing rule didn't stick in a past session and needs more weight.** Don't just point at the existing entry. Promote the rule by applying one or more of the following:
1. Rename the section to `## CRITICAL: ...` if it isn't already.
2. Strengthen the wording: vague verbs (`should`, `prefer`) become hard verbs (`NEVER`, `MUST`, `always`). Add a one-line consequence if useful (e.g. `...otherwise X breaks`).
3. Add the concrete example the user just brought up. Concrete violations stick harder than abstract rules.
4. Move the section higher in the file if it's buried; CRITICAL sections cluster near the top so they get the highest attention on load.

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

**Forbidden AI-slop vocabulary.** Do not use `no-op`, `noop`, `delve`, `delves into`, `leverage`, `leverages`, `seamless`, `seamlessly`, `robust`, `robustly`, `streamline`, `streamlined`, `unlock`, `unlocks`, `harness` (as a verb), `tapestry`, `intricate`, `realm`, `landscape`, `journey` (as metaphor), or `dive into`. They are filler that signals AI prose. Pick the concrete verb instead: `no-op` becomes `does nothing` / `skip`; `leverage` becomes `use`; `seamless` becomes `works without setup` or just delete it; `robust` becomes `handles X` (name the case); `streamline` becomes `simplify` or name the step removed. Applies everywhere prose lands: chat, commits, PRs, READMEs, comments, docs.

**Default to brief, casual, plain.** Short phrase beats a paragraph when both carry the same meaning. Simple words over fancy ones. Match the register of a teammate sending a Slack message, not a press release. If a sentence can be cut to a clause without losing information, cut it.

**README.md is for humans.** It's the project intro for a new reader (engineer, recruiter, drive-by browser), not Claude-facing memory, runbook, or agent-routing material. Lead with what the project is and how to start using it; keep the tone casual and short.

## CRITICAL: Comments
**Adding any comment is a rule violation by default.** Before writing any comment, state in chat first: `comment justified: <complex flow / hidden invariant / non-obvious WHY / workaround>`. **No comment goes into a tool call without that chat utterance preceding it.** If you can't articulate the justification in advance, don't write the comment. The check is pre-write, not post-write. There is no cleanup pass to fall back on.

Forbidden:
- Narrative comments that restate the next line.
- Function-purpose summaries on functions whose name and signature already convey it. Default for small helpers and single-purpose conversion functions: zero comments.
- File-level header comments that merely inventory what the file contains (filename plus declared types already say it). A short header IS justified when the file handles a complex flow and the header genuinely orients the reader.
- Type/struct comments that restate the type name as a sentence.
- "Used by X" / "For the Y flow" / cross-cutting consistency notes. Those belong in the PR description, not the code.
- Multi-line docstrings, unless the flow is truly hairy (subtle invariants, surprising ordering, platform workaround).

See [`~/.claude/lazy/code/comments.md`](.claude/lazy/code/comments.md) for worked forbidden/justified pairs.

Exception: tests. A one-line function-header comment on a test that names a non-obvious scenario is OK (`// Workday quirk: ref ID without name, require both`). Per-line narration inside the test body is not. Default is still zero, only add when the test name alone wouldn't tell a future reader what's being checked.

When a comment IS justified: as short as possible, as long as it needs to be. Understanding is the priority, brevity is second. Example, justified: `// REST-1107 requires dotted projection on this endpoint.` (vendor quirk a reader couldn't infer). Example, not justified: `// fetch the user` (the next line says so). If the complexity can be untangled by a small refactor that makes the code self-explanatory, prefer the refactor.

When touching existing code: if a comment restates the line that follows it, delete the comment.

## CRITICAL: Playwright Browser Issues
**NEVER ask the user to do anything with the browser.** Use the Playwright MCP plugin tools directly; they handle browser launch automatically.
- **NEVER delete** `~/.cache/ms-playwright/mcp-chrome-*`. Contains Okta session data.
- If browser is frozen or errors out: call `browser_close`, then retry. Chrome relaunches automatically.

## Code organization
**Prefer many small files over one monolithic file.** Group by responsibility (state, IPC, platform shims, lifecycle, install, autocmds, etc.). One folder per coarse unit, one file per concern. When a module starts mixing concerns or pushing past a few hundred lines, split it; don't wait for it to balloon. The split applies to any language: a Lua plugin gets `lua/<name>/init.lua` + sibling files, a Python tool gets `pkg/__init__.py` + submodules, a Go service gets per-concern packages. This rule overrides any "single-file plugin" or "keep it small" notes in older project READMEs or `CLAUDE.local.md` files: surface the conflict, update the project doc, then split.

## Worktrees
Worktrees live at `~/worktrees/<repo>/<branch>` (managed by the `wt` helper at `$UTILITIES/stuff-git/wt`). Two rules when working in one:

- **Mirror the main checkout's `.envrc`.** Worktrees inherit `.git` but NOT working-tree files like `.envrc`, so dev-env hooks defined there don't follow you in. When work starts in a worktree, copy `.envrc` from the main checkout (and run `direnv allow` once). If the main repo has no `.envrc`, do nothing; there's nothing to mirror.
- **Promote repeated dev-binary build sequences to `.envrc`.** If the same multi-step build (e.g. `bun run build:bin && install -m 0755 dist/<repo> ~/.local/bin/<repo>-dev`) gets run more than a couple of times and the project has no Makefile target / `bin/` script for it, define it as an alias or shell function in `.envrc` (e.g. `<repo>-dev() { ... }`). Add it to **both** the main checkout's `.envrc` and every active worktree's copy so the command is available everywhere on `cd`. Don't pollute the project's source: `.envrc` stays gitignored and per-checkout.

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
- **Auto-suspend**: Managed via systemd service `xautolock@kanon.service`
- **Stow**: Use `cd ~/.dotfiles && stow <folder>` to manage symlinks
- **Shortcuts**: File shortcuts in `~/.config/shortcuts/sf`, dir shortcuts in `sd`

## Work Environment
- **Work Directory**: `$WORK` - Work-related projects
- **Work Aliases**: `~/.config/.aliases_work` (`.aw`)
- **Work Startup**: `~/.config/.startup_work` (`.sw`)

## Commits & PRs
- **NEVER** mention Claude or add `Co-Authored-By: Claude` in commit messages or PR descriptions
