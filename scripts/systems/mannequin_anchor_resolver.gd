extends RefCounted
class_name MannequinAnchorResolver

## Shared shoulder placement for layered mannequin (tuner + in-game).

const LimbPresetCoordsScript = preload("res://scripts/systems/limb_preset_coords.gd")


static func shoulder_global_from_display(
	sprite: Sprite2D,
	body_visual: Node,
	display_px: Vector2
) -> Vector2:
	if sprite == null:
		return Vector2.ZERO
	if body_visual == null:
		return LimbPresetCoordsScript.body_global_from_display(sprite, display_px)
	var body_local := shoulder_body_local_from_display_px(sprite, body_visual, display_px)
	return shoulder_anchor_global(body_visual, body_local)


static func shoulder_body_local_from_display_px(
	sprite: Sprite2D,
	body_visual: Node,
	display_px: Vector2
) -> Vector2:
	if body_visual == null or sprite == null:
		return Vector2.ZERO
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var rig_local: Vector2 = LimbPresetCoordsScript.body_display_to_rig_local(sprite, display_px)
	var in_sprite_local: Vector2 = (rig_local - sprite.position) / sx
	var body_offset := Vector2.ZERO
	if body_visual.has_method("get_body_sprite_offset"):
		body_offset = body_visual.call("get_body_sprite_offset")
	return in_sprite_local - body_offset


static func shoulder_anchor_global(body_visual: Node, body_local: Vector2) -> Vector2:
	if body_visual == null:
		return Vector2.ZERO
	var body_sprite: Sprite2D = null
	if body_visual.has_method("get_body_sprite"):
		body_sprite = body_visual.call("get_body_sprite") as Sprite2D
	if body_sprite:
		return body_sprite.to_global(body_local)
	if body_visual.has_method("get_body_sprite_offset"):
		return body_visual.to_global(body_local + body_visual.call("get_body_sprite_offset"))
	return body_visual.to_global(body_local)


static func rig_local_from_global(rig: Node2D, global_pos: Vector2) -> Vector2:
	if rig == null:
		return global_pos
	return rig.to_local(global_pos)
