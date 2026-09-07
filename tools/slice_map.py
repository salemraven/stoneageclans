#!/usr/bin/env python3
"""Slice an authored island PNG into 2048px chunk tiles + biome mask.

Usage:
  python3 tools/slice_map.py --input path/to/island.png --output maps/island \\
      --chunk-size 2048 --sample-stride 32

Outputs:
  maps/island/chunks/tile_<cx>_<cy>.png
  maps/island/biome_mask.png
  maps/island/island_meta.json
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageFilter
except ImportError:
    print("ERROR: Pillow required — pip install pillow", file=sys.stderr)
    sys.exit(1)

# Match scripts/world/biome_palette.gd legend (RGB).
LEGEND: list[tuple[tuple[int, int, int], int]] = [
    ((0x00, 0x66, 0xCC), 0),   # OCEAN
    ((0xC8, 0xD8, 0x78), 1),   # SAVANNA
    ((0xE8, 0xD9, 0xA0), 2),   # DESERT
    ((0x1A, 0x5C, 0x2E), 3),   # JUNGLE
    ((0x4A, 0x37, 0x28), 4),   # SWAMP
    ((0xEE, 0xF4, 0xFF), 5),   # GLACIER
    ((0x2D, 0x5A, 0x2D), 6),   # FOREST_PATCH
    ((0x44, 0x99, 0xDD), 7),   # RIVER
    ((0xF5, 0xE6, 0xC8), 8),   # BEACH
]

BIOME_INDEX_TO_RGB = {idx: rgb for rgb, idx in LEGEND}


def nearest_legend_rgb(r: int, g: int, b: int) -> tuple[int, int, int]:
    best = LEGEND[0][0]
    best_dist = float("inf")
    for rgb, _ in LEGEND:
        dr, dg, db = r - rgb[0], g - rgb[1], b - rgb[2]
        dist = dr * dr + dg * dg + db * db
        if dist < best_dist:
            best_dist = dist
            best = rgb
    return best


def rgb_to_legend_color(r: int, g: int, b: int) -> tuple[int, int, int]:
    return nearest_legend_rgb(r, g, b)


def pad_to_chunk_grid(img: Image.Image, chunk_size: int) -> Image.Image:
    w, h = img.size
    gw = int(math.ceil(w / chunk_size) * chunk_size)
    gh = int(math.ceil(h / chunk_size) * chunk_size)
    if (gw, gh) == (w, h):
        return img
    ocean = BIOME_INDEX_TO_RGB[0]
    padded = Image.new("RGB", (gw, gh), ocean)
    padded.paste(img, (0, 0))
    return padded


def build_biome_mask(img: Image.Image, sample_stride: int) -> Image.Image:
    w, h = img.size
    mw = max(1, int(math.ceil(w / sample_stride)))
    mh = max(1, int(math.ceil(h / sample_stride)))
    mask = Image.new("RGB", (mw, mh))
    px = img.load()
    mx = mask.load()
    for my in range(mh):
        sy = min(h - 1, my * sample_stride + sample_stride // 2)
        for mx_i in range(mw):
            sx = min(w - 1, mx_i * sample_stride + sample_stride // 2)
            r, g, b = px[sx, sy][:3]
            mx[mx_i, my] = rgb_to_legend_color(r, g, b)
    return mask


def slice_chunks(img: Image.Image, chunk_size: int, out_dir: Path) -> tuple[int, int]:
    out_dir.mkdir(parents=True, exist_ok=True)
    w, h = img.size
    cx_count = w // chunk_size
    cy_count = h // chunk_size
    for cy in range(cy_count):
        for cx in range(cx_count):
            box = (cx * chunk_size, cy * chunk_size, (cx + 1) * chunk_size, (cy + 1) * chunk_size)
            tile = img.crop(box)
            tile.save(out_dir / f"tile_{cx}_{cy}.png", optimize=True)
    return cx_count, cy_count


def write_meta(out_root: Path, world_w: int, world_h: int, cx_count: int, cy_count: int, sample_stride: int, source: str) -> None:
    meta = {
        "world_width_px": world_w,
        "world_height_px": world_h,
        "chunk_size_px": 2048,
        "chunk_count_x": cx_count,
        "chunk_count_y": cy_count,
        "sample_stride_px": sample_stride,
        "source_image": source,
        "display": "continuous_texture_slices",
        "note": "Chunks are load-only; ground art uses soft blends. Biome mask snaps for gameplay.",
    }
    (out_root / "island_meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Slice island map into Godot chunk tiles + biome mask.")
    parser.add_argument("--input", required=True, help="Source island PNG/JPEG")
    parser.add_argument("--output", default="maps/island", help="Output directory (repo-relative)")
    parser.add_argument("--chunk-size", type=int, default=2048)
    parser.add_argument("--sample-stride", type=int, default=32)
    parser.add_argument("--blur-radius", type=float, default=0.0, help="Optional soft blur on display map (px)")
    parser.add_argument("--pad-ocean", action="store_true", help="Pad image to full chunk grid with ocean")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    input_path = Path(args.input)
    if not input_path.is_absolute():
        input_path = repo_root / input_path
    out_root = Path(args.output)
    if not out_root.is_absolute():
        out_root = repo_root / out_root

    if not input_path.exists():
        print(f"ERROR: input not found: {input_path}", file=sys.stderr)
        return 1

    img = Image.open(input_path).convert("RGB")
    if args.blur_radius > 0:
        img = img.filter(ImageFilter.GaussianBlur(radius=args.blur_radius))

    if args.pad_ocean:
        img = pad_to_chunk_grid(img, args.chunk_size)

    chunks_dir = out_root / "chunks"
    cx_count, cy_count = slice_chunks(img, args.chunk_size, chunks_dir)
    mask = build_biome_mask(img, args.sample_stride)
    out_root.mkdir(parents=True, exist_ok=True)
    mask.save(out_root / "biome_mask.png", optimize=True)
    write_meta(out_root, img.width, img.height, cx_count, cy_count, args.sample_stride, str(input_path.name))

    print(f"OK: {img.width}x{img.height} -> {cx_count}x{cy_count} chunks, mask {mask.size[0]}x{mask.size[1]}")
    print(f"Output: {out_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
