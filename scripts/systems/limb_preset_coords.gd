extends RefCounted
class_name LimbPresetCoords

## Single source of truth: body display px ↔ rig/player local space (matches ProceduralArmController).


static func flip_display_x(display_px: Vector2, flip_h: bool) -> Vector2:
	if flip_h:
		return Vector2(-display_px.x, display_px.y)
	return display_px


static func body_display_to_rig_local(sprite: Sprite2D, display_px: Vector2) -> Vector2:
	if sprite == null:
		return Vector2.ZERO
	var off := flip_display_x(display_px, sprite.flip_h)
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	return sprite.position + Vector2(off.x * sx, off.y * sx)


static func body_global_from_display(sprite: Sprite2D, display_px: Vector2) -> Vector2:
	var rig := sprite.get_parent() as Node2D
	if rig == null:
		return sprite.global_position
	return rig.to_global(body_display_to_rig_local(sprite, display_px))


static func body_display_from_global(sprite: Sprite2D, global_pos: Vector2) -> Vector2:
	if sprite == null:
		return Vector2.ZERO
	var rig := sprite.get_parent() as Node2D
	if rig == null:
		return Vector2.ZERO
	var rig_local := rig.to_local(global_pos)
	var delta := rig_local - sprite.position
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var display := Vector2(delta.x / sx, delta.y / sx)
	return flip_display_x(display, sprite.flip_h)


static func overlay_display_from_position(sprite: Sprite2D, overlay: Sprite2D) -> Vector2:
	if sprite == null or overlay == null:
		return Vector2.ZERO
	var sx: float = absf(sprite.scale.x)
	var display := overlay.position * sx
	if sprite.flip_h:
		display.x = -display.x
	return display


static func overlay_grip_global(overlay: Sprite2D, grip_px: Vector2) -> Vector2:
	if overlay == null:
		return Vector2.ZERO
	var local_grip := Vector2(grip_px.x * overlay.scale.x, grip_px.y * overlay.scale.y)
	return overlay.to_global(local_grip)


static func overlay_grip_px_from_global(overlay: Sprite2D, global_pos: Vector2) -> Vector2:
	if overlay == null:
		return Vector2.ZERO
	var local_on_overlay := overlay.to_local(global_pos)
	var sx: float = overlay.scale.x
	var sy: float = overlay.scale.y
	if absf(sx) < 0.001:
		sx = 1.0
	if absf(sy) < 0.001:
		sy = 1.0
	return Vector2(local_on_overlay.x / sx, local_on_overlay.y / sy)
