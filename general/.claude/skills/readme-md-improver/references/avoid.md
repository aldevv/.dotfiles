# Anti-patterns: Bad → Better worked examples

Companion to `SKILL.md`. Each entry pairs a real **Bad** form with the **Better** rewrite, sourced from actual READMEs the skill has improved. The rule names match the bullets in `SKILL.md`'s "Concrete techniques" and the angle-2 description — this file carries the worked detail so `SKILL.md` stays scannable.

**When to read this**: during step 6 (apply selected changes), after the user picks a scope. Skim the entries that match the patterns you're about to fix — the **Better** form usually points at the specific replacement shape.

---

## Flat paragraph block packing ≥3 unrelated topics

A trailing block at the end of a section that flatly stacks several unrelated topics. Each topic becomes invisible to Cmd-F because the surrounding heading doesn't name it.

**Bad** — from a Go CLI's `## Usage` section:

```markdown
In-page nav: `j`/`k`, `h`/`l`, `d`/`u` (half-page), `g`/`G` (top/bottom), `q` to close. Colemak-keyboard users get `h`/`n`/`e`/`i` via `colemak = true` in the config.

`-e` opens nvim after spawning the browser preview. The preview is static — re-run `mdp` to refresh, or use the Neovim plugin for live scroll-sync.

YAML frontmatter is stripped, not rendered. Raw HTML in markdown is intentionally **not** rendered (security): the preview origin is loopback-bound and a malicious README could otherwise inject scripts.
```

Three topics jammed together: keyboard reference, refresh-model + flag clarification, rendering/security caveat. None individually findable.

**Better**:

```markdown
### Keys

| Action       | Default   | Colemak   |
| ------------ | --------- | --------- |
| Down / Up    | `j` / `k` | `n` / `e` |
| ...          | ...       | ...       |

Enable Colemak with `colemak = true` in the [config](#config).

### Notes

The preview is static — re-run `mdp` to refresh, or install the [Neovim plugin](#neovim-plugin) for live scroll-sync.

YAML frontmatter is stripped. Raw HTML in markdown is intentionally **not** rendered (security): the preview origin is loopback-bound and a malicious README could otherwise inject scripts.
```

The keys move into a table under their own H3; the misc behavior caveats consolidate under `### Notes`. The flag-clarification sentence (`-e opens nvim after spawning the browser preview`) is dropped because the cheat-sheet code block already shows `mdp -e # preview AND open the file in nvim` — it was redundant prose.

**Why it wins**: each topic has a heading or tabular shape that names it. A reader Cmd-F-ing for "Colemak" lands on the table; "scroll-sync" on Notes; "raw HTML" on Notes.

---

## Comma-string enumeration when an alt-mapping exists

A keys / flags reference written as a comma-string forces the reader to decode which alternate replaces which default.

**Bad**:

```markdown
In-page nav: `j`/`k`, `h`/`l`, `d`/`u` (half-page), `g`/`G` (top/bottom), `q` to close. Colemak-keyboard users get `h`/`n`/`e`/`i` via `colemak = true` in the config.
```

The reader has to pattern-match `h/n/e/i` against `j/k/h/l` to discover that Colemak's `n` replaces `j`, `e` replaces `k`, `i` replaces `l`, `h` is unchanged. The mapping is left as homework.

**Better** — table form:

```markdown
| Action            | Default   | Colemak   |
| ----------------- | --------- | --------- |
| Down / Up         | `j` / `k` | `n` / `e` |
| Left / Right      | `h` / `l` | `h` / `i` |
| Half-page down/up | `d` / `u` | `d` / `u` |
| Top / Bottom      | `g` / `G` | `g` / `G` |
| Close             | `q`       | `q`       |
```

**Why it wins**: the mapping IS the value. A glance per row.

---

## Splitting half a reference into a prose afterthought

A near-miss of the previous fix: half the reference goes into a table, the other half ("the rest are the same on both layouts") becomes prose. The reader has to stitch two formats together.

**Bad**:

```markdown
| Action       | Default   | Colemak   |
| ------------ | --------- | --------- |
| Down / Up    | `j` / `k` | `n` / `e` |
| Left / Right | `h` / `l` | `h` / `i` |

`d`/`u` half-page, `g`/`G` top/bottom, `q` close — same on both layouts. Enable Colemak with `colemak = true` in the config.
```

A reader scanning the table for "how do I jump to the bottom?" doesn't find `g`/`G`, has to drop into the prose afterthought to discover it.

**Better**: include the unchanged-on-alt rows in the *same* table, repeating the default in the alt column (`q` appears in both columns). See the table in the previous entry. The visual repetition is a feature: it tells the reader "yes, same on both layouts, no exception to remember."

**Why it wins**: one surface, one lookup format.

---

## H3 dumping an exhaustive list of implementation-detail binaries or flags

A subsection whose entire body is a paragraph-form enumeration of every binary or flag value the tool might match. Reads as a code dump in prose.

**Bad**:

```markdown
### Browser

`mdp` auto-detects, in order: Chromium-family (`google-chrome`, `chromium`, `brave-browser`, `microsoft-edge`, `vivaldi`) opened with `--app=` for a chromeless window; then Firefox-family (`firefox`, `firefox-esr`, `librewolf`, `waterfox`) opened with `--new-window`. Falls back to `xdg-open` (Linux) or `open` (macOS) when none are found. Override with `browser = ...` in the config.
```

Five Chromium binaries, four Firefox binaries, two fallback commands. The reader doesn't need any of them — they have one browser installed and just want to know "will it find mine?" and "how do I override?"

**Better** — compress to a sentence, drop the H3, let `--help` or source carry the binary list:

```markdown
`mdp` auto-detects a browser (Chromium- or Firefox-family, then `xdg-open` / `open`). Override via `browser = ...` in the [config](#config).
```

**Why it wins**: the two questions a reader actually has are answered in one sentence. Exhaustive enumeration belongs in code, not the README.

---

## Pre-documenting runtime UX the reader only encounters in context

A bullet or sentence that describes what an installer / CLI prints, warns about, or falls back to. The reader only sees this behavior at runtime — at which point the runtime UX is its own teacher. The doc line is filler until then.

**Bad** — from a Go CLI's `## Install` bullet list:

```markdown
- Prebuilt binaries — [Releases page](...).
- Building from source needs Go 1.26.2+ (release users don't).
- The installer warns if the install dir isn't on `PATH`.
```

The third bullet documents a behavior the user only encounters when running the installer. If the warning fires, they see it. If it doesn't, the line is noise. The reader can't *act* on the bullet; it's a passive promise about a future stdout message.

**Better** — drop the bullet:

```markdown
- Prebuilt binaries — [Releases page](...).
- Building from source needs Go 1.26.2+ (release users don't).
```

Or — if PATH guidance is actually load-bearing — give the actionable form directly:

```markdown
- After install, add the install dir to your `PATH`:
  `export PATH="$HOME/.local/bin:$PATH"`
```

**Why it wins**: doc prose isn't the right surface for runtime CLI contracts. A reader-visible line should give them an action they can take *now*; otherwise it vacates the line. Same logic applies to "the build will fail if X," "you'll see a deprecation warning if Y," "the CLI prints a banner on first run" — either fix the underlying thing or remove the line.

---

## Embedding a video via `<video>` tag pointing at a `raw.githubusercontent.com` URL

The instinct: drop an mp4 in the repo, reference it with `<video src="...raw...">`. It silently renders as **nothing** on github.com — the README sanitizer strips `<video>` tags whose `src` isn't from `github.com/user-attachments` or `user-images.githubusercontent.com`. The author tests it locally (where the tag works), commits, pushes, and discovers the demo is invisible on the rendered README.

The naive next attempt — drop the tag and leave the bare `.../raw/.../demo.mp4` URL — is barely better. A bare raw URL on its own line renders as a *link*, not a player. The reader has to click through.

**Bad** — committed mp4 + `<video>` tag:

```markdown
<video src="https://github.com/aldevv/md-preview/raw/main/docs/demo.mp4" controls width="100%"></video>
```

Renders as: nothing. The `<p>` containing the tag becomes empty in GitHub's HTML.

**Better** — bare `user-attachments` URL on its own line:

```markdown
https://github.com/user-attachments/assets/19f64fa1-a4d6-4a9c-a94f-2c40ca5a979b
```

GitHub auto-wraps this in a native `<video>` player. The mp4 lives on GitHub's CDN, not in the repo.

**Why it wins**: bare `user-attachments` URLs are the *only* repo-external pattern GitHub's renderer turns into a player. No tag needed; no repo bloat.

**Where to look for the antidote**: `references/github-markdown.md` carries the full workflow — how the author obtains the `user-attachments` URL (drag-drop into a new issue editor), when to use a GIF instead (off-GitHub renderers), and the YouTube thumbnail fallback for longer walk-throughs.
