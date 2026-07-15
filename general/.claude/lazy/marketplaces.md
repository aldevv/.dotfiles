# Marketplaces (~/marketplaces) — my plugin instances

`~/marketplaces/` is the home for my Claude Code plugin marketplaces. Each subdir is a single-plugin marketplace. This file is the instance layout; the general plugin mechanism (anatomy, dependencies, source-vs-cache, the version-keyed cache gotcha, the CLI, applying + verifying a change, `${CLAUDE_PLUGIN_ROOT}`) lives in [`plugins.md`](plugins.md).

## Layout

- **`~/marketplaces/auto-new-day/`** — generic morning-triage engine. A **symlink** into dotfiles (`~/.dotfiles/general/marketplaces/auto-new-day`), so edits are tracked + synced. Marketplace name `auto-new-day`, plugin `auto-new-day` (skills: `new-day` engine, `impl` generic worker, `fix-bug`, `pr-code-review`). Ships the sweep/dispatch scripts, systemd templates, and a built-in GitHub `default.json` profile.
- A **private domain pack** can layer on top: its own single-plugin marketplace that declares `dependencies: ["auto-new-day@auto-new-day"]` and ships only its profile + specialized skills. Such a pack lives directly under `~/marketplaces/` (a git clone, not a dotfiles symlink, since it can't go in public dotfiles). Keep its project-specific operational notes out of this global file — they belong in that project's own scope.

## auto-new-day generics (the sweep)

- Engine skill is `/auto-new-day:new-day`; `/auto-new-day` (a stowed personal launcher skill) delegates to it. A domain pack ships its own `<pack>:new-day` entrypoint that pins its profile then calls the engine.
- Active dispatch profile: `~/.config/auto-new-day/profile.json`. With no profile written, the engine falls back to its built-in GitHub `profiles/default.json`.
- Default sweep state (no profile `state_dir`): `~/.local/state/auto-new-day/`.
- The generic engine reads `$HOME/CLAUDE.md` + `~/.claude/lazy/*.md` explicitly in its skill bodies (`new-day` "Project memory", `impl` Step 0); see the memory note in [`plugins.md`](plugins.md).
- systemd unit: install via the engine launcher's `--install` (`~/marketplaces/auto-new-day/scripts/launch-auto-new-day.sh --install`); `AUTO_NEW_DAY_LAUNCHER` overrides the `ExecStart` and `AUTO_NEW_DAY_SLASH` overrides which slash-command it runs, so a domain pack can point the timer at its own wrapper + entrypoint. Generic unit templates: `~/marketplaces/auto-new-day/references/systemd/`.
