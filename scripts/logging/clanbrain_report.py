#!/usr/bin/env python3
"""Standard ClanBrain markdown report from playtest_session.jsonl.

Usage:
  python3 scripts/logging/clanbrain_report.py path/to/playtest_session.jsonl
  python3 scripts/logging/clanbrain_report.py path/to/playtest_session.jsonl -o report.md
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

BUILDING_TYPE_NAMES: dict[int, str] = {
    16: "Living Hut",
    17: "Supply Hut",
    18: "Shrine",
    19: "Dairy Farm",
    20: "Farm",
    21: "Oven",
    28: "Campfire",
}

FIGHTER_TYPES = frozenset({"caveman", "clansman"})
NOISE_GATHER_FAILS = frozenset({"inventory_full"})


def load_events(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    with path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return events


def fmt_t(sec: float | int | None) -> str:
    if sec is None:
        return "—"
    return f"{float(sec):.1f}s"


def fmt_pct(ratio: float | None, digits: int = 0) -> str:
    if ratio is None:
        return "—"
    return f"{ratio * 100:.{digits}f}%"


def fmt_ratio(num: int, den: int) -> str:
    if den <= 0:
        return "—"
    return f"{num}/{den}"


def fmt_kcal(val: Any) -> str:
    try:
        n = int(val)
    except (TypeError, ValueError):
        return "—"
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1000:
        return f"{n / 1000:.1f}k"
    return str(n)


def building_label(ev: dict[str, Any]) -> str:
    name = ev.get("building")
    if name:
        return str(name)
    bt = ev.get("building_type")
    if bt is not None:
        return BUILDING_TYPE_NAMES.get(int(bt), f"type_{bt}")
    return "Unknown"


def add_item_counts(dst: dict[str, int], items: dict[str, Any]) -> None:
    if not isinstance(items, dict):
        return
    for key, val in items.items():
        try:
            dst[str(key)] = dst.get(str(key), 0) + int(val)
        except (TypeError, ValueError):
            continue


def normalize_building_event(ev: dict[str, Any]) -> dict[str, Any]:
    return {
        "t": ev.get("t", 0.0),
        "clan": str(ev.get("clan", "?")),
        "building": building_label(ev),
        "source": str(ev.get("source", ev.get("evt", "?"))),
        "builder": str(ev.get("builder", "")),
        "x": ev.get("x"),
        "y": ev.get("y"),
    }


def safe_float(val: Any, default: float = 0.0) -> float:
    try:
        return float(val)
    except (TypeError, ValueError):
        return default


def compute_quota_stats(rows: list[dict[str, Any]]) -> dict[str, Any]:
    def_acc = 0.0
    def_n = 0
    def_under = 0
    search_acc = 0.0
    search_n = 0
    search_under = 0
    search_under_no_breed = 0
    search_no_breed_n = 0
    alert_sec: dict[str, float] = defaultdict(float)

    prev_t = safe_float(rows[0].get("t")) if rows else 0.0
    prev_alert = str(rows[0].get("alert_level", "NONE")) if rows else "NONE"

    for ev in rows:
        t = safe_float(ev.get("t"))
        dt = max(0.0, t - prev_t)
        if prev_alert != "NONE":
            alert_sec[prev_alert] += dt

        dq = int(ev.get("defender_quota", 0) or 0)
        dc = int(ev.get("defender_count", 0) or 0)
        sq = int(ev.get("searcher_quota", 0) or 0)
        sc = int(ev.get("searcher_count", 0) or 0)
        breeding = int(ev.get("breeding_females", 0) or 0)

        if dq > 0:
            def_n += 1
            def_acc += min(dc / dq, 1.0)
            if dc < dq:
                def_under += 1
        if sq > 0:
            search_n += 1
            search_acc += min(sc / sq, 1.0)
            if sc < sq:
                search_under += 1
            if breeding == 0:
                search_no_breed_n += 1
                if sc < sq:
                    search_under_no_breed += 1

        prev_t = t
        prev_alert = str(ev.get("alert_level", "NONE"))

    return {
        "defender_fill": def_acc / def_n if def_n else None,
        "defender_underfill_pct": def_under / def_n if def_n else None,
        "searcher_fill": search_acc / search_n if search_n else None,
        "searcher_underfill_pct": search_under / search_n if search_n else None,
        "searcher_underfill_no_breed_pct": search_under_no_breed / search_no_breed_n if search_no_breed_n else None,
        "alert_sec": dict(alert_sec),
    }


def compute_food_buffer(rows: list[dict[str, Any]]) -> dict[str, float | None]:
    vals = [safe_float(ev.get("food_days_buffer")) for ev in rows]
    if not vals:
        return {"min": None, "max": None, "end": None}
    return {"min": min(vals), "max": max(vals), "end": vals[-1]}


def compute_scalar_stats(rows: list[dict[str, Any]], key: str) -> dict[str, float | None]:
    vals: list[float] = []
    for ev in rows:
        if key not in ev:
            continue
        vals.append(safe_float(ev.get(key)))
    if not vals:
        return {"min": None, "max": None, "end": None, "count": 0}
    return {"min": min(vals), "max": max(vals), "end": vals[-1], "count": len(vals)}


def compute_calorie_buffer(rows: list[dict[str, Any]]) -> dict[str, float | None]:
    vals: list[float] = []
    for ev in rows:
        if "calories_days_buffer" in ev:
            vals.append(safe_float(ev.get("calories_days_buffer")))
        elif "food_days_buffer" in ev:
            vals.append(safe_float(ev.get("food_days_buffer")))
    if not vals:
        return {"min": None, "max": None, "end": None}
    return {"min": min(vals), "max": max(vals), "end": vals[-1]}


def evals_have_calorie_fields(rows: list[dict[str, Any]]) -> bool:
    return any("calories_in_storage" in ev for ev in rows)


def compute_survival_seconds(rows: list[dict[str, Any]], max_t: float) -> float:
    if not rows:
        return 0.0
    total = 0.0
    prev_t = safe_float(rows[0].get("t"))
    prev_on = bool(rows[0].get("survival_mode", False))
    for ev in rows[1:]:
        t = safe_float(ev.get("t"))
        if prev_on:
            total += max(0.0, t - prev_t)
        prev_t = t
        prev_on = bool(ev.get("survival_mode", False))
    if prev_on:
        total += max(0.0, max_t - prev_t)
    return total


def compute_fsm_dwell(
    transitions: list[dict[str, Any]],
    max_t: float,
) -> dict[str, dict[str, float]]:
    """Return npc -> {state: seconds}. Uses `from` state for each interval."""
    by_npc: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for tr in transitions:
        by_npc[str(tr.get("npc", "?"))].append(tr)

    dwell: dict[str, dict[str, float]] = {}
    for npc, rows in by_npc.items():
        rows_sorted = sorted(rows, key=lambda e: safe_float(e.get("t")))
        states: dict[str, float] = defaultdict(float)
        if not rows_sorted:
            continue
        prev_t = safe_float(rows_sorted[0].get("t"))
        for i, ev in enumerate(rows_sorted):
            t = safe_float(ev.get("t"))
            nxt = safe_float(rows_sorted[i + 1].get("t")) if i + 1 < len(rows_sorted) else max_t
            state = str(ev.get("to", "unknown"))
            states[state] += max(0.0, nxt - t)
            prev_t = t
        dwell[npc] = dict(states)
    return dwell


def top_states(states: dict[str, float], limit: int = 3) -> str:
    if not states:
        return "—"
    total = sum(states.values()) or 1.0
    parts = []
    for name, sec in sorted(states.items(), key=lambda x: -x[1])[:limit]:
        parts.append(f"{name} {sec / total * 100:.0f}%")
    return ", ".join(parts)


def actionable_gather_fails(fails: dict[str, int]) -> int:
    return sum(v for k, v in fails.items() if k not in NOISE_GATHER_FAILS and not k.startswith("empty_switch:"))


class ReportData:
    def __init__(self, events: list[dict[str, Any]]) -> None:
        self.events = events
        self.session: dict[str, Any] = {}
        self.max_t = 0.0
        self.evals: dict[str, list[dict]] = defaultdict(list)
        self.hunts_started: dict[str, list[dict]] = defaultdict(list)
        self.hunts_done: dict[str, list[dict]] = defaultdict(list)
        self.parties_formed: list[dict] = []
        self.parties_disbanded: list[dict] = []
        self.baby_growth: dict[str, list[dict]] = defaultdict(list)
        self.baby_spawned: dict[str, list[dict]] = defaultdict(list)
        self.npc_joined: dict[str, list[dict]] = defaultdict(list)
        self.invariants: list[dict] = []
        self.quota_updates: dict[str, int] = defaultdict(int)
        self.gathered: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.gathered_npc: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.deposited: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.gather_fails: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.deposit_fails: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.deposit_trips: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.buildings: list[dict[str, Any]] = []
        self.hunt_prey_killed: dict[str, int] = defaultdict(int)
        self.hunt_prey_escaped: dict[str, int] = defaultdict(int)
        self.hunt_deposits: dict[str, int] = defaultdict(int)
        self.hunt_deposit_items: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.hunt_butcher_complete: dict[str, int] = defaultdict(int)
        self.survival_changes: dict[str, list[dict]] = defaultdict(list)
        self.fsm_transitions: list[dict] = []
        self.npc_types: dict[str, str] = {}
        self.npc_clans: dict[str, str] = {}
        self.task_ok: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.task_fail: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        self.task_ok_npc: dict[str, int] = defaultdict(int)
        self.task_fail_npc: dict[str, int] = defaultdict(int)
        self.gather_no_resource: dict[str, int] = defaultdict(int)
        self.stuck_escapes: dict[str, int] = defaultdict(int)
        self.has_building_placed = False
        self.simulation_ticks: list[dict[str, Any]] = []
        self.productivity_reports: dict[str, list[dict]] = defaultdict(list)
        self._parse()

    def _parse(self) -> None:
        self.has_building_placed = any(ev.get("evt") == "building_placed" for ev in self.events)
        for ev in self.events:
            t = safe_float(ev.get("t"))
            self.max_t = max(self.max_t, t)
            evt = ev.get("evt", "")
            clan = str(ev.get("clan", "")) or "?"

            if evt == "session_start":
                self.session = ev
            elif evt == "clan_brain_eval":
                c = str(ev.get("clan", "?"))
                if not ev.get("player_owned"):
                    self.evals[c].append(ev)
            elif evt == "hunt_started":
                self.hunts_started[str(ev.get("clan", "?"))].append(ev)
            elif evt in ("hunt_completed", "hunt_aborted"):
                self.hunts_done[str(ev.get("clan", "?"))].append(ev)
            elif evt == "hunt_prey_killed":
                self.hunt_prey_killed[str(ev.get("clan", "?"))] += 1
            elif evt == "hunt_prey_escaped":
                self.hunt_prey_escaped[str(ev.get("clan", "?"))] += 1
            elif evt == "hunt_deposit":
                npc = str(ev.get("npc", ""))
                c = str(ev.get("clan", "")) or self.npc_clans.get(npc, "?")
                self.hunt_deposits[c] += 1
                skip = {"evt", "t", "npc", "hunt_units", "clan", "items_deposited", "items"}
                if isinstance(ev.get("items"), dict):
                    add_item_counts(self.hunt_deposit_items[c], ev["items"])
                elif isinstance(ev.get("items_deposited"), dict):
                    add_item_counts(self.hunt_deposit_items[c], ev["items_deposited"])
                else:
                    for k, v in ev.items():
                        if k not in skip:
                            try:
                                self.hunt_deposit_items[c][str(k)] += int(v)
                            except (TypeError, ValueError):
                                pass
            elif evt == "hunt_butcher_complete":
                c = self.npc_clans.get(str(ev.get("npc", "")), "?")
                if c != "?":
                    self.hunt_butcher_complete[c] += 1
            elif evt == "party_formed":
                self.parties_formed.append(ev)
            elif evt == "party_disbanded":
                self.parties_disbanded.append(ev)
            elif evt == "baby_grew_to_clansman":
                self.baby_growth[str(ev.get("clan", "?"))].append(ev)
            elif evt == "baby_spawned":
                self.baby_spawned[str(ev.get("clan", "?"))].append(ev)
            elif evt == "npc_joined_clan":
                self.npc_joined[str(ev.get("clan", "?"))].append(ev)
            elif evt == "survival_mode_changed":
                self.survival_changes[str(ev.get("clan", "?"))].append(ev)
            elif evt == "clan_brain_invariant_failed":
                self.invariants.append(ev)
            elif evt == "clan_brain_quota_update":
                self.quota_updates[str(ev.get("clan", "?"))] += 1
            elif evt == "gather_completed":
                resource = str(ev.get("resource", f"type_{ev.get('resource_type', '?')}"))
                amount = int(ev.get("amount", 0))
                self.gathered[clan][resource] += amount
                npc = str(ev.get("npc", "?"))
                self.gathered_npc[npc][resource] += amount
            elif evt == "gather_failed":
                self.gather_fails[clan][str(ev.get("reason", "unknown"))] += 1
            elif evt == "gather_empty_switch":
                reason = f"empty_switch:{ev.get('reason', 'unknown')}"
                empty_clan = str(ev.get("clan", "")) or "?"
                self.gather_fails[empty_clan][reason] += 1
            elif evt == "deposit_completed":
                add_item_counts(self.deposited[clan], ev.get("items", {}))
                npc = str(ev.get("npc", "?"))
                self.deposit_trips[clan][npc] = self.deposit_trips[clan].get(npc, 0) + 1
            elif evt == "deposit_failed":
                self.deposit_fails[clan][str(ev.get("reason", "unknown"))] += 1
            elif evt == "building_placed":
                self.buildings.append(normalize_building_event(ev))
            elif not self.has_building_placed and evt in ("milestone_building_placed", "campfire_building_built"):
                row = normalize_building_event(ev)
                row["source"] = evt.replace("_", " ")
                self.buildings.append(row)
            elif evt == "npc_fsm_transition":
                self.fsm_transitions.append(ev)
                npc = str(ev.get("npc", "?"))
                self.npc_types[npc] = str(ev.get("type", self.npc_types.get(npc, "?")))
                self.npc_clans[npc] = str(ev.get("clan", self.npc_clans.get(npc, "?")))
            elif evt == "task_completed":
                npc = str(ev.get("npc", "?"))
                self.task_ok[clan][str(ev.get("task_type", "?"))] += 1
                self.task_ok_npc[npc] += 1
                self.npc_clans[npc] = clan
            elif evt == "task_failed":
                npc = str(ev.get("npc", "?"))
                self.task_fail[clan][str(ev.get("task_type", "?"))] += 1
                self.task_fail_npc[npc] += 1
                self.npc_clans[npc] = clan
            elif evt == "gather_no_resource":
                self.gather_no_resource[clan] += 1
            elif evt == "npc_stuck_state_escaped":
                c = str(ev.get("clan", "")) or self.npc_clans.get(str(ev.get("npc", "")), "?")
                self.stuck_escapes[c] += 1
            elif evt == "simulation_tick":
                self.simulation_ticks.append(ev)
            elif evt == "productivity_report":
                self.productivity_reports[str(ev.get("clan", "?"))].append(ev)

    @property
    def ai_clans(self) -> list[str]:
        return sorted(self.evals.keys())

    def clan_gather_total(self, c: str) -> int:
        return sum(self.gathered.get(c, {}).values())

    def clan_deposit_total(self, c: str) -> int:
        return sum(self.deposited.get(c, {}).values())

    def clan_gather_fail_total(self, c: str) -> int:
        return sum(self.gather_fails.get(c, {}).values())

    def clan_deposit_fail_total(self, c: str) -> int:
        return sum(self.deposit_fails.get(c, {}).values())

    def clan_building_count(self, c: str) -> int:
        return sum(1 for b in self.buildings if b["clan"] == c)

    def hunt_completed_count(self, c: str) -> int:
        return sum(1 for h in self.hunts_done.get(c, []) if h.get("evt") == "hunt_completed")

    def hunt_aborted_count(self, c: str) -> int:
        return sum(1 for h in self.hunts_done.get(c, []) if h.get("evt") == "hunt_aborted")

    def task_stats(self, c: str) -> tuple[int, int]:
        ok = sum(self.task_ok.get(c, {}).values())
        fail = sum(self.task_fail.get(c, {}).values())
        return ok, fail

    def fighters_for_clan(self, c: str) -> list[str]:
        names = [n for n, cl in self.npc_clans.items() if cl == c and self.npc_types.get(n, "") in FIGHTER_TYPES]
        return sorted(set(names))

    def fsm_dwell_for_clan(self, c: str) -> dict[str, float]:
        fighters = set(self.fighters_for_clan(c))
        trs = [t for t in self.fsm_transitions if str(t.get("npc")) in fighters]
        dwell = compute_fsm_dwell(trs, self.max_t)
        merged: dict[str, float] = defaultdict(float)
        for states in dwell.values():
            for st, sec in states.items():
                merged[st] += sec
        return dict(merged)

    def render(self, jsonl_path: Path) -> str:
        lines: list[str] = []
        stuck_parties = max(0, len(self.parties_formed) - len(self.parties_disbanded))

        lines.extend(["# ClanBrain Report (standard)", ""])
        lines.extend(["## Session", ""])
        lines.append(f"- **Duration:** {fmt_t(self.max_t)}")
        lines.append(f"- **JSONL:** `{jsonl_path}`")
        if self.session.get("world_seed") is not None:
            lines.append(f"- **World seed:** {self.session.get('world_seed')}")
        if self.session.get("npc_only_world"):
            lines.append("- **NPC-only world:** yes")
        if self.session.get("playtest_30min"):
            lines.append("- **Timed run:** 30 min")
        elif self.session.get("playtest_10min") or any(
            ev.get("evt") == "test_run_ended_10min" for ev in self.events
        ):
            lines.append("- **Timed run:** 10 min")
        elif self.session.get("playtest_5min"):
            lines.append("- **Timed run:** 5 min")
        elif self.session.get("playtest_2min") or any(
            ev.get("evt") == "test_run_ended_2min" for ev in self.events
        ):
            lines.append("- **Timed run:** 2 min")
        lines.append(f"- **AI clans with eval:** {len(self.ai_clans)}")
        if self.simulation_ticks:
            lines.append(f"- **Simulation ticks:** {len(self.simulation_ticks)}")
            last_tick = self.simulation_ticks[-1]
            if last_tick.get("ticks_per_sim_day") is not None:
                lines.append(
                    f"- **Sim tick interval:** {last_tick.get('tick_interval_seconds', '?')}s "
                    f"({last_tick.get('ticks_per_sim_day', '?')} ticks/sim-day)"
                )
        calorie_eval_clans = sum(1 for c in self.ai_clans if evals_have_calorie_fields(self.evals[c]))
        if self.ai_clans:
            lines.append(
                f"- **Calorie eval coverage:** {calorie_eval_clans}/{len(self.ai_clans)} clans "
                f"({fmt_pct(calorie_eval_clans / len(self.ai_clans)) if self.ai_clans else '—'})"
            )
        lines.append("")

        # Summary
        lines.extend(["## Summary", ""])
        lines.append(
            "| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | "
            "Quota fill | Surv | Clansmen | Bld | 1st hunt |"
        )
        lines.append(
            "|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|"
            "------------|------|----------|-----|----------|"
        )
        for clan in self.ai_clans:
            rows = self.evals[clan]
            first, last = rows[0], rows[-1]
            pop = f"{int(first.get('clan_members', 0))}→{int(last.get('clan_members', 0))}"
            fight = int(last.get("cavemen", 0))
            kcal_store = fmt_kcal(last.get("calories_in_storage"))
            kcal_need = fmt_kcal(last.get("calories_daily_need"))
            cal_buf = last.get("calories_days_buffer", last.get("food_days_buffer", "—"))
            if isinstance(cal_buf, (int, float)):
                cal_buf = f"{float(cal_buf):.1f}"
            n_hunt = len(self.hunts_started.get(clan, []))
            hunt_ok = self.hunt_completed_count(clan)
            qs = compute_quota_stats(rows)
            fill = qs["defender_fill"]
            if qs["searcher_fill"] is not None:
                if fill is None:
                    fill = qs["searcher_fill"]
                else:
                    fill = (fill + qs["searcher_fill"]) / 2
            surv = compute_survival_seconds(rows, self.max_t)
            n_grown = len(self.baby_growth.get(clan, []))
            g_fail = actionable_gather_fails(self.gather_fails.get(clan, {}))
            first_hunt = fmt_t(self.hunts_started[clan][0]["t"]) if self.hunts_started.get(clan) else "—"
            lines.append(
                f"| {clan} | {pop} | {fight} | {kcal_store} | {kcal_need} | {cal_buf} | {n_hunt} | {hunt_ok} | "
                f"{self.clan_gather_total(clan)} | {self.clan_deposit_total(clan)} | {g_fail} | "
                f"{fmt_pct(fill)} | {fmt_t(surv)} | {n_grown} | {self.clan_building_count(clan)} | {first_hunt} |"
            )
        lines.append("")
        lines.append(
            "*G fail* = gather failures excluding `inventory_full` noise. "
            "**Cal buffer** = stored kcal ÷ daily need (days of food). "
            "Legacy logs without calorie fields show `—` for kcal columns."
        )
        lines.append("")

        # Gates
        lines.extend(["## Gates", ""])
        lines.append(f"- **ClanBrain invariant failures:** {len(self.invariants)}")
        lines.append(f"- **Parties formed / disbanded:** {len(self.parties_formed)} / {len(self.parties_disbanded)}")
        if self.ai_clans and calorie_eval_clans < len(self.ai_clans):
            lines.append(
                f"- **⚠ Calorie metrics missing:** {len(self.ai_clans) - calorie_eval_clans} clan(s) "
                f"have eval rows without `calories_in_storage` (re-run capture after calorie system update)"
            )
        if stuck_parties > 0:
            lines.append(f"- **⚠ Possible stuck parties (formed − disbanded):** {stuck_parties}")
        else:
            lines.append("- **Stuck parties (rough):** 0")
        lines.append("")

        # ClanBrain health
        lines.extend(["## ClanBrain health", ""])
        lines.append(
            "| Clan | Def fill | Def under | Search fill | Search under (no breed) | "
            "Kcal store min→max→end | Cal buffer min→max→end | Survival |"
        )
        lines.append(
            "|------|----------|-----------|-------------|-------------------------|"
            "------------------------|------------------------|----------|"
        )
        for clan in self.ai_clans:
            rows = self.evals[clan]
            qs = compute_quota_stats(rows)
            cb = compute_calorie_buffer(rows)
            kcal_stats = compute_scalar_stats(rows, "calories_in_storage")
            surv = compute_survival_seconds(rows, self.max_t)
            kcal_str = "—"
            if kcal_stats["min"] is not None:
                kcal_str = (
                    f"{fmt_kcal(kcal_stats['min'])}→{fmt_kcal(kcal_stats['max'])}→"
                    f"{fmt_kcal(kcal_stats['end'])}"
                )
            cal_str = "—"
            if cb["min"] is not None:
                cal_str = f"{cb['min']:.1f}→{cb['max']:.1f}→{cb['end']:.1f}"
            lines.append(
                f"| {clan} | {fmt_pct(qs['defender_fill'])} | {fmt_pct(qs['defender_underfill_pct'])} | "
                f"{fmt_pct(qs['searcher_fill'])} | {fmt_pct(qs['searcher_underfill_no_breed_pct'])} | "
                f"{kcal_str} | {cal_str} | {fmt_t(surv)} |"
            )
        lines.append("")

        lines.extend(["### Hunt lifecycle", ""])
        lines.append("| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |")
        lines.append("|------|---------|-----------|---------|-------------|--------------|---------------|--------------|")
        for clan in self.ai_clans:
            lines.append(
                f"| {clan} | {len(self.hunts_started.get(clan, []))} | {self.hunt_completed_count(clan)} | "
                f"{self.hunt_aborted_count(clan)} | {self.hunt_prey_killed.get(clan, 0)} | "
                f"{self.hunt_prey_escaped.get(clan, 0)} | {self.hunt_deposits.get(clan, 0)} | "
                f"{self.hunt_butcher_complete.get(clan, 0)} |"
            )
        lines.append("")

        lines.extend(["### Breeding pipeline", ""])
        lines.append("| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |")
        lines.append("|------|--------------|----------------|----------------|--------------|")
        for clan in self.ai_clans:
            women = sum(1 for e in self.npc_joined.get(clan, []) if str(e.get("type", "")) == "woman")
            babies = len(self.baby_spawned.get(clan, []))
            grown = len(self.baby_growth.get(clan, []))
            first_g = fmt_t(self.baby_growth[clan][0]["t"]) if self.baby_growth.get(clan) else "—"
            lines.append(f"| {clan} | {women} | {babies} | {grown} | {first_g} |")
        lines.append("")

        # Worker efficiency
        lines.extend(["## Worker efficiency", ""])
        lines.append("| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |")
        lines.append("|------|----------|------------|-----------|---------------|---------------|---------------------|")
        for clan in self.ai_clans:
            ok, fail = self.task_stats(clan)
            rate = ok / (ok + fail) if (ok + fail) > 0 else None
            fsm = self.fsm_dwell_for_clan(clan)
            lines.append(
                f"| {clan} | {ok} | {fail} | {fmt_pct(rate)} | {self.gather_no_resource.get(clan, 0)} | "
                f"{self.stuck_escapes.get(clan, 0)} | {top_states(fsm)} |"
            )
        lines.append("")

        # Economy (session)
        session_gathered: dict[str, int] = defaultdict(int)
        session_deposited: dict[str, int] = defaultdict(int)
        for clan in self.ai_clans:
            for res, amt in self.gathered.get(clan, {}).items():
                session_gathered[res] += amt
            for res, amt in self.deposited.get(clan, {}).items():
                session_deposited[res] += amt

        lines.extend(["## Economy (session)", ""])
        g_total = sum(session_gathered.values())
        d_total = sum(session_deposited.values())
        lines.append(f"- **Items gathered:** {g_total}")
        lines.append(f"- **Items deposited:** {d_total}")
        if g_total > 0:
            lines.append(f"- **Deposit yield:** {fmt_pct(d_total / g_total)}")
        lines.append(f"- **Gather failures (all):** {sum(sum(v.values()) for v in self.gather_fails.values())}")
        lines.append(
            f"- **Gather failures (actionable):** "
            f"{sum(actionable_gather_fails(v) for v in self.gather_fails.values())}"
        )
        lines.append(f"- **Deposit failures:** {sum(sum(v.values()) for v in self.deposit_fails.values())}")
        lines.append("")

        session_gf_actionable: dict[str, int] = defaultdict(int)
        for fails in self.gather_fails.values():
            for reason, count in fails.items():
                if reason not in NOISE_GATHER_FAILS:
                    session_gf_actionable[reason] += count
        if session_gf_actionable:
            lines.extend(["### Gather failures (actionable)", ""])
            for reason, count in sorted(session_gf_actionable.items(), key=lambda x: (-x[1], x[0])):
                lines.append(f"- **{reason}:** {count}")
            lines.append("")

        all_resources = sorted(set(session_gathered.keys()) | set(session_deposited.keys()))
        if all_resources:
            lines.extend(["### Items by resource", "", "| Resource | Gathered | Deposited | Yield |", "|----------|----------|-----------|-------|"])
            for res in all_resources:
                g = session_gathered.get(res, 0)
                d = session_deposited.get(res, 0)
                y = fmt_pct(d / g) if g > 0 else "—"
                lines.append(f"| {res} | {g} | {d} | {y} |")
            lines.append("")

        # Buildings
        lines.extend(["## Buildings (session)", ""])
        lines.append(f"- **Total placed:** {len(self.buildings)}")
        if self.buildings:
            by_type: dict[str, int] = defaultdict(int)
            by_source: dict[str, int] = defaultdict(int)
            for b in self.buildings:
                by_type[b["building"]] += 1
                by_source[b["source"]] += 1
            lines.append("")
            for label, bucket in (("By type", by_type), ("By source", by_source)):
                lines.append(f"### {label}")
                lines.append("")
                for name, count in sorted(bucket.items(), key=lambda x: (-x[1], x[0])):
                    lines.append(f"- **{name}:** {count}")
                lines.append("")
            lines.append("### Chronological")
            lines.append("")
            for b in sorted(self.buildings, key=lambda x: safe_float(x.get("t"))):
                builder = f" builder={b['builder']}" if b.get("builder") else ""
                pos = ""
                if b.get("x") is not None and b.get("y") is not None:
                    pos = f" @ ({float(b['x']):.0f},{float(b['y']):.0f})"
                lines.append(
                    f"- t={fmt_t(b.get('t'))} **{b['clan']}** — {b['building']} ({b['source']}){builder}{pos}"
                )
            lines.append("")

        # Per-clan detail
        lines.extend(["## Per-clan detail", ""])
        for clan in self.ai_clans:
            rows = self.evals[clan]
            last = rows[-1]
            qs = compute_quota_stats(rows)
            fb = compute_food_buffer(rows)
            lines.append(f"### {clan}")
            lines.append("")
            lines.append(
                f"- **Brain:** {last.get('strategic_state', '?')} | alert {last.get('alert_level', '?')} | "
                f"hunt {last.get('hunt_state', '?')} | raid {last.get('raid_state', '?')} | "
                f"survival {last.get('survival_mode', '?')}"
            )
            lines.append(
                f"- **Quotas (end):** defenders {last.get('defender_count', '?')}/{last.get('defender_quota', '?')} "
                f"({fmt_pct(qs['defender_fill'])} fill) | searchers {last.get('searcher_count', '?')}/"
                f"{last.get('searcher_quota', '?')} ({fmt_pct(qs['searcher_fill'])} fill)"
            )
            lines.append(
                f"- **Pressure:** defend {last.get('defend_pressure', '?')} | search {last.get('search_pressure', '?')} | "
                f"gather {last.get('gather_pressure', '?')}"
            )
            if fb["end"] is not None:
                lines.append(f"- **Food days buffer:** {fb['min']:.1f} → {fb['max']:.1f} → {fb['end']:.1f}")
            cb = compute_calorie_buffer(rows)
            kcal_stats = compute_scalar_stats(rows, "calories_in_storage")
            need_stats = compute_scalar_stats(rows, "calories_daily_need")
            if kcal_stats["count"] > 0:
                lines.append(
                    f"- **Calories in storage:** {fmt_kcal(kcal_stats['min'])} → "
                    f"{fmt_kcal(kcal_stats['max'])} → {fmt_kcal(kcal_stats['end'])}"
                )
            if need_stats["count"] > 0 and need_stats["end"] is not None:
                lines.append(f"- **Daily calorie need (end):** {fmt_kcal(need_stats['end'])}")
            if cb["end"] is not None:
                lines.append(
                    f"- **Calorie days buffer:** {cb['min']:.1f} → {cb['max']:.1f} → {cb['end']:.1f}"
                )
            prod_rows = self.productivity_reports.get(clan, [])
            if prod_rows:
                last_prod = prod_rows[-1]
                lines.append(
                    f"- **Productivity (end):** food_rate={last_prod.get('food_rate', '?')}/s | "
                    f"herd_rate={last_prod.get('herd_rate', '?')}/s"
                )

            g_items = self.gathered.get(clan, {})
            d_items = self.deposited.get(clan, {})
            if g_items or d_items:
                lines.extend(["", "#### Economy", "", "| Resource | Gathered | Deposited |", "|----------|----------|-----------|"])
                for res in sorted(set(g_items.keys()) | set(d_items.keys())):
                    lines.append(f"| {res} | {g_items.get(res, 0)} | {d_items.get(res, 0)} |")

            gf = self.gather_fails.get(clan, {})
            df = self.deposit_fails.get(clan, {})
            if gf or df:
                lines.extend(["", "#### Failures", ""])
                if gf:
                    lines.append(
                        "- **Gather:** "
                        + ", ".join(f"{k}={v}" for k, v in sorted(gf.items(), key=lambda x: (-x[1], x[0])))
                    )
                if df:
                    lines.append(
                        "- **Deposit:** "
                        + ", ".join(f"{k}={v}" for k, v in sorted(df.items(), key=lambda x: (-x[1], x[0])))
                    )

            fighters = self.fighters_for_clan(clan)
            if fighters:
                lines.extend(
                    [
                        "",
                        "#### Fighter roster",
                        "",
                        "| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |",
                        "|-----|----------|------|----------|----------|------------|",
                    ]
                )
                trs = [t for t in self.fsm_transitions if str(t.get("npc")) in fighters]
                dwell_all = compute_fsm_dwell(trs, self.max_t)
                for npc in fighters:
                    ok_n = self.task_ok_npc.get(npc, 0)
                    fail_n = self.task_fail_npc.get(npc, 0)
                    deps = self.deposit_trips.get(clan, {}).get(npc, 0)
                    gath = sum(self.gathered_npc.get(npc, {}).values())
                    states = top_states(dwell_all.get(npc, {}))
                    lines.append(f"| {npc} | {ok_n} | {fail_n} | {deps} | {gath} | {states} |")

            if self.hunts_started.get(clan):
                lines.extend(["", "#### Hunts", ""])
                for h in self.hunts_started[clan]:
                    lines.append(
                        f"- start t={fmt_t(h.get('t'))} prey={h.get('prey', h.get('prey_type', '?'))} "
                        f"quota={h.get('quota', h.get('hunter_quota', '?'))}"
                    )
                for h in self.hunts_done.get(clan, []):
                    lines.append(
                        f"- {h.get('evt')} t={fmt_t(h.get('t'))} reason={h.get('reason', '?')}"
                    )

            clan_buildings = [b for b in self.buildings if b["clan"] == clan]
            if clan_buildings:
                lines.extend(["", "#### Buildings", ""])
                for b in sorted(clan_buildings, key=lambda x: safe_float(x.get("t"))):
                    builder = f" (builder: {b['builder']})" if b.get("builder") else ""
                    lines.append(f"- t={fmt_t(b.get('t'))} **{b['building']}** — {b['source']}{builder}")

            lines.append("")

        if self.invariants:
            lines.extend(["## Invariant failures", ""])
            for inv in self.invariants:
                lines.append(f"- t={fmt_t(inv.get('t'))} **{inv.get('clan', '?')}:** {inv.get('message', '?')}")
            lines.append("")

        return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Standard ClanBrain markdown report from JSONL")
    parser.add_argument("jsonl", type=Path, help="playtest_session.jsonl path")
    parser.add_argument("-o", "--output", type=Path, help="Write markdown here (default stdout)")
    args = parser.parse_args()

    if not args.jsonl.is_file():
        print(f"ERROR: not found: {args.jsonl}", file=sys.stderr)
        return 1

    data = ReportData(load_events(args.jsonl))
    if not data.events:
        print("ERROR: no events in JSONL", file=sys.stderr)
        return 1

    out = data.render(args.jsonl)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(out, encoding="utf-8")
        print(f"Wrote {args.output}")
    else:
        print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
