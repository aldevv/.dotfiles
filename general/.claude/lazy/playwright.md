# Playwright

## pnogui (headless agent mode)

"pnogui" means run Playwright in agent mode: headless, no visible browser window that steals OS focus. Don't use the Playwright MCP browser tools (they open a headed window); close it with `browser_close` only if this session opened it (never a browser another session shares).

Write a small Node script and run it with Bash instead. Load `playwright-core` from the npx cache the MCP already uses and launch the installed Chromium headless:

```bash
export PWCORE=$(ls -d ~/.npm/_npx/*/node_modules/playwright-core | tail -1)
export CHROME=$(ls -d ~/.cache/ms-playwright/chromium-*/chrome-linux*/chrome | tail -1)
node script.js   # require(process.env.PWCORE).chromium.launch({ headless: true, executablePath: process.env.CHROME })
```

Print the text you need to stdout and save screenshots with `page.screenshot({ path })`, then `Read` the PNG to check it.

## Secrets

- `browser_run_code_unsafe` echoes the code it ran into the tool result, including code loaded via `filename`, so a password inlined there lands in the transcript. `browser_type` echoes its text too. For a secret, write it to a 0600 file and have run_code read it (`require('fs').readFileSync(path,'utf8')`) so only the path is echoed (untested, verify the first time); delete the file after.
