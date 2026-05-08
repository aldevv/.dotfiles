# Dotfiles

GNU Stow-managed dotfiles. Each top-level **directory** is a stow package whose contents are symlinked into `$HOME` when stowed. Top-level **shell scripts** (e.g. `install`, `linux`, `linux_work`) are bootstrap/setup scripts, not packages.

## Packages

- `general` — cross-platform configs (`.config/`, `.gitconfig`, `.xscreensaver`, `.Xmodmap`, `.claude/skills/`)
- `nvim` — Neovim config
- `zsh` — Zsh config
- `scripts` — `~/.local/share/scripts/` (note: `.local/share` and `.local/state` are gitignored at the repo root, but tracked files inside `scripts/` are kept)
- `personal` — personal-only configs
- `epic` — Epic-specific config
- `wiki` — wiki package
- `xprofile`, `minimal-xprofile` — alternate `.xprofile` setups (stow only one)

## Stow workflow

```bash
cd ~/.dotfiles && stow <package>      # link a package into $HOME
cd ~/.dotfiles && stow -R <package>   # restow (refresh links after files added/removed)
cd ~/.dotfiles && stow -D <package>   # unstow
```

When adding new files to a package, **restow** that package so the new files get linked. The `sync-dotfiles` skill (`general/.claude/skills/sync-dotfiles/`) does this automatically after pulling — detects newly-added files per package and runs `stow -R` for each.

## Stow conflicts

If `stow` errors with `existing target is neither a link nor a directory`, the target in `$HOME` is a real file (often because an app rewrote it in place — e.g. `xscreensaver-settings` rewrites `~/.xscreensaver`).

Do **not** auto-adopt or overwrite. Ask the user which side wins:
- Local newer / wanted: copy `~/.<file>` into the package, delete the real file, restow.
- Repo wins: delete the local real file, restow.

To unblock other files in the package while resolving, pass `--ignore='<basename>$'`.

## Commits & syncing

- Personal push: run `personal-push-all` (alias `dgpA`) — commits and pushes `~/.dotfiles`, `~/notes`, `~/wiki`, `~/.local/share/ansible`.
- Cross-machine sync: invoke the `sync-dotfiles` skill — pulls, resolves conflicts, restows packages with new files, pushes a `sync: dotfiles update [<os>, machine-<id>]` commit.
- **Never** mention Claude or add `Co-Authored-By: Claude` in commits or PR descriptions.

## Repo-level gitignore

Under `scripts/.local/`, only `share/scripts/` is tracked. Everything else (`state/`, `bin/`, `lib/`, `builds/`, `share/*` except `share/scripts/`) is gitignored so that tools writing into `~/.local/` via the stow symlinks don't pollute the repo. Files inside ignored paths that are already tracked still work, but `git add` of a new file there needs `-f`.

## Stow --no-folding for the scripts package

The `scripts` package must be stowed with `stow --no-folding scripts` (not plain `stow scripts`). Without `--no-folding`, stow collapses `~/.local` into a single symlink pointing at `~/.dotfiles/scripts/.local/`, which causes every tool that writes to `~/.local/` (fnm, claude CLI, ranger, nvim, go, direnv, ansible, bob, certs, node_modules, etc.) to pollute the dotfiles repo. With `--no-folding`, `~/.local` stays a real directory and only leaf files under `share/scripts/` are symlinked.

If you see leaked directories show up under `scripts/.local/share/` or `scripts/.local/lib/`, re-stow: `stow -D scripts && stow --no-folding scripts`.
