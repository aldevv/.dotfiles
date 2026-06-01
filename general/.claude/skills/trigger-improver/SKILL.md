---
name: trigger-improver
description: "Improve a CLAUDE.md lazy-load trigger's **Read when** block. Generates realistic should-fire/should-not-fire eval queries, runs a harness to test rewrites, iterates suggestions, selects the best by held-out test score, and can apply the winning block back to the file."
---

Improve a single lazy-load trigger in a CLAUDE.md file by mirroring the skill-creator's Description Optimization flow. The skill operates on the `- [<path>](<path>). **Read when** any of: ...` block, evaluates it against a synthetic eval set of realistic turns, and iterates the wording until misfires and overfires stop.

## When this fires (and when it doesn't)

Fires on explicit "improve / audit / optimize / tighten / fix this trigger" requests against a CLAUDE.md `**Read when**` block. Composition with sibling skills:

- `claude-md-save` writes a brand-new rule. Use that to add a new trigger entry; come here only to refine one that already exists.
- `claude-md-simplify` reshapes structure: extracts buried sections into `.claude/lazy/<topic>.md`, adds a load-on-demand index. Use that for layout. Come here for wording inside a single entry.
- `skill-creator:skill-creator` is the parent flow. Its target is a `SKILL.md` frontmatter `description:`; this skill's target is a CLAUDE.md `**Read when**` bullet list. The flow is the same, the artifact and the eval mechanism differ.

## Resolve the target file

In order, stop at the first match:

1. **User passed a path.** Use it verbatim. If it's a symlink (e.g. `~/CLAUDE.md`), resolve with `readlink -f` before editing so the Edit tool isn't refused.
2. **User said "global" or "global claude".** Target `~/.dotfiles/general/CLAUDE.md` (the real path behind `~/CLAUDE.md`).
3. **`./CLAUDE.local.md` exists** in the current working directory. Project-local instructions win over global when both apply.
4. **`./CLAUDE.md` exists** in the current working directory.
5. **Fallback: global.** `~/.dotfiles/general/CLAUDE.md`.

The resolution above is your responsibility, not the harness's. The harness takes `--claude-md` verbatim and does not search. Announce the `readlink -f` result (not the input) in one sentence before continuing, so the path you optimize against and the path you write to are the same.

## Identify the trigger to improve

A trigger entry looks like this (verbatim shape from `~/CLAUDE.md`'s Lazy load section):

```
- [`~/.claude/lazy/code/code.md`](.claude/lazy/code/code.md). **Read when** any of:
  - <signal 1>
  - <signal 2>
  - ...

  Covers <one-line summary of the file's content>.
```

Selection:

1. **User named a target.** Match by the linked path (`~/.claude/lazy/code/code.md`), the file basename (`code.md`), or a section heading they reference. Confirm the match in one sentence. When the CLAUDE.md has two entries whose basenames collide (e.g. multiple `code.md` files at different paths), pass the full path to `--target`, not the basename: the harness's substring fallback would pick the first match and silently optimize the wrong entry.
2. **User did not name a target.** List the trigger entries in the file (just the `- [path]` line of each, numbered) and ask which one. Do not guess.

Extract the entire block, from the `- [` line through the `Covers ...` paragraph (or the next blank line if no `Covers` paragraph). That whole block is the unit you're optimizing; the bullet list is the trigger proper but the `Covers` line is helpful context for the eval generator.

## Step 1: Generate the eval set

Build ~30 realistic turn descriptions: 13-15 should-fire, 13-15 should-NOT-fire. Save as JSON in the workspace (e.g. `/tmp/trigger-eval-<basename>.json`). The earlier 20-query default produced noisy verdicts: 8-test-query splits gave wins-by-1-query that didn't reproduce in the real CLAUDE.md. 30 queries with a 60/40 split gives 18 train / 12 test, which dampens single-query swings.

```json
[
  {"query": "...", "should_trigger": true},
  {"query": "...", "should_trigger": false}
]
```

**Realism rules** (these decide whether the loop converges):

- Each `query` is a complete turn description: the user prompt plus any signal the trigger says it watches for. If the trigger fires on "Write/Edit of a .go file", the query should say what file was just opened or what the next tool call will be, not just "user wants to refactor".
- Mix lengths. Include casual phrasing, typos, and contextual backstory (the user's project, a file path, a specific error, a column name). Skill-creator's example for SKILL.md descriptions applies here too: `"ok so my boss just sent me this xlsx..."` style.
- For the **should-fire** queries (8-10): different phrasings of the same intent (formal, casual, abbreviated, no explicit name); coverage of every distinct signal in the trigger; at least one case that doesn't name the file extension or skill but clearly fits.
- For the **should-NOT-fire** queries (8-10): near-misses. Queries that share keywords with the trigger but actually need something else (sibling-skill turf, adjacent domain, ambiguous phrasing that a naive keyword match would catch). A query like "write a fibonacci function" against a debugging trigger is too easy and tests nothing. Push for genuinely tricky negatives.

If the trigger has an explicit Skip clause, generate at least two queries that satisfy the skip conditions to verify the negative branch holds.

## Step 2: Review with the user

**2a. Inline review.** Present the eval set inline (numbered, grouped by should-fire / should-NOT-fire) and ask:

- any to edit, add, or remove?
- any whose `should_trigger` flag should flip?
- any signals from the trigger the eval set doesn't cover?

**2b. HTML viewer (offer explicitly when the eval set exceeds 12 queries OR the user asks for a UI).** Read the skill-creator template at `~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/assets/eval_review.html`. Substitute the placeholders (`__EVAL_DATA_PLACEHOLDER__`, `__SKILL_NAME_PLACEHOLDER__` → the trigger's basename, `__SKILL_DESCRIPTION_PLACEHOLDER__` → the trigger block text), and write to the snap-safe path:

```
~/snap/firefox/common/trigger-eval/trigger_eval_<basename>.html
```

Always use that path by default (run `mkdir -p ~/snap/firefox/common/trigger-eval` first). Ubuntu's default Firefox is the snap build, and snap Firefox is sandboxed from `/tmp/` (it reports "File not found" even though the file exists), so writing to `/tmp/trigger_eval_<basename>.html` and launching Firefox is a known misfire. The `~/snap/firefox/common/` tree is always readable by the snap. Open with `setsid firefox "file://<absolute-path>" >/dev/null 2>&1 < /dev/null &` so Firefox detaches cleanly. User edits and exports back to JSON; re-read the exported file before continuing. Always offer this step explicitly, do not skip it silently.

If `~/snap/firefox/` doesn't exist (Firefox installed via apt, Flatpak, or another channel), fall back to `/tmp/trigger_eval_<basename>.html`.

Save the finalized eval set; bad eval queries lead to bad triggers. To reduce phrasing leakage into the held-out test set, draft the train queries first and stop, then draft the test queries in a separate pass with a different mental seed (different domains, different sentence shapes). Don't author all 20 in one batch.

## Step 3: Evaluation + iteration loop

Run the bundled harness at `scripts/run_loop.py`. It mirrors skill-creator's `run_loop.py`: stratified 60/40 train/test split, 5 runs per query to smooth noise (was 3; 5 gives 20% per-run granularity so one flip doesn't cross the threshold), up to 5 iterations, Claude proposes a revised block between rounds, winner picked by PR-aware scoring on the held-out test.

**Mechanism.** Each eval query spawns a `claude -p` subprocess with `cwd` set to a temp project. The temp project's `CLAUDE.md` is the user's REAL CLAUDE.md with the candidate block swapped in (in-memory swap via `swap_block_in_text`), so the trigger competes with every other rule in the file from iteration 1. No discrimination-stub or decoy: optimization happens against the actual load context, not a stripped-down proxy. No "follow the trigger" preamble either; the bullet wording is the only thing steering Claude. The harness watches stream events for a `Read` tool call whose `file_path` resolves to the trigger's target (absolute-path equality, not basename substring). The per-run outcome is `fired`, `no_fire`, or `timed_out`. Timeouts count as `no_fire` for scoring: a timeout on a should-fire query is functionally a miss (Claude never loaded the file), a timeout on a should-NOT-fire query is a correct non-load. Only zero-outcome queries (subprocess crashed before producing any event) are treated as indeterminate. The subprocess runs with `CLAUDECODE` stripped from its env so nesting `claude -p` inside this Claude Code session works.

**Asymmetric thresholds.** Default `--fire-threshold 0.4` (a should-fire query passes at 2/5 runs or higher); default `--nofire-threshold 0.2` (a should-NOT query passes only at 0/5 runs, strictly under 1/5). Precision matters more than recall for lazy-load triggers, since a false fire wastes tokens every turn.

Per-call token cost is higher than the old sandbox (the real CLAUDE.md plus its lazy-load index runs ~3-5k input tokens) but the optimization is finally pointed at the right target. Budget ~$5-15 per trigger run depending on model and iteration count.

**Invocation.** Run the loop with stderr streamed for live progress:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-eval.json> \
  --claude-md <path-to-CLAUDE.md> \
  --target <full-trigger-path> \
  --model <model-id-from-this-session> \
  --max-iterations 5 \
  --spot-check 10 \
  --verbose
```

Run from the skill directory (`~/.claude/skills/trigger-improver/`) so the `scripts.` package resolves. `--model` is required: the script exits 2 without it, it does not fall back to a default. Use the model ID from your system prompt (the one powering this session) so the test reflects what the user actually experiences. Prefer the full trigger path over the basename for `--target`.

Useful overrides (all have sensible defaults; you usually don't need them):

- `--runs-per-query 5` (default). Bump to 7-9 if results stay noisy on small eval sets.
- `--fire-threshold 0.4` / `--nofire-threshold 0.2` (defaults). See "Asymmetric thresholds" above.
- `--explore-iteration N` (default 3). At iteration N the improvement prompt is swapped from "minimal edit" to "propose a structurally different rewrite". Also auto-triggers whenever train recall on the previous iteration is below `--explore-recall-threshold` (default 0.5). Set to 0 to disable.

The harness prints train/test precision/recall/accuracy per iteration to stderr; stdout is the final JSON with `best_block`, `best_score`, `best_train_score`, `best_test_score`, `original_pr`, `best_pr`, `delta_pr` (precision/recall/accuracy delta vs original on the held-out test set; this is the real-context delta, no separate "sandbox vs real" gap), `bullet_count_original`, `bullet_count_best`, `length_original`, `length_best`, `length_ratio`, `length_cap` (hard ceiling, currently 1024 chars), `length_cap_exceeded` (true if the winner is over the cap), `no_op_win` (true if the winner only adds bullets without improving accuracy), `bloat_warning` (true if `length_ratio >= 1.5x`), `harness_verdict` (set to `"unfixable_by_wording"` when the winner is the original AND `original_pr.recall < 0.50`), `verdict_hint` (one-paragraph next-step suggestion when a verdict fires), `selection_log` (winner and runner-up iteration/score/length for debuggability), `spot_check` (winner re-sampled on N queries for noise reduction; optional), and per-iteration `history`. Selection is `(test_passed, recall, precision, length_slack, -length)` so recall breaks ties on accuracy, precision breaks ties on recall, and length within 1.5x of the original is treated as length-equal (legitimate growth is no longer punished by the tiebreak).

**Hard 1024-char cap.** Triggers should be small bullet lines, not paragraphs. The harness enforces a strict `MAX_TRIGGER_CHARS = 1024` ceiling on the entire `**Read when**` block (leading `- [link]` line included). It surfaces `length_cap_exceeded: true` in the output, prints a `LENGTH CAP EXCEEDED` warning on stderr, and refuses `--apply` when the winner is over the cap. The improvement prompt also cites the cap, so the LLM is told not to propose rewrites that breach it. If a winner trips the cap, the fix is to cut the weakest bullet, shorten verbose phrasing, or split the trigger into two entries pointing at the same target with tighter per-entry predicates; do not raise the cap to fit a bloated rewrite.

**`--apply`** writes the winner of THIS run back into the CLAUDE.md. It is not an apply-from-cache shortcut: rerunning with `--apply` is a full re-optimization that costs another 5 iterations of API calls. To apply a winner you already have (from a previous JSON output), call `scripts.utils.replace_trigger(claude_md, old_block, new_block)` directly instead. The harness refuses `--apply` when the winner is the original (no-op write), when `no_op_win` is true, and when `delta_pr.accuracy` is strictly negative on the test set.

**`--spot-check N`** (optional, noise reduction only) re-samples N queries against the real CLAUDE.md with the winner block swapped in and returns `spot_check`. Since the main loop already optimizes against the real CLAUDE.md, this is no longer the safety-critical "did we cheat?" probe it once was; it's just a small re-run to smooth single-shot noise. Set N to 8-12 for a useful confirmation, or 0 to skip.

**Failure classification.** The improvement prompt (in `scripts/improve_trigger.py`) bakes in five categories used by the inline review:

- **MISSING_SIGNAL** (should-fire failed): trigger didn't list a phrase/extension/tool-call the query implied. Broaden an existing bullet or add one observable.
- **INTROSPECTIVE** (should-fire failed): bullet uses "considering", "deciding", "judging", "planning". Replace with the observable that was visible at the load moment.
- **LATE_BINDING** (should-fire failed): trigger asks for preemptive loading BEFORE a Write/Edit, but Claude inspected the index only after composing the action. Wording alone may not fix this. Options: flip polarity to a Skip-default ("always load UNLESS all of X/Y/Z hold"); accept the recall ceiling and tighten precision; or surface the failure mode so the human caller knows to consider a `PreToolUse:Edit|Write` hook instead.
- **TOO_BROAD** (should-NOT-fire fired): scope the bullet to a code object, or move the case into the Skip clause.
- **SOFT_SKIP** (overfire only on Skip-eligible case): rewrite the Skip clause as conjunctive with hard cutoffs.

The rubric the prompt cites is verbatim from the parent CLAUDE.md's "Good vs bad triggers" section. Anti-overfit guardrails in the prompt: the model is told to broaden an existing bullet over adding a new one, with an EXCEPTION when the failing query names a concrete observable the trigger genuinely lacks (a missing file extension, tool, or command) since naming that observable IS the generalization. A separate EXCEPTION protects file-extension lists from the "generalize over enumerate" rule, because collapsing extensions into prose strictly loses recall. The style rule (no em-dashes or `--` as prose punctuation) is also baked in so the proposed block complies with the parent CLAUDE.md. The prompt also tells the model the tiebreak rule explicitly: a longer rewrite must strictly improve recall or precision, not just preserve accuracy.

## Step 4: Apply the result

1. Show before/after of the trigger block to the user (full diff, no truncation).
2. Show the train and test accuracy plus the `delta_pr` from the harness JSON. Because the loop runs against the real CLAUDE.md, `delta_pr` IS the real-context delta; if it's negative or zero, recommend keeping the original. If `no_op_win` is true, say so explicitly: the winner ties or trails the original on accuracy and only adds bullets. If `bloat_warning` is true (winner `length_ratio` is 1.5x or more), say so explicitly: triggers should be minimal; even a real accuracy gain may not justify the bloat. Equal accuracy with a longer winner is a "keep original" verdict. If `length_cap_exceeded` is true (winner is over the 1024-char cap), say so explicitly and surface it as a hard block: `--apply` will refuse, and the right next move is to cut the weakest bullet, shorten phrasing, or split the trigger into two entries; do not propose raising the cap.
3. If `harness_verdict == "unfixable_by_wording"`, surface it verbatim along with `verdict_hint`. The verdict fires when the winner is the original AND `original_pr.recall < 0.50`; it means iterating again will not help. Surface the three suggested next steps from `verdict_hint` (PreToolUse hook, split into two entries, or inline the lazy file) and ask the user which direction to take; do not silently re-run.
4. Show the `selection_log` (winner iteration vs runner-up) so the user can sanity-check why this candidate won. Especially useful when the original wins: the log makes the "loop reverted to original" outcome explicit instead of buried.
5. If `--spot-check` was set, report the winner's re-sample pass rate. It exists for noise reduction now, not anti-overfit; treat it as a confidence signal, not a gate.
6. Ask for confirmation. If approved:
   - To apply the current run's winner: re-invoke with `--apply` (it picks up the same eval set and the same model, runs the full loop again, and writes if the winner is not the original AND `no_op_win` is false AND accuracy didn't regress), OR
   - To apply a winner you already have from a prior JSON: call `scripts.utils.replace_trigger(claude_md_path, old_block, new_block)` directly. This avoids re-running the loop.
   The replace function resolves the symlink behind `~/CLAUDE.md` before writing.
7. End-of-turn summary: one sentence on what changed and the score delta. No section headers.

## Failure modes

What the harness does when things go sideways:

- **`claude -p` crashes mid-eval for a query.** The run is logged as `Warning: query failed` on stderr and counted as `timed_out` for that run. Timeouts now count toward scoring (as `no_fire`); a sprinkling of timeouts is fine but a flood means the model can't reach a verdict in time. Re-run before applying.
- **Model refuses to emit `<new_block>...</new_block>` tags.** The script falls back to using the whole response. This will inject prose (or apologies) into the next iteration. Before applying, eyeball the `best_block` in the JSON output: it MUST start with `- [` and have the leading line shape `- [<link>](<href>). **Read when** any of:`. If not, discard and re-run.
- **Eval JSON malformed.** `json.loads` raises and the script exits with a stack trace. Fix the file and re-run.
- **Trigger target file doesn't exist on disk.** The harness runs anyway (the sandbox doesn't care), but a "fire" still means Claude attempted a Read of a path that points nowhere. Verify the target file exists before running, otherwise the eval is exercising a no-op.
- **All runs for a query time out.** Treated as `no_fire` for scoring (should-fire fails, should-NOT-fire passes). If many queries time out, the model isn't finishing in the time given; raise `--timeout` (default 60s in `run_loop.py`, 90s in `run_eval.py`) and re-run. Only zero-outcome queries (subprocess crashed before producing any event) are marked `indeterminate` and excluded from pass/fail counts.
- **Winner is the original AND `original_pr.recall < 0.50`.** The harness sets `harness_verdict = "unfixable_by_wording"` and emits `verdict_hint` with three concrete next-step suggestions. Stop iterating; the loop has hit a wall that wording optimization can't break through. Likely causes: (a) the lazy-load mechanism itself isn't firing for this file, switch to a `PreToolUse:Edit|Write` hook in `~/.claude/settings.json` that reads the file when the relevant tool calls land; (b) the trigger conflates two signal classes (file-edit observables vs user-phrase observables), split into two entries pointing at the same target each with a tight predicate; (c) the target file is small enough (under ~150 LOC) to inline into the parent CLAUDE.md under one always-on bullet. These fixes are out of scope for this skill, but the verdict surfaces them so the human caller can route correctly.

## Notes on durability of the result

A trigger that wins the eval today can still rot tomorrow if its language drifts toward introspection during a future edit. After applying the winner, scan the bullets one more time for the bad-trigger patterns the parent CLAUDE.md lists (`implementing a feature`, `considering whether X applies`, `about to add a comment`, `when in doubt, read this`). If any survived, flag them; do not silently leave them in. Concrete observables beat abstract categories every time.
