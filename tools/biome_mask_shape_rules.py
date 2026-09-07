"""Biome mask shape rules — straight-border DETECTION (mirror of mask_topology.gd).

Fixing is NOT done per tile here (nibbling only turns a line into a broken line).
Shape fixes live in tools/shape_biome_regions.py (region-level warp/smooth).

Definition
----------
An "edge run" is a horizontal/vertical run of one land biome whose perpendicular
side is a different land biome (so it is a border, not interior fill).
Runs on the same row/column, same biome, same side, separated by a gap of
<= STRAIGHT_GAP_MERGE tiles are merged into one collinear chain — this catches
the "dashed line" pattern as well as a solid line.

A chain is a straight border when its extent >= MIN_STRAIGHT_BORDER_LEN.
Chains between MIN_STRAIGHT_REPORT_LEN and MIN_STRAIGHT_BORDER_LEN-1 are
reported as minor.

Why 28: a smooth curve of radius R drawn on a tile grid has axis-aligned flats
about 2*sqrt(R) tiles long (deviation < 0.5 tile). Regions here have R <= ~160
tiles -> flats up to ~25 are geometric necessity (and the 3/4 speck rule forbids
1-tile bumps that would break them). Anything >= 28 cannot come from a smooth
region of this size, so it is a genuinely ruler-straight edge. Measured: the old
wedge-cut swamp had chains of 45-77; shaped regions top out at 25.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

OCEAN = 0
SAVANNA = 1
BEACH = 8

# Base thresholds tuned for 1024x1024 — scaled for higher resolutions.
_BASE_MASK_SIZE = 1024
_BASE_MIN_STRAIGHT_REPORT_LEN = 8
_BASE_MIN_STRAIGHT_BORDER_LEN = 28
_BASE_STRAIGHT_GAP_MERGE = 2
STRAIGHT_BORDER_SKIP_BIOMES = {BEACH}


def scale_straight_thresholds(mask_size: int) -> tuple[int, int, int]:
    """Return (report_len, border_len, gap_merge) scaled for mask resolution."""
    scale = mask_size / _BASE_MASK_SIZE
    return (
        max(2, int(_BASE_MIN_STRAIGHT_REPORT_LEN * scale)),
        max(4, int(_BASE_MIN_STRAIGHT_BORDER_LEN * scale)),
        max(1, int(_BASE_STRAIGHT_GAP_MERGE * scale)),
    )


# Legacy globals for backward compat — code should call scale_straight_thresholds() instead.
MIN_STRAIGHT_REPORT_LEN = _BASE_MIN_STRAIGHT_REPORT_LEN
MIN_STRAIGHT_BORDER_LEN = _BASE_MIN_STRAIGHT_BORDER_LEN
STRAIGHT_GAP_MERGE = _BASE_STRAIGHT_GAP_MERGE


@dataclass
class StraightSegment:
    axis: str  # "h" or "v"
    biome: int
    neighbor: int
    length: int
    row: int
    col: int
    start: int
    end: int


def _land_ids(ids: np.ndarray, is_water: np.ndarray) -> np.ndarray:
    """Land biome id per tile, -1 for ocean/river."""
    land = ids.astype(np.int32).copy()
    land[(ids == OCEAN) | is_water] = -1
    return land


def _edge_runs_1d(line: np.ndarray, side_a: np.ndarray, side_b: np.ndarray) -> list[tuple[int, int, int, int, int]]:
    """Runs (start, end, biome, neighbor, side) along one row/col.

    side_a / side_b are the perpendicular neighbor lines (-1 where off-map/water).
    A run is an edge run if >= len-1 of one side is a *different land biome*.
    """
    n = line.shape[0]
    runs: list[tuple[int, int, int, int, int]] = []
    i = 0
    while i < n:
        b = int(line[i])
        if b < 0 or b in STRAIGHT_BORDER_SKIP_BIOMES:
            i += 1
            continue
        j = i
        while j < n and line[j] == b:
            j += 1
        length = j - i
        if length >= 2:
            for side_idx, side in ((0, side_a), (1, side_b)):
                seg = side[i:j]
                diff = (seg >= 0) & (seg != b)
                if int(diff.sum()) >= length - 1:
                    vals, counts = np.unique(seg[diff], return_counts=True)
                    neighbor = int(vals[int(np.argmax(counts))]) if vals.size else SAVANNA
                    runs.append((i, j - 1, b, neighbor, side_idx))
                    break
        i = j
    return runs


def _merge_chains(runs: list[tuple[int, int, int, int, int]], gap_merge: int = STRAIGHT_GAP_MERGE) -> list[tuple[int, int, int, int]]:
    """Merge collinear runs (same biome + side) separated by small gaps."""
    runs.sort()
    chains: list[tuple[int, int, int, int]] = []
    for start, end, biome, neighbor, side in runs:
        if chains:
            c_start, c_end, c_biome, c_side = chains[-1][0], chains[-1][1], chains[-1][2], chains[-1][3]
            if c_biome == biome and c_side == side and start - c_end - 1 <= gap_merge:
                chains[-1] = (c_start, max(c_end, end), biome, side)
                continue
        chains.append((start, end, biome, side))
    return [(s, e, b, side) for s, e, b, side in chains]


def find_straight_borders(
    ids: np.ndarray, is_water: np.ndarray, min_len: int | None = None, mask_size: int | None = None
) -> list[StraightSegment]:
    """Find straight border segments on the biome mask.

    If mask_size is given, thresholds are scaled automatically for that resolution.
    Otherwise, uses legacy 1024-based constants.
    """
    h, w = ids.shape
    actual_size = mask_size or max(h, w)
    report_len, border_len, gap_merge = scale_straight_thresholds(actual_size)
    if min_len is None:
        min_len = report_len

    land = _land_ids(ids, is_water)
    pad = np.full((h + 2, w + 2), -1, dtype=np.int32)
    pad[1:-1, 1:-1] = land
    segments: list[StraightSegment] = []

    for y in range(h):
        line = pad[y + 1, 1:-1]
        north = pad[y, 1:-1]
        south = pad[y + 2, 1:-1]
        runs = _edge_runs_1d(line, north, south)
        for start, end, biome, side in _merge_chains(runs, gap_merge):
            length = end - start + 1
            if length < min_len:
                continue
            mid = (start + end) // 2
            nb_line = north if side == 0 else south
            nb = int(nb_line[mid]) if nb_line[mid] >= 0 else SAVANNA
            segments.append(StraightSegment("h", biome, nb, length, y, mid, start, end))

    for x in range(w):
        line = pad[1:-1, x + 1]
        west = pad[1:-1, x]
        east = pad[1:-1, x + 2]
        runs = _edge_runs_1d(line, west, east)
        for start, end, biome, side in _merge_chains(runs, gap_merge):
            length = end - start + 1
            if length < min_len:
                continue
            mid = (start + end) // 2
            nb_line = west if side == 0 else east
            nb = int(nb_line[mid]) if nb_line[mid] >= 0 else SAVANNA
            segments.append(StraightSegment("v", biome, nb, length, mid, x, start, end))

    return segments


def count_straight_borders(ids: np.ndarray, is_water: np.ndarray, mask_size: int | None = None) -> int:
    """Count serious straight borders (>= threshold for this mask size)."""
    h = ids.shape[0]
    actual_size = mask_size or h
    _, border_len, _ = scale_straight_thresholds(actual_size)
    segments = find_straight_borders(ids, is_water, min_len=border_len, mask_size=actual_size)
    return sum(1 for seg in segments if seg.length >= border_len)


def format_straight_report(segments: list[StraightSegment], mask_size: int = _BASE_MASK_SIZE, limit: int = 8) -> str:
    """Format a human-readable report of straight borders."""
    report_len, border_len, _ = scale_straight_thresholds(mask_size)
    serious = [s for s in segments if s.length >= border_len]
    minor = len([s for s in segments if report_len <= s.length < border_len])
    longest = max((s.length for s in segments), default=0)
    lines = [
        f"straight_borders={len(serious)} "
        f"(minor_{report_len}_{border_len - 1}={minor}, longest={longest}, threshold={border_len})"
    ]
    serious.sort(key=lambda s: -s.length)
    for seg in serious[:limit]:
        lines.append(
            f"  {seg.axis} biome={seg.biome} len={seg.length} "
            f"row={seg.row} col={seg.col} span={seg.start}-{seg.end} neighbor={seg.neighbor}"
        )
    if len(serious) > limit:
        lines.append(f"  ... +{len(serious) - limit} more")
    return "\n".join(lines)
