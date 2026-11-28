# Playwright rules

## CRITICAL: Playwright Browser Issues
**NEVER ask the user to do anything with the browser.** Use the Playwright MCP plugin tools directly; they handle browser launch automatically.
- **NEVER delete** `~/.cache/ms-playwright/mcp-chrome-*`. Contains Okta session data.
- If browser is frozen or errors out: open a new tab and retry there. Call `browser_close` only on a browser this session launched and no other session uses (see below).

## CRITICAL: Never close or take over another session's browser
- Before driving any browser (Playwright MCP edge/firefox/plugin, or a CDP Chrome on 9399/9400/etc.), check whether one is already running. If it is, open a NEW tab (`context.newPage()`) or start a parallel browser with its own `--user-data-dir` and port. Never navigate or type in tabs you didn't open.
- Close only the tabs you opened. Never call `browser.close()` / `browser_close` on a shared profile: every session's Edge MCP uses `mcp-edge-epam`, so closing it kills the other session's work.
- Example: a car-search run called `page.context().browser().close()` in the Edge MCP and closed another session's browser.
