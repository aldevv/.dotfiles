#!/usr/bin/env python3
"""
Record a posted PR/MR comment in references/examples.md with dedup + count.

Usage:
  scripts/record_example.py --category "<heading>" --body "<comment text>"

Behavior:
  - Reads references/examples.md (relative to this script).
  - Locates `### <category>` under `## Answers`. Creates the heading if missing.
  - If a bullet with the same body text already exists in that category,
    increments its `(×N)` counter. Otherwise appends a new
    `- <body> (×1)` bullet.
  - Bodies are normalized (collapsed whitespace) before comparison so trivial
    formatting differences don't fragment the dedup.
  - Refuses (exit 2) a body containing any term from the private denylists,
    so employer names and work concepts never land in this public corpus.
    Denylists: colon-separated paths in $HUMANIZE_DENYLIST, else
    $WORK/.claude/humanize/denylist.txt. One term per line, `re:` prefix for a
    regex, `#` for comments. Genericize the body and re-run on refusal.

Common categories:
  - Replies — agreeing or already done
  - Replies — pushback
  - Replies — clarifying / asking back
  - New line comments — feedback
  - New line comments — nit
  - Top-level PR/MR comments
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

EXAMPLES_PATH = Path(__file__).resolve().parent.parent / "references" / "examples.md"
ANSWERS_HEADING = "## Answers"
CATEGORY_RE = re.compile(r"^###\s+(.+?)\s*$")
BULLET_RE = re.compile(r"^- (.*?)\s+\(×(\d+)\)\s*$")


def normalize(body: str) -> str:
    """Collapse whitespace so equivalent comments dedup correctly."""
    return " ".join(body.split())


def denylist_paths() -> list[Path]:
    raw = os.environ.get("HUMANIZE_DENYLIST")
    if raw:
        return [Path(p).expanduser() for p in raw.split(":") if p]
    work = os.environ.get("WORK")
    return [Path(work) / ".claude" / "humanize" / "denylist.txt"] if work else []


def load_patterns(paths: list[Path]) -> list[re.Pattern[str]]:
    patterns = []
    for path in paths:
        if not path.exists():
            continue
        for line in path.read_text().splitlines():
            term = line.strip()
            if not term or term.startswith("#"):
                continue
            if term.startswith("re:"):
                patterns.append(re.compile(term[3:]))
            else:
                patterns.append(re.compile(rf"(?<!\w){re.escape(term)}(?!\w)", re.I))
    return patterns


def denied_terms(body: str, patterns: list[re.Pattern[str]]) -> list[str]:
    return sorted({m.group(0) for p in patterns for m in [p.search(body)] if m})


def find_section_bounds(lines: list[str], heading: str) -> tuple[int, int] | None:
    """Return (start, end) line indices for the section under `heading`,
    where end is the index of the next `## ` heading or len(lines)."""
    try:
        start = lines.index(heading)
    except ValueError:
        return None
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].startswith("## "):
            end = j
            break
    return start, end


def find_category_bounds(
    lines: list[str], answers_start: int, answers_end: int, category: str
) -> tuple[int, int] | None:
    """Within the Answers section, return (start, end) of the matching `### category`
    block, where end is the next `### ` / `## ` heading or answers_end."""
    for j in range(answers_start + 1, answers_end):
        m = CATEGORY_RE.match(lines[j])
        if m and m.group(1).strip() == category:
            cat_start = j
            cat_end = answers_end
            for k in range(j + 1, answers_end):
                if lines[k].startswith("### ") or lines[k].startswith("## "):
                    cat_end = k
                    break
            return cat_start, cat_end
    return None


def trim_trailing_blanks(lines: list[str], hi: int) -> int:
    while hi > 0 and lines[hi - 1] == "":
        hi -= 1
    return hi


def record(lines: list[str], category: str, body: str) -> list[str]:
    body_norm = normalize(body)

    answers = find_section_bounds(lines, ANSWERS_HEADING)
    if answers is None:
        # No Answers section — append one with the new category and bullet.
        if lines and lines[-1] != "":
            lines.append("")
        lines.extend(
            [
                ANSWERS_HEADING,
                "",
                f"### {category}",
                "",
                f"- {body_norm} (×1)",
                "",
            ]
        )
        return lines

    answers_start, answers_end = answers
    cat = find_category_bounds(lines, answers_start, answers_end, category)

    if cat is None:
        # Category missing — insert at the end of the Answers section.
        insert_at = trim_trailing_blanks(lines, answers_end)
        block: list[str] = []
        # Exactly one blank separator between the previous content and the new
        # heading. If the line above is already blank, nothing extra is needed.
        if insert_at > 0 and lines[insert_at - 1] != "":
            block.append("")
        block += [f"### {category}", "", f"- {body_norm} (×1)"]
        lines[insert_at:insert_at] = block
        return lines

    cat_start, cat_end = cat
    # Look for an existing bullet with this body and bump it.
    for j in range(cat_start + 1, cat_end):
        m = BULLET_RE.match(lines[j])
        if m and normalize(m.group(1)) == body_norm:
            count = int(m.group(2)) + 1
            lines[j] = f"- {body_norm} (×{count})"
            return lines

    # No existing bullet — append after the last one.
    insert_at = trim_trailing_blanks(lines, cat_end)
    lines.insert(insert_at, f"- {body_norm} (×1)")
    return lines


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[1])
    parser.add_argument("--category", required=True, help="### heading under ## Answers")
    parser.add_argument("--body", required=True, help="exact comment text that was posted")
    args = parser.parse_args()

    if not normalize(args.body):
        print("record_example: empty body, nothing to record", file=sys.stderr)
        return 1

    hits = denied_terms(args.body, load_patterns(denylist_paths()))
    if hits:
        print(
            f"record_example: refused, body has private terms {hits}. "
            "genericize it (placeholders like <vendor>, <field>, <TICKET>) and re-run.",
            file=sys.stderr,
        )
        return 2

    if not EXAMPLES_PATH.exists():
        print(f"record_example: missing {EXAMPLES_PATH}", file=sys.stderr)
        return 1

    original = EXAMPLES_PATH.read_text()
    lines = original.splitlines()
    updated = record(lines, args.category.strip(), args.body)
    text = "\n".join(updated)
    if not text.endswith("\n"):
        text += "\n"
    if text != original:
        EXAMPLES_PATH.write_text(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
