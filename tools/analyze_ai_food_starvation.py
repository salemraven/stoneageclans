#!/usr/bin/env python3
"""Analyze AI clan food + growth from playtest JSONL.

Success = productive surviving clan (not just pantry buffer).
Exit 0 when ring AI clans survive with acceptable food/growth signals.

Usage:
  python3 tools/analyze_ai_food_starvation.py path/to/playtest_*.jsonl
"""
from __future__ import annotations

import json
import os
import sys
from collections import Counter, defaultdict
from typing import Any

CRITICAL_DAYS = 0.5
PLAYER_CLAN = "TEST"


def load_events(path: str) -> list[dict[str, Any]]:
	events: list[dict[str, Any]] = []
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


def main() -> int:
	if len(sys.argv) < 2:
		print("Usage: analyze_ai_food_starvation.py playtest.jsonl", file=sys.stderr)
		return 2
	path = sys.argv[1]
	include_test = os.environ.get("INCLUDE_TEST", "0") == "1"
	events = load_events(path)

	by_clan: dict[str, dict[str, Any]] = defaultdict(
		lambda: {
			"samples": [],
			"modes": Counter(),
			"dormant_ticks": 0,
			"brain_evals": 0,
			"births": 0,
			"baby_grew": 0,
			"deaths": 0,
			"slaughters": 0,
			"regen_events": 0,
			"spawn_pop": None,
			"last_pop": None,
		}
	)
	max_t = 0.0
	spawn_clans: list[str] = []

	for obj in events:
		t = float(obj.get("t", 0.0))
		max_t = max(max_t, t)
		evt = str(obj.get("evt", ""))
		clan = str(obj.get("clan", "")).upper()
		if not clan:
			continue
		if not include_test and clan == PLAYER_CLAN:
			continue

		st = by_clan[clan]

		if evt == "session_nearby_clan_spawned":
			spawn_clans.append(clan)
			continue

		if evt == "settlement_tick_food_delta":
			buf = obj.get("food_days_buffer")
			mode = str(obj.get("workforce_mode", ""))
			if buf is not None:
				st["samples"].append(
					{
						"t": t,
						"buffer": float(buf),
						"mode": mode,
						"pop": obj.get("pop"),
					}
				)
			if mode:
				st["modes"][mode] += 1
			if obj.get("pop") is not None:
				if st["spawn_pop"] is None:
					st["spawn_pop"] = int(obj.get("pop"))
				st["last_pop"] = int(obj.get("pop"))
			st["dormant_ticks"] += 1
		elif evt == "clan_brain_eval":
			buf = obj.get("food_days_buffer")
			mode = str(obj.get("workforce_mode", ""))
			if buf is not None:
				st["samples"].append(
					{
						"t": t,
						"buffer": float(buf),
						"mode": mode,
					}
				)
			if mode:
				st["modes"][mode] += 1
			st["brain_evals"] += 1
		elif evt == "settlement_birth":
			st["births"] += 1
		elif evt == "settlement_baby_grew":
			st["baby_grew"] += 1
		elif evt == "settlement_member_died" or evt == "settlement_roster_death":
			st["deaths"] += 1
		elif evt == "settlement_slaughter_completed":
			st["slaughters"] += 1
		elif evt == "settlement_regen_completed":
			st["regen_events"] += 1

	clans = sorted(set(spawn_clans) | set(by_clan.keys()))
	clans = [c for c in clans if c and (include_test or c != PLAYER_CLAN)]

	print("=== AI food & growth analysis ===")
	print(f"File: {path}")
	print(f"Session length: {max_t:.0f}s")
	print(f"Success target: surviving clan + growth signals (births/baby_grew/pop) + not chronic STARVING")
	print("")

	if not clans:
		print("No AI clans in log.")
		return 2

	any_fail = False
	any_pass = False

	for clan in clans:
		st = by_clan[clan]
		samples = sorted(st["samples"], key=lambda x: x["t"])
		print(f"--- {clan} ---")
		print(
			f"  ticks={st['dormant_ticks']} pop={st['last_pop']} "
			f"births={st['births']} grew={st['baby_grew']} deaths={st['deaths']} "
			f"slaughters={st['slaughters']} regen={st['regen_events']}"
		)
		if not samples:
			print("  ⚠ no food buffer samples")
			any_fail = True
			print("")
			continue

		buffers = [s["buffer"] for s in samples]
		first, last = buffers[0], buffers[-1]
		mn = min(buffers)
		modes = dict(st["modes"])
		total_mode = sum(modes.values()) or 1
		starving_pct = 100.0 * modes.get("STARVING", 0) / total_mode
		print(
			f"  buffer: {first:.2f}d → {last:.2f}d (min {mn:.2f}d) modes={modes}"
		)

		growth = st["births"] + st["baby_grew"] > 0 or (
			st["last_pop"] is not None
			and st["spawn_pop"] is not None
			and st["last_pop"] > st["spawn_pop"]
		)
		survived = st["last_pop"] is None or st["last_pop"] > 0
		chronic_starve = starving_pct > 40.0 or (last < CRITICAL_DAYS and mn < CRITICAL_DAYS * 0.5)
		extinct = st["deaths"] > 0 and (st["last_pop"] is not None and st["last_pop"] <= 0)

		verdict = "OK"
		if extinct:
			verdict = "FAILED (extinct)"
			any_fail = True
		elif not survived:
			verdict = "FAILED (no population)"
			any_fail = True
		elif chronic_starve and not growth:
			verdict = "AT RISK (chronic STARVING, no growth)"
			any_fail = True
		elif chronic_starve and growth:
			verdict = "MIXED (growing but food tight)"
			any_pass = True
		elif growth or last >= CRITICAL_DAYS:
			verdict = "PRODUCTIVE / STABLE"
			any_pass = True
		else:
			verdict = "SURVIVING (leader-only, no growth yet)"
			any_pass = True if last >= CRITICAL_DAYS and starving_pct < 25 else False
			if not any_pass:
				any_fail = True
		print(f"  verdict: {verdict}")
		step = max(1, len(samples) // 10)
		timeline = " ".join(f"{s['buffer']:.1f}" for s in samples[::step][:10])
		print(f"  buffer timeline: {timeline}")
		print("")

	print("--- Overall ---")
	ring = [c for c in clans if c in {x.upper() for x in spawn_clans}]
	if ring:
		print(f"  Ring AI clans: {', '.join(ring)}")
	if any_fail and not any_pass:
		print("  ❌ Clans failed survival/growth targets — tune regen, gather, or world density.")
		return 1
	if any_pass and not any_fail:
		print("  ✓ Clans surviving with productive/stable food signals.")
		return 0
	if any_pass and any_fail:
		print("  ⚠ Mixed — some clans OK, some at risk.")
		return 1
	print("  ⚠ Inconclusive — extend test duration or check instrumentation.")
	return 1


if __name__ == "__main__":
	raise SystemExit(main())
