extends RefCounted
class_name WeaponOverlayCombat

## Overlay-only weapon animation (card body stays static; WeaponOverlay child animates).

enum OverlayState { IDLE, READY, STRIKING, RECOVERING }

enum AttackKind { THRUST, SWING_DOWN }

const Registry = preload("res://scripts/config/placeholder_card_registry.gd")
const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")

const META_OVERLAY_STATE := "weapon_overlay_state"
const META_STRIKE_DIR := "weapon_strike_dir"


static func get_overlay_state(entity: Node) -> int:
	if entity == null:
		return OverlayState.IDLE
	return int(entity.get_meta(META_OVERLAY_STATE, OverlayState.IDLE))


static func set_overlay_state(entity: Node, st: int) -> void:
	if entity:
		entity.set_meta(META_OVERLAY_STATE, st)


static func uses_overlay_combat(entity: Node) -> bool:
	if entity == null or not is_instance_valid(entity):
		return false
	if not PlaceholderCardService:
		return false
	return PlaceholderCardService.uses_placeholder_cards(entity)


static func should_hold_weapon_ready(entity: Node) -> bool:
	if entity == null or not is_instance_valid(entity):
		return false
	if entity.is_in_group("player"):
		return Input.is_action_pressed("weapon_ready")
	var weapon_comp: Node = entity.get_node_or_null("WeaponComponent")
	if weapon_comp and weapon_comp.has_method("_card_overlay_should_show"):
		return weapon_comp._card_overlay_should_show()
	return false


static func resolve_recovery_aim(entity: Node, fallback_aim: Vector2) -> Vector2:
	if entity == null or not is_instance_valid(entity):
		return fallback_aim
	if entity.is_in_group("player") and entity.has_method("_get_cursor_aim_direction"):
		return entity._get_cursor_aim_direction()
	if entity.get("aim_dir") != null:
		var ad: Vector2 = entity.get("aim_dir") as Vector2
		if ad.length_squared() > 0.0001:
			return ad.normalized()
	if fallback_aim.length_squared() > 0.0001:
		return fallback_aim.normalized()
	return Vector2(1, 0)


static func _world_aim_dir(world_aim: Vector2) -> Vector2:
	if world_aim.length_squared() < 0.0001:
		return Vector2(1, 0)
	return world_aim.normalized()


static func compute_aim_rotation(body_sprite: Sprite2D, world_aim: Vector2, texture_tip_deg: float, extra_offset_deg: float = 0.0) -> float:
	## World aim in parent local space — flip_h is cosmetic on the card body and does not mirror children.
	if body_sprite == null:
		return deg_to_rad(texture_tip_deg + extra_offset_deg)
	var dir := _world_aim_dir(world_aim)
	var tip_rad := deg_to_rad(texture_tip_deg)
	return dir.angle() - tip_rad + deg_to_rad(extra_offset_deg)


static func uses_aim_facing_flip(registry, weapon_type: ResourceData.ResourceType) -> bool:
	if registry == null:
		return false
	return int(registry.get_weapon_combat_profile(weapon_type).get("attack_kind", AttackKind.SWING_DOWN)) == AttackKind.THRUST


static func apply_idle_pose(body_sprite: Sprite2D, overlay: Sprite2D, registry, weapon_type: ResourceData.ResourceType) -> void:
	if body_sprite == null or overlay == null or registry == null:
		return
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	var idle_deg: float = float(profile.get("idle_rotation_deg", 0.0))
	_ensure_weapon_pivot(overlay, profile)
	var base_offset: Vector2 = _pose_offset(body_sprite, registry, weapon_type, profile, false)
	overlay.rotation = deg_to_rad(idle_deg)
	overlay.set_meta("card_overlay_offset", base_offset)
	CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, base_offset)


static func _overlay_mirror_texture(registry, weapon_type: ResourceData.ResourceType) -> bool:
	## Thrust spears mirror with body flip; swing weapons use signed rotation instead.
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	return int(profile.get("attack_kind", AttackKind.SWING_DOWN)) == AttackKind.THRUST


static func uses_overlay_texture_mirror(registry, weapon_type: ResourceData.ResourceType) -> bool:
	return _overlay_mirror_texture(registry, weapon_type)


static func apply_ready_pose(body_sprite: Sprite2D, overlay: Sprite2D, registry, weapon_type: ResourceData.ResourceType, aim_dir: Vector2) -> void:
	if body_sprite == null or overlay == null or registry == null:
		return
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
	var kind: int = int(profile.get("attack_kind", AttackKind.SWING_DOWN))
	var rot: float
	if kind == AttackKind.THRUST:
		body_sprite.flip_h = aim_dir.x < 0.0
		rot = compute_aim_rotation(body_sprite, aim_dir, tip_deg, 0.0)
		_ensure_weapon_pivot(overlay, profile)
	else:
		sync_swing_body_facing(body_sprite.get_parent(), body_sprite)
		_ensure_weapon_pivot(overlay, profile)
		rot = deg_to_rad(_swing_ready_degrees(body_sprite, profile))
	overlay.rotation = rot
	var base_offset: Vector2 = _pose_offset(body_sprite, registry, weapon_type, profile, true)
	overlay.set_meta("card_overlay_offset", base_offset)
	CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, base_offset, _overlay_mirror_texture(registry, weapon_type))
	if kind == AttackKind.THRUST:
		var forward_px: float = float(profile.get("ready_forward_px", 0.0))
		if forward_px > 0.0 and aim_dir.length_squared() > 0.0001:
			overlay.position += _aim_delta_local(body_sprite, aim_dir, forward_px)


static func play_strike(
	entity: Node,
	body_sprite: Sprite2D,
	overlay: Sprite2D,
	registry,
	weapon_type: ResourceData.ResourceType,
	aim_dir: Vector2,
	on_hit: Callable,
	on_strike_anim_done: Callable = Callable()
) -> void:
	if body_sprite == null or overlay == null or registry == null or entity == null:
		return
	if not entity.is_inside_tree():
		return
	set_overlay_state(entity, OverlayState.STRIKING)
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	var strike_duration: float = float(profile.get("strike_duration", 0.12))
	var kind: int = int(profile.get("attack_kind", AttackKind.SWING_DOWN))
	var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
	var ready_base: Vector2 = _pose_offset(body_sprite, registry, weapon_type, profile, true)
	var start_rot: float
	var hit_called := false
	var tween := overlay.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)

	if kind == AttackKind.THRUST:
		# Match card facing to thrust direction before computing local strike path.
		body_sprite.flip_h = aim_dir.x < 0.0
		start_rot = compute_aim_rotation(body_sprite, aim_dir, tip_deg, 0.0)
		overlay.rotation = start_rot
		var mirror_tex: bool = _overlay_mirror_texture(registry, weapon_type)
		var windup_px: float = float(profile.get("thrust_windup_px", 8.0))
		var extend_px: float = float(profile.get("thrust_extend_px", 50.0))
		var windup_frac: float = float(profile.get("thrust_windup_frac", 0.0))
		var lunge_frac: float = float(profile.get("thrust_lunge_frac", 0.52))
		var hit_lunge_frac: float = clampf(float(profile.get("thrust_hit_lunge_frac", 0.55)), 0.2, 1.0)
		var windup_t: float = strike_duration * windup_frac
		var lunge_t: float = strike_duration * lunge_frac
		var retract_t: float = maxf(strike_duration - windup_t - lunge_t, 0.04)
		var ready_base_now: Vector2 = _pose_offset(body_sprite, registry, weapon_type, profile, true)
		var ready_pos: Vector2 = _flipped_position(body_sprite, ready_base_now)
		var ready_forward_px: float = float(profile.get("ready_forward_px", 0.0))
		if ready_forward_px > 0.0 and aim_dir.length_squared() > 0.0001:
			ready_pos += _aim_delta_local(body_sprite, aim_dir, ready_forward_px)
		overlay.set_meta("card_overlay_offset", ready_base_now)
		CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, ready_base_now, mirror_tex)
		var windup_pos: Vector2 = ready_pos + _aim_delta_local(body_sprite, aim_dir, -windup_px)
		var extend_pos: Vector2 = ready_pos + _aim_delta_local(body_sprite, aim_dir, extend_px)
		var hit_pos: Vector2 = ready_pos + _aim_delta_local(body_sprite, aim_dir, extend_px * hit_lunge_frac)
		overlay.position = ready_pos
		if windup_t > 0.001:
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(overlay, "position", windup_pos, windup_t)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(overlay, "position", hit_pos, lunge_t * hit_lunge_frac)
		tween.tween_callback(func() -> void:
			if not hit_called and on_hit.is_valid():
				hit_called = true
				on_hit.call()
		)
		if hit_lunge_frac < 0.999:
			tween.tween_property(overlay, "position", extend_pos, lunge_t * (1.0 - hit_lunge_frac))
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(overlay, "position", ready_pos, retract_t)
	else:
		_play_swing_strike(
			overlay, body_sprite, registry, weapon_type, profile, ready_base,
			strike_duration, tween, func() -> void:
				if not hit_called and on_hit.is_valid():
					hit_called = true
					on_hit.call()
		)

	tween.tween_callback(func() -> void:
		if entity and is_instance_valid(entity):
			if on_strike_anim_done.is_valid():
				on_strike_anim_done.call()
			elif should_hold_weapon_ready(entity):
				var hold_aim: Vector2 = resolve_recovery_aim(entity, aim_dir)
				set_overlay_state(entity, OverlayState.READY)
				apply_ready_pose(body_sprite, overlay, registry, weapon_type, hold_aim)
			else:
				set_overlay_state(entity, OverlayState.RECOVERING)
	)


static func play_post_strike_recovery(
	entity: Node,
	body_sprite: Sprite2D,
	overlay: Sprite2D,
	registry,
	weapon_type: ResourceData.ResourceType,
	aim_dir: Vector2,
	recovery_duration: float,
	on_recovery_complete: Callable = Callable()
) -> void:
	if overlay == null or not entity.is_inside_tree():
		set_overlay_state(entity, OverlayState.IDLE)
		return
	var hold_ready: bool = should_hold_weapon_ready(entity)
	var resolved_aim: Vector2 = resolve_recovery_aim(entity, aim_dir)
	if hold_ready:
		# Stay in ready pose for the whole cooldown — no flash to vertical idle.
		set_overlay_state(entity, OverlayState.READY)
		apply_ready_pose(body_sprite, overlay, registry, weapon_type, resolved_aim)
	else:
		set_overlay_state(entity, OverlayState.RECOVERING)
		apply_idle_pose(body_sprite, overlay, registry, weapon_type)
	var t := entity.get_tree().create_timer(maxf(recovery_duration, 0.05))
	t.timeout.connect(func() -> void:
		if not entity or not is_instance_valid(entity):
			return
		var still_hold: bool = should_hold_weapon_ready(entity)
		var end_aim: Vector2 = resolve_recovery_aim(entity, aim_dir)
		if still_hold:
			set_overlay_state(entity, OverlayState.READY)
			apply_ready_pose(body_sprite, overlay, registry, weapon_type, end_aim)
		else:
			set_overlay_state(entity, OverlayState.IDLE)
			apply_idle_pose(body_sprite, overlay, registry, weapon_type)
		if on_recovery_complete.is_valid():
			on_recovery_complete.call()
	)


## Legacy name — delegates to play_post_strike_recovery (no aim / no callback).
static func play_recovery_to_idle(
	entity: Node,
	body_sprite: Sprite2D,
	overlay: Sprite2D,
	registry,
	weapon_type: ResourceData.ResourceType,
	recovery_duration: float
) -> void:
	play_post_strike_recovery(entity, body_sprite, overlay, registry, weapon_type, Vector2(1, 0), recovery_duration)


static func _base_offset(body_sprite: Sprite2D, registry, weapon_type: ResourceData.ResourceType) -> Vector2:
	var offset_px: Vector2 = registry.get_tool_overlay_offset_px(weapon_type)
	return _offset_px_to_local(body_sprite, offset_px)


static func _pose_offset(body_sprite: Sprite2D, registry, weapon_type: ResourceData.ResourceType, profile: Dictionary, ready: bool) -> Vector2:
	var offset_px: Vector2 = registry.get_tool_overlay_offset_px(weapon_type)
	if ready and profile.has("ready_offset_px"):
		offset_px = profile["ready_offset_px"] as Vector2
	return _offset_px_to_local(body_sprite, offset_px)


static func _offset_px_to_local(body_sprite: Sprite2D, offset_px: Vector2) -> Vector2:
	var sx: float = absf(body_sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	return Vector2(offset_px.x / sx, offset_px.y / sx)


static func _flipped_position(body_sprite: Sprite2D, base_offset: Vector2) -> Vector2:
	var x := base_offset.x
	if body_sprite.flip_h:
		x = -base_offset.x
	return Vector2(x, base_offset.y)


static func _aim_delta_local(body_sprite: Sprite2D, world_aim: Vector2, distance_display_px: float) -> Vector2:
	var dir := _world_aim_dir(world_aim)
	var sx: float = absf(body_sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	return dir * (distance_display_px / sx)


## Swing weapons: rotate around handle (bottom of texture), not center of PNG.
static func _ensure_weapon_pivot(overlay: Sprite2D, profile: Dictionary) -> void:
	if overlay == null or overlay.texture == null:
		return
	var kind: int = int(profile.get("attack_kind", AttackKind.SWING_DOWN))
	overlay.centered = true
	if kind == AttackKind.THRUST:
		overlay.offset = Vector2.ZERO
		return
	var pivot_y_frac: float = clampf(float(profile.get("pivot_y_frac", 1.0)), 0.0, 1.0)
	var h: float = float(overlay.texture.get_height()) * absf(overlay.scale.y)
	# Godot draws centered sprites at node.position + offset; node origin = rotation pivot.
	# pivot_y_frac 1.0 = handle at bottom of PNG → shift texture center up (−Y).
	var pivot_from_center_y: float = (0.5 - pivot_y_frac) * h
	overlay.offset = Vector2(0.0, pivot_from_center_y)


static func _swing_ready_degrees(body_sprite: Sprite2D, profile: Dictionary) -> float:
	var idle_deg: float = float(profile.get("idle_rotation_deg", 0.0))
	var ready_offset_deg: float = float(profile.get("ready_rotation_offset_deg", 40.0))
	var facing: float = _swing_facing_sign(body_sprite)
	# Right: −offset = 10 o'clock. Left: +offset = 2 o'clock. Card-side placement uses body flip_h.
	return idle_deg - ready_offset_deg * facing


static func sync_swing_body_facing(entity: Node, body_sprite: Sprite2D) -> void:
	if entity == null or body_sprite == null:
		return
	var vel: Vector2 = Vector2.ZERO
	if entity is CharacterBody2D:
		vel = (entity as CharacterBody2D).velocity
	if vel.length_squared() > 25.0:
		body_sprite.flip_h = vel.x < 0.0
		return
	if entity.get("last_facing") != null:
		var lf: Vector2 = entity.get("last_facing") as Vector2
		if absf(lf.x) > 0.05:
			body_sprite.flip_h = lf.x < 0.0


static func _swing_facing_sign(body_sprite: Sprite2D) -> float:
	## +1 facing right, -1 facing left. Rotation arc and horizontal lunge flip with facing.
	return -1.0 if body_sprite.flip_h else 1.0


static func compute_swing_strike_targets(
	body_sprite: Sprite2D,
	ready_base: Vector2,
	profile: Dictionary
) -> Dictionary:
	var facing: float = _swing_facing_sign(body_sprite)
	var sx: float = absf(body_sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var ready_rot: float = deg_to_rad(_swing_ready_degrees(body_sprite, profile))
	var windup_extra_deg: float = float(profile.get("swing_windup_deg", 14.0))
	var swing_arc_deg: float = float(profile.get("swing_arc_deg", 72.0))
	var pull_back_px: float = float(profile.get("swing_pull_back_px", 10.0))
	var pull_up_px: float = float(profile.get("swing_pull_up_px", 6.0))
	var lunge_forward_px: float = float(profile.get("swing_lunge_forward_px", 24.0))
	var lunge_down_px: float = float(profile.get("swing_lunge_down_px", 16.0))
	var windup_rot: float = ready_rot - deg_to_rad(windup_extra_deg) * facing
	var end_rot: float = ready_rot + deg_to_rad(swing_arc_deg) * facing
	var ready_pos: Vector2 = _flipped_position(body_sprite, ready_base)
	# Back = opposite of forward; up = negative Y in Godot parent space.
	var windup_pos: Vector2 = ready_pos + Vector2(-facing * pull_back_px / sx, -pull_up_px / sx)
	var hit_pos: Vector2 = ready_pos + Vector2(facing * lunge_forward_px / sx, lunge_down_px / sx)
	return {
		"ready_rot": ready_rot,
		"windup_rot": windup_rot,
		"end_rot": end_rot,
		"ready_pos": ready_pos,
		"windup_pos": windup_pos,
		"hit_pos": hit_pos,
	}


static func _play_swing_strike(
	overlay: Sprite2D,
	body_sprite: Sprite2D,
	registry,
	weapon_type: ResourceData.ResourceType,
	profile: Dictionary,
	ready_base: Vector2,
	strike_duration: float,
	tween: Tween,
	on_hit_frame: Callable
) -> void:
	_ensure_weapon_pivot(overlay, profile)
	var mirror_tex: bool = _overlay_mirror_texture(registry, weapon_type)
	var swing_entity: Node = body_sprite.get_parent() if body_sprite else null
	sync_swing_body_facing(swing_entity, body_sprite)
	var targets: Dictionary = compute_swing_strike_targets(body_sprite, ready_base, profile)
	var ready_rot: float = targets["ready_rot"]
	var windup_rot: float = targets["windup_rot"]
	var end_rot: float = targets["end_rot"]
	var ready_pos: Vector2 = targets["ready_pos"]
	var windup_pos: Vector2 = targets["windup_pos"]
	var hit_pos: Vector2 = targets["hit_pos"]
	var windup_frac: float = clampf(float(profile.get("swing_windup_frac", 0.12)), 0.05, 0.25)
	var strike_frac: float = clampf(float(profile.get("swing_strike_frac", 0.48)), 0.3, 0.75)
	var recover_frac: float = maxf(1.0 - windup_frac - strike_frac, 0.08)
	var windup_t: float = strike_duration * windup_frac
	var strike_t: float = strike_duration * strike_frac
	var recover_t: float = strike_duration * recover_frac
	overlay.rotation = ready_rot
	overlay.set_meta("card_overlay_offset", ready_base)
	CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, ready_base, mirror_tex)
	overlay.position = ready_pos
	# Wind-up: quick cock back.
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "rotation", windup_rot, windup_t)
	tween.tween_property(overlay, "position", windup_pos, windup_t)
	# Downswing: fast sweep forward and down.
	tween.chain().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(overlay, "rotation", end_rot, strike_t)
	tween.tween_property(overlay, "position", hit_pos, strike_t)
	tween.chain().tween_callback(on_hit_frame)
	# Snap back to ready.
	tween.chain().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "rotation", ready_rot, recover_t)
	tween.tween_property(overlay, "position", ready_pos, recover_t)
