#!/usr/bin/env -S python3 -I
"""SessionStart hook: in a dispatched auto-new-day window, inject the active
profile's `session_context_files` so the child has them before its first step,
without depending on the model choosing to read them.

Hook output above ~10k characters is replaced by a 2KB preview, so the
concatenated files are split at `## `/`### ` headings into chunks under
LIMIT, and chunk N is emitted by the hook entry invoked with argument N.
"""
import json, os, re, sys

LIMIT = 9000


def chunks(text):
    parts = re.split(r"(?m)^(?=#{2,3} )", text)
    out, cur = [], ""
    for p in parts:
        while len(p) > LIMIT:
            if cur:
                out.append(cur)
                cur = ""
            out.append(p[:LIMIT])
            p = p[LIMIT:]
        if len(cur) + len(p) > LIMIT:
            out.append(cur)
            cur = ""
        cur += p
    if cur.strip():
        out.append(cur)
    return [c for c in out if c.strip()]


def main():
    if not os.environ.get("AUTO_NEW_DAY_DATE_DIR"):
        return
    idx = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    prof = os.environ.get("AUTO_NEW_DAY_PROFILE") or os.path.expanduser("~/.config/auto-new-day/profile.json")
    try:
        files = json.load(open(prof)).get("session_context_files") or []
    except (OSError, ValueError):
        return
    text = ""
    for f in files:
        path = os.path.expanduser(f)
        try:
            text += f"\n\n<!-- session context: {f} -->\n" + open(path).read()
        except OSError:
            text += f"\n\n<!-- session context: {f} is missing -->\n"
    cs = chunks(text)
    if idx >= len(cs):
        return
    head = f"[auto-new-day session context, part {idx + 1} of {len(cs)}]\n"
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": head + cs[idx]}}))


if __name__ == "__main__":
    main()
