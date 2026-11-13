#!/usr/bin/env bash
# preflight.sh: read-only snapshot of one machine's ~/.dotfiles, printed as key=value lines.
# Run locally or through `mssh <machine> 'bash -s' < preflight.sh`. Fetches origin, changes nothing else.
#   machine      id from ~/.machine_metadata
#   head         short HEAD
#   behind/ahead commits vs origin/main
#   modified     tracked files changed locally (count), untracked = new files git would add
#   deleted      tracked files missing on disk (one path per deleted= line): BLOCKER
#   markers      changed files that still contain conflict markers: BLOCKER
#   sub_dirty    initialized submodules with uncommitted changes (path: short status)
#   full_sync_days  age of the last sync-dotfiles-full run
cd ~/.dotfiles || {
  echo "error=no ~/.dotfiles"
  exit 1
}
id=$(grep '^id=' ~/.machine_metadata 2>/dev/null | cut -d= -f2)
git fetch -q origin main 2>/dev/null || echo "warn=fetch failed"
echo "machine=${id:-$(hostname -s)}"
echo "head=$(git rev-parse --short HEAD)"
echo "behind=$(git rev-list --count HEAD..origin/main)"
echo "ahead=$(git rev-list --count origin/main..HEAD)"
echo "modified=$(git diff --name-only HEAD --ignore-submodules | wc -l | tr -d ' ')"
echo "untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
git ls-files --deleted | sed 's/^/deleted=/'

# Conflict markers in locally changed files (leftovers from a stash pop or an aborted merge).
{
  git diff --name-only HEAD --ignore-submodules
  git ls-files --others --exclude-standard
} | sort -u | while IFS= read -r f; do
  [ -f "$f" ] && grep -qE '^(<<<<<<<|>>>>>>>) ' "$f" && echo "markers=$f"
done

# Submodules with uncommitted work; the fast sync never enters them.
git submodule foreach --quiet 'st=$(git status --short | head -5 | tr "\n" " "); [ -n "$st" ] && echo "sub_dirty=$displaypath: $st"; true' 2>/dev/null

last=$(cat ~/.cache/sync-dotfiles/last-full-sync 2>/dev/null || echo 0)
[ "$last" = 0 ] && echo "full_sync_days=never" || echo "full_sync_days=$((($(date +%s) - last) / 86400))"
