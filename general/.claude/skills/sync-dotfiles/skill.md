---
name: sync-dotfiles
description: "Pull dotfiles, resolve any merge conflicts (keep both non-conflicting changes; keep the newest/incoming for logic conflicts), then push with a commit message that includes the OS name and machine identifier. The machine ID is stored in ~/.machine_id — if missing, prompt the user to create it."
---

Sync the dotfiles repo at `~/.dotfiles`: pull remote changes, resolve conflicts, and push with a machine-tagged commit.

## Step 1 — Check for machine ID

Check whether `~/.machine_id` exists and contains a valid number:

```bash
cat ~/.machine_id 2>/dev/null
```

If the file is missing or empty, **stop and ask the user** to provide their machine identifier number, then write it:

```bash
echo "<number>" > ~/.machine_id
```

Do not proceed until the ID is confirmed.

## Step 2 — Detect OS

```bash
uname -s   # Darwin → macOS, Linux → Linux
```

Map the result to a friendly name:
- `Darwin` → `macOS`
- `Linux` → `Linux`

## Step 3 — Stage any uncommitted local changes

Before pulling, make sure there are no untracked or modified files left unstaged that could cause issues. Check with:

```bash
cd ~/.dotfiles && git status --short
```

If there are **unstaged modifications**, stage and commit them first so the pull can merge cleanly:

```bash
cd ~/.dotfiles
git add -A
git commit -m "wip: local changes before sync [machine-<ID>]"
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

## Step 5 — Commit the merge (if a merge commit is needed)

If git left a pending merge commit, finalize it:

```bash
git diff --cached --quiet || git commit -m "merge: sync from remote [machine-<ID>, <OS>]"
```

## Step 6 — Push with a tagged commit message

Push the result. The final push should include (or be preceded by) a descriptive commit if there were local changes beyond the merge:

```bash
cd ~/.dotfiles
git push origin main
```

The commit message format must be:
```
sync: dotfiles update [<OS>, machine-<ID>]
```

Example: `sync: dotfiles update [macOS, machine-3]`

If no new commit is needed (the only new commit is the merge itself), amend its message to follow this format:

```bash
git commit --amend -m "sync: dotfiles update [<OS>, machine-<ID>]"
```

## Step 7 — Report

Print a summary of what was done:
- Machine ID and OS used
- Whether any conflicts were resolved (and how many)
- Final git log of the last commit pushed
