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
	speed: float = Registry.WALK_BOUNCE_SPEED
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


static func walk_arm_sway_phase(bounce_time: float, moving: bool, is_dominant_arm: bool) -> float:
	if not moving:
		return 0.0
	var swing := sin(bounce_time)
	return swing if is_dominant_arm else -swing


static func walk_arm_sway_display_px(
	bounce_time: float,
	moving: bool,
	facing_left: bool,
	is_dominant_arm: bool
) -> Vector2:
	var swing := walk_arm_sway_phase(bounce_time, moving, is_dominant_arm)
	if absf(swing) < 0.0001:
		return Vector2.ZERO
	var theta: float = swing * deg_to_rad(Registry.WALK_ARM_SWING_ANGLE_DEG)
	var radius: float = Registry.WALK_ARM_PENDULUM_RADIUS_PX
	var forward_sign := -1.0 if facing_left else 1.0
	var forward: float = sin(theta) * radius * forward_sign
	var arc_drop: float = (1.0 - cos(theta)) * radius * Registry.WALK_ARM_PENDULUM_SAG_SCALE
	return Vector2(forward, arc_drop)


static func walk_weapon_overlay_sway_offset_x(bounce_time: float, moving: bool, facing_left: bool) -> float:
	return walk_arm_sway_display_px(bounce_time, moving, facing_left, true).x


static func sync_weapon_overlay_flip(
	body_sprite: Sprite2D,
	overlay: Sprite2D,
	base_offset: Vector2,
	mirror_texture: bool = true,
	bounce_y_extra: float = 0.0,
	bounce_x_extra: float = 0.0
) -> void:
	if body_sprite == null or overlay == null:
		return
	overlay.flip_h = body_sprite.flip_h if mirror_texture else false
	var x := base_offset.x
	if body_sprite.flip_h:
		x = -base_offset.x - bounce_x_extra
	else:
		x = base_offset.x + bounce_x_extra
	overlay.position = Vector2(x, base_offset.y + bounce_y_extra)
