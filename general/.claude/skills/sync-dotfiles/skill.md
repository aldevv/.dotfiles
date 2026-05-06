---
name: sync-dotfiles
description: "Pull dotfiles, resolve any merge conflicts (keep both non-conflicting changes; keep the newest/incoming for logic conflicts), then push with a commit message that includes the OS name and machine identifier. Metadata (id and os) is stored in ~/.machine_metadata — if missing, prompt the user to create it."
---

Sync the dotfiles repo at `~/.dotfiles`: pull remote changes, resolve conflicts, and push with a machine-tagged commit.

## Step 1 — Load machine metadata

Read `~/.machine_metadata`:

```bash
source ~/.machine_metadata 2>/dev/null
```

This sets `$id` and `$os`. If the file is missing or either value is empty, **stop and ask the user** to provide them, then write the file:

```bash
printf "id=<number>\nos=<OS>\n" > ~/.machine_metadata
```

Do not proceed until both values are confirmed.

## Step 2 — Stage any uncommitted local changes

Before pulling, check for modified tracked files:

```bash
cd ~/.dotfiles && git status --short
```

If there are **unstaged modifications** (lines starting with ` M`, `M `, etc.), stage and commit only the tracked modified files so the pull can merge cleanly:

```bash
cd ~/.dotfiles
git add -u
git commit -m "wip: local changes before sync [machine-${id}]"
```

Skip this commit step if the working tree is already clean.

## Step 3 — Pull with merge strategy

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

## Step 4 — Commit the merge (if a merge commit is needed)

If git left a pending merge commit, finalize it:

```bash
git diff --cached --quiet || git commit -m "merge: sync from remote [machine-${id}, ${os}]"
```

## Step 5 — Push with a tagged commit message

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

## Step 6 — Report

Print a summary of what was done:
- Machine ID and OS used
- Whether any conflicts were resolved (and how many)
- Final git log of the last commit pushed
