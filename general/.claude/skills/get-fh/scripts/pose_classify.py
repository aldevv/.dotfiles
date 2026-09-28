"""v2 forehand finder: YOLO11-pose classifies each audio-onset candidate as
forehand / backhand / other using wrist-shoulder geometry, and enforces full
view (all keypoints inside the frame) directly from keypoints.

Reuses candidates.csv (audio-onset shot times) and the 10fps frame cache from v1.
Right-handed player assumed (dominant = right wrist, kp 10).
"""
import csv, os, sys, json
import numpy as np
from ultralytics import YOLO

WORK = sys.argv[1] if len(sys.argv) > 1 else "/tmp/fhwork_full"
CACHE = os.path.join(WORK, "cache"); FPS = 10
OFFS = [-0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3, 0.4]
# COCO kpts
NOSE, LSH, RSH, LEL, REL, LWR, RWR, LHIP, RHIP, LAN, RAN = 0, 5, 6, 7, 8, 9, 10, 11, 12, 15, 16
MARGIN = 45          # px from frame edge required for "in view"
WRIST_MARGIN = 60    # dominant wrist needs more room (racket extends beyond it)

def cache_frame(t):
    idx = int(round(t * FPS)) + 1
    return os.path.join(CACHE, f"f_{idx:06d}.jpg")

rows = list(csv.DictReader(open(os.path.join(WORK, "candidates.csv"))))
# unique frames to infer
need = {}
for i, r in enumerate(rows):
    for dt in OFFS:
        fp = cache_frame(max(0, float(r["time"]) + dt))
        need[fp] = None
paths = [p for p in need if os.path.exists(p)]
print(f"candidates {len(rows)}, unique frames {len(paths)}", flush=True)

model = YOLO("yolo11n-pose.pt")
BATCH = 64
for s in range(0, len(paths), BATCH):
    chunk = paths[s:s + BATCH]
    res = model.predict(chunk, imgsz=960, conf=0.35, verbose=False)
    for p, rr in zip(chunk, res):
        kps = rr.keypoints.data.cpu().numpy() if rr.keypoints is not None else np.zeros((0, 17, 3))
        boxes = rr.boxes.xyxy.cpu().numpy() if rr.boxes is not None else np.zeros((0, 4))
        need[p] = (kps, boxes)
    if s % (BATCH * 8) == 0: print(f"  infer {s+len(chunk)}/{len(paths)}", flush=True)

def pick_player(pack, cx):
    if pack is None: return None
    kps, boxes = pack
    best = None; bd = 1e9
    for k, b in zip(kps, boxes):
        h = b[3] - b[1]
        if h < 150: continue          # too small to be the player
        bcx = (b[0] + b[2]) / 2
        d = abs(bcx - cx)
        if d < bd: bd = d; best = k
    return best

def inview(k):
    for j in (NOSE, LSH, RSH, LAN, RAN, LWR, RWR):
        if k[j, 2] < 0.3: return False
        x, y = k[j, 0], k[j, 1]
        m = WRIST_MARGIN if j in (LWR, RWR) else MARGIN
        if x < m or x > 1280 - m or y < MARGIN or y > 720 - MARGIN: return False
    return True

out = []
for i, r in enumerate(rows):
    t = float(r["time"]); cx = float(r["cx"])
    series = []
    for dt in OFFS:
        pack = need.get(cache_frame(max(0, t + dt)))
        series.append(pick_player(pack, cx))
    valid = [(dt, k) for dt, k in zip(OFFS, series) if k is not None]
    if len(valid) < 4:
        out.append({"i": i, "t": t, "label": "no-pose", "conf": 0}); continue
    # right-wrist speed -> contact frame
    pts = {dt: k for dt, k in valid}
    dts = sorted(pts)
    rw = np.array([pts[dt][RWR, :2] for dt in dts])
    speed = np.r_[0, np.linalg.norm(np.diff(rw, axis=0), axis=1)]
    ci = int(speed.argmax()); cdt = dts[ci]; kc = pts[cdt]
    shoulder_w = abs(kc[RSH, 0] - kc[LSH, 0]) + 1e-6
    wrist_sep = np.linalg.norm(kc[RWR, :2] - kc[LWR, :2]) / shoulder_w
    mid_sh_x = (kc[RSH, 0] + kc[LSH, 0]) / 2
    side = (kc[RWR, 0] - mid_sh_x) / shoulder_w        # >0 right wrist screen-right of body
    rise = (pts[dts[0]][RWR, 1] - kc[RWR, 1]) / shoulder_w  # + if wrist rose from first frame to contact
    fullview = all(inview(k) for _, k in valid[max(0, ci-1):ci+2]) and inview(kc)
    # right-handed forehand: hands apart (one-handed) and wrist works the right side,
    # decent swing speed. Two-handed backhand: wrist_sep small.
    swing = speed.max() > 0.25 * shoulder_w
    is_fh = swing and wrist_sep > 1.1 and side > -0.2
    conf = int(max(0, min(100, 55 + 18*(wrist_sep-1.1) + 12*side + 8*rise)))
    label = "forehand" if is_fh else ("backhand-2h" if wrist_sep < 0.8 else "other")
    out.append({"i": i, "t": round(t,2), "label": label, "conf": conf,
                "wrist_sep": round(float(wrist_sep),2), "side": round(float(side),2),
                "rise": round(float(rise),2), "fullview": bool(fullview),
                "speed": round(float(speed.max()/shoulder_w),2)})

json.dump(out, open(os.path.join(WORK, "v2_pose.json"), "w"))
fh = [o for o in out if o.get("label") == "forehand" and o.get("fullview")]
fh.sort(key=lambda o: -o["conf"])
with open(os.path.join(WORK, "v2_keep.txt"), "w") as f:
    for o in sorted(fh, key=lambda o: o["t"]): f.write(f"{o['t']}\n")
from collections import Counter
print("labels:", Counter(o["label"] for o in out))
print(f"forehand+fullview: {len(fh)}")
print("wrote v2_keep.txt")
