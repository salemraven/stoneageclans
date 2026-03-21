# Draw Order (Y-Sorting) – Complete Guide

## TL;DR

We **did NOT use YSort nodes**. We use **manual `z_index`** based on sprite Y position, plus **WorldObjects y_sort_enabled** and a **WorldLayer** for the floor.

> **Rule:** The lower something is on the screen (higher Y), the more "in front" it renders.

---

## Goal

- Objects lower on screen (higher Y) appear in front
- Objects higher on screen (lower Y) appear behind
- Works for: Player, NPCs, Buildings, Trees, Resources, Grass
- Natural depth when walking behind/in front of objects
- Floor never covers entities (even when moving north)

---

## Scene Structure (Main.tscn)

```
Main
├── WorldLayer          ← draws first (floor always behind)
│   └── World (TileMap)
├── WorldObjects        ← y_sort_enabled=true, entities sort by Y
│   ├── Player
│   ├── Resources
│   ├── LandClaims
│   └── (+ buildings, NPCs, ground items added at runtime)
└── UI (CanvasLayer)
```

**Key:** WorldLayer is separate so the floor never draws on top of entities. WorldObjects has `y_sort_enabled` for correct north/south ordering.

---

## The Formula

Sort by the **sprite's visual foot**, not the node origin.

```gdscript
foot_y = global_position.y + sprite.position.y
sprite.z_index = Z_BASE + int(foot_y * Y_SORT_SCALE)
```

- `global_position.y` → entity position
- `sprite.position.y` → sprite offset (most sprites sit *above* their origin)

Use `YSortUtils.update_draw_order(sprite, self)` – do not calculate manually.

---

## Where We Applied It

### Moving entities (Player, NPCs)

Every physics frame:

```gdscript
func _physics_process(_delta):
    if sprite:
        YSortUtils.update_draw_order(sprite, self)
```

**Files:** `player.gd`, `npc_base.gd`

### Buildings and land claims

Once in `_ready()` – use `update_building_draw_order` (adds tunable offset):

```gdscript
func _ready():
    if sprite:
        YSortUtils.update_building_draw_order(sprite, self)
```

**Files:** `building_base.gd`, `land_claim.gd`

### Static entities (Resources, ground items)

Once in `_ready()`:

```gdscript
func _ready():
    if sprite:
        YSortUtils.update_draw_order(sprite, self)
```

**Files:** `gatherable_resource.gd`, `ground_item.gd`

### Future: Trees, grass

- **Trees:** Same pattern as buildings (use `update_building_draw_order` if tall, else `update_draw_order`)
- **Grass:** If TileMap, already sorted; if sprites, use `update_draw_order` or put on `CanvasLayer` layer=-1 to draw behind

---

## Z-Index Constants (y_sort_utils.gd)

Godot 4.5 limits `z_index` to 0..4095 (12-bit). Values outside this range cause `p_z > CANVAS_ITEM_Z_MAX` errors.

```gdscript
const Z_BASE = 2048           # Center of Y-sort range
const Y_SORT_SCALE = 1        # foot_y maps directly to z
const Z_ABOVE_WORLD = 4095    # Progress bars, lines, indicators (max)
```

Floor draws via tree order (WorldLayer first). Overlay elements (progress bars, follow lines, etc.) use `Z_ABOVE_WORLD` with `z_as_relative = false`.

---

## Editable Values

| Variable | Default | Description |
|----------|---------|-------------|
| `building_sort_offset_y` | -220 | Buildings: negative = player stays in front longer; positive = goes behind sooner |
| `tree_foot_offset_y` | -24 | Trees: more negative = less visible foot/stump (64px: -24 = 8px below node) |
| `tree_sort_offset_y` | 80 | Trees: positive = tree draws in front for larger zone = player hides behind more easily |

Edit in `y_sort_utils.gd` or Project Settings > Autoload > YSortUtils.

---

## Godot Details

### z_index limitation

`z_index` only sorts **sibling** nodes. Nodes in different branches use tree order.

**Fix:** Use `z_as_relative = false` on sortable sprites so they sort globally. Put floor on WorldLayer (or `CanvasLayer` layer=-1) so it never covers entities.

### Why manual z_index (not YSort node)

- Full control over sorting
- Handles sprite offsets correctly
- Works with existing scene structure
- Easy to debug
- Buildings need custom offset (`update_building_draw_order`)

---

## Edge Cases

| Case | Handling |
|------|----------|
| Same Y | Godot falls back to scene order; usually fine |
| Negative Y (north) | Z_BASE is high enough; sprites stay above floor |
| Very large Y | `int()` handles it |
| Sprite offsets | Use `sprite.position.y` in formula |
| Moving vs static | Moving: every frame; static: `_ready()` only |

---

## Testing Checklist

- [ ] Player appears behind buildings when north of them (higher on screen)
- [ ] Player appears in front of buildings when south of them (lower on screen)
- [ ] NPCs sort correctly vs player and buildings
- [ ] Resources and ground items sort correctly
- [ ] Floor never covers player/NPCs when moving north
- [ ] Progress bars, follow lines stay visible above sprites
- [ ] No flickering or z-fighting

---

## Performance

- Updating `z_index` is cheap (setting an int)
- Moving objects: update every frame
- Static objects: update once in `_ready()` or when position changes

---

## Implementation Summary

| Step | Status | File |
|------|--------|------|
| YSortUtils helper | ✅ | `scripts/systems/y_sort_utils.gd` |
| Player | ✅ | `player.gd` |
| NPCs | ✅ | `npc_base.gd` |
| Buildings | ✅ | `building_base.gd` |
| Land claims | ✅ | `land_claim.gd` |
| Resources | ✅ | `gatherable_resource.gd` |
| Ground items | ✅ | `ground_item.gd` |
| Trees | ✅ | `main.gd` (decorative), `gatherable_resource.gd` (wood) |
| Grass | ✅ | `main.gd` (tallgrass) |
| Campfire | ✅ | `campfire.gd` |

---

## One-Sentence Memory Hook

> **"Always sort by the feet, not the node."**
