#!/usr/bin/env python3
"""Paint one regional biome from island_map2.jpg onto the existing biome_mask.

Only replaces SAVANNA land pixels — keeps ocean, existing biomes, and water_layer untouched.
Usage:
  python3 tools/paint_biome_from_map2.py --biome glacier
  python3 tools/paint_biome_from_map2.py --biome desert
  python3 tools/paint_biome_from_map2.py --biome jungle
  python3 tools/paint_biome_from_map2.py --biome swamp
  python3 tools/paint_biome_from_map2.py --biome beach
"""
from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from build_biome_mask_from_map2 import (  # noqa: E402
    BIOME_BEACH,
    BIOME_DESERT,
    BIOME_FOREST,
    BIOME_GLACIER,
    BIOME_JUNGLE,
    BIOME_OCEAN,
    BIOME_SAVANNA,
    BIOME_SWAMP,
    build_biome_mask,
    classify_pixel,
    is_ocean_pixel,
)

BIOME_ALIASES = {
    "savanna": BIOME_SAVANNA,
    "desert": 2,
    "jungle": 3,
    "swamp": 4,
    "glacier": BIOME_GLACIER,
    "forest": 6,
    "forest_patch": 6,
    "beach": 8,
}

SOURCE = REPO / "bible/assets/island_map2.jpg"
MASK_PATH = REPO / "maps/island/biome_mask.png"
GLACIER_MIN_LAND_FRAC = 0.03
GLACIER_MAX_LAND_FRAC = 0.05

# Base values tuned for 1024x1024 — scaled automatically for higher resolutions.
_BASE_MASK_SIZE = 1024
_BASE_GLACIER_GROW_MAX_RADIUS = 85
_BASE_WEDGE_WAVE_AMPLITUDE = 52
_BASE_GLACIER_RADIUS_WAVE_AMPLITUDE = 34

# Regional biomes that use 3+/4-side speck cleanup vs savanna (see clean_biome_mask_specks.py).
REGIONAL_SPECK_BIOMES = (BIOME_DESERT, BIOME_JUNGLE, BIOME_SWAMP, BIOME_BEACH)


def _mask_scale(mask_size: int) -> float:
    return mask_size / _BASE_MASK_SIZE


def hub_coords(h: int, w: int) -> tuple[int, int]:
    return w // 2, h // 2


WEDGE_WAVE_SEED = 882001


def _glacier_radius_limit(cy: int, cx: int, y: int, x: int, mask_size: int) -> int:
    """Seeded wavy radius so snow line is not a perfect circle on the grid."""
    scale = _mask_scale(mask_size)
    base = int(_BASE_GLACIER_GROW_MAX_RADIUS * scale)
    wave_amp = int(_BASE_GLACIER_RADIUS_WAVE_AMPLITUDE * scale)
    dy, dx = y - cy, x - cx
    if dy == 0 and dx == 0:
        return base + wave_amp
    angle_idx = int((math.atan2(dy, dx) + math.pi) / (2.0 * math.pi) * 24.0) % 24
    wa = _wedge_wave(angle_idx, 0, 40)
    wb = _wedge_wave(angle_idx // 2, 0, 41)
    wave = (wa + wb) / 2.0
    return base + int((wave - 0.5) * 2 * wave_amp)


def _wedge_wave(a: int, b: int, salt: int) -> float:
    hv = hash((WEDGE_WAVE_SEED, salt, a, b)) & 0xFFFFFFFF
    return hv / 4294967295.0


def ne_wedge_mask(h: int, w: int, hub_x: int | None = None, hub_y: int | None = None) -> np.ndarray:
    """Northeast quadrant only — desert belongs here, nowhere else."""
    if hub_x is None or hub_y is None:
        hub_x, hub_y = hub_coords(h, w)
    xs = np.arange(w)
    ys = np.arange(h)
    xx, yy = np.meshgrid(xs, ys)
    return (xx >= hub_x) & (yy <= hub_y)


def sw_wedge_mask(h: int, w: int, hub_x: int | None = None, hub_y: int | None = None) -> np.ndarray:
    """Southwest quadrant — jungle finger."""
    if hub_x is None or hub_y is None:
        hub_x, hub_y = hub_coords(h, w)
    xs = np.arange(w)
    ys = np.arange(h)
    xx, yy = np.meshgrid(xs, ys)
    return (xx <= hub_x) & (yy >= hub_y)


def nw_west_wedge_mask(h: int, w: int, hub_x: int | None = None, hub_y: int | None = None) -> np.ndarray:
    """Northwest quadrant — swamp on the muddy western bays.

    Plain box on purpose: tools/shape_biome_regions.py turns the cut into a curve.
    (A per-column wavy limit produced a comb of stripes along the growth front.)
    """
    if hub_x is None or hub_y is None:
        hub_x, hub_y = hub_coords(h, w)
    xs = np.arange(w)
    ys = np.arange(h)
    xx, yy = np.meshgrid(xs, ys)
    return (xx <= hub_x) & (yy <= hub_y)


SWAMP_TARGET_LAND_FRACTION = 0.10


def is_map2_swamp_tone(r: int, g: int, b: int) -> bool:
    """Dark olive / muddy map2 tones used for the NW bay (from measured swamp pixels)."""
    if b > 110 or r > 140 or g > 135 or min(r, g, b) > 100:
        return False
    if 28 <= r <= 130 and 45 <= g <= 120 and 4 <= b <= 100:
        if g >= r - 30 and (r + g) * 0.5 >= b + 8:
            return True
    if r > g and r > b and g < 100 and r < 130:
        return True
    return False


def expand_swamp_from_map2_tones(ids: np.ndarray, ref: np.ndarray) -> int:
    """Paint dark muddy map2 savanna in the NW west wedge before ring growth."""
    h, w = ids.shape
    wedge = nw_west_wedge_mask(h, w)
    painted = 0
    for y in range(h):
        for x in range(w):
            if ids[y, x] != BIOME_SAVANNA or not wedge[y, x]:
                continue
            r, g, b = int(ref[y, x, 0]), int(ref[y, x, 1]), int(ref[y, x, 2])
            if is_map2_swamp_tone(r, g, b):
                ids[y, x] = BIOME_SWAMP
                painted += 1
    return painted


def keep_largest_swamp_body(ids: np.ndarray) -> int:
    """Swamp is ONE marsh region. Drop tone-matched polka dots (map2 forest clumps)."""
    from scipy import ndimage

    swamp = ids == BIOME_SWAMP
    labels, count = ndimage.label(swamp, structure=np.ones((3, 3), dtype=bool))
    if count <= 1:
        return 0
    sizes = ndimage.sum(swamp, labels, index=np.arange(1, count + 1))
    keep = int(np.argmax(sizes)) + 1
    stray = swamp & (labels != keep)
    ids[stray] = BIOME_SAVANNA
    return int(stray.sum())


def grow_swamp_to_target(
    ids: np.ndarray,
    is_water: np.ndarray | None = None,
    target_fraction: float = SWAMP_TARGET_LAND_FRACTION,
) -> int:
    """Grow swamp within NW west wedge — seeded noisy frontier (not uniform rings).

    * May reach the bay shore (marsh on a bay is natural; beach skips swamp coast).
    * Never crosses a painted river — the river is the marsh's natural boundary.
    """
    h, w = ids.shape
    if is_water is None:
        is_water = np.zeros(ids.shape, dtype=bool)
    land = int((ids != BIOME_OCEAN).sum())
    target = max(int(land * target_fraction), int((ids == BIOME_SWAMP).sum()))
    wedge = nw_west_wedge_mask(h, w) & ~is_water
    grown = 0

    def shape_rand(x: int, y: int, salt: int = 0) -> float:
        hv = hash((882001, salt, x, y)) & 0xFFFFFFFF
        return hv / 4294967295.0

    for pass_idx in range(512):
        if int((ids == BIOME_SWAMP).sum()) >= target:
            break
        candidates: list[tuple[float, int, int]] = []
        for y in range(h):
            for x in range(w):
                if ids[y, x] != BIOME_SAVANNA or not wedge[y, x]:
                    continue
                neighbors = 0
                for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and ids[ny, nx] == BIOME_SWAMP:
                        neighbors += 1
                if neighbors == 0:
                    continue
                # Prefer tight clusters but jitter order so the front wobbles.
                score = float(neighbors) + shape_rand(x, y, pass_idx) * 1.35
                if shape_rand(x, y, pass_idx + 17) < 0.22:
                    continue
                candidates.append((score, y, x))
        if not candidates:
            break
        candidates.sort(reverse=True)
        for _score, y, x in candidates:
            if int((ids == BIOME_SWAMP).sum()) >= target:
                break
            if ids[y, x] == BIOME_SAVANNA:
                ids[y, x] = BIOME_SWAMP
                grown += 1
    return grown


def clamp_jungle_to_southwest(ids: np.ndarray) -> dict:
    h, w = ids.shape
    wedge = sw_wedge_mask(h, w)
    jungle = ids == BIOME_JUNGLE
    removed = int((jungle & ~wedge).sum())
    ids[jungle & ~wedge] = BIOME_SAVANNA
    land = int((ids != BIOME_OCEAN).sum())
    total = int((ids == BIOME_JUNGLE).sum())
    return {
        "removed_outside_sw": removed,
        "total_jungle": total,
        "pct_of_land": round(100.0 * total / max(land, 1), 2),
    }


def clamp_swamp_to_west_north(ids: np.ndarray) -> dict:
    h, w = ids.shape
    wedge = nw_west_wedge_mask(h, w)
    swamp = ids == BIOME_SWAMP
    removed = int((swamp & ~wedge).sum())
    ids[swamp & ~wedge] = BIOME_SAVANNA
    land = int((ids != BIOME_OCEAN).sum())
    total = int((ids == BIOME_SWAMP).sum())
    return {
        "removed_outside_nw_west": removed,
        "total_swamp": total,
        "pct_of_land": round(100.0 * total / max(land, 1), 2),
    }


def _ocean_adjacent(ids: np.ndarray, y: int, x: int) -> bool:
    h, w = ids.shape
    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        ny, nx = y + dy, x + dx
        if 0 <= ny < h and 0 <= nx < w and ids[ny, nx] == BIOME_OCEAN:
            return True
    return False


def _swamp_adjacent(ids: np.ndarray, y: int, x: int) -> bool:
    h, w = ids.shape
    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        ny, nx = y + dy, x + dx
        if 0 <= ny < h and 0 <= nx < w and ids[ny, nx] == BIOME_SWAMP:
            return True
    return False


def clamp_beach_to_coast(ids: np.ndarray) -> dict:
    """Beach only on ocean shore; no sandy band on swamp coast."""
    h, w = ids.shape
    removed = 0
    for y in range(h):
        for x in range(w):
            if ids[y, x] != BIOME_BEACH:
                continue
            if not _ocean_adjacent(ids, y, x) or _swamp_adjacent(ids, y, x):
                ids[y, x] = BIOME_SAVANNA
                removed += 1
    land = int((ids != BIOME_OCEAN).sum())
    total = int((ids == BIOME_BEACH).sum())
    return {
        "removed_inland_or_swamp_coast": removed,
        "total_beach": total,
        "pct_of_land": round(100.0 * total / max(land, 1), 2),
    }


def clamp_desert_to_northeast(ids: np.ndarray) -> dict:
    """Remove desert outside the NE wedge (map2 tan often bleeds island-wide)."""
    h, w = ids.shape
    wedge = ne_wedge_mask(h, w)
    desert = ids == BIOME_DESERT
    removed = int((desert & ~wedge).sum())
    ids[desert & ~wedge] = BIOME_SAVANNA
    total = int((ids == BIOME_DESERT).sum())
    land = int((ids != BIOME_OCEAN).sum())
    return {
        "removed_outside_ne": removed,
        "total_desert": total,
        "pct_of_land": round(100.0 * total / max(land, 1), 2),
    }


def ids_from_mask(arr: np.ndarray) -> np.ndarray:
    return np.rint(arr.astype(np.float32) / 255.0 * 9.0).astype(np.int32)


def encode_ids(ids: np.ndarray) -> np.ndarray:
    return np.rint(ids.astype(np.float32) / 9.0 * 255.0).astype(np.uint8)


def _glacier_seed(ids: np.ndarray) -> tuple[int, int] | None:
    h, w = ids.shape
    cy, cx = h // 2, w // 2
    if ids[cy, cx] == BIOME_GLACIER:
        return cy, cx
    glacier = np.argwhere(ids == BIOME_GLACIER)
    if glacier.size == 0:
        return None
    dist = (glacier[:, 0] - cy) ** 2 + (glacier[:, 1] - cx) ** 2
    idx = int(dist.argmin())
    return int(glacier[idx, 0]), int(glacier[idx, 1])


def clamp_glacier_to_center(ids: np.ndarray) -> dict:
    """Glacier belongs at the watershed center only — not pale map2 streaks along rivers."""
    h, w = ids.shape
    seed = _glacier_seed(ids)
    if seed is None:
        return {"removed_spokes": 0, "grown": 0, "total_glacier": 0, "pct_of_land": 0.0}

    glacier = ids == BIOME_GLACIER
    visited = np.zeros((h, w), dtype=bool)
    queue: list[tuple[int, int]] = [seed]
    visited[seed] = True
    head = 0
    while head < len(queue):
        y, x = queue[head]
        head += 1
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and glacier[ny, nx] and not visited[ny, nx]:
                visited[ny, nx] = True
                queue.append((ny, nx))

    removed = int((glacier & ~visited).sum())
    ids[glacier & ~visited] = BIOME_SAVANNA

    land = int((ids != BIOME_OCEAN).sum())
    target_min = max(1, int(land * GLACIER_MIN_LAND_FRAC))
    target_max = max(target_min, int(land * GLACIER_MAX_LAND_FRAC))
    cy, cx = h // 2, w // 2
    grown = 0
    gmask = ids == BIOME_GLACIER

    for _ in range(32):
        if int(gmask.sum()) >= target_min:
            break
        new = gmask.copy()
        for y in range(h):
            for x in range(w):
                if gmask[y, x] or ids[y, x] != BIOME_SAVANNA:
                    continue
                if (y - cy) ** 2 + (x - cx) ** 2 > _glacier_radius_limit(cy, cx, y, x, h) ** 2:
                    continue
                if any(
                    gmask[y + dy, x + dx]
                    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))
                    if 0 <= y + dy < h and 0 <= x + dx < w
                ):
                    new[y, x] = True
        added = int((new & ~gmask).sum())
        if added == 0:
            break
        gmask = new
        grown += added

    ids[gmask] = BIOME_GLACIER
    total = int(gmask.sum())
    return {
        "removed_spokes": removed,
        "grown": grown,
        "total_glacier": total,
        "pct_of_land": round(100.0 * total / max(land, 1), 2),
    }


def map2_pixels_at_mask_size(source: Path, output_size: int) -> np.ndarray:
    img = Image.open(source).convert("RGB")
    canvas = Image.new("RGB", (output_size, output_size), (30, 90, 180))
    ref_w, ref_h = img.size
    scale = min(output_size / ref_w, output_size / ref_h)
    new_w = max(1, int(ref_w * scale))
    new_h = max(1, int(ref_h * scale))
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    ox = (output_size - new_w) // 2
    oy = (output_size - new_h) // 2
    canvas.paste(resized, (ox, oy))
    return np.array(canvas)


# map2 color IDs accepted when painting each regional biome (wedge still applies).
PAINT_ACCEPT_CLASSES: dict[int, set[int]] = {
    BIOME_JUNGLE: {BIOME_JUNGLE, BIOME_SWAMP, BIOME_FOREST},
    BIOME_SWAMP: {BIOME_SWAMP, BIOME_JUNGLE, BIOME_FOREST},
    BIOME_DESERT: {BIOME_DESERT},
    BIOME_GLACIER: {BIOME_GLACIER},
    BIOME_BEACH: {BIOME_BEACH},
}


def accepted_map2_class(biome_id: int, classified: int) -> bool:
    allowed = PAINT_ACCEPT_CLASSES.get(biome_id, {biome_id})
    return classified in allowed


def paint_coast_beach(ids: np.ndarray, ref: np.ndarray) -> int:
    """Narrow sand band: land touching ocean, except swamp coast (design lock)."""
    h, w = ids.shape
    painted = 0
    for y in range(h):
        for x in range(w):
            if ids[y, x] not in (BIOME_SAVANNA, BIOME_DESERT):
                continue
            if not _ocean_adjacent(ids, y, x) or _swamp_adjacent(ids, y, x):
                continue
            ids[y, x] = BIOME_BEACH
            painted += 1
    return painted


def paint_mask_for_biome(biome_id: int, h: int, w: int) -> np.ndarray | None:
    if biome_id == BIOME_DESERT:
        return ne_wedge_mask(h, w)
    if biome_id == BIOME_JUNGLE:
        return sw_wedge_mask(h, w)
    if biome_id == BIOME_SWAMP:
        return nw_west_wedge_mask(h, w)
    return None


def clamp_for_biome(biome_id: int, ids: np.ndarray) -> dict:
    if biome_id == BIOME_GLACIER:
        return clamp_glacier_to_center(ids)
    if biome_id == BIOME_DESERT:
        return clamp_desert_to_northeast(ids)
    if biome_id == BIOME_JUNGLE:
        return clamp_jungle_to_southwest(ids)
    if biome_id == BIOME_SWAMP:
        return clamp_swamp_to_west_north(ids)
    if biome_id == BIOME_BEACH:
        return clamp_beach_to_coast(ids)
    return {}


def paint_biome(biome_name: str, mask_path: Path = MASK_PATH, source: Path = SOURCE) -> dict:
    biome_id = BIOME_ALIASES.get(biome_name.lower())
    if biome_id is None:
        raise SystemExit(f"Unknown biome '{biome_name}'. Choose: {', '.join(BIOME_ALIASES)}")

    arr = np.array(Image.open(mask_path))
    ids = ids_from_mask(arr)
    h, w = ids.shape
    ref = map2_pixels_at_mask_size(source, w)
    wedge = paint_mask_for_biome(biome_id, h, w)

    painted = 0
    for y in range(h):
        for x in range(w):
            if ids[y, x] != BIOME_SAVANNA:
                continue
            if wedge is not None and not wedge[y, x]:
                continue
            r, g, b = int(ref[y, x, 0]), int(ref[y, x, 1]), int(ref[y, x, 2])
            if biome_id == BIOME_BEACH:
                continue
            classified = classify_pixel(r, g, b)
            ok = accepted_map2_class(biome_id, classified)
            if biome_id == BIOME_SWAMP and not ok:
                ok = is_map2_swamp_tone(r, g, b)
            if not ok:
                continue
            ids[y, x] = biome_id
            painted += 1

    if biome_id == BIOME_BEACH:
        painted = paint_coast_beach(ids, ref)

    Image.fromarray(encode_ids(ids)).save(mask_path)
    clamp_stats = clamp_for_biome(biome_id, ids)
    if biome_id == BIOME_SWAMP:
        tone_px = expand_swamp_from_map2_tones(ids, ref)
        clamp_stats["strays_dropped"] = keep_largest_swamp_body(ids)
        water_path = mask_path.parent / "water_layer.png"
        is_water = None
        if water_path.exists():
            water_arr = np.array(Image.open(water_path))
            if water_arr.ndim == 3:
                water_arr = water_arr[:, :, 0]
            is_water = water_arr > 127
        grown = grow_swamp_to_target(ids, is_water)
        clamp_stats["tone_expanded"] = tone_px
        clamp_stats["grown"] = grown
        clamp_stats["total_swamp"] = int((ids == BIOME_SWAMP).sum())
        land_now = int((ids != BIOME_OCEAN).sum())
        clamp_stats["pct_of_land"] = round(100.0 * clamp_stats["total_swamp"] / max(land_now, 1), 2)
    if clamp_stats:
        Image.fromarray(encode_ids(ids)).save(mask_path)

    land = int((ids != BIOME_OCEAN).sum())
    total_biome = int((ids == biome_id).sum())
    return {
        "biome": biome_name,
        "biome_id": biome_id,
        "pixels_painted": painted,
        "total_biome_pixels": total_biome,
        "land_pixels": land,
        "pct_of_land": round(100.0 * total_biome / max(land, 1), 2),
        "clamp": clamp_stats,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--biome", required=True, help="glacier, desert, jungle, swamp, beach, ...")
    parser.add_argument("--mask", default=str(MASK_PATH))
    parser.add_argument("--source", default=str(SOURCE))
    args = parser.parse_args()

    stats = paint_biome(args.biome, Path(args.mask), Path(args.source))
    msg = (
        f"painted {stats['biome']}: +{stats['pixels_painted']} px "
        f"(total {stats['total_biome_pixels']} = {stats['pct_of_land']}% of land)"
    )
    clamp = stats.get("clamp") or {}
    if clamp:
        msg += f"\n  clamp: {clamp}"
    print(msg)


if __name__ == "__main__":
    main()
