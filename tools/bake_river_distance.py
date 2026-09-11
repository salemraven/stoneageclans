#!/usr/bin/env python3
"""Bake uint8 2048 river distance field from water_layer.png."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt

ROOT = Path(__file__).resolve().parent.parent
WATER = ROOT / "maps/island/water_layer.png"
OUT = ROOT / "maps/island/river_distance.png"
LOG = ROOT / "Tests/logs/river_distance.jsonl"


def main() -> int:
    water = np.array(Image.open(WATER).convert("L")) > 128
    dist = distance_transform_edt(~water)
    cap = 32.0
    q = np.clip(dist / cap * 255.0, 0, 255).astype(np.uint8)
    Image.fromarray(q, mode="L").save(OUT)
    on_w = dist[water]
    on_l = dist[~water]
    rec = {
        "t": "river_distance",
        "size": [int(q.shape[1]), int(q.shape[0])],
        "water_mean_dist": float(on_w.mean()) if on_w.size else 0.0,
        "land_mean_dist": float(on_l.mean()) if on_l.size else 0.0,
        "land_max_dist": float(on_l.max()) if on_l.size else 0.0,
        "water_max_dist": float(on_w.max()) if on_w.size else 0.0,
    }
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec) + "\n")
    print(json.dumps(rec, indent=2))
    if on_w.size and on_w.max() > 0.5:
        print("FAIL water pixels not at distance 0")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
