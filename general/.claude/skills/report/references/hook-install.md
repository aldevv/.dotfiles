# Hook install (Round 4 detail)

When to read this: at Round 4 of the `hunk` workflow, ONLY when `$HOME/.cache/hunk/state.json` is missing (one-time prompt). If the state file exists, skip Round 4 entirely without reading this.

## The prompt

Ask once via `AskUserQuestion`:

Question: "Install a PreToolUse hook that auto-runs `hunk` right before any `gh pr create` or `glab mr create`? Hunk opens in a new tmux window and the parent Claude session fills it with review comments for any complex flows in the diff (or clears the placeholder if there's nothing complex)."

Options:
1. **Yes, install it** — symlink the script + register two matchers in settings.json
2. **No, skip** — record the decision so we don't ask again
3. **Ask me later** — do NOT write state; re-asks next run

## On "Yes"

Fire these two in parallel:

```bash
mkdir -p "$HOME/.claude/hooks" && \
  ln -sf "$HOME/.claude/skills/report/scripts/hunk-pre-pr.sh" \
         "$HOME/.claude/hooks/hunk-pre-pr.sh"
```

```bash
mkdir -p "$HOME/.cache/hunk" && \
  printf '{"hookInstalled": true, "promptedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$HOME/.cache/hunk/state.json"
```

Then patch `$HOME/.claude/settings.json` to add the two PreToolUse matchers. **Delegate to the `update-config` skill** for the actual JSON edit — it's the canonical handler for `settings.json` mutations and knows the merge rules. Pass it the two matchers to add:

- Matcher `Bash(gh pr create:*)` → command `$HOME/.claude/hooks/hunk-pre-pr.sh`
- Matcher `Bash(glab mr create:*)` → command `$HOME/.claude/hooks/hunk-pre-pr.sh`

If `update-config` isn't available in the session, edit `settings.json` directly. The target shape:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(gh pr create:*)",
        "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/hunk-pre-pr.sh"}]
      },
      {
        "matcher": "Bash(glab mr create:*)",
        "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/hunk-pre-pr.sh"}]
      }
    ]
  }
}
```

If a matcher entry for `Bash(gh pr create:*)` (or the glab equivalent) already exists, append to its `hooks` array instead of duplicating the matcher object.

## On "No"

```bash
mkdir -p "$HOME/.cache/hunk" && \
  printf '{"hookDeclined": true, "promptedAt": "%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$HOME/.cache/hunk/state.json"
```

## On "Ask me later"

Do not write state. The next `/report` invocation will ask again.
