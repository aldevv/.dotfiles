#!/usr/bin/env python3
"""Pull review-request messages out of a Slack channel history dump into a markdown examples file.

Input is Slack conversations.history JSON: an object with `messages` (or `data.messages`), or a bare
list of messages. Leading non-JSON noise is skipped.
Usage: extract_examples.py <history.json> --channel NAME [--self-id UXXXX] [--out PATH] [--limit N]
       extract_examples.py --selftest
"""
import argparse
import json
import os
import re
import sys

REVIEW_LINK = re.compile(r"/merge_requests/\d+|/pull/\d+|/pipelines/\d+")
SLACK_LINK = re.compile(r"<(https?://[^|>]+)(?:\|[^>]*)?>")
SLACK_CHANNEL = re.compile(r"<#C[A-Z0-9]+\|([^>]+)>")
SLACK_USER = re.compile(r"<@(U[A-Z0-9]+)>")


def default_path(channel):
    cache = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    return os.path.join(cache, "slack-request-review", f"{channel}.md")


def load_messages(raw):
    starts = [i for i in (raw.find("{"), raw.find("[")) if i >= 0]
    if not starts:
        sys.exit("input is not JSON. Pick the review requests by hand and write the examples file directly.")
    data = json.loads(raw[min(starts):])
    if isinstance(data, list):
        return data
    return data.get("messages") or data.get("data", {}).get("messages") or []


def clean(text):
    text = SLACK_LINK.sub(r"\1", text)
    text = SLACK_CHANNEL.sub(r"#\1", text)
    text = SLACK_USER.sub(r"@\1", text)
    return text.replace("&gt;", ">").replace("&lt;", "<").replace("&amp;", "&").strip()


def is_review_request(msg):
    return not msg.get("subtype") and bool(REVIEW_LINK.search(msg.get("text", "")))


def render(messages, channel, self_id, limit):
    picked = [m for m in messages if is_review_request(m)][:limit]
    is_mine = lambda m: bool(self_id) and m.get("user") == self_id
    mine = [clean(m["text"]) for m in picked if is_mine(m)]
    team = [clean(m["text"]) for m in picked if not is_mine(m)]
    out = [f"# Review requests in #{channel}", "", "Newest first. Mine = the operator's own voice.", ""]
    for title, items in (("## Mine", mine), ("## Team", team)):
        out += [title, ""] + [f"- {t.replace(chr(10), ' / ')}" for t in items] + [""]
    return "\n".join(out), len(mine)


def selftest():
    msgs = [
        {"user": "U1", "text": "hello team, need a review <https://git.example/x/-/merge_requests/1|x/1>"},
        {"user": "U2", "text": "Could someone review this: <https://git.example/y/pull/2> CC: <@U9> in <#C1|ops>"},
        {"user": "U2", "text": "approved https://docs.example/page"},
        {"user": "U2", "subtype": "channel_join", "text": "joined https://git.example/z/pull/3"},
    ]
    md, n_mine = render(msgs, "dev", "U1", 10)
    assert n_mine == 1
    assert "- hello team, need a review https://git.example/x/-/merge_requests/1" in md
    assert "https://git.example/y/pull/2 CC: @U9 in #ops" in md
    assert "approved" not in md and "joined" not in md
    assert md.index("## Mine") < md.index("hello team") < md.index("## Team")
    assert load_messages('noise {"data": {"messages": [1]}}') == [1]
    assert load_messages('[{"text": "x"}]') == [{"text": "x"}]
    print("selftest ok")


def main():
    if "--selftest" in sys.argv:
        return selftest()
    p = argparse.ArgumentParser()
    p.add_argument("history")
    p.add_argument("--channel", required=True)
    p.add_argument("--self-id")
    p.add_argument("--out")
    p.add_argument("--limit", type=int, default=60)
    a = p.parse_args()
    channel = a.channel.lstrip("#").lower()
    md, n_mine = render(load_messages(open(a.history).read()), channel, a.self_id, a.limit)
    if n_mine == 0:
        print("warning: no messages matched --self-id, ## Mine is empty", file=sys.stderr)
    out = a.out or default_path(channel)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "w").write(md)
    print(out)


if __name__ == "__main__":
    main()
