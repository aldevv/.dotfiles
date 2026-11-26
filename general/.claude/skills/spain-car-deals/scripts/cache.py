#!/usr/bin/env python3
"""Listing cache for spain-car-deals.

  cache.py check CARDS.jsonl   tag each card {url, price, km} as new / changed / unchanged
  cache.py save EVALUATED.jsonl  store evaluated listings (any fields, must have url, price, km)
  cache.py selftest
"""
import json
import os
import sys
import tempfile
from datetime import date

CACHE = os.path.expanduser(os.environ.get("SPAIN_CAR_CACHE", "~/.cache/spain-car-deals/listings.json"))
PRUNE_DAYS = 30


def load():
    if not os.path.exists(CACHE):
        return {}
    with open(CACHE) as f:
        return json.load(f)


def store(cache):
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    tmp = CACHE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(cache, f, ensure_ascii=False, indent=1)
    os.replace(tmp, CACHE)


def read_jsonl(path):
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def tag(card, cache):
    cached = cache.get(card["url"])
    if cached is None:
        return {**card, "status": "new"}
    is_same = (cached.get("price"), cached.get("km")) == (card.get("price"), card.get("km"))
    if is_same:
        return {**cached, **card, "status": "unchanged"}
    return {**card, "status": "changed", "old_price": cached.get("price"), "old_km": cached.get("km")}


def check(path):
    cache = load()
    for card in read_jsonl(path):
        print(json.dumps(tag(card, cache), ensure_ascii=False))


def save(path):
    cache = load()
    today = date.today().isoformat()
    for rec in read_jsonl(path):
        rec.pop("status", None)
        first_seen = cache.get(rec["url"], {}).get("first_seen", today)
        cache[rec["url"]] = {**rec, "first_seen": first_seen, "last_seen": today}
    cutoff = date.today().toordinal() - PRUNE_DAYS
    cache = {u: r for u, r in cache.items() if date.fromisoformat(r["last_seen"]).toordinal() >= cutoff}
    store(cache)
    print(f"cached {len(cache)} listings")


def selftest():
    global CACHE
    with tempfile.TemporaryDirectory() as d:
        CACHE = os.path.join(d, "c.json")
        evaluated = os.path.join(d, "e.jsonl")
        with open(evaluated, "w") as f:
            f.write(json.dumps({"url": "a", "price": 100, "km": 5, "verdict": "good"}) + "\n")
        save(evaluated)
        cache = load()
        assert tag({"url": "a", "price": 100, "km": 5}, cache)["status"] == "unchanged"
        assert tag({"url": "a", "price": 100, "km": 5}, cache)["verdict"] == "good"
        dropped = tag({"url": "a", "price": 90, "km": 5}, cache)
        assert dropped["status"] == "changed" and dropped["old_price"] == 100
        assert tag({"url": "b", "price": 1, "km": 1}, cache)["status"] == "new"
    print("selftest ok")


if __name__ == "__main__":
    cmd, *args = sys.argv[1:] or ["help"]
    {"check": check, "save": save, "selftest": selftest}.get(cmd, lambda *_: print(__doc__))(*args)
