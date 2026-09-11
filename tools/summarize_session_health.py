#!/usr/bin/env python3
"""Roll up playtest JSONL + Godot console into a health report.

Usage:
  python3 tools/summarize_session_health.py <playtest_session.jsonl|dir> [godot.log]
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path


def _load_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict):
            rows.append(obj)
    return rows


def _pick_jsonl(arg: Path) -> Path:
    if arg.is_file():
        return arg
    for name in ("playtest_session.jsonl",):
        cand = arg / name
        if cand.is_file():
            return cand
    found = sorted(arg.glob("*.jsonl"))
    if not found:
        raise SystemExit(f"No jsonl in {arg}")
    return found[-1]


def _pick_log(arg: Path, extra: Path | None) -> Path | None:
    if extra and extra.is_file():
        return extra
    if arg.is_dir():
        for name in ("godot.log",):
            cand = arg / name
            if cand.is_file():
                return cand
        logs = sorted(arg.glob("*.log"))
        return logs[-1] if logs else None
    sibling = arg.with_name("godot.log")
    return sibling if sibling.is_file() else None


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: summarize_session_health.py <jsonl|dir> [godot.log]", file=sys.stderr)
        return 2
    arg = Path(sys.argv[1])
    extra = Path(sys.argv[2]) if len(sys.argv) > 2 else None
    jsonl = _pick_jsonl(arg)
    log_path = _pick_log(arg if arg.is_dir() else arg.parent, extra)
    rows = _load_jsonl(jsonl)

    evts = Counter(str(r.get("evt", "?")) for r in rows)
    last_health = None
    for r in rows:
        if r.get("evt") == "repro_health":
            last_health = r
    gate_by_npc: dict[str, str] = {}
    gate_codes = Counter()
    for r in rows:
        if r.get("evt") != "repro_gate":
            continue
        npc = str(r.get("npc", "?"))
        code = str(r.get("code", "?"))
        gate_by_npc[npc] = code
        gate_codes[code] += 1

    births = [r for r in rows if r.get("evt") in ("baby_spawned", "settlement_birth")]
    cancelled = [r for r in rows if r.get("evt") in ("baby_pregnancy_cancelled", "settlement_pregnancy_cancelled")]
    blocked = [r for r in rows if r.get("evt") in ("baby_pregnancy_blocked", "settlement_birth_blocked")]
    started = [r for r in rows if r.get("evt") in ("settlement_pregnancy_started",)]

    print("=== SESSION HEALTH ===")
    print(f"jsonl: {jsonl}")
    if log_path:
        print(f"log:   {log_path}")
    print(f"events: {sum(evts.values())} rows, {len(evts)} types")
    interesting = (
        "session_start",
        "repro_health",
        "repro_gate",
        "baby_spawned",
        "baby_pregnancy_cancelled",
        "baby_pregnancy_blocked",
        "settlement_pregnancy_started",
        "settlement_birth",
        "clan_brain_eval",
        "snapshot",
        "test_run_ended_2min",
    )
    for k in interesting:
        if evts[k]:
            print(f"  {k}: {evts[k]}")

    print("\n--- Reproduction (last world snapshot) ---")
    if last_health:
        print(
            f"women={last_health.get('women')} clan_women={last_health.get('clan_women')} "
            f"pregnant={last_health.get('pregnant')}"
        )
        print(f"codes: {json.dumps(last_health.get('codes', {}), sort_keys=True)}")
        samples = last_health.get("blocked_samples") or []
        if samples:
            print("blocked samples:")
            for s in samples[:12]:
                print(
                    f"  {s.get('npc')} clan={s.get('clan')} {s.get('code')} "
                    f"hut={s.get('hut')} in_claim={s.get('in_claim')} "
                    f"food={s.get('food_items')}/{s.get('food_days')} father={s.get('father')}"
                )
    else:
        print("(no repro_health rows — capture may be too short)")

    last_codes = Counter(gate_by_npc.values())
    print("\n--- Last known per-woman gate ---")
    print(dict(last_codes))
    print(f"pregnancies started (settlement): {len(started)}")
    print(f"births logged: {len(births)}")
    print(f"pregnancy cancelled: {len(cancelled)}")
    print(f"pregnancy blocked events: {len(blocked)}")
    if cancelled:
        reasons = Counter(str(r.get("reason", "?")) for r in cancelled)
        print(f"cancel reasons: {dict(reasons)}")
    if blocked:
        reasons = Counter(str(r.get("reason", "?")) for r in blocked)
        print(f"block reasons: {dict(reasons)}")

    print("\n--- Godot console ---")
    if not log_path:
        print("(no godot.log)")
        return 0
    text = log_path.read_text(encoding="utf-8", errors="replace")
    errors = [ln for ln in text.splitlines() if ln.startswith("ERROR:")]
    warns = [ln for ln in text.splitlines() if ln.startswith("WARNING:")]
    print(f"ERROR lines: {len(errors)}")
    err_kinds = Counter()
    for ln in errors:
        err_kinds[ln[:120]] += 1
    for ln, c in err_kinds.most_common(8):
        print(f"  [{c}] {ln}")
    print(f"WARNING lines: {len(warns)}")
    warn_kinds = Counter()
    for ln in warns:
        warn_kinds[ln[:120]] += 1
    for ln, c in warn_kinds.most_common(8):
        print(f"  [{c}] {ln}")

    overlap = text.count("Can't find overlapping bodies when monitoring is off")
    lineage = text.count("BABY LINEAGE")
    repro_health_lines = text.count("REPRO_HEALTH")
    print(f"overlap-monitor errors: {overlap}")
    print(f"BABY LINEAGE warnings: {lineage}")
    print(f"REPRO_HEALTH prints: {repro_health_lines}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
