#!/usr/bin/env python3
"""Run trigger evaluation for a CLAUDE.md lazy-load trigger.

Per-query outcome is tri-state: "fired", "no_fire", or "timed_out".
Timeouts count as "no_fire" for scoring: a timeout on a should-fire
query is functionally a miss (Claude never loaded the file in the
time given); a timeout on a should-NOT-fire query is a correct
non-load. Only the edge case of zero outcomes (process crashed
before any decision) is treated as indeterminate.

Asymmetric pass thresholds: fire_threshold (default 0.4) for
should-fire queries, nofire_threshold (default 0.2) for should-NOT
queries. Precision matters more than recall for lazy-load triggers
(a false fire wastes tokens every turn), so the negative threshold
is stricter.

The per-query workdir contains the user's REAL CLAUDE.md with the
candidate block swapped in. Optimization happens against the real
load context, so the trigger competes with every other rule in the
file from iteration 1, not a stripped-down stub. No "follow the
trigger" preamble: the trigger's own bullets are the only thing
steering Claude.
"""

from __future__ import annotations

import argparse
import json
import os
import select
import subprocess
import sys
import tempfile
import time
import uuid
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path
from typing import Literal

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from scripts.utils import TriggerBlock, find_trigger, find_trigger_blocks


Outcome = Literal["fired", "no_fire", "timed_out"]


def _write_claude_md(workdir: Path, content: str) -> Path:
    """Write the candidate-swapped real CLAUDE.md into the per-query workdir."""
    claude_md = workdir / "CLAUDE.md"
    claude_md.write_text(content)
    return claude_md


def _read_file_path_equals_target(file_path: str, target_abs: Path | None, basename: str) -> bool:
    if not file_path:
        return False
    expanded = Path(os.path.expanduser(file_path))
    if target_abs is not None:
        try:
            if expanded.resolve(strict=False) == target_abs.resolve(strict=False):
                return True
        except OSError:
            pass
    return expanded.name == basename and target_abs is None


def run_single_query(
    query: str,
    claude_md_content: str,
    target_path: str,
    target_basename: str,
    target_abs_str: str | None,
    timeout: int,
    model: str | None = None,
) -> Outcome:
    target_abs = Path(target_abs_str) if target_abs_str else None
    run_id = uuid.uuid4().hex[:8]
    workdir = Path(tempfile.mkdtemp(prefix=f"trigger-eval-{run_id}-"))

    try:
        _write_claude_md(workdir, claude_md_content)

        cmd = [
            "claude",
            "-p", query,
            "--output-format", "stream-json",
            "--verbose",
            "--include-partial-messages",
        ]
        if model:
            cmd.extend(["--model", model])

        env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            cwd=workdir,
            env=env,
        )

        start = time.time()
        buffer = ""
        pending_read_json = None
        finished_normally = False

        try:
            while time.time() - start < timeout:
                if process.poll() is not None:
                    remaining = process.stdout.read()
                    if remaining:
                        buffer += remaining.decode("utf-8", errors="replace")
                    finished_normally = True
                    break

                ready, _, _ = select.select([process.stdout], [], [], 1.0)
                if not ready:
                    continue

                chunk = os.read(process.stdout.fileno(), 8192)
                if not chunk:
                    finished_normally = True
                    break
                buffer += chunk.decode("utf-8", errors="replace")

                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        event = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    if event.get("type") == "stream_event":
                        se = event.get("event", {})
                        se_type = se.get("type", "")

                        if se_type == "content_block_start":
                            cb = se.get("content_block", {})
                            if cb.get("type") == "tool_use" and cb.get("name") == "Read":
                                pending_read_json = ""

                        elif se_type == "content_block_delta" and pending_read_json is not None:
                            delta = se.get("delta", {})
                            if delta.get("type") == "input_json_delta":
                                pending_read_json += delta.get("partial_json", "")

                        elif se_type == "content_block_stop" and pending_read_json is not None:
                            try:
                                parsed = json.loads(pending_read_json)
                                fp = parsed.get("file_path", "")
                                if _read_file_path_equals_target(fp, target_abs, target_basename):
                                    return "fired"
                            except json.JSONDecodeError:
                                pass
                            pending_read_json = None

                        elif se_type == "message_stop":
                            return "no_fire"

                    elif event.get("type") == "assistant":
                        message = event.get("message", {})
                        for item in message.get("content", []):
                            if item.get("type") != "tool_use":
                                continue
                            if item.get("name") != "Read":
                                continue
                            fp = item.get("input", {}).get("file_path", "")
                            if _read_file_path_equals_target(fp, target_abs, target_basename):
                                return "fired"

                    elif event.get("type") == "result":
                        return "no_fire" if finished_normally or process.poll() is not None else "timed_out"
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()

        return "no_fire" if finished_normally else "timed_out"
    finally:
        for p in workdir.rglob("*"):
            if p.is_file():
                p.unlink()
        for p in sorted(workdir.rglob("*"), reverse=True):
            if p.is_dir():
                p.rmdir()
        if workdir.exists():
            workdir.rmdir()


def _summarize_query(
    outcomes: list[Outcome],
    should_trigger: bool,
    fire_threshold: float,
    nofire_threshold: float,
) -> dict:
    fires = sum(1 for o in outcomes if o == "fired")
    no_fires = sum(1 for o in outcomes if o == "no_fire")
    timeouts = sum(1 for o in outcomes if o == "timed_out")
    total_runs = fires + no_fires + timeouts
    if total_runs == 0:
        return {
            "fires": 0,
            "no_fires": 0,
            "timed_outs": timeouts,
            "trigger_rate": None,
            "indeterminate": True,
            "pass": False,
        }
    rate = fires / total_runs
    if should_trigger:
        did_pass = rate >= fire_threshold
    else:
        did_pass = rate < nofire_threshold
    return {
        "fires": fires,
        "no_fires": no_fires,
        "timed_outs": timeouts,
        "trigger_rate": rate,
        "indeterminate": False,
        "pass": did_pass,
    }


def run_eval(
    eval_set: list[dict],
    trigger: TriggerBlock,
    claude_md_content: str,
    num_workers: int,
    timeout: int,
    runs_per_query: int = 5,
    fire_threshold: float = 0.4,
    nofire_threshold: float = 0.2,
    model: str | None = None,
    block_text_under_test: str | None = None,
) -> dict:
    target_abs_str = str(trigger.target_abs) if trigger.target_abs else None

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        future_to_info = {}
        for item in eval_set:
            for run_idx in range(runs_per_query):
                future = executor.submit(
                    run_single_query,
                    item["query"],
                    claude_md_content,
                    trigger.target_path,
                    trigger.target_basename,
                    target_abs_str,
                    timeout,
                    model,
                )
                future_to_info[future] = (item, run_idx)

        outcomes: dict[str, list[Outcome]] = {}
        items: dict[str, dict] = {}
        for future in as_completed(future_to_info):
            item, _ = future_to_info[future]
            q = item["query"]
            items[q] = item
            outcomes.setdefault(q, [])
            try:
                outcomes[q].append(future.result())
            except Exception as e:
                print(f"Warning: query failed: {e}", file=sys.stderr)
                outcomes[q].append("timed_out")

    results = []
    for q, outs in outcomes.items():
        item = items[q]
        summary = _summarize_query(outs, item["should_trigger"], fire_threshold, nofire_threshold)
        results.append({
            "query": q,
            "should_trigger": item["should_trigger"],
            "runs": len(outs),
            **summary,
        })

    passed = sum(1 for r in results if r["pass"])
    total = len(results)
    indeterminate = sum(1 for r in results if r.get("indeterminate"))
    return {
        "target": trigger.target_path,
        "block_text": block_text_under_test if block_text_under_test is not None else trigger.block_text,
        "results": results,
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "indeterminate": indeterminate,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Evaluate a CLAUDE.md trigger against an eval set")
    parser.add_argument("--eval-set", required=True)
    parser.add_argument("--claude-md", required=True)
    parser.add_argument("--target", required=True, help="Trigger target full path (preferred) or basename")
    parser.add_argument("--num-workers", type=int, default=6)
    parser.add_argument("--timeout", type=int, default=90)
    parser.add_argument("--runs-per-query", type=int, default=5)
    parser.add_argument("--fire-threshold", type=float, default=0.4, help="A should-fire query passes when its fire-rate is >= this value (default 0.4 = 2/5 runs).")
    parser.add_argument("--nofire-threshold", type=float, default=0.2, help="A should-NOT-fire query passes when its fire-rate is < this value (default 0.2 = strictly under 1/5 runs).")
    parser.add_argument("--model", required=True)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    trigger = find_trigger(Path(args.claude_md), args.target)
    if trigger is None:
        print(f"Error: no trigger matched '{args.target}' in {args.claude_md}", file=sys.stderr)
        print("Available targets:", file=sys.stderr)
        for b in find_trigger_blocks(Path(args.claude_md)):
            print(f"  - {b.target_path}", file=sys.stderr)
        sys.exit(1)

    if args.verbose:
        print(f"Evaluating trigger for: {trigger.target_path}", file=sys.stderr)

    claude_md_content = Path(args.claude_md).read_text()
    output = run_eval(
        eval_set=eval_set,
        trigger=trigger,
        claude_md_content=claude_md_content,
        num_workers=args.num_workers,
        timeout=args.timeout,
        runs_per_query=args.runs_per_query,
        fire_threshold=args.fire_threshold,
        nofire_threshold=args.nofire_threshold,
        model=args.model,
    )

    if args.verbose:
        s = output["summary"]
        print(f"Results: {s['passed']}/{s['total']} passed, {s['indeterminate']} indeterminate", file=sys.stderr)
        for r in output["results"]:
            status = "PASS" if r["pass"] else ("INDET" if r.get("indeterminate") else "FAIL")
            rate = f"{r['fires']}/{r['fires']+r['no_fires']}" if not r.get("indeterminate") else "n/a"
            timeout_note = f" ({r['timed_outs']} t/o)" if r["timed_outs"] else ""
            print(f"  [{status}] rate={rate}{timeout_note} expected={r['should_trigger']}: {r['query'][:70]}", file=sys.stderr)

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
