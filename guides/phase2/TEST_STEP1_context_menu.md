# Step 1 — Context Menu (DropdownMenuUI) — Manual Test

**Goal:** Verify context menu shows, hover highlights, left-click confirms, ESC/click-outside closes.

## How to test

1. **Run the game** (e.g. `./run_with_logging.sh` or Godot editor Play).

2. **Open context menu (debug):**
   - Move mouse where you want the menu (e.g. over world, or **over an NPC**).
   - Press **F2**.
   - A small menu appears at/near the mouse. For clansman/caveman: **FOLLOW**, **DEFEND**, **SEARCH**, **WORK** (if assigned), **INFO**. For woman/baby: **FOLLOW**, **INFO** only.
   - **If cursor was over an NPC:** that NPC **freezes** until you pick an option, press ESC, or click outside.

3. **Hover:**
   - Move mouse over each option. The hovered option should **highlight** (Button default highlight).

4. **Confirm with left-click:**
   - **Left-click** one of the options.
   - Menu should **close**.
   - Console/terminal should print: `Context menu option selected: follow` (or `defend` / `info`).

5. **ESC:**
   - Press **F2** again to open menu.
   - Press **ESC**. Menu should **close** without selecting.

6. **Click outside:**
   - Press **F2** again.
   - **Click** on the dark overlay (outside the menu panel). Menu should **close**.

## Pass criteria

- [ ] F2 opens menu at mouse position.
- [ ] **F2 over NPC → NPC freezes** until menu closes (option/ESC/outside).
- [ ] Hover highlights options.
- [ ] Left-click on option → menu closes, `option_selected` logged.
- [ ] ESC closes menu.
- [ ] Click outside (overlay) closes menu.

## Step 2: Right-click (after Step 2 wired)

- **Right-click** NPC → menu at target; NPC freezes. **Right-click** land claim / building → menu. **Right-click** empty world → no menu.
- **Right-click** on UI (hotbar, inventory, etc.) → no menu.

## Step 3: Info

- **Right-click** clan NPC → menu → **left-click** **INFO** → character menu opens.
- **Right-click** land claim → menu → **left-click** **INFO** → land claim inventory + build menu.
- **Right-click** building (e.g. oven) → menu → **left-click** **INFO** → building inventory.
- Character menu / building inventory no longer open on left-click; only via context menu.

## Step 4: Target-type-specific options

- **Right-click** woman or baby → menu has **FOLLOW**, **INFO** only (no Defend/Search).
- **Right-click** clansman or caveman (player has land claim) → **FOLLOW**, **DEFEND**, **SEARCH**, **WORK** (if assigned), **INFO**.
- If target (e.g. NPC) dies while menu is open → menu closes automatically.

## Step 5–6: Ordered Follow & Break Follow

- **Right-click** NPC → menu → **left-click** **FOLLOW** → NPC follows player (unbreakable; no distance break).
- Run far away → NPC keeps following. Press **B** (**Break Follow**) or use **HUD "Break Follow"** → all followers stop.
- **B** = Break Follow (Step 9: HUD button left of hotbar; B key still works).

## Step 9: HUD — Hostile, Break Follow

- **HUD** panel **left of hotbar**: **Hostile** (CheckButton), **Break Follow** (Button).
- **Hostile** on → followers mirror (is_hostile); **Hostile** off → clear. Toggle Hostile → followers update.
- **Break Follow** → same as **B**; all ordered followers released.

## Step 10: NPC drag (left-click hold)

- **Left-click hold** (~0.2s) on **clansman/caveman** (menu closed, not over UI) → drag starts; **preview** follows mouse.
- **Drop on player** (within ~56px) → **ordered follow** (same as Follow).
- **Drop inside player’s land claim** → **DEFEND** that specific claim (same as DEFEND).
- **Drop outside any land claim** (world) → **SEARCH** (same as Assign SEARCHING); requires at least one player claim.
- Drop on UI → cancel; no follow/defend/search.
- **Right-click** NPC → menu; **left-click** option = confirm (no drag). **Quick left-click** (no hold) = attack if weapon in slot 1.

## Step 7–8: DEFEND

- **F4** (debug): spawn **1 caveman + 2 wild women** near player (for Follow/Defend testing).
- **F3** (debug): hover over clansman/caveman, press **F3** → DEFEND set; NPC moves to land claim border and patrols. Requires player-owned land claim.
- **Right-click** clansman/caveman → menu → **left-click** **DEFEND** → same (uses player's land claim). Option only if player has land claim.
- When intruder enters claim, defender goes agro/combat then returns to border. Axe shows when hostile/defending (WeaponComponent).

## Step 11: Role overrides (DEFEND / SEARCH / WORK)

- **DEFEND** → NPC added to claim's defender pool, `defend_target` set, clears follow. NPC patrols border.
- **SEARCH** → NPC added to claim's searcher pool, `assigned_to_search` + `search_home_claim` set, clears defend/follow. **Search state:** ant-style loop (outbound waypoints, 5 attempts, return home, then wander/search again).
- **WORK** (only when NPC is assigned) → removed from both pools, `defend_target` / `assigned_to_search` / `search_home_claim` cleared, **and follow broken** for that NPC; returns to WORKING.
- **Test:** DEFEND → NPC counts as defender. SEARCH → NPC moves outward then returns. WORK → returns to normal, follow cleared. Ratios (20% defend, 20% search) on claim for future auto-assignment.

### Drag → outside = Search (guide)

- **Left-click hold** clansman/caveman → drag → **drop on empty world** (not on player, not inside a land claim). NPC is assigned **SEARCH**; must have ≥1 player land claim. NPC enters search state (outbound → return home after 5 attempts).

## Notes

- **F2** remains for quick test; **right-click** opens menu in play (Step 2).
