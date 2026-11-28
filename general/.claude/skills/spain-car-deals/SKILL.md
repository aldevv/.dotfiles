---
name: spain-car-deals
description: Find the best current used-car deals in Spain (default Madrid) for a hybrid or electric SUV within a budget (default max 30,000 EUR). Searches the ranked Spanish used-car sites, filters by fuel, body, price and km rules, compares cash prices against market medians and new-car prices, and returns a ranked deal table with links. Triggers on "/spain-car-deals", "find me car deals in Spain", "search used cars Madrid", "check coches.net / flexicar / toyota ocasion for deals", "any good used hybrid SUV deals", "re-run the car search", "install/set up the daily car search on this machine". Use this over `investigate` for any Spanish used-car listing or deal hunt. Not for selling a car or for car advice outside Spain.
argument-hint: "[install | daily] [max-price EUR, default 30000] [province, default madrid] [model filter, optional e.g. rav4]"
---

# spain-car-deals

Live search of Spanish used-car sites for the best hybrid/EV SUV deal, scored against the market brief.

**Install** (`install` argument): run `scripts/install.sh` to set up the daily schedule on this machine (copies `references/systemd/` units, enables `spain-car-deals.timer`, turns on linger, warns if the personal-manage Gmail profile is missing). Then stop.

**Daily mode** (`daily` argument): run unattended by `scripts/daily.sh` (systemd timer `spain-car-deals.timer`, every morning; set up with `install`). Same steps, but never ask questions, and finish by writing the report files in Step 5; the script emails them.

Cache: `scripts/cache.py` (state in `~/.cache/spain-car-deals/listings.json`, entries pruned after 30 days unseen) keeps every evaluated listing so a run only opens detail pages for listings that are new or whose card price/km changed.

## Buyer rules (non-negotiable unless the user overrides in the turn)

- Fuel: full hybrid (HEV), plug-in hybrid (PHEV) or electric (BEV). **Reject mild hybrids (MHEV, "48V", "microhibrido")**, portals tag them "hibrido".
- Body: SUV / crossover.
- Price: cash price ("al contado") at or below the max. Never rank by a financed price.
- Km: Toyota, Lexus, Honda may exceed 100k km (Toyota/Lexus up to about 150k, Honda up to about 120k, both with full official service history). **Every other brand: hard max 100,000 km.** Any brand: flag more than 20k km per year of age.
- Brand preference: Toyota first, then Lexus/Honda, then others only if clearly the better deal.

## Step 1: Load the brief

Read `references/market-brief.md`: target models, "insanely good" price thresholds, ranked sites with URLs, checklist. Detail files `references/sites-detail.md` (fees, warranties, financing traps per site) and `references/resale-detail.md` (depreciation, liquidity) are read only when a question needs them.

The brief is dated. If it is older than about 6 months, or new-car prices / promos in it have expired, say so and refresh the thresholds with a quick web search (new-car prices on toyota.es promos, coches.net medians) before scoring.

## Step 2: Check current promotions

One web search for current promos (e.g. "black friday coches segunda mano <year>", "ofertas toyota ocasion <month year>", Clicars, Flexicar). Note deadlines and whether financing is required.

## Step 3: Search the sites

Use the URLs from the brief's "Where to search" table, substituting price and province from arguments (Spoticar, Das WeltAuto and other extra sites are in `references/sites-detail.md` section 1). If a model filter was given, search only that model. Order: coches.net (per target model), Toyota Ocasion, Autocasion, Autohero, Clicars, Flexicar/OcasionPlus, Spoticar/Das WeltAuto for non-Toyota, A Car For You, Wallapop last.

- Try WebFetch first. If it returns a block, captcha, or empty JavaScript shell, switch to the Playwright browser tools (snapshot, then read listing cards). If both fail, record the site as `NOT SEARCHED: <reason>`, never silently skip it. Clicars, AutoScout24 and Milanuncios blocked automated clients when the brief was written: try each once with the browser, then move on.
- Fan out with parallel subagents when searching more than 3 sites; give each the buyer rules above and the thresholds table, and ask for rows: model, version, year, km, cash price, financed price if shown, seller, location, warranty, URL.
- For each listing capture the cash price. If only a financed price is shown (Flexicar, OcasionPlus, many dealer ads), mark it and estimate cash (Flexicar about +2,300 EUR, OcasionPlus about +10%, Clicars about +10%) until confirmed.

Site access notes (learned on the first run, 2026-11):
- Autocasion: plain `curl` works when WebFetch fails; sort by cash price with `?direction=asc&sort=price`.
- Coches.net: bot-blocks after about 5 quick requests; space requests out and prefer WebFetch for page 1 per model.
- Wallapop: the web UI geolocates by IP; Flexicar cross-posts list the wrong town, read the dealer location from the ad text.
- Toyota Ocasion: listings load via JavaScript; read the page's results data in the browser. One price shown; it may be the financed one.
- Clicars: Cloudflare 403 for curl and headless browsers. Black Days prices need 84+ month financing; cash is about 2,000 more plus 490 fees.
- A Car For You: the page is a JavaScript app, but the whole stock comes from one POST: `curl -s -X POST https://acarforyou.es/api/api/buscador_vehiculos --data-urlencode 'json={"busqueda":"2","marca":"","modelo":"","carroceria":"","puerta":"","km":"0","fecha":0,"combustible":"","cambio":"","potencia":"0","precio":30000,"orden":"","direccion":""}'`. Fields: `VehMake`, `VehModelShortName`, `VehModelYear`, `VehMileage`, `VehPublicPriceInclVAT`, `VehEnergy`, `VehDistintivoAmbiental`, `VehState`, `permalink`. Listing URL: `https://acarforyou.es/ficha/<permalink>`. Its "Híbrido" includes mild hybrids (e.g. 2019 Tucson 48V); check the version.
- AutoScout24.es and Milanuncios geo-block non-Spanish IPs (checked 2026-11-26 from a Colombian IP with a real Chrome and a reader proxy: AutoScout24 serves a fake "page no longer exists" on every URL, Milanuncios a captcha). Check `curl -s ipinfo.io/country`: unless it prints `ES`, mark both `NOT SEARCHED: non-Spanish IP` and skip them. AutoScout24.es now belongs to Sumauto (same owner as Autocasion), so stock likely overlaps with Autocasion (not verified).
- Spoticar: page is 403 to curl; its JSON API works with browser-style headers: `https://www.spoticar.es/api/vehicleoffers/paginate/search?page=N&filters[0][energy]=híbrido&filters[1][category]=suv`.
- Das WeltAuto: fuel URLs don't filter and WebFetch is 403; curl `https://www.dasweltauto.es/esp/get-anuncios?condicion[provincia]=M&por_pagina=100&pagina=N` and filter locally. Listed price is cash. No Toyota/Lexus/Honda/Kia/Hyundai stock near Madrid when checked.
- Coches.net slugs: `/honda/hr-v/`, `/lexus/ux/` (no `/hibrido/`), `/kia/sportage/hibrido/` (includes MHEV, filter by version). `MaxPrice` filters on the financed price, so read the cash price per listing.
- Listing-card prices sometimes differ from the detail page: always use the detail page.
- Each parallel subagent needs its own browser. Other sessions share the Playwright MCP profiles (Edge uses `mcp-edge-epam`), so work in a new tab and close only that tab; never call `browser_close` / `browser.close()`. For sites that block headless browsers, start a separate real Chrome on its own hidden display `:100` (never `:99`, the ollama-login display: one VNC viewer per display, sharing one makes the window flip between sessions). If `:100` isn't running: `setsid nohup Xvfb :100 -screen 0 1400x1000x24 &`, `setsid nohup x11vnc -display :100 -localhost -nopw -forever -shared -quiet -rfbport 6000 &`, `DISPLAY=:0 setsid nohup xtigervncviewer -SecurityTypes None localhost::6000 &`. Then: `DISPLAY=:100 setsid nohup /opt/google/chrome/chrome --user-data-dir=$HOME/.cache/ms-playwright/ollama-login-car-sites --remote-debugging-port=9401 --no-first-run about:blank &`, then drive it with `CDP_PORT=9401 node ~/.claude/skills/ollama-login/scripts/pw.js`. Never use port 9400 (the ollama-login browser other sessions use).

## Step 3b: Skip what was already evaluated

After collecting listing cards (url, price as shown on the card, km, year) and before opening any detail page:

```bash
python3 -I ~/.claude/skills/spain-car-deals/scripts/cache.py check cards.jsonl > tagged.jsonl
```

- `unchanged`: reuse the cached fields (cash price, warranty, verdict); do NOT open the detail page. A matching km + year on a different URL counts as the same car cross-posted on another site.
- `price_drop` / `price_up`: re-open the detail page and show the old and new price; a drop on a good car is news.
- `new`: open and evaluate normally.

Then list cars from earlier reports that are no longer listed: `python3 -I ~/.claude/skills/spain-car-deals/scripts/cache.py gone cards.jsonl`.

After scoring, save every evaluated listing (one JSON object per line with at least `url`, `price` as on the card, `km`, plus `cash`, `model`, `year`, `seller`, `warranty`, `verdict`; add `"reported": true` on every row that goes into the report, so a later run can flag it as gone):

```bash
python3 -I ~/.claude/skills/spain-car-deals/scripts/cache.py save evaluated.jsonl
```

Keep the jsonl files in a temp dir, not in the skill folder.

## Step 4: Score

For each surviving listing:
- **Deal gap** = (market median for model/year/km from the brief or the live search median) minus cash price. Below the brief's "insanely good" threshold = top tier. The brief's medians and thresholds are Madrid figures; for other provinces use the live search median.
- Add known fees (transfer/prep, delivery) to the price before comparing.
- For 2024+ cars, compare against the new-car cash price; if the used price is within about 2,000 EUR of new, mark "buy new instead".
- Penalise: no warranty, private sale (add 4% ITP for Madrid; other regions have their own ITP rate, look it up), missing official service history, ex-rental with high km/year, any red flag from the brief's checklist.
- Resale weight: Toyota C-HR, Yaris Cross, RAV4 rank highest for liquidity; EVs and Chinese brands lowest.

## Step 5: Report

Lead with the verdict line: how many sites searched, which were NOT SEARCHED and why, and the single best deal.

Then one table, best first:

| # | Model / version | Year | Km | Cash price | vs market | Seller / site | Warranty | Why / flags | Link |

Start each row with the status emoji from `cache.py` (the user asked for emojis here): 🆕 new, 📉 price drop (old -> new), 📈 price up, 👀 same as before, ❌ gone (from `cache.py gone`, listed at the end). The verdict line counts each (e.g. "🆕 2, 📉 1, 👀 5, ❌ 1"). Then, for the top 3, the next actions from the brief's checklist (ask cash price in writing, DGT report by plate, service history printout, hybrid check). Keep it short. No em-dashes, no emojis.

In daily mode, also write two files for the mailer (`$(date +%F)` for the date):
- `~/.cache/spain-car-deals/report-<date>.txt`: the verdict line plus the top 5 as one short line each with the link. Plain text, under about 2,000 characters (the mailer types it into Gmail).
- `~/.cache/spain-car-deals/report-<date>.html`: the full table as a simple HTML table with clickable links.
If nothing is new or changed and no cached deal is still listed, the txt says so in one line.

Never contact sellers, submit forms, reserve cars, or start financing applications. Read-only browsing only.
