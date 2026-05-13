---
name: video-edit
description: "Edit a video file with ffmpeg — trim, crop, scale, concat, mute, change speed, transcode, extract audio/frames. Inspection (probe + sample-frame extraction) runs in parallel; multi-op edits are bundled into a single ffmpeg pass to preserve quality. Trigger when the user asks to trim/cut/clip/shorten a video, crop a bar/border, remove the OBS UI from a recording, scale/resize, change FPS, mute, speed up or slow down, concatenate clips, transcode, extract a still or the audio track. Common phrasing: 'trim the first/last N seconds', 'remove the top bar', 'cut the OBS frames', 'crop X off the top/bottom', 'speed this up 2x', 'scale to 720p', 'mute the audio', 'extract a frame at Ns', 'concat these two clips'. Do NOT trigger for: choosing a video editor app, advice about non-ffmpeg tooling (DaVinci, Premiere, kdenlive), or pure-audio files (use a different tool)."
argument-hint: "<input.mp4> [op...] — operation is inferred from the user request. Examples: 'trim 1s..17s', 'crop top 32', 'scale 1280x720', 'mute', 'extract frame 5s', 'speed 2x'."
---

# video-edit

A playbook for ffmpeg-based video edits. Optimized for the common cases I run into (mostly trimming and cropping OBS recordings), but covers the broader catalog of single-pass operations.

## Core principles

1. **Inspect first, edit second.** Never run a destructive ffmpeg pass before knowing the file's duration, resolution, fps, and where the content boundaries are. The probe is cheap, the wrong trim is expensive.
2. **One pass per output.** When the user asks for trim+crop+scale, build **one** ffmpeg command with chained `-vf` filters and a single `-ss/-to`. Chaining encodes round-trips quality through libx264 multiple times.
3. **Never overwrite the input.** Always write to a sibling file with a clear suffix (`_trimmed`, `_cropped`, `_<op>`, or `_edit` for combined). Leave the original alone unless the user explicitly says "in place" — and even then, write to a temp first, verify, then `mv`.
4. **Parallelize the slow parts.** Frame extraction and probe and metadata reads are independent and can be issued in a single message. So can the "look at start" + "look at end" frame inspections.
5. **Verify before reporting done.** After the edit, read the first and last frames of the output to confirm the trim/crop landed where intended. Don't skip this — the boundary frames are exactly what the user asked you to fix.

## Operation taxonomy (decides which steps run)

Sort the request into one of these before Step 1 — it determines whether Step 2 (boundary detection) runs:

- **Parameter-explicit** ops — user gave you the exact knob (e.g. "scale to 720p", "mute", "speed 2x", "extract frame at 5s", "transcode to webm", "crop top 32px"). Skip Step 2; go straight to Step 3.
- **Boundary-finding** ops — user described content, not coordinates ("remove the first few seconds", "trim the OBS bookends", "crop the top bar" without a pixel count). Step 2 is mandatory: visually find the boundary first.

## Step 1 — Probe (always) + first-pass sample (boundary-finding only)

Issue **in a single message**:

- Always: `ffprobe -v error -show_entries stream=width,height,duration,r_frame_rate -of default=noprint_wrappers=1 <input>` — duration, resolution, fps. (Note: `r_frame_rate` is rational like `60/1`, not a number.)
- Boundary-finding only: extract sample frames at **2 fps** to a temp dir (good enough to find scene boundaries within ~0.5s):
  ```bash
  rm -rf /tmp/vidframes && mkdir -p /tmp/vidframes
  ffmpeg -y -i <input> -vf "fps=2" /tmp/vidframes/f_%03d.png 2>&1 | tail -2
  ```

## Step 2 — Identify boundaries (boundary-finding ops only)

For **trim** ("remove the first/last N seconds", "cut the OBS frames"):

- Read the first sample frame and a frame ~5s later in **parallel** (multiple Read calls in one message).
- If they look the same kind of content (e.g. both desktop), trim is unnecessary — confirm with user.
- If they differ (intro/UI vs. content), narrow with a 10 fps re-extract over the suspect window:
  ```bash
  ffmpeg -y -ss <approx-start> -to <approx-end> -i <input> -vf "fps=10" /tmp/vidframes/zoom_%03d.png
  ```
  Read 3–5 frames spanning the transition in parallel. Pick the first frame that's clean content. Add a 0.05–0.1s safety pad.
- Repeat for the end boundary.

For **visual crop** ("remove the top bar" with no pixel count, "crop the title bar off"):

- Extract one clean content frame, crop the top N px to a sibling PNG (`crop=W:N:0:0`), and Read it. Test heights 28/32/36/40 **in parallel** until the bar is fully gone but content isn't clipped.
- Round to an even number — libx264 requires even dimensions on the output, and the crop's resulting H must stay even too.
- (If the user gave an exact pixel count, this is a parameter-explicit op — skip this step.)

## Step 3 — Build the single ffmpeg command

**Chain everything into one pass.** Common operation cookbook (combine as needed):

| Operation | ffmpeg fragment |
|---|---|
| Trim | `-ss <start> -to <end>` (place **before** `-i` for fast seek; before output for accurate seek) |
| Crop top bar | `-vf "crop=<W>:<H-top>:0:<top>"` |
| Crop arbitrary | `-vf "crop=w:h:x:y"` |
| Scale | `-vf "scale=<w>:<h>"` (use `-1` for one dim to keep aspect) |
| Change fps | `-vf "fps=<n>"` |
| Speed up Nx (video) | `-vf "setpts=PTS/<N>"` |
| Speed up Nx (audio) | `-af "atempo=<N>"` (max 2.0 per filter — chain for >2x) |
| Mute | `-an` |
| Extract audio | `-vn -acodec copy <out.<ext>>` |
| Extract single frame | `-ss <t> -frames:v 1 <out.png>` |
| Concat (same codec) | `-f concat -safe 0 -i list.txt -c copy <out>` |
| Transcode | omit `-c copy`; let `-c:v libx264 -crf 18` re-encode |

**Combining filters**: separate with commas inside one `-vf` quote:
```bash
-vf "crop=1920:1048:0:32,scale=1280:720"
```

**Encoder defaults** (when re-encoding):
- Video: `-c:v libx264 -preset medium -crf 18` (visually lossless-ish; bump CRF to 23 for smaller files).
- Audio: `-c:a copy` if container supports it; else `-c:a aac -b:a 192k`.
- Output container: keep the input's extension unless the user asked otherwise.

**When you can avoid re-encoding**: pure trims on keyframe boundaries can use `-c copy` and run in milliseconds. But the trim becomes inexact (snaps to nearest keyframe). Default to re-encoding for accuracy unless the user says "fast" or the trim is on round-second keyframe boundaries.

**Output path**: `<input-stem>_<suffix>.<ext>` next to the original. Suffixes:
- single op: `_trimmed`, `_cropped`, `_scaled`, `_muted`
- multi op: `_edit`
- audio extract: `_audio.<ext>`
- frame extract: `<input-stem>_<ts>s.png`

## Step 4 — Run + verify (PARALLEL verification)

Run the ffmpeg command. After it completes, in **a single message** issue:

- `ffprobe` on the output to confirm new duration/dimensions.
- Extract first frame: `ffmpeg -y -ss 0 -i <output> -frames:v 1 /tmp/out_start.png`
- Extract last frame: `ffmpeg -y -sseof -0.1 -i <output> -frames:v 1 /tmp/out_end.png`

Then Read both PNGs in parallel. Confirm:

- First frame is what should be the new opening (no leftover intro/UI).
- Last frame is what should be the new closing (no leftover outro/UI).
- Dimensions and duration match the plan.

If anything is off, redo with adjusted parameters before reporting to the user.

## Step 5 — Report

One sentence: what you wrote, where, dimensions, duration, what was removed/changed. Mention that the original is untouched. Offer to redo with different bounds if the user wants.

## Common scenarios (cookbook)

### "Remove OBS bookends + top bar from an OBS recording"

This is the canonical case. OBS recordings often have:
- 0.5–1.5s of OBS UI at the start (before the user minimized).
- 0.5–2s of OBS UI at the end (after they clicked Stop Recording).
- A persistent OS top bar (i3bar, etc.) the user wants out.

Workflow:
1. Probe + 2fps sample (Step 1).
2. Read frame 1 (0.0s), frame 2 (0.5s), frame 3 (1.0s), frame 4 (1.5s) **in parallel**. Find first OBS-free frame.
3. Read last few frames **in parallel**. Find last OBS-free frame.
4. If transitions are within 0.2s of a sample, narrow with a 10fps zoomed extract over the suspect 1–2s window.
5. Crop top bar: read one clean content frame, test crop heights 28/32/36/40 in parallel. Pick smallest height that fully removes the bar.
6. One-pass: `-ss <start> -to <end> -vf "crop=<W>:<H-top>:0:<top>"` with `-c:v libx264 -crf 18 -c:a copy`.
7. Verify start/end frames.

### "Trim only"

Skip the crop step. Use `-c copy` only if the user asked for a fast cut and is OK with keyframe-snap inaccuracy.

### "Crop only"

Skip the trim/boundary step. Verify first/last frame after.

### "Scale / change fps / transcode"

Skip the frame extraction in Step 1 — no boundaries to detect. Probe is enough. Verify the output's dimensions/duration via `ffprobe` after.

### "Concat clips A and B"

If A and B share codec/resolution/fps:
```bash
printf "file '%s'\nfile '%s'\n" "$PWD/A.mp4" "$PWD/B.mp4" > /tmp/concat.txt
ffmpeg -y -f concat -safe 0 -i /tmp/concat.txt -c copy <out>
```
If they don't match, scale/transcode each to a common spec first (two parallel ffmpeg calls), then concat.

### "Speed up 3x"

```bash
-vf "setpts=PTS/3" -af "atempo=2.0,atempo=1.5"
```
(`atempo` caps at 2.0 per filter; chain for higher rates.)

### "Extract a frame at Ns"

```bash
ffmpeg -y -ss <N> -i <input> -frames:v 1 <input-stem>_<N>s.png
```

## Guardrails

- **Never write to the input path.** Even with `-y`, the user expects the original preserved.
- **Even dimensions.** libx264 fails on odd width or height after crop/scale. Round to even before passing.
- **Don't chain ffmpeg passes** when one combined `-vf` filtergraph would do the same job with one encode.
- **Don't extract frames at high fps** unless narrowing a known transition window — at 60fps × 20s that's 1200 PNGs per scan.
- **Don't ask the user to confirm pixel counts before trying** when you can crop and visually verify in 2 calls. Visual confirmation is faster than a clarifying question.
- **Audio sync**: when re-encoding video but copying audio, sync usually holds. If the user reports drift, re-encode audio too (`-c:a aac -b:a 192k`) and remove `-c:a copy`.
- **`-ss` placement**: before `-i` = fast seek (keyframe-aligned, can be slightly off). After `-i` (or `-to` after `-i`) = accurate seek (slower, exact). For short videos default to accurate; for long videos with small trims do fast seek before `-i` then accurate within.

## Composition

This skill doesn't delegate to other skills. It's a single-tool playbook around `ffmpeg` and `ffprobe`. If a user asks for something genuinely outside ffmpeg's reach (e.g. "remove the watermark", "auto-caption"), say so and stop — don't spiral into ffmpeg gymnastics.
