---
name: machines-ops
description: Run commands, deploy files, start GUI apps, and take screenshots on my own machines (titan, elite, mac) from whichever one this session runs on. Triggers on "on elite", "on the mac", "on titan", "ssh into <machine>", "deploy this to elite/mac", "install X on my other machines", "add it to elite and mac too", "screenshot the mac", "is <machine> reachable", or any task that has to touch one of my other machines. Resolves the current LAN IP itself (DHCP changes it, mDNS and tailscale are unreliable). Not for remote servers, VMs, or cloud hosts.
argument-hint: '<machine: titan | elite | mac> [what to do]'
---

# machines-ops

Three machines on one home LAN, all reachable from each other over SSH with key auth:

- **titan**: Linux, xmonad + xmobar + trayer. The hub: runs the long-lived jobs and timers.
- **elite**: Ubuntu, GNOME on X11 (legacy tray icons enabled). Primary workstation.
- **mac**: macOS laptop, device-managed (some permissions get reset).

Per-machine data (users, LAN MACs, mDNS names, host-key aliases) lives in the private
`~/.dotfiles/personal/machines.json`; long-form history and troubleshooting in
`~/CLAUDE-machines.md`. Read that file when something below fails. Never copy IPs, MACs, or
usernames into this public skill or any other public file.

## Connect: always through `mssh`

```bash
M=~/.claude/skills/machines-ops/scripts/mssh
$M elite hostname                 # run a command
$M mac --ip                       # current IP (cached in ~/.cache/machines-ops/)
$M elite --gui 'xdpyinfo | head'  # inside the logged-in desktop session
$M titan                          # interactive shell
```

`mssh` tries the cached IP, then mDNS, then pings the subnet and matches the machine's MAC.
It passes the right user and `HostKeyAlias` for the source machine, so a stale IP that now
belongs to another device fails host-key verification instead of logging in somewhere else.
Don't hand-build `ssh` lines with hardcoded IPs; if `mssh` can't reach a machine, report
what it printed and check `~/CLAUDE-machines.md` "What makes it work".

For anything that runs on a machine later without you (autostart entries, timers, tray
apps that SSH back to titan), the stored command can't call `mssh`'s resolution each time
cheaply; use `$M <machine> --ip` now and say in the report that a DHCP change will break it
(a router DHCP reservation is the real fix).

## Recipes

- **Copy a file**: `$M elite 'cat > /tmp/x' < local-file` and `$M mac 'cat /tmp/y' > local-file`.
- **GUI command / app start**: `$M elite --gui '<cmd>'` (borrows DISPLAY / XAUTHORITY / DBUS
  from the session's window-manager process); on the mac `--gui` wraps in `launchctl asuser`.
- **Screenshot to verify a UI change**:
  - Linux: `$M elite --gui 'import -window root /tmp/shot.png'`, then copy it back and crop
    (`convert shot.png -crop WxH+X+Y`). Read the image before claiming it worked.
  - mac: `$M mac 'screencapture -x /tmp/shot.png'`. Needs Screen Recording for
    `/usr/libexec/sshd-keygen-wrapper` (System Settings > Privacy & Security); System Events
    menu-bar queries need Accessibility for the same binary. Device management may revoke both.
- **Click / type remotely** (Linux): `$M elite --gui 'xdotool mousemove X Y click 1'`; save and
  restore the pointer position around it.
- **Autostart**: GNOME = `~/.config/autostart/<name>.desktop` (quote env args in `Exec=` as
  `"KEY=value with spaces"`, shell escapes don't work there). mac = a LaunchAgent plist in
  `~/Library/LaunchAgents/` started with `launchctl bootstrap gui/$(id -u) <plist>` (launchd
  gives a bare PATH, set `EnvironmentVariables/PATH` with `/opt/homebrew/bin`).
- **Python tray icons**: use a venv (`~/.local/share/trays-venv`; on Linux create it with
  `--system-site-packages` for `gi`). On GNOME without the AppIndicator typelib set
  `PYSTRAY_BACKEND=gtk`, or pystray dies at import.

## Deploying dotfiles changes to a machine

The other machines' `~/.dotfiles` are often behind AND carry their own uncommitted edits.
Never `git pull`, merge, stash, or reset there on your own. Push from here, then bring over
only the files you changed:

```bash
$M elite 'cd ~/.dotfiles && git fetch -q origin && git status --short'   # look first
$M elite 'cd ~/.dotfiles && git checkout origin/main -- <path> [<path>...]'
```

Only do that for paths the machine has not edited locally (check `git status` first). A file
the machine edited too is the user's merge decision: report it and ask. New files in a new
directory may need a restow (`stow -R <package>`) before they appear under `$HOME`; running
them by their `~/.dotfiles/...` path avoids that.

## Gotchas

- The Bash tool's shell is zsh: unquoted `$VAR` doesn't word-split (put ssh options inline or
  in an array) and `path` is tied to `$PATH` (never name a loop variable `path`).
- Every machine's login shell is zsh; wrap remote scripts in `bash -c '...'` when they use bash
  syntax (`${PIPESTATUS[@]}`, `[[ ]]` with regex, arrays).
- macOS has no `timeout`, `setsid`, or GNU `readlink -f` on older versions; `arp` drops leading
  zeros in MAC bytes.
- Tailscale is normally stopped: tailnet names in `~/.ssh/config` aliases won't resolve.
- mDNS (`*.local`) is flaky from elite; don't depend on it for anything stored.

## Safety

Read-only checks need no confirmation. Ask before anything that changes another machine for
its user beyond the task asked: installing system packages, `sudo`, killing processes you
didn't start, editing `~/.ssh`, or touching that machine's uncommitted dotfiles edits.
