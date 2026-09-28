---
name: get-fh
description: >-
  Build a slow-motion compilation of ONE stroke type (default: the user's
  forehand) shown fully in frame, from a long fixed-camera racket-sport
  practice video (tennis, padel, pickleball). Triggers on requests like
  "make a video of only my forehands in slow motion", "compile my forehands
  in full view at 0.25x", "get my forehand clips from this tennis video",
  "cut just my backhands slowed down". Handedness, which stroke, player side,
  target clip count and playback speed are all configurable. Assumes a fixed
  (tripod) camera and one main player in frame. Requires ffmpeg, python3 with
  numpy and Pillow. Sibling: video-edit is the generic single-file ffmpeg
  playbook; use get-fh specifically for stroke-filtered slow-mo compilations.
---

# get-fh

Find every instance of one stroke type in a long fixed-camera practice video and
cut a slow-motion reel of the ones where the player is fully in view (body and
racket, not clipped by the frame edge).

The hard part is telling a forehand from a backhand. No cheap signal does it
reliably from this camera angle, so the pipeline reduces the video to a small set
of candidate contact moments, renders a compact motion strip for each, and the
stroke call is a vision step you (Claude) do on those strips. Everything around
that is scripted in `scripts/fh.py`.

## Preconditions

- `ffmpeg` / `ffprobe` on PATH.
- python3 with `numpy` and `Pillow`. If missing, make a venv:
  `python3 -m venv /tmp/fhvenv && /tmp/fhvenv/bin/pip install numpy Pillow`, and
  call `fh.py` with that interpreter.
- A fixed camera. If the camera pans, the background model breaks; stop and say so.

## Inputs to confirm before starting

Ask only what you cannot see in the footage:

1. **Which player is the subject** (there is usually one main player). Get it wrong
   and the whole reel is wrong.
2. **Handedness** (right/left). Decides forehand vs backhand.
3. **Scope**: every instance (long output) vs the cleanest N (tight reel). At 0.25x
   each swing becomes ~5-8s, so "every forehand" over an hour is easily 20-40 min.

## Workflow

Pick a work dir, e.g. `WORK=<scratch>/get-fh`.

### 1. Probe (video-edit Step 1)

`ffprobe` for duration, resolution, fps. Sanity-check the camera is static by
reading two frames minutes apart.

### 2. Analyze -> candidates

```
python3 scripts/fh.py analyze "<video>" --work "$WORK"
```

This does three things in a couple of minutes:
- extracts mono audio and detects ball-strike onsets (each "pock" is a candidate
  contact time),
- runs a single low-res decode computing per-frame motion and a block-median
  background so the player's bounding box survives lighting drift,
- keeps onsets that land while the player is in frame, dedupes them, and writes
  `candidates.csv` (time, player x, edge-risk flag, motion).

Onsets alone are noisy (partner hits, bounces), which is why the vision step below
still filters hard.

### 3. Sheets -> classification strips

```
python3 scripts/fh.py sheets "<video>" --work "$WORK"
```

Builds one 6-frame motion strip per candidate (takeback -> contact ->
follow-through, 0.15s apart), packed onto sheet images. Six frames is the key: a
single still is ambiguous, but the swing arc across six frames makes the stroke
obvious. Green header = player fully in frame; red `EDGE-RISK` = bbox touches an
edge, likely clipped, treat as reject unless clearly whole.

### 4. Classify (vision, you or subagents)

Read the sheets. For the target stroke, a **right-handed forehand** reads as:
racket taken back low/behind on the right, one-handed swing forward, contact in
front, follow-through finishing up over the LEFT shoulder (arc moves right to
left). A **two-handed backhand** is both hands, racket to the left side. Mirror
for a left-hander.

Keep a strip only when it is (a) clearly the target stroke and (b) the whole body
and racket stay inside the frame through contact. Prefer precision over recall.

For a big candidate set, fan out subagents: hand each a batch of sheet paths and
the rule above, have each return `{idx, t, confidence, note}` for clean keepers
only, then pool. For "cleanest N", rank by confidence and spread picks across the
session. Write the kept contact times (one per line) to `$WORK/keep.txt`.

Spot-check a few keepers yourself against the full-res frames before assembling.

### 5. Assemble

```
python3 scripts/fh.py assemble "<video>" --work "$WORK" --keep "$WORK/keep.txt" \
  --out "<video-stem>_forehands.mp4" --speed 0.25 --pre 0.7 --post 0.9
```

Cuts each contact time to a `[-pre, +post]` window (whole swing plus a beat),
slows it, drops audio (0.25x audio is a droning mess), and concats. Full 720p
frame is kept so "fully in view" is guaranteed. Verify per video-edit Step 4:
read first/last frames of the output and confirm duration.

**Fluid slow-mo (important):** plain `setpts` just holds each source frame, so a
30fps clip at 0.25x shows ~7 unique frames/sec and stutters badly. `assemble`
defaults to `--interp mci`, which runs `minterpolate` (motion-compensated frame
interpolation) after the stretch to synthesize real in-between frames at
`--fps` (default 60). This is the fix for "the slow-mo looks choppy". It is CPU
heavy (~1 min per clip at 720p), so bump `--jobs` to your core count. `--interp
blend` is a cheaper crossfade; `--interp none` is the old choppy hold. On very
fast motion mci can warp briefly; drop to `blend` if a swing looks smeary.

## Speed levers

The two slow parts are the decode passes and per-candidate frame extraction. Ways
to make it faster, roughly in order of payoff:

- **Frame cache, not seeks** (already the default in `sheets`): decode the whole
  video to JPGs once at `--cache-fps` and crop strips from disk, instead of tens
  of thousands of `ffmpeg -ss` seeks. Trades disk for a big wall-clock win and
  makes re-running `sheets` instant. Delete `$WORK/cache` when done.
- **One analysis decode** (already merged): motion and bbox come from a single
  low-res pass, not two.
- **Parallel by time-segment**: split the video into N chunks (N = cores) and run
  the analysis / cache decodes concurrently, then merge. ffmpeg is single-thread-
  bound per stream on this workload, so this is close to linear.
- **Cache only candidate windows**: once `candidates.csv` exists, cache frames
  only within +-0.6s of a candidate (a `select` over unioned windows) to shrink
  the cache decode and disk when candidates are sparse.
- **Prune candidates earlier**: raise the onset refractory / dedupe, or gate on
  audio loudness (the subject's own contact is louder/closer than the partner's)
  to drop far-court hits before rendering strips.
- **Fewer frames for a first pass**: classify on 3-frame strips to reject the
  obvious non-strokes cheaply, then render 6-frame strips only for survivors.
- **Local pose model (`scripts/pose_classify.py`, experimental)**: with
  `ultralytics` installed, runs YOLO11-pose on the cached frames around each
  candidate, classifies forehand/backhand from wrist-shoulder geometry, and
  enforces full-view from keypoints. Fully automatic and higher-recall than the
  strict subagent scan. BUT on a small, distant player the nano model's
  keypoints are jittery and hand-tuned geometry rules misfire (sprints and wide
  reaches read as forehands, and tightening the rule drops real forehands). In a
  head-to-head on a 54-min clay-court clip it was noisier than the audio+vision
  method, not cleaner. To make it win: use a larger pose model (yolo11m/x-pose)
  for stable keypoints, sample at higher fps near contact, and train a small
  classifier on the keypoint sequence instead of thresholds. A purpose-built app
  (SwingVision) already does exactly this if the goal is the result, not the DIY.

## Notes

- The `EDGE-RISK` flag over-fires when the player casts a long shadow to the frame
  edge (shadow inflates the bbox). Do not auto-reject on it; let the strip decide.
- Racket-visible check matters most near the left/right edges and on high
  follow-throughs; that is exactly where the flag helps you look harder.
- Composes with `video-edit` for any extra trim/crop/scale on the final reel.
