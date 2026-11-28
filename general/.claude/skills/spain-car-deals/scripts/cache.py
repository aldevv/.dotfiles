#!/usr/bin/env python3
"""Listing cache for spain-car-deals.

  cache.py check CARDS.jsonl   tag each card {url, price, km, year} as new / price_drop / price_up / unchanged, with an emoji
  cache.py save EVALUATED.jsonl  store evaluated listings (any fields, must have url, price, km; set reported=true on report rows)
  cache.py gone CARDS.jsonl    previously reported listings missing from today's cards
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


EMOJI = {"new": "\U0001F195", "price_drop": "\U0001F4C9", "price_up": "\U0001F4C8", "unchanged": "\U0001F440", "gone": "\u274C"}


def same_car_elsewhere(card, cache):
    km = card.get("km")
    if not km:
        return None
    return next((r for r in cache.values() if r.get("km") == km and is_close_year(r.get("year"), card.get("year"))), None)


def is_close_year(a, b):
    if not a or not b:
        return True
    return abs(int(a) - int(b)) <= 1


def status_of(card, cached):
    old_price, new_price = cached.get("price"), card.get("price")
    if old_price is None or new_price is None or old_price == new_price:
        return "unchanged"
    return "price_drop" if new_price < old_price else "price_up"


def tag(card, cache):
    cached = cache.get(card["url"]) or same_car_elsewhere(card, cache)
    if cached is None:
        return {**card, "status": "new", "emoji": EMOJI["new"]}
    status = status_of(card, cached)
    if status == "unchanged" and cached.get("km") == card.get("km"):
        return {**cached, **card, "status": status, "emoji": EMOJI[status]}
    return {**card, "status": status, "emoji": EMOJI[status], "old_price": cached.get("price"), "old_km": cached.get("km")}


def gone(path):
    cache = load()
    seen_today = {c["url"] for c in read_jsonl(path)}
    for url, rec in cache.items():
        if rec.get("reported") and url not in seen_today:
            print(json.dumps({**rec, "status": "gone", "emoji": EMOJI["gone"]}, ensure_ascii=False))


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
            f.write(json.dumps({"url": "a", "price": 100, "km": 5, "verdict": "good", "reported": True}) + "\n")
        save(evaluated)
        cache = load()
        assert tag({"url": "a", "price": 100, "km": 5}, cache)["status"] == "unchanged"
        assert tag({"url": "a", "price": 100, "km": 5}, cache)["verdict"] == "good"
        dropped = tag({"url": "a", "price": 90, "km": 5}, cache)
        assert dropped["status"] == "price_drop" and dropped["old_price"] == 100
        assert tag({"url": "a", "price": 110, "km": 5}, cache)["status"] == "price_up"
        assert tag({"url": "b", "price": 1, "km": 1}, cache)["status"] == "new"
        # same car cross-posted on another site keeps its history instead of looking new
        assert tag({"url": "other-site", "price": 100, "km": 5}, cache)["status"] == "unchanged"
        assert tag({"url": "other-site", "price": 100, "km": 5, "year": 2021}, cache)["status"] == "unchanged"
    print("selftest ok")


if __name__ == "__main__":
    cmd, *args = sys.argv[1:] or ["help"]
    {"check": check, "save": save, "gone": gone, "selftest": selftest}.get(cmd, lambda *_: print(__doc__))(*args)
