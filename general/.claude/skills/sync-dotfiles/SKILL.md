---
name: sync-dotfiles
description: "Fast dotfiles sync — pulls/pushes the parent repo only and skips submodules entirely (they're almost never updated, so syncing them every run is wasted time). At least once every 30 days, or when any submodule is uninitialized (`-` prefix), this skill delegates to `sync-dotfiles-full` so submodules stay current. Resolves merge conflicts (keep both non-conflicting changes; keep newest/incoming for logic conflicts), restows packages with newly-added files, and pushes a machine-tagged commit. After the git sync, applies `~/.claude/my-settings.json` as a managed overlay onto `~/.claude/settings.json` (Step 5b): added/changed entries flow in, removed entries are stripped from settings (only when the live value still matches what was previously applied, so manual edits in settings.json are preserved). Metadata (id and os) is in ~/.machine_metadata; full-sync state is tracked in ~/.cache/sync-dotfiles/last-full-sync; the my-settings overlay state is at ~/.cache/sync-dotfiles/my-settings-applied.json."
---

> **Thinking budget: none on the happy path — just execute.** The happy path is two deterministic tool-call rounds. Don't reason about strategy, don't evaluate alternatives, don't re-derive the flow — run the steps verbatim.
>
> **Exception — think hard on merge conflicts, but never pause the turn.** If Step 2 exits 8 (merge conflict) or Step 4 reports an unresolved conflict, think harder while picking Rule A vs Rule B per file. Thinking is internal: do NOT end the turn after announcing the rule. Listing, deciding, and running the resolution command happen in the SAME response. The only legitimate pause is the "genuinely ambiguous" case defined in Step 3, and even then state the reason and proceed to ask — don't pause silently. Return to zero thinking once every conflict is staged.

Sync the **parent** dotfiles repo at `~/.dotfiles`: pull remote changes, resolve conflicts, restow packages with new files, and push a machine-tagged commit. Submodules are intentionally **not** touched — they update rarely, and the periodic `sync-dotfiles-full` run handles them.

**Delegation contract**: at Step 1 this skill checks several conditions. If any of them fires, it stops and follows `~/.claude/skills/sync-dotfiles-full/SKILL.md` instead:

1. `~/.cache/sync-dotfiles/last-full-sync` is missing or older than 30 days (= a full sync is overdue).
2. Any submodule has a `-` prefix (= not initialized, fast path can't safely operate without it).
3. Any submodule with a reachable remote has a `+` prefix (= pointer drift, the parent's recorded SHA disagrees with the submodule HEAD). Drifted-but-unreachable submodules are skipped: a leftover wip commit from a previous failed sync can't be pushed from this machine anyway, and the next sync on a reachable machine resolves it.
4. Any initialized submodule whose remote is reachable on this machine has a dirty worktree (`git status --porcelain` non-empty) or unpushed commits (`@{u}..HEAD` non-empty). The fast skill never enters submodules, so these go un-synced and the user thinks "I edited the wiki, why didn't it push?" — this trigger catches that. Submodules whose remote is NOT reachable (missing SSH alias, offline, etc.) are skipped: their local edits stay local until the next sync on a machine that can push them.

A fifth check **stops** the skill (no delegation) and asks the user for manual cleanup: **stow-link mismatch**. If a submodule's stow target (`$HOME/<path-with-leading-package-stripped>`) is a real directory with its own `.git` instead of a stow symlink to the submodule, the user has a standalone clone shadowing where the symlink should be. Their edits go into the standalone, never into the submodule; no amount of syncing fixes the divergence. The full skill doesn't fix this either, so STOP and report rather than delegating.

**Fast-path shape**: in the common case (no merge conflicts, no newly-added files), this skill runs **three tool-call rounds total** — Step 1 (3 parallel reads, including a prefetch), Step 2 (one bundled script that merges, amends, and pushes), and Step 5b (apply the my-settings.json overlay). Steps 3–5 only fire on the rare conflict / restow branches. Step 5b is a separate round rather than inlined into Step 2 so it runs identically on the common and rare paths and so its exit codes don't tangle with Step 2's routing codes (7/8/9).

> **Important — env vars don't persist across Bash tool invocations.** Each Bash call is a fresh shell, so `export` from one call is **lost** in subsequent ones. Any later command that uses `${id}` or `${os}` must re-source the metadata inline by prefixing with:
> ```bash
> export $(grep -v '^#' ~/.machine_metadata | xargs) && ...
> ```

---

## Step 1 — Metadata + freshness + prefetch **[PARALLEL × 3]**

Issue all three calls in **a single message** so they run concurrently. They're independent: metadata bootstrap doesn't depend on submodule status, and `git fetch` only needs the remote — none of them touch each other.

The point of the prefetch (Call 3) is that the network round-trip for `git fetch` is the slowest single op in this skill. Doing it in parallel with the cheap local reads hides its latency, so Step 2's `git merge` is purely local.

**Call 1 — metadata + freshness check:**

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
```

**Call 2 — submodule status + dirty/unpushed/mismatch scan:**

```bash
echo "--- submodules ---"
sub_status=$(cd ~/.dotfiles && git submodule status)
echo "$sub_status"

# Walk each initialized submodule once and check four things:
# 1. Reachability → if the remote can't be reached on this machine (missing
#    SSH alias, offline, auth failure), report SKIPPED and skip the
#    dirty/unpushed checks for this submodule. The user's local edits stay
#    local; the next sync on a reachable machine picks them up. Without
#    this guard, a machine that can't talk to a personal remote would loop
#    into the full skill on every sync and still fail there.
# 2. Dirty worktree → delegate (full skill commits + pushes inside the submodule).
# 3. Unpushed commits → delegate (full skill pushes).
# 4. Stow-link mismatch — the submodule's stow target ($HOME/<rest>) is a real
#    directory with its own .git instead of a stow symlink. The user's edits go
#    into that standalone clone, the submodule never sees them, sync passes blindly.
#    Cannot delegate: the full skill doesn't reconcile two diverged clones either.
#    STOP and report so the user can converge them manually. Stow check runs
#    regardless of reachability since the divergence is a local-config issue.
sub_report=$(cd ~/.dotfiles && git submodule foreach --quiet '
  reachable=1
  if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=3" \
       git ls-remote --exit-code origin HEAD >/dev/null 2>&1; then
    reachable=0
    echo "$displaypath: SKIPPED (remote unreachable on this machine)"
  fi
  if [ "$reachable" = "1" ]; then
    if [ -n "$(git status --porcelain)" ]; then
      echo "$displaypath: dirty worktree"
    fi
    if [ -n "$(git log @{u}..HEAD --oneline 2>/dev/null)" ]; then
      echo "$displaypath: unpushed commits"
    fi
  fi
  # Stow target = $HOME/<displaypath with leading package dir stripped>.
  # e.g. wiki/.local/share/wiki -> $HOME/.local/share/wiki
  rel=$(echo "$displaypath" | cut -d/ -f2-)
  if [ -n "$rel" ] && [ "$rel" != "$displaypath" ]; then
    target="$HOME/$rel"
    if [ -e "$target" ] && [ ! -L "$target" ] && { [ -d "$target/.git" ] || [ -f "$target/.git" ]; }; then
      echo "$displaypath: STOW_MISMATCH at $target (real dir with .git, expected symlink to ~/.dotfiles/$displaypath)"
    fi
  fi
' 2>/dev/null)

# Build the unreachable-path set so the '+' drift check below can ignore
# submodules that can't be pushed from this machine anyway.
unreachable_paths=$(echo "$sub_report" | sed -n 's/: SKIPPED.*$//p')

if [ -n "$sub_report" ]; then
  echo "$sub_report"
fi

# Uninitialized → DELEGATE. Only the full skill can clone, regardless of
# whether THIS machine can reach the remote (the user might have aliases set
# up that the foreach probe can't see in our subshell environment).
if echo "$sub_status" | grep -q '^-'; then
  echo "submodule uninitialized -> DELEGATE"
fi

# Pointer drift → DELEGATE only when the drifted submodule is reachable.
# A drifted but unreachable submodule is leftover from a previous failed
# sync (e.g. a wip commit made when the remote was down); the new pointer
# can't be pushed from here, and the next sync on a reachable machine will
# resolve it.
drifted=$(echo "$sub_status" | awk '/^\+/ {print $2}')
if [ -n "$drifted" ]; then
  if [ -n "$unreachable_paths" ]; then
    drifted_reachable=$(echo "$drifted" | grep -vxF -f <(echo "$unreachable_paths") || true)
  else
    drifted_reachable="$drifted"
  fi
  if [ -n "$drifted_reachable" ]; then
    echo "submodule pointer drift -> DELEGATE"
    echo "$drifted_reachable"
  fi
fi

# STOW_MISMATCH wins over DELEGATE — manual cleanup is the only fix.
if echo "$sub_report" | grep -q 'STOW_MISMATCH'; then
  echo "stow-link mismatch -> STOP (manual cleanup required: merge the standalone clone into the submodule, delete the real dir, then re-stow the package)"
elif echo "$sub_report" | grep -qE '(dirty worktree|unpushed commits)'; then
  echo "submodule has unsynced work -> DELEGATE"
fi
```

**Call 3 — prefetch origin/main:**

```bash
cd ~/.dotfiles && git fetch origin main 2>&1
```

Routing after Step 1:

- If any call's output contains `-> STOP`, **stop the skill entirely** and report the STOW_MISMATCH lines to the user. Do NOT delegate — the full skill doesn't reconcile two diverged clones either. The user has to: (a) commit and push everything in the standalone clone, (b) pull the same state into the dotfiles submodule, (c) delete the standalone, (d) `cd ~/.dotfiles && stow <package>` to recreate the symlink, (e) commit + push the updated submodule pointer in the parent. Past incident: the wiki standalone at `~/.local/share/wiki/` shadowed the would-be stow link for months while `/sync-dotfiles` silently reported success.
- Else if any call's output contains `-> DELEGATE`, **stop following this skill** and follow `~/.claude/skills/sync-dotfiles-full/SKILL.md` from its Step 1. Do not continue with the steps below — the full skill handles the fast path's work too. (The prefetch was wasted but harmless.)
- Else continue with Step 2 — submodules are skipped for the rest of this skill.

If `$id` or `$os` is empty after Call 1 (e.g. unwritable HOME), stop and report regardless of the other checks.

---

## Step 2 — Bundled merge + finalize (single call)

One bash invocation that does **everything** for the happy path: secret scan, commit local changes, merge the already-fetched remote, amend to the final sync message, push. Two early exits flag the rare branches:

- **`exit 8`** = merge conflict surfaced. Continue at Step 3 (resolve). Step 3 then checks whether the merge ALSO added new files: if yes → Step 4 → Step 5 → Step 5b → Step 6; if no → Step 5 → Step 5b → Step 6.
- **`exit 9`** = clean merge added new files that need restowing. Continue at Step 4 (restow), then Step 5 (finalize), then Step 5b (apply my-settings overlay), then Step 6 (report).
- **`exit 7`** = pre-commit scan blocked (symlink loop or secret). Stop and run Step 6 (report) directly so the user sees what blocked. **Skip Step 5b** — when the git sync didn't complete, propagating my-settings.json into settings.json could spread whatever made the scan fail.
- **`exit 0`** = git sync succeeded. Continue to **Step 5b** (apply my-settings overlay), then Step 6 (report). This includes the "Already up to date / nothing to push" no-op case; Step 5b still runs because my-settings.json may have been edited locally even when the remote was a no-op, and the overlay must reflect that.

```bash
set -e -o pipefail
cd ~/.dotfiles
export $(grep -v '^#' ~/.machine_metadata | xargs)

# 1. Scan ALL local changes — modified-tracked AND untracked-not-gitignored —
# and commit them as a wip checkpoint. The dotfiles repo is a personal config
# store: any file the user dropped under it that isn't gitignored is meant to
# travel between machines. Leaving untracked files behind silently strands new
# scripts / configs on the originating machine. The precommit scan and
# `.gitignore` are the safety net; honor them both, but don't second-guess.
#
# `set -o pipefail` plus an explicit `if !`-guarded scan invocation makes the
# commit unreachable when the scan exits non-zero. Without pipefail, the pipe's
# overall exit code is the printf's (always 0) and the scan's BLOCKED status
# silently slips by — that's how an earlier ad-hoc run committed flagged files.
local_files=$( { git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u)
if [ -n "$local_files" ]; then
  if ! printf '%s\n' "$local_files" | "$HOME/.claude/skills/sync-dotfiles/scripts/precommit-scan.sh"; then
    echo "precommit-scan blocked the wip commit. Resolve the flagged files (or rephrase the docs that triggered the false positive) and retry."
    exit 7
  fi
  git add -A && git commit -m "wip: local changes before sync [machine-${id}]"
fi

# 2. Merge the remote (already fetched in Step 1 Call 3).
pre_merge=$(git rev-parse HEAD)
if ! git merge --no-edit origin/main; then
  echo "MERGE_CONFLICT -> Step 3"; exit 8
fi
post_merge=$(git rev-parse HEAD)

# 2b. Post-merge loop guard: refuse to push a merge that introduced (or kept)
# a looping symlink, even if it came from the remote. Without this we'd
# fast-forward a bad commit onto every other machine. --loop-only skips the
# secret checks (committed-upstream secrets are a different policy concern).
if [ "$pre_merge" != "$post_merge" ]; then
  if ! git diff "$pre_merge" "$post_merge" --name-only --diff-filter=AM \
       | "$HOME/.claude/skills/sync-dotfiles/scripts/precommit-scan.sh" --loop-only; then
    echo "Merge introduced a symlink loop. To unwind: git reset --hard $pre_merge"
    exit 7
  fi
fi

# 3. If the merge added new files, bail out so Step 4 can restow before we push.
if [ "$pre_merge" != "$post_merge" ] \
   && [ -n "$(git diff "$pre_merge" "$post_merge" --name-only --diff-filter=A)" ]; then
  echo "RESTOW_NEEDED ($pre_merge..$post_merge) -> Step 4"; exit 9
fi

# 4. Finalize: rename the head commit to the canonical sync message and push.
#
# The amend is gated on "HEAD is ahead of upstream" because amending an
# already-pushed commit rewrites its SHA and the subsequent push lands
# as non-fast-forward. The two paths through Step 2 that end here with
# HEAD == @{u} are (a) no local changes + no remote changes (merge said
# "Already up to date") and (b) no local changes + remote was strictly
# ahead (merge fast-forwarded to the remote tip). In both, there's
# nothing new to relabel.
git diff --cached --quiet || git commit -m "merge: sync from remote [machine-${id}, ${os}]"
if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then
  git commit --amend -m "sync: dotfiles update [${os}, machine-${id}]"
fi
if [ -n "$(git log @{u}..HEAD --oneline 2>/dev/null)" ]; then
  git push origin main
else
  echo "parent: nothing to push"
fi
```

`set -e` plus the explicit `exit 7/8/9` codes makes Bash surface them to Claude. **Do not** treat exits 8 or 9 as failures — they're hand-offs to Steps 3 and 4.

---

## Step 3 — Conflict resolution (only on exit 8)

> **CRITICAL — anti-stop rule.** Do NOT end the turn between listing the conflicts and resolving them. Listing, deciding, and executing the resolution all happen in the SAME response. After announcing the rule for a file, the next tool call must be the resolution command — no "let me explain what I'm about to do, then wait" turn endings, no implicit pause for user confirmation. The user invoked `/sync-dotfiles` expecting it to finish; pausing for "is Rule B OK?" defeats the skill. The only legitimate pause is the narrow "genuinely ambiguous" case below, and when it fires you must say it out loud: "Conflict on `<file>` is ambiguous because `<reason>`; pausing for user input."
>
> Past failure: a session announced "lazy-lock.json — Rule B applies (keep incoming)" and ended the turn without running the `checkout --theirs`. The user had to ask why the run stalled. This block exists to make that mistake unmissable on a future read.

List the unresolved conflicts:

```bash
cd ~/.dotfiles && git status --short | grep -E '^(UU|AA|DD|AU|UA|DU|UD)'
```

For each conflicted file, pick a rule and execute its command in the same turn:

- **Rule A — Additive/structural** (both sides added independent content). Open the file, drop the conflict markers so both blocks remain, then `git add <file>`.
- **Rule B — Logic conflict on the same setting/lockfile/generated artifact** (same key changed both sides, or same auto-generated content updated both sides). Keep incoming:
  ```bash
  git checkout --theirs -- <file> && git add <file>
  ```

**Default to Rule B for generated artifacts and lockfiles** — they're meant to be replaced wholesale, not three-way-merged. No thinking needed for these: `lazy-lock.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock`, `Pipfile.lock`, `Gemfile.lock`, `composer.lock`, `flake.lock`, `*.lock`, any file under a `__generated__/` / `dist/` / `build/` directory.

**When to actually pause** (genuinely ambiguous, narrow set):
- Hand-edited config (NOT a generated artifact) where both sides changed the same key to different meaningful values and context can't tell which is the user's current intent.
- Multiple unrelated hunks in one file where the rule would differ per hunk and the right call isn't obvious.

In those cases, post the conflict body and ask. In all other cases, pick and run in the same turn.

After every conflict is staged, check whether the merge ALSO added new files. If yes, hop to **Step 4** before finalizing (Step 4 will restow the new files, then Step 5 commits). If no, jump straight to **Step 5**.

```bash
cd ~/.dotfiles && new_files=$(git diff ORIG_HEAD --cached --name-only --diff-filter=A)
if [ -n "$new_files" ]; then
  echo "RESTOW_NEEDED -> Step 4"; echo "$new_files"
else
  echo "no new files added by merge -> Step 5"
fi
```

The merge commit is not finalized yet; the staged conflict resolutions + any new files will become the merge commit in Step 5 (or Step 4 → Step 5).

---

## Step 4 — Restow packages that gained new files

Called in two cases:
1. **From Step 2 exit 9** — clean merge that added new files. The merge commit has been made; new files are in HEAD.
2. **From Step 3** — conflict resolution finished and the staged result includes new files from the remote side. Merge commit not yet made; new files are only in the INDEX.

The diff form below covers both because `git diff ORIG_HEAD --cached` compares ORIG_HEAD against the INDEX, and the INDEX equals HEAD post-commit (case 1) or "pre-merge HEAD + staged resolutions" mid-conflict (case 2):

```bash
cd ~/.dotfiles && git diff ORIG_HEAD --cached --name-only --diff-filter=A 2>/dev/null | sed 's|/.*||' | sort -u
```

For each package directory listed, run stow then verify each new file is actually a symlink. Stow can bail with `BUG in find_stowed_path? Absolute/relative mismatch` (or "WARNING! stowing X would cause conflicts: existing target is not owned by stow") when it walks unrelated absolute symlinks in `$HOME` (e.g. `~/.local/state/nix/profiles/profile`, or other dotfiles symlinks created by hand) — when that happens it leaves new files unlinked, so we always verify and fall back to manual symlinking.

```bash
pkg=<package>
cd ~/.dotfiles && stow -R "$pkg" 2>&1 || true
git diff ORIG_HEAD --cached --name-only --diff-filter=A | grep "^${pkg}/" | while IFS= read -r src; do
  rel=${src#${pkg}/}
  dest="$HOME/$rel"
  expected="$HOME/.dotfiles/$src"
  # -e (not -L): catches both a direct file-level symlink AND a folded
  # parent directory. With directory folding, $dest's final component is
  # a regular file reached through a folded parent; -L would miss that
  # and the rm/ln branch below would traverse the folded parent, delete
  # the real file in the package, and write a self-looping symlink.
  if [ -e "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$expected")" ]; then
    continue
  fi
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$expected" "$dest"
  echo "manually linked $rel"
done
```

Report any remaining conflicts (e.g. unwritable parent dirs) but do not abort. Then continue to Step 5.

---

## Step 5 — Finalize (only after Step 3 or 4)

Step 2 already does this inline on the happy path. This step only fires after the conflict-resolution or restow branches: same logic, separate call.

The amend is gated on "HEAD is ahead of upstream" for the same reason as Step 2: if no new commit was made this run (rare here, but possible if Step 4's restow finished with nothing left to commit), amending would rewrite a previously-pushed commit and the push would be rejected as non-fast-forward.

```bash
cd ~/.dotfiles && export $(grep -v '^#' ~/.machine_metadata | xargs) && \
  { git diff --cached --quiet || git commit -m "merge: sync from remote [machine-${id}, ${os}]"; } && \
  { if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then git commit --amend -m "sync: dotfiles update [${os}, machine-${id}]"; fi; } && \
  if [ -n "$(git log @{u}..HEAD --oneline 2>/dev/null)" ]; then git push origin main; else echo "parent: nothing to push"; fi
```

This skill does **not** update `~/.cache/sync-dotfiles/last-full-sync` — only `sync-dotfiles-full` does. Updating it here would defeat the monthly trigger.

---

## Step 5b — Apply the my-settings.json overlay

Runs after every successful git sync (Step 2 exit 0, or after Step 5 finalize succeeds). Skipped only on Step 2 exit 7 (pre-commit blocked).

`~/.claude/my-settings.json` is a symlink into the dotfiles repo and travels between machines. `~/.claude/settings.json` is the live, unsymlinked file Claude Code actually reads (Claude itself writes a few fields into it, e.g. `feedbackSurveyState.lastShownTime`). This step deep-merges the dotfiles-tracked overlay into the live settings:

- New entries in my-settings → added to settings.
- Removed entries → stripped from settings, but only when the value in settings still matches what was previously applied. Manual edits to settings are preserved.
- Scalar updates in my-settings → overwrite settings (my-settings wins).
- Arrays → union (settings entries first, then my-settings entries not already present).
- Settings keys my-settings doesn't claim → preserved untouched.

The previously-applied my-settings content is cached at `~/.cache/sync-dotfiles/my-settings-applied.json` so the script can compute the strip set and short-circuit when my-settings is byte-identical to the cache.

```bash
"$HOME/.claude/skills/sync-dotfiles/scripts/apply-my-settings.sh"
```

Exit codes: `0` success (updated, no-op merge, or skipped because my-settings.json was unchanged since last apply), `1` error (invalid JSON / missing jq / corrupted cache). The stdout line distinguishes "updated" / "no diff after merge" / "unchanged since last apply, skipping" for Step 6's report.

**Manual force-reapply:** if you need to re-merge from scratch (e.g. after blowing away settings.json and wanting the overlay back), delete `~/.cache/sync-dotfiles/my-settings-applied.json` first. Without a cache, strip is a no-op and the script falls back to additive merge.

---

## Pre-commit scan (reference)

Implemented in `scripts/precommit-scan.sh`. Step 2 pipes the union of `git diff --name-only HEAD` (modified-tracked) and `git ls-files --others --exclude-standard` (untracked, gitignore-respecting) into it. The post-merge guard (Step 2b) pipes `git diff $pre $post --diff-filter=AM` with `--loop-only`. Untracked files are scanned the same way as modified ones — the secret/loop checks are the gate that keeps `git add -A` safe to use blindly.

Three checks, in order — the symlink-loop guard runs first because a looping symlink makes the content grep fail silently with ELOOP and would otherwise let a self-loop slip through (real incident: dotfiles `dda112d8`):

1. **Symlink loop** — files where `stat -L` reports the recursion-limit error.
2. **Suspicious filename** — common credential-bearing extensions (env / pem / key / pfx / ppk family) and dotenv variants, plus paths that name themselves after a credential type (passwords, private keys, ssh identities). Exact regex lives in the script.
3. **Suspicious content** — RSA / ed25519 private-key headers, AWS access-key prefixes, GitHub personal-access-token prefixes, Slack tokens, and credential-style key=value or `key:` assignments. Exact regex lives in the script — kept out of these docs so the scan doesn't trip on its own description.

Flags:
- `--loop-only` — skip checks 2 and 3 (post-merge use)
- `--prefix=<path>` — prepend `<path>/` to BLOCKED messages (parallel-submodule use; the `sync-dotfiles-full` skill uses this)

Exits 0 if every input file passes; exits 7 (after scanning all of them) if any blocked. The script reads filenames from stdin (newline-separated) or from argv.

---

## Step 6 — Report

**Always run this step, including on the "already up to date / nothing to push" no-op path.** The report is the only user-visible signal that the skill executed; suppressing it on a clean run looks indistinguishable from the skill never starting. State "already in sync, nothing to do" explicitly rather than going silent.

- Machine ID and OS
- Mode: fast (parent-only) — note this explicitly so the user knows submodules were skipped
- Days since last full sync
- Path taken: happy / already-synced / conflict / restow (= which exit code from Step 2; "already-synced" is the exit-0 sub-case where the merge said "Already up to date" and there was nothing to push)
- Local changes committed (split: modified-tracked count + newly-tracked count from `git ls-files --others --exclude-standard`) / nothing to push / fast-forwarded
- Conflicts resolved (count and files), if any
- Packages restowed, if any
- Final pushed commit (or "nothing to push")
- my-settings.json overlay (Step 5b): updated / no diff / skipped because unchanged / skipped because git sync failed / error
