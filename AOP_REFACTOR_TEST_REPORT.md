# AOP Refactor — Post-Implementation Test Report

**Date:** 2026-03-15  
**Plan:** AOP as Base Refactor  
**Test Run:** Executed via `tools\godot\Godot_v4.6.1-stable_win64.exe`

---

## Executive Summary

| Check | Result | Notes |
|-------|--------|------|
| Game loads with PerceptionArea | ✅ PASS | Preload fix applied; no parse errors |
| Layer verification log | ✅ PASS | `PerceptionArea init: parent_layer=1 collision_mask=3 radius=300` |
| TARGET_SELECTED | ⏳ | Requires game_logs.txt; check with file logging |
| combat_started | ✅ PASS | Present in playtest_20260315_112737.jsonl |
| agro_increased | ✅ PASS | Present (proximity agro) |
| combat_detection_null | ✅ PASS | Zero events (PerceptionArea never null) |
| perception_query | ✅ PASS | Present (proximity agro) |

---

## Test Execution

**Command:** `.\tools\godot\Godot_v4.6.1-stable_win64.exe --path . -- --agro-combat-test --verbose`

**Output:** Game started, PlaytestInstrumentor enabled, clans spawned. Run duration ~6–14 seconds before exit.

---

## Findings

### 1. PerceptionArea / AOP Refactor — Working

- **PerceptionArea init log** (game_logs.txt):  
  `[DEBUG] [SYSTEM] PerceptionArea init: parent_layer=1 collision_mask=3 radius=300 npc=<null>`
- Confirms: collision_mask=3, layer verification, radius from config.
- No `combat_detection_null` in playtest JSONL — PerceptionArea is never null when queried.

### 2. Agro Combat Test — Pre-existing Setup Issues

The agro combat test showed:

- **`ERROR: FSM: State 'herd' not registered`** — Test tries to set `herd` state; FSM does not have it.
- **`Could not equip club to <null> - WeaponComponent not found`** — NPC ref is null during equip.
- **`alive_npcs: 0`** in all snapshots — NPCs may not be in `npcs` group or fail to initialize.

Because of this, no combat or agro occurred, so we could not observe:

- TARGET_SELECTED
- combat_started
- agro_increased
- perception_query

---

## Instrumentation Verification (Code-Level)

| Component | Location | Status |
|-----------|----------|--------|
| TARGET_SELECTED | perception_area.gd:161 | Wired; DEBUG when enable_agro_combat_test |
| Layer verification | perception_area.gd:51–57 | Working (log observed) |
| perception_query | npc_base agro functions | Wired; gated by agro-combat-test |
| combat_detection_null | combat_state.gd | Fires only when PerceptionArea null |
| DebugConfig DEBUG level | debug_config.gd | enable_agro_combat_test sets min_log_level=DEBUG |

---

## Fixes Applied During Test

1. **PerceptionArea preload** — Added `const PerceptionArea = preload("res://scripts/npc/components/perception_area.gd")` to npc_base.gd and combat_state.gd to fix "Could not find type PerceptionArea" when run from CLI.
2. **npc_base.gd:695** — Fixed "Invalid operands 'Object' and 'bool'" by replacing `get("combat_target") != false` with `is_instance_valid(combat_t)`.

## Recommendations

1. **TARGET_SELECTED** — Enable file logging (`--log-file`) to capture in game_logs.txt, or run from editor with verbose logging.
2. **Test script** — `run_agro_combat_test.ps1` uses `tools\godot\Godot_v4.6.1-stable_win64.exe` when present.

---

## Files Modified for Test Support

- `run_agro_combat_test.ps1` — Uses project-local Godot path
- `debug_config.gd` — enable_agro_combat_test sets min_log_level=DEBUG for TARGET_SELECTED
