#!/usr/bin/env python3
"""Static project health scan — no Godot required.

Finds oversized textures, missing res:// targets, orphan .import files,
and backups folder without .gdignore.

Usage (repo root):
  python3 tools/project_health_scan.py
  python3 tools/project_health_scan.py --json
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    Image = None  # type: ignore

REPO = Path(__file__).resolve().parents[1]
SKIP_DIRS = {".git", ".godot", "node_modules", "__pycache__"}
RES_REF = re.compile(r'res://([^\s"\')\]]+)')
GPU_HARD_MAX = 16384
GPU_WARN_MAX = 8192


@dataclass
class Finding:
    severity: str  # error | warning | info
    category: str
    path: str
    message: str
    fix_hint: str = ""


@dataclass
class ScanReport:
    tool: str = "project_health_scan.py"
    timestamp: str = ""
    findings: list[Finding] = field(default_factory=list)

    def add(self, severity: str, category: str, path: str, message: str, fix_hint: str = "") -> None:
        self.findings.append(Finding(severity, category, path, message, fix_hint))

    def summary(self) -> dict[str, int]:
        out = {"error": 0, "warning": 0, "info": 0}
        for f in self.findings:
            out[f.severity] = out.get(f.severity, 0) + 1
        return out


def iter_files(*suffixes: str) -> list[Path]:
    paths: list[Path] = []
    for root, dirs, files in os.walk(REPO):
        root_path = Path(root)
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        if "backup" in root.lower() and (root_path / ".gdignore").exists():
            dirs.clear()
            continue
        for name in files:
            if name.endswith(suffixes):
                paths.append(root_path / name)
    return paths


def scan_oversized_textures(report: ScanReport) -> None:
    if Image is None:
        report.add("warning", "oversized_texture", "PIL", "Pillow not installed — skip texture size scan", "pip install pillow")
        return
    for path in iter_files(".png", ".jpg", ".jpeg", ".webp"):
        rel = path.relative_to(REPO).as_posix()
        if rel.startswith("backups/"):
            continue
        try:
            w, h = Image.open(path).size
        except OSError:
            report.add("warning", "oversized_texture", rel, "Could not read image")
            continue
        mx = max(w, h)
        if mx > GPU_HARD_MAX:
            report.add(
                "error",
                "oversized_texture",
                rel,
                f"{w}x{h} exceeds GPU hard limit ~{GPU_HARD_MAX}px",
                "Archive or split sprite sheet; add backups/.gdignore if archived in-repo",
            )
        elif mx > GPU_WARN_MAX:
            report.add(
                "warning",
                "oversized_texture",
                rel,
                f"{w}x{h} is large (warn threshold {GPU_WARN_MAX}px)",
                "Consider splitting if this is a sprite sheet",
            )


def scan_res_references(report: ScanReport) -> None:
    refs: dict[str, list[str]] = {}
    for path in iter_files(".gd", ".tscn", ".tres"):
        rel = path.relative_to(REPO).as_posix()
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for m in RES_REF.finditer(text):
            target = m.group(1).split("#")[0].strip()
            if not target or target.endswith((".gd", ".tscn", ".tres", ".png", ".jpg", ".shader", ".gdshader")):
                refs.setdefault(target, []).append(rel)

    for target, sources in sorted(refs.items()):
        full = REPO / target
        if full.exists():
            continue
        # Godot glob patterns — skip
        if "%" in target or "*" in target:
            continue
        report.add(
            "error",
            "missing_resource",
            target,
            f"Referenced by {len(sources)} file(s): {', '.join(sources[:4])}{'...' if len(sources) > 4 else ''}",
            "Restore file, update reference, or archive dead code",
        )


def scan_orphan_imports(report: ScanReport) -> None:
    for imp in iter_files(".import"):
        rel = imp.relative_to(REPO).as_posix()
        if rel.startswith("backups/"):
            continue
        text = imp.read_text(encoding="utf-8", errors="replace")
        m = re.search(r'^source_file="(res://[^"]+)"', text, re.M)
        if not m:
            continue
        src = m.group(1).replace("res://", "")
        if not (REPO / src).exists():
            report.add(
                "warning",
                "orphan_import",
                rel,
                f"source_file missing: {src}",
                "Remove .import or restore source PNG",
            )


def scan_backups_gdignore(report: ScanReport) -> None:
    backups = REPO / "backups"
    if not backups.is_dir():
        return
    if not (backups / ".gdignore").exists():
        report.add(
            "warning",
            "backups",
            "backups/",
            "No .gdignore — Godot will try to import archived PNGs in backups/",
            "Add empty backups/.gdignore",
        )


def scan_island_map(report: ScanReport) -> None:
    meta_path = REPO / "maps/island/island_meta.json"
    if not meta_path.exists():
        report.add("warning", "island_map", "maps/island/island_meta.json", "Missing island meta")
        return
    meta = json.loads(meta_path.read_text())
    mask_size = int(meta.get("mask_size", 0))
    for name in ("biome_mask.png", "water_layer.png"):
        p = REPO / "maps/island" / name
        if not p.exists():
            report.add("error", "island_map", f"maps/island/{name}", "Missing")
            continue
        if Image is None:
            continue
        w, h = Image.open(p).size
        if w != mask_size or h != mask_size:
            report.add(
                "error",
                "island_map",
                f"maps/island/{name}",
                f"Size {w}x{h} != island_meta mask_size {mask_size}",
                "Run bash tools/rebuild_island_biomes.sh",
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--json", action="store_true", help="Print JSON only")
    args = parser.parse_args()

    report = ScanReport(timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    scan_oversized_textures(report)
    scan_res_references(report)
    scan_orphan_imports(report)
    scan_backups_gdignore(report)
    scan_island_map(report)

    payload = {
        "tool": report.tool,
        "timestamp": report.timestamp,
        "summary": report.summary(),
        "findings": [asdict(f) for f in report.findings],
    }

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        s = report.summary()
        print(f"=== project_health_scan {report.timestamp} ===")
        print(f"errors={s['error']} warnings={s['warning']} info={s['info']}")
        for sev in ("error", "warning", "info"):
            items = [f for f in report.findings if f.severity == sev]
            if not items:
                continue
            print(f"\n--- {sev.upper()} ({len(items)}) ---")
            for f in items:
                print(f"[{f.category}] {f.path}")
                print(f"  {f.message}")
                if f.fix_hint:
                    print(f"  fix: {f.fix_hint}")

    return 1 if report.summary()["error"] > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
