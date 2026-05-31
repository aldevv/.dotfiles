#!/usr/bin/env python3
"""Propose an improved CLAUDE.md trigger block based on eval failures."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


def _call_claude(prompt: str, model: str | None, timeout: int = 300) -> str:
    cmd = ["claude", "-p", "--output-format", "text"]
    if model:
        cmd.extend(["--model", model])
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    result = subprocess.run(
        cmd, input=prompt, capture_output=True, text=True, env=env, timeout=timeout
    )
    if result.returncode != 0:
        raise RuntimeError(f"claude -p exited {result.returncode}\nstderr: {result.stderr}")
    return result.stdout


_RUBRIC = """\
A good trigger ties to observable signals: file paths or extensions about to
be edited, commands about to run, syntactic content in the tool call, specific
tool calls, explicit user phrases.

A bad trigger relies on introspection or abstract categories ("implementing a
feature", "considering whether X applies", "about to add a comment" (this
fires too late because Claude has already composed the comment in the Edit
payload), "when in doubt, read this").

Fix recipe when a trigger is ignored: replace the introspective phrasing with
the file/tool/syntax signal that was actually observable at the moment the
trigger should have fired.

Completeness beats brevity. A long, comprehensive trigger that lists every
signal is better than a terse one that loses cases. Err broader: a wasted
load is fine, a silently-missed load is not.

For conditional files, skip clauses should be as concrete as the fire
clauses. Vague skips ("skip for small scripts") drift; conjunctive skips with
hard cutoffs ("Skip ONLY if ALL hold: (a), (b), (c)") do not.
"""

_ANTI_OVERFIT = """\
Anti-overfit rules. Failing queries are a signal about the kind of moment the
trigger missed, not a phrasebook to copy. When adding bullets:

- Name an observable: a file extension or path, a tool call (Read/Write/Edit/
  Bash/Grep), syntactic content in the tool input, a specific command, or a
  user-phrase pattern.
- Do NOT paste the failing query's wording into a bullet for soft intent
  cases. If query 12 says "wrap this in a shell function for me", do NOT add
  `user phrase: "wrap this in a shell function for me"`. Generalize: the
  underlying signal is "user asks for code to exist where none did before",
  which the existing intent bullet should already cover. Broaden that bullet,
  don't add a duplicate.
- EXCEPTION: when the failing query names a concrete observable the trigger
  genuinely lacks (a missing file extension like `.tf`, a missing tool name,
  a missing command), naming that observable IS the generalization. Add the
  extension to the existing file-list bullet; do not invent a fresh bullet
  per-query.
- Prefer broadening an existing bullet over adding a new one. Three new
  bullets per iteration is a smell; one well-placed edit usually beats it.
- If a failure is "trigger missed because the query is genuinely off-target
  for this trigger", that's an eval-set issue, not a trigger issue. Leave
  the trigger alone for that case.

Generalize over enumerate. Enumeration is the overfit signature. If you find
yourself listing 4+ verbs, 4+ artifact types, or 4+ referent forms, STOP and
write a generalized predicate instead. The eval set has 8-12 should-fire
queries; enumerating to cover each one fits the train set but loses recall on
the next phrasing you didn't see. Concrete pairs:

  BAD (enumeration):
    - User asks `refactor, clean up, tidy up, simplify, polish, improve,
      restructure, rework, rewrite, redo, extract, rename, inline, make
      readable, make cleaner, make nicer, neaten, beautify` paired with
      `this code, this function, this file, this loop, this script, the
      <name> function, the <symbol> module, the <name>() helper, or it`.

  GOOD (predicate):
    - User phrases for code change to existing files, scoped to a code object:
      "refactor X", "clean up X", "extract X", "rename X", "simplify X",
      where X is any function/loop/condition/module/file/script reference.

The good form names the category and gives 3-5 representative examples; the
bad form tries to list every member of the category. A reader (Claude or
human) can extend the good form on the fly; the bad form is brittle to any
new phrasing.

Generalize over enumerate also applies to artifact lists. "Any code artifact
(script, helper, wrapper, CLI, hook, function, Dockerfile, Makefile, CI
workflow, ...)" beats listing 15 specific artifact names.

EXCEPTION for file-extension lists. Extensions are the canonical observable;
collapsing them into prose ("any source file", "any code file") strictly
loses recall because the model has no way to recognize `.tf`, `.lua`, `.rs`
as members of "code" without a list. Keep `.go`, `.py`, `.ts`, `.tf`, `.lua`,
`.rs`, etc. as a literal enumeration in the bullet. Do not delete the list
to satisfy the "generalize over enumerate" rule.

Length budget. The current trigger has N bullets. If your rewrite has more
than N+1 bullets, or if any single bullet is more than 2x the length of the
longest bullet in the current trigger, you are almost certainly overfitting.
Cut.

Selection tiebreaker (be aware). The harness picks the winning candidate by
(test_passed, recall, precision, length-slack, -length). A candidate that
ties the original on test accuracy loses unless it improves recall or
precision. Adding a bullet that doesn't convert at least one failing query
is wasted: the original wins the tiebreak. To win with a longer rewrite, the
edit must strictly improve at least one of those scores, not preserve them.
Length within 1.5x of the original is treated as length-equal, so legitimate
growth is not punished within that band.

Style. The parent CLAUDE.md forbids em-dash and double-hyphen as prose
punctuation. Use commas, periods, parentheses, or colons. CLI flags like
`--flag` are fine; banned shapes are `--` and the em-dash glyph used as
sentence punctuation.
"""


def improve_trigger(
    target_path: str,
    current_block: str,
    eval_results: dict,
    history: list[dict],
    model: str,
    test_results: dict | None = None,
    explore: bool = False,
) -> str:
    missed = [r for r in eval_results["results"] if r["should_trigger"] and not r["pass"]]
    overfire = [r for r in eval_results["results"] if not r["should_trigger"] and not r["pass"]]

    train_score = f"{eval_results['summary']['passed']}/{eval_results['summary']['total']}"
    score_line = f"Train: {train_score}"
    if test_results:
        score_line += f", Test: {test_results['summary']['passed']}/{test_results['summary']['total']}"

    prompt = (
        f"You are optimizing a lazy-load trigger entry in a CLAUDE.md file. The "
        f"entry tells Claude when to read the file at `{target_path}` into context. "
        f"A trigger that fires correctly loads the right file at the right moment; "
        f"a trigger that misfires either skips a load it should have done, or "
        f"loads a file the turn didn't need.\n\n"
        f"Current trigger block:\n<current>\n{current_block}</current>\n\n"
        f"Current scores ({score_line}):\n"
    )

    if missed:
        prompt += "FAILED TO FIRE (should have, didn't):\n"
        for r in missed:
            prompt += f'  - "{r["query"]}" (fired {r["fires"]}/{r["runs"]} times)\n'
        prompt += "\n"

    if overfire:
        prompt += "OVERFIRED (fired when it shouldn't):\n"
        for r in overfire:
            prompt += f'  - "{r["query"]}" (fired {r["fires"]}/{r["runs"]} times)\n'
        prompt += "\n"

    if history:
        prompt += "PREVIOUS ATTEMPTS (do NOT repeat verbatim, try a structurally different angle):\n\n"
        for h in history:
            train_s = f"{h.get('train_passed', '?')}/{h.get('train_total', '?')}"
            prompt += f"<attempt train={train_s}>\n"
            prompt += f"{h['block_text']}"
            prompt += "</attempt>\n\n"

    edit_mode_instruction = (
        "Apply the minimal edit that fixes the failing cases without breaking the passing ones. "
        "Keep the bullet list flat; do not collapse triggers into prose paragraphs. "
        "If the only edit you can think of is to paste the failing query into a new bullet, "
        "stop and broaden an existing bullet instead."
    )
    if explore:
        edit_mode_instruction = (
            "EXPLORE MODE: minimal edits have plateaued or recall is below 50%. Propose a "
            "STRUCTURALLY DIFFERENT rewrite. Examples of structural changes: collapse all "
            "bullets into one tight predicate clause; split into two bullets that name distinct "
            "observable classes (file-edit vs user-phrase); invert polarity from 'load when X' "
            "to 'load unless ALL of Y/Z/W hold' with hard cutoffs; consolidate enumerations. "
            "Do NOT preserve the existing bullet layout if your only option to do so is a "
            "cosmetic tweak. Length within 1.5x of the original is fine; the harness will "
            "still pick the shorter block on ties, but it will not punish growth that buys "
            "real recall or precision."
        )

    prompt += (
        f"\nGood vs bad trigger rubric:\n{_RUBRIC}\n"
        f"{_ANTI_OVERFIT}\n"
        f"Rewrite the trigger block. Keep the leading line shape exactly: "
        f"`- [<link>](<href>). **Read when** any of:` followed by indented bullets "
        f"(two spaces, then `- `). Preserve the link target. Keep any trailing "
        f"`Covers ...` summary line if it was there.\n\n"
        f"For each FAILED-TO-FIRE case, classify the cause:\n"
        f"- MISSING_SIGNAL: the trigger didn't list a phrase/extension/tool-call the query implied. Broaden an existing bullet or add one observable.\n"
        f"- INTROSPECTIVE: a bullet uses 'considering', 'deciding', 'judging', 'planning'. Replace with the observable that was visible at the load moment.\n"
        f"- LATE_BINDING: the trigger asks for preemptive loading BEFORE a tool call (e.g. 'BEFORE the first Write/Edit'), but Claude inspected the index only after composing the action. Wording alone may not fix this. Options: flip polarity to a Skip-default ('always load UNLESS all of X/Y/Z hold'); accept the recall ceiling and tighten precision; or note the failure mode in your proposed block so the human caller knows to consider a hook-based load instead.\n\n"
        f"For each OVERFIRED case:\n"
        f"- TOO_BROAD: scope the offending bullet (add an explicit code object, or move the case into a Skip clause).\n"
        f"- SOFT_SKIP: if a Skip clause exists and was satisfied, rewrite it as conjunctive with hard cutoffs.\n\n"
        f"{edit_mode_instruction}\n\n"
        f"Selection rule: ties on test accuracy go to the shorter block. To win, a longer "
        f"rewrite must strictly improve recall, precision, or both. Adding a bullet that "
        f"doesn't convert at least one failing query loses the tiebreak.\n\n"
        f"Respond with ONLY the new block inside <new_block>...</new_block> tags. "
        f"Nothing before or after."
    )

    text = _call_claude(prompt, model)
    match = re.search(r"<new_block>(.*?)</new_block>", text, re.DOTALL)
    new_block = match.group(1).strip("\n") + "\n" if match else text.strip("\n") + "\n"
    return new_block


def main():
    parser = argparse.ArgumentParser(description="Improve a trigger block based on eval results")
    parser.add_argument("--eval-results", required=True)
    parser.add_argument("--history", default=None)
    parser.add_argument("--model", required=True)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    eval_results = json.loads(Path(args.eval_results).read_text())
    history = []
    if args.history:
        history = json.loads(Path(args.history).read_text())

    new_block = improve_trigger(
        target_path=eval_results["target"],
        current_block=eval_results["block_text"],
        eval_results=eval_results,
        history=history,
        model=args.model,
    )

    if args.verbose:
        print("Proposed block:", file=sys.stderr)
        print(new_block, file=sys.stderr)

    print(json.dumps({
        "block_text": new_block,
        "history": history + [{
            "block_text": eval_results["block_text"],
            "train_passed": eval_results["summary"]["passed"],
            "train_total": eval_results["summary"]["total"],
            "results": eval_results["results"],
        }],
    }, indent=2))


if __name__ == "__main__":
    main()
