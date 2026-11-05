#!/usr/bin/env bash
# Check out every lazy.nvim plugin at the commit pinned in lazy-lock.json,
# but only when the lockfile changed since the last restore on this machine.
# Pulling a new lockfile does not move installed plugins on its own, so
# without this each machine keeps running whatever versions it last installed.
#
# Exits 0 on success or skip, 1 if the headless restore failed.

set -euo pipefail

LOCK="${HOME}/.config/nvim/lazy-lock.json"
CACHE="${HOME}/.cache/sync-dotfiles/lazy-lock-restored.sha"

if ! command -v nvim >/dev/null 2>&1 || [ ! -f "$LOCK" ]; then
	echo "restore-nvim-plugins: nvim or lockfile missing, skipping"
	exit 0
fi

if [ "$(git hash-object "$LOCK")" = "$(cat "$CACHE" 2>/dev/null)" ]; then
	echo "restore-nvim-plugins: lockfile unchanged since last restore, skipping"
	exit 0
fi

if ! nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1; then
	echo "restore-nvim-plugins: Lazy restore failed, run :Lazy restore inside nvim to see why"
	exit 1
fi

# Hash after the restore: lazy rewrites the lockfile when it records plugins
# that were installed but not yet pinned.
mkdir -p "$(dirname "$CACHE")"
git hash-object "$LOCK" >"$CACHE"
echo "restore-nvim-plugins: plugins restored to lockfile"
