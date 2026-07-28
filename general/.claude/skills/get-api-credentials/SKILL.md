---
name: get-api-credentials
description: Obtain and configure API credentials for a service / connector by reading its README, checking your password manager for an existing account, and using Playwright to create or retrieve tokens, then writing them to the project's env/config file. Use directly via `/get-api-credentials <name>`, or when another skill needs live credentials before it can run.
argument: service or connector name (e.g. "zendesk")
---

# Get API Credentials

Obtain credentials for a service/connector API and write them to the project's env file so it can run.

## Environment credentials reference (read FIRST if present)

Environment-specific details are NOT hardcoded here. If the project (or its CLAUDE tree) provides a **credentials reference doc** — a lazy/notes file describing the password manager account + how to sign in non-interactively, the signup-email fallback list + per-service "burned" log, and how to read a verification inbox — read it and follow it. In a Baton/connector setup that doc is the `credentials` lazy file; other setups may name it differently. If no such doc exists, ask the operator once for: password-manager access, a signup email to use, and how to read its inbox.

Everything below is the generic procedure; defer to the reference doc for concrete accounts, vaults, emails, and paths.

## Usage

```
/get-api-credentials <name>
```

Resolve the name to the project directory (a connector may use a `<prefix>-<name>` convention — apply whatever the environment's reference doc specifies).

---

## Step 1 — Locate the project directory

Resolve the target project directory (current repo, or the path convention from the reference doc). If it does not exist, stop and tell the user.

---

## Step 2 — Read the README / docs

Read the project's `README.md` (and `docs/` / any `*.md`) to identify:
- **Required environment variables / config fields** and their names.
- **How to obtain each credential** (URL, UI steps, token-generation page, auth method: API key / OAuth / key-pair / SSO).
- **Whether the required features need a paid plan.**

**Paywall detection first:** if the docs state that API access or the required features need a paid subscription with no free tier, **STOP** and report:
```
PAYWALL DETECTED
Minimum required plan: <plan name and price>
Reason: <what's behind the paywall>
No action taken. Ask the user to provide credentials manually.
```

---

## Step 3 — Check the password manager for an existing account

**ALWAYS check the password manager before creating anything.** The 1Password CLI (`op`) is driven entirely by env vars sourced from the project's env file (the reference doc names the file; commonly `.envrc`) — nothing about the account or vault is hardcoded here:

- `ONEPASSWORD` — master password (unlocks `op`, not individual service passwords).
- `OP_SECRET_KEY` — secret key.
- `OP_ACCOUNT` — account shorthand for `op signin --account "$OP_ACCOUNT"`.
- `OP_VAULT` — vault to search.

```bash
source <env-file>                                   # loads the vars above
eval "$(echo "$ONEPASSWORD" | op signin --account "$OP_ACCOUNT")"
# search by service name and by URL/domain. $OP_VAULT is a HINT: try it first,
# then fall back to ALL vaults so creds in another vault aren't missed.
op item list ${OP_VAULT:+--vault "$OP_VAULT"} --format=json | jq '.[] | select(.title|ascii_downcase|contains("<service>"))'
op item list --format=json | jq '.[] | select(.title|ascii_downcase|contains("<service>"))'   # all vaults, if the hint vault had nothing
```

Never ask the operator to run `op signin` or unlock 1Password — sign in yourself non-interactively with the piped-password form above (an `inappropriate ioctl for device` error just means no TTY; the piped form still works). If `ONEPASSWORD`/`OP_ACCOUNT`/`OP_VAULT` are unset, the reference doc or operator supplies them; only then fall back to asking.

- Existing credentials found → use them (Step 4).
- Nothing found → create a new account (Step 5).

---

## Step 4 — Retrieve credentials via Playwright (existing account)

Use the Playwright MCP tools to:
1. Navigate to the service login page (URL from README).
2. Log in with the credentials from the password manager (follow the reference doc's SSO/login flow when the account uses one).
3. Navigate to the token/key generation page.
4. Generate a token/key at the **highest available admin / owner / super-user scope** unless the caller explicitly asked for a narrower one. Connectors and live probes want write-capable tokens; least-privilege is the exception. Role names vary per vendor (e.g. `Admin`/`Owner`, `Super Administrator`, `Site admin`, `ACCOUNTADMIN`); for a permissions matrix, select all CRUD scopes for the resources the README documents. When unclear, default to full access.
5. Copy the token value.

**CRITICAL during Playwright:**
- **NEVER click any upgrade / paid-plan / purchase option.** If the account is expired/locked and only paid plans continue it, STOP (paywall rule).
- If a free plan can reactivate it, choose that.
- Preserve browser session — never clear cookies or userdata.
- Do NOT narrow scope below admin without explicit instruction; if the UI defaults to a lower role, change it up.

---

## Step 5 — Create a new account via Playwright (no existing credentials)

1. Navigate to the service signup page.
2. **Choose the signup email from the fallback list — never get blocked on a trivial email-format rejection or a burned address.** The ordered list is typically an env var the reference doc names (e.g. an env-file variable holding space-separated emails in priority order); read it, plus the reference doc's per-service "burned" log. Try each candidate in order, skipping any already burned for THIS service (a trial already exists for it), until the form accepts one AND it provisions.
   - Do NOT stop because the form rejected a `+` sub-address — fall through to the next candidate.
   - Do NOT stop because an address was used before — skip it and try the next.
   - **If the list is exhausted for this service, do NOT report blocked: mint a NEW readable email, use it, and APPEND it to the list (with date + which service forced it) so it's remembered.** Verify you can read the new inbox before relying on it. Progress is never blocked by "ran out of emails."
   - After a successful signup, record the address used in that service's burned log.
   - Use the signup password from the password manager / reference doc.
   - Select the **free plan** — never a trial that requires a credit card if a free option exists.
3. Complete email verification. Read the inbox per the reference doc's inbox-access flow; if an inbox API/token is expired, fall back to logging into webmail with Playwright rather than declaring the inbox unreachable. **Be patient:** provisioning + activation email can take 10-15 min — wait and re-check (refresh, sort by date) before concluding none arrived.
4. Generate the token/key as in Step 4.

**If only paid plans are offered:** STOP and report the paywall.

---

## Step 6 — Verify the credential

Before writing config, verify the credential works (a `curl` against a documented read endpoint, or the project's own auth check). If it returns an auth error, stop and report — do not write bad credentials.

---

## Step 7 — Write the env / config file

Write the required variables to the project's env/config file (the reference doc names it; commonly `.envrc`). If the file exists, read and merge — preserve unrelated entries. One `export VAR="value"` per line, no trailing whitespace.

---

## Step 8 — Run the project to verify

Run the project's own entry point (the README's run command) against the new credentials. Confirm it completes without auth errors. If it fails, diagnose (wrong var name, missing field) and fix before declaring success.

---

## Step 9 — Document how to re-fetch (local notes file)

Write a local, gitignored notes file (e.g. `CLAUDE.local.md`) in the project so a future run can recreate the credentials without re-deriving anything. Never modify a checked-in `CLAUDE.md`. If the notes file exists, read and merge.

Include, in a single `## Credentials` section:
1. **Password-manager entry** — title + vault + the retrieve command.
2. **Account details** — username/email used, role/permissions.
3. **Auth method** — API key / OAuth / key-pair / SSO, plus any non-obvious gotcha.
4. **Generation steps** — exact UI path / SQL / CLI for each credential that had to be generated (quote URLs, buttons, commands verbatim).
5. **Env/config contents** — every variable and where each value came from.
6. **Verification command** — the exact run invocation + expected output.
7. **Expiry / renewal** — trial end date, token lifetime, rotation (absolute dates).
8. **Paywall avoidance** — plan-tier traps to skip.

Be terse and reproducible — commands and values in code blocks, no narrative.

---

## Final report

```
Project: <name>
Credentials written to: <path to env/config file>
Local docs written to: <path to notes file>
Variables set: <list>
Account used: <email / account>
Source: password manager (existing) | new account created
Verify result: ✓ ran successfully | ⛔ blocked — <reason>
```
