# Off-screen clan balance & production modifiers

**Status:** **Environment-first survival in progress** (2026-09-05). Pantry ruler + regen + slaughter **shipped**; **gather food availability blocked** by placeholder pseudo-biome code until fixed. Phase B modifiers not started.  
**Last updated:** 2026-09-05  
**Implementation plan:** `ai_food_balance_tuning_d9beab75.plan.md` (Cursor plans)  
**Owner intent:** Living clans on a **continuous plane** — when you walk away, villages keep **gathering, hunting, crafting, building, growing, and reproducing** at abstract fidelity. Balance must be **fair in multiplayer**, **not starve AI into irrelevance**, and **not let neglected AI snowball past attentive humans** — but **ignored strong neighbors should eventually raid** and force a response.

**See also (canonical implementation):**
- [settlement_sim.md](../settlement_sim.md) — hot / warm / cold tiers, “settlement never sleeps”
- [settlement_sim_phases.md](settlement_sim_phases.md) — phased delivery (gather, hunt, pregnancy, …)
- [ai_clan_brain.md](../ai_clan_brain.md) — on-screen brain, raids, survival mode
- [production_economy.md](../production_economy.md) — on-screen WorkRequests when claim is **hot**
- [traits.md](../traits.md) — per-NPC traits (future clan-level modifiers stack on top)

**Planning workspace pointer:** `soc planning/earlygame_roadmap.md` (delivery tracking).

---

## Why this doc exists

We need **one written target** for:

1. **Baseline balance** — “normal production = **1.0**” before creative modifiers  
2. **Off-screen sim scope** — what abstract ticks actually do today vs later  
3. **Player vs AI** — same rules where code already agrees; different **advantage when hot**  
4. **Future buffs/debuffs** — traits, **real biomes** (not shipped), seasons as **small multipliers** on the baseline  

**Explicit non-goal for this pass:** changing **`sim_wake_player_radius_px`** (450 px). NPCs may look frozen until you are close; economy runs on **warm/dormant** tiers separately.

---

## ⚠️ Placeholder “biomes” vs player-facing biomes (read this first)

**Owner lock (2026-09-05):** **Player-facing biomes are not in the game yet.** There is no swamp/forest/plains content on the map the player recognizes.

**However**, off-screen gather **already uses hidden labels** in `ChunkGenerator.get_chunk_biome()` (`forest`, `plains`, `rocky`, `swamp`) and `BIOME_RESOURCE_KEYS` to decide which abstract resources a dormant clan can pull from a chunk pool.

| Label (code only) | Abstract gather keys today | Edible food in gather list? |
|-------------------|----------------------------|----------------------------|
| forest | wood, berries, fiber, nuts | ✅ berries, nuts |
| plains | grain, fiber, berries | ✅ grain, berries |
| rocky | stone, fiber | ❌ **none** |
| swamp | fiber, bugs | ✅ bugs |

**Impact:** A claim whose chunk rolls **`rocky`** can gather **fiber + stone only** — no berries/grain/bugs. Leaders eat starting food, then **STARVING** with no food gather (confirmed 10-min JSONL: all three ring clans logged `biome: rocky`, gather = fiber only).

**Until real biomes ship**, balance work must either:
1. **Replace** pseudo-biome gating with a **default food-capable gather list** for all chunks, and/or  
2. **Food-first gather** when pantry has no edible items, and/or  
3. Ensure **every chunk label** includes at least one food key.

**Do not** tune `ai_claim_starting_food_berries` to compensate for “rocky = no food” — that hides the bug.

**Canonical code:** `scripts/world/chunk_generator.gd` — `get_chunk_biome()`, `BIOME_RESOURCE_KEYS`, `get_biome_available_resources()`.  
**Canonical gather:** `scripts/systems/abstract_gather.gd` → `MutationStore` pools + regen.

---

## Simulation tiers (space vs CPU)

From [settlement_sim.md](../settlement_sim.md) — **one world plane**, tiered fidelity:

| Tier | Distance / interest | Actors (NPC nodes) | Village (settlement) |
|------|---------------------|--------------------|----------------------|
| **HOT** | Player within ~**450 px** (`sim_wake_player_radius_px`) | Full physics, FSM, pathfinding | ClanBrain live + WorkRequests |
| **WARM** | Claim within **2400 px** of any player (`CLAIM_ACTIVE_WORLD_RADIUS`) | Often **sim-dormant** (frozen visually) | ClanBrain live on claim; may still assign quotas |
| **DORMANT** | Claim **> 2400 px** from all players | Despawned or roster-only | **Settlement tick** every ~30s (`settlement_tick_interval_sec`) |

**Key rule:** *Actor sleep is allowed. Settlement sleep is not.*

Config refs: `WorldInterestManager`, `WorldGenConfig`, `SimDormancyController`, `ClanBrain.dormant_update()`.

---

## Off-screen settlement tick — what runs today

Implemented in `SettlementSimTick` + `AbstractGather` + `AbstractHunt`, driven by `ClanBrain.dormant_update()` when `is_dormant == true`.

| Activity | Off-screen behavior | Gates / notes |
|----------|---------------------|---------------|
| **Gathering** | Biome-weighted resources; chunk **pools deplete + regen** (`MutationStore`) | `gather_yield_per_population`, `gather_regen_per_sim_day`, `gather_population_efficiency` |
| **Hunting** | One wild prey per tick when meat low | `abstract_hunt_enabled`, `abstract_hunt_meat_threshold`; skips if live hunt party active |
| **Livestock slaughter** | Last resort when STARVING, pantry empty, hunt failed | `AbstractSlaughter` — owned sheep/goat in claim |
| **Feeding / starvation** | Roster hunger drain, feed from claim inventory, deaths | Starvation cancels pregnancy |
| **Passive craft** | Campfire cook, drying rack, **oven → bread** (if buildings exist) | Timers in `settlement_passive_state` meta |
| **Wood burn** | Abstract fuel use for passive production | |
| **Pregnancy** | Timers advance; birth adds baby to roster | Needs food buffer; starvation cancels |
| **New conception** | Off-screen pregnancies start | Requires **Living Hut**, food buffer ≥ `reproduction_min_food_buffer_days`, baby cap, cooldown |
| **Baby → clansman** | Growth timer → promote in roster | `abstract_baby_growth_enabled` |
| **Aging** | Adults age with sim-day proportion | `abstract_aging_enabled` |
| **On-screen build queue** | **Not** full WorkRequest sim | Pending work cleared on dormant; abstract production replaces **passive** chains only |

**Not yet / deferred:** full off-screen construction milestones, cross-chunk raid parties while dormant, genetics, female babies ([female_baby.md](female_baby.md)).

**Instrumentation:** `PlaytestInstrumentor` events (`settlement_tick_*`, `settlement_gather_completed`, `settlement_birth`, …). Summaries: `tools/summarize_phase7_playtest.sh`, `tools/summarize_ai_clans_playtest.sh`.

---

## Player vs AI — what we already agreed (code + bible)

### Dormant economy: **same settlement tick for all clans**

When a claim goes **dormant**, **`ClanBrain.dormant_update()`** runs **`SettlementSimTick`** for **player-owned and AI claims alike**. There is **no separate “player cheat tick”** in code.

- Player advantage while **away** comes from **what you built** (huts, oven, stockpile, roster size), not a hidden multiplier.  
- Player advantage while **present** comes from **direct control**, herding, RTS, and build placement.

### Live (hot) brain: **player clans differ**

On-screen `ClanBrain.update()` treats `player_owned` differently (documented in [ai_clan_brain.md](../ai_clan_brain.md)):

- Player clans: defend ratio via player drag; **no NPC raid evaluation against player from this brain path** the same way as NPC vs NPC.  
- AI clans: hunt/raid intent, strategic pressure, survival mode when fighters < 2.  
- **Survival mode** (`SURVIVAL_MODE_THRESHOLD = 2`) is **AI-only** — skips offensive hunt/raid until population recovers.

**Design lock for this doc:** Do **not** add a dormant food boost for humans unless we explicitly decide that later and document it here. Baseline tuning targets **one economy**.

### Growth & threat: **rough parity for neglected AI (design target)**

**Owner intent (2026-08-30):** AI that is **left alone long enough** should become **strong enough to raid** and create pressure — not infinite, not decorative.

Existing code supports this direction:

- Raids require **`food_days_buffer ≥ 3.0`** sim-days (`RAID_MIN_FOOD_DAYS_FOR_RAID` in `clan_brain.gd`).  
- Off-screen sim can grow population **only** with huts + food + males ([Phase 7](settlement_sim_phases.md)).  
- **Baby cap** scales with Living Huts — no hut spam, no infinite babies.

**Balance implication:** Baseline gather/food must let AI clans **survive and slowly build** off-screen; raid strength is a **downstream** outcome of pop + food + fighters, gated by existing raid rules — not by giving free soldiers.

**Attentive humans should still win** through micro, timing, and defense — but **ignoring a neighbor for many sim-days** should have consequences.

---

## Baseline balance philosophy

### Phase A — establish “Normal = 1.0” (current work)

Before traits, **real biomes**, or seasons:

1. **Measure** with instrumented sessions (`--session-nearby-clans`, optional `--session-ai-clan-tour`, `bash tools/run_ai_food_long_test.sh`).  
2. **Fix gather food availability** — placeholder `rocky` (and any label) must not block all food; food-first when starving (planned).  
3. Tune until **leader-only AI** (pop 1) holds ~**0.5–1.0 days** food buffer on **release bootstrap (~1 meal)**, not permanent STARVING.  
4. Tune until **one off-screen tick** is roughly **break-even** on **edible** food (small net gain or loss, not −1 every tick with only fiber).  
5. Verify **regen** logs (`settlement_regen_completed`) on long runs; fix caps if regen stays at 0.  
6. **One knob at a time** — no guessing multiple constants.

### Primary knobs (single source of truth)

| Knob | File | Purpose |
|------|------|---------|
| `ai_claim_starting_food_berries_release` / `_dev` | `balance_config.gd` | Release **1** meal; dev **55** (`--ai-dev-food-bootstrap`) |
| `gather_yield_per_population` | `world_gen_config.gd` | Per-resource harvest per pop per tick (berries 2.0, grain 3.5) |
| `gather_regen_per_sim_day` | `world_gen_config.gd` | Per-resource pool regen toward chunk cap |
| `gather_population_efficiency` | `world_gen_config.gd` | Diminishing returns hook |
| `gather_starvation_penalty` | `world_gen_config.gd` | Mult when clan in STARVING workforce mode |
| `settlement_tick_interval_sec` | `world_gen_config.gd` | Wall-clock between dormant ticks (~30s) |
| `food_items_per_capita_per_sim_day` | `balance_config.gd` | Buffer math / consumption proxy |
| `clan_food_buffer_target_days` / `_critical_days` | `balance_config.gd` | GROWTH / BALANCED / STARVING thresholds |
| `reproduction_min_food_buffer_days` | `balance_config.gd` | Block new pregnancies when poor |
| `RAID_MIN_FOOD_DAYS_FOR_RAID` | `clan_brain.gd` | Block raids when starving |

### Success metrics (JSONL)

**Primary success (owner lock):** a **productive, multiplying clan** — survival + growth (births, baby_grew, pop↑) when roster includes women/huts. Leader-only runs prove **survival**, not multiplication.

| Metric | Target (leader-only neighbor, **release bootstrap**) |
|--------|------------------------------------------------------|
| `food_days_buffer` | ~0.5–1.0+; not chronic STARVING (>40% ticks) |
| `workforce_mode` | Mostly GROWTH/BALANCED on long runs |
| `settlement_gather_completed` | Includes **edible** resources (berries/grain/bugs/meat), not fiber-only |
| `settlement_regen_completed` | Present when pools below cap |
| `settlement_tick_food_delta` | avg `food_delta` ≥ 0 over 20+ ticks |
| Player TEST clan | Higher buffer + faster visible growth when attended (dev bootstrap OK) |

**Long test:** `bash tools/run_ai_food_long_test.sh` → `Tests/logs/ai_food_long_*/` + `analyze_ai_food_starvation.py`.  
**Note:** `run_session_instrument.sh --session-quickstart` enables **dev bootstrap (55 berries)** — not a release-like run until that coupling is removed.

---

## Phase B — production modifier stack (future content)

Once baseline is stable, expose **small multipliers** for flavor and difficulty — **same formula for player and AI**.

### Formula (conceptual)

```
effective_rate = base_rate
                 × clan_production_modifier    // traits, culture, buffs
                 × biome_production_modifier   // forest, swamp, …
                 × season_modifier             // winter, drought, …
                 × workforce_modifier          // STARVING penalty (existing)
```

**Apply at one choke point** (recommended): e.g. `ProductionModifiers.get_gather_mult(clan, chunk, context)` used by `AbstractGather` and eventually on-screen gather/deposit paths.

### Tier sizes (**owner choice: tight**)

| Tier | Multiplier | Example use |
|------|------------|-------------|
| **Normal** | **1.0** | Default clans, neutral season |
| **Slight under** | **0.85 – 0.92** | Harsh winter, “lean harvest” trait, debuff |
| **Slight over** | **1.08 – 1.15** | Fertile valley, “plentiful roots” trait, short buff |

**Stacking rule:** clamp combined modifier to roughly **0.7 – 1.3** so biome + trait + season never explode. Rare world events (multi-sim-day drought) may use wider swings **only** as scripted seasons, not permanent traits.

### Where modifiers can attach (future)

| Layer | Examples | Systems touched |
|-------|----------|-----------------|
| **Clan trait / culture** | +8% gather, −8% hunt yield | Roster + ClanBrain meta |
| **Biome** | Swamp +fiber, −grain | `ChunkGenerator` + modifier table |
| **Season / disaster** | Winter −10% all food production | World sim / `Environment` (future) |
| **Building aura** | Oven village +bread efficiency | Claim building index |
| **Leader buff** | Temporary post-ritual +10% | Timed claim meta |

Log **`production_mult`** on gather/tick events when enabled so playtests show *why* a clan over/under-produced.

---

## Multiplayer notes

- **Server authoritative:** dormant ticks and dormancy run on **server only** (`_is_server_authoritative()`, `SimDormancyController` client skip).  
- **Interest union:** claims active / chunks loaded use **all player positions** on server.  
- **Same baseline rules** for every clan; no client-side economy.  
- **Cost:** more players spread across the map ⇒ more warm/dormant claims simulating — tune radii separately from economy (wake radius unchanged in this pass).

---

## Relationship to ClanBrain

| Mode | ClanBrain role |
|------|----------------|
| **Hot** (player very close) | Full FSM, WorkRequests, hunt/raid parties (AI), player RTS (human) |
| **Warm** (claim active, NPCs frozen) | Brain may still evaluate; NPC physics off |
| **Dormant** | `set_dormant(true)` → roster snapshot → **`dormant_update()` settlement ticks** |

Off-screen balance is **not** a separate brain — it is **ClanBrain’s warm tier** calling **`SettlementSimTick`**. On-screen balance remains **WorkRequests + FSM + production_economy**.

---

## Phased delivery checklist

### Shipped (2026-08-31)
- [x] **`ClanFoodBuffer`** — single pantry ruler (kcal ÷ daily need); live + dormant agree
- [x] Release/dev bootstrap split (`ai_claim_starting_food_berries_release` = 1 meal; dev = 55)
- [x] Per-resource gather + pool regen (`AbstractGather`, `MutationStore.regen_abstract_resources`)
- [x] Emergency slaughter (`AbstractSlaughter`) when STARVING + empty pantry + hunt failed
- [x] Long test tooling (`run_ai_food_long_test.sh`, `analyze_ai_food_starvation.py`)
- [x] JSONL: `settlement_tick_food_delta`, `settlement_regen_completed`, `settlement_slaughter_*`

### In progress (2026-09-05) — baseline balance blocked on gather food
- [ ] **Fix placeholder pseudo-biome** — `rocky` (and any label) must not block all edible gather
- [ ] **Food-first gather** when pantry has no edible items (planned)
- [ ] **Regen verification** — 10-min run logged **0** `settlement_regen_completed` (investigate caps / pool state)
- [ ] **Release-like long test** — decouple dev bootstrap from `--session-quickstart` in long-test path
- [ ] Tune until leader-only AI holds ~0.5–1.0d buffer on **release bootstrap**, not chronic STARVING

#### Measured runs (instrumented AI clan tour, leader-only)

| Run | Bootstrap | Result |
|-----|-----------|--------|
| **5 min** (`Tests/logs/ai_food_long_20260830_222729/`) | Dev (55 berries via quickstart) | 3 ring clans **stable** (0.74–1.05d buffer); **59** regen events; mixed gather (fiber + grain/berries/bugs by chunk label) |
| **10 min** (`Tests/logs/ai_food_long_20260830_225611/`) | Dev (55 berries) | All 3 clans ended **0.02d**, **~50% STARVING** ticks; avg **−1 food/tick**; gather **fiber only**; JSONL `biome: rocky` for all; **0** regen; hunt `no_prey`; slaughter `no_owned_livestock` |

**Interpretation:** Dev bootstrap masks early starvation, but **rocky pseudo-biome = no food keys** still collapses clans mid-run. Do not call baseline “done” until release-bootstrap long runs pass edible-gather + regen checks.

**Earlier tuning (2026-08-31, pre environment-first):** bootstrap 5→20 berries, gather 2.0→2.5 — superseded by release=1 meal + environment-first spec below.

### Next (neighbor content)
- [ ] Optional: session nearby clans with **1 hut + 1 woman** profile for growth/raid testing
- [ ] Verify raid gate (`food_days_buffer ≥ 3`) reachable after N sim-days neglect, not instant

### Later (modifiers)
- [ ] `ProductionModifiers` helper + clamp
- [ ] Dev menu preview (F10 / tuning panel): 0.9 / 1.0 / 1.1
- [ ] First clan trait using tight band
- [ ] Biome row in modifier table (no new mechanics — mult only)

---

## Decisions log (this conversation)

| Date | Decision |
|------|----------|
| 2026-08-30 | **Keep** `sim_wake_player_radius_px = 450` for now; fix economy first |
| 2026-08-30 | **Baseline before modifiers** — traits/biomes/seasons come after JSONL-stable 1.0 |
| 2026-08-30 | **Tight modifier band** (~±15%, stack cap ~0.7–1.3) |
| 2026-08-30 | **Dormant tick: same rules** for player + AI (already in code) |
| 2026-08-30 | **Neglected AI should reach raid pressure** (parity over “AI always weak”) — via existing raid food gate + off-screen growth, not free units |
| 2026-08-30 | Doc lives here under **future implementations** (design + tuning spec); links from ClanBrain + settlement sim |
| 2026-08-31 | **Baseline tuning shipped** — plan `ai_food_balance_tuning_d9beab75.plan.md`: bootstrap **20** berries, gather **2.5**, item-based `food_days_buffer` unified live+dormant, `settlement_tick_food_delta` JSONL |
| 2026-08-31 | **Single pantry ruler** — `ClanFoodBuffer` (kcal stored ÷ daily need); `food_days_buffer` == `calories_days_buffer` on claims |
| 2026-08-31 | **Environment-first survival (owner lock)** — release bootstrap ≈ **1 meal** (`ai_claim_starting_food_berries_release`); dev/session uses `ai_claim_starting_food_berries_dev` via `--ai-dev-food-bootstrap` / `--session-quickstart` |
| 2026-08-31 | **Per-resource regen** — abstract chunk pools regen toward cap at different rates (`gather_regen_per_sim_day`; berries fast, grain slower/larger harvest) |
| 2026-08-31 | **Emergency slaughter** — `AbstractSlaughter`: STARVING + empty pantry + hunt failed → slaughter owned sheep/goat in claim (off-screen + on-screen world) |
| 2026-08-31 | **Success metric** — productive multiplying clan (survival + growth), not pantry buffer alone; long test: `tools/run_ai_food_long_test.sh` + `analyze_ai_food_starvation.py` |
| 2026-09-05 | **Baseline not done** — 10-min long test: all clans `biome: rocky`, fiber-only gather, chronic STARVING despite dev bootstrap |
| 2026-09-05 | **Player-facing biomes not shipped** — `ChunkGenerator` pseudo-labels are off-screen gather only; must not block survival until real biomes exist |
| 2026-09-05 | **Next code (after bible):** default food on all chunks and/or food-first gather; fix regen; release-like long test path |

---

## Environment-first survival spec (2026-08-31)

**Owner intent:** Clans must **gather from the world** — not rely on large free pantries. More clansmen = naturally easier (more abstract workers). **Do not starve** if owned livestock exist (last-resort slaughter).

| Layer | System | Notes |
|-------|--------|-------|
| Bootstrap | `BalanceConfig.get_ai_claim_starting_food_berries()` | Release: **1 berry** (~1 feed). Dev: **55** for instrumented sessions only |
| Gather | `AbstractGather` + chunk pools | Per-resource yield; pools **deplete** |
| Regen | `MutationStore.regen_abstract_resources` | Per-resource rates toward chunk **cap**; tune faster if clans die |
| Hunt | `AbstractHunt` | Wild prey in chunk when meat low; live parties need clansmen |
| Slaughter | `AbstractSlaughter` | STARVING + empty pantry + hunt failed → owned sheep/goat |
| Measure | `settlement_tick_food_delta`, `settlement_regen_completed`, `settlement_slaughter_*` | Long run: `bash tools/run_ai_food_long_test.sh` |

**Release time scale:** dev keeps fast pregnancy/baby/age; when release slows time, regen/yield knobs scale — do not re-introduce large bootstrap.

**Pseudo-biomes (placeholder):** Off-screen gather uses hidden per-chunk labels in `ChunkGenerator` — **not** player-facing biomes. See **§ Placeholder “biomes”** above. Until real biomes ship, every chunk must remain **survivable** (food-capable gather or food-first when starving).

---

## Open questions (for future sessions)

1. **Session test clans:** leader-only forever vs standardized “rival kit” (hut + woman + food)?  
2. **Separate MP bootstrap?** Same `ai_claim_starting_food_berries` or lower for high pop servers?  
3. **Off-screen building:** when do abstract huts/ovens appear for worldgen clans vs player-built only?

When answering these, prefer **measurement + one JSONL scenario** over lore-only defaults.
