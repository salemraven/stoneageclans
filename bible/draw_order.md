# Draw Order — Locked Spec (Y-Sort on a Flat Plane)

**Source of truth:** `scripts/systems/y_sort_utils.gd` (Autoload **YSortUtils**).  
**Art alignment:** `assets/sprites/art_sprite.md`.  
**Last locked:** October 2026 (plane Y-sort + **timer overlay band** above sprites, below CanvasLayer UI).

---

## Philosophy: 3/4 top-down on one flat plane

Stone Age Clans is drawn as **¾ top-down** on a **single horizontal ground plane**. There is no real camera height, no separate “layer” for roofs, and **no per-pixel depth** inside one sprite.

| What the player sees | What the engine does |
|----------------------|----------------------|
| Walking “up” on screen (toward the top edge) | Moving **north** → **lower world Y** |
| Walking “down” on screen (toward the bottom edge) | Moving **south** → **higher world Y** |
| Something **south** of you on screen | **In front** (drawn later, higher `z_index`) |
| Something **north** of you on screen | **Behind** (drawn earlier, lower `z_index`) |
| Tall art (trees, huts, pawn cards) | **One** sort line per object; the whole sprite uses that depth |

**Design intent**

- Depth is **fake but consistent**: one **sort Y** (world pixels) per drawable decides order vs every other object on the plane.
- **Ambush / tuck:** move **north** of a trunk or building midpoint to draw **behind** it; approach from the **south** to draw **in front** of the base.
- **Tall objects are not split** (no separate trunk vs canopy `z_index`). Canopy and trunk share one line — tune **where** that line sits, not `Z_ABOVE_WORLD` hacks.

**Do not**

- Put **gameplay sprites** (bodies, trees, huts) at `Z_ABOVE_WORLD` (4095) — that breaks the plane.
- Y-sort **progress timers** with pawn feet — use **`update_world_timer_draw_order`** (fixed overlay band).
- Add **large** positive `tree_sort_offset_y` (old ~240 values) — player never gets **in front** of the trunk from the south.
- Sort buildings at the **ground footprint only** with huge negative offsets (old ~-220) — wrong flip vs midpoint art.
- Use one `z_index` for an entire **grass MultiMesh** chunk (use **16 px foot buckets** in `grass_batch.gd`).
- Set raw `z_index` on world sprites outside **YSortUtils** (overflow + z-fighting).

---

## Screen ↔ world (memorize this)

```
        NORTH  (lower Y, “up” on screen)
              ↑
              │
    behind    │    behind
              │
  ←───────────┼───────────→  EAST / WEST (X)
              │
   in front   │   in front
              │
              ↓
        SOUTH  (higher Y, “down” on screen)
```

**Comparison rule:** for two objects A and B, if `sort_y(A) > sort_y(B)` then **A draws in front of B**.

**Pawns (player/NPC cards):** `sort_y = global_position.y + _card_foot_y` (foot anchor, not walk bounce on `sprite.position.y`).

---

## Engine setup (`Main.tscn`)

```
Main
├── WorldLayer                 ← floor TileMap; never competes with entities
│   └── World
├── WorldObjects               ← y_sort_enabled = true (sibling hint only)
│   ├── Player
│   ├── LandClaims → buildings parented here at runtime
│   ├── NPCs, gatherables, ground items, …
└── UI (CanvasLayer)           ← real HUD; not Y-sorted with world
```

**Why manual `z_index` + `z_as_relative = false`?**  
`y_sort_enabled` only sorts **siblings**. Buildings under land claims and the player under `WorldObjects` are **different branches**. Global `z_index` from **sort Y** unifies depth.

**Formula (Y-sorted plane sprites only):**

```gdscript
sprite.z_index = world_sort_z_from_y(sort_y)
# clamp(Z_BASE + int(sort_y), 0, Z_WORLD_SORT_CAP)  — cap leaves room for overlays
```

### Render stack (bottom → top)

| Layer | What | `z_index` / node |
|-------|------|------------------|
| 1 | Floor / TileMap | `WorldLayer`, low z |
| 2 | **Game plane** — pawns, props, trees, huts, grass | `world_sort_z_from_y` → **≤ `Z_WORLD_SORT_CAP` (3840)** |
| 3 | **World timers** — gather, eat, craft rings, floating hit numbers | **`Z_WORLD_PROGRESS_OVERLAY` (3880)** via `update_world_timer_draw_order` |
| 4 | Optional world HUD (clan name on claim, etc.) | `Z_HUD_WORLD_FLOAT` (3920) or `Z_ABOVE_WORLD` sparingly |
| 5 | **Menus / inventory / info cards** | **`UI` `CanvasLayer`** in `Main.tscn` — always above world branch |

Timers are **viewer-adjacent**: they float over the whole plane so you always read them, but they stay on the **world scene tree** (follow pawn position). **CanvasLayer UI** draws after the world, so menus still win.

**Pawn combat/rout chevrons** still use `update_overlay_draw_order` (Y-sort with body) — not the timer band.

---

## Sort line per entity type (LOCKED)

Each type picks **one world Y** for its main sprite. That is the “flip line” vs pawn feet.

| Type | Sort line (world Y) | Flip vs pawn foot |
|------|---------------------|-------------------|
| **Pawn** (player/NPC card) | `node.y + _card_foot_y` | Reference (~`-28` for 56px display height) |
| **Flat prop** (boulder, bush, pile) | `node.y + sprite.position.y` (foot at bottom of art) | Standard foot compare |
| **Tree (WOOD)** | `node.y + tree_foot_offset_y + tree_sort_offset_y` | South of line → in front; north → behind trunk |
| **Building / claim / campfire** | Vertical **midpoint** of building sprite + `building_sort_offset_y` | South of midpoint → in front; north → behind hut |
| **Tall grass** | Per-blade foot Y (bucketed 16px in `grass_batch.gd`) | Same as flat prop |
| **World timer / ring** | Fixed **`Z_WORLD_PROGRESS_OVERLAY`** | Always above plane sprites; **not** behind huts/trees |

### Trees (`update_tree_draw_order`)

- **Node** = gather point at trunk on the plane.
- **Art:** `get_tree_sprite_position_for_cell_height` — bottom of scaled region at `node.y + tree_foot_offset_y`.
- **Sort:** `get_tree_trunk_sort_y()` — **not** canopy top, **not** sprite center.
- **Tuning (Inspector → YSortUtils):**
  - `tree_foot_offset_y` default **`-24`** — art vs ground.
  - `tree_sort_offset_y` default **`-20`** — negative = must walk **farther north** before hiding; small band only (±20), **never ~240**.

### Buildings (`update_building_draw_order`)

- **Art:** bottom on ground via `get_building_sprite_position_for_texture` × `BUILDING_SCALE` (2.0).
- **Sort:** **halfway up** the scaled sprite (`get_building_midpoint_sort_y`) — flip at mid-height, not at foundation only.
- **Tuning:** `building_sort_offset_y` default **`0`** (nudge midpoint line; negative = flip behind farther north).

### Pawns (`update_card_draw_order`)

- Sort uses **`_card_foot_y`** from `PlaceholderCardService` / registry — stable foot, not procedural bounce.
- Refresh every **`_physics_process`** while moving.

### World progress rings (`update_world_timer_draw_order`)

- **Fixed `z_index = Z_WORLD_PROGRESS_OVERLAY` (3880)** — above all Y-sorted sprites (cap 3840).
- Child of pawn / gatherable / ground item — **position** still tracks world (above head / resource).
- **Does not** tuck behind huts when the pawn does; that is intentional (readable feedback layer).
- **Below** inventory, build menus, and other **`UI` CanvasLayer** controls.
- Use for: `CollectionProgress` (gather, eat, hut craft), eat bar on player, floating hitmarkers on NPCs.

### Plane-tied pawn indicators (`update_overlay_draw_order`)

- Rout / hostile markers — still **Y-sort** with `_card_foot_y` + small **`OVERLAY_Z_BIAS`**.

---

## API quick reference

| Function | Use |
|----------|-----|
| `update_card_draw_order(sprite, parent, card_anchor_foot_y)` | Player, NPC card bodies |
| `update_draw_order` / `update_object_y_sort` | Flat sprites, grass decor nodes |
| `update_tree_draw_order(sprite, parent, texture)` | WOOD gatherables |
| `update_building_draw_order(sprite, parent)` | Huts, land claim, campfire |
| `update_world_timer_draw_order(overlay)` | **All progress rings / timed feedback** (fixed overlay band) |
| `update_overlay_draw_order(overlay, owner, local_y, body_sort_local_y?)` | Rout / hostile (plane depth) |
| `world_sort_z_from_y(sort_y)` | Clamp plane sprites to `Z_WORLD_SORT_CAP` |
| `get_tree_trunk_sort_y(parent)` | Trunk line (world Y) |
| `get_building_midpoint_sort_y(sprite, parent)` | Hut midline (world Y) |

**Position helpers (set before sort):**  
`get_sprite_position_for_texture`, `get_building_sprite_position_for_texture`, `get_tree_sprite_position_for_*`, `get_grass_sprite_position_for_texture`.

---

## Where it runs (code map)

| Entity | When | Function | File |
|--------|------|----------|------|
| Player | `_physics_process` | `update_card_draw_order` | `player.gd` |
| NPC | `_physics_process` | `update_card_draw_order` | `npc_base.gd` |
| Building | `_process` + art change | `update_building_draw_order` | `building_base.gd` |
| Land claim | `_ready` | `update_building_draw_order` | `land_claim.gd` |
| Campfire | `_ready` | `update_building_draw_order` | `campfire.gd` |
| Tree WOOD | `_setup_tree_from_sheet` | `update_tree_draw_order` | `gatherable_resource.gd` |
| Other gatherables | `_ready` | `update_object_y_sort` | `gatherable_resource.gd` |
| Ground item | `_ready` | `update_draw_order` | `ground_item.gd` |
| Tall grass | spawn | foot buckets + per-bucket `z_index` | `grass_batch.gd` |
| Pawn timers | visible + each frame | `update_world_timer_draw_order` | `npc_base.gd`, `placeholder_card_service.gd`, `player.gd` |
| Gather timer | visible + `_process` | `update_world_timer_draw_order` | `gatherable_resource.gd`, `ground_item.gd` |

### Lines & HUD (exceptions)

| Item | `z_index` | Notes |
|------|-----------|--------|
| Follow / party / herd lines | `Z_BEHIND_ENTITIES` (0) | Under pawn feet |
| Clan name on claim (world label) | `Z_ABOVE_WORLD` | HUD-style readability |
| Building health bar (UI control) | `Z_ABOVE_WORLD` | Not plane-sorted |
| Thrown projectile (legacy) | `Z_ABOVE_WORLD` | Review if moved to world sort |

---

## Inspector defaults (lock these unless playtesting)

| Export | Default | Meaning |
|--------|---------|---------|
| `tree_foot_offset_y` | `-24` | Trunk bottom vs gather node |
| `tree_sort_offset_y` | `-20` | Northward hide delay (small!) |
| `building_sort_offset_y` | `0` | Midpoint nudge |
| `world_prop_scale` | `1.15` | Trees, grass, small props (not buildings/pawns) |

If playtest feels wrong, **tweak exports in YSortUtils** — do not add new magic numbers in entity scripts.

---

## Adding a new world object (checklist)

1. Parent under **WorldObjects** (or descendant), not UI layer.
2. Place **node on the ground plane** (feet / trunk / building anchor).
3. Set `sprite.position` with the correct **helper** for art size.
4. Call the correct **`update_*_draw_order`** once (static) or every frame (moving).
5. Child **progress timer** → `update_world_timer_draw_order` (not plane Y-sort).
6. Playtest: pass **north and south** of tree trunk and **building midpoint**.
7. No raw `z_index` on the sprite.

---

## Player crouch (tall grass)

- **`C`** toggles crouch (input action `crouch`). Slower movement, low body/head pose on card mannequins.
- **Hide** when crouching **inside** registered tall-grass blades (`TallGrassCover`, filled by `grass_batch.gd`): sets `is_hidden` + `hide_has_cover`, softer alpha, quieter footsteps (no footstep sounds while hidden).
- Crouch blocked while weapon-ready (Shift), gathering, or in combat windup.

---

## Playtest checklist

- [ ] South of tree trunk → **in front**; north → **behind** (ambush).
- [ ] South of hut **midpoint** → **in front**; north → **behind**.
- [ ] Craft/gather/eat ring **visible over** huts/trees/pawns (timer band), menus still on top.
- [ ] Grass / bushes **not** drawn over tree tops unless their foot Y is south of tree sort line.
- [ ] Floor never covers pawns moving north.
- [ ] No `p_z > CANVAS_ITEM_Z_MAX` errors.

---

## Performance

- `z_index` update is cheap; only **moving** pawns/buildings need per-frame refresh.
- Static props: sort in `_ready` / when texture changes.

---

## Archive

`bible/archives/draw_order_y_sorting_plan.md` — historical; **this file wins** on conflict.

---

## One-line hook

> **¾ top-down flat plane: higher screen Y = in front; one sort line per thing; YSortUtils only; feet (or trunk / hut mid) set the depth.**
