# get-api-credentials

Get working API credentials for a vendor or Baton connector and write them into the connector's `.envrc` so it can run. It reads the connector's README to learn what's needed, checks 1Password for an account you already have, and drives Playwright to create or fetch tokens when you don't. It also leaves a `CLAUDE.local.md` so the next session can re-fetch the same credentials without re-deriving anything.

## Use it

Type `/get-api-credentials <name>` (the `baton-` prefix is optional, so `zendesk` and `baton-zendesk` both work). Or ask in plain words:

- "get me credentials for baton-zendesk"
- "set up an API token so I can run baton-launchdarkly"
- "grab the snowflake creds from 1password and wire up .envrc"

It also runs under the hood as a pre-step of `impl-connector` and during `investigate`'s live-validation when an HTTP API needs auth before probes can run.

## Flow

```
locate dir --> read README --> check 1Password --> got an account?
                    |                                   |
              PAYWALL? stop                    yes --> retrieve token (Playwright)
                                                no  --> create free account (Playwright)
                                                            |
                                                            v
                                          verify with curl --> write .envrc --> run connector
                                                            |                        |
                                                       auth fails? stop         sync fails? fix
                                                            |
                                                            v
                                            write CLAUDE.local.md --> final report
```

## Steps

| Step | What it does |
|------|--------------|
| Locate the connector | Normalize the name to `baton-<name>`, confirm `$HOME/work/<connector>` exists, stop if not. |
| Read the README | Pull required env vars, how to get each credential, and whether anything sits behind a paywall. A hard paywall stops the run right there. |
| Check 1Password | Search by service name, domain, and the `baton.test@batonc1.com` SSO account before creating anything. |
| Retrieve (existing account) | Playwright logs in and generates a token, defaulting to the broadest admin/owner scope. Never clicks upgrade or paid options. |
| Create (no account) | Playwright signs up with `alejandro.bernal@conductorone.com` on the free plan, verifies email, generates a token. Only paid plans on offer means stop. |
| Verify with curl | Hit an API endpoint with the token; bad credentials are never written. |
| Write `.envrc` | Set every required var, merging into an existing file rather than clobbering it. |
| Run the connector | `go run ./cmd/<connector>` and confirm a clean sync before declaring success. |
| Write `CLAUDE.local.md` | Document the exact recreate steps (1Password entry, account, auth method, generation steps, `.envrc`, verify command, expiry, paywall traps) so it's reproducible. |

## Notes

- Scope defaults to admin/owner. Connectors and live probes want write-capable tokens, so narrow scope is only used when you explicitly ask for it.
- Never clicks upgrade, purchase, or trials that demand a card. A hard paywall with no free tier stops the run and reports back for manual credentials.
- Preserves the browser session (no cookie or userdata clearing), since it holds the Google SSO login.
- `CLAUDE.local.md` (gitignored), never the connector's checked-in `CLAUDE.md`.
