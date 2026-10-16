# Testing tmux.conf / tmux script changes

Don't test tmux.conf changes against the live session, it's actively in use. Spin up an isolated tmux server on a throwaway socket instead: same binary, same plugins, but a `kill-server` never touches the real one.

## Isolated test server

```bash
SOCK=/tmp/tmux-test-<topic>
tmux -S "$SOCK" kill-server 2>/dev/null   # start clean if reusing the name
tmux -S "$SOCK" new-session -d -s t -c <some-dir>
tmux -S "$SOCK" source-file ~/.config/tmux/tmux.conf   # pull in the config under test
```

- `-f /dev/null -S "$SOCK" new-session ...` skips tmux's default config entirely, useful when you need to prove a setting is/isn't set by a specific line (e.g. confirming an `if-shell` branch is truly a no-op on the other platform) rather than testing the full merged config.
- Always `tmux -S "$SOCK" kill-server` when done, and `rm -rf` any scratch dirs you made.

## Testing a claude pane inside the test server

A fresh `claude` pane hits the "Accessing workspace... trust this folder?" prompt on any brand-new directory, which blocks non-interactive `send-keys` testing. Dodge it with a `git init`:

```bash
mkdir -p /tmp/trusted-test-dir && cd /tmp/trusted-test-dir && git init -q
tmux -S "$SOCK" new-session -d -s t -c /tmp/trusted-test-dir
tmux -S "$SOCK" send-keys -t t:1.1 'claude --dangerously-skip-permissions' C-m
sleep 3
tmux -S "$SOCK" send-keys -t t:1.1 Down   # select "Yes, I trust this folder"
tmux -S "$SOCK" send-keys -t t:1.1 Enter
```

Use a fresh directory per test round — reusing one keeps stitching new messages onto old scrollback/conversation state and makes `capture-pane` output ambiguous about what actually happened just now.

## Worked example: verifying window-title logic

Confirmed macOS pane titles are dynamic (not stuck on the literal "Claude Code") before rewriting `automatic-rename-format` to drop the dead JSONL-scraping fallback:

```bash
SOCK=/tmp/tmux-title-test
tmux -S "$SOCK" kill-server 2>/dev/null
mkdir -p /tmp/title-test-dir && cd /tmp/title-test-dir && git init -q
tmux -S "$SOCK" new-session -d -s t -c /tmp/title-test-dir
tmux -S "$SOCK" send-keys -t t:1.1 'claude --dangerously-skip-permissions' C-m
sleep 3
tmux -S "$SOCK" send-keys -t t:1.1 Down
tmux -S "$SOCK" send-keys -t t:1.1 Enter
sleep 3
tmux -S "$SOCK" send-keys -t t:1.1 'Help me write a script that backs up my home directory to S3'
tmux -S "$SOCK" send-keys -t t:1.1 Enter
sleep 6
tmux -S "$SOCK" display-message -p -t t:1.1 '#{pane_title}'   # -> "✳ Home directory S3 backup script"
tmux -S "$SOCK" display-message -p -t t:1.1 '#{window_name}'  # -> "title-test-dir:claude:home-backup-s3"

tmux -S "$SOCK" kill-server 2>/dev/null
rm -rf /tmp/title-test-dir
```

To force a rename check on an already-running window without waiting for the next natural trigger (new command, focus change): `tmux set-option -w -t <session>:<window> automatic-rename on` re-evaluates `automatic-rename-format` immediately.

## Other useful probes

- `tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} title=[#{pane_title}] cmd=[#{pane_current_command}]"` — snapshot every pane's title + resolved command in one shot, good for spotting the macOS `pane_current_command` version-string quirk (`2.1.283` instead of `claude`).
- `tmux show-options -g | grep <option-name>` — confirm a `set -g` / `if-shell` branch actually took effect after a `source-file` reload.
- `tmux capture-pane -t <target> -p -S -200` — full scrollback dump when a single `-p` capture doesn't show enough context to tell what happened.
