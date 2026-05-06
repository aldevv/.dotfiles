# nvim-md-preview — Implementation Plan

## OS-Level Feasibility Assessment

### Can Chrome genuinely "swallow" a tmux pane?

**Linux (X11 + devour): YES.**
`devour chrome --app=URL` sends SIGSTOP to the parent terminal, Chrome opens and takes the visible space, SIGCONT is sent when Chrome closes. The tmux pane is hidden at the X11 window level. Real, documented workflow.

**macOS: NO.**
macOS has no X11 window reparenting. `devour` doesn't exist for macOS. There is no mechanism to embed a browser into a terminal pane.

**macOS alternative:** Use `osascript` to query the kitty window bounds, resize kitty to the left half of the screen, and position Chrome to the right half. The tmux pane stays visible (or gets killed after Chrome opens). It's a visual split, not true embedding.

**Linux without devour:** `chromium --app=URL &` in the tmux split, then optionally minimize the idle pane. No swallowing without devour.

---

## File Structure

Everything lives inside the existing dotfiles config — no separate git repo.

```
~/.config/nvim/
├── scripts/
│   ├── md-preview.py                  # existing, untouched
│   └── md-preview-server.py           # NEW: HTTP + WebSocket server
└── lua/
    ├── plugins/
    │   └── markdown.lua               # MODIFY: add new keybindings
    └── utils/
        └── lua/
            └── md-preview.lua         # NEW: Lua state + IPC + window logic

~/.local/share/nvim/md-preview-venv/   # auto-created on first run
    bin/python3
    lib/.../site-packages/markdown_it/
```

---

## Component Responsibilities

### 1. Python Server: `scripts/md-preview-server.py`

Single process, two threads.

**Thread A — `ThreadingHTTPServer` on port 9753:**
- `GET /` — renders markdown with `markdown-it-py`, injects `data-line` attrs, returns full HTML
- `GET /reload` — returns `{"version": N}` (browser polls this as a fallback)
- `POST /scroll` — receives `{"line": N}` from Neovim, broadcasts to WebSocket clients
- `POST /render` — re-renders the watched file, broadcasts `{"type": "reload"}` to clients
- `GET /ws` — upgrades to WebSocket (RFC 6455 handshake, pure stdlib)

**Thread B — stdin reader:**
Reads newline-delimited JSON from stdin. Neovim sends via `vim.fn.chansend(job_id, msg)`.
Messages: `{"type":"scroll","line":N}`, `{"type":"render","file":"..."}`, `{"type":"quit"}`.

**Shared state (protected by `threading.Lock`):**
```python
state = {
    "file":           str,   # absolute path to watched file
    "html_cache":     str,   # last rendered HTML
    "line_map":       list,  # [(source_line_0idx, data_line_value), ...]
    "ws_clients":     set,   # connected WebSocket sockets
    "render_version": int,   # increments on every render
}
```

**WebSocket — pure stdlib (no `websockets` package needed):**
RFC 6455 handshake uses `hashlib.sha1` + `base64.b64encode`. Frame encoding/decoding uses `struct.pack`. Each client runs in its own thread (spawned by `ThreadingHTTPServer`). ~60 lines total.

**Self-bootstrapping venv:**
```python
VENV_DIR = os.path.expanduser("~/.local/share/nvim/md-preview-venv")
VENV_PYTHON = os.path.join(VENV_DIR, "bin", "python3")

if sys.executable != VENV_PYTHON:
    if not os.path.exists(VENV_PYTHON):
        subprocess.run([sys.executable, "-m", "venv", VENV_DIR], check=True)
        subprocess.run([VENV_PYTHON, "-m", "pip", "install", "-q", "markdown-it-py"], check=True)
    os.execv(VENV_PYTHON, [VENV_PYTHON] + sys.argv)
    # os.execv replaces the process — same PID, Neovim still tracks it
```
First run: ~3-5s for pip install. Subsequent runs: instant.

---

### 2. Lua Module: `lua/utils/lua/md-preview.lua`

Module-level state (persists for the full nvim session via module cache):
```lua
M.state = {
  job_id         = nil,   -- jobstart() channel ID
  port           = 9753,
  file           = nil,   -- absolute path currently previewed
  tmux_pane_id   = nil,   -- "%12" style tmux pane ID
  debounce_timer = nil,   -- vim.loop timer for cursor debounce
  platform       = nil,   -- "linux" or "macos"
}
```

**`M.setup()`** — called once from plugin `config`. Detects platform via `vim.uv.os_uname()`.

**`M.open(theme)`** — main entry point:
1. If `M.is_alive()`: send `{"type":"render","file":"..."}` via `chansend` → replaces content, no new server/Chrome
2. Otherwise: `jobstart({venv_python, server_script, file, port, theme}, {stdin='pipe'})`
3. Poll `http://localhost:9753/` with `vim.defer_fn` (50ms retries, max 20) until ready
4. Open Chrome + manage windows per platform (see below)
5. Register `BufWritePost`, `CursorHold`, `BufWipeout`, `VimLeavePre` autocmds

**`M.on_cursor_moved()`** — debounced 150ms via `vim.loop.new_timer()`. On fire: get cursor line with `vim.api.nvim_win_get_cursor(0)[1]`, send `{"type":"scroll","line":N}` via `chansend`.

**`M.on_save()`** — sends `{"type":"render","file":"..."}` via `chansend`.

**`M.close()`** — sends `{"type":"quit"}`, calls `vim.fn.jobstop(job_id)`, kills tmux pane if present, clears state.

**`M.is_alive()`**:
```lua
return M.state.job_id ~= nil
  and vim.fn.jobwait({M.state.job_id}, 0)[1] == -1
  -- -1 = still running, -2 = invalid id, 0 = exited
```

---

### 3. Window Management per Platform

**Linux + tmux + devour:**
```bash
tmux split-window -h -l 45%
# store pane ID
tmux display-message -p "#{pane_id}"   # -> "%12"
# launch browser with swallowing
tmux send-keys -t %12 "devour chromium --app=http://localhost:9753/" Enter
```
Chrome takes the visual space of the pane. When Chrome closes, the pane returns.

**Linux + tmux, no devour:**
```bash
tmux split-window -h -l 45% "chromium --app=http://localhost:9753/"
# pane stays open showing the browser process
```

**macOS + tmux:**
```applescript
-- Get kitty bounds
tell application "System Events"
    tell process "kitty"
        set pos to position of window 1   -- {x, y}
        set sz  to size of window 1       -- {w, h}
    end tell
end tell
-- Resize kitty to left half, Chrome to right half
tell application "System Events"
    tell process "kitty"
        set size of window 1 to {(item 1 of sz) div 2, item 2 of sz}
    end tell
end tell
tell application "Google Chrome"
    set bounds of window 1 to {(item 1 of pos) + (item 1 of sz) div 2,
                                item 2 of pos,
                                item 1 of pos + item 1 of sz,
                                item 2 of pos + item 2 of sz}
end tell
```
Terminal app is detected dynamically via `osascript` frontmost process. Supports kitty, iTerm2, Ghostty, Alacritty, WezTerm.

**No tmux (any OS):** Just open Chrome `--app=http://localhost:9753/`. No window management.

---

## Line-to-Element Mapping

`markdown-it-py` tokens carry `.map = [start_line, end_line]` (0-indexed) on block-level tokens — the same as the JS version that markdown-preview.nvim uses.

**Server-side (Python):**
```python
from markdown_it import MarkdownIt

md = MarkdownIt()
tokens = md.parse(content)
counter = 0
line_map = []  # [(source_line_0idx, data_line_value), ...]

for token in tokens:
    if token.map is not None and (
        token.type.endswith('_open') or
        token.type in ('fence', 'hr', 'html_block')
    ):
        counter += 1
        token.attrSet('data-line', str(counter))
        line_map.append((token.map[0], counter))

html_body = md.renderer.render(tokens, md.options, {})
```

**Lookup (source line → data-line value):**
```python
def source_to_data_line(source_line_0idx):
    result = 1
    for src, dl in line_map:       # line_map is sorted ascending
        if src <= source_line_0idx:
            result = dl
        else:
            break
    return result
# Server converts before broadcasting: {"type":"scroll","line": data_line_value}
```

**Browser-side (JS):**
```javascript
const ws = new WebSocket('ws://localhost:9753/ws');
ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    if (msg.type === 'scroll') {
        const el = document.querySelector(`[data-line="${msg.line}"]`);
        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    if (msg.type === 'reload') {
        fetch('/').then(r => r.text()).then(html => {
            const doc = new DOMParser().parseFromString(html, 'text/html');
            document.querySelector('#content').innerHTML =
                doc.querySelector('#content').innerHTML;
            hljs.highlightAll();
        });
    }
};
```

**Known limitation:** Elements without `data-line` (table rows, list items) jump to the nearest preceding block. Same behavior as VS Code's markdown preview. Acceptable.

---

## Data Flow

### Initial Open
```
<leader>mv
  └─ M.open("dark")
       ├─ M.is_alive() → false → start server
       │    jobstart(venv_python, server.py, file, port, "dark")
       │      server bootstraps venv on first run
       │      parses markdown, builds line_map, caches HTML
       │      starts ThreadingHTTPServer :9753
       │      starts stdin reader thread
       ├─ poll http://localhost:9753/ (vim.defer_fn, 50ms × 20)
       ├─ detect tmux ($TMUX env var)
       │    → open Chrome, position windows per platform
       └─ register autocmds (BufWritePost, CursorHold, BufWipeout, VimLeavePre)
```

### Scroll Sync
```
cursor moves → CursorHold fires (after &updatetime ms)
  └─ 150ms debounce timer fires
       └─ chansend(job_id, '{"type":"scroll","line":42}\n')
            └─ stdin thread → source_to_data_line(41) → 7
                 └─ broadcast_ws('{"type":"scroll","line":7}')
                      └─ Chrome JS → querySelector('[data-line="7"]').scrollIntoView(...)
```

### Save / Re-render
```
:w → BufWritePost
  └─ chansend(job_id, '{"type":"render","file":"..."}\n')
       └─ stdin thread → re-parse markdown → rebuild line_map + html_cache
            └─ broadcast_ws('{"type":"reload","version":4}')
                 └─ Chrome JS → fetch('/') → replace #content innerHTML → hljs.highlightAll()
```

### Single Instance — Second Open
```
<leader>mv (again, same or different file)
  └─ M.open("dark")
       └─ M.is_alive() → true
            └─ chansend(job_id, '{"type":"render","file":"/new/path.md"}\n')
                 └─ server switches file, re-renders, broadcasts reload
                      (no new server, no new Chrome window)
```

---

## Pure-stdlib WebSocket Sketch

```python
import hashlib, base64, struct

WS_MAGIC = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'

def ws_handshake(handler):
    key = handler.headers.get('Sec-WebSocket-Key', '')
    accept = base64.b64encode(
        hashlib.sha1((key + WS_MAGIC).encode()).digest()
    ).decode()
    handler.send_response(101, 'Switching Protocols')
    handler.send_header('Upgrade', 'websocket')
    handler.send_header('Connection', 'Upgrade')
    handler.send_header('Sec-WebSocket-Accept', accept)
    handler.end_headers()

def ws_encode(message: str) -> bytes:
    data = message.encode('utf-8')
    n = len(data)
    if n <= 125:
        return struct.pack('BB', 0x81, n) + data
    elif n <= 65535:
        return struct.pack('!BBH', 0x81, 126, n) + data
    else:
        return struct.pack('!BBQ', 0x81, 127, n) + data

def ws_read_frame(sock) -> tuple[int, bytes]:
    """Returns (opcode, payload). Returns (8, b'') on close."""
    header = sock.recv(2)
    if len(header) < 2:
        return 8, b''
    opcode = header[0] & 0x0F
    length = header[1] & 0x7F
    if length == 126:
        length = struct.unpack('!H', sock.recv(2))[0]
    elif length == 127:
        length = struct.unpack('!Q', sock.recv(8))[0]
    masked = (header[1] & 0x80) != 0
    mask = sock.recv(4) if masked else b'\x00\x00\x00\x00'
    payload = bytearray(sock.recv(length))
    if masked:
        for i in range(len(payload)):
            payload[i] ^= mask[i % 4]
    return opcode, bytes(payload)
```

No external package required.

---

## New Keybindings (added to existing FileType autocmd in markdown.lua)

| Key | Action |
|---|---|
| `<leader>mv` | Open scroll-synced preview (dark theme) |
| `<leader>mV` | Open scroll-synced preview (light theme) |
| `<leader>mq` | Close preview (server + Chrome + pane) |

Existing `<leader>mp` / `<leader>mP` (static preview) are kept as-is.

---

## What Is Left Out

- **Reverse scroll sync** (Chrome → nvim): complex, minimal gain
- **Windows support**: macOS/Linux only
- **Multiple simultaneous previews**: intentionally single-instance
- **True pane embedding on macOS**: not feasible without X11

---

## Implementation Phases

| Phase | Deliverable |
|---|---|
| 1 | Server with HTTP rendering, venv bootstrap, BufWritePost reload |
| 2 | WebSocket scroll sync (CursorHold → scroll) |
| 3 | tmux pane management + window positioning per OS |
| 4 | Single-instance replace, stdin IPC, VimLeavePre cleanup |
| 5 | Polish: port conflict detection, `vim.notify` errors, which-key group |
