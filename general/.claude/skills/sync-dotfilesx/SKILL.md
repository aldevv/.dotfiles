---
name: sync-dotfilesx
description: Sync ~/.dotfiles across all my machines (titan, elite, mac) in one run, in a safe order, so every machine ends on the same commit. Preflights every machine first (deletions, leftover conflict markers, dirty submodules, how far behind), picks the order, runs the sync-dotfiles skill on each over SSH, then fast-forwards the machines that synced early. Triggers on "/sync-dotfilesx", "sync dotfiles on all machines", "sync my dotfiles everywhere", "run sync-dotfiles in all 3". For one machine only, use sync-dotfiles.
argument-hint: '[machines to include, default: titan elite mac]'
---

# sync-dotfilesx

Runs `sync-dotfiles` on every machine, sequentially, then converges them. All remote work goes
through `mssh` from the `machines-ops` skill (`~/.claude/skills/machines-ops/scripts/mssh`),
never hand-built ssh lines. `S=~/.claude/skills/sync-dotfilesx/scripts`.

## Step 1: Preflight every machine (read-only)

Run `$S/preflight.sh` on each machine (this one directly, the others with
`mssh <m> 'bash -s' < $S/preflight.sh`) and show one row per machine: head, behind, ahead,
modified, untracked, deleted, markers, sub_dirty, full_sync_days. Unreachable machine: report it
and leave it out of the run.

**Blockers. Stop and ask before syncing that machine**, because the sync would push them to
every machine:
- `deleted=` lines: tracked files missing on disk. Committing them deletes them everywhere.
  Offer: restore them (`git ls-files --deleted -z | xargs -0 git checkout HEAD --`), sync as-is,
  or skip the machine.
- `sub_dirty=` you can't explain. If it's a file you yourself checked out there earlier in this
  session (e.g. a single file pulled into `personal` ahead of the sync), clean it (`git reset -q
  -- <file> && rm <file>`) and say so; the catch-up pass brings it back properly. Anything else
  goes to the user: the fast sync would delegate to `sync-dotfiles-full` there.

Not blockers, fix in place and say so:
- `markers=` files: leftover conflict markers from a stash pop or old merge. The sync's
  pre-commit scan refuses them. Resolve with sync-dotfiles' Rule A (append-only logs and examples
  files: keep both sides, drop the stale duplicate) or Rule B (generated files: keep incoming).

## Step 2: Pick the order

1. Machines with local changes (`modified`, `untracked`, or `ahead` > 0) go first, so their
   edits reach origin before anyone pulls. Among them, the one with the fewest `behind`
   first (fewest merge conflicts), ties broken by most local changes.
2. Machines with nothing local go last; for them the sync is just a pull.

State the order and why in one line, then run it. No confirmation needed unless Step 1 hit a
blocker.

## Step 3: Sync each machine, in order

Follow `~/.claude/skills/sync-dotfiles/SKILL.md` exactly, once per machine. On this machine run
its bash blocks directly. On a remote machine run each block as a script:
`mssh <m> 'bash -s' <<'EOF' ... EOF` (the remote login shell is zsh; `bash -s` keeps the
skill's bash intact). Its routing (exit 7/8/9, DELEGATE, STOP) applies per machine as written,
including conflict resolution in the same turn. A STOP or a genuinely ambiguous conflict pauses
that machine only; report it and continue with the next.

Remote Step 4 (restow) gotcha: the skill's fallback linker creates real directories for missing
parents. If the package folder is linked as a whole on other machines (check
`ls -la ~/marketplaces` etc.), link the top missing ancestor instead; `catchup.sh` does this.

After the parent sync on each machine, fast-forward its `personal` submodule too
(`git -C ~/.dotfiles/personal merge --ff-only origin/main`); the fast skill never enters
submodules, so without this the next sync sees pointer drift.

## Step 4: Catch-up pass

Machines synced early are now behind the later pushes. Run `$S/catchup.sh` on every machine
except the last one synced (it fast-forwards, links new files, updates `personal`). Then print
each machine's `git -C ~/.dotfiles rev-parse --short HEAD`; they must all match. A leftover
`nvim/.config/nvim/lazy-lock.json` edit is normal (sync-dotfiles Step 5c adds entries that the
next sync commits).

## Step 5: Report

One table: machine, order, path taken (happy / conflict / restow / delegated / skipped), what
was committed, conflicts resolved, final HEAD. Then list anything you fixed in Step 1 and any
machine that needs the user.

## Gotchas

- The Bash tool's shell is zsh: `$list` doesn't split (use `xargs` or `bash -s`), and
  `${pipestatus[1]}` not `${PIPESTATUS[0]}` for the remote exit code after a pipe.
- `pkill -f <pattern>` over mssh matches the remote shell's own command line and kills it;
  anchor the pattern (`^...`).
