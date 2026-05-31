"""Parse and replace lazy-load trigger blocks in CLAUDE.md files."""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass
class TriggerBlock:
    target_path: str
    target_basename: str
    target_abs: Path | None
    block_text: str
    start_line: int
    end_line: int


_ENTRY_RE = re.compile(r"^- \[`([^`]+)`\]\(([^)]+)\)\. \*\*Read when\*\*", re.MULTILINE)


def _resolve_home(path: str) -> Path | None:
    if path.startswith("~"):
        return Path(os.path.expanduser(path))
    if path.startswith("/"):
        return Path(path)
    return None


def find_trigger_blocks(claude_md_path: Path) -> list[TriggerBlock]:
    content = claude_md_path.read_text()
    lines = content.split("\n")
    blocks = []

    matches = list(_ENTRY_RE.finditer(content))
    for i, m in enumerate(matches):
        start_offset = m.start()
        start_line = content[:start_offset].count("\n")

        end_offset = matches[i + 1].start() if i + 1 < len(matches) else None
        if end_offset is None:
            tail = content[start_offset:]
            section_break = re.search(r"\n(?=## )", tail)
            end_offset = start_offset + section_break.start() if section_break else len(content)

        block_text = content[start_offset:end_offset].rstrip() + "\n"
        end_line = start_line + block_text.count("\n")
        target = m.group(1)
        blocks.append(
            TriggerBlock(
                target_path=target,
                target_basename=Path(target).name,
                target_abs=_resolve_home(target),
                block_text=block_text,
                start_line=start_line,
                end_line=end_line,
            )
        )
    return blocks


def find_trigger(claude_md_path: Path, identifier: str) -> TriggerBlock | None:
    blocks = find_trigger_blocks(claude_md_path)
    ident_expanded = os.path.expanduser(identifier)
    ident_lower = identifier.lower()
    ident_exp_lower = ident_expanded.lower()
    for b in blocks:
        if b.target_path == identifier or b.target_basename == identifier:
            return b
        b_expanded = os.path.expanduser(b.target_path)
        if b_expanded == ident_expanded:
            return b
    for b in blocks:
        b_expanded_lower = os.path.expanduser(b.target_path).lower()
        if ident_lower in b.target_path.lower() or ident_lower in b.target_basename.lower():
            return b
        if ident_exp_lower in b_expanded_lower:
            return b
    return None


def swap_block_in_text(content: str, old_block: str, new_block: str) -> str:
    """In-memory equivalent of replace_trigger: swap old_block for new_block in content.

    Raises ValueError if the old block is not present.
    """
    if old_block.rstrip() == new_block.rstrip():
        return content
    if old_block in content:
        return content.replace(old_block, new_block, 1)
    stripped_old = old_block.rstrip()
    if stripped_old in content:
        return content.replace(stripped_old, new_block.rstrip(), 1)
    raise ValueError("Original block not found in content; cannot swap.")


def replace_trigger(claude_md_path: Path, old_block: str, new_block: str) -> None:
    real_path = Path(os.path.realpath(claude_md_path))
    content = real_path.read_text()
    if old_block not in content:
        stripped_old = old_block.rstrip()
        if stripped_old in content:
            content = content.replace(stripped_old, new_block.rstrip(), 1)
        else:
            raise ValueError("Original block not found verbatim in file; refusing to write.")
    else:
        content = content.replace(old_block, new_block, 1)
    real_path.write_text(content)


def trigger_bullets(block_text: str) -> str:
    lines = block_text.split("\n")
    out = []
    for line in lines[1:]:
        if line.startswith("  -") or line.startswith("    ") or line.strip() == "":
            out.append(line)
        else:
            break
    return "\n".join(out).strip()
