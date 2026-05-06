---
name: sync-dotfiles
description: "Pull dotfiles, resolve any merge conflicts (keep both non-conflicting changes; keep the newest/incoming for logic conflicts), sync submodules, restow any packages that gained new files, then push with a commit message that includes the OS name and machine identifier. Metadata (id and os) is stored in ~/.machine_metadata — if missing, prompt the user to create it."
---

Sync the dotfiles repo at `~/.dotfiles` and all its submodules: pull remote changes, resolve conflicts, restow packages with new files, and push with a machine-tagged commit.

## Step 1 — Load machine metadata

Read `~/.machine_metadata` and export the values so they persist across all subsequent commands:

```bash
export $(grep -v '^#' ~/.machine_metadata | xargs) 2>/dev/null
```

This sets and exports `$id` and `$os`. If the file is missing or either value is empty, **stop and ask the user** to provide them, then write the file:

```bash
printf "id=<number>\nos=<OS>\n" > ~/.machine_metadata
```

Do not proceed until both values are confirmed.

## Step 2 — Sync submodules

For each submodule defined in `~/.dotfiles/.gitmodules`, sync it independently before touching the parent repo. Run:

```bash
cd ~/.dotfiles && git submodule status
```

For each submodule path listed, note the prefix:
- `-` = not yet initialized (needs cloning)
- `+` = initialized but parent repo's recorded commit pointer is stale (needs pointer update after sync)
- ` ` = in sync

### 2a — Resolve SSH alias

The submodule URLs use a `personal` SSH alias (e.g. `git@personal:aldevv/wiki.git`). Check if it resolves:

```bash
ssh -T git@personal -o ConnectTimeout=3 2>&1 | grep -q "successfully authenticated"
```

If it fails, derive the fallback GitHub URL by replacing `git@personal:` with `git@github.com:`. Use this fallback URL for all git operations on that submodule for the rest of this session.

### 2b — Initialize if needed

If the submodule shows a leading `-` (not yet cloned), initialize it:

```bash
# If 'personal' alias works:
git -C ~/.dotfiles submodule update --init <path>

# If 'personal' alias doesn't work, use insteadOf override:
git -c "url.git@github.com:aldevv/<repo>.git.insteadOf=git@personal:aldevv/<repo>.git" \
    -C ~/.dotfiles submodule update --init <path>
```

### 2c — Ensure on a branch (not detached HEAD)

```bash
cd ~/.dotfiles/<submodule-path>
git rev-parse --abbrev-ref HEAD   # returns "HEAD" if detached
```

If detached, check out the default branch:

```bash
# Try main first, then master
git checkout main 2>/dev/null || git checkout master
```

### 2d — Stage and commit any local changes

```bash
cd ~/.dotfiles/<submodule-path>
git status --short
```

If there are modified tracked files, commit them:

```bash
git add -u
git commit -m "wip: local changes before sync [machine-${id}]"
```

### 2e — Pull remote changes

```bash
git pull --no-rebase origin <branch>
```

If the pull fails due to the `personal` SSH alias, use the fallback URL:

```bash
git pull --no-rebase git@github.com:aldevv/<repo>.git <branch>
```

Resolve any conflicts using the same rules as Step 3 below.

### 2f — Push submodule changes

```bash
git push origin <branch>
```

If push fails due to SSH alias, push to the fallback URL:

```bash
git push git@github.com:aldevv/<repo>.git <branch>
```

### 2g — Update the submodule pointer in the parent repo

After syncing each submodule, stage the updated pointer:

```bash
cd ~/.dotfiles
git add <submodule-path>
```

## Step 3 — Stage any uncommitted local changes in parent repo

After submodule syncs, check for modified tracked files in the parent:

```bash
cd ~/.dotfiles && git status --short
```

If there are **unstaged modifications** (lines starting with ` M`, `M `, etc.), stage and commit:

```bash
cd ~/.dotfiles
git add -u
git commit -m "wip: local changes before sync [machine-${id}]"
```

Skip this commit step if the working tree is already clean.

## Step 4 — Pull with merge strategy

Fetch and merge remote changes, preferring to keep both sides:

```bash
cd ~/.dotfiles && git pull --no-rebase origin main
```

### Conflict resolution rules

After the pull, check for conflicts:

```bash
git status --short | grep -E '^(UU|AA|DD|AU|UA|DU|UD)'
```

For each conflicted file, open its content and apply the following rules:

**Rule A — Non-logic conflicts (additive/structural)**
If both sides added independent content (e.g. alias additions, plugin list additions, different config keys), **keep both**. Remove the conflict markers and include all content from both sides.

**Rule B — Logic conflicts (same code path or option changed on both sides)**
If both sides modified the same logical setting or code path, **keep the incoming (remote) version** — it is treated as the newest. Use:

```bash
git checkout --theirs -- <file>
git add <file>
```

After resolving all conflicts, stage them:

```bash
git add -A
```

## Step 5 — Restow packages that gained new files

After pulling, `ORIG_HEAD` points to where HEAD was before the pull. Use it to find every package that changed (covers all commits pulled, not just the last one):

```bash
cd ~/.dotfiles
git diff ORIG_HEAD HEAD --name-only 2>/dev/null | sed 's|/.*||' | sort -u
```

If `ORIG_HEAD` doesn't exist (no pull was needed), skip this step.

For each package directory returned that exists in `~/.dotfiles`, restow it:

```bash
cd ~/.dotfiles && stow -R <package>
```

If stow reports a conflict because a target file exists as a regular file (not a symlink), re-run with `--adopt` to take ownership of it:

```bash
cd ~/.dotfiles && stow --adopt -R <package>
```

Report any remaining conflicts but do not abort.

## Step 7 — Commit the merge (if a merge commit is needed)

If git left a pending merge commit, finalize it:

```bash
git diff --cached --quiet || git commit -m "merge: sync from remote [machine-${id}, ${os}]"
```

## Step 8 — Push with a tagged commit message

The commit message format must be:
```
sync: dotfiles update [<os>, machine-<id>]
```

Example: `sync: dotfiles update [macOS, machine-3]`

If the only new commit is the wip or merge commit, amend it:

```bash
git commit --amend -m "sync: dotfiles update [${os}, machine-${id}]"
```

Then push:

```bash
cd ~/.dotfiles && git push origin main
```

## Step 9 — Report

Print a summary of what was done:
- Machine ID and OS used
- Which submodules were synced (and whether any needed initialization or fallback URLs)
- Whether any conflicts were resolved in parent or submodules (and how many)
- Final git log of the last commit pushed
