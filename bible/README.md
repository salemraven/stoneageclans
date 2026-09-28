# Stone Age Clans — Bible folder index

**Last updated:** September 2026

All design documentation lives in this **`bible/`** folder. The repo root **`bible.md`** file is only a redirect.

## Which doc is canonical?

| Doc | Use for |
|-----|---------|
| **[bible.md](bible.md)** | Lore, mechanics, code map, implementation snapshot — **start here** |
| **[earlygame_vision.md](earlygame_vision.md)** | **Opening 10 min**, tiers, food, raids, horn — design owner (Sep 2026) |
| **[economy_catalog.md](economy_catalog.md)** | **Items / craft / buildings / gather** — classes, stations, food, containers (Sep 2026 lock) |
| **[environment_goal.md](environment_goal.md)** | **Canonical environment** — wedge biomes, map, weather, resources, wildlife |
| **[island_map.md](island_map.md)** | **Art reference + progress tracker** — map2 layout, **`rebuild_island_biomes.sh` pipeline**, layer status |
| **[roadmap_2026.md](roadmap_2026.md)** | **Unified build order** Phases 0–7 |
| **[game_dictionary.md](game_dictionary.md)** | Terminology (wins over bible table if they conflict) |
| **[dictionary_your_terms.md](dictionary_your_terms.md)** | **Your** design words, checked against docs (Sep 2026) |
| **[dictionary_assistant_terms.md](dictionary_assistant_terms.md)** | Sim names added in write-ups (flags, buffers, indexes) |
| **Wiki** (`mkdocs.yml`, `wiki/`) | Linked pages. Draft until confirmed. `bash tools/serve_wiki.sh` |
| **[gdd.md](gdd.md)** | Player-facing vision / GDD prose (numbers may lag code) |
| **[main.md](main.md)** | Living implementation report (loop, controls, what ships) |
| **[future implementations/](future%20implementations/)** | **Not promised** — ideas only; do not treat as shipped |

Unimplemented mechanics belong in **§XXII** or `future implementations/` — not in core docs unless marked *planned*.

**Doc hygiene (Sep 2026):** If a guide disagrees with **`bible.md`**, **`main.md`**, or **[earlygame_vision.md](earlygame_vision.md)**, treat those three as current. **`future implementations/main.md`** is a historical snapshot — ignore its “not implemented” lines for War Horn, Farm, etc.

**Old path:** former `guides/` folder → merged here (May 2026). Stub: `guides/README.md`.

---

## Core systems (implemented or in progress)

| Guide | Topic |
|-------|--------|
| [main.md](main.md) | Full mechanics + implementation status |
| [game_dictionary.md](game_dictionary.md) | Terms (AoH, party, herd, hunt intent, …) |
| [ai_clan_brain.md](ai_clan_brain.md) | ClanBrain: defense, search, raid, **hunt**, pressures |
| [production_economy.md](production_economy.md) | **WorkRequests**, bread/leather chains, passive cooking |
| [hunting.md](hunting.md) | **Hunting hub** — NPC AoH hunts + player RTS hunt modes |
| [Phase4/raiding_hunting.md](Phase4/raiding_hunting.md) | RTS PEACE/AGRO/HUNT, stances, deer flee |
| [rts.md](rts.md) | War Horn, formations — **as implemented today** |
| **[party_ui.md](party_ui.md)** | **Agreed next** — party dock, pile, short horn, I/X |
| [wildlife_movement.md](wildlife_movement.md) | Deer, mammoth, herdables, `WildRole` — **current code** |
| [wildlife_migration.md](wildlife_migration.md) | **Seasonal cross-plane** herd migration (design lock) |
| [HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md) | Herd influence, steal, claim join |
| [movement.md](movement.md) | Speed, formation debuffs, steering |
| [GatherGuide.md](GatherGuide.md) | Gather jobs, deposit, ResourceIndex |
| [tasks_guide.md](tasks_guide.md) | Tasks, jobs, TaskRunner |
| [raid.md](raid.md) | Raiding flow (player + AI) |
| [AgroGuide.md](AgroGuide.md) | Agro meter, combat entry |
| [reproduction_guide.md](reproduction_guide.md) | Huts, pregnancy, babies, **baby feeding gap (planned)** |
| [genetics.md](genetics.md) | **Genetics vision** — inheritance, metabolism, evolution (planned) |
| [Buildings.md](Buildings.md) | Building list, placement (**menu today**; design → [economy_catalog.md](economy_catalog.md)) |
| **[economy_catalog.md](economy_catalog.md)** | **Canonical** item classes, recipes, stations, food/containers |
| [items_guide.md](items_guide.md) | Hotbar/slots — **item list stale**; use economy_catalog |
| [traits.md](traits.md) | Species, traits, stats |
| [game_map.md](game_map.md) | Chunks, seed, streaming, `MutationStore` |
| [clan_founding_and_exile.md](clan_founding_and_exile.md) | **Planned (major):** wild cavemen, exile, clan slots, founder spawn |
| [settlement_sim.md](settlement_sim.md) | **Off-screen villages** — actor sleep vs settlement tick (babies, build, craft) |
| [future implementations/off_screen_clan_balance.md](future%20implementations/off_screen_clan_balance.md) | **Environment-first survival** — dormant gather/hunt/regen/slaughter; placeholder pseudo-biomes; long test tooling |
| [visual_vs_sim_layers.md](visual_vs_sim_layers.md) | Chunk visual/sim/data layers + NPC tier A/B/C |
| **[environment_goal.md](environment_goal.md)** | **Canonical environment** — wedge biomes, map, weather, resources, wildlife |
| **[island_map.md](island_map.md)** | **Art reference + progress tracker** — map2 layout, **`rebuild_island_biomes.sh` pipeline**, layer status |
| [roadmap_2026.md](roadmap_2026.md) | Phased build order (nomad → island MP) |
| [multiplayer.md](multiplayer.md) | MP roadmap + repo stubs |
| [earlygame.md](earlygame.md) | Nomadic loop, territory tiers |
| [nomad.md](nomad.md) | Nomadic playstyle overview · **Tier 1 = campfire land claim** · campfire art needs |
| [earlygame_vision.md](earlygame_vision.md) | **First 10 min, food tiers, raids, horn, genetics UI** — design owner (Sep 2026) |
| [camp_relocation.md](camp_relocation.md) | **Nomad Mode** (ABANDON CAMP, AI relocate) |

---

## Playtest & tuning

| Guide | Topic |
|-------|--------|
| [PLAYTEST.md](PLAYTEST.md) | Capture flags, manual playtest |
| [clanbrain_report.md](clanbrain_report.md) | Standard 5 min AI report spec |
| [Ultimate_npc_clanbrain_test.md](Ultimate_npc_clanbrain_test.md) | Strict gates, AoH, hunts |
| [console.md](console.md) | Log patterns, debug |
| [dev_resources.md](dev_resources.md) | Cursor plans, playtest pipeline |
| [../guides/lag.md](../guides/lag.md) | Lag baseline, profiler, scale roadmap (Aug 2026) |
| [../guides/character_layers.md](../guides/character_layers.md) | **Layered identity** — hair/cloth/hats, atlas, sleep, visual LOD |

---

## Phase / historical docs

Older phase docs may be partially stale — cross-check **`bible.md` §XXI** before trusting “not implemented” lines.

| Folder / file | Notes |
|---------------|--------|
| [phase1.md](phase1.md) | Land claim, herd, deposit |
| [phase2.md](phase2.md) | Reproduction, tasks |
| [phase2/](phase2/) | State priorities, task edge cases |
| [Phase3/](Phase3/) | Map upgrade |
| [Phase4/](Phase4/) | Raid/hunt phase, playtest readiness |
| [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) | Open engineering items |
| [CHANGELOG.md](CHANGELOG.md) | Doc/code changelog |

---

## Future / aspirational only

Everything under **[future implementations/](future%20implementations/)** — village, predators, knapping, prisoner flows (if added), etc. See **`bible.md` §XXII** for the master table.

**Genetics hub:** [genetics.md](genetics.md) (canonical overview) · deep spec: [future implementations/genetics.md](future%20implementations/genetics.md)

**Wild cavemen / clan founding (planned — major update):** [clan_founding_and_exile.md](clan_founding_and_exile.md)

**Also aspirational:** [future implementations/warhorn.md](future%20implementations/warhorn.md) (leader-carried trophy horn — **H rally is implemented**; see [rts.md](rts.md)).

**Female babies (planned):** [future implementations/female_baby.md](future%20implementations/female_baby.md) — sex at birth, daughters → clanswomen, genetics/inbreeding notes; **not shipped**.

**Hut husband assignment (planned):** [future implementations/hut_assignment.md](future%20implementations/hut_assignment.md) — drag-drop male to Living Hut, designated father UI; **not shipped**.

**Herdable raiding (planned):** [future implementations/herdable_raiding.md](future%20implementations/herdable_raiding.md) — cordage capture, STEAL/LOOT/KILL/WIPE raid goals, ClanBrain payoff pick; **not shipped**.

**Proto farming (planned):** [future implementations/proto_farming.md](future%20implementations/proto_farming.md) — Field building, crop ring inside claim, grain → Oven; **not shipped** (today: wild wheat + existing Farm = sheep/wool).

**Island MP (planned):** [future implementations/island_mp.md](future%20implementations/island_mp.md) · environment: [environment_goal.md](environment_goal.md) · art: [island_map.md](island_map.md).

**Lineage (planned):** [future implementations/lineage.md](future%20implementations/lineage.md) — Person ids for genetics + female babies.

**ClanBrain raid scoring (planned):** [future implementations/clanbrain_raid_scoring.md](future%20implementations/clanbrain_raid_scoring.md) — food buffer vs raid goals.

---

## Engine & UI

| Guide | Topic |
|-------|--------|
| [godot_save_scene_help.md](godot_save_scene_help.md) | Editor save conflicts |
| **[UI.md](UI.md)** | **Canon** — look, layout, keys, **drag-and-drop**, compact stockpile, **remembered window positions** (Sep 2026) |
| **[party_ui.md](party_ui.md)** | **Agreed next (not shipped)** — party dock, short horn, pile, I/X, Walk/Hunt/Fight |
| [rts.md](rts.md) | RTS **as implemented today** + pointer to party_ui |
| [UI_IMPLEMENTATION_STATUS.md](UI_IMPLEMENTATION_STATUS.md) | **Stale** checklist — do not follow “1 item per drag” |
| [DragAndDropInventoryGuide.md](DragAndDropInventoryGuide.md) | **Stale** (grid / 1-item drag / “undraggable panels”). Use **UI.md** |
| [draw_order.md](draw_order.md) | Y-sort |
| [SPRITE_SHEET_LAYOUT.md](SPRITE_SHEET_LAYOUT.md) | 8-dir sheets |

---

*When you add a new system guide, link it here and add a row to `bible.md` game systems table if it is a major system.*
