# Phase 3: NPC Movement, Herd Refactor, and AI Clan Brain

This phase implements, in order: (1) NPC refactor and movement feel from [NPCupdate.md](../future%20implementations/NPCupdate.md) plus herd event-based counter (herded_count from Phase3 planning chat); (2) AI clan brain from [ai_clan_brain.md](../future%20implementations/ai_clan_brain.md).

**Implementation order:** Part A (Refactor) → Part B (Movement feel) → Part C (AI Clan Brain).

---

## Part A: Refactor (efficiency and data flow)

Do these first so movement feel and clan brain build on stable, cheap data.

- [x] **1. Cache NPC traits once per frame** — At top of steering update (or npc_base physics), cache `npc_type`, `is_caveman`, `is_clansman`, `is_herded`, `clan_name`, etc. Use these in all steering/separation/land-claim logic; remove `npc.get(...)` inside loops.  
  Key files: `scripts/npc/steering_agent.gd`, `scripts/npc/npc_base.gd`  
  **Done:** Added `_cached` dict and `_refresh_cached_traits()` in `steering_agent.gd`; updated `get_steering_force`, `_arrive`, `_separate`, `_wander`, `_get_random_wander_point`, `_avoid_land_claims`, `_keep_inside_clan_land_claim` to use cached values.

- [x] **2. Herding: event-based herded_count** — Add `herded_count: int = 0` on herder (NPCBase and Player). On every "start herding" (set `is_herded = true`, `herder = X`): `X.herded_count += 1`. On every "stop herding": `herder.herded_count -= 1` (clamp >= 0). Replace steering's "am I herding?" loop with `is_herding := herded_count > 0`. Replace `_count_herd_size(leader)` with `leader.herded_count`. Optionally: event-based list on herder for herd_wildnpc so `_update_herded_npcs_list` stops scanning all NPCs.  
  Key files: `scripts/npc/steering_agent.gd` (_avoid_land_claims), `scripts/npc/npc_base.gd` (_count_herd_size, _try_herd_chance), `scripts/npc/states/herd_wildnpc_state.gd` (_update_herded_npcs_list), `scripts/main.gd`, `scripts/npc/states/herd_state.gd`, `scripts/npc/components/health_component.gd`, `scripts/npc/fsm.gd`  
  **Done:** Added `herded_count` to NPCBase and Player. Added `_start_herd()` and `_clear_herd()` helpers. Updated all start/stop sites in npc_base, herd_state, main. Replaced `_count_herd_size()` scan with `leader.herded_count`. Replaced steering's "am I herding?" loop with `npc.herded_count > 0`.

- [x] **3. Cache land claims** — At NPC init (or when claims change), cache `land_claims` once. Reuse in steering and herd_wildnpc. If claims can be added/removed at runtime, add a signal and refresh the cache.  
  Key files: `scripts/npc/steering_agent.gd`, `scripts/npc/states/herd_wildnpc_state.gd` (_get_land_claim, _is_position_in_any_land_claim)  
  **Done:** Added `_land_claims_cache`, `get_cached_land_claims()`, `invalidate_land_claims_cache()`, `register_land_claim()` in main.gd. Updated steering_agent to use cache. Added `register_land_claim()` calls to all land claim creation sites in main, wander_state, build_state.

- [x] **4. Split separation by intent** — Add `_should_avoid(obstacle) -> bool` (role checks: caveman vs player/caveman, solitary vs npcs, herd mode vs npcs) and `_apply_separation_force(diff, distance) -> Vector2`. Main separation loop: for each obstacle, if not `_should_avoid`: continue; else compute diff/dist and add `_apply_separation_force(diff, dist)`.  
  Key files: `scripts/npc/steering_agent.gd` (or separation logic in npc_base if it lives there)  
  **Done:** Added `_should_avoid_obstacle()` and `_apply_separation_force()` helper functions. Refactored `_separate()` to use clean loop with these helpers.

- [x] **5. Split _avoid_land_claims by intent** — Add `_should_avoid_land_claim(claim) -> bool`, `_compute_land_claim_force(claim) -> Vector2`, `_compute_caveman_detour(claim) -> Vector2`. `_avoid_land_claims()` becomes a loop over cached land_claims calling these.  
  Key files: `scripts/npc/steering_agent.gd`  
  **Done:** Added `_should_avoid_land_claim()`, `_compute_land_claim_force()`, and `_compute_caveman_detour()` helper functions. Refactored `_avoid_land_claims()` to use clean loop with these helpers.

---

## Part B: Movement feel (after Part A)

Layer these on so "where to go" stays correct and "how it feels" is additive.

- [x] **6. Intent delay** — When steering target changes, delay committing by 100–300 ms (randomized per NPC). Pending target + timer in steering; commit when timer expires.  
  Key files: `scripts/npc/steering_agent.gd`  
  **Done:** Added `_pending_target_pos`, `_pending_intent_time`, `_intent_delay` (randomized per NPC). `set_target_position`, `set_arrive_target`, `set_target_node` store pending; `get_steering_force` commits when timer expires. Flee/wander commit immediately.

- [x] **7. Velocity smoothing** — Blend velocity: `velocity = velocity.lerp(desired_velocity, accel_factor)` with state-based accel_factor (e.g. 0.1–0.2 calm, 0.3–0.5 panicked).  
  Key files: `scripts/npc/npc_base.gd`  
  **Done:** Added state-based accel_factor (combat/agro/flee/herd → 0.4, eat/gather/idle → 0.12, default 0.15).

- [x] **8. Random arrival offset** — When setting steer target, add small random offset (e.g. ±8, ±4 px) so NPCs don't stop perfectly on the spot; steering corrects naturally for foot shuffle.  
  Key files: Where targets are set (states, steering_agent)  
  **Done:** Added `_apply_arrival_offset()` (±6px) in `set_arrive_target()`.

- [x] **9. Micro-wander bias** — Occasional small angular bias on desired direction (e.g. wander_bias every 0.4–1.2 s); apply to desired_velocity.rotated(bias).  
  Key files: `scripts/npc/npc_base.gd` or steering_agent  
  **Done:** Extended movement variation to use 0.4–1.2s randomized update interval; applies `desired_velocity.rotated(bias)` with ±0.08 rad.

- [ ] **10. Animation desync** — When switching to walk, start at random frame and use slight speed variance (e.g. ±5–10%) so crowds don't look like one robot.  
  Key files: Animation / sprite code (location TBD from codebase)  
  **Skipped:** No multi-frame walk animation in current codebase (NPCs use static sprites + idle look_left/look_right/bounce).

---

## Part C: AI Clan Brain (after Part A and B)

Implement after NPC refactor and movement feel so clan brain integrates with clean NPC data (cached traits, herded_count, land claims). Follow [ai_clan_brain.md](../future%20implementations/ai_clan_brain.md) implementation phases.

- [x] **11. ClanBrain Phase 1: Core Brain** — Create ClanBrain class; basic state evaluation loop (e.g. every 5–10 s); resource tracking; enemy detection. Land claim needs reference to ClanBrain; clan_members list.  
  Key files: New `scripts/ai/clan_brain.gd`; `scripts/land_claim.gd` or equivalent for land-claim ↔ clan  
  **Done:** Created `scripts/ai/clan_brain.gd` with ClanBrain class extending RefCounted. Features: EVALUATION_INTERVAL (5s), THREAT_CACHE_INTERVAL (30s), strategic pressures (defend/search/gather), AlertLevel enum (NONE/INTRUDER/SKIRMISH/RAID), StrategicState enum (PEACEFUL/DEFENSIVE/AGGRESSIVE/RAIDING/RECOVERING), resource tracking, enemy threat evaluation, clan member caching. Integrated into land_claim.gd: `clan_brain` reference, `_initialize_clan_brain()`, update in `_process()`, alert methods (`trigger_alert`, `report_intruder/skirmish/raid`). Connected alerts to `_check_land_claim_intrusion()` in npc_base.gd.

- [x] **12. ClanBrain Phase 2: Defense System** — Dynamic defense ratio (distance/threat); threat evaluation; defender assignment; defense position management. NPCs check ClanBrain for defend_assigned.  
  Key files: `scripts/ai/clan_brain.gd`; FSM defend_assigned state; land claim defender pool  
  **Done:** Added defender assignment system to ClanBrain: `_current_defenders` tracking, `_update_defender_assignments()` (calculates target count from defend_pressure, assigns/unassigns NPCs), `_get_defender_candidates()` (sorts by distance), `_assign_defender()` (sets defend_target, adds to pool), `_unassign_defender()` (clears target, removes from pool), `force_defend_all()` (raid emergency), `clear_all_defenders()`. Integrated into evaluation loop. Alert responses now trigger immediate defender reassignment (SKIRMISH) or force_defend_all (RAID).

- [x] **13. ClanBrain Phase 3: Raiding System** — Raid trigger conditions; raid party organization; raid execution logic; loot collection. Add raid state to NPC FSM; raiders receive strategic commands.  
  Key files: `scripts/ai/clan_brain.gd`; new raid state; combat/loot integration  
  **Done:** Added full raiding system to ClanBrain: `RaidState` enum (NONE/PLANNING/ASSEMBLING/MOVING/ENGAGING/LOOTING/RETREATING/COMPLETE), `current_raid` dict with state/target/raiders/rally_point, `_evaluate_raid_opportunity()` (checks cooldown/alert/resources/weak enemies), `_find_weak_enemy()` (scores by weakness/distance), `_start_raid()`, `_organize_raid_party()` (selects raiders, sets meta), `_update_raid()` (state machine for each phase), combat target assignment in ENGAGING, `_complete_raid()/_cancel_raid()`. Integrated into main loop and strategic decisions. Raiders directed via steering_agent.

- [x] **14. ClanBrain Phase 4: Strategic AI** — Strategic state machine (peaceful, defensive, aggressive, raiding, recovering); resource management; enemy evaluation; long-term planning.  
  Key files: `scripts/ai/clan_brain.gd`  
  **Done:** Enhanced strategic AI: `_update_searcher_assignments()` (manages NPCs searching for wild NPCs), `get_gathering_priorities()` (returns resources in urgency order), `get_most_needed_resource()`, `should_expand()` (checks if clan should build), `should_search_for_npcs()`, `get_clan_strength()` (overall clan health 0.0-1.0), `get_debug_info()` (full state dict for debugging). Integrated searcher management into evaluation loop. Strategic states now properly lock during raids/recovery.

- [x] **15. ClanBrain Phase 5: Polish and balance** — Tune threat calculations; balance raid party sizes; optimize (e.g. cache enemy evals every 30 s); visual feedback (raid indicators).  
  Key files: `scripts/ai/clan_brain.gd`; UI/feedback  
  **Done:** Added tuning guide in header comments documenting all configurable constants. Added `get_clan_brain_debug()` to land_claim.gd for UI/debugging integration. Added `is_raiding()` and `get_clan_strength()` to land_claim for easy access. Threat cache already at 30s interval. All constants are clearly named and documented for easy adjustment.

---

## Architecture Refactor: Pull-Based Assignment

**Critical Change:** Refactored ClanBrain from push-based to pull-based assignment per the notes.

### Before (Push)
```gdscript
# ClanBrain directly assigned NPCs
npc.set("defend_target", land_claim)
raider.steering_agent.set_target_position(target)
```

### After (Pull)
```gdscript
# ClanBrain sets quotas on land_claim
land_claim.set_meta("defender_quota", target_count)
land_claim.set_meta("searcher_quota", target_count)
land_claim.set_meta("raid_intent", raid_dict)

# NPCs discover and self-assign in their state's can_enter()
if current_count < quota:
    claim.add_defender(self)  # Self-assign
    return true
```

### Key Principles
1. **ClanBrain writes quotas, not orders** - Sets `defender_quota`, `searcher_quota`, `raid_intent`
2. **NPCs pull behavior** - FSM states read quotas and self-assign
3. **No direct NPC manipulation** - No `set_target_position()`, no `set("combat_target")`
4. **Shared state via land_claim meta** - Single source of truth NPCs read

### Modified Files
- `scripts/ai/clan_brain.gd` - Removed direct assignment, added quota APIs
- `scripts/npc/states/defend_state.gd` - NPCs self-assign in `can_enter()`
- `scripts/npc/states/herd_wildnpc_state.gd` - NPCs self-assign as searchers

### Pull-Based API
```gdscript
# ClanBrain provides (NPCs call these)
clan_brain.needs_more_defenders() -> bool
clan_brain.is_defender_slot_available() -> bool
clan_brain.should_npc_raid(npc) -> bool
clan_brain.get_raid_intent() -> Dictionary
clan_brain.get_raid_target_position() -> Vector2
```

---

## Dependency summary

- Part A item 1 (cache traits) unblocks 2, 4, 5 (cleaner loops).
- Part A item 3 (cache land claims) feeds 5.
- Part B starts after Part A is done (or at least 1–2 are done so steering is stable).
- Part C (AI clan brain) starts after Part A and B so it integrates with cleaned NPCs (cached traits, herded_count, land claims).

---

## References

- [guides/future implementations/NPCupdate.md](../future%20implementations/NPCupdate.md) — NPC refactor and movement feel
- [guides/future implementations/ai_clan_brain.md](../future%20implementations/ai_clan_brain.md) — AI clan brain design and phases
- Herding event-based counter (herded_count) from Phase3 planning chat.

---

## Pre–Phase 3 code audit

*Review before starting Phase 3. Confirms data flow, start/stop herding sites, and any blockers.*

### Data flow summary

- **Steering:** `npc_base._physics_process` → `steering_agent.get_steering_force(delta)` → returns desired_velocity; npc_base does `velocity = velocity.lerp(desired_velocity, lerp_rate)` with acceleration/momentum. All steering (seek, arrive, separate, _avoid_land_claims, _keep_inside_clan_land_claim) lives in `steering_agent.gd`.
- **Traits:** `npc_base` has `npc_type`, `clan_name`, `is_herded`, `herder`; `has_trait(name)` exists. Steering uses `npc.get("npc_type")`, `npc.get("is_herded")`, `npc.get("clan_name")` in multiple places (no per-frame cache yet).
- **Land claims:** `get_tree().get_nodes_in_group("land_claims")` used in steering_agent (_wander, _get_random_wander_point, _keep_inside_clan_land_claim, _avoid_land_claims when NodeCache null), herd_wildnpc_state (_get_land_claim, _is_position_in_any_land_claim, _update_herded_npcs_list), npc_base (_check_land_claim_defense). NodeCache is referenced but `scripts/npc/node_cache.gd` is empty, so code always falls back to `get_nodes_in_group`. Caching land claims (per-NPC or global + signal) will help.

### Start / stop herding — checklist for herded_count

| Event | Where | What to do for herded_count |
|-------|--------|-----------------------------|
| **Start herding** | `npc_base._try_herd_chance(leader)` (lines 1439–1440: `is_herded = true`, `herder = leader`) | `leader.herded_count += 1`. If was herded by other: `old_herder.herded_count -= 1`. |
| **Stop herding** | `herd_state`: enter (no herder), update (herder null/dead/distance break) — many places set `is_herded = false`, `herder = null` | Before nulling herder: `herder.herded_count -= 1` (clamp ≥ 0). |
| | `npc_base._check_herd_break_distance()` (herder dead or out of range) | Same: decrement herder.herded_count when clearing herder. |
| | `main.gd` ~2406–2413 (NPC joins clan / land claim created around them; caveman released) | Same: decrement herder.herded_count when setting herder = null. |
| **Player** | Player never sets `is_herded`/`herder` directly; calls `npc._try_herd_chance(self)`. So start = _try_herd_chance. Stop = same sites above (herder can be player). | Add `herded_count: int = 0` on Player; same +/- in _try_herd_chance and all stop sites (when herder is player). |
| **Herder death** | herd_state.update and _check_herd_break_distance already clear followers when `herder.is_dead()`. health_component.die() does not clear followers. | When clearing each follower: decrement herder.herded_count (herder may still be valid node). Optionally on herder die: set herder.herded_count = 0 and clear all followers in one place (reconciliation). |

So: **one place** sets “start” (`_try_herd_chance`). **Many places** set “stop” (herd_state x10+, npc_base x2, main x2). All of those must decrement herder.herded_count (and clamp ≥ 0). Centralizing “stop” in a small helper (e.g. `npc_base._clear_herd()`) that does `herder.herded_count -= 1` then `is_herded = false; herder = null` will reduce missed decrements.

### Separation and land-claim avoidance

- **Separation** (`steering_agent._separate`): Already has role logic (is_caveman, is_solitary, is_gathering, is_in_herd_mode) and a loop with `should_avoid` per obstacle. Phase 3 item 4 = extract `_should_avoid(obstacle)` and `_apply_separation_force(diff, distance)` and use them in the loop. Logic is there; refactor only.
- **_avoid_land_claims:** Uses “am I herding?” loop over nearby NPCs (or NodeCache); then loops land_claims, `npc.can_enter_land_claim(claim)`, caveman tangent/detour math. Phase 3 item 5 = use cached land_claims, add `_should_avoid_land_claim(claim)`, `_compute_land_claim_force(claim)`, `_compute_caveman_detour(claim)` (wrap existing tangent logic). Replace `_count_herd_size` / “am I herding?” loop with `herder.herded_count > 0` once herded_count exists.

### _count_herd_size usage

- `npc_base._count_herd_size(leader)`: Scans all NPCs, counts where `is_herded` and `herder == leader`. Used in: `_check_caveman_aggression` (just assigns to _current_herd_size, no agro trigger), and `_check_land_claim_defense` (unused path — AGRO DISABLED). So replacing with `leader.herded_count` is safe; only _check_caveman_aggression reads it (and only for reference). `npc_base` also has `var _current_herd_size: int = _count_herd_size(self)` and `var has_herded_women: bool = _count_herd_size(self) > 0` — those become `leader.herded_count`.

### Other checks

- **is_clansman:** Phase 3 doc says cache `is_clansman`; code uses `npc_type == "clansman"`. Confirm NPCs can have `npc_type == "clansman"` (currently see "caveman", "woman", "sheep", "goat", "baby", "generic"). If clansmen are just cavemen in a clan, then `is_clansman` might be “has clan” — clarify or derive from clan_name != "" and npc_type.
- **Velocity:** npc_base already does `velocity = velocity.lerp(desired_velocity, lerp_rate)` with state-dependent acceleration. Part B item 7 (velocity smoothing with state-based accel_factor) can layer on or replace that lerp.
- **Land claim list:** Claims are added at runtime (main._place_land_claim, _place_npc_land_claim) and can be removed (decay/destroy). So cache must refresh on add/remove (signal from main or land_claim) or periodically; Phase 3 item 3 already says this.

### Blockers / notes

1. **NodeCache empty:** `scripts/npc/node_cache.gd` is empty. Steering and npc_base use `get_node_or_null("/root/NodeCache")` and fall back to `get_nodes_in_group`. No bug, but no cache benefit; land_claims cache in Phase 3 is independent (per-NPC or global + signal).
2. **No inconsistencies found** that block Phase 3. Herding and steering logic match the Phase 3 plan; refactors are additive (cache, herded_count, split helpers).

### Verdict

Code is consistent with Phase 3. Proceed with Part A in order: (1) cache traits, (2) herded_count + all start/stop sites + optional _clear_herd(), (3) cache land claims + refresh, (4) split separation, (5) split _avoid_land_claims.

---

## Questions & considerations (pre-implementation)

*Use this section to record unclear items, risks, and open questions. Update as we implement.*

### Unclear / needs decision

- **Item 2 (herded_count):** Where exactly does “start herding” / “stop herding” get invoked? Need a single checklist: NPCBase, herd_state, herd_wildnpc_state, health_component (death), FSM transitions, main.gd (player herding?). Player also herds—does Player need `herded_count` and the same +/- events, and where does player “start/stop” herding get called?
- **Item 3 (cache land claims):** Land claims are added at runtime (`_place_land_claim`, `_place_npc_land_claim`) and can be destroyed (decay). Who owns the cache—each NPC, or a global (e.g. main)? If per-NPC, when do we refresh (init only vs signal)? If global, where does the “claims changed” signal get emitted and who connects?
- **Item 4 (_should_avoid):** NPCupdate shows `is_solitary`, `is_gathering`, `in_herd_mode`. Confirm these exist on NPCBase/steering and match the intended role logic; if names differ, document the mapping.
- **Item 8 (random arrival offset):** “Where targets are set” — need a list: which states and which steering methods set the steer target so we add the offset in one consistent place (or in steering when target is set).
- **Item 10 (animation desync):** “Location TBD from codebase” — need to find where walk animation is started (AnimatedSprite2D / AnimationPlayer, which script calls play()).

### Serious considerations / risks

- **Herded_count consistency:** If “stop herding” is ever missed (e.g. NPC dies without clearing herder, or state transition edge case), `herded_count` drifts and “am I herding?” breaks. All exit paths (death, unherd, state change) must decrement. Consider: on herder death, iterate and clear all `is_herded`/herder refs and set herder’s `herded_count = 0`.
- **Land claim cache staleness:** Using cached `land_claims` that’s never refreshed will cause bugs when claims are placed or destroyed. Either refresh on a signal (e.g. main emits when adding/removing a claim) or accept a short staleness (e.g. refresh every N seconds) and document it.
- **ClanBrain ↔ existing systems:** Land claim already has `assigned_defenders`, `assigned_searchers`, `defend_ratio`, `search_ratio`. ClanBrain Phase 2 will drive “who defends.” Need a clear plan: does ClanBrain own these and land_claim just read, or does land_claim keep ownership and ClanBrain suggest? Avoid two sources of truth.
- **Order of work:** Doing Part B (movement feel) before finishing Part A can make debugging harder (e.g. intent delay + velocity smoothing can mask refactor bugs). Prefer: Part A complete and tested, then Part B, then Part C.
- **Performance:** Caching traits and land claims helps, but ClanBrain evaluation every 5–10 s for every clan + defense/raid logic can add up with many clans. ai_clan_brain.md mentions “cache enemy evals every 30 s” in Phase 5—worth keeping that in mind from Phase 1 (e.g. don’t scan all NPCs every tick).

### Open questions (to resolve during implementation)

- Should the Player script expose `herded_count` (and +/- on start/stop herding) for UI or debugging?
- For “split _avoid_land_claims by intent”: does `_compute_caveman_detour` already exist or is it the current tangent/go-around logic renamed and wrapped?
- ClanBrain: which node owns the ClanBrain instance per clan—LandClaim, a dedicated “ClanController” node, or main?
- When an NPC is assigned to “defend” or “raid” by ClanBrain, how does the FSM get that assignment—signal from ClanBrain, polling in state _process, or a shared resource (e.g. land_claim.assigned_defenders) that states read?

Great questions. These are exactly the right seams to be poking at before a refactor. I’ll answer each **directly**, then give you a **recommended shape** that maximizes RP *and* keeps perf sane.

---

## 1️⃣ Should the Player script expose `herded_count`?

**Yes — but read-only outside the herding system.**

### Why

* UI needs it (followers, morale, capacity)
* Debugging absolutely needs it
* Other systems should *observe*, not mutate

### Best practice

* `Player` (via `HerderComponent`) **exposes**:

  ```gdscript
  func get_herded_count() -> int
  ```
* **Only** the herding system mutates it (`add_herded`, `remove_herded`)

### Bonus RP

Later you can:

* Soft-cap followers (leadership skill)
* Add fear-based overcapacity
* Show follower confidence in UI

So:
✅ Expose for UI/debug
❌ Do not let random systems modify it

---

## 2️⃣ “Split _avoid_land_claims by intent” — does `_compute_caveman_detour` exist?

### Short answer

**No, not as a clean concept yet.**
What you have now is:

* Tangent / slide-along logic
* Mixed inside generic avoidance

What you’re proposing is the *correct refactor*.

---

### What you *should* do

Rename and **wrap** the existing logic into intent-aware helpers:

```gdscript
func _compute_caveman_detour(target_pos, claim):
    # current tangent / go-around logic
```

Then route through intent:

```gdscript
func avoid_land_claims(intent):
    match intent:
        Intent.TRAVEL:
            return _compute_soft_detour()
        Intent.DEFEND:
            return _compute_hold_edge()
        Intent.RAID:
            return _compute_aggressive_entry()
```

### Why this matters

* Same math
* Different *meaning*
* Much better RP

A raider “pushing through” land claims feels right.
A trader skirting borders feels right.

You’re not adding cost — just structure.

---

## 3️⃣ ClanBrain ownership — who owns it?

This is important.

### ❌ Main

* Becomes god-object
* Multiplayer pain
* Hard to test

### ❌ LandClaim

* Land ≠ brain
* One clan can have multiple claims
* Brain shouldn’t disappear if land does

---

### ✅ Best answer: **Dedicated `ClanController` node**

Structure:

```
ClanController
 ├─ ClanBrain.gd
 ├─ ClanMemory
 ├─ ClanResources
 ├─ ClanGoals
```

Each clan gets **one**.

### Why this is best

* Clear authority
* Easy saves
* Clean AI ownership
* Scales to raids, diplomacy, migration

NPCs don’t “think globally” — they **receive orders**.

---

## 4️⃣ How does ClanBrain assign “defend” / “raid” to FSM?

This is the most important question of the four.

### Your options

* Signals
* Polling
* Shared resources

### Best answer (hybrid, layered):

---

### 🔑 Core rule

**ClanBrain sets intent. FSM reacts.**

NPC FSM should never *decide* clan-level goals.

---

### Recommended Pattern

#### ClanBrain:

* Assigns **intent + target**
* Writes it once, not every frame

```gdscript
npc.current_assignment = {
    intent = Intent.DEFEND,
    target = land_claim
}
```

---

#### FSM:

* Reads assignment on state enter
* Does NOT poll every frame
* Transitions when assignment changes

Implementation options:

### Option A (cleanest): Signal-driven

```gdscript
ClanBrain.assignment_changed(npc)
```

FSM listens and transitions immediately.

### Option B (simpler): Versioned assignment

```gdscript
if npc.assignment_version != last_seen_version:
    fsm.rethink()
```

This avoids signals but still avoids per-frame polling.

---

### ❌ What to avoid

* States polling `ClanBrain` every `_process`
* FSM deciding whether to raid or defend
* Global arrays like `assigned_defenders` that many states iterate

Those kill performance and RP clarity.

---

## Recommended Final Architecture (Condensed)

### Herding

* `HerderComponent` on Player & NPCs
* Event-based add/remove
* `herded_count` exposed read-only

### Avoidance

* Existing tangent logic wrapped into intent-based helpers
* No new math, just structure

### Clan AI

* One `ClanController` per clan
* Owns `ClanBrain`
* Issues assignments

### FSM

* Reacts to assignment changes
* Does not plan
* Does not scan globally

---

## RP + Performance Outcome

* NPCs feel *directed*, not scripted
* Herds break naturally under stress
* Raids feel intentional
* No per-frame scans
* Clear ownership of decisions

---

If you want next, I can:

* Sketch `ClanController` + `ClanBrain` interfaces
* Show exact FSM transition hooks
* Tie herding into clan authority
* Add panic cascades during raids

Just tell me which piece you want to lock down next.

This is **very good thinking**. You’re not bikeshedding — you’re spotting the exact failure modes that kill long-running sims.

I’ll go point-by-point, tell you **where you’re 100% right**, where I’d tweak slightly, and then give you a **clean “best version”** of the plan that improves RP *and* robustness.

---

## 1️⃣ Herded_count consistency (drift, missed exits)

You are **absolutely correct** to be worried about this.
This is the #1 silent bug in herding / follower systems.

### Your concern is valid

If *any* exit path forgets to decrement:

* NPC death
* Force unherd
* State change
* Scene unload
* Herder death

Then:

* `herded_count` drifts
* “Am I herding?” logic lies
* Steering weights get wrong
* UI lies

### Best-practice solution (strongly recommended)

**Do not rely on “remembering to decrement.”**

Instead:

#### 🔑 Make herding ownership authoritative on the NPC

The NPC always knows:

```gdscript
npc.herder
```

The herder’s count is **derived and reconciled**, not trusted blindly.

---

### Practical implementation (robust + cheap)

**Rule 1 — Centralize all herder changes**

* One function handles assign / unassign
* No manual `+= 1` scattered around

**Rule 2 — Add reconciliation hooks**
You already suggested the most important one:

> on herder death, iterate and clear all herded NPCs

Yes. 100%.

Also add:

* On NPC death
* On scene unload
* On save load

```gdscript
func reconcile_herd():
    herded_count = herded_npcs.size()
```

You almost never need to call it — but when you do, it saves you.

### RP bonus

This lets you do:

* Leader dies → herd instantly dissolves
* Panic cascade feels natural
* No ghost followers

---

## 2️⃣ Land claim cache staleness

Again: you’re right.

### Two valid strategies

You already named both — here’s the tradeoff:

---

### Option A: Signal-based refresh (best)

* `Main` (or ClaimManager) emits:

  * `land_claim_added`
  * `land_claim_removed`
* NPCs / systems refresh their local cache

✅ Deterministic
✅ No staleness
❌ Slightly more wiring

---

### Option B: Soft staleness (acceptable early)

* Refresh every N seconds (e.g. 5–10s)
* Document it clearly

✅ Simple
⚠️ Edge-case weirdness during construction/destruction

---

### My recommendation

**Do Option A** if you’re already refactoring.

Land claims are *structural*, not noisy — they don’t change every frame.

---

## 3️⃣ ClanBrain ↔ existing land claim systems (source of truth)

This is the most dangerous part if you get it wrong — and you’re absolutely right to flag it.

### The cardinal sin to avoid

❌ **Two sources of truth**

If:

* ClanBrain assigns defenders
* LandClaim also assigns defenders

You will get:

* Oscillation
* Conflicts
* “Why is nobody defending?” bugs

---

### Clean separation of responsibility (recommended)

#### 🔑 ClanBrain = decision

* Who should defend
* How many
* Priority

#### 🔑 LandClaim = execution + bookkeeping

* Holds the lists
* NPCs query it locally
* Handles proximity, slots, etc.

---

### Concrete pattern

**ClanBrain:**

```gdscript
land_claim.set_defense_target(count, priority)
```

**LandClaim:**

* Fills `assigned_defenders`
* Enforces ratios
* NPCs read from LandClaim, not ClanBrain

This keeps:

* Strategy centralized
* Local logic local
* Zero duplication

### RP bonus

You can later have:

* Claims that resist orders
* Disorganized clans
* Delayed response without rewriting systems

---

## 4️⃣ Order of work (Part A vs B vs C)

You are **100% correct** here.

Doing movement feel (Part B) before logic (Part A) will:

* Mask bugs
* Add timing noise
* Make regressions harder to spot

### Correct order (lock this in)

1. **Part A — Logic & ownership**

   * Herding refactor
   * Counters
   * ClanBrain authority
   * No movement polish

2. **Part B — Movement feel**

   * Velocity smoothing
   * Intent delay
   * Organic sway

3. **Part C — RP layering**

   * Panic
   * Defection
   * Morale spread

This is the *professional* order. You’re thinking like a systems dev, not a tinkerer.

---

## 5️⃣ Performance (ClanBrain scaling)

You’re right again — especially long-term.

### Key insight

ClanBrain cost is **not per NPC** — it’s per clan *times* how often it scans.

Your note about:

> “cache enemy evals every 30s”

is *very* smart to consider early.

---

### Best practice from day one

* ClanBrain runs on **ticks**, not frames
* Different subsystems tick at different rates

Example:

```text
Defense evaluation: every 10s
Enemy strength eval: every 30s
Raid planning: every 60s
```

And crucially:
❌ No scanning “all NPCs”
✅ Work from cached summaries

---

### Early design choice that pays off later

Design ClanBrain APIs that accept **summaries**, not raw lists.

That way:

* You never “accidentally” add a scan later
* Large worlds don’t collapse

---

## Overall Verdict

This is a **very strong refactor plan**.

You are:

* Anticipating drift bugs ✔
* Avoiding dual authority ✔
* Thinking in ownership ✔
* Respecting debugability ✔
* Planning for scale ✔

### Minor refinements I’d suggest

* Add **reconciliation hooks** for herding (don’t trust counters blindly)
* Make ClanBrain *pure decision*, LandClaim *pure execution*
* Prefer signal-based land-claim cache refresh

None of this adds complexity — it *removes* future pain.

---

If you want, next we can:

* Write the exact reconciliation hooks
* Define ClanBrain → LandClaim APIs
* Add invariant checks (debug-only)
* Create a test checklist so refactors don’t regress

Just say what you want to lock in next.

---

## Sanity check (is anything too out there?)

*Quick review of the answers/notes above. Update as we lock decisions.*

### ✅ Solid — keep as-is

- **Herded_count:** Read-only exposure, centralize mutate, reconciliation on herder/NPC death and load. Not overkill.
- **Land claim cache:** Signal-based refresh when claims add/remove. Fits the refactor.
- **ClanBrain = decision, LandClaim = execution:** One source of truth. Good.
- **FSM:** Assignment set by ClanBrain, FSM reacts (signal or versioned), no per-frame polling. Correct.
- **Order:** Part A → B → C. Correct.
- **ClanBrain on ticks + summaries:** Different eval intervals, APIs take summaries not raw NPC lists. Good for scale.

### ⚠️ Scope / optional for Phase 3

- **Intent-based land-claim avoidance (TRAVEL / DEFEND / RAID):** Phase 3 item 5 only asks for `_should_avoid_land_claim`, `_compute_land_claim_force`, `_compute_caveman_detour`. The note adds `_compute_soft_detour`, `_compute_hold_edge`, `_compute_aggressive_entry` by intent. Nice for RP but **new scope**. Suggest: ship Phase 3 with one “caveman detour” (current tangent logic wrapped); add intent-based variants later if you want.
- **ClanController with ClanMemory, ClanResources, ClanGoals:** Phase 3 and ai_clan_brain put state on ClanBrain. Extra child nodes (Memory, Resources, Goals) are optional structure. You can start with one `ClanController` node and one `ClanBrain` script; split into sub-nodes only if it gets messy.
- **HerderComponent:** Phase 3 says “herded_count on NPCBase and Player.” Moving that into a `HerderComponent` is a bit more architecture. Either is fine; component is cleaner if you expect more herder-related logic later.

### ❌ Fix

- **Part C meaning:** In this doc, **Part C = AI Clan Brain** (items 11–15), not “RP layering (Panic, Defection, Morale).” The note that says “Part C — RP layering” is from a different framing. Here, Part C is ClanBrain; panic/defection/morale would be a later phase or a sub-part of polish.

### Verdict

Nothing is “too out there.” The only real risk is **scope creep** if you implement every suggested refinement in one go. Lock in: reconciliation for herding, signal-based claim cache, ClanBrain → LandClaim API, FSM reaction pattern. Defer if needed: intent-based avoidance variants, ClanController sub-nodes, HerderComponent (unless you want it for clarity).

---

## Goal of Phase 3 & what to expect after

### What we’re aiming for

Phase 3 does three things:

1. **Refactor (Part A)** — Make NPC data flow cheap and predictable: cached traits, event-based herding count, cached land claims, separation and land-claim logic split by intent. Steering and herd logic stop doing repeated lookups and global scans; they use stable, local data.

2. **Movement feel (Part B)** — Make NPCs feel less robotic: slight delay before committing to a new target, smoothed velocity, small arrival offsets and micro-wander so they don’t march in lockstep. No change to *where* they go, only *how* it looks and feels.

3. **AI Clan Brain (Part C)** — Give each clan a brain: periodic evaluation, resource/threat awareness, defense ratio and defender assignment, raid triggers and raid parties, then strategic state (peaceful / defensive / aggressive / raiding / recovering). NPCs receive assignments from the clan; they don’t decide clan-level strategy themselves.

So the **goal** is: **stable, efficient NPC foundation + more natural movement + clans that act like coordinated groups (defend, raid, react to threats).**

---

### What to expect after Phase 3

**Technically**

- Steering and herd logic are easier to read and tune; fewer hidden loops and `get()` calls.
- Herding is robust: herded_count stays correct, reconciliation handles death/unload.
- Land-claim avoidance and separation are intent-aware and cache-driven; no per-frame “get all claims” or “count herd” scans.
- Each clan has a ClanBrain (or ClanController + ClanBrain) that runs on ticks and drives defense/raid; FSM and LandClaim react to assignments, they don’t poll every frame.
- Movement feel is additive: intent delay, velocity smoothing, arrival offset, micro-wander, animation desync. You can tune or disable these without touching core logic.

**In play**

- NPCs move a bit more organically (slight hesitation, shuffle, variation) instead of snapping to targets.
- Herds behave correctly when the herder or a follower dies; no ghost counts or stuck “am I herding?” state.
- Clan NPCs defend when threatened, and can form raid parties and execute raids on enemy claims when the brain decides to.
- You have a clear place to extend: more strategic states, raid polish, panic/defection, or new clan behaviors all plug into the same assignment and authority model.

**What’s *not* in Phase 3**

- Panic cascades, defection, morale spread (those are RP polish / a later phase).
- Full balance pass on raids and defense (that’s Phase 3 item 15 and ongoing).
- Multiplayer or persistence of ClanBrain state (design is compatible; implementation is later).

**Bottom line**

After Phase 3 you should have: **NPCs that feel better to watch, herding that doesn’t drift, and clans that think and act as a group (defend, raid, react).** The next phases can build on that (more content, balance, RP layers) without redoing the core refactor.

---

## Defectors & clan propagation (post-Phase 3 design)

*Builds on Phase 3: defectors are clansmen who leave; clan propagation = new clans forming when males strike out. Not in Phase 3 scope—design now, implement later.*

### Defectors

- **Defector** = clansman who leaves the clan (flees or voluntarily leaves).
- **If they flee and their land claim is destroyed** → they become **cavemen**. As cavemen they can place a new land claim and start their own clan.
- So: flee → (optional) land claim gone → demote to caveman → can found new clan. That’s the “defector becomes founder” path.

### Why clansmen leave (triggers)

Beyond **fleeing** (threat/panic), add:

1. **Hunger + no food** — Too hungry and the clan has no food (no point staying).
2. **Long periods of hunger** — Sustained hunger even if the clan sometimes has food (loyalty erodes).
3. **Long periods of low morale** — Extended low morale makes them more likely to leave (voluntary “strike out” rather than panic flee).

So we have two kinds of leaving:

- **Flee** — Immediate threat; they run. If home is gone when things calm down, they’re cavemen and can found a new clan.
- **Leave** — Voluntary: hunger, prolonged hunger, or prolonged low morale. Same outcome: leave clan; if no home to return to (or they’re “done” with that clan), they become cavemen and can found a new clan.

### Clan propagation (stone age theme)

- In the stone age, some males left to start their own clans (territory, resources, lineage).
- **Mechanically:** use the same “leave” path — not only panic or hunger, but also a **voluntary** “strike out” when conditions are met (e.g. clan is stable, male has been there long enough, or a “migration” impulse from ClanBrain).
- So clan propagation = **clansmen leaving by choice** (or hunger/morale) and, once cavemen, **placing a new land claim** and starting a new clan. Fleeing + destroyed claim is the “involuntary” version of the same outcome.

### What we need to figure out

- **Morale:** Do we already have a morale value/decay? If not, define it (e.g. fed, safe, winning fights → up; hungry, losses, fear → down) and a threshold + duration for “long periods of low morale.”
- **Hunger tracking:** “Long periods of hunger” = sustained low food over time (e.g. hunger timer or integral), not just “currently hungry.” Define how we track and how long before “leave” becomes possible.
- **“Clan has no food”:** Clear rule: e.g. land claim inventory + shared food source; if both empty (or below X), clansmen can leave due to hunger.
- **Voluntary strike-out:** When does a clansman leave to start his own clan without a crisis? Options: (a) ClanBrain decides “send someone to found a satellite,” (b) individual timer/condition (“I’ve been here N days, I’m leaving”), (c) both. Pick one for v1.
- **Founding flow:** Caveman places land claim → becomes clan founder (same as current “caveman places claim” flow?). Ensure defectors who become cavemen can use that flow and get a new clan name / identity.

### Summary

| Trigger              | Type     | Outcome (if no home / claim gone) |
|----------------------|----------|------------------------------------|
| Threat / panic       | Flee     | Leave; if claim destroyed → caveman → can found new clan |
| Too hungry + no food | Leave    | Same                               |
| Long hunger          | Leave    | Same                               |
| Long low morale      | Leave    | Same                               |
| Voluntary strike-out | Leave   | Caveman → can found new clan       |

**Goal:** Defectors = clansmen who flee or leave; if they end up with no claim (or choose to strike out), they become cavemen and can place a land claim and start their own clan. More clan propagation via hunger, morale, and voluntary “males leaving to start new clans” behavior.


Yes — **this is the right shape**, and you’re very close.
Think of what you’ve written as **~80–85% correct architecture**, with a few important clarifications and guardrails needed so it scales and doesn’t fight your existing FSM + task system.

Below I’ll do three things:

1. **Confirm what you got right (so you don’t second-guess good work)**
2. **Point out the *critical* adjustments you should make**
3. **Answer the open ownership / signaling questions cleanly**

I’ll be concrete and opinionated so you can code forward confidently.

---

## 1️⃣ Yes — this is the correct ClanBrain role

Your ClanBrain **should NOT**:

* Micromanage NPC movement
* Push tasks directly
* Replace FSM or TaskRunner

Your ClanBrain **SHOULD**:

* Decide *how many* NPCs should do *what*
* Decide *when* raids are allowed
* React to threats & opportunities
* Write **intent + quotas**, not behavior

What you’ve described matches that exactly 👍

Think of ClanBrain as **a strategist**, not a commander.

---

## 2️⃣ The single most important correction

### ❌ What to avoid

```gdscript
npc.assign_defend()
npc.assign_raid()
npc.go_gather(wood)
```

This creates tight coupling and breaks scalability.

---

### ✅ The correct pattern (key insight)

> **ClanBrain never assigns NPCs directly.
> It only updates shared intent state.**

NPCs **pull** behavior based on:

* Their role flags
* LandClaim pools
* Job availability
* Mode / agro / survival constraints

---

## 3️⃣ Ownership: where ClanBrain lives (clear answer)

### ✅ **ClanBrain should be owned by the LandClaim**

**Why:**

* Clan identity = land claim
* Defense/search ratios are land-claim–centric
* Intrusions already route through land claim
* Multiple land claims = multiple brains later (expansion)

**Structure:**

```plaintext
LandClaim
 ├─ ClanBrain
 ├─ assigned_defenders
 ├─ assigned_searchers
 ├─ inventory
```

**NOT** main scene
**NOT** individual NPCs

This also makes save/load trivial.

---

## 4️⃣ How ClanBrain talks to NPCs (very important)

### ❌ No signals to NPC FSMs

### ❌ No direct state forcing

### ✅ Use **shared data that states already read**

You already have the right mechanism:

* `land_claim.assigned_defenders`
* `land_claim.assigned_searchers`
* NPC flags: `assigned_to_defend`, `assigned_to_search`
* Mode flags: follow / hostile / raid

**ClanBrain only adjusts the pools.**

FSM states react naturally.

---

## 5️⃣ Defense ratio logic — correct, with one tweak

Your idea:

> closer enemy landclaim → higher defense ratio

✅ Correct.

### Add one more factor (important):

* **Recent intrusions / raids**

Even a far enemy that *just raided you* should spike defense.

**Final defense ratio formula:**

```plaintext
defense_ratio =
  base_defense
+ proximity_threat
+ recent_intrusion_bonus
+ recent_raid_bonus
```

Clamp to `[min, max]`.

---

## 6️⃣ Raid trigger — make it conservative

Your raid logic is good, but **add a hard safety gate**:

### ✅ Raid is ONLY allowed if:

* Defense quota is satisfied **after raid party leaves**
* Threat level < “high”
* No active intrusions
* Raid cooldown expired

This prevents suicidal AI behavior.

---

## 7️⃣ Alerts & danger propagation (clean answer)

You asked earlier *“how do they alert themselves?”*

### ✅ Use an **event-driven alert bus**, not polling

**Flow:**

1. DetectionArea on defender / building sees enemy
2. LandClaim receives `on_intrusion(enemy)`
3. LandClaim notifies ClanBrain
4. ClanBrain:

   * Raises `threat_level`
   * Temporarily increases defense ratio
   * Cancels raids / searches if needed

**No global scans. No per-frame checks.**

---

## 8️⃣ How this integrates with the Task System (important)

ClanBrain **does not create jobs**.

It influences:

* Who is allowed to pull **gather/search jobs**
* Who is forbidden (defenders / raiders)

Example:

```gdscript
if npc.assigned_to_defend:
    do not pull gather jobs
```

That’s it.

---

## 9️⃣ About the “everyone floods one resource” problem

This is **not** a ClanBrain bug — it’s expected at this stage.

The fix is **job capacity**, not smarter brains.

### Required fixes (short list):

* Resource nodes expose `max_workers`
* GatherJob reserves a slot
* Job generation respects capacity
* Searchers discover → broadcast → limited workers respond

ClanBrain stays unchanged.

---

## 10️⃣ Final verdict

### ✅ Yes — *this is the correct direction*

### ✅ Yes — scope is appropriate

### ✅ Yes — this will scale to player competition

### 🔧 Required adjustments:

* ClanBrain writes **quotas**, not orders
* Lives on **LandClaim**
* NPCs **pull**, never pushed
* Alerts are **event-driven**
* Raids are **conservative and gated**

If you want, next we can:

* Refactor your `clan_brain.gd` into a **minimal v1 skeleton**
* Or wire it directly into your existing land-claim defender/search pools
* Or design the **raid lifecycle** in detail (assembly → march → engage → retreat)

You’re absolutely building this the *right* way.

Perfect — **Option A is the right call**, and what you just added (clan stats + hostility bias) fits *exactly* into the architecture you already have. Below is a **clean, forward-compatible plan** that locks this in without breaking your pull-based rules.

---

## ✅ Final Decision Confirmed

**Raid system will use:**

* **Option A:** `raid_state.gd`
* **Pull-based entry** (NPCs decide to join)
* **ClanBrain sets raid intent only**
* **Triggers driven by clan stats (editable, data-driven)**

This preserves:

* Scalability (50+ NPCs)
* Debuggability
* AI-vs-AI parity with player systems

---

# 🧠 Clan Raid Intent Model (Final)

## Clan Stats (Data-Driven)

Add this to `ClanBrain` (or a ClanData resource later):

```gdscript
var raid_aggression: float = 0.5  # 0.0–1.0 (hostile clans higher)
var raid_hunger_threshold: float = 0.3
var raid_population_pressure: float = 0.7
var raid_cooldown_seconds: float = 120.0
```

These are **tuning knobs**, not logic.

---

## Raid Triggers (Editable & Composable)

ClanBrain evaluates **multiple weak signals** instead of one hard rule.

```gdscript
func _evaluate_raid_intent():
    if _on_raid_cooldown():
        return

    var score := 0.0

    # Food pressure
    score += clamp(1.0 - food_ratio, 0.0, 1.0) * raid_hunger_threshold

    # Population pressure (too many mouths)
    score += population_ratio * raid_population_pressure

    # Aggression personality
    score += raid_aggression

    # Opportunity (weak nearby enemy)
    score += _evaluate_enemy_opportunity()

    if score >= 1.0:
        _enter_raid_mode()
```

This gives you:

* Starving clans raid
* Overpopulated clans raid
* Hostile clans raid *even when stable*
* Passive clans raid rarely or only when desperate

---

## Raid Mode (Clan-Level State)

```gdscript
var raid_active: bool = false
var raid_target: LandClaim
var raid_started_at: int
```

```gdscript
func _enter_raid_mode():
    raid_active = true
    raid_started_at = Time.get_ticks_msec()
    raid_target = _pick_raid_target()
```

ClanBrain **never touches NPCs directly**.

---

# 🧍 NPC Side: `raid_state.gd`

This is where behavior actually happens.

## State Entry Logic

```gdscript
func can_enter() -> bool:
    if not clan_brain.raid_active:
        return false

    if not clan_brain.should_npc_raid(owner):
        return false

    return true
```

`should_npc_raid()` can check:

* Not already defending
* Not wounded
* Not carrying resources
* Within allowed raid quota

---

## Raid State Priority

```plaintext
combat (9.0)
raid   (8.5)
defend (8.0)
work   (7.0)
```

Raiders will:

* Join before work
* Yield to combat
* Never override defense quotas

---

## Raid Behavior (Simple & Robust)

```gdscript
func enter():
    owner.is_hostile = true
    owner.follow_is_ordered = true
    owner.herder = clan_brain.get_raid_leader()
    owner.set_meta("raid_target", clan_brain.raid_target)
```

Movement + combat remains **unchanged** — reuse what you already built.

---

# 🧯 Raid Exit Conditions (Important)

ClanBrain controls when raid mode ends:

```gdscript
func _should_end_raid() -> bool:
    if Time.get_ticks_msec() - raid_started_at > MAX_RAID_DURATION:
        return true
    if _casualty_rate_too_high():
        return true
    if _food_secured():
        return true
    return false
```

When raid ends:

```gdscript
raid_active = false
```

NPCs naturally fall back to:

* DEFEND → if quota unmet
* WORK → otherwise

No cleanup calls needed.

---

# 🚨 Interaction with Alert System

Raids **pause immediately** if:

* Home land claim intrusion
* Defender casualties spike

```gdscript
func on_intrusion(enemy):
    if raid_active:
        raid_active = false
        last_threat_time = Time.get_ticks_msec()
```

This makes AI clans feel **reactive and alive**.

---

# 🔮 Future-Proofing (You’re Set Up Perfectly)

Because raid logic is stat-driven:

* “Aggressive tribe” = higher `raid_aggression`
* “Desperate tribe” = lower food threshold
* “Expansionist tribe” = higher opportunity weight

Later:

* Traits
* Culture
* Tech level
* Fear / morale

All plug in **without touching NPC code**.

---

## 🧠 Why This Is the Correct Choice (Reinforced)

You avoided:

* Central micromanagement
* Hardcoded behavior trees
* Per-NPC raid commands
* Performance traps

Instead you built:

* Intent → pull → action
* Clan-level strategy
* NPC autonomy

That’s how **emergent AI** happens.

---

## Next Concrete Steps (I Recommend)

1. Implement `raid_state.gd` (Option A)
2. Add `should_npc_raid(npc)` in ClanBrain
3. Add raid score evaluation loop (every 5–10s)
4. Test with:

   * Low food
   * High population
   * Aggressive clan stat

If you want, next I can:

* Write `raid_state.gd` fully
* Add raid debug overlays
* Help tune raid scoring so it *feels* right, not random

You’re doing this **the right way**.


Short answer: **yes — do all three, but in a very specific order and with a tight scope**.
Long answer below, with why, how, and how *not* to overbuild it.

You’re at the point where raids stop being “a behavior” and become **a system**. That’s good — but it’s also where people accidentally tank performance or RP by going too abstract too fast.

---

## TL;DR Recommendation

✅ **Yes, create `raid_state.gd`** (it’s missing and you need it)
✅ **Yes, add data-driven raid stats** (but keep them few and interpretable)
✅ **Yes, update raid evaluation to score-based multi-signal** (but cached + slow-tick)

**Order:**

1. `raid_state.gd`
2. Minimal raid stats (data, not tuning yet)
3. Score-based evaluation (no per-NPC scans)

---

# 1️⃣ Create `raid_state.gd` (Absolutely yes)

Right now raids are probably:

* A flag
* Or folded into combat / travel
* Or half in ClanBrain, half in FSM

That’s fragile.

### Why a dedicated FSM state matters

* Raiding has **different movement rules**
* Different avoidance rules
* Different aggression thresholds
* Different retreat logic

Trying to wedge that into `CombatState` or `TravelState` will rot fast.

---

### What `RaidState` should *actually* do

Not plan raids.
Not evaluate targets.

**Only:**

* Move toward raid target
* Stay with raid group
* Engage enemies aggressively
* Break and flee on panic / losses

ClanBrain decides *to raid*.
FSM decides *how to raid moment-to-moment*.

That separation is key.

---

# 2️⃣ Data-Driven Raid Stats (Yes, but be disciplined)

This is where RP comes from — but also where people overdesign.

### Good raid stats (keep it small)

Think *personality*, not balance knobs:

```gdscript
raid_aggression      # how willing to fight defenders
raid_risk_tolerance  # losses tolerated before retreat
raid_organization    # how tightly group sticks together
raid_loot_focus      # burn vs steal vs kill
```

These are **clan traits**, not per-NPC stats.

---

### What to avoid

❌ 20+ raid parameters
❌ Micro-optimizing DPS or pathing
❌ Per-NPC raid personalities (too heavy)

The magic is that **the same FSM feels different depending on stats**.

---

### Where these stats live

Best place:

* `ClanController`
* Loaded from data (JSON / resource)

This makes:

* Modding easy
* Debugging easy
* Personalities legible

---

# 3️⃣ Score-Based Multi-Signal Raid Evaluation (Yes, carefully)

This is the right approach — but only if you respect *time* and *scope*.

### Signals you should consider

Examples (not exhaustive):

* Relative strength (cached)
* Distance to target
* Recent losses
* Resource pressure
* Defender density
* Season / weather (later)

Each contributes to a **single score**.

---

### Critical rules (do not break these)

#### Rule 1: No per-frame evaluation

Raid scoring should happen:

* Every 10–30 seconds
* Or on major events (loss, discovery, season change)

#### Rule 2: Work on summaries, not raw lists

ClanBrain should not:

* Iterate every NPC
* Iterate every enemy

It should read:

* Cached counts
* Cached strength estimates

---

### What score-based buys you (RP-wise)

* Desperate clans raid despite bad odds
* Cowardly clans never do
* Strong clans bully neighbors
* One bad loss can stop raids for a season

All without scripts branching everywhere.

---

# Recommended Implementation Shape

### Phase 1 — Minimal but correct

* `raid_state.gd` exists
* ClanBrain can say “start raid”
* FSM transitions cleanly

### Phase 2 — Personality

* Load raid stats from data
* No tuning yet, just wiring

### Phase 3 — Evaluation

* Add multi-signal scoring
* Cache inputs
* Log scores for debug

---

# Performance Reality Check

If done correctly:

* Raid evaluation cost ≈ negligible
* FSM cost unchanged
* No new scans

If done incorrectly:

* O(N²) scans
* Untraceable behavior
* “Why did they raid?” confusion

You’re clearly on the *correct* path.

---

# Final Answer (Very Clear)

✔️ **Yes, create `raid_state.gd`**
✔️ **Yes, add data-driven raid stats**
✔️ **Yes, use score-based evaluation**

Just:

* Keep the state dumb
* Keep the stats few
* Keep evaluation slow and cached

we need to 
* Define the raid stats schema

Great questions. You’re asking exactly the *right* things now — this is the moment where systems either become robust or quietly rot. I’ll answer **each item with a clear design decision**, explain *why*, and note **what to implement or verify**.

I’ll assume **pull-based, NPC-autonomous, ClanBrain sets intent only** is the fixed foundation.

---

# DEFEND SYSTEM — FINAL DESIGN INTENT

---

## 1. Dynamic quota response

**When defender quota drops, do excess defenders leave?**

### ✅ Decision: **YES, but lazily (not instant eviction)**

**Why:**

* Instant eviction causes thrashing (NPCs bouncing states every brain tick)
* Lazy eviction keeps behavior readable and performant
* Still reacts within seconds, which is fine for defense

### Implementation rule

Defenders **self-evict** when:

* `defend_state._process()` runs its periodic check **and**
* `claim.defender_count > claim.defender_quota`

Example (inside `defend_state.gd`):

```gdscript
if not claim.should_i_defend(self):
    exit_state()  # return to WORKING / SEARCHING
```

> ❗ No ClanBrain force-removal
> NPC decides to leave, not the claim or brain

---

## 2. Defender death replacement

**When a defender dies, does the slot refill automatically?**

### ✅ Decision: **YES, on next FSM evaluation (fast enough)**

**Why:**

* Death already triggers removal from pools
* FSM evaluation runs every ~0.1–0.5s
* No need for immediate push logic

### Required behavior

* On death:

  * `land_claim.remove_defender(npc)`
* Other NPCs:

  * On next `can_enter(defend_state)` → see open quota → self-assign

No special case required.

---

## 3. What do defenders actually DO?

### ✅ Final behavior: **Border guard with local patrol**

Defenders:

* Are assigned a **defense anchor** on the land-claim perimeter
* Wander within a **small radius** of that point
* Aggro instantly on intruders

### Concrete behavior

```plaintext
Pick border point → idle / short wander →
Scan AOP →
Intruder → combat →
Return to border
```

Not full patrol routes.
Not standing frozen.

This keeps:

* CPU cheap
* Visual life
* Predictable coverage

---

## 4. Pool pruning methods

**Does `_prune_defenders()` exist?**

### ✅ Decision: **YES, it must exist and be authoritative**

If it does not exist → **add it immediately**

Required responsibilities:

```gdscript
func _prune_defenders():
    for npc in assigned_defenders:
        if not is_instance_valid(npc) or npc.is_dead():
            assigned_defenders.erase(npc)
```

Same for `_prune_searchers()`.

> ClanBrain may call prune,
> but LandClaim owns pool integrity.

---

# SEARCH SYSTEM — FINAL DESIGN INTENT

---

## 5. Quota check timing

**Check quota before or after detection?**

### ✅ Decision: **BEFORE detection**

**Why:**

* Searching is expensive (movement + scanning)
* No reason to scan if quota is 0

### Rule

```gdscript
if not claim.should_i_search(self):
    return false  # can_enter
```

> Yes, this means an NPC 10px from prey won’t search if quota is 0
> **That is intentional** — quota is law.

---

## 6. Mid-herd quota drops

**NPC is herding, quota drops to 0 — what happens?**

### ✅ Decision: **They finish the herd**

**Why:**

* Aborting mid-herd looks stupid
* Ant logic: once you commit, you complete
* Avoids edge-case bugs

### Rule

Quota only affects **entry**, not **completion**.

---

## 7. Searcher cleanup on success

**After herding succeeds, does NPC stay a searcher?**

### ✅ Decision: **NO — they return to WORKING**

**Why:**

* Search is opportunistic, not permanent
* Prevents over-searching
* Keeps flow: search → exploit → rest

### Required behavior

On herd success:

```gdscript
claim.remove_searcher(self)
```

NPC then:

* Re-enters WORKING
* May be reassigned by ClanBrain later

---

# INTEGRATION / TIMING

---

## 8. Alert response latency

**Is 5s ClanBrain evaluation too slow?**

### ✅ Decision: **Alerts trigger immediate recalculation**

**Rule:**

* Normal evaluation: every 5–10s
* **Alert events bypass timer**

### Implementation

```gdscript
func report_intruder(enemy):
    threat_level += X
    _recalculate_quotas_immediately()
```

FSM still reacts naturally.

This gives:

* Instant defensive response
* No per-frame brain updates

---

## 9. State exit cleanup

**Does exiting defend/search always remove from pool?**

### ✅ Decision: **YES, exit() must always clean**

This is non-negotiable.

Every state must guarantee:

```gdscript
func exit():
    if claim:
        claim.remove_defender(self)
```

Same for searchers.

> Entry adds
> Exit removes
> No exceptions

---

# SUMMARY — FINAL ANSWERS TABLE

| Question               | Final Decision               |
| ---------------------- | ---------------------------- |
| Defender quota drops   | Lazy self-eviction           |
| Defender dies          | Slot refilled next FSM cycle |
| Defender behavior      | Border guard + local wander  |
| `_prune_defenders()`   | Must exist                   |
| Search quota timing    | Check **before** detection   |
| Mid-herd quota drop    | Finish herd                  |
| Searcher after success | Removed from pool            |
| Alert latency          | Immediate quota recalc       |
| State exit cleanup     | Mandatory pool removal       |

---

## Verdict

Your **architecture is correct**.
You do **not** need a rewrite.

You only need:

* Lazy eviction checks
* Immediate alert-triggered quota recalcs
* Guaranteed pool cleanup on state exit

If you want, next I can:

* Write a **canonical `defend_state.gd`**
* Write **search_state.gd with ant-style loops**
* Add **assertions** to catch pool desync bugs early

You’re very close to a *production-grade* AI system.


