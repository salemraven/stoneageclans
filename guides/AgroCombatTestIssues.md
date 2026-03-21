# Agro Combat Test — Identified Issues

**Last updated:** from code review and test runs.

---

## 1. Test run from CLI can abort

- **Symptom:** `Command failed to spawn: Aborted` when running Godot with `--agro-combat-test` in some environments (e.g. background + sleep + kill).
- **Likely cause:** Process/sandbox killing the Godot process or Godot not starting correctly in that context.
- **Workaround:** Run the game manually: `godot --path . -- --agro-combat-test`, let it run 60–90s, then close. Analyse the latest `user://playtest_*.jsonl` after the run.

---

## 2. Formation-at-border zone — FIXED

- **Where:** `main.gd` agro combat block — now `BORDER_ZONE_INNER = 0.70`, `BORDER_ZONE_OUTER = 1.20` (× claim radius 400 → 280–480 px).
- **Fix:** Widened from 0.82–1.08 to 0.70–1.20, giving ~200 px zone so leaders won't skip it.

---

## 3. Formation creep speed can look stuck

- **Where:** `FORMATION_CREEP_SPEED = 18.0` while holding at border.
- **Behaviour:** Leader target is set to current position each frame, so they should almost stop; small creep if steering doesn't fully zero.
- **If they drift:** Ensure we're not updating `target_position` to a moving point; using `leader.global_position` each frame is correct.

---

## 4. GUARD + follow_ordered distance (58 px)

- **Where:** `herd_state.gd` — when `mode == "GUARD"` and `follow_is_ordered`, `distance_max = 58`.
- **Note:** With `is_hostile` we also set 70 then override to 58 for GUARD+ordered, so raiding party stays tight. No overwrite from `NPCConfig` when hostile. Logic is consistent.

---

## 5. Reporter script — FIXED

- **Fix:** Changed `extends Node` → `extends SceneTree`, `_ready()` → `_init()`, `get_tree().quit()` → `quit()`.
- **Usage:** `godot --path . -s scripts/logging/playtest_reporter.gd [path_to.jsonl]`

---

## 6. Whiff count > hit count in data

- **Observed:** e.g. 28 hits vs 121 whiffs (GUARD run).
- **Possible causes:** Club arc / head-on checks, target switching, or movement causing many "in range but not valid" attacks.
- **Status:** Acceptable as current balance.

---

## 7. `combat_ended` on death — FIXED

- **Fix:** `health_component.gd` `die()` now emits `combat_ended` if NPC was in combat state or had a combat target.
- **Result:** `combat_ended` fires on death (most common combat exit) as well as agro drop.

---

## 8. No combat in test (0 combat_started) — FIXED

- **Cause:** Raid path required herder == player; test uses herder == leader. DetectionArea might not overlap in time.
- **Fixes:** (1) Combat `can_enter()` raid path now allows herder == leader when `DebugConfig.enable_agro_combat_test`. (2) DetectionArea collision_mask = 1 so it detects NPCs on layer 1. (3) Legacy enemy search range in agro combat test increased to 450px so parties engage sooner.
- **Also:** 90s auto-quit added so test runs full duration when you leave the window open.

---

## Summary

- **Environment:** CLI test can abort; run manually; leave window open 90s for auto-quit and full capture.
- **Logic:** Formation zone widened; raid path and detection fixed for test; 90s auto-quit.
- **Data:** Reporter runnable with `-s`; `combat_ended` on death. Whiff > hit acceptable.
