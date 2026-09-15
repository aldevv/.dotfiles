---
name: show-id
description: Print the current Claude Code conversation/session id, or list/search this folder's past conversations. Triggers on "/show-id", "show id", "show the session/conversation id", "current convo id", "which session is this"; ALSO on "list/search past conversations", "what conversations are in this folder", "find the previous conversation about X", "look up another session's id or summary". scripts/show-id.sh prints $CLAUDE_CODE_SESSION_ID (Claude exports it into every command it runs), or an fzf picker when run outside a session. Companion scripts in the same dir: scripts/show-sessions.sh prints every conversation for the cwd as "id<TAB>date  title" (plain and greppable — use this to find a past conversation non-interactively), and scripts/show-summary.sh prints an id and its summary, optionally for a given <id>. Needs fzf + jq for the picker; run from a Claude Code project directory.
---

# show-id

Print the current session (conversation) id.

Run the helper and report the id it prints:

```bash
~/.claude/skills/show-id/scripts/show-id.sh
```

That is the whole skill: report the id. If the script errors ("no conversations found"), the current directory has no Claude Code transcript, tell the user to run it from the directory the session started in.

## How it decides what to show

Claude Code exports `CLAUDE_CODE_SESSION_ID` into every command it runs (and into `!` shells), so that env var is the authoritative current id whenever the script runs inside a session, including this skill's own invocation.

- **Inside a session** (`CLAUDE_CODE_SESSION_ID` set) — prints that id. No transcript guessing.
- **Outside a session, non-interactive** (piped) — falls back to the newest transcript for this cwd under `$CLAUDE_CONFIG_DIR/projects/<cwd-slug>/`.
- **Outside a session, interactive terminal** — opens an fzf picker of this directory's past conversations, previewing each one's title, last prompt, and message count, and prints the id you pick. Needs `fzf` and `jq`.

Detecting the session via the env var (not transcript freshness) is what makes the picker open from a second terminal even while another session is live in the same directory.

## Companion: show-summary

`scripts/show-summary.sh` prints a conversation's id and its summary on two lines (id first, summary second). With no argument it resolves the id exactly like `show-id` (current session, or the fzf picker outside one); with an explicit `<id>` it skips the picker and summarizes that conversation directly:

```bash
~/.claude/skills/show-id/scripts/show-summary.sh            # current / picked
~/.claude/skills/show-id/scripts/show-summary.sh <id>       # a specific one
```

## Companion: show-sessions

`scripts/show-sessions.sh` prints every conversation for the current directory, newest first, one per line as `id<TAB>date  title` — the same rows the fzf picker uses, but plain and greppable. It's the non-interactive way to find a past conversation in a folder (grep the titles, then feed the id to `show-summary.sh <id>` or read the transcript at `$CLAUDE_CONFIG_DIR/projects/<cwd-slug>/<id>.jsonl`):

```bash
~/.claude/skills/show-id/scripts/show-sessions.sh
```

All three scripts share `scripts/lib.sh` (dir resolution, summary extraction, the session listing, the fzf picker, the `--preview` renderer).
