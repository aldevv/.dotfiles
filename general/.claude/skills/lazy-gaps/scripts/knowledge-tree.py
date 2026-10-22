#!/usr/bin/env python3
"""Print lazy-gaps' knowledge tree as JSON, built fresh from disk on every run.

Tiers: global (~/CLAUDE.md, ~/.claude/lazy, ~/.claude/rules), workspace ($WORK, default ~/work: CLAUDE.md,
.claude/lazy, .claude/scripts), repo (git root of cwd or argv[1]:
CLAUDE.md, CLAUDE.local.md, .claude/lazy). Each rule file lists its headings and the
"Read when" trigger taken from the governing CLAUDE.md index. Generated, never stored,
so it can't drift from the files.
"""
import json, os, re, subprocess, sys

HOME = os.path.expanduser('~')
WORK = os.environ.get('WORK', os.path.join(HOME, 'work'))


def headings(path):
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            return [l.rstrip() for l in f if re.match(r'^#{2,3} ', l)]
    except OSError:
        return []


def triggers(claude_md):
    """Map lazy-file basename -> Read-when text from a CLAUDE.md index."""
    out = {}
    try:
        lines = open(claude_md, encoding='utf-8', errors='replace').read().splitlines()
    except OSError:
        return out
    i = 0
    while i < len(lines):
        m = re.match(r'^- \[[^\]]*\]\(([^)]*\.md)\)', lines[i])
        if m:
            text = [lines[i]]
            j = i + 1
            while j < len(lines) and (lines[j].startswith('  ') or lines[j].startswith('\t')):
                text.append(lines[j].strip())
                j += 1
            joined = ' '.join(text)
            w = re.search(r'\*\*Read when[^*]*\*\*:?\s*(.*)', joined)
            out[os.path.basename(m.group(1))] = (w.group(1) if w else joined)[:400]
            i = j
        else:
            i += 1
    return out


def tier(name, index_files, globs, extra_files=()):
    trig = {}
    for c in index_files:
        trig.update(triggers(c))
    files = []
    for f in list(extra_files) + index_files:
        if os.path.isfile(f):
            files.append({'path': f, 'kind': 'claude-md', 'headings': headings(f)})
    for d, pattern in globs:
        if not os.path.isdir(d):
            continue
        for root, _, names in os.walk(d):
            for n in sorted(names):
                if not re.search(pattern, n):
                    continue
                p = os.path.join(root, n)
                entry = {'path': p, 'kind': 'script' if n.endswith(('.py', '.sh')) else ('rule' if '/.claude/rules' in root else 'lazy')}
                if entry['kind'] in ('lazy', 'rule'):
                    entry['trigger'] = trig.get(n)
                    entry['headings'] = headings(p)
                files.append(entry)
    return {'tier': name, 'files': files}


def git_root(start):
    try:
        return subprocess.check_output(['git', '-C', start, 'rev-parse', '--show-toplevel'],
                                       stderr=subprocess.DEVNULL, text=True).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


start = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
tiers = [
    tier('global', [os.path.join(HOME, 'CLAUDE.md')],
         [(os.path.join(HOME, '.claude/lazy'), r'\.md$'), (os.path.join(HOME, '.claude/rules'), r'\.md$')]),
    tier('workspace', [os.path.join(WORK, 'CLAUDE.md')],
         [(os.path.join(WORK, '.claude/lazy'), r'\.md$'), (os.path.join(WORK, '.claude/scripts'), r'\.(py|sh)$')]),
]
root = git_root(start)
if root and os.path.realpath(root) not in (os.path.realpath(HOME), os.path.realpath(WORK)):
    tiers.append(tier('repo', [p for p in (os.path.join(root, 'CLAUDE.local.md'), os.path.join(root, 'CLAUDE.md')) if os.path.isfile(p)],
                      [(os.path.join(root, '.claude/lazy'), r'\.md$')]))
json.dump({'root': root, 'tiers': tiers}, sys.stdout, indent=1)
print()
