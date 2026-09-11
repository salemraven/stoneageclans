#!/usr/bin/env python3
"""Summarize Tests/logs/front_tick.jsonl or front_metrics_run.jsonl."""
from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path


def load(path: Path) -> list[dict]:
    rows = []
    if not path.exists():
        return rows
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return rows


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "Tests/logs/front_metrics_run.jsonl"
    rows = load(path)
    if not rows:
        print("no rows", path)
        return 1
    by = defaultdict(list)
    for r in rows:
        by[str(r.get("phase") or (r.get("events") or ["?"])[0] if r.get("events") else "?")].append(r)
    print("file", path, "n", len(rows))
    for phase, rs in by.items():
        ice_int = [float(r.get("new_ice_interior_frac") or 0) for r in rs if int(r.get("new_ice") or 0) >= 16]
        ice_mar = [float(r.get("new_ice_margin_frac") or 0) for r in rs if int(r.get("new_ice") or 0) >= 16]
        pops = [float(r.get("new_ice_share") or 0) for r in rs] + [float(r.get("new_dry_share") or 0) for r in rs]
        des_rd = [float(r.get("new_des_mean_rd") or 0) for r in rs if int(r.get("new_des") or 0) >= 8]
        print(
            f"  {phase}: days={len(rs)} ice_interior_frac_mean={_mean(ice_int):.3f} "
            f"ice_margin_frac_mean={_mean(ice_mar):.3f} max_share={max(pops) if pops else 0:.4f} "
            f"des_rd {_mean(des_rd[:3]):.3f}->{_mean(des_rd[-3:]):.3f}"
        )
    return 0


def _mean(xs: list[float]) -> float:
    return sum(xs) / len(xs) if xs else 0.0


if __name__ == "__main__":
    raise SystemExit(main())
