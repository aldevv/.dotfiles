#!/usr/bin/env bash
# Print the path of every submodule declared optional in .gitmodules, one per line.
#
# Optional means `submodule.<name>.update = none`, which makes both
# `git submodule update` and `git clone --recurse-submodules` print
# "Skipping submodule '<path>'". An uninitialized optional submodule is a
# deliberate choice on this machine, not a fault to repair, so the sync skills
# must not delegate to the full sync or clone it on the user's behalf.
#
# $1 = repo root to inspect (default ~/.dotfiles)
set -euo pipefail

cd "${1:-$HOME/.dotfiles}"
[ -f .gitmodules ] || exit 0

# `--get-regexp` exits 1 when nothing matches, which is the normal case for a
# repo with no optional submodules, so swallow it rather than tripping set -e.
matches=$(git config -f .gitmodules --get-regexp '^submodule\..*\.update$' 2>/dev/null || true)
[ -n "$matches" ] || exit 0

# Each line is "submodule.<name>.update <value>". Resolve name -> path, since
# the two only coincide by convention and callers compare against paths.
while read -r key value; do
  [ "$value" = "none" ] || continue
  name=${key#submodule.}
  name=${name%.update}
  git config -f .gitmodules --get "submodule.${name}.path" || true
done <<<"$matches"
