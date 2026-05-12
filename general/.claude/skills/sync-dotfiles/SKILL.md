---
name: sync-dotfiles
description: "Fast dotfiles sync — pulls/pushes the parent repo only and skips submodules entirely (they're almost never updated, so syncing them every run is wasted time). At least once every 30 days, or when any submodule is uninitialized (`-` prefix), this skill delegates to `sync-dotfiles-full` so submodules stay current. Resolves merge conflicts (keep both non-conflicting changes; keep newest/incoming for logic conflicts), restows packages with newly-added files, and pushes a machine-tagged commit. Metadata (id and os) is in ~/.machine_metadata; full-sync state is tracked in ~/.cache/sync-dotfiles/last-full-sync."
---

> **Thinking budget: none on the happy path — just execute.** The happy path is two deterministic tool-call rounds. Don't reason about strategy, don't evaluate alternatives, don't re-derive the flow — run the steps verbatim.
>
> **Exception — think hard on merge conflicts.** If Step 2 exits 8 (merge conflict) or Step 4 reports an unresolved conflict, switch on extended thinking for that branch only. Conflict resolution needs real reasoning: distinguish Rule A (additive/structural, keep both) from Rule B (logic conflict, keep incoming), and when it's ambiguous, think through which side represents the newer intent before choosing. Return to zero thinking once the conflict is staged.

Sync the **parent** dotfiles repo at `~/.dotfiles`: pull remote changes, resolve conflicts, restow packages with new files, and push a machine-tagged commit. Submodules are intentionally **not** touched — they update rarely, and the periodic `sync-dotfiles-full` run handles them.

**Delegation contract**: at Step 1 this skill checks two conditions. If either is true, it stops and follows `~/.claude/skills/sync-dotfiles-full/SKILL.md` instead:

1. `~/.cache/sync-dotfiles/last-full-sync` is missing or older than 30 days (= a full sync is overdue).
2. Any submodule has a `-` prefix (= not initialized, fast path can't safely operate without it).

**Fast-path shape**: in the common case (no merge conflicts, no newly-added files), this skill runs **two tool-call rounds total** — Step 1 (3 parallel reads, including a prefetch) and Step 2 (one bundled script that merges, amends, and pushes). Steps 3–5 only fire on the rare conflict / restow branches.

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

**Call 2 — submodule status:**

```bash
echo "--- submodules ---"
sub_status=$(cd ~/.dotfiles && git submodule status)
echo "$sub_status"
if echo "$sub_status" | grep -q '^-'; then
  echo "submodule uninitialized -> DELEGATE"
fi
```

**Call 3 — prefetch origin/main:**

```bash
cd ~/.dotfiles && git fetch origin main 2>&1
```

If any call's output contains a `-> DELEGATE` line, **stop following this skill** and follow `~/.claude/skills/sync-dotfiles-full/SKILL.md` from its Step 1. Do not continue with the steps below — the full skill handles the fast path's work too. (The prefetch was wasted but harmless.)

If `$id` or `$os` is empty after Call 1 (e.g. unwritable HOME), stop and report.

If neither delegation condition fired, continue with Step 2 — submodules are skipped for the rest of this skill.

---

## Step 2 — Bundled merge + finalize (single call)

One bash invocation that does **everything** for the happy path: secret scan, commit local changes, merge the already-fetched remote, amend to the final sync message, push. Two early exits flag the rare branches:

- **`exit 8`** = merge conflict surfaced. Continue at Step 3 (resolve), then Step 5 (finalize).
- **`exit 9`** = merge added new files that need restowing. Continue at Step 4 (restow), then Step 5 (finalize).
- **`exit 7`** = pre-commit scan blocked (symlink loop or secret). Stop and report.
- **`exit 0`** = success, sync is done. Skip to Step 6 (report).

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

```bash
cd ~/.dotfiles && git status --short | grep -E '^(UU|AA|DD|AU|UA|DU|UD)'
```

**Rule A — Additive/structural**: both sides added independent content → keep both, remove markers.

**Rule B — Logic conflict**: same setting changed on both sides → keep incoming (remote):

```bash
git checkout --theirs -- <file> && git add <file>
```

After all conflicts are staged, jump to **Step 5** (the merge commit isn't finalized yet — Step 5's `git diff --cached --quiet || git commit ...` will create it from the staged resolution).

---

## Step 4 — Restow packages that gained new files (only on exit 9)

The Step 2 exit-9 message includes the pre/post merge SHAs. Use those (or `ORIG_HEAD..HEAD` — `git merge` sets `ORIG_HEAD` whenever the merge actually changed HEAD) to find packages that received newly-added files:

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

- Machine ID and OS
- Mode: fast (parent-only) — note this explicitly so the user knows submodules were skipped
- Days since last full sync
- Path taken: happy / conflict / restow (= which exit code from Step 2)
- Local changes committed (split: modified-tracked count + newly-tracked count from `git ls-files --others --exclude-standard`) / nothing to push / fast-forwarded
- Conflicts resolved (count and files), if any
- Packages restowed, if any
- Final pushed commit (or "nothing to push")
