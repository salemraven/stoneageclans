# Reproduction Guide

**Last Updated:** 2026-08-27  
**Status:** Active System

**Regression gate:** `bash tools/run_repro_harness.sh` (also step **[4/5]** in `tools/run_earlygame_verify.sh`). Headless baby-cap unit tests: `SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_baby_cap.gd`

## Overview

Clan women reproduce with male cavemen (or the player) inside a land claim. Babies spawn as NPCs, grow to clansmen after a timer, and receive clubs. **Wild women cannot reproduce or stay pregnant** — they must be herded into a land claim and join the clan first.

## Flow

1. Cavemen (or player) herd wild women into the land claim via `herd_wildnpc` / `herd` states.
2. When a herded woman enters the land claim radius, she joins the clan via `set_clan_name(clan_name)`.
3. `ReproductionComponent` runs each frame: finds a mate (player or caveman in same clan, inside claim), starts pregnancy (if cap allows when enforced), counts down birth timer.
4. When timer hits 0, `main._spawn_baby()` spawns a baby NPC at the land claim center.
5. `BabyGrowthComponent` ages the baby; after the growth timer the baby becomes a clansman and gets a club.

---

## Baby cap (dynamic per clan)

Capacity = **base** + **Living Huts × bonus** + **fertility stub** (`baby_cap_bonus` meta summed from clan women).

| Setting | Default | Meaning |
|---------|---------|---------|
| `enforce_baby_cap` | `false` | When OFF (dev/stress tests), capacity is computed and logged but **never blocks** new pregnancies. |
| When ON | — | Blocks **starting** new pregnancies only. **Does not** block birth when an in-progress pregnancy finishes. |

Modifiers refresh when Living Huts are built or destroyed (`BabyPoolManager.refresh_clan_modifiers`).

---

## Wild vs nomad vs sedentary

**Pregnancy is tied to clan membership / wild state — not “standing on a claim this frame.”**

| State | Pregnancy |
|-------|-----------|
| Sedentary clan woman at claim | OK (normal rules) |
| Nomad woman marching (clan still set) | OK — timer **frozen** (`nomad_pregnancy_frozen`); **not cancelled** on pack-up |
| Nomad woman after new camp placed | Timer **resumed**; birth allowed at camp |
| Woman after claim destroyed (`become_wild()`) | **Cancel** — no wild pregnancies |
| Wild herdable woman | **Never** start or keep pregnancy |

Nomad freeze/resume lives in `campfire.gd` (`_freeze_clan_pregnancies`, `resume_clan_after_nomad`). Do **not** cancel pregnancy on nomad pack-up.

---

## Pregnancy cancellation

| Reason | Trigger |
|--------|---------|
| `went_wild` / `claim_destroyed` | `become_wild()` after claim lost |
| `starvation` | Clan food buffer below `pregnancy_cancel_food_buffer_days` while pregnant (no berry bypass) |
| `hut_lost` | No home Living Hut assigned |

---

## Requirements for Reproduction

All must be true:

| Requirement | Where checked |
|-------------|---------------|
| `npc_type == "woman"` | `reproduction_component.gd`, `reproduction_state.gd` |
| `clan_name != ""` / not wild | `reproduction_component.gd`, `become_wild()` |
| Woman inside land claim radius | `_is_in_land_claim()` |
| Mate (player or caveman) in same clan | `_try_find_mate()` |
| Mate inside land claim | `_is_player_in_land_claim()` (Player), `_is_npc_in_land_claim()` (NPCs) |
| Not pregnant | `is_pregnant == false` |
| Birth cooldown expired | `time_since_last_birth >= config.birth_cooldown` |
| Baby room (when enforce ON) | `BabyPoolManager.has_baby_room()` |
| Home Living Hut | `OccupationSystem.get_home_living_hut()` |

---

## Key Files

| File | Purpose |
|------|---------|
| `scripts/npc/components/reproduction_component.gd` | Pregnancy logic, mate finding, birth timer, `cancel_pregnancy()` |
| `scripts/npc/states/reproduction_state.gd` | FSM state (priority 8.0); logic in component |
| `scripts/config/reproduction_config.gd` | Timers, capacity, `enforce_baby_cap`, starvation threshold |
| `scripts/systems/baby_pool_manager.gd` | Per-clan capacity modifiers and breakdown |
| `scripts/npc/components/baby_growth_component.gd` | Baby aging → clansman transition |
| `scripts/main.gd` | `_spawn_baby()` – instantiates baby, sets lineage, sprite |
| `tools/test_baby_cap.gd` | Headless cap / wild / nomad / starvation tests |

---

## Configuration

### ReproductionConfig

| Property | Default | Notes |
|----------|---------|------|
| `birth_timer_base` | 15.0 | Pregnancy duration (seconds) |
| `birth_cooldown` | 10.0 | Seconds between births per woman |
| `baby_pool_base_capacity` | 3 | Base capacity from land claim |
| `living_hut_capacity_bonus` | 5 | Per Living Hut |
| `baby_growth_time_testing` | 17.5 | Seconds until baby → clansman |
| `baby_growth_age_normal` | 13 | Age for normal mode (unused) |
| `enforce_baby_cap` | `false` | Gate new pregnancies when true |
| `pregnancy_cancel_food_buffer_days` | 0.28 | Cancel pregnancy below this buffer |

### BalanceConfig

| Property | Default |
|----------|---------|
| `pregnancy_seconds` | 30.0 |
| `baby_growth_seconds` | 35.0 |

---

## Baby Spawning

1. `reproduction_component._spawn_baby()` — no cap check at birth; refuses wild/frozen mothers.
2. `main._spawn_baby(clan_name, spawn_pos, mother, father)` — same; logs capacity breakdown on spawn event.
3. Baby gets `BabyGrowthComponent`; after growth timer becomes clansman, gets club.

---

## Playtest JSONL events

| Event | When |
|-------|------|
| `baby_cap_snapshot` | Modifier refresh |
| `baby_pregnancy_blocked` | Conception refused (cap, food, wild) |
| `baby_pregnancy_cancelled` | starvation, hut_lost, went_wild |
| `baby_pregnancy_frozen` / `baby_pregnancy_resumed` | Nomad pack-up / new camp |
| `baby_spawned` | Includes optional `baby_cap` breakdown |

---

## Baby Pool formula

```
effective_capacity = base + (living_huts × hut_bonus) + sum(women.baby_cap_bonus)
has_baby_room = current_babies < effective   (always true when enforce_baby_cap is false)
```

---

## Baby feeding & starvation (planned — not shipped)

**Design intent:** Born babies consume food at a rate driven by **genetics (`metabolism` locus)** and role base calories. If unfed, they starve and are removed. See **[genetics.md](genetics.md)** for the full genetics + food plan.

### Shipped today (partial)

| Behavior | Status | Where |
|----------|--------|-------|
| Baby has 2 inventory slots (food intended) | Yes | `NPCConfig.baby_inventory_slots`, `npc_base._initialize_inventory()` |
| Calorie tracking on sim tick | Yes | `Stats` — babies use `base_daily_calories_baby` (720) |
| Need scales with strength/intelligence | Yes | `Stats.get_daily_calorie_need()` — **not** genetics yet |
| Growth timer → clansman | Yes | `BabyGrowthComponent` |
| Auto-feed from land claim when hungry | **No** | Old phase2 doc only; no code |
| Baby can enter `eat` state | **No** | FSM: babies limited to wander/idle |
| Genetics-based consumption rate | **No** | `genetics_profile` exists; not wired to food |
| Starvation despawn for born babies | **No** | Babies lack `HealthComponent`; no famine kill order |
| Cancel pregnancy on clan starvation | Yes | In utero only — `cancel_pregnancy("starvation")` |

**Practical note:** Babies currently **lose calories** but **cannot refill**. Short growth timer (~17.5s) usually completes before empty calories matter. This is acceptable for dev/stress tests until feeding + genetics land.

### Planned (future implementation)

1. **`BirthEngine`** resolves child genome; **`metabolism`** locus sets daily need.  
2. **Auto-transfer** food from claim/storage → baby inventory below hunger threshold.  
3. **Starvation:** health drain → infant death / despawn; log `baby_starved`.  
4. **Famine order:** babies die first when clan buffer negative (see [food.md](future%20implementations/food.md)).  
5. **JSONL:** `baby_fed`, `baby_starved`, tie into genetics ledger.

**Out of scope for v1:** player infanticide choice, baby corpses, spoilage.

