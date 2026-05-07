---
name: sync-dotfiles
description: "Fast dotfiles sync — pulls/pushes the parent repo only and skips submodules entirely (they're almost never updated, so syncing them every run is wasted time). At least once every 30 days, or when any submodule is uninitialized (`-` prefix), this skill delegates to `sync-dotfiles-full` so submodules stay current. Resolves merge conflicts (keep both non-conflicting changes; keep newest/incoming for logic conflicts), restows packages with newly-added files, and pushes a machine-tagged commit. Metadata (id and os) is in ~/.machine_metadata; full-sync state is tracked in ~/.cache/sync-dotfiles/last-full-sync."
---

Sync the **parent** dotfiles repo at `~/.dotfiles`: pull remote changes, resolve conflicts, restow packages with new files, and push a machine-tagged commit. Submodules are intentionally **not** touched — they update rarely, and the periodic `sync-dotfiles-full` run handles them.

**Delegation contract**: at Step 1 this skill checks two conditions. If either is true, it stops and follows `~/.claude/skills/sync-dotfiles-full/SKILL.md` instead:

1. `~/.cache/sync-dotfiles/last-full-sync` is missing or older than 30 days (= a full sync is overdue).
2. Any submodule has a `-` prefix (= not initialized, fast path can't safely operate without it).

> **Important — env vars don't persist across Bash tool invocations.** Each Bash call is a fresh shell, so `export` from one call is **lost** in subsequent ones. Any later command that uses `${id}` or `${os}` must re-source the metadata inline by prefixing with:
> ```bash
> export $(grep -v '^#' ~/.machine_metadata | xargs) && ...
> ```

---

## Step 1 — Load metadata + decide fast vs. full (single call)

One bash invocation that bootstraps metadata, snapshots submodule status (cheap), and prints whether the fast path is safe:

```bash
if [ ! -f ~/.machine_metadata ] || ! grep -q '^id=' ~/.machine_metadata || ! grep -q '^os=' ~/.machine_metadata; then
  auto_id=$(hostname -s 2>/dev/null || hostname)
  auto_os=$( ( . /etc/os-release 2>/dev/null && echo "${ID:-$(uname -s)}" ) | tr '[:upper:]' '[:lower:]')
  printf "id=%s\nos=%s\n" "$auto_id" "$auto_os" > ~/.machine_metadata
  echo "created ~/.machine_metadata: id=$auto_id os=$auto_os"
fi
export $(grep -v '^#' ~/.machine_metadata | xargs) 2>/dev/null && echo "id=$id os=$os"

last=$(cat ~/.cache/sync-dotfiles/last-full-sync 2>/dev/null || echo 0)
now=$(date +%s)
age=$(( now - last ))
threshold=$(( 30*24*60*60 ))
if [ "$last" -eq 0 ]; then
  echo "full-sync: never recorded -> DELEGATE"
elif [ "$age" -ge "$threshold" ]; then
  echo "full-sync: $((age/86400)) days old (>=30) -> DELEGATE"
else
  echo "full-sync: $((age/86400)) days old (<30) -> fast path OK"
fi

echo "--- submodules ---"
sub_status=$(cd ~/.dotfiles && git submodule status)
echo "$sub_status"
if echo "$sub_status" | grep -q '^-'; then
  echo "submodule uninitialized -> DELEGATE"
fi
```

If the output contains either `-> DELEGATE` line, **stop following this skill** and follow `~/.claude/skills/sync-dotfiles-full/SKILL.md` from its Step 1. Do not continue with the steps below — the full skill handles the fast path's work too.

If `$id` or `$os` is empty after this (e.g. unwritable HOME), stop and report.

If neither delegation condition fired, continue with Step 2 below — submodules are skipped for the rest of this skill.

---

## Step 2 — Sync the parent repo

Single bash call, mirrors the parent template from `sync-dotfiles-full`'s Step 3 but stands alone (no `[PARALLEL]` block since there's only one repo to sync):

```bash
set -e
cd ~/.dotfiles
diff_files=$(git diff --name-only HEAD)
if [ -n "$diff_files" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if echo "$f" | grep -qiE '\.(env|pem|key|p12|pfx|ppk)$|^\.env(\.|$)|secret|password|credential|private_key|id_rsa|id_dsa|id_ed25519' \
       || grep -qiE 'BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9]|password\s*=\s*\S+|api[_-]?key\s*[=:]\s*[A-Za-z0-9/+]{16,}|secret\s*[=:]\s*[A-Za-z0-9/+]{16,}' "$f"; then
      echo "BLOCKED: possible secret in $f"; exit 7
    fi
  done <<< "$diff_files"
  export $(grep -v '^#' ~/.machine_metadata | xargs)
  git add -u && git commit -m "wip: local changes before sync [machine-${id}]"
fi
git pull --no-rebase origin main
```

If the pull surfaces conflicts, resolve via Rule A / Rule B from Step 3 and re-run this command (or just re-run the conflict resolution + Step 4 onward — the pull's merge state is already in place).

---

## Step 3 — Conflict resolution

Only fires when Step 2's pull surfaced conflicts.

```bash
cd ~/.dotfiles && git status --short | grep -E '^(UU|AA|DD|AU|UA|DU|UD)'
```

**Rule A — Additive/structural**: both sides added independent content → keep both, remove markers.

**Rule B — Logic conflict**: same setting changed on both sides → keep incoming (remote):

```bash
git checkout --theirs -- <file> && git add <file>
```

---

## Step 4 — Restow packages that gained new files

`ORIG_HEAD` is set by `git pull` only when something was actually merged. If absent → up-to-date pull → skip this step.

Find packages that received **newly-added** files (modified files don't need restowing — their symlink already exists):

```bash
cd ~/.dotfiles && git diff ORIG_HEAD HEAD --name-only --diff-filter=A 2>/dev/null | sed 's|/.*||' | sort -u
```

For each package directory listed, run stow then verify each new file is actually a symlink. Stow can bail with `BUG in find_stowed_path? Absolute/relative mismatch` when it walks an unrelated symlink in `$HOME` (e.g. `~/.local/state/nix/profiles/profile`) — when that happens it leaves new files unlinked, so we always verify and fall back to manual symlinking.

```bash
pkg=<package>
cd ~/.dotfiles && stow -R "$pkg" 2>&1 || true
git diff ORIG_HEAD HEAD --name-only --diff-filter=A | grep "^${pkg}/" | while IFS= read -r src; do
  rel=${src#${pkg}/}
  dest="$HOME/$rel"
  expected="$HOME/.dotfiles/$src"
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$expected")" ]; then
    continue
  fi
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$expected" "$dest"
  echo "manually linked $rel"
done
```

Report any remaining conflicts (e.g. unwritable parent dirs) but do not abort.

---

## Step 5 — Commit and push parent

Finalize any pending merge commit and push, but skip the push if nothing's ahead:

```bash
cd ~/.dotfiles && export $(grep -v '^#' ~/.machine_metadata | xargs) && \
  { git diff --cached --quiet || git commit -m "merge: sync from remote [machine-${id}, ${os}]"; } && \
  { git commit --amend -m "sync: dotfiles update [${os}, machine-${id}]" 2>/dev/null || true; } && \
  if [ -n "$(git log @{u}..HEAD --oneline 2>/dev/null)" ]; then git push origin main; else echo "parent: nothing to push"; fi
```

This skill does **not** update `~/.cache/sync-dotfiles/last-full-sync` — only `sync-dotfiles-full` does. Updating it here would defeat the monthly trigger.

---

## Secret Scan Rules (reference)

The Step 2 template inlines this scan. Reproduced here for one-off / manual use:

```bash
# 1. Suspicious filename
echo "<filename>" | grep -qiE '\.(env|pem|key|p12|pfx|ppk)$|^\.env(\.|$)|secret|password|credential|private_key|id_rsa|id_dsa|id_ed25519'

# 2. Suspicious content
grep -qiE \
  'BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9]|password\s*=\s*\S+|api[_-]?key\s*[=:]\s*[A-Za-z0-9/+]{16,}|secret\s*[=:]\s*[A-Za-z0-9/+]{16,}' \
  "<filepath>"
```

If either matches: don't stage/commit, print `BLOCKED: possible secret in <filepath>`, include in final report.

---

## Step 6 — Report

- Machine ID and OS
- Mode: fast (parent-only) — note this explicitly so the user knows submodules were skipped
- Days since last full sync
- Local changes committed / nothing to push / fast-forwarded
- Conflicts resolved (count and files)
- Packages restowed
- Final pushed commit (or "nothing to push")
