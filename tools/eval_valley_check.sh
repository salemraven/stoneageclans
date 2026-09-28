#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export SKIP_SINGLE_INSTANCE=1
OUT="/tmp/eval_valley_means.txt"
: > "$OUT"

for i in 1 2 3; do
  echo "== valley run $i/3 =="
  "$GODOT" --path . --eval-ai-arena --godmode --lag-profile \
    --session-quit-after 300 > "/tmp/eval_valley_$i.log" 2>&1 || true
  python3 - <<'PY'
import json, os, glob
home = os.path.expanduser("~/Library/Application Support/Godot/app_userdata/StoneAgeClans")
files = sorted(glob.glob(os.path.join(home, "lag_profile_*.jsonl")))
if not files:
    raise SystemExit("no lag profile")
path = files[-1]
rows = []
for line in open(path):
    if '"interval"' not in line:
        continue
    o = json.loads(line)
    if o.get("t", 0) >= 180:
        rows.append(o)
if len(rows) < 30:
    print("VALLEY_RUN short n=%d file=%s" % (len(rows), path))
    raise SystemExit(1)
avg = sum(r["frame_ms_avg"] for r in rows) / len(rows)
mn = min(r["frames"] for r in rows)
mx = max(r["frames"] for r in rows)
st = sum(float(r.get("physics_steps_per_frame", 0)) for r in rows) / len(rows)
print("VALLEY_RUN frame_ms=%.2f min_fps=%d max_fps=%d steps/frame=%.2f n=%d" % (avg, mn, mx, st, len(rows)))
open("/tmp/eval_valley_means.txt", "a").write("%.4f %.4f %d %d\n" % (avg, st, mn, mx))
PY
done

python3 - <<'PY'
rows = [tuple(map(float, line.split())) for line in open("/tmp/eval_valley_means.txt")]
means = [r[0] for r in rows]
steps = [r[1] for r in rows]
mins = [int(r[2]) for r in rows]
means_s = sorted(means)
median = means_s[len(means_s)//2]
step_med = sorted(steps)[len(steps)//2]
print("=== VALLEY CHECK ===")
print("frame_ms runs: %s  median=%.2f" % (means, median))
print("steps/frame: %s  median=%.2f" % (steps, step_med))
print("min fps across runs: %d" % min(mins))
ok = median < 16.7 and step_med < 2.0
print("G1 %s" % ("PASS" if ok else "FAIL"))
raise SystemExit(0 if ok else 1)
PY
