#!/usr/bin/env -S python3 -I
"""Stop hook: in a dispatched auto-new-day window, block a turn that ends by
asking the operator to decide. The run must decide, act, and log the call in
the closing report's `## Decisions made` table instead.

Only enforced while the turn was started by a slash-command prompt (the
dispatch prompt or a /loop tick). Once the operator types a plain message in
the window, questions are allowed again. Allows the second attempt
(stop_hook_active) so it can never loop.
"""
import json, os, re, sys

QUESTION = re.compile(
    r"\b(should|shall) i\b|\bwant me to\b|\bdo you want\b|\bwould you like\b"
    r"|\blet me know (if|whether|which|how)\b|\bplease confirm\b|\bcan you confirm\b"
    r"|\bwhich (one|option|approach) (do|would|should) you\b|\byour call\b|\byou decide\b",
    re.I,
)


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
    return ""


def main():
    if not os.environ.get("AUTO_NEW_DAY_DATE_DIR"):
        return
    data = json.load(sys.stdin)
    if data.get("stop_hook_active"):
        return
    last_user, last_assistant = "", data.get("last_assistant_message") or ""
    try:
        with open(data.get("transcript_path") or "") as fh:
            for line in fh:
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                msg = e.get("message") or {}
                if e.get("type") == "user" and not e.get("isMeta"):
                    t = text_of(msg.get("content")).strip()
                    cmd = re.search(r"<command-name>(/[^<]+)</command-name>", t)
                    if cmd:
                        last_user = cmd.group(1)
                    elif t and not t.startswith("<"):
                        last_user = t
                elif e.get("type") == "assistant" and not data.get("last_assistant_message"):
                    t = text_of(msg.get("content"))
                    if t.strip():
                        last_assistant = t
    except OSError:
        return
    if not last_user.startswith("/"):
        return
    body = re.sub(r"```.*?```", "", last_assistant, flags=re.S)
    hits = sorted({m.group(0).lower() for m in QUESTION.finditer(body)})
    if not hits:
        return
    print(json.dumps({
        "decision": "block",
        "reason": (
            "Autonomous auto-new-day run: the reply asks the operator to decide (" + ", ".join(hits) + "). "
            "Nobody is watching this window. Research it, decide, act, and record the call as a row in "
            "the closing report's `## Decisions made` table. Put only a genuine operator-only item under "
            "`Needs you:` with the safe default already applied and your recommended answer, stated as a "
            "fact, not a question. Then end the turn."
        ),
    }))


if __name__ == "__main__":
    main()
