#!/usr/bin/env python3
"""Shape regional biomes into organic regions — deterministic, seeded.

Run AFTER paint_biome_from_map2.py (all biomes) and BEFORE clean_biome_mask_specks.py.

Why: the per-tile "nibble" approach only punches gaps in straight lines. Natural
borders come from shaping the WHOLE region:
  1. drop stray blobs (polka dots from map2 tone matching)
  2. morphological open/close (kills 1-3 tile spikes and pinholes)
  3. domain-warp the region with seeded low-frequency noise (straight cuts -> curves)
  4. gaussian blur + threshold (rounded, grid-free borders)
  5. keep land only, drop strays again

Compose priority: glacier > desert > swamp > jungle over savanna.
Water layer is NEVER modified here (rivers = water_layer_guides.png).
Desert retracts from rivers; beach is recomputed on the ocean coast (not on swamp coast).

Usage:
  python3 tools/shape_biome_regions.py            # in place on maps/island
  python3 tools/shape_biome_regions.py --report   # print per-biome stats only
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from clean_biome_mask_specks import (  # noqa: E402
    BEACH,
    DESERT,
    GLACIER,
    JUNGLE,
    OCEAN,
    SAVANNA,
    SWAMP,
    encode_ids,
    ids_from_mask,
)

MASK_PATH = REPO / "maps/island/biome_mask.png"
WATER_PATH = REPO / "maps/island/water_layer.png"
META_PATH = REPO / "maps/island/island_meta.json"
DEFAULT_SEED = 882001
CARDINAL = ((-1, 0), (1, 0), (0, -1), (0, 1))


@dataclass(frozen=True)
class ShapeParams:
    name: str
    keep: str  # "largest" or "min_size"
    min_size: int
    open_radius: int
    close_radius: int
    warp_amplitude: float  # tiles
    warp_wavelength: float  # tiles
    blur_sigma: float
    edge_noise: float  # small high-frequency threshold jitter


# Base parameters tuned for 1024x1024 mask. Scaled automatically for higher resolutions.
BASE_MASK_SIZE = 1024
_BASE_PARAMS: dict[int, ShapeParams] = {
    GLACIER: ShapeParams("glacier", "largest", 0, 3, 2, 7.0, 48.0, 2.0, 0.06),
    DESERT: ShapeParams("desert", "largest", 0, 2, 3, 16.0, 96.0, 3.0, 0.08),
    SWAMP: ShapeParams("swamp", "largest", 0, 2, 3, 16.0, 96.0, 3.0, 0.08),
    JUNGLE: ShapeParams("jungle", "min_size", 900, 2, 3, 18.0, 96.0, 3.0, 0.08),
}
COMPOSE_ORDER = (GLACIER, DESERT, SWAMP, JUNGLE)
_BASE_DESERT_RIVER_MARGIN = 2
_BASE_SHORE_FILL_RADIUS = 6


def scale_params(mask_size: int) -> tuple[dict[int, ShapeParams], int, int]:
    """Scale shape parameters for the actual mask resolution."""
    scale = mask_size / BASE_MASK_SIZE
    scaled: dict[int, ShapeParams] = {}
    for biome_id, p in _BASE_PARAMS.items():
        scaled[biome_id] = ShapeParams(
            name=p.name,
            keep=p.keep,
            min_size=int(p.min_size * scale * scale),  # area scales quadratically
            open_radius=max(1, int(p.open_radius * scale)),
            close_radius=max(1, int(p.close_radius * scale)),
            warp_amplitude=p.warp_amplitude * scale,
            warp_wavelength=p.warp_wavelength * scale,
            blur_sigma=p.blur_sigma * scale,
            edge_noise=p.edge_noise,  # threshold jitter doesn't scale
        )
    desert_margin = max(1, int(_BASE_DESERT_RIVER_MARGIN * scale))
    shore_fill = max(1, int(_BASE_SHORE_FILL_RADIUS * scale))
    return scaled, desert_margin, shore_fill


def _disk(radius: int) -> np.ndarray:
    if radius <= 0:
        return np.ones((1, 1), dtype=bool)
    yy, xx = np.mgrid[-radius : radius + 1, -radius : radius + 1]
    return (yy * yy + xx * xx) <= radius * radius


def seeded_noise(shape: tuple[int, int], wavelength: float, seed: int, octaves: int = 2) -> np.ndarray:
    """Smooth noise in [-1, 1]; deterministic from seed. Coarse random grid -> cubic zoom."""
    h, w = shape
    total = np.zeros((h, w), dtype=np.float32)
    amp_sum = 0.0
    for octave in range(octaves):
        wl = max(4.0, wavelength / (2**octave))
        amp = 1.0 / (2**octave)
        rng = np.random.default_rng(seed * 7919 + octave * 104729)
        gh = max(2, int(np.ceil(h / wl)) + 2)
        gw = max(2, int(np.ceil(w / wl)) + 2)
        grid = rng.uniform(-1.0, 1.0, size=(gh, gw)).astype(np.float32)
        zoomed = ndimage.zoom(grid, (h / gh, w / gw), order=3, mode="reflect")
        zoomed = zoomed[:h, :w]
        if zoomed.shape != (h, w):
            padded = np.zeros((h, w), dtype=np.float32)
            padded[: zoomed.shape[0], : zoomed.shape[1]] = zoomed
            zoomed = padded
        total += amp * zoomed
        amp_sum += amp
    total /= amp_sum
    peak = float(np.abs(total).max()) or 1.0
    return total / peak


def keep_components(mask: np.ndarray, keep: str, min_size: int) -> np.ndarray:
    labels, count = ndimage.label(mask, structure=np.ones((3, 3), dtype=bool))
    if count == 0:
        return mask
    sizes = ndimage.sum(mask, labels, index=np.arange(1, count + 1))
    if keep == "largest":
        best = int(np.argmax(sizes)) + 1
        return labels == best
    keep_ids = [i + 1 for i, s in enumerate(sizes) if s >= min_size]
    if not keep_ids:
        best = int(np.argmax(sizes)) + 1
        keep_ids = [best]
    return np.isin(labels, keep_ids)


def domain_warp(mask: np.ndarray, amplitude: float, wavelength: float, seed: int) -> np.ndarray:
    """Sample the region at displaced coordinates -> straight edges become curves.

    Three octaves (wavelength, /2, /4) so long edges get both a slow meander and
    mid-frequency character; a single octave leaves 20+ tile flats on long edges.
    """
    h, w = mask.shape
    dx = seeded_noise((h, w), wavelength, seed + 11, octaves=3) * amplitude
    dy = seeded_noise((h, w), wavelength, seed + 23, octaves=3) * amplitude
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    coords = np.array([yy + dy, xx + dx])
    warped = ndimage.map_coordinates(mask.astype(np.float32), coords, order=1, mode="nearest")
    return warped


def shape_region(
    region: np.ndarray, land: np.ndarray, params: ShapeParams, seed: int, shore_fill_radius: int
) -> np.ndarray:
    if not region.any():
        return region
    m = keep_components(region, params.keep, params.min_size)
    m = ndimage.binary_opening(m, structure=_disk(params.open_radius))
    m = ndimage.binary_closing(m, structure=_disk(params.close_radius))
    if not m.any():
        return m
    # Shore/river tiles right next to the region count as region while smoothing,
    # otherwise the blur sees "not region" there and peels a 2-3 tile rim off every coast.
    shore_fill = ~land & ndimage.binary_dilation(m, structure=_disk(shore_fill_radius))
    field = domain_warp(m | shore_fill, params.warp_amplitude, params.warp_wavelength, seed)
    field = ndimage.gaussian_filter(field, sigma=params.blur_sigma)
    jitter = seeded_noise(m.shape, 6.0, seed + 97, octaves=1) * params.edge_noise
    shaped = (field + jitter) > 0.5
    shaped &= land
    shaped = keep_components(shaped, params.keep, params.min_size)
    return shaped


def retract_desert_from_rivers(ids: np.ndarray, is_water: np.ndarray, margin: int) -> int:
    near_river = ndimage.binary_dilation(is_water, structure=_disk(margin))
    hit = (ids == DESERT) & near_river
    ids[hit] = SAVANNA
    return int(hit.sum())


def paint_coast_beach(ids: np.ndarray, is_water: np.ndarray) -> int:
    """Sand band on ocean shore (savanna/desert only), never on swamp coast."""
    h, w = ids.shape
    ocean = ids == OCEAN
    ocean_adjacent = ndimage.binary_dilation(ocean, structure=_disk(1)) & ~ocean
    swamp_adjacent = ndimage.binary_dilation(ids == SWAMP, structure=_disk(1))
    candidates = ocean_adjacent & ~is_water & np.isin(ids, (SAVANNA, DESERT)) & ~swamp_adjacent
    ids[candidates] = BEACH
    return int(candidates.sum())


def shape_all(ids: np.ndarray, is_water: np.ndarray, seed: int) -> dict[str, dict[str, float]]:
    mask_size = ids.shape[0]
    shape_params, desert_margin, shore_fill_radius = scale_params(mask_size)

    land = (ids != OCEAN) & ~is_water
    stats: dict[str, dict[str, float]] = {}
    shaped: dict[int, np.ndarray] = {}
    for biome_id in COMPOSE_ORDER:
        params = shape_params[biome_id]
        before = ids == biome_id
        after = shape_region(before, land, params, seed + biome_id * 1000, shore_fill_radius)
        shaped[biome_id] = after
        stats[params.name] = {"before_px": int(before.sum()), "after_px": int(after.sum())}

    # Rebuild land as savanna, then compose by priority.
    ids[land] = SAVANNA
    claimed = np.zeros_like(land)
    for biome_id in COMPOSE_ORDER:
        region = shaped[biome_id] & land & ~claimed
        ids[region] = biome_id
        claimed |= region

    stats["desert_retracted_px"] = {"value": retract_desert_from_rivers(ids, is_water, desert_margin)}
    stats["beach_px"] = {"value": paint_coast_beach(ids, is_water)}

    total_land = int(land.sum())
    for biome_id, name in ((SAVANNA, "savanna"), (DESERT, "desert"), (JUNGLE, "jungle"), (SWAMP, "swamp"), (GLACIER, "glacier"), (BEACH, "beach")):
        stats.setdefault(name, {})["pct_land"] = round(100.0 * int((ids == biome_id).sum()) / max(total_land, 1), 2)
    stats["mask_size"] = {"value": mask_size}
    return stats


def load_seed(meta_path: Path, override: int | None) -> int:
    if override is not None:
        return override
    if meta_path.exists():
        meta = json.loads(meta_path.read_text())
        if "world_seed" in meta:
            return int(meta["world_seed"])
    return DEFAULT_SEED


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mask", default=str(MASK_PATH))
    parser.add_argument("--water", default=str(WATER_PATH))
    parser.add_argument("--seed", type=int, default=None, help="override world_seed from island_meta.json")
    parser.add_argument("--report", action="store_true", help="compute stats but do not write")
    args = parser.parse_args()

    mask_path = Path(args.mask)
    water_path = Path(args.water)
    ids = ids_from_mask(np.array(Image.open(mask_path)))
    water = np.array(Image.open(water_path))
    if water.ndim == 3:
        water = water[:, :, 0]
    is_water = water > 127
    seed = load_seed(META_PATH, args.seed)

    stats = shape_all(ids, is_water, seed)
    if not args.report:
        Image.fromarray(encode_ids(ids)).save(mask_path)
    print(f"shape_biome_regions seed={seed} {'(report only)' if args.report else 'written'}")
    for name, values in stats.items():
        print(f"  {name}: {values}")


if __name__ == "__main__":
    main()
