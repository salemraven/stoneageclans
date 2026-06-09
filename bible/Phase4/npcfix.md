# NPC Occupation System — Code Context for Redesign

Answers to the questions in npcfix.md, extracted from the actual codebase.

---

## 1️⃣ `scripts/buildings/building_base.gd`

### Slot definitions

```gdscript
var woman_slots: Array = []   # Array of Node (women occupying)
var animal_slots: Array = []  # Array of Node (sheep or goats)
```

- **Initialization:** `_init_slots()` resizes and fills with `null` (lines 86-92)
- **Counts:** Oven/Farm/Dairy: `get_woman_slot_count()` returns 1-2; `get_animal_slot_count()` returns 3 for Farm/Dairy

### set_occupant(slot_index, npc, is_woman)

- Sets `slots[slot_index] = npc`
- Hides NPC sprite
- For women: `set_active(true)`, `_notify_occupation_changed()`
- For animals: `_update_building_sprite()`
- **Does NOT** touch NPC `assigned_building`

### clear_occupant(slot_index, is_woman)

- Sets `slots[slot_index] = null`
- For leaving NPC: `claim.release_items(npc_leaving)`, makes sprite visible
- For women: clears `job_reserved_by`, `transport_reserved_by`; may `set_active(false)`
- **Does NOT** clear NPC `assigned_building`

### Legacy: add_animal, reserve_animal_slot, unreserve_animal_slot (REMOVED)

Animals now use **OccupationSystem** `request_slot` → `confirm_arrival` → `set_occupant`. The legacy `add_animal()`, `reserve_animal_slot()`, and `unreserve_animal_slot()` have been removed. Per-slot reservation uses `animal_slot_reserved_by`.

### Building ownership of NPC state

- Building does **not** write to NPC state
- Building only holds references in `woman_slots` / `animal_slots`

### Building destruction clears occupants?

**No.** `_destroy_building()` (lines 248-255):

- Calls `ClaimBuildingIndex.unregister_building(self)`
- Calls `queue_free()`  
- Does **not** iterate `woman_slots` / `animal_slots` or call `clear_occupant`

Occupants stay referenced until the building is freed; NPCs may keep stale references to a freed building.

---

## 2️⃣ `scripts/npc/npc_base.gd`

### assigned_building

```gdscript
var assigned_building: Node2D = null  # Building this NPC is assigned to (for sheep/goats in land claims)
```

- Acts as **target** and **workplace** for animals pathing to Farm/Dairy
- Set when `_check_and_assign_to_building` finds a building and reserves a slot
- Cleared when: `OccupationSystem.confirm_arrival` succeeds, timeout (5s), building physically full
- **Not** cleared when: `clear_occupant` (drag removal), NPC death

### _check_and_assign_to_building (lines 2826-3060)

1. Only for sheep/goat with `clan_name != ""`
2. If `assigned_building` is valid: path to it, call `OccupationSystem.confirm_arrival` when within range
3. If no assignment: get `ClaimBuildingIndex.get_buildings_in_claim(my_claim)`
4. For each matching building (Farm→sheep, Dairy→goat): if slot available (OccupationSystem) and distance < current best → pick it
5. **Does not** check whether this NPC is already in the building
6. Calls `OccupationSystem.request_slot`; if it fails, skips
7. Sets `assigned_building = nearest_building` (or uses `workplace_building` from system)

### Building arrival handling

- When in range: calls `OccupationSystem.confirm_arrival(self)`
- On success: `assigned_building = null`, `steering_agent.set_wander()`
- On failure: keeps `assigned_building` and retries

### _try_join_clan_from_claim

- Used for herd join, wander join, placement join
- Sets `clan_name`; for sheep/goat, calls `_check_and_assign_to_building()` right after join

### _exit_tree

- If assigned: `OccupationSystem.unassign(npc, "exit_tree")` or equivalent
- Does **not** call `clear_occupant_for_npc` (NPC may already be queued for free)

---

## 3️⃣ `scripts/npc/states/occupy_building_state.gd`

### How women choose buildings

- `get_tree().get_nodes_in_group("buildings")`
- Filter: `requires_woman`, same clan, occupiable (active or Farm/Dairy with empty/has-animal), not occupied, within 500px
- Pick closest within range

### Do they modify building state directly?

Yes. `_occupy_building()` calls `target_building.set_occupied(npc)` which calls `set_occupant()`.

### Do they store assignment locally?

- `target_building` stored in state; cleared after occupation
- Women do **not** use `assigned_building`; they use the FSM state

### Difference from animals

- Women: FSM, pull model, `get_nodes_in_group("buildings")`, 500px range, no reservation
- Animals: npc_base poll, push model, `ClaimBuildingIndex`, reservation, `assigned_building`

---

## 4️⃣ `scripts/inventory/building_inventory_ui.gd`

### Who calls clear_occupant

1. **try_resolve_occupation_drag_release** (line 1549): slot-to-map drag → `b.clear_occupant(src_idx, src_woman)`
2. **_handle_npc_drop_on_occupation_slot** (lines 1612, 1621): slot-to-slot or replace occupant → `building.clear_occupant(...)`

### Does it touch NPC fields?

No. Only calls `building.clear_occupant()`. Does not set `npc.assigned_building = null`.

### Does it assume building owns truth?

Yes. UI treats building slots as source of truth. It does not coordinate with `assigned_building` on the NPC.

---

# 🎯 Answers to Design Questions

## 1. Does building own slot state?

**Yes.** `woman_slots` and `animal_slots` are the source of truth for who is in which slot.

## 2. Does NPC own workplace state?

**Partially.** For animals, `assigned_building` is the NPC’s “target/workplace,” but:
- It is not cleared when the building removes the NPC (e.g. drag)
- It is not updated when the NPC is already in a slot (causing re-assignment loops)

Women do not use `assigned_building`; they use FSM state (`target_building`).

## 3. Is there any circular dependency?

**Indirect.** Building holds NPC refs; NPC holds `assigned_building`. Clear paths:
- Building → NPC (slot contents)
- NPC → Building (`assigned_building`)

No direct cycle, but both sides must be updated together, and they often are not.

## 4. Is assignment event-driven or polling-driven?

**Polling.**  
- Animals: `_check_and_assign_to_building` runs periodically from `_physics_process` (throttled by `assignment_check_interval`)  
- Women: FSM `occupy_building_state.update()` runs every frame and re-scans buildings

No events when slots free up; NPCs discover work by polling.

## 5. Does any system bypass another?

**Yes.**  
- UI drag removal: `clear_occupant` only; does not clear `assigned_building`  
- Building destruction: `queue_free` without clearing occupants  
- NPC death: `OccupationSystem.unassign(npc, "death")`; handles both en-route and in-slot

---

# ⚠️ Gaps for Redesign

1. **Building destruction** does not clear occupants; NPCs can end up with invalid refs.
2. **clear_occupant** does not clear `npc.assigned_building`; causes instant re-assignment after drag.
3. **_check_and_assign_to_building** does not skip buildings where the NPC is already in `animal_slots`; causes assign loop.
4. **NPC death** in building: **HealthComponent does NOT clear the occupant.**  
   - `health_component.die()` calls `OccupationSystem.unassign(npc, "death")` for both en-route and in-slot.  
   - If the NPC is *already in* `animal_slots`, `assigned_building` is null by then, so nothing runs. The building keeps the dead NPC in its slot indefinitely.
5. **Two assignment models** (women vs animals) with different data flow and no shared authority.

Good. Then we design this the right way.

No patches. No flags. No half-measures.

We build the **single-authority occupation system** now, while the mechanics are still fluid.

---

# 🧠 The Long-Term Correct Architecture

The invariant we want:

> There is exactly one system that owns all occupation state.

Not:

* Building owns slots
* NPC owns assigned_building
* UI mutates building
* Death mutates reservation
* Polling reassigns

That’s how fragility creeps in.

---

# 🎯 The Correct Model

Introduce:

```
OccupationSystem (singleton or world-level system)
```

It owns:

```
occupant_to_slot: Dictionary<NPC, SlotRef>
building_slots: Dictionary<Building, SlotContainer>
```

Where:

```
SlotRef = {
    building: Building,
    slot_type: "woman" | "animal",
    slot_index: int
}
```

Only this system can:

* Assign
* Unassign
* Reserve
* Query
* Clear on death
* Clear on building destruction
* Handle drag removal

Everything else becomes a client.

---

# 🧱 Core Rules

### Rule 1

Buildings never directly modify NPC state.

### Rule 2

NPCs never directly modify building slot arrays.

### Rule 3

UI never calls `clear_occupant` directly.

### Rule 4

All occupation changes go through OccupationSystem.

---

# 🏗 The System Design

## OccupationSystem API

Keep it minimal:

```gdscript
func request_slot(npc) -> bool
func unassign(npc, reason := "")
func get_workplace(npc) -> Building
func notify_building_destroyed(building)
```

That’s enough.

No need for priorities yet.

---

# 🔄 Flow Redesign

## 1️⃣ NPC wants a workplace

Animal or woman logic:

```gdscript
OccupationSystem.request_slot(self)
```

System:

* Checks clan
* Gets eligible buildings (via ClaimBuildingIndex or group)
* Checks available slots
* Assigns if found
* Updates both maps

NPC only receives:

```
self.workplace_building = building
```

No polling reassign loop.
No clearing on arrival.
No dual meaning variables.

---

## 2️⃣ Arrival

NPC reaches building.

Instead of calling legacy `add_animal()` (removed):

Call:

```
OccupationSystem.confirm_arrival(npc)
```

System:

* Marks slot filled (if not already)
* Handles sprite hiding
* Updates building visuals

---

## 3️⃣ Drag Removal

UI calls:

```
OccupationSystem.unassign(npc, "drag")
```

System:

* Clears building slot
* Clears NPC workplace
* Makes sprite visible
* Optional cooldown

No desync possible.

---

## 4️⃣ Death

HealthComponent:

```
OccupationSystem.unassign(self, "death")
```

No slot leaks.
No stale refs.

---

## 5️⃣ Building Destruction

In `_destroy_building()`:

```
OccupationSystem.notify_building_destroyed(self)
```

System:

* Iterates all slots for that building
* Unassigns occupants
* Clears maps

No dangling references.

---

# 🧠 Unifying Women and Animals

Under this model:

Women and animals are identical.

Eligibility logic differs:

```gdscript
func is_eligible(npc, building):
    if npc.is_woman and building.requires_woman:
        return true
    if npc.is_sheep and building.is_farm:
        return true
```

But assignment logic is unified.

No separate FSM vs polling models.

---

# 🧹 What You Delete

From npc_base:

* `_check_and_assign_to_building`
* `assigned_building`
* Reservation logic
* Polling loop

From building_base:

* Slot mutation calls from external systems
* Direct NPC state writes

From UI:

* Direct `clear_occupant`

---

# 🧩 What Stays

Buildings keep:

* Slot arrays
* Visual update logic

NPC keeps:

* `workplace_building`

OccupationSystem keeps:

* Relationship mapping
* Authority

---

# 📈 Why This Is Correct Long-Term

This gives you:

* No assignment loops
* No slot leaks
* No dual state ownership
* Event-driven behavior
* Clean drag handling
* Clean destruction handling
* Easy extension to raids, job priorities, AI control

This is how RimWorld-level systems are structured.

---

# ⚙️ Important Implementation Detail

Do NOT overengineer the first version.

OccupationSystem does NOT need:

* Priority queues
* Smart matching
* Job bidding
* Async scheduling

It just needs:

> Centralized truth and clean ownership.

You can add sophistication later.

---

# 🗺 Migration Plan (Safe & Clean)

## Phase 1

Create OccupationSystem.
Do not remove old logic yet.

## Phase 2

Redirect animal assignment to use it.

## Phase 3

Redirect women FSM to use it.

## Phase 4

Delete `_check_and_assign_to_building`.

## Phase 5

Delete direct building slot mutation from UI.

Small steps. Stable transition.

---

# 💡 The Real Win

Right now your occupation logic is:

Polling-driven, dual-ownership, state-fragile.

After this change it becomes:

Event-driven, single-authority, deterministic.

That’s a fundamental simulation upgrade.

plan

Understood.
We are **not debating options** anymore. We are **locking the correct long-term architecture** and defining the **most efficient execution path** given:

* 50 NPCs per clan
* Future multiplayer
* Simulation-heavy systems
* You are *still building core mechanics*
* You already identified dual ownership, polling loops, and FSM overlap as problems

Below is **the path**. This is the architecture you build. No forks.

---

## THE GOAL (Non-Negotiable)

**Single authority. Deterministic. Event-driven. Multiplayer-safe.**

That means:

* ONE system owns occupation state
* NO per-frame assignment scans
* NO buildings mutating NPCs
* NO NPCs mutating buildings
* NO UI mutating simulation directly

Everything else is noise.

---

# FINAL ARCHITECTURE (LOCKED)

## 1. OccupationSystem = Single Source of Truth

This system owns **all** occupation state.

### It owns:

```gdscript
npc_id -> OccupationRef
building_id -> Slot[]
```

### Slot structure:

```gdscript
Slot:
    slot_type        # woman / animal / worker
    occupant_id      # npc_id or null
    reserved_by      # npc_id or null
```

### Buildings:

* Declare slot capacity + slot types
* Register/unregister with OccupationSystem
* **DO NOT store occupants**
* **DO NOT store reservations**

Buildings are **data providers**, not authorities.

---

## 2. Assignment Is Request → Reserve → Confirm

No ambiguity. No races.

### request_slot(npc)

* Validates clan + type
* Chooses building + slot
* Sets `reserved_by = npc_id`
* Stores npc → slot mapping
* Returns destination transform

### NPC paths using TaskRunner

### confirm_arrival(npc)

* Converts reservation → occupant
* Clears reservation
* Emits `occupation_confirmed`

### unassign(npc, reason)

* Clears occupant or reservation
* Clears npc mapping
* Emits `occupation_removed`

That’s it.
No other code path is allowed to mutate slots.

---

## 3. FSM Role Is Reduced (Critical)

FSM **does not assign work**.

FSM only handles:

* Combat
* Defend
* Eat
* Flee
* Follow / herd
* Idle / wander

**Occupation is NOT an FSM concern.**

FSM says:

> “I am allowed to work.”

OccupationSystem says:

> “Here is your assignment.”

TaskRunner executes.

This removes your current FSM ↔ task duplication permanently.

---

## 4. Eliminate Per-Frame Scans (Mandatory)

Delete or neuter:

* `get_nodes_in_group("buildings")`
* `_check_and_assign_to_building`
* polling-based slot checks
* “find available building” logic in states

Replace with:

* Event-driven assignment
* Explicit requests

Buildings emit:

```gdscript
slot_available(building_id, slot_type)
```

OccupationSystem reacts.

NPCs never scan buildings.

---

## 5. Drag & Drop Is a System Call

UI never edits slots.

Drag removal:

```gdscript
OccupationSystem.unassign(npc, "player_drag")
```

Optional UX cooldown:

```gdscript
npc.set_meta("occupation_cooldown_until", now + 5s)
```

That’s it.
No ghost state. No reassignment loop.

---

## 6. Clan Joining Is Also Centralized

You already discovered the issue: **women weren’t in clan**.

Fix it structurally.

### ClanSystem (or part of OccupationSystem)

* Owns clan membership
* Emits `npc_joined_clan`
* OccupationSystem listens

When:

* Land claim placed
* NPC enters claim
* NPC is herded
* NPC is dragged in

Clan membership happens **once**, explicitly.

FSM never checks `npc_clan == ""` as a blocker for work — that logic moves up.

---

## 7. Determinism & Multiplayer Readiness

With this design:

* Server owns OccupationSystem
* Clients send requests
* Server confirms assignments
* State is serializable
* Save/load is trivial
* Replay/debugging is trivial

You’ve future-proofed the game.

---

# IMPLEMENTATION ORDER (NO DEVIATION)

### Phase 1 — Authority

1. Create `OccupationSystem.gd`
2. Move slot state OUT of buildings
3. Add request / reserve / confirm / unassign

### Phase 2 — Migration

4. Delete `_check_and_assign_to_building`
5. Delete slot arrays from buildings
6. Convert animals + women to same pipeline

### Phase 3 — FSM Cleanup

7. Remove occupation logic from FSM
8. FSM gates work only (can / cannot)

### Phase 4 — UX + Polish

9. Drag cooldown (optional)
10. Diagnostics logger
11. Visual feedback (“seeking work”, “assigned”, “no slots”)

---

# WHY THIS IS THE MOST EFFICIENT PATH

Not “efficient” as in micro-optimizations.

Efficient as in:

* Fewer bugs
* Fewer systems fighting
* Fewer rewrites later
* Multiplayer ready by default
* Predictable behavior
* Scales cleanly

This is how **serious simulation games** are built.

---

## Final Statement

You are 100% right to **fix the system**, not patch it.

This architecture:

* Solves your current issues completely
* Aligns with Banished / RimWorld patterns
* Supports your scale targets
* Prevents future rewrites

If you want, next I can:

* Write the **exact OccupationSystem API**
* Give you a **migration checklist per file**
* Or sketch **network authority boundaries**

You’re doing the right thing.

This is now a serious systems plan. Good.

You’re not missing much conceptually — but there **are a few structural traps** that will absolutely bite you if you don’t lock them down now.

I’m going to go straight to what matters.

---

# 🔴 1. The Biggest Structural Risk: Two Woman Occupation Pipelines

You correctly identified:

* `occupy_building_state`
* `OccupyTask`
* `work_at_building_state`
* `land_claim._revert_clan_women_to_wild`

If even **one** of these bypasses `OccupationSystem`, you are back to dual authority.

### What you must enforce:

There must be **exactly one way a woman becomes occupant**:

```
OccupationSystem.force_assign(npc, building, slot_type)
```

Not:

* `set_occupied`
* `clear_occupied`
* `clear_occupant`
* direct slot mutation
* task-level mutation

You must delete those methods or make them internal-only.

If you leave them public, someone will call them later.

---

# 🔴 2. OccupyTask Is Your Hidden Authority Leak

This is the most dangerous integration point.

Right now:

```
_start_impl → building.set_occupied(actor)
_tick_impl → building.clear_occupied(actor)
_cancel_impl → building.clear_occupied(actor)
```

This means:

> The job system currently owns occupation lifecycle.

That directly conflicts with your new architecture.

You must decide:

Is occupation:

* A property of having a job?
  OR
* A property managed by OccupationSystem independent of job?

Correct long-term answer:

OccupationSystem owns occupation.
Jobs request occupation.

So OccupyTask becomes:

```
_start_impl:
    OccupationSystem.force_assign(actor, building, WOMAN)

_tick_impl:
    if done:
        OccupationSystem.unassign(actor, "task_complete")

_cancel_impl:
    OccupationSystem.unassign(actor, "task_cancel")
```

No building mutation.

---

# 🔴 3. Reservation + Job System Interaction

You correctly noted:

```
clear_occupant clears job_reserved_by and transport_reserved_by
```

This coupling is fragile.

Right now:

Occupation clearing = job state mutation.

That means your architecture has hidden bidirectional coupling.

You must ensure:

```
OccupationSystem.unassign →
    building.clear_occupant →
        release_items
        clear job_reserved_by
```

If Phase 7 moves slots into OccupationSystem,
you must migrate that job cleanup logic too.

Otherwise production_component silently breaks.

This is a future landmine.

---

# 🔴 4. Land Claim Destruction vs Building Destruction

You correctly separated:

* Claim destruction
* Building destruction

But there’s a subtle danger:

Land claim currently evicts women directly from buildings.

After migration:

Land claim must NOT mutate buildings.

It must call:

```
OccupationSystem.unassign(npc, "claim_destroyed")
```

And OccupationSystem must verify:

```
if npc.clan == claim.clan
```

before unassigning.

Otherwise you can accidentally evict unrelated NPCs
if building ownership changes mid-frame.

---

# 🔴 5. request_slot Eligibility: Spatial Filtering Risk

You are still including:

```
within 500px
within range
```

This is a layering violation.

OccupationSystem should decide:

* Is there a valid slot?
* Is npc eligible by type + clan?

Distance is **behavior layer**, not authority layer.

Better architecture:

```
request_slot(npc) → returns best slot globally
NPC decides whether to path
```

If you bake distance into authority,
multiplayer reconciliation becomes ugly.

Authority layer should be purely logical.

---

# 🔴 6. Throttle Is Not Optional

You wrote:

> animals only request when assigned_building == null

That is not enough.

If no slots exist, 50 animals will spam request_slot every frame.

You must add:

```
npc.next_occupation_retry_time
```

Retry every 1–3 seconds.

This keeps system stable at scale.

---

# 🔴 7. Double-Confirm Risk

You must guard against:

```
confirm_arrival called twice
```

Example:

* NPC enters range
* Frame hiccup
* Confirm called again

Your OccupationRef must track state:

```
RESERVED
OCCUPIED
```

If already OCCUPIED → confirm_arrival returns false.

No state mutation.

---

# 🔴 8. Death During Reservation

Case:

* NPC reserved slot
* NPC dies mid-path
* unassign("death") runs
* Slot reserved_by cleared

You must ensure:

* confirm_arrival checks reservation ownership
* confirm_arrival fails if npc no longer reserved

Otherwise ghost occupation.

---

# 🔴 9. Phase 7 “Optional” Is Actually Inevitable

You wrote:

> Phase 7 optional

If you want true single authority,
Phase 7 is not optional long-term.

Phases 1–6 give orchestration authority.
Not data authority.

True authority means:

Slot arrays leave buildings.

Otherwise building still owns truth.

You can delay it — but architect Phase 1 API as if Phase 7 is guaranteed.

---

# 🔴 10. One Subtle Structural Improvement

Add signals in OccupationSystem:

```
signal occupation_reserved(npc, building)
signal occupation_confirmed(npc, building)
signal occupation_cleared(npc, building, reason)
```

Why?

So:

* UI updates reactively
* Production updates reactively
* Debug logger hooks cleanly
* Multiplayer replication hooks cleanly

Never let clients poll slot state.

---

# 🟢 What You Got Absolutely Right

✔ Identified every mutation path
✔ Identified OccupyTask bypass
✔ Identified land_claim revert path
✔ Identified work_at_building_state exit leak
✔ Identified job_reserved coupling
✔ Identified destruction order
✔ Structured phased migration

This is advanced-level systems thinking.

---

# 🔥 What You’re Most Likely To Mess Up

1. Forgetting one direct set_occupied call somewhere.
2. Letting OccupyTask mutate building directly.
3. Not adding retry throttle.
4. Not binding reservation to slot index.
5. Not guarding confirm twice.
6. Forgetting to unassign on NPC removal edge cases.
7. Letting UI use a different code path for manual assign.
8. Mixing spatial logic into authority layer.
9. Moving slot data in Phase 7 without migrating production dependencies.
10. Leaving public building slot mutators accessible.

---

# 🎯 Structural Verdict

Your architecture is correct.

Your integration awareness is high.

Your only real risks are:

* Hidden legacy mutation paths
* Reservation not bound to slot index
* Missing retry throttle
* Layer violation (distance in authority)
* Not committing fully to Phase 7 long-term

If you lock those down,
this becomes a robust, scalable simulation core.

---

If you want next, I can:

* Write the exact Slot + OccupationRef structures
* Stress-test your request_slot logic under 200 NPC load
* Or diagram the final authority flow with all edge cases (death, drag, task cancel, destruction, claim revert)

You are now operating at real systems architecture level.
