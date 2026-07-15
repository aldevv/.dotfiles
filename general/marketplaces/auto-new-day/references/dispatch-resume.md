# Dispatch resume contract

Shared resume / completion-manifest contract used by every skill that auto-new-day dispatches (and by the generic skills they wrap). One canonical document; each skill's `references/dispatch-resume.md` is a symlink here.

## Operator-facing args

Every skill that honors this contract accepts:

- `--date <date>` — `today`/`yesterday`/`"june 16"`/`2026-06-16` etc. Defaults to today. Selects which day's archive to read at start / write at end. Resolved via `${AUTO_NEW_DAY_SCRIPTS_DIR}/resolve-date.sh`.
- `--force` — bypass the start-of-run manifest check (always redo the work). The end-of-run write still fires; the prior manifest is overwritten.

## Manifest key (which artifact identifies this dispatch)

In priority order:

1. `$AUTO_NEW_DAY_TICKET` set (auto-new-day own-work dispatch) → ticket-keyed.
2. `$AUTO_NEW_DAY_WINDOW` set (auto-new-day review dispatch) → window-keyed.
3. Branch name matches `cxh-NNNN-...` (operator running a work skill manually inside a connector repo) → ticket-keyed (`CXH-NNNN`).
4. `git rev-parse --show-toplevel` resolves (operator running a generic skill inside any git repo) → repo-keyed (`basename` of toplevel).
5. None of the above → skip the contract entirely (no resume, no manifest write).

The same key derivation logic runs at start (for the check) and end (for the write).

## Start of run — resume check

```bash
SCRIPTS="${AUTO_NEW_DAY_SCRIPTS_DIR}"

# 1. Pick the key.
KEY_FLAG=""; KEY_VAL=""
if   [ -n "${AUTO_NEW_DAY_TICKET:-}" ]; then KEY_FLAG=--ticket; KEY_VAL="$AUTO_NEW_DAY_TICKET"
elif [ -n "${AUTO_NEW_DAY_WINDOW:-}" ]; then KEY_FLAG=--window; KEY_VAL="$AUTO_NEW_DAY_WINDOW"
elif branch=$(git symbolic-ref --short HEAD 2>/dev/null) && [[ "$branch" =~ ^cxh-([0-9]+) ]]; then
  KEY_FLAG=--ticket; KEY_VAL="CXH-${BASH_REMATCH[1]}"
elif top=$(git rev-parse --show-toplevel 2>/dev/null); then
  KEY_FLAG=--repo;   KEY_VAL=$(basename "$top")
fi

# 2. If --force or no key resolved, proceed with the real work.
if [ "$FORCE" = "1" ] || [ -z "$KEY_FLAG" ]; then
  : # fall through; no resume
else
  # 3. Check for an existing manifest (today by default; --date overrides).
  if "$SCRIPTS/dispatch-done.sh" check $KEY_FLAG "$KEY_VAL" ${DATE:+--date "$DATE"}; then
    MANIFEST=$("$SCRIPTS/dispatch-done.sh" path $KEY_FLAG "$KEY_VAL" ${DATE:+--date "$DATE"})
    # 4. Fast-path: print prior summary, re-invoke /report with saved args, exit.
    jq -r '"already completed at \(.completedAt) — \(.reason)"' "$MANIFEST"
    jq -r '.commits[]?  | "  commit \(.)"' "$MANIFEST"
    jq -r '.artifacts | to_entries[] | "  artifact \(.key): \(.value)"' "$MANIFEST"
    DIFF_RANGE=$(jq -r '.hunkArgs.diffRange'           "$MANIFEST")
    PR_FB=$(    jq -r '.hunkArgs.prFeedbackPath // ""' "$MANIFEST")
    # Skill calls /report here with $DIFF_RANGE and (if non-empty) pr_feedback=$PR_FB.
    exit 0
  fi
fi
```

The fast-path replaces every step the skill would have otherwise done. The operator gets the prior run's summary + a re-opened Hunk window, without redoing any multi-agent work, validation pass, or sibling-skill artifacts.

## End of run — manifest write

```bash
SCRIPTS="${AUTO_NEW_DAY_SCRIPTS_DIR}"
# $KEY_FLAG / $KEY_VAL were derived above. Reuse.
if [ -n "$KEY_FLAG" ]; then
  "$SCRIPTS/dispatch-done.sh" write $KEY_FLAG "$KEY_VAL" ${DATE:+--date "$DATE"} \
    --verdict "<yes|no, mirroring the operator-facing summary>" \
    --reason  "<one short line>" \
    --diff-range "<git range that was passed to /report>" \
    --pr-feedback "<pr_feedback path passed to /report, if any>" \
    --commits "<short SHAs added this run, space-separated>" \
    --artifact <kind>=<path>   # repeat for each artifact (validate-connector, my-connector-review, baton-admin-review, etc.)
fi
```

Best-effort; never block. The script always exits 0 unless its args are malformed.

## Compose with wrapping skills

A wrapper skill (e.g. `/fix-bug-work` wraps `/auto-new-day:fix-bug`) should:

- Do its OWN resume check at the top, before delegating to the wrapped skill. If the wrapper's manifest exists, fast-path WITHOUT calling the wrapped skill.
- Pass `--skip-hunk` (or equivalent suppressor) when delegating so the wrapped skill DOESN'T also write a manifest. The wrapper writes the manifest at end with the richer artifact list.

The wrapped skill detects suppression and skips its own write — same flag (`--skip-hunk`) covers both Hunk and the manifest write, since both belong to the closing tail.

## Skip conditions (everything skips when any of these hold)

- The skill was invoked outside any dispatch flow AND the cwd isn't a git repo (no key resolves).
- `jq` isn't on `$PATH` (the script's own precondition).
- The operator passed `--force` (start check skipped, but write still fires).
- `--skip-hunk` is set (wrapper-driven path; the wrapper owns the close).

## Where to put the args parsing

Each skill parses `--date <date>` and `--force` from its `$ARGUMENTS` block alongside its existing args. Forward both to `dispatch-done.sh` invocations. Document them in the skill's `argument-hint:` frontmatter.
