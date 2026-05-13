# GitHub-flavored markdown features for READMEs

Companion to `SKILL.md`. Positive reference: GitHub-specific markdown features worth using when their semantics fit. Antipatterns (`**Note:**` prefixes, stripped `<video>` tags) live in `avoid.md` — this file is the antidote, not the diagnosis.

**When to read this**: during step 6 (apply selected changes), when the picked items include a video embed, a callout, or any other GitHub-specific markdown feature.

---

## Alerts (`> [!NOTE]` and friends)

GitHub renders five blockquote-prefix markers as styled, icon-bearing callout boxes. On any other renderer (npm, crates.io, pypi, internal docs sites) they fall back to ordinary blockquotes — graceful degradation, no off-GitHub breakage.

### Syntax

The marker is on its own line; every body line is also prefixed with `>`:

```markdown
> [!IMPORTANT]
> Raw HTML in markdown is intentionally **not** rendered: the preview origin
> is loopback-bound and a malicious README could otherwise inject scripts.
```

### Type semantics

| Type           | Use for                                                                |
| -------------- | ---------------------------------------------------------------------- |
| `[!NOTE]`      | Neutral useful info — supported platforms, prerequisites               |
| `[!TIP]`       | Optional power-user advice                                             |
| `[!IMPORTANT]` | Load-bearing info the reader MUST notice — security, must-set env vars |
| `[!WARNING]`   | Bad outcome if ignored                                                 |
| `[!CAUTION]`   | Possibly destructive operation                                         |

Pick semantics deliberately:

- `[!IMPORTANT]` for "raw HTML is not rendered for security reasons" reads naturally; `[!WARNING]` would read as alarmist for the same content.
- Don't reach for `[!CAUTION]` unless the user could actually lose data.
- `[!WARNING]` is not "this might surprise you" — that's `[!NOTE]` or `[!TIP]`.

---

## Embedding a video

GitHub's README sanitizer strips `<video>` tags whose `src` isn't from `github.com/user-attachments` or `user-images.githubusercontent.com`. A bare `.../raw/.../demo.mp4` URL renders as a plain link, not a player. The three patterns below are the ones that actually work.

### Option 1 — `user-attachments` URL (preferred for github.com)

The mp4 lives on GitHub's CDN, the README has a bare URL on its own line, GitHub auto-wraps it in a native `<video>` player with audio and controls. No repo bloat. Only renders on github.com.

Author steps (one-time, manual — this skill can't do it):

1. Open `https://github.com/<user>/<repo>/issues/new`. Don't fill in title/body, don't submit — the editor is just an uploader.
2. Drag the mp4 into the comment textarea (or click "Attach files" at the bottom).
3. Wait for the upload progress bar to finish. The placeholder becomes a URL of the form `https://github.com/user-attachments/assets/<uuid>`.
4. Copy that URL.
5. Close the issue tab without submitting. The asset stays alive on GitHub's CDN.

In the README, paste it on its own line:

```markdown
Preview any `.md` file in a real browser tab — single static binary.

https://github.com/user-attachments/assets/19f64fa1-a4d6-4a9c-a94f-2c40ca5a979b

## Install
```

### Option 2 — GIF under `docs/`

Renders everywhere a README ends up (npm, crates.io, pypi, anywhere). No audio, larger file, but no upload step and no GitHub dependency.

Conversion (lanczos + palette, the standard high-quality recipe):

```sh
ffmpeg -i in.mp4 -vf "fps=15,scale=900:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" out.gif
```

Embed:

```markdown
![demo](docs/demo.gif)
```

### Option 3 — YouTube thumbnail link

For walk-throughs >30s where filesize would be prohibitive. The thumbnail is a static image, clicking jumps to YouTube.

```markdown
[![demo](https://img.youtube.com/vi/<id>/maxresdefault.jpg)](https://youtu.be/<id>)
```

### Picking between them

| Situation                                                           | Use                  |
| ------------------------------------------------------------------- | -------------------- |
| Short demo, README only consumed on github.com                      | `user-attachments`   |
| README rendered off-GitHub too (npm/crates.io/pypi)                 | GIF                  |
| Walk-through, file would be too large                               | YouTube thumbnail    |

### When proposing this fix

The user has to perform the upload (step 1–4 above) themselves. When step 6 of the skill calls for swapping a stripped `<video>` tag to a `user-attachments` URL: spell out the upload steps, wait for them to paste the URL back, then swap it in. Don't promise a player without the URL in hand.
