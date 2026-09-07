#!/usr/bin/env python3
"""Build dev placeholder island from bible/assets/island_map2.jpg.

Maps reference colors to flat legend colors, upscales, optionally softens edges,
then runs slice_map to produce maps/island/ for pipeline testing.

Usage (repo root):
  python3 tools/build_placeholder_island.py
  python3 tools/build_placeholder_island.py --world-size 4096
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageFilter
except ImportError:
    print("ERROR: Pillow required — pip install pillow", file=sys.stderr)
    sys.exit(1)

# Import legend helpers from slice_map (same directory).
sys.path.insert(0, str(Path(__file__).resolve().parent))
from slice_map import (  # noqa: E402
    BIOME_INDEX_TO_RGB,
    build_biome_mask,
    pad_to_chunk_grid,
    slice_chunks,
    write_meta,
    rgb_to_legend_color,
)

DEFAULT_SOURCE = Path("bible/assets/island_map2.jpg")
CHUNK_SIZE = 2048
SAMPLE_STRIDE = 32


def color_map_reference(img: Image.Image) -> Image.Image:
    """Snap each pixel to nearest legend biome color (mask source)."""
    w, h = img.size
    out = Image.new("RGB", (w, h))
    src = img.load()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = src[x, y][:3]
            dst[x, y] = rgb_to_legend_color(r, g, b)
    return out


def soften_display(mapped: Image.Image, radius: float = 1.25) -> Image.Image:
    """Light blur so biome edges are not blocky on the display layer."""
    if radius <= 0:
        return mapped
    return mapped.filter(ImageFilter.GaussianBlur(radius=radius))


def upscale_to_world(img: Image.Image, world_size: int) -> Image.Image:
    """Fit reference aspect into square world canvas padded with ocean."""
    ocean = BIOME_INDEX_TO_RGB[0]
    canvas = Image.new("RGB", (world_size, world_size), ocean)
    ref_w, ref_h = img.size
    scale = min(world_size / ref_w, world_size / ref_h)
    new_w = max(1, int(ref_w * scale))
    new_h = max(1, int(ref_h * scale))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    ox = (world_size - new_w) // 2
    oy = (world_size - new_h) // 2
    canvas.paste(resized, (ox, oy))
    return canvas


def main() -> int:
    parser = argparse.ArgumentParser(description="Build placeholder island from map2 reference.")
    parser.add_argument("--source", default=str(DEFAULT_SOURCE))
    parser.add_argument("--output", default="maps/island")
    parser.add_argument("--world-size", type=int, default=4096, help="Square dev world (must be multiple of 2048)")
    parser.add_argument("--blur", type=float, default=1.25, help="Display softening blur radius")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    source = Path(args.source)
    if not source.is_absolute():
        source = repo_root / source
    out_root = Path(args.output)
    if not out_root.is_absolute():
        out_root = repo_root / out_root

    if not source.exists():
        print(f"ERROR: source not found: {source}", file=sys.stderr)
        return 1

    world_size = args.world_size
    if world_size % CHUNK_SIZE != 0:
        world_size = int(math.ceil(world_size / CHUNK_SIZE) * CHUNK_SIZE)
        print(f"Adjusted world-size to {world_size} (chunk aligned)")

    ref = Image.open(source).convert("RGB")
    mapped = color_map_reference(ref)
    world_mapped = upscale_to_world(mapped, world_size)
    display = soften_display(world_mapped, args.blur)

    chunks_dir = out_root / "chunks"
    cx_count, cy_count = slice_chunks(display, CHUNK_SIZE, chunks_dir)
    mask = build_biome_mask(world_mapped, SAMPLE_STRIDE)
    out_root.mkdir(parents=True, exist_ok=True)
    mask.save(out_root / "biome_mask.png", optimize=True)
    write_meta(
        out_root,
        display.width,
        display.height,
        cx_count,
        cy_count,
        SAMPLE_STRIDE,
        f"placeholder from {source.name}",
    )

    print(f"Placeholder island: {display.width}x{display.height}, chunks={cx_count}x{cy_count}")
    print(f"Mask: {mask.size[0]}x{mask.size[1]} @ stride {SAMPLE_STRIDE}px")
    print(f"Output: {out_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
