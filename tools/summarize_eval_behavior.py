#!/usr/bin/env python3
"""English report + gates for eval-ai-arena playtest JSONL."""
from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from pathlib import Path


WATCH = {
    "clan_brain_eval",
    "clan_brain_invariant_failed",
    "clan_brain_quota_update",
    "survival_mode_changed",
    "gather_started",
    "gather_completed",
    "gather_failed",
    "gather_no_resource",
    "deposit_completed",
    "npc_move_sample",
    "combat_started",
    "combat_ended",
    "combat_target_switch",
    "fsm_bounce",
    "npc_died",
    "npc_kill",
    "fight_over",
    "fight_over_broadcast",
    "rout_delta",
    "rout_flee",
    "flee_decide",
    "corpse_job_opened",
    "butcher_slice",
    "work_request_issued",
    "work_request_claimed",
    "work_request_completed",
    "work_request_expired",
    "npc_hunger_threshold",
    "npc_ate",
    "task_no_job",
    "npc_stuck_state_escaped",
    "agro_increased",
    "agro_threshold_crossed",
    "player_died",
    "snapshot",
}


def load_rows(path: Path) -> list[dict]:
    rows = []
    with path.open() as f:
        for line in f:
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


def median(xs: list[float]) -> float:
    if not xs:
        return 0.0
    s = sorted(xs)
    n = len(s)
    mid = n // 2
    if n % 2:
        return s[mid]
    return 0.5 * (s[mid - 1] + s[mid])


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: summarize_eval_behavior.py <playtest.jsonl>")
        return 2
    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"ERROR: missing {path}")
        return 2
    rows = load_rows(path)
    counts = Counter(str(r.get("evt", "")) for r in rows)
    t_max = max((float(r.get("t", 0) or 0) for r in rows), default=0.0)

    print(f"=== EVAL BEHAVIOR  t={t_max:.0f}s  lines={len(rows)}  file={path} ===")
    print("-- counts --")
    for k in sorted(WATCH):
        if counts[k]:
            print(f"  {k}: {counts[k]}")

    clans = sorted({str(r.get("clan", "")) for r in rows if r.get("evt") == "clan_brain_eval" and r.get("clan")})
    print(f"-- ClanBrain clans ({len(clans)}): {', '.join(clans) or 'NONE'}")
    inv = counts["clan_brain_invariant_failed"]
    print(f"  invariant_failed: {inv}")
    quota_bad = 0
    gather_p = 0
    for r in rows:
        if r.get("evt") != "clan_brain_eval":
            continue
        cav = int(r.get("cavemen") or 0)
        dq = int(r.get("defender_quota") or 0)
        sq = int(r.get("searcher_quota") or 0)
        if dq + sq > cav:
            quota_bad += 1
        if float(r.get("gather_pressure") or 0) > 0:
            gather_p += 1
        print(
            f"  {r.get('clan')} t={float(r.get('t', 0)):.0f}s "
            f"state={r.get('strategic_state')} gather_p={r.get('gather_pressure')} "
            f"fsm gather/combat/wander={r.get('gather_count')}/{r.get('combat_count')}/{r.get('wander_count')} "
            f"quota d+s={dq}+{sq}/{cav}"
        )

    speeds = [float(r.get("spd") or 0) for r in rows if r.get("evt") == "npc_move_sample"]
    jumps = [float(r.get("jump_px") or 0) for r in rows if r.get("evt") == "npc_move_sample"]
    stuck = [float(r.get("stuck_s") or 0) for r in rows if r.get("evt") == "npc_move_sample"]
    late = [r for r in rows if r.get("evt") == "npc_move_sample" and float(r.get("t") or 0) >= max(0.0, t_max - 60.0)]
    late_stuck = sum(1 for r in late if float(r.get("stuck_s") or 0) > 4.0)
    late_combat = [r for r in late if str(r.get("fsm") or "") in ("combat", "flee_combat")]
    late_combat_stuck = sum(1 for r in late_combat if float(r.get("stuck_s") or 0) > 4.0)
    late_flee = [r for r in late if str(r.get("fsm") or "") == "flee_combat"]
    late_flee_stuck = sum(1 for r in late_flee if float(r.get("stuck_s") or 0) > 4.0)
    big_jumps = sum(1 for j in jumps if j > 200)
    print(
        f"-- move samples {len(speeds)} median_spd={median(speeds):.1f} "
        f"jumps>200px={big_jumps} late_stuck>4s={late_stuck}/{len(late)} "
        f"late_combat_stuck={late_combat_stuck}/{len(late_combat)} "
        f"late_flee_stuck={late_flee_stuck}/{len(late_flee)}"
    )

    print(
        f"-- work gather_started={counts['gather_started']} completed={counts['gather_completed']} "
        f"deposit={counts['deposit_completed']} failed={counts['gather_failed']}"
    )
    print(
        f"-- combat started={counts['combat_started']} ended={counts['combat_ended']} "
        f"kills={counts['npc_kill']} died={counts['npc_died']} fight_over={counts['fight_over']} "
        f"bounce={counts['fsm_bounce']} target_switch={counts['combat_target_switch']}"
    )
    switches = [r for r in rows if r.get("evt") == "combat_target_switch"]
    print(f"-- targeting switches={len(switches)}")
    for r in switches[:20]:
        print(
            f"  switch t={float(r.get('t', 0)):.1f} npc={r.get('npc')} "
            f"{r.get('old_target')} -> {r.get('new_target')} reason={r.get('reason')}"
        )
    if len(switches) > 20:
        print(f"  ... {len(switches) - 20} more switches")
    deltas = [r for r in rows if r.get("evt") == "rout_delta"]
    if deltas:
        print("-- rout_delta sample --")
        for r in deltas[:16]:
            print(
                f"  t={float(r.get('t', 0)):.1f} npc={r.get('npc')} clan={r.get('clan')} "
                f"add={r.get('add')} after={r.get('rout_after')} bravery={r.get('bravery')} "
                f"thresh={r.get('flee_threshold')} reason={r.get('reason')}"
            )
    print(
        f"-- morale rout_delta={counts['rout_delta']} rout_flee={counts['rout_flee']} flee_decide={counts['flee_decide']}"
    )
    snaps = [r for r in rows if r.get("evt") == "snapshot"]
    if snaps:
        comb = [int(r.get("in_combat") or 0) for r in snaps]
        flee = [int(r.get("in_flee") or 0) for r in snaps]
        pile = [int(r.get("pile_max") or 0) for r in snaps]
        routm = [float(r.get("rout_max") or 0) for r in snaps]
        tp = [int(r.get("targeting_player") or 0) for r in snaps]
        dead_snaps = sum(1 for r in snaps if r.get("player_dead"))
        hp0 = snaps[0].get("player_hp")
        hpl = snaps[-1].get("player_hp")
        print(
            f"-- battle pulses {len(snaps)} combat max={max(comb)} median={median([float(x) for x in comb]):.0f} "
            f"flee max={max(flee)} pile_max={max(pile)} rout_max={max(routm):.1f} "
            f"targeting_player max={max(tp)}"
        )
        print(f"-- player snap hp first/last={hp0}/{hpl} dead_snaps={dead_snaps} ignore={snaps[-1].get('npcs_ignore_player')}")
        peak = max(snaps, key=lambda r: int(r.get("in_combat") or 0) + int(r.get("in_flee") or 0))
        print(
            f"  peak-fight t={float(peak.get('t', 0)):.0f}s combat={peak.get('in_combat')} "
            f"flee={peak.get('in_flee')} pile={peak.get('pile_max')} on {peak.get('pile_target')} "
            f"rout_mean={peak.get('rout_mean')} brav={peak.get('combat_bravery_mean')}"
        )
    player_deaths = [r for r in rows if r.get("evt") == "player_died"]
    if player_deaths:
        print(f"-- player_died={len(player_deaths)}")
        for r in player_deaths:
            print(
                f"  t={float(r.get('t', 0)):.1f} cause={r.get('cause')} "
                f"killer={r.get('killer')} hp={r.get('hp')}"
            )
    for r in rows:
        if r.get("evt") not in ("npc_kill", "rout_flee", "flee_decide", "fight_over"):
            continue
        print(
            f"  {r.get('evt')} t={float(r.get('t', 0)):.1f} "
            f"npc={r.get('npc') or r.get('killer')} bravery={r.get('bravery')} "
            f"rout={r.get('rout_meter')} hp={r.get('hp_ratio')} rule={r.get('rule')} "
            f"reason={r.get('reason')} agro_after={r.get('agro_after')}"
        )

    warns: list[str] = []
    fails: list[str] = []
    if len(clans) < 4:
        fails.append(f"need 4 clan_brain_eval clans, got {len(clans)}")
    if inv:
        fails.append(f"clan_brain_invariant_failed={inv}")
    if quota_bad:
        fails.append(f"quota > cavemen on {quota_bad} evals")
    if gather_p == 0:
        fails.append("no clan_brain_eval with gather_pressure > 0")
    if counts["gather_started"] + counts["gather_completed"] < 1:
        fails.append("nobody gathered")
    if speeds and median(speeds) <= 0:
        fails.append("fighters look frozen (median speed 0)")
    if late_flee and late_flee_stuck > len(late_flee) * 0.75:
        fails.append(
            f"more than 75% late flee samples stuck > 4s ({late_flee_stuck}/{len(late_flee)})"
        )
    bounce_cap = max(80, int(counts["combat_started"] * 0.2))
    if counts["fsm_bounce"] > bounce_cap:
        fails.append(f"fsm_bounce {counts['fsm_bounce']} > {bounce_cap}")
    if big_jumps > 8:
        fails.append(f"teleport-like jumps {big_jumps}")
    if counts["combat_started"] == 0:
        warns.append("no combat_started (camps may have missed)")
    if counts["npc_kill"] + counts["npc_died"] > 0 and counts["fight_over"] + counts["fight_over_broadcast"] == 0:
        fails.append("a death happened but no fight_over")
    fo_pairs = set()
    for r in rows:
        if r.get("evt") != "fight_over":
            continue
        fo_pairs.add((str(r.get("npc")), str(r.get("corpse"))))
    if counts["fight_over"] > 0 and counts["fight_over"] > max(8, len(fo_pairs) * 2):
        fails.append(
            f"fight_over spam {counts['fight_over']} rows for {len(fo_pairs)} npc+corpse pairs"
        )
    if counts["combat_ended"] > max(counts["combat_started"] * 3, 20):
        fails.append(
            f"combat_ended {counts['combat_ended']} vs started {counts['combat_started']}"
        )
    if counts["npc_kill"] > 0 and counts["rout_delta"] == 0:
        warns.append("kills happened but rout_delta is 0")
    if counts["gather_completed"] > 0 and counts["deposit_completed"] == 0:
        warns.append("gathers but no deposits")

    for w in warns:
        print(f"WARN: {w}")
    for f in fails:
        print(f"FAIL: {f}")
    if not fails:
        print("PASS: behavior gates")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
