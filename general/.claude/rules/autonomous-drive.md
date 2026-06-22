# Autonomous-drive rules

## CRITICAL: No premature breakpoints during autonomous drive
**When autonomous-drive is active, NEVER end a turn at a "natural breakpoint".** Active when ANY of:
- Campaign file has `autonomous: true` frontmatter and `status: active`
- User said "continue", "keep going", "don't stop", "drive until done", "make sessions longer", or "until you are done"
- `/loop`, `/daemon`, or `/citadel:do continue` started the work

Keep iterating in the same response until exactly one of:
- Context budget tightens to within ~15% of the cap
- A circuit breaker fires (3+ consecutive failures on the same approach, fundamental architectural conflict, gate stays red across two fix cycles)
- The user interrupts

**Forbidden:** turn-ending summaries, asking "want me to keep going?", listing future strategies, declaring a stopping point because the next batch needs a strategy change. If a strategy change is needed, MAKE it and execute, then find the next bounded action.

**How to apply:** after every commit, the next text announces the next bounded action, not a summary. Tool calls follow immediately. One-sentence status updates are fine; sectioned summaries are not.
