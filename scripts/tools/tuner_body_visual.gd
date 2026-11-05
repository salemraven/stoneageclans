extends Node2D
class_name TunerBodyVisual

## Layered blank body + head sprites in card texture space (feet at card bottom).

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")

const PartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")
const BODY_DRAW_Z_INDEX := 1
const HEAD_DRAW_Z_INDEX := 2
const WEAPON_DRAW_Z_INDEX := 3
## Style 0 hide tunic, 1 fur cloak, 2 tooth harness, 3 fiber vest.
## Notch is the pin on the garment (image pixels). Width is the opaque span.
const HIDE_STYLE_PATHS := [
	"res://assets/character_cards/clothing/hide.png",
	"res://assets/character_cards/clothing/hide2.png",
	"res://assets/character_cards/clothing/hide3.png",
	"res://assets/character_cards/clothing/fiber1.png",
]
const HIDE_STYLE_NOTCH := [
	Vector2(1524.0, 1049.0),
	Vector2(1173.0, 784.0),
	Vector2(1209.0, 749.0),
	Vector2(1191.0, 727.0),
]
const HIDE_STYLE_OPAQUE_W := [2291.0, 1892.0, 1826.0, 1885.0]
const HIDE3_CLOTHING_STYLE := 2
const BODY_OPAQUE_WIDTH := 343.0
const HIDE_CLOTHING_PATH := "res://assets/character_cards/clothing/hide.png"
## Draw order on the head: nose, brow, hair, then eyes. Eyes stay readable on top.
const EYE_DRAW_Z_INDEX := 4
const NOSE_DRAW_Z_INDEX := 1
const BROW_DRAW_Z_INDEX := 2
const HAIR_FRONT_Z_INDEX := 3
const HAT_DRAW_Z_INDEX := 5
## Source oval is drawn big so it stays smooth when the pawn is zoomed.
const EYE_DOT_TEX_PX := 64
## Width of that oval texture on a normal 56px-tall pawn, before eye_scale_mul.
const RUNTIME_EYE_DIAMETER_DISPLAY_PX := 6.5
const RUNTIME_PAWN_HEIGHT_PX := 56.0
const EYE_DOT_MODULATE := Color(0.12, 0.1, 0.08, 1.0)

@export var body_texture_path: String = PartsRegistry.BLANK_BODY_PATH
@export var head_texture_path: String = PartsRegistry.BLANK_HEAD_PATH

var _layout
var _layer_layout: CharacterCardLayerLayout
var _body_sprite: Sprite2D
var _clothing_sprite: Sprite2D
var _clothing_style: int = 0
var _head_pivot: Node2D
var _head_sprite: Sprite2D
var _hair_sprite: Sprite2D
var _eye_left_sprite: Sprite2D
var _eye_right_sprite: Sprite2D
var _nose_sprite: Sprite2D
## Opaque pixels of the current nose, in sprite-local space. Used for click tests.
var _nose_hit_box := Rect2()
var _brow_sprite: Sprite2D
var _brow_hit_box := Rect2()
static var _cached_eye_dot_texture: Texture2D
static var _cached_pupil_texture: Texture2D
var _head_rest_y := 0.0
var _head_bob_y := 0.0
var _look_right := true
var _body_tex: Texture2D
var _death_active := false
var _body_build_scale := Vector2.ONE
var _head_build_scale := Vector2.ONE
var _crouch_active := false
## Cosmetic blink only. Each body picks its own timing so a crowd does not blink together.
var _blink_rng := RandomNumberGenerator.new()
var _blink_phase := "wait"
var _blink_phase_time := 0.0
var _blink_wait := 1.0
var _blink_openness := 1.0
var _blink_double_left := 0
const BLINK_CLOSE_SEC := 0.07
const BLINK_HOLD_SEC := 0.04
const BLINK_OPEN_SEC := 0.14


func _ready() -> void:
	z_index = 0
	_blink_rng.seed = hash(get_instance_id()) + 17
	_blink_wait = _blink_rng.randf_range(0.7, 1.3)
	_blink_double_left = 1 if _blink_rng.randf() < 0.2 else 0


func _process(delta: float) -> void:
	if _eye_left_sprite == null or _death_active:
		return
	_advance_blink(delta)
	_advance_gaze(delta)
	_apply_eyes_attachment()


func _advance_blink(delta: float) -> void:
	_blink_phase_time += delta
	match _blink_phase:
		"wait":
			if _blink_phase_time < _blink_wait:
				_blink_openness = 1.0
				return
			_start_blink_phase("close")
		"close":
			var t := clampf(_blink_phase_time / BLINK_CLOSE_SEC, 0.0, 1.0)
			_blink_openness = 1.0 - smoothstep(0.0, 1.0, t)
			if _blink_phase_time >= BLINK_CLOSE_SEC:
				_start_blink_phase("hold")
		"hold":
			_blink_openness = 0.0
			if _blink_phase_time >= BLINK_HOLD_SEC:
				_start_blink_phase("open")
		"open":
			var t := clampf(_blink_phase_time / BLINK_OPEN_SEC, 0.0, 1.0)
			_blink_openness = smoothstep(0.0, 1.0, t)
			if _blink_phase_time >= BLINK_OPEN_SEC:
				if _blink_double_left > 0:
					_blink_double_left -= 1
					_blink_wait = 0.12
					_start_blink_phase("wait")
				else:
					_blink_wait = _blink_rng.randf_range(2.4, 5.8)
					_blink_double_left = 1 if _blink_rng.randf() < 0.2 else 0
					_start_blink_phase("wait")
		_:
			_blink_openness = 1.0


func _start_blink_phase(phase: String) -> void:
	_blink_phase = phase
	_blink_phase_time = 0.0


## Pupil offset in the 64px eye picture. Both eyes share it.
var _gaze := Vector2.ZERO
var _gaze_from := Vector2.ZERO
var _gaze_to := Vector2.ZERO
var _gaze_move_time := 0.0
var _gaze_move_dur := 0.6
var _gaze_hold_left := 0.4
var _gaze_demo_time := 0.0
const GAZE_CALM_SPAN_SEC := 8.0
const GAZE_AGRO_SPAN_SEC := 5.0


func _advance_gaze(delta: float) -> void:
	_gaze_demo_time += delta
	if _gaze_hold_left > 0.0:
		_gaze_hold_left -= delta
		return
	_gaze_move_time += delta
	var u := clampf(_gaze_move_time / maxf(_gaze_move_dur, 0.01), 0.0, 1.0)
	_gaze = _gaze_from.lerp(_gaze_to, smoothstep(0.0, 1.0, u))
	if u >= 1.0:
		_pick_next_gaze()


func _gaze_is_agro() -> bool:
	## Tuner has no fight, so it alternates a slow look and a fast one.
	if not _uses_runtime_draw_layers():
		var span := GAZE_CALM_SPAN_SEC + GAZE_AGRO_SPAN_SEC
		return fmod(_gaze_demo_time, span) >= GAZE_CALM_SPAN_SEC
	var root := _card_sprite_root()
	var entity := root.get_parent() if root != null else null
	if entity == null:
		return false
	var agro_value: Variant = entity.get("agro_meter")
	return agro_value != null and float(agro_value) >= 40.0


func gaze_caption() -> String:
	if _gaze_is_agro():
		return "Agro look — pupils dart"
	return "Calm look — slow glance"


func _pick_next_gaze() -> void:
	var agro := _gaze_is_agro()
	_gaze_from = _gaze
	var reach_x := 14.0 if agro else 11.0
	var reach_y := 3.5 if agro else 2.5
	_gaze_to = Vector2(
		_blink_rng.randf_range(-reach_x, reach_x),
		_blink_rng.randf_range(-reach_y, reach_y)
	)
	_gaze_move_dur = _blink_rng.randf_range(0.06, 0.12) if agro else _blink_rng.randf_range(0.45, 0.75)
	_gaze_hold_left = _blink_rng.randf_range(0.05, 0.16) if agro else _blink_rng.randf_range(1.1, 2.6)
	_gaze_move_time = 0.0


func get_layer_layout() -> CharacterCardLayerLayout:
	return _layer_layout


func apply_layout(layout, layer_layout: CharacterCardLayerLayout = null) -> void:
	_layout = layout
	_layer_layout = layer_layout if layer_layout != null else PartsRegistry.get_layout()
	_build_layers()


func apply_layer_layout(layer_layout: CharacterCardLayerLayout) -> void:
	if layer_layout == null:
		return
	var paths_changed := (
		_layer_layout == null
		or layer_layout.body_texture_path != body_texture_path
		or layer_layout.head_texture_path != head_texture_path
		or layer_layout.hair_texture_path != (
			_layer_layout.hair_texture_path if _layer_layout else ""
		)
	)
	_layer_layout = layer_layout
	if paths_changed or _body_sprite == null or _head_sprite == null:
		_build_layers()
	else:
		_build_hair_layer()
		_apply_head_attachment()


func neck_socket_global() -> Vector2:
	if _head_pivot:
		return _head_pivot.global_position
	return global_position


func get_body_sprite() -> Sprite2D:
	return _body_sprite


func get_body_sprite_offset() -> Vector2:
	return _body_sprite.position if _body_sprite else Vector2.ZERO


func apply_tuner_draw_layers() -> void:
	if _body_sprite:
		_body_sprite.z_as_relative = false
		_body_sprite.z_index = BODY_DRAW_Z_INDEX
	if _clothing_sprite:
		_clothing_sprite.z_as_relative = false
		_clothing_sprite.z_index = BODY_DRAW_Z_INDEX
	if _head_pivot:
		_head_pivot.z_as_relative = false
		_head_pivot.z_index = HEAD_DRAW_Z_INDEX
	if _head_sprite:
		_head_sprite.z_as_relative = true
		_head_sprite.z_index = 0
	if _nose_sprite:
		_nose_sprite.z_as_relative = true
		_nose_sprite.z_index = NOSE_DRAW_Z_INDEX
	if _brow_sprite:
		_brow_sprite.z_as_relative = true
		_brow_sprite.z_index = BROW_DRAW_Z_INDEX
	if _eye_left_sprite:
		_eye_left_sprite.z_as_relative = true
		_eye_left_sprite.z_index = EYE_DRAW_Z_INDEX
	if _eye_right_sprite:
		_eye_right_sprite.z_as_relative = true
		_eye_right_sprite.z_index = EYE_DRAW_Z_INDEX
	if _hair_sprite:
		_hair_sprite.z_as_relative = true
		_hair_sprite.z_index = HAIR_FRONT_Z_INDEX


## In-game mannequin: stack body/head/weapon relative to card Sprite Y-sort z_index.
func apply_runtime_draw_layers() -> void:
	z_as_relative = true
	z_index = 0
	if _body_sprite:
		_body_sprite.z_as_relative = true
		_body_sprite.z_index = BODY_DRAW_Z_INDEX
	if _clothing_sprite:
		_clothing_sprite.z_as_relative = true
		_clothing_sprite.z_index = BODY_DRAW_Z_INDEX
	if _head_pivot:
		_head_pivot.z_as_relative = true
		_head_pivot.z_index = HEAD_DRAW_Z_INDEX
	if _head_sprite:
		_head_sprite.z_as_relative = true
		_head_sprite.z_index = 0
	if _nose_sprite:
		_nose_sprite.z_as_relative = true
		_nose_sprite.z_index = NOSE_DRAW_Z_INDEX
	if _brow_sprite:
		_brow_sprite.z_as_relative = true
		_brow_sprite.z_index = BROW_DRAW_Z_INDEX
	if _eye_left_sprite:
		_eye_left_sprite.z_as_relative = true
		_eye_left_sprite.z_index = EYE_DRAW_Z_INDEX
	if _eye_right_sprite:
		_eye_right_sprite.z_as_relative = true
		_eye_right_sprite.z_index = EYE_DRAW_Z_INDEX
	if _hair_sprite:
		_hair_sprite.z_as_relative = true
		_hair_sprite.z_index = HAIR_FRONT_Z_INDEX
	var sprite_root := get_parent() as Node2D
	if sprite_root:
		var weapon := sprite_root.get_node_or_null("WeaponOverlay") as Sprite2D
		if weapon:
			weapon.z_as_relative = true
			weapon.z_index = WEAPON_DRAW_Z_INDEX
			sprite_root.move_child(weapon, -1)


func _uses_runtime_draw_layers() -> bool:
	var sprite_root := get_parent() as Node2D
	if sprite_root == null:
		return false
	var entity := sprite_root.get_parent()
	if entity == null or not PlaceholderCardService:
		return false
	return PlaceholderCardService.uses_layered_body_mannequin(entity)


func _apply_draw_layers() -> void:
	if _uses_runtime_draw_layers():
		apply_runtime_draw_layers()
	else:
		apply_tuner_draw_layers()


func sync_head_draw_transform() -> void:
	if _death_active:
		sync_attached_head_transform()
		return
	if _head_pivot == null or _layer_layout == null or _body_tex == null:
		return
	var neck_local := _neck_local_scaled()
	neck_local.y += _head_bob_y
	_head_pivot.global_position = to_global(neck_local)
	_head_pivot.global_rotation = global_rotation
	if _head_pivot:
		_head_pivot.scale = _head_build_scale
	_apply_layer_facing_flips()
	if _uses_runtime_draw_layers():
		apply_runtime_draw_layers()


## Death fall: keep head on neck without re-sorting draw layers every frame.
func sync_attached_head_transform() -> void:
	if _head_pivot == null or _layer_layout == null or _body_tex == null:
		return
	var neck_local := _neck_local_scaled()
	var neck_global := to_global(neck_local)
	_head_pivot.global_position = neck_global.round()
	_head_pivot.global_rotation = global_rotation
	if _head_pivot:
		_head_pivot.scale = _head_build_scale


func prepare_for_death_fall() -> void:
	_death_active = true
	_head_bob_y = 0.0
	rotation = 0.0
	position = Vector2.ZERO
	sync_attached_head_transform()


func _card_sprite_root() -> Sprite2D:
	return get_parent() as Sprite2D


func _facing_left() -> bool:
	var root := _card_sprite_root()
	return root != null and root.flip_h


func _resolve_head_sprite_flip_h() -> bool:
	## Card Sprite.flip_h is logical facing only — body/head sprites mirror themselves.
	var facing_left := _facing_left()
	## Default travel look (in-game): look_right == (not facing_left) → head mirrors with body.
	if _look_right == (not facing_left):
		return facing_left
	## Idle1 look-around on top of travel facing.
	if not facing_left:
		return not _look_right
	return _look_right


func _apply_layer_facing_flips() -> void:
	var facing_left := _facing_left()
	if _body_sprite:
		_body_sprite.flip_h = facing_left
	_apply_clothing_transform()
	if _head_sprite:
		_head_sprite.flip_h = _resolve_head_sprite_flip_h()
	if _hair_sprite:
		_hair_sprite.flip_h = _resolve_head_sprite_flip_h()
	_apply_eyes_attachment()
	_apply_nose_attachment()
	_apply_brow_attachment()
	_apply_hair_attachment()


func _resolved_hair_attach_local_px() -> Vector2:
	if _layer_layout == null:
		return Vector2.ZERO
	return PartsRegistry.resolved_hair_attach_local_px(_layer_layout, _facing_left())


func layer_facing_in_sync() -> bool:
	if _body_sprite == null:
		return true
	var head_flip := _resolve_head_sprite_flip_h()
	var hair_ok := _hair_sprite == null or _hair_sprite.flip_h == head_flip
	return _body_sprite.flip_h == _facing_left() and (
		_head_sprite == null or _head_sprite.flip_h == head_flip
	) and hair_ok


func _apply_facing(look_right: bool) -> void:
	_look_right = look_right
	_apply_layer_facing_flips()


func _body_pivot_local() -> Vector2:
	return get_body_sprite_offset()


func _apply_torso_sway(sway_rad: float) -> void:
	var pivot := _body_pivot_local()
	rotation = sway_rad
	position = pivot - pivot.rotated(sway_rad)


## Nearest point on the visible torso silhouette for a shoulder/arm pin stem.
func torso_surface_global_for(world_point: Vector2) -> Vector2:
	if _body_sprite == null or _body_tex == null:
		return world_point
	var center := _body_sprite.global_position
	var half_w := float(_body_tex.get_width()) * 0.5 * absf(_body_sprite.global_scale.x)
	var half_h := float(_body_tex.get_height()) * 0.5 * absf(_body_sprite.global_scale.y)
	if half_w < 1.0 or half_h < 1.0:
		return center
	var local := world_point - center
	var dir := local.normalized()
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT
	var inset := 0.82
	var edge := Vector2(dir.x * half_w * inset, dir.y * half_h * inset)
	if dir.y < -0.15:
		edge.y = minf(edge.y, -half_h * 0.28)
	return center + edge


func set_neck_socket_from_global(global_pos: Vector2) -> void:
	if _layer_layout == null or _body_tex == null:
		return
	var local_pos := to_local(global_pos)
	var center := Vector2(_body_tex.get_width(), _body_tex.get_height()) * 0.5
	_layer_layout.body_neck_socket_px = local_pos + center - _layer_layout.body_offset_px
	_apply_head_attachment()


func hair_attach_global() -> Vector2:
	if _head_pivot == null:
		return global_position
	return _head_pivot.to_global(_resolved_hair_attach_local_px())


func set_hair_attach_from_global(global_pos: Vector2) -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	var local_pos := _head_pivot.to_local(global_pos)
	if _facing_left():
		local_pos.x = -local_pos.x
	_layer_layout.hair_attach_local_px = local_pos
	_apply_hair_attachment()


func has_hair_layer() -> bool:
	return _hair_sprite != null and _hair_sprite.texture != null


func get_hair_sprite() -> Sprite2D:
	return _hair_sprite


func is_facing_right() -> bool:
	return not _facing_left()


func set_walk_state(moving: bool, bounce_time: float, direction: int, motion_scale: float = 1.0) -> void:
	if _death_active:
		return
	_apply_facing(direction > 0)
	var tilt_sign := -1.0 if direction < 0 else 1.0
	var bob: float = _layout.head_bob_local() if _layout else 2.5
	var m: float = clampf(motion_scale, 0.15, 1.0)
	if moving:
		var hop := CardVisualController.walk_bounce_hop_factor(bounce_time)
		var hop_dir := signf(sin(bounce_time))
		if hop_dir == 0.0:
			hop_dir = tilt_sign
		_apply_torso_sway(hop * hop_dir * 0.11 * tilt_sign * m)
		_head_bob_y = -CardVisualController.walk_bounce_hop_factor(bounce_time - 0.28) * bob * m
		sync_head_draw_transform()
	else:
		clear_motion_state()


func set_idle_state(head_offset_y: float, sway_rad: float, look_right: bool = true) -> void:
	_head_bob_y = head_offset_y
	_apply_facing(look_right)
	_apply_torso_sway(sway_rad)
	sync_head_draw_transform()


func set_gather_state(bend_rad: float, head_forward_local: float) -> void:
	_apply_torso_sway(bend_rad)
	_head_bob_y = head_forward_local
	sync_head_draw_transform()


## Low crouch — torso bent, head tucked (tall-grass hide).
func set_crouch_state(active: bool, moving: bool = false, bounce_time: float = 0.0, direction: int = 1) -> void:
	if _death_active:
		return
	if not active:
		if _crouch_active:
			_crouch_active = false
			clear_motion_state()
		return
	_crouch_active = true
	var tilt_sign := -1.0 if direction < 0 else 1.0
	_apply_facing(direction > 0)
	var bend: float = 0.48 if moving else 0.42
	_apply_torso_sway(bend * tilt_sign)
	var tuck: float = 14.0
	var sink: float = 10.0
	if _layout:
		tuck = _layout.display_to_local(20.0)
		sink = _layout.display_to_local(12.0)
	if moving:
		var hop := CardVisualController.walk_bounce_hop_factor(bounce_time) * 0.35
		sink += hop * 2.0
		_head_bob_y = tuck + hop * 3.0
	else:
		_head_bob_y = tuck
	position.y = sink
	scale = Vector2(0.94, 0.86)
	sync_head_draw_transform()


func is_crouch_active() -> bool:
	return _crouch_active


func clear_motion_state() -> void:
	if _death_active:
		return
	_crouch_active = false
	rotation = 0.0
	position = Vector2.ZERO
	scale = Vector2.ONE
	_head_bob_y = 0.0
	var sprite_root := _card_sprite_root()
	_look_right = not sprite_root.flip_h if sprite_root else true
	sync_head_draw_transform()


func set_death_active(on: bool) -> void:
	_death_active = on


func is_death_active() -> bool:
	return _death_active


## Bottom-center of body art — pivot for tipping over onto the ground.
func apply_body_build_scale(body_scale: Vector2, head_scale: Vector2 = Vector2.ONE) -> void:
	_body_build_scale = body_scale
	_head_build_scale = head_scale
	_apply_body_build_to_sprites()
	if _death_active:
		sync_attached_head_transform()
	else:
		sync_head_draw_transform()


func _apply_body_build_to_sprites() -> void:
	if _body_sprite == null or _layer_layout == null or _body_tex == null:
		return
	var half_h := float(_body_tex.get_height()) * 0.5
	var sy: float = _body_build_scale.y
	_body_sprite.scale = _body_build_scale
	_body_sprite.position = _layer_layout.body_offset_px + Vector2(0.0, -(sy - 1.0) * half_h)
	## Hair / hats live on HeadPivot — they follow head_scale, not body_scale.
	## Hide is a sibling so skin tint on the body does not dye the tunic, but it copies body scale.
	_apply_clothing_transform()
	if _head_pivot:
		_head_pivot.scale = _head_build_scale
	if _head_sprite:
		_head_sprite.scale = Vector2.ONE


func _neck_local_scaled() -> Vector2:
	var unscaled := PartsRegistry.head_pivot_on_body_local(_body_tex, _layer_layout)
	if _facing_left():
		unscaled.x = -unscaled.x
	if _body_sprite == null or _layer_layout == null:
		return unscaled
	var body_off: Vector2 = _layer_layout.body_offset_px
	return _body_sprite.position + (unscaled - body_off) * _body_sprite.scale


func get_death_fall_pivot_local() -> Vector2:
	if _body_sprite == null or _body_tex == null:
		return Vector2.ZERO
	var half_h := float(_body_tex.get_height()) * 0.5
	return _body_sprite.position + Vector2(0.0, half_h * _body_sprite.scale.y)


func _build_layers() -> void:
	var sprite_root := get_parent() as Node2D
	_clear_sprite_head_pivots(sprite_root)

	while get_child_count() > 0:
		var old: Node = get_child(0)
		remove_child(old)
		old.free()
	_body_sprite = null
	_clothing_sprite = null

	if _layer_layout == null:
		_layer_layout = PartsRegistry.get_layout()

	body_texture_path = _layer_layout.body_texture_path
	head_texture_path = _layer_layout.head_texture_path

	_body_tex = _load_texture(body_texture_path)
	var head_tex := _load_texture(head_texture_path)
	if _body_tex == null:
		push_warning("TunerBodyVisual: missing body texture at %s" % body_texture_path)
		return

	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = _body_tex
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.centered = true
	_body_sprite.position = _layer_layout.body_offset_px
	add_child(_body_sprite)
	_build_clothing_layer()

	if head_tex == null:
		push_warning("TunerBodyVisual: missing head texture at %s" % head_texture_path)
		_apply_clothing_transform()
		_apply_draw_layers()
		return

	_head_pivot = Node2D.new()
	_head_pivot.name = "HeadPivot"
	if sprite_root:
		sprite_root.add_child(_head_pivot)
	else:
		add_child(_head_pivot)

	_head_sprite = Sprite2D.new()
	_head_sprite.name = "HeadSprite"
	_head_sprite.texture = head_tex
	_head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_head_sprite.centered = true
	_head_pivot.add_child(_head_sprite)
	_build_nose_layer()
	_build_brow_layer()
	_build_eyes_layer()
	_build_hair_layer()
	_apply_body_build_to_sprites()
	_apply_head_attachment()
	_apply_draw_layers()


func _build_clothing_layer() -> void:
	_clothing_sprite = null
	var tex := _load_texture(HIDE_CLOTHING_PATH)
	if tex == null:
		return
	_clothing_sprite = Sprite2D.new()
	_clothing_sprite.name = "HideClothing"
	_clothing_sprite.texture = tex
	_clothing_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_clothing_sprite.centered = true
	_clothing_sprite.modulate = Color.WHITE
	add_child(_clothing_sprite)


## Pin the tunic's neck opening to the body neck, then add clothing_offset_px.
func _apply_clothing_transform() -> void:
	if _clothing_sprite == null or _body_sprite == null or _body_tex == null or _layer_layout == null:
		return
	var hide_tex := _clothing_sprite.texture
	if hide_tex == null:
		return
	var offset := _clothing_pin_offset_px() + _active_clothing_offset()
	if _facing_left():
		offset.x = -offset.x
	var body_scale := _body_sprite.scale
	var fit := _clothing_fit_scale()
	_clothing_sprite.scale = body_scale * fit
	_clothing_sprite.position = _body_sprite.position + Vector2(offset.x * body_scale.x, offset.y * body_scale.y)
	_clothing_sprite.flip_h = _body_sprite.flip_h


func _clothing_fit_scale() -> float:
	var mul := 1.0
	if _layer_layout != null:
		mul = _active_clothing_scale_mul()
	var width := float(HIDE_STYLE_OPAQUE_W[_clothing_style])
	if width < 1.0:
		width = 2291.0
	return (BODY_OPAQUE_WIDTH / width) * mul


func set_clothing_style(index: int) -> void:
	var n := HIDE_STYLE_PATHS.size()
	if n <= 0:
		return
	var style := posmod(index, n)
	_clothing_style = style
	if _clothing_sprite == null:
		return
	var tex := _load_texture(str(HIDE_STYLE_PATHS[style]))
	if tex:
		_clothing_sprite.texture = tex
	if style != HIDE3_CLOTHING_STYLE:
		_clothing_sprite.material = null
	_apply_clothing_transform()


func set_clothing_scale_mul(mul: float) -> void:
	if _layer_layout == null:
		return
	var clamped := maxf(0.05, mul)
	match _clothing_style:
		3:
			_layer_layout.clothing4_scale_mul = clamped
		2:
			_layer_layout.clothing3_scale_mul = clamped
		1:
			_layer_layout.clothing2_scale_mul = clamped
		_:
			_layer_layout.clothing_scale_mul = clamped
	_apply_clothing_transform()


func clothing_scale_mul() -> float:
	return _active_clothing_scale_mul()


func clothing_style() -> int:
	return _clothing_style


func clothing_receipt_fields() -> Dictionary:
	var style := _clothing_style
	var path := str(HIDE_STYLE_PATHS[style]) if style >= 0 and style < HIDE_STYLE_PATHS.size() else ""
	return {
		"clothing_style": style,
		"clothing_texture": path,
		"clothing_offset_px": _active_clothing_offset(),
		"clothing_scale_mul": _active_clothing_scale_mul(),
	}


func _active_clothing_offset() -> Vector2:
	if _layer_layout == null:
		return Vector2.ZERO
	match _clothing_style:
		3:
			return _layer_layout.clothing4_offset_px
		2:
			return _layer_layout.clothing3_offset_px
		1:
			return _layer_layout.clothing2_offset_px
		_:
			return _layer_layout.clothing_offset_px


func _active_clothing_scale_mul() -> float:
	if _layer_layout == null:
		return 1.0
	match _clothing_style:
		3:
			return maxf(0.05, _layer_layout.clothing4_scale_mul)
		2:
			return maxf(0.05, _layer_layout.clothing3_scale_mul)
		1:
			return maxf(0.05, _layer_layout.clothing2_scale_mul)
		_:
			return maxf(0.05, _layer_layout.clothing_scale_mul)


func set_head_and_hair_visible(show: bool) -> void:
	if _head_pivot:
		_head_pivot.visible = show


func set_hair_layer_visible(show: bool) -> void:
	if _hair_sprite:
		_hair_sprite.visible = show


func set_clothing_layer_visible(show: bool) -> void:
	if _clothing_sprite:
		_clothing_sprite.visible = show


func _clothing_pin_offset_px() -> Vector2:
	var hide_tex := _clothing_sprite.texture if _clothing_sprite else null
	if hide_tex == null or _body_tex == null or _layer_layout == null:
		return Vector2.ZERO
	var hide_center := Vector2(float(hide_tex.get_width()), float(hide_tex.get_height())) * 0.5
	var notch: Vector2 = HIDE_STYLE_NOTCH[_clothing_style]
	var notch_local := (notch - hide_center) * _clothing_fit_scale()
	var body_center := Vector2(float(_body_tex.get_width()), float(_body_tex.get_height())) * 0.5
	return _layer_layout.body_neck_socket_px - body_center - notch_local


func set_clothing_center_from_global(global_pos: Vector2) -> void:
	if _clothing_sprite == null or _body_sprite == null or _layer_layout == null:
		return
	var parent := _clothing_sprite.get_parent() as Node2D
	if parent == null:
		return
	var desired := parent.to_local(global_pos)
	var body_scale := _body_sprite.scale
	if absf(body_scale.x) < 0.0001 or absf(body_scale.y) < 0.0001:
		return
	var unscaled := Vector2(
		(desired.x - _body_sprite.position.x) / body_scale.x,
		(desired.y - _body_sprite.position.y) / body_scale.y
	)
	if _facing_left():
		unscaled.x = -unscaled.x
	var slide := unscaled - _clothing_pin_offset_px()
	match _clothing_style:
		3:
			_layer_layout.clothing4_offset_px = slide
		2:
			_layer_layout.clothing3_offset_px = slide
		1:
			_layer_layout.clothing2_offset_px = slide
		_:
			_layer_layout.clothing_offset_px = slide
	_apply_clothing_transform()


func clothing_hit_rect_global() -> Rect2:
	if _clothing_sprite == null or _clothing_sprite.texture == null:
		return Rect2()
	return _clothing_sprite.get_global_transform() * _clothing_sprite.get_rect()


func _build_hair_layer() -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	if _hair_sprite != null:
		_hair_sprite.queue_free()
		_hair_sprite = null
	var path := _layer_layout.hair_texture_path
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var hair_tex := _load_texture(path)
	if hair_tex == null:
		return
	_hair_sprite = Sprite2D.new()
	_hair_sprite.name = "HairFront"
	_hair_sprite.texture = hair_tex
	_hair_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hair_sprite.centered = true
	_head_pivot.add_child(_hair_sprite)
	_head_pivot.move_child(_hair_sprite, -1)
	_apply_hair_attachment()


func _clear_sprite_head_pivots(sprite_root: Node2D) -> void:
	if sprite_root == null:
		return
	var stale: Array[Node] = []
	for child in sprite_root.get_children():
		if child.name == "HeadPivot":
			stale.append(child)
	for node in stale:
		node.free()
	_head_pivot = null
	_head_sprite = null
	_eye_left_sprite = null
	_eye_right_sprite = null
	_nose_sprite = null
	_brow_sprite = null


func _apply_head_attachment() -> void:
	if _head_pivot == null or _head_sprite == null or _layer_layout == null or _body_tex == null:
		return
	var head_tex := _head_sprite.texture
	_head_rest_y = PartsRegistry.head_pivot_on_body_local(_body_tex, _layer_layout).y
	_head_sprite.position = PartsRegistry.head_sprite_offset_local(head_tex, _layer_layout)
	sync_head_draw_transform()
	_apply_eyes_attachment()
	_apply_nose_attachment()
	_apply_brow_attachment()
	_apply_hair_attachment()


func _build_nose_layer() -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	var stale := _head_pivot.get_node_or_null("Nose")
	if stale:
		stale.queue_free()
	_nose_sprite = null
	var tex := _load_texture(_layer_layout.nose_texture_path)
	if tex == null:
		return
	_nose_sprite = Sprite2D.new()
	_nose_sprite.name = "Nose"
	_nose_sprite.texture = tex
	_nose_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_nose_sprite.centered = true
	_head_pivot.add_child(_nose_sprite)
	_cache_nose_hit_box()
	_apply_nose_attachment()


func _apply_nose_attachment() -> void:
	if _nose_sprite == null or _layer_layout == null:
		return
	var pos := _layer_layout.nose_local_px
	if _facing_left():
		pos.x = -pos.x
	_nose_sprite.position = pos
	_nose_sprite.flip_h = _facing_left()
	_nose_sprite.scale = Vector2.ONE * nose_scale_mul()


func set_nose_texture_path(path: String) -> void:
	if _layer_layout == null or path.is_empty():
		return
	_layer_layout.nose_texture_path = path
	var tex := _load_texture(path)
	if tex == null:
		return
	if _nose_sprite == null:
		_build_nose_layer()
		return
	_nose_sprite.texture = tex
	_cache_nose_hit_box()
	_apply_nose_attachment()


func nose_texture_path() -> String:
	if _layer_layout == null:
		return ""
	return _layer_layout.nose_texture_path


func set_nose_scale_mul(mul: float) -> void:
	if _layer_layout == null:
		return
	_layer_layout.nose_scale_mul = maxf(0.05, mul)
	_apply_nose_attachment()


func nose_scale_mul() -> float:
	if _layer_layout == null:
		return 1.0
	return maxf(0.05, _layer_layout.nose_scale_mul)


func nose_global() -> Vector2:
	return _nose_sprite.global_position if _nose_sprite else global_position


func set_nose_from_global(global_pos: Vector2) -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	var local := _head_pivot.to_local(global_pos)
	if _facing_left():
		local.x = -local.x
	_layer_layout.nose_local_px = local
	_apply_nose_attachment()


func nose_contains_global(global_pos: Vector2) -> bool:
	if _nose_sprite == null or _nose_sprite.texture == null:
		return false
	var local := _nose_sprite.to_local(global_pos)
	var box := _nose_hit_box
	if box.size == Vector2.ZERO and _nose_sprite.texture != null:
		var tex := _nose_sprite.texture
		var center := Vector2(tex.get_width(), tex.get_height()) * 0.5
		box = Rect2(Vector2.ZERO, Vector2(tex.get_width(), tex.get_height()))
		box.position -= center
	if _nose_sprite.flip_h:
		local.x = -local.x
	return box.grow(12.0).has_point(local)


func _cache_nose_hit_box() -> void:
	_nose_hit_box = Rect2()
	if _nose_sprite == null or _nose_sprite.texture == null:
		return
	var img := _nose_sprite.texture.get_image()
	if img == null:
		return
	var used := img.get_used_rect()
	if used.size == Vector2i.ZERO:
		return
	var center := Vector2(img.get_width(), img.get_height()) * 0.5
	_nose_hit_box = Rect2(Vector2(used.position) - center, Vector2(used.size))


func _build_brow_layer() -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	var stale := _head_pivot.get_node_or_null("Brow")
	if stale:
		stale.queue_free()
	_brow_sprite = null
	var tex := _load_texture(_layer_layout.brow_texture_path)
	if tex == null:
		return
	_brow_sprite = Sprite2D.new()
	_brow_sprite.name = "Brow"
	_brow_sprite.texture = tex
	_brow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_brow_sprite.centered = true
	_head_pivot.add_child(_brow_sprite)
	_cache_brow_hit_box()
	_apply_brow_attachment()


func _apply_brow_attachment() -> void:
	if _brow_sprite == null or _layer_layout == null:
		return
	var pos := _layer_layout.brow_local_px
	if _facing_left():
		pos.x = -pos.x
	_brow_sprite.position = pos
	_brow_sprite.flip_h = _facing_left()
	_brow_sprite.scale = Vector2.ONE * brow_scale_mul()


func set_brow_texture_path(path: String) -> void:
	if _layer_layout == null or path.is_empty():
		return
	_layer_layout.brow_texture_path = path
	var tex := _load_texture(path)
	if tex == null:
		return
	if _brow_sprite == null:
		_build_brow_layer()
		return
	_brow_sprite.texture = tex
	_cache_brow_hit_box()
	_apply_brow_attachment()


func brow_texture_path() -> String:
	if _layer_layout == null:
		return ""
	return _layer_layout.brow_texture_path


func set_brow_scale_mul(mul: float) -> void:
	if _layer_layout == null:
		return
	_layer_layout.brow_scale_mul = maxf(0.05, mul)
	_apply_brow_attachment()


func brow_scale_mul() -> float:
	if _layer_layout == null:
		return 1.0
	return maxf(0.05, _layer_layout.brow_scale_mul)


func brow_global() -> Vector2:
	return _brow_sprite.global_position if _brow_sprite else global_position


func set_brow_from_global(global_pos: Vector2) -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	var local := _head_pivot.to_local(global_pos)
	if _facing_left():
		local.x = -local.x
	_layer_layout.brow_local_px = local
	_apply_brow_attachment()


func brow_contains_global(global_pos: Vector2) -> bool:
	if _brow_sprite == null or _brow_sprite.texture == null:
		return false
	var local := _brow_sprite.to_local(global_pos)
	var box := _brow_hit_box
	if box.size == Vector2.ZERO:
		var tex := _brow_sprite.texture
		var center := Vector2(tex.get_width(), tex.get_height()) * 0.5
		box = Rect2(Vector2.ZERO, Vector2(tex.get_width(), tex.get_height()))
		box.position -= center
	if _brow_sprite.flip_h:
		local.x = -local.x
	return box.grow(12.0).has_point(local)


func _cache_brow_hit_box() -> void:
	_brow_hit_box = Rect2()
	if _brow_sprite == null or _brow_sprite.texture == null:
		return
	var img := _brow_sprite.texture.get_image()
	if img == null:
		return
	var used := img.get_used_rect()
	if used.size == Vector2i.ZERO:
		return
	var center := Vector2(img.get_width(), img.get_height()) * 0.5
	_brow_hit_box = Rect2(Vector2(used.position) - center, Vector2(used.size))


func _build_eyes_layer() -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	for node_name in ["EyeLeft", "EyeRight"]:
		var stale := _head_pivot.get_node_or_null(node_name)
		if stale:
			stale.queue_free()
	_eye_left_sprite = null
	_eye_right_sprite = null
	var tex := _eye_dot_texture()
	if tex == null:
		return
	_eye_left_sprite = _make_eye_sprite("EyeLeft", tex)
	_eye_right_sprite = _make_eye_sprite("EyeRight", tex)
	_add_pupil(_eye_left_sprite)
	_add_pupil(_eye_right_sprite)
	_head_pivot.add_child(_eye_left_sprite)
	_head_pivot.add_child(_eye_right_sprite)
	_apply_eyes_attachment()


func _make_eye_sprite(node_name: String, tex: Texture2D) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.name = node_name
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.centered = true
	spr.modulate = Color.WHITE
	return spr


func _eye_dot_texture() -> Texture2D:
	if _cached_eye_dot_texture != null:
		return _cached_eye_dot_texture
	var size := EYE_DOT_TEX_PX
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(size - 1) * 0.5, float(size - 1) * 0.5)
	var radius_x := float(size) * 0.46
	var radius_y := float(size) * 0.30
	for y in size:
		for x in size:
			var p := Vector2(float(x), float(y))
			var oval := Vector2((p.x - center.x) / radius_x, (p.y - center.y) / radius_y)
			var edge := 1.0 - oval.length()
			if edge <= 0.0:
				continue
			var white_a := clampf(edge * radius_y, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, white_a))
	_cached_eye_dot_texture = ImageTexture.create_from_image(img)
	return _cached_eye_dot_texture


func _resolved_eye_dot_scale() -> Vector2:
	var mul := maxf(0.05, _layer_layout.eye_scale_mul) if _layer_layout else 1.0
	## Size the oval in the head's own pixels, same as the nose and brow.
	## A 56px pawn then shows a 6.5px eye. Babies and the big tuner mannequin
	## keep that same fraction of the head, instead of a fixed screen size.
	var body_h := float(_body_tex.get_height()) if _body_tex != null else RUNTIME_PAWN_HEIGHT_PX
	if body_h < 1.0:
		body_h = RUNTIME_PAWN_HEIGHT_PX
	var pawn_scale := RUNTIME_PAWN_HEIGHT_PX / body_h
	var head_px := RUNTIME_EYE_DIAMETER_DISPLAY_PX / pawn_scale
	var aspect := 1.0
	if _layer_layout:
		aspect = clampf(_layer_layout.eye_aspect, 0.75, 1.35)
	if aspect < 0.01:
		aspect = 1.0
	var base := (head_px / float(EYE_DOT_TEX_PX)) * mul
	return Vector2(base * aspect, base / aspect)


func _apply_eyes_attachment() -> void:
	if _layer_layout == null:
		return
	var scale := _resolved_eye_dot_scale()
	var shut := 1.0 - clampf(_blink_openness, 0.0, 1.0)
	scale.y *= lerpf(1.0, 0.08, shut)
	var skin := _body_sprite.modulate if _body_sprite else Color(0.72, 0.52, 0.38, 1.0)
	var lid := smoothstep(0.35, 0.9, shut)
	var eye_color := Color.WHITE.lerp(Color(skin.r, skin.g, skin.b, 1.0), lid)
	if _eye_left_sprite:
		_eye_left_sprite.position = PartsRegistry.resolved_eye_local_px(
			_layer_layout, true, _facing_left()
		)
		_eye_left_sprite.scale = scale
		_eye_left_sprite.modulate = eye_color
	if _eye_right_sprite:
		_eye_right_sprite.position = PartsRegistry.resolved_eye_local_px(
			_layer_layout, false, _facing_left()
		)
		_eye_right_sprite.scale = scale
		_eye_right_sprite.modulate = eye_color
	_place_pupils()


func _add_pupil(eye: Sprite2D) -> void:
	var pupil := Sprite2D.new()
	pupil.name = "Pupil"
	pupil.texture = _pupil_texture()
	pupil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pupil.centered = true
	pupil.scale = Vector2.ONE * (26.0 / 16.0)
	pupil.z_as_relative = true
	pupil.z_index = 1
	eye.add_child(pupil)


func _pupil_texture() -> Texture2D:
	if _cached_pupil_texture != null:
		return _cached_pupil_texture
	var size := 16
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(size - 1) * 0.5, float(size - 1) * 0.5)
	var radius := float(size) * 0.42
	for y in size:
		for x in size:
			var d := Vector2(float(x), float(y)).distance_to(center)
			var a := clampf(radius + 0.8 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_cached_pupil_texture = ImageTexture.create_from_image(img)
	return _cached_pupil_texture


func _place_pupils() -> void:
	for eye in [_eye_left_sprite, _eye_right_sprite]:
		if eye == null:
			continue
		var pupil := eye.get_node_or_null("Pupil") as Sprite2D
		if pupil:
			pupil.position = _gaze
			pupil.visible = _blink_openness > 0.2
			var tint := Color(0.05, 0.04, 0.03, 1.0)
			if _layer_layout:
				tint = _layer_layout.pupil_color
			pupil.modulate = tint


func set_eye_scale_mul(mul: float) -> void:
	if _layer_layout == null:
		return
	_layer_layout.eye_scale_mul = maxf(0.05, mul)
	_apply_eyes_attachment()


func eye_scale_mul() -> float:
	if _layer_layout == null:
		return 1.0
	return _layer_layout.eye_scale_mul


func eye_left_global() -> Vector2:
	return _eye_left_sprite.global_position if _eye_left_sprite else global_position


func eye_right_global() -> Vector2:
	return _eye_right_sprite.global_position if _eye_right_sprite else global_position


func set_eye_left_from_global(global_pos: Vector2) -> void:
	_store_eye_from_global(true, global_pos)


func set_eye_right_from_global(global_pos: Vector2) -> void:
	_store_eye_from_global(false, global_pos)


func _store_eye_from_global(left_eye: bool, global_pos: Vector2) -> void:
	if _head_pivot == null or _layer_layout == null:
		return
	var local := _head_pivot.to_local(global_pos)
	if _facing_left():
		local.x = -local.x
	if left_eye:
		_layer_layout.eye_left_local_px = local
	else:
		_layer_layout.eye_right_local_px = local
	_apply_eyes_attachment()


func apply_preview_skin(skin: Color) -> void:
	if _body_sprite:
		_body_sprite.modulate = skin
	if _head_sprite:
		_head_sprite.modulate = skin
	if _nose_sprite:
		_nose_sprite.modulate = skin
	if _brow_sprite:
		_brow_sprite.modulate = skin


func eyes_receipt_fields() -> Dictionary:
	if _layer_layout == null:
		return {}
	return {
		"eye_left_local_px": _layer_layout.eye_left_local_px,
		"eye_right_local_px": _layer_layout.eye_right_local_px,
		"eye_scale_mul": _layer_layout.eye_scale_mul,
		"nose_texture": _layer_layout.nose_texture_path,
		"nose_local_px": _layer_layout.nose_local_px,
		"nose_scale_mul": _layer_layout.nose_scale_mul,
		"brow_texture": _layer_layout.brow_texture_path,
		"brow_local_px": _layer_layout.brow_local_px,
		"brow_scale_mul": _layer_layout.brow_scale_mul,
	}


func _apply_hair_attachment() -> void:
	if _hair_sprite == null or _layer_layout == null:
		return
	var hair_tex := _hair_sprite.texture
	if hair_tex == null:
		return
	_hair_sprite.position = PartsRegistry.hair_sprite_offset_local(
		hair_tex, _layer_layout, _facing_left()
	)
	if _head_sprite:
		_hair_sprite.flip_h = _head_sprite.flip_h


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded: Texture2D = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Texture2D
		if loaded:
			return loaded
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			return ImageTexture.create_from_image(img)
	return null
