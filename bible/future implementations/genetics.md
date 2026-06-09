# Genetics & evolution simulation (future)

**Status:** Idea / design draft — **not implemented**.  
**Scope:** Extends `§IX Hominid Classes` and `bible/future implementations/reproductiontraits.md`. Pairs with the **lineage system** (also planned — see "Open question" at bottom).  
**Drafted:** May 2026

---

## Why

Stone Age Clans already has 5 hominid species and trait inheritance, but traits are **on/off labels** picked from species pools. That's enough for flavor; it isn't enough for an emergent **evolution sim** (Crusader Kings × early hominids).

Goal: **lineage** + **genetics** + **selection pressure** so the player can watch hybridization, climate adaptation, and trait drift play out over hundreds of in-game years — driven by the existing combat, food, raid, and (future) climate systems, not scripted events.

---

## Two trait kinds

The current system supports only **discrete** traits. Add a second kind: **continuous**.

| Type | Examples | Inheritance |
|------|----------|-------------|
| **Discrete (allele)** | Lactase on/off, marker traits, "Hunter's Grit" | Mendelian: pick one allele from each parent (dominant/recessive) |
| **Continuous (range)** | Body size, cold/heat resistance, strength, perception, fertility | **Polygenic average + noise**: child = avg(mother, father) + small random drift |

### Continuous example — body size

```
Neanderthal mother: body_size = 1.30   (burly)
Floresiensis father: body_size = 0.65  (small)

Child = 0.5 × (1.30 + 0.65) + noise(±0.05)
      = ~0.97  (medium, slightly above midpoint)
```

After several generations of `florensis × florensis` matings, the population drifts back toward 0.65 — that's natural selection or simple drift, free from the math.

### Polygenic refinement (siblings differ)

Each continuous locus has **N hidden contributors** (e.g. 4 numbers per parent, 8 total per child, averaged). Same parents → siblings still vary. Cheap: 4 floats.

### Heritability (`h²`)

Each locus has a **heritability constant 0–1**. `h² = 0.6` means 60% of the trait is parents, 40% is environmental noise. Real human ranges sit ~0.4–0.7. Lets you tune "how much family resembles each other".

---

## Climate-driven selection (the engine)

Without selection, alleles just shuffle. The world has to **kill or favor** carriers. The good news: existing systems already do this.

| Pressure (existing or planned) | Selects for |
|--------------------------------|-------------|
| Combat death | Strength, aggression, pain tolerance |
| Starvation (`food_days_buffer`) | Endurance, low metabolism |
| **Ice age tick** (planned) | Cold resistance, body size, fat |
| **Drought tick** (planned) | Heat resistance, water efficiency |
| Hunt success | Perception, agility, stalking |
| Births per woman alive | Fertility |
| Clan dominance / raid winners | Whatever the winning clan happens to carry |

### New continuous loci for climate

| Locus | Range | Notes |
|-------|-------|-------|
| `cold_resistance` | -1 (frail) … +1 (Neanderthal-tier) | Founders' species sets starting mean |
| `heat_resistance` | -1 … +1 | Tradeoff with cold |
| `body_size` | 0.5 (Floresiensis) … 1.5 (Neanderthal) | Drives carry / damage / food need |
| `endurance` | -1 … +1 | Drought + travel + hunt |
| `metabolism` | 0.5 … 1.5 | Higher = eats more, runs longer |

### Climate as ticks (sketch)

- **Ice age window** (e.g. years 80–140 of run): every NPC takes a small `cold_damage` per game day scaled by `(1 - cold_resistance)`. Low-resistance NPCs die earlier; their alleles leave the pool.
- **Drought window**: gather rate × `(1 + heat_resistance × k)`. Heat-tolerant clans starve less.

Climate cadence belongs in a future `SimulationManager` autoload (already proposed in `popcontrol.md` / `food.md`).

---

## Tradeoffs (avoid superhuman convergence)

Without coupling, evolution will drive every trait toward "max" and the sim becomes boring. Force tradeoffs:

- High `cold_resistance` ↔ low `heat_resistance`
- High `body_size` ↔ higher `food_need`, lower `agility`
- High `aggression` ↔ lower `social` cohesion, lower clan stability

Either by hard math (paired locus rule) or by **shared genes** (one allele affects two traits, fancy name: **antagonistic pleiotropy** — simple idea: real life works this way).

---

## Schema sketch

### Locus catalog (one config Resource)

```
Locus = {
  id: "cold_resistance",
  kind: CONTINUOUS,             # vs DISCRETE
  min: -1.0,
  max: 1.0,
  heritability: 0.6,
  mutation_sigma: 0.02,         # gaussian noise per generation
  contributors: 4,              # 4 hidden values per parent
  species_means: {
    sapiens: 0.0,
    neanderthal: 0.7,
    heidelbergensis: 0.3,
    denisovan: 0.4,
    floresiensis: -0.3,
  },
  paired_with: { id: "heat_resistance", penalty: 0.6 },  # optional
}
```

A `LocusCatalog` resource holds 10–20 of these. Adding a locus = add a row, no code change.

### Person genome (per NPC, lives in lineage record)

Discrete loci: pair of allele ids.  
Continuous loci: array of contributor floats (mean shown in UI).

```
Genome = {
  "lactase": ("on", "off"),                # discrete, heterozygous
  "body_size": [0.32, 0.41, 0.28, 0.39],   # 4 contributors → mean 0.35
  "cold_resistance": [0.61, 0.58, 0.72, 0.65],  # mean 0.64
  ...
}
```

Expressed value (continuous) = mean of contributors (clamped to locus range).

### Birth

For each locus:

- **Discrete:** pick one allele from each parent → resolve dominant/recessive → store pair.
- **Continuous:** randomly sample N/2 contributors from each parent → recombine into N child contributors → add gaussian noise scaled by `(1 - h²)` and `mutation_sigma`.

Mutation rate is small (e.g. 1 in 1000 births flips a discrete allele; continuous ones drift each gen anyway).

---

## Trait expression (UI / gameplay)

Continuous traits don't show as "+10% strength". They show as:

- **Numeric stat** under the hood: combat reads `body_size`, gather reads `endurance`, etc. Bridges into existing `Stats` (`scripts/npc/stats.gd`).
- **Label bands** in UI:
  - `body_size > 1.2` → "Burly"
  - `0.85–1.2` → "Average"
  - `< 0.85` → "Slight"
  - Bands are thresholds, free to retune.

Player still sees *names* (CK-friendly); math underneath stays smooth.

---

## Population genetics ledger

Every N births (or seconds), per-clan and global, snapshot:

```
allele_frequency[clan_id][locus][value_band] = float (0..1)
```

Derive:

- **Hybridization timeline** — % sapiens vs neanderthal vs denisovan per clan, per year.
- **Trait fixation events** — "Year 312: 'Hunter's Grit' fixed at 90% in clan WU QEME."
- **Bottleneck detection** — clan size dropped, allele diversity crashed.
- **Founder effect** — one ancestor's rare allele dominates a region 200 years later.

Output as JSONL (same pattern as `clanbrain_report.py`) so playtests can be analyzed offline.

---

## Visualization

| View | What it shows |
|------|---------------|
| Family tree (lineage) | Who fathered whom — see lineage doc |
| Allele heatmap on tree | Branch color = "% Neanderthal" or "cold tolerance" |
| World map overlay | Per-region species mix; watch migration / replacement |
| Trait timeline graph | Line chart of trait % over generations |
| Bloodline portrait | Player's own ancestry → "you are 12% Floresiensis" |

Even a simple Godot `Line2D` chart is fine for v1.

---

## Performance & scale

| Concern | Plain answer |
|---------|--------------|
| 50k dead NPCs × 20 loci × ~10 floats | ~few MB. Trivial. |
| Recompute frequencies every tick | Don't — sample every N births or every N seconds. |
| Live NPCs ticking genome | Genome is **read-only after birth**, used at birth-time only. |
| Save size | Compress with packed arrays; or store **diffs from species template**. |

---

## What this is **not**

- **Not** a real polygenic-score genome — keep readable, ~10–20 loci, not thousands of SNPs.
- **Not** a phenotype-perfect art system. Visuals stay 2D sprite sheets; later optionally swap body/skin sheet by trait band.
- **Not** something to ship before lineage is solid — genetics adds zero if `father_id` isn't tracked.

---

## Speculative payoffs (flag: prediction)

- **Player picks founder species, watches replacement** — start as Sapiens, but if your bloodline keeps mating with Neanderthal raidees, by year 800 your "Sapiens" descendants are 60% Neanderthal. Real prehistory in miniature.
- **Punctuated runs** — short ice age every ~200 years selects fast, then relaxes. Players will *notice* the era flips.
- **Founder effect with continuous traits** — starting clan with 4 above-average `body_size` women → bloodline trends burly forever. One choice becomes a 1000-year story.
- **Convergent evolution** — different runs on a cold-map seed land on different "winning" hominids, all converging to high `cold_resistance`.
- **Domestication path** — same allele machine on **sheep / goat** → herd that's bred for milk yield drifts over generations. Ranching as emergent gameplay.
- **Visible body sprites later** — pick from 3 body sheets (slight / avg / burly) by `body_size` band. Cheap visual payoff using the same number.

---

## Order to build (when this becomes real work)

1. **Lineage first** — `Person` records, `father_id`/`mother_id`, persistent on save (not yet a system in repo).
2. **`LocusCatalog` Resource** + 8–12 starting loci (mix of discrete + continuous).
3. **Genome** on each Person; `BirthEngine.spawn_baby(mother, father)` does discrete + continuous inheritance.
4. **Hook existing combat/food** so survivors' alleles bias the next gen automatically (no climate yet).
5. **Allele-frequency snapshot** every N ticks → JSONL like the ClanBrain report.
6. **Tiny UI** — per-clan trait %, line chart over time.
7. **Climate windows** (ice age, drought) → activate `cold_resistance` etc.
8. **Mutation + tradeoff coupling** — fine-tune so traits don't all max out.
9. **Family tree visualization** with allele heatmap.
10. **Visible body sprite bands** (optional polish).

---

## Reliability gates (lock before coding)

| Decision | Why |
|----------|-----|
| **Locus list (10–20 max for v1)** | Save schema is hard to migrate later |
| **Discrete vs continuous per locus** | Inheritance code path differs |
| **Mutation rate per locus type** | Determines drift speed |
| **Climate event cadence** (years per ice age?) | Otherwise selection feels random |
| **Tradeoff pairs** | Prevent superhuman convergence |
| **Authoritative owner** | Server `Genealogy` autoload (MP-safe) |
| **Save format** (JSON / Resource / SQLite) | Tied to expected lineage size |

---

## Open question

**Lineage doc** isn't written yet. This genetics design assumes a `Person` record per NPC (alive or dead) with `father_id`, `mother_id`, `birth_tick`, `death_tick`, plus the `Genome` block above. That doc should land **first** as `bible/future implementations/lineage.md` (or be folded into one combined `bible/future implementations/lineage_genetics.md`).

---

## Related docs

- `bible.md` §IX — current 5 species + trait pool
- `bible/traits.md` — trait list + character menu wiring
- `bible/future implementations/reproductiontraits.md` — original Mendelian sketch
- `bible/future implementations/popcontrol.md`, `food.md` — `SimulationManager` tick proposal (pairs with climate)
- `bible/future implementations/daynight.md` — environmental cadence
- `bible/multiplayer.md` — server authority for `Genealogy`

---

## Promote-to-bible criteria

When ready, summarize this whole doc into **one row** in `bible.md §XXII`:

> **genetics.md** | Polygenic continuous traits + Mendelian alleles; climate-driven selection; per-clan allele frequency ledger; tradeoff coupling. | Add `LocusCatalog` Resource; extend Person record with `Genome`; recombination in `BirthEngine`; selection hooks in existing combat/food + new climate ticks; JSONL snapshots; UI tree heatmap.

Then this file stays as the long-form design source.
