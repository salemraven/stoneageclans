# Default Settings Reference

Single source of truth for gameplay settings: buffs, debuffs, multipliers, and testing overrides. Values marked **disabled for testing** can be re-enabled for default/shipping gameplay.

---

## Disabled for testing (restore for default gameplay)

When running the game in default/shipping mode, restore these to their intended values.

| Setting | Current (testing) | Default (intended) | Where |
|--------|---------------------|---------------------|--------|
| **Combat** | `combat_disabled = true` | `false` | NPCConfig – agro stays 0, no combat |
| **Herd sprint speed** | `herd_speed_multiplier_sprint = 1.0` | `1.5` | NPCConfig – herder sprint when target far |
| **Herd match fast targets** | `herd_speed_match_fast_targets = 1.0` | `1.2` | NPCConfig – herder speed when target moving fast |
| **Follower speed (herd state)** | `1.0` (hardcoded) | `1.25` normal, `1.4` hostile | herd_state.gd – women/NPCs following herder |
| **Deposit movement speed** | `1.0` (full speed) | `0.4` | wander_state.gd – speed when moving to land claim to deposit |
| **Caveman productivity test** | `caveman_productivity_test = 1.0` | `0.0` | NPCConfig – 1.0 = min wander, 0.5s re-eval; 0 = normal wander/priority |

---

## Speed multipliers (buffs)

| Setting | Value | Effect |
|--------|--------|--------|
| herd_speed_multiplier_sprint | 1.0 (testing) / **1.5** (default) | Herder speed when target > herd_sprint_distance |
| herd_speed_multiplier_normal | 1.0 | Herder speed at normal follow distance |
| herd_speed_match_fast_targets | 1.0 (testing) / **1.2** (default) | Herder speed to match fast-moving target |
| Follower (herd_state) | 1.0 (testing) / **1.25** normal, **1.4** hostile (default) | Women/herd NPCs following caveman |
| herd_velocity_toward_claim_bonus | 1.5 | Priority score bonus for targets moving toward claim (not movement speed) |
| wild_npc_speed_multiplier | 0.70–1.0 (random) | Wild NPCs move at 70–100% of base (variation) |

---

## Speed multipliers (debuffs / slowdowns)

| Setting | Value | Effect |
|--------|--------|--------|
| action_speed_multiplier | 0.3 | NPC speed when eating or gathering (30%) – npc_base applies via NPCConfig |
| herd_speed_multiplier_slow | 0.8 | Herder speed when very close to target (slow down to avoid overshoot) |
| Follower backing up | 0.15 | When follower is too close and backing up (herd_state.gd) |
| Stats (stats.gd get_speed_multiplier) | | |
| – Hunger &lt; 30 | 0.7 | Speed penalty |
| – Stamina &lt; 50 | 0.8 | Speed penalty |
| – Morale &lt; 30 | 0.9 | Speed penalty |

---

## Gather / deposit thresholds

| Setting | Value | Effect |
|--------|--------|--------|
| INVENTORY_FULL_FOR_NODE (gather_state) | 0.8 | Gather from same node until inventory 80% full, then deposit or next node |
| _get_inventory_threshold (gather_state) | 80% of slots (min 3) | When to break for deposit from gather state |
| wander deposit_threshold | 50% of slots (min 2) | When wander state considers “should move to deposit” |
| inventory_nearly_full_threshold (NPCConfig) | 0.8 | Reference for “nearly full” (80%) |

---

## Priority (FSM) – state order

Rough order highest → lowest: agro (15) &gt; deposit (11) = herd (11) &gt; herd_wildnpc (10.9) &gt; build (9.5) &gt; craft (12 when unlocked) &gt; gather (4–6) &gt; wander (0.5–1) &gt; idle (0).

| Setting | Value | Note |
|--------|--------|--------|
| priority_agro | 15.0 | Highest; combat/defense |
| priority_deposit | 11.0 | Protected; core gather→deposit loop |
| priority_herd | 11.0 | Following herder |
| priority_herd_wildnpc | 10.9 | Herd wild NPCs; above gather |
| priority_build | 9.5 | Place land claim |
| priority_gather_berries | 4.0 | Berries (hunger &lt; 90%) |
| priority_gather_other | 3.0 | Other resources (cavemen can get 6.0 when productivity_test ≥ 1) |
| priority_wander | 1.0 | Fallback (0.5 when productivity_test ≥ 1 for cavemen) |
| priority_idle | 0.0 | Lowest |
| caveman_productivity_test | 1.0 (testing) / 0.0 (default) | ≥ 1: gather 6, wander 0.5, re-eval 0.5s |

---

## Combat / agro (when combat enabled)

| Setting | Value | Effect |
|--------|--------|--------|
| combat_disabled | true (testing) / **false** (default) | If true, agro forced to 0 |
| agro_start_level | 10.0 | Agro when woman lost |
| agro_increase_rate | 10.0 | Per second |
| agro_max_level | 100.0 | Cap |
| hostile_threshold | 70.0 | “!!!” hostile mode |
| caveman_push_agro_multiplier | 1.5 | Push force multiplier in agro |

---

## Herd behavior (selection, attraction, distances)

| Setting | Value | Effect |
|--------|--------|--------|
| herd_target_stick_distance | 400 | Don’t switch target within this range |
| herd_sprint_distance | 500 | Use “sprint” multiplier when target this far |
| herd_slow_down_distance | 200 | Use slow multiplier when this close |
| herd_ideal_follow_distance | 175 | Ideal herder–follower distance when leading |
| herd_max_follow_distance | 300 | Start slowing follower beyond this |
| herd_min_follow_distance | 150 | Follower backs up below this |
| herd_max_distance_before_break | 300 | Herd breaks if follower &gt; this from herder |
| herd_max_distance_from_claim | 2000 | Max distance herder can go from claim |
| attraction_threshold | 50 | Attraction needed to start following |
| herd_npc_type_priority_woman | 1.2 | Target priority multiplier for women |

---

## Action durations (NPCConfig)

| Setting | Value |
|--------|--------|
| eat_duration | 2.0 s |
| gather_duration | 0.5 s |
| craft_knap_duration | 30.0 s |
| action_speed_multiplier | 0.3 (during eat/gather) |

---

## Movement / steering (NPCConfig)

| Setting | Value |
|--------|--------|
| max_speed_base | 260.0 |
| speed_agility_multiplier | 26.0 |
| max_force | 40.0 |
| arrive_radius | 100.0 |
| gather_distance | 48.0 |
| wander_radius | 300.0 |

---

## How to restore default (shipping) behavior

1. **NPCConfig (scripts/config/npc_config.gd)**  
   - `combat_disabled` → `false`  
   - `herd_speed_multiplier_sprint` → `1.5`  
   - `herd_speed_match_fast_targets` → `1.2`  
   - `caveman_productivity_test` → `0.0`

2. **herd_state.gd**  
   - Where follower speed is set to `1.0`, restore: `1.25` (normal), `1.4` (hostile).

3. **wander_state.gd**  
   - Where deposit movement uses `set_speed_multiplier(1.0)` (comment “TESTING”), change to `set_speed_multiplier(0.4)` for deposit movement.

All other values in this doc are either already at default or are standard buffs/debuffs to keep as-is unless tuning.
