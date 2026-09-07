#!/usr/bin/env python3
"""Render biome_mask + water_layer to a colour PNG for quick visual review.

  python3 tools/render_biome_preview.py                      # maps/island/preview_biomes.png
  python3 tools/render_biome_preview.py --crop 60,200,600,560 --scale 2 --out /tmp/nw.png
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image

from clean_biome_mask_specks import ids_from_mask, load_water

PALETTE = {
    0: (30, 70, 140),  # ocean
    1: (120, 160, 70),  # savanna
    2: (220, 200, 120),  # desert
    3: (30, 110, 40),  # jungle
    4: (90, 70, 40),  # swamp
    5: (240, 245, 255),  # glacier
    6: (50, 120, 50),  # forest
    8: (235, 220, 170),  # beach
}
RIVER = (60, 130, 220)


def render(mask_path: Path, water_path: Path) -> np.ndarray:
    ids = ids_from_mask(np.array(Image.open(mask_path)))
    is_water = load_water(water_path, ids.shape)
    rgb = np.zeros(ids.shape + (3,), dtype=np.uint8)
    for biome_id, colour in PALETTE.items():
        rgb[ids == biome_id] = colour
    rgb[is_water] = RIVER
    return rgb


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mask", default="maps/island/biome_mask.png")
    parser.add_argument("--water", default="maps/island/water_layer.png")
    parser.add_argument("--out", default="maps/island/preview_biomes.png")
    parser.add_argument("--crop", default=None, help="x0,y0,x1,y1 in mask pixels")
    parser.add_argument("--scale", type=int, default=1)
    args = parser.parse_args()

    rgb = render(Path(args.mask), Path(args.water))
    if args.crop:
        x0, y0, x1, y1 = (int(v) for v in args.crop.split(","))
        rgb = rgb[y0:y1, x0:x1]
    img = Image.fromarray(rgb)
    if args.scale > 1:
        img = img.resize((img.width * args.scale, img.height * args.scale), Image.NEAREST)
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    img.save(args.out)
    print(f"wrote {args.out} ({img.width}x{img.height})")


if __name__ == "__main__":
    main()
