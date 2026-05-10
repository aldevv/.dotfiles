# Exemplar READMEs — pattern reference for `improve-readme-md`

This file backs the `improve-readme-md` skill's **angle-5 (ecosystem comparison)** review pass. When the multi-agent fan-out reviews a target README, one critic compares it against well-regarded peers in its ecosystem; this file is the candidate pool. The 12 entries split 7 / 5 between CLI tools (the most common shape for solo-author terminal apps the skill is invoked on) and broadly-cited libraries / frameworks (so reviewers can borrow framing tricks from polished marketing READMEs even for a CLI). Distillations are **patterns only** — no raw README content is copied. Treat each "Standout patterns" bullet as a transferable move; treat "Antipatterns" bullets as scale-dependent moves that backfire on small projects. When the target README is itself in one of these ecosystems, prefer in-ecosystem exemplars (e.g. cite `fd` and `bat` for a Rust CLI, `glow` and `fzf` for a Go CLI). When the target needs a shape lift rather than a content lift (badge sprawl, missing hero, no install matrix), the cross-cutting patterns at the bottom are the load-bearing checklist.

## Refresh policy

Each entry below carries a `Last fetched` date. Whenever the skill cites this file:

- **If `Last fetched` is more than 12 months ago**, re-fetch the README via `WebFetch` and update both the per-entry distillation and the `Last fetched` date in the same commit. Pattern notes age fast — taglines get reworded, sections move, hero assets get added.
- **If the repo is archived, deleted, or shows no commits in the last 12 months on `https://github.com/<owner>/<repo>/commits`**, treat it as **dead** and substitute a different in-ecosystem exemplar that's actively maintained. Drop the dead entry from the per-repo sections, drop its row from the quick-pick table, and update the cross-cutting patterns section if it cited the dead exemplar. Note the substitution in a one-line comment under the new entry's `Last fetched` line: `Substituted for <old-name> on <date> (archived / no commits since <year>).`
- **Quick liveness check before re-fetch**: hit `https://api.github.com/repos/<owner>/<repo>` once and look at `archived`, `pushed_at`, and the HTTP status. A 404 means the repo moved or was deleted — search GitHub for the new canonical home before substituting.
- **Dead-repo substitution candidates by ecosystem**:
  - Rust CLI: `helix-editor/helix`, `astral-sh/uv`, `Wilfred/difftastic`, `dandavison/delta`, `extrawurst/gitui`
  - Go CLI: `cli/cli` (gh), `derailed/k9s`, `jesseduffield/lazygit`, `spf13/cobra`, `charmbracelet/bubbletea`
  - TS / JS library: `pmndrs/zustand`, `tanstack/query`, `t3-oss/create-t3-app`, `honojs/hono`, `withastro/astro`
  - Cross-platform framework: `electron/electron`, `flutter/flutter`, `expo/expo`

---

## Quick-pick table

| Repo | Ecosystem | Best when reviewing a… | Single biggest takeaway |
|------|-----------|------------------------|--------------------------|
| `sharkdp/fd` | Rust CLI | small-to-mid CLI replacing a Unix tool | A `Demo` H2 with a single screencast SVG, before any feature prose, sells the tool faster than any feature list |
| `BurntSushi/ripgrep` | Rust CLI | CLI defending its existence vs. incumbents | Dedicated "Why should/shouldn't I use X?" sections — explicit honesty about non-fit cases earns trust |
| `sharkdp/bat` | Rust CLI | CLI with rich visual output | Lead with subsection-level *feature screenshots* (syntax highlighting → git → non-printables) instead of one mega-screenshot |
| `junegunn/fzf` | Go CLI | CLI with shell + editor integrations | Split overflow into `ADVANCED.md` so the main README stays scannable; link to it from a "Advanced topics" stub |
| `eza-community/eza` | Rust CLI | fork / rewrite of an existing tool | Defer the long install list to `INSTALL.md`; keep the README focused on "what's new vs. the original" |
| `ajeetdsouza/zoxide` | Rust CLI | CLI with 10+ install paths | Collapsible `<details>` per OS keeps a sprawling install matrix from drowning the page |
| `charmbracelet/glow` | Go CLI | CLI whose output IS its demo | Put the animated GIF before any prose — for visual tools the demo IS the pitch |
| `tailwindlabs/tailwindcss` | CSS framework | mature library where the README is just a router | Three sections (Documentation, Community, Contributing) — the docs site does the work, README defers cleanly |
| `colinhacks/zod` | TS library | DX-focused dev library | "What is Zod / Features" pairing — name the category, then list aspirations as features (no API docs in README) |
| `shadcn-ui/ui` | UI registry | unconventional distribution model | Stake a positioning claim ("Open Source. Open Code.") in the first paragraph — distinctiveness is the hook |
| `vercel/next.js` | Meta-framework | flagship project of a larger org | Tagline name-drops scale ("used by some of the world's largest companies") to establish credibility in one sentence |
| `tauri-apps/tauri` | Desktop framework | cross-platform framework with platform support claims | Platform support as a 2-column table (Platform / Versions) — answers "does it work on X?" without scrolling |

---

## CLI tools

### fd — fast, user-friendly `find` alternative

- **Last fetched**: 2026-05-10
- **Repo**: `sharkdp/fd` — https://github.com/sharkdp/fd
- **Ecosystem**: Rust CLI
- **Hero asset**: SVG screencast (under a `## Demo` heading, after Features)
- **Tagline shape**: "`fd` is a program to find entries in your filesystem."
- **Badges**: CI status, crates.io version, links to translated READMEs (zh, ko). Restrained — three slots.
- **Section order**: Features → Demo → How to use → Benchmark → Troubleshooting → Integration with other programs → Installation → Development
- **Install matrix style**: Flat bulleted subsections per distro/package manager (~20 platforms), each with a one-line install command. No collapsibles.
- **Standout patterns**:
  - Features list comes *before* the demo — sets expectations, then proves them with a single screencast
  - `## Benchmark` section with concrete `hyperfine` numbers (~23x vs. find) does the "is it actually fast" defense in a paragraph + table
  - `## Troubleshooting` is a top-level H2, not buried — surfaces the FAQ-grade gotchas (smart case, hidden files) where users will find them
  - `## Integration with other programs` shows real shell snippets (fd + fzf, fd + xargs) — positions the tool as part of a pipeline, not a silo
  - Translation links in the header (zh/ko) — small move, signals the project takes non-English users seriously
- **When to cite this exemplar**: Mid-sized Rust/Go CLIs replacing a coreutil. The shape — Features → Demo → Use → Benchmark → Install — is a strong default.

### ripgrep — recursive line-oriented regex search

- **Last fetched**: 2026-05-10
- **Repo**: `BurntSushi/ripgrep` — https://github.com/BurntSushi/ripgrep
- **Ecosystem**: Rust CLI
- **Hero asset**: Static screenshot of search results (linked image)
- **Tagline shape**: "ripgrep is a line-oriented search tool that recursively searches the current directory for a regex pattern."
- **Badges**: GitHub Actions build, crates.io version, repology packaging status. Three, all signal-bearing.
- **Section order**: CHANGELOG → Documentation quick links → Screenshot → Quick examples comparing tools → Why should I use ripgrep? → Why shouldn't I use ripgrep? → Is it really faster than everything else? → Feature comparison → Playground → Installation → Building → Running tests → Related tools → Vulnerability reporting → Translations
- **Install matrix style**: Flat bulleted list (~20 platforms) with copy-pasteable shell commands.
- **Standout patterns**:
  - "Quick examples comparing tools" up top — runs the same query on `grep`, `ag`, and `rg` so the reader sees the difference *before* any prose claim
  - Paired `Why should / Why shouldn't I use ripgrep?` sections — disarming honesty about non-fit cases (binary search, fixed strings under N bytes) builds far more trust than feature lists
  - "Is it really faster than everything else?" links to a long-form post rather than dumping benchmark tables — keeps the README pacing tight while still answering the question
  - Top-of-README "Documentation quick links" sub-section acts as a hand-rolled TOC for the most-jumped-to sections
  - `Vulnerability reporting` and `Translations` as their own H2s — tiny sections, but their presence signals project maturity
- **Antipatterns / things to avoid copying**: Putting `CHANGELOG` as the first H2 only works because ripgrep churns; on a stable small project this is noise. Keep the README focused on *what the tool is*, link to a separate `CHANGELOG.md` instead.
- **When to cite this exemplar**: Any CLI where the user might reasonably ask "why this and not the existing thing." The "Why should/shouldn't" framing is the highest-leverage move.

### bat — `cat` clone with syntax highlighting and Git integration

- **Last fetched**: 2026-05-10
- **Repo**: `sharkdp/bat` — https://github.com/sharkdp/bat
- **Ecosystem**: Rust CLI
- **Hero asset**: SVG logo only — feature screenshots appear inline in the first three sections, not bundled at the top
- **Tagline shape**: "A cat(1) clone with syntax highlighting and Git integration."
- **Badges**: GitHub Actions build, license, crates.io version. Plus a top-of-page repology badge specifically for the install section.
- **Section order**: Syntax highlighting → Git integration → Show non-printable characters → Automatic paging → How to use → Integration with other tools → Installation → Customization → Configuration file → Using bat on Windows → Troubleshooting → Development → Contributing → Maintainers → Security vulnerabilities → Project goals and alternatives → License
- **Install matrix style**: Per-platform `###` subsections under `## Installation`, each with code blocks. Repology badge fronts the section.
- **Standout patterns**:
  - The first four sections are *each a feature with its own screenshot* — the demo is dispersed, so each scroll-page sells one capability rather than betting everything on a single hero image
  - `## Project goals and alternatives` near the bottom — names competing tools and what each does better. Reads as confident, not defensive.
  - Dedicated `## Using bat on Windows` H2 — Windows is the highest-friction platform for Rust CLIs, calling it out by name pre-empts the issues
  - `## Maintainers` listed by handle — humanizes the project; cheap, high-trust move
  - `## Customization` and `## Configuration file` split — reflects two real user journeys (theme tweak vs. config baseline) rather than one mega-config dump
- **When to cite this exemplar**: CLIs whose value is *visual* (highlighting, formatting, color). Disperse the screenshots; don't front-load.

### fzf — general-purpose command-line fuzzy finder

- **Last fetched**: 2026-05-10
- **Repo**: `junegunn/fzf` — https://github.com/junegunn/fzf
- **Ecosystem**: Go CLI
- **Hero asset**: Color logo + preview screenshot
- **Tagline shape**: "fzf is a general-purpose command-line fuzzy finder."
- **Badges**: build, version tag, MIT license, contributors, sponsors, GitHub stars. Six — pushes the limit; the sponsor / contributor count badges feel scale-driven, not informational.
- **Section order**: Installation → Upgrading fzf → Building fzf → Usage → Examples → Key bindings for command-line → Fuzzy completion → Vim plugin → Advanced topics → Tips → Related projects → License → Goods → Sponsors
- **Install matrix style**: Mixed — prose paragraphs for Homebrew/Mise/git, then tables for Linux distros and Windows package managers.
- **Standout patterns**:
  - `## Advanced topics` is a stub that links out to `ADVANCED.md` — the main README stays under 6k words even though the project is enormous
  - Side-by-side preset comparison screenshots (default / full / minimal) — shows configuration's *visual impact* instead of describing it
  - Per-shell snippets (bash / zsh / fish) for completions — respects that shells aren't interchangeable; reader copies their flavor
  - `Vim plugin` as its own top-level section — acknowledges that a major install path *is* its editor integration
  - `Goods` (merch) section near the bottom — softens the otherwise-dense doc; works because it's last
- **Antipatterns / things to avoid copying**: Six-badge strip. Build + version + license is plenty for a project under 10k stars.
- **When to cite this exemplar**: CLIs that grow editor / shell integrations. The "split overflow into ADVANCED.md" pattern is the highest-value steal.

### eza — modern replacement for `ls`

- **Last fetched**: 2026-05-10
- **Repo**: `eza-community/eza` — https://github.com/eza-community/eza
- **Ecosystem**: Rust CLI (community fork of `exa`)
- **Hero asset**: PNG screenshot grid (`docs/images/screenshots.png`)
- **Tagline shape**: "A modern replacement for ls."
- **Badges**: Gitter, "built with Nix," Contributor Covenant, unit tests workflow, crates.io version, crates.io license. Six — heavy.
- **Section order**: Try it! → Installation → Command-line options → Display options → Filtering options → Long view options → Custom Themes → Hacking on eza
- **Install matrix style**: Repology badge + a pointer to `INSTALL.md` for the long matrix; only the most common paths inline.
- **Standout patterns**:
  - `## Try it!` as the first content section — playground / nix-shell one-liner is the lowest-friction "show me" path; lower-friction than install
  - "What's new vs. exa" framing — fork READMEs need to *justify their existence as a separate project* in the first paragraph; eza does this
  - Install matrix lives in a sibling `INSTALL.md` — the README stays tight while the platform sprawl gets full coverage elsewhere
  - Star history chart at the bottom — visual proof of momentum without a "we have N stars" badge
  - `## Custom Themes` as its own top-level section — surfaces the highest-leverage extension point
- **Antipatterns / things to avoid copying**: Six-badge strip — the Contributor Covenant + Gitter + Nix-built badges are organizational signals that fit a community fork but are dead weight on a one-author project.
- **When to cite this exemplar**: Forks, rewrites, or tools that supersede an existing project. Lead with the delta, not the inheritance.

### zoxide — smarter `cd` command

- **Last fetched**: 2026-05-10
- **Repo**: `ajeetdsouza/zoxide` — https://github.com/ajeetdsouza/zoxide
- **Ecosystem**: Rust CLI
- **Hero asset**: Animated tutorial WebP (autoplay, embedded inline)
- **Tagline shape**: "zoxide is a **smarter cd command**, inspired by z and autojump."
- **Badges**: crates.io version, downloads, "built with Nix." Three.
- **Section order**: Getting started → Installation → Configuration → Third-party integrations
- **Install matrix style**: Collapsible `<details>` per OS (Linux/WSL, macOS, Windows, BSD, Android) with nested package-manager tables inside.
- **Standout patterns**:
  - Tagline names the lineage ("inspired by z and autojump") — credit + positioning in five words; pre-empts "isn't this just z?"
  - Each OS in a `<details>` block — clicking the OS you actually use is faster than scrolling past four others
  - Path-and-example tables under each OS — three-column (OS / config path / example) means *one glance* tells you the right rc-file edit
  - "Importing data from competing tools" subsection — says "we expect you're switching from autojump/fasd/z" and lowers migration friction
  - Third-party integrations table calls out *native* vs. *plugin-required* — one small column saves users from wrong assumptions
- **When to cite this exemplar**: Any CLI with a sprawling install matrix (5+ OSes, 3+ package managers each). The collapsible-details pattern is the cleanest scale-handling move in the set.

### glow — render markdown on the CLI, with pizzazz

- **Last fetched**: 2026-05-10
- **Repo**: `charmbracelet/glow` — https://github.com/charmbracelet/glow
- **Ecosystem**: Go CLI (DIRECT competitor / sibling to `md-preview`)
- **Hero asset**: Animated banner GIF, then a static UI screenshot
- **Tagline shape**: "Render markdown on the CLI, with _pizzazz_!"
- **Badges**: Latest Release, GoDoc, Build Status, Go Report Card. Four — the Go-CLI default set.
- **Section order**: What is it? → Installation → The TUI → The CLI → The Config File → Contributing → Feedback → License
- **Install matrix style**: Sequential bash code blocks per package manager (macOS / Linux / Windows / BSD / Android). No table, no collapsibles.
- **Standout patterns**:
  - Animated GIF *before* the title — the demo is the hook; for a markdown-renderer the value is visual
  - Verb-first, voice-y tagline ("Render markdown on the CLI, with pizzazz!") — Charm's house style; sets a fun tone in 8 words
  - `## The TUI` and `## The CLI` as parallel sections — teaches the user the project's two surfaces *as a structure*, not just a list of flags
  - `## Feedback` section pointing to social channels — distinct from "issues" — invites users who don't have a bug yet
  - YAML config example with inline comments — shows shape and defaults in one block
- **When to cite this exemplar**: Direct comparator for `md-preview`. Use when reviewing any markdown / TUI / Charm-adjacent Go CLI.

---

## Libraries & frameworks

### tailwindcss — utility-first CSS framework

- **Last fetched**: 2026-05-10
- **Repo**: `tailwindlabs/tailwindcss` — https://github.com/tailwindlabs/tailwindcss
- **Ecosystem**: CSS framework / TS-distributed
- **Hero asset**: Logo only (linked image)
- **Tagline shape**: "A utility-first CSS framework for rapidly building custom user interfaces."
- **Badges**: GitHub Actions build, npm downloads, npm version, npm license. Four — the npm default.
- **Section order**: Documentation → Community → Contributing
- **Install matrix style**: Not in README — defers entirely to docs site.
- **Standout patterns**:
  - Three-section README — `Documentation`, `Community`, `Contributing`. Confidence move: the README is a router, not the doc itself
  - Each section is two or three sentences max — the README respects that nobody reads a mature library's README cover-to-cover
  - "Utility-first CSS framework" — the tagline names the *category* the project invented; works because the category is now well-known
- **Antipatterns / things to avoid copying**: This README only works because the docs site is exhaustive. A small project with no docs site that copies this structure ends up with no usable documentation.
- **When to cite this exemplar**: When reviewing a project that already has a strong external docs site and the README has become bloated with content that should live there. Argues for *deletion*.

### zod — TypeScript-first schema validation with static type inference

- **Last fetched**: 2026-05-10
- **Repo**: `colinhacks/zod` — https://github.com/colinhacks/zod
- **Ecosystem**: TypeScript library
- **Hero asset**: SVG logo
- **Tagline shape**: "TypeScript-first schema validation with static type inference"
- **Badges**: CI, MIT license, npm weekly downloads, Discord, GitHub stars. Five — borderline; the Discord + stars badges trade signal for marketing.
- **Section order**: What is Zod? → Features → Installation → Basic usage
- **Install matrix style**: Single command (`npm install zod`) — the README doesn't pretend there's a matrix when there isn't.
- **Standout patterns**:
  - "TypeScript-first" — two words that pre-position the entire library against runtime-only validators (joi, yup). The category framing IS the marketing
  - `## Features` is a bulleted *aspirational* list (zero deps, sync + async, branded types) — not API surface; sells the philosophy
  - Discriminated-union error-handling example shown early — picks the *one* idiomatic pattern that's load-bearing and teaches it before anything else
  - `z.infer` / `z.input` / `z.output` shown as a triplet — the type-inference utilities ARE the headline feature; the README treats them that way
- **When to cite this exemplar**: TS / dev libraries where the type-system trick IS the value. Lead with the category-framing tagline.

### shadcn/ui — copy-paste component registry

- **Last fetched**: 2026-05-10
- **Repo**: `shadcn-ui/ui` — https://github.com/shadcn-ui/ui
- **Ecosystem**: React component registry (not an npm package — that's the trick)
- **Hero asset**: OG screenshot image
- **Tagline shape**: "A set of beautifully designed components that you can customize, extend, and build on."
- **Badges**: None (notably).
- **Section order**: Documentation → Contributing → License
- **Install matrix style**: None in README — the install model itself is unusual (CLI copies code into your repo); README points at docs.
- **Standout patterns**:
  - Zero badges — the project is confident enough that no signal-from-CI matters; an unusual choice that works because the project is widely known
  - Positioning paragraph ("Open Source. Open Code.") makes the *unusual distribution model* legible in two sentences — without it, the project would be confused for a normal component library
  - Three-section minimalist body — same shape as Tailwind's; same reason works (docs site does the heavy lifting)
- **Antipatterns / things to avoid copying**: Zero badges only works at scale. For a small project, a single CI-status badge is still load-bearing.
- **When to cite this exemplar**: When the project has an *unconventional distribution / consumption model* that needs explaining before anything else. The first paragraph IS the model explainer.

### next.js — React meta-framework

- **Last fetched**: 2026-05-10
- **Repo**: `vercel/next.js` — https://github.com/vercel/next.js
- **Ecosystem**: TypeScript / React framework
- **Hero asset**: Logo
- **Tagline shape**: "Used by some of the world's largest companies, Next.js enables you to create full-stack web applications by extending the latest React features, and integrating powerful Rust-based JavaScript tooling for the fastest builds."
- **Badges**: Vercel, NPM version, license, "join community." Four; restrained for project size.
- **Section order**: Getting Started → Documentation → Community → Contributing → Good First Issues → Security → About
- **Install matrix style**: Not in README — `Getting Started` links to docs.
- **Standout patterns**:
  - Tagline name-drops scale ("largest companies") in clause one, then names the technical bets (React features, Rust tooling) in clause two — establishes credibility *and* technical posture in one sentence
  - `## Good First Issues` is its own H2 — onboards contributors structurally, not as a footnote in CONTRIBUTING
  - `## Security` is its own H2 with a responsible-disclosure email — for a framework with this surface area, public issues for vulns are a non-starter; prominent placement enforces it
  - `## About` at the bottom — names the maintainer org (Vercel) explicitly. Removes ambiguity about stewardship.
- **Antipatterns / things to avoid copying**: A very long "credibility-first" tagline only works when there *are* large companies to cite. On a small project this reads as filler; lead with what the tool *does* instead.
- **When to cite this exemplar**: Flagship / sponsored OSS projects where governance matters. The `Security` + `About` + `Good First Issues` triad is the credibility package.

### tauri — framework for tiny, fast desktop binaries

- **Last fetched**: 2026-05-10
- **Repo**: `tauri-apps/tauri` — https://github.com/tauri-apps/tauri
- **Ecosystem**: Rust + web frontend (cross-platform desktop)
- **Hero asset**: Splash image
- **Tagline shape**: "Tauri is a framework for building tiny, blazingly fast binaries for all major desktop platforms."
- **Badges**: status (stable), license (MIT/Apache 2), test workflow, FOSSA, Discord, website, Good Labs, sponsorship. Eight — heavy; the org-status / FOSSA / Good Labs badges are governance signals tied to the project being a foundation member.
- **Section order**: Introduction → Getting Started → Features → Contributing → Organization → Licenses
- **Install matrix style**: Two-column markdown table (Platform / Versions) for supported targets — Windows, macOS, Linux, iOS, Android.
- **Standout patterns**:
  - Platform support as a 2-column table answers "does it run on my OS, and what version?" without forcing the user to scroll through prose
  - `## Organization` H2 — names the parent foundation, lists adjacent projects (tao, WRY) as ecosystem siblings; positions Tauri as part of a stack
  - Architecture deferred to `ARCHITECTURE.md` — the README acknowledges the system is too big to summarize and points at the right doc
  - Dual-license callout (MIT *or* Apache 2) up front — load-bearing for an org-friendly framework; users need to see this before importing
- **Antipatterns / things to avoid copying**: Eight badges. The FOSSA / Good Labs / Discord set is appropriate for a foundation-backed project; on anything smaller it's badge soup.
- **When to cite this exemplar**: Cross-platform tools where "does it run on X" is the first user question. The platform-support table is the canonical answer shape.

---

## Cross-cutting patterns worth copying

These show up in 3+ exemplars and are robustly applicable down to small projects. Each bullet names the exemplars that use it.

- **Verb-first or category-first tagline (≤120 chars)** — `fd`, `bat`, `glow`, `eza`, `zod`, `tauri`. Whether it's "A cat clone with syntax highlighting…" or "TypeScript-first schema validation…", the first sentence positions the project *as a category*. Avoid "X is a tool that…" filler.
- **Demo asset above the fold** — `fd` (SVG screencast), `glow` (animated GIF), `zoxide` (animated WebP), `bat` (per-section screenshots), `eza` (screenshot grid). For visual tools, the demo precedes prose. Prefer SVG screencast > animated WebP/GIF > static screenshot.
- **3-badge ceiling for small projects** — `fd`, `ripgrep`, `bat`, `zoxide` all run lean (3-4 badges, all signal-bearing: build / version / packaging). Anything above 5 (fzf, eza, tauri) starts being noise unless project scale demands it.
- **Comparison / positioning section against alternatives** — `ripgrep` ("Why should/shouldn't I use…"), `bat` ("Project goals and alternatives"), `eza` (vs. exa). Naming the competition explicitly out-performs implicit comparison.
- **Defer overflow to a sibling doc** — `fzf` → `ADVANCED.md`, `eza` → `INSTALL.md`, `tauri` → `ARCHITECTURE.md`. When a section starts pushing the README past ~600 lines, eject it to a sibling and link.
- **Top-level `Troubleshooting` H2** — `fd`, `bat`. Surfaces the FAQ-grade gotchas where users hit them, instead of burying in a wiki.
- **Install matrix in priority order, not alphabetical** — `fd`, `ripgrep`, `bat`, `zoxide` all lead with the OS / package manager that has the most users (Homebrew on macOS, apt on Debian/Ubuntu) before sliding into the long tail. Alphabetical install lists are the cargo-cult version.
- **Collapsible `<details>` for sprawling install matrices** — `zoxide` is the cleanest example. When the matrix is 5+ OSes × 3+ managers, collapsibles beat flat bullets.
- **Integration / "playing well with others" section** — `fd`, `bat`, `zoxide`, `fzf`. Real shell snippets (X + fzf, X + ripgrep) reframe the tool as part of a workflow.
- **Tagline that names the lineage when the project is a fork or successor** — `eza` (vs. exa), `zoxide` (inspired by z, autojump), `bat` (cat clone). Pre-empts "isn't this just X?" in the first sentence.
- **Section order: hook → demo → use → install → develop** — `fd` and `bat` exemplify this. The default trap is putting Installation first; the better default is putting the *value* first.
