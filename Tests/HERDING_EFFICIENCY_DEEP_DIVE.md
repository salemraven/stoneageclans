# Herding Efficiency Deep Dive

Analysis of test run data and tunings applied to make cavemen herd more effectively.

## Data Summary (last 3‑min run)

| Metric | Value |
|--------|--------|
| Deliveries (target joined clan) | 15 |
| herd_wildnpc state entries (logged) | 2 (under-counted; many more via searcher self-assign) |
| Self-assigned searchers (log lines) | 28 |
| Block reasons in log | no_land_claim, searcher_quota_full (9), no_women_in_range |

## Bottlenecks Identified

1. **Searcher quota** – Only `ceil(cavemen.size() * search_pressure)` cavemen can be in herd_wildnpc per clan. With `search_pressure = 0.35` and 4 cavemen, only 2 could herd; the rest stayed in gather/wander.
2. **Delivery cooldown** – After each delivery, 45s cooldown before that caveman could enter herd_wildnpc again. Fewer trips per run.
3. **No-target exit** – If no wild NPC found, state exited after 5s base × 2 = 10s extended. Short search window before falling back to wander.
4. **Rapid-move drop** – Targets moving away at >100 px/s were invalidated after 1.5s. Some chases abandoned too soon.
5. **Search coverage** – Spiral expansion 50 px/rotation; slower coverage of the map when searching.

## Changes Applied

### 1. More searchers (ClanBrain)

- **File:** `scripts/ai/clan_brain.gd`
- **Change:** `search_pressure` 0.35 → **0.5**
- **Effect:** More cavemen allowed to be in herd_wildnpc at once (e.g. 4 cavemen → 2 searchers before, now 2–3; 6 cavemen → 3 searchers). At least 2 searchers when clan has 2+ cavemen (unchanged).

### 2. Shorter delivery cooldown

- **File:** `scripts/npc/states/herd_wildnpc_state.gd`
- **Change:** `DELIVERY_COOLDOWN_SEC` 45 → **28**
- **Effect:** Cavemen can start another herd run sooner; more deliveries per 3‑min run.
- **Config:** `NPCConfig.herd_delivery_cooldown_sec` (default 28) so it can be tuned without code change.

### 3. Longer search and chase grace

- **File:** `scripts/npc/states/herd_wildnpc_state.gd`
- **Change:**  
  - `max_no_target_time` 5 → **7** (extended search = 14s before exit).  
  - `rapid_move_timeout` 1.5 → **2.5** (seconds before dropping a “rapidly moving away” target).
- **Effect:** More time to find a target when searching; fewer aborted chases when target is fleeing.
- **Config:** `NPCConfig.herd_max_no_target_time`, `NPCConfig.herd_rapid_move_timeout`.

### 4. Config-driven tuning (NPCConfig + state)

- **File:** `scripts/config/npc_config.gd`
- **Added exports:**  
  - `herd_detection_range` = 1700 (default; was 1500 in state).  
  - `herd_max_no_target_time` = 7.0  
  - `herd_delivery_cooldown_sec` = 28.0  
  - `herd_rapid_move_timeout` = 2.5  
  - `herd_spiral_expansion_rate` = **80** (was 50; faster spiral = better area coverage).
- **File:** `scripts/npc/states/herd_wildnpc_state.gd`
- **Change:** In `enter()`, state reads detection range, max no-target time, and rapid-move timeout from `NPCConfig` when present. Delivery cooldown read via `_get_delivery_cooldown_sec()` everywhere it’s used.

## Priority / Quota (unchanged)

- herd_wildnpc **priority** stays above gather (10.9 vs 4–6), so when `can_enter` is true and quota allows, cavemen still choose herding over gathering.
- **can_enter** still requires: land claim, not depositing, not over inventory threshold, and **searcher quota not full**. Raising `search_pressure` increases quota, so more cavemen pass the quota check.

## How to Verify

1. Run the 3‑min test: `./Tests/TEST2_HERDING_COMPETITION.sh`
2. Compare: **Deliveries (target joined clan)** and **herd_wildnpc state entries** (and searcher self-assigns) vs a run before these changes.
3. Optional: In Godot, select the NPCConfig resource and adjust `herd_delivery_cooldown_sec`, `herd_detection_range`, `herd_spiral_expansion_rate` to taste.

## Possible Next Steps

- **Per-clan pressure override:** Let certain clans have higher `search_pressure` (e.g. via meta on land claim).
- **Detection range by clan size:** Larger clans could use slightly higher `herd_detection_range` to find distant wild NPCs faster.
- **Metrics:** Log time-in-state and deliveries-per-caveman to spot clans that under-herd or over-herd.
