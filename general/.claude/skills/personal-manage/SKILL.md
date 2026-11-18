---
name: personal-manage
description: >
  Handles my personal admin through my personal Google account: send mail with
  attachments from my personal Gmail, search and read my mail, and personal Drive
  uploads. Use for: "/personal-manage", "send these files to <address>", "email this
  from my personal email/gmail", "forward <files> to <person>", "find/read the email from
  <sender>", "what did <person> send me", "check my gmail for X". Wins over generic browser
  work whenever my personal mail account is involved. Not for my employer accounts (they
  have their own skills) or Drive-only uploads with no mail step (follow
  `~/.claude/lazy/rclone-remotes.md`).
argument-hint: "<task in plain words>, e.g. \"send ~/Documents/x/*.pdf to someone@example.com\""
---

# Personal manage

Everything goes through `scripts/gmail.js`. It drives a dedicated Chrome profile
(`~/.cache/ms-playwright/personal-gmail`) over CDP on port 9399. It reuses that Chrome if it's
running, else starts it headless, so no window steals focus. One command per call, no MCP
browser needed (the Playwright MCP profiles are often locked by other sessions).

```bash
export PWCORE=$(ls -d ~/.npm/_npx/*/node_modules/playwright-core | tail -1)
G=~/.claude/skills/personal-manage/scripts/gmail.js
node $G search 'from:someone newer_than:7d' 10   # one line per match: sender, subject, snippet, date
node $G read 'subject:"exact subject"'            # body + attachment names of the first match
node $G send --to a@b.com [--cc c@d.com] --subject 'S' --body 'T' file1.pdf file2.pdf
node $G login                                     # only when a command says "not signed in"
```

- Queries use Gmail operators (`from:`, `to:`, `subject:`, `has:attachment`, `newer_than:`, `in:sent`, `in:anywhere`).
- `send` attaches, waits for the uploads, clicks Send, waits for "Message sent", then prints
  the matching row from Sent. A screenshot of the compose is left at `/tmp/gmail-compose.png`.
- `login` needs `PERSONAL_EMAIL` and `PERSONAL_EMAIL_PASS`. They live in `~/.envrc` (local
  only, not in any repo), so run `direnv exec ~ node $G login`: a nested project `.envrc`
  without `source_up` hides them. It skips Google's passkey prompt and uses the
  password. If Google asks for 2FA or the sign-in stalls, it fails with a screenshot at
  `/tmp/gmail-login.png`: rerun with `GMAIL_SHOW=1` (kill the headless Chrome on port 9399
  first) and tell me to finish in the window. Never print the password.

## Sending mail is outward-facing

Send only when my current message names the recipient and the files. If I gave both
explicitly, send without asking again; otherwise show from, to, subject, body and the
attachment list first. Always confirm with `read 'in:sent to:<addr> subject:"<subject>"'`
that the attachments made it, and report that.

When I don't give a subject or body: a short plain subject naming the files (Spanish if the
files are Spanish) and a one-line body, no signature fluff. Gmail caps a mail at 25 MB;
above that, upload to Drive per `rclone-remotes.md` and send the link.

## Gotchas (2026-11-18)

- Copying a desktop Chrome/Brave profile doesn't carry the Google session, and Google
  rejects sign-in from the Playwright Firefox MCP. The dedicated profile above is the path.
- Gmail SMTP refuses the normal account password; it would need an app password.
- When driving the CDP Chrome by hand, pick the page by URL: Chrome can open a
  `chrome://signin-dice-web-intercept` tab that steals the first-page slot.
- Before resending anything that might have gone out, search `in:anywhere to:<addr>
  newer_than:1d` so it never goes twice.
