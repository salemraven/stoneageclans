#!/usr/bin/env python3
"""Build tile rivers from painted guide marks, then replace water_layer.png.

Default mode (--replace): your paint is a guide only — fresh 2-tile-wide rivers
are generated and the old paint is removed. Guides are kept in water_layer_guides.png.

Legacy mode (--keep-paint): widen paint in place (old behavior).

Runs topology cleanup (3+ / 4-side rules) after writing.
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from generate_river_paths import (  # noqa: E402
    AUTHORING_MIN_WIDTH,
    enrich_painted_rivers,
    rebuild_rivers_from_guides,
)

OCEAN = 0
DEFAULT_MASK = REPO / "maps/island/biome_mask.png"
DEFAULT_WATER = REPO / "maps/island/water_layer.png"
DEFAULT_GUIDES = REPO / "maps/island/water_layer_guides.png"


def ids_from_mask(arr: np.ndarray) -> np.ndarray:
    return np.rint(arr.astype(np.float32) / 255.0 * 9.0).astype(np.int32)


def load_land(mask_path: Path) -> np.ndarray:
    ids = ids_from_mask(np.array(Image.open(mask_path)))
    return ids != OCEAN


def backup_water(water_path: Path, label: str) -> Path:
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = REPO / "backups" / f"water_layer_{label}_{stamp}.png"
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(water_path, dest)
    return dest


def ensure_guides(guide_path: Path, water_path: Path) -> Path:
    """Persist hand-painted marks so rebuilds always use the same guide."""
    if guide_path.exists():
        return guide_path
    if not water_path.exists():
        raise SystemExit(f"Missing guide source: {water_path}")
    guide_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(water_path, guide_path)
    return guide_path


def run_topology_clean(mask_path: Path, water_path: Path) -> None:
    script = REPO / "tools/clean_biome_mask_specks.py"
    subprocess.run(
        [sys.executable, str(script), "--mask", str(mask_path), "--water", str(water_path)],
        cwd=REPO,
        check=True,
    )


def load_painted(path: Path) -> np.ndarray:
    arr = np.array(Image.open(path))
    if arr.ndim == 3:
        arr = arr[:, :, 0]
    return arr > 127


def process_file(
    mask_path: Path,
    guide_path: Path,
    water_path: Path,
    seed: int,
    main_width: int,
    tributaries_per_main: int,
    replace: bool,
    dry_run: bool,
) -> dict:
    land = load_land(mask_path)
    painted = load_painted(guide_path)
    main_width = max(AUTHORING_MIN_WIDTH, main_width)

    if replace:
        river, stats = rebuild_rivers_from_guides(
            land,
            painted,
            seed=seed,
            main_width=main_width,
            tributary_width=AUTHORING_MIN_WIDTH,
            tributaries_per_main=tributaries_per_main,
        )
    else:
        river, stats = enrich_painted_rivers(
            land,
            painted,
            seed=seed,
            main_width=main_width,
            tributaries_per_main=tributaries_per_main,
        )

    if dry_run:
        stats["dry_run"] = True
        stats["guide_path"] = str(guide_path.relative_to(REPO))
        return stats

    backup = backup_water(water_path, "before_rebuild" if replace else "before_enrich")
    stats["backup"] = str(backup.relative_to(REPO))
    stats["guide_path"] = str(guide_path.relative_to(REPO))

    out = np.where(river, 255, 0).astype(np.uint8)
    Image.fromarray(out).save(water_path)
    run_topology_clean(mask_path, water_path)
    return stats


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mask", default=str(DEFAULT_MASK))
    parser.add_argument("--water", default=str(DEFAULT_WATER))
    parser.add_argument(
        "--guides",
        default=str(DEFAULT_GUIDES),
        help="Hand-painted guide marks (saved once, reused)",
    )
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--main-width",
        type=int,
        default=AUTHORING_MIN_WIDTH,
        help=f"Minimum {AUTHORING_MIN_WIDTH} tiles (drought can shrink to 1 in-game)",
    )
    parser.add_argument("--tributaries", type=int, default=4, help="Per main river system")
    parser.add_argument(
        "--keep-paint",
        action="store_true",
        help="Legacy: widen painted pixels instead of replacing them",
    )
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    mask_path = Path(args.mask)
    water_path = Path(args.water)
    guide_path = Path(args.guides)

    if not args.keep_paint:
        # First run: copy current water (or backup) into guides if guides missing
        if not guide_path.exists():
            fallback = REPO / "backups/water_layer_before_enrich_20260906_233411.png"
            source = fallback if fallback.exists() else water_path
            shutil.copy2(source, guide_path)
            print(f"saved guides -> {guide_path.relative_to(REPO)}")
        guide_path = ensure_guides(guide_path, guide_path)
    else:
        guide_path = water_path

    stats = process_file(
        mask_path,
        guide_path,
        water_path,
        seed=args.seed,
        main_width=args.main_width,
        tributaries_per_main=args.tributaries,
        replace=not args.keep_paint,
        dry_run=args.dry_run,
    )

    if stats.get("replaced_guides"):
        print(
            f"rebuilt from guides: systems={stats['main_systems']} "
            f"tributaries={stats['tributaries_added']} "
            f"guide_px={stats.get('guide_pixels', '?')} -> river_px={stats['pixels_after']}"
        )
    else:
        print(
            f"main systems={stats['main_systems']} widened={stats.get('widened_paths', 0)} "
            f"tributaries={stats['tributaries_added']} "
            f"water px {stats.get('pixels_before', '?')} -> {stats['pixels_after']}"
        )
    if stats.get("backup"):
        print(f"backup: {stats['backup']}")
    print(f"guides: {stats.get('guide_path', guide_path)}")
    if stats.get("dry_run"):
        print("(dry run — no files written)")


if __name__ == "__main__":
    main()
