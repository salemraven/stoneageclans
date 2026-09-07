#!/usr/bin/env python3
"""Clean biome_mask illegal tiles (must match scripts/world/mask_topology.gd).

Source-of-truth contract
------------------------
* water_layer.png  = hand-painted rivers (water_layer_guides.png). NEVER modified here.
* biome_mask.png   = gameplay grid. Only this file is edited.
* Region SHAPE (organic borders) is done by tools/shape_biome_regions.py, not here.

Rules (3+ of 4 cardinal neighbors; includes fully enclosed 4-side holes)
* land tile with 3+ OCEAN sides (map edge counts as ocean) -> ocean
* ocean tile with 3+ land sides -> savanna
* ocean not connected to the map-edge sea -> savanna
* land tile with 3+ sides of one other land biome -> that biome (rivers/ocean skipped)
* desert never touches a river: desert tile beside river -> savanna

Straight biome borders are DETECTED and reported (see biome_mask_shape_rules.py);
--check-only fails when a collinear border chain is >= MIN_STRAIGHT_BORDER_LEN tiles.

Usage:
  python3 tools/clean_biome_mask_specks.py               # fix in place
  python3 tools/clean_biome_mask_specks.py --check-only  # exit 1 on violations
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

from biome_mask_shape_rules import (
    MIN_STRAIGHT_BORDER_LEN,
    count_straight_borders,
    find_straight_borders,
    format_straight_report,
)

OCEAN = 0
SAVANNA = 1
DESERT = 2
JUNGLE = 3
SWAMP = 4
GLACIER = 5
BEACH = 8
LAND_SPECK_BIOMES = (SAVANNA, DESERT, JUNGLE, SWAMP, GLACIER, BEACH)
BIOME_NAMES = {
    SAVANNA: "grass",
    DESERT: "desert",
    JUNGLE: "jungle",
    SWAMP: "swamp",
    GLACIER: "glacier",
    BEACH: "beach",
}
MIN_OPPOSING_SIDES = 3
CARDINAL = [(-1, 0), (1, 0), (0, -1), (0, 1)]
FOUR_CONNECTED = np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]], dtype=bool)


def ids_from_mask(arr: np.ndarray) -> np.ndarray:
    if arr.ndim == 3:
        arr = arr[:, :, 0]
    return np.rint(arr.astype(np.float32) / 255.0 * 9.0).astype(np.int32)


def encode_ids(ids: np.ndarray) -> np.ndarray:
    return np.rint(ids.astype(np.float32) / 9.0 * 255.0).astype(np.uint8)


def load_water(path: Path, shape: tuple[int, int]) -> np.ndarray:
    if not path.exists():
        return np.zeros(shape, dtype=bool)
    water = np.array(Image.open(path))
    if water.ndim == 3:
        water = water[:, :, 0]
    return water > 127


def _cardinal_count(mask: np.ndarray, pad_value: bool) -> np.ndarray:
    """For each tile, how many of its 4 cardinal neighbors are True in `mask`."""
    padded = np.pad(mask, 1, constant_values=pad_value)
    return (
        padded[:-2, 1:-1].astype(np.int32)
        + padded[2:, 1:-1]
        + padded[1:-1, :-2]
        + padded[1:-1, 2:]
    )


# --- ocean / land topology ---------------------------------------------------


def land_mask(ids: np.ndarray, is_water: np.ndarray) -> np.ndarray:
    return (ids != OCEAN) & ~is_water


def find_land_in_ocean(ids: np.ndarray, is_water: np.ndarray) -> np.ndarray:
    ocean = ids == OCEAN
    return land_mask(ids, is_water) & (_cardinal_count(ocean, True) >= MIN_OPPOSING_SIDES)


def find_ocean_in_land(ids: np.ndarray, is_water: np.ndarray) -> np.ndarray:
    ocean = ids == OCEAN
    return ocean & (_cardinal_count(land_mask(ids, is_water), False) >= MIN_OPPOSING_SIDES)


def remove_disconnected_ocean(ids: np.ndarray) -> int:
    ocean = ids == OCEAN
    labels, count = ndimage.label(ocean, structure=FOUR_CONNECTED)
    if count == 0:
        return 0
    edge_labels = set(np.unique(labels[0, :])) | set(np.unique(labels[-1, :]))
    edge_labels |= set(np.unique(labels[:, 0])) | set(np.unique(labels[:, -1]))
    edge_labels.discard(0)
    stray = ocean & ~np.isin(labels, list(edge_labels))
    ids[stray] = SAVANNA
    return int(stray.sum())


# --- biome specks ----------------------------------------------------------------


def speck_targets(ids: np.ndarray, is_water: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """(mask of tiles to flip, target biome per tile) for the 3+/4 rule."""
    land = land_mask(ids, is_water)
    best_count = np.zeros(ids.shape, dtype=np.int32)
    best_biome = np.full(ids.shape, -1, dtype=np.int32)
    for biome_id in LAND_SPECK_BIOMES:
        member = land & (ids == biome_id)
        n = _cardinal_count(member, False)
        better = (n >= MIN_OPPOSING_SIDES) & (n > best_count) & (ids != biome_id)
        best_count[better] = n[better]
        best_biome[better] = biome_id
    flip = land & (best_biome >= 0)
    return flip, best_biome


def count_remaining_biome_specks(ids: np.ndarray, is_water: np.ndarray) -> int:
    flip, _ = speck_targets(ids, is_water)
    return int(flip.sum())


def clean_all_land_biome_specks(ids: np.ndarray, is_water: np.ndarray, max_passes: int = 64) -> int:
    fixed = 0
    for _ in range(max_passes):
        flip, target = speck_targets(ids, is_water)
        n = int(flip.sum())
        if n == 0:
            break
        ids[flip] = target[flip]
        fixed += n
    return fixed


def retract_desert_from_rivers(ids: np.ndarray, is_water: np.ndarray) -> int:
    hit = (ids == DESERT) & (_cardinal_count(is_water, False) > 0)
    ids[hit] = SAVANNA
    return int(hit.sum())


# --- report / fix ------------------------------------------------------------------


def validate(ids: np.ndarray, is_water: np.ndarray) -> dict[str, int]:
    return {
        "grass_in_water": int(find_land_in_ocean(ids, is_water).sum()),
        "ocean_in_grass": int(find_ocean_in_land(ids, is_water).sum()),
        "desert_on_river": int(((ids == DESERT) & (_cardinal_count(is_water, False) > 0)).sum()),
    }


def clean_ids(ids: np.ndarray, is_water: np.ndarray, max_passes: int = 16) -> dict[str, int]:
    totals = {
        "grass_in_water": 0,
        "ocean_in_grass": 0,
        "disconnected_ocean": 0,
        "desert_retracted": 0,
        "biome_specks_fixed": 0,
        "passes": 0,
    }
    for i in range(max_passes):
        step = 0
        totals["desert_retracted"] += (n := retract_desert_from_rivers(ids, is_water))
        step += n
        totals["biome_specks_fixed"] += (n := clean_all_land_biome_specks(ids, is_water))
        step += n

        hit = find_land_in_ocean(ids, is_water)
        ids[hit] = OCEAN
        totals["grass_in_water"] += (n := int(hit.sum()))
        step += n

        hit = find_ocean_in_land(ids, is_water)
        ids[hit] = SAVANNA
        totals["ocean_in_grass"] += (n := int(hit.sum()))
        step += n

        totals["disconnected_ocean"] += (n := remove_disconnected_ocean(ids))
        step += n

        totals["passes"] = i + 1
        if step == 0:
            break
    return totals


def clean_mask(mask_path: Path, water_path: Path, max_passes: int = 16) -> dict[str, int]:
    ids = ids_from_mask(np.array(Image.open(mask_path)))
    is_water = load_water(water_path, ids.shape)
    totals = clean_ids(ids, is_water, max_passes)
    Image.fromarray(encode_ids(ids)).save(mask_path)
    return totals


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mask", default="maps/island/biome_mask.png")
    parser.add_argument("--water", default="maps/island/water_layer.png")
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()

    mask_path = Path(args.mask)
    water_path = Path(args.water)

    if not args.check_only:
        totals = clean_mask(mask_path, water_path)
        print("cleaned " + mask_path.name + ": " + ", ".join(f"{k}={v}" for k, v in totals.items()))

    ids = ids_from_mask(np.array(Image.open(mask_path)))
    is_water = load_water(water_path, ids.shape)
    report = validate(ids, is_water)
    specks = count_remaining_biome_specks(ids, is_water)
    segments = find_straight_borders(ids, is_water)
    straight = sum(1 for s in segments if s.length >= MIN_STRAIGHT_BORDER_LEN)
    ok = sum(report.values()) == 0 and specks == 0 and straight == 0
    print("OK" if ok else "FAIL", report, f"biome_specks={specks}", f"straight_borders={straight}")
    print(format_straight_report(segments))
    if args.check_only:
        raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
