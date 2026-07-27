extends RefCounted

const Registry = preload("res://scripts/config/placeholder_card_registry.gd")


static func apply_card_layout(sprite: Sprite2D, texture: Texture2D, registry) -> float:
	if sprite == null or texture == null or registry == null:
		return -128.0
	sprite.texture = texture
	sprite.region_enabled = false
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var scale_value: float = registry.get_card_scale(texture)
	sprite.scale = Vector2(scale_value, scale_value)
	var foot_y: float = registry.get_card_foot_y(texture)
	sprite.position = Vector2(0.0, foot_y)
	return foot_y


static func tick_walk_bounce(
	sprite: Sprite2D,
	foot_y: float,
	bounce_time: float,
	moving: bool,
	delta: float,
	amplitude: float = Registry.WALK_BOUNCE_AMPLITUDE,
	speed: float = Registry.effective_walk_bounce_speed()
) -> float:
	if sprite == null:
		return bounce_time
	if moving:
		bounce_time += delta * speed
		var offset := sin(bounce_time) * amplitude
		sprite.position.y = roundf(foot_y + offset)
	else:
		bounce_time = 0.0
		sprite.position.y = roundf(foot_y)
	return bounce_time


static func weapon_overlay_walk_bounce_offset_y(bounce_time: float, moving: bool) -> float:
	## Counter the inherited body bounce and re-apply a phase-lagged wave (weapon trails the card).
	if not moving:
		return 0.0
	var body_amp: float = Registry.WALK_BOUNCE_AMPLITUDE
	var overlay_amp: float = body_amp * Registry.WEAPON_OVERLAY_BOUNCE_AMP_SCALE
	var body_y: float = sin(bounce_time) * body_amp
	var overlay_y: float = sin(bounce_time - Registry.WEAPON_OVERLAY_BOUNCE_PHASE_LAG_RAD) * overlay_amp
	return overlay_y - body_y


static func sync_weapon_overlay_flip(body_sprite: Sprite2D, overlay: Sprite2D, base_offset: Vector2, mirror_texture: bool = true, bounce_y_extra: float = 0.0) -> void:
	if body_sprite == null or overlay == null:
		return
	overlay.flip_h = body_sprite.flip_h if mirror_texture else false
	var x := base_offset.x
	if body_sprite.flip_h:
		x = -base_offset.x
	overlay.position = Vector2(x, base_offset.y + bounce_y_extra)
