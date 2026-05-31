# Autonomous-drive rules

## CRITICAL: No premature breakpoints during autonomous drive
**When autonomous-drive is active, NEVER end a turn at a "natural breakpoint".** Autonomous-drive is active when ANY of the following holds:
- Campaign file has `autonomous: true` frontmatter and `status: active`
- User said any of: "continue", "keep going", "don't stop", "drive until done", "make sessions longer", "I don't want to manually touch this", "until you are done"
- `/loop`, `/daemon`, or `/citadel:do continue` is the invocation that started the work

While active, keep iterating inside the same response until exactly one of:
- Context budget tightens to within ~15% of the cap
- A documented circuit breaker fires (3+ consecutive failures on the same approach, fundamental architectural conflict, gate stays red across two fix cycles)
- The user interrupts the turn

**Forbidden during autonomous-drive:** turn-ending summaries ("Session N closed", "Wave concluded"), asking "want me to keep going?", listing future strategies in the response body, declaring a stopping point because the next batch of work would need a strategy change. If a strategy change is needed, MAKE the strategy change and execute it. The next bounded piece of work always exists; find it and emit the next tool call.

**How to apply:** after every commit during autonomous-drive, the very next text should announce the next bounded action, not summarize the previous one. Tool calls follow immediately. Status updates (one sentence each) are fine; sectioned summaries are not.
