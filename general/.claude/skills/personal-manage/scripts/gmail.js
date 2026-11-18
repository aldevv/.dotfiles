#!/usr/bin/env node
// Drive personal Gmail through a dedicated Chrome profile over CDP.
// usage: gmail.js login | send --to A [--cc B] --subject S [--body T] [file...] | search "<gmail query>" [N] | read "<gmail query>"
// env: PERSONAL_EMAIL, PERSONAL_EMAIL_PASS (login only). GMAIL_SHOW=1 opens a visible window.
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const pw = require(process.env.PWCORE || 'playwright-core');

const PORT = process.env.GMAIL_CDP_PORT || 9399;
const PROFILE = path.join(process.env.HOME, '.cache/ms-playwright/personal-gmail');
const CHROME = process.env.CHROME_BIN || '/opt/google/chrome/chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const clean = (s) => s.replace(/\s+/g, ' ').trim();

async function connect() {
  try { return await pw.chromium.connectOverCDP(`http://localhost:${PORT}`); } catch {}
  const args = [`--user-data-dir=${PROFILE}`, `--remote-debugging-port=${PORT}`, '--no-first-run', '--no-default-browser-check'];
  if (!process.env.GMAIL_SHOW) args.push('--headless=new');
  spawn(CHROME, [...args, 'about:blank'], { detached: true, stdio: 'ignore' }).unref();
  for (let i = 0; i < 30; i++) {
    await sleep(500);
    try { return await pw.chromium.connectOverCDP(`http://localhost:${PORT}`); } catch {}
  }
  throw new Error(`Chrome did not open CDP on port ${PORT}`);
}

async function gmailPage(browser) {
  const ctx = browser.contexts()[0];
  const page = ctx.pages().find((p) => p.url().startsWith('https://mail.google.com')) || ctx.pages().find((p) => !p.url().startsWith('chrome://')) || await ctx.newPage();
  if (!page.url().startsWith('https://mail.google.com')) await page.goto('https://mail.google.com/mail/u/0/');
  await page.waitForLoadState('domcontentloaded');
  return page;
}

async function login(page) {
  if (page.url().startsWith('https://mail.google.com')) { await page.waitForTimeout(3000); }
  if (page.url().startsWith('https://mail.google.com')) return console.log('already signed in:', await page.title());
  await page.locator('#identifierId').fill(process.env.PERSONAL_EMAIL);
  await page.keyboard.press('Enter');
  for (let i = 0; i < 20 && !/challenge|pwd/.test(page.url()); i++) await sleep(500);
  if (/challenge\/pk/.test(page.url())) {
    // Google offers the passkey first; pick the password instead.
    await page.keyboard.press('Escape');
    await page.getByRole('button', { name: /Try another way/i }).first().click();
    await page.getByText('Enter your password').first().click();
  }
  await page.locator('input[type=password]').fill(process.env.PERSONAL_EMAIL_PASS);
  await page.keyboard.press('Enter');
  for (let i = 0; i < 60 && !page.url().startsWith('https://mail.google.com'); i++) await sleep(1000);
  if (!page.url().startsWith('https://mail.google.com')) {
    await page.screenshot({ path: '/tmp/gmail-login.png' });
    throw new Error(`sign-in stuck at ${page.url().split('?')[0]} (screenshot /tmp/gmail-login.png)`);
  }
  console.log('signed in:', await page.title());
}

function ensureSignedIn(page) {
  if (!page.url().startsWith('https://mail.google.com')) throw new Error('not signed in, run: gmail.js login');
}

async function search(page, query) {
  await page.goto('https://mail.google.com/mail/u/0/#search/' + encodeURIComponent(query));
  await page.waitForTimeout(1500);
  const q = page.locator('input[name=q]');
  await q.fill(query);
  await q.press('Enter');
  await page.waitForTimeout(4000);
  return page.locator('div[role=main] tr.zA');
}

async function send(page, opts, files) {
  const u = new URL('https://mail.google.com/mail/u/0/');
  u.search = new URLSearchParams({ view: 'cm', fs: '1', to: opts.to, su: opts.subject || '', body: opts.body || '', ...(opts.cc ? { cc: opts.cc } : {}) }).toString();
  await page.goto(u.toString());
  await page.waitForSelector('input[type=file]', { state: 'attached', timeout: 30000 });
  if (files.length) {
    for (const f of files) if (!fs.existsSync(f)) throw new Error(`missing file: ${f}`);
    await page.locator('input[type=file]').first().setInputFiles(files);
    // wait until every attachment chip shows up and no upload is in flight
    for (let i = 0; i < 120; i++) {
      const names = await page.locator('[role=main], body').first().innerText();
      const done = files.every((f) => names.includes(path.basename(f).slice(0, 20))) && !/Uploading|Attaching/i.test(names);
      if (done) break;
      await sleep(1000);
    }
  }
  await page.screenshot({ path: '/tmp/gmail-compose.png' });
  await page.locator('div[role=button][data-tooltip^="Send"]').first().click();
  await page.getByText(/Message sent/i).first().waitFor({ timeout: 30000 });
  const rows = await search(page, `in:sent to:${opts.to} newer_than:1d`);
  console.log('sent. latest in Sent:', clean(await rows.first().innerText()).slice(0, 200));
}

(async () => {
  const [cmd, ...rest] = process.argv.slice(2);
  const browser = await connect();
  const page = await gmailPage(browser);
  try {
    if (cmd === 'login') await login(page);
    else if (cmd === 'search') {
      ensureSignedIn(page);
      const rows = await search(page, rest[0]);
      const n = Math.min(await rows.count(), Number(rest[1] || 20));
      for (let i = 0; i < n; i++) console.log(clean(await rows.nth(i).innerText()).slice(0, 220));
      if (!n) console.log('no results');
    } else if (cmd === 'read') {
      ensureSignedIn(page);
      const rows = await search(page, rest[0]);
      if (!(await rows.count())) return console.log('no results');
      await rows.first().click();
      await page.waitForTimeout(3000);
      console.log(clean(await page.locator('div[role=main]').innerText()).slice(0, 4000));
    } else if (cmd === 'send') {
      ensureSignedIn(page);
      const opts = {}; const files = [];
      for (let i = 0; i < rest.length; i++) {
        if (rest[i].startsWith('--')) opts[rest[i].slice(2)] = rest[++i]; else files.push(path.resolve(rest[i]));
      }
      if (!opts.to) throw new Error('--to is required');
      await send(page, opts, files);
    } else {
      console.log('usage: gmail.js login | send --to A [--cc B] --subject S [--body T] [file...] | search "<query>" [N] | read "<query>"');
    }
  } finally {
    await browser.close().catch(() => {}); // disconnects CDP, Chrome keeps running for the next call
  }
})().catch((e) => { console.error('ERROR:', e.message); process.exit(1); });
