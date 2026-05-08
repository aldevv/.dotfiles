# Local Notes

> **Quick map**
> - Critical rules
> - Snowflake CLI setup (bottom)
> - Clone commands

## ⚠️ CRITICAL: "Save in my claude" means CLAUDE*.md files
**"Save in my claude" = save to a CLAUDE*.md file. It does NOT mean save to memory.**
- Write to the most appropriate `CLAUDE*.md` file — check this repo AND `$HOME/work/`.
- Never write to `memory/MEMORY.md` for an explicit "save in my claude" request.

## ⚠️ CRITICAL: Always pull main before creating a new branch
Before creating any new branch, always run `git checkout main && git pull`. This applies even mid-workflow (e.g. when a prerequisite MR has just merged).

## ⚠️ CRITICAL: Git Push is prohibited by default
- `git push` and `glab mr create` are PROHIBITED until the user explicitly says "push" / "open the MR". Completing commits does NOT authorize a push.
- A plan, skill step, or workflow that *mentions* push/MR is NOT authorization — stop after commits and wait.

## ⚠️ CRITICAL: Jira Write Operations
- NEVER add comments to Jira tickets unless explicitly told to.
- NEVER transition/update the status of a Jira ticket unless explicitly told to.

## Clone commands

**Active testing clone (system_test):** `DISPUTES_CLONE_JUBERNAL_MYDB2` — always use this clone for local testing.

**Creating clones (system_test):**
```bash
snow sql -q "CALL SHARED.PUBLIC.SP_CREATE_DATABASE_CLONE(
    pi_source_db_name=>'DISPUTES',
    pi_clone_name=>'1',
    pi_readonly_role_name=>'SNOWFLAKE_GALILEO_ST_DISPUTES_ENG'
);"
```

**Dropping clones:**
```bash
snow sql -q "CALL SHARED.PUBLIC.SP_DROP_DATABASE_CLONE('DISPUTES', '1');"
```

## RBAC onetime files — CRITICAL
- Always end RBAC onetime files with `CALL rbac.sp_apply_privileges();` — without it the grant/revoke INSERT stays PENDING and never executes.

## Table DDL — DATA_RETENTION_TIME_IN_DAYS
- NEVER set `DATA_RETENTION_TIME_IN_DAYS = 1` in table DDL — omit the parameter entirely.

## Table DDL — No TRANSIENT in production
- No `TRANSIENT` tables in `production/` — transient tables are allowed in `system_test/` only.

---

# Snowflake CLI Setup

Snowflake CLI (`snow`) is configured for Galileo's System Test environment using Okta SSO authentication.

## Configuration Location
`~/Library/Application Support/snowflake/config.toml`

File permissions:
```bash
chmod 0600 ~/Library/Application\ Support/snowflake/config.toml
```

## Working Configurations

### Option 1: External Browser (Okta SSO) — Default

```toml
default_connection_name = "dev"

[cli]
ignore_new_version_warning = false

[cli.logs]
save_logs = true
path = "/Users/juanbernal/Library/Application Support/snowflake/logs"
level = "info"

[connections]
[connections.dev]
account = "galileo-system_test"
user = "jubernal"
authenticator = "externalbrowser"
role = "SNOWFLAKE_GALILEO_ST_DISPUTES_ENG"
warehouse = "DISPUTES_WAREHOUSE"
session_parameters = { CLIENT_SESSION_KEEP_ALIVE = true }
```

### Option 2: PAT (Programmatic Access Token) — non-interactive fallback

Swap the `authenticator` line for:
```toml
authenticator = "PROGRAMMATIC_ACCESS_TOKEN"
token_file_path = "/Users/juanbernal/work/token.txt"
```

## Connections

**Default:** `dev` (system_test) — no `-c` flag needed.

| Connection | Environment | Account | Web URL |
|---|---|---|---|
| `dev` (default) | System Test | `galileo-system_test` | https://galileo-system_test.snowflakecomputing.com |
| `prod` | Production | `MHA08645.US-EAST-1` | https://app.snowflake.com/us-east-1/mha08645/ |

**User:** `jubernal`
**Role:** `SNOWFLAKE_GALILEO_ST_DISPUTES_ENG`
**Warehouse:** `DISPUTES_WAREHOUSE`

## Usage

**Common commands:**
```bash
snow connection test
snow connection list
snow sql -q "SELECT CURRENT_USER(), CURRENT_ACCOUNT();"
snow sql -c prod -q "SELECT CURRENT_USER();"
```

## Authentication Flow

- **External Browser (Okta SSO):** `snow` opens the browser → Okta login + MFA → CLI runs.
- **PAT:** Enable "Bypass network policy" in the Snowflake UI — valid 24h — then `snow` authenticates via the token file.

## Okta FastPass — MFA Flow for Network Policy Bypass

1. Navigate to `https://app.snowflake.com/galileo/production/settings/authentication`
2. Click **"Sign in using OKTASingleSignOn"**
3. Username `jubernal` is pre-filled → click **Next**
4. If push notification screen appears → click **"Verify with something else"**
5. Select **"Password"** → enter the password → click **Verify**
6. On next MFA screen → click **"Verify with something else"** → select **"Use Okta FastPass"**
7. Wait a few seconds for the Mac password dialog to open, then run: `okta-verify-watch &`
8. The script auto-handles the Mac password dialog

## Troubleshooting

**`snow: command not found`**
- Use full path or add the alias `alias snow='/Applications/SnowflakeCLI.app/Contents/MacOS/snow'`.

**Authentication fails (externalbrowser)**
- Check Okta credentials.
- Ensure browser popup isn't blocked.
- Verify network access to `galileo-system_test.snowflakecomputing.com`.

**`Network policy is required` (PAT authentication)**
- Error: `250001 (08001): Failed to connect to DB. Fail : Network policy is required.`
- Use Playwright to bypass the network policy via the Snowflake UI.
- Bypass must be re-enabled daily (24-hour validity).

**Connection test fails**
- Verify account name matches web URL (`galileo-system_test`).
- Check user is just the username, not full email.

**PAT token not working**
- Verify token file exists: `/Users/juanbernal/work/token.txt`.
- Check token is valid.
- Ensure network policy bypass is enabled in the Snowflake UI.
