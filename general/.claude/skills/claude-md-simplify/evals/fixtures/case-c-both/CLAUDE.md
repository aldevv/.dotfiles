# Team Rules

This file is checked in and shared with the team.

## Deployment
- Always deploy to PERF (system_test/) first, validate, then PROD (production/).
- Semicolons: every SQL statement must end with `;`.
- Use `onetime/` for data changes, `tables/` for schema DDL.
- Tables use `CREATE` or `ALTER`, not `CREATE OR REPLACE` (preserves data).

## Style
- sqlfluff lint runs on all SQL files — fix violations before MR.
- Prefer `CREATE OR ALTER` over `CREATE OR REPLACE` where supported.
