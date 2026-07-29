# Stone Age Clans — Bible folder index

**Last updated:** May 2026

All design documentation lives in this **`bible/`** folder. The repo root **`bible.md`** file is only a redirect.

## Which doc is canonical?

| Doc | Use for |
|-----|---------|
| **[bible.md](bible.md)** | Lore, mechanics, code map, implementation snapshot — **start here** |
| **[game_dictionary.md](game_dictionary.md)** | Terminology (wins over bible table if they conflict) |
| **[gdd.md](gdd.md)** | Player-facing vision / GDD prose (numbers may lag code) |
| **[main.md](main.md)** | Living implementation report (loop, controls, what ships) |
| **[future implementations/](future%20implementations/)** | **Not promised** — ideas only; do not treat as shipped |

Unimplemented mechanics (prisoners, full starvation sim, etc.) belong in **bible.md §XXII** or `future implementations/` — not in core docs unless marked *planned*.

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
| [rts.md](rts.md) | War Horn, formations, `RTS_CONFIG`, engineering |
| [wildlife_movement.md](wildlife_movement.md) | Deer, mammoth, herdables, `WildRole` |
| [HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md) | Herd influence, steal, claim join |
| [movement.md](movement.md) | Speed, formation debuffs, steering |
| [GatherGuide.md](GatherGuide.md) | Gather jobs, deposit, ResourceIndex |
| [tasks_guide.md](tasks_guide.md) | Tasks, jobs, TaskRunner |
| [raid.md](raid.md) | Raiding flow (player + AI) |
| [AgroGuide.md](AgroGuide.md) | Agro meter, combat entry |
| [reproduction_guide.md](reproduction_guide.md) | Huts, pregnancy, babies |
| [Buildings.md](Buildings.md) | Building list, placement |
| [items_guide.md](items_guide.md) | Items, hotbar, resources |
| [traits.md](traits.md) | Species, traits, stats |
| [game_map.md](game_map.md) | Chunks, seed, streaming, `MutationStore` |
| [environment_goal.md](environment_goal.md) | **Environment vision** — island map, water, lushness, ClanBrain resources (goals) |
| [multiplayer.md](multiplayer.md) | MP roadmap + repo stubs |
| [earlygame.md](earlygame.md) | Nomadic loop, territory tiers |
| [nomad.md](nomad.md) | Nomadic playstyle overview |
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

**Also aspirational:** [future implementations/warhorn.md](future%20implementations/warhorn.md) (leader-carried trophy horn — **H rally is implemented**; see [rts.md](rts.md)).

---

## Engine & UI

| Guide | Topic |
|-------|--------|
| [godot_save_scene_help.md](godot_save_scene_help.md) | Editor save conflicts |
| [UI.md](UI.md) / [UI_IMPLEMENTATION_STATUS.md](UI_IMPLEMENTATION_STATUS.md) | UI standards |
| [draw_order.md](draw_order.md) | Y-sort |
| [SPRITE_SHEET_LAYOUT.md](SPRITE_SHEET_LAYOUT.md) | 8-dir sheets |

---

*When you add a new system guide, link it here and add a row to `bible.md` game systems table if it is a major system.*
