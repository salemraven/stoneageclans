#!/usr/bin/env python3
"""Measure river continuity in a biome mask PNG."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image

BIOME_RIVER = 7


@dataclass
class RiverConnectivityReport:
    river_pixels: int
    component_count: int
    largest_component: int
    largest_pct: float
    components_ge_100: int
    tiny_fragments_lt_20: int
    component_sizes: list[int]

    def passes(self, min_largest_pct: float = 95.0, max_components_ge_100: int = 8, max_tiny: int = 0) -> bool:
        return (
            self.largest_pct >= min_largest_pct
            and self.components_ge_100 <= max_components_ge_100
            and self.tiny_fragments_lt_20 <= max_tiny
        )

    def summary(self) -> str:
        return (
            f"rivers={self.river_pixels} components={self.component_count} "
            f"largest={self.largest_component} ({self.largest_pct:.1f}%) "
            f"medium(>=100px)={self.components_ge_100} tiny(<20px)={self.tiny_fragments_lt_20}"
        )


def mask_to_ids(mask: np.ndarray) -> np.ndarray:
    return np.rint(mask.astype(np.float32) / 255.0 * 9.0).astype(np.int32)


def analyze_river_connectivity(mask: np.ndarray) -> RiverConnectivityReport:
    ids = mask_to_ids(mask) if mask.ndim == 2 else mask
    river = ids == BIOME_RIVER
    h, w = river.shape
    seen = np.zeros_like(river, dtype=bool)
    sizes: list[int] = []

    for y in range(h):
        for x in range(w):
            if not river[y, x] or seen[y, x]:
                continue
            q: deque[tuple[int, int]] = deque([(x, y)])
            seen[y, x] = True
            count = 0
            while q:
                cx, cy = q.popleft()
                count += 1
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and river[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            q.append((nx, ny))
            sizes.append(count)

    sizes.sort(reverse=True)
    total = int(river.sum())
    largest = sizes[0] if sizes else 0
    largest_pct = (100.0 * largest / total) if total else 0.0
    return RiverConnectivityReport(
        river_pixels=total,
        component_count=len(sizes),
        largest_component=largest,
        largest_pct=largest_pct,
        components_ge_100=sum(1 for s in sizes if s >= 100),
        tiny_fragments_lt_20=sum(1 for s in sizes if s < 20),
        component_sizes=sizes,
    )


def load_report(path: Path) -> RiverConnectivityReport:
    mask = np.array(Image.open(path))
    return analyze_river_connectivity(mask)


def main() -> int:
    import argparse
    import json

    parser = argparse.ArgumentParser(description="Verify river connectivity in biome_mask.png")
    parser.add_argument("--mask", default="maps/island/biome_mask.png")
    parser.add_argument("--min-largest-pct", type=float, default=95.0)
    parser.add_argument("--max-medium-components", type=int, default=8)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[1]
    mask_path = repo / args.mask
    if not mask_path.exists():
        print(f"ERROR: mask not found: {mask_path}")
        return 1

    report = load_report(mask_path)
    ok = report.passes(args.min_largest_pct, args.max_medium_components)

    if args.json:
        print(
            json.dumps(
                {
                    "ok": ok,
                    "summary": report.summary(),
                    "component_sizes_top10": report.component_sizes[:10],
                },
                indent=2,
            )
        )
    else:
        print(report.summary())
        print("PASS" if ok else "FAIL")
        if not ok:
            print("Top component sizes:", report.component_sizes[:12])

    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
