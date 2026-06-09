# AOP Phase 2 — Resources, Herd Detection, Traits, Building Perception

**Status:** Plan. Implementation order and review items included.

---

## Current State

- **PerceptionArea** (`scripts/npc/components/perception_area.gd`): Tracks enemies only via `body_entered`/`body_exited`. `collision_mask=3` (layers 1+2). Radius from NPCConfig by `npc_type` (380 default, 600 mammoth).
- **Gather**: Land claim uses ResourceIndex.query_near(claim_pos, 3×radius) to generate jobs. No per-NPC resource perception.
- **Herd detection**: `herd_wildnpc_state.gd` uses `get_nodes_in_group("npcs")` + `_find_nearest_herdable_target()` — O(n) scan every evaluation.
- **Land claim intrusion**: `land_claim.gd` has EnemiesInClaim zone (Area2D, `body_entered`/`body_exited`). **BUG:** `collision_mask=1` detects layer 1 only; NPCs are layer 2 — enemy cavemen entering claim are NOT detected.
- **RPC**: Authority-only is sufficient; no sync work. See `perception_rpc.md`.

---

## Phase 2.1: Herdables in PerceptionArea (Event-Driven)

**Goal:** Replace O(n) `get_nodes_in_group` scan in herd_wildnpc with event-driven PerceptionArea.

**Changes:**

1. **PerceptionArea** — Add herdable tracking:
   - `nearby_herdables: Dictionary` (instance_id -> Node2D)
   - **Only populate for cavemen/clansmen** — skip when parent is woman/sheep/goat (they don't herd)
   - In `_on_body_entered`: if body is woman/sheep/goat and wild (`clan_name == ""`), add to `nearby_herdables`
   - In `_on_body_exited`: remove from `nearby_herdables`
   - `_prune_invalid()`: also prune herdables (dead, invalid, now in clan)
   - **Filter by `can_join_clan()`** — same as `_find_nearest_wild_in_range`; exclude NPCs that can't join
   - `get_herdables_in_range(origin, radius, npc) -> Array`: return valid herdables within radius, sorted by distance
   - `has_herdables(npc) -> bool`: quick check for can_enter

2. **herd_wildnpc_state.gd** — Use PerceptionArea:
   - Replace `_find_nearest_herdable_target(detection_range, woman_range)` with PerceptionArea lookup when available
   - **Within 380px:** use PerceptionArea (event-driven)
   - **Beyond 380px (1700px active seeking):** keep `get_nodes_in_group` fallback
   - Woman priority: call `get_herdables_in_range(..., woman_range)` first; if empty, call with `detection_range` for sheep/goat

3. **get_priority** — Use PerceptionArea for targets within 380px; fallback for 380–1700px (CLOSE_TARGET_RANGE etc).

---

## Phase 2.2: Resources in AOP (Gather)

**Goal:** Use AOP radius for gather resource queries instead of claim-centric only.

**Changes:**

1. **NPCConfig** — Add `aop_radius_gather: float = 800.0`
2. **Wiring:** Optional opportunistic gather when NPC has no job. Use `ResourceIndex.query_near(npc_pos, aop_radius_gather)`. Defer to later phase if desired.

---

## Phase 2.3: Different AOP per NPC Trait (Config Support)

**Goal:** Config can support trait-based radii later. No trait system yet.

**Changes:**

1. **NPCConfig** — Add optional overrides (0 = unused):
   - `aop_radius_leader: float = 0.0`
   - `aop_radius_searcher: float = 0.0`
2. **PerceptionArea._ready()** — If parent has `is_leader`/`is_searcher` and config > 0, use trait radius. No behavior change until traits exist.

---

## Phase 2.4: PerceptionArea for Buildings (Separate System)

**Goal:** Keep building intrusion as separate system. Fix EnemiesInClaim bug.

**Current bug:** `_enemies_zone.collision_mask = 1` only detects layer 1 (player). NPCs use `collision_layer = 2`. Enemy cavemen entering claim do NOT trigger `body_entered` — intrusion detection for NPCs is broken.

**Action:** Set `_enemies_zone.collision_mask = 3` so both player and NPCs are detected. **Required fix, not optional.**

---

## Phase 2.5: RPC / Multiplayer Sync

**Action:** No changes. PerceptionArea already disables on non-authority. Documented in `perception_rpc.md`.

---

## Implementation Order

| Step | Task | Files |
|------|------|-------|
| 1 | Add `nearby_herdables`, `get_herdables_in_range()`, `has_herdables()` to PerceptionArea; only populate for cavemen/clansmen; filter by `can_join_clan()` | perception_area.gd |
| 2 | Wire herd_wildnpc_state to use PerceptionArea for in-range herdables; keep scan fallback for 1700px | herd_wildnpc_state.gd |
| 3 | Add NPCConfig: `aop_radius_gather`, `aop_radius_leader`, `aop_radius_searcher` | npc_config.gd |
| 4 | Add trait hooks in PerceptionArea._ready() for leader/searcher radii | perception_area.gd |
| 5 | Fix land claim EnemiesInClaim `collision_mask` 1 → 3 | land_claim.gd |
| 6 | Update bible.md with AOP Phase 2 scope | bible.md |

---

## Test / Verification

- [ ] Run `--agro-combat-test` and herd-focused playtest
- [ ] Confirm `get_nodes_in_group("npcs")` is not used in hot path when herdables within 380px
- [ ] Verify herd_wildnpc behavior matches current: woman priority, deposit override (350px), get_priority CLOSE_TARGET_RANGE (500px)
- [ ] Verify EnemiesInClaim detects enemy NPCs after mask fix

---

## Out of Scope (Deferred)

- **`_is_leading_woman()`** — Still uses `get_nodes_in_group("npcs")` (line 361). Could use herder's herded list instead; optional follow-up.
- Event-driven resource detection (Area2D area_entered) — ResourceIndex sufficient
- RPC sync of perception — not needed

---

*Sources: CreatePlan, review pass, perception_area.gd, herd_wildnpc_state.gd, land_claim.gd*
