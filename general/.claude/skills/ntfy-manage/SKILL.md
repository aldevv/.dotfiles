---
name: ntfy-manage
description: Send push notifications to my phone through my ntfy.sh topic, and turn my notifications off or on. Use for "send me a notification", "notify my phone", "ping me when X finishes", "ntfy me", "alert me if X breaks", a cron job or script that should notify me, and for "turn notifications off/on", "mute/unmute notifications", "pause my notifications", "are my notifications on". Also sets up the ntfy config on a new machine. Not for Slack, email, or desktop-only popups.
---

# ntfy-manage

One script: `scripts/ntfy-manage` (link or call it by full path, `~/.claude/skills/ntfy-manage/scripts/ntfy-manage`).

| Command | What it does |
|---|---|
| `send [-t title] [-p priority] [-g tags] [message...]` | Push to the topic. No message argument reads the body from stdin. Priority: `min`, `low`, `default`, `high`, `urgent`. Prints `sent` |
| `off` | Every `send` exits 0 without sending, and my `my-notifications*` user services stop and stay off across reboots |
| `on` | Sends work again and those services start |
| `status` | On/off, the topic, each `my-notifications*` service state |
| `setup --env-file <file> [--url <topic-url>]` | Writes the config from an env file holding `NTFY_TOKEN` (and `NTFY_URL`), then checks the topic reads back 200 |

## Config

- `~/.config/ntfy-manage/env`: `NTFY_URL=https://ntfy.sh/<topic>`.
- `~/.config/ntfy-manage/curlrc` (600): the bearer token as a curl config, so it never shows in `ps`. Never print it or paste it into a command line.
- `~/.config/ntfy-manage/disabled`: the off flag.
- Not configured on this machine? The token and topic are in the `.env` of my `my-notifications` repo (clone `aldevv/my-notifications` into `~/repos` if it's missing). Run `setup --env-file ~/repos/my-notifications/.env --url https://ntfy.sh/<topic>` (the topic is named in the repo's `CLAUDE.md`). Values in that `.env` are quoted; `setup` strips the quotes (a quoted token gives HTTP 403).

## Scripts that notify

Cron jobs and scripts should call `ntfy-manage send` instead of curling ntfy directly, so `off` silences them too. Notify on state changes, not on every run, or the phone gets the same alert every hour.

```sh
printf '%s\n' "$problems" | ~/.claude/skills/ntfy-manage/scripts/ntfy-manage send -t "backup: 2 problems" -p high -g backup
```

## my-notifications (desktop notifications to the phone)

The `my-notifications` repo forwards desktop notifications to the same topic. `./install.sh` in the repo picks the role: macOS sender, Linux + dunst relay (the main box), or Linux on GNOME sender (`linux-gnome-notify`, posts to the relay box). Phone replies only route back for notifications from the relay box itself.
