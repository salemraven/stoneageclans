# AI Clan Test – Findings and Issues Report

**Date:** 2026-02-03  
**Scope:** Headless test harness, analysis, automation with apply-fixes, and NPC flow polish (gather → deposit → herd) for AI clans.

---

## 1. What Was Implemented

| Component | Location | Purpose |
|-----------|----------|---------|
| **Instrumentation** | `npc_base.gd`, `gather_state.gd`, `gather_task.gd` | Call `NPCActivityTracker.log_deposit` / `log_gather` on successful deposit and harvest so the analyzer has data. |
| **Test runner** | `Tests/RUN_AI_CLAN_TEST.sh` | Run Godot headless for a set duration, copy `user://` logs (activity, metrics, console) into a timestamped or specified dir. |
| **Analyzer** | `Tests/ANALYZE_NPC_EFFICIENCY.sh` | Parse activity log, metrics CSV, and console; compute gathers, deposits, state distribution, land claims; write `analysis_result.env` and exit 0/1 for automation. |
| **Automation** | `Tests/AUTOMATE_AI_CLAN_TEST.sh` | Loop: run test → analyze → if issues and `--apply-fixes`, apply one predefined fix (priority/range/logic only) → re-run until pass or max iterations. |
| **Predefined fixes** | Same script | Boost gather priority, widen deposit range (50→60→70→100), match wander deposit range to 100, lower wander priority, faster build cooldown, wander deposit range in `wander_state`. |
| **Herd exit when full** | `herd_wildnpc_state.gd` | In `update()`, if inventory ≥ 80% full, set `moving_to_deposit` and `change_state("wander")` so cavemen leave herding to go deposit. |

---

## 2. What the Runs Show

### Metrics (typical 120s headless runs)

- **Gathers:** ~8–23 per run (from console `GATHER:` / `GATHER_TASK:` and, when present, activity log).
- **Deposits:** **0** in every run so far (no `AUTO-DEPOSIT:` or `Competition:` in console).
- **Land claims placed:** 4–5 (cavemen do place claims; names like RA CUWE, DU FURE, GA VOZU).
- **State distribution:** When `npc_metrics.log` is present, we can see wander/gather/herd; in many runs the metrics file is **missing** (see below).

### Behavior observed from console

- Cavemen spawn, place land claims, and gather.
- Herd_wildnpc is very active: many “target X is inside land claim (clan: Y) – invalidating” messages. Cavemen often chase women who are already inside another clan’s claim, so they stay in herd_wildnpc and rarely get a clean “full inventory → go deposit” flow.
- No `AUTO-DEPOSIT:` or `Competition:` lines, so the deposit path in `npc_base._check_and_deposit_items()` is never logged as having run successfully.

---

## 3. Issues Found

### 3.1 Deposits never occur (main blocker)

- **Symptom:** Deposit count stays 0 in all headless runs (2–4 minutes).
- **Possible causes (from code and logs):**
  1. **Stuck in herd_wildnpc:** Cavemen stay in herd_wildnpc (priority 10.6) chasing targets. When inventory hits 80%, `can_enter` for herd_wildnpc correctly becomes false, but **while already in the state** they did not exit until we added the “exit when full” check in `update()`. That fix is in place; if they still don’t deposit, either they never reach 80% in the test window or something else blocks the deposit path.
  2. **Never within deposit range:** Deposit only runs when the NPC is within `DEPOSIT_DISTANCE` of their clan’s claim (we increased this from 50 to 100 in both `npc_base` and `wander_state`). If they never path close enough (e.g. steering/obstacles, or they keep switching back to gather/herd before reaching the claim), deposits won’t trigger.
  3. **Too few items in time:** With ~8–10 gathers across 4 cavemen in 2 minutes, many may never reach 4/5 slots (80%), so the “full inventory → wander to deposit” and “exit herd_wildnpc when full” logic may rarely or never run.
  4. **Wander vs deposit:** There is no separate “deposit” state; deposit is done inside `wander` via `moving_to_deposit` and `_check_and_deposit_items()`. If FSM keeps them in gather or herd_wildnpc (or they re-enter before reaching the claim), they never get a sustained wander run near the claim.

We have not yet seen a single successful deposit in headless, so the exact failing step (pathfinding, range, state selection, or timing) is still to be pinned down with more targeted logs or a longer run.

### 3.2 Activity and metrics logs often missing

- **Symptom:** `npc_activity_tracker.log` and `npc_metrics.log` are frequently absent from the copied run dir (only `game_console.log`, `minigame_logs.txt`, `game_logs.txt` are present).
- **Impact:** Analyzer falls back to console-only (grep for GATHER/deposit/Competition); state distribution and activity-based counts are missing; `analysis_result.env` may have zeros or incomplete data.
- **Possible causes:** Tracker might not open/write files in headless, or might write under a different `user://` path; or the game process is killed before flush. Copy logic uses `$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans` (macOS); path or permissions might differ in the test environment.

### 3.3 Test runner argument bug (fixed)

- **Was:** `RUN_AI_CLAN_TEST.sh` used `$1` for both duration and output dir, so when automation passed `(DURATION, LOG_DIR)` the second argument was ignored and the run wrote into a dir named after the first number (e.g. `5`).
- **Fix:** Use `$1` as duration and `$2` as optional output dir.

### 3.4 Automation argument parsing (fixed)

- **Was:** Second numeric argument overwrote the first (e.g. `120 5` ended up as duration 5, max iter 120).
- **Fix:** First numeric arg = duration, second = max iterations.

### 3.5 Herd_wildnpc blocks deposit flow (partially addressed)

- **Issue:** When inventory is full, herd_wildnpc’s `can_enter` is false and priority is lowered, but NPCs **already in** herd_wildnpc never left, so they never transitioned to wander to deposit.
- **Fix:** At the start of `herd_wildnpc_state.update()`, if inventory ≥ 80% full, set `moving_to_deposit` and switch to wander. This should allow them to break out of herding and go deposit once full.

---

## 4. Fixes Applied (summary)

| Fix | File(s) | Change |
|-----|---------|--------|
| Deposit range | `npc_base.gd` | `DEPOSIT_DISTANCE` 50 → 60 → 70 → 100. |
| Wander deposit range | `wander_state.gd` | `DEPOSIT_RANGE` 50 → 100 to match npc_base. |
| Herd exit when full | `herd_wildnpc_state.gd` | In `update()`, if inventory ≥ 80%, set `moving_to_deposit` and `change_state("wander")`. |
| Gather priority (optional) | `npc_config.gd` | `priority_gather_other` 3.0 → 4.0 (only when automation applies it for LOW_GATHER). |
| Build cooldown (optional) | `build_state.gd` | Build cooldown 6.0 → 4.0 (only when automation applies it for NO_CLAIMS). |
| Analyzer threshold | `ANALYZE_NPC_EFFICIENCY.sh` | “Low deposit” only when deposit count &lt; 1 (was &lt; 2). |

No changes were made to move speed or gather rates (per plan).

---

## 5. Open / Recommended Next Steps

1. **Confirm why deposits are 0**  
   Add short debug prints or one-off logs in `_check_and_deposit_items()` and in `wander_state` when setting `moving_to_deposit` and when within `DEPOSIT_RANGE`, then run a single long headless test (e.g. 5 min) and inspect console to see whether:
   - NPCs ever get “moving to deposit” and wander to the claim.
   - They ever enter the “within range” branch and call the deposit logic.

2. **Fix or diagnose missing tracker logs**  
   - Ensure NPCActivityTracker creates and flushes `user://npc_activity_tracker.log` and `user://npc_metrics.log` in headless (e.g. enable unconditionally when `--headless` and open files in `_ready()`).  
   - After stopping Godot, add a short sleep or ensure process exit allows flush; confirm the copy script uses the same `user://` path that Godot uses on macOS in your setup.

3. **Longer or more focused runs**  
   - Use longer duration (e.g. 300s) so cavemen have time to fill 4+ slots and trigger “exit when full” and deposit.  
   - Optionally reduce herd_wildnpc priority or detection in a test build so more time is spent in gather/wander and less in chasing invalid targets.

4. **Success criteria**  
   Current bar: at least 1 deposit and no critical red flags. Once deposits are occurring, consider raising the bar (e.g. ≥2 deposits per run, or per-clan rates) and re-running automation.

---

## 6. How to Reproduce

```bash
# Single run (2 min), then analyze
./Tests/RUN_AI_CLAN_TEST.sh 120
# Then: ./Tests/ANALYZE_NPC_EFFICIENCY.sh Tests/ai_clan_test_<timestamp>

# Automated loop with fixes (2 min per run, up to 5 iterations)
./Tests/AUTOMATE_AI_CLAN_TEST.sh 120 5 --apply-fixes
```

Logs and analysis report are under the run directory (e.g. `Tests/ai_clan_auto_1/`); `game_console.log` has the raw Godot/print output.
