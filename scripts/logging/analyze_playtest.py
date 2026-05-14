#!/usr/bin/env python3
"""Analyze playtest JSONL for herd/gather anomalies and optional combat/agro stability.

Strict modes:
  --strict                 Fail on herd invariants (+ optional coverage thresholds).
  --strict-stability      Fail on combat FSM churn, agro ping-pong, or frozen combat probes.
  --strict-clanbrain      Fail on bad hunt_started prey, friendly-fire JSONL markers, optional brain coverage.
  --strict-npc-sim        Fail if AI clans lack gather FSM touches, hunt telemetry, or population growth signals.

See tools/README.md for capture flags (--playtest-capture, --playtest-2min).
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple


def _loads_events(path: Path) -> List[Dict[str, Any]]:
    events: List[Dict[str, Any]] = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return events


COMBAT_TOUCH_STATES = frozenset({"combat", "flee_combat"})
AI_FIGHTER_TYPES = frozenset({"caveman", "clansman"})

# AoH / ClanBrain hunts: PREY-role types only (`NPCConfig.is_ai_hunt_prey_type`; see guides).
DEFAULT_AI_HUNT_PREY_TYPES = frozenset({"deer", "mammoth"})
FORBIDDEN_HUNT_PREY_TYPES = frozenset({"sheep", "goat", "woman"})


def analyze_combat_fsm_churn(
    events: Sequence[Dict[str, Any]],
    window_sec: float,
    max_touches_per_window: int,
    violations_out: List[str],
) -> None:
    """Flag NPCs whose FSM crosses combat/flight too often inside a sliding time window."""
    by_npc: Dict[str, List[Tuple[float, str, str]]] = defaultdict(list)
    for e in events:
        if e.get("evt") != "npc_fsm_transition":
            continue
        npc = str(e.get("npc", "?"))
        t_raw = str(e.get("type", "") or "").strip().lower()
        # Backward compat: old JSONL omitted "type" — still analyze churn when absent.
        if t_raw != "" and t_raw not in AI_FIGHTER_TYPES:
            continue
        frm = str(e.get("from", ""))
        to = str(e.get("to", ""))
        if frm not in COMBAT_TOUCH_STATES and to not in COMBAT_TOUCH_STATES:
            continue
        by_npc[npc].append((float(e.get("t", 0)), frm, to))

    print("\n--- Combat / flee FSM touch rate (fighters only) ---")
    print(
        f"  (window={window_sec:g}s, fail if >{max_touches_per_window} touches involving combat/flee_combat)"
    )

    offenders = 0
    for npc, rows in sorted(by_npc.items(), key=lambda x: x[0]):
        rows.sort(key=lambda r: r[0])
        if not rows:
            continue
        j = 0
        peak = 0
        peak_t = 0.0
        for i, (ti, _, _) in enumerate(rows):
            while j < len(rows) and rows[j][0] - ti <= window_sec:
                j += 1
            cnt = j - i
            if cnt > peak:
                peak = cnt
                peak_t = ti
        if peak > max_touches_per_window:
            offenders += 1
            msg = (
                f"combat_fsm_churn:{npc}:{peak}_touches_in_{window_sec:g}s@"
                f"t={peak_t:.1f} (limit {max_touches_per_window})"
            )
            print(f"  VIOLATION: {npc} peak={peak} at t≈{peak_t:.1f}s")
            violations_out.append(msg)
    if offenders == 0:
        print("  ✓ No fighter exceeded combat/flee churn threshold")


def analyze_agro_pingpong(
    events: Sequence[Dict[str, Any]],
    window_sec: float,
    max_flips_per_window: int,
    violations_out: List[str],
) -> None:
    """Count alternations on agro_threshold_crossed.above_70 per NPC inside sliding windows."""
    by_npc: Dict[str, List[Tuple[float, bool]]] = defaultdict(list)
    for e in events:
        if e.get("evt") != "agro_threshold_crossed":
            continue
        npc = str(e.get("npc", "?"))
        if "above_70" not in e:
            continue
        by_npc[npc].append((float(e.get("t", 0)), bool(e["above_70"])))

    print("\n--- Agro threshold crossings (above vs below hysteresis band) ---")
    print(f"  (window={window_sec:g}s, fail if >{max_flips_per_window} directional flips)")
    offenders = 0
    for npc, rows in sorted(by_npc.items(), key=lambda x: x[0]):
        rows.sort(key=lambda r: r[0])
        if len(rows) < 2:
            continue
        # Build flip timestamps: when consecutive above_70 differs.
        flip_times: List[float] = []
        for idx in range(1, len(rows)):
            if rows[idx][1] != rows[idx - 1][1]:
                flip_times.append(rows[idx][0])

        peak = 0
        peak_t = 0.0
        if flip_times:
            j = 0
            for i, ti in enumerate(flip_times):
                while j < len(flip_times) and flip_times[j] - ti <= window_sec:
                    j += 1
                cnt = j - i
                if cnt > peak:
                    peak = cnt
                    peak_t = ti

        if peak > max_flips_per_window:
            offenders += 1
            msg = (
                f"agro_pingpong:{npc}:{peak}_flips_in_{window_sec:g}s@"
                f"t≈{peak_t:.1f} (limit {max_flips_per_window})"
            )
            print(f"  VIOLATION: {npc} peak directional flips={peak} near t≈{peak_t:.1f}s")
            violations_out.append(msg)
    if offenders == 0:
        print("  ✓ No NPC exceeded agro flip rate threshold")


def analyze_frozen_combat_probes(
    events: Sequence[Dict[str, Any]],
    min_consecutive: int,
    max_vel: float,
    max_target_dist: float,
    violations_out: List[str],
) -> None:
    """Detect caveman/clansman rows in npc_world_probe stuck in combat with target in range but negligible velocity."""
    # name -> chronological probe rows from combat-ish states with ctl_d populated
    by_npc: Dict[str, List[Tuple[float, str, float, Optional[float], bool]]] = defaultdict(list)
    for e in events:
        if e.get("evt") != "npc_world_probe":
            continue
        t_evt = float(e.get("t", 0))
        for row in e.get("npcs", []) or []:
            if not isinstance(row, dict):
                continue
            name = str(row.get("name", ""))
            st = str(row.get("state", ""))
            if st not in COMBAT_TOUCH_STATES:
                continue
            nt = str(row.get("type", "")).strip().lower()
            if nt not in AI_FIGHTER_TYPES:
                continue
            if "ctl_d" not in row or "agro" not in row:
                continue
            v_len = float(row.get("v", 999))
            ctl_d_raw = row.get("ctl_d", -1)
            ctl_d_f: Optional[float] = None
            try:
                if ctl_d_raw is not None and float(ctl_d_raw) >= 0:
                    ctl_d_f = float(ctl_d_raw)
            except (TypeError, ValueError):
                ctl_d_f = None
            c_lock = row.get("c_lock") is True
            by_npc[name].append((t_evt, st, v_len, ctl_d_f, c_lock))

    print("\n--- Frozen combat probes (velocity vs target proximity) ---")
    print(
        f"  (need ≥{min_consecutive} successive snapshots at capture interval, "
        f"v≤{max_vel:g}, ctl_d<{max_target_dist:g}px, excluding windup/recovery locks)"
    )
    offenders = 0
    for npc, timeline in sorted(by_npc.items()):
        timeline.sort(key=lambda x: x[0])
        run = 0
        run_start_t = 0.0
        for t_evt, _, v_len, ctl_d, locked in timeline:
            ok = (
                v_len <= max_vel
                and ctl_d is not None
                and 0 <= ctl_d < max_target_dist
                and not locked
            )
            if ok:
                if run == 0:
                    run_start_t = t_evt
                run += 1
                if run >= min_consecutive:
                    msg = (
                        f"frozen_combat_probe:{npc}:run_{run}_from_t≈{run_start_t:.1f}s "
                        f"(v≤{max_vel:g}, ctl_d<{max_target_dist:g})"
                    )
                    print(f"  VIOLATION: {npc}: {run} consecutive frozen snapshots from t≈{run_start_t:.1f}s")
                    violations_out.append(msg)
                    offenders += 1
                    run = 0
            else:
                run = 0
    if offenders == 0:
        print("  ✓ No frozen combat streak detected (or no ctl_d-enhanced probes in capture)")


def _parse_allowed_hunt_prey(arg: Optional[str]) -> frozenset:
    """Comma-separated prey type names; empty -> DEFAULT_AI_HUNT_PREY_TYPES."""
    if not arg or not arg.strip():
        return DEFAULT_AI_HUNT_PREY_TYPES
    names = frozenset(s.strip().lower() for s in arg.split(",") if s.strip())
    return names if names else DEFAULT_AI_HUNT_PREY_TYPES


def analyze_strict_clanbrain(
    events: Sequence[Dict[str, Any]],
    allowed_hunt_prey: frozenset,
    min_clan_brain_eval_events: int,
    min_quota_update_events: int,
    violations_out: List[str],
) -> None:
    """AoH hunt targets + friendly-fire JSONL gates (ultimate NPC / ClanBrain spec)."""

    hunt_rows = [e for e in events if e.get("evt") == "hunt_started"]

    ff_combat_started = sum(1 for e in events if e.get("evt") == "friendly_fire_combat_started")
    ff_test_fail = sum(1 for e in events if e.get("evt") == "test_failed_friendly_fire")
    ff_hits_rows = sum(1 for e in events if e.get("evt") == "combat_hit" and e.get("friendly_fire") is True)

    brain_eval_ct = sum(1 for e in events if e.get("evt") == "clan_brain_eval")
    quota_up_ct = sum(1 for e in events if e.get("evt") == "clan_brain_quota_update")

    print("\n--- ClanBrain strict (JSONL oracle) ---")
    print(f"  hunt_started rows: {len(hunt_rows)}")
    print(
        "  friendly_fire signals: combat_started="
        f"{ff_combat_started}, combat_hit(ff)={ff_hits_rows}, test_failed="
        f"{ff_test_fail}"
    )
    print(f"  clan_brain_eval: {brain_eval_ct}, clan_brain_quota_update: {quota_up_ct}")

    for e in hunt_rows:
        # Instrumentor writes `prey` (historical specs said prey_type — accept both).
        prey = str(e.get("prey", "") or e.get("prey_type", "") or "").strip().lower()
        clan = e.get("clan", "?")
        if not prey:
            msg = "hunt_started:missing_prey_identifier"
            print(f"  VIOLATION: {msg} clan={clan} row keys={sorted(e.keys())}")
            violations_out.append(msg)
            continue
        if prey in FORBIDDEN_HUNT_PREY_TYPES:
            msg = f"hunt_started:herdable_or_invalid_prey:{prey}"
            print(f"  VIOLATION: {msg} clan={clan}")
            violations_out.append(msg)
        elif prey not in allowed_hunt_prey:
            msg = f"hunt_started:prey_not_in_allowed_set:{prey}"
            print(f"  VIOLATION: {msg} clan={clan} (allowed={sorted(allowed_hunt_prey)})")
            violations_out.append(msg)

    if ff_combat_started > 0:
        violations_out.append(f"friendly_fire:combat_started_events={ff_combat_started}")
        print(f"  VIOLATION: friendly_fire_combat_started ×{ff_combat_started}")
    if ff_hits_rows > 0:
        violations_out.append(f"friendly_fire:combat_hit_rows={ff_hits_rows}")
        print(f"  VIOLATION: combat_hit with friendly_fire ×{ff_hits_rows}")
    if ff_test_fail > 0:
        violations_out.append(f"friendly_fire:test_failed_marker×{ff_test_fail}")
        print(f"  VIOLATION: test_failed_friendly_fire ×{ff_test_fail}")

    if min_clan_brain_eval_events > 0 and brain_eval_ct < min_clan_brain_eval_events:
        msg = f"coverage:clan_brain_eval have={brain_eval_ct} need>={min_clan_brain_eval_events}"
        print(f"  VIOLATION: {msg}")
        violations_out.append(msg)
    if min_quota_update_events > 0 and quota_up_ct < min_quota_update_events:
        msg = f"coverage:clan_brain_quota_update have={quota_up_ct} need>={min_quota_update_events}"
        print(f"  VIOLATION: {msg}")
        violations_out.append(msg)

    clan_brain_violations_only = [
        v
        for v in violations_out
        if v.startswith(("hunt_started", "friendly_fire", "coverage:clan_brain"))
    ]
    if not clan_brain_violations_only:
        print("  ✓ ClanBrain strict thresholds satisfied")


def analyze_strict_npc_sim(
    events: Sequence[Dict[str, Any]],
    session: Optional[Dict[str, Any]],
    *,
    require_npc_only_session: bool,
    min_gather_fsm_touches: int,
    min_hunt_signals: int,
    min_growth_events: int,
    min_session_sec: float,
    violations_out: List[str],
) -> None:
    """Proof that AI clans gather, hunt pipeline runs, and population grows (JSONL oracle).

    Gather: npc_fsm_transition rows for caveman/clansman touching gather state.
    Hunt: hunt_started / hunt_joined / hunt_phase_changed, plus prey (deer/mammoth)
          npc_fsm_transition rows touching flee_prey (pressure from hunters).
    Growth: baby_spawned + baby_grew_to_clansman.
    """

    _mark_start = len(violations_out)

    gather_fsm_touches = 0
    hunt_signals = 0
    growth_events = 0

    prey_types_for_hunt_evidence = frozenset({"deer", "mammoth"})

    for e in events:
        evt = e.get("evt")
        if evt == "npc_fsm_transition":
            t_raw = str(e.get("type", "") or "").strip().lower()
            frm = str(e.get("from", ""))
            to = str(e.get("to", ""))
            if t_raw in AI_FIGHTER_TYPES:
                if "gather" in frm or "gather" in to:
                    gather_fsm_touches += 1
                if "hunt" in frm or "hunt" in to:
                    hunt_signals += 1
            elif t_raw in prey_types_for_hunt_evidence:
                if "flee_prey" in frm or "flee_prey" in to:
                    hunt_signals += 1
        elif evt == "hunt_started":
            hunt_signals += 1
        elif evt in ("hunt_joined", "hunt_phase_changed"):
            hunt_signals += 1
        elif evt in ("baby_spawned", "baby_grew_to_clansman"):
            growth_events += 1

    max_t = max((float(e.get("t", 0)) for e in events), default=0.0)

    print("\n--- NPC world sim strict (AI gather / hunt / growth) ---")
    print(f"  npc_fsm_transition gather touches (caveman/clansman): {gather_fsm_touches}")
    print(
        "  hunt signals (AoH JSONL + fighter hunt FSM + prey flee_prey FSM): "
        f"{hunt_signals}"
    )
    print(f"  growth events (baby spawn/grew): {growth_events}")
    print(f"  max event t: {max_t:.1f}s")

    if require_npc_only_session:
        if session is None or session.get("npc_only_world") is not True:
            msg = "npc_sim:session_missing_npc_only_world_flag"
            print(f"  VIOLATION: {msg}")
            violations_out.append(msg)

    if min_session_sec > 0 and max_t + 1e-6 < min_session_sec:
        msg = f"coverage:npc_sim_session_sec have_max_t={max_t:.1f}s need>={min_session_sec:g}s"
        print(f"  VIOLATION: {msg}")
        violations_out.append(msg)

    if min_gather_fsm_touches > 0 and gather_fsm_touches < min_gather_fsm_touches:
        msg = (
            f"coverage:npc_sim_gather_fsm have={gather_fsm_touches} need>={min_gather_fsm_touches}"
        )
        print(f"  VIOLATION: {msg}")
        violations_out.append(msg)

    if min_hunt_signals > 0 and hunt_signals < min_hunt_signals:
        msg = f"coverage:npc_sim_hunt_signals have={hunt_signals} need>={min_hunt_signals}"
        print(f"  VIOLATION: {msg}")
        violations_out.append(msg)

    if min_growth_events > 0 and growth_events < min_growth_events:
        msg = f"coverage:npc_sim_growth have={growth_events} need>={min_growth_events}"
        print(f"  VIOLATION: {msg}")
        violations_out.append(msg)

    if len(violations_out) == _mark_start:
        print("  ✓ NPC sim strict thresholds satisfied")



def analyze(
    path: Path,
    strict: bool,
    rapid_reenter_sec: float,
    min_herd_wildnpc_enters: int,
    min_session_sec: float,
    *,
    strict_stability: bool = False,
    strict_clanbrain: bool = False,
    allowed_hunt_prey: frozenset = DEFAULT_AI_HUNT_PREY_TYPES,
    min_clanbrain_eval_events: int = 0,
    min_clanbrain_quota_updates: int = 0,
    combat_churn_window_sec: float = 14.0,
    max_combat_touches_window: int = 14,
    agro_flip_window_sec: float = 30.0,
    max_agro_flips_window: int = 14,
    frozen_min_probe_streak: int = 6,
    frozen_max_vel: float = 4.0,
    frozen_max_target_dist: float = 360.0,
    strict_npc_sim: bool = False,
    require_npc_only_session: bool = False,
    min_npc_gather_fsm_touches: int = 1,
    min_npc_hunt_signals: int = 1,
    min_npc_growth_events: int = 1,
    min_npc_sim_session_sec: float = 110.0,
) -> int:
    events = _loads_events(path)
    violations: list[str] = []
    stability_violations: list[str] = []

    print(f"\n=== Playtest Analysis: {path.name} ({len(events)} events) ===\n")

    session = next((e for e in events if e.get("evt") == "session_start"), None)
    if session:
        print(f"Session path: {session.get('path', '?')}")
        if session.get("npc_only_world"):
            print("  npc_only_world: true")
        print()

    # Herd enter/exit flicker: exit -> enter gap under rapid_reenter_sec (matches herd_wildnpc_reentry_cooldown_sec intent)
    herd_enters = defaultdict(list)
    herd_exits = defaultdict(list)
    per_npc_timeline = defaultdict(list)
    for e in events:
        evt = e.get("evt")
        if evt == "herd_wildnpc_enter":
            npc = e.get("npc")
            t = float(e.get("t", 0))
            herd_enters[npc].append(t)
            per_npc_timeline[npc].append((t, "enter"))
        elif evt == "herd_wildnpc_exit":
            npc = e.get("npc")
            t = float(e.get("t", 0))
            herd_exits[npc].append(t)
            per_npc_timeline[npc].append((t, "exit"))

    print("--- Herd enter/exit patterns ---")
    print(f"  (rapid re-enter = exit then enter within {rapid_reenter_sec:g}s)")
    for npc in sorted(set(herd_enters.keys()) | set(herd_exits.keys())):
        enters = herd_enters.get(npc, [])
        exits = herd_exits.get(npc, [])
        timeline = sorted(per_npc_timeline[npc], key=lambda item: item[0])
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
                print(f"    VIOLATION: {i}")
                violations.append(f"herd_flicker:{npc}:{i}")
            if len(issues) > 8:
                extra = len(issues) - 8
                print(f"    ... and {extra} more")
                violations.append(f"herd_flicker:{npc}:+{extra}_more")

    # herd_count_change sanity
    print("\n--- herd_count_change ---")
    herd_count_bad = False
    count_changes = [e for e in events if e.get("evt") == "herd_count_change"]
    for e in count_changes:
        old = int(e.get("old", -1))
        new = int(e.get("new", -1))
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

    if not herd_count_bad:
        if not count_changes:
            print("  (no herd_count_change events — session may be too short or no herding)")
        else:
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
            rejects[str(e.get("reason", "?"))] += 1
    for reason, count in sorted(rejects.items(), key=lambda x: -x[1]):
        print(f"  {reason}: {count}")

    print("\n--- Herd influence activity ---")
    influence_entered = len([e for e in events if e.get("evt") == "herd_influence_entered"])
    influence_transfer = len([e for e in events if e.get("evt") == "herd_influence_transfer"])
    influence_contested = len([e for e in events if e.get("evt") == "herd_influence_contested"])
    print(f"  entered: {influence_entered}, transfer: {influence_transfer}, contested: {influence_contested}")

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

    # ─── Combat/agro stability (always printed; strict only when --strict-stability) ───
    analyze_combat_fsm_churn(events, combat_churn_window_sec, max_combat_touches_window, stability_violations)
    analyze_agro_pingpong(events, agro_flip_window_sec, max_agro_flips_window, stability_violations)
    analyze_frozen_combat_probes(
        events,
        frozen_min_probe_streak,
        frozen_max_vel,
        frozen_max_target_dist,
        stability_violations,
    )

    print("\n=== Done ===\n")

    herd_all_fail = violations + coverage_failures
    if strict and herd_all_fail:
        print(f"STRICT HERD FAIL: {len(herd_all_fail)} issue(s)")
        for v in herd_all_fail:
            print(f"  - {v}")
    elif strict:
        print("STRICT HERD OK: no herd invariant or coverage failures")

    exit_code = 0
    if strict and herd_all_fail:
        exit_code = 1

    if strict_stability and stability_violations:
        print(f"STRICT STABILITY FAIL: {len(stability_violations)} issue(s)")
        for v in stability_violations:
            print(f"  - {v}")
        exit_code = max(exit_code, 1)

    elif strict_stability:
        print("STRICT STABILITY OK: combat/agro anomaly thresholds satisfied")

    clanbrain_violations: list[str] = []
    if strict_clanbrain:
        analyze_strict_clanbrain(
            events,
            allowed_hunt_prey,
            min_clanbrain_eval_events,
            min_clanbrain_quota_updates,
            clanbrain_violations,
        )
        if clanbrain_violations:
            print(f"STRICT CLANBRAIN FAIL: {len(clanbrain_violations)} issue(s)")
            for v in clanbrain_violations:
                print(f"  - {v}")
            exit_code = max(exit_code, 1)
        else:
            print("STRICT CLANBRAIN OK")

    npc_sim_violations: list[str] = []
    if strict_npc_sim:
        analyze_strict_npc_sim(
            events,
            session,
            require_npc_only_session=require_npc_only_session,
            min_gather_fsm_touches=min_npc_gather_fsm_touches,
            min_hunt_signals=min_npc_hunt_signals,
            min_growth_events=min_npc_growth_events,
            min_session_sec=min_npc_sim_session_sec,
            violations_out=npc_sim_violations,
        )
        if npc_sim_violations:
            print(f"STRICT NPC SIM FAIL: {len(npc_sim_violations)} issue(s)")
            for v in npc_sim_violations:
                print(f"  - {v}")
            exit_code = max(exit_code, 1)
        else:
            print("STRICT NPC SIM OK")

    return exit_code


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("jsonl", nargs="?", help="Path to playtest_session.jsonl")
    ap.add_argument(
        "--strict",
        action="store_true",
        help="Exit 1 if herd_count_change or herd flicker violations found",
    )
    ap.add_argument(
        "--strict-stability",
        action="store_true",
        help="Exit 1 if combat churn, agro ping-pong, or frozen combat probe streak exceeds thresholds",
    )
    ap.add_argument(
        "--strict-clanbrain",
        action="store_true",
        help="Exit 1 on invalid AoH hunt JSONL prey, friendly-fire hits, optional clan_brain eval/quota thresholds",
    )
    ap.add_argument(
        "--strict-npc-sim",
        action="store_true",
        help="Exit 1 if AI gather/hunt/growth JSONL signals fall below thresholds (use with --npc-only-world captures)",
    )
    ap.add_argument(
        "--require-npc-only-session",
        action="store_true",
        help="With --strict-npc-sim: require session_start.npc_only_world == true",
    )
    ap.add_argument(
        "--min-npc-gather-fsm",
        type=int,
        default=1,
        metavar="N",
        help="With --strict-npc-sim: min npc_fsm_transition rows touching gather for caveman/clansman",
    )
    ap.add_argument(
        "--min-npc-hunt-signals",
        type=int,
        default=1,
        metavar="N",
        help=(
            "With --strict-npc-sim: min hunt-related signals "
            "(hunt_started/joined/phase + fighter hunt FSM + deer/mammoth flee_prey FSM)"
        ),
    )
    ap.add_argument(
        "--min-npc-growth-events",
        type=int,
        default=1,
        metavar="N",
        help="With --strict-npc-sim: min baby_spawned+baby_grew_to_clansman rows",
    )
    ap.add_argument(
        "--min-npc-session-sec",
        type=float,
        default=110.0,
        metavar="SEC",
        help="With --strict-npc-sim: fail if max JSONL t < SEC (0 = off). Default 110 for ~120s playtests.",
    )
    ap.add_argument(
        "--allowed-ai-hunt-prey",
        type=str,
        default="",
        metavar="LIST",
        help="Comma-separated allowlist for hunt_started (default deer,mammoth). Use with --strict-clanbrain.",
    )
    ap.add_argument(
        "--min-clanbrain-eval-events",
        type=int,
        default=0,
        metavar="N",
        help="With --strict-clanbrain: require at least N clan_brain_eval events (0 = off)",
    )
    ap.add_argument(
        "--min-clanbrain-quota-updates",
        type=int,
        default=0,
        metavar="N",
        help="With --strict-clanbrain: require at least N clan_brain_quota_update rows (0 = off)",
    )
    ap.add_argument(
        "--rapid-reenter-sec",
        type=float,
        default=1.5,
        metavar="SEC",
        help="Max exit->enter gap (seconds) still counted as flicker (default 1.5)",
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
        help="With --strict: exit 1 if max event t is below SEC (0 = disabled)",
    )
    ap.add_argument("--combat-churn-window", type=float, default=14.0, help="Sliding window (sec) for FSM churn")
    ap.add_argument(
        "--max-combat-touches-window",
        type=int,
        default=14,
        metavar="N",
        help="Max combat/flee FSM transitions involving combat per NPC inside window",
    )
    ap.add_argument("--agro-flip-window", type=float, default=30.0, help="Sliding window for agro threshold directional flips")
    ap.add_argument(
        "--max-agro-flips-window",
        type=int,
        default=14,
        metavar="N",
        help="Max agro hysteresis crossings (direction reversals) per NPC per window",
    )
    ap.add_argument(
        "--frozen-probe-streak",
        type=int,
        default=6,
        help="Violate if NPC has this many successive combat probes with negligible motion",
    )
    ap.add_argument("--frozen-max-vel", type=float, default=4.0, help="Frozen if reported velocity length <= this")
    ap.add_argument(
        "--frozen-max-target-dist",
        type=float,
        default=360.0,
        help="Frozen check only counts if combat_target distance px is below this and non-negative",
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
            print("Usage: python analyze_playtest.py [options] <path/to/playtest_*.jsonl>")
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

    allowed_hp = _parse_allowed_hunt_prey(args.allowed_ai_hunt_prey)

    sys.exit(
        analyze(
            path,
            args.strict,
            args.rapid_reenter_sec,
            args.min_herd_wildnpc_enters,
            args.min_session_sec,
            strict_stability=args.strict_stability,
            strict_clanbrain=args.strict_clanbrain,
            allowed_hunt_prey=allowed_hp,
            min_clanbrain_eval_events=args.min_clanbrain_eval_events,
            min_clanbrain_quota_updates=args.min_clanbrain_quota_updates,
            combat_churn_window_sec=args.combat_churn_window,
            max_combat_touches_window=args.max_combat_touches_window,
            agro_flip_window_sec=args.agro_flip_window,
            max_agro_flips_window=args.max_agro_flips_window,
            frozen_min_probe_streak=args.frozen_probe_streak,
            frozen_max_vel=args.frozen_max_vel,
            frozen_max_target_dist=args.frozen_max_target_dist,
            strict_npc_sim=args.strict_npc_sim,
            require_npc_only_session=args.require_npc_only_session,
            min_npc_gather_fsm_touches=args.min_npc_gather_fsm,
            min_npc_hunt_signals=args.min_npc_hunt_signals,
            min_npc_growth_events=args.min_npc_growth_events,
            min_npc_sim_session_sec=args.min_npc_session_sec,
        )
    )


if __name__ == "__main__":
    main()
