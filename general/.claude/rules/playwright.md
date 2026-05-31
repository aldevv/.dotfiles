# Playwright rules

## CRITICAL: Playwright Browser Issues
**NEVER ask the user to do anything with the browser.** Use the Playwright MCP plugin tools directly; they handle browser launch automatically.
- **NEVER delete** `~/.cache/ms-playwright/mcp-chrome-*`. Contains Okta session data.
- If browser is frozen or errors out: call `browser_close`, then retry. Chrome relaunches automatically.
