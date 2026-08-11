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


static func _combat_profile(registry, weapon_type: ResourceData.ResourceType) -> Dictionary:
	var profile: Dictionary = registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		return LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	return profile


static func _display_scale_mul(body_sprite: Sprite2D) -> float:
	if body_sprite == null or not PlaceholderCardService:
		return 1.0
	var entity: Node = body_sprite.get_parent()
	if entity and PlaceholderCardService.uses_layered_body_mannequin(entity):
		return PlaceholderCardService.get_runtime_display_scale(entity)
	return 1.0


static func uses_aim_facing_flip(registry, weapon_type: ResourceData.ResourceType) -> bool:
	if registry == null:
		return false
	return int(_combat_profile(registry, weapon_type).get("attack_kind", AttackKind.SWING_DOWN)) == AttackKind.THRUST


static func apply_idle_pose(body_sprite: Sprite2D, overlay: Sprite2D, registry, weapon_type: ResourceData.ResourceType) -> void:
	if body_sprite == null or overlay == null or registry == null:
		return
	var profile: Dictionary = _combat_profile(registry, weapon_type)
	var idle_deg: float = float(profile.get("idle_rotation_deg", 0.0))
	_ensure_weapon_pivot(overlay, profile)
	var base_offset: Vector2 = _pose_offset(body_sprite, registry, weapon_type, profile, false)
	overlay.rotation = deg_to_rad(idle_deg)
	overlay.set_meta("card_overlay_offset", base_offset)
	CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, base_offset)


static func _overlay_mirror_texture(registry, weapon_type: ResourceData.ResourceType) -> bool:
	## Thrust spears mirror with body flip; swing weapons use signed rotation instead.
	var profile: Dictionary = _combat_profile(registry, weapon_type)
	return int(profile.get("attack_kind", AttackKind.SWING_DOWN)) == AttackKind.THRUST


static func uses_overlay_texture_mirror(registry, weapon_type: ResourceData.ResourceType) -> bool:
	return _overlay_mirror_texture(registry, weapon_type)


static func is_thrust_weapon(registry, weapon_type: ResourceData.ResourceType) -> bool:
	return uses_aim_facing_flip(registry, weapon_type)


static func horizontal_sign_from_entity(entity: Node, fallback_aim: Vector2 = Vector2.ZERO) -> float:
	if entity == null:
		return 1.0
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite and sprite.flip_h:
		return -1.0
	if entity.get("last_facing") != null:
		var lf: Vector2 = entity.get("last_facing") as Vector2
		if absf(lf.x) > 0.05:
			return signf(lf.x)
	if fallback_aim.length_squared() > 0.0001 and absf(fallback_aim.x) > 0.05:
		return signf(fallback_aim.x)
	return 1.0


## Spear thrust cannot aim straight up/down — clamp to a minimum horizontal component.
static func clamp_thrust_aim(
	world_aim: Vector2,
	registry,
	weapon_type: ResourceData.ResourceType,
	horizontal_sign: float = 1.0
) -> Vector2:
	if registry == null or not is_thrust_weapon(registry, weapon_type):
		return _world_aim_dir(world_aim)
	if world_aim.length_squared() < 0.0001:
		return Vector2(signf(horizontal_sign), 0.0).normalized()
	var profile: Dictionary = _combat_profile(registry, weapon_type)
	var min_horiz: float = clampf(float(profile.get("thrust_min_horizontal_frac", 0.35)), 0.05, 0.95)
	var dir := world_aim.normalized()
	if absf(dir.x) >= min_horiz:
		return dir
	var sign_x: float = signf(dir.x) if absf(dir.x) > 0.001 else signf(horizontal_sign)
	if sign_x == 0.0:
		sign_x = 1.0
	var sign_y: float = signf(dir.y) if absf(dir.y) > 0.001 else -1.0
	var clamped_x: float = sign_x * min_horiz
	var clamped_y: float = sign_y * sqrt(maxf(0.0, 1.0 - min_horiz * min_horiz))
	return Vector2(clamped_x, clamped_y).normalized()


static func resolve_thrust_aim(
	world_aim: Vector2,
	registry,
	weapon_type: ResourceData.ResourceType,
	entity: Node = null
) -> Vector2:
	var sign_x: float = horizontal_sign_from_entity(entity, world_aim)
	return clamp_thrust_aim(world_aim, registry, weapon_type, sign_x)


static func apply_ready_pose(body_sprite: Sprite2D, overlay: Sprite2D, registry, weapon_type: ResourceData.ResourceType, aim_dir: Vector2) -> void:
	if body_sprite == null or overlay == null or registry == null:
		return
	var profile: Dictionary = _combat_profile(registry, weapon_type)
	var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
	var kind: int = int(profile.get("attack_kind", AttackKind.SWING_DOWN))
	var entity: Node = body_sprite.get_parent()
	if kind == AttackKind.THRUST:
		aim_dir = resolve_thrust_aim(aim_dir, registry, weapon_type, entity)
	var rot: float
	if kind == AttackKind.THRUST:
		body_sprite.flip_h = aim_dir.x < 0.0
		rot = compute_aim_rotation(body_sprite, aim_dir, tip_deg, 0.0)
		_ensure_weapon_pivot(overlay, profile)
	else:
		sync_swing_body_facing(body_sprite.get_parent(), body_sprite)
		_ensure_weapon_pivot(overlay, profile)
		if use_tuned_swing(profile):
			var targets: Dictionary = compute_tuned_swing_strike_targets(body_sprite, profile)
			rot = targets["ready_rot"]
		else:
			rot = deg_to_rad(_swing_ready_degrees(body_sprite, profile))
	overlay.rotation = rot
	var base_offset: Vector2
	if use_tuned_swing(profile) and profile.get("club_strike_use_keyframes", false):
		var windup_px: Vector2 = profile.get("club_strike_windup_overlay_px", Vector2.ZERO) as Vector2
		base_offset = _offset_px_to_local(body_sprite, windup_px)
	else:
		base_offset = _pose_offset(body_sprite, registry, weapon_type, profile, true)
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
	var profile: Dictionary = _combat_profile(registry, weapon_type)
	if not club_overlay_strike_enabled(profile, weapon_type):
		set_overlay_state(entity, OverlayState.READY)
		if on_strike_anim_done.is_valid():
			on_strike_anim_done.call()
		return
	var strike_duration: float = float(profile.get("strike_duration", 0.12))
	var kind: int = int(profile.get("attack_kind", AttackKind.SWING_DOWN))
	var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
	var ready_base: Vector2 = _pose_offset(body_sprite, registry, weapon_type, profile, true)
	var start_rot: float
	var hit_called := false
	var tween := overlay.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)

	if kind == AttackKind.THRUST:
		aim_dir = resolve_thrust_aim(aim_dir, registry, weapon_type, entity)
		# Match card facing to thrust direction before computing local strike path.
		body_sprite.flip_h = aim_dir.x < 0.0
		start_rot = compute_aim_rotation(body_sprite, aim_dir, tip_deg, 0.0)
		overlay.rotation = start_rot
		var mirror_tex: bool = _overlay_mirror_texture(registry, weapon_type)
		var strike_px: Vector2 = profile.get("strike_offset_px", Vector2.ZERO) as Vector2
		var ready_px: Vector2 = profile.get("ready_offset_px", Vector2.ZERO) as Vector2
		var use_tuned_strike := (
			strike_px.length_squared() > 0.0001
			and ready_px.length_squared() > 0.0001
			and strike_px.distance_to(ready_px) > 2.0
		)
		var windup_frac: float = float(profile.get("thrust_windup_frac", 0.0))
		var lunge_frac: float = float(profile.get("thrust_lunge_frac", 0.52))
		var hold_frac: float = float(profile.get("thrust_hold_frac", 0.0))
		var retract_frac: float = float(profile.get("thrust_retract_frac", -1.0))
		if retract_frac < 0.0:
			retract_frac = maxf(1.0 - windup_frac - lunge_frac - hold_frac, 0.04)
		var windup_t: float = strike_duration * windup_frac
		var lunge_t: float = strike_duration * lunge_frac
		var hold_t: float = strike_duration * hold_frac
		var retract_t: float = strike_duration * retract_frac
		var ready_base_now: Vector2 = _pose_offset(body_sprite, registry, weapon_type, profile, true)
		var ready_pos: Vector2 = _flipped_position(body_sprite, ready_base_now)
		var ready_forward_px: float = float(profile.get("ready_forward_px", 0.0))
		if ready_forward_px > 0.0 and aim_dir.length_squared() > 0.0001:
			ready_pos += _aim_delta_local(body_sprite, aim_dir, ready_forward_px)
		overlay.set_meta("card_overlay_offset", ready_base_now)
		CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, ready_base_now, mirror_tex)
		overlay.position = ready_pos
		if use_tuned_strike:
			var strike_pos: Vector2 = compute_tuned_thrust_strike_pos(
				body_sprite, ready_pos, ready_px, strike_px, aim_dir
			)
			var lunge_trans := _profile_swing_trans(profile, "thrust_lunge_trans", Tween.TRANS_SINE)
			var lunge_ease := _profile_swing_ease(profile, "thrust_lunge_ease", Tween.EASE_IN_OUT)
			if windup_t > 0.001:
				var windup_pos: Vector2 = ready_pos + _aim_delta_local(
					body_sprite, aim_dir, -float(profile.get("thrust_windup_px", 3.0))
				)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(overlay, "position", windup_pos, windup_t)
			tween.set_trans(lunge_trans)
			tween.set_ease(lunge_ease)
			tween.tween_property(overlay, "position", strike_pos, lunge_t)
			tween.tween_callback(func() -> void:
				if not hit_called and on_hit.is_valid():
					hit_called = true
					on_hit.call()
			)
			if hold_t > 0.001:
				tween.tween_interval(hold_t)
			tween.set_trans(_profile_swing_trans(profile, "thrust_recover_trans", Tween.TRANS_SINE))
			tween.set_ease(_profile_swing_ease(profile, "thrust_recover_ease", Tween.EASE_OUT))
			tween.tween_property(overlay, "position", ready_pos, retract_t)
		else:
			var windup_px: float = float(profile.get("thrust_windup_px", 8.0))
			var extend_px: float = float(profile.get("thrust_extend_px", 50.0))
			var lunge_trans := _profile_swing_trans(profile, "thrust_lunge_trans", Tween.TRANS_QUAD)
			var lunge_ease := _profile_swing_ease(profile, "thrust_lunge_ease", Tween.EASE_IN)
			var recover_trans := _profile_swing_trans(profile, "thrust_recover_trans", Tween.TRANS_QUAD)
			var recover_ease := _profile_swing_ease(profile, "thrust_recover_ease", Tween.EASE_IN)
			var windup_pos: Vector2 = ready_pos + _aim_delta_local(body_sprite, aim_dir, -windup_px)
			var extend_pos: Vector2 = ready_pos + _aim_delta_local(body_sprite, aim_dir, extend_px)
			if windup_t > 0.001:
				tween.set_trans(Tween.TRANS_SINE)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(overlay, "position", windup_pos, windup_t)
			tween.set_trans(lunge_trans)
			tween.set_ease(lunge_ease)
			tween.tween_property(overlay, "position", extend_pos, lunge_t)
			tween.tween_callback(func() -> void:
				if not hit_called and on_hit.is_valid():
					hit_called = true
					on_hit.call()
			)
			if hold_t > 0.001:
				tween.tween_interval(hold_t)
			tween.set_trans(recover_trans)
			tween.set_ease(recover_ease)
			tween.tween_property(overlay, "position", ready_pos, retract_t)
	else:
		if uses_club_keyframed_strike(profile):
			_play_club_keyframed_strike(
				overlay, body_sprite, registry, weapon_type, profile,
				strike_duration, tween, func() -> void:
					if not hit_called and on_hit.is_valid():
						hit_called = true
						on_hit.call()
			)
		elif use_tuned_swing(profile):
			_play_tuned_swing_strike(
				overlay, body_sprite, registry, weapon_type, profile, ready_base,
				strike_duration, tween, func() -> void:
					if not hit_called and on_hit.is_valid():
						hit_called = true
						on_hit.call()
			)
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
			elif should_hold_weapon_ready(entity) and not uses_club_keyframed_strike(profile):
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
	# Get idle offset from LimbPresetRegistry if available (tuned value), else fall back to registry default
	var offset_px: Vector2
	if LimbPresetRegistry:
		offset_px = LimbPresetRegistry.get_overlay_offset_idle_px(weapon_type)
	else:
		offset_px = registry.get_tool_overlay_offset_px(weapon_type)
	# ready_offset_px is an absolute position (same as idle format)
	if ready and profile.has("ready_offset_px"):
		offset_px = profile["ready_offset_px"] as Vector2
	return _offset_px_to_local(body_sprite, offset_px)


static func _offset_px_to_local(body_sprite: Sprite2D, offset_px: Vector2) -> Vector2:
	var sx: float = absf(body_sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var mul: float = _display_scale_mul(body_sprite)
	return Vector2(offset_px.x * mul / sx, offset_px.y * mul / sx)


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
	var mul: float = _display_scale_mul(body_sprite)
	return dir * (distance_display_px * mul / sx)


## Swing weapons: rotate around handle (bottom of texture), not center of PNG.
static func _ensure_weapon_pivot(overlay: Sprite2D, profile: Dictionary) -> void:
	if overlay == null or overlay.texture == null:
		return
	var kind: int = int(profile.get("attack_kind", AttackKind.SWING_DOWN))
	overlay.centered = true
	if kind == AttackKind.THRUST:
		overlay.offset = Vector2.ZERO
		return
	var pivot_x_frac: float = clampf(float(profile.get("pivot_x_frac", 0.5)), 0.0, 1.0)
	var pivot_y_frac: float = clampf(float(profile.get("pivot_y_frac", 1.0)), 0.0, 1.0)
	var w: float = float(overlay.texture.get_width()) * absf(overlay.scale.x)
	var h: float = float(overlay.texture.get_height()) * absf(overlay.scale.y)
	# Node origin = texture point (pivot_x_frac, pivot_y_frac) — measured on opaque art for club.
	overlay.offset = Vector2((0.5 - pivot_x_frac) * w, (0.5 - pivot_y_frac) * h)


static func compute_tuned_thrust_strike_pos(
	body_sprite: Sprite2D,
	ready_pos: Vector2,
	ready_px: Vector2,
	strike_px: Vector2,
	aim_dir: Vector2
) -> Vector2:
	## Preset ready/strike offsets are tuned in card space; extend along live aim at the same distance.
	var extend_dist: float = ready_px.distance_to(strike_px)
	if extend_dist < 0.001 or aim_dir.length_squared() < 0.0001:
		return ready_pos
	return ready_pos + _aim_delta_local(body_sprite, aim_dir, extend_dist)


static func _swing_ready_degrees(body_sprite: Sprite2D, profile: Dictionary) -> float:
	var idle_deg: float = float(profile.get("idle_rotation_deg", 0.0))
	var ready_offset_deg: float = float(profile.get("ready_rotation_offset_deg", 40.0))
	var facing: float = _swing_facing_sign(body_sprite)
	# Right: −offset = 10 o'clock. Left: +offset = 2 o'clock. Card-side placement uses body flip_h.
	return idle_deg - ready_offset_deg * facing


static func sync_swing_body_facing(entity: Node, body_sprite: Sprite2D, aim_hint: Vector2 = Vector2.ZERO) -> void:
	if entity == null or body_sprite == null:
		return
	var aim := aim_hint
	if aim.length_squared() < 0.0001 and entity.get("aim_dir") != null:
		var ad: Vector2 = entity.get("aim_dir") as Vector2
		if ad.length_squared() > 0.0001:
			aim = ad
	if aim.length_squared() > 0.0001 and absf(aim.x) > 0.05:
		body_sprite.flip_h = aim.x < 0.0
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


static func _profile_swing_trans(profile: Dictionary, key: String, default: Tween.TransitionType) -> Tween.TransitionType:
	match str(profile.get(key, "")):
		"cubic":
			return Tween.TRANS_CUBIC
		"sine":
			return Tween.TRANS_SINE
		"elastic":
			return Tween.TRANS_ELASTIC
		"quad", "quart":
			return Tween.TRANS_QUAD
		_:
			return default


static func _profile_swing_ease(profile: Dictionary, key: String, default: Tween.EaseType) -> Tween.EaseType:
	match str(profile.get(key, "")):
		"in":
			return Tween.EASE_IN
		"out":
			return Tween.EASE_OUT
		"in_out":
			return Tween.EASE_IN_OUT
		_:
			return default


static func uses_club_keyframed_strike(profile: Dictionary) -> bool:
	return bool(profile.get("club_strike_use_keyframes", false))


static func club_overlay_strike_enabled(profile: Dictionary, weapon_type: ResourceData.ResourceType) -> bool:
	if weapon_type != ResourceData.ResourceType.WOOD:
		return true
	if uses_club_keyframed_strike(profile):
		return true
	var strike_px: Vector2 = profile.get("strike_offset_px", Vector2.ZERO) as Vector2
	return strike_px.length_squared() > 0.0001


static func uses_club_keyframed_strike_for_weapon(registry, weapon_type: ResourceData.ResourceType) -> bool:
	if weapon_type != ResourceData.ResourceType.WOOD or registry == null:
		return false
	return uses_club_keyframed_strike(_combat_profile(registry, weapon_type))


static func use_tuned_swing(profile: Dictionary) -> bool:
	if uses_club_keyframed_strike(profile):
		return true
	var strike_px: Vector2 = profile.get("strike_offset_px", Vector2.ZERO) as Vector2
	var ready_px: Vector2 = profile.get("ready_offset_px", Vector2.ZERO) as Vector2
	return (
		strike_px.length_squared() > 0.0001
		and ready_px.length_squared() > 0.0001
		and strike_px.distance_to(ready_px) > 2.0
	)


static func _keyframe_overlay_pos(body_sprite: Sprite2D, display_px: Vector2) -> Vector2:
	return _flipped_position(body_sprite, _offset_px_to_local(body_sprite, display_px))


static func _signed_rotation_deg(deg: float) -> float:
	return WeaponLimbPreset.signed_rotation_deg(deg)


static func _keyframe_swing_rotation_rad(
	body_sprite: Sprite2D,
	profile: Dictionary,
	rotation_deg: float
) -> float:
	var facing: float = _swing_facing_sign(body_sprite)
	var idle_deg: float = float(profile.get("idle_rotation_deg", 0.0))
	var applied: float = idle_deg + (rotation_deg - idle_deg) * facing
	return deg_to_rad(_signed_rotation_deg(applied))


static func _lerp_swing_rotation_rad(
	from_rad: float,
	to_rad: float,
	t: float,
	facing: float,
	strike_phase: bool
) -> float:
	## Strike: clockwise away from the body (Godot +CW when facing right). Recover reverses.
	var from_deg: float = _signed_rotation_deg(rad_to_deg(from_rad))
	var to_deg: float = _signed_rotation_deg(rad_to_deg(to_rad))
	var delta: float = to_deg - from_deg
	if facing > 0.0:
		if strike_phase:
			if delta <= 0.0:
				delta += 360.0
		elif delta >= 0.0:
			delta -= 360.0
	elif strike_phase:
		if delta >= 0.0:
			delta -= 360.0
	elif delta <= 0.0:
		delta += 360.0
	return deg_to_rad(from_deg + delta * clampf(t, 0.0, 1.0))


static func compute_club_keyframe_strike_targets(
	body_sprite: Sprite2D,
	profile: Dictionary
) -> Dictionary:
	var windup_px: Vector2 = profile.get("club_strike_windup_overlay_px", Vector2.ZERO) as Vector2
	var peak_px: Vector2 = profile.get("club_strike_peak_overlay_px", Vector2.ZERO) as Vector2
	var start_pos: Vector2 = _keyframe_overlay_pos(body_sprite, windup_px)
	var hit_pos: Vector2 = _keyframe_overlay_pos(body_sprite, peak_px)
	var peak_deg: float = float(profile.get("attack_rotation_deg", profile.get("idle_rotation_deg", 0.0)))
	var windup_deg: float = float(
		profile.get(
			"club_strike_windup_rotation_deg",
			_swing_ready_degrees(body_sprite, profile)
		)
	)
	var start_rot: float = _keyframe_swing_rotation_rad(body_sprite, profile, windup_deg)
	var end_rot: float = _keyframe_swing_rotation_rad(body_sprite, profile, peak_deg)
	return {
		"ready_rot": start_rot,
		"end_rot": end_rot,
		"ready_pos": start_pos,
		"hit_pos": hit_pos,
		"windup_overlay_px": windup_px,
		"peak_overlay_px": peak_px,
	}


static func compute_tuned_swing_strike_targets(
	body_sprite: Sprite2D,
	profile: Dictionary
) -> Dictionary:
	if profile.get("club_strike_use_keyframes", false):
		return compute_club_keyframe_strike_targets(body_sprite, profile)
	var facing: float = _swing_facing_sign(body_sprite)
	var sx: float = absf(body_sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var ready_px: Vector2 = profile.get("ready_offset_px", Vector2.ZERO) as Vector2
	var strike_px: Vector2 = profile.get("strike_offset_px", Vector2.ZERO) as Vector2
	var ready_base: Vector2 = _offset_px_to_local(body_sprite, ready_px)
	var strike_base: Vector2 = _offset_px_to_local(body_sprite, strike_px)
	var ready_pos: Vector2 = _flipped_position(body_sprite, ready_base)
	var hit_pos: Vector2 = _flipped_position(body_sprite, strike_base)
	var idle_deg: float = float(profile.get("idle_rotation_deg", 0.0))
	var strike_deg: float = float(profile.get("attack_rotation_deg", idle_deg))
	var ready_rot_deg: float = float(
		profile.get("club_strike_windup_rotation_deg", _swing_ready_degrees(body_sprite, profile))
	)
	var ready_rot: float = _keyframe_swing_rotation_rad(body_sprite, profile, ready_rot_deg)
	var end_rot: float = _keyframe_swing_rotation_rad(body_sprite, profile, strike_deg)
	return {
		"ready_rot": ready_rot,
		"end_rot": end_rot,
		"ready_pos": ready_pos,
		"hit_pos": hit_pos,
	}


static func _lerp_rotation_rad_linear(from_rad: float, to_rad: float, t: float) -> float:
	return from_rad + (to_rad - from_rad) * clampf(t, 0.0, 1.0)


static func _smoothstep01(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _ease_sine_in_out(t: float) -> float:
	return 0.5 - 0.5 * cos(clampf(t, 0.0, 1.0) * PI)


static func _lerp_club_support_hand_smooth(from_px: Vector2, to_px: Vector2, t: float) -> Vector2:
	return from_px.lerp(to_px, _ease_sine_in_out(t))


const CLUB_STRIKE_SUPPORT_META := &"club_strike_support_display_px"
const CLUB_STRIKE_HAND_META := &"club_strike_hand_grip_px"


static func clear_club_strike_pose_meta(entity: Node) -> void:
	if entity == null:
		return
	if entity.has_meta(CLUB_STRIKE_SUPPORT_META):
		entity.remove_meta(CLUB_STRIKE_SUPPORT_META)
	if entity.has_meta(CLUB_STRIKE_HAND_META):
		entity.remove_meta(CLUB_STRIKE_HAND_META)


static func apply_club_keyframe_strike_pose(
	body_sprite: Sprite2D,
	overlay: Sprite2D,
	registry,
	weapon_type: ResourceData.ResourceType,
	profile: Dictionary,
	display_px: Vector2,
	rotation_rad: float,
	hand_grip_px: Vector2 = Vector2.ZERO,
	support_display_px: Vector2 = Vector2.ZERO,
	entity: Node = null
) -> void:
	## Pose-based club strike — whole overlay + grip move together (no legacy pivot arc).
	if body_sprite == null or overlay == null:
		return
	_ensure_weapon_pivot(overlay, profile)
	var mirror_tex: bool = _overlay_mirror_texture(registry, weapon_type)
	var sx: float = absf(body_sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var base_unflipped := Vector2(display_px.x / sx, display_px.y / sx)
	overlay.rotation = rotation_rad
	overlay.set_meta("card_overlay_offset", base_unflipped)
	CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, base_unflipped, mirror_tex)
	if entity != null and is_instance_valid(entity):
		if hand_grip_px.length_squared() > 0.0001:
			entity.set_meta(CLUB_STRIKE_HAND_META, hand_grip_px)
		if support_display_px.length_squared() > 0.0001:
			entity.set_meta(CLUB_STRIKE_SUPPORT_META, support_display_px)


static func _club_keyframe_strike_samples(profile: Dictionary) -> Dictionary:
	return {
		"windup_overlay_px": profile.get("club_strike_windup_overlay_px", Vector2.ZERO) as Vector2,
		"peak_overlay_px": profile.get("club_strike_peak_overlay_px", Vector2.ZERO) as Vector2,
		"windup_hand_px": profile.get("club_strike_windup_hand_px", Vector2.ZERO) as Vector2,
		"peak_hand_px": profile.get("club_strike_peak_hand_px", Vector2.ZERO) as Vector2,
		"windup_support_px": profile.get("club_strike_windup_support_px", Vector2.ZERO) as Vector2,
		"peak_support_px": profile.get("club_strike_peak_support_px", Vector2.ZERO) as Vector2,
		"peak_rotation_deg": float(profile.get("attack_rotation_deg", profile.get("idle_rotation_deg", 0.0))),
		"windup_rotation_deg": float(
			profile.get("club_strike_windup_rotation_deg", profile.get("idle_rotation_deg", 0.0))
		),
	}


static func _play_club_keyframed_strike(
	overlay: Sprite2D,
	body_sprite: Sprite2D,
	registry,
	weapon_type: ResourceData.ResourceType,
	profile: Dictionary,
	strike_duration: float,
	tween: Tween,
	on_hit_frame: Callable
) -> void:
	## Windup keyframe → saved attack peak → windup keyframe. Arms track overlay grip (no swing arc).
	var swing_entity: Node = body_sprite.get_parent() if body_sprite else null
	sync_swing_body_facing(swing_entity, body_sprite)
	var samples: Dictionary = _club_keyframe_strike_samples(profile)
	var windup_px: Vector2 = samples["windup_overlay_px"]
	var peak_px: Vector2 = samples["peak_overlay_px"]
	var start_px: Vector2 = LimbPresetCoords.overlay_display_from_position(body_sprite, overlay)
	if start_px.length_squared() < 0.0001:
		start_px = windup_px
	var start_rot: float = overlay.rotation
	var end_rot: float = _keyframe_swing_rotation_rad(body_sprite, profile, samples["peak_rotation_deg"])
	var profile_windup_rot: float = _keyframe_swing_rotation_rad(
		body_sprite, profile, samples["windup_rotation_deg"]
	)
	var start_hand: Vector2 = samples["windup_hand_px"]
	if swing_entity != null and swing_entity.has_meta(CLUB_STRIKE_HAND_META):
		start_hand = swing_entity.get_meta(CLUB_STRIKE_HAND_META) as Vector2
	elif start_hand.length_squared() < 0.0001:
		start_hand = samples["peak_hand_px"]
	var loop_seam_support: Vector2 = samples["windup_support_px"]
	var peak_support: Vector2 = samples["peak_support_px"]
	var start_support: Vector2 = loop_seam_support
	var strike_frac: float = clampf(float(profile.get("swing_strike_frac", 0.56)), 0.4, 0.72)
	var recover_frac: float = maxf(1.0 - strike_frac, 0.15)
	var strike_t: float = strike_duration * strike_frac
	var recover_t: float = strike_duration * recover_frac
	var strike_trans := _profile_swing_trans(profile, "swing_strike_trans", Tween.TRANS_CUBIC)
	var strike_ease := _profile_swing_ease(profile, "swing_strike_ease", Tween.EASE_IN_OUT)
	var recover_trans := _profile_swing_trans(profile, "swing_recover_trans", Tween.TRANS_CUBIC)
	var recover_ease := _profile_swing_ease(profile, "swing_recover_ease", Tween.EASE_OUT)
	var apply_pose := func(
		display_px: Vector2,
		rot_rad: float,
		hand_px: Vector2,
		support_px: Vector2
	) -> void:
		apply_club_keyframe_strike_pose(
			body_sprite,
			overlay,
			registry,
			weapon_type,
			profile,
			display_px,
			rot_rad,
			hand_px,
			support_px,
			swing_entity
		)
	tween.set_trans(strike_trans)
	tween.set_ease(strike_ease)
	tween.tween_method(
		func(t: float) -> void:
			apply_pose.call(
				start_px.lerp(peak_px, t),
				_lerp_rotation_rad_linear(start_rot, end_rot, t),
				start_hand.lerp(samples["peak_hand_px"], t),
				_lerp_club_support_hand_smooth(start_support, peak_support, t)
			),
		0.0,
		1.0,
		strike_t
	)
	tween.chain().tween_callback(on_hit_frame)
	tween.chain().set_trans(recover_trans)
	tween.chain().set_ease(recover_ease)
	tween.tween_method(
		func(t: float) -> void:
			apply_pose.call(
				peak_px.lerp(windup_px, t),
				_lerp_rotation_rad_linear(end_rot, profile_windup_rot, t),
				samples["peak_hand_px"].lerp(samples["windup_hand_px"], t),
				_lerp_club_support_hand_smooth(peak_support, loop_seam_support, t)
			),
		0.0,
		1.0,
		recover_t
	)
	tween.chain().tween_callback(func() -> void:
		apply_pose.call(
			windup_px,
			profile_windup_rot,
			samples["windup_hand_px"],
			loop_seam_support
		)
		if swing_entity != null and is_instance_valid(swing_entity):
			clear_club_strike_pose_meta(swing_entity)
	)


static func _play_tuned_swing_strike(
	overlay: Sprite2D,
	body_sprite: Sprite2D,
	registry,
	weapon_type: ResourceData.ResourceType,
	profile: Dictionary,
	_ready_base: Vector2,
	strike_duration: float,
	tween: Tween,
	on_hit_frame: Callable,
	force_keyframed: bool = false
) -> void:
	_ensure_weapon_pivot(overlay, profile)
	var mirror_tex: bool = _overlay_mirror_texture(registry, weapon_type)
	var swing_entity: Node = body_sprite.get_parent() if body_sprite else null
	sync_swing_body_facing(swing_entity, body_sprite)
	var targets: Dictionary = compute_tuned_swing_strike_targets(body_sprite, profile)
	var windup_pos: Vector2 = targets["ready_pos"]
	var windup_rot: float = targets["ready_rot"]
	var end_rot: float = targets["end_rot"]
	var hit_pos: Vector2 = targets["hit_pos"]
	var use_keyframes: bool = force_keyframed or uses_club_keyframed_strike(profile)
	var start_pos: Vector2 = overlay.position if use_keyframes else windup_pos
	var start_rot: float = overlay.rotation if use_keyframes else windup_rot
	var meta_px: Vector2 = (
		profile.get("club_strike_windup_overlay_px", profile.get("ready_offset_px", Vector2.ZERO))
		as Vector2
	)
	var start_base_local: Vector2 = _offset_px_to_local(body_sprite, meta_px)
	if use_keyframes:
		var live_px: Vector2 = overlay.get_meta("card_overlay_offset", start_base_local)
		if live_px is Vector2:
			start_base_local = live_px
	var strike_frac: float = clampf(float(profile.get("swing_strike_frac", 0.52)), 0.35, 0.78)
	var recover_frac: float = maxf(1.0 - strike_frac, 0.12)
	if use_keyframes:
		strike_frac = clampf(float(profile.get("swing_strike_frac", 0.56)), 0.4, 0.72)
		recover_frac = maxf(1.0 - strike_frac, 0.15)
	var strike_t: float = strike_duration * strike_frac
	var recover_t: float = strike_duration * recover_frac
	overlay.rotation = start_rot
	if not use_keyframes:
		overlay.set_meta("card_overlay_offset", start_base_local)
		CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, start_base_local, mirror_tex)
		overlay.position = start_pos
	var facing: float = _swing_facing_sign(body_sprite)
	var strike_trans := _profile_swing_trans(profile, "swing_strike_trans", Tween.TRANS_CUBIC)
	var strike_ease := _profile_swing_ease(profile, "swing_strike_ease", Tween.EASE_IN)
	var recover_trans := _profile_swing_trans(profile, "swing_recover_trans", Tween.TRANS_CUBIC)
	var recover_ease := _profile_swing_ease(profile, "swing_recover_ease", Tween.EASE_OUT)
	var peak_meta: Vector2 = Vector2.ZERO
	var windup_meta: Vector2 = Vector2.ZERO
	if use_keyframes:
		peak_meta = _offset_px_to_local(
			body_sprite,
			profile.get("club_strike_peak_overlay_px", profile.get("strike_offset_px", Vector2.ZERO)) as Vector2
		)
		windup_meta = _offset_px_to_local(body_sprite, meta_px)
	tween.set_parallel(true)
	tween.set_trans(strike_trans)
	tween.set_ease(strike_ease)
	tween.tween_method(
		func(t: float) -> void:
			overlay.rotation = _lerp_swing_rotation_rad(start_rot, end_rot, t, facing, true),
		0.0,
		1.0,
		strike_t
	)
	tween.tween_property(overlay, "position", hit_pos, strike_t)
	if use_keyframes:
		tween.tween_method(
			func(t: float) -> void:
				var px: Vector2 = start_base_local.lerp(peak_meta, t)
				overlay.set_meta("card_overlay_offset", px)
				CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, px, mirror_tex),
			0.0,
			1.0,
			strike_t
		)
	tween.chain().tween_callback(on_hit_frame)
	tween.chain().set_parallel(true)
	tween.set_trans(recover_trans)
	tween.set_ease(recover_ease)
	tween.tween_method(
		func(t: float) -> void:
			overlay.rotation = _lerp_swing_rotation_rad(end_rot, windup_rot, t, facing, false),
		0.0,
		1.0,
		recover_t
	)
	tween.tween_property(overlay, "position", windup_pos, recover_t)
	if use_keyframes:
		tween.tween_method(
			func(t: float) -> void:
				var px: Vector2 = peak_meta.lerp(windup_meta, t)
				overlay.set_meta("card_overlay_offset", px)
				CardVisualController.sync_weapon_overlay_flip(body_sprite, overlay, px, mirror_tex),
			0.0,
			1.0,
			recover_t
		)


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
	var windup_trans := _profile_swing_trans(profile, "swing_windup_trans", Tween.TRANS_QUAD)
	var windup_ease := _profile_swing_ease(profile, "swing_windup_ease", Tween.EASE_OUT)
	var strike_trans := _profile_swing_trans(profile, "swing_strike_trans", Tween.TRANS_QUAD)
	var strike_ease := _profile_swing_ease(profile, "swing_strike_ease", Tween.EASE_IN)
	var recover_trans := _profile_swing_trans(profile, "swing_recover_trans", Tween.TRANS_QUAD)
	var recover_ease := _profile_swing_ease(profile, "swing_recover_ease", Tween.EASE_OUT)
	# Wind-up: cock back (short fraction of total time).
	tween.set_parallel(true)
	tween.set_trans(windup_trans)
	tween.set_ease(windup_ease)
	tween.tween_property(overlay, "rotation", windup_rot, windup_t)
	tween.tween_property(overlay, "position", windup_pos, windup_t)
	# Downswing: sweep forward and down.
	tween.chain().set_parallel(true)
	tween.set_trans(strike_trans)
	tween.set_ease(strike_ease)
	tween.tween_property(overlay, "rotation", end_rot, strike_t)
	tween.tween_property(overlay, "position", hit_pos, strike_t)
	tween.chain().tween_callback(on_hit_frame)
	# Return to ready.
	tween.chain().set_parallel(true)
	tween.set_trans(recover_trans)
	tween.set_ease(recover_ease)
	tween.tween_property(overlay, "rotation", ready_rot, recover_t)
	tween.tween_property(overlay, "position", ready_pos, recover_t)
