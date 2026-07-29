extends CharacterBody2D
class_name LimbTunerRig

## Minimal player-like rig for LimbTuner — same node layout as Player for shared combat/arm code.

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const TunerWalkPreview = preload("res://scripts/tools/tuner_walk_preview.gd")
const TunerIdlePreview = preload("res://scripts/tools/tuner_idle_preview.gd")
const TunerGatherPreview = preload("res://scripts/tools/tuner_gather_preview.gd")
const GatherArmMotion = preload("res://scripts/systems/gather_arm_motion.gd")
const WalkArmSwing = preload("res://scripts/systems/walk_arm_swing.gd")
const TUNER_ARM1_Z_INDEX := 0
const TUNER_BODY_Z_INDEX := 1
const TUNER_HEAD_Z_INDEX := 2
const TUNER_ARM2_Z_INDEX := 3
const TunerMannequinLayoutScript = preload("res://scripts/tools/tuner_mannequin_layout.gd")
const MannequinAnchorResolver = preload("res://scripts/systems/mannequin_anchor_resolver.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")
const LimbAnimationBakerScript = preload("res://scripts/tools/limb_animation_baker.gd")

## Tuner handle 3 — grip on overlay texture (normalized Y from top). Spear = shaft midpoint.
const WEAPON_HANDLE_Y_FRAC := PlaceholderCardRegistry.SPEAR_GRIP_TEXTURE_NY

var aim_dir: Vector2 = Vector2(1.0, 0.0)
var body_card_index: int = 1
var weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.SPEAR

@onready var sprite: Sprite2D = $Sprite
@onready var body_visual: Node2D = $Sprite/BodyVisual
@onready var weapon_overlay: Sprite2D = $Sprite/WeaponOverlay
@onready var combat_component: CombatComponent = $CombatComponent
@onready var arm_controller: ProceduralArmController = $ProceduralArmController

var _anchor_foot_y: float = -64.0
var _mannequin_layout
var _walk := TunerWalkPreview.new()
var _idle := TunerIdlePreview.new()
var _gather := TunerGatherPreview.new()
var _registry = PlaceholderCardRegistry.new()
var _last_overlay_base := Vector2.ZERO
var _preview_idle_mode := true
var _preview_gather_mode := false
var _walk_preview_preset: WeaponLimbPreset = null
var _walk_preview_grip_mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE


func _ready() -> void:
	process_priority = -1
	add_to_group("player")
	if combat_component:
		combat_component.initialize(self)
		refresh_weapon_combat_timing()
	if arm_controller:
		arm_controller.body_card_id = "clansmen_1"
		arm_controller.force_show_arms = true
		arm_controller.initialize_tuner_arm_layers()
		_sync_tuner_arm_process()
	_apply_tuner_arm_draw_order()
	_setup_mannequin_anchor()
	_show_weapon_overlay()


func _apply_tuner_arm_draw_order() -> void:
	if arm_controller and arm_controller.use_tuner_arm_layers:
		arm_controller.call("_ensure_tuner_draw_containers")
	if body_visual and body_visual.has_method("apply_tuner_draw_layers"):
		body_visual.call("apply_tuner_draw_layers")


## ProceduralArmController defaults to set_process(false); tuner must tick IK every frame.
func _sync_tuner_arm_process() -> void:
	if arm_controller:
		arm_controller.set_process(true)


func _process(delta: float) -> void:
	_update_motion_preview(delta)


func set_walk_preview_context(
	preset: WeaponLimbPreset,
	grip_mode: WeaponLimbPreset.TunerAnimMode
) -> void:
	_walk_preview_preset = preset
	_walk_preview_grip_mode = grip_mode


func sync_spear_overlay_motion_preview(
	preset: WeaponLimbPreset,
	grip_mode: WeaponLimbPreset.TunerAnimMode,
	walk_swing: bool,
	gather_motion: bool
) -> void:
	## Spear: overlay (art) is source of truth — sway it, then yellow pin reads grip on art.
	if (
		preset == null
		or weapon_type != ResourceData.ResourceType.SPEAR
		or weapon_overlay == null
		or sprite == null
		or not weapon_overlay.visible
	):
		return
	_apply_overlay_walk_bounce(walk_swing or gather_motion)
	if walk_swing:
		_apply_spear_overlay_motion_delta(preset, grip_mode, true, false)
	elif gather_motion:
		_apply_spear_overlay_motion_delta(preset, grip_mode, false, true)


func _apply_spear_overlay_motion_delta(
	preset: WeaponLimbPreset,
	grip_mode: WeaponLimbPreset.TunerAnimMode,
	walk_swing: bool,
	gather_motion: bool
) -> void:
	var shoulder_global := shoulder_global_from_preset(preset)
	var rest_grip_global := hand_grip_global_from_preset(preset, grip_mode)
	var target_grip_global := rest_grip_global
	if walk_swing:
		target_grip_global = _apply_walk_swing_arc(shoulder_global, rest_grip_global, true)
	elif gather_motion:
		target_grip_global = hand_grip_global_with_gather_motion(preset, grip_mode)
	var delta_global := target_grip_global - rest_grip_global
	if delta_global.length_squared() > 0.0001:
		weapon_overlay.global_position += delta_global


func set_preview_playing(on: bool) -> void:
	_idle.set_playing(on and _preview_idle_mode)
	_gather.set_playing(on and _preview_gather_mode)


func is_gather_preview_playing() -> bool:
	return _gather.playing if _gather else false


func get_gather_cycle_phase() -> float:
	return _gather.cycle_phase() if _gather else 0.0


func is_preview_playing() -> bool:
	return _idle.playing


func get_idle_variant_id() -> String:
	return _idle.get_variant_id() if _idle else TunerIdlePreview.VARIANT_BASE


func get_idle_arm2_raise_blend() -> float:
	return _idle.arm2_raise_blend()


func set_preview_idle_variant(variant_id: String) -> void:
	if _idle:
		_idle.set_variant(variant_id)


func set_preview_idle_mode(on: bool) -> void:
	_preview_idle_mode = on
	if not on:
		_idle.set_playing(false)


func set_preview_gather_mode(on: bool) -> void:
	_preview_gather_mode = on
	if not on:
		_gather.set_playing(false)


func get_walk_swing_phase() -> float:
	return _walk.swing_phase() if _walk else 0.0


func get_walk_bounce_time() -> float:
	return _walk.bounce_time if _walk else 0.0


func is_walking() -> bool:
	return _walk.is_moving()


func hand_grip_global_with_walk_swing(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	return _apply_walk_swing_arc(
		shoulder_global_from_preset(preset),
		hand_grip_global_from_preset(preset, mode),
		true
	)


func support_hand_global_with_walk_swing(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	return _apply_walk_swing_arc(
		support_shoulder_global_from_preset(preset),
		support_hand_global_for_mode(preset, mode),
		false
	)


func _apply_walk_swing_arc(shoulder_global: Vector2, rest_hand_global: Vector2, dominant: bool) -> Vector2:
	if sprite == null or not _walk.is_moving():
		return rest_hand_global
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var shoulder_local := to_local(shoulder_global)
	var hand_local := to_local(rest_hand_global)
	var rest_offset := (hand_local - shoulder_local) / sx
	var travel_sign := float(_walk.direction) if _walk.direction != 0 else 1.0
	var swung_offset := WalkArmSwing.swing_hand_local_offset(
		rest_offset,
		_walk.swing_phase(),
		dominant,
		travel_sign,
		weapon_type
	) * sx
	return to_global(shoulder_local + swung_offset)


func hand_grip_global_with_gather_motion(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	return _apply_gather_hand_motion(
		shoulder_global_from_preset(preset),
		hand_grip_global_from_preset(preset, mode),
		preset,
		mode,
		true,
		_gather.cycle_phase()
	)


func support_hand_global_with_gather_motion(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	return _apply_gather_hand_motion(
		support_shoulder_global_from_preset(preset),
		support_hand_global_for_mode(preset, mode),
		preset,
		mode,
		false,
		_gather.cycle_phase()
	)


func gather1_pull_hand_global_from_preset(
	preset: WeaponLimbPreset,
	dominant: bool
) -> Vector2:
	if preset == null:
		return global_position
	var grip_px := preset.resolve_gather1_pull_hand(dominant)
	if not has_weapon_overlay():
		return LimbPresetCoords.body_global_from_display(sprite, grip_px)
	return LimbPresetCoords.overlay_grip_global(weapon_overlay, grip_px)


func _apply_gather_hand_motion(
	shoulder_global: Vector2,
	reach_hand_global: Vector2,
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	dominant: bool,
	cycle_phase: float
) -> Vector2:
	if sprite == null or not _gather.playing:
		return reach_hand_global
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var shoulder_local := to_local(shoulder_global)
	var reach_local := to_local(reach_hand_global)
	var reach_offset := (reach_local - shoulder_local) / sx
	var idle_global := (
		hand_grip_global_from_preset(preset, WeaponLimbPreset.TunerAnimMode.IDLE)
		if dominant
		else support_hand_global_for_mode(preset, WeaponLimbPreset.TunerAnimMode.IDLE)
	)
	var idle_local := to_local(idle_global)
	var idle_offset := (idle_local - shoulder_local) / sx
	var motion_offset: Vector2
	var arm_work := GatherArmMotion.arm_work_phase(cycle_phase)
	if arm_work >= 0.0 and preset != null and preset.has_gather1_pull_pose():
		var pull_global := gather1_pull_hand_global_from_preset(preset, dominant)
		var pull_local := to_local(pull_global)
		var pull_offset := (pull_local - shoulder_local) / sx
		motion_offset = GatherArmMotion.hand_offset_between_keyframes(
			reach_offset, pull_offset, arm_work, dominant
		) * sx
	else:
		motion_offset = GatherArmMotion.blend_idle_to_reach_offset(
			idle_offset, reach_offset, cycle_phase
		) * sx
	var max_reach_len := maxf(
		idle_offset.length(),
		reach_offset.length()
	) * sx * (1.0 + GatherArmMotion.reach_slack_ratio(dominant))
	if preset != null and preset.has_gather1_pull_pose():
		var pull_global := gather1_pull_hand_global_from_preset(preset, dominant)
		var pull_local := to_local(pull_global)
		var pull_offset := (pull_local - shoulder_local) / sx
		max_reach_len = maxf(
			max_reach_len,
			pull_offset.length() * sx * (1.0 + GatherArmMotion.reach_slack_ratio(dominant))
		)
	if motion_offset.length_squared() > 0.0001 and motion_offset.length() > max_reach_len:
		motion_offset = motion_offset.normalized() * max_reach_len
	return to_global(shoulder_local + motion_offset)


func set_walk_direction(dir: int) -> void:
	_walk.set_direction(dir)


func get_walk_direction() -> int:
	return _walk.direction


func get_walk_phase() -> float:
	return _walk.walk_phase


func refresh_weapon_combat_timing() -> void:
	if combat_component:
		combat_component.refresh_attack_sprite_sheet()


func refresh_weapon_overlay() -> void:
	_show_weapon_overlay()


func reload_mannequin_from_layout() -> void:
	if sprite == null:
		return
	_mannequin_layout = TunerMannequinLayoutScript.from_registry(_registry, body_card_index)
	sprite.scale = Vector2.ONE * _mannequin_layout.sprite_scale
	_anchor_foot_y = _mannequin_layout.foot_y
	sprite.position = Vector2(0.0, _anchor_foot_y)
	var layout := CharacterCardPartsRegistry.reload_layout()
	if body_visual and body_visual.has_method("apply_layer_layout"):
		body_visual.call("apply_layer_layout", layout)


func reset_head_layout_to_defaults() -> void:
	CharacterCardPartsRegistry.reload_layout()
	reload_mannequin_from_layout()


func get_equipped_weapon_type() -> ResourceData.ResourceType:
	return weapon_type


func _get_cursor_aim_direction() -> Vector2:
	var mp := get_global_mouse_position()
	var delta := mp - global_position
	if delta.length_squared() > 4.0:
		var raw := delta.normalized()
		if weapon_type == ResourceData.ResourceType.SPEAR and _registry:
			return WeaponOverlayCombat.resolve_thrust_aim(raw, _registry, weapon_type, self)
		return raw
	return aim_dir


func _setup_mannequin_anchor() -> void:
	if sprite == null:
		return
	_mannequin_layout = TunerMannequinLayoutScript.from_registry(_registry, body_card_index)
	sprite.texture = null
	sprite.region_enabled = false
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.scale = Vector2.ONE * _mannequin_layout.sprite_scale
	_anchor_foot_y = _mannequin_layout.foot_y
	sprite.position = Vector2(0.0, _anchor_foot_y)
	set_meta("card_index", body_card_index)
	if body_visual and body_visual.has_method("apply_layout"):
		body_visual.call("apply_layout", _mannequin_layout)


func get_layer_layout() -> CharacterCardLayerLayout:
	if body_visual and body_visual.has_method("get_layer_layout"):
		return body_visual.call("get_layer_layout") as CharacterCardLayerLayout
	return CharacterCardPartsRegistry.get_layout()


func neck_socket_global() -> Vector2:
	if body_visual and body_visual.has_method("neck_socket_global"):
		return body_visual.call("neck_socket_global")
	return global_position


func set_neck_socket_from_global(global_pos: Vector2) -> void:
	if body_visual and body_visual.has_method("set_neck_socket_from_global"):
		body_visual.call("set_neck_socket_from_global", global_pos)


func torso_pin_global_for_shoulder(shoulder_global: Vector2) -> Vector2:
	if body_visual and body_visual.has_method("torso_surface_global_for"):
		return body_visual.call("torso_surface_global_for", shoulder_global)
	return shoulder_global


func _shoulder_body_local_from_display_px(display_px: Vector2) -> Vector2:
	return MannequinAnchorResolver.shoulder_body_local_from_display_px(sprite, body_visual, display_px)


func _shoulder_display_px_from_body_local(body_local: Vector2) -> Vector2:
	if body_visual == null or sprite == null:
		return Vector2.ZERO
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var body_offset := Vector2.ZERO
	if body_visual.has_method("get_body_sprite_offset"):
		body_offset = body_visual.call("get_body_sprite_offset")
	var in_sprite_local := body_local + body_offset
	var rig_local := sprite.position + Vector2(in_sprite_local.x * sx, in_sprite_local.y * sx)
	return LimbPresetCoords.body_display_from_global(sprite, to_global(rig_local))


func _shoulder_anchor_global(body_local: Vector2) -> Vector2:
	return MannequinAnchorResolver.shoulder_anchor_global(body_visual, body_local)


func shoulder_global_from_preset(preset: WeaponLimbPreset) -> Vector2:
	if preset == null:
		return global_position
	return MannequinAnchorResolver.shoulder_global_from_display(sprite, body_visual, preset.shoulder_offset_px)


func set_shoulder_from_global(preset: WeaponLimbPreset, global_pos: Vector2) -> void:
	if preset == null:
		return
	if body_visual == null:
		preset.shoulder_offset_px = LimbPresetCoords.body_display_from_global(sprite, global_pos)
		return
	var body_local := _body_local_from_shoulder_global(global_pos)
	preset.shoulder_offset_px = _shoulder_display_px_from_body_local(body_local)


## Deterministic pose for animation bake (no delta) — body + head + weapon layers only.
func apply_bake_sample(clip: String, phase: float) -> void:
	if sprite == null:
		return
	phase = clampf(phase, 0.0, 1.0)
	_idle.set_playing(false)
	_gather.set_playing(false)
	_walk.set_direction(0)
	match clip:
		LimbAnimationBakerScript.CLIP_WALK:
			sprite.flip_h = false
			_walk.set_direction(1)
			_walk.bounce_time = phase * TAU
			_walk.walk_phase = phase * TAU
			sprite.position.y = roundf(
				_anchor_foot_y + sin(_walk.bounce_time) * PlaceholderCardRegistry.WALK_BOUNCE_AMPLITUDE
			)
			if body_visual and body_visual.has_method("set_walk_state"):
				body_visual.call("set_walk_state", true, _walk.bounce_time, 1)
			_sync_body_visual_head_draw()
		LimbAnimationBakerScript.CLIP_GATHER1:
			_gather.cycle_time = phase / GatherArmMotion.CYCLE_SPEED
			var gather_phase := GatherArmMotion.cycle_phase_from_time(_gather.cycle_time)
			var body_bend := GatherArmMotion.body_bend_rad(gather_phase)
			var head_fwd := _display_to_local(GatherArmMotion.head_forward_display_px(gather_phase))
			sprite.position.y = _anchor_foot_y + head_fwd * 0.35
			if body_visual and body_visual.has_method("set_gather_state"):
				body_visual.call("set_gather_state", body_bend, head_fwd)
			_sync_body_visual_head_draw()
		LimbAnimationBakerScript.CLIP_IDLE1:
			_idle.set_variant(TunerIdlePreview.VARIANT_ID)
			_apply_bake_idle_sample(phase)
		_:
			_idle.set_variant(TunerIdlePreview.VARIANT_BASE)
			_apply_bake_idle_sample(phase)


func _apply_bake_idle_sample(phase: float) -> void:
	_idle.breath_time = phase * LimbAnimationBakerScript.IDLE_CYCLE_SEC
	var body_amp := _display_to_local(TunerIdlePreview.BODY_BOUNCE_DISPLAY_PX)
	var head_amp := _display_to_local(TunerIdlePreview.HEAD_BOB_DISPLAY_PX)
	var weapon_amp := _display_to_local(TunerIdlePreview.WEAPON_EXTRA_BOUNCE_DISPLAY_PX)
	var breath := _idle.breath_time
	sprite.position.y = _anchor_foot_y + sin(breath * TunerIdlePreview.BREATH_SPEED) * body_amp
	var head_bob := sin(breath * TunerIdlePreview.BREATH_SPEED * 1.15 - 0.4) * head_amp
	var body_sway := sin(breath * TunerIdlePreview.SWAY_SPEED) * TunerIdlePreview.BODY_SWAY_RAD
	var look_right := _idle.head_look_right() if _idle.get_variant_id() == TunerIdlePreview.VARIANT_ID else true
	if body_visual and body_visual.has_method("set_idle_state"):
		body_visual.call("set_idle_state", head_bob, body_sway, look_right)
	var bounce_y := sin(breath * TunerIdlePreview.BREATH_SPEED - 0.55) * weapon_amp * 0.65
	if weapon_overlay != null and sprite != null and weapon_overlay.visible:
		var base_offset: Vector2 = weapon_overlay.get_meta("card_overlay_offset", _last_overlay_base)
		if base_offset != Vector2.ZERO:
			_last_overlay_base = base_offset
		var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
		CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_offset, mirror_tex, bounce_y)
	_sync_body_visual_head_draw()


func sync_bake_weapon_overlay(
	preset: WeaponLimbPreset,
	grip_mode: WeaponLimbPreset.TunerAnimMode,
	walk_swing: bool,
	gather_motion: bool
) -> void:
	if preset == null or not has_weapon_overlay():
		return
	if weapon_type == ResourceData.ResourceType.SPEAR:
		sync_spear_overlay_motion_preview(preset, grip_mode, walk_swing, gather_motion)
		return
	if not uses_weapon_grip_anchor_hand():
		return
	var grip_global: Vector2
	if gather_motion:
		grip_global = hand_grip_global_with_gather_motion(preset, grip_mode)
	elif walk_swing:
		grip_global = hand_grip_global_with_walk_swing(preset, grip_mode)
	else:
		grip_global = dominant_grip_global_from_preset(preset, grip_mode)
	align_weapon_overlay_to_hand_grip_global(preset, grip_global, grip_mode)


func _update_motion_preview(delta: float) -> void:
	if sprite == null:
		return
	_walk.tick(delta)
	var moving := _walk.is_moving()
	if moving:
		if sprite:
			sprite.flip_h = _walk.direction < 0
		_walk.bounce_time = CardVisualController.tick_walk_bounce(
			sprite, _anchor_foot_y, _walk.bounce_time, true, delta
		)
		if body_visual and body_visual.has_method("set_walk_state"):
			body_visual.call("set_walk_state", true, _walk.bounce_time, _walk.direction)
		_sync_overlay_walk_bounce(true)
		_sync_body_visual_head_draw()
		return
	if _gather.playing and _preview_gather_mode:
		_gather.tick(delta)
		var phase := _gather.cycle_phase()
		var body_bend := GatherArmMotion.body_bend_rad(phase)
		var head_fwd := _display_to_local(GatherArmMotion.head_forward_display_px(phase))
		sprite.position.y = _anchor_foot_y + head_fwd * 0.35
		if body_visual and body_visual.has_method("set_gather_state"):
			body_visual.call("set_gather_state", body_bend, head_fwd)
		_sync_body_visual_head_draw()
		return
	if _preview_gather_mode:
		_apply_gather_edit_hold_pose()
		return
	if _idle.playing and _preview_idle_mode:
		_idle.tick(delta)
		var body_amp := _display_to_local(TunerIdlePreview.BODY_BOUNCE_DISPLAY_PX)
		var head_amp := _display_to_local(TunerIdlePreview.HEAD_BOB_DISPLAY_PX)
		var weapon_amp := _display_to_local(TunerIdlePreview.WEAPON_EXTRA_BOUNCE_DISPLAY_PX)
		sprite.position.y = _anchor_foot_y + _idle.body_bounce_offset(body_amp)
		if body_visual and body_visual.has_method("set_idle_state"):
			body_visual.call(
				"set_idle_state",
				_idle.head_bob_offset(head_amp),
				_idle.body_sway_rad(),
				_idle.head_look_right()
			)
		_sync_overlay_idle_bounce(weapon_amp)
		_sync_body_visual_head_draw()
		return
	_idle.reset()
	_walk.bounce_time = CardVisualController.tick_walk_bounce(
		sprite, _anchor_foot_y, _walk.bounce_time, false, delta
	)
	if body_visual and body_visual.has_method("clear_motion_state"):
		body_visual.call("clear_motion_state")
	elif body_visual and body_visual.has_method("set_walk_state"):
		body_visual.call("set_walk_state", false, 0.0, 1)
	_sync_body_visual_head_draw()
	_sync_overlay_walk_bounce(false)


func _sync_body_visual_head_draw() -> void:
	if body_visual and body_visual.has_method("sync_head_draw_transform"):
		body_visual.call("sync_head_draw_transform")


func _apply_gather_edit_hold_pose() -> void:
	if sprite == null:
		return
	var phase := GatherArmMotion.EDIT_HOLD_PHASE
	var body_bend := GatherArmMotion.body_bend_rad(phase)
	var head_fwd := _display_to_local(GatherArmMotion.head_forward_display_px(phase))
	sprite.position.y = _anchor_foot_y + head_fwd * 0.35
	if body_visual and body_visual.has_method("set_gather_state"):
		body_visual.call("set_gather_state", body_bend, head_fwd)
	_sync_body_visual_head_draw()


func _display_to_local(display_px: float) -> float:
	if _mannequin_layout:
		return _mannequin_layout.display_to_local(display_px)
	return display_px


func _sync_overlay_idle_bounce(amplitude_local: float) -> void:
	if weapon_overlay == null or sprite == null or not weapon_overlay.visible:
		return
	var base_offset: Vector2 = weapon_overlay.get_meta("card_overlay_offset", _last_overlay_base)
	if base_offset != Vector2.ZERO:
		_last_overlay_base = base_offset
	var bounce_y := _idle.weapon_bounce_offset(amplitude_local)
	var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_offset, mirror_tex, bounce_y)


func _update_walk_preview(delta: float) -> void:
	_update_motion_preview(delta)


func _sync_overlay_walk_bounce(moving: bool) -> void:
	if weapon_overlay == null or sprite == null or not weapon_overlay.visible:
		return
	## Spear walk/gather sway is applied in sync_spear_overlay_motion_preview (grip on art).
	if weapon_type == ResourceData.ResourceType.SPEAR and moving:
		return
	_apply_overlay_walk_bounce(moving)


func _apply_overlay_walk_bounce(moving: bool) -> void:
	if weapon_overlay == null or sprite == null or not weapon_overlay.visible:
		return
	var base_offset: Vector2 = weapon_overlay.get_meta("card_overlay_offset", _last_overlay_base)
	if base_offset != Vector2.ZERO:
		_last_overlay_base = base_offset
	var bounce_y := 0.0
	if moving:
		bounce_y = CardVisualController.weapon_overlay_walk_bounce_offset_y(_walk.bounce_time, true)
	var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_offset, mirror_tex, bounce_y)


func _show_weapon_overlay() -> void:
	if weapon_overlay == null or sprite == null:
		return
	if weapon_type == ResourceData.ResourceType.NONE:
		weapon_overlay.visible = false
		weapon_overlay.texture = null
		return
	var tex: Texture2D = null
	if _registry.TOOL_OVERLAY_PATHS.has(weapon_type):
		var path: String = _registry.TOOL_OVERLAY_PATHS[weapon_type]
		if ResourceLoader.exists(path):
			tex = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Texture2D
	if tex == null:
		tex = _registry.get_tool_overlay(weapon_type)
	if tex == null:
		weapon_overlay.visible = false
		return
	weapon_overlay.texture = tex
	var overlay_scale: float = _registry.get_tool_overlay_scale(weapon_type)
	weapon_overlay.scale = Vector2(overlay_scale, overlay_scale)
	weapon_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_overlay.visible = true
	WeaponOverlayCombat.set_overlay_state(self, WeaponOverlayCombat.OverlayState.IDLE)


func has_weapon_overlay() -> bool:
	return weapon_type != ResourceData.ResourceType.NONE and weapon_overlay != null and weapon_overlay.visible


func apply_preset_overlay_for_mode(preset: WeaponLimbPreset, mode: WeaponLimbPreset.TunerAnimMode) -> void:
	if preset == null or not has_weapon_overlay():
		return
	match mode:
		WeaponLimbPreset.TunerAnimMode.ATTACK:
			if preset.attack_pose_inherits_idle():
				apply_preset_overlay_idle(preset, WeaponLimbPreset.TunerAnimMode.IDLE)
			else:
				apply_preset_overlay_ready(preset, Vector2(1.0, 0.0))
		WeaponLimbPreset.TunerAnimMode.WALK, WeaponLimbPreset.TunerAnimMode.WALK1:
			apply_preset_overlay_walk(preset, mode)
		WeaponLimbPreset.TunerAnimMode.GATHER1:
			apply_preset_overlay_walk(preset, mode)
		_:
			apply_preset_overlay_idle(preset, mode)


func apply_preset_overlay_walk(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.WALK
) -> void:
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	var idle_deg: float = preset.idle_rotation_deg
	if absf(idle_deg) < 0.001:
		idle_deg = float(profile.get("idle_rotation_deg", 0.0))
	_apply_tuner_overlay_pose(
		preset.resolve_overlay_for_mode(mode),
		deg_to_rad(idle_deg),
		WeaponOverlayCombat.OverlayState.IDLE
	)


func apply_preset_overlay_idle(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE
) -> void:
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	var idle_deg: float = preset.idle_rotation_deg
	if absf(idle_deg) < 0.001:
		idle_deg = float(profile.get("idle_rotation_deg", 0.0))
	_apply_tuner_overlay_pose(
		preset.resolve_overlay_for_mode(mode),
		deg_to_rad(idle_deg),
		WeaponOverlayCombat.OverlayState.IDLE
	)


func apply_preset_overlay_ready(preset: WeaponLimbPreset, aim: Vector2) -> void:
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	aim_dir = aim.normalized() if aim.length_squared() > 0.0001 else Vector2(1.0, 0.0)
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	var kind: int = int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN))
	var rot: float
	if kind == WeaponOverlayCombat.AttackKind.THRUST:
		if sprite:
			sprite.flip_h = aim_dir.x < 0.0
		var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
		rot = WeaponOverlayCombat.compute_aim_rotation(sprite, aim_dir, tip_deg, 0.0)
	else:
		WeaponOverlayCombat.sync_swing_body_facing(self, sprite)
		rot = deg_to_rad(WeaponOverlayCombat._swing_ready_degrees(sprite, profile))
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	_apply_tuner_overlay_pose(
		preset.resolve_overlay_for_mode(WeaponLimbPreset.TunerAnimMode.ATTACK),
		rot,
		WeaponOverlayCombat.OverlayState.READY
	)


func apply_tuner_spear_windup_overlay(preset: WeaponLimbPreset, aim: Vector2) -> void:
	## Horizontal ready pose using windup overlay row (tuner can edit before Save all).
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	aim_dir = aim.normalized() if aim.length_squared() > 0.0001 else Vector2(1.0, 0.0)
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	if sprite:
		sprite.flip_h = aim_dir.x < 0.0
	var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
	var rot := WeaponOverlayCombat.compute_aim_rotation(sprite, aim_dir, tip_deg, 0.0)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	_apply_tuner_overlay_pose(
		preset.resolve_tuner_spear_attack_overlay_px(),
		rot,
		WeaponOverlayCombat.OverlayState.READY
	)


func _apply_tuner_overlay_pose(display_px: Vector2, rotation_rad: float, overlay_state: int) -> void:
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var base_unflipped := Vector2(display_px.x / sx, display_px.y / sx)
	weapon_overlay.rotation = rotation_rad
	weapon_overlay.set_meta("card_overlay_offset", base_unflipped)
	_last_overlay_base = base_unflipped
	var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	var bounce_y := 0.0
	if _walk.is_moving():
		bounce_y = CardVisualController.weapon_overlay_walk_bounce_offset_y(_walk.bounce_time, true)
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_unflipped, mirror_tex, bounce_y)
	WeaponOverlayCombat.set_overlay_state(self, overlay_state)


func display_px_from_overlay_position() -> Vector2:
	return LimbPresetCoords.overlay_display_from_position(sprite, weapon_overlay)


## Keep card_overlay_offset meta in sync after global_position drags — otherwise
## _sync_overlay_walk_bounce resets the club back to the stale preset every frame.
func _commit_overlay_meta_from_current_pose() -> void:
	if weapon_overlay == null or sprite == null:
		return
	var display_px := display_px_from_overlay_position()
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var base_unflipped := Vector2(display_px.x / sx, display_px.y / sx)
	weapon_overlay.set_meta("card_overlay_offset", base_unflipped)
	_last_overlay_base = base_unflipped


func _apply_overlay_display_for_mode(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> void:
	if preset == null:
		return
	var display_px := display_px_from_overlay_position()
	preset.set_overlay_for_mode(mode, display_px)
	_commit_overlay_meta_from_current_pose()


func display_px_from_global(global_pos: Vector2) -> Vector2:
	return LimbPresetCoords.body_display_from_global(sprite, global_pos)


func set_overlay_from_display_px(display_px: Vector2) -> void:
	if sprite == null or weapon_overlay == null:
		return
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var base_unflipped := Vector2(display_px.x / sx, display_px.y / sx)
	weapon_overlay.set_meta("card_overlay_offset", base_unflipped)
	_last_overlay_base = base_unflipped
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_unflipped, true)


func move_weapon_overlay_global(global_pos: Vector2) -> Vector2:
	return move_weapon_handle_anchor_global(global_pos)


func _ensure_overlay_pivot() -> void:
	if weapon_overlay == null or sprite == null:
		return
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)


func _texture_frac_to_overlay_local(nx: float, ny: float) -> Vector2:
	if weapon_overlay == null or weapon_overlay.texture == null:
		return Vector2.ZERO
	var tex := weapon_overlay.texture
	var draw_size := Vector2(tex.get_width(), tex.get_height()) * weapon_overlay.scale.abs()
	return Vector2(
		weapon_overlay.offset.x + (nx - 0.5) * draw_size.x,
		weapon_overlay.offset.y + (ny - 0.5) * draw_size.y
	)


func weapon_handle_anchor_local() -> Vector2:
	_ensure_overlay_pivot()
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	var kind: int = int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN))
	var nx: float = float(profile.get("pivot_x_frac", 0.5))
	var ny: float = _weapon_handle_y_frac()
	if kind == WeaponOverlayCombat.AttackKind.THRUST:
		nx = 0.5
	return _texture_frac_to_overlay_local(nx, ny)


func weapon_hand_grip_local_from_preset(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE
) -> Vector2:
	if weapon_overlay == null or preset == null:
		return Vector2.ZERO
	var grip_px := preset.resolve_club_overlay_grip_px(mode)
	return Vector2(grip_px.x * weapon_overlay.scale.x, grip_px.y * weapon_overlay.scale.y)


func _weapon_handle_y_frac() -> float:
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	var kind: int = int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN))
	return float(profile.get("pivot_y_frac", WEAPON_HANDLE_Y_FRAC))


func weapon_handle_anchor_global() -> Vector2:
	if weapon_overlay == null:
		return global_position
	return weapon_overlay.to_global(weapon_handle_anchor_local())


func move_weapon_handle_anchor_global(anchor_global: Vector2) -> Vector2:
	if weapon_overlay == null or sprite == null:
		return Vector2.ZERO
	_ensure_overlay_pivot()
	var local := weapon_handle_anchor_local()
	var anchor_offset: Vector2 = weapon_overlay.to_global(local) - weapon_overlay.global_position
	weapon_overlay.global_position = anchor_global - anchor_offset
	_commit_overlay_meta_from_current_pose()
	return display_px_from_overlay_position()


func support_shoulder_global_from_preset(preset: WeaponLimbPreset) -> Vector2:
	if preset == null:
		return global_position
	return MannequinAnchorResolver.shoulder_global_from_display(
		sprite, body_visual, preset.support_shoulder_offset_px
	)


func set_support_shoulder_from_global(preset: WeaponLimbPreset, global_pos: Vector2) -> void:
	if preset == null:
		return
	if body_visual == null:
		preset.support_shoulder_offset_px = LimbPresetCoords.body_display_from_global(sprite, global_pos)
		return
	var body_local := _body_local_from_shoulder_global(global_pos)
	preset.support_shoulder_offset_px = _shoulder_display_px_from_body_local(body_local)


func _body_local_from_shoulder_global(global_pos: Vector2) -> Vector2:
	if body_visual == null:
		return Vector2.ZERO
	var body_sprite: Sprite2D = null
	if body_visual.has_method("get_body_sprite"):
		body_sprite = body_visual.call("get_body_sprite") as Sprite2D
	if body_sprite:
		return body_sprite.to_local(global_pos)
	if body_visual.has_method("get_body_sprite_offset"):
		return body_visual.to_local(global_pos) - body_visual.call("get_body_sprite_offset")
	return body_visual.to_local(global_pos)


func support_hand_idle_global_from_preset(preset: WeaponLimbPreset) -> Vector2:
	return LimbPresetCoords.body_global_from_display(sprite, preset.support_hand_idle_offset_px)


func set_support_hand_idle_from_global(preset: WeaponLimbPreset, global_pos: Vector2) -> void:
	if preset == null:
		return
	preset.support_hand_idle_offset_px = LimbPresetCoords.body_display_from_global(sprite, global_pos)


func support_hand_global_from_preset(preset: WeaponLimbPreset) -> Vector2:
	return LimbPresetCoords.overlay_grip_global(weapon_overlay, preset.support_hand_offset_px)


func spear_windup_dominant_grip_global(preset: WeaponLimbPreset) -> Vector2:
	if preset == null or weapon_overlay == null:
		return global_position
	return LimbPresetCoords.overlay_grip_global(
		weapon_overlay, preset.resolve_spear_windup_dominant_grip_px()
	)


func spear_windup_support_grip_global(preset: WeaponLimbPreset) -> Vector2:
	return support_hand_global_from_preset(preset)


func set_support_hand_from_global(preset: WeaponLimbPreset, global_pos: Vector2) -> void:
	if preset == null:
		return
	preset.support_hand_offset_px = LimbPresetCoords.overlay_grip_px_from_global(weapon_overlay, global_pos)


func hand_grip_global_from_preset(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE
) -> Vector2:
	var grip_px := preset.resolve_club_overlay_grip_px(mode)
	if not has_weapon_overlay():
		return LimbPresetCoords.body_global_from_display(sprite, grip_px)
	return LimbPresetCoords.overlay_grip_global(weapon_overlay, grip_px)


func set_hand_grip_from_global(
	preset: WeaponLimbPreset,
	global_pos: Vector2,
	mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE
) -> void:
	if preset == null:
		return
	if not has_weapon_overlay():
		preset.set_hand_grip_for_mode(
			mode,
			LimbPresetCoords.body_display_from_global(sprite, global_pos)
		)
		return
	var grip_px := LimbPresetCoords.overlay_grip_px_from_global(weapon_overlay, global_pos)
	preset.set_hand_grip_for_mode(mode, grip_px)


## Club/swing weapons: move weapon so grip anchor sits on the hand (handles 1h + 3 stack).
func align_spear_windup_overlay_to_grip_global(
	preset: WeaponLimbPreset,
	target_grip_global: Vector2,
	dominant: bool
) -> void:
	## Move the whole horizontal spear; overlay-local grip px stay fixed on the art.
	if preset == null or weapon_overlay == null or sprite == null or not has_weapon_overlay():
		return
	_ensure_overlay_pivot()
	var grip_px := (
		preset.resolve_spear_windup_dominant_grip_px()
		if dominant
		else preset.support_hand_offset_px
	)
	var grip_local := Vector2(grip_px.x * weapon_overlay.scale.x, grip_px.y * weapon_overlay.scale.y)
	var grip_global := weapon_overlay.to_global(grip_local)
	weapon_overlay.global_position += target_grip_global - grip_global
	_apply_overlay_display_for_mode(preset, WeaponLimbPreset.TunerAnimMode.ATTACK)


func align_weapon_overlay_to_hand_grip_global(
	preset: WeaponLimbPreset,
	hand_global: Vector2,
	mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE,
	commit_to_preset: bool = true
) -> void:
	if preset == null or weapon_overlay == null or sprite == null or not has_weapon_overlay():
		return
	var ready_pose := mode == WeaponLimbPreset.TunerAnimMode.ATTACK
	var grip_px := preset.resolve_club_overlay_grip_px(mode)
	if (
		grip_px.length_squared() > 0.0001
		or preset.uses_saved_club_grip_on_art()
		or preset.uses_saved_spear_grip_on_art()
	):
		_ensure_overlay_pivot()
		var grip_local := Vector2(grip_px.x * weapon_overlay.scale.x, grip_px.y * weapon_overlay.scale.y)
		var grip_global := weapon_overlay.to_global(grip_local)
		weapon_overlay.global_position += hand_global - grip_global
		if commit_to_preset:
			_apply_overlay_display_for_mode(preset, mode)
		return
	if uses_weapon_grip_anchor_hand() and not preset.uses_saved_club_grip_on_art():
		move_weapon_handle_anchor_global(hand_global)
		snap_hand_grip_to_weapon_anchor(preset, ready_pose)
		if commit_to_preset:
			_apply_overlay_display_for_mode(preset, mode)
		return
	_ensure_overlay_pivot()
	if grip_px.length_squared() < 0.0001 and not preset.uses_saved_club_grip_on_art():
		snap_hand_grip_to_weapon_anchor(preset, ready_pose)
		grip_px = preset.resolve_club_overlay_grip_px(mode)
	var grip_local := Vector2(grip_px.x * weapon_overlay.scale.x, grip_px.y * weapon_overlay.scale.y)
	var grip_global := weapon_overlay.to_global(grip_local)
	weapon_overlay.global_position += hand_global - grip_global
	if commit_to_preset:
		_apply_overlay_display_for_mode(preset, mode)


func uses_spear_shaft_grip_slide() -> bool:
	return weapon_type == ResourceData.ResourceType.SPEAR and has_weapon_overlay()


func project_spear_shaft_grip_drag_global(global_pos: Vector2, current_grip_global: Vector2) -> Vector2:
	if weapon_overlay == null or not weapon_overlay.visible:
		return global_pos
	return _project_grip_slide_along_weapon_shaft(global_pos, current_grip_global)


func project_hand_grip_drag_global(
	global_pos: Vector2,
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE
) -> Vector2:
	if weapon_overlay == null or not weapon_overlay.visible:
		return global_pos
	if uses_weapon_grip_anchor_hand():
		return _project_grip_slide_along_weapon_shaft(
			global_pos, hand_grip_global_from_preset(preset, mode)
		)
	if uses_spear_shaft_grip_slide():
		return _project_grip_slide_along_weapon_shaft(
			global_pos, hand_grip_global_from_preset(preset, mode)
		)
	return global_pos


func project_support_hand_grip_drag_global(global_pos: Vector2, preset: WeaponLimbPreset) -> Vector2:
	if weapon_overlay == null or not weapon_overlay.visible:
		return global_pos
	if uses_weapon_grip_anchor_hand():
		return _project_grip_slide_along_weapon_shaft(global_pos, support_hand_global_from_preset(preset))
	if uses_spear_shaft_grip_slide():
		return _project_grip_slide_along_weapon_shaft(
			global_pos, support_hand_global_from_preset(preset)
		)
	return global_pos


func _project_grip_slide_along_weapon_shaft(global_pos: Vector2, current_grip_global: Vector2) -> Vector2:
	## Club/swing weapons: slide grip along overlay Y (shaft), keep X fixed.
	var current_local := weapon_overlay.to_local(current_grip_global)
	var proposed_local := weapon_overlay.to_local(global_pos)
	proposed_local.x = current_local.x
	return weapon_overlay.to_global(proposed_local)


func snap_hand_grip_to_weapon_anchor(preset: WeaponLimbPreset, ready_pose: bool = false) -> void:
	if preset == null or weapon_overlay == null:
		return
	if preset.uses_saved_club_grip_on_art() and not ready_pose:
		return
	_ensure_overlay_pivot()
	var anchor_local := weapon_handle_anchor_local()
	var grip_px := LimbPresetCoords.overlay_grip_px_from_global(
		weapon_overlay, weapon_overlay.to_global(anchor_local)
	)
	if ready_pose:
		preset.hand_grip_ready_offset_px = grip_px
	elif preset.weapon_type == ResourceData.ResourceType.WOOD:
		preset.set_club_grip_on_art_from_overlay_px(grip_px)
	else:
		preset.hand_grip_offset_px = grip_px


func snap_dominant_hand_grip_to_weapon_anchor(preset: WeaponLimbPreset) -> void:
	snap_hand_grip_to_weapon_anchor(preset, false)


func sync_idle_club1_grip_from_handle_anchor(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> void:
	if preset == null or weapon_overlay == null or not has_weapon_overlay():
		return
	var grip_px := LimbPresetCoords.overlay_grip_px_from_global(
		weapon_overlay, weapon_handle_anchor_global()
	)
	preset.set_hand_grip_for_mode(mode, grip_px)


func dominant_grip_global_from_preset(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE
) -> Vector2:
	if preset == null:
		return global_position
	if not has_weapon_overlay():
		return hand_grip_global_from_preset(preset, mode)
	if uses_weapon_grip_anchor_hand():
		if preset.uses_saved_club_grip_on_art():
			return hand_grip_global_from_preset(preset, mode)
		var grip_px := preset.resolve_club_overlay_grip_px(mode)
		if grip_px.length_squared() > 0.0001:
			return hand_grip_global_from_preset(preset, mode)
		return weapon_handle_anchor_global()
	return hand_grip_global_from_preset(preset, mode)


func uses_weapon_grip_anchor_hand() -> bool:
	if weapon_type == ResourceData.ResourceType.NONE or not has_weapon_overlay():
		return false
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	return int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN)) != WeaponOverlayCombat.AttackKind.THRUST


func elbow_pole_global_from_preset(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	if preset == null or sprite == null:
		return global_position
	var pole_px := preset.resolve_elbow_pole_for_mode(dominant, mode)
	if pole_px.length_squared() < 0.0001:
		return global_position
	return LimbPresetCoords.body_global_from_display(sprite, pole_px)


func set_elbow_pole_from_global(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	global_pos: Vector2
) -> void:
	if preset == null or sprite == null:
		return
	preset.set_elbow_pole_for_mode(
		dominant,
		mode,
		LimbPresetCoords.body_display_from_global(sprite, global_pos)
	)


func elbow_pole_global_from_preset_legacy(preset: WeaponLimbPreset, dominant: bool, ready_pose: bool) -> Vector2:
	var mode := (
		WeaponLimbPreset.TunerAnimMode.ATTACK
		if ready_pose
		else WeaponLimbPreset.TunerAnimMode.IDLE
	)
	return elbow_pole_global_from_preset(preset, dominant, mode)


func set_elbow_pole_from_global_legacy(
	preset: WeaponLimbPreset,
	dominant: bool,
	ready_pose: bool,
	global_pos: Vector2
) -> void:
	var mode := (
		WeaponLimbPreset.TunerAnimMode.ATTACK
		if ready_pose
		else WeaponLimbPreset.TunerAnimMode.IDLE
	)
	set_elbow_pole_from_global(preset, dominant, mode, global_pos)


func elbow_joint_global_from_arms(dominant: bool) -> Vector2:
	if arm_controller == null:
		return global_position
	var endpoints: Dictionary = (
		arm_controller.get_weapon_arm_global_endpoints()
		if dominant
		else arm_controller.get_support_arm_global_endpoints()
	)
	return endpoints.get("elbow", global_position)


func elbow_bend_sign_auto_for_facing(dominant: bool) -> float:
	## Default bend from sprite.flip_h — overridden per arm when preset bend sign is set.
	var aiming_left := sprite != null and sprite.flip_h
	if dominant:
		if aiming_left:
			return WeaponLimbPreset.DOMINANT_ELBOW_BEND_SIGN
		return -WeaponLimbPreset.DOMINANT_ELBOW_BEND_SIGN
	if aiming_left:
		return WeaponLimbPreset.SUPPORT_ELBOW_BEND_SIGN
	return -WeaponLimbPreset.SUPPORT_ELBOW_BEND_SIGN


func resolve_elbow_bend_sign(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode
) -> float:
	if preset == null:
		return elbow_bend_sign_auto_for_facing(dominant)
	return preset.resolve_elbow_bend_sign(dominant, mode, elbow_bend_sign_auto_for_facing(dominant))


func elbow_joint_global_from_handles(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	shoulder_global: Vector2,
	hand_global: Vector2
) -> Vector2:
	if preset == null or sprite == null:
		return global_position
	var shoulder_local := to_local(shoulder_global)
	var hand_local := to_local(hand_global)
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var upper_len: float = preset.resolve_upper_arm_length(dominant) * sx
	var lower_len: float = preset.resolve_lower_arm_length(dominant) * sx
	var bend_sign: float = resolve_elbow_bend_sign(preset, dominant, mode)
	var relax_min_reach := (
		(
			mode == WeaponLimbPreset.TunerAnimMode.WALK
			or mode == WeaponLimbPreset.TunerAnimMode.WALK1
		) and _walk.is_moving()
	) or (mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and _gather.playing)
	var fold_min := 8.0
	var fold_max := 150.0
	if arm_controller and arm_controller.config:
		var cfg: ProceduralArmConfig = arm_controller.config
		if relax_min_reach:
			fold_min = cfg.elbow_fold_min_walk_deg
			fold_max = cfg.elbow_fold_max_walk_deg
		else:
			fold_min = cfg.elbow_fold_min_deg
			fold_max = cfg.elbow_fold_max_deg
	var elbow_local := _solve_ik_local(
		shoulder_local, hand_local, upper_len, lower_len, bend_sign, fold_min, fold_max, relax_min_reach
	)
	return to_global(elbow_local)


func _solve_ik_local(
	shoulder: Vector2,
	hand: Vector2,
	upper_len: float,
	lower_len: float,
	bend_sign: float,
	fold_min_deg: float = 8.0,
	fold_max_deg: float = 150.0,
	relax_min_reach: bool = false
) -> Vector2:
	var to_hand := hand - shoulder
	var dist := to_hand.length()
	if dist < 0.001:
		return shoulder + Vector2(upper_len, 0.0)
	var min_fold := deg_to_rad(fold_min_deg)
	var max_fold := deg_to_rad(fold_max_deg)
	var max_reach := sqrt(
		upper_len * upper_len + lower_len * lower_len - 2.0 * upper_len * lower_len * cos(PI - min_fold)
	) - 0.01
	var min_reach := sqrt(
		upper_len * upper_len + lower_len * lower_len - 2.0 * upper_len * lower_len * cos(PI - max_fold)
	) + 0.01
	if dist > max_reach:
		dist = max_reach
	elif not relax_min_reach and dist < min_reach:
		dist = min_reach
	var dir := to_hand / dist
	var cos_shoulder := (upper_len * upper_len + dist * dist - lower_len * lower_len) / (2.0 * upper_len * dist)
	cos_shoulder = clampf(cos_shoulder, -1.0, 1.0)
	var shoulder_angle := acos(cos_shoulder)
	var pole_side := signf(bend_sign)
	if pole_side == 0.0:
		pole_side = 1.0
	var elbow_dir := dir.rotated(shoulder_angle * pole_side)
	return shoulder + elbow_dir * upper_len


func set_arm_lengths_from_elbow_global(
	preset: WeaponLimbPreset,
	dominant: bool,
	shoulder_global: Vector2,
	elbow_global: Vector2,
	hand_global: Vector2
) -> void:
	if preset == null or sprite == null:
		return
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var shoulder_local := to_local(shoulder_global)
	var elbow_local := to_local(elbow_global)
	var hand_local := to_local(hand_global)
	var upper := maxf(shoulder_local.distance_to(elbow_local) / sx, WeaponLimbPreset.TUNER_MIN_SEGMENT_PX)
	var lower := maxf(elbow_local.distance_to(hand_local) / sx, WeaponLimbPreset.TUNER_MIN_SEGMENT_PX)
	var capped := WeaponLimbPreset.cap_arm_segment_lengths(upper, lower)
	preset.set_shared_arm_lengths(capped.x, capped.y)


func clamp_hand_global_to_arm_reach(
	preset: WeaponLimbPreset,
	shoulder_global: Vector2,
	hand_global: Vector2,
	dominant: bool = true,
	reach_slack_ratio: float = 0.0,
	walk_swing: bool = false
) -> Vector2:
	if preset == null or sprite == null:
		return hand_global
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var max_reach: float = preset.tuner_ik_max_reach_px(dominant) * sx * (1.0 + maxf(reach_slack_ratio, 0.0))
	var min_reach: float = preset.tuner_ik_min_reach_px(dominant) * sx
	var shoulder_local := to_local(shoulder_global)
	var hand_local := to_local(hand_global)
	var delta := hand_local - shoulder_local
	var dist := delta.length()
	if dist < 0.001:
		return hand_global
	if dist > max_reach:
		return to_global(shoulder_local + delta * (max_reach / dist))
	if not walk_swing and dist < min_reach:
		return to_global(shoulder_local + delta * (min_reach / dist))
	return hand_global


func set_elbow_joint_from_global(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	elbow_global: Vector2,
	shoulder_global: Vector2,
	hand_global: Vector2
) -> void:
	if preset == null or sprite == null:
		return
	var bend_sign := resolve_elbow_bend_sign(preset, dominant, mode)
	var pole_px := LimbPresetCoords.pole_display_from_elbow_global(
		sprite, shoulder_global, hand_global, elbow_global, preset.elbow_hint_outward, bend_sign
	)
	preset.set_elbow_pole_for_mode(dominant, mode, pole_px)


func seed_elbow_pole_if_unset(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	shoulder_global: Vector2,
	hand_global: Vector2
) -> void:
	if preset == null or sprite == null:
		return
	if preset.resolve_elbow_pole_for_mode(dominant, mode).length_squared() > 0.0001:
		return
	var bend_sign := resolve_elbow_bend_sign(preset, dominant, mode)
	var auto_px := LimbPresetCoords.auto_elbow_pole_display_from_global(
		sprite, shoulder_global, hand_global, preset.elbow_hint_outward, bend_sign
	)
	preset.set_elbow_pole_for_mode(dominant, mode, auto_px)


func support_hand_global_for_mode(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	if preset == null or sprite == null:
		return global_position
	## Only spear ready/attack locks off-hand to the weapon overlay (two-hand shaft grip).
	## Until windup is saved, inherit idle — off-hand stays on body like carry pose.
	if mode == WeaponLimbPreset.TunerAnimMode.ATTACK and WeaponLimbPreset.uses_two_hand_grip(weapon_type):
		if preset.attack_pose_inherits_idle():
			return LimbPresetCoords.body_global_from_display(
				sprite, preset.resolve_support_hand_for_mode(mode)
			)
		return support_hand_global_from_preset(preset)
	return LimbPresetCoords.body_global_from_display(
		sprite, preset.resolve_support_hand_for_mode(mode)
	)


func support_hand_idle_global_with_raise(preset: WeaponLimbPreset, raise_blend: float) -> Vector2:
	if preset == null or sprite == null:
		return global_position
	if not preset.has_idle_arm2_raise_pose():
		return LimbPresetCoords.body_global_from_display(sprite, preset.resolve_support_hand_idle_rest_px())
	if raise_blend <= 0.0001:
		return LimbPresetCoords.body_global_from_display(sprite, preset.resolve_support_hand_idle_rest_px())
	var rest_px := preset.resolve_support_hand_idle_rest_px()
	var raised_px := preset.resolve_support_hand_idle_raised_px()
	var blended_px := rest_px.lerp(raised_px, clampf(raise_blend, 0.0, 1.0))
	return LimbPresetCoords.body_global_from_display(sprite, blended_px)


func set_support_hand_for_mode(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	global_pos: Vector2
) -> void:
	if preset == null:
		return
	if mode == WeaponLimbPreset.TunerAnimMode.ATTACK and WeaponLimbPreset.uses_two_hand_grip(weapon_type):
		if preset.attack_pose_inherits_idle():
			preset.set_support_hand_for_mode(
				mode,
				LimbPresetCoords.body_display_from_global(sprite, global_pos)
			)
		else:
			set_support_hand_from_global(preset, global_pos)
	else:
		preset.set_support_hand_for_mode(
			mode,
			LimbPresetCoords.body_display_from_global(sprite, global_pos)
		)


func get_weapon_overlay_bounds_on_stage() -> Rect2:
	var stage := get_parent() as Node2D
	if stage == null or weapon_overlay == null or not weapon_overlay.visible:
		return Rect2()
	return _sprite_rect_on_stage(weapon_overlay, stage)


func get_body_bounds_on_stage() -> Rect2:
	var stage := get_parent() as Node2D
	if stage == null:
		return Rect2()
	var rects: Array[Rect2] = []
	_collect_sprite_rects_excluding(self, stage, rects, [&"WeaponOverlay"])
	if rects.is_empty():
		return Rect2()
	var merged: Rect2 = rects[0]
	for i in range(1, rects.size()):
		merged = merged.merge(rects[i])
	return merged


func get_body_center_on_stage() -> Vector2:
	var bounds := get_body_bounds_on_stage()
	if bounds.size.length_squared() < 1.0:
		return get_visual_center_on_stage()
	return bounds.get_center()


func get_visual_bounds_on_stage() -> Rect2:
	var stage := get_parent() as Node2D
	if stage == null:
		return Rect2()
	var rects: Array[Rect2] = []
	_collect_sprite_rects(self, stage, rects)
	if rects.is_empty():
		return Rect2()
	var merged: Rect2 = rects[0]
	for i in range(1, rects.size()):
		merged = merged.merge(rects[i])
	return merged


func get_visual_center_on_stage() -> Vector2:
	var bounds := get_visual_bounds_on_stage()
	if bounds.size.length_squared() < 1.0:
		return Vector2.ZERO
	return bounds.get_center()


func _collect_sprite_rects(node: Node, stage: Node2D, rects: Array[Rect2]) -> void:
	if node is Sprite2D:
		var sprite := node as Sprite2D
		if sprite.visible and sprite.texture != null:
			var rect := _sprite_rect_on_stage(sprite, stage)
			if rect.size.length_squared() > 0.01:
				rects.append(rect)
	for child in node.get_children():
		_collect_sprite_rects(child, stage, rects)


func _collect_sprite_rects_excluding(
	node: Node,
	stage: Node2D,
	rects: Array[Rect2],
	skip_names: Array[StringName]
) -> void:
	if node.name in skip_names:
		return
	if node is Sprite2D:
		var sprite := node as Sprite2D
		if sprite.visible and sprite.texture != null:
			var rect := _sprite_rect_on_stage(sprite, stage)
			if rect.size.length_squared() > 0.01:
				rects.append(rect)
	for child in node.get_children():
		_collect_sprite_rects_excluding(child, stage, rects, skip_names)


func _sprite_rect_on_stage(sprite: Sprite2D, stage: Node2D) -> Rect2:
	var tex := sprite.texture
	if tex == null:
		return Rect2()
	var draw_size := Vector2(tex.get_width(), tex.get_height()) * sprite.scale.abs()
	var half := draw_size * 0.5 if sprite.centered else Vector2.ZERO
	var corners := [
		Vector2(-half.x, -half.y) + sprite.offset,
		Vector2(half.x, -half.y) + sprite.offset,
		Vector2(half.x, half.y) + sprite.offset,
		Vector2(-half.x, half.y) + sprite.offset,
	]
	var xf := sprite.global_transform
	var rect := Rect2()
	for i in corners.size():
		var stage_pt := stage.to_local(xf * corners[i])
		if i == 0:
			rect = Rect2(stage_pt, Vector2.ZERO)
		else:
			rect = rect.expand(stage_pt)
	return rect


func sync_combat_overlay(hold_ready: bool) -> void:
	if weapon_overlay == null or not weapon_overlay.visible:
		return
	var ostate: int = WeaponOverlayCombat.get_overlay_state(self)
	if ostate == WeaponOverlayCombat.OverlayState.STRIKING:
		return
	if hold_ready:
		aim_dir = _get_cursor_aim_direction()
		if PlaceholderCardService:
			PlaceholderCardService.update_weapon_overlay_combat(self, weapon_type, aim_dir)
		if combat_component and combat_component.state == CombatComponent.CombatState.READY:
			combat_component.update_ready_aim(aim_dir)
	elif combat_component and combat_component.state == CombatComponent.CombatState.READY:
		combat_component.update_ready_aim(aim_dir)
		if PlaceholderCardService:
			PlaceholderCardService.update_weapon_overlay_combat(self, weapon_type, aim_dir)
