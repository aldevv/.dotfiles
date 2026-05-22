# Project Rules

## Git
- `git push` is prohibited until the user explicitly says "push".
- Always pull main before creating a new branch.
- Never commit new `.claude/` files without explicit authorization.

## Snowflake
- Validation is mandatory; always test DDL against a clone before committing.
- NEVER set `DATA_RETENTION_TIME_IN_DAYS = 1` in table DDL.
- No `TRANSIENT` tables in `production/`.
- Always end RBAC onetime files with `CALL rbac.sp_apply_privileges();`.

## Jira
- Never add comments to Jira tickets unless explicitly told to.
- Never transition Jira ticket status unless explicitly told to.

## Save guidance
When the user says "save in my claude", write to this file (or another `CLAUDE*.md`), never to `memory/MEMORY.md`.
