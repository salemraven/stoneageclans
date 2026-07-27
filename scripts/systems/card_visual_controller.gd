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


## Alternate walk swing: one arm forward on +character X while the other goes back.
static func swing_hand_display_px(
	shoulder_display_px: Vector2,
	hand_idle_display_px: Vector2,
	bounce_time: float,
	moving: bool,
	facing_left: bool,
	is_dominant_arm: bool
) -> Vector2:
	if not moving:
		return hand_idle_display_px
	var arm_phase := walk_arm_sway_phase(bounce_time, moving, is_dominant_arm)
	if absf(arm_phase) < 0.0001:
		return hand_idle_display_px
	var forward_sign := -1.0 if facing_left else 1.0
	var offset := hand_idle_display_px - shoulder_display_px
	if offset.length_squared() < 0.0001:
		return hand_idle_display_px
	# Opposite arms: dominant +phase swings forward, support -phase swings back.
	var forward_delta := arm_phase * Registry.WALK_ARM_SWING_FORWARD_PX * forward_sign
	var swung_offset := offset + Vector2(forward_delta, 0.0)
	var pivot_angle := arm_phase * deg_to_rad(Registry.WALK_ARM_SWING_ANGLE_DEG)
	return shoulder_display_px + swung_offset.rotated(pivot_angle)


static func swing_hand_delta_display_px(
	shoulder_display_px: Vector2,
	hand_idle_display_px: Vector2,
	bounce_time: float,
	moving: bool,
	facing_left: bool,
	is_dominant_arm: bool
) -> Vector2:
	return (
		swing_hand_display_px(
			shoulder_display_px, hand_idle_display_px, bounce_time, moving, facing_left, is_dominant_arm
		)
		- hand_idle_display_px
	)


static func overlay_display_from_base_offset(sprite: Sprite2D, base_offset: Vector2) -> Vector2:
	var sx: float = absf(sprite.scale.x) if sprite != null else 1.0
	if sx < 0.001:
		sx = 1.0
	var display := Vector2(base_offset.x * sx, base_offset.y * sx)
	if sprite != null and sprite.flip_h:
		display.x = -display.x
	return display


static func overlay_position_from_display(sprite: Sprite2D, display_px: Vector2, bounce_y_extra: float = 0.0) -> Vector2:
	var sx: float = absf(sprite.scale.x) if sprite != null else 1.0
	if sx < 0.001:
		sx = 1.0
	var x := display_px.x / sx
	if sprite != null and sprite.flip_h:
		x = -x
	return Vector2(x, display_px.y / sx + bounce_y_extra)


static func walk_arm_sway_display_px(
	bounce_time: float,
	moving: bool,
	facing_left: bool,
	is_dominant_arm: bool,
	shoulder_display_px: Vector2 = Vector2.ZERO,
	hand_idle_display_px: Vector2 = Vector2.ZERO
) -> Vector2:
	return swing_hand_delta_display_px(
		shoulder_display_px, hand_idle_display_px, bounce_time, moving, facing_left, is_dominant_arm
	)


static func walk_weapon_overlay_sway_delta_display(
	sprite: Sprite2D,
	base_offset: Vector2,
	shoulder_display_px: Vector2,
	bounce_time: float,
	moving: bool
) -> Vector2:
	if not moving or sprite == null:
		return Vector2.ZERO
	var idle_display := overlay_display_from_base_offset(sprite, base_offset)
	return swing_hand_delta_display_px(
		shoulder_display_px, idle_display, bounce_time, moving, sprite.flip_h, true
	)


static func sync_weapon_overlay_flip(
	body_sprite: Sprite2D,
	overlay: Sprite2D,
	base_offset: Vector2,
	mirror_texture: bool = true,
	bounce_y_extra: float = 0.0,
	walk_swing_delta_display: Vector2 = Vector2.ZERO
) -> void:
	if body_sprite == null or overlay == null:
		return
	overlay.flip_h = body_sprite.flip_h if mirror_texture else false
	if walk_swing_delta_display.length_squared() > 0.0001:
		var display_px := overlay_display_from_base_offset(body_sprite, base_offset) + walk_swing_delta_display
		overlay.position = overlay_position_from_display(body_sprite, display_px, bounce_y_extra)
		return
	var x := base_offset.x
	if body_sprite.flip_h:
		x = -base_offset.x
	overlay.position = Vector2(x, base_offset.y + bounce_y_extra)
