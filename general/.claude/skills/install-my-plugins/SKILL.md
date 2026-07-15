---
name: install-my-plugins
description: Reinstall/refresh my dotfiles-tracked Claude Code plugins from their ~/marketplaces sources, persist via a dotfiles sync, then kill the tmux server for a clean restart. Triggers on "/install-my-plugins", "install my plugins", "reinstall my plugins", "refresh my plugins", "apply my plugin edits and restart". Force-refreshes the version-keyed plugin cache (which `claude plugin marketplace update` alone will NOT do), so local edits to a plugin source actually take effect. Do NOT use to author/edit a plugin (that's a normal file edit) — this is the apply + persist + restart step after editing.
---

# install-my-plugins

Apply my local plugin sources to the runtime, push them upstream, and restart tmux clean. Three steps, in order. Plugin mechanics live in `~/.claude/lazy/plugins.md`; my instances in `~/.claude/lazy/marketplaces.md`.

Installs every plugin under `~/marketplaces/` that is **dotfiles-tracked** (a symlink resolving into `~/.dotfiles/`). Anything under `~/marketplaces/` that is a plain directory (a standalone clone) is not part of the synced dotfiles set and is left untouched.

## Step 1. Install / force-refresh the dotfiles-tracked plugins from source

The plugin cache is keyed by version (`~/.claude/plugins/cache/<mp>/<plugin>/<version>/`), so `marketplace update` does NOT re-copy a same-version plugin. Deleting the cache dir and running `install` is what forces a fresh copy from source. For each tracked plugin: register its marketplace if it isn't known, wipe its cache, install.

```bash
set -u
MP="$HOME/marketplaces"
DOTS=$(readlink -f "$HOME/.dotfiles")
for src in "$MP"/*; do
  [ -e "$src" ] || continue
  name=$(basename "$src")
  # dotfiles-tracked = a symlink whose target lives under ~/.dotfiles
  case "$(readlink -f "$src")" in
    "$DOTS"/*) : ;;
    *) echo "skip $name (not a dotfiles-tracked marketplace)"; continue ;;
  esac
  claude plugin marketplace list 2>/dev/null | grep -q "$src" || claude plugin marketplace add "$src"
  rm -rf "$HOME/.claude/plugins/cache/$name"          # version-keyed cache won't refresh on its own
  claude plugin install "$name@$name"
done
echo "--- installed ---"
claude plugin list 2>/dev/null
```

No `/reload-plugins` needed here — Step 3 kills tmux, so the next session loads the fresh cache.

## Step 2. Sync dotfiles

Invoke the `sync-dotfiles` skill. The plugin sources refreshed above live in dotfiles, so this persists + pushes any edits (and the wiki/notes if they're dirty).

Wait for the sync to finish before Step 3.

## Step 3. Kill the tmux server

```bash
tmux kill-server 2>/dev/null || true
```

Drops ALL tmux sessions so the next one starts with the freshly-installed plugins. If you run this from inside tmux it terminates the current session too — that's the intended clean restart, so make it the last thing you do.
