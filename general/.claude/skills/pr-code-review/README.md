# pr-code-review

Multi-angle review of one or more GitHub PRs, with verification + Hunk + ask-then-post.

## Args

- `<pr-url-or-num> [<pr-url-or-num>...]` — one or more PRs to review.
- `count=<N>` or leading integer — override the auto-picked agent count (1-12).
- `effort=<low|medium|high>` — override the auto-picked effort tier.
- `--date <date>` — `today` / `yesterday` / `"june 16"` / ISO. Defaults to today. Drives the resume manifest lookup.
- `--force` — bypass the resume check; always redo the work.

## What it does

- Resolves the local checkout for each PR, classifies the diff, decides agent count + effort.
- Spawns N parallel review agents (distinct angles), then a verification round with different agents.
- Consolidates findings with per-finding confidence + verification marker.
- Computes an "approve" confidence and tier.
- Persists the report to `${REVIEWS_DIR:-$HOME/.reviews}/<repo>/<DATE>/<author>/pr-<N>-<slug>.md` AND the per-PR log to `<repo>/.inreview/<DATE>/pr-code-review/<N>.md` (per-date archive so auto-new-day can replay it).
- Opens Hunk with every finding attached; asks the operator whether to reduce.
- Walks each surviving finding with per-comment ask-then-post.

## See also

- `references/dispatch-resume.md` — shared resume contract.
- `~/work/.claude/skills/pr-code-review-work/` — connector-flavored wrapper.
- `~/work/.claude/skills/pr-code-review-all/` — Linear-driven batch.
