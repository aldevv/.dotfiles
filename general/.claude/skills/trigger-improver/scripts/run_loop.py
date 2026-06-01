#!/usr/bin/env python3
"""Run the eval + improve loop for a CLAUDE.md trigger.

Mirrors skill-creator's run_loop.py: stratified 60/40 train/test split,
multiple runs per query, up to N iterations with Claude proposing edits
between rounds, winner selected by held-out test score.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from scripts.improve_trigger import improve_trigger
from scripts.run_eval import run_single_query
from scripts.run_eval import run_eval
from scripts.utils import (
    TriggerBlock,
    find_trigger,
    find_trigger_blocks,
    replace_trigger,
    swap_block_in_text,
)

# Hard ceiling on the size of a `**Read when**` block. Triggers should be
# small bullet lines; the cap forces structural splits or wording cuts when a
# winner balloons. Enforced in three places: the improvement prompt cites it,
# the harness surfaces `length_cap_exceeded` in the output, and `--apply`
# refuses to write a winner over the cap.
MAX_TRIGGER_CHARS = 1024


def spot_check_against_real(
    real_claude_md: Path,
    trigger: TriggerBlock,
    candidate_block: str,
    queries: list[dict],
    num_workers: int,
    timeout: int,
    runs_per_query: int,
    fire_threshold: float,
    nofire_threshold: float,
    model: str,
) -> dict:
    """Run a sample of queries against the user's real CLAUDE.md with the candidate block swapped in.

    This catches winners that look good in the minimal sandbox but lose
    discrimination when forced to compete with the rest of the user's rules
    for Claude's attention.
    """
    real_content = real_claude_md.read_text()
    if trigger.block_text.rstrip() == candidate_block.rstrip():
        swapped = real_content
    else:
        swapped = real_content.replace(trigger.block_text.rstrip(), candidate_block.rstrip(), 1)
        if swapped == real_content:
            return {"error": "candidate block could not be swapped into real CLAUDE.md (original block not found)"}

    workdir = Path(tempfile.mkdtemp(prefix="trigger-spotcheck-"))
    try:
        (workdir / "CLAUDE.md").write_text(swapped)
        from concurrent.futures import ProcessPoolExecutor, as_completed
        target_abs_str = str(trigger.target_abs) if trigger.target_abs else None

        with ProcessPoolExecutor(max_workers=num_workers) as ex:
            future_to_q = {}
            for item in queries:
                for _ in range(runs_per_query):
                    f = ex.submit(
                        _spot_check_one,
                        item["query"],
                        str(workdir),
                        target_abs_str,
                        trigger.target_basename,
                        timeout,
                        model,
                    )
                    future_to_q[f] = item

            outcomes: dict[str, list[str]] = {}
            items_map: dict[str, dict] = {}
            for f in as_completed(future_to_q):
                item = future_to_q[f]
                q = item["query"]
                items_map[q] = item
                outcomes.setdefault(q, [])
                try:
                    outcomes[q].append(f.result())
                except Exception as e:
                    outcomes[q].append("timed_out")

        results = []
        for q, outs in outcomes.items():
            item = items_map[q]
            fires = sum(1 for o in outs if o == "fired")
            no_fires = sum(1 for o in outs if o == "no_fire")
            timed = sum(1 for o in outs if o == "timed_out")
            total = len(outs)
            if total == 0:
                results.append({"query": q, "should_trigger": item["should_trigger"], "indeterminate": True, "fires": 0, "no_fires": 0, "timed_outs": timed, "runs": 0, "pass": False})
                continue
            rate = fires / total
            if item["should_trigger"]:
                did_pass = rate >= fire_threshold
            else:
                did_pass = rate < nofire_threshold
            results.append({"query": q, "should_trigger": item["should_trigger"], "fires": fires, "no_fires": no_fires, "timed_outs": timed, "trigger_rate": rate, "runs": total, "pass": did_pass})

        passed = sum(1 for r in results if r["pass"])
        return {"results": results, "summary": {"passed": passed, "total": len(results)}, "pr": _compute_pr_inline(results)}
    finally:
        for p in workdir.rglob("*"):
            if p.is_file():
                p.unlink()
        for p in sorted(workdir.rglob("*"), reverse=True):
            if p.is_dir():
                p.rmdir()
        if workdir.exists():
            workdir.rmdir()


def _spot_check_one(query, workdir, target_abs_str, basename, timeout, model):
    """Use the spot-check workdir directly without sandbox rebuild.

    Reuses the stream-event detection logic of run_single_query but skips
    the temp-CLAUDE.md creation since we already wrote the real-CLAUDE.md
    copy to workdir.
    """
    from pathlib import Path
    import os, subprocess, select, time, json
    target_abs = Path(target_abs_str) if target_abs_str else None
    cmd = ["claude", "-p", query, "--output-format", "stream-json", "--verbose", "--include-partial-messages"]
    if model:
        cmd.extend(["--model", model])
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, cwd=workdir, env=env)
    start = time.time()
    buffer = ""
    pending = None
    finished = False
    try:
        while time.time() - start < timeout:
            if process.poll() is not None:
                rem = process.stdout.read()
                if rem:
                    buffer += rem.decode("utf-8", errors="replace")
                finished = True
                break
            ready, _, _ = select.select([process.stdout], [], [], 1.0)
            if not ready:
                continue
            chunk = os.read(process.stdout.fileno(), 8192)
            if not chunk:
                finished = True
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
                    st = se.get("type", "")
                    if st == "content_block_start":
                        cb = se.get("content_block", {})
                        if cb.get("type") == "tool_use" and cb.get("name") == "Read":
                            pending = ""
                    elif st == "content_block_delta" and pending is not None:
                        d = se.get("delta", {})
                        if d.get("type") == "input_json_delta":
                            pending += d.get("partial_json", "")
                    elif st == "content_block_stop" and pending is not None:
                        try:
                            parsed = json.loads(pending)
                            fp = parsed.get("file_path", "")
                            if fp:
                                expanded = Path(os.path.expanduser(fp))
                                if target_abs is not None and expanded.resolve(strict=False) == target_abs.resolve(strict=False):
                                    return "fired"
                                if target_abs is None and expanded.name == basename:
                                    return "fired"
                        except json.JSONDecodeError:
                            pass
                        pending = None
                    elif st == "message_stop":
                        return "no_fire"
                elif event.get("type") == "result":
                    return "no_fire" if finished else "timed_out"
        return "no_fire" if finished else "timed_out"
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()


def _compute_pr_inline(results):
    pos = [r for r in results if r["should_trigger"]]
    neg = [r for r in results if not r["should_trigger"]]
    tp = sum(r.get("fires", 0) for r in pos)
    pos_total = sum(r.get("fires", 0) + r.get("no_fires", 0) + r.get("timed_outs", 0) for r in pos)
    fn = pos_total - tp
    fp = sum(r.get("fires", 0) for r in neg)
    neg_total = sum(r.get("fires", 0) + r.get("no_fires", 0) + r.get("timed_outs", 0) for r in neg)
    tn = neg_total - fp
    total = tp + tn + fp + fn
    precision = tp / (tp + fp) if (tp + fp) > 0 else 1.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 1.0
    accuracy = (tp + tn) / total if total > 0 else 0.0
    return {"precision": precision, "recall": recall, "accuracy": accuracy}


def split_eval_set(eval_set: list[dict], holdout: float, seed: int = 42) -> tuple[list[dict], list[dict]]:
    random.seed(seed)
    pos = [e for e in eval_set if e["should_trigger"]]
    neg = [e for e in eval_set if not e["should_trigger"]]
    random.shuffle(pos)
    random.shuffle(neg)
    n_pos_test = max(1, int(len(pos) * holdout))
    n_neg_test = max(1, int(len(neg) * holdout))
    test = pos[:n_pos_test] + neg[:n_neg_test]
    train = pos[n_pos_test:] + neg[n_neg_test:]
    return train, test


def _split_results(all_results: dict, train_set: list[dict]) -> tuple[dict, dict]:
    train_qs = {q["query"] for q in train_set}
    train_list = [r for r in all_results["results"] if r["query"] in train_qs]
    test_list = [r for r in all_results["results"] if r["query"] not in train_qs]

    def summarize(rs):
        passed = sum(1 for r in rs if r["pass"])
        return {"passed": passed, "failed": len(rs) - passed, "total": len(rs)}

    train_block = {"results": train_list, "summary": summarize(train_list), "target": all_results["target"], "block_text": all_results["block_text"]}
    test_block = {"results": test_list, "summary": summarize(test_list), "target": all_results["target"], "block_text": all_results["block_text"]}
    return train_block, test_block


def _compute_pr(results: list[dict]) -> dict:
    pos = [r for r in results if r["should_trigger"]]
    neg = [r for r in results if not r["should_trigger"]]
    tp = sum(r.get("fires", 0) for r in pos)
    pos_total = sum(r.get("fires", 0) + r.get("no_fires", 0) + r.get("timed_outs", 0) for r in pos) or sum(r.get("runs", 0) for r in pos)
    fn = pos_total - tp
    fp = sum(r.get("fires", 0) for r in neg)
    neg_total = sum(r.get("fires", 0) + r.get("no_fires", 0) + r.get("timed_outs", 0) for r in neg) or sum(r.get("runs", 0) for r in neg)
    tn = neg_total - fp
    total = tp + tn + fp + fn
    precision = tp / (tp + fp) if (tp + fp) > 0 else 1.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 1.0
    accuracy = (tp + tn) / total if total > 0 else 0.0
    return {"precision": precision, "recall": recall, "accuracy": accuracy}


def _print_stats(label: str, results: list[dict], elapsed: float):
    pr = _compute_pr(results)
    print(
        f"{label}: precision={pr['precision']:.0%} recall={pr['recall']:.0%} accuracy={pr['accuracy']:.0%} ({elapsed:.1f}s)",
        file=sys.stderr,
    )
    for r in results:
        if r.get("indeterminate"):
            status = "INDET"
            rate = "n/a"
        else:
            status = "PASS" if r["pass"] else "FAIL"
            total = r.get("fires", 0) + r.get("no_fires", 0) + r.get("timed_outs", 0)
            rate = f"{r.get('fires', 0)}/{total}" if total else "n/a"
        timeout_note = f" ({r.get('timed_outs', 0)} t/o)" if r.get("timed_outs") else ""
        print(f"  [{status}] rate={rate}{timeout_note} expected={r['should_trigger']}: {r['query'][:60]}", file=sys.stderr)


def run_loop(
    eval_set: list[dict],
    trigger: TriggerBlock,
    real_claude_md_content: str,
    num_workers: int,
    timeout: int,
    max_iterations: int,
    runs_per_query: int,
    fire_threshold: float,
    nofire_threshold: float,
    holdout: float,
    model: str,
    verbose: bool,
    explore_iteration: int | None = None,
    explore_recall_threshold: float = 0.5,
) -> dict:
    if holdout > 0:
        train_set, test_set = split_eval_set(eval_set, holdout)
        if verbose:
            print(f"Split: {len(train_set)} train, {len(test_set)} test (holdout={holdout})", file=sys.stderr)
    else:
        train_set, test_set = eval_set, []

    current_block = trigger.block_text
    history: list[dict] = []
    exit_reason = "unknown"

    for iteration in range(1, max_iterations + 1):
        if verbose:
            print(f"\n{'='*60}", file=sys.stderr)
            print(f"Iteration {iteration}/{max_iterations}", file=sys.stderr)
            print(f"{'='*60}", file=sys.stderr)

        iter_trigger = TriggerBlock(
            target_path=trigger.target_path,
            target_basename=trigger.target_basename,
            target_abs=trigger.target_abs,
            block_text=current_block,
            start_line=trigger.start_line,
            end_line=trigger.end_line,
        )

        try:
            iter_claude_md = swap_block_in_text(
                real_claude_md_content,
                trigger.block_text,
                current_block,
            )
        except ValueError:
            iter_claude_md = real_claude_md_content

        t0 = time.time()
        all_results = run_eval(
            eval_set=train_set + test_set,
            trigger=iter_trigger,
            claude_md_content=iter_claude_md,
            num_workers=num_workers,
            timeout=timeout,
            runs_per_query=runs_per_query,
            fire_threshold=fire_threshold,
            nofire_threshold=nofire_threshold,
            model=model,
            block_text_under_test=current_block,
        )
        elapsed = time.time() - t0

        train_results, test_results = _split_results(all_results, train_set)

        history.append({
            "iteration": iteration,
            "block_text": current_block,
            "train_passed": train_results["summary"]["passed"],
            "train_failed": train_results["summary"]["failed"],
            "train_total": train_results["summary"]["total"],
            "train_results": train_results["results"],
            "test_passed": test_results["summary"]["passed"] if test_set else None,
            "test_failed": test_results["summary"]["failed"] if test_set else None,
            "test_total": test_results["summary"]["total"] if test_set else None,
            "test_results": test_results["results"] if test_set else None,
        })

        if verbose:
            _print_stats("Train", train_results["results"], elapsed)
            if test_set:
                _print_stats("Test ", test_results["results"], 0)

        if train_results["summary"]["failed"] == 0:
            exit_reason = f"all_passed (iteration {iteration})"
            break
        if iteration == max_iterations:
            exit_reason = f"max_iterations ({max_iterations})"
            break

        train_recall = _compute_pr(train_results["results"])["recall"]
        next_iter = iteration + 1
        explore = (
            (explore_iteration is not None and next_iter == explore_iteration)
            or train_recall < explore_recall_threshold
        )

        if verbose:
            mode_tag = " (EXPLORE)" if explore else ""
            print(f"\nProposing edits{mode_tag}...", file=sys.stderr)
        blinded = [{k: v for k, v in h.items() if not k.startswith("test_")} for h in history]
        current_block = improve_trigger(
            target_path=trigger.target_path,
            current_block=current_block,
            eval_results=train_results,
            history=blinded,
            model=model,
            explore=explore,
        )

    orig_len_for_score = len(history[0]["block_text"])

    def _length_slack_term(h):
        """0 within 1.5x of original; -1 per 0.25x step beyond. Lets legitimate growth tie on length."""
        if orig_len_for_score == 0:
            return 0
        ratio = len(h["block_text"]) / orig_len_for_score
        if ratio <= 1.5:
            return 0
        return -(int((ratio - 1.5) / 0.25) + 1)

    def _score(h):
        results_key = "test_results" if test_set else "train_results"
        passed_key = "test_passed" if test_set else "train_passed"
        results = h.get(results_key) or h["train_results"]
        pr = _compute_pr(results)
        passed = h.get(passed_key) or h["train_passed"]
        return (
            passed,
            pr["recall"],
            pr["precision"],
            _length_slack_term(h),
            -len(h["block_text"]),
        )

    history_scored = sorted(history, key=_score, reverse=True)
    best = history_scored[0]
    runner_up = history_scored[1] if len(history_scored) > 1 else None
    if test_set:
        best_score = f"{best['test_passed']}/{best['test_total']}"
    else:
        best_score = f"{best['train_passed']}/{best['train_total']}"

    original = history[0]
    original_test_results = original.get("test_results") or original["train_results"]
    best_test_results = best.get("test_results") or best["train_results"]
    orig_pr = _compute_pr(original_test_results)
    best_pr = _compute_pr(best_test_results)
    delta = {
        "precision": best_pr["precision"] - orig_pr["precision"],
        "recall": best_pr["recall"] - orig_pr["recall"],
        "accuracy": best_pr["accuracy"] - orig_pr["accuracy"],
    }

    block_changed = best["block_text"].strip() != original["block_text"].strip()
    orig_bullet_count = sum(1 for l in original["block_text"].splitlines() if l.startswith("  - "))
    best_bullet_count = sum(1 for l in best["block_text"].splitlines() if l.startswith("  - "))
    orig_len = len(original["block_text"])
    best_len = len(best["block_text"])
    length_ratio = best_len / orig_len if orig_len else 1.0
    no_op_win = (
        block_changed
        and delta["accuracy"] <= 0.0
        and best_bullet_count > orig_bullet_count
    )
    bloat_warning = block_changed and length_ratio >= 1.5
    length_cap_exceeded = best_len > MAX_TRIGGER_CHARS

    harness_verdict = None
    verdict_hint = None
    if not block_changed and orig_pr["recall"] < 0.50:
        harness_verdict = "unfixable_by_wording"
        verdict_hint = (
            "Wording optimization can't fix this trigger. Likely causes: "
            "(a) the lazy-load mechanism itself isn't firing for this file; switch "
            "to a PreToolUse:Edit|Write hook in settings.json that injects the file. "
            "(b) the trigger conflates two signal classes; split into two entries "
            "pointing at the same target, each with a tight predicate. "
            "(c) the target file is small enough (<150 LOC) to inline into the "
            "parent CLAUDE.md under one always-on bullet."
        )

    selection_log = {
        "winner_iteration": best.get("iteration"),
        "winner_test_passed": best.get("test_passed"),
        "winner_train_passed": best.get("train_passed"),
        "winner_recall": best_pr["recall"],
        "winner_precision": best_pr["precision"],
        "winner_length": best_len,
        "runner_up_iteration": runner_up.get("iteration") if runner_up else None,
        "runner_up_test_passed": runner_up.get("test_passed") if runner_up else None,
        "runner_up_length": len(runner_up["block_text"]) if runner_up else None,
    }

    return {
        "exit_reason": exit_reason,
        "target": trigger.target_path,
        "original_block": trigger.block_text,
        "best_block": best["block_text"],
        "best_score": best_score,
        "best_train_score": f"{best['train_passed']}/{best['train_total']}",
        "best_test_score": f"{best['test_passed']}/{best['test_total']}" if test_set else None,
        "original_pr": orig_pr,
        "best_pr": best_pr,
        "delta_pr": delta,
        "bullet_count_original": orig_bullet_count,
        "bullet_count_best": best_bullet_count,
        "length_original": orig_len,
        "length_best": best_len,
        "length_ratio": length_ratio,
        "no_op_win": no_op_win,
        "bloat_warning": bloat_warning,
        "length_cap_exceeded": length_cap_exceeded,
        "length_cap": MAX_TRIGGER_CHARS,
        "harness_verdict": harness_verdict,
        "verdict_hint": verdict_hint,
        "selection_log": selection_log,
        "iterations_run": len(history),
        "holdout": holdout,
        "train_size": len(train_set),
        "test_size": len(test_set),
        "history": history,
    }


def main():
    parser = argparse.ArgumentParser(description="Eval + improve loop for a CLAUDE.md trigger")
    parser.add_argument("--eval-set", required=True)
    parser.add_argument("--claude-md", required=True)
    parser.add_argument("--target", required=True, help="Trigger target path or basename")
    parser.add_argument("--num-workers", type=int, default=6)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--max-iterations", type=int, default=5)
    parser.add_argument("--runs-per-query", type=int, default=5, help="Runs per query, smooths per-query noise. 5 gives 20%% per-run granularity.")
    parser.add_argument("--fire-threshold", type=float, default=0.4, help="A should-fire query passes when fire-rate >= this value (default 0.4 = 2/5 runs).")
    parser.add_argument("--nofire-threshold", type=float, default=0.2, help="A should-NOT-fire query passes when fire-rate < this value (default 0.2 = strictly under 1/5 runs).")
    parser.add_argument("--holdout", type=float, default=0.4)
    parser.add_argument("--model", required=True)
    parser.add_argument("--explore-iteration", type=int, default=3, help="At this iteration (1-indexed), force a structural-rewrite prompt instead of minimal edits. Also triggers automatically whenever train recall is below --explore-recall-threshold. 0 disables.")
    parser.add_argument("--explore-recall-threshold", type=float, default=0.5, help="If train recall is below this on the previous iteration, the next iteration runs in EXPLORE mode (structural rewrites invited).")
    parser.add_argument("--apply", action="store_true", help="Write the winner back into CLAUDE.md (current-run winner only; this is not an apply-from-cache shortcut)")
    parser.add_argument("--spot-check", type=int, default=0, help="After picking the winner, re-eval N random queries against the real CLAUDE.md (with the winner substituted) to catch sandbox-only wins. 0 = skip.")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    claude_md = Path(args.claude_md)
    trigger = find_trigger(claude_md, args.target)
    if trigger is None:
        print(f"Error: no trigger matched '{args.target}' in {claude_md}", file=sys.stderr)
        print("Available targets:", file=sys.stderr)
        for b in find_trigger_blocks(claude_md):
            print(f"  - {b.target_path}", file=sys.stderr)
        sys.exit(1)

    real_claude_md_content = claude_md.read_text()
    explore_iter = args.explore_iteration if args.explore_iteration and args.explore_iteration > 0 else None
    output = run_loop(
        eval_set=eval_set,
        trigger=trigger,
        real_claude_md_content=real_claude_md_content,
        num_workers=args.num_workers,
        timeout=args.timeout,
        max_iterations=args.max_iterations,
        runs_per_query=args.runs_per_query,
        fire_threshold=args.fire_threshold,
        nofire_threshold=args.nofire_threshold,
        holdout=args.holdout,
        model=args.model,
        verbose=args.verbose,
        explore_iteration=explore_iter,
        explore_recall_threshold=args.explore_recall_threshold,
    )

    if args.verbose:
        print(f"\nExit: {output['exit_reason']}", file=sys.stderr)
        print(f"Best (test): {output['best_score']}", file=sys.stderr)
        d = output["delta_pr"]
        print(f"Delta vs original: precision={d['precision']:+.0%} recall={d['recall']:+.0%} accuracy={d['accuracy']:+.0%}", file=sys.stderr)
        print(f"Length: {output['length_original']} chars original, {output['length_best']} chars winner (ratio {output['length_ratio']:.2f}x)", file=sys.stderr)
        sl = output["selection_log"]
        print(
            f"Selected iter={sl['winner_iteration']} (test={output['best_test_score']}, "
            f"recall={sl['winner_recall']:.0%}, precision={sl['winner_precision']:.0%}, len={sl['winner_length']})",
            file=sys.stderr,
        )
        if sl["runner_up_iteration"] is not None:
            print(
                f"Runner-up: iter={sl['runner_up_iteration']} (test_passed={sl['runner_up_test_passed']}, len={sl['runner_up_length']})",
                file=sys.stderr,
            )
        if output["no_op_win"]:
            print("NO-OP WIN: best block adds bullets without improving accuracy. Consider keeping the original.", file=sys.stderr)
        if output["bloat_warning"]:
            print(f"BLOAT WARNING: winner is {output['length_ratio']:.2f}x the original length. Triggers should be minimal; even a real accuracy gain may not justify the bloat.", file=sys.stderr)
        if output["length_cap_exceeded"]:
            print(f"LENGTH CAP EXCEEDED: winner is {output['length_best']} chars, cap is {MAX_TRIGGER_CHARS}. --apply will be refused; cut the bullets or split into two entries before re-running.", file=sys.stderr)
        if output["harness_verdict"] == "unfixable_by_wording":
            print(f"\nVERDICT: unfixable_by_wording (original recall={output['original_pr']['recall']:.0%}).", file=sys.stderr)
            print(output["verdict_hint"], file=sys.stderr)

    if args.spot_check > 0:
        sample = random.sample(eval_set, min(args.spot_check, len(eval_set)))
        if args.verbose:
            print(f"\nNoise-reduction re-sample of WINNER on {len(sample)} queries...", file=sys.stderr)
        spot_best = spot_check_against_real(
            real_claude_md=claude_md,
            trigger=trigger,
            candidate_block=output["best_block"],
            queries=sample,
            num_workers=args.num_workers,
            timeout=args.timeout,
            runs_per_query=args.runs_per_query,
            model=args.model,
            fire_threshold=args.fire_threshold,
            nofire_threshold=args.nofire_threshold,
        )
        output["spot_check"] = spot_best
        if args.verbose and "summary" in spot_best:
            sb = spot_best["summary"]
            pb = spot_best["pr"]
            print(f"Winner re-sample: {sb['passed']}/{sb['total']} passed, precision={pb['precision']:.0%} recall={pb['recall']:.0%} accuracy={pb['accuracy']:.0%}", file=sys.stderr)

    if args.apply:
        regressed = output["delta_pr"]["accuracy"] < 0
        block_changed = output["best_block"].strip() != output["original_block"].strip()
        if not block_changed:
            print("Skipping --apply: winner is the original block (nothing to write).", file=sys.stderr)
        elif output["no_op_win"]:
            print("Skipping --apply: best block adds bullets without improving accuracy.", file=sys.stderr)
        elif regressed:
            print(f"Skipping --apply: winner regresses on the held-out test set (delta_pr.accuracy={output['delta_pr']['accuracy']:+.0%}).", file=sys.stderr)
        elif output["length_cap_exceeded"]:
            print(f"Skipping --apply: winner is {output['length_best']} chars, exceeds {MAX_TRIGGER_CHARS}-char cap. Cut bullets or split into two entries before re-running.", file=sys.stderr)
        else:
            replace_trigger(claude_md, trigger.block_text, output["best_block"])
            if args.verbose:
                print(f"Applied winner to {claude_md}", file=sys.stderr)

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
