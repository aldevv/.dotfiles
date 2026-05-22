# Debugging Claude Code hooks

Reference for when a hook isn't behaving and you can't tell why.

**Quick links:** [silent exits](#the-number-one-trap-silent-exits) ·
[manual test recipe](#manual-test-recipe) ·
[matcher vs `if`](#matcher-vs-if-the-filtering-split) ·
[ask trap](#permission-modes-the-ask-trap) ·
[verify checklist](#things-to-verify-before-assuming-the-hook-is-broken)

Scope: focuses on PreToolUse/PostToolUse. Other events (Stop,
UserPromptSubmit, SessionStart, Notification) follow similar shapes but
aren't covered here.

## The number-one trap: silent exits

A hook that exits with no stdout JSON is interpreted by Claude Code as "no
decision, allow normally." If your script aborts mid-flight, you won't see an
error — the tool just runs as if the hook didn't exist. **Symptom:** you
expected a deny, the tool ran instead.

**Exit code footgun:** for most events, *only* exit code **2** blocks. Exit
**1** — the conventional Unix failure code — is **non-blocking**: Claude Code
shows a `<hook> hook error` notice and proceeds with the action anyway. So a
script that aborts with `exit 1` (or any non-zero other than 2) silently
allows. Use `exit 2` when you mean "block" and write to stderr; the stderr
text is fed back to Claude as the error message. (Exception: `WorktreeCreate`
treats any non-zero exit code as blocking.)

The most common causes of silent exits:

- **`set -euo pipefail` + a pipeline whose first command can legitimately fail.**
  E.g.:
  ```bash
  base="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null \
    | sed 's|^origin/||')"
  ```
  If `git symbolic-ref` fails (origin/HEAD not set), the pipeline returns
  non-zero (because `pipefail`) and the script aborts before the `[[ -n "$base" ]] || base=main`
  fallback runs. **Fix:** drop the pipe, use parameter expansion + `|| true`:
  ```bash
  base="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  base="${base#origin/}"
  [[ -n "$base" ]] || base=main
  ```

- **`while read -r seg; do ... done < <(... | tr X '\n')` drops the last
  segment** when the input lacks a trailing newline. `read -r` returns failure
  on EOF without `\n`, so the loop body never runs for the final segment.
  **Fix:** append `\n` (`printf '%s\n'`) or use `while read -r seg || [[ -n "$seg" ]]; do`.

- **`set -u` and an unset variable** referenced by accident.

- **Process substitution exit codes** (`< <(cmd)`) don't propagate cleanly
  with `set -e`; combined with `pipefail` inside the substitution, abort is
  surprising.

If you suspect a silent abort, the fastest diagnostic is to add one log line
near the top:
```bash
echo "$(date +%FT%T.%N) PID=$$ TMUX=${TMUX:-UNSET} PWD=$PWD" >> /tmp/hook-debug.log
```
Then sprinkle `echo "checkpoint X" >> /tmp/hook-debug.log` between guards. If
you see "checkpoint 3" but not "checkpoint 4", the abort is between them.

## Stdin payload — the load-bearing fields

See the [hooks reference](https://code.claude.com/docs/en/hooks) for the full
schema. The one gotcha worth calling out: when the user runs
`cd /tmp/foo && cmd`, the hook's `cwd` is the session cwd at fire time, not
the post-`cd` target — to scope to the actual directory, parse the `cd <path>`
prefix from `tool_input.command` yourself.

`permission_mode` is also worth knowing — it's a stdin field with values
`"default" | "plan" | "acceptEdits" | "auto" | "dontAsk" | "bypassPermissions"`,
and matters for the [ask trap](#permission-modes-the-ask-trap) below. Not all
events receive this field.

## Hook output gotchas

- `additionalContext` is **one-way only** — info into the live session, no
  way to make it do work in parallel. Accepted by `SessionStart`, `Setup`,
  `UserPromptSubmit`, `UserPromptExpansion`, `PreToolUse`, `PostToolUse`, and
  `PostToolBatch`.
- Build the output JSON with `jq -nc --arg ...` so quoting is safe; raw
  `printf` of decision strings is how stray-quote bugs land in prod hooks.

## Permission modes (the `"ask"` trap)

The stdin `permission_mode` field tells you which mode the user is in.
`bypassPermissions` "skips all permission prompts" per the
[permissions docs](https://code.claude.com/docs/en/permissions#permission-modes),
and that includes `permissionDecision: "ask"` — the prompt is suppressed and
the tool just runs. Same return value, completely different behavior.

**Symptom:** you wrote a hook that returns `"ask"` to confirm something with
the user. You test it and the tool runs without a prompt. You think the hook
is broken. It isn't — the user is in bypass mode.

**Workaround when you really need a confirmation:** the hook can't invoke
`AskUserQuestion` itself (hooks run outside the assistant loop), but it *can*
instruct the assistant to invoke it via the deny `reason` — the reason text
is delivered verbatim to the assistant as the tool's error message, and
naming `AskUserQuestion` with a question + options gets it called.

**default mode** (2 phases): `"deny"` + sentinel A on first call; `"ask"`
on retry (works natively).

**bypassPermissions mode** (3 phases, since `"ask"` auto-allows):
1. `"deny"` + sentinel A → tell assistant to do prep work and retry.
2. `"deny"` + sentinel B → reason instructs assistant to call
   `AskUserQuestion` for a structured prompt; retry once after the user
   answers yes.
3. silent `"allow"`.

## Matcher vs. `if` (the filtering split)

Two separate fields control when a hook fires, and conflating them is the
most common config bug:

- **`matcher`** filters on tool name only. `"matcher": "Bash"` fires for
  *every* Bash call — putting `Bash(gh pr create *)` here does **not** filter
  on the command, it just fails to match anything.
- **`if`** uses [permission rule
  syntax](https://code.claude.com/docs/en/permissions) and filters on tool
  name + arguments. `"if": "Bash(gh pr create *)"` only fires when the
  command actually starts with `gh pr create`. For Bash, `if` is matched
  against each subcommand of the input after stripping leading `VAR=value`
  assignments — so `FOO=bar gh pr create` and `npm test && gh pr create`
  both match. **If the command is too complex to parse, the hook always
  runs**, so script-side validation is still useful as a fallback.

Use `if` whenever you can; reserve script-side `tool_input.command`
validation for cases `if` can't express. (`if` is only evaluated on tool
events: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`,
`PermissionRequest`, `PermissionDenied` — on other events a hook with `if`
set never runs.)

## Manual test recipe

The fastest way to verify a hook works without going through Claude Code:

```bash
# Synthetic input that mirrors what Claude Code sends
echo '{"tool_name":"Bash","tool_input":{"command":"gh pr create --title test"}}' \
  | bash /path/to/hook.sh
echo "exit=$?"
```

Add `bash -x` for line-by-line trace:
```bash
echo '...' | bash -x /path/to/hook.sh 2>&1 | tail -50
```

Trigger phrases hardcoded in the test command (e.g. `gh pr create`) will
re-fire the hook against your test invocation. Substitute via `sed` so the
hook itself doesn't see the trigger:
```bash
echo '...{"command":"GH_PLACE pr create"}...' | sed 's/GH_PLACE/gh/' | bash hook.sh
```

## Recursion guard

If your hook can spawn children that re-trigger it (e.g. a `claude -p`
subagent that runs `gh pr create`), guard with an exported env var:
```bash
[[ "${MY_HOOK_ACTIVE:-}" == "1" ]] && exit 0
export MY_HOOK_ACTIVE=1
```

## Things to verify before assuming the hook is broken

- **Which settings file wires it?** Check in order: project
  `.claude/settings.local.json` → project `.claude/settings.json` → user
  `~/.claude/settings.json`. An old entry in a higher-priority file can
  shadow your fix.
- **Does the matcher cover your command?** Print `tool_input.command` from
  stdin to confirm the parser sees what you expect.
- **Is `TMUX` (or any other env var you guard on) set?** Hook subprocess env
  is a curated subset of your shell environment, not the full set.

(For "is it invoked at all?" and "is the JSON valid?" — see the silent-exits
section above; both manifest as silent allows.)

## Spec lives in the docs

Matcher formats, the full hook event list, and the JSON schema evolve —
cross-reference [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks).
This file is the *debugging* checklist.
