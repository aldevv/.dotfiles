# add-comment

Draft a short, human-sounding review comment on a GitHub PR or GitLab MR, confirm it, then post it. Handles three shapes: a threaded reply, a new line comment, or a top-level PR/MR comment. Voice is a tired engineer on Slack, not a memo: lowercase, short, no greetings, no em dashes.

## Use it

Type `/add-comment`, or just ask in plain words:

- "reply to bjorn's comment with done"
- "answer all of mateo's comments on PR #12"
- "leave a line comment on config.yaml:418 about the partial-failure guard"
- "mark all these threads as fixed"

It picks the tool from the URL (`github.com` → `gh`, `gitlab.*` → `glab`), drafts, shows you the exact text, and posts only after you confirm.

## Flow

```
route ──► read the code ──► draft ──► [fact-check?] ──► confirm ──► post ──► record
 │            │              │           │               │          │         │
 reply /   fetch the      slack       subagents       qa pane    gh/glab   examples.md
 line /    original +     voice,      verify any      (edit,     endpoint  (voice
 top-level the file       backticks   claims          say post)            training)
```

For a batch (several comments at once) the confirm step is an editable draft file, not a modal. That file is opened by the **qa** skill so you can tweak, reorder, or `SKIP` blocks in your own editor, then say "post".

## Who does what (batch mode)

| Step | Owner |
|------|-------|
| Route comments, draft bodies, fact-check | **add-comment** |
| Compose the draft file (block format, `- answer:` / `- thread_id:` bullets) | **add-comment** |
| Write it to `/tmp/add-comment-drafts-*.md` | **add-comment** |
| Open the pane / terminal, reuse it on repeat calls | **qa** (`open-qa-pane.sh`) |
| Re-read the edited file, parse blocks, post, clean up | **add-comment** |

The whole handoff to qa is one line: `~/.claude/skills/qa/scripts/open-qa-pane.sh <path>`. qa is format-blind; add-comment owns the block format.

## Notes

- Nothing posts without your per-comment confirmation. A prior "go ahead" does not carry over to a new batch, you always see the verbatim body first.
- Posted comments are appended to `references/examples.md` as voice training, with a `(×N)` count so overused phrasings stay visible.
- Not for: long formal responses, regular in-file code comments, or accepting a suggestion (just make the change).
