---
name: sync-dotfiles
description: "Pull dotfiles, resolve any merge conflicts (keep both non-conflicting changes; keep the newest/incoming for logic conflicts), sync submodules, restow any packages that gained new files, then push with a commit message that includes the OS name and machine identifier. Metadata (id and os) is stored in ~/.machine_metadata — if missing, prompt the user to create it."
---

Sync the dotfiles repo at `~/.dotfiles` and all its submodules: pull remote changes, resolve conflicts, restow packages with new files, and push with a machine-tagged commit.

**Parallelism rule**: wherever steps are marked **[PARALLEL]**, issue all their tool calls in a single message to run them concurrently.

---

## Step 1 — Load metadata + check SSH **[PARALLEL]**

Run both of these simultaneously:

**1a — Load machine metadata:**
```bash
export $(grep -v '^#' ~/.machine_metadata | xargs) 2>/dev/null && echo "id=$id os=$os"
```
If `$id` or `$os` is empty, stop and ask the user to create `~/.machine_metadata`:
```bash
printf "id=<number>\nos=<OS>\n" > ~/.machine_metadata
```

**1b — Check SSH alias and submodule status:**
```bash
ssh -T git@personal -o ConnectTimeout=3 2>&1 | grep -q "successfully authenticated" && echo "ssh=ok" || echo "ssh=fallback"
```
```bash
cd ~/.dotfiles && git submodule status
```

If SSH check returns `fallback`, use `git@github.com:aldevv/<repo>.git` instead of `git@personal:aldevv/<repo>.git` for all submodule operations.

Submodule prefix legend:
- `-` = not yet initialized (needs cloning)
- `+` = pointer stale (pointer needs updating after sync)
- ` ` = in sync

---

## Step 2 — Initialize any uncloned submodules **[PARALLEL if multiple]**

For each submodule with a `-` prefix, initialize it (all at once in parallel):

```bash
# personal alias works:
git -C ~/.dotfiles submodule update --init <path>

# personal alias unavailable — use insteadOf override:
git -c "url.git@github.com:aldevv/<repo>.git.insteadOf=git@personal:aldevv/<repo>.git" \
    -C ~/.dotfiles submodule update --init <path>
```

---

## Step 3 — Sync all submodules **[PARALLEL]**

For every submodule (initialized or already cloned), run all of the following steps for each submodule simultaneously — issue one set of tool calls per submodule in a single message.

For each submodule:

**3a — Ensure on a branch:**
```bash
cd ~/.dotfiles/<path>
git rev-parse --abbrev-ref HEAD
# If output is "HEAD" (detached), run:
git checkout main 2>/dev/null || git checkout master
```

**3b — Commit any local changes:**
```bash
cd ~/.dotfiles/<path>
git status --short
# If modified tracked files exist:
git add -u && git commit -m "wip: local changes before sync [machine-${id}]"
```

**3c — Pull:**
```bash
# personal alias works:
git -C ~/.dotfiles/<path> pull --no-rebase origin <branch>
# personal alias unavailable:
git -C ~/.dotfiles/<path> pull --no-rebase git@github.com:aldevv/<repo>.git <branch>
```

**3d — Push:**
```bash
# personal alias works:
git -C ~/.dotfiles/<path> push origin <branch>
# personal alias unavailable:
git -C ~/.dotfiles/<path> push git@github.com:aldevv/<repo>.git <branch>
```

Resolve any pull conflicts using Rule A / Rule B from Step 4.

After all submodules finish, stage their updated pointers in the parent:
```bash
cd ~/.dotfiles && git add <path1> <path2> <path3>
```

---

## Step 4 — Pull parent repo

Check for local changes, then pull:

```bash
cd ~/.dotfiles && git status --short
# If modified tracked files:
git add -u && git commit -m "wip: local changes before sync [machine-${id}]"

git pull --no-rebase origin main
```

### Conflict resolution rules

```bash
git status --short | grep -E '^(UU|AA|DD|AU|UA|DU|UD)'
```

**Rule A — Additive/structural**: both sides added independent content → keep both, remove markers.

**Rule B — Logic conflict**: same setting changed on both sides → keep incoming (remote):
```bash
git checkout --theirs -- <file> && git add <file>
```

---

## Step 5 — Restow packages that gained new files

`ORIG_HEAD` is set by git during a pull. If it exists, find changed packages and restow:

```bash
cd ~/.dotfiles
git diff ORIG_HEAD HEAD --name-only 2>/dev/null | sed 's|/.*||' | sort -u
```

If `ORIG_HEAD` doesn't exist (already up to date), skip this step.

For each package directory listed:
```bash
cd ~/.dotfiles && stow -R <package>
# If conflict (regular file exists, not a symlink):
cd ~/.dotfiles && stow --adopt -R <package>
```

Report any remaining conflicts but do not abort.

---

## Step 6 — Commit and push

Finalize any pending merge commit, then push:

```bash
cd ~/.dotfiles
git diff --cached --quiet || git commit -m "merge: sync from remote [machine-${id}, ${os}]"
git commit --amend -m "sync: dotfiles update [${os}, machine-${id}]" 2>/dev/null || true
git push origin main
```

---

## Step 7 — Report

- Machine ID and OS
- SSH alias status (ok / fallback)
- Submodules synced (which needed init, which had local changes, which were already up to date)
- Conflicts resolved (count and files)
- Packages restowed
- Final pushed commit
