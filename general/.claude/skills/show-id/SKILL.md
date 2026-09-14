---
name: show-id
description: Print the current Claude Code conversation/session id. Triggers on "/show-id", "show id", "show the session/conversation id", "what's the current session id", "current convo id", "which session is this". Runs scripts/show-id.sh, which returns the newest transcript filename for the cwd under $CLAUDE_CONFIG_DIR (default ~/.claude/projects) — that is the active session. Needs to be run from inside a Claude Code session in this directory.
---

# show-id

Print the current session (conversation) id.

Run the helper and show its output to the user:

```bash
~/.claude/skills/show-id/scripts/show-id.sh
```

That is the whole skill: report the id it prints. If the script errors ("no session transcript found"), the current directory has no Claude Code transcript, tell the user to run it from the directory the session started in.

The id is the newest `.jsonl` under `$CLAUDE_CONFIG_DIR/projects/<cwd-slug>/`; the active conversation is the one being written to right now, so newest = current.
