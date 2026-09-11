#!/usr/bin/env python3
"""Log island mask + water stats as JSONL. Exit 1 if desert-on-river or size mismatch."""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from clean_biome_mask_specks import (  # noqa: E402
    DESERT,
    OCEAN,
    ids_from_mask,
    load_water,
)

NAMES = {
    0: "ocean",
    1: "savanna",
    2: "desert",
    3: "jungle",
    4: "swamp",
    5: "glacier",
    6: "forest",
    8: "beach",
}


def main() -> int:
    mask_path = ROOT / "maps/island/biome_mask.png"
    water_path = ROOT / "maps/island/water_layer.png"
    meta_path = ROOT / "maps/island/island_meta.json"
    log_dir = ROOT / "Tests/logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / "map_build.jsonl"

    img = Image.open(mask_path)
    ids = ids_from_mask(np.array(img))
    h, w = ids.shape
    is_water = load_water(water_path, ids.shape)
    land = (ids != OCEAN) & ~is_water
    land_n = int(land.sum()) or 1
    pct: dict[str, float] = {}
    for bid, name in NAMES.items():
        n = int(((ids == bid) & land).sum()) if bid != 0 else int((ids == OCEAN).sum())
        pct[name] = round(100.0 * n / ids.size if bid == 0 else 100.0 * n / land_n, 3)
    desert_on_river = int(((ids == DESERT) & is_water).sum())
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    water_img = Image.open(water_path)
    ww, wh = water_img.size
    from scipy.ndimage import binary_dilation

    ocean = ids == OCEAN
    near_ocean = binary_dilation(ocean, iterations=1) & is_water & ~ocean
    rivers_reach_ocean = bool(near_ocean.any())
    rec = {
        "t": "map_build",
        "ts": datetime.now(timezone.utc).isoformat(),
        "mask_w": w,
        "mask_h": h,
        "water_w": ww,
        "water_h": wh,
        "water_pixels": int(is_water.sum()),
        "desert_on_river": desert_on_river,
        "rivers_reach_ocean": rivers_reach_ocean,
        "sample_stride_px": meta.get("sample_stride_px"),
        "world_seed": meta.get("world_seed"),
        "land_pct": pct,
    }
    with log_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec) + "\n")
    print(json.dumps(rec, indent=2))
    expect = int(meta.get("mask_size", w))
    ok = desert_on_river == 0 and w == h == ww == wh == expect
    print("OK" if ok else "FAIL", f"desert_on_river={desert_on_river}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
