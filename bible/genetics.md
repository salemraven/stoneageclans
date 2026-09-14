# Genetics — design & implementation status

**Last updated:** 2026-08-27  
**Status:** **Planned — not shipped.** This is the canonical overview. Deep technical spec: [future implementations/genetics.md](future%20implementations/genetics.md).

**Shipped appearance:** hair + skin + **body height/width** are additive genes on the card (men and women; kids inherit via the same mix as hair/skin). **Head size** (tall vs wide skull) is next; **sex dimorphism** is coded but off (no catalog loci yet). Future **clothes and hair styles** must parent to the body or head they sit on so they stretch with those genes.

**See also:** [reproduction_guide.md](reproduction_guide.md) (babies, caps, pregnancy), [traits.md](traits.md) (species & traits today), [food.md](future%20implementations/food.md) (starvation & baby throttle vision), [settlement_sim.md](settlement_sim.md) (off-screen roster births), [clan_founding_and_exile.md](clan_founding_and_exile.md) (**wild cavemen** / founder lineage — planned).

---

## What we want genetics to do

Genetics is the **long-term identity and evolution layer** for Stone Age Clans:

1. **Lineage** — every NPC knows mother, father, and clan bloodline (alive or dead).
2. **Inheritance** — children get a mix of parents’ genes (discrete traits + continuous stats).
3. **Expression** — genes change gameplay: strength, food need, cold tolerance, fertility, appearance bands.
4. **Selection** — harsh world systems (combat, famine, climate) remove some alleles and favor others over generations.
5. **Player story** — “Our clan used to be Sapiens; after 200 years of Neanderthal raids we’re 60% burly and cold-hardy.”

Genetics is **not** cosmetic-only. It must hook into **Stats**, **reproduction**, **food**, **combat**, and (later) **appearance layers**.

---

## Two kinds of inheritance

| Kind | Examples | How child gets it |
|------|----------|-------------------|
| **Discrete (allele)** | Lactase on/off, marker traits, “Hunter’s Grit” | Mendelian: one allele from each parent; dominant/recessive rules |
| **Continuous (polygenic)** | Body size, metabolism, cold/heat resistance, fertility | Average of parents + small random drift (+ optional hidden contributors) |

**Continuous example — body size**

```
Neanderthal mother: body_size = 1.30
Floresiensis father: body_size = 0.65
Child ≈ 0.97 (midpoint + noise)
```

**Tradeoffs (required)** — without coupling, evolution maxes everything:

- High cold resistance ↔ lower heat resistance  
- High body size ↔ more food need, lower agility  
- High aggression ↔ lower social cohesion  

Details: [future implementations/genetics.md](future%20implementations/genetics.md) § Tradeoffs.

---

## When genetics run

| Moment | What happens |
|--------|----------------|
| **Conception / birth** | `BirthEngine` (future) resolves child genome from mother + father |
| **Spawn** | Genome → `Stats` baselines, appearance bands, optional `baby_cap_bonus`-style modifiers |
| **Life** | Genome is **read-only**; world applies selection by killing or starving carriers |
| **Death** | Person record kept for lineage ledger and allele-frequency snapshots |

**Multiplayer:** server-owned `Genealogy` / birth resolution — clients display results only.

---

## Loci we care about (v1 target: ~10–20)

| Locus | Type | Gameplay hook |
|-------|------|----------------|
| `body_size` | Continuous | Carry, melee damage, sprite band (slight / avg / burly) |
| `metabolism` | Continuous | **Daily calorie need** (babies, women, clansmen) |
| `cold_resistance` | Continuous | Ice-age / winter damage |
| `heat_resistance` | Continuous | Drought gather penalty |
| `fertility` | Continuous | Conception weight + optional cap modifier |
| `strength`, `perception`, … | Continuous | Existing `Stats` |
| Species markers | Discrete | Hominid mix % (Sapiens, Neanderthal, …) |
| Named traits | Discrete | CK-style labels from allele combos |

**Metabolism → food (important for babies)**

Planned rule:

```
daily_calories = role_base × metabolism × body_size_factor × pregnancy_mult
```

- Babies use a **lower base** than adults but **can still starve** if not fed.  
- **Genetics sets the rate**; **food systems decide survival**.

---

## Baby feeding & starvation (planned — ties genetics + food)

**Design intent:** Born babies are a **food sink** until they grow up. If the clan cannot feed them, they die (harsh, visible, prehistoric).

| Rule | Detail |
|------|--------|
| **Consumption** | Each baby drains calories on the sim tick at a rate from **`metabolism` locus** (+ base baby need). |
| **Feeding** | Auto-pull from **land claim / storage** into baby’s 2-slot inventory when hungry; optional mother-priority path later. |
| **Starvation** | Below safety threshold → health drain → **despawn / infant death** (no full corpse pipeline for babies v1). |
| **Famine order** | When clan buffer is negative: **babies first**, then clansmen, women last (breeders protected longest). |
| **Cap interaction** | Baby **pool cap** gates *new pregnancies*; **food** gates *keeping* babies alive. Both matter. |

**Not in scope for genetics v1:** cannibalism, infanticide player choice, spoilage (see [food.md](future%20implementations/food.md)).

---

## What exists in code today (Aug 2026)

| Area | Shipped | Notes |
|------|---------|-------|
| `genetics_profile: Dictionary` on NPC | Partial | Field exists; not full sim genome |
| `baby_cap_bonus` meta on women | Stub | Summed into baby pool capacity — future fertility gene plugs here |
| `PlaceholderCardService` inherited card | Partial | Visual card index from father; not allele sim |
| `Stats.get_daily_calorie_need()` | Partial | Role base + strength/intelligence; **not** `genetics_profile` / metabolism locus |
| Baby calorie drain | Partial | Babies in calorie sim (`base_daily_calories_baby = 720`) |
| Baby auto-feed from claim | **No** | Documented in old phase2 docs only |
| Baby `eat` state | **No** | FSM locked to wander/idle for `npc_type == "baby"` |
| Baby starvation despawn | **No** | No `HealthComponent` on babies; fallback `die()` → `queue_free()` possible but untested/unwired |
| Famine kill order | **No** | See [food.md](future%20implementations/food.md), [popcontrol.md](future%20implementations/popcontrol.md) |
| `BirthEngine` / `LocusCatalog` / Person record | **No** | Design in [future implementations/genetics.md](future%20implementations/genetics.md) |
| Wild caveman founder lineage | **No** | [clan_founding_and_exile.md](clan_founding_and_exile.md) — reuse survivor NPC as founder genome root |
| Pregnancy cancel on clan starvation | **Yes** | `ReproductionComponent.cancel_pregnancy("starvation")` — **in utero only**, not born babies |

**Regression today:** [reproduction_guide.md](reproduction_guide.md), `tools/test_baby_cap.gd`.

---

## Build order (when we implement)

1. **Lineage** — `Person` id, `mother_id`, `father_id`, birth/death tick on save (see open question in deep spec). **Founder clans:** [clan_founding_and_exile.md](clan_founding_and_exile.md) — survivor NPC becomes lineage root on new claim.
2. **`LocusCatalog` Resource** — 8–12 loci (mix discrete + continuous); metabolism + body_size included.
3. **`BirthEngine.spawn_baby(mother, father)`** — recombination; write genome to child NPC.
4. **Expression pass** — genome → `Stats` + metabolism → `get_daily_calorie_need()`.
5. **Baby feeding loop** — auto-transfer from claim storage; hunger threshold; JSONL `baby_fed` / `baby_starved`.
6. **Starvation wave** — clan-level tick: babies first; integrate with `SimulationManager`.
7. **Selection hooks** — combat deaths + starvation update allele-frequency ledger (JSONL snapshots).
8. **Climate windows** — ice age / drought select on `cold_resistance` / `heat_resistance`.
9. **UI** — family tree, trait bands, clan allele % over time.
10. **Appearance** — sprite band from `body_size` (optional polish).

**Reliability gates before coding:** locus list frozen, save schema, server authority, mutation rates, tradeoff pairs — see deep spec § Reliability gates.

---

## JSONL events (planned)

| Event | When |
|-------|------|
| `genome_resolved` | Birth — child loci summary |
| `allele_frequency_snapshot` | Periodic per clan / global |
| `baby_fed` | Food moved claim → baby |
| `baby_starved` | Baby despawned from hunger |
| `selection_death` | Death attributed to famine/combat/climate with genome ref |

Existing baby events: `baby_spawned`, `baby_cap_snapshot`, `baby_pregnancy_*` — see [reproduction_guide.md](reproduction_guide.md).

---

## Key files (today vs future)

| Today | Future |
|-------|--------|
| `scripts/npc/npc_base.gd` (`genetics_profile`) | `BirthEngine`, `Genealogy` autoload |
| `scripts/npc/stats.gd` | Read metabolism from genome |
| `scripts/npc/components/baby_growth_component.gd` | Gate growth on “ adequately fed” optional |
| `scripts/systems/baby_pool_manager.gd` (`baby_cap_bonus` stub) | Fertility locus → same modifier API |
| `scripts/config/balance_config.gd` (role kcal bases) | Bases × genome multipliers |
| — | `resources/genetics/locus_catalog.tres` |

---

## Related docs

| Doc | Role |
|-----|------|
| [future implementations/genetics.md](future%20implementations/genetics.md) | Long-form math, schema, climate, ledger |
| [reproduction_guide.md](reproduction_guide.md) | Pregnancy, caps, wild/nomad — **includes baby feeding gap** |
| [traits.md](traits.md) | Current species & trait UI |
| [food.md](future%20implementations/food.md) | Housing vs food vs starvation vision |
| [bible.md](bible.md) §IX | Five hominid species |
| [guides/pawn_goal.md](../guides/pawn_goal.md) | Layered appearance + genetics morph |

---

*Promote sections into [bible.md](bible.md) §I–§XXI only when coded and behind agreed feature flags.*
