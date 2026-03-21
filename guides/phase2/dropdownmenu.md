# Context Menu (Right-Click Dropdown) – Implementation Plan

**Date**: January 2026  
**Status**: Planning  
**Scope**: Mac/Windows-style context menu for interacting with buildings, NPCs, land claims, and other world entities.

---

## Overview

**Context menu model (Mac / Windows style):**

1. **Right-click** on NPC, building, or land claim → **context menu (dropdown) opens** at that target.
2. **NPC freezes** (stops movement) while the menu is open.
3. Player **hovers** over menu options (vertical list) → **hovered option is highlighted**.
4. Player **left-clicks** the highlighted option → **confirm** action; run it; close menu.
5. **Cancel:** Click outside menu or press **ESC** → close without action.

This replaces “click → immediate open” (character menu, building inventory). Same interaction as standard OS context menus.

**Goals:**
- **Right-click** = open context menu on target. **Hover** = highlight option. **Left-click** = confirm selection.
- Extensible: same menu for NPCs, buildings, land claims.
- **Clan NPCs:** Follow, Defend, Info (menu). **Clansmen** can also be **dragged** to player (follow) or land claim (defend) when menu is closed — see *Drag & drop*.
- **Follow**: Unbreakable herd follow; player = leader.
- **Defend**: NPC stays at land claim border; first-line defense.
- **Info**: Opens character menu (stats, inventory).

---

## Target Types & Options

### 1. Clan-Member NPCs (woman, clansman, caveman, baby)

**Condition:** Same clan as player (e.g. `npc.clan_name == player clan` from land claim).  
**Options:**

| Option   | Action |
|----------|--------|
| **Follow** | Set NPC into unbreakable herd follow; player = leader. |
| **Defend** | Instruct NPC to stay inside the player’s land claim. |
| **Info**   | Open character menu (existing `CharacterMenuUI`). |

- Non–clan members (e.g. wild, enemy): different options (e.g. **Attack**, **Info** only, or no Follow/Defend). Exact set TBD; dropdown must support “options vary by target.”

### 2. Buildings (LandClaim, BuildingBase)

**Options:**

| Option           | Action |
|------------------|--------|
| **Open Inventory** | Land claim: open land claim inventory (+ build menu). Building: open building inventory if applicable. |
| **Info** (optional) | Future: building-specific info (occupation, production, etc.). |

- Reuse existing `BuildingInventoryUI` / land claim flow; dropdown only routes to it.

### 3. Land Claims

- Same as “Buildings” above when clicking the claim itself: **Open Inventory** (and optionally **Info** later).

### 4. Other (corpses, resources, etc.)

- **Placeholder:** Define per-type later (e.g. **Loot** for corpses, **Gather** for resources). Architecture should allow adding new target types and options without reworking the core dropdown.

---

## Option Semantics (Clan NPCs)

### Follow

- **Effect:** NPC enters “**unbreakable**” follow mode with the **player as leader**.
- **Implementation notes:**
  - Reuse existing herd system (`is_herded`, `herder`, `herd_state.gd`) but add a distinct “**order-based follow**” (e.g. `follow_order_active` or `unbreakable_herd`) so that:
    - Herd **does not** break due to distance (override or bypass `herd_break_distance` / `_check_herd_break()` for this mode).
    - Herd **does** break only when the player explicitly cancels (e.g. “Stop Follow” from dropdown or future UI) or NPC dies.
  - Player = `herder`; optional extra flag to ignore distance-based break and “steal” logic for order-based follow.
- **Existing:** `herd_state`, `herd_max_distance_before_break`, `_check_herd_break()` in `npc_base.gd`.

### Defend

- **Effect:** NPC is instructed to **stay inside the player’s land claim**.
- **Implementation notes:**
  - New AI/state or overlay (e.g. “**defend_land_claim**” behavior): NPC’s “home” = player’s land claim; prioritizes staying within claim radius; may still fight intruders (Fight or Flight).
  - Integrate with land claim intrusion / agro (e.g. `_check_land_claim_intrusion`) so Defend NPCs respond to threats inside the claim.
  - Clarify: “Stay inside” = hard boundary (never leave) vs. “prefer to stay, can chase slightly out” — document in implementation phase.

### Info

- **Effect:** Open **character menu** for that NPC (existing `CharacterMenuUI`).
- **Implementation:** Call same flow as today: `character_menu_ui.setup(npc)`, `character_menu_ui.show_menu()`, optionally `_freeze_npc_for_inspection(npc, true)`. No new UI.

---

## UI Layout

### Dropdown Structure

```
                [Right-click position at target]
                           │
                           ▼
┌─────────────────────────────┐
│ Follow                      │
├─────────────────────────────┤
│ Defend                      │
├─────────────────────────────┤
│ Info                        │
└─────────────────────────────┘
```

- **Anchor:** At **target** (NPC, building, land claim) — e.g. at right-click position. Convert to screen if using a CanvasLayer. Menu appears at/near the clicked entity.
- **Layout:** Vertical list of options; one per row. **Hover** over an option → **highlight** it (like Mac/Windows context menus).
- **Styling:** Match existing UI (e.g. `UITheme`, brown panels). Same family as Building Menu / inventory panels.

### Behavior (Mac / Windows Style)

- **Open:** **Right-click** on valid target (NPC, building, land claim) → show context menu at target. **NPC freezes** (stops movement) while menu is open.
- **Hover:** Mouse over menu options → **highlight** the option under cursor.
- **Confirm:** **Left-click** the highlighted option → run that action, then **close** menu. Left-click **only** confirms a menu choice when the menu is open.
- **Cancel:** Click outside menu, or press **ESC** → close without action; NPC resumes if it was frozen.
- **Only one menu** open at a time; opening on a new target closes the previous.

### Building / Land Claim

- Options like **Open Inventory** (and later **Info**) instead of Follow/Defend/Info. Same dropdown UX, different options per target type.

---

## Input & Controls

### Context Menu (Canonical — Mac / Windows Style)

| Step | Input | Result |
|------|--------|--------|
| 1 | **Right-click** on NPC, building, or land claim | **Open** context menu at target; **NPC freezes** |
| 2 | **Hover** over menu options | **Highlight** the option under cursor |
| 3 | **Left-click** highlighted option | **Confirm** action; run it; close menu |

**Right-click** opens the menu. **Left-click** confirms the selected (hovered) option. **ESC** or **click outside** closes without action.

### Drag & Drop (When Menu Closed)

When the **context menu is closed**, **left-click hold** on a clansman (or item, etc.) → **drag** → drop on **player** (follow) or **land claim** (defend). When the menu **is** open, left-click is used only to **confirm** a menu option, not to drag.

- **Drag clansman → player** → ordered follow.
- **Drag clansman → land claim** → DEFEND.

### Current vs New

| Current | New |
|--------|-----|
| Click NPC (clan) → instant character menu | **Right-click** NPC → menu → **hover** → **left-click Info** → character menu |
| Click land claim → instant inventory | **Right-click** land claim → menu → **hover** → **left-click Open Inventory** |
| Click building → (disabled) | **Right-click** building → menu → **hover** → **left-click** Open Inventory / Info |
| (various) item / building drag | **Left-click hold** (menu closed) drag items, buildings, **clansmen** |
| Weapon + click NPC → attack | TBD: e.g. **Attack** as menu option for hostiles. |

### Proposed Input Rules

1. **Right-click** on valid target → **open** context menu at target; **NPC freezes**. Never start drag.
2. **Hover** over menu → **highlight** option. **Left-click** on option → **confirm** action; close menu.
3. **ESC / click outside** → close menu; NPC resumes.
4. **Menu closed:** **Left-click hold** on clansman (or item, etc.) → **drag** → drop on player / land claim. No menu open during drag.
5. **Weapon + click:** Defer: “Attack” via menu or separate input.

---

## Implementation Architecture

### New Components

1. **`DropdownMenuUI`** (or `ContextMenuUI`)
   - Scene/script: `scenes/ui/DropdownMenuUI.tscn` + `scripts/ui/dropdown_menu_ui.gd`.
   - Lives on a **CanvasLayer** (e.g. `UI`).
   - API:
     - `show_at(target, screen_position, options: Array[DropdownOption])`
     - `hide()`
     - `option_selected(index or id)` → emit signal or callback; main wires to actions.

2. **Dropdown option definition**
   - Minimal: `{ "id": "follow" | "defend" | "info" | "open_inventory" | ..., "label": "Follow" }`.
   - Optional: icons, shortcuts, disable state.

3. **Target resolution**
   - **Click pipeline:** On **right-click** only (when not dragging, not over UI):
     - **Resolve target:** Raycast or distance-check vs NPCs, buildings, land claims.
     - **Build options:** From target type + context (e.g. clan member vs not).
     - **Show context menu** at target; **freeze NPC** if target is NPC. **Left-click** is used to **confirm** a menu option (after hover highlight), not to open the menu.

### Integration Points

- **`main.gd`:**
  - **Right-click** on target → resolve target → show context menu; **freeze NPC** if target is NPC.
  - **Hover** over options → highlight. **Left-click** on option → call handler (Follow, Defend, Info, Open Inventory, etc.); close menu.
  - Continue to manage `character_menu_ui`, `building_inventory_ui`, `clicked_npc`, `nearby_building` as today; menu only changes **when** they’re opened (after **left-click** confirm on option).

- **Land claim / BuildingBase:**
  - **Right-click** can emit “I was clicked” (e.g. `_on_clicked`). Main uses that to **select** the target and show menu, then **left-click** “Open Inventory” triggers `_on_land_claim_clicked` / building inventory flow.

- **NPC resolution:**
  - Keep “which NPC is under cursor?” logic (distance < 32 px, etc.). **Right-click** → select NPC, show menu, **freeze NPC**. **Left-click** **Info** → run character-menu flow.

### File Structure (Proposed)

```
scripts/
├── ui/
│   ├── dropdown_menu_ui.gd     (NEW)
│   ├── character_menu_ui.gd    (existing)
│   └── build_menu_ui.gd        (existing)
scenes/
└── ui/
    └── DropdownMenuUI.tscn     (NEW, optional if fully code-built)
```

---

## Implementation Phases

### Phase A: Context Menu UI + Wiring

1. Add `DropdownMenuUI` (scene + script).
2. Implement `show_at(target, position, options)`, `hide()`, **hover highlight**, `option_selected` on **left-click**.
3. In `main.gd`, **right-click** on target → resolve target → show menu; **freeze NPC** if NPC. **Left-click** on option → confirm; **hover** → highlight.
4. Add **Info** and **Open Inventory** handlers (on **left-click** confirm) that call existing logic (character menu, land claim/building inventory).
5. **No** Follow/Defend yet; just menu + Info + Open Inventory.

### Phase B: Follow (Unbreakable Herd)

1. Add “order-based follow” (e.g. `follow_order_active` / `unbreakable_herd`) for clan NPCs.
2. When **Follow** chosen: set `herder = player`, `is_herded = true`, enable order-based follow; bypass distance-based herd break (and optionally steal logic) for this mode.
3. Implement “Stop Follow” (dropdown when clicking same NPC again, or separate mechanism).
4. Reuse `herd_state` where possible; minimal divergence.

### Phase C: Defend

1. Add “defend land claim” behavior (state or overlay).
2. When **Defend** chosen: bind NPC to player’s land claim; AI keeps NPC inside claim radius.
3. Hook into existing land claim intrusion / combat so Defend NPCs react to threats.

### Phase D: Polish & Extensions

1. Non–clan NPC options (e.g. Attack, Info).
2. **Info** for buildings; further options for “other” types.
3. Keyboard shortcuts (e.g. 1/2/3 for Follow/Defend/Info) — optional.
4. Visual feedback (highlight selected target when dropdown is open).

---

## Edge Cases & Validation

- **Right-click on empty world:** No target → no menu.
- **Left-click on world (no menu open):** Can start **drag** (e.g. left-click hold on clansman). **Right-click** opens menu; **left-click** confirms option when menu is open.
- **Click on UI:** Don’t open world context menu; UI handles its own clicks.
- **Drag in progress (left-click hold):** Don’t open or interact with menu; handle drag.
- **Menu open + click outside:** Close menu; no action; NPC resumes.
- **Multiple valid targets under cursor:** Priority (e.g. NPC > building > land claim); resolve single target for **right-click**.
- **NPC dies / becomes invalid while menu open:** Close menu and clear target.
- **Follow:** Only for clan members; grey out or hide **Follow** for others. **Clansmen** can also be **dragged to player** (left-click hold when menu closed) for follow.
- **Defend:** Only show if player has a land claim; otherwise hide or disable. **Clansmen** can also be **dragged to land claim** (left-click hold when menu closed) for defend.

---

## Summary

| Item | Description |
|------|-------------|
| **Right-click** | **Open** context menu on NPC, building, or land claim. **NPC freezes** while menu open. |
| **Hover** | **Highlight** menu option under cursor. |
| **Left-click** | **Confirm** highlighted option; run action; close menu. When menu **closed**, **left-click hold** = **drag** (clansmen → player / land claim, items, buildings). |
| **UI** | Vertical menu at target; Mac/Windows-style context menu. |
| **Clan NPCs** | Menu: Follow, Defend, Info. **Clansmen** also **drag** (left-click hold, menu closed) to player (follow) or land claim (defend). |
| **Buildings / Land claims** | Menu: Open Inventory (and optionally Info). |
| **Integration** | `DropdownMenuUI`; `main.gd` routes **right-click** → target → menu; **hover** → highlight; **left-click** on option → action. **Left-click hold** (no menu) → drag. |
| **Phasing** | A: Context menu + Info + Open Inventory → B: Follow → C: Defend → D: Polish. |

**Right-click** = open menu. **Hover** = highlight. **Left-click** = confirm (menu open) or **drag** (menu closed). Clansmen can be dragged to player (follow) or land claim (defend).
