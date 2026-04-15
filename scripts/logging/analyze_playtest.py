#!/usr/bin/env python3
"""Analyze playtest JSONL for herd/gather anomalies. Use --strict for CI (exit 1 on violations)."""
import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Optional


def analyze(
    path: Path,
    strict: bool,
    rapid_reenter_sec: float,
    min_herd_wildnpc_enters: int,
    min_session_sec: float,
) -> int:
    events = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                pass

    violations: list[str] = []

    print(f"\n=== Playtest Analysis: {path.name} ({len(events)} events) ===\n")

    session = next((e for e in events if e.get("evt") == "session_start"), None)
    if session:
        print(f"Session path: {session.get('path', '?')}\n")

    # Herd enter/exit flicker: exit -> enter gap under rapid_reenter_sec (matches herd_wildnpc_reentry_cooldown_sec intent)
    herd_enters = defaultdict(list)
    herd_exits = defaultdict(list)
    per_npc_timeline = defaultdict(list)
    for e in events:
        evt = e.get("evt")
        if evt == "herd_wildnpc_enter":
            npc = e.get("npc")
            t = e.get("t", 0)
            herd_enters[npc].append(t)
            per_npc_timeline[npc].append((t, "enter"))
        elif evt == "herd_wildnpc_exit":
            npc = e.get("npc")
            t = e.get("t", 0)
            herd_exits[npc].append(t)
            per_npc_timeline[npc].append((t, "exit"))

    print("--- Herd enter/exit patterns ---")
    print(f"  (rapid re-enter = exit then enter within {rapid_reenter_sec:g}s)")
    for npc in sorted(set(herd_enters.keys()) | set(herd_exits.keys())):
        enters = herd_enters.get(npc, [])
        exits = herd_exits.get(npc, [])
        timeline = per_npc_timeline[npc]
        issues: list[str] = []
        last_exit_t: Optional[float] = None
        for t, kind in timeline:
            if kind == "exit":
                last_exit_t = t
            else:
                if last_exit_t is not None and 0 < (t - last_exit_t) < rapid_reenter_sec:
                    dt = t - last_exit_t
                    issues.append(
                        f"rapid re-enter {dt:.2f}s after exit at t={t:.1f} (threshold {rapid_reenter_sec:g}s)"
                    )
                last_exit_t = None
        if len(enters) > 2 or len(exits) > 2 or issues:
            print(f"  {npc}: enters={len(enters)}, exits={len(exits)}")
            for i in issues[:8]:
                msg = f"herd_flicker:{npc}:{i}"
                print(f"    VIOLATION: {i}")
                violations.append(msg)
            if len(issues) > 8:
                extra = len(issues) - 8
                print(f"    ... and {extra} more")
                violations.append(f"herd_flicker:{npc}:+{extra}_more")

    # herd_count_change sanity
    print("\n--- herd_count_change ---")
    count_changes = [e for e in events if e.get("evt") == "herd_count_change"]
    herd_count_bad = False
    for e in count_changes:
        old, new = e.get("old", -1), e.get("new", -1)
        cause = e.get("cause", "?")
        if cause == "attach" and new != old + 1:
            herd_count_bad = True
            msg = f"herd_count:{e.get('npc')}:attach expected new=old+1 got old={old} new={new}"
            print(f"  VIOLATION: {e.get('npc')}: attach but new({new}) != old({old})+1")
            violations.append(msg)
        elif cause == "switch_away" and new != old - 1:
            herd_count_bad = True
            msg = f"herd_count:{e.get('npc')}:switch_away expected new=old-1 got old={old} new={new}"
            print(f"  VIOLATION: {e.get('npc')}: switch_away but new({new}) != old({old})-1")
            violations.append(msg)
        elif cause == "clear_herd" and new != old - 1 and old > 0:
            herd_count_bad = True
            msg = f"herd_count:{e.get('npc')}:clear_herd expected new=old-1 got old={old} new={new}"
            print(f"  VIOLATION: {e.get('npc')}: clear_herd but new({new}) != old({old})-1")
            violations.append(msg)

    if not count_changes:
        print("  (no herd_count_change events — session may be too short or no herding)")
    elif not herd_count_bad:
        print("  ✓ Count changes look consistent")

    print("\n--- Snapshots ---")
    snapshots = [e for e in events if e.get("evt") == "snapshot"]
    if snapshots:
        last = snapshots[-1]
        print(
            f"  Last snapshot @ t={last.get('t', 0):.1f}s: "
            f"herders={last.get('in_herd_wildnpc', 0)}, "
            f"herdable_wild={last.get('herdable_wild', 0)}, "
            f"total_herded={last.get('total_herded_count', 0)}"
        )
    else:
        print("  (no snapshots)")

    print("\n--- herd_wildnpc_can_enter rejections ---")
    rejects = defaultdict(int)
    for e in events:
        if e.get("evt") == "herd_wildnpc_can_enter" and e.get("result") is False:
            rejects[e.get("reason", "?")] += 1
    for reason, count in sorted(rejects.items(), key=lambda x: -x[1]):
        print(f"  {reason}: {count}")

    print("\n--- Herd influence activity ---")
    influence_entered = len([e for e in events if e.get("evt") == "herd_influence_entered"])
    influence_transfer = len([e for e in events if e.get("evt") == "herd_influence_transfer"])
    influence_contested = len([e for e in events if e.get("evt") == "herd_influence_contested"])
    print(f"  entered: {influence_entered}, transfer: {influence_transfer}, contested: {influence_contested}")

    # Optional coverage gates (when min_* > 0): fail strict if capture is too thin to prove herd activity
    herd_enter_total = len([e for e in events if e.get("evt") == "herd_wildnpc_enter"])
    max_t = max((float(e.get("t", 0)) for e in events), default=0.0)
    print("\n--- Coverage (herd session density) ---")
    print(f"  herd_wildnpc_enter count: {herd_enter_total}, max t: {max_t:.1f}s")

    coverage_failures: list[str] = []
    if min_herd_wildnpc_enters > 0 and herd_enter_total < min_herd_wildnpc_enters:
        msg = (
            f"coverage:min_herd_wildnpc_enters have={herd_enter_total} need>={min_herd_wildnpc_enters}"
        )
        print(f"  COVERAGE FAIL: {msg}")
        coverage_failures.append(msg)
    if min_session_sec > 0 and max_t < min_session_sec:
        msg = f"coverage:min_session_sec have_max_t={max_t:.1f}s need>={min_session_sec:g}s"
        print(f"  COVERAGE FAIL: {msg}")
        coverage_failures.append(msg)
    if min_herd_wildnpc_enters <= 0 and min_session_sec <= 0:
        print("  (no min thresholds — use --min-herd-wildnpc-enters / --min-session-sec for strict herd proof)")
    elif not coverage_failures:
        print("  ✓ Coverage thresholds satisfied")

    print("\n=== Done ===\n")

    all_fail = violations + coverage_failures
    if strict and all_fail:
        print(f"STRICT FAIL: {len(all_fail)} issue(s)")
        for v in all_fail:
            print(f"  - {v}")
        return 1
    if strict and not all_fail:
        print("STRICT OK: no herd invariant or coverage failures")
    return 0


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("jsonl", nargs="?", help="Path to playtest_session.jsonl")
    ap.add_argument(
        "--strict",
        action="store_true",
        help="Exit 1 if herd_count_change or herd flicker violations found",
    )
    ap.add_argument(
        "--rapid-reenter-sec",
        type=float,
        default=1.5,
        metavar="SEC",
        help="Max exit->enter gap (seconds) still counted as flicker (default 1.5, align with NPCConfig.herd_wildnpc_reentry_cooldown_sec)",
    )
    ap.add_argument(
        "--min-herd-wildnpc-enters",
        type=int,
        default=0,
        metavar="N",
        help="With --strict: exit 1 if fewer than N herd_wildnpc_enter events (0 = disabled)",
    )
    ap.add_argument(
        "--min-session-sec",
        type=float,
        default=0.0,
        metavar="SEC",
        help="With --strict: exit 1 if max event t is below SEC (0 = disabled); approximates capture length",
    )
    args = ap.parse_args()

    if args.jsonl:
        path = Path(args.jsonl)
    else:
        import platform

        if platform.system() == "Windows":
            base = Path.home() / "AppData/Roaming/Godot/app_userdata/StoneAgeClans"
        else:
            base = Path.home() / "Library/Application Support/Godot/app_userdata/StoneAgeClans"
        if not base.exists():
            print("Usage: python analyze_playtest.py [--strict] <path/to/playtest_*.jsonl>")
            print(f"Default path not found: {base}")
            sys.exit(1)
        files = sorted(base.glob("playtest_*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
        if not files:
            print(f"No playtest_*.jsonl found in {base}")
            sys.exit(1)
        path = files[0]
        print(f"Using latest: {path}")

    if not path.exists():
        print(f"File not found: {path}")
        sys.exit(1)

    sys.exit(
        analyze(
            path,
            args.strict,
            args.rapid_reenter_sec,
            args.min_herd_wildnpc_enters,
            args.min_session_sec,
        )
    )


if __name__ == "__main__":
    main()
