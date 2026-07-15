# systemd automation for `/auto-new-day`

User-level systemd units that fire the `/auto-new-day` launcher on weekday mornings (America/Bogota). The actual HH:MM lives in `auto-new-day-sweep.timer`; inspect it with `launch-auto-new-day.sh --show-time` or change it with `--set-time HH:MM`. Tracked here so the skill is portable across machines (and so a future "reinstall on new laptop" run can re-copy these files).

## Goal

The sweep fires on the scheduled morning tick; later the user opens the laptop and finds a terminal window already open with the `AUTO-new-day` tmux session inside (one `sweep` window holding the sweep report). Three sibling sessions get created lazily by the sweep when they have work:

- `AUTO-inreview` — own In-Review tickets with new human comments or `CHANGES_REQUESTED` reviews. Each window already ran `/auto-new-day:fix-bug` on the PR branch, committed locally, and dropped the diff into a `/report` review. Nothing has been pushed.
- `AUTO-inprogress` — unstarted In Progress tickets, each in plan-aware mode waiting for the user to approve the plan.
- `AUTO-inreview-others` — up to 5 teammate PRs from Connector Horizon that need review, each running `/pr-code-review-work` (validate-connector-changes + baton-admin-review-connector + multi-agent diff review via `/auto-new-day:pr-code-review`, closing with Hunk + an answer-draft pane; never posts, never asks).

## Files

- `auto-new-day-sweep.service` — fires the launcher (`Type=simple`). Launcher script: `~/work/.claude/skills/auto-new-day/scripts/launch-auto-new-day.sh`. Service stdout/stderr go to the journal (`journalctl --user -u auto-new-day-sweep`); the launcher writes sweep output to `~/.cache/auto-new-day-sweep/sweep.log` via `tmux pipe-pane`.
- `auto-new-day-sweep.timer` fires `Mon..Fri *-*-* HH:MM:00 America/Bogota` (HH:MM lives in the .timer file; inspect or change with `launch-auto-new-day.sh --show-time` / `--set-time HH:MM`). `Persistent=true` so a missed run (laptop off when the timer fired) runs on the next boot/login.
- (The launcher itself lives at `../../scripts/launch-auto-new-day.sh`, not here — it's part of the skill, not the systemd config.)

## What the launcher does

1. Rotates the previous day's `sweep.log` to `sweep.log.<date>.old` (keeps the last 7).
2. Bails (after writing a sentinel) if no `$DISPLAY` / `$WAYLAND_DISPLAY` is set (laptop closed, no graphical session yet).
3. Preflights every required binary (`tmux`, `jq`, `git`, `gh`, `claude`); writes a `FAILED` sentinel and exits non-zero if any is missing.
4. Picks `$TERMINAL` if set and on `$PATH`; falls back to `kitty`, then `st`, `alacritty`, `foot`, `wezterm`, `xterm`.
5. Holds a non-blocking `flock` on `~/work/.auto-new-day/.sweep.lock` so a manual `/auto-new-day` can't race with the timer-fired run.
6. If yesterday's `AUTO-new-day` session has in-flight (non-`sweep`) windows, renames it to `AUTO-new-day-prev-<date-time>` instead of killing it. Otherwise the stale session is killed and a fresh one is created.
7. Creates the new `AUTO-new-day` session detached, wires `tmux pipe-pane` to `sweep.log`, waits briefly for the pane shell to be ready, then sends `claude --dangerously-skip-permissions /auto-new-day` into the pane. Tmux is configured with `remain-on-exit on` and the inner command ends with `; exec ${SHELL:-bash}` so the pane drops to an interactive shell after the sweep finishes — both for clean exits and crashed claudes the operator can scroll through later.
8. Step 7 of `/auto-new-day` creates the `AUTO-inreview` session lazily (if there are ≥1 actionable own-tickets) and adds one window per actionable own-ticket inside it, each running its own `/auto-new-day:fix-bug + /report` flow on the PR branch under per-window safety guards. Step 7b creates `AUTO-inprogress` lazily for unstarted In Progress tickets. Step 7c creates `AUTO-inreview-others` lazily for up-to-5 teammate PRs that need review (no Bjorn/John approval yet, not already reviewed unless commits landed since my review). A session is only created when it has ≥1 window of real work — no placeholder windows.

## Install

```bash
mkdir -p ~/.config/systemd/user ~/.cache/auto-new-day-sweep ~/work/.auto-new-day/{dispatch,done,guards}
cp auto-new-day-sweep.service auto-new-day-sweep.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now auto-new-day-sweep.timer
systemctl --user list-timers auto-new-day-sweep.timer
```

The launcher's `--install` branch (`~/work/.claude/skills/auto-new-day/scripts/launch-auto-new-day.sh --install`) does the same steps with backup-on-overwrite and a pre-`cp` `stop` to avoid mid-copy races.

## Operate

- **See next fire:** `systemctl --user list-timers auto-new-day-sweep.timer`
- **Run now (real, will commit):** `systemctl --user start auto-new-day-sweep.service` (terminal window pops up, attaches to `AUTO-new-day` tmux)
- **Pause:** `systemctl --user disable --now auto-new-day-sweep.timer`
- **Resume:** `systemctl --user enable --now auto-new-day-sweep.timer`
- **Tail launcher diagnostics:** `journalctl --user -u auto-new-day-sweep -f`
- **Tail sweep output:** `tail -F ~/.cache/auto-new-day-sweep/sweep.log` (or `sweep-dryrun.log` for dry-run output)

## Dry run

When you want to see what the sweep WOULD do without any commits, state writes, or `/auto-new-day:fix-bug` runs, invoke the launcher directly with `--dry-run`:

```bash
~/work/.claude/skills/auto-new-day/scripts/launch-auto-new-day.sh --dry-run
# or: AUTO_NEW_DAY_DRY_RUN=1 ~/work/.claude/skills/auto-new-day/scripts/launch-auto-new-day.sh
```

What changes vs a real run:

- Launcher's tmux session is `AUTO-new-day-dryrun` (not `AUTO-new-day`), so a real run sitting on screen isn't disturbed.
- Discovery (Linear + GitHub reads) still runs against today's real state — that's the whole point.
- The sweep writes the per-day plan to `~/work/.auto-new-day/dates/<YYYY-MM-DD>-dryrun-create.md` (sections per session listing every window's bootstrap + claude command). No dispatch tmux session is created and no child claude is launched. The operator inspects the create.md, then re-runs without `--dry-run` to actually spawn.
- `state.json` and `done/<id>.json` are NOT written. The dry run is repeatable without advancing `lastCheckedAt`.

Don't trigger a dry run via `systemctl --user start` — the unit doesn't carry the flag. Always invoke the launcher directly when you want dry-run behavior.

## Requirements

- systemd ≥ 245 (inline timezone in `OnCalendar`). Verified with `systemctl --version`. Local machine: systemd 255.
- `claude` on the unit's `PATH=%h/.local/bin:%h/.nix-profile/bin:%h/.cargo/bin:%h/.bun/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin:/bin`. Adjust the `Environment=PATH=` line if `claude` lives elsewhere on this machine.
- Linear plugin already authenticated in the local Claude config (the timer-fired claude inherits the same `~/.claude/` state).
- `gh` authenticated as `al-conductorone` (the skill checks PR approvals via `gh pr view`).
- `tmux`, `jq`, and a terminal (`$TERMINAL` defaults to `st` per the unit's `Environment=TERMINAL=st`; override there if you want kitty / alacritty / etc.).

## DBUS / DISPLAY / WAYLAND_DISPLAY env

The unit does NOT set `DISPLAY` / `WAYLAND_DISPLAY` / `DBUS_SESSION_BUS_ADDRESS` itself; it relies on the user-manager's environment, which on this machine is populated by `/etc/X11/Xsession.d/95dbus_update-activation-env` (calls `dbus-update-activation-environment --systemd --all` at login). Verify with:

```bash
systemctl --user show-environment | grep -E 'DISPLAY|DBUS'
```

If those variables aren't there (Wayland-only sessions, sway/hypr without an explicit `import-environment`, TTY-only login), the launcher's own `$DISPLAY` / `$WAYLAND_DISPLAY` check at the top will short-circuit and write a `NO_DISPLAY` sentinel under `~/.cache/auto-new-day-sweep/sentinels/`. Either add `systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XAUTHORITY` to your session startup, or accept the silent skip.

## Behavior when the timer fires headless

The service runs without a TTY. The skill's Step 7 / Step 7b / Step 7c each create their dispatch tmux session **detached** (`tmux new-session -d -s AUTO-inreview` / `AUTO-inprogress` / `AUTO-inreview-others`) IF that step found ≥1 candidate, then spawn one window per ticket. The launcher's own `AUTO-new-day` session is created up front (it hosts the sweep itself); the dispatch sessions are spawned by the skill. The launcher opens the terminal AFTER it creates `AUTO-new-day`, so the user always sees the rendered window when they sit down. From a fully headless `systemctl start`, the launcher still tries to open the terminal; if no `$DISPLAY` is set it writes the `NO_DISPLAY` sentinel and exits 0 without trying to attach.

The user can attach manually any time:

```bash
tmux attach -t AUTO-new-day                # sweep report (always exists after a run)
tmux attach -t AUTO-inreview          # own PR-feedback work (if any)
tmux attach -t AUTO-inprogress        # own unstarted In Progress tickets (if any)
tmux attach -t AUTO-inreview-others   # up-to-5 teammate PR reviews (if any)
```

## Adjusting the schedule

Edit `OnCalendar=` in `auto-new-day-sweep.timer`. systemd's calendar syntax is documented at `man systemd.time`. After editing, `systemctl --user daemon-reload && systemctl --user restart auto-new-day-sweep.timer`. Re-copy back into this `references/` folder so the skill's checked-in version stays in sync.
