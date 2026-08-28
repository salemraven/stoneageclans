extends RefCounted
class_name PawnDeathAnimation

## Layered body+head pawn: tip over as one piece; head stays on the neck.

const META_ACTIVE := "pawn_death_anim_active"
const META_POSE_LOCKED := "pawn_death_pose_locked"
const META_FALL_ON_BACK := "pawn_death_fall_on_back"

const BODY_DROP_DURATION := 0.34
const BODY_SETTLE_UP_DURATION := 0.07
const BODY_SETTLE_DOWN_DURATION := 0.12

const BODY_FALL_DEG := 88.0
const FALL_ON_BACK_CHANCE := 0.5
const CORPSE_MODULATE := Color(0.42, 0.42, 0.42, 1.0)


static func is_playing(entity: Node) -> bool:
	return entity != null and is_instance_valid(entity) and entity.get_meta(META_ACTIVE, false)


static func is_pose_locked(entity: Node) -> bool:
	return entity != null and is_instance_valid(entity) and entity.get_meta(META_POSE_LOCKED, false)


static func play(entity: Node, on_complete: Callable = Callable()) -> bool:
	if entity == null or not is_instance_valid(entity):
		return false
	if not PlaceholderCardService or not PlaceholderCardService.uses_layered_body_mannequin(entity):
		return false
	if is_playing(entity) or is_pose_locked(entity):
		return false
	var sprite: Sprite2D = entity.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return false
	var body_visual: Node2D = sprite.get_node_or_null("BodyVisual") as Node2D
	if body_visual == null:
		return false
	if not entity.is_inside_tree():
		return false

	entity.set_meta(META_ACTIVE, true)
	entity.set("_card_bounce_time", 0.0)
	entity.set("_card_bounce_moving", false)

	var foot_y: float = float(entity.get("_card_foot_y")) if entity.get("_card_foot_y") != null else sprite.position.y
	sprite.position.y = roundf(foot_y)

	var overlay: Sprite2D = sprite.get_node_or_null("WeaponOverlay") as Sprite2D
	if overlay:
		if PlaceholderCardService:
			PlaceholderCardService.hide_holdables_on_death(entity)
		else:
			overlay.visible = false

	if body_visual.has_method("prepare_for_death_fall"):
		body_visual.call("prepare_for_death_fall")
	elif body_visual.has_method("set_death_active"):
		body_visual.call("set_death_active", true)

	var fall_sign := -1.0 if sprite.flip_h else 1.0
	var fall_on_back := _roll_fall_on_back(entity)
	entity.set_meta(META_FALL_ON_BACK, fall_on_back)
	var tip_sign := -1.0 if fall_on_back else 1.0
	var target_body_rot := deg_to_rad(BODY_FALL_DEG) * fall_sign * tip_sign
	var sx: float = maxf(absf(sprite.scale.x), 0.001)
	var body_drop_y := 11.0 / sx
	var settle_px := 2.0 / sx

	var pivot_local := Vector2.ZERO
	if body_visual.has_method("get_death_fall_pivot_local"):
		pivot_local = body_visual.call("get_death_fall_pivot_local") as Vector2

	var body_start_pos := body_visual.position

	var fall := entity.create_tween()
	fall.tween_method(
		func(t: float) -> void:
			_apply_fall_pose(body_visual, t, target_body_rot, pivot_local, body_start_pos, body_drop_y, 0.0),
		0.0,
		1.0,
		BODY_DROP_DURATION
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	fall.tween_method(
		func(t: float) -> void:
			_apply_fall_pose(body_visual, 1.0, target_body_rot, pivot_local, body_start_pos, body_drop_y, -settle_px * t),
		0.0,
		1.0,
		BODY_SETTLE_UP_DURATION
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	fall.tween_method(
		func(t: float) -> void:
			_apply_fall_pose(
				body_visual, 1.0, target_body_rot, pivot_local, body_start_pos, body_drop_y, -settle_px + settle_px * t
			),
		0.0,
		1.0,
		BODY_SETTLE_DOWN_DURATION
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	var finish := func() -> void:
		if not is_instance_valid(entity):
			return
		entity.set_meta(META_ACTIVE, false)
		entity.set_meta(META_POSE_LOCKED, true)
		if is_instance_valid(sprite):
			sprite.modulate = CORPSE_MODULATE
		if is_instance_valid(body_visual) and body_visual.has_method("sync_attached_head_transform"):
			body_visual.call("sync_attached_head_transform")
		if on_complete.is_valid():
			on_complete.call()

	fall.finished.connect(finish)

	return true


static func _apply_fall_pose(
	body_visual: Node2D,
	t_rot: float,
	target_rot: float,
	pivot_local: Vector2,
	start_pos: Vector2,
	drop_y: float,
	extra_drop_y: float
) -> void:
	if body_visual == null or not is_instance_valid(body_visual):
		return
	var rot := lerpf(0.0, target_rot, clampf(t_rot, 0.0, 1.0))
	body_visual.rotation = rot
	body_visual.position = (
		start_pos + pivot_local - pivot_local.rotated(rot) + Vector2(0.0, drop_y + extra_drop_y)
	)
	if body_visual.has_method("sync_attached_head_transform"):
		body_visual.call("sync_attached_head_transform")


static func _roll_fall_on_back(entity: Node) -> bool:
	## Deterministic per entity + position so multiplayer clients match server fall direction.
	var ws := 0
	var wgc: Node = entity.get_node_or_null("/root/WorldGenConfig")
	if wgc and wgc.get("world_seed") != null:
		ws = int(wgc.world_seed)
	var entity_id := -1
	if EntityRegistry:
		entity_id = EntityRegistry.get_id(entity)
	if entity_id < 0:
		entity_id = entity.get_instance_id()
	var pos := Vector2.ZERO
	if entity is Node2D:
		pos = (entity as Node2D).global_position
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash([entity_id, int(pos.x), int(pos.y), ws, "pawn_death_fall_back"]))
	return rng.randf() < FALL_ON_BACK_CHANCE
