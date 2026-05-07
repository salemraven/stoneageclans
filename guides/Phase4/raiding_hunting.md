# Raiding & hunting — group shape, hunt modes, and prey

This guide is for **how your warband should feel** when you raid or hunt: **spread out with cohesion**, not a single blob on the leader’s heels — and for the **Peace / Agro / Hunt** RTS layer that drives **stalking, arc, hide, and ambush**.

**Authoritative numbers** (formations, speeds, horn): **`guides/rts.md`** — especially **§4** (geometry) and **§11a** (modes). **Edge cases:** `docs/hunting_system_edge_cases.md`.

---

## 1. Shared goal: cohesion without clumping

**Intent:** Whether you’re marching to a fight or stalking deer, followers should read as a **group**: each has a **slot** (ring, line, or arc), with **spacing** and **matching pace**, not everyone stacked on the same pixel.

**Implementation (high level):** Ordered fighters use FSM **`party`** and read **`formation_slots`** from the leader (player or NPC leader). Slot math lives in **`FormationUtils.compute_formation_slots`**; tuning in **`rts_formation_config.gd`** / **`STANCE_CONFIG`** in `main.gd`.

**Raid-style tip:** For **long marches**, keep **Peace** mode and **FOLLOW** (or **GUARD** if you want a tighter ring at the cost of speed). Switch to **Agro** and **ATTACK** when you’re **close** to contact so the line forms **ahead** — same idea as before the hunt update (`guides/rtsguide.md` §4).

---

## 2. Hunt modes — bottom RTS HUD

When **clansmen are selected** (or on your follower cache), the combat HUD shows:

1. **Mode row:** **PEACE** · **AGRO** · **HUNT** (one active at a time).
2. **Stance row:** **three buttons** whose **labels change** with the mode, plus **BREAK**.

Default mode is **PEACE** — closest to “classic” Follow / Guard travel.

| Mode | Stances (left → right on HUD) | Role |
|------|-------------------------------|------|
| **PEACE** | **FOLLOW**, **GUARD**, **HIDE** | Escort, defense ring, or **hide / crouch** (cover when available). |
| **AGRO** | **ATTACK**, **GUARD**, **AMBUSH** | Offensive line/ring, or **ambush** (hidden until your leader **starts a melee swing** — windup). |
| **HUNT** | **AMBUSH**, **STALK**, **ARC** | Hide-and-release, **slow quiet** wide rear arc, or **arc ahead** of you for a closing semicircle. |

**`command_context.mode`** stores the stance string (`FOLLOW`, `STALK`, `ARC`, …). Formations and speed multipliers use that same pipeline as the original three stances.

---

## 3. Hunting stances — what to use when

### STALK (Hunt mode)

- **Formation:** Same family as **FOLLOW** (rear arc), but **wider** (~180° style spread vs the tighter default rear arc — see `stalk_formation_arc_half_rad` in **`rts_formation_config.gd`**).
- **Speed:** Slower (**~0.5×** formation multiplier) so the band doesn’t sprint into prey.
- **Sound:** Treated as **quiet** footfalls (`SoundDetection` + **`STALK`** / **`is_stalking`** meta where applied). Still not silent — deer can hear you if you’re loud or close.

**Good for:** Closing distance on **deer** without instantly triggering flee.

### ARC (Hunt mode)

- **Formation:** Slots on a **curved “half moon” ahead** of the leader (same forward anchor idea as **ATTACK**, but **angles** instead of a straight lateral line).
- **Speed:** Tuned between Follow and Attack (`STANCE_CONFIG` **`ARC`**).
- **No target ping:** The arc is **only relative to you** — you **physically** aim the group toward prey (`guides/rts.md` §11a).

**Good for:** Wrapping or presenting a front **before** you commit.

### AMBUSH (Agro or Hunt)

- **Behavior:** Enters **`hide_state`**: moves to **nearest cover** (trees / bushes / tall grass via **`CoverQuery`** + **ResourceIndex**) or **open crouch** if nothing is near.
- Sets **`is_hidden`** when settled; **footsteps suppressed** while hidden.
- **Release:** When you (the **commander** in `command_context`) **start a melee windup**, hidden followers copy your combat target (ally-safe) and spike **agro** into **`combat`** — **simple “attack with me” trigger**, not detection polling on deer.

**Spear-first on ambush:** Design lock-in was **throw if 2+ spears** then melee — wire-up may still be partial; check **`combat_state`** / weapon path if throws don’t appear yet.

### HIDE (Peace mode)

Same **hide / cover** behavior as ambush setup, but **no** “everyone jumps when leader swings” unless you’re in **AMBUSH** stance in Agro/Hunt. Peace **HIDE** is **hold position** until **stance change**, **Break**, or orders change.

---

## 4. Horn (**H**) and Hunt abort

- **PEACE / AGRO:** **H** still **rallies** nearby same-clan fighters (radius in **`RTS_CONFIG`**) and refreshes follow/context — see **`guides/rts.md`**.
- **HUNT:** **H** does **not** rally for hunting — it **aborts the hunt**: switches HUD to **PEACE**, sets followers toward **FOLLOW**, plays a **very loud** cue (`SoundDetection` horn volume), which **spooks prey**. Matches the design lock: horn = **regroup / retreat**, not a stealth hunt tool.

---

## 5. Deer, flight, and sound (prey loop)

- **Deer** use **`npc_type == "deer"`** on **`NPCBase`**: **not herdable**. The FSM **`flee_prey`** state runs **`flee_prey_state.gd`** — panicked run from human **centroid** steering + optional **sound** spook.
- **Threats:** Player, cavemen, clansmen, and women inside **`DetectionArea`** counts are turned into a **centroid** in **`PerceptionArea.get_deer_threat_centroid`**. A **distance fallback** ensures the **player** still counts **inside visual range** if **`body_entered` overlap misses**.
- **“Fright” meter** (`NPCBase.deer_fright_meter`): accumulates while humans register in range (fill **`deer_fright_fill_per_sec`**, faster when the **player is closer**), decays when safe / herded (**`deer_fright_decay_per_sec`**). Crossing **`deer_fright_flee_at`** (against **`deer_fright_meter_max`**) forces **`flee_prey`** so approach feels like mounting pressure—not one frame.
- **Sound:** Loud ambient events vs **`deer_sound_threshold`** still contribute to **`flee_prey.can_enter()`** / ongoing threat checks inside **`flee_prey_state`** (`SoundDetection`).
- **Panic:** Starting flee emits a **`deer_panic`** sound so nearby deer can chain-react (**`deer_panic_spread_*`** radius / delays).
- **Burst sprint:** **`deer_flee_burst_speed_mult`** applies during **burst** phase on **`SteeringAgent`**; **winded** phase uses **`deer_winded_speed_mult`**; **`exit`** / leaving state restores **`original_max_speed`**.
- **Stats / tuning (`NPCConfig`, hunting group):** `deer_base_speed`, `deer_hp`, **`deer_perception_visual`**, **`deer_sound_threshold`**, **`deer_fright_*`**, **`deer_flee_burst_speed_mult`**, **`deer_flee_duration_sec`**, **`deer_winded_*`**, footstep volumes.
- **Loot:** **`CorpseConfig`** includes **`deer`** → meat / hide like sheep/goat pattern.

---

## 6. AI clans (same systems)

- **ClanBrain** still raises hunt intent from **Area of Hunt** huntables (**deer**, sheep, goat, mammoth — claim-side filters).
- **Doctrine stub:** For **deer**, if prey is **far** from the claim, **`use_stalk_approach`** can be set so **`hunt_state`** marks hunters **`is_stalking`** while closing — quieter approach until they’re near.

---

## 7. Key files (for designers & coders)

| Area | Files |
|------|--------|
| HUD modes / stances / horn abort | `scripts/main.gd` (`RTS_MODE`, `STANCES_BY_MODE`, `_handle_war_horn`) |
| Formation slots / speeds | `scripts/systems/formation_utils.gd`, `scripts/config/rts_formation_config.gd` |
| Follower movement | `scripts/npc/states/party_state.gd` |
| Hide / ambush | `scripts/npc/states/hide_state.gd`, `scripts/systems/cover_query.gd` |
| Sound | `scripts/systems/sound_detection.gd` (preload where used — no global autoload) |
| Deer flee, fright meter, perception | `scripts/npc/states/flee_prey_state.gd`, `scripts/npc/components/perception_area.gd`, `scripts/npc/npc_base.gd`, `scripts/config/npc_config.gd` |
| AI hunt stalk flag | `scripts/ai/clan_brain.gd`, `scripts/npc/states/hunt_state.gd` |
| Spawn / balance | `scripts/main.gd` (`_spawn_deer`, respawn batch), `scripts/config/balance_config.gd` |

---

## 8. Related docs

- **`guides/Phase4/Raiding_hunting_phase2.md`** — Deeper raid/hunt roadmap (phase 2: doctrine, telemetry, raid/hunt parity, guardrails).
- **`guides/rts.md`** — Full RTS reference including **§11a** (modes).
- **`guides/rtsguide.md`** — Player-facing RTS overview (selection, drag, hostile).
- **`guides/wildlife_movement.md`** — Migratory vs territorial wild NPCs, chunk spawn, **deer flight / fright / debug JSONL**.
- **`bible.md`** — Lore / primitive command tone.

---

*Last updated: May 2026 — Deer fright meter, player proximity fallback, flee burst speed; wild NPC trace / playtest probes (see `guides/wildlife_movement.md`).*
