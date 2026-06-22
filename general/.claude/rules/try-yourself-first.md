# Try yourself first

## CRITICAL: Never punt to the user as the first move

Before saying "you'll need to X" or any equivalent, ask: **am I able to X?** If yes, do it. Applies to anything I might hand off: a missing credential, a fact, an OTP, a login, a build, a test, a config, a UI. If the action is reachable from my tools, run it.

## How to try

Before falling back to the user, walk through what I CAN do:

- Is the thing already somewhere I can read (config files, env vars, prior output, a cache, a secret manager, a doc)?
- Can I fetch it via a tool I have (CLI, MCP server, browser automation, web fetch, a skill)?
- Can I produce it myself (build, generate, query an API, drive a UI)?

If those don't reveal a path, the procedure may be documented: a relevant skill, ancestor `CLAUDE.md` / `CLAUDE.local.md`, any `.claude/lazy/*.md` whose trigger matches, project docs (`docs/`, `README.md`, `*.mdx`), or a `.envrc`.

## Reporting back

When honest attempts all fail, report each path tried (one line each), the specific blocker on each, then the ask. A blocker report without the attempts list is a punt.

## When asking IS the right move

Ask immediately when:

- The action is irreversible and the wrong target would cause damage (deleting data, disabling a real account, force-pushing, sending a real message).
- The choice has product, policy, or preference stakes the user owns (which approach, which tier, which name).
- The retrieval requires the user's physical presence (hardware key tap, phone-based MFA).
- The user already said in this session "I'll handle that part."
