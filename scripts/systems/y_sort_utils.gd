extends Node
# Manual z_index based on sprite Y position. No YSort nodes.
# Rule: Lower on screen (higher Y) = more "in front".
# Sort by the sprite's visual foot: global_position.y + sprite.position.y
#
# Usage: YSortUtils.update_draw_order(sprite, self)
# See guides/draw_order.md (plan archived at guides/archives/draw_order_y_sorting_plan.md)

# --- EDITABLE: Tweak in Inspector (Project > Project Settings > Autoload > YSortUtils) or here ---
@export var building_sort_offset_y: float = -220.0  # Buildings: more negative = player stays in front longer as they move north
@export var tree_foot_offset_y: float = -24.0  # Trees: more negative = less visible foot/stump (64px: -24 = 8px below node)
@export var tree_sort_offset_y: float = 240.0  # Trees: positive = tree draws in front for larger zone = player hides behind trunk when closer

# z_index only sorts SIBLINGS in Godot. z_as_relative=false lets sprites sort across branches.
# Godot 4.5 limits z_index to 0..4095 (12-bit); values outside cause "p_z > CANVAS_ITEM_Z_MAX" errors.
const CANVAS_Z_MIN: int = 0
const CANVAS_Z_MAX: int = 4095
const Z_BASE: int = 2048  # Center of Y-sort range
const Y_SORT_SCALE: int = 1  # foot_y maps to z; scale 1 keeps typical Y (-2000..2000) in range
const Z_BEHIND_ENTITIES: int = 0  # Follow/leader lines - draw behind player and NPCs
const Z_ABOVE_WORLD: int = 4095  # Progress bars, lines, indicators - max, draws on top

# 128x128 sprites: move draw lower so feet align with 64x64
const SPRITE_BASE_OFFSET_Y_64: float = -6.0
const SPRITE_128_EXTRA_OFFSET_Y: float = 24.0

## Returns sprite position (0, y) so feet align: 64x64 = -6, 128x128 = -6+24
func get_sprite_position_for_texture(texture: Texture2D) -> Vector2:
	var y: float = SPRITE_BASE_OFFSET_Y_64
	if texture and texture.get_height() >= 128:
		y += SPRITE_128_EXTRA_OFFSET_Y
	return Vector2(0, y)

# Buildings (hut, etc.): 64x64 = center -32 (bottom at 0), 128x128 = center -64 (bottom at 0)
const BUILDING_BASE_OFFSET_Y_64: float = -32.0
const BUILDING_128_EXTRA_OFFSET_Y: float = -32.0

# Global scale for all buildings and land claim (2.0 = double size)
const BUILDING_SCALE: float = 2.0

## Returns building sprite position (0, y): 64x64 = -32, 128x128 = -64 so ground line matches. Scaled by BUILDING_SCALE.
func get_building_sprite_position_for_texture(texture: Texture2D) -> Vector2:
	var y: float = BUILDING_BASE_OFFSET_Y_64
	if texture and texture.get_height() >= 128:
		y += BUILDING_128_EXTRA_OFFSET_Y
	return Vector2(0, y * BUILDING_SCALE)

## Returns tree sprite position (0, y) so bottom of trunk is at node. Pass scale_y used on sprite.
func get_tree_sprite_position_for_texture(texture: Texture2D, scale_y: float = 1.0) -> Vector2:
	var h: float = texture.get_height() if texture else 64.0
	return get_tree_sprite_position_for_cell_height(h, scale_y)

## Returns tree sprite position for a cell height. With centered=true, y = half_visual_height so trunk base is at node.
func get_tree_sprite_position_for_cell_height(cell_height: float, scale_y: float = 1.0) -> Vector2:
	var half_visual: float = (cell_height * scale_y) / 2.0
	return Vector2(0, half_visual)

## Returns grass/decor sprite position (0, y): foot at node so draw order is correct.
## 64px: -32 (bottom at node); 128px: -64.
func get_grass_sprite_position_for_texture(texture: Texture2D) -> Vector2:
	if not texture:
		return Vector2(0, -32.0)  # Default 64px
	var h: float = texture.get_height()
	return Vector2(0, -h / 2.0)  # Center at node - half height = bottom at node

## Update draw order. Sort by feet. Same formula for all (grass is on CanvasLayer -1).
## z_as_relative=false so sprites in different branches (player vs building) sort together.
func update_draw_order(sprite: Sprite2D, parent_node: Node2D) -> void:
	if not sprite or not parent_node:
		return
	sprite.z_as_relative = false  # Cross-branch sorting (player under WorldObjects, buildings under LandClaims)
	var foot_y: float = parent_node.global_position.y + sprite.position.y
	sprite.z_index = clampi(Z_BASE + int(foot_y * Y_SORT_SCALE), CANVAS_Z_MIN, CANVAS_Z_MAX - 1)

## Tree-specific: sort by visual trunk base (bottom of sprite) so player can hide behind trunks.
## tree_sort_offset_y (positive) adds to trunk base = tree draws in front for larger zone = maximize hiding.
## With centered sprite: trunk_base = center - half_height. Higher Y = draws in front.
func update_tree_draw_order(sprite: Sprite2D, parent_node: Node2D, texture: Texture2D) -> void:
	if not sprite or not parent_node:
		return
	sprite.z_as_relative = false
	var tex_h: float
	if sprite.region_enabled:
		tex_h = sprite.region_rect.size.y
	else:
		tex_h = texture.get_height() if texture else 64.0
	var scale_y: float = sprite.scale.y if sprite.scale.y > 0 else 1.0
	var half_visual_height: float = (tex_h * scale_y) / 2.0
	var trunk_base_y: float = parent_node.global_position.y + sprite.position.y - half_visual_height + tree_sort_offset_y
	sprite.z_index = clampi(Z_BASE + int(trunk_base_y * Y_SORT_SCALE), CANVAS_Z_MIN, CANVAS_Z_MAX - 1)

## Buildings: offset adjusts when player goes behind. Uses building_sort_offset_y (editable).
func update_building_draw_order(sprite: Sprite2D, parent_node: Node2D) -> void:
	if not sprite or not parent_node:
		return
	sprite.z_as_relative = false
	var foot_y: float = parent_node.global_position.y + sprite.position.y + building_sort_offset_y
	sprite.z_index = clampi(Z_BASE + int(foot_y * Y_SORT_SCALE), CANVAS_Z_MIN, CANVAS_Z_MAX - 1)

# Aliases
func update_object_y_sort(sprite: Sprite2D, parent_node: Node2D) -> void:
	update_draw_order(sprite, parent_node)

func update_decal_y_sort(sprite: Sprite2D, parent_node: Node2D) -> void:
	update_draw_order(sprite, parent_node)

func update_effect_y_sort(sprite: Sprite2D, parent_node: Node2D) -> void:
	update_draw_order(sprite, parent_node)
