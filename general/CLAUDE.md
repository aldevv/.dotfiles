# Claude Code Configuration

## Lazy load

Files in the list below are read on demand when their `**Read when:**` clause matches the current context. A wasted load is fine; a silently-missed load is not, so err broader on a match. Lazy files live in a sibling `.claude/lazy/` directory (here: `~/.claude/lazy/`, dotfiles source `~/.dotfiles/general/.claude/lazy/`). Authoring guidance for triggers lives in [`~/.claude/lazy/trigger-authoring.md`](.claude/lazy/trigger-authoring.md), loaded when editing a Lazy load section.

A PreToolUse hook (`~/.claude/hooks/lazy-scan-reminder.sh`) fires on every `Write`/`Edit`/`NotebookEdit` and injects a reminder to:
- Re-scan this table.
- Re-read any listed file whose trigger fires on the current work.
- After a compaction summary: treat every lazy file as evicted and re-read every triggered file. No "I remember it" self-check — the summary preserves the *fact* of reading, not the content.

- [`~/.claude/lazy/skills.md`](.claude/lazy/skills.md). **Read when** any of:
  - creating, editing, or auditing a skill
  - editing any `SKILL.md` file or anything under a `.claude/skills/` directory

- [`~/.claude/lazy/hooks.md`](.claude/lazy/hooks.md). **Read when** any of:
  - editing hook entries in any `settings.json` / `settings.local.json` / plugin `hooks/hooks.json`
  - editing the `hooks:` block in a skill or agent frontmatter
  - writing or editing any script under `~/.claude/hooks/` (or a project-local `.claude/hooks/`)
  - the user mentions a Claude Code hook event by name (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart`, `Notification`, etc.)
  - diagnosing a Claude Code hook that fires when it shouldn't, misses when it should, exits silently, hangs, or has a `set -e` script aborting unexplained

The `~/.claude/lazy/code/` folder has three files; load each only when its own trigger fires. Do NOT load the whole folder by default. `code.md` covers refactoring, naming, function shape, comments, and shell rules in one file; `design.md` and `debugging.md` are conditional and usually skipped.

- [`~/.claude/lazy/code/code.md`](.claude/lazy/code/code.md). **Read when** any of:
  - BEFORE the first `Write`/`Edit` of any source/code file (anything a formatter like `gofmt`/`prettier`/`black`/`shfmt`/`rustfmt` would touch; one-line changes and brand-new wrappers/scripts/CLIs count).
  - BEFORE adding, editing, or removing a comment (`//`, `#`, `/*`, `"""`, `'''`, docstring) in a code file.
  - User asks for new code: "write a script", "create a wrapper/utility/CLI/helper", "I want a command/tool".
  - User asks for a new feature or implementation: "new feature", "add a feature", "implement X", "add X to <project>", "build X for <project>", "support X in <project>", "can we add X".
  - User asks for a code change: "refactor/clean up/extract/rename/simplify <code object>", "update/modify/tweak/fix my <script/program/config>", "change X in <file>".
  - Skip: bare `rename`/`extract`/`simplify` with no code object (e.g. "rename a column") does NOT fire.

- [`~/.claude/lazy/code/design.md`](.claude/lazy/code/design.md). **Read when** any of:
  - planning code structure across more than one file: where logic should live, file/module layout, splitting an existing file, moving functions/types between files, adding a new package or module
  - touching code that already spans multiple files in coordinated ways (cross-file refactor, layer reshuffle)
  - `Read` returned a code file ≥300 LOC AND the next `Write`/`Edit` adds a new top-level responsibility (a new function/type/section unrelated to the existing ones in the file)
  - editing two or more files in the same turn where one calls into the other (client/service/repository layout), or the user said "split this file", "where should X live", "which layer owns Y", "add a new package for Z"

  **Skip ONLY if ALL hold:** (a) the whole program is in a single file, (b) the file is under 200 LOC including blanks, (c) there is exactly one top-level entry point and no internal layering (no client/service/repo split, no per-concern helpers grouped into sections). If any of (a)/(b)/(c) is uncertain, do NOT skip; load it. Typical skip targets: wrapper CLIs, one-shot utilities, glue scripts, ad-hoc shell tools.

- [`~/.claude/lazy/code/debugging.md`](.claude/lazy/code/debugging.md). **Read when** any of:
  - user says "debug" / "can't see what's happening" / "dump" / "print/inspect what X contains" / "why is X wrong" / "trace what happens when" / "I can't tell what this struct/value contains"
  - about to add a `log.`/`fmt.Print`/`println!`/`print(`/`console.log`/`eprintln!`/`puts`/`p `/`pp` call to source that isn't a test fixture, AND the call is ad-hoc debug-only (not first-class production logging or structured prod tracing)
  - adding a `String()` / `__repr__` / `Display` helper or a `Dump*` / `_string.go` file, OR creating a file literally named `debug.go` / `dump.go` / `_string.go`
  - about to invoke `dlv` / `gdb` / `pdb` / `lldb` from Bash
  - writing a reproducer or regression test for a bug the user has identified
  - user has sent 2+ consecutive turns about the same bug without resolution

  **Skip ONLY when:** no bug is being investigated AND no debug-only logging/tracing/dump code is being added AND no `String()`/`__repr__`/`Display` helper is being touched AND the user did not use a debug-intent phrase from the list above. If any fire-clause matches, the fire wins; do not skip. Concrete skip targets: fixing a typo, renaming a variable, adding a new endpoint, building a CLI wrapper.

## Machine connection notes
Per-machine connection info, SSH aliases, and deploy recipes live in `~/CLAUDE-machines.md` (gitignored, machine-local). Read it when the user mentions `mac`, `titan`, or other host aliases, or asks how to push code/configs between machines.

## CRITICAL: Editing this file
**Before adding any rule, command, or note to this file, grep the whole file for the topic first.** Past sessions have introduced duplicates by adding a new entry without checking what was already documented. If a section already covers it, edit that section in place. Never create a parallel copy. When a rule must be visible from multiple contexts, link with `See ## Section Name` rather than copying.

**When the user asks to add a rule that's already documented, promote the existing rule** instead of re-adding it: mark it `## CRITICAL:` if it isn't, swap soft verbs (`should`, `prefer`) for hard ones (`NEVER`, `MUST`), append the concrete example the user just brought up, and move the section higher if buried.

## Paths and shortcuts

Env vars: `$PROJECTS`, `$CODE`, `$SCRIPTS`, `$AUTOMATION`, `$UTILITIES`, `$BUILDS`, `$SUCKLESS`, `$WORK`. Repos under `~/repos`, dotfiles under `~/.dotfiles` (stow-managed), QMK firmware under `~/qmk_firmware`.

Configs (alias in parens): nvim `~/.config/nvim/init.lua` (`.v`), zsh `~/.config/zsh/.zshrc` (`.z`), tmux `~/.config/tmux/tmux.conf` (`.t`), aliases `~/.config/.aliases` (`.a`), work aliases `~/.config/.aliases_work` (`.aw`), work startup `~/.config/.startup_work` (`.sw`), ansible `~/.local/share/ansible/local.yml` (`.an`).

Ansible uses role-based structure (core/auth roles, `tasks/` by category).

Shortcuts: files in `~/.config/shortcuts/sf`, dirs in `sd`. Auto-suspend via `xautolock@kanon.service`.
