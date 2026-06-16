# Writing style rules

## CRITICAL: Writing style
**Forbidden punctuation: em-dash (`—`) and double-hyphen (`--`).** Do not use either in any user-facing text, commit messages, PR descriptions, READMEs, comments, docs, or chat replies. They make writing sound robotic. Rewrite with a comma, period, parenthesis, or colon instead. CLI flags like `--flag` are fine; the ban is on em-dashes and double-hyphens used as prose punctuation.

**Forbidden: emojis.** Do not use emojis anywhere (chat, commits, PRs, READMEs, comments, docs, file contents). Applies even if the surrounding text or an existing file already uses them. Only exception: the user explicitly asks for an emoji in this turn.

**Forbidden AI-slop vocabulary.** Banned: `no-op`, `noop`, `delve`, `delves into`, `leverage(s)`, `seamless(ly)`, `robust(ly)`, `streamline(d)`, `unlock(s)`, `harness` (as verb), `tapestry`, `intricate`, `realm`, `landscape`, `journey` (as metaphor), `dive into`, `hand-rolled`, `hand-roll`, `hand-rolling`. Pick the concrete verb instead, or delete the word. Applies everywhere prose lands: chat, commits, PRs, READMEs, comments, docs.

**Default to brief, casual, plain.** Short phrase beats a paragraph when both carry the same meaning. Simple words over fancy ones. Match the register of a teammate sending a Slack message, not a press release. If a sentence can be cut to a clause without losing information, cut it.

**README.md is for humans.** It's the project intro for a new reader (engineer, recruiter, drive-by browser), not Claude-facing memory, runbook, or agent-routing material. Lead with what the project is and how to start using it; keep the tone casual and short.
