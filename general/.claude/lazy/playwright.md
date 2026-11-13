# Playwright

## pnogui (headless agent mode)

"pnogui" means run Playwright in agent mode: headless, no visible browser window that steals OS focus. Don't use the Playwright MCP browser tools (they open a headed window); close it with `browser_close` if it's open.

Write a small Node script and run it with Bash instead. Load `playwright-core` from the npx cache the MCP already uses and launch the installed Chromium headless:

```bash
export PWCORE=$(ls -d ~/.npm/_npx/*/node_modules/playwright-core | tail -1)
export CHROME=$(ls -d ~/.cache/ms-playwright/chromium-*/chrome-linux*/chrome | tail -1)
node script.js   # require(process.env.PWCORE).chromium.launch({ headless: true, executablePath: process.env.CHROME })
```

Print the text you need to stdout and save screenshots with `page.screenshot({ path })`, then `Read` the PNG to check it.
