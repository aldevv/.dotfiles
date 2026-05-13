---
name: sync-dotfiles-full
description: "Full dotfiles sync including all submodules. Pulls remote changes for the parent repo and every submodule, resolves conflicts (keep both non-conflicting changes; keep the newest/incoming for logic conflicts), restows packages with new files, then pushes a machine-tagged commit. Records the run timestamp in ~/.cache/sync-dotfiles/last-full-sync so the fast `sync-dotfiles` skill can tell when a monthly full sync is due. Trigger when the user runs /sync-dotfiles-full, asks for a full sync, or has not run a full sync in 30+ days. Metadata (id and os) is stored in ~/.machine_metadata — auto-created from hostname + /etc/os-release if missing."
---

Full sync of `~/.dotfiles` and **all** its submodules: pull remote changes, resolve conflicts, restow packages with new files, push a machine-tagged commit, then record the timestamp so the fast `sync-dotfiles` skill knows when the next full sync is due.

**Use this skill when**: the user runs `/sync-dotfiles-full`, the fast `sync-dotfiles` skill delegated here (stale state file or uninitialized submodule), or the user explicitly asks for a "full" sync.

**Parallelism rule**: wherever steps are marked **[PARALLEL]**, issue all their tool calls in a single message to run them concurrently. Within a single bash invocation, chain inspection commands with `;` or `&&` to avoid extra tool-call overhead.

> **Important — env vars don't persist across Bash tool invocations.** Each Bash call is a fresh shell, so `export` from one call is **lost** in subsequent ones. Any later command that uses `${id}` or `${os}` (the wip/merge/amend commit messages in Steps 3, 4, 6) **must** re-source the metadata inline by prefixing with:
> ```bash
> export $(grep -v '^#' ~/.machine_metadata | xargs) && ...
> ```

---

## Step 1 — Load metadata + inspect submodules (single call)

One bash invocation, no upfront SSH check (it's deferred to Step 2 where it's actually needed):

```bash
if [ ! -f ~/.machine_metadata ] || ! grep -q '^id=' ~/.machine_metadata || ! grep -q '^os=' ~/.machine_metadata; then
  auto_id=$(hostname -s 2>/dev/null || hostname)
  auto_os=$( ( . /etc/os-release 2>/dev/null && echo "${ID:-$(uname -s)}" ) | tr '[:upper:]' '[:lower:]')
  printf "id=%s\nos=%s\n" "$auto_id" "$auto_os" > ~/.machine_metadata
  echo "created ~/.machine_metadata: id=$auto_id os=$auto_os"
fi
export $(grep -v '^#' ~/.machine_metadata | xargs) 2>/dev/null && echo "id=$id os=$os"
echo "--- submodules ---"
cd ~/.dotfiles && git submodule status
```

If `$id` or `$os` is empty after this (e.g. unwritable HOME), stop and report.

Submodule prefix legend:
- `-` = not yet initialized (needs cloning) — Step 2 fires
- `+` = pointer stale (pointer needs updating after sync)
- ` ` = in sync

---

## Step 2 — Initialize any uncloned submodules **[PARALLEL if multiple]**

**Skip this step entirely if no submodules have a `-` prefix** — it's the common case and pure waste otherwise. The SSH alias check below is the single biggest time-sink in the skill (≥3s timeout) and only matters here.

If any `-` was reported, run the SSH alias check:

```bash
ssh -T git@personal -o ConnectTimeout=3 2>&1 | grep -q "successfully authenticated" && echo "ssh=ok" || echo "ssh=fallback"
```

For each submodule with a `-` prefix, initialize it (all at once in parallel):

```bash
# personal alias works:
git -C ~/.dotfiles submodule update --init <path>

# personal alias unavailable — use insteadOf override:
git -c "url.git@github.com:aldevv/<repo>.git.insteadOf=git@personal:aldevv/<repo>.git" \
    -C ~/.dotfiles submodule update --init <path>
```

---

## Step 3 — Sync all submodules + parent in parallel **[PARALLEL]**

Run **one bash call per repo** (each submodule **and** the parent) in a single message. Each call is a self-contained pipeline that:

1. ensures we're on a branch,
2. checks for local changes,
3. fast-paths empty diff (skip secret scan and commit),
4. otherwise scans for secrets, commits if clean,
5. pulls,
6. pushes only if `@{u}..HEAD` is non-empty.

**Per-submodule template** (replace `<path>` with the submodule path; the script auto-detects the branch):

```bash
set -e
cd ~/.dotfiles/<path>
branch=$(git rev-parse --abbrev-ref HEAD)
[ "$branch" = "HEAD" ] && { git checkout main 2>/dev/null || git checkout master; branch=$(git rev-parse --abbrev-ref HEAD); }
diff_files=$(git diff --name-only HEAD)
if [ -n "$diff_files" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if echo "$f" | grep -qiE '\.(env|pem|key|p12|pfx|ppk)$|^\.env(\.|$)|secret|password|credential|private_key|id_rsa|id_dsa|id_ed25519' \
       || grep -qiE 'BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9]|password\s*=\s*\S+|api[_-]?key\s*[=:]\s*[A-Za-z0-9/+]{16,}|secret\s*[=:]\s*[A-Za-z0-9/+]{16,}' "$f"; then
      echo "BLOCKED: possible secret in <path>/$f"; exit 7
    fi
  done <<< "$diff_files"
  export $(grep -v '^#' ~/.machine_metadata | xargs)
  git add -u && git commit -m "wip: local changes before sync [machine-${id}]"
fi
git pull --no-rebase origin "$branch"
if [ -n "$(git log @{u}..HEAD --oneline 2>/dev/null)" ]; then
  git push origin "$branch"
else
  echo "<path>: nothing to push"
fi
```

**Parent template** (run in the same message as the submodules):

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

(Parent push happens in Step 6 after pointer staging and possible merge commit.)

If a pull surfaces conflicts, resolve via Rule A / Rule B from Step 4 and re-run Step 3 for the affected repo.

After all parallel calls finish, stage updated submodule pointers in the parent (idempotent — no-op when already aligned):

```bash
cd ~/.dotfiles && git add <path1> <path2> <path3>
```

---

## Step 4 — Conflict resolution

Only fires when a Step 3 pull surfaced conflicts.

```bash
cd ~/.dotfiles && git status --short | grep -E '^(UU|AA|DD|AU|UA|DU|UD)'
```

**Rule A — Additive/structural**: both sides added independent content → keep both, remove markers.

**Rule B — Logic conflict**: same setting changed on both sides → keep incoming (remote):

```bash
git checkout --theirs -- <file> && git add <file>
```

---

## Step 5 — Restow packages that gained new files

`ORIG_HEAD` is set by `git pull` only when something was actually merged. If absent → up-to-date pull → skip Step 5.

Find packages that received **newly-added** files (modified files don't need restowing — their symlink already exists):

```bash
cd ~/.dotfiles && git diff ORIG_HEAD HEAD --name-only --diff-filter=A 2>/dev/null | sed 's|/.*||' | sort -u
```

For each package directory listed, run stow then verify each new file is actually a symlink. Stow can bail with `BUG in find_stowed_path? Absolute/relative mismatch` when it walks an unrelated symlink in `$HOME` (e.g. `~/.local/state/nix/profiles/profile`) — when that happens it leaves new files unlinked, so we always verify and fall back to manual symlinking. This is idempotent and cheap.

```bash
pkg=<package>
cd ~/.dotfiles && stow -R "$pkg" 2>&1 || true
# Verify + fix each newly-added file from the pull. Ignore the stow exit
# code: success is "every new file is a symlink to the dotfiles source".
git diff ORIG_HEAD HEAD --name-only --diff-filter=A | grep "^${pkg}/" | while IFS= read -r src; do
  rel=${src#${pkg}/}
  dest="$HOME/$rel"
  expected="$HOME/.dotfiles/$src"
  # Skip when $dest already resolves to $expected — covers both leaf-symlink and
  # parent-symlink cases (e.g. ~/.local/share/scripts is itself a symlink into the
  # repo, so its children are real files but already reachable at the right path).
  # Using -L here would miss the parent-symlink case and our `rm -rf` would
  # recurse through the parent symlink and delete the real file in the repo.
  if [ -e "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$expected")" ]; then
    continue
  fi
  # Wrong state: real file/dir, dangling link, or missing. Replace with a symlink.
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$expected" "$dest"
  echo "manually linked $rel"
done
```

Report any remaining conflicts (e.g. unwritable parent dirs) but do not abort.

---

## Step 6 — Commit and push parent

Finalize any pending merge commit and push, but skip the push if nothing's ahead:

```bash
cd ~/.dotfiles && export $(grep -v '^#' ~/.machine_metadata | xargs) && \
  { git diff --cached --quiet || git commit -m "merge: sync from remote [machine-${id}, ${os}]"; } && \
  # Only rename the head commit if THIS run just made it (wip:/merge:). On a
  # clean fast-forward with no local changes, HEAD is the upstream tip; amending
  # it would rewrite the upstream commit's message and produce a non-FF push.
  case "$(git log -1 --format=%s)" in
    "wip: "*|"merge: "*) git commit --amend -m "sync: dotfiles update [${os}, machine-${id}]" ;;
  esac && \
  if [ -n "$(git log @{u}..HEAD --oneline 2>/dev/null)" ]; then git push origin main; else echo "parent: nothing to push"; fi
```

---

## Step 7 — Record full-sync timestamp

Always run, regardless of whether anything was pushed. The fast `sync-dotfiles` skill reads this file to decide when the next monthly full sync is due, so it must be updated on every successful full run.

```bash
mkdir -p ~/.cache/sync-dotfiles && date +%s > ~/.cache/sync-dotfiles/last-full-sync && echo "recorded full-sync timestamp: $(date -d @$(cat ~/.cache/sync-dotfiles/last-full-sync))"
```

If a hard failure occurred earlier (e.g. secret scan blocked, unresolved conflict), **skip this step** — the next `sync-dotfiles` invocation should still treat the full sync as overdue.

---

## Secret Scan Rules (reference)

The Step 3 templates inline this scan. Reproduced here for one-off / manual use:

```bash
# 1. Suspicious filename
echo "<filename>" | grep -qiE '\.(env|pem|key|p12|pfx|ppk)$|^\.env(\.|$)|secret|password|credential|private_key|id_rsa|id_dsa|id_ed25519'

# 2. Suspicious content
grep -qiE \
  'BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9]|password\s*=\s*\S+|api[_-]?key\s*[=:]\s*[A-Za-z0-9/+]{16,}|secret\s*[=:]\s*[A-Za-z0-9/+]{16,}' \
  "<filepath>"
```

If either matches: don't stage/commit, print `BLOCKED: possible secret in <filepath>`, continue with other repos, include in final report.

---

## Step 8 — Report

- Machine ID and OS
- SSH alias status (only relevant if Step 2 fired)
- Submodules synced (init / local changes committed / nothing to push / fast-forwarded)
- Conflicts resolved (count and files)
- Packages restowed
- Final pushed commit (or "nothing to push")
- Full-sync timestamp recorded (or skipped due to failure)
