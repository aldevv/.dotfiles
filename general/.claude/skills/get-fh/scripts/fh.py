#!/usr/bin/env python3
"""get-fh pipeline: find one stroke type (default forehand) in a long fixed-camera
racket-sport video and cut a slow-motion compilation.

Subcommands:
  analyze  VIDEO            audio onsets + motion/bbox pass -> candidates.csv
  sheets                    build 6-frame classification strips (frame-cache, fast)
  assemble --keep FILE      cut + slow + concat the kept timestamps

The forehand/backhand call itself is a vision step done by Claude (or subagents)
reading the sheets; see SKILL.md. This script does everything around it.
"""
import argparse, subprocess, os, sys, csv, json, wave
import numpy as np
from concurrent.futures import ThreadPoolExecutor

def sh(args):
    subprocess.run(args, check=False)

def work_paths(work):
    os.makedirs(work, exist_ok=True)
    return {k: os.path.join(work, v) for k, v in {
        "audio": "audio.wav", "onsets": "onsets.npy", "pass1": "pass1.npz",
        "cands": "candidates.csv", "cache": "cache", "sheets": "sheets",
        "clips": "clips", "manifest": "sheets_manifest.json"}.items()}

# ---------- analyze ----------
def detect_onsets(wav, refractory=0.25, k=3.0):
    w = wave.open(wav, "rb"); sr = w.getframerate(); n = w.getnframes()
    x = np.frombuffer(w.readframes(n), np.int16).astype(np.float32) / 32768.0
    hp = np.diff(x, prepend=x[0])
    hop = 256; frames = len(hp) // hop
    env = (hp * hp)[:frames * hop].reshape(frames, hop).sum(axis=1)
    flux = np.diff(env, prepend=env[0]); flux[flux < 0] = 0
    win = int(2.0 * sr / hop); ker = np.ones(win) / win
    m = np.convolve(flux, ker, mode="same")
    sd = np.sqrt(np.maximum(np.convolve(flux * flux, ker, mode="same") - m * m, 0))
    thr = m + k * sd
    cand = np.where(flux > thr)[0]
    refr = int(refractory * sr / hop); out = []
    for i in cand:
        if out and i - out[-1] < refr:
            if flux[i] > flux[out[-1]]: out[-1] = i
            continue
        out.append(i)
    return np.array(out) * hop / sr

def analyze(a):
    p = work_paths(a.work)
    print("extracting audio...", flush=True)
    sh(["ffmpeg", "-y", "-v", "error", "-i", a.video, "-ac", "1", "-ar", "22050", "-vn", p["audio"]])
    print("detecting ball-strike onsets...", flush=True)
    onsets = detect_onsets(p["audio"]); np.save(p["onsets"], onsets)
    print(f"  {len(onsets)} onsets", flush=True)

    W, H, FPS, ROW0, BLK = 320, 180, a.fps, 28, a.fps * 30
    print("motion + player-bbox pass (single decode)...", flush=True)
    proc = subprocess.Popen(["ffmpeg", "-v", "error", "-i", a.video, "-vf",
        f"fps={FPS},scale={W}:{H}", "-pix_fmt", "gray", "-f", "rawvideo", "-"],
        stdout=subprocess.PIPE)
    sz = W * H; prev = None
    motion = []; present = []; xmin = []; xmax = []; buf = []
    def flush(block):
        F = np.stack(block); bg = np.median(F, axis=0)
        for f in F:
            fg = np.abs(f - bg) > 26; fg[:ROW0, :] = False
            if int(fg.sum()) >= 25:
                cols = fg.sum(axis=0)
                xs = np.where(cols >= 0.15 * cols.max())[0]
                if len(xs) == 0: xs = np.where(cols > 0)[0]
                present.append(1); xmin.append(int(xs.min())); xmax.append(int(xs.max()))
            else:
                present.append(0); xmin.append(-1); xmax.append(-1)
    while True:
        b = proc.stdout.read(sz)
        if len(b) < sz: break
        f = np.frombuffer(b, np.uint8).reshape(H, W).astype(np.float32)
        motion.append(0.0 if prev is None else float((np.abs(f[ROW0:] - prev[ROW0:]) > 18).sum()))
        prev = f; buf.append(f)
        if len(buf) == BLK: flush(buf); buf = []
    if buf: flush(buf)
    proc.stdout.close(); proc.wait()
    n = len(present)
    motion = np.array(motion[:n]); present = np.array(present)
    xmin = np.array(xmin); xmax = np.array(xmax); t6 = np.arange(n) / FPS
    np.savez(p["pass1"], t=t6, motion=motion, present=present, xmin=xmin, xmax=xmax, fps=FPS, W=W, H=H)

    # candidates: onset within a present window, deduped
    SX = 1280.0 / W
    def fi(tt): return int(round(tt * FPS))
    ons = []
    for x in onsets:
        if ons and x - ons[-1] < a.dedupe: continue
        ons.append(x)
    rows = []
    for tt in ons:
        i = fi(tt)
        if i < 0 or i >= n: continue
        lo, hi = max(0, i - 2), min(n, i + 3)
        if present[lo:hi].sum() == 0: continue
        xm = [xmin[j] for j in range(lo, hi) if present[j]]
        xM = [xmax[j] for j in range(lo, hi) if present[j]]
        bx0, bx1 = min(xm), max(xM)
        edge = 1 if (bx0 <= 1 or bx1 >= W - 2) else 0
        cx = int((bx0 + bx1) / 2 * SX)
        mot = int(motion[lo:hi].max())
        rows.append((round(float(tt), 2), cx, edge, mot))
    with open(p["cands"], "w", newline="") as f:
        wr = csv.writer(f); wr.writerow(["time", "cx", "edge", "mot"]); wr.writerows(rows)
    print(f"candidates: {len(rows)} (present-frac {present.mean():.2f}, {sum(r[2] for r in rows)} edge-risk)")
    print(f"wrote {p['cands']}")

# ---------- sheets ----------
def build_cache(video, cache_dir, fps):
    os.makedirs(cache_dir, exist_ok=True)
    done = os.path.join(cache_dir, ".done")
    if os.path.exists(done): return
    print(f"decoding frame cache @ {fps}fps (one pass)...", flush=True)
    sh(["ffmpeg", "-y", "-v", "error", "-i", video, "-vf", f"fps={fps}",
        "-q:v", "3", os.path.join(cache_dir, "f_%06d.jpg")])
    open(done, "w").write(str(fps))

def sheets(a):
    from PIL import Image, ImageDraw, ImageFont
    p = work_paths(a.work)
    build_cache(a.video, p["cache"], a.cache_fps)
    try: FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
    except Exception: FONT = ImageFont.load_default()
    CW, CHH, CY, Hh = 560, 560, 150, a.height
    offs = [float(x) for x in a.offsets.split(",")]
    rows = list(csv.DictReader(open(p["cands"])))
    def cache_frame(tt):
        idx = int(round(tt * a.cache_fps)) + 1
        return os.path.join(p["cache"], f"f_{idx:06d}.jpg")
    os.makedirs(p["sheets"], exist_ok=True)
    manifest = []; batch = []; sidx = [0]
    def strip(i, r):
        cx = int(r["cx"]); x = max(0, min(1280 - CW, int(cx - CW / 2)))
        ims = []
        for dt in offs:
            fp = cache_frame(max(0, float(r["time"]) + dt))
            if not os.path.exists(fp): continue
            im = Image.open(fp).convert("RGB").crop((x, CY, x + CW, CY + CHH))
            im = im.resize((int(CW * Hh / CHH), Hh))
            ims.append(im)
        if not ims: return None
        w = sum(im.width for im in ims) + (len(ims) - 1) * 2
        s = Image.new("RGB", (w, Hh + 20), (15, 15, 15)); xo = 0
        for im in ims: s.paste(im, (xo, 20)); xo += im.width + 2
        dr = ImageDraw.Draw(s); edge = r["edge"] == "1"
        dr.rectangle([0, 0, w, 18], fill=(150, 20, 20) if edge else (20, 90, 20))
        dr.text((3, 2), f"#{i}  t={float(r['time']):.1f}s" + ("  EDGE-RISK" if edge else ""),
                fill=(255, 255, 255), font=FONT)
        return s
    def flush():
        if not batch: return
        Wd = max(s.width for _, _, s in batch); rh = batch[0][2].height
        sheet = Image.new("RGB", (Wd, len(batch) * (rh + 4) + 4), (0, 0, 0)); y = 4; cells = []
        for i, tt, s in batch:
            sheet.paste(s, (0, y)); y += rh + 4; cells.append({"idx": i, "t": tt})
        fn = f"sheet_{sidx[0]:03d}.jpg"; sheet.save(os.path.join(p["sheets"], fn), quality=88)
        manifest.append({"sheet": fn, "cells": cells}); sidx[0] += 1; batch.clear()
    for i, r in enumerate(rows):
        s = strip(i, r)
        if s is None: continue
        batch.append((i, float(r["time"]), s))
        if len(batch) == a.per: flush()
    flush()
    json.dump(manifest, open(p["manifest"], "w"))
    print(f"{sidx[0]} sheets in {p['sheets']}  (manifest {p['manifest']})")

# ---------- assemble ----------
def assemble(a):
    p = work_paths(a.work)
    os.makedirs(p["clips"], exist_ok=True)
    times = []
    for line in open(a.keep):
        line = line.strip()
        if not line or line.startswith("#"): continue
        times.append(float(line.split(",")[0]))
    times = sorted(set(round(t, 2) for t in times))
    setpts = 1.0 / a.speed
    # Fluid slow-mo: setpts stretches time, then minterpolate synthesizes real
    # in-between frames (motion-compensated) so it doesn't stutter. Plain setpts
    # alone just holds each source frame and looks choppy.
    vf = f"setpts=PTS*{setpts:.4f}"
    if a.interp == "mci":
        vf += f",minterpolate=fps={a.fps}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1"
    elif a.interp == "blend":
        vf += f",minterpolate=fps={a.fps}:mi_mode=blend"
    def cut(i_t):
        i, t = i_t
        out = os.path.join(p["clips"], f"clip_{i:03d}.mp4")
        ss = max(0, t - a.pre); dur = a.pre + a.post
        # -ss and -t are INPUT options: seek + limit read to the window BEFORE setpts
        # stretches it, otherwise -t would truncate the slowed output back to `dur`.
        sh(["ffmpeg", "-y", "-v", "error", "-ss", f"{ss:.3f}", "-t", f"{dur:.3f}", "-i", a.video,
            "-vf", vf, "-r", str(a.fps), "-an", "-c:v", "libx264", "-preset", a.preset,
            "-crf", str(a.crf), out])
        return out
    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        clips = list(ex.map(cut, list(enumerate(times))))
    lst = os.path.join(p["clips"], "list.txt")
    with open(lst, "w") as f:
        for c in clips:
            if os.path.exists(c): f.write(f"file '{os.path.abspath(c)}'\n")
    sh(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", a.out])
    print(f"{len(times)} clips -> {a.out}  (speed {a.speed}x, window -{a.pre}/+{a.post}s)")

def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("analyze"); g.add_argument("video"); g.add_argument("--work", required=True)
    g.add_argument("--fps", type=int, default=6); g.add_argument("--dedupe", type=float, default=0.7)
    g.set_defaults(fn=analyze)
    g = sub.add_parser("sheets"); g.add_argument("video"); g.add_argument("--work", required=True)
    g.add_argument("--cache-fps", type=int, default=10); g.add_argument("--per", type=int, default=8)
    g.add_argument("--height", type=int, default=200); g.add_argument("--offsets", default="-0.30,-0.15,0,0.15,0.30,0.45")
    g.set_defaults(fn=sheets)
    g = sub.add_parser("assemble"); g.add_argument("video"); g.add_argument("--work", required=True)
    g.add_argument("--keep", required=True); g.add_argument("--out", required=True)
    g.add_argument("--pre", type=float, default=0.7); g.add_argument("--post", type=float, default=0.9)
    g.add_argument("--speed", type=float, default=0.25); g.add_argument("--crf", type=int, default=18)
    g.add_argument("--preset", default="medium"); g.add_argument("--jobs", type=int, default=8)
    g.add_argument("--fps", type=int, default=60, help="output fps for fluid slow-mo")
    g.add_argument("--interp", choices=["mci", "blend", "none"], default="mci",
                   help="mci=motion-compensated (fluid), blend=cheaper crossfade, none=choppy hold")
    g.set_defaults(fn=assemble)
    a = ap.parse_args(); a.fn(a)

if __name__ == "__main__":
    main()
