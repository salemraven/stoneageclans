extends Node
# 3/4 top-down flat-plane depth: one world sort-Y per sprite → global z_index.
# LOCKED SPEC: bible/draw_order.md — do not add ad-hoc z_index on world objects.
# Screen south (higher Y) draws in front. Pawns @ foot; trees @ trunk; buildings @ midpoint.

# --- EDITABLE: Tweak in Inspector (Project > Project Settings > Autoload > YSortUtils) or here ---
## Fine-tune (world px) on building midpoint sort line; negative = flip behind only farther north.
@export var building_sort_offset_y: float = 0.0
@export var tree_foot_offset_y: float = -24.0  # Bottom of trunk at parent.y + this; see bible/draw_order.md
## Pixels south of trunk-bottom sort line. Lower/negative = must walk further north before hiding; higher = hide sooner while still south.
@export var tree_sort_offset_y: float = -20.0
## Slight uniform bump for trees, grass, rocks, gatherables, ground piles (not player/buildings).
@export var world_prop_scale: float = 1.15

# z_index only sorts SIBLINGS in Godot. z_as_relative=false lets sprites sort across branches.
# Godot 4.5 limits z_index to 0..4095 (12-bit); values outside cause "p_z > CANVAS_ITEM_Z_MAX" errors.
const CANVAS_Z_MIN: int = 0
const CANVAS_Z_MAX: int = 4095
const Z_BASE: int = 2048  # Center of Y-sort range
const Y_SORT_SCALE: int = 1  # foot_y maps to z; scale 1 keeps typical Y (-2000..2000) in range
const Z_BEHIND_ENTITIES: int = 0  # Follow/leader lines - draw behind player and NPCs
## Y-sorted world sprites clamp here so a band above stays free (see bible/draw_order.md stack).
const Z_WORLD_SORT_CAP: int = 3840
## Progress rings / eat / gather / craft timers — above all plane sprites, still on world branch (below CanvasLayer UI).
const Z_WORLD_PROGRESS_OVERLAY: int = 3880
## Rare world-attached HUD (e.g. clan name on claim). Below menus; above timers optional.
const Z_HUD_WORLD_FLOAT: int = 3920
const Z_ABOVE_WORLD: int = 4095  # Max canvas z — CanvasLayer HUD only; not world timers
## Pawn indicators that still Y-sort with depth (rout / hostile chevrons).
const OVERLAY_Z_BIAS: int = 2

## World overlay polylines (herd follow, party leader lines, land claim radius): shared width + opacity.
const WORLD_OVERLAY_LINE_WIDTH_PX := 2.0
const WORLD_OVERLAY_LINE_HERD_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const WORLD_OVERLAY_LINE_PARTY_COLOR := Color(0.92, 0.22, 0.2, 0.35)


func get_world_prop_scale() -> float:
	return maxf(world_prop_scale, 0.01)


func world_sort_z_from_y(sort_y: float) -> int:
	return clampi(Z_BASE + int(sort_y * Y_SORT_SCALE), CANVAS_Z_MIN, Z_WORLD_SORT_CAP)


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

## Returns tree sprite position for a cell height. With centered=true, y = -half_visual + tree_foot_offset_y
## so the bottom of the scaled cell sits at local y = tree_foot_offset_y (0 = gather node / trunk base).
func get_tree_sprite_position_for_cell_height(cell_height: float, scale_y: float = 1.0) -> Vector2:
	var half_visual: float = (cell_height * scale_y) / 2.0
	return Vector2(0, -half_visual + tree_foot_offset_y)

## Returns grass/decor sprite position (0, y): foot at node so draw order is correct.
## 64px: -32 (bottom at node); 128px: -64. Pass scale_y matching sprite.scale.y.
func get_grass_sprite_position_for_texture(texture: Texture2D, scale_y: float = 1.0) -> Vector2:
	if not texture:
		return Vector2(0, -32.0 * scale_y)
	var h: float = texture.get_height()
	return Vector2(0, -h * scale_y / 2.0)

## Update draw order. Sort by feet. Same formula for all (grass is on CanvasLayer -1).
## z_as_relative=false so sprites in different branches (player vs building) sort together.
func update_draw_order(sprite: Sprite2D, parent_node: Node2D) -> void:
	if not sprite or not parent_node:
		return
	sprite.z_as_relative = false  # Cross-branch sorting (player under WorldObjects, buildings under LandClaims)
	var foot_y: float = parent_node.global_position.y + sprite.position.y
	sprite.z_index = world_sort_z_from_y(foot_y)


## Tall placeholder cards: sort by anchored foot (not walk bounce on sprite.position.y).
func update_card_draw_order(sprite: Sprite2D, parent_node: Node2D, card_anchor_foot_y: float) -> void:
	if not sprite or not parent_node:
		return
	sprite.z_as_relative = false
	var anchor_y: float = card_anchor_foot_y
	if absf(anchor_y) < 0.001:
		anchor_y = sprite.position.y
	var foot_y: float = parent_node.global_position.y + anchor_y
	sprite.z_index = world_sort_z_from_y(foot_y)


## Timers / progress rings: float above the Y-sorted plane (viewer-adjacent), not behind huts/trees.
func update_world_timer_draw_order(overlay: CanvasItem) -> void:
	if overlay == null:
		return
	overlay.z_as_relative = false
	overlay.z_index = Z_WORLD_PROGRESS_OVERLAY


## Pawn indicators that still participate in plane depth (not gather/eat craft rings).
func update_overlay_draw_order(
	overlay: CanvasItem,
	owner: Node2D,
	local_y_from_owner: float,
	owner_body_sort_local_y: float = NAN
) -> void:
	if overlay == null or owner == null:
		return
	overlay.z_as_relative = false
	var sort_y: float = owner.global_position.y + local_y_from_owner
	if not is_nan(owner_body_sort_local_y):
		sort_y = maxf(sort_y, owner.global_position.y + owner_body_sort_local_y)
	overlay.z_index = clampi(world_sort_z_from_y(sort_y) + OVERLAY_Z_BIAS, CANVAS_Z_MIN, Z_WORLD_SORT_CAP)


## Tree-specific: sort at trunk ground (same Y line as player/NPC foot compare).
## North of trunk → behind tree (ambush); south of trunk → in front. Whole canopy uses this one depth.
func get_tree_trunk_sort_y(parent_node: Node2D) -> float:
	if parent_node == null:
		return 0.0
	# Pawn foot sort uses node.y + card foot (~-28). Trunk bottom is node.y + tree_foot_offset_y (~-24).
	# Default gap is 4px; tree_sort_offset_y is a small extra so feet-on-trunk reads behind, without a huge southern band.
	var trunk_bottom_y: float = parent_node.global_position.y + tree_foot_offset_y
	return trunk_bottom_y + tree_sort_offset_y


func update_tree_draw_order(sprite: Sprite2D, parent_node: Node2D, _texture: Texture2D) -> void:
	if not sprite or not parent_node:
		return
	sprite.z_as_relative = false
	var sort_y: float = get_tree_trunk_sort_y(parent_node)
	sprite.z_index = world_sort_z_from_y(sort_y)

func get_building_sprite_half_height(sprite: Sprite2D) -> float:
	if sprite == null:
		return 64.0 * BUILDING_SCALE * 0.5
	var tex_h: float
	if sprite.region_enabled:
		tex_h = sprite.region_rect.size.y
	elif sprite.texture:
		tex_h = float(sprite.texture.get_height())
	else:
		tex_h = 64.0
	var scale_y: float = absf(sprite.scale.y)
	if scale_y < 0.001:
		scale_y = 1.0
	return (tex_h * scale_y) * 0.5


## World Y at vertical center of building art (halfway between ground line and roof).
func get_building_midpoint_sort_y(sprite: Sprite2D, parent_node: Node2D) -> float:
	if sprite == null or parent_node == null:
		return 0.0
	var half_h: float = get_building_sprite_half_height(sprite)
	var ground_y: float = parent_node.global_position.y + sprite.position.y + half_h
	var mid_y: float = ground_y - half_h
	return mid_y + building_sort_offset_y


## Buildings: player in front when south of midpoint; behind when north (same rule as trees at trunk).
func update_building_draw_order(sprite: Sprite2D, parent_node: Node2D) -> void:
	if not sprite or not parent_node:
		return
	sprite.z_as_relative = false
	var sort_y: float = get_building_midpoint_sort_y(sprite, parent_node)
	sprite.z_index = world_sort_z_from_y(sort_y)

# Aliases
func update_object_y_sort(sprite: Sprite2D, parent_node: Node2D) -> void:
	update_draw_order(sprite, parent_node)

func update_decal_y_sort(sprite: Sprite2D, parent_node: Node2D) -> void:
	update_draw_order(sprite, parent_node)

func update_effect_y_sort(sprite: Sprite2D, parent_node: Node2D) -> void:
	update_draw_order(sprite, parent_node)
