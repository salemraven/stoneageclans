# Stone Age Clans — RTS Guide

**Last updated:** May 2026  
**Authoritative engineering doc:** `bible/rts.md` · **Hunt stances:** `bible/Phase4/raiding_hunting.md` · **Index:** `bible/README.md`

**Player control of clansmen, modes, selection, drag-and-drop**

---

## Design Philosophy

Stone Age Clans uses a **light RTS** model. You don’t micromanage every action — you set **intent** (Follow, Defend, Search, Work). NPCs pull their own tasks and follow rules; your commands override autonomous work.

**Rules:**
- Player commands set **mode/intent**, not tasks
- Modes block autonomous behavior (gather, wander, etc.)
- All commands are cancelable

**Code terms:** Fighters in ordered follow use FSM state **`party`** (Peace/Agro/Hunt stance formations: Follow, Guard, Hide, Attack, Ambush, Stalk, Arc). Wild women/animals being escorted use FSM state **`herd`** — different rules (influence, steal). See **`bible/rts.md`** and **`bible.md` Terminology**.

---

## Core RTS Elements

### 1. Selection

**Box selection**
- **LMB** click on empty ground (not on an NPC) → start selection box
- Drag to draw a rectangle
- **LMB release** → only **player's clansmen** (same clan as player's land claim) inside the box are selected
- Selected units get a bright outline
- If the player has no land claim, no units are selected

**Single selection**
- Right-click an NPC → context menu (no single-select-only; drag applies to selection if NPC is in it)

**Multi-unit commands**
- Any command (Follow, Defend, Search, Work) via **context menu** or **drag-and-drop** applies to the **whole selection** if the target NPC is selected
- Drag one selected NPC → drop → all selected NPCs receive the command

---

### 2. Context Menu (Right-Click)

Right-click a target → dropdown opens.

**Enemy or non–same-clan NPCs**

- **INFO** only (no Follow, Defend, Hunt, etc.)

**Same-clan: caveman, clansman**

| Option | Effect |
|--------|--------|
| **FOLLOW** | Ordered follow (unbreakable until Break Follow or death) |
| **DEFEND** | Assign to defend land claim border |
| **SEARCH** | Assign to ant-style exploration from land claim |
| **WORK** | Clear role; return to auto (gather, wander, etc.) — only shown if already Defend/Search |
| **INFO** | Open character menu (stats, inventory) |

**Same-clan: clanswomen (claimed)**

- **INFO** only. They can be herded when wild, but once claimed they cannot follow/guard (no Follow option).

**Same-clan: sheep / goat**

- **FOLLOW**, **HUNT**, **INFO**

**Land claim**

- **INFO** → open inventory/build menu  
- **DEFEND** → call all clan cavemen/clansmen back to defend this claim (emergency defend)

**How to use**
1. Right-click target
2. Hover option to highlight
3. Left-click to confirm (ESC or click outside to cancel)

---

### 3. Drag-and-Drop (Clansmen)

When the **context menu is closed**, you can drag NPCs for quick commands.

**How**
- **LMB** click and **hold** on a caveman or clansman
- Hold briefly → drag starts (preview icon follows cursor)
- Release over a valid drop target

**Drop targets**

| Drop on | Result |
|---------|--------|
| **Player** (within ~56px) | Ordered follow |
| **Inside land claim** (within radius) | Clear role — return to Work |
| **Outside land claim** (empty world) | Assign Defend (this land claim) |

**Batching**
- If the dragged NPC is in the selection, the command applies to **all selected** clansmen/cavemen.

---

### 4. Modes & stances — Peace / Agro / Hunt

When clansmen are on **ordered follow**, you set **mode** and **stance** with the bottom RTS strip (exact geometry and speeds: **`bible/rts.md`** §4 and **§11a**).

**Mode row:** **PEACE** · **AGRO** · **HUNT** (one active). **Stance row:** three buttons whose labels change with the mode, plus **Break**.

| Mode | Stances (typical) |
|------|-------------------|
| **PEACE** | **FOLLOW**, **GUARD**, **HIDE** — escort, defense ring, or hold cover/crouch |
| **AGRO** | **ATTACK**, **GUARD**, **AMBUSH** — closing line, tight ring, or hide until you swing |
| **HUNT** | **AMBUSH**, **STALK**, **ARC** — hide-until-swing, slow quiet rear arc, semicircle ahead |

**Peace — travel vs caution**

- **FOLLOW:** loose escort **behind**; **full** formation speed (**~1.0×**) when moving as a unit.
- **GUARD:** ring around you; **slower** (**~0.75×**) — “we might get hit.”
- **HIDE:** seek cover or crouch; hold until you change stance or **Break**.

**Agro — raid closing**

- **ATTACK:** line **ahead**; tuned for combat closing (**~0.85×** march vs Follow — numbers in `STANCE_CONFIG`).
- **AMBUSH:** hide near cover; followers jump in when **your melee windup** starts (simple trigger).

**Hunt — approach prey**

- **STALK:** wide rear arc, **slower** and **quieter** footsteps — good for closing on deer without sprinting in.
- **ARC:** curved slots **ahead** of you; aim by moving — no separate “ping prey” button.

**Hunt, raid, long movement — recommended**

- Move the band in **Peace + FOLLOW** (or GUARD if you want the tighter ring) until you’re **near** the fight or prey.
- Don’t march forever in **ATTACK** or heavy hunt shapes: those are for **closing**, not cross-map travel.
- Near contact: **Agro + ATTACK**, or **Hunt + ARC/STALK/AMBUSH** as needed.

**HUD controls**

- Mode + stance buttons apply to **selection**; **Break** clears ordered follow (see below).

Full hunting write-up: **`bible/Phase4/raiding_hunting.md`**.

---

### 5. Ordered Follow vs Herding

**Ordered follow** (`follow_is_ordered = true`)
- Trigger: context menu **FOLLOW** or drag clansman → player (or **ClanBrain** forming an NPC raid party: same-clan caveman leader + followers)
- Fighters use FSM state **`party`** (not **`herd`**): Follow/Guard/Attack formations and speeds match the player-led path (`FormationUtils` + `formation_slots` on the leader).
- Unbreakable until **Break Follow**, **Work**, **Defend**, raid cleanup, or death (exact break rules depend on source of the order)
- Ignores distance break (except GUARD mode at 120px)
- Cannot be stolen by other herders
- Mirrors leader’s hostile state (weapon for player; NPC leader `is_hostile` for AI parties)

**Herding (right-click wild NPCs)**
- Right-click woman/sheep/goat → they attach as **wild herdables**; FSM **`herd`** (tethered follow, influence/steal, `NPCConfig` follow refresh + speed mult)
- Cavemen/clansmen are **not** in **`herd`** for formations — only the wild types above
- Uses normal herd rules: breaks if you go >300px; can be stolen
- Bringing them into land claim radius claims them for your clan

---

### 6. Hostile Mode (Raid)

**Automatic**
- **Weapon equipped** (axe, pick, club in right hand) → followers are hostile
- Followers mirror leader `is_hostile`
- Agro set to 70 so they’re ready to fight

**Hostile follower behavior**
- Auto-attack enemies in detection range
- Stay closer (40–120px, GUARD: 32–45px)
- Move ~40% faster (1.4x)
- “Raid path”: if hostile + herder = player + ordered follow + enemies seen → enter combat

---

### 7. Role Assignments

**DEFEND**
- Patrol land claim border
- Engage intruders
- Do not leave claim
- Set via: context menu **DEFEND**, or drag clansman → world (outside claim)

**SEARCH**
- Ant-style exploration from land claim
- Find resources/herds; return with what they can carry
- Set via: context menu **SEARCH**

**WORK**
- Clear Defend/Search
- Return to auto behavior (gather, wander, etc.)
- Set via: context menu **WORK**, or drag clansman → inside land claim

---

### 8. Item Drag-and-Drop

**Inventory**
- Drag items: player ↔ land claim ↔ buildings ↔ NPCs ↔ corpses ↔ ground
- Valid drop = highlight; invalid = red; source fades while dragging
- Buildings: drag from build menu onto world inside claim (50px spacing)

---

## Quick Reference

| Action | Method |
|--------|--------|
| Select multiple | LMB drag on empty ground → box select |
| Follow | Context menu FOLLOW, or drag clansman → player |
| Defend | Context menu DEFEND, or drag clansman → world (outside claim) |
| Search | Context menu SEARCH |
| Work (clear role) | Context menu WORK, or drag clansman → inside land claim |
| Stances | HUD: **PEACE / AGRO / HUNT** modes — three stance buttons each — see §4 & **`Phase4/raiding_hunting.md`** |
| Break follow | HUD: Break Follow |
| Hostile | Equip weapon (automatic) |

---

## Related Guides

- **`Phase4/raiding_hunting.md`** — Raid cohesion + **Peace / Agro / Hunt** hunting HUD (stalk, arc, hide, ambush, deer fright / flee tuning)
- **`wildlife_movement.md`** — Wild profiles, chunk migratory spawn, deer flight meter + JSONL trace flags
- **`rts.md`** — Authoritative RTS doc: formations, speeds, horn, break, playtest (`bible/rts.md`)
- `Task_system.md` — Tasks, modes, pull-based work
- `HERDING_SYSTEM_GUIDE.md` — Herding, influence, stealing
- `phase2.md` — Defend, Search, FSM states
- `main.md` — Full mechanics overview
