# RTS — Player commands, formations, and playtest

**Stone Age Clans** — lightweight RTS layer on top of the sim: you **order clansmen** (not cavemen/women as combat squads in the same way), set **stance**, **rally** with the horn, **defend** territory, and **break** formation so they go back to work.

This doc matches **implementation** as of April 2026 (`main.gd`, `party_state.gd`, `formation_utils.gd`, `rts_formation_config.gd`, `wander_state.gd`, UI). **Wild animals** use **`herd` state**, not party. For lore-wide context see **bible.md §I** (primitive command model) and **§XVIII**.

---

## Design intent — early Sapiens, simple orders, clean code

**Lore / UX:** Early *Homo sapiens* would **not** have had spoken language capable of **detailed tactical orders** or “army-scale” micromanagement. Leadership is modeled as **crude, bodily signals**: stay close (**follow**), watch my back (**guard**), push forward with me (**attack**), hold this place (**defend** claim), come when called (**horn**), **disperse** and get back to work (**break**). No flanking hotkeys, stances-within-stances, or chat-style command strings — that would break the fantasy.

**Engineering:** One shared **`command_context`**, **`formation_slots`** on the leader each frame (player via `main`; NPC leader via `FormationUtils`), tuning in **`RTS_CONFIG`** / **`STANCE_CONFIG`**, behavior in **`party_state.gd`** (fighters) and **`main`** ordering paths. New ideas should prefer **new tuning** or **one new verb** over splintering special cases across many files.

---

## 1. What the RTS layer does

| Capability | Notes |
|------------|--------|
| **Select** | Single click, **drag box** (rect on screen), or context target |
| **Order follow** | Context **Follow**, or **drag clansman onto player** |
| **Rally** | **H** (War Horn): clansmen in radius sprint to you; ordered follow + default stance refresh |
| **Stance** | **Follow** / **Guard** / **Attack** (bottom HUD when clansmen selected) |
| **Break** | **Break** HUD button or **B**: clear ordered follow, reset agro path, send clansmen **back toward land claim** / work |
| **Defend** | Context / flow for **defend this land claim or campfire** (border formation) — separate from the moving formation stances |

**Out of scope (by design):** verbal-style micro (waypoints, formations-in-formation), control groups 1–9, minimap ping orders, complex army UI — not part of the primitive-command fantasy and intentionally not implemented.

---

## 2. Controls (reference)

| Input | Effect |
|--------|--------|
| **Right-click NPC** | Context menu: Follow, Defend, Search, Work, Info (options depend on target and clan resolution) |
| **Drag clansman → drop on player** | **Ordered follow** (same clan / valid target) |
| **Drag box** | Select multiple clansmen (requires resolvable **player clan** / territory) |
| **H** | **War Horn**: rally clansmen within **rally radius** (~1500 px, `RTS_CONFIG`); registers followers; applies **command context**; detaches **herd** from rallied clansmen if they were leading animals |
| **B** | **Break** ordered follow (same as Break button) |
| **Follow / Guard / Attack** (HUD) | Sets **stance** on **selected** clansmen and refreshes **command_context** |
| **Break** (HUD) | Dismiss formation; `returning_from_break` meta + wander priority so they walk home |
| **F5** (debug) | Spawns RTS playtest pack: player claim + 5 same-clan clansmen (when running in editor / dev) |
| **Space** | **Gather** (resources / ground items) — not an RTS unit command |

---

## 3. Command context & followers

Each ordered clansman carries a **`command_context`** dictionary (on `NPCBase`), built in `main.gd`:

- **`commander_id`**: leader’s instance id (usually player)
- **`mode`**: `"FOLLOW"` \| `"GUARD"` \| `"ATTACK"`
- **`stance_aggro_threshold`**, **`stance_chase_dist`**: from **STANCE_CONFIG** (see §5)
- **`is_hostile`**: derived from player weapon / RTS rules
- **`issued_at_time`**: timestamp

**Follower list:** `main._follower_cache` — entity ids for **Break**, snapshots, and horn bookkeeping.

---

## 4. Formations (moving with the player)

**Single source of truth per frame:** `main._update_formation_slots()` writes **`formation_slots`** on the **player** (`meta`): per follower id → `slot_pos`, `steer_target`, `slot_index`, `count`, `facing`, `player_stopped`, `mode`.

**`herd_state.gd`** (ordered follow) reads that meta so all clansmen share the **same** geometry — no per-NPC full map scan for slot assignment.

### 4.1 Geometry by stance (intent)

| Stance | Formation | Notes |
|--------|-----------|--------|
| **FOLLOW** | Loose group **behind** leader | Rear arc (~120°) centered on “behind”; escort feel |
| **GUARD** | **Ring** around leader | Even spacing on a circle; medium aggression band |
| **ATTACK** | **Line in front** of leader | Horizontal line perpendicular to facing, ahead of player; offensive posture |

Ideal distances / lookahead are tuned in **`main._update_formation_slots()`** (not duplicated ad hoc in herd_state for slot placement).

### 4.2 Speed & cohesion

| Role | Rule |
|------|------|
| **Player `move_speed`** | **110** px/s baseline (aligned with clansman ~95 base + formation tuning) |
| **Player formation debuff** | **`formation_speed_mult`** meta: slowest stance among **active** ordered followers — **Guard 0.75×**, **Attack 0.85×**, **Follow 1.0×** (`STANCE_CONFIG` + `_update_player_formation_speed`) |
| **Clansman stance multiplier** | Same 1.0 / 0.75 / 0.85 via steering **`set_speed_multiplier`** when “in slot” and leader moving |
| **Catch-up** | If farther than **`slot_settled_dist`** (~35 px) from assigned slot, **2×** speed (`catchup_speed_mult`) even while leader moves — keeps the blob from lagging |

**Leash:** extreme **ordered leash** (~1200 px) can break follow; see `RTS_CONFIG` / herd_state.

### 4.3 Agro & combat vs stance

**STANCE_CONFIG** (in `main.gd`):

| Mode | `aggro_threshold` | `chase_dist` | `speed_mult` |
|------|---------------------|--------------|--------------|
| FOLLOW | 0 | 0 | 1.0 |
| GUARD | 70 | 150 | 0.75 |
| ATTACK | 100 | 300 | 0.85 |

Higher threshold = easier to enter combat / chase. **FOLLOW** is passive; **ATTACK** is full offensive band.

### 4.4 Recommended flow — hunt, raid, and long movement

**Most efficient cross-country:** Keep the group in **Follow** while you move **long distances** over terrain (hunting approach, marching toward a raid target, exploration). **Follow** uses **full** player and clansman formation speed (**1.0×**); the band stays in a loose escort **behind** you.

**Switch to Attack only when closing:** **Attack** stance **slows** the **player** (**0.85×** `formation_speed_mult`) and clansmen (**0.85×** when moving in formation). It also places the line **ahead** of you — good for **engagement**, awkward for **marches**. Treat **Attack** as a **short-range** signal: flip to **Attack** when the **prey, enemy, or objective is near**, not for crossing the whole map.

**Guard** sits in the middle (**0.75×**) — use when you expect trouble along the route but still need to move faster than Attack; it is still slower than Follow for pure travel.

| Situation | Stance |
|-----------|--------|
| Long walk / ride to hunting ground or raid | **Follow** |
| Cautious approach, expect skirmishes | **Guard** (optional) |
| Close enough to fight or breach | **Attack** |

---

## 5. War Horn (H)

- **Cooldown:** ~1 s (`RTS_CONFIG.war_horn_cooldown`)
- **Radius:** ~1500 px (`rally_radius`)
- Rallied units get **ordered follow** and **command_context**; stance HUD can be used after rally
- **Edge case:** If a clansman was **herding** wild NPCs, rally **clears herd** so they can join formation

---

## 6. Break

- Clears **follower cache** / ordered follow flags and related hostile timers where applicable
- Sets **`returning_from_break`** meta (time window from `RTS_CONFIG`) and forces **wander** with **high priority** so **gather / herd** do not immediately steal the NPC
- **Wander** steers toward **land claim** until close, then clears meta so normal work resumes

---

## 7. Defend (static POI)

**Defend land claim / campfire** is a **different** flow from Follow/Guard/Attack: clansmen take **defend_state**, stand on **claim border** in a spread pattern. Use context menu / systems wired in `main.gd` + `defend_state.gd`. (Exact menu strings may say DEFEND.)

---

## 8. Gathering (player) — overlap with RTS

Not RTS, but often confused:

- **Space** gathers the **active** target among overlapping `Area2D` nodes (`active_collection_resource` on `main`)
- **Berry bushes** use tall sprites with **feet at node origin**; hitbox is **aligned to sprite** in `gatherable_resource.gd` (`_align_gather_hitbox_to_sprite`) so overlap matches the art
- Stale **active** pointer after ground-item pickup was fixed (clear on free + prune invalid in `_process`)

---

## 9. Playtest & telemetry

| Mechanism | Purpose |
|-----------|---------|
| **`--playtest-capture`** | Enables `PlaytestInstrumentor` JSONL session log |
| **`--playtest-log-dir <path>`** | Writes `playtest_session.jsonl` to a folder (good for CI / scripted runs) |
| **`--rts-playtest-spawn`** | CLI variant to spawn RTS test pack (see main / launch scripts) |
| **RTS snapshots** | `clansman_rts_snapshot`: follower mode, state, `dist_to_leader`, `angle_deg`, `rel_pos` (behind/ahead), etc. |
| **Gather diagnostics** | `gather_*` events: `gather_hitbox_ready`, `gather_space_pressed`, `gather_body_entered`, … |

**PowerShell:** see `Tests/run_playtest.ps1`, `Tests/run_and_monitor.ps1` for quoted paths and Godot discovery.

---

## 10. Key files

| File | Role |
|------|------|
| `scripts/main.gd` | Horn, BREAK, selection box, stance HUD, `_follower_cache`, `_update_formation_slots`, `_build_command_context`, `_emit_rts_snapshot`, gather active target |
| `scripts/config/rts_formation_config.gd` | **`RTS_CONFIG`** tuning dict |
| `scripts/npc/states/herd_state.gd` | Ordered follow movement, slot read from player meta, formation speed / catch-up |
| `scripts/npc/states/wander_state.gd` | `returning_from_break` priority + steer to claim |
| `scripts/npc/npc_base.gd` | `command_context`, FSM / component guards |
| `scripts/player.gd` | `move_speed`, `formation_velocity` meta, `formation_speed_mult` |
| `scripts/gatherable_resource.gd` | Hitbox alignment, gather instrumentation hooks |
| `scripts/logging/playtest_instrumentor.gd` | `gather_diagnostic`, RTS snapshot events |

---

## 11. Related docs

- **bible.md** — §XVIII (summary), §I primitive command, hunt/raid travel bullets
- **`guides/rtsguide.md`** — Player-facing RTS guide (selection, drag, stances; links here for numbers)
- **guides/earlygame.md**, **guides/Phase4/config.md** — economy / tuning may mention move speeds
- **.cursor/plans/** — historical RTS cleanup plans (read-only reference)

---

*Last updated: April 2026 — aligned with formation slot pipeline, stance STANCE_CONFIG, and gather hitbox fix.*
