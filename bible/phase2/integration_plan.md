# Task System & Context Menu Integration Plan

**Purpose:** Break the Task_system + context menu (right-click dropdown) changes into ordered, dependency-aware steps. Each step is small, testable, and builds on the previous.

**References:** `Task_system.md`, `dropdownmenu.md` (context menu: right-click open, hover highlight, left-click confirm)

**Context menu (Mac / Windows style):**
- **Right-click** on NPC, building, or land claim → **open** context menu at target; **NPC freezes**.
- **Hover** over options → **highlight**. **Left-click** highlighted option → **confirm** action; close menu.
- **Drag** (when menu **closed**): **Left-click hold** on clansman (or item, etc.) → drag → drop on **player** (follow) or **land claim** (defend).

---

## Overview

| Phase | Focus | Steps |
|-------|--------|-------|
| **A** | Context menu foundation | 1–2 |
| **B** | Relocate actions to context menu | 3–4 |
| **C** | Ordered follow | 5–6 |
| **D** | DEFEND | 7–8 |
| **E** | HUD & NPC drag | 9–10 |
| **F** | Roles | 11 |
| **G** | Task system (jobs, TaskRunner, NPC-pull) | 12–18 |

---

## Phase A: Context Menu Foundation

### Step 1 — Create DropdownMenuUI (Context Menu)

**Goal:** Add a reusable **context menu** (Mac/Windows style) that shows at target, displays options in a vertical list, **highlights** on **hover**, and **confirms** on **left-click** of highlighted option. Closes on confirm, click outside, or ESC.

**Deliverables:**
- `scripts/ui/dropdown_menu_ui.gd` (and optionally `scenes/ui/DropdownMenuUI.tscn` if not fully code-built).
- API: `show_at(target, screen_position: Vector2, options: Array[{id: String, label: String}])`, `hide()`, **hover → highlight**, **left-click** on option → `option_selected(id: String)` signal/callback.

**Dependencies:** None.

**Details:**
- Options = `{ "id": "follow" | "defend" | "info" | "open_inventory" | ..., "label": "Follow" }`.
- Position menu at `screen_position` (at/near **right-click** target). Use CanvasLayer (e.g. UI).
- **Hover** over option → **highlight** it. **Left-click** highlighted option → emit `option_selected`, then hide. Close on: left-click confirm, click outside, ESC.
- Style consistent with existing panels (e.g. UITheme, build menu).

**Test:** Spawn menu at mouse position with dummy options; **hover** → highlight; **left-click** option → callback; ESC / click outside → hide.

---

### Step 2 — Right-click → context menu (no actions yet)

**Goal:** **Right-click** on NPC, building, or land claim → resolve single target → show **context menu** at target with **placeholder** options. **NPC freezes** if target is NPC. Do **not** open character menu or building inventory on click. **Hover** over options → **highlight**. **Left-click** on option → confirm (handled in Step 3). **Left-click** when menu **closed** = potential **drag** (Step 10).

**Deliverables:**
- `_resolve_click_target() -> { target, target_type }` (or similar) in `main.gd`.
- `_get_dropdown_options_for_target(target, target_type) -> Array`.
- Wire **right-click** only for opening menu: if target resolved → show menu at target; **freeze NPC** if NPC. **Hover** → highlight. **Left-click** on menu option → confirm (placeholder for now). **Do not** call `_try_click_npc_for_inventory` / `_try_click_land_claim_for_inventory` / land claim `_on_clicked` for opening UIs.

**Dependencies:** Step 1 (DropdownMenuUI exists).

**Details:**
- **Context menu:** **Right-click** = open menu at target; **NPC freezes**. **Hover** = highlight option. **Left-click** on option = confirm. **ESC** / click outside = close.
- **Target resolution:** Use world mouse position on **right-click**. Check NPCs (distance &lt; ~32px), then buildings (collision/area), then land claims (distance ≤ radius). Priority: NPC &gt; building &gt; land claim.
- **Drag** (menu **closed**): **Left-click hold** on clansman/item/etc. → drag (Step 10). If drag in progress, **don’t** open menu. Menu closes only on option chosen or cancel (outside click / ESC).

**Test:** **Right-click** NPC → menu at target; NPC freezes. **Right-click** land claim / building → menu. **Right-click** empty world → no menu. **Hover** → highlight. **Left-click** on option → (placeholder). **Left-click hold** (no menu) → drag (once Step 10 exists).

---

## Phase B: Relocate Actions to Context Menu

### Step 3 — Wire “Open Inventory” and “Info”

**Goal:** Context menu **Open Inventory** opens building/land claim inventory; **Info** opens character menu. Character menu is **only** opened via **Info** (after **right-click** → menu → **hover** → **left-click** Info), never by direct click. **Left-click** on option = confirm; when menu **closed**, **left-click hold** = drag (Step 10).

**Deliverables:**
- Context menu handler in main: on **left-click** confirm → `option_selected("open_inventory")` / `option_selected("info")` → call existing land claim / building inventory flow or character menu.
- On `option_selected("info")` for clan NPC → `character_menu_ui.setup(npc)`, `character_menu_ui.show_menu()`, `_freeze_npc_for_inspection(npc, true)`. Set `clicked_npc` / `nearby_building` when opening so existing “close on release” or other logic still works if we keep it for **these** UIs.
- **Remove** opening character menu or building inventory from **right-click** path (except as menu open). **Right-click** opens menu; **left-click** confirms option. When menu closed, **left-click hold** = drag.

**Dependencies:** Step 2.

**Details:**
- When do we close character menu / building inventory? Context menu closes on left-click confirm, ESC, or click outside. Character menu has its own close behavior; decide and document (e.g. ESC, explicit close button, or click outside).
- **Building inventory:** If we open it from “Open Inventory”, we still need `nearby_building` or equivalent so the UI knows which building/land claim to show.

**Test:** **Right-click** clan NPC → menu → **hover** → **left-click** Info → character menu opens. **Right-click** land claim → menu → **left-click** Open Inventory → land claim inventory + build menu. Same for building. **Right-click** → menu → click outside → menu closes. **Left-click** on option confirms.

---

### Step 4 — Target-type-specific options & edge cases

**Goal:** Show only valid options per target (e.g. clanswoman: no Defend). Handle edge cases: no target, **right**-click on UI (no world menu), **left**-click hold = drag when menu closed (no menu open), multiple targets, invalid target while menu open.

**Deliverables:**
- `_get_dropdown_options_for_target()` respects NPC role (clanswoman: Follow, Info only; no Defend / Assign).
- **Right**-click on UI → no world menu. **Left**-click hold (menu closed) = drag; no menu. Drag in progress → no menu. Multiple targets → single resolved target by priority (**right-click**).
- If target invalidated (e.g. NPC died) while menu open → hide menu, clear target.

**Dependencies:** Step 3.

**Test:** **Right-click** clanswoman → menu, no Defend option. **Right-click** clansman → Defend present. **Right-click** UI → no menu. **Left-click** hold (menu closed) → drag. Resolve priority when overlapping NPC/building.

---

## Phase C: Ordered Follow

### Step 5 — `follow_is_ordered` & unbreakable follow

**Goal:** Player-initiated follow is unbreakable (no distance-based herd break). Break only on Break Follow, explicit Stop Follow, or NPC death.

**Deliverables:**
- Add `follow_is_ordered` (or equivalent) on NPC. When set, skip distance-based herd break in `_check_herd_break()` / `herd_state`; optionally ignore “steal” logic for ordered follow.
- Set `follow_is_ordered = true` and `herder = player` when follow is triggered (context menu or later drag). Clear on break.

**Dependencies:** None for this step; can run parallel to Phase A/B if needed. Dropdown “Follow” wiring depends on Step 4.

**Details:**
- Reuse `is_herded`, `herder`, `herd_state`. Differentiate “ordered” vs “herded by attraction” so only ordered follow ignores distance break.

**Test:** Follow NPC via context menu (Step 6) → run far away → NPC keeps following. Break Follow → NPC stops following.

---

### Step 6 — Wire dropdown “Follow” & “Break Follow”

**Goal:** Dropdown **Follow** sets ordered follow. **Break Follow** clears ordered follow for all followers.

**Deliverables:**
- On `option_selected("follow")` for clan NPC → set ordered follow (Step 5).
- **Break Follow** HUD button or dropdown “Stop Follow”: clear `follow_is_ordered` (and `herder` if applicable) for all NPCs currently following player.

**Dependencies:** Step 4 (context menu), Step 5 (unbreakable follow).

**Test:** Follow via dropdown → unbreakable. Break Follow → all stop. Follow again → works.

---

## Phase D: DEFEND

### Step 7 — DEFEND state / behavior

**Goal:** DEFEND mode: NPC holds land claim border, patrols within guard band, engages hostiles in AOP, returns to guard after combat.

**Deliverables:**
- New FSM state (or behavior) “defend” / “defend_idle”. NPC has `defend_target` (land claim or position).
- Logic: move to border, stay near it, on hostile in AOP → agro/combat, then return to guard.

**Dependencies:** None for behavior. Wiring to dropdown/drag in Step 8.

**Details:**
- Hook into existing land claim intrusion / agro so DEFEND NPCs react. **Clansmen only.**

**Test:** Manually set NPC to DEFEND (e.g. debug) → stays at border, attacks intruder, returns.

---

### Step 8 — Wire “Defend” & drag NPC → Landclaim

**Goal:** Context menu **Defend** (right-click → menu → left-click Defend) and **drag clansman → land claim** (left-click hold when menu closed) set DEFEND mode and `defend_target`.

**Deliverables:**
- On `option_selected("defend")` for clan NPC → set `mode = DEFEND`, `defend_target =` player’s land claim (or current land claim in context).
- **NPC drag-from-world:** **left-click hold** on clansman (menu closed), drop on land claim → same as Defend. (Full drag UX in Step 10.)

**Dependencies:** Step 4 (context menu), Step 7 (DEFEND behavior).

**Details:**
- If player has no land claim, hide or disable Defend option.

**Test:** Defend via context menu → NPC defends. Drag NPC → land claim (once implemented) → same.

---

## Phase E: HUD & NPC Drag

### Step 9 — HUD: Hostile toggle, Break Follow

**Goal:** HUD left of hotbar: **Hostile** toggle (player raid leader), **Break Follow** (clear ordered follow for all).

**Deliverables:**
- Small HUD panel with Hostile and Break Follow. Hostile toggles player “raid leader” state (followers mirror). Break Follow uses same logic as Step 6.

**Dependencies:** Step 6 (Break Follow logic).

**Test:** Toggle Hostile → visuals/intent clear. Break Follow → all followers released.

---

### Step 10 — NPC drag-from-world (Left-Click Hold: Clansmen → Player / Land Claim)

**Goal:** **Left-click hold** on **clansman** in world (when **context menu is closed**), drag, drop on **Player** → ordered follow; drop on **Land claim** → DEFEND. **Right-click** opens context menu; **left-click** confirms menu option when menu open. **Left-click hold** when menu **closed** = drag.

**Deliverables:**
- **Left-click hold** NPC drag: hit-test clansman on **left-click** hold when menu closed, not over UI. Drag preview (e.g. NPC icon or highlight).
- Drop-on-player / drop-on-land-claim detection. On drop → same as Follow / Defend (Steps 6, 8).
- Don’t start NPC drag if context menu is open (left-click = confirm option). Don’t start if item/building drag in progress. **Right-click** on NPC opens menu; no drag.

**Dependencies:** Step 6, Step 8. Extend or add NPC-drag flow; **left-click hold** when menu closed.

**Test:** **Left-click hold** clansman (menu closed) → drag → player → follow. **Left-click hold** clansman → land claim → defend. **Right-click** NPC → menu; **left-click** on option → confirm, no drag. No conflict with item/building drag.

---

## Phase F: Roles & Later Work

### Step 11 — Role overrides (Assign DEFEND / SEARCHING / Work)

**Goal:** Context menu **Assign DEFEND**, **Assign SEARCHING**, **Work** (normal behavior). Land claim tracks defender/searcher pools; default 20% defend, 20% search when unassigned.

**Deliverables:**
- Land claim (or equivalent) holds `assigned_defenders`, `assigned_searchers`, default ratios.
- Context menu options per Task_system: Assign DEFEND, Assign SEARCHING, Work. Selection logic: player override &gt; quota-based assignment &gt; WORKING.

**Dependencies:** Step 4 (context menu), Step 7–8 (DEFEND). SEARCHING behavior not yet defined; can add stub “assigned to search” and implement search logic later.

**Test:** Assign Defend via context menu → NPC counts as defender. Work → returns to normal. Ratios apply when not overridden.

---

## Phase G: Task System (Jobs, TaskRunner, NPC-Pull)

*Implements “work as a sequence of reusable TASKS.” See `Task_system.md` → **Task System Plan**.*

### Step 12 — Task base class

**Goal:** `Task` base with `start(actor)`, `tick(actor, delta)` → RUNNING/SUCCESS/FAILED, `cancel(actor)`.

**Deliverables:** `scripts/ai/tasks/task.gd` (or similar). Status enum. Tasks are dumb; no mode/issuer.

**Dependencies:** None.

**Test:** Instantiate a no-op Task; start → tick → SUCCESS. Cancel mid-run.

---

### Step 13 — TaskRunner component

**Goal:** NPC component that holds `current_job`, `current_task`; runs tick loop; `cancel_current_job()`.

**Deliverables:** `scripts/ai/task_runner.gd` as Node. Attach to NPC. Advance job on SUCCESS; clear on FAILED or cancel.

**Dependencies:** Step 12.

**Test:** Assign a simple Job (e.g. two no-op tasks); runner completes both. Cancel → job cleared.

---

### Step 14 — Job container

**Goal:** Job = ordered list of tasks. `advance()`, `get_current_task()`, `is_complete()`.

**Deliverables:** `scripts/ai/jobs/job.gd`. Holds `tasks: Array[Task]`, current index.

**Dependencies:** Step 12.

**Test:** Build Job from 3 tasks; TaskRunner runs through; `is_complete` when done.

---

### Step 15 — Concrete tasks (MoveTo, PickUp, DropOff, Wait)

**Goal:** Implement MoveTo, PickUp, DropOff, Wait. Use 50 px deposit range. Hook into steering, inventory, existing systems.

**Deliverables:** Task subclasses. MoveTo drives steering target; PickUp/DropOff use inventory + source/dest.

**Dependencies:** Step 12, existing steering/inventory.

**Test:** Job = MoveTo(land claim) → PickUp(wood, 5) → MoveTo(oven) → DropOff(wood, 5). NPC runs it.

---

### Step 16 — Building `generate_job(worker)`

**Goal:** Buildings expose `generate_job(worker) -> Job | null`. Example: Oven bake-bread job (land claim → oven → occupy → wait → land claim). Buildings never assign.

**Deliverables:** Oven (or one building) implements `generate_job`. Returns Job or null. No `npc.set_job()`.

**Dependencies:** Step 14, 15.

**Test:** Woman asks oven for job; gets valid Job. Run it via TaskRunner.

---

### Step 17 — NPC-pull wiring

**Goal:** Job-doing state (e.g. work_at_building or new “work” state) pulls job when idle. Queries nearby buildings `generate_job(self)`; picks one (e.g. distance, drag-to-building bias). Assigns to TaskRunner.

**Deliverables:** State pulls on enter/idle; assigns job; state update delegates to TaskRunner or runs alongside.

**Dependencies:** Step 13, 16. FSM / mode layer.

**Test:** WORKING woman with no job → queries buildings → gets oven job → runs it. Job done → idle → pulls again.

---

### Step 18 — Interrupt wiring (mode switch, agro)

**Goal:** Mode switch or agro → `cancel_current_job()`. No task injection. NPC exits job-doing state; FSM picks mode-appropriate state.

**Deliverables:** ModeController/mode logic and agro path call `task_runner.cancel_current_job()` when interrupting.

**Dependencies:** Step 13, 17. Modes, agro.

**Test:** Woman in oven job; agro triggers → job cancelled, enters combat. Threat gone → returns to WORKING, can pull new job.

---

### Later (post–Phase G)

- **Hunt** button (reuse raid machinery; target wild NPCs).
- **Intel sharing:** searchers report resources; workers use intel.
- **ModeController** layer (modes gate FSM) — if not done earlier.
- **Gather / herd as tasks** (optional migration from FSM states).
- **Resource locking** for world resources (PickUp); **job caching**; **LOD** for 50+ NPCs.

---

## Dependency Graph (Summary)

```
1 (Context menu UI)
    ↓
2 (Right-click → resolve target → show menu; hover → highlight; left-click confirm; left-click hold = drag when closed)
    ↓
3 (Open Inventory + Info handlers) → 4 (target-specific options)
    ↓
5 (follow_is_ordered) ──→ 6 (Follow + Break Follow)
    ↓
7 (DEFEND state) ──→ 8 (Defend + drag → land claim)
    ↓
9 (HUD) ← 6        10 (NPC drag) ← 6, 8        11 (Role overrides) ← 4, 7–8
    ↓
12 (Task base) → 13 (TaskRunner) → 14 (Job) → 15 (MoveTo, PickUp, …)
    ↓
16 (generate_job) → 17 (NPC-pull) → 18 (interrupt wiring)
```

---

## Recommended implementation order

**Phases A–F (context menu, follow, defend, HUD, drag, roles):**  
1. **Step 1** — DropdownMenuUI (context menu: hover highlight, left-click confirm)  
2. **Step 2** — Right-click → context menu (hover highlight, left-click confirm); no direct opens; left-click hold = drag when closed  
3. **Step 3** — Open Inventory + Info (relocate character menu)  
4. **Step 4** — Target-specific options, edge cases  
5. **Step 5** — `follow_is_ordered`, unbreakable follow  
6. **Step 6** — Follow + Break Follow  
7. **Step 7** — DEFEND state  
8. **Step 8** — Defend + drag NPC → land claim  
9. **Step 9** — HUD (Hostile, Break Follow)  
10. **Step 10** — NPC drag-from-world  
11. **Step 11** — Role overrides (Assign DEFEND / SEARCHING / Work)  

**Phase G (Task system):**  
12. **Step 12** — Task base class  
13. **Step 13** — TaskRunner component  
14. **Step 14** — Job container  
15. **Step 15** — Concrete tasks (MoveTo, PickUp, DropOff, Wait)  
16. **Step 16** — Building `generate_job(worker)`  
17. **Step 17** — NPC-pull wiring  
18. **Step 18** — Interrupt wiring (mode switch, agro)  

---

## Checklist template (copy per step)

```
[ ] Step N — <name>
    [ ] Implemented
    [ ] Tested (list cases)
    [ ] No regressions (character menu, building inventory, drag placement)
    [ ] Updated Task_system / dropdownmenu (context menu) if needed
```

---

## Status Report (Phases A–F)

**Scope:** Steps 1–11 (context menu, follow, defend, HUD, NPC drag, role overrides). **Phase G (Task system)** not yet started.

### What went well

- **Stepwise integration:** Moving slowly and testing after each step caught regressions early (e.g. character menu, building inventory, drag).
- **Documentation alignment:** `dropdownmenu.md`, `Task_system.md`, and this plan stayed in sync on input (right-click menu, left-click confirm, left-click hold = drag).
- **Context menu UX:** Right-click → menu at target, hover highlight, left-click confirm, NPC freeze while menu open — all work as intended. ESC / click outside close the menu.
- **Target resolution:** Single target per click (NPC > building > land claim), 32px radius. Works for menu, drag, and attack.
- **Ordered follow:** `follow_is_ordered` + herd-state skip on distance break → unbreakable follow until Break Follow or death.
- **DEFEND:** `defend_state` patrols land-claim border, intrusion sets `combat_target`, defenders engage and return to guard.
- **NPC drag:** Left-click hold (menu closed) → drag preview → drop on player (follow) or land claim (defend). No conflict with context menu or item/building drag.
- **Role overrides:** Assign DEFEND / SEARCHING / Work via context menu; land claim `assigned_defenders` / `assigned_searchers`; remove-from-pools on Work or reassignment.
- **Combat:** Player equips from hotbar slot 1 (right hand), left-click attack triggers aggro. Defenders aggro on intrusion. Followers in Hostile Mode (raid path) engage enemies without prior agro.
- **Agro:** Always decays (2/sec in combat, 5/sec out). Clearing `combat_target` when agro < 70 + FSM re-eval stops infinite chasing.

### Issues encountered & fixes

| Issue | Cause | Fix |
|-------|--------|-----|
| **Input confusion (left vs right)** | Initial design used left-click for menu, right for drag. | Switched to Mac/Windows style: **right-click** open menu, **left-click** confirm, **left-click hold** (menu closed) = drag. Updated all docs. |
| **`hide()` override** | `DropdownMenuUI.hide()` overrode `CanvasItem.hide()`. | Renamed to `hide_menu()`. |
| **NPC unfreeze on Info** | Menu closed and unfroze NPC when Info opened CharacterMenuUI (which also freezes). | `hide_menu(option_id)`: skip unfreeze if `option_id == "info"`. |
| **Player not equipping weapon** | `_update_equipment()` only on drag to/from hotbar slot 1. | `player_inventory_ui._update_hotbar_slots()` calls `main_node._update_equipment()` so equip syncs on any hotbar refresh. |
| **No aggro on left-click attack** | Attack path was dropped during context-menu refactor. | Restored: LMB release (no drag, not over UI, over NPC, weapon in slot 1) → `_player_attack_npc()` → `combat_comp.request_attack`. |
| **Defenders not aggroing** | Intrusion skipped when NPC `clan_name` empty (e.g. dragged defenders). | Run intrusion when `defend_target` set; derive `filter_clan` from `defend_target.clan_name` or default. |
| **Axes always visible** | Weapons shown regardless of mode. | `WeaponComponent`: show axe only when `is_hostile` or `defend_target` set; skip during WINDUP/RECOVERY. |
| **No swing / hit feedback** | Combat positioning too strict; hit markers on NPC. | Loosened combat_state angle/distance; `_flash_sprite_fallback()` on hit; hit markers on `ui_layer` at screen pos, font 36, tween up. |
| **Slot 0 vs 1** | Code used index 0; design said “slot 1 = right hand”. | `RIGHT_HAND_SLOT_INDEX := 0`; use it everywhere; comments say “slot 1 (right hand)”. |
| **NPC drag vs right-click** | Starting drag then right-clicking left drag state active. | On right-click menu open: reset `npc_drag_source`, `npc_dragging`, `npc_drag_hold_timer`, hide preview. |
| **Crash in enemy land claim** | `combat_target` typed as `NPCBase`; player assigned → type error. | `combat_target` → `Node2D`; `_is_target_still_valid()` handles player vs NPC; same in combat_state, CombatComponent. |
| **Followers in Hostile Mode not attacking** | Combat `can_enter` required agro ≥ 70 or existing target; Followers in Hostile Mode had neither. | “Raid path”: if `is_hostile`, `herder == player`, `follow_is_ordered`, DetectionArea has enemies → set `combat_target` from `get_nearest_enemy`, allow entry. |
| **Followers attacking player** | DetectionArea / legacy enemy finder could target herder (player). | In `get_nearest_enemy` and `_find_nearest_enemy_legacy`: skip `enemy` if `enemy.is_in_group("player")` and `npc.herder == enemy`. Same-clan skip for non-player. |
| **Agro never decayed while chasing** | Decay only when `state != "combat"`; chaser stayed in combat. | Always decay; 2/sec in combat, 5/sec out. When agro < 70, clear `combat_target`, set `evaluation_timer = 0`, `_evaluate_states()`. |
| **Orders to dead body** | `_get_npc_under_cursor` included corpses (`npcs` group). | Skip NPCs with `is_dead()` in `_get_npc_under_cursor`. |
| **Agro stuck at 100 / Battle Royale** | Special-case “no decay at 100” for old combat test. | Agro always decays (including at 100). Removed all battle royale code (init call, `_start_battle_royale()`). |

### What was implemented (summary)

- **DropdownMenuUI:** `show_at(target, position, options)`, `hide_menu(option_id)`, hover highlight, left-click → `option_selected(id)`. Styled with UITheme.
- **Main input:** Right-click → `_resolve_click_target` → `_get_dropdown_options_for_target` → `show_at`; freeze NPC if target NPC. Left-click on option → `_on_dropdown_option_selected`. Left-click hold (menu closed, not over UI) → NPC drag.
- **Options:** Follow, Assign DEFEND, Assign SEARCHING, Work (if assigned), Info. Clanswoman: Follow, Info only. Open Inventory for buildings/land claims.
- **Follow:** `_set_ordered_follow(npc)` → `follow_is_ordered`, `herder = player`, mirror `player_hostile`; `_break_follow_all()` clears follow + `is_hostile` for released.
- **Defend:** `_set_defend(npc)` → `_remove_npc_from_all_player_claim_pools`, `claim.add_defender(npc)`, `defend_target = claim`, clear follow/search. **Defend** context option uses “Assign DEFEND” id.
- **Search:** `_set_searching(npc)` → add to `assigned_searchers`, `assigned_to_search = true`, clear defend/follow. **Work** → `_clear_role_assignment` (pools cleared, flags reset).
- **Land claims:** `assigned_defenders`, `assigned_searchers`, `add_defender` / `remove_defender`, `add_searcher` / `remove_searcher`, `remove_npc_from_pools`. No more direct left-click to open inventory.
- **NPC drag:** Hold threshold → `npc_dragging`, preview TextureRect; `_resolve_npc_drop_target` (player 56px / land claim); drop → follow or defend.
- **Combat HUD:** Hostile toggle, Break Follow. `_on_hostile_toggled` → `_update_followers_hostile`.
- **Combat:** Player attack from slot 1; intrusion → `combat_target` (player or NPC); raid path for Followers in Hostile Mode; agro decay + target clear + FSM re-eval; no targeting of herder (player) or same-clan.

### Questions about the implementation

1. **Work vs Assign:** “Work” clears explicit DEFEND/SEARCH assignment. Should “Work” also clear **Follow**? Currently we have a separate Break Follow; Work only clears defend/search.
2. **SEARCHING behavior:** Step 11 adds “assigned to search” and pool logic, but **what do searchers actually do?** Move further out? Scout? Report resources? Need a concrete behavior to implement.
3. **Defend ratio / search ratio:** Land claim has `defend_ratio`, `search_ratio` (e.g. 0.2). Are these used for **auto**-assignment when not overridden (e.g. “20% defend, 20% search”), or only for display? If auto, where does that logic run?
4. **Corpse looting:** We exclude dead NPCs from context menu and drag. Looting still uses “nearby corpse” + inventory key. Is that the intended looting flow, or should we add a context menu “Loot” on corpse?
5. **F3 DEFEND debug:** F3 sets DEFEND for NPC under cursor. Keep as dev-only, or document for players? Same for F4 spawn, F2 context menu test.
6. **Hostile toggle persistence:** Is `player_hostile` reset on load / scene change, or should it persist?

### What needs to be done

- [ ] **Phase G (Task system):** Steps 12–18 — Task base, TaskRunner, Job, concrete tasks (MoveTo, PickUp, DropOff, Wait), `generate_job(worker)`, NPC-pull, interrupt wiring. See `Task_system.md`.
- [ ] **SEARCHING:** Define and implement what “assigned to search” NPCs do (scout, report, gather further out, etc.).
- [ ] **Ratio-based assignment:** If `defend_ratio` / `search_ratio` should drive auto-assignment, implement that and hook it to idle WORKING NPCs.
- [ ] **Tests & polish:** Re-run `TEST_STEP1_context_menu.md` and fix any regressions. Consider automated tests for context menu, drag, follow, defend.
- [x] **Docs:** Battle royale readiness doc **removed** (Apr 2026); scrub remaining mentions in `combat_plan.md`, `dev_menu.md`, etc., if any linger.

---

*End of integration plan. Update this doc as steps are completed or de-scoped.*

# NPC Roles, Modes, and Task Framework (Authoritative Guide)

## Core Principles

- NPCs always have exactly ONE of:
  - FOLLOW
  - DEFEND
  - SEARCH
  - WORK (default)

- FOLLOW is mutually exclusive with all village roles.
- WORK / SEARCH / DEFEND always break FOLLOW.
- Player overrides are explicit and sticky.
- Automation fills gaps, never overrides player intent.
- Tasks execute behavior; roles define intent.

---

## Roles

### WORKING (Default)
- Gather known resources
- Herd known animals
- Craft tools & weapons
- Idle only if nothing is possible
- Uses landclaim resource intel
- Does not leave safe area

---

### SEARCHING (like Ant-style)
Purpose: Discover resources and herds.
moving while scanning for resources/herd

Loop:
1. Pick outward direction
2. Move to fixed search waypoint area - avoid combat - scanning for resources (if found go to step 4)
3. Scan AOP - avoid combat
4. If resource/herd found:
    - consider combat for resources
   - Gather what can be carried
   - Return to landclaim (avoiding combat)
5. If nothing found:
6. Repeat step 1
7. return home after 5 unsuccessful attempts

---

### DEFENDING
Purpose: Protect landclaim.

- Patrol area of border
- Engage intruders immediately
- Return to patrol after combat
- Never leave landclaim

---

### FOLLOW
Purpose: Player-led actions.

- Stay near player
- No work or village roles
- Can become HOSTILE or set to Hostile by player
- Ends only via Break Follow or death

---

## Modes

### HOSTILE
- Aggressive intent
- Used for raids and hunts
- Followers auto-attack enemies in AOP
- Does not exist with WORK / SEARCH / DEFEND

---

## Player Interaction

### Context Menu (Right-click)
- FOLLOW
- DEFEND
- SEARCH
- WORK (clears role + breaks follow) 
- INFO

### Drag & Drop
- Drag NPC → Player: Follow
- Drag NPC → inside LandClaim: Defend
- Drag NPC → outside LandClaim: Search

### HUD
- Hostile toggle
- Break Follow

---

## Automation

- Default ratios (e.g. 20% DEFEND, 20% SEARCH)
- Applied only to unassigned NPCs
- LandClaim manages auto-assignment

---

## Tasks & Jobs (Phase G)

- NPCs pull jobs based on role
- Buildings generate jobs, never assign
- Role/mode change cancels current task
- Tasks are atomic and dumb

---

## Aggro

- Only clansmen have aggro
- Aggro fills faster in LandClaim Area
- When aggro drops below threshold:
  - Combat target cleared
  - NPC returns to previous role
- Women never gain aggro

---

## Design Mantra

"Roles define intent.
Modes define aggression.
Tasks do the work."

---

## Implementation status (guide)

**Implemented and tested:**
- **Work clears role + breaks follow:** `_clear_role_assignment` now also clears follow (herder, `follow_is_ordered`, etc.) for that NPC.
- **Drag → Player:** Follow. **Drag → inside LandClaim:** Defend **that specific claim** (`_get_player_land_claim_at_position`, `_set_defend(npc, claim)`). **Drag → outside LandClaim:** Search (`_resolve_npc_drop_target` returns `outside_land_claim`; `_set_searching` when player has ≥1 claim).
- **Search state:** `search_state.gd` — ant-style loop: outbound waypoints (radius × 2 from home), 5 attempts, return home, then wander (can re-enter search). `search_home_claim` set in `_set_searching`; FSM registers `search`, priority 5.5.
- **NPC** `search_home_claim` added; cleared on Work, Defend, or role clear.

**Tests:** See `TEST_STEP1_context_menu.md` (Step 10 drag, Step 11 roles, Drag → outside = Search).
