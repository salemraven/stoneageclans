# Stone Age Clans — RTS Guide

**Player control of clansmen, modes, selection, drag-and-drop**

---

## Design Philosophy

Stone Age Clans uses a **light RTS** model. You don’t micromanage every action — you set **intent** (Follow, Defend, Search, Work). NPCs pull their own tasks and follow rules; your commands override autonomous work.

**Rules:**
- Player commands set **mode/intent**, not tasks
- Modes block autonomous behavior (gather, wander, etc.)
- All commands are cancelable

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

### 4. Follow and Guard Modes

When clansmen follow you, you choose formation style via HUD.

**FOLLOW (loose formation)**
- Distance: 50–150px behind leader (config)
- In hostile: 40–120px
- Max break distance: 300px (non-ordered herding); **ordered follow does not break by distance**

**GUARD (tight formation)**
- Distance: 28–80px around leader (ordered: ~45px)
- In hostile: 32–45px
- Max distance: 120px — if leader moves farther, followers break and stop following (unless in combat)

**HUD controls**
- **FOLLOW** button — loose formation
- **GUARD** button — tight formation
- **Break Follow** — clear ordered follow from all followers

---

### 5. Ordered Follow vs Herding

**Ordered follow** (`follow_is_ordered = true`)
- Trigger: context menu **FOLLOW** or drag clansman → player
- Unbreakable until **Break Follow**, **Work**, **Defend**, or death
- Ignores distance break (except GUARD mode at 120px)
- Cannot be stolen by other herders
- Mirrors leader’s hostile state (weapon = hostile)

**Herding (right-click wild NPCs)**
- Right-click woman/sheep/goat/caveman → they follow
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
| Formation | HUD: FOLLOW (loose) / GUARD (tight) |
| Break follow | HUD: Break Follow |
| Hostile | Equip weapon (automatic) |

---

## Related Guides

- `Task_system.md` — Tasks, modes, pull-based work
- `HERDING_SYSTEM_GUIDE.md` — Herding, influence, stealing
- `phase2.md` — Defend, Search, FSM states
- `main.md` — Full mechanics overview
