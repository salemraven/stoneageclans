# Stone Age Clans — UI Guide

**Status:** Living canon  
**Last updated:** September 2026  
**Owns:** look, layout, keys, and **drag-and-drop** for every in-game menu.

Slot **counts** (how many bag slots, land-claim slots, max stack) live in code (`BalanceConfig`, building scripts). This file owns **how it looks** and **how you move things**.

If another doc disagrees with this one, **this file wins**.

---

## 1. Philosophy

- Rustic, earthy brown panels. World still shows through (semi-transparent).
- Simple and readable. No ornate chrome.
- **Drag-and-drop is the main way you move stuff** — items, building kits, clansmen.
- No double-click / Shift-click shortcuts unless we add them later on purpose.
- Panels may sit next to each other. Default layout leaves a gap. After you **drag a title bar**, that panel stays where you put it (clamped on screen).
- Visual feedback for every drag: gold = ok, red = no.
- **No click-to-take-one** from a stockpile. Move items by drag only.

---

## 2. Look

Shared tokens live in `scripts/ui/ui_theme.gd` (optional override: `ui/design_tokens/design_tokens.json`).

| Token | Value |
|--------|--------|
| Panel background | `#1a1512` at 85% |
| Border | `#8b4513` at 90%, **2px** (claim/stockpile outer frame **3px**) |
| Corner radius | 12px (list slots **8px**) |
| Shadow | black 25%, 4px, offset (0, 5) |
| Primary text | `#e8e8e8` |
| Secondary text | `#b0b0b0` |
| Error | `#d32f2f` |
| Success | `#66bb6a` |
| Selected / warning | `#ffa726` |
| Valid drop hover | gold `#FFCE1B` (semi) |
| Invalid drop hover | red `#B31B1B` (semi) |

**Two slot shapes only:**

- **List row** (bags, stockpiles): icon + name + one-line description. Height **56px**. **2px** slot border. Stockpile **count** sits on the **right of the row** (overlay, big number, not clipped by the scrollbar). List rows do **not** clip the count (`clip_contents` off).
- **Hotbar square**: ~40×40. Icon + key number + count if stacked food.

Not a Minecraft grid. Last UI pass locked the list.

**Panel sizes (code today):** player bag **320×360**. Land-claim / building stockpile **400×540** (wider so counts fit). Inner pad **12px** on the claim. Default: claim to the **left** of the bag, **16px** gap.

---

## 3. Screens and keys

| Key | What it does |
|-----|----------------|
| **I** | **Today:** toggles bag + nearby building together. **Agreed next:** open **every** panel that applies (bag, party sheet, nearby building — yours or enemy); **I again re-opens** ones you hid. See [party_ui.md](party_ui.md). |
| **Tab** | Stats panel (**planned**; not bound today — `toggle_inventory` is **I** only) |
| **ESC** | Close open **sheets** (bag, building, expanded party). **Agreed:** party **bar** stays if you still have followers. |
| **9 / 0** | Eat from hotbar food slots |
| **Right-click** | Context menu on NPC / building / claim |
| **Left-click hold** | Start a drag (menu closed) |

**Hotbar + vitals** — always at the bottom. Health full width; calories + water half width above the slots.

**Player bag** — list of slots. **No stacking** except food (max 5 per slot). Hotbar 1–8: one item. Hotbar 9/0: food stacks to 5.

**Building / claim / campfire / travois** — **stockpile**. Stacking on (max from `BalanceConfig`, huge on claims). **One row per item type** after consolidate. Big count on the right. Empty slots hidden except **one** empty drop-in row. Deposit bar at the bottom is a **drop shortcut** (same as dropping on the list). Claim also shows build icons. Scroll with the mouse wheel; scrollbar stays hidden so it does not cover counts.

**NPC inventory** — list, no stacking. Read-only (no drop in).

**Corpse** — same panel as a building stockpile. Title: “Corpse of [name]”.

**Character menu** — right-click → Info. NPC freezes while open.

**Context menu** — right-click target, hover highlight, left-click confirms. See `bible/phase2/dropdownmenu.md`.

**Build icons** — on the claim stockpile. Click spends claim materials and puts a building **item** in the player bag. Place it by **dragging that item onto the world**.

**X on panels (agreed next)** — each inventory gets a close control. Bag / building **X** hides that window only. Party sheet **X** **collapses the dock to the bar** (does not **B**). Full rules: [party_ui.md](party_ui.md).

**Party dock (agreed next, not shipped)** — if fighters are following you: a **narrow bar** (Walk / Hunt / Fight + mode shout) stays up. **I** expands **that same dock** into slider + pile. Details: [party_ui.md](party_ui.md). Today’s `CombatHUD` (PEACE / AGRO / HUNT) stays until that lands.

---

## 4. Drag-and-drop (this is the important part)

You pick up a **whole row**. The ghost shows the count (Wood x47). The source row is empty until you drop or cancel.

### Where it can go

| Drop on | What happens |
|---------|----------------|
| **Building / claim / campfire / travois** | Whole stack moves. Same type **merges**. Different type on a filled row: **swap** whole rows. Drop on the list, empty row, or deposit bar: same result (player → stockpile joins that type). |
| **Player bag** | Drop hits **one slot only**. Empty slot: wood/stone = **1** item; food = fill that slot up to **5**. Leftover stays in the stockpile. Occupied other type = red, stack returns. Same food in that slot: merge up to 5. Do **not** spray into every empty bag slot. |
| **NPC bag** | Same as player bag (empty slots only). NPC UI is still read-only for drops *into* the NPC from the player in current code — do not add drops into NPC here. |
| **Hotbar 9 / 0** | Food only. Fill up to 5. Leftover stays in the source. |
| **Hotbar 1–8** | Only if empty and the item belongs in that slot. Count 1. Leftover stays. |
| **World** (not placing a building) | Cancel. Stack snaps back. |
| **World** (building kit from player bag) | Place the building if the spot is valid. |

### Other drags (not items)

- Clansman → player = ordered follow.
- Clansman → land claim = defend.
- Box-select clansmen = RTS selection (`bible/rts.md`).
- **Agreed:** party **pile** is a stockpile (loot + spare kit). Drag like a claim. Cap **5 × party fighters**. Player bag does not count. [party_ui.md](party_ui.md).

### Feedback

- Source row: faded while dragging.
- Valid target: gold wash.
- Invalid: red wash.
- No extra tooltip while the ghost is up.

---

## 5. Layout

```
Top: debug / toasts
Left: building stockpile     Center: player bag     Party sheet (I) / character menu
Bottom: vitals + hotbar; party BAR (if followers) left of hotbar
```

- **Default:** claim left, bag center, character menu on the person. Gap between claim and bag. Hotbar stays at the bottom (not draggable).
- **Move a menu:** drag the **dark title bar**. Player bag, stockpile, and NPC inventory remember that spot (this machine, `user://ui_window_layout.cfg`). Until you drag, they snap back to the default.
- **Resize / reopen:** remembered menus come back; they are **clamped** so they stay on screen. They do not reset to default just because you closed **I**.
- Character / Info menu still **follows the NPC** (not saved).
- Bars (vitals, production, deposit) stay **inside** the panel.
- Z-order: dialogs → menus → HUD → debug.

Minimum layout target: 1280×720. Do not hard-clip stack numbers outside the row.

---

## 6. Checklist for new UI

- [ ] `UITheme` panel / slot style
- [ ] 12px panel corners; list slots 2px border / 8px radius; claim outer frame 3px
- [ ] Stockpile counts fully visible (overlay, not under a scrollbar)
- [ ] Text sizes: title 18–20, body 12–14, secondary 10–12; stockpile count ~18
- [ ] Item/people move by **drag**; title bar moves the **window**
- [ ] ESC closes
- [ ] Default layout does not overlap; after drag, remember + clamp on screen
- [ ] Gold / red drop hover if it is a drop target

---

## 7. Out of scope / planned

Not shipped. Do not treat as current:

- Drag woman onto a Living Hut (`bible/future implementations/hut_assignment.md`)
- Controller / touch drag
- Stats panel (Tab)
- Auto-nudge so two **remembered** windows never overlap (today: you place them; clamp only keeps them on screen)
- **Party dock / pile / short horn / I+X** — **agreed**, not shipped: [party_ui.md](party_ui.md)

Placement / oven history: `bible/phase2/build_menu.md`.  
Old grid / “1 item per drag” notes: `bible/DragAndDropInventoryGuide.md` (stale).

---

## 8. Where it lives in code

| What | File |
|------|------|
| Look tokens | `scripts/ui/ui_theme.gd` |
| List row + count overlay | `scripts/inventory/inventory_slot.gd` |
| Title-bar move + remembered positions | `scripts/inventory/inventory_ui.gd` (`window_layout_id`, `user://ui_window_layout.cfg`) |
| Player bag | `scripts/inventory/player_inventory_ui.gd` |
| Claim / building stockpile | `scripts/inventory/building_inventory_ui.gd` |
| Whole-stack ghost | `scripts/inventory/drag_manager.gd` |
| Stack vs one-per-empty-slot | `scripts/inventory/inventory_data.gd` |
| Combat HUD **today** | `main.gd` (`CombatHUD`) |
| Party UI **agreed** | [party_ui.md](party_ui.md) |
