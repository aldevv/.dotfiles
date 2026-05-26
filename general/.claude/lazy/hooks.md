# Claude Code hooks reference

Canonical docs: https://code.claude.com/docs/hooks. The spec evolves; cross-reference there for matcher formats, the full event list, and JSON schema details. This file captures the load-bearing semantics, the debugging recipes, and the correct/incorrect patterns learned from real sessions.

## Where to put hook entries (this setup)

User-level hooks split across two files. Pick by what you want shared between machines.

- `~/.claude/settings.json` is a real file on disk, **machine-local**, never travels. Put entries here when they reference machine-specific paths, plugin internals, or work-specific tooling you do NOT want reproduced on other machines. Examples in this setup: airc plugin `guard.py`/`inject.py`, `context-mode-cache-heal.mjs`, `notify.sh` wiring, the statusline command, the enabled-plugins list, the three baton-work PreToolUse reminders (`CLAUDE-gh.md`, `validate-connector-changes`, `baton-admin-review-connector`), the `gh-pr-post-assign.sh` PostToolUse (hardcoded reviewer list).
- `~/.claude/settings.local.json` is **symlinked into dotfiles** (`~/.dotfiles/general/.claude/settings.local.json`), so anything here travels and gets reproduced on every machine. Put entries here when you want the workflow on every box you log into. Examples in this setup: the generic PR/MR watch flow (`hunk-pre-pr.sh`, `gh-pr-post-watch-checks.sh`, `gh-pr-post-watch-comments.sh`).

Claude Code merges hooks across both files at the user level, so runtime behavior is identical regardless of which file an entry lives in. Splitting is purely an authoring choice about portability.

Note: the official docs only describe `settings.local.json` at the project level. The user-level form is undocumented but evidently honored (the existing `permissions`, `env`, `autoMemoryEnabled` keys at `~/.claude/settings.local.json` are being applied, and the moved PR-watch hooks fire from there).

## The two filters

Each hook handler goes through two filters before its command runs:

1. The block-level `matcher` field. For tool events (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`) this matches the **tool name only**: `Bash`, `Edit|Write`, `mcp__memory__.*`. Plain letters/digits/`|` are exact-or-pipelist; anything else is JS regex. Putting `Bash(gh pr create *)` in `matcher` does NOT filter on the command, it just fails to match anything.
2. The per-handler `if:` field. Uses [permission rule syntax](https://code.claude.com/docs/en/permissions): `Bash(git push *)`, `Edit(*.ts)`. Filters on tool name + arguments. For Bash, matched against each subcommand after stripping leading `VAR=value` assignments, so `FOO=bar gh pr create` and `npm test && gh pr create` both match. Only evaluated on tool events; on other events a hook with `if:` set never runs.

Use `if:` whenever you can; reserve script-side `tool_input.command` validation for cases `if:` can't express.

### CRITICAL: `if:` fails OPEN on complex commands

From the docs:
> The hook runs if any subcommand matches, **and always runs when the command is too complex to parse.**

Pipes plus command substitution plus escaped quotes can defeat the parser. When that happens every `if:` clause in the matcher group "matches" and every handler fires.

Real misfires hit in our sessions:

- `gh api ... 2>&1 | python3 -c "..." | sed -n '140,200p'` triggered `Bash(git push *)` and `Bash(gh pr create *)` handlers.
- `for f in $(ls -t ~/.claude/hooks/logs/*.log | head -30); do ... done` did the same.

**Fix pattern.** When a handler is doing something expensive (long polls, fixer spawns, paid API calls, spawning tmux windows), add a positive in-script gate at the top of the script that greps the raw `tool_input.command` for the expected pattern. Bail in milliseconds if it doesn't match. Example from `~/.claude/hooks/lib/gh-pr-watch-prelude.sh`:

```bash
tool_cmd=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
if ! printf '%s' "$tool_cmd" | grep -qE '(^|[[:space:]]|[;&|]|&&|\|\|)(git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create|glab[[:space:]]+mr[[:space:]]+create)([[:space:]]|$)'; then
  echo "tool_cmd does not match expected pattern, exiting"
  exit 0
fi
```

For cheap PreToolUse reminders (printing `additionalContext`) the misfire is harmless context noise and not worth gating. For PostToolUse watchers that spawn background work, take the defensive in-script gate.

## Matcher edge cases

`Bash(git push *)` requires at least one trailing arg. To also catch the bare command and the colon-form variant, add sibling matchers:

- `Bash(git push)` for the bare command
- `Bash(git push:*)` for the colon syntax
- `Bash(git push *)` for the space-form with args

Each `if:` is a single rule. There is no `&&`/`||` combining. If you need multiple conditions, define separate handler entries.

## Silent exits (the number-one debugging trap)

A hook that exits with no stdout JSON is interpreted by Claude Code as "no decision, allow normally." If your script aborts mid-flight, you won't see an error: the tool just runs as if the hook didn't exist. **Symptom:** you expected a deny, the tool ran instead.

**Exit code footgun.** For most events, *only* exit code `2` blocks. Exit `1` (the conventional Unix failure code) is **non-blocking**: Claude Code shows a `<hook> hook error` notice and proceeds with the action anyway. A script that aborts with `exit 1` silently allows. Use `exit 2` when you mean "block" and write to stderr; the stderr text is fed back to Claude as the error message. (Exception: `WorktreeCreate` treats any non-zero exit code as blocking.)

Most common causes of silent exits:

- **`set -euo pipefail` + a pipeline whose first command can legitimately fail.** Example:
  ```bash
  base="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null \
    | sed 's|^origin/||')"
  ```
  If `git symbolic-ref` fails (origin/HEAD not set), the pipeline returns non-zero (because `pipefail`) and the script aborts before the `[[ -n "$base" ]] || base=main` fallback runs. Fix: drop the pipe, use parameter expansion + `|| true`:
  ```bash
  base="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  base="${base#origin/}"
  [[ -n "$base" ]] || base=main
  ```
- **`while read -r seg; do ... done < <(... | tr X '\n')` drops the last segment** when the input lacks a trailing newline. `read -r` returns failure on EOF without `\n`, so the loop body never runs for the final segment. Fix: append `\n` (`printf '%s\n'`) or use `while read -r seg || [[ -n "$seg" ]]; do`.
- **`set -u` and an unset variable** referenced by accident.
- **Process substitution exit codes** (`< <(cmd)`) don't propagate cleanly with `set -e`; combined with `pipefail` inside the substitution, abort is surprising.

Fastest diagnostic: add one log line near the top:
```bash
echo "$(date +%FT%T.%N) PID=$$ TMUX=${TMUX:-UNSET} PWD=$PWD" >> /tmp/hook-debug.log
```
Then sprinkle `echo "checkpoint X" >> /tmp/hook-debug.log` between guards. If you see "checkpoint 3" but not "checkpoint 4", the abort is between them.

## Stdin payload

See the canonical docs for the full schema. Two fields worth calling out:

- **`cwd`** is the session cwd at fire time, not the post-`cd` target. If the user runs `cd /tmp/foo && cmd`, the hook still sees the session cwd. To scope to the actual directory, parse the `cd <path>` prefix from `tool_input.command` yourself.
- **`permission_mode`** is `"default" | "plan" | "acceptEdits" | "auto" | "dontAsk" | "bypassPermissions"`. Matters for the "ask" trap below. Not all events receive this field.

## Decision control by event

Different events use different output shapes. Mixing them up silently no-ops.

| Event | Block format |
|---|---|
| `PreToolUse` | `hookSpecificOutput.permissionDecision: "deny"\|"allow"\|"ask"\|"defer"` + `permissionDecisionReason` |
| `PostToolUse` / `PostToolUseFailure` | top-level `{"decision": "block", "reason": "..."}` |
| `UserPromptSubmit` / `UserPromptExpansion` | top-level `{"decision": "block", "reason": "..."}` |
| `Stop` / `SubagentStop` | top-level `{"decision": "block", "reason": "..."}` |
| `PermissionRequest` | `hookSpecificOutput.decision.behavior: "allow"\|"deny"` |
| `ConfigChange`, `PreCompact` | top-level `{"decision": "block", "reason": "..."}` |
| `Notification`, `SessionStart`, `SessionEnd`, `CwdChanged`, `FileChanged`, `PostCompact`, `StopFailure` | no blocking, side-effect only |

Most events also accept `hookSpecificOutput.additionalContext: "..."` to feed Claude info alongside the tool result.

## Output gotchas

- **`additionalContext` is one-way.** Info into the live session, no way to make it do work in parallel. Accepted by `SessionStart`, `Setup`, `UserPromptSubmit`, `UserPromptExpansion`, `PreToolUse`, `PostToolUse`, `PostToolBatch`.
- **Build output JSON with `jq -nc --arg ...`** so quoting is safe. Raw `printf` of decision strings is how stray-quote bugs land in prod hooks.

## Exit code vs JSON output

Exit codes:

- `0` success. stdout is parsed as JSON if it looks like JSON, otherwise discarded. Exceptions: `SessionStart`, `UserPromptSubmit`, `UserPromptExpansion` use plain stdout as context.
- `2` blocking error. stderr is fed back to Claude as the reason. Per-event semantics in the docs table.
- Anything else is a non-blocking error. First line of stderr surfaces as `<hook> hook error`.

JSON output and exit code 2 are mutually exclusive. Exit 2 ignores stdout. `WorktreeCreate` is the lone exception where any non-zero exit aborts.

## Async hooks

`"async": true` on a command hook runs it in the background. Cannot block. Output delivered on next user turn. Use for long polls, CI watchers, deploy triggers.

`"asyncRewake": true` is like async, but exit code 2 wakes Claude immediately with the stderr (or stdout if stderr is empty) shown as a system reminder.

Only `type: "command"` hooks support async. Prompt and HTTP hooks cannot.

## Permission modes (the `"ask"` trap)

The stdin `permission_mode` field tells you which mode the user is in. `bypassPermissions` "skips all permission prompts" per the [permissions docs](https://code.claude.com/docs/en/permissions#permission-modes), and that includes `permissionDecision: "ask"`: the prompt is suppressed and the tool just runs. Same return value, completely different behavior.

**Symptom:** you wrote a hook that returns `"ask"` to confirm something with the user. You test it and the tool runs without a prompt. You think the hook is broken. It isn't, the user is in bypass mode.

Workaround when you really need a confirmation: the hook can't invoke `AskUserQuestion` itself (hooks run outside the assistant loop), but it CAN instruct the assistant to invoke it via the deny `reason`: the reason text is delivered verbatim to the assistant as the tool's error message, and naming `AskUserQuestion` with a question + options gets it called.

Two phases in **default mode**: `"deny"` + sentinel A on first call; `"ask"` on retry (works natively).

Three phases in **bypassPermissions mode** (since `"ask"` auto-allows):
1. `"deny"` + sentinel A: tell assistant to do prep work and retry.
2. `"deny"` + sentinel B: reason instructs assistant to call `AskUserQuestion` for a structured prompt; retry once after user answers yes.
3. silent `"allow"`.

## Notification helpers

Hooks run without a controlling terminal as of v2.1.139, so writing escape sequences to `/dev/tty` fails. Two supported alternatives:

- `notify-send` (Linux) or `osascript` (macOS) from the hook script. Inherits `$TMUX` / `$TMUX_PANE` from the parent Claude process, so a downstream `notify.sh` can stamp the session/window into the title.
- Return `{"terminalSequence": "..."}` in JSON output. Claude Code emits the escape sequence on your behalf. Restricted to OSC 0/1/2/9/99/777 plus BEL.

## Persisting env vars from hooks

`SessionStart`, `Setup`, `CwdChanged`, and `FileChanged` hooks see `$CLAUDE_ENV_FILE`. Append `export FOO=bar` lines to it and every later Bash tool call inherits them. Other events do not have this variable.

## Manual test recipe

Fastest way to verify a hook works without going through Claude Code:

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

Trigger phrases hardcoded in the test command (e.g. `gh pr create`) will re-fire the hook against your test invocation. Substitute via `sed` so the hook itself doesn't see the trigger:
```bash
echo '...{"command":"GH_PLACE pr create"}...' | sed 's/GH_PLACE/gh/' | bash hook.sh
```

## Recursion guard

If your hook can spawn children that re-trigger it (e.g. a `claude -p` subagent that runs `gh pr create`), guard with an exported env var:
```bash
[[ "${MY_HOOK_ACTIVE:-}" == "1" ]] && exit 0
export MY_HOOK_ACTIVE=1
```

## Correct vs incorrect patterns (lessons from real sessions)

**Gating an expensive PostToolUse hook**
- DON'T: trust `if: "Bash(git push *)"` alone. Fail-opens on complex commands (pipes + command substitution), so `gh api ... | python3 ... | sed ...` and `for f in $(...); do ... done` both fired the watch hook.
- DO: keep the `if:` clause AND add a positive in-script grep at the top of the script (see "Fix pattern" above). Bails in milliseconds when the parser fail-opened.

**Catching all variants of a command**
- DON'T: one matcher `Bash(git push *)`. Misses the bare `git push`. Also fail-opens on complex commands, so even the matchers you do define stop being reliable.
- DO (better): drop the `if:` clause entirely, write one entry per command with no per-tool filter, and put a positive command-type grep at the top of the script (see "Fix pattern" under the fail-open section). One entry covers bare / args / colon-form / complex-command cases uniformly, and the script bails in milliseconds when the gate fails.
- DO (only when the script has no in-script gate): three sibling matchers `Bash(git push)`, `Bash(git push *)`, `Bash(git push:*)`. Verbose but works for cheap hooks where you don't want the script to spawn at all on non-matches.

**Multiple `if:` clauses, one tool call**
- DON'T: let N siblings fire N concurrent watcher instances on the same push.
- DO: atomic-mkdir dedup keyed on stdin hash. Loser instances exit silently. Example: `prelude_dedup_event` in the watch prelude.

**Surfacing a notification from a hook**
- DON'T: write escape sequences to `/dev/tty`. Hooks run without a controlling terminal.
- DO: call `notify-send` / `osascript` from the script, OR return `{"terminalSequence": "..."}` JSON.

**Blocking a PreToolUse vs PostToolUse call**
- DON'T: return `{"decision": "block"}` for a `PreToolUse` hook. It's a no-op; the field is ignored.
- DO: `PreToolUse` uses `hookSpecificOutput.permissionDecision: "deny"`. `PostToolUse` uses top-level `decision: "block"`. See the table above.

**Exit code vs JSON output**
- DON'T: exit 2 AND print JSON. Exit 2 ignores stdout.
- DO: pick one. Exit 0 + JSON for structured control; exit 2 + stderr for a quick block-with-reason.

**Signaling "block" via the wrong exit code**
- DON'T: `exit 1` from a script that meant to block. Non-blocking error, the tool runs anyway.
- DO: `exit 2` for blocking + stderr message. Or `exit 0` with JSON `decision: "block"`.

**Resolving the actual repo dir from a hook**
- DON'T: trust `INPUT.cwd` blindly. It's Claude's session cwd, not the post-`cd` target. A `cd ~/.dotfiles && git push` from a session rooted in `baton-sage-intacct` shows `cwd=baton-sage-intacct`, so a watcher will look up "the PR for branch `impl`" in the wrong repo and misfire.
- DO: parse the last `cd <path>` from `tool_input.command`, expand `~` / `$HOME` without `eval`, fall back to `INPUT.cwd` only if no `cd` was found.
  ```bash
  cd_path=$(printf '%s\n' "$tool_cmd" \
    | grep -oE '(^|[[:space:]]|;|&&|\|\|)cd[[:space:]]+[^[:space:]&;|]+' \
    | tail -n1 | sed -E 's/^.*cd[[:space:]]+//')
  case "$cd_path" in
    '~') cd_path="$HOME" ;;
    '~/'*) cd_path="$HOME/${cd_path#'~/'}" ;;   # single-quote the pattern to block tilde expansion
    '$HOME') cd_path="$HOME" ;;
    '$HOME/'*) cd_path="$HOME/${cd_path#\$HOME/}" ;;
  esac
  ```

**No-op push triggering a CI watcher**
- DON'T: assume every `git push` that the tool returns rc=0 from actually moved the remote. `Everything up-to-date` is rc=0 but the PR head didn't change.
- DO: grep `tool_response.stdout`+`stderr` for `everything up-to-date` and bail. The PR's existing CI shouldn't be re-watched on a no-op push.

## Things to verify before assuming the hook is broken

- **Which settings file wires it?** Check in order: project `.claude/settings.local.json` -> project `.claude/settings.json` -> user `~/.claude/settings.json`. An old entry in a higher-priority file can shadow your fix.
- **Does the matcher cover your command?** Print `tool_input.command` from stdin to confirm the parser sees what you expect.
- **Is `TMUX` (or any other env var you guard on) set?** Hook subprocess env is a curated subset of your shell environment, not the full set.
- **Did the script silently abort?** See the silent-exits section above; symptoms are identical to "hook not invoked".
