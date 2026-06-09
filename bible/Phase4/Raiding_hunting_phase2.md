# Raiding & hunting — Phase 2 (in-game backlog)

**Parent doc:** [`raiding_hunting.md`](raiding_hunting.md)

**Focus:** Only items we can **ship in the Stone Age Clans codebase** — incremental changes on top of **ClanBrain**, **`hunt_state` / `raid_state`**, **`party`**, **`FormationUtils`**, **`flee_prey_state`**, **sound**, and **land claim**. Bigger fantasies (full ecology, wind/scent simulation) stay in **§8 Future** so they don’t bloat near-term scope.

**Related:** [`bible/rts.md`](../rts.md), [`bible/ai_clan_brain.md`](../ai_clan_brain.md), `scripts/npc/states/hunt_state.gd`, `scripts/npc/states/raid_state.gd`, `scripts/npc/states/flee_prey_state.gd`, `scripts/ai/clan_brain.gd`.

---

## Principles

1. **Reuse one spine** — pressure-like variables, steering blends, and phase FSMs should feel parallel for **prey flee**, **AI hunt return**, and **AI raid retreat** where possible (not three unrelated AI stacks).
2. **Reward positioning over DPS** — formations, sound, and routing already exist; extend them before adding new combat verbs.
3. **Readable, not simulation-heavy** — a few floats + clear state thresholds beat giant behavior trees.
4. **Primitive command tone** — horn, stances, movement; avoid MMO-style ability bars for this phase.

---

## Current foundation (do not break)

- **Player:** Peace / Agro / Hunt HUD, STALK / ARC / AMBUSH / HIDE, horn **aborts** Hunt (loud), formations from **`FormationUtils`** + **`rts_formation_config.gd`**.
- **AI hunt:** `HuntPhase` forming → chasing → killing → looting → returning; **`get_hunt_intent()`**, **`use_stalk_approach`** / **`is_stalking`**, abort grace if brain/claim flickers. **AoH prey only:** deer/mammoth via **`NPCConfig.is_ai_hunt_prey_type`**; sheep/goat/woman stay **herd** (`herd_wildnpc`), not ClanBrain hunt targets.
- **AI raid:** Mirror pattern in **`raid_state`** + ClanBrain party form/disband.
- **Deer:** **`flee_prey_state`**, **`NPCConfig`** thresholds, **fright meter + burst flee speed** on **`NPCBase`** / **`SteeringAgent`**, sound / panic hooks, **player proximity centroid fallback** in **`PerceptionArea`**.

---

## Tier A — High impact, fits current architecture (do these first)

| ID | Feature | What to implement | Touchpoints |
|----|---------|-------------------|-------------|
| **A1** | **Prey pressure (prey-side)** | One accumulated scalar (0–100-style) from **visible threats** + decay; map to **few** substates (graze / alert / nervous / flee) instead of binary detect→flee. **Partial (shipped):** **`deer_fright_*`** meter + forced **`flee_prey`** — still one flee state, no separate graze/alert substates yet. | **`npc_base.gd`**, **`flee_prey_state.gd`**, **`perception_area.gd`**, **`sound_detection.gd`**, **`NPCConfig`** |
| **A2** | **Prey stamina** | Drain while sprinting in flee; recover when calm; cap speed / turn rate when low (**winded** hooks). **Partial:** burst vs winded speed multipliers (**`deer_flee_burst_speed_mult`** / **`deer_winded_speed_mult`**); no dedicated stamina pool yet. | **`flee_prey_state.gd`**, **`npc_base` / `steering_agent`** |
| **A3** | **Directional flee** | Replace “always away from centroid” with **scored candidate directions** (away from humans, toward open space, soft herd bias) — cheap dot-product scoring, no navmesh requirement. | `flee_prey_state.gd` |
| **A4** | **Hunt LOOTING** | Replace short timer with **corpse / loot spawn** (or pickup task) + **one** log line (PlaytestInstrumentor / SESSION) for tuning. | `hunt_state.gd`, corpse/loot pipeline, `CorpseConfig` |
| **A5** | **Combat exit cleanup** | Audit **`hunt_after_combat`**, **`combat_target`**, agro meter when leaving hunt or combat so hunters don’t stick in combat after prey dies. | `hunt_state.gd`, `combat_state.gd` |
| **A6** | **Telemetry** | Structured events: `hunt_phase_change`, `raid_phase_change`, `hunt_cancel(reason)`, `raid_cancel(reason)` with clan + target ids (optional JSONL). | `PlaytestInstrumentor`, `clan_brain.gd` cancel paths |
| **A7** | **STALK ↔ sound (player party)** | Ensure **STALK** stance actually scales **footstep / SoundDetection** contribution end-to-end; one manual or scripted scenario vs **`deer_sound_threshold`**. | `party_state.gd`, `sound_detection.gd`, `main.gd` context |
| **A8** | **Raid / hunt parity** | Shared **return-to-claim** feel: leash, steering home, cancel on **alert** symmetric to hunt cancel where design matches. | `raid_state.gd`, `clan_brain.gd`, `hunt_state.gd` |

---

## Tier B — Group wildlife & migration (medium scope)

| ID | Feature | What to implement | Notes |
|----|---------|-------------------|--------|
| **B1** | **Herd anchor / migration bias** | Wild groups share a **slow-moving anchor** or **preferred heading** (E/W bias) so motion is **directional**, not pure `wander` ping-pong. Low-frequency heading changes (minutes), plus local grazing noise. | Chunk/wild spawn or `HerdController`-style node; **`ChunkUtils`** / spawn scripts |
| **B2** | **Migration corridors** | Data-only or editor **polyline / markers**: herds bias toward routes (river strip, forest edge). Start with **weight in steering**, not full path following. | World gen or `ResourceIndex`-style markers |
| **B3** | **Herd shape** | Light **spacing** rules: front slightly faster, calves inward — boid-lite or slot offsets (reuse formation ideas for animals). | Wild NPC herd update loop |
| **B4** | **Species configs** | Export **acceleration, turn cap, pressure decay, stamina** per `npc_type` (deer vs mammoth) in **`NPCConfig`** or small Resource — avoid duplicating scripts per species. | `npc_config.gd` |

---

## Tier C — Raid depth (reuse Tier A ideas)

| ID | Feature | What to implement | Notes |
|----|---------|-------------------|--------|
| **C1** | **Defender / settlement pressure** | Land claim or defender group accumulates **pressure** from deaths, horn, fire proxy, outnumbered — thresholds for **pull more defenders** vs **routing** (even simple: reduce aggressor chase distance). | `defend_state`, `clan_brain`, land claim |
| **C2** | **Morale / routing (humans)** | Optional **morale scalar** on clansmen (like A1): above threshold → prefer **steer away** / break contact; same **directional scoring** as A3 for retreat vector. | `combat_state.gd`, `agro_state.gd` — start minimal |
| **C3** | **Raid phases ↔ pressure** | Wire **raid intent** so “shock” moments (first casualty, fire) spike pressure once, not every frame spam. | `clan_brain.gd`, `raid_state.gd` |

---

## Tier D — Polish (after A–C feel fun)

| ID | Feature | Notes |
|----|---------|--------|
| **D1** | **Formation looseness** | Small per-follower jitter / delayed slot convergence in **`party_state`** or **`FormationUtils`** — keep cohesion, kill “perfect grid.” |
| **D2** | **Terrain multipliers** | If tile/biome tags exist: multiply **noise**, **speed**, **visibility** (mud, tall grass) — start with 2–3 tags. |
| **D3** | **Animal locomotion pass** | `move_toward` / capped turn rate on **`CharacterBody2D`** velocity for deer vs mammoth (mass feel) — shared helper on **`npc_base`** or prey base. |

---

## §8 Future (explicitly not Tier A–D)

Track separately so scope doesn’t creep:

- Full **tracking** VFX (prints, blood trails, birds).
- **Seasonal reversal** of migration (`direction *= -1` on day counter).
- **Wind / scent** grids.
- Deep **village civilian** sim for raids.
- Large **PressureAgent / AnimalBase** refactor — only if Tiers A–C justify it.

---

## Suggested build order (sprints)

1. **Sprint 1:** A1 + A2 + A3 on deer (one species proven); tune with logs.
2. **Sprint 2:** A4 + A5 + A6 (one corpse path + cleanup + telemetry).
3. **Sprint 3:** A7 + A8 (player stalk sound + raid/hunt parity).
4. **Sprint 4:** B1 + B4 (directional wild herds + exported tuning).
5. **Sprint 5:** C1 or C2 (pick **one** raid depth vector).

Adjust based on playtest; do not start B until A1–A3 feel good in-hand.

---

## Success signals

Players (or you in logs) describe hunts/raids as **cut off**, **too loud**, **they ran before we closed**, **drive them toward X** — without needing UI bars (animation + motion sell the state).

---

## Related docs

- [`raiding_hunting.md`](raiding_hunting.md)
- [`docs/hunting_system_edge_cases.md`](../../docs/hunting_system_edge_cases.md) — add when locking edge cases

---

## Changelog

| Date | Note |
|------|------|
| 2026-05-01 | Initial phase 2 roadmap. |
| 2026-05-02 | **Trimmed to in-game tiers only**; removed chat paste; merged hunt, raid, and animal/migration items into A–D + future §8. |
| 2026-05-06 | Clan **insanity / enlightenment** idea moved to `bible/future implementations/clan_insanity_enlightenment.md` (removed from §8 here). |
