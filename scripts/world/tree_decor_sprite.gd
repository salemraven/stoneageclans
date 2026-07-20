extends Node2D
class_name TreeDecorSprite
## Visual-only tree — same Sprite2D layout as GatherableResource WOOD (no collision/scripts).

const DEFAULT_SCALE := 1.15


func setup(desc: Dictionary) -> void:
	var pos: Vector2 = desc.get("position", Vector2.ZERO) as Vector2
	var sort_offset: float = YSortUtils.tree_sort_offset_y if YSortUtils else 0.0
	position = pos + Vector2(0.0, sort_offset)
	var tree_idx: int = clampi(int(desc.get("tree_idx", 0)), 0, 14)
	var scale_mult: float = float(desc.get("scale_mult", DEFAULT_SCALE))
	var rot: float = float(desc.get("rotation", 0.0))
	var tex := AssetRegistry.get_treess_sprite() if AssetRegistry else null
	if tex == null:
		push_warning("TreeDecorSprite: treess.png missing")
		return
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	var cols := 5
	var rows := 3
	var cell_w: float = float(tex.get_width()) / float(cols)
	var cell_h: float = float(tex.get_height()) / float(rows)
	var col: int = tree_idx % cols
	var row: int = tree_idx / cols
	sprite.region_enabled = true
	sprite.region_rect = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
	sprite.scale = Vector2(scale_mult, scale_mult)
	sprite.rotation = rot
	if YSortUtils:
		sprite.position = Vector2(0.0, -sort_offset) + YSortUtils.get_tree_sprite_position_for_cell_height(cell_h, sprite.scale.y)
		sprite.z_as_relative = false
	add_child(sprite)
	if YSortUtils:
		YSortUtils.update_tree_draw_order(sprite, self, tex)
