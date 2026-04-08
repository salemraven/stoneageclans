# Draw Order (Y-Sorting) – Complete Guide

**Last updated:** April 2026 — matches `scripts/systems/y_sort_utils.gd`.

## TL;DR

- **WorldObjects** uses **`y_sort_enabled = true`** so siblings sort by node Y.
- **Every sortable sprite** also gets **manual `z_index`** from **`YSortUtils`**, with **`z_as_relative = false`**, so depth stays correct **across different parent branches** (player vs building vs resource).
- **WorldLayer** (floor TileMap) is a **separate** branch so the ground never draws on top of entities.

> **Rule:** The lower something is on the screen (**higher Y**), the more “in front” it renders.

> **Hook:** **Always sort by the feet, not the node origin** — use `YSortUtils`; don’t invent new `z_index` formulas.

---

## Goals

- Objects lower on screen (higher Y) appear in front; higher on screen (lower Y) appear behind.
- Works for: Player, NPCs, Buildings, Land claims, Campfires, Trees, Resources, Grass/decor, Ground items.
- Natural depth when walking behind / in front of tall objects.
- Floor never covers entities when moving north.
- UI stays above the world (`CanvasLayer`).

---

## Scene structure (`Main.tscn`)

```
Main
├── WorldLayer              ← draws first (floor always behind)
│   └── World (TileMap)
├── WorldObjects            ← y_sort_enabled = true (sibling Y sort)
│   ├── Player
│   ├── Resources           ← container / grouping as needed
│   ├── LandClaims          ← buildings parented under claims at runtime
│   └── … NPCs, ground items, grass nodes, etc. added at runtime
└── UI (CanvasLayer)
```

**Why both YSort and manual z?**  
`y_sort_enabled` only affects **siblings under WorldObjects**. Buildings live under land claims; the player is a direct child. **`z_as_relative = false`** + **`z_index` from foot Y** makes all those sprites participate in one global depth ordering.

---

## Rules (keep draw order consistent)

1. **Use `YSortUtils` only** for world sprites — `update_draw_order`, `update_building_draw_order`, or `update_tree_draw_order` (or aliases below).
2. **Sort by visual foot:** `parent.global_position.y + sprite.position.y` (buildings/trees add their documented offsets).
3. **Set sprite offset first** where helpers exist (`get_sprite_position_for_texture`, `get_building_sprite_position_for_texture`, `get_tree_sprite_position_for_*`, `get_grass_sprite_position_for_texture`) so “feet” match art.
4. **Moving entities:** update draw order **every `_physics_process`** (or whenever `global_position` changes).
5. **Static entities:** update in **`_ready()`** and again if the node **moves** or **sprite/texture changes** (see `building_base.gd`).
6. **Overlays** (bars, indicators, hitmarkers): **`z_index = YSortUtils.Z_ABOVE_WORLD`**, **`z_as_relative = false`**.
7. **Lines behind characters** (follow line, party line): **`YSortUtils.Z_BEHIND_ENTITIES`**.
8. **Never** set raw `z_index` on world sprites for “sorting” except via YSortUtils (avoids z-fighting and overflow).

---

## API reference (`YSortUtils` autoload)

### Sorting functions

| Function | Use when |
|----------|----------|
| `update_draw_order(sprite, parent_node)` | Default: player, NPCs, boulders, berries, most flat sprites. |
| `update_object_y_sort(sprite, parent)` | **Alias** of `update_draw_order` — NPCs use this name in code. |
| `update_building_draw_order(sprite, parent)` | Land claims, `building_base`, **campfire** — applies `building_sort_offset_y`. |
| `update_tree_draw_order(sprite, parent, texture)` | **Wood trees** in `gatherable_resource.gd` — trunk-base math + `tree_sort_offset_y`. |
| `update_decal_y_sort` / `update_effect_y_sort` | Aliases of `update_draw_order`. |

All set **`sprite.z_as_relative = false`** and **`z_index = clampi(Z_BASE + int(sort_y * Y_SORT_SCALE), 0, CANVAS_Z_MAX - 1)`**.

### Sprite position helpers (feet alignment)

| Function | Purpose |
|----------|---------|
| `get_sprite_position_for_texture(texture)` | Character-sized sprites: 64×64 base offset; +extra for **height ≥ 128**. |
| `get_building_sprite_position_for_texture(texture)` | Building anchor: 64×64 vs 128×128 bottom alignment; multiplied by **`BUILDING_SCALE`** (2.0). |
| `get_tree_sprite_position_for_texture(texture, scale_y)` | Tree centering so trunk base sits on node. |
| `get_tree_sprite_position_for_cell_height(cell_height, scale_y)` | Trees from tile cell height (region sprites). |
| `get_grass_sprite_position_for_texture(texture)` | Decor / tall grass: bottom of sprite at node (`-h/2`). |

---

## The core formula (flat sprites)

Sort by the **sprite’s visual foot**, not the parent’s origin alone:

```gdscript
foot_y = parent_node.global_position.y + sprite.position.y
sprite.z_index = clampi(Z_BASE + int(foot_y * Y_SORT_SCALE), CANVAS_Z_MIN, CANVAS_Z_MAX - 1)
```

**Buildings:** same, plus `building_sort_offset_y` (see `update_building_draw_order`).  
**Trees:** sort by **trunk base** (sprite center minus half visual height) plus `tree_sort_offset_y` — see `update_tree_draw_order` in `y_sort_utils.gd`.

---

## Where it’s applied (code map)

| Entity | When | Function | File(s) |
|--------|------|----------|---------|
| Player | `_physics_process` | `update_draw_order` | `player.gd` |
| NPCs | `_physics_process` | `update_object_y_sort` | `npc_base.gd` |
| Buildings | `_ready` + sprite updates | `update_building_draw_order` | `building_base.gd` |
| Land claim | `_ready` | `update_building_draw_order` | `land_claim.gd` |
| Campfire | `_ready` | `update_building_draw_order` | `campfire.gd` |
| Gatherable (tree WOOD) | `_ready` | `update_tree_draw_order` | `gatherable_resource.gd` |
| Gatherable (other) | `_ready` | `update_object_y_sort` | `gatherable_resource.gd` |
| Ground item | `_ready` | `update_draw_order` | `ground_item.gd` |
| Grass / decor (main) | spawn | `get_grass_sprite_position_for_texture` + `update_draw_order` | `main.gd` |
| Character (legacy) | `_physics_process` | `update_draw_order` | `character.gd` |

### Overlays using `Z_ABOVE_WORLD` / `Z_BEHIND_ENTITIES`

- `npc_base.gd` — progress ring, hostile indicator; follow line → `Z_BEHIND_ENTITIES`.
- `player.gd` — eat progress → `Z_ABOVE_WORLD`; herd line → `Z_BEHIND_ENTITIES`.
- `ground_item.gd` / `gatherable_resource.gd` — collection progress → `Z_ABOVE_WORLD`.
- `health_component.gd` — hitmarker → `Z_ABOVE_WORLD`.
- `main.gd` — some world UI markers → `Z_ABOVE_WORLD`.

---

## Constants (`y_sort_utils.gd`)

Godot **4.5** limits `z_index` to **0..4095** (12-bit). Values outside cause `p_z > CANVAS_ITEM_Z_MAX` errors — **always use `clampi`**.

| Constant | Value | Role |
|----------|-------|------|
| `Z_BASE` | 2048 | Center of Y-sort range |
| `Y_SORT_SCALE` | 1 | Multiply foot Y before converting to z |
| `CANVAS_Z_MIN` / `CANVAS_Z_MAX` | 0 / 4095 | Clamp range |
| `Z_ABOVE_WORLD` | 4095 | Progress bars, indicators (max) |
| `Z_BEHIND_ENTITIES` | 0 | Follow / leader lines under characters |
| `BUILDING_SCALE` | 2.0 | Global building visual scale (affects building sprite Y offset) |

---

## Editable exports (Inspector: Autoload → YSortUtils)

| Variable | Default (code) | Effect |
|----------|------------------|--------|
| `building_sort_offset_y` | `-220` | More **negative** → player stays **in front** of buildings longer when moving north; positive → slips behind sooner |
| `tree_foot_offset_y` | `-24` | Intended for tree sprite foot tweak (see `assets/sprites/art_sprite.md`); **export exists** — wire into tree placement if you need runtime tuning |
| `tree_sort_offset_y` | **`240`** | More **positive** → tree draws **in front** over a wider band → easier to hide behind trunk |

*If your doc or older notes say `80` for `tree_sort_offset_y`, trust **`y_sort_utils.gd`** as source of truth.*

---

## Godot details

### `z_index` only sorts siblings

Without `z_as_relative = false`, nested sprites wouldn’t sort correctly against the player. **YSortUtils always sets `z_as_relative = false`** on sorted sprites.

### Why not *only* YSort on the root?

Nested hierarchies (buildings under claims) and mixed branches need **global z** from foot Y. **YSort on WorldObjects** still helps sibling ordering; **manual z** unifies depth across the tree.

---

## Edge cases

| Case | Handling |
|------|----------|
| Same Y | Scene tree order tie-break; usually acceptable |
| Very north/south | `clampi` prevents z overflow |
| Region-enabled tree sprites | `update_tree_draw_order` uses `region_rect.size.y` for height |
| Moving vs static | Moving: every physics frame; static: `_ready` + when position/sprite changes |
| New 128×128 art | Use `get_*_for_texture` helpers so feet stay aligned |

---

## New entity checklist

When adding a **new visible world object**:

- [ ] Parent under **WorldObjects** (or a node that’s under it), unless it’s purely UI.
- [ ] Set **sprite.position** with the right helper if size is 64 vs 128.
- [ ] Call **`YSortUtils.update_draw_order`** or **building** / **tree** variant in `_ready`.
- [ ] If it **moves**, refresh draw order **every frame** (or on position change).
- [ ] Any child UI (bar, icon) → **`Z_ABOVE_WORLD`** + `z_as_relative = false`.
- [ ] Lines that should sit under feet → **`Z_BEHIND_ENTITIES`**.
- [ ] Playtest: pass **north and south** of buildings and trees.

---

## Testing checklist

- [ ] Player **behind** buildings when **north** of them (higher on screen)
- [ ] Player **in front** when **south** of them
- [ ] NPCs vs player vs buildings — no systematic wrong layering
- [ ] Resources, ground items, grass — sensible depth
- [ ] **Floor never** covers player/NPCs moving north
- [ ] Progress bars, indicators, hitmarkers **above** sprites
- [ ] Follow / party lines **behind** characters where intended
- [ ] No z spam errors in console; no visible z-fighting

---

## Performance

- Setting `z_index` is cheap (one int per update).
- Per-frame updates only for **moving** entities.
- Static objects: once in `_ready()`, plus rare updates when art or position changes.

---

## Archive

Older planning notes: `guides/archives/draw_order_y_sorting_plan.md`.

---

## One-sentence memory hook

> **“Feet set the depth; YSortUtils sets the z; floor lives on its own layer.”**
