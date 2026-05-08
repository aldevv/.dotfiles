# Local Notes (personal, gitignored)

## Critical rules
- `git push` is prohibited until I explicitly say "push".
- Always pull main before a new branch.
- Never add comments to Jira tickets unless told to.

## My clone
Active testing clone: `DISPUTES_CLONE_JUBERNAL_MYDB2`.

## Snowflake CLI setup

Config lives at `~/Library/Application Support/snowflake/config.toml`.

### External Browser (Okta SSO) default config

```toml
default_connection_name = "dev"

[connections]
[connections.dev]
account = "galileo-system_test"
user = "jubernal"
authenticator = "externalbrowser"
role = "SNOWFLAKE_GALILEO_ST_DISPUTES_ENG"
warehouse = "DISPUTES_WAREHOUSE"
session_parameters = { CLIENT_SESSION_KEEP_ALIVE = true }
```

### PAT fallback

Swap `authenticator = "PROGRAMMATIC_ACCESS_TOKEN"` and add `token_file_path = "/Users/juanbernal/work/token.txt"`. Requires daily network policy bypass via the Snowflake UI.

### Connections

| Connection | Environment | Account |
|---|---|---|
| `dev` (default) | System Test | `galileo-system_test` |
| `prod` | Production | `MHA08645.US-EAST-1` |

### Common commands

```bash
snow connection test
snow sql -q "SELECT CURRENT_USER();"
snow sql -c prod -q "SELECT CURRENT_USER();"
```

### Troubleshooting

**`snow: command not found`** — use full path `/Applications/SnowflakeCLI.app/Contents/MacOS/snow`.

**Authentication fails (externalbrowser)** — check Okta credentials, ensure browser popup isn't blocked.

**Network policy required (PAT)** — bypass via Snowflake UI, valid 24h.

**Connection test fails** — verify account matches web URL, user is just username (not email).

## Save guidance
"Save in my claude" = save to a `CLAUDE*.md`, never to memory.
