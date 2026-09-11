# Settlement Sim — Phases Roadmap

Living document for off-screen clan simulation (warm tier / dormant claims). Update when scope shifts.

## Recommended Build Order

Based on complexity and gameplay impact:

1. **Phase 7** — Pregnancy, birth, baby growth, aging (quick win, visible impact)
2. **Phase 1** — Full sleep records (foundation for richer persistence)
3. **Phase 5** — Active parties persist (complex, important for MP/raids)
4. **Phase 6** — MP sync (once single-player is solid)

---

## Overview

When the player leaves a territory, the claim goes **dormant**. A roster snapshot replaces live NPC actors. **Settlement ticks** run on a configurable interval (default 30s) to simulate food, production, gathering, and population changes. When the player returns, the **roster is truth** — NPCs spawn/despawn to match.

---

## Phase 1 — Full Sleep Records (Future)

**Goal:** Persist rich NPC state when sleeping/dormant (pregnancy, genetics, traits beyond minimal roster).

**Work:**
- Extend sleep records with pregnancy timer, gene/trait payload
- Roster snapshot merges sleep + live NPC fields
- Wake reconcile applies full state to spawned actors
- Save/load migration for sleep schema

**Status:** Not started (optional "Phase 1 lite" could add pregnancy to roster only)

---

## Phase 2 — Food + Passive Buildings (Done)

**Goal:** Dormant clans consume food, starve by tier, run campfire cook + drying rack passively.

**Delivered:**
- `SettlementRoster` — member schema, feed/death priority
- `SettlementSimTick` — hunger drain, feeding, starvation, passive cook/rack/wood burn
- `WorldGenConfig.settlement_tick_interval_sec`
- ClanBrain dormant/wake + PlaytestInstrumentor events
- `tools/test_settlement_sim.gd`

---

## Phase 3 — Abstract Gather + Oven Production (Done)

**Goal:** Dormant clans gather resources from chunk pools (weighted by **placeholder** pseudo-biome label), deplete pools, bake bread if oven exists.

**Work:**
- Biome query from `ChunkGenerator` (seeded **pseudo-biome** per chunk — **code-only**, not player-facing biomes)
- `AbstractGather` — population-based yield, configurable rates in `WorldGenConfig`
- Chunk resource depletion + regen via `MutationStore` (persisted abstract pools)
- Abstract oven production in `SettlementSimTick`
- Instrumentation: gather, depletion, regen, oven events
- Headless test `tools/test_abstract_gather.gd`

**Known issue (2026-09-05):** Label `rocky` maps to `stone` + `fiber` only — **no edible food**. Long test JSONL showed chronic STARVING when all tour clans rolled `rocky`. Fix: default food-capable gather and/or food-first when pantry empty — see [off_screen_clan_balance.md](off_screen_clan_balance.md).

**Old system handling:**
- Mid-gather NPCs → snapshot carryover bonus on first dormant tick
- Pending WorkRequests → cleared when going dormant (abstract production takes over)

**Status:** Code **done**; **balance / survivability not done** until pseudo-biome gather gating is fixed.

---

## Phase 4 — Abstract Hunting (Done)

**Goal:** Dormant clans hunt when animals exist in chunk/biome; meat enters claim inventory.

**Delivered:**
- `AbstractHunt` — one prey per settlement tick when meat is low; skips live hunt parties
- Prey from live `npcs` group in same chunk (deer/sheep/goat); herded and clan-owned excluded
- Loot from `CorpseConfig`; prey despawned + `MutationStore.deplete_node_if_stable`
- `WorldGenConfig.abstract_hunt_enabled` + `abstract_hunt_meat_threshold`
- Instrumentation: `settlement_hunt_completed`, `settlement_prey_despawned`, `settlement_hunt_skipped`
- Headless test `tools/test_abstract_hunt.gd`

**Deferred:** seasonal migration, abstract wildlife pools, hunter injury, mammoth, cross-chunk hunt parties.

**Status:** Done

---

## Phase 5+ — Active Parties + Raids (Future)

**Goal:** Raid/hunt parties stay spawned when origin chunk goes dormant — player cannot cancel raids by leaving the area.

**Work:**
- Party registry independent of chunk dormancy
- Cross-chunk party movement (abstract or full sim)
- Raid resolution off-screen with logging
- Do not despawn active attackers when interest tier changes

**Deferred from Phase 3:** For now, active parties despawn with chunk (documented limitation).

---

## Phase 6 — Client Sync / MP Replication (Future)

**Goal:** Replicate roster, inventory deltas, and settlement events to clients (Phase 2–3 are server-log-only for MP v1).

---

## Phase 7 — Pregnancy, Birth, Aging Off-Screen (Done)

**Goal:** Roster ticks advance pregnancy, births add babies, babies grow to clansmen, and members age while dormant.

**Delivered:**
- Roster schema: `growth_timer`, `designated_father_id`, `last_birth_time`
- Settlement tick phases: pregnancy advance/birth, new conceptions, baby growth, aging
- Starvation cancels pregnancy; baby cap enforced off-screen
- Father selection: designated father if alive, else any alive male
- Seeded baby names via `NamingUtils`
- Birth cooldown respected for new off-screen conceptions
- `apply_sleep_data()` restores pregnancy/growth state on wake
- PlaytestInstrumentor: `settlement_birth`, `settlement_pregnancy_started`, `settlement_pregnancy_cancelled`, `settlement_baby_grew`, `settlement_birth_blocked`
- Headless test: `tools/test_settlement_pregnancy.gd`

**Deferred:** Genetics inheritance, death by old age, pregnancy complications

---

## Success Checklist (Phase 7)

- [x] Pregnant women advance `pregnancy_timer` off-screen
- [x] Starvation cancels pregnancy
- [x] Birth adds baby to roster with generated name
- [x] New pregnancies start when hut + food + cooldown OK
- [x] Designated father preferred for conception/birth
- [x] Babies grow into clansmen off-screen
- [x] Member ages increment proportionally
- [x] Baby cap blocks births at capacity
- [x] Birth cooldown blocks immediate re-conception
- [x] JSONL logs show birth, conception, cancel, growth events
- [x] Headless tests pass

---

## Integration Notes

| System | Tie-in |
|--------|--------|
| `ClanBrain` | Owns roster, calls tick, clears WorkRequests on dormant |
| `MutationStore` | Chunk abstract resource pools + stable_id depletions |
| `ChunkGenerator` | Biome + initial pool counts from seeded layout |
| `WorldGenConfig` | Tick interval, gather yields, efficiency tuning |
| `PlaytestInstrumentor` | All settlement events for playtest verification |
| `ClaimBuildingIndex` | Oven/rack presence for abstract production |
| [off_screen_clan_balance.md](off_screen_clan_balance.md) | Baseline economy targets + future modifier tiers |

---

## Success Checklist (Phase 4)

- [x] Dormant clans hunt only when meat is below threshold
- [x] Live hunt parties block abstract hunt on same clan
- [x] Herded and clan-owned animals are not hunted
- [x] Prey despawned from world; loot from CorpseConfig
- [x] JSONL logs show hunt, despawn, and skip events
- [x] Headless tests pass

---

## Success Checklist (Phase 3)

- [x] Dormant clans gather only pseudo-biome-allowed resources (⚠️ `rocky` has no food — fix pending)
- [x] Chunk pools deplete and persist (save/load via MutationStore)
- [x] Ovens produce bread off-screen when grain+wood available
- [x] JSONL logs show gather, depletion, oven events
- [x] Headless tests pass
- [x] No legacy dormant food-drain code remains
