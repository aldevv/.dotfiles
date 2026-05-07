---
name: sync-dotfiles
description: "Pull dotfiles, resolve any merge conflicts (keep both non-conflicting changes; keep the newest/incoming for logic conflicts), sync submodules, restow any packages that gained new files, then push with a commit message that includes the OS name and machine identifier. Metadata (id and os) is stored in ~/.machine_metadata — auto-created from hostname + /etc/os-release if missing."
---

Sync the dotfiles repo at `~/.dotfiles` and all its submodules: pull remote changes, resolve conflicts, restow packages with new files, and push with a machine-tagged commit.

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

```bash
cd ~/.dotfiles && git diff ORIG_HEAD HEAD --name-only 2>/dev/null | sed 's|/.*||' | sort -u
```

For each package directory listed:

```bash
cd ~/.dotfiles && stow -R <package>
# If conflict (regular file exists, not a symlink):
cd ~/.dotfiles && stow --adopt -R <package>
```

Report any remaining conflicts but do not abort.

---

## Step 6 — Commit and push parent

Finalize any pending merge commit and push, but skip the push if nothing's ahead:

```bash
cd ~/.dotfiles && export $(grep -v '^#' ~/.machine_metadata | xargs) && \
  { git diff --cached --quiet || git commit -m "merge: sync from remote [machine-${id}, ${os}]"; } && \
  { git commit --amend -m "sync: dotfiles update [${os}, machine-${id}]" 2>/dev/null || true; } && \
  if [ -n "$(git log @{u}..HEAD --oneline 2>/dev/null)" ]; then git push origin main; else echo "parent: nothing to push"; fi
```

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

## Step 7 — Report

- Machine ID and OS
- SSH alias status (only relevant if Step 2 fired)
- Submodules synced (init / local changes committed / nothing to push / fast-forwarded)
- Conflicts resolved (count and files)
- Packages restowed
- Final pushed commit (or "nothing to push")
