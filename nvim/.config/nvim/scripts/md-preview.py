#!/usr/bin/env python3
"""
Render a markdown file to HTML and open it in a dedicated window.
Primary: marked.js via CDN (no external tools needed, same quality as a browser renderer).
Offline fallback: pandoc (auto-installed if missing) > python-markdown > plain text.
Opens in Chrome/Chromium app mode for a dedicated window, falls back to default browser.
"""
import sys
import os
import json
import subprocess
import shutil
import tempfile
import platform

CSS_DARK = """
:root {
    --color-text-primary: #c9d1d9;
    --color-text-tertiary: #8b949e;
    --color-text-link: #58a6ff;
    --color-bg-primary: #0d1117;
    --color-bg-secondary: #0d1117;
    --color-bg-tertiary: #161b22;
    --color-border-primary: #30363d;
    --color-border-secondary: #21262d;
    --color-border-tertiary: #6e7681;
    --color-kbd-foreground: #b1bac4;
    --color-markdown-blockquote-border: #3b434b;
    --color-markdown-table-border: #3b434b;
    --color-markdown-table-tr-border: #272c32;
    --color-markdown-code-bg: #f0f6fc26;
}
html, body { min-height: 100vh; margin: 0; background-color: var(--color-bg-primary); }
#page-ctn { margin: 0 auto; max-width: 900px; padding: 20px; color: var(--color-text-primary); }
.markdown-body ol ol, .markdown-body ul ol, .markdown-body ol ul, .markdown-body ul ul,
.markdown-body ol ul ol, .markdown-body ul ul ol, .markdown-body ol ul ul, .markdown-body ul ul ul {
    margin-top: 0; margin-bottom: 0;
}
.markdown-body {
    font-family: "Helvetica Neue", Helvetica, "Segoe UI", Arial, freesans, sans-serif;
    font-size: 16px; color: var(--color-text-primary); line-height: 1.6;
    word-wrap: break-word; padding: 45px; background: var(--color-bg-primary);
    border: 1px solid var(--color-border-primary); border-radius: 0 0 3px 3px;
}
.markdown-body > *:first-child { margin-top: 0 !important; }
.markdown-body > *:last-child { margin-bottom: 0 !important; }
.markdown-body * { box-sizing: border-box; }
.markdown-body h1, .markdown-body h2, .markdown-body h3,
.markdown-body h4, .markdown-body h5, .markdown-body h6 {
    margin-top: 1em; margin-bottom: 16px; font-weight: bold; line-height: 1.4;
}
.markdown-body p, .markdown-body blockquote, .markdown-body ul, .markdown-body ol,
.markdown-body dl, .markdown-body table, .markdown-body pre {
    margin-top: 0; margin-bottom: 16px;
}
.markdown-body h1 { margin: 0.67em 0; padding-bottom: 0.3em; font-size: 2.25em; line-height: 1.2; border-bottom: 1px solid var(--color-border-secondary); }
.markdown-body h2 { padding-bottom: 0.3em; font-size: 1.75em; line-height: 1.225; border-bottom: 1px solid var(--color-border-secondary); }
.markdown-body h3 { font-size: 1.5em; line-height: 1.43; }
.markdown-body h4 { font-size: 1.25em; }
.markdown-body h5 { font-size: 1em; }
.markdown-body h6 { font-size: 1em; color: var(--color-text-tertiary); }
.markdown-body hr { margin-top: 20px; margin-bottom: 20px; height: 0; border: 0; border-top: 1px solid var(--color-border-primary); }
.markdown-body ol, .markdown-body ul { padding-left: 2em; }
.markdown-body ol ol, .markdown-body ul ol { list-style-type: lower-roman; }
.markdown-body ol ul, .markdown-body ul ul { list-style-type: circle; }
.markdown-body ol ul ul, .markdown-body ul ul ul { list-style-type: square; }
.markdown-body ol { list-style-type: decimal; }
.markdown-body ul { list-style-type: disc; }
.markdown-body blockquote { margin: 0; padding: 0 15px; color: var(--color-text-tertiary); border-left: 4px solid var(--color-markdown-blockquote-border); }
.markdown-body table { display: block; width: 100%; overflow: auto; border-collapse: collapse; border-spacing: 0; }
.markdown-body table tr { background-color: var(--color-bg-primary); border-top: 1px solid var(--color-markdown-table-tr-border); }
.markdown-body table tr:nth-child(2n) { background-color: var(--color-bg-tertiary); }
.markdown-body table th, .markdown-body table td { padding: 6px 13px; border: 1px solid var(--color-markdown-table-border); vertical-align: top; }
.markdown-body table th { font-weight: 600; }
.markdown-body kbd { display: inline-block; padding: 5px 6px; font: 14px SFMono-Regular,Consolas,monospace; line-height: 10px; color: var(--color-kbd-foreground); vertical-align: middle; background-color: var(--color-bg-secondary); border: 1px solid var(--color-border-tertiary); border-radius: 3px; box-shadow: inset 0 -1px 0 var(--color-border-tertiary); }
.markdown-body pre { word-wrap: normal; padding: 16px; overflow: auto; font-size: 85%; line-height: 1.45; background-color: var(--color-bg-tertiary); border-radius: 3px; }
.markdown-body pre code { display: inline; max-width: initial; padding: 0; margin: 0; overflow: initial; font-size: 100%; line-height: inherit; word-wrap: normal; white-space: pre; border: 0; border-radius: 3px; background-color: transparent; }
.markdown-body code { font-family: Consolas,"Liberation Mono",Menlo,Courier,monospace; padding: 0.2em 0.4em; margin: 0; font-size: 85%; background-color: var(--color-markdown-code-bg); border-radius: 3px; }
.markdown-body a { color: var(--color-text-link); text-decoration: none; }
.markdown-body a:hover { text-decoration: underline; }
.markdown-body img { max-width: 100%; max-height: 100%; }
.markdown-body strong { font-weight: bold; }
.markdown-body em { font-style: italic; }
.markdown-body del { text-decoration: line-through; }
.task-list-item { list-style-type: none; }
.task-list-item input { margin: 0 0.35em 0.25em -1.6em; vertical-align: middle; }
"""

CSS_LIGHT = """
:root {
    --color-text-primary: #333;
    --color-text-tertiary: #777;
    --color-text-link: #4078c0;
    --color-bg-primary: #fff;
    --color-bg-secondary: #fafbfc;
    --color-bg-tertiary: #f8f8f8;
    --color-border-primary: #ddd;
    --color-border-secondary: #eaecef;
    --color-border-tertiary: #d1d5da;
    --color-kbd-foreground: #444d56;
    --color-markdown-blockquote-border: #dfe2e5;
    --color-markdown-table-border: #dfe2e5;
    --color-markdown-table-tr-border: #c6cbd1;
    --color-markdown-code-bg: #1b1f230d;
}
html, body { min-height: 100vh; margin: 0; background-color: var(--color-bg-primary); }
#page-ctn { margin: 0 auto; max-width: 900px; padding: 20px; color: var(--color-text-primary); }
.markdown-body ol ol, .markdown-body ul ol, .markdown-body ol ul, .markdown-body ul ul,
.markdown-body ol ul ol, .markdown-body ul ul ol, .markdown-body ol ul ul, .markdown-body ul ul ul {
    margin-top: 0; margin-bottom: 0;
}
.markdown-body {
    font-family: "Helvetica Neue", Helvetica, "Segoe UI", Arial, freesans, sans-serif;
    font-size: 16px; color: var(--color-text-primary); line-height: 1.6;
    word-wrap: break-word; padding: 45px; background: var(--color-bg-primary);
    border: 1px solid var(--color-border-primary); border-radius: 0 0 3px 3px;
}
.markdown-body > *:first-child { margin-top: 0 !important; }
.markdown-body > *:last-child { margin-bottom: 0 !important; }
.markdown-body * { box-sizing: border-box; }
.markdown-body h1, .markdown-body h2, .markdown-body h3,
.markdown-body h4, .markdown-body h5, .markdown-body h6 {
    margin-top: 1em; margin-bottom: 16px; font-weight: bold; line-height: 1.4;
}
.markdown-body p, .markdown-body blockquote, .markdown-body ul, .markdown-body ol,
.markdown-body dl, .markdown-body table, .markdown-body pre {
    margin-top: 0; margin-bottom: 16px;
}
.markdown-body h1 { margin: 0.67em 0; padding-bottom: 0.3em; font-size: 2.25em; line-height: 1.2; border-bottom: 1px solid var(--color-border-secondary); }
.markdown-body h2 { padding-bottom: 0.3em; font-size: 1.75em; line-height: 1.225; border-bottom: 1px solid var(--color-border-secondary); }
.markdown-body h3 { font-size: 1.5em; line-height: 1.43; }
.markdown-body h4 { font-size: 1.25em; }
.markdown-body h5 { font-size: 1em; }
.markdown-body h6 { font-size: 1em; color: var(--color-text-tertiary); }
.markdown-body hr { margin-top: 20px; margin-bottom: 20px; height: 0; border: 0; border-top: 1px solid var(--color-border-primary); }
.markdown-body ol, .markdown-body ul { padding-left: 2em; }
.markdown-body ol ol, .markdown-body ul ol { list-style-type: lower-roman; }
.markdown-body ol ul, .markdown-body ul ul { list-style-type: circle; }
.markdown-body ol ul ul, .markdown-body ul ul ul { list-style-type: square; }
.markdown-body ol { list-style-type: decimal; }
.markdown-body ul { list-style-type: disc; }
.markdown-body blockquote { margin: 0; padding: 0 15px; color: var(--color-text-tertiary); border-left: 4px solid var(--color-markdown-blockquote-border); }
.markdown-body table { display: block; width: 100%; overflow: auto; border-collapse: collapse; border-spacing: 0; }
.markdown-body table tr { background-color: var(--color-bg-primary); border-top: 1px solid var(--color-markdown-table-tr-border); }
.markdown-body table tr:nth-child(2n) { background-color: var(--color-bg-tertiary); }
.markdown-body table th, .markdown-body table td { padding: 6px 13px; border: 1px solid var(--color-markdown-table-border); vertical-align: top; }
.markdown-body table th { font-weight: 600; }
.markdown-body kbd { display: inline-block; padding: 5px 6px; font: 14px SFMono-Regular,Consolas,monospace; line-height: 10px; color: var(--color-kbd-foreground); vertical-align: middle; background-color: var(--color-bg-secondary); border: 1px solid var(--color-border-tertiary); border-radius: 3px; box-shadow: inset 0 -1px 0 var(--color-border-tertiary); }
.markdown-body pre { word-wrap: normal; padding: 16px; overflow: auto; font-size: 85%; line-height: 1.45; background-color: var(--color-bg-tertiary); border-radius: 3px; }
.markdown-body pre code { display: inline; max-width: initial; padding: 0; margin: 0; overflow: initial; font-size: 100%; line-height: inherit; word-wrap: normal; white-space: pre; border: 0; border-radius: 3px; background-color: transparent; }
.markdown-body code { font-family: Consolas,"Liberation Mono",Menlo,Courier,monospace; padding: 0.2em 0.4em; margin: 0; font-size: 85%; background-color: var(--color-markdown-code-bg); border-radius: 3px; }
.markdown-body a { color: var(--color-text-link); text-decoration: none; }
.markdown-body a:hover { text-decoration: underline; }
.markdown-body img { max-width: 100%; max-height: 100%; }
.markdown-body strong { font-weight: bold; }
.markdown-body em { font-style: italic; }
.markdown-body del { text-decoration: line-through; }
.task-list-item { list-style-type: none; }
.task-list-item input { margin: 0 0.35em 0.25em -1.6em; vertical-align: middle; }
"""

THEMES = {
    "dark":  {"css": CSS_DARK,  "hljs": "github-dark"},
    "light": {"css": CSS_LIGHT, "hljs": "github"},
}

TEMPLATE_ONLINE = """\
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/{hljs_theme}.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <style>{css}</style>
</head>
<body>
  <div id="page-ctn"><div class="markdown-body" id="content"></div></div>
  <script>
    const src = {content_json};
    document.getElementById("content").innerHTML = marked.parse(src);
    hljs.highlightAll();
  </script>
</body>
</html>"""

TEMPLATE_OFFLINE = """\
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  <style>{css}</style>
</head>
<body>
  <div id="page-ctn"><div class="markdown-body">{body}</div></div>
</body>
</html>"""


# ── pandoc auto-install (offline fallback only) ───────────────────────────────

def _run_silent(cmd):
    return subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def ensure_pandoc():
    if shutil.which("pandoc"):
        return True

    system = platform.system()

    if system == "Darwin":
        if shutil.which("brew"):
            _run_silent(["brew", "install", "pandoc"])

    elif system == "Linux":
        for mgr, cmd in [
            ("apt-get", ["sudo", "apt-get", "install", "-y", "pandoc"]),
            ("dnf",     ["sudo", "dnf", "install", "-y", "pandoc"]),
            ("pacman",  ["sudo", "pacman", "-S", "--noconfirm", "pandoc"]),
            ("zypper",  ["sudo", "zypper", "install", "-y", "pandoc"]),
        ]:
            if shutil.which(mgr):
                _run_silent(cmd)
                break

    elif system == "Windows":
        for mgr, cmd in [
            ("winget", ["winget", "install", "--silent", "--id", "JohnMacFarlane.Pandoc"]),
            ("choco",  ["choco", "install", "pandoc", "-y"]),
            ("scoop",  ["scoop", "install", "pandoc"]),
        ]:
            if shutil.which(mgr):
                _run_silent(cmd)
                break

    return shutil.which("pandoc") is not None


# ── rendering ─────────────────────────────────────────────────────────────────

def strip_frontmatter(content):
    if content.startswith("---"):
        end = content.find("\n---", 3)
        if end != -1:
            return content[end + 4:].lstrip("\n")
    return content


def render_html(filepath, theme="dark"):
    title = os.path.basename(filepath)
    t = THEMES.get(theme, THEMES["dark"])

    with open(filepath, encoding="utf-8") as f:
        content = f.read()

    content = strip_frontmatter(content)
    content_json = json.dumps(content)
    return TEMPLATE_ONLINE.format(
        title=title,
        css=t["css"],
        hljs_theme=t["hljs"],
        content_json=content_json,
    )


def render_html_offline(filepath, theme="dark"):
    """Offline fallback: pandoc > python-markdown > plain text."""
    title = os.path.basename(filepath)
    css = THEMES.get(theme, THEMES["dark"])["css"]

    if ensure_pandoc():
        result = subprocess.run(
            ["pandoc", "--from=gfm", "--to=html5", filepath],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            return TEMPLATE_OFFLINE.format(title=title, css=css, body=result.stdout)

    try:
        import markdown as md
        with open(filepath, encoding="utf-8") as f:
            content = f.read()
        body = md.markdown(content, extensions=["fenced_code", "tables", "toc"])
        return TEMPLATE_OFFLINE.format(title=title, css=css, body=body)
    except ImportError:
        pass

    with open(filepath, encoding="utf-8") as f:
        content = f.read()
    escaped = content.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return TEMPLATE_OFFLINE.format(title=title, css=css, body=f"<pre>{escaped}</pre>")


# ── browser / window ──────────────────────────────────────────────────────────

def find_chrome():
    candidates = [
        "google-chrome",
        "google-chrome-stable",
        "chromium",
        "chromium-browser",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
        "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    ]
    for c in candidates:
        if shutil.which(c) or os.path.isfile(c):
            return c
    return None


def is_online():
    import socket
    try:
        socket.setdefaulttimeout(2)
        socket.create_connection(("cdn.jsdelivr.net", 443))
        return True
    except OSError:
        return False


def open_preview(filepath, theme="dark"):
    filepath = os.path.abspath(filepath)
    html = render_html(filepath, theme) if is_online() else render_html_offline(filepath, theme)

    tmp = tempfile.NamedTemporaryFile(
        suffix=".html", delete=False, mode="w", encoding="utf-8"
    )
    tmp.write(html)
    tmp.close()

    chrome = find_chrome()
    if chrome:
        subprocess.Popen([chrome, f"--app=file://{tmp.name}"])
        return

    system = platform.system()
    if system == "Darwin":
        subprocess.Popen(["open", tmp.name])
    elif system == "Windows":
        os.startfile(tmp.name)
    else:
        subprocess.Popen(["xdg-open", tmp.name])


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: md-preview.py <file.md> [dark|light]", file=sys.stderr)
        sys.exit(1)
    theme = sys.argv[2] if len(sys.argv) > 2 else "dark"
    open_preview(sys.argv[1], theme)
