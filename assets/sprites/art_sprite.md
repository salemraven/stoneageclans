# Stone Age Clans – Sprite Art & Draw Order Reference

## Style Guidelines (All Sprites)

- **Look:** Gritty, hand-drawn, Paleolithic/RimWorld feel. Muted earthy tones (browns, greys, ochres, dull greens). No bright colors or cartoon style.
- **View:** Top-down isometric.
- **Icons:** Quality borders (2px overlay: grey / white / blue / light-blue / purple / purple-glow) where applicable.

---

## Sprite Sizes & Display (Current System)

### Characters (Player, NPCs)

| Texture size | Display size | Scale | sprite.position (Y) | Sort "foot" |
|--------------|--------------|-------|---------------------|-------------|
| 64×64        | 64×64 px     | 1.0   | -6                  | entity.y + (-6) |
| 128×128      | 64×64 px     | 0.5   | -6 (or +18 for 128px path) | entity.y + sprite.position.y |

- **64×64:** `scale = Vector2.ONE`, `position = (0, -6)`. Sort line ~6 px above entity root (at feet).
- **128×128:** `scale = Vector2(0.5, 0.5)`, position from `YSortUtils.get_sprite_position_for_texture(texture)` (64: -6, 128: -6+24). Sort line at feet.
- **Walk animation:** `walkcmss.png` (128 px), scale 0.5 → 64 px; atlas regions. Foot/sort set by character's `apply_sprite_offset_for_texture` / player setup.

### Buildings & Land Claim

| Texture size | Display size | sprite.scale | sprite.position |
|--------------|--------------|--------------|-----------------|
| 64×64        | 64×64 px     | 1.0          | (0, 0)          |
| 128×128      | 128×128 px   | 1.0          | (0, 0)          |

- Native display: scale = Vector2.ONE, position = Vector2.ZERO.
- Entity root = center; sprite centered on node.

### Gatherable Resources (trees, boulders, bush, wheat, fiber)

- **Trees (WOOD):** `position` from `YSortUtils.get_tree_sprite_position_for_texture(texture)` – very little foot, base near ground. Editable via `tree_foot_offset_y` (-24 default).
- **Other resources:** `position = Vector2.ZERO` (centered).
- **Sort:** `foot_y = entity.global_position.y + sprite.position.y`.

### Ground Items (stone, wood pickups)

- Same as gatherables: scale 1, position (0,0), centered. Sort by entity center.

### Tall Grass

- Full texture size, centered on grass Node2D. Uses `YSortUtils.update_draw_order` + `get_grass_sprite_position_for_texture` so grass Y-sorts with other entities (can appear in front when south of player).

---

## Draw Order ("Foot" for Y-Sort)

- **Formula:** `foot_y = parent_node.global_position.y + sprite.position.y`
- **Rule:** Lower `foot_y` → drawn first (behind). Higher `foot_y` → drawn later (in front).
- Characters: offsets so sort line is at feet. Buildings: so sort line is at ground. Resources/ground items: center.

---

## Art File Conventions (For New Assets)

- **Pawns / characters:** 64×64 standard; 128×128 if scaled down to 64 px in code (e.g. PlayerB, walk sheet).
- **Buildings:** 64×64 or 128×128; bottom of sprite = ground line.
- **Gatherables / ground items:** 64×64 typical; centered, any size supported.
- **Tall grass / decor:** Any size; centered; uses `update_draw_order` to Y-sort with entities.
- **Icons (inventory, etc.):** 32×32 with quality border overlay where needed.
