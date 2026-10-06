# Systems canon — master index & lock workflow

**Status:** Living program (Oct 2026)  
**Goal:** Every major game system gets the **same treatment**: intent, bulletproof rules, boundaries, integration, tests — then **one owner `.md`** so building and planning share one truth.

**How to use this file**

- **Planning:** Scan the inventory (§2) for big-picture coverage and gaps.  
- **Building:** Open the system’s **owner doc** (or template); if status is not **Locked**, confirm rules before coding.  
- **Locking a system:** Copy [templates/system_canon_template.md](templates/system_canon_template.md) → `bible/systems/<slug>_canon.md`, fill it, set status **Locked**, add a row here.

**Hierarchy when docs disagree**

1. **Locked system canon** (`bible/systems/*_canon.md`) for that system  
2. Domain locks: [economy_catalog.md](economy_catalog.md), [environment_goal.md](environment_goal.md), [earlygame_vision.md](earlygame_vision.md), [UI.md](UI.md), [game_dictionary.md](game_dictionary.md)  
3. [bible.md](bible.md) lore + overview  
4. [main.md](main.md) — what shipped in code today  
5. `future implementations/` — ideas only until promoted

**Synthesis docs** (multi-system): [village_and_economy_rundown.md](village_and_economy_rundown.md) — not a lock; feeds economy + settlement canon.

---

## 1. What “locked canon” means

A system is **Locked** when:

- §3 rules are complete enough that two implementers would not contradict each other.  
- Edge cases that **break saves or MP** are decided (even if “not v1”).  
- Owner doc lists **code paths** and **tests** (or explicit “no test yet”).  
- Open questions are only **future polish**, not core logic.  
- This master index row is updated to **Locked** with link.

**Not required for lock:** final balance numbers, all art, all UI polish.

**Template:** [templates/system_canon_template.md](templates/system_canon_template.md)

---

## 2. Full systems inventory

**Status legend**

| Icon | Meaning |
|------|---------|
| 🔒 | **Locked** — owner doc is canon |
| 🟡 | **Partial** — strong doc(s), rules not consolidated |
| ⬜ | **Draft** — scattered or aspirational |
| 💻 | **Code-first** — behavior in code; doc lags |
| 🗄️ | **Stale** — do not use without rewrite |

**Priority** for locking (P0 = do soon): drives order below; adjust in PRs.

---

### A. World & simulation shell

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| W1 | **World grid & coordinates** | 🟡 | [game_map.md](game_map.md), `ChunkUtils` | P1 |
| W2 | **Chunk streaming & content** | 🟡 | [game_map.md](game_map.md), [visual_vs_sim_layers.md](visual_vs_sim_layers.md) | P0 |
| W3 | **Seeded generation + mutations** | 🟡 | [game_map.md](game_map.md), `MutationStore` | P0 |
| W4 | **ResourceIndex (spatial gather)** | 💻 | [GatherGuide.md](GatherGuide.md) | P1 |
| W5 | **Island / biomes / environment** | 🔒 | [environment_goal.md](environment_goal.md) | — |
| W6 | **Terrain & water (passability)** | 🟡 | environment_goal §17–18 | P1 |
| W7 | **Weather & seasons** | ⬜ | environment_goal §19 | P2 |
| W8 | **Wildlife spawn & roles** | 🟡 | [wildlife_movement.md](wildlife_movement.md), environment_goal §6 | P1 |
| W9 | **Wildlife migration (seasonal)** | 🔒 | [wildlife_migration.md](wildlife_migration.md) | — |
| W10 | **Settlement sim (warm / off-screen)** | 🟡 | [settlement_sim.md](settlement_sim.md), [off_screen_clan_balance.md](future%20implementations/off_screen_clan_balance.md) | P0 |
| W11 | **NPC sim tiers (A/B/C LOD)** | 🟡 | [visual_vs_sim_layers.md](visual_vs_sim_layers.md) | P1 |
| W12 | **Day / night** | ⬜ | future `daynight.md` | P3 |

---

### B. Territory & village layout

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| T1 | **Territory tiers (campfire → flag)** | 🟡 | [earlygame_vision.md](earlygame_vision.md), [nomad.md](nomad.md) | P0 |
| T2 | **Land claim / AoH / radius** | 💻 | bible §V, [Buildings.md](Buildings.md) | P0 |
| T3 | **Nomad relocation** | 🟡 | [camp_relocation.md](camp_relocation.md) | P0 |
| T4 | **Building placement & validation** | 💻 | [Buildings.md](Buildings.md), `main.gd` | P1 |
| T5 | **Authentic camp layout (hearth-centric)** | 🟡 | [village_and_economy_rundown.md](village_and_economy_rundown.md) §4 | P0 |
| T6 | **Claim upgrade (flag → keep)** | ⬜ | items_guide / bible mentions | P3 |
| T7 | **Camp relocation loot loss rules** | 🟡 | camp_relocation | P1 |

**Target canon file (not written yet):** `bible/systems/territory_canon.md` (merge T1–T4–T7).

---

### C. Economy — items, gather, craft, buildings

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| E1 | **Item classes, tags, containers** | 🔒 | [economy_catalog.md](economy_catalog.md) §2–4 | — |
| E2 | **Gatherables & world resources** | 🟡 | [environment_goal.md](environment_goal.md) §5, [village_and_economy_rundown.md](village_and_economy_rundown.md) §2 | P0 |
| E3 | **Gather & deposit (NPC)** | 💻 | [GatherGuide.md](GatherGuide.md) | P0 |
| E4 | **Player gather & tools** | 💻 | bible §XIX, gatherable_resource | P1 |
| E5 | **Craft registry (hands)** | 💻 | `craft_registry.gd`, economy_catalog §12 | P1 |
| E6 | **Production buildings & stations** | 🟡 | economy_catalog §11, [production_economy.md](production_economy.md) | P0 |
| E7 | **Food states (raw/cooked/preserved)** | 🔒 | economy_catalog §6 | — |
| E8 | **Food buffer & calories** | 🟡 | [earlygame_vision.md](earlygame_vision.md) §2, `BalanceConfig` | P0 |
| E9 | **Container loops (milk, stew, potions)** | 🔒 | economy_catalog §7 | — |
| E10 | **Clothing pipeline (hide → tailor)** | 🔒 | economy_catalog §8, §3.5–3.6 | — |
| E11 | **Building tiers & mastery** | 🟡 | [production_tiers.md](future%20implementations/production_tiers.md) + economy_catalog §9 | P1 |
| E12 | **Proto farming (Field / crops)** | ⬜ | [proto_farming.md](future%20implementations/proto_farming.md) | P1 |
| E13 | **Trade & caravans** | ⬜ | environment_goal, lategame | P3 |

**Target canon files:** `economy_canon.md` (optional rename/split from economy_catalog), `gather_canon.md`, `production_canon.md`.

---

### D. Population — people, housing, genetics

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| P1 | **NPC types & roles** | 🟡 | bible §VIII, [traits.md](traits.md) | P1 |
| P2 | **Women labor & occupation** | 💻 | [farms.md](farms.md), [production_economy.md](production_economy.md), OccupationSystem | P0 |
| P3 | **Living hut & baby pool** | 🟡 | [reproduction_guide.md](reproduction_guide.md), bible §VII | P0 |
| P4 | **Pregnancy, birth, growth** | 🟡 | reproduction_guide, nomad freeze rules | P0 |
| P5 | **Female babies & sex at birth** | ⬜ | [female_baby.md](future%20implementations/female_baby.md) | P1 |
| P6 | **Lineage & Person registry** | ⬜ | [lineage.md](future%20implementations/lineage.md) | P1 |
| P7 | **Genetics & inheritance** | ⬜ | [genetics.md](genetics.md), future genetics.md | P1 |
| P8 | **Hominid species (5)** | 🟡 | bible §IX, [hominids.md](hominids.md) | P2 |
| P9 | **Leader hut & succession** | ⬜ | [leader_hut.md](leader_hut.md) | P2 |
| P10 | **Housing cap vs food cap** | ⬜ | future [food.md](future%20implementations/food.md), popcontrol | P1 |
| P11 | **Starvation & death order** | ⬜ | food.md, SimulationManager partial | P1 |
| P12 | **Clan founding / exile / wild cavemen** | ⬜ | [clan_founding_and_exile.md](clan_founding_and_exile.md) | P2 |

**Target canon file:** `bible/systems/reproduction_canon.md`, `bible/systems/population_canon.md`.

---

### E. Herding, hunting, animals

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| H1 | **Herd influence & wild attach** | 🟡 | [HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md) | P0 |
| H2 | **Claim join & herdables** | 💻 | HERDING + land_claim | P0 |
| H3 | **Cordage steal (raid)** | ⬜ | [herdable_raiding.md](future%20implementations/herdable_raiding.md) | P0 |
| H4 | **Hunting (AI AoH)** | 🟡 | [hunting.md](hunting.md), ClanBrain hunt_intent | P0 |
| H5 | **Hunting (player RTS)** | 🟡 | [Phase4/raiding_hunting.md](Phase4/raiding_hunting.md) | P1 |
| H6 | **Prey flee & combat with wildlife** | 💻 | flee_prey, wildlife_movement | P1 |
| H7 | **Butcher & corpse loot** | 💻 | butcher tasks, economy_catalog | P1 |
| H8 | **Animal pen / corral (design merge)** | 🟡 | economy_catalog §11.10, village rundown | P0 |
| H9 | **Predators** | ⬜ | future predator.md | P2 |

---

### F. Combat, agro, defense

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| C1 | **Agro meter & entry** | 🟡 | [AgroGuide.md](AgroGuide.md) | P0 |
| C2 | **Combat component (windup/hit/recovery)** | 💻 | bible §X, combat_component | P0 |
| C3 | **Combat scheduler / zones** | 💻 | combat_scheduler, optimizations doc | P1 |
| C4 | **Death, corpses, loot** | 💻 | fightorflight, butcher | P1 |
| C5 | **Defend land claim** | 💻 | defend_state, rts | P0 |
| C6 | **Morale / flee** | ⬜ | AgroGuide Part 2, combat_plan | P2 |
| C7 | **Wounds (persistent)** | ⬜ | [wounds.md](future%20implementations/wounds.md) | P2 |
| C8 | **Healing / medic** | ⬜ | bible §X Medic Hut | P3 |

---

### G. Raiding & diplomacy

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| R1 | **Raid intent & phases** | 💻 | [raid.md](raid.md), raid_state | P0 |
| R2 | **Four verbs (STEAL/LOOT/KILL/WIPE)** | ⬜ | [herdable_raiding.md](future%20implementations/herdable_raiding.md), earlygame_vision §4 | P0 |
| R3 | **ClanBrain raid scoring** | ⬜ | [clanbrain_raid_scoring.md](future%20implementations/clanbrain_raid_scoring.md) | P0 |
| R4 | **Loot before wipe** | 🟡 | bible §XI | P1 |
| R5 | **Join clan / usurp** | ⬜ | joinclan.md | P3 |

---

### H. AI — ClanBrain, jobs, FSM

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| A1 | **ClanBrain (pressures, quotas)** | 🟡 | [ai_clan_brain.md](ai_clan_brain.md) | P0 |
| A2 | **WorkRequests & jobs** | 💻 | [tasks_guide.md](tasks_guide.md), [production_economy.md](production_economy.md) | P0 |
| A3 | **FSM priorities & states** | 💻 | bible §XVII, [phase2/STATE_PRIORITIES.md](phase2/STATE_PRIORITIES.md) | P0 |
| A4 | **State blocking & economy rules** | 🟡 | phase2 STATE_BLOCKING, StateEconomyRules | P1 |
| A5 | **Village supply/demand (experience)** | ⬜ | [village.md](future%20implementations/village.md) | P1 |
| A6 | **Wild AI cavemen** | 💻 | build_state, wander claim place | P1 |
| A7 | **Perception / AOP** | 💻 | AOP_PHASE2_PLAN, perception | P1 |

**Target canon file:** `bible/systems/clan_brain_canon.md`, `bible/systems/fsm_canon.md`.

---

### I. Player — controls, RTS, UI, inventory

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| U1 | **Universal controls & hotkeys** | 🔒 | [UI.md](UI.md) | — |
| U2 | **Inventory & drag-drop** | 🔒 | UI.md (DragAndDrop guide stale) | — |
| U3 | **RTS / War Horn / formations** | 🟡 | [rts.md](rts.md), [party_ui.md](party_ui.md) (next) | P0 |
| U4 | **Party command & pile** | ⬜ | party_ui.md | P0 |
| U5 | **Context menus (herd, raid, build)** | 💻 | phase2 dropdown, rtsguide | P1 |
| U6 | **Vitals (health, calories, water)** | 💻 | bible §III, BalanceConfig | P1 |
| U7 | **Clan menu (C)** | ⬜ | future Clan_Menu.md | P2 |
| U8 | **Tutorial beats** | ⬜ | tutorial.md, earlygame_vision | P2 |
| U9 | **Camera & selection** | 💻 | main.gd, rtsguide | P2 |

---

### J. Multiplayer & persistence

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| M1 | **Authority model** | 🟡 | [multiplayer.md](multiplayer.md), bible §XX-A | P0 |
| M2 | **Interest management (chunks)** | ⬜ | multiplayer + island_mp | P1 |
| M3 | **Island MP (4 quadrants)** | ⬜ | [island_mp.md](future%20implementations/island_mp.md) | P1 |
| M4 | **Save / load** | ⬜ | scattered | P2 |
| M5 | **Disconnect → AI runs claim** | ⬜ | island_mp | P1 |

---

### K. Meta, progression, social

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| K1 | **Win / domination (sandbox)** | 🟡 | bible §I | P2 |
| K2 | **Relics & shrine buffs** | 🟡 | bible §XIV, economy_catalog §3.10 | P1 |
| K3 | **Shaman / medicine / potions** | 🔒 | economy_catalog §3.7–3.8, §11.16 | — |
| K4 | **Insanity / enlightenment** | ⬜ | clan_insanity_enlightenment.md | P3 |
| K5 | **Custom flag** | ⬜ | customflag.md | P3 |
| K6 | **Generational permadeath** | 🟡 | bible §I, inheritance docs | P2 |

---

### L. Content & presentation (supporting)

| ID | System | Status | Owner / best doc | P0 |
|----|--------|--------|------------------|-----|
| L1 | **Art direction & sprites** | 🟡 | Art docs, SPRITE_SHEET_* | P2 |
| L2 | **Animation / limb tuner** | 💻 | guides/animation_tuner.md | P2 |
| L3 | **Audio / music** | ⬜ | [music.md](music.md) | P3 |
| L4 | **Playtest & instrumentation** | 💻 | [PLAYTEST.md](PLAYTEST.md), clanbrain_report | P1 |

---

## 3. Recommended lock order (program)

Work in **waves** so later systems depend on earlier locks.

### Wave 1 — Foundation (P0, blocks everything)

1. **T1–T3** Territory & nomad → `territory_canon.md`  
2. **E1, E7–E9** Already in economy_catalog — mark 🔒 in this index only  
3. **E3, E6, E8** Gather + production + food buffer → `gather_canon.md`, `production_canon.md`  
4. **A1, A3** ClanBrain + FSM → `clan_brain_canon.md`, `fsm_canon.md`  
5. **W2–W3** Chunk + mutations (MP-safe)  
6. **H1–H2, H4** Herd + hunt core  
7. **C1–C2, C5** Agro + combat + defend  
8. **R2–R3** Raid verbs + brain scoring (design lock before more raid code)  
9. **T5** Camp layout (hearth, corral, stations) — extend village rundown into `village_layout_canon.md`  
10. **U3** RTS + party (merge rts + party_ui when party ships)

### Wave 2 — Growth loop

P3–P4 reproduction, P5–P7 lineage/genetics, E12 proto farming, H3 cordage steal, P10–P11 food/housing caps, A5 village supply/demand.

### Wave 3 — World & MP

W5–W6 island play, M1–M3 multiplayer, W8 wildlife kits in chunks, R4 loot rules polish.

### Wave 4 — Depth

Combat morale, wounds, predators, trade, lategame, tutorial, clan menu.

---

## 4. Per-system workflow (repeatable)

1. **Pick** a row from §2 with status 🟡 / 💻 / ⬜ and P0.  
2. **Collect** sources (owner doc + code + tests).  
3. **Draft** `bible/systems/<slug>_canon.md` from template.  
4. **Review** against code: either update code to match or mark **Implementation gap** in §8.  
5. **Add tests** or playtest gates in §9.  
6. **Set Locked** + date; update this master index; link from [README.md](README.md).  
7. **Trim** stale sections in old guides (banner: “superseded by X_canon.md”).

**Folder:** `bible/systems/` — one file per locked domain (create as we go).

---

## 5. Relationship to roadmap

[roadmap_2026.md](roadmap_2026.md) = **when we build**.  
This file = **what must be true** when we build.

Before starting a roadmap phase task, check: is the relevant system **Locked** or at least **Partial** with §3 rules written? If not, spend the first PR on canon for that system.

---

## 6. Changelog

| Date | Change |
|------|--------|
| 2026-10-06 | Initial master index + template + lock workflow |
