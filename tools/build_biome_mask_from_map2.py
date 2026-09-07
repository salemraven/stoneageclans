#!/usr/bin/env python3
"""Extract a high-quality biome mask from map2.jpg with rivers, glacier, etc.

Maps the reference image colors to biome IDs encoded in the red channel.
Output is a single-channel image where R = biome_id / 9.0

Usage (repo root):
  python3 tools/build_biome_mask_from_map2.py
  python3 tools/build_biome_mask_from_map2.py --output-size 2048
  python3 tools/build_biome_mask_from_map2.py --grass-only --output-size 2048
  python3 tools/build_biome_mask_from_map2.py --phase rivers --output-size 2048
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

try:
    from PIL import Image, ImageFilter
    import numpy as np
except ImportError:
    print("ERROR: Pillow and numpy required — pip install pillow numpy")
    raise SystemExit(1)

# Biome IDs (must match biome_palette.gd and shader)
BIOME_OCEAN = 0
BIOME_SAVANNA = 1
BIOME_DESERT = 2
BIOME_JUNGLE = 3
BIOME_SWAMP = 4
BIOME_GLACIER = 5
BIOME_FOREST = 6
BIOME_RIVER = 7
BIOME_BEACH = 8

# Reference colors from map2.jpg (sampled from actual image)
COLOR_MAP = [
    # (R, G, B), biome_id, tolerance
    # Ocean - blue
    ((46, 111, 165), BIOME_OCEAN, 50),
    ((30, 90, 150), BIOME_OCEAN, 45),
    # River - lighter blue
    ((100, 150, 200), BIOME_RIVER, 40),
    ((120, 160, 190), BIOME_RIVER, 35),
    ((150, 180, 210), BIOME_RIVER, 35),
    # Glacier - white/pale
    ((234, 245, 249), BIOME_GLACIER, 25),
    ((220, 235, 245), BIOME_GLACIER, 30),
    ((200, 215, 230), BIOME_GLACIER, 35),
    ((180, 195, 210), BIOME_GLACIER, 35),
    # Desert - tan/khaki
    ((226, 195, 131), BIOME_DESERT, 45),
    ((210, 185, 125), BIOME_DESERT, 40),
    ((200, 180, 130), BIOME_DESERT, 40),
    ((190, 175, 120), BIOME_DESERT, 40),
    # Jungle - dark green
    ((48, 97, 32), BIOME_JUNGLE, 45),
    ((55, 105, 40), BIOME_JUNGLE, 40),
    ((45, 85, 35), BIOME_JUNGLE, 40),
    ((60, 90, 45), BIOME_JUNGLE, 40),
    # Swamp - brown/muddy
    ((95, 80, 55), BIOME_SWAMP, 40),
    ((85, 70, 45), BIOME_SWAMP, 40),
    ((110, 90, 60), BIOME_SWAMP, 40),
    # Forest - medium green (darker than savanna)
    ((70, 95, 55), BIOME_FOREST, 35),
    ((80, 100, 60), BIOME_FOREST, 35),
    ((65, 85, 50), BIOME_FOREST, 35),
    # Savanna - olive/tan/muted green (the most common land type)
    ((160, 163, 84), BIOME_SAVANNA, 50),
    ((150, 155, 85), BIOME_SAVANNA, 50),
    ((140, 145, 80), BIOME_SAVANNA, 50),
    ((170, 170, 95), BIOME_SAVANNA, 50),
    ((180, 175, 100), BIOME_SAVANNA, 50),
    ((196, 177, 111), BIOME_SAVANNA, 50),
    ((185, 170, 105), BIOME_SAVANNA, 50),
    ((175, 165, 95), BIOME_SAVANNA, 50),
    ((122, 110, 68), BIOME_SAVANNA, 45),
    ((130, 120, 75), BIOME_SAVANNA, 45),
    ((145, 135, 85), BIOME_SAVANNA, 45),
    ((78, 79, 35), BIOME_SAVANNA, 40),  # darker olive
    ((90, 90, 45), BIOME_SAVANNA, 45),
    ((105, 100, 55), BIOME_SAVANNA, 45),
    # Beach - pale tan
    ((240, 230, 200), BIOME_BEACH, 30),
    ((235, 225, 195), BIOME_BEACH, 30),
    ((230, 220, 190), BIOME_BEACH, 30),
]


def color_distance(c1, c2):
    """Euclidean distance in RGB space."""
    return math.sqrt(sum((a - b) ** 2 for a, b in zip(c1, c2)))


def is_ocean_pixel(r: int, g: int, b: int) -> bool:
    """True for surrounding sea water (not land, rivers, or beach)."""
    if classify_pixel(r, g, b) == BIOME_RIVER:
        return False
    if b > r + 25 and b > g + 15 and b > 90 and r < 80:
        return True
    for ref_color, biome_id, tolerance in COLOR_MAP:
        if biome_id != BIOME_OCEAN:
            continue
        if color_distance((r, g, b), ref_color) < tolerance:
            return True
    return False


def is_river_pixel(r: int, g: int, b: int) -> bool:
    """Light blue stream lines from map2 (not open ocean)."""
    if classify_pixel(r, g, b) == BIOME_RIVER:
        return True
    if is_ocean_pixel(r, g, b):
        return False
    for ref_color, biome_id, tolerance in COLOR_MAP:
        if biome_id != BIOME_RIVER:
            continue
        if color_distance((r, g, b), ref_color) < tolerance + 8:
            return True
    # Pale/cyan blue streaks on land
    if b > 118 and b > r + 8 and g > 98 and 65 <= r <= 185:
        return True
    return False


def classify_pixel(r, g, b):
    """Find best matching biome for a pixel color."""
    best_biome = BIOME_SAVANNA
    best_dist = float('inf')
    
    for ref_color, biome_id, tolerance in COLOR_MAP:
        dist = color_distance((r, g, b), ref_color)
        if dist < tolerance and dist < best_dist:
            best_dist = dist
            best_biome = biome_id
    
    # Fallback heuristics if no close match
    if best_dist == float('inf'):
        # Very blue = ocean or river
        if b > r + 20 and b > g + 10 and b > 100:
            if b > 150 and r < 100:
                return BIOME_RIVER
            return BIOME_OCEAN
        # Very white/pale = glacier
        if r > 180 and g > 180 and b > 180 and min(r, g, b) > 160:
            return BIOME_GLACIER
        # Tan/yellow with high R = desert
        if r > 180 and r > g and g > b and r - b > 60:
            return BIOME_DESERT
        # Pale tan = beach
        if r > 200 and g > 190 and b > 150 and r > g > b:
            return BIOME_BEACH
        # Dark green with low R = jungle
        if g > r and g > b and r < 70 and g < 120:
            return BIOME_JUNGLE
        # Brown-ish = swamp
        if r > g and r > b and g < 100 and r < 130:
            return BIOME_SWAMP
        # Medium-dark green = forest
        if g > r and g > b and g < 120 and r > 50:
            return BIOME_FOREST
        # Everything else with greenish/olive tint = savanna (default land)
        # This catches the olive, tan-green, and muted colors
    
    return best_biome


def classify_phase_pixel(r: int, g: int, b: int, phase: str) -> int:
    if phase == "grass":
        return BIOME_OCEAN if is_ocean_pixel(r, g, b) else BIOME_SAVANNA
    if phase == "rivers":
        if is_ocean_pixel(r, g, b):
            return BIOME_OCEAN
        return BIOME_SAVANNA
    return classify_pixel(r, g, b)


def erode_mask(mask: np.ndarray, radius: int) -> np.ndarray:
    """Chebyshev erosion."""
    if radius <= 0:
        return mask.copy()
    h, w = mask.shape
    src = mask.astype(bool)
    out = np.zeros_like(src)
    for y in range(h):
        y0 = max(0, y - radius)
        y1 = min(h, y + radius + 1)
        for x in range(w):
            x0 = max(0, x - radius)
            x1 = min(w, x + radius + 1)
            if src[y0:y1, x0:x1].all():
                out[y, x] = True
    return out


def morph_dilate_mask(mask: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return mask.copy()
    size = radius * 2 + 1
    img = Image.fromarray((mask.astype(np.uint8) * 255))
    img = img.filter(ImageFilter.MaxFilter(size))
    return np.array(img) > 127


def morph_close_mask(mask: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return mask.copy()
    size = radius * 2 + 1
    img = Image.fromarray((mask.astype(np.uint8) * 255))
    img = img.filter(ImageFilter.MaxFilter(size))
    img = img.filter(ImageFilter.MinFilter(size))
    return np.array(img) > 127


def remove_small_components(mask: np.ndarray, min_size: int) -> np.ndarray:
    """Drop tiny river specks that are not real streams."""
    if min_size <= 1:
        return mask.copy()
    h, w = mask.shape
    src = mask.astype(bool)
    keep = np.zeros_like(src)
    seen = np.zeros_like(src, dtype=bool)
    for y in range(h):
        for x in range(w):
            if not src[y, x] or seen[y, x]:
                continue
            stack = [(x, y)]
            seen[y, x] = True
            component: list[tuple[int, int]] = []
            while stack:
                cx, cy = stack.pop()
                component.append((cx, cy))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and src[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            stack.append((nx, ny))
            if len(component) >= min_size:
                for cx, cy in component:
                    keep[cy, cx] = True
    return keep


def refine_river_mask(river: np.ndarray, land: np.ndarray, close_radius: int, min_component: int) -> np.ndarray:
    """Connect gaps and remove noise while staying on land."""
    refined = river & land
    if close_radius > 0:
        refined = morph_close_mask(refined, close_radius)
    refined &= land
    refined = remove_small_components(refined, min_component)
    # Bridge nearby stream segments that are only a few pixels apart.
    refined = morph_close_mask(morph_dilate_mask(refined, 3), 3)
    refined &= land
    refined = remove_small_components(refined, min_component)
    if close_radius > 1:
        refined = morph_close_mask(refined, max(1, close_radius - 1))
        refined &= land
    return remove_small_components(refined, min_component)


def build_source_river_mask(img: Image.Image, close_radius: int = 2) -> np.ndarray:
    """Detect rivers on the original map2 image, then connect small gaps."""
    src = np.array(img.convert("RGB"))
    h, w = src.shape[:2]
    river = np.zeros((h, w), dtype=bool)
    for y in range(h):
        for x in range(w):
            r, g, b = map(int, src[y, x])
            river[y, x] = is_river_pixel(r, g, b)
    if close_radius > 0:
        river = morph_close_mask(river, close_radius)
        river = morph_dilate_mask(river, 1)
        river = morph_close_mask(river, max(1, close_radius - 1))
    return river


def paste_resized_river_mask(
    river_src: np.ndarray,
    output_size: int,
    new_w: int,
    new_h: int,
    ox: int,
    oy: int,
    land_mask: np.ndarray,
    close_radius: int,
    min_component: int,
) -> np.ndarray:
    """Upscale rivers with nearest-neighbor, then close gaps on the output grid."""
    river_img = Image.fromarray((river_src.astype(np.uint8) * 255))
    river_up = np.array(river_img.resize((new_w, new_h), Image.Resampling.NEAREST)) > 0
    canvas = np.zeros((output_size, output_size), dtype=bool)
    canvas[oy : oy + new_h, ox : ox + new_w] = river_up
    return refine_river_mask(canvas, land_mask, close_radius, min_component)


def dilate_mask(mask: np.ndarray, radius: int) -> np.ndarray:
    """Chebyshev dilation."""
    if radius <= 0:
        return mask.copy()
    h, w = mask.shape
    src = mask.astype(bool)
    out = src.copy()
    for y in range(h):
        y0 = max(0, y - radius)
        y1 = min(h, y + radius + 1)
        for x in range(w):
            x0 = max(0, x - radius)
            x1 = min(w, x + radius + 1)
            if src[y0:y1, x0:x1].any():
                out[y, x] = True
    return out


def build_biome_mask(
    img: Image.Image,
    output_size: int,
    phase: str = "full",
) -> Image.Image:
    """Convert reference image to biome ID mask, preserving aspect ratio with ocean padding."""
    img = img.convert("RGB")
    
    # Create square canvas with ocean background
    ocean_gray = int(BIOME_OCEAN * 255 / 9.0)
    canvas = Image.new("RGB", (output_size, output_size), (30, 90, 180))  # Ocean blue
    
    # Fit reference into canvas preserving aspect ratio
    ref_w, ref_h = img.size
    scale = min(output_size / ref_w, output_size / ref_h)
    new_w = max(1, int(ref_w * scale))
    new_h = max(1, int(ref_h * scale))
    img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Center on canvas
    ox = (output_size - new_w) // 2
    oy = (output_size - new_h) // 2
    canvas.paste(img_resized, (ox, oy))
    
    # Convert to biome mask
    pixels = np.array(canvas)
    ids = np.zeros((output_size, output_size), dtype=np.uint8)

    for y in range(output_size):
        for x in range(output_size):
            r, g, b = pixels[y, x]
            ids[y, x] = classify_phase_pixel(int(r), int(g), int(b), phase)

    if phase == "rivers":
        return _build_biome_mask_rivers_tuned(img, output_size, max(3, output_size // 512))

    mask = np.rint(ids.astype(np.float32) / 9.0 * 255.0).astype(np.uint8)
    return Image.fromarray(mask)


def build_procedural_rivers(
    img: Image.Image,
    output_size: int,
    seed: int = 42,
    num_rivers: int = 5,
    tributaries: int = 2,
) -> tuple[Image.Image, dict]:
    """Build tile-grid glacier-spoke rivers — connected, game-map style."""
    import sys
    from pathlib import Path

    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))

    from generate_river_paths import (
        GRID_SIZE,
        TILE_SIZE,
        downsample_land_mask,
        generate_glacier_spoke_rivers,
        grids_to_biome_mask,
        upscale_mask,
    )
    from river_connectivity import analyze_river_connectivity

    # High-res land classification from map2 (guide for shape only)
    img = img.convert("RGB")
    canvas = Image.new("RGB", (output_size, output_size), (30, 90, 180))
    ref_w, ref_h = img.size
    scale = min(output_size / ref_w, output_size / ref_h)
    new_w = max(1, int(ref_w * scale))
    new_h = max(1, int(ref_h * scale))
    img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    ox = (output_size - new_w) // 2
    oy = (output_size - new_h) // 2
    canvas.paste(img_resized, (ox, oy))
    pixels = np.array(canvas)

    full_land = np.zeros((output_size, output_size), dtype=bool)
    for y in range(output_size):
        for x in range(output_size):
            r, g, b = pixels[y, x]
            full_land[y, x] = not is_ocean_pixel(int(r), int(g), int(b))

    # Tile grid (64px world tiles, 1 tile = 1 grid cell)
    land_grid = downsample_land_mask(full_land, GRID_SIZE)
    river_grid = generate_glacier_spoke_rivers(
        land_grid,
        seed=seed,
        num_spokes=num_rivers,
        tributaries_per_spoke=tributaries,
    )

    tile_mask = grids_to_biome_mask(land_grid, river_grid)
    mask_arr = upscale_mask(tile_mask, output_size) if output_size != GRID_SIZE else tile_mask
    mask_img = Image.fromarray(mask_arr)

    report = analyze_river_connectivity(mask_arr)

    return mask_img, {
        "summary": report.summary(),
        "ok": report.passes(),
        "component_sizes_top10": report.component_sizes[:10],
        "num_main_rivers": num_rivers,
        "num_tributaries": tributaries * num_rivers,
        "tile_size_px": TILE_SIZE,
        "grid_size": GRID_SIZE,
    }


def build_and_verify_rivers(
    img: Image.Image,
    output_size: int,
    min_largest_pct: float = 95.0,
) -> tuple[Image.Image, dict]:
    """Build rivers phase and auto-tune gap closing until connectivity checks pass."""
    import sys
    from pathlib import Path

    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from river_connectivity import analyze_river_connectivity

    best_mask: Image.Image | None = None
    best_report = None
    best_score = -1.0

    # Try progressively stronger gap closing on the output grid.
    for extra_close in (0, 1, 2):
        global_close_output = max(3, output_size // 512) + extra_close
        # Temporarily patch via kwargs stored on function - simpler: rebuild inline tweak
        mask = _build_biome_mask_rivers_tuned(img, output_size, global_close_output)
        report = analyze_river_connectivity(np.array(mask))
        score = report.largest_pct - report.components_ge_100 * 2 - report.tiny_fragments_lt_20
        if score > best_score:
            best_score = score
            best_mask = mask
            best_report = report
        if report.passes(min_largest_pct=min_largest_pct):
            break

    assert best_mask is not None and best_report is not None
    return best_mask, {
        "summary": best_report.summary(),
        "ok": best_report.passes(min_largest_pct=min_largest_pct),
        "component_sizes_top10": best_report.component_sizes[:10],
    }


def _build_biome_mask_rivers_tuned(img: Image.Image, output_size: int, close_output: int) -> Image.Image:
    img = img.convert("RGB")
    canvas = Image.new("RGB", (output_size, output_size), (30, 90, 180))
    ref_w, ref_h = img.size
    scale = min(output_size / ref_w, output_size / ref_h)
    new_w = max(1, int(ref_w * scale))
    new_h = max(1, int(ref_h * scale))
    img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    ox = (output_size - new_w) // 2
    oy = (output_size - new_h) // 2
    canvas.paste(img_resized, (ox, oy))
    pixels = np.array(canvas)
    ids = np.zeros((output_size, output_size), dtype=np.uint8)
    for y in range(output_size):
        for x in range(output_size):
            r, g, b = pixels[y, x]
            ids[y, x] = classify_phase_pixel(int(r), int(g), int(b), "rivers")
    land_mask = ids != BIOME_OCEAN
    close_source = max(3, int(round(scale * 2.0)))
    min_component = max(25, output_size // 100)
    river_src = build_source_river_mask(img, close_radius=close_source)
    river_canvas = paste_resized_river_mask(
        river_src, output_size, new_w, new_h, ox, oy, land_mask, close_output, min_component
    )
    ids[river_canvas] = BIOME_RIVER
    # Final scrub: drop any river specks introduced by closing.
    river_only = remove_small_components(ids == BIOME_RIVER, min_component)
    ids[ids == BIOME_RIVER] = BIOME_SAVANNA
    ids[river_only] = BIOME_RIVER
    mask = np.rint(ids.astype(np.float32) / 9.0 * 255.0).astype(np.uint8)
    return Image.fromarray(mask)


def main():
    parser = argparse.ArgumentParser(description="Build biome mask from map2.jpg")
    parser.add_argument("--source", default="bible/assets/island_map2.jpg")
    parser.add_argument("--output", default="maps/island/biome_mask.png")
    parser.add_argument("--output-size", type=int, default=1024, help="Mask resolution (1024 or 2048)")
    parser.add_argument(
        "--grass-only",
        action="store_true",
        help="Deprecated alias for --phase grass",
    )
    parser.add_argument(
        "--phase",
        choices=["grass", "rivers", "rivers-proc", "full"],
        default=None,
        help="Incremental build: grass, rivers, or full biomes",
    )
    args = parser.parse_args()

    phase = args.phase
    if args.grass_only:
        phase = "grass"
    if phase is None:
        phase = "full"
    
    repo_root = Path(__file__).resolve().parents[1]
    source = repo_root / args.source
    output = repo_root / args.output
    
    if not source.exists():
        print(f"ERROR: Source not found: {source}")
        return 1
    
    print(f"Loading {source}...")
    img = Image.open(source)
    print(f"  Source size: {img.size}")
    
    phase_labels = {
        "grass": "grass baseline (ocean + savanna)",
        "rivers": "grass + image-traced rivers (legacy)",
        "rivers-proc": "grass + procedural rivers (recommended)",
        "full": "full biomes",
    }
    print(f"Building biome mask at {args.output_size}x{args.output_size} [{phase_labels.get(phase, phase)}]...")
    if phase == "rivers-proc":
        mask, report = build_procedural_rivers(img, args.output_size)
        print(f"  Main rivers: {report.get('num_main_rivers', '?')}")
        print(f"  Tributaries: {report.get('num_tributaries', '?')}")
        print(f"  Connectivity: {report['summary']}")
        print("  Status: PASS" if report["ok"] else "  Status: WARN (best effort)")
    elif phase == "rivers":
        mask, report = build_and_verify_rivers(img, args.output_size)
        print(f"River connectivity: {report['summary']}")
        print("River connectivity: PASS" if report["ok"] else "River connectivity: WARN (best effort)")
    else:
        mask = build_biome_mask(img, args.output_size, phase=phase)
    
    output.parent.mkdir(parents=True, exist_ok=True)
    mask.save(output, optimize=True)
    print(f"Saved: {output}")
    
    # Also update island_meta.json
    import json
    meta_path = output.parent / "island_meta.json"
    meta = {
        "world_width_px": 65536,
        "world_height_px": 65536,
        "chunk_size_px": 2048,
        "chunk_count_x": 32,
        "chunk_count_y": 32,
        "mask_size": args.output_size,
        "source_image": str(source.name),
        "mask_phase": phase,
        "grass_only_baseline": phase == "grass",
        "tile_size_px": 64,
        "sample_stride_px": 64 if phase == "rivers-proc" else 32,
        "note": "Shader-based ground rendering - no chunk PNGs needed",
    }
    meta_path.write_text(json.dumps(meta, indent=2) + "\n")
    print(f"Updated: {meta_path}")
    
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
