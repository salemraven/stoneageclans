# Clan founding, exile & wild cavemen (defectors)

**Status:** **Planned — not implemented** (design locked Aug 2026).  
**Scope:** **Major systems update** — new exile/founder pipeline, clan slot budget, NPC promotion, spawn integration, bible canon change. **Do not implement** until NPC/ClanBrain work stabilizes; this doc is the **single source of truth** when we build it.

**See also:** [game_dictionary.md](game_dictionary.md) (terms), [game_map.md](game_map.md) (`MutationStore`, clan density), [genetics.md](genetics.md) (founder lineage), [Phase3/phase3.md](Phase3/phase3.md) (original defector notes — superseded by this file), [reproduction_guide.md](reproduction_guide.md).

---

## 1. Fantasy (tribal sim)

When a clan’s **flag (land claim) is destroyed**, the territory is gone — but **some fighting-age males may survive**. Most die or fade in the wilderness; a **lucky few** can become **founders** of a new clan if the world has **room** for another AI tribe.

This supports:

- Messy raids (not instant spreadsheet delete of every person)
- **Branching bloodlines** (survivor keeps age, traits, future genetics)
- **Controlled clan count** (slots — we decide if another clan is allowed)
- Same pipeline for **voluntary strike-out** later (hunger, morale, ClanBrain “send a founder”)

**Not the same as herdables going wild:** women, sheep, and goats use `become_wild()` today. **Male fighters** become **wild cavemen** — a separate **exile → (optional) founder** path (promote to `caveman`, spawn with claim — see §5). Do **not** route fighters through herdable `become_wild()`.

---

## 2. Terms

| Term | Meaning |
|------|---------|
| **Wild caveman** | Male (`caveman` or promoted from `clansman`) with **no land claim** — exiled, defected, or founder-in-waiting. **Not** a herdable; **not** the old canon “all males always have a clan.” |
| **Exile** | Wild-caveman phase right after home is lost: cleared claim refs, party/follow broken, no ClanBrain home. |
| **Founder candidate** | Wild caveman who passed the **clan slot** check and may receive a new claim. |
| **Founder** | Candidate promoted to `caveman` (if not already), placed at chunk edge with **pre-spawned land claim**; **clan name = his personal name** (with uniqueness rule). |
| **Clan slot** | Budget slot: “may the sim add one more active AI clan here?” Separate from `min_clans_per_player` (floor). Needs **`max_ai_clans_*`** (ceiling — **not in code yet**). |
| **Defector** | Clansman who **voluntarily** leaves (hunger, morale, strike-out) → wild caveman → same founder pipeline when home is gone. |
| **Chunk exhausted** | `MutationStore.clan_deaths >= clan_max_deaths_per_chunk` (default 3) — blocks **seeded** clans, not necessarily **founder** clans (§7). |

---

## 3. Triggers (one pipeline)

All paths converge on **exile**, then optional **founder** spawn.

### 3.1 Involuntary — flag destroyed (raid / decay / combat)

1. Land claim HP → 0 → `_destroy_building()` (records **one** `MutationStore` death per clan — already wired).
2. Women / sheep / goats → `become_wild()` (existing).
3. Babies → despawn with claim (existing).
4. **Living cavemen + clansmen** → become **wild cavemen** (exile handling — planned):
   - Break ordered follow / party / defend / tasks
   - **One founder roll per extinction event** (§4) — not every survivor gets a clan

### 3.2 Involuntary — soft clan death then flag destroyed

Typical raid flow: last caveman dies → buildings decay → flag destroyed later.  
**MutationStore** counts **once** (double-count guard on `LandClaim.try_record_clan_extinction`).  
Founder logic runs when the **flag** is destroyed (or optionally at soft death — **v1: flag destroy only**).

### 3.3 Voluntary — defectors (later phase)

From [Phase3/phase3.md](Phase3/phase3.md) — same exile/founder pipeline:

| Trigger | Type | If no home / claim gone |
|---------|------|-------------------------|
| Threat / panic | Flee | Exile → founder roll if slots |
| Too hungry + no clan food | Leave | Same |
| Long hunger | Leave | Same |
| Long low morale | Leave | Same |
| Voluntary strike-out | Leave | Exile → founder roll if slots |

**Open (implement later):** morale meter, hunger integral, “clan has no food” rule, ClanBrain satellite founding.

---

## 4. Founder selection rules (v1)

When a clan extinction leaves living **cavemen/clansmen**:

1. **At most one founder per wiped clan** per extinction event. Other survivors: **age-weighted** die / despawn (§6).
2. **Clan slot check** (server-side in MP):
   - `active_ai_clans_in_radius < max_ai_clans_near_player` (new config — TBD exact radius, likely reuse `clan_check_radius_chunks`)
   - Valid claim position at **target chunk edge** (overlap / min gap — reuse ~1200 px center-to-center rule from wander/build)
   - **Recommended:** allow founding in **MutationStore-exhausted** chunks if slot open (organic repopulation; seeded spam still blocked)
3. If slot **open** → pick **one** founder (e.g. oldest adult clansman, or random among adults — **TBD**).
4. If slot **closed** → no founder; all exiles proceed to survival/despawn rolls.

**Do not** spawn `_spawn_replacement_caveman()` when a founder path runs or when survivors exist (replace today’s unconditional replacement on AI `claim_destroyed`).

---

## 5. Founding flow (v1 — spawn with claim)

**Do not** use the player/caveman “place landclaim from inventory” loop for exiles. Founders get a **direct spawn** like density backfill, but **reuse the survivor NPC**.

### Steps

1. **Promote** survivor: `npc_type` → `caveman` (same as leader succession).
2. **Clear** old `clan_name`; set new clan name = **founder’s `npc_name`** (personal name).
   - Uniqueness: if taken, append suffix (`"KOR II"`, `"KOR'S BAND"`) — TBD string table.
3. **Pick position:** chunk **edge** near exile origin (narrative: leaving dead homeland). Prefer deterministic offset from `(chunk, world_seed, founder_id)` for MP/save.
4. **Spawn land claim** at position (reuse pattern from `main.spawn_seeded_ai_clan_at()`):
   - Parent under `world_objects` (not chunk root — claims persist across unload)
   - `BalanceConfig.seed_ai_claim_starting_food()` on claim inventory
   - Register claim, despawn grass/trees in radius, init **ClanBrain**
5. **Move existing NPC** to claim (not a new instantiated caveman):
   - `owner_npc` / `has_land_claim` meta / spear equip as today
   - **Genetics:** founder **is** the lineage seed when genetics ships — store `founder_person_id` / parent clan ref on claim meta for stories
6. **Optional v2:** walk-to-edge animation before spawn; **v1:** fade or short teleport after slot pass

### What **not** to do

- Do **not** call `become_wild()` on fighters — that path is for herdables (chunk roam like wildlife).
- Do **not** create a **new** NPC in `spawn_seeded_ai_clan_at()` for founders — loses age/traits/genetics.
- Do **not** require LANDCLAIM item in inventory (`wander_state` / `build_state` gates stay for normal cavemen only).

---

## 6. Survivors who are not founders

**Age-weighted survival** (design intent):

- Males **too young** or **too old** → higher chance to **die** or **despawn** while exiled (no claim).
- Prime-age adults → higher chance to become the **single** founder candidate if slots allow.

Exact curves → `NPCConfig` or `BalanceConfig` when implemented. Instrumentation: `exile_survival_roll`, `exile_despawn`, `exile_death`.

Outcomes:

| Outcome | Sim effect |
|---------|------------|
| **Die in wild** | Corpse loot or despawn |
| **Despawn** | Remove NPC after timer / failed roll (fade out at chunk edge) |
| **Found new clan** | §5 |

---

## 7. Interaction with world systems

### MutationStore

- Flag destroy records **`clan_deaths++`** once per clan (implemented).
- **Seeded** clans + density timer **skip** exhausted chunks (implemented).
- **Founder** clans: **recommended** to **allowed** in exhausted chunks if clan slot open — story repopulation without seeded spam.

### Clan density (existing)

| Config | Role today | Founder feature |
|--------|------------|-----------------|
| `min_clans_per_player` | Floor — density timer spawns if too few | Unchanged |
| `clan_max_deaths_per_chunk` | Caps seeded spawns per chunk | Founders may bypass (§7) |
| **`max_ai_clans_near_player`** | **Does not exist** | **Add** — ceiling for founder + optional global cap |

Helpers to extend: `main.count_ai_clans_with_claims_near()`, `main.spawn_seeded_ai_clan_at()` → new `main.found_clan_from_exile_npc(npc, chunk_edge_pos)`.

### Player clans

Player extinction (`main._handle_clan_extinction`) today: decay + game-over message.  
**Player clansmen** after player wipe: **TBD** — likely same exile rules for AI clansmen, but **no** auto-founder that competes with player story unless design says otherwise. Document decision when implementing.

---

## 8. Multiplayer

- **Clan slot check** and **founder spawn** run **server-only**.
- Clients receive claim + NPC replication via existing entity spawn path.
- Log founder events for late joiners in playtest JSONL (not a separate MutationStore field — founder is live sim state).

---

## 9. Instrumentation (when built)

PlaytestInstrumentor / UnifiedLogger events (names TBD):

| Event | Fields |
|-------|--------|
| `clan_exile_started` | old_clan, npc, reason (`flag_destroyed`, `voluntary_leave`, …) |
| `clan_founder_slot_check` | pass/fail, active_count, max_slots, chunk |
| `clan_founder_spawned` | new_clan, npc, old_clan, pos, parent_clan_for_genetics |
| `clan_exile_survival_roll` | npc, age, outcome (`founder`, `despawn`, `death`) |
| `clan_replacement_spawn_blocked` | reason (`survivor_founder`, `slot_full`) |

Headless test file (future): `tools/test_clan_founder_exile.gd`.

---

## 10. Current code vs planned (honest snapshot)

| Behavior | Today | Planned |
|----------|-------|---------|
| Flag destroy → MutationStore | Yes | — |
| Flag destroy → women/animals wild | Yes | — |
| Flag destroy → clansmen/cavemen | **Untouched** — keep dead `clan_name`, broken AI | Exile + founder/despawn |
| Flag destroy → AI replacement caveman | **`_spawn_replacement_caveman()`** always | Disable when founder/survivor logic runs |
| Voluntary defector leave | Not wired | Same pipeline |
| Max clan slots | Not wired | `max_ai_clans_near_player` |
| Founder spawn with claim | Density fill only (new NPC) | Reuse survivor NPC |
| Clan name = founder name | Seeded random names | Founder personal name |
| Walk to chunk edge | — | Optional v2 |

**Bible conflicts resolved by this doc (when implemented):**

- Old GDD “clansmen drop dead on flag destroy” → **territory wipe**; survivors may become **wild cavemen** → founder/despawn/die.
- Old `game_dictionary` “cavemen never wild” → **wild cavemen** use exile/founder, not herdable `become_wild()`.

---

## 11. Implementation order (suggested)

1. **`ClanExileService`** (or `main` helpers): exile cleanup on flag destroy (break follow, clear claim cache).
2. **`max_ai_clans_near_player`** + slot check.
3. **`found_clan_from_exile_npc()`** — reuse survivor, spawn claim at chunk edge.
4. Gate **`_spawn_replacement_caveman()`**.
5. Age-weighted despawn/death for non-founders.
6. Voluntary defector triggers (morale/hunger).
7. Walk-to-edge polish + genetics founder metadata.

---

## 12. Open questions (decide at implementation)

1. **Founder pick rule:** oldest adult vs random vs highest skill?
2. **Player clan survivors** after player extinction — founder allowed?
3. **Exact max clan cap** and radius (global vs per-player-neighborhood).
4. **Name collision** suffix format.
5. **Soft death only** (no flag destroy yet) — do exiles happen early or only on hard destroy? **v1: hard destroy only.**

---

*Last updated: August 2026.*
