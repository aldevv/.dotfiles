---
name: agent-tui
description: Use agent-tui to drive a TUI app from the shell — spawn it on a PTY, snapshot its screen as text or a semantic tree, press keys, wait for state changes. Triggers on "use agent-tui", "/agent-tui", "drive <tui app> programmatically", "automate vim/htop/fzf/<repl>", "test a TUI", "snapshot terminal output", "press keys in a TUI app", "control a curses app from a script", or any explicit request for headless terminal automation. Do NOT trigger for one-shot CLI commands with normal stdin/stdout (use plain Bash), or for browser automation (use Playwright).
---

# agent-tui

A CLI + per-session daemon that owns a PTY and drives a TUI program from the outside. Read the live screen as text or a semantic outline, send keystrokes, wait on structured state changes. Think "playwright for terminal apps."

Repo: https://github.com/ConductorOne/agent-tui

## When to use

- The target program is interactive (fzf, vim, htop, psql, a REPL, a custom TUI) and you want to drive or observe it from a script.
- A normal `cmd < input > output` pipe won't work because the program needs a real terminal or paints with curses.
- You want a structured wait (`wait --ref`, `wait --text`) instead of `sleep`s.

Skip it for:
- Non-interactive commands. Use plain Bash, or `agent-tui run --stdin '...' -- cmd` if you want the same client surface.
- Browser automation. Use the Playwright MCP plugin.

## Install

```bash
# Pick the right tarball from the latest release.
gh release download --repo ConductorOne/agent-tui \
  --pattern "agent-tui-x86_64-unknown-linux-gnu.tar.xz*"
sha256sum -c agent-tui-x86_64-unknown-linux-gnu.tar.xz.sha256
tar -xf agent-tui-x86_64-unknown-linux-gnu.tar.xz
install -m 0755 agent-tui-*/agent-tui ~/.local/bin/agent-tui
agent-tui --version
```

If the official installer script (`agent-tui-installer.sh`) is hosted at `/releases/latest/download/`, it may 404 for some releases. Falling back to a tagged download (`/releases/download/vX.Y.Z/...`) or the `gh release download` route above always works.

## The four verbs you'll actually use

| Verb | When |
|---|---|
| `spawn` | Start the child in a PTY. Returns immediately. |
| `snapshot` | Read the current screen (`--mode text` is plain UTF-8; `outline` is semantic; `cells` is raw grid). |
| `press` / `type` | `press` sends key tokens (`<cr>`, `<esc>`, `<c-b>`); `type` sends literal text. |
| `wait` | Block on a state: `--ref <selector>`, `--text <regex>`, `--idle <ms>`. Replace `sleep`s with this. |

There's also `run` (subprocess-as-data: stdin in, stdout out, no PTY semantics), `ask` (CLI sugar for AI subprocesses), `edit` (wraps `$EDITOR`), and `replay` (asciicast regression).

## Sessions

Every command takes `--session NAME` (default `default`). Sessions isolate one daemon + its panes. Use unique names when running parallel agent-tui flows or when you want to pin state across invocations.

```bash
agent-tui spawn --session demo -- vim notes.md
agent-tui --session demo press 'i hello<esc>:wq<cr>'
```

## Minimal vim example

```bash
agent-tui spawn -- vim notes.md
agent-tui wait --ref '@vim.buffer'              # buffer rendered
agent-tui press 'i'
agent-tui wait --ref '@vim.mode[value=insert]'  # mode flipped
agent-tui type 'review the draft'
agent-tui press '<esc>:wq<cr>'
```

The named refs (`@vim.buffer`, `@vim.mode`) come from agent-tui's vim adapter. Apps without a dedicated adapter still get generic positional refs (`@e1`, `@e2`) tagged with a `role`.

## Reading the screen

```bash
# Plain text (alt-screen is captured automatically if the app uses it):
agent-tui --json snapshot --mode text | jq -r .data.text

# Semantic outline (one node per addressable region):
agent-tui --json snapshot --mode outline | jq -c '.data.outline.nodes'

# Raw grid (cells RLE-compressed):
agent-tui --json snapshot --mode cells | jq -c '.data.cells | {rows, cols}'

# Everything at once:
agent-tui --json snapshot --mode hybrid | jq -c '.data | keys'
```

## Key tokens for `press`

- Plain letters/digits: `a`, `1`
- Ctrl: `<c-a>`, `<c-b>`, ...
- Alt/Meta: `<m-a>`, `<a-b>`
- Special: `<cr>`, `<esc>`, `<tab>`, `<bs>`, `<space>`, `<up>`, `<down>`, `<left>`, `<right>`, `<f1>`...`<f12>`
- Sequences are concatenated: `:wq<cr>`, `gg<c-d>`, `i hello<esc>`

`type` sends literal characters (no token parsing), which is the right choice for pasting text that may contain `<`.

## Driving fzf or anything that uses the alt screen

Most picker / curses apps switch to the **alternate screen buffer**. agent-tui captures it transparently — no flag needed — but two things bite first-time users:

- **A leaky `$FZF_DEFAULT_OPTS`** (or `$EDITOR`'s plugins) can crash or hang the child before it draws. Reproduce with `--env FZF_DEFAULT_OPTS=` (or other suspect vars cleared) to isolate.
- **`snapshot --mode text` can read empty** the first few hundred ms after spawn while the child is still negotiating the PTY size. Either `wait --idle 500` or `wait --text '<known-prompt>'` before sampling.

```bash
agent-tui spawn --session pick --env FZF_DEFAULT_OPTS= -- bash -c '
  printf "alpha\nbeta\ngamma\n" | fzf --header=demo
'
agent-tui wait --session pick --idle 500
agent-tui --session pick press '<down><down><cr>'   # select gamma
```

## Replacing `sleep` with `wait`

```bash
# Bad: timing race.
agent-tui press 'i hello'
sleep 1
agent-tui --json snapshot --mode text | jq -r .data.text

# Good: blocks on state.
agent-tui press 'i hello'
agent-tui wait --text 'hello'           # screen contains "hello"
agent-tui wait --ref '@vim.mode[value=insert]'   # adapter-specific
agent-tui wait --ref '@vim.cmdline[focused]' --gone   # prompt closed
agent-tui wait --idle 300               # screen quiescent (last resort)
```

`wait` has a default timeout; check `agent-tui wait --help` for the flag and exit codes if you need a tight bound.

## Common gotchas

- **Pane state shows `running` but `--mode text` returns empty.** The child is on the alt screen but the cell buffer hasn't been refreshed since the last paint. Press an arrow key or `<c-l>`, or call `wait --idle 500`, then re-snapshot.
- **`press '<cr>'` looks like it did nothing.** Confirm the pane has focus (only one pane per session by default; multi-pane needs `--pane p1`). Also try `press '<enter>'` or sending raw bytes via `send-ansi`.
- **`spawn -- bash -lc 'cmd'` exits immediately.** A login shell + `-c` runs `cmd` then exits, killing the pane. Spawn the program directly (`-- cmd`) or use `-- bash` then `type 'cmd'; press '<cr>'`.
- **`agent-tui list` shows no panes** but a snapshot returns content. You're hitting the wrong session. Pass `--session NAME` (or set `AGENT_TUI_SESSION`) to every call, including `list`.

## Wiring into a debugging loop

When something looks broken in an interactive app, agent-tui turns it into a scripted experiment:

```bash
agent-tui spawn --session dbg -- <your-cli>
agent-tui wait --session dbg --idle 500
agent-tui --session dbg --json snapshot --mode text | jq -r .data.text > /tmp/before.txt

agent-tui --session dbg press '<keys-under-test>'
agent-tui wait --session dbg --idle 500
agent-tui --session dbg --json snapshot --mode text | jq -r .data.text > /tmp/after.txt

diff /tmp/before.txt /tmp/after.txt
```

Combine that with running a real backend (e.g. a nvim launched with `--listen <sock>` and queried with `nvim --server <sock> --remote-expr '...'`) to confirm whether your CLI's interaction with that backend actually landed.
