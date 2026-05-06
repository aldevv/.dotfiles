#!/usr/bin/env python3
"""
md-preview-server.py — Neovim markdown preview server
Self-bootstrapping venv, pure-stdlib WebSocket, markdown-it-py rendering.

Usage: python3 md-preview-server.py <file> <port> <theme>
"""

import os
import sys

# ── Self-bootstrapping venv ────────────────────────────────────────────────
# Inject the venv site-packages into sys.path directly (avoids os.execv +
# symlink issues when the venv lives under a stow-managed directory).
import glob as _glob, subprocess as _subprocess

VENV_DIR = os.path.expanduser("~/.local/share/nvim/md-preview-venv")
VENV_PYTHON = os.path.join(VENV_DIR, "bin", "python3")

def _ensure_venv():
    if not os.path.exists(VENV_PYTHON):
        print("[md-preview] Creating venv...", flush=True)
        _subprocess.run([sys.executable, "-m", "venv", VENV_DIR], check=True)
        print("[md-preview] Installing dependencies...", flush=True)
        _subprocess.run(
            [VENV_PYTHON, "-m", "pip", "install", "-q",
             "markdown-it-py", "mdit-py-plugins", "linkify-it-py"],
            check=True,
        )
    # Inject site-packages so imports resolve without re-execing
    matches = _glob.glob(os.path.join(VENV_DIR, "lib", "python*", "site-packages"))
    if matches and matches[0] not in sys.path:
        sys.path.insert(0, matches[0])

_ensure_venv()

# ── Imports ────────────────────────────────────────────────────────────────
import base64
import hashlib
import json
import struct
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse


# ── Args ───────────────────────────────────────────────────────────────────
if len(sys.argv) < 4:
    print("Usage: md-preview-server.py <file> <port> <theme>", file=sys.stderr)
    sys.exit(1)

WATCHED_FILE = os.path.abspath(sys.argv[1])
PORT = int(sys.argv[2])
THEME = sys.argv[3]  # "dark" or "light"


# ── Shared state ───────────────────────────────────────────────────────────
_lock = threading.Lock()
_state = {
    "file": WATCHED_FILE,
    "html_cache": "",
    "ws_clients": set(),  # set of raw sockets
    "render_version": 0,
}


# ── Markdown rendering ─────────────────────────────────────────────────────
from markdown_it import MarkdownIt
from mdit_py_plugins.tasklists import tasklists_plugin

_md = MarkdownIt("gfm-like", {"linkify": True}).enable("linkify").use(tasklists_plugin)


def _strip_frontmatter(content: str) -> str:
    lines = content.split("\n")
    if not lines or lines[0].strip() != "---":
        return content
    end = -1
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end == -1:
        return content
    return "\n".join(lines[end + 1:])


def _render(filepath: str):
    """Parse file, annotate elements with 1-indexed source lines, cache HTML."""
    try:
        with open(filepath, encoding="utf-8") as f:
            content = f.read()
    except OSError as e:
        return f"<p>Error reading file: {e}</p>"

    content = _strip_frontmatter(content)
    tokens = _md.parse(content)

    for token in tokens:
        if token.map is not None and (
            token.type.endswith("_open")
            or token.type in ("fence", "hr", "html_block", "table")
        ):
            # 1-indexed source line — used directly by the browser for interpolation
            token.attrSet("data-line", str(token.map[0] + 1))

    html_body = _md.renderer.render(tokens, _md.options, {})
    return html_body


def _do_render():
    with _lock:
        filepath = _state["file"]
    html_body = _render(filepath)
    with _lock:
        _state["html_cache"] = html_body
        _state["render_version"] += 1
        version = _state["render_version"]
    return version


# ── HTML template ─────────────────────────────────────────────────────────
CSS_DARK = """
:root {
  --color-bg-primary: #0d1117;
  --color-text-primary: #c9d1d9;
  --color-text-secondary: #8b949e;
  --color-border: #30363d;
  --color-bg-code: #161b22;
  --color-link: #58a6ff;
  --color-heading-border: #21262d;
}
"""

CSS_LIGHT = """
:root {
  --color-bg-primary: #ffffff;
  --color-text-primary: #24292e;
  --color-text-secondary: #586069;
  --color-border: #e1e4e8;
  --color-bg-code: #f6f8fa;
  --color-link: #0366d6;
  --color-heading-border: #eaecef;
}
"""

CSS_COMMON = """
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  background: var(--color-bg-primary);
  color: var(--color-text-primary);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
  font-size: 14px;
  line-height: 1.6;
  padding: 32px;
  max-width: 900px;
  margin: 0 auto;
}
.markdown-body h1 { font-size: 2.25em; border-bottom: 1px solid var(--color-heading-border); padding-bottom: 0.3em; margin-bottom: 1em; margin-top: 1.5em; }
.markdown-body h2 { font-size: 1.75em; border-bottom: 1px solid var(--color-heading-border); padding-bottom: 0.3em; margin-bottom: 1em; margin-top: 1.5em; }
.markdown-body h3 { font-size: 1.5em; margin-bottom: 0.75em; margin-top: 1.5em; }
.markdown-body h4 { font-size: 1.25em; margin-bottom: 0.75em; margin-top: 1.5em; }
.markdown-body h5 { font-size: 1em; margin-bottom: 0.75em; margin-top: 1.5em; }
.markdown-body h6 { font-size: 0.875em; color: var(--color-text-secondary); margin-bottom: 0.75em; margin-top: 1.5em; }
.markdown-body p { margin-bottom: 1em; }
.markdown-body a { color: var(--color-link); text-decoration: none; }
.markdown-body a:hover { text-decoration: underline; }
.markdown-body code {
  background: var(--color-bg-code);
  border-radius: 4px;
  font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
  font-size: 85%;
  padding: 0.2em 0.4em;
}
.markdown-body pre {
  background: var(--color-bg-code);
  border-radius: 6px;
  overflow: auto;
  padding: 16px;
  margin-bottom: 1em;
}
.markdown-body pre code {
  background: none;
  padding: 0;
  font-size: 100%;
  white-space: pre;
}
.markdown-body blockquote {
  border-left: 4px solid var(--color-border);
  color: var(--color-text-secondary);
  padding: 0 1em;
  margin-bottom: 1em;
}
.markdown-body ul, .markdown-body ol { padding-left: 2em; margin-bottom: 1em; }
.markdown-body li { margin-bottom: 0.25em; }
.markdown-body table { border-collapse: collapse; width: 100%; margin-bottom: 1em; }
.markdown-body th, .markdown-body td {
  border: 1px solid var(--color-border);
  padding: 6px 13px;
  text-align: left;
}
.markdown-body th { background: var(--color-bg-code); font-weight: 600; }
.markdown-body tr:nth-child(even) { background: var(--color-bg-code); }
.markdown-body hr { border: none; border-top: 1px solid var(--color-border); margin: 1.5em 0; }
.markdown-body img { max-width: 100%; }
"""

HLJS_THEME_DARK = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css"
HLJS_THEME_LIGHT = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css"


def _build_page(html_body: str, theme: str) -> str:
    css_vars = CSS_DARK if theme == "dark" else CSS_LIGHT
    hljs_theme = HLJS_THEME_DARK if theme == "dark" else HLJS_THEME_LIGHT
    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="{hljs_theme}">
<style>
{css_vars}
{CSS_COMMON}
</style>
</head>
<body>
<div id="content" class="markdown-body">
{html_body}
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script>
hljs.highlightAll();

// Compute element's absolute top from document origin (scroll-independent).
function absDocTop(el) {{
    let y = 0;
    while (el) {{ y += el.offsetTop; el = el.offsetParent; }}
    return y;
}}

// Cache annotated element positions after DOM settles.
let _els = [];
function cacheEls() {{
    _els = [...document.querySelectorAll('[data-line]')]
        .map(el => ({{ el, line: parseInt(el.dataset.line), top: absDocTop(el) }}))
        .sort((a, b) => a.line - b.line);
}}
window.addEventListener('load', cacheEls);

const ws = new WebSocket('ws://localhost:{PORT}/ws');
ws.onmessage = (e) => {{
    const msg = JSON.parse(e.data);
    if (msg.type === 'scroll') {{
        if (!_els.length) return;
        const line = msg.line;
        let prev = _els[0], next = null;
        for (let i = 0; i < _els.length; i++) {{
            if (_els[i].line <= line) {{ prev = _els[i]; next = _els[i+1] || null; }}
            else break;
        }}
        let targetTop;
        if (next && next.line > prev.line) {{
            const frac = (line - prev.line) / (next.line - prev.line);
            targetTop = prev.top + frac * (next.top - prev.top);
        }} else {{
            targetTop = prev.top;
        }}
        // Center cursor position in the viewport
        window.scrollTo({{ top: targetTop - window.innerHeight * 0.5, behavior: 'smooth' }});
    }}
    if (msg.type === 'reload') {{
        fetch('/').then(r => r.text()).then(html => {{
            const doc = new DOMParser().parseFromString(html, 'text/html');
            document.querySelector('#content').innerHTML =
                doc.querySelector('#content').innerHTML;
            hljs.highlightAll();
            cacheEls();
        }});
    }}
}};
ws.onclose = () => setTimeout(() => location.reload(), 1000);
</script>
</body>
</html>"""


# ── WebSocket helpers ──────────────────────────────────────────────────────
WS_MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


def _ws_handshake(handler):
    key = handler.headers.get("Sec-WebSocket-Key", "")
    accept = base64.b64encode(
        hashlib.sha1((key + WS_MAGIC).encode()).digest()
    ).decode()
    handler.send_response(101, "Switching Protocols")
    handler.send_header("Upgrade", "websocket")
    handler.send_header("Connection", "Upgrade")
    handler.send_header("Sec-WebSocket-Accept", accept)
    handler.end_headers()


def _ws_encode(message: str) -> bytes:
    data = message.encode("utf-8")
    n = len(data)
    if n <= 125:
        return struct.pack("BB", 0x81, n) + data
    elif n <= 65535:
        return struct.pack("!BBH", 0x81, 126, n) + data
    else:
        return struct.pack("!BBQ", 0x81, 127, n) + data


def _ws_read_frame(sock) -> tuple:
    """Returns (opcode, payload). Returns (8, b'') on close/error."""
    try:
        header = _recv_exact(sock, 2)
        if not header:
            return 8, b""
        opcode = header[0] & 0x0F
        length = header[1] & 0x7F
        if length == 126:
            length = struct.unpack("!H", _recv_exact(sock, 2))[0]
        elif length == 127:
            length = struct.unpack("!Q", _recv_exact(sock, 8))[0]
        masked = (header[1] & 0x80) != 0
        mask = _recv_exact(sock, 4) if masked else b"\x00\x00\x00\x00"
        payload = bytearray(_recv_exact(sock, length))
        if masked:
            for i in range(len(payload)):
                payload[i] ^= mask[i % 4]
        return opcode, bytes(payload)
    except Exception:
        return 8, b""


def _recv_exact(sock, n: int) -> bytes:
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            return buf
        buf += chunk
    return buf


def _broadcast(msg: str):
    frame = _ws_encode(msg)
    with _lock:
        clients = set(_state["ws_clients"])
    dead = set()
    for sock in clients:
        try:
            sock.sendall(frame)
        except Exception:
            dead.add(sock)
    if dead:
        with _lock:
            _state["ws_clients"] -= dead


# ── HTTP handler ───────────────────────────────────────────────────────────
class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass  # silence default access log

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/ws":
            self._handle_ws()
        elif path == "/reload":
            with _lock:
                version = _state["render_version"]
            self._json({"version": version})
        else:
            with _lock:
                html_body = _state["html_cache"]
            page = _build_page(html_body, THEME)
            self._html(page)

    def do_POST(self):
        path = urlparse(self.path).path
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length else b""
        try:
            data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            data = {}

        if path == "/render":
            filepath = data.get("file", "")
            if filepath:
                with _lock:
                    _state["file"] = filepath
            version = _do_render()
            _broadcast(json.dumps({"type": "reload", "version": version}))
            self._json({"ok": True, "version": version})
        elif path == "/scroll":
            line = data.get("line", 0)  # 1-indexed source line from Neovim
            _broadcast(json.dumps({"type": "scroll", "line": line}))
            self._json({"ok": True, "line": line})
        else:
            self.send_response(404)
            self.end_headers()

    def _html(self, content: str):
        encoded = content.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def _json(self, data: dict):
        encoded = json.dumps(data).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def _handle_ws(self):
        _ws_handshake(self)
        sock = self.connection
        with _lock:
            _state["ws_clients"].add(sock)
        try:
            while True:
                opcode, _ = _ws_read_frame(sock)
                if opcode == 8:  # close
                    break
        finally:
            with _lock:
                _state["ws_clients"].discard(sock)


# ── stdin reader thread ────────────────────────────────────────────────────
def _stdin_reader():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue

        mtype = msg.get("type", "")
        if mtype == "quit":
            os._exit(0)
        elif mtype == "render":
            filepath = msg.get("file", "")
            if filepath:
                with _lock:
                    _state["file"] = filepath
            version = _do_render()
            _broadcast(json.dumps({"type": "reload", "version": version}))
        elif mtype == "scroll":
            line = msg.get("line", 0)  # 1-indexed source line from Neovim
            _broadcast(json.dumps({"type": "scroll", "line": line}))


# ── Main ───────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    # Initial render
    _do_render()

    # Start stdin reader
    t = threading.Thread(target=_stdin_reader, daemon=True)
    t.start()

    # Start HTTP server
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"[md-preview] Serving on http://localhost:{PORT}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
