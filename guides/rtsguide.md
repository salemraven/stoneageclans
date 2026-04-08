# Stone Age Clans — RTS Guide

**Player control of clansmen, modes, selection, drag-and-drop**

---

## Design Philosophy

Stone Age Clans uses a **light RTS** model. You don’t micromanage every action — you set **intent** (Follow, Defend, Search, Work). NPCs pull their own tasks and follow rules; your commands override autonomous work.

**Rules:**
- Player commands set **mode/intent**, not tasks
- Modes block autonomous behavior (gather, wander, etc.)
- All commands are cancelable

**Code terms:** Fighters in ordered follow use FSM state **`party`** (Follow/Guard/Attack formations). Wild women/animals being escorted use FSM state **`herd`** — different rules (influence, steal). See **`guides/rts.md`** and **`bible.md` Terminology**.

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

### 4. Follow, Guard, and Attack (HUD stances)

When clansmen are on **ordered follow**, you set **stance** with the bottom HUD (exact geometry and speeds: **`guides/rts.md`** §4).

**FOLLOW**
- Loose escort **behind** the leader; **full** formation speed (**1.0×**) for player and clansmen when moving as a unit.

**GUARD**
- **Ring** around the leader; **slower** (**0.75×**) — better for “we might get hit” than for pure travel.

**ATTACK**
- **Line in front** of the leader; higher aggression tuning; **slower** march (**0.85×** player + formation NPCs vs Follow).

**Hunt, raid, long movement — recommended**
- **Most efficient** way to move the **group** across the map (hunt approach, march to a raid): stay in **Follow** until you are **close** to the prey or objective.
- **Do not** use **Attack** for long cross-country travel: it **slows** you and the line is meant for **closing into combat**, not marching.
- When the **target is near**, switch to **Attack** so clansmen fan **ahead** and engage. Optional: **Guard** for a tense approach if you accept slower travel than Follow.

**HUD controls**
- **FOLLOW** / **GUARD** / **ATTACK** — stances (applies to **selection**)
- **Break** — clear ordered follow (see below)

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
| Stances | HUD: FOLLOW (travel) / GUARD / ATTACK (close to fight) — see §4 |
| Break follow | HUD: Break Follow |
| Hostile | Equip weapon (automatic) |

---

## Related Guides

- **`rts.md`** — Authoritative RTS doc: formations, speeds, horn, break, playtest (`guides/rts.md`)
- `Task_system.md` — Tasks, modes, pull-based work
- `HERDING_SYSTEM_GUIDE.md` — Herding, influence, stealing
- `phase2.md` — Defend, Search, FSM states
- `main.md` — Full mechanics overview
