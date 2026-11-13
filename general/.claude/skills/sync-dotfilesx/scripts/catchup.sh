#!/usr/bin/env bash
# catchup.sh: fast-forward one machine's ~/.dotfiles (and its personal submodule) to origin/main
# after the other machines pushed, then link any files the fast-forward added.
# Run locally or through `mssh <machine> 'bash -s' < catchup.sh`.
# Local edits are left alone; git refuses the fast-forward only if they overlap incoming changes.
cd ~/.dotfiles || exit 1
git fetch -q origin main
pre=$(git rev-parse HEAD)
git merge -q --ff-only origin/main || {
  echo "catchup: not a fast-forward (this machine has its own commits); run a full sync on it"
  exit 4
}

# Link each new file; when its parent dir is missing in $HOME, link the highest missing ancestor
# instead, so a package folder that is a single symlink elsewhere doesn't become a partial tree.
git diff "$pre" HEAD --name-only --diff-filter=A | while IFS= read -r src; do
  pkg=${src%%/*}
  rel=${src#*/}
  [ "$pkg" = steamdeck ] && continue
  dest="$HOME/$rel"
  [ -e "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$HOME/.dotfiles/$src")" ] && continue
  top=$rel
  while [ "$(dirname "$top")" != . ] && [ ! -e "$HOME/$(dirname "$top")" ]; do top=$(dirname "$top"); done
  [ -e "$HOME/$top" ] && [ "$(readlink -f "$HOME/$top")" = "$(readlink -f "$HOME/.dotfiles/$pkg/$top")" ] && continue
  mkdir -p "$(dirname "$HOME/$top")"
  ln -sfn "$HOME/.dotfiles/$pkg/$top" "$HOME/$top"
  echo "linked $top"
done

if git -C personal rev-parse --git-dir >/dev/null 2>&1; then
  git -C personal fetch -q origin 2>/dev/null && git -C personal merge -q --ff-only "origin/$(git -C personal rev-parse --abbrev-ref HEAD)" 2>/dev/null || true
fi
echo "$(hostname -s): $(git log --oneline -1)"
