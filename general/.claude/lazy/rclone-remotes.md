# rclone remotes and Google Drive uploads

Config: `~/.config/rclone/rclone.conf` (backups saved as `rclone.conf.bak.YYYYMMDD` before edits).

## Remotes and their accounts

| Remote | Google account | Notes |
| --- | --- | --- |
| `alejandrobernal.fx-google-drive:` | alejandrobernal.fx@gmail.com (personal) | 100 GiB plan. This is the default target for personal uploads. Mounted by the `rcmg` alias to `$REMOTES/gd`. |
| `unal-google-drive:` | unal.edu.co (Universidad Nacional) | Token is stale, run a reconnect before use. |

Neither is the work account (alejandro.bernal@conductorone.com). Do NOT upload personal or family data to any work-connected Drive.

## Upload convention

Personal uploads go under `claude-uploaded/<topic>/` on the personal remote, one topic subfolder per thing, e.g. `claude-uploaded/resonancia-magnetica/`. Keep it organized, do not dump files at the Drive root.

## Reconnecting an expired token

Tokens expire (`invalid_grant` / "token expired" / "Bad Request" on `rclone about`). Reconnect opens a browser to pick the account:

```
rclone config reconnect <remote>: --auto-confirm
```

Have the user select the correct Google account on the consent screen (this is the one step only they can do). `rclone config userinfo` is blocked by the drive scope, so confirm the account by the reconnect selection plus the Drive contents, not by reading the email programmatically.
