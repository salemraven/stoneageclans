# Agro & Combat Guide — Overhaul Plan

**Last Updated:** Feb 18, 2026

## Test process: validate the overhaul combat and agro system

**This is the test process to see if the overhaul combat and agro system works.** The goal of the test is to produce lots of data for debugging and to validate the new overhaul.

1. **Setup:** 2 land claims, 2 clans of 10 clansmen each (1 clan leader + 9 followers per clan).
2. **Follow mode:** Clan leaders have their clansmen in **follow mode** so they form up behind the leader.
3. **Advance:** When the clansmen are at the leader (formation ready), the leader moves toward the **other clan’s leader** (and the other clan does the same).
4. **Meet head-on:** Both raiding parties meet head-on → **melee combat**.
5. **Goal:** Capture lots of instrumentation data (agro, combat_started/ended, hits/whiffs, target switches, FPS, alive_npcs) for **debugging and validating the new overhaul**.

Run with `--agro-combat-test`; capture is auto-enabled. After the run, use the playtest reporter (or inspect the JSONL) to analyze the data.

This doc is the **planning reference** for the agro and combat overhaul. It captures current behavior, target design from brainstorming, and the implementation plan. All important ideas from brainstorming are collected here.

**Design philosophy:** Simple, stone-age appropriate behaviour — **no in-depth RTS commands**. One toggle: **Follow** vs **Guard**. Follow = loose formation behind leader; Guard = tight formation around leader. Friendly vs hostile is shown by whether the leader has a **weapon equipped** (no separate toggle). When hostile (weapon out), followers/guards sit at **70 agro** so they’re defensive and ready to fight. At **agro 100** a clansman will attack on their own regardless of mode (savagery / unpredictability). **All of this applies to NPC cavemen too** (AI leaders have followers that follow or guard; hostile from weapon, 70 agro when hostile). In the future, raiding will be properly implemented in the clanbrain for AI cavemen NPCs.

**Contents:** Part 0 = **testing environment & implementation plan** (do this first). Part 1 = current state + limitations. Part 2 = target design. Part 3 = foundation design, overhaul phases, and checklist.

---

# Part 0: Testing Environment & Implementation Plan

**Set up a proper testing environment and run it before starting the agro/combat overhaul.** Each implementation step ends with: implement → run test → read instrumentation → tweak/fix → re-test until green → sign off (and optionally tag/branch) → next step.

---

## Test environment (single source of truth)

**Goal:** Reproducible scenario where two clans walk in FOLLOW mode, enter each other's land claims, trigger hostile/agro, and fight with clubs. Validate behavior and performance after every step.

### Raid test (ideal setup — current implementation)

- **Purpose:** This raid test is **the test process to validate the overhaul combat and agro system**; it produces lots of data for debugging.
- **Mode:** Run with `--agro-combat-test`. No separate capture flag needed; **playtest capture is auto-enabled** for this mode.
- **What it does:** Both clans go into **follow mode** to their leaders and **go at each other** for a combat test. Raiding party per clan: clan leader leads all their clansmen at the enemy; the two parties meet head-on for melee.
- **Clans:** 2 clans (`ClanA`, `ClanB`), each with **10 clansmen**: **1 clan leader + 9 followers**. Unit type: `clansman`. All spawn with **club (WOOD)** equipped.
- **Claims:** One land claim per clan (~400px radius). Claims placed well apart so the two raiding parties have a clear approach before meeting.
- **Behavior:** Both clans in **follow mode** — followers have `herder` = clan leader, `follow_is_ordered` = true; FSM forced into herd state so they follow their leader. Each frame each leader’s steering target is set to the **other** clan’s claim, so the **two groups go at each other** → meet → intrusion → agro → combat.
- **Load variants (optional):** For lighter runs use fewer per clan (e.g. 5); for stress use more (e.g. 20). The default **2×10** is the ideal raid test.
- **Next (after follow-mode is solid):** Run the same test in **guard mode** — both clans in guard mode going at each other; same instrumentation and data goal.

### Instrumentation (required)

- **Events** (in `playtest_instrumentor.gd`; emitted from CombatTick, combat_state, combat_component):
  - `agro_increased` (npc, value, reason: intrusion/aoa/hit/mammoth/herd_steal_*)
  - `agro_threshold_crossed` (npc, above_70: bool)
  - `combat_started` / `combat_ended` (npc, target)
  - `combat_target_switch` (npc, old_target, new_target, reason)
  - `combat_hit` / `combat_whiff` (npc, target, reason if whiff)
- **Session:** First line is `session_start`; when running raid test it includes `agro_combat_test: true`.
- **Snapshots:** Periodic writes (every **2 seconds** in agro-combat-test mode, 5s otherwise) with:
  - `fps`, `in_combat` (number of NPCs in combat state), `alive_npcs` (for raid test).
- **Output:** `user://playtest_YYYYMMDD_HHMMSS.jsonl` (Godot user data dir).

### Reporter

- **Script:** `scripts/logging/playtest_reporter.gd`. Reads the latest `user://playtest_*.jsonl` (or a path you pass) and prints:
  - Counts for all agro/combat events (agro_increased, agro_threshold_crossed, combat_started, combat_ended, combat_target_switch, combat_hit, combat_whiff).
  - For raid-test runs: peak `in_combat` and final `alive_npcs` from snapshots.
  - FPS from snapshots (min / avg / max, sample count).
- **Run reporter:**  
  `godot --path . -s scripts/logging/playtest_reporter.gd`  
  or with explicit path:  
  `godot --path . -s scripts/logging/playtest_reporter.gd /path/to/playtest_YYYYMMDD_HHMMSS.jsonl`
- **“Read the data”** = run the test, then run the reporter and compare counts/FPS to your baseline.

### Baseline (record after Step 0b)

- After first green run of the raid test, run the reporter and record: combat_started range, hit/whiff range, target_switch, FPS (e.g. "combat_started: 40–60, hit: 80–150, whiff: 10–30, FPS ≥ 30"). **Green** in later steps = within ~20% of baseline or better. See **guides/AgroCombatBaseline.md** for a template and how to run the reporter.

**Success criteria per run:**

- Both clans move in follow formation toward the other claim; intrusion triggers; agro rises; combat_started events fire; clansmen attack with clubs.
- No crashes; FPS acceptable (2×10 default; use 2×5 for quick loops, 2×20 for stress).
- After club arc + target-switch step: whiffs when target is behind; target_switch when unit switches to an enemy it can hit.

**How to run the raid test (quick ref):**

- Start game with capture: `godot --path . -- --agro-combat-test` (capture auto-on).
- After run, summarize data: `godot --path . -s scripts/logging/playtest_reporter.gd` (uses latest `user://playtest_*.jsonl`).

**Rollback:** Tag or branch after each green step so you can revert to last known good.

---

## Implementation steps (test loop every step)

### Step 0a: Test harness only (no instrumentation yet)

- Test mode: `--agro-combat-test` spawns 2 clans × 10 clansmen (1 leader + 9 followers), clubs, 2 land claims; leaders walk toward the other claim so the groups meet and trigger intrusion.
- Spawn/init: clan names, herder + follow_is_ordered, force FSM into herd so followers form up, equip WOOD, land claim placement (~900px apart).
- **Test:** Run; confirm both clans form up, walk toward each other, and combat triggers. No instrumentation yet.

### Step 0b: Instrumentation + reporter + baseline

- Instrumentation events in playtest_instrumentor.gd; emissions from CombatTick, combat_state, combat_component (single layer).
- Reporter script (`scripts/logging/playtest_reporter.gd`) reads latest JSONL and prints event counts + FPS (+ peak in_combat / final alive_npcs for raid runs).
- **Capture:** When running `--agro-combat-test`, capture is **auto-enabled**; output is `user://playtest_YYYYMMDD_HHMMSS.jsonl`. Snapshots every 2s during raid test.
- **Test:** Run `--agro-combat-test`; run reporter; confirm events and counts. Record **baseline** in guides/AgroCombatBaseline.md. Re-test until green. **Sign off; tag/branch.**

### Step 1: Club arc (one direction) + target switch (RTS behavior)

- **Narrow club arc:** In combat_component.gd, WOOD profile: set arc to narrow cone (e.g. PI/4, "directly in front" per Part 2 RTS weapons).
- **Target switch when can't hit:** In combat_state, when current target is valid but **not in attack arc**, prefer "nearest enemy in arc" or clear and re-find. Emit `combat_target_switch` and `combat_whiff` (reason: out_of_arc). **Abstraction:** Introduce a small API for "get combat target candidates" (e.g. get_enemies_in_range(pos, radius) → array); combat_state picks in-arc from that. When Step 5 adds HostileEntityIndex, swap this API to use the index so Step 5 is a clean swap.
- **Test:** Run (light load); expect more whiffs and target_switch. Tweak arc and switch logic; re-test until green. **Sign off; tag/branch.**

### Step 2: Foundations — CombatTick, agro as data, hysteresis

- CombatTick at fixed timestep (20–30 Hz); agro decay, threshold (70 enter / 60 exit), combat target selection, combat enter/exit. Remove agro from npc_base `_physics_process`; feed CombatTick with events (intrusion/damage push agro deltas).
- Agro as data (value, source_flags, current_target_id, last_agro_event_time); hysteresis enter 70 / exit 60.
- Move instrumentation emissions to CombatTick + combat_state (single layer).
- **Test:** Run; confirm same or better behavior and event counts. **Sign off; tag/branch.**

### Step 3: IDs everywhere (entity_id + generation), EntityRegistry

- EntityRegistry (id + generation, ALIVE/DYING/REMOVED); combat_target_id, leader_id, defend_target_id; resolve at edge only. Invalid target → agro 69, clear intent.
- **Test:** Run; no shadow fighting, combat_end when target dies. **Sign off; tag/branch.**

### Step 4: CommandContext, follower cache, HUD (FOLLOW/GUARD, BREAK)

- CommandContext (commander_id, mode, is_hostile, issued_at_time); follower cache on commander; HUD FOLLOW|GUARD, BREAK; weapon out = 70 agro sustained.
- **Test:** FOLLOW/GUARD/BREAK; formation and clear. **Sign off; tag/branch.**

### Step 5: Spatial & claims — HostileEntityIndex, EnemiesInClaim

- One HostileEntityIndex (spatial + tags); EnemiesInClaim per claim (Area2D body_entered/body_exited); merge intrusion + AOA. Swap "get target candidates" to use index.
- **Test:** Full load (2×20); FPS and event counts green. **Sign off; tag/branch.**

### Step 6: Formations (FOLLOW loose, GUARD tight); formation only when agro &lt; 70

- Formation when agro < 70; combat ignores formation; re-form when agro < 60.
- **Test:** Visual and instrumentation. **Sign off; tag/branch.**

### Step 7: Hardening — phase order, intent priority, debug viz

- CombatTick phase order fixed; single intent per tick (Combat > Recover > Command > Work); debug toggles (agro, bubble, formation, target lines).
- **Test:** Full run; fix ordering bugs. **Sign off; tag/branch.**

### Step 8: Data-driven thresholds

- Move 70, 60, 100, decay rates to config; no logic change.
- **Test:** Change config; confirm behavior changes. **Sign off; tag/branch.**

### Step 9: Save/load smoke test (optional)

- Save game, reload, run test again; no crash. Confirms save/load guards (Part 3 hardening) don't regress.

---

## Test loop (every step)

1. **Implement** the step only.
2. **Run** test: `--agro-combat-test` (default 2×10 raid; use 2×5 for quick Steps 0–2, 2×20 for Steps 4+ stress if desired).
3. **Read** instrumentation: run reporter (`godot --path . -s scripts/logging/playtest_reporter.gd`); check counts vs baseline.
4. **Tweak/fix** from data.
5. **Re-run** until success criteria and baseline match.
6. **Sign off** (tick checklist in this guide); **tag or branch**; proceed to next step.

---

# Part 0.5: How Combat Works (Current Implementation)

This section documents the **actual** combat flow in the codebase (as of 2026-02-21). See Part 1+ for limitations and overhaul plans.

## Flow

1. **Agro** – Intrusion, damage, or herd steal increases agro. At agro ≥ 70, NPC can enter combat.
2. **Target** – `combat_target` / `combat_target_id` set by agro_state or FSM. DetectionArea finds nearest enemy.
3. **Combat state** – Priority 12.0. On enter: cancel tasks, set target in CombatComponent, same-clan check (never attack allies).
4. **CombatComponent** – Event-driven: WINDUP → hit frame → RECOVERY. CombatScheduler schedules hit at `windup_time` (e.g. 0.45s).
5. **Hit** – Arc check (210° cone). In arc: apply damage via HealthComponent; emit combat_hit. Out of arc: whiff.
6. **Target switch** – If target out of arc or behind, combat_state can find nearest enemy in arc and switch.
7. **Exit** – Target dead/invalid or out of range; agro drops; FSM evaluates; combat state exits.

## Key Files

| File | Role |
|------|------|
| `combat_state.gd` | FSM state; moves toward target, requests attack, handles target switch |
| `combat_component.gd` | Windup/recovery, hit frame, arc check, damage |
| `combat_scheduler.gd` | Schedules hit events at fixed time (avoids delta drift) |
| `detection_area.gd` | Finds nearest enemy for target selection |
| `health_component.gd` | Receives damage, death, leader succession |

## CombatComponent Timing

| Phase | Duration | Notes |
|-------|----------|-------|
| WINDUP | 0.45s (config) | Sprite frames 1→2→3; hit at end |
| RECOVERY | 0.8s (config) | Sprite frame 4; no new attack until done |

## Attack Arc

- **Cone:** 210° (7π/6) in front of attacker.
- **Range:** 100px default.
- **Whiff:** Target in range but out of arc → no damage, can trigger target switch.

## Damage

- **Base:** 10 per hit (3 hits ≈ 30 HP to kill).
- Applied via HealthComponent on target.

---

# Part 1: Current State

## Overview

The agro system controls when NPCs become hostile and enter combat. The **agro meter** (0–100) is the main driver: when it reaches 70+, the NPC sets a combat target and enters the combat state to attack.

**Primary flow:** Triggers increase `agro_meter` → at 70+ set `combat_target` → enter `combat_state` → attack.

---

## Agro Meter System

- **Range:** 0.0 to 100.0
- **Combat threshold:** 70.0 — when reached, `combat_target` is set and the NPC can enter combat state
- **Decay:** 5.0/sec when not in combat, 2.0/sec when in combat (chasers eventually give up)
- **Location:** `npc_base.gd` — updated every frame in `_physics_process`

---

## Agro Triggers (Increase agro_meter)

### 1. Land Claim Intrusion

**Location:** `npc_base.gd` - `_check_land_claim_intrusion(delta)`

**Who:** Cavemen and clansmen with a land claim (`clan_name != ""`)

**When:** Enemy cavemen, clansmen, or the player enter the land claim (within claim radius ~400px)

**Effect:** Agro increases at 50/sec; at 70+ sets `combat_target` to nearest intruder. Also calls `report_intruder` / `report_raid` on the land claim.

### 2. Area of Agro (AOA)

**Location:** `npc_base.gd` - `_check_area_of_agro(delta)`

**Who:** Cavemen and clansmen

**When:** Enemy cavemen, clansmen, or player are within AOA radius (default 200px) *and* within land claim (AOP). AOA must be ≤ claim radius.

**Effect:** Same as land claim intrusion — 50/sec, combat_target at 70+.

**Config:** `NPCConfig.area_of_agro_radius` = 200px

### 3. Mammoth Agro

**Location:** `npc_base.gd` - `_check_mammoth_agro(delta)`

**Who:** Mammoths only

**When:** Cavemen, clansmen, predators, or player enter mammoth AOP (default 600px radius)

**Effect:** Agro rate = `mammoth_base_agro_rate` × threat count (more threats = faster agro). At 70+ sets combat_target.

**Config:** `NPCConfig.mammoth_aop_radius` = 600, `mammoth_base_agro_rate` = 30

### 4. Being Attacked

**Location:** `health_component.gd` - `take_damage()`

**When:** NPC takes damage from an attacker

**Effect:** +50 agro, `combat_target` = attacker (if valid enemy — not herder, not same clan)

### 5. Herd Steal

**Location:** `npc_base.gd` — herd mentality / leader switch logic

**When:**
- **Steal success:** Old herder loses the NPC to another herder → old herder gets +40 agro (`agro_steal_success`)
- **Steal attempt failed:** Challenger tried to steal, herder defended → herder gets +20 agro (`agro_steal_attempt`)

---

## Combat State

- **Entry:** `agro_meter >= 70` and `combat_target` is set (and valid)
- **Behavior:** Chase and attack `combat_target` with melee
- **Exit:** `agro_meter` decays below 70 (target cleared), or target dies/invalid
- **Task cancellation:** Entering combat cancels gather/craft jobs

---

## Agro State (Agro Recover)

**agro_state.gd** is used only for **Agro Recover**: when a caveman loses a herd member to a steal, they try to get them back via approach/retreat (not combat). Cavemen only; triggered when herd steal success sets `is_agro = true`, `agro_target` = new herder. Land claim defense is handled by intrusion → agro_meter → combat, not a separate push state.

---

## Configuration (NPCConfig)

| Variable | Default | Description |
|----------|---------|-------------|
| `combat_disabled` | false | When true, agro_meter stays 0 (testing) |
| `area_of_agro_radius` | 200.0 | AOA trigger radius (px) |
| `agro_steal_attempt` | 20.0 | Agro added when steal attempt fails |
| `agro_steal_success` | 40.0 | Agro added when steal succeeds (old herder) |
| `mammoth_aop_radius` | 600.0 | Mammoth agro range (px) |
| `mammoth_base_agro_rate` | 30.0 | Base agro/sec for mammoths (× threat count) |

---

## Code Locations

| Component | File |
|-----------|------|
| Agro meter, decay | `npc_base.gd` - `_physics_process` |
| Land claim intrusion | `npc_base.gd` - `_check_land_claim_intrusion()` |
| Area of Agro | `npc_base.gd` - `_check_area_of_agro()` |
| Mammoth agro | `npc_base.gd` - `_check_mammoth_agro()` |
| Damage → agro | `health_component.gd` - `take_damage()` |
| Combat state | `combat_state.gd` |
| Agro state (recover) | `agro_state.gd` |

---

## Current limitations (why overhaul)

- **Scalability:** Intrusion, AOA, and mammoth agro run every physics frame for every eligible NPC. Each uses `get_nodes_in_group("npcs")` + full scan → O(N²) cost. No spatial partitioning.
- **Efficiency:** No throttling; no use of NodeCache for land claims in agro paths. Redundant logic between intrusion and AOA.
- **Multiplayer:** No network layer. Agro/combat are frame-driven and use direct node references; not event-based or ID-based for replication. Not server-authoritative.

---

## Q&A

**Q: What drives combat?**  
A: `agro_meter` >= 70 with a valid `combat_target`. Triggers: land claim intrusion, AOA, mammoth threats, being attacked, herd steal.

**Q: Can cavemen agro at wild NPCs?**  
A: No. They agro at other cavemen/clansmen/player who threaten their claim or steal their herd. Wild NPCs are herd targets, not combat targets.

**Q: Does agro decay?**  
A: Yes. 5/sec normally, 2/sec while in combat. When agro drops below 70, combat_target is cleared and combat state exits.

**Q: What’s the difference between Defend Land Claim and Guard?**  
A: Defend Land Claim = stay at the claim, patrol, fight intruders. Guard = follow the player outside the claim and protect them (interpose, attack threats near leader). Guard uses herd_state + guard_mode; land claim defend uses defend_state + defend_target.

**Q: Can follow be broken by distance?**  
A: No. Follow (clansmen following the leader) is only broken by the player (BREAK button) or future panic. Herd (women/animals) can break from distance, steal, or joining a clan.

---

# Part 2: Target Design (from brainstorming)

## Two Defend Modes

There are two distinct "defend" behaviors:

### 1. Defend Land Claim (Static)

**What:** Protect the land claim; NPCs stay on the claim border.

**When:** Player assigns DEFEND to a land claim (or slider sets defender quota). NPC is in the claim’s defender pool.

**Behavior:**
- `defend_target` = LandClaim
- `defend_state` — patrol on the claim circle (guard band)
- Combat when intruders enter the claim (`_check_land_claim_intrusion`)
- Pursuit limited so defenders don’t chase far from the claim
- Does **not** follow the player — stays at the claim

**Context:** Defenders hold the territory whether the player is home or away.

### 2. Defend Player (Guard / Escort)

**What:** Protect the player while they move. Clansmen act as bodyguards. This mode is called **Guard** in the HUD.

**When:** Clansmen are following the player (`herder == player`) and the player has set **Guard** mode (Guard/Follow toggle). They leave the land claim with the leader.

**Behavior:**
- `herder` = player (no `defend_target`; the defended entity is the leader)
- **Guard mode:** Clansmen move **between** the leader and enemies (interpose), higher agro, tighter formation
- **Follow mode:** Loose formation, standard follow
- Combat when enemies get close to the **player** or when the player attacks
- Movement is mobile (around the player), not fixed to a claim

**Context:** Raids, exploration, escort. Escorts stay around the player and react to threats near the leader.

| Aspect | Defend Land Claim | Defend Player (Guard) |
|--------|--------------------|------------------------|
| **Target** | Land claim | Player (leader) |
| **Reference** | `defend_target` = claim | `herder` = player + guard_mode |
| **State** | `defend_state` | `herd_state` (follow) |
| **Location** | Fixed (claim border) | Mobile (around player) |
| **Aggro trigger** | Intruders in claim | Enemies near player / player attacks |

---

## Follow vs Herd

| Concept | Who | Lines | Breakable? |
|--------|-----|------|------------|
| **Follow** | Clansmen (and cavemen) following the player/leader | Leader→follower lines: white/dim (not herd red) | **No.** Only the player can break it (BREAK button), or future panic. |
| **Herd** | Women, sheep, goats following a herder | **Darker red** (herd lines) | **Yes.** Distance, steal, join clan, etc. |

- **Follow** = ordered escort; unbreakable except by player choice (BREAK button) or future panic.
- **Herd** = leading wild NPCs; breakable; drawn as **darker red** lines.
- **Line colors:** Herd lines (leader→woman/sheep/goat, and follower’s line to herder) use a darker red. Follow lines (leader→clansman/caveman) use white or dim (non-red).

---

## Raid follow & formation (target)

- **Default:** Loose formation — tribe-of-cavemen feel, stalking movement, ready for raiding. No obstacles in the game so movement is direct (no pathfinding).
- **Formation:** Arc/semicircle behind leader; 90–120px ideal distance; ~25px tolerance so units don’t chase tiny corrections; small random jitter so they don’t line up perfectly.
- **Attack triggers:** Clansmen attack when (1) an enemy gets too close to the **leader** (leader bubble ~150–200px), or (2) the **leader attacks** someone. Same for **NPC cavemen**: their followers/guards use the same formation and hostile rules.
- **No in-depth RTS:** One toggle — **FOLLOW** vs **GUARD** — and **BREAK** button. Stone-age simple; no CHARGE or unit selection.
- **Follow:** Loose formation **behind** the leader. **Guard:** Tight formation **around** the leader. Applies to player and NPC cavemen.

---

## Combat HUD

*Single FOLLOW/GUARD toggle and BREAK button; no Friendly/Hostile checkbox; hostile = weapon equipped; applies to NPC cavemen.*

**Layout (left of hotbar):**

```
[ FOLLOW | GUARD ]   [ BREAK ]
```

- **FOLLOW / GUARD toggle:** **FOLLOW** = loose formation behind leader. **GUARD** = tight formation around leader. **Applies to both player and NPC cavemen.** No CHARGE, no unit selection. Stone-age simple.
- **BREAK:** Clears ordered follow for all followers (only the player can break follow, or future panic).

**Friendly / Hostile = weapon equipped (no separate toggle):**

- **Removed:** Friendly/Hostile CheckButton.
- **Rule:** If the **leader** (player or NPC caveman) has a **weapon equipped** (e.g. slot 1: WOOD/AXE/PICK/BLADE), followers are **hostile** (raid mode). When unequipped, followers are **friendly**.

- **When hostile:** Set followers' agro to **70** (combat threshold) so they are **defensive**. Sync on equip/unequip: set `is_hostile` from leader has_weapon, and set follower agro to 70 when hostile (decay when friendly). **Applies to NPC cavemen** too.
- **Future:** Raiding will be properly implemented in the **clanbrain** for AI cavemen NPCs later.

---

## Priority Order

1. **Agro 100 (full agro)** → Attack even when following or guarding. Savagery / unpredictability; formation does not override full agro.
2. **Leader mode (Follow/Guard)** → Applies to all followers of that leader (player or NPC caveman). Overrides land claim defend and work for those followers.
3. **Land claim defend** → Defender quota (slider). Only applies to clansmen **not** following a leader.
4. **Work** → Gather, craft, etc.

So: **Agro (100) > Follow/Guard (leader mode) > land claim defend > work.** Same priority logic for NPC cavemen with followers.

---

## Land Claim Defender Slider

- **Meaning:** Percentage of clansmen **left at the claim** (not following the leader) that should defend.
- **Denominator:** Clansmen in the clan who are **not** following the player (`herder != player` or not on ordered follow).
- **Numerator:** Defenders are drawn from that pool; quota = e.g. `ceil(total_non_following * player_defend_ratio)`.
- The slider does **not** affect clansmen who are following the player; it only divides the remainder between “defend” and “work.”

---

## RTS combat & weapons (target design)

Combat is RTS-style: units follow orders, agro triggers when threats appear or leader attacks. Weapons and damage types to support role-play and tactics:

**Weapons & attack geometry:**
- **Club (WOOD):** Melee only, narrow cone (directly in front). Must face target.
- **Spear:** Extended melee range, wider attack cone.
- **Stone axe:** Tool + weapon; similar cone to spear, shorter reach; cut damage.
- **Adze/pick:** Tool + weapon; attack similar to club; puncture damage; good vs armor.
- **Mace:** Same cone/range as axe; blunt damage; good vs armor.
- **Projectiles:** Stone throw, sling, arrow, atlatl (separate ammo/range/arc logic).

**Damage types:**
- **Blunt (club, mace):** High crit chance, low crit damage, no bleed, good vs armor, chance to break bone.
- **Cut (axe):** Low crit chance, high crit damage, bleed, weak vs armor.
- **Puncture (spear, adze):** Low crit chance, high crit damage, bleed, good vs armor.

**Armor:** Reduces damage and crit chance for the wearer. Blunt favored vs armor; cut weak vs armor.

**Attack profiles:** Per-weapon data (range, arc_degrees, damage_type, windup/recovery, crit, etc.) so combat and targeting use “in range + in arc” for melee. Projectiles handled separately (ammo, travel, hit).

---

# Part 3: Foundation Design & Implementation Plan

Small structural choices here save months later. The following are **locked-in design constraints** — implement them before layering on content.

---

## MUST-DO FOUNDATIONS (lock in now)

These are painful to retrofit later.

### 1. Single authoritative Combat / Agro Tick

**Do this first.**

One system runs at a **fixed timestep** (e.g. 20–30 Hz). Combat/agro logic does **not** live in `_physics_process`.

```
CombatTick (fixed timestep)
├─ agro decay
├─ agro increase (from events)
├─ threshold crossing (70 enter, 60 exit with hysteresis)
├─ combat enter / exit
├─ target selection (by entity_id)
└─ combat events (started / ended)
```

**Why:** Determinism, replay/debug, multiplayer-ready. Movement stays physics-driven; **decision-making does not.**

---

### 2. IDs everywhere, Nodes nowhere (for logic)

**Rule:** Logic uses **entity_id**. Rendering uses Node references. Conversion happens at the edge.

**Do not store Node references in logic for:**

- `combat_target` → use `combat_target_id : int`
- `herder` / `leader` → use `leader_id : int`
- `defend_target` → use `defend_target_id : int` (e.g. claim_id or entity_id)

**Why:** Entities can despawn safely; network replication is trivial; no dangling refs or crashes.

---

### 3. Agro as data, not state

**Agro is data. Combat is a state.**

Recommended model:

```
Agro (data)
├─ value (0–100)
├─ source_flags (bitmask: intrusion | damage | leader_attack | herd_steal | hostile_mode)
├─ current_target_id
├─ last_agro_event_time
```

Agro naturally decays, spikes, and crosses thresholds. Multiple sources stack cleanly. Remove the idea of a long-lived "agro state" for general combat; keep Agro Recover as a separate, caveman-only behavior if needed.

---

### 4. Explicit CommandContext for Follow / Guard

Unify Follow/Guard so it isn't scattered across herder, guard_mode, is_hostile.

```
CommandContext (per follower)
├─ commander_id
├─ mode: FOLLOW | GUARD | NONE
├─ is_hostile (derived from commander weapon equipped)
├─ issued_at_time
```

Every follower checks: (1) Do I have a CommandContext? (2) Is it still valid? (3) What mode applies? Avoids conditionals like "if herder == player AND guard_mode AND agro < 100…".

---

### 5. Hysteresis (no instant flips)

Clamp behavior transitions so states don't flicker.

- **Agro:** Enter combat at **70**, exit at **60** (not 70 both ways).
- **Weapon unequip:** Does **not** instantly pacify followers; decay or short delay.
- **Formation mode:** Only change after a short cooldown (e.g. X seconds) to avoid jitter.

**Why:** Prevents flickering, jitter, and edge-case exploits.

---

## SHOULD-DO SIMPLIFICATIONS (reduce complexity early)

### 6. Merge intrusion + AOA immediately

Do not keep two code paths. Use one structure:

```
EnemiesInClaim (per claim)
├─ full list (intruders in claim)
├─ inner_zone (AOA radius)
```

One loop, one code path, one set of bugs. Event-driven: maintain list via land claim Area2D `body_entered` / `body_exited`; defenders and agro tick read from it.

---

### 7. One spatial index for everything hostile

Do **not** create separate ThreatIndex, MammothIndex, CombatIndex.

Create **one** index:

```
HostileEntityIndex (spatial)
├─ Query by position/radius
├─ Entities tagged: CanAggro | CanBeAggroed | IsLeader | IsWild
```

Use tags on entities, not separate structures. All "who is near me / in this claim / in AOA" queries go through this index.

---

### 8. Formation only when not in combat

**Hard rule:**

- Formation (FOLLOW/GUARD positions) applies when **agro < 70**.
- Combat ignores formation entirely; unit chases/attacks.
- Re-form when agro decays below threshold.

Saves CPU and avoids weird movement during combat.

---

### 9. No per-frame scanning

Even before multiplayer:

- **No** `get_nodes_in_group()` inside logic loops.
- **No** per-frame distance checks for every NPC.

Throttle, index, or event-drive everything. CombatTick + HostileEntityIndex + EnemiesInClaim (event-driven) replace all broad scans.

---

## FUTURE-PROOFING HOOKS (cheap now, gold later)

### Event bus for combat/agro

Emit events even in single-player:

- `agro_increased`, `agro_threshold_crossed`
- `combat_started`, `combat_ended`
- `leader_command_changed`

Later: network replication and UI/audio/VFX subscribe to the same events.

---

### Intent vs Action separation

- **Intent:** "I want to attack entity_id X" (from agro/commands).
- **Action:** "I am swinging" (animation + cooldowns).

Intent changes come from CombatTick/commands; action execution from animation and cooldowns. Keeps AI logic simple and timing sane.

---

### Debug visualizations (add early)

Toggles for:

- Agro value above heads
- Leader bubble radius
- Formation slots
- Land claim intruder list
- Who is targeting whom (lines or labels)

Saves days during tuning and bug hunts.

---

## What NOT to overbuild yet

- Do **not** over-optimize combat math (weapon balance, crit curves).
- Do **not** add advanced morale/panic systems yet.
- Do **not** lock weapon balance numbers.

Those are **content tuning**, not foundations. Get the structure right first.

---

## Systems Hardening (do now)

Things that don't change RP or features but make the systems safer, clearer, and multiplayer-ready. Each item is small, cheap, and worth doing **now**. Use as pre-MP checklist.

### Full list

**1. EntityRegistry hardening**

- **Tweak:** Add `generation` or `spawn_version` per entity_id. Store `{entity_id, generation}` pairs in logic instead of raw IDs.
- **Why:** Prevents ID reuse bugs (old follower targeting a new entity that reused the same ID). Critical in MP and long sessions.
- **Cost:** +1 int compare per lookup.

**2. Explicit entity states (alive / dying / removed)**

- **Tweak:** Add an enum: `ALIVE`, `DYING`, `REMOVED`. Registry returns `null` for anything not `ALIVE`.
- **Why:** Stops edge bugs where combat or follow logic runs on dying entities. Makes death, flee, and despawn predictable.

**3. CommandContext ownership flag**

- **Tweak:** Add `command_source = PLAYER | NPC | SYSTEM`. BREAK only clears contexts with `PLAYER`.
- **Why:** Prevents player BREAK from nuking NPC formations or scripted behavior. Makes AI chains composable later.

**4. Follower cache on CommandContext**

- **Tweak:** Each commander keeps a small list/set of follower IDs. Followers register/unregister themselves.
- **Why:** Avoids scanning all entities to apply "weapon out = agro 70". Needed for scalable MP.

**5. CombatTick phase ordering (fixed)**

- **Tweak:** Define a strict order: (1) Validate entities, (2) Resolve command context, (3) Resolve combat target, (4) Set intent, (5) Emit events.
- **Why:** Eliminates frame-order bugs ("why did he attack then follow?"). Makes behavior deterministic across clients.

**6. Intent overwrite rules**

- **Tweak:** Only one intent slot per tick. Priority order: Combat > Recover > Command > Work/Idle.
- **Why:** Prevents double behaviors in one tick. Keeps animation/action layer simple.

**7. Agro clamping + reason tags**

- **Tweak:** Clamp agro to `[0, 100]`. Track `last_agro_reason` (e.g. `WEAPON`, `HIT`, `THREAT`, `DECAY`).
- **Why:** Debuggable ("why is this guy angry?"). Lets you tune decay without changing logic.

**8. "No target" combat guard**

- **Tweak:** If `combat_target_id` becomes invalid mid-tick: drop to `agro = 69`, clear combat intent immediately.
- **Why:** Prevents "shadow fighting" or stuck combat states. Smooth return to formation.

**9. HostileEntityIndex soft failure**

- **Tweak:** Queries return empty arrays, never null. Index auto-cleans invalid IDs lazily.
- **Why:** Makes every caller simpler. Prevents cascade crashes under load.

**10. Claim / leader mutual exclusion assert**

- **Tweak:** Assert (in debug): `!(leader_id != NONE && defend_claim_id != NONE)` — i.e. follow OR defend, not both.
- **Why:** Catches logic errors early. Forces clear mental model.

**11. Event bus fire-and-forget**

- **Tweak:** Events must never return values. No logic branching based on listeners.
- **Why:** Prevents UI/audio from accidentally becoming gameplay logic. Essential for server authority later.

**12. Save/load guards (even if SP only)**

- **Tweak:** On load: rebuild registry, revalidate all IDs, clear invalid CommandContexts.
- **Why:** Prevents corrupted saves. MP rejoin = same problem as load.

**13. Debug visualization hooks**

- **Tweak:** Optional overlays: leader_id arrow, combat_target_id line, agro value text.
- **Why:** Saves weeks of guesswork. Zero runtime cost when disabled.

**14. Data-driven thresholds**

- **Tweak:** Move magic numbers (70, 100, decay rates) into config tables.
- **Why:** Balance without code churn. Different species (mammoth vs caveman) stay clean.

**15. Deterministic randomness**

- **Tweak:** Use seeded RNG per entity or per tick batch.
- **Why:** MP sync safety. Replays and debugging become possible.

### If you only do 5 first (prevents silent, late-stage bugs)

1. Entity ID + generation  
2. Fixed CombatTick phase order  
3. Single intent per tick with priority  
4. Follower cache on CommandContext  
5. Combat target invalidation guard  

---

## Foundation summary (printable)

**Lock in now:**

- Fixed Combat/Agro tick (20–30 Hz); movement stays in physics.
- IDs for all targets (combat_target_id, leader_id, defend_target_id); Nodes only at render edge.
- Agro as data (value, source_flags, current_target_id, last_agro_event_time); combat as state.
- Unified CommandContext (commander_id, mode FOLLOW|GUARD|NONE, is_hostile, issued_at_time).
- Hysteresis: enter combat at 70, exit at 60; no instant pacify or formation flip.
- One HostileEntityIndex (spatial + tags); one EnemiesInClaim per claim (event-driven list + inner zone).
- Formation only when agro < 70; no per-frame scans (throttle, index, or events).

**Avoid:**

- Node references in logic; per-frame `get_nodes_in_group()` or distance scans; multiple overlapping agro systems; instant behavior flips.

---

## Phases (suggested order)

1. **Foundations:** CombatTick (fixed timestep 20–30 Hz), agro as data, IDs everywhere (combat_target_id, leader_id, defend_target_id), hysteresis (enter 70 / exit 60). No combat logic in `_physics_process`.
2. **Spatial & claims:** HostileEntityIndex (one index, tags CanAggro/CanBeAggroed/IsLeader/IsWild). EnemiesInClaim per claim (event-driven from Area2D); merge intrusion + AOA into one path. No per-frame scans.
3. **CommandContext & HUD:** CommandContext (commander_id, FOLLOW|GUARD|NONE, is_hostile). HUD: FOLLOW|GUARD toggle, BREAK. Hostile = leader weapon equipped; followers at 70 agro when hostile. Applies to NPC cavemen. Line colors: herd = darker red, follow = white/dim.
4. **Formations:** **FOLLOW** = loose behind leader; **GUARD** = tight around leader. Formation only when agro < 70. Leader-bubble and leader-attack triggers.
5. **Events & debug:** Event bus (agro_increased, combat_started/ended, leader_command_changed). Debug toggles (agro values, leader bubble, formation slots, intruder list, target lines).
6. **Combat/weapons (as needed):** Attack profiles, damage types, armor. Intent vs Action for attacks. Projectiles separate.
7. **Multiplayer (later):** Server runs CombatTick; replicate events; clients apply and render. No client-side agro/combat authority.

---

## Ideas (reference; see foundations above)

- **HostileEntityIndex:** One spatial index; entities tagged CanAggro, CanBeAggroed, IsLeader, IsWild. All hostile/threat queries go through it.
- **EnemiesInClaim:** Per-claim list from Area2D body_entered/body_exited; inner_zone for AOA. Defenders and CombatTick read from it.
- **CombatTick:** All agro decay, threshold, combat enter/exit, target selection run in one fixed-timestep pass; feed with events (damage, intrusion, leader attack, etc.).
- **Event bus:** agro_increased, agro_threshold_crossed, combat_started, combat_ended, leader_command_changed — single-player and network both consume these.
---

## Checklist (track progress)

**Foundations (must-do first)**

- [ ] CombatTick: fixed timestep (20–30 Hz); agro decay, threshold (70 enter / 60 exit), combat enter/exit, target selection; no combat logic in `_physics_process`
- [ ] IDs everywhere: combat_target_id, leader_id, defend_target_id; no Node refs in logic; resolve ID → Node at render edge only
- [ ] Agro as data: value, source_flags, current_target_id, last_agro_event_time; combat is state, agro is data
- [ ] CommandContext: commander_id, mode FOLLOW|GUARD|NONE, is_hostile, issued_at_time; followers check validity and mode
- [ ] Hysteresis: enter combat at 70, exit at 60; no instant pacify on weapon unequip; formation mode cooldown to avoid jitter

**Spatial & claims**

- [ ] HostileEntityIndex: one spatial index; tags CanAggro, CanBeAggroed, IsLeader, IsWild; no per-frame get_nodes_in_group
- [ ] EnemiesInClaim: per claim, event-driven (Area2D body_entered/body_exited); inner_zone for AOA; merge intrusion + AOA into one path

**HUD & behavior**

- [ ] HUD: FOLLOW | GUARD toggle, BREAK button; remove Friendly/Hostile; hostile = leader weapon equipped; followers at 70 agro when hostile; applies to NPC cavemen
- [ ] Formations: FOLLOW = loose behind leader, GUARD = tight around; formation only when agro < 70; leader-bubble and leader-attack triggers
- [ ] Agro 100 overrides follow/guard (attack even when following)
- [ ] Line colors: herd = darker red, follow = white/dim

**Future-proofing**

- [ ] Event bus: agro_increased, agro_threshold_crossed, combat_started, combat_ended, leader_command_changed
- [ ] Debug toggles: agro above heads, leader bubble, formation slots, intruder list, target lines
- [ ] Intent vs Action for attacks (intent from CombatTick; action from animation/cooldowns)

**Hardening (do first 5, then rest — see Systems Hardening section)**

- [ ] Entity ID + generation (registry; store {entity_id, generation} in logic)
- [ ] Fixed CombatTick phase order (validate → command → combat target → intent → events)
- [ ] Single intent per tick with priority (Combat > Recover > Command > Work/Idle)
- [ ] Follower cache on CommandContext (commander keeps list of follower IDs)
- [ ] Combat target invalidation guard (invalid target → agro 69, clear intent)
- [ ] Entity states ALIVE/DYING/REMOVED; command_source PLAYER|NPC|SYSTEM; agro clamp + last_agro_reason; HostileEntityIndex soft failure; claim/leader mutual exclusion assert; event bus fire-and-forget; save/load revalidate; data-driven thresholds; deterministic RNG

**Later**

- [ ] Combat/weapons: attack profiles, damage types, armor; projectiles separate
- [ ] Multiplayer: server runs CombatTick; replicate events; no client authority
- [ ] Raiding in clanbrain for AI cavemen NPCs

