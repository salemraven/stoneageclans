extends CharacterBody2D
class_name LimbTunerRig

## Minimal player-like rig for LimbTuner — same node layout as Player for shared combat/arm code.

const CardVisualController = preload("res://scripts/systems/card_visual_controller.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const LimbPresetCoords = preload("res://scripts/systems/limb_preset_coords.gd")
const IKUtils = preload("res://scripts/systems/ik_utils.gd")
const IdleMotion = preload("res://scripts/systems/idle_motion.gd")
const SpearIdleMotion = preload("res://scripts/systems/spear_idle_motion.gd")
const ClubWindupMotion = preload("res://scripts/systems/club_windup_motion.gd")
const TunerWalkPreview = preload("res://scripts/tools/tuner_walk_preview.gd")
const TunerIdlePreview = preload("res://scripts/tools/tuner_idle_preview.gd")
const TunerGatherPreview = preload("res://scripts/tools/tuner_gather_preview.gd")
const TunerWindupIdlePreview = preload("res://scripts/tools/tuner_windup_idle_preview.gd")
const GatherArmMotion = preload("res://scripts/systems/gather_arm_motion.gd")
const WalkArmSwing = preload("res://scripts/systems/walk_arm_swing.gd")
const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")
const KeyedMotionPlayback = preload("res://scripts/systems/keyed_motion_playback.gd")
const TUNER_ARM1_Z_INDEX := 0
const TUNER_BODY_Z_INDEX := 1
const TUNER_HEAD_Z_INDEX := 2
const TUNER_ARM2_Z_INDEX := 3
const TunerMannequinLayoutScript = preload("res://scripts/tools/tuner_mannequin_layout.gd")
const MannequinAnchorResolver = preload("res://scripts/systems/mannequin_anchor_resolver.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")
const LimbAnimationBakerScript = preload("res://scripts/tools/limb_animation_baker.gd")
const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")
const TunerMotionResolverScript = preload("res://scripts/tools/tuner_motion_resolver.gd")

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
var _windup_idle := TunerWindupIdlePreview.new()
var _registry = PlaceholderCardRegistry.new()
var _last_overlay_base := Vector2.ZERO
var _preview_idle_mode := true
var _preview_gather_mode := false
var _preview_walk_mode := false
var _preview_walk_keyframe_overlay := false
var _preview_windup_mode := false
var _shift_ready_windup_mode := false
var _windup_preview_preset: WeaponLimbPreset = null
var _windup_idle_sample_active := false
var _windup_idle_sample: Dictionary = {}
var _walk_preview_preset: WeaponLimbPreset = null
var _walk_preview_grip_mode: WeaponLimbPreset.TunerAnimMode = WeaponLimbPreset.TunerAnimMode.IDLE
var _idle_preview_amp_scale: float = 1.0
var _walk_elbow_pick_locked := false
var _walk_support_elbow_pick_a := true
var _walk_weapon_elbow_pick_a := true


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
	_windup_preview_preset = preset


func set_preview_windup_mode(on: bool) -> void:
	_preview_windup_mode = on
	if not on and not _shift_ready_windup_mode:
		clear_windup_idle_preview_sample()


func set_shift_ready_windup_loop(on: bool) -> void:
	if _shift_ready_windup_mode and not on:
		clear_windup_idle_preview_sample()
		if _windup_preview_preset != null and not _preview_windup_mode:
			apply_preset_overlay_for_mode(_windup_preview_preset, WeaponLimbPreset.TunerAnimMode.IDLE)
	var entering := on and not _shift_ready_windup_mode
	_shift_ready_windup_mode = on
	if entering:
		_windup_idle.reset()
	if on:
		_windup_idle.set_playing(true)
	elif not _preview_windup_mode:
		_windup_idle.set_playing(false)


func set_windup_idle_playing(on: bool) -> void:
	_windup_idle.set_playing(on and (_preview_windup_mode or _shift_ready_windup_mode))
	if not on and not _shift_ready_windup_mode:
		clear_windup_idle_preview_sample()


func clear_windup_idle_preview_sample() -> void:
	_windup_idle_sample_active = false
	_windup_idle_sample = {}


func seek_windup_idle_loop_phase(phase: float) -> void:
	_windup_idle.cycle_time = fposmod(phase, 1.0) * maxf(_windup_idle.cycle_sec, 0.5)


func reset_windup_idle_loop() -> void:
	_windup_idle.reset()


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
	var windup_on := on and _preview_windup_mode
	if _windup_idle.playing and not windup_on and not _shift_ready_windup_mode:
		clear_windup_idle_preview_sample()
		if _windup_preview_preset != null:
			apply_preset_overlay_ready(_windup_preview_preset, aim_from_facing())
	_windup_idle.set_playing(windup_on or _shift_ready_windup_mode)
	_gather.set_playing(on and _preview_gather_mode)
	_walk.set_playing(on and (_preview_walk_mode or _preview_walk_keyframe_overlay))
	_idle.set_playing(on and _preview_idle_mode)


func is_windup_idle_loop_playing() -> bool:
	return _windup_idle.playing and (_preview_windup_mode or _shift_ready_windup_mode)


func is_shift_ready_windup_loop() -> bool:
	return _shift_ready_windup_mode and _windup_idle.playing


func is_windup_idle_sample_active() -> bool:
	if should_pause_windup_loop_tick():
		return false
	return _windup_idle_sample_active and is_windup_idle_loop_playing()


func seed_club_strike_start_from_windup() -> void:
	## Capture live windup-loop hand/support so strike starts from current loop phase.
	if not _windup_idle_sample_active:
		return
	var hand_px: Vector2 = _windup_idle_sample.get("hand_grip_ready_offset_px", Vector2.ZERO)
	var support_px: Vector2 = _windup_idle_sample.get("support_hand_idle_offset_px", Vector2.ZERO)
	if hand_px.length_squared() > 0.0001:
		set_meta(WeaponOverlayCombat.CLUB_STRIKE_HAND_META, hand_px)
	if support_px.length_squared() > 0.0001:
		set_meta(WeaponOverlayCombat.CLUB_STRIKE_SUPPORT_META, support_px)
	_windup_idle_sample_active = false


func hand_grip_global_from_windup_sample() -> Vector2:
	var grip_px: Vector2 = _windup_idle_sample.get("hand_grip_ready_offset_px", Vector2.ZERO)
	if not has_weapon_overlay():
		return LimbPresetCoords.body_global_from_display(sprite, grip_px)
	return LimbPresetCoords.overlay_grip_global(weapon_overlay, grip_px)


func support_hand_global_from_windup_sample() -> Vector2:
	var support_px: Vector2 = _windup_idle_sample.get("support_hand_idle_offset_px", Vector2.ZERO)
	return LimbPresetCoords.body_global_from_display(sprite, support_px)


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


func is_idle_arm2_lowering() -> bool:
	return _idle.is_arm2_lowering() if _idle else false


func get_idle_arm2_lowering() -> bool:
	return is_idle_arm2_lowering()


func idle_head_look_visual_right() -> bool:
	if sprite == null or _idle == null:
		return true
	var look_right := not sprite.flip_h
	if _idle.get_variant_id() == TunerIdlePreview.VARIANT_ID:
		look_right = _idle.head_look_right()
		if sprite.flip_h:
			look_right = not _idle.head_look_right()
	return look_right


func tick_idle_hand_shade_slide(delta: float) -> void:
	if _idle == null or sprite == null:
		return
	_idle.tick_hand_shade_slide(delta, sprite.flip_h, idle_head_look_visual_right())


func idle_hand_shade_offset_display_px() -> Vector2:
	if _idle == null or sprite == null:
		return Vector2.ZERO
	return _idle.hand_shade_offset_display_px(sprite.flip_h, idle_head_look_visual_right())


func begin_idle_sun_shield_scan() -> void:
	if _idle:
		_idle.set_sun_shield_scan_mode(true)
		_idle.begin_sun_shield_raise()


func snap_idle_pose_edit(key: String) -> void:
	if _idle:
		_idle.set_pose_edit(true, key)


func clear_idle_pose_edit() -> void:
	if _idle:
		_idle.set_pose_edit(false)


func is_idle_pose_edit_b() -> bool:
	return _idle.is_pose_edit_b() if _idle else false


func prime_idle_arm_raise_soon() -> void:
	if _idle:
		_idle.prime_arm_raise_soon()


func set_idle_look_hold_sec(sec: float) -> void:
	if _idle:
		_idle.set_look_hold_sec(sec)


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


func set_preview_walk_mode(on: bool) -> void:
	_preview_walk_mode = on
	if not on and not _preview_walk_keyframe_overlay:
		_walk.set_playing(false)
		_walk.set_pose_edit(false)


func sync_walk_keyframe_preview(keyframe_active: bool, walk_tab: bool, anim_playing: bool) -> void:
	## Walk 1 keyframe loop: walk tab Play/A/D, or temporary overlay from Idle + A/D.
	_preview_walk_keyframe_overlay = keyframe_active and not walk_tab
	var should_play := false
	if walk_tab:
		should_play = anim_playing or _walk.is_moving()
	elif keyframe_active:
		should_play = _walk.is_moving()
	_walk.set_playing(should_play)


func is_walk_keyframe_overlay() -> bool:
	return _preview_walk_keyframe_overlay


func is_walk_keyframe_playing() -> bool:
	return _walk.is_keyframe_playing() if _walk else false


func is_walk_pose_edit_active() -> bool:
	return _walk.is_pose_edit_active() if _walk else false


func is_walk_pose_edit_b() -> bool:
	return _walk.is_pose_edit_b() if _walk else false


func set_idle_preview_amplitude_scale(scale: float) -> void:
	_idle_preview_amp_scale = maxf(scale, 0.0)


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
	var rest_px := preset.resolve_walk_support_swing_rest_hand() if preset != null else Vector2.ZERO
	var rest_global := (
		LimbPresetCoords.body_global_from_display(sprite, rest_px)
		if sprite != null
		else global_position
	)
	return _apply_walk_swing_arc(
		support_shoulder_global_from_preset(preset),
		rest_global,
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


func snap_gather_pose_edit(pull: bool) -> void:
	if _gather:
		_gather.set_pose_edit(true, pull)
	_gather.set_playing(false)
	_apply_gather_edit_hold_pose()


func clear_gather_pose_edit() -> void:
	if _gather:
		_gather.set_pose_edit(false)


func is_gather_pose_edit_active() -> bool:
	return _gather.is_pose_edit_active() if _gather else false


func is_gather_pose_edit_pull() -> bool:
	return _gather.is_pose_edit_pull() if _gather else false


func gather_dominant_hand_global_for_pose_edit(preset: WeaponLimbPreset, pull: bool) -> Vector2:
	if preset == null:
		return global_position
	if pull and preset.has_gather1_pull_pose():
		return gather1_pull_hand_global_from_preset(preset, true)
	return hand_grip_global_from_preset(preset, WeaponLimbPreset.TunerAnimMode.GATHER1)


func gather_support_hand_global_for_pose_edit(preset: WeaponLimbPreset, pull: bool) -> Vector2:
	if preset == null:
		return global_position
	if pull and preset.has_gather1_pull_pose():
		return gather1_pull_hand_global_from_preset(preset, false)
	return support_hand_global_for_mode(preset, WeaponLimbPreset.TunerAnimMode.GATHER1)


func walk1_pull_hand_global_from_preset(preset: WeaponLimbPreset, dominant: bool) -> Vector2:
	if preset == null:
		return global_position
	var grip_px := preset.resolve_walk1_pull_hand(dominant)
	return LimbPresetCoords.body_global_from_display(sprite, grip_px)


func snap_walk_pose_edit(pose_b: bool) -> void:
	if _walk:
		_walk.set_pose_edit(true, pose_b)
	_walk.set_playing(false)
	_apply_walk_pose_edit_hold()


func clear_walk_pose_edit() -> void:
	if _walk:
		_walk.set_pose_edit(false)


func walk_dominant_hand_global_for_pose_edit(preset: WeaponLimbPreset, pose_b: bool) -> Vector2:
	if preset == null:
		return global_position
	if (
		pose_b
		and preset.has_walk1_pull_pose()
		and not preset.uses_club_walk_off_arm_travel_swing()
	):
		return walk1_pull_hand_global_from_preset(preset, true)
	return hand_grip_global_from_preset(preset, WeaponLimbPreset.TunerAnimMode.WALK1)


func walk_support_hand_global_for_pose_edit(preset: WeaponLimbPreset, pose_b: bool) -> Vector2:
	if preset == null:
		return global_position
	if pose_b and preset.has_walk1_pull_pose():
		return walk1_pull_hand_global_from_preset(preset, false)
	return support_hand_global_for_mode(preset, WeaponLimbPreset.TunerAnimMode.WALK1)


func hand_grip_global_with_walk_keyframe_motion(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	return _apply_walk_keyframe_hand_motion(
		shoulder_global_from_preset(preset),
		hand_grip_global_from_preset(preset, mode),
		preset,
		mode,
		true,
		_walk.cycle_phase()
	)


func support_hand_global_with_walk_keyframe_motion(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	return _apply_walk_keyframe_hand_motion(
		support_shoulder_global_from_preset(preset),
		support_hand_global_for_mode(preset, mode),
		preset,
		mode,
		false,
		_walk.cycle_phase()
	)


func _apply_walk_keyframe_hand_motion(
	shoulder_global: Vector2,
	pose_a_hand_global: Vector2,
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	dominant: bool,
	cycle_phase: float
) -> Vector2:
	if sprite == null or not (_walk.is_keyframe_playing() or _walk.is_moving()):
		return pose_a_hand_global
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var shoulder_local := to_local(shoulder_global)
	var pose_a_local := to_local(pose_a_hand_global)
	var pose_a_offset := (pose_a_local - shoulder_local) / sx
	var motion_offset: Vector2
	if preset != null and preset.has_walk1_pull_pose():
		var pose_b_global := walk1_pull_hand_global_from_preset(preset, dominant)
		var pose_b_local := to_local(pose_b_global)
		var pose_b_offset := (pose_b_local - shoulder_local) / sx
		motion_offset = WalkArmMotion.hand_offset_between_keyframes(
			pose_a_offset, pose_b_offset, cycle_phase, dominant
		) * sx
	else:
		motion_offset = pose_a_offset * sx
	return to_global(shoulder_local + motion_offset)


func is_keyed_motion_playback_active(mode: WeaponLimbPreset.TunerAnimMode) -> bool:
	return KeyedMotionPlayback.is_active(self, mode)


func elbow_joint_global_from_keyed_motion(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	shoulder_global: Vector2
) -> Vector2:
	if preset == null:
		return shoulder_global
	match mode:
		WeaponLimbPreset.TunerAnimMode.WALK1:
			return _walk_keyframe_elbow_global(preset, dominant, shoulder_global)
		WeaponLimbPreset.TunerAnimMode.GATHER1:
			return _gather_keyframe_elbow_global(preset, dominant, shoulder_global)
		_:
			return shoulder_global


func _club_walk_off_arm_keyframe_preset(club_preset: WeaponLimbPreset) -> WeaponLimbPreset:
	if club_preset == null or not club_preset.uses_club_walk_off_arm_travel_swing():
		return club_preset
	if LimbPresetRegistry != null:
		var none_preset: WeaponLimbPreset = LimbPresetRegistry.get_preset(
			ResourceData.ResourceType.NONE, "clansmen_1", 1
		)
		if none_preset != null and none_preset.walk1_pose_a_saved:
			return none_preset
	return club_preset


func _walk_keyframe_elbow_global(
	preset: WeaponLimbPreset,
	dominant: bool,
	shoulder_global: Vector2
) -> Vector2:
	var mode := WeaponLimbPreset.TunerAnimMode.WALK1
	var walk_motion := _walk.is_keyframe_playing() or _walk.is_moving()
	if not walk_motion or not preset.has_walk1_pull_pose():
		var hand_global := (
			hand_grip_global_from_preset(preset, mode)
			if dominant
			else support_hand_global_for_mode(preset, mode)
		)
		return elbow_joint_global_from_handles(
			preset, dominant, mode, shoulder_global, hand_global
		)
	if preset.uses_club_walk_off_arm_travel_swing() and dominant:
		var carry_hand := hand_grip_global_from_preset(preset, mode)
		return elbow_joint_global_from_handles(
			preset, dominant, mode, shoulder_global, carry_hand
		)
	var key_preset := preset
	if preset.uses_club_walk_off_arm_travel_swing() and not dominant:
		key_preset = _club_walk_off_arm_keyframe_preset(preset)
	var hand_a := (
		hand_grip_global_from_preset(key_preset, mode)
		if dominant
		else support_hand_global_for_mode(key_preset, mode)
	)
	var hand_b := walk1_pull_hand_global_from_preset(key_preset, dominant)
	var auto_sign := elbow_bend_sign_auto_for_facing(dominant)
	var pole_a := key_preset.resolve_walk1_elbow_pole_px(dominant, false)
	var pole_b := key_preset.resolve_walk1_elbow_pole_px(dominant, true)
	var bend_a := key_preset.resolve_elbow_bend_sign_for_pose(dominant, mode, false, false, auto_sign)
	var bend_b := key_preset.resolve_elbow_bend_sign_for_pose(dominant, mode, true, false, auto_sign)
	var elbow_a := _elbow_global_for_saved_pose(
		key_preset, dominant, mode, shoulder_global, hand_a, pole_a, bend_a
	)
	var elbow_b := _elbow_global_for_saved_pose(
		key_preset, dominant, mode, shoulder_global, hand_b, pole_b, bend_b
	)
	return WalkArmMotion.body_snapshot_between_keyframes(
		elbow_a, elbow_b, _walk.cycle_phase()
	)


func _gather_keyframe_elbow_global(
	preset: WeaponLimbPreset,
	dominant: bool,
	shoulder_global: Vector2
) -> Vector2:
	var mode := WeaponLimbPreset.TunerAnimMode.GATHER1
	if not _gather.playing:
		var hand_global := (
			hand_grip_global_from_preset(preset, mode)
			if dominant
			else support_hand_global_for_mode(preset, mode)
		)
		return elbow_joint_global_from_handles(
			preset, dominant, mode, shoulder_global, hand_global
		)
	var hand_reach := (
		hand_grip_global_from_preset(preset, mode)
		if dominant
		else support_hand_global_for_mode(preset, mode)
	)
	var hand_pull := gather1_pull_hand_global_from_preset(preset, dominant)
	var auto_sign := elbow_bend_sign_auto_for_facing(dominant)
	var pole_reach := preset.resolve_gather1_elbow_pole_px(dominant, false)
	var pole_pull := preset.resolve_gather1_elbow_pole_px(dominant, true)
	var bend_reach := preset.resolve_elbow_bend_sign_for_pose(
		dominant, mode, false, false, auto_sign
	)
	var bend_pull := preset.resolve_elbow_bend_sign_for_pose(
		dominant, mode, false, true, auto_sign
	)
	var elbow_reach := _elbow_global_for_saved_pose(
		preset, dominant, mode, shoulder_global, hand_reach, pole_reach, bend_reach
	)
	var elbow_pull := _elbow_global_for_saved_pose(
		preset, dominant, mode, shoulder_global, hand_pull, pole_pull, bend_pull
	)
	var arm_work := GatherArmMotion.arm_work_phase(_gather.cycle_phase())
	if arm_work < 0.0:
		return elbow_reach
	var blend := GatherArmMotion.keyframe_blend(arm_work, dominant)
	return elbow_reach.lerp(elbow_pull, blend)


func _elbow_global_for_saved_pose(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	shoulder_global: Vector2,
	hand_global: Vector2,
	pole_px: Vector2,
	bend_override: float
) -> Vector2:
	if preset == null or sprite == null:
		return shoulder_global
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var upper_len: float = preset.resolve_upper_arm_length(dominant) * sx
	var lower_len: float = preset.resolve_lower_arm_length(dominant) * sx
	if pole_px.length_squared() > 0.0001:
		return _elbow_global_from_pole_pick(
			shoulder_global, hand_global, pole_px, upper_len, lower_len, true
		)
	var bend_sign: float = bend_override
	if absf(bend_sign) < 0.001:
		bend_sign = elbow_bend_sign_auto_for_facing(dominant)
	var shoulder_local := to_local(shoulder_global)
	var hand_local := to_local(hand_global)
	var fold_min := 8.0
	var fold_max := 150.0
	if arm_controller and arm_controller.config:
		fold_min = arm_controller.config.elbow_fold_min_walk_deg
		fold_max = arm_controller.config.elbow_fold_max_walk_deg
	var elbow_local := _solve_ik_local(
		shoulder_local, hand_local, upper_len, lower_len, bend_sign, fold_min, fold_max, true
	)
	return to_global(elbow_local)


func _apply_walk_pose_edit_hold() -> void:
	if sprite == null:
		return
	sprite.position.y = _anchor_foot_y
	if body_visual and body_visual.has_method("set_walk_state"):
		body_visual.call("set_walk_state", false, 0.0, 1 if not sprite.flip_h else -1)
	_sync_body_visual_head_draw()


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
	if dir == 0:
		_walk_elbow_pick_locked = false
	_walk.set_direction(dir)


func get_walk_direction() -> int:
	return _walk.direction


func aim_from_facing() -> Vector2:
	if sprite != null and sprite.flip_h:
		return Vector2(-1.0, 0.0)
	return Vector2(1.0, 0.0)


## Apply left/right facing immediately (idle/gather/etc.) — no walk bounce.
func apply_travel_facing_direction(dir: int) -> void:
	if sprite == null or dir == 0 or _should_tick_club_windup_loop():
		return
	var face_left := dir < 0
	var card_facing_changed := sprite.flip_h != face_left
	var layers_need_sync: bool = (
		body_visual != null
		and body_visual.has_method("layer_facing_in_sync")
		and not bool(body_visual.call("layer_facing_in_sync"))
	)
	if (
		not card_facing_changed
		and not layers_need_sync
		and (not body_visual or _facing_matches_body(face_left))
	):
		return
	if card_facing_changed:
		sprite.flip_h = face_left
		_resync_weapon_overlay_for_facing()
	_sync_body_visual_after_facing_change(dir > 0)


func sync_travel_facing() -> void:
	if sprite == null or _should_tick_club_windup_loop():
		return
	if not _walk.is_moving():
		return
	var face_left := _walk.direction < 0
	if sprite.flip_h != face_left:
		sprite.flip_h = face_left
		_resync_weapon_overlay_for_facing()
	if body_visual and body_visual.has_method("sync_head_draw_transform"):
		if body_visual.has_method("layer_facing_in_sync") and not bool(body_visual.call("layer_facing_in_sync")):
			body_visual.call("sync_head_draw_transform")
	if body_visual and body_visual.has_method("set_walk_state"):
		body_visual.call("set_walk_state", true, _walk.bounce_time, _walk.direction)
	_sync_body_visual_head_draw()


func _facing_matches_body(face_left: bool) -> bool:
	if body_visual == null:
		return true
	return body_visual.is_facing_right() == (not face_left)


func _resync_weapon_overlay_for_facing() -> void:
	if weapon_overlay == null or sprite == null or not weapon_overlay.visible:
		return
	var base_offset: Vector2 = weapon_overlay.get_meta("card_overlay_offset", _last_overlay_base)
	if base_offset != Vector2.ZERO:
		_last_overlay_base = base_offset
	var bounce_y := _tuner_overlay_walk_bounce_y_extra(_walk.is_moving())
	var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	CardVisualController.sync_weapon_overlay_flip(sprite, weapon_overlay, base_offset, mirror_tex, bounce_y)


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


func _uses_spear_keyframed_strike() -> bool:
	if weapon_type != ResourceData.ResourceType.SPEAR or _registry == null:
		return false
	return WeaponOverlayCombat.uses_spear_keyframed_strike_for_weapon(_registry, weapon_type)


func _get_combat_aim_direction() -> Vector2:
	## Keyframed spear: horizontal travel facing only — no cursor tracking.
	if _uses_spear_keyframed_strike():
		if sprite and sprite.flip_h:
			return Vector2(-1.0, 0.0)
		if aim_dir.length_squared() > 0.0001 and absf(aim_dir.x) > 0.05:
			return Vector2(signf(aim_dir.x), 0.0)
		return Vector2(1.0, 0.0)
	return _get_cursor_aim_direction()


func _get_cursor_aim_direction() -> Vector2:
	var mp := get_global_mouse_position()
	var delta := mp - global_position
	if delta.length_squared() > 4.0:
		var raw := delta.normalized()
		if weapon_type == ResourceData.ResourceType.SPEAR and _registry and not _uses_spear_keyframed_strike():
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


func hair_attach_global() -> Vector2:
	if body_visual and body_visual.has_method("hair_attach_global"):
		return body_visual.call("hair_attach_global")
	return neck_socket_global()


func set_hair_attach_from_global(global_pos: Vector2) -> void:
	if body_visual and body_visual.has_method("set_hair_attach_from_global"):
		body_visual.call("set_hair_attach_from_global", global_pos)


func has_hair_layer() -> bool:
	return body_visual != null and body_visual.has_method("has_hair_layer") and body_visual.call("has_hair_layer")


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


func should_pause_windup_loop_tick() -> bool:
	var ostate: int = WeaponOverlayCombat.get_overlay_state(self)
	return (
		ostate == WeaponOverlayCombat.OverlayState.STRIKING
		or ostate == WeaponOverlayCombat.OverlayState.RECOVERING
	)


func _should_tick_club_windup_loop() -> bool:
	if _windup_preview_preset == null or not _windup_preview_preset.has_club_windup_idle_loop():
		return false
	if should_pause_windup_loop_tick():
		return false
	return _windup_idle.playing and (_preview_windup_mode or _shift_ready_windup_mode)


func _update_motion_preview(delta: float) -> void:
	if sprite == null:
		return
	_walk.tick(delta)
	if _should_tick_club_windup_loop():
		_windup_idle.tick(delta)
		_windup_idle.set_cycle_sec(_windup_preview_preset.club_windup_idle_loop_sec)
		apply_club_windup_idle_preview(
			_windup_preview_preset, _windup_idle.cycle_phase()
		)
		_sync_body_visual_head_draw()
		return
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
	if _walk.is_keyframe_playing() and (_preview_walk_mode or _preview_walk_keyframe_overlay):
		_walk.tick(delta)
		if sprite != null:
			if _walk.direction < 0:
				sprite.flip_h = true
			elif _walk.direction > 0:
				sprite.flip_h = false
		_walk.bounce_time = CardVisualController.tick_walk_bounce(
			sprite, _anchor_foot_y, _walk.bounce_time, true, delta
		)
		if body_visual and body_visual.has_method("set_walk_state"):
			body_visual.call("set_walk_state", true, _walk.bounce_time, _walk.direction)
		_sync_overlay_walk_bounce(true)
		_sync_body_visual_head_draw()
		return
	if _preview_walk_mode and _walk.is_pose_edit_active():
		_apply_walk_pose_edit_hold()
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
	if _windup_idle.playing and _preview_windup_mode and _windup_preview_preset != null:
		_windup_idle.tick(delta)
		if _windup_preview_preset.has_club_windup_idle_loop():
			_windup_idle.set_cycle_sec(_windup_preview_preset.club_windup_idle_loop_sec)
			apply_club_windup_idle_preview(
				_windup_preview_preset, _windup_idle.cycle_phase()
			)
		_sync_body_visual_head_draw()
		return
	if _preview_gather_mode:
		_apply_gather_edit_hold_pose()
		return
	if _idle.is_pose_edit_active() and _preview_idle_mode:
		if body_visual and body_visual.has_method("set_idle_state"):
			body_visual.call("set_idle_state", 0.0, 0.0, idle_head_look_visual_right())
		_sync_body_visual_head_draw()
		return
	if _idle.playing and _preview_idle_mode:
		_idle.tick(delta)
		tick_idle_hand_shade_slide(delta)
		set_meta(
			"_idle_sun_shield_scan_active",
			_idle.is_sun_shield_scan_mode()
		)
		var amp_scale := _idle_preview_amp_scale
		var body_amp := _display_to_local(TunerIdlePreview.BODY_BOUNCE_DISPLAY_PX * amp_scale)
		var head_amp := _display_to_local(TunerIdlePreview.HEAD_BOB_DISPLAY_PX * amp_scale)
		var weapon_amp := _display_to_local(TunerIdlePreview.WEAPON_EXTRA_BOUNCE_DISPLAY_PX * amp_scale)
		sprite.position.y = _anchor_foot_y + _idle.body_bounce_offset(body_amp)
		if body_visual and body_visual.has_method("set_idle_state"):
			body_visual.call(
				"set_idle_state",
				_idle.head_bob_offset(head_amp),
				_idle.body_sway_rad(),
				idle_head_look_visual_right()
			)
		_sync_overlay_idle_bounce(weapon_amp)
		_sync_body_visual_head_draw()
		return
	if not _idle.is_pose_edit_active():
		_idle.reset()
	set_meta("_idle_sun_shield_scan_active", false)
	_walk.bounce_time = CardVisualController.tick_walk_bounce(
		sprite, _anchor_foot_y, _walk.bounce_time, false, delta
	)
	if body_visual and body_visual.has_method("clear_motion_state"):
		body_visual.call("clear_motion_state")
	elif body_visual and body_visual.has_method("set_walk_state"):
		body_visual.call("set_walk_state", false, 0.0, 1 if not sprite.flip_h else -1)
	_sync_body_visual_head_draw()
	_sync_overlay_walk_bounce(false)


func _sync_body_visual_head_draw() -> void:
	if body_visual and body_visual.has_method("sync_head_draw_transform"):
		body_visual.call("sync_head_draw_transform")


## Keep gather bend / idle look when only facing changes — do not reset to neutral idle.
func _sync_body_visual_after_facing_change(look_right: bool) -> void:
	if _preview_gather_mode:
		if _gather.playing:
			var phase := _gather.cycle_phase()
			var body_bend := GatherArmMotion.body_bend_rad(phase)
			var head_fwd := _display_to_local(GatherArmMotion.head_forward_display_px(phase))
			if body_visual and body_visual.has_method("set_gather_state"):
				body_visual.call("set_gather_state", body_bend, head_fwd)
		else:
			_apply_gather_edit_hold_pose()
			return
	elif body_visual and body_visual.has_method("set_idle_state"):
		body_visual.call("set_idle_state", 0.0, 0.0, look_right)
	_sync_body_visual_head_draw()


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


func _tuner_overlay_walk_bounce_y_extra(_moving: bool) -> float:
	## Weapon overlay is parented to the body sprite — body bounce already moves the art.
	## Extra phase-lagged bounce made yellow grip pins slide on weapon art during A/D walk.
	return 0.0


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
	var bounce_y := _tuner_overlay_walk_bounce_y_extra(moving)
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
				apply_preset_overlay_ready(preset, aim_from_facing())
		WeaponLimbPreset.TunerAnimMode.WALK, WeaponLimbPreset.TunerAnimMode.WALK1:
			apply_preset_overlay_walk(preset, mode)
		WeaponLimbPreset.TunerAnimMode.GATHER1:
			apply_preset_overlay_gather(preset)
		WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1:
			apply_preset_overlay_idle_club1(preset)
		_:
			apply_preset_overlay_idle(preset, mode)


func apply_weapon_rotation_for_mode(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	aim: Vector2 = Vector2(1.0, 0.0)
) -> void:
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	weapon_overlay.rotation = _resolve_overlay_rotation_rad(preset, mode, profile, aim)
	CardVisualController.sync_weapon_overlay_flip(
		sprite,
		weapon_overlay,
		weapon_overlay.get_meta("card_overlay_offset", _last_overlay_base),
		WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	)


func _resolve_overlay_rotation_rad(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	profile: Dictionary,
	aim: Vector2 = Vector2(1.0, 0.0)
) -> float:
	if preset == null or sprite == null:
		return 0.0
	var kind: int = int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN))
	if mode == WeaponLimbPreset.TunerAnimMode.ATTACK:
		if kind == WeaponOverlayCombat.AttackKind.THRUST:
			var aim_dir := aim.normalized() if aim.length_squared() > 0.0001 else Vector2(1.0, 0.0)
			if preset.rotation_deg_is_custom(mode):
				return deg_to_rad(preset.get_rotation_deg_for_mode(mode))
			sprite.flip_h = aim_dir.x < 0.0
			var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
			return WeaponOverlayCombat.compute_aim_rotation(sprite, aim_dir, tip_deg, 0.0)
		WeaponOverlayCombat.sync_swing_body_facing(self, sprite, aim)
		if preset.rotation_deg_is_custom(mode):
			var facing: float = WeaponOverlayCombat._swing_facing_sign(sprite)
			var stored_deg: float = preset.get_rotation_deg_for_mode(mode)
			return deg_to_rad(preset.resolve_swing_stored_rotation_deg(stored_deg, facing, profile))
		return deg_to_rad(WeaponOverlayCombat._swing_ready_degrees(sprite, profile))
	var mode_for_rot := mode
	if mode == WeaponLimbPreset.TunerAnimMode.WALK and preset.rotation_deg_is_custom(WeaponLimbPreset.TunerAnimMode.WALK):
		mode_for_rot = WeaponLimbPreset.TunerAnimMode.WALK
	elif mode == WeaponLimbPreset.TunerAnimMode.WALK1 and preset.rotation_deg_is_custom(WeaponLimbPreset.TunerAnimMode.WALK1):
		mode_for_rot = WeaponLimbPreset.TunerAnimMode.WALK1
	elif mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and preset.rotation_deg_is_custom(WeaponLimbPreset.TunerAnimMode.GATHER1):
		mode_for_rot = WeaponLimbPreset.TunerAnimMode.GATHER1
	elif mode == WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1 and preset.rotation_deg_is_custom(WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1):
		mode_for_rot = WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1
	if preset.rotation_deg_is_custom(mode_for_rot):
		var stored_deg: float = preset.get_rotation_deg_for_mode(mode_for_rot)
		if weapon_type == ResourceData.ResourceType.WOOD:
			var facing: float = WeaponOverlayCombat._swing_facing_sign(sprite)
			return deg_to_rad(preset.resolve_swing_stored_rotation_deg(stored_deg, facing, profile))
		return deg_to_rad(WeaponLimbPreset.normalize_rotation_deg(stored_deg))
	var idle_deg: float = preset.idle_rotation_deg
	if absf(idle_deg) < 0.001:
		idle_deg = float(profile.get("idle_rotation_deg", 0.0))
	return deg_to_rad(idle_deg)


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
	var rot := _resolve_overlay_rotation_rad(preset, mode, profile)
	_apply_tuner_overlay_pose(
		preset.resolve_overlay_for_mode(mode),
		rot,
		WeaponOverlayCombat.OverlayState.IDLE
	)


func apply_preset_overlay_gather(preset: WeaponLimbPreset) -> void:
	apply_preset_overlay_walk(preset, WeaponLimbPreset.TunerAnimMode.GATHER1)


func apply_preset_overlay_idle_club1(preset: WeaponLimbPreset) -> void:
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	var rot := _resolve_overlay_rotation_rad(preset, WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1, profile)
	_apply_tuner_overlay_pose(
		preset.resolve_overlay_for_mode(WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1),
		rot,
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
	var rot := _resolve_overlay_rotation_rad(preset, mode, profile)
	_apply_tuner_overlay_pose(
		preset.resolve_overlay_for_mode(mode),
		rot,
		WeaponOverlayCombat.OverlayState.IDLE
	)


func apply_preset_overlay_ready(preset: WeaponLimbPreset, aim: Vector2) -> void:
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	apply_club_windup_overlay_at_ready_offset(preset, preset.resolve_overlay_for_mode(WeaponLimbPreset.TunerAnimMode.ATTACK), aim)


func apply_club_windup_overlay_at_ready_offset(
	preset: WeaponLimbPreset,
	ready_display_px: Vector2,
	aim: Vector2 = Vector2(1.0, 0.0),
	rotation_deg_override: float = NAN
) -> void:
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	aim_dir = aim.normalized() if aim.length_squared() > 0.0001 else Vector2(1.0, 0.0)
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	var kind: int = int(profile.get("attack_kind", WeaponOverlayCombat.AttackKind.SWING_DOWN))
	var rot: float
	if not is_nan(rotation_deg_override):
		WeaponOverlayCombat.sync_swing_body_facing(self, sprite, aim_dir)
		var facing: float = WeaponOverlayCombat._swing_facing_sign(sprite)
		var idle_deg: float = float(profile.get("idle_rotation_deg", preset.idle_rotation_deg))
		var applied_deg: float = WeaponLimbPreset.signed_rotation_deg(
			idle_deg + (rotation_deg_override - idle_deg) * facing
		)
		rot = deg_to_rad(applied_deg)
	elif kind == WeaponOverlayCombat.AttackKind.THRUST:
		if sprite:
			sprite.flip_h = aim_dir.x < 0.0
		var tip_deg: float = float(profile.get("texture_tip_deg", -90.0))
		rot = _resolve_overlay_rotation_rad(
			preset, WeaponLimbPreset.TunerAnimMode.ATTACK, profile, aim_dir
		)
		if not preset.rotation_deg_is_custom(WeaponLimbPreset.TunerAnimMode.ATTACK):
			rot = WeaponOverlayCombat.compute_aim_rotation(sprite, aim_dir, tip_deg, 0.0)
	else:
		WeaponOverlayCombat.sync_swing_body_facing(self, sprite, aim_dir)
		rot = _resolve_overlay_rotation_rad(
			preset, WeaponLimbPreset.TunerAnimMode.ATTACK, profile, aim_dir
		)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	_apply_tuner_overlay_pose(ready_display_px, rot, WeaponOverlayCombat.OverlayState.READY)
	_sync_body_visual_head_draw()


func apply_club_windup_idle_preview(preset: WeaponLimbPreset, phase: float) -> void:
	if preset == null or not preset.has_club_windup_idle_loop():
		clear_windup_idle_preview_sample()
		return
	_windup_idle_sample = preset.sample_club_windup_idle_loop(phase)
	_windup_idle_sample_active = true
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	# Saved windup: lerp overlay + hands between rest/A/B keyframes; club angle stays at ready cock.
	var windup_rot_deg: float = preset.resolve_club_windup_rotation_deg(&"b", profile)
	apply_club_windup_overlay_at_ready_offset(
		preset,
		_windup_idle_sample.get("ready_offset_px", preset.ready_offset_px),
		aim_from_facing(),
		windup_rot_deg
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
		preset.resolve_tuner_spear_windup_overlay_px(),
		rot,
		WeaponOverlayCombat.OverlayState.READY
	)


func apply_tuner_spear_strike_overlay(preset: WeaponLimbPreset, aim: Vector2) -> void:
	## Thrust peak / furthest extension row (strike_offset_px + attack rotation).
	if preset == null or sprite == null or weapon_overlay == null or not has_weapon_overlay():
		return
	aim_dir = aim.normalized() if aim.length_squared() > 0.0001 else Vector2(1.0, 0.0)
	var profile: Dictionary = _registry.get_weapon_combat_profile(weapon_type)
	if LimbPresetRegistry:
		profile = LimbPresetRegistry.apply_combat_profile_overrides(profile, weapon_type)
	if sprite:
		sprite.flip_h = aim_dir.x < 0.0
	var rot := _resolve_overlay_rotation_rad(
		preset, WeaponLimbPreset.TunerAnimMode.ATTACK, profile, aim
	)
	WeaponOverlayCombat._ensure_weapon_pivot(weapon_overlay, profile)
	var display_px := preset.resolve_tuner_spear_strike_overlay_px()
	_apply_tuner_overlay_pose(display_px, rot, WeaponOverlayCombat.OverlayState.STRIKING)


func _apply_tuner_overlay_pose(display_px: Vector2, rotation_rad: float, overlay_state: int) -> void:
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var base_unflipped := Vector2(display_px.x / sx, display_px.y / sx)
	weapon_overlay.rotation = rotation_rad
	weapon_overlay.set_meta("card_overlay_offset", base_unflipped)
	_last_overlay_base = base_unflipped
	var mirror_tex: bool = WeaponOverlayCombat._overlay_mirror_texture(_registry, weapon_type)
	var bounce_y := _tuner_overlay_walk_bounce_y_extra(_walk.is_moving())
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


func support_shoulder_global_with_idle_raise(preset: WeaponLimbPreset, raise_blend: float) -> Vector2:
	if preset == null:
		return global_position
	var lowering: bool = is_idle_arm2_lowering()
	var display_px := preset.resolve_support_shoulder_for_idle_raise(raise_blend, lowering)
	return MannequinAnchorResolver.shoulder_global_from_display(
		sprite, body_visual, display_px
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
	var body_px := LimbPresetCoords.body_display_from_global(sprite, global_pos)
	if preset.uses_saved_club_grip_on_art() and has_weapon_overlay():
		## Green 1h is body-card carry; yellow 3 owns grip-on-art — never write overlay px into body rows.
		if (
			mode == WeaponLimbPreset.TunerAnimMode.IDLE
			or (
				mode == WeaponLimbPreset.TunerAnimMode.WALK1
				and preset.uses_club_walk_off_arm_travel_swing()
			)
		):
			preset.set_club_carry_body_hand_px(body_px)
			return
	if not has_weapon_overlay():
		preset.set_hand_grip_for_mode(mode, body_px)
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
	if mode == WeaponLimbPreset.TunerAnimMode.WALK1 and _walk.is_pose_edit_b():
		pole_px = preset.resolve_walk1_elbow_pole_px(dominant, true)
	elif mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and _gather.is_pose_edit_pull():
		pole_px = preset.resolve_gather1_elbow_pole_px(dominant, true)
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
	var display_px := LimbPresetCoords.body_display_from_global(sprite, global_pos)
	if mode == WeaponLimbPreset.TunerAnimMode.WALK1 and _walk.is_pose_edit_b():
		preset.set_walk1_elbow_pole(dominant, true, display_px)
	elif mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and _gather.is_pose_edit_pull():
		preset.set_gather1_elbow_pole(dominant, true, display_px)
	else:
		preset.set_elbow_pole_for_mode(dominant, mode, display_px)


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
	var pose_b := mode == WeaponLimbPreset.TunerAnimMode.WALK1 and is_walk_pose_edit_b()
	var gather_pull := mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and is_gather_pose_edit_pull()
	return preset.resolve_elbow_bend_sign_for_pose(
		dominant, mode, pose_b, gather_pull, elbow_bend_sign_auto_for_facing(dominant)
	)


func _resolve_tuner_elbow_pole_px(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Vector2:
	if preset == null:
		return Vector2.ZERO
	match mode:
		WeaponLimbPreset.TunerAnimMode.WALK1:
			if (_walk.is_keyframe_playing() or _walk.is_moving()) and preset.has_walk1_pull_pose():
				var pole_preset := preset
				if preset.uses_club_walk_off_arm_travel_swing() and not dominant:
					pole_preset = _club_walk_off_arm_keyframe_preset(preset)
				return pole_preset.resolve_walk1_elbow_pole_for_keyframe(dominant, _walk.cycle_phase())
			if _walk.is_pose_edit_active():
				return preset.resolve_walk1_elbow_pole_px(dominant, _walk.is_pose_edit_b())
			return preset.resolve_walk1_elbow_pole_px(dominant, false)
		WeaponLimbPreset.TunerAnimMode.GATHER1:
			if _gather.is_pose_edit_active():
				return preset.resolve_gather1_elbow_pole_px(dominant, _gather.is_pose_edit_pull())
			if _gather.playing and preset.has_gather1_pull_pose():
				var arm_work := GatherArmMotion.arm_work_phase(_gather.cycle_phase())
				if arm_work >= 0.0:
					var reach_pole := preset.resolve_gather1_elbow_pole_px(dominant, false)
					var pull_pole := preset.resolve_gather1_elbow_pole_px(dominant, true)
					return WalkArmMotion.body_snapshot_between_keyframes(reach_pole, pull_pole, arm_work)
			return preset.resolve_gather1_elbow_pole_px(dominant, false)
		_:
			return preset.resolve_elbow_pole_for_mode(dominant, mode)


func _elbow_global_from_pole_pick(
	shoulder_global: Vector2,
	hand_global: Vector2,
	pole_px: Vector2,
	upper_len: float,
	lower_len: float,
	relax_min_reach: bool
) -> Vector2:
	if sprite == null:
		return shoulder_global
	var shoulder_local := to_local(shoulder_global)
	var hand_local := to_local(hand_global)
	var pole_local := LimbPresetCoords.body_display_to_rig_local(sprite, pole_px)
	var candidates: Array = ProceduralArmScript.ik_elbow_candidates(
		shoulder_local, hand_local, upper_len, lower_len, relax_min_reach
	)
	if candidates.size() < 2:
		return to_global(shoulder_local)
	var pick_a := ProceduralArmScript.prefers_elbow_a_near_pole(
		shoulder_local, hand_local, upper_len, lower_len, pole_local, true
	)
	var elbow_local: Vector2 = candidates[0] if pick_a else candidates[1]
	return to_global(elbow_local)


func flipped_elbow_global_from_handles(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	shoulder_global: Vector2,
	hand_global: Vector2
) -> Vector2:
	if preset == null or sprite == null:
		return shoulder_global
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var shoulder_local := to_local(shoulder_global)
	var hand_local := to_local(hand_global)
	var upper_len: float = preset.resolve_upper_arm_length(dominant) * sx
	var lower_len: float = preset.resolve_lower_arm_length(dominant) * sx
	var relax_min_reach := (
		(
			mode == WeaponLimbPreset.TunerAnimMode.WALK
			or mode == WeaponLimbPreset.TunerAnimMode.WALK1
		) and _walk.is_moving()
	) or (mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and _gather.playing)
	var candidates: Array = ProceduralArmScript.ik_elbow_candidates(
		shoulder_local, hand_local, upper_len, lower_len, relax_min_reach
	)
	if candidates.size() < 2:
		return to_global(shoulder_local)
	var pole_px := _resolve_tuner_elbow_pole_px(preset, dominant, mode)
	var pick_a := true
	if pole_px.length_squared() > 0.0001:
		var pole_local := LimbPresetCoords.body_display_to_rig_local(sprite, pole_px)
		pick_a = ProceduralArmScript.prefers_elbow_a_near_pole(
			shoulder_local, hand_local, upper_len, lower_len, pole_local, true
		)
	var elbow_local: Vector2 = candidates[1] if pick_a else candidates[0]
	return to_global(elbow_local)


func sync_elbow_bend_sign_override_from_pole_px(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	pose_b: bool,
	gather_pull: bool,
	shoulder_global: Vector2,
	hand_global: Vector2,
	pole_px: Vector2
) -> void:
	if preset == null or sprite == null or pole_px.length_squared() < 0.0001:
		return
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var shoulder_local := to_local(shoulder_global)
	var hand_local := to_local(hand_global)
	var upper_len: float = preset.resolve_upper_arm_length(dominant) * sx
	var lower_len: float = preset.resolve_lower_arm_length(dominant) * sx
	var pole_local := LimbPresetCoords.body_display_to_rig_local(sprite, pole_px)
	var candidates: Array = ProceduralArmScript.ik_elbow_candidates(
		shoulder_local, hand_local, upper_len, lower_len, false
	)
	if candidates.size() < 2:
		return
	var pick_a := ProceduralArmScript.prefers_elbow_a_near_pole(
		shoulder_local, hand_local, upper_len, lower_len, pole_local, true
	)
	var auto_sign := elbow_bend_sign_auto_for_facing(dominant)
	var fold_min := 8.0
	var fold_max := 150.0
	if arm_controller and arm_controller.config:
		var cfg: ProceduralArmConfig = arm_controller.config
		fold_min = cfg.elbow_fold_min_deg
		fold_max = cfg.elbow_fold_max_deg
	for trial in [1.0, -1.0]:
		preset.set_elbow_bend_sign_override_for_pose(dominant, mode, pose_b, gather_pull, trial)
		var bend_sign := preset.resolve_elbow_bend_sign_for_pose(
			dominant, mode, pose_b, gather_pull, auto_sign
		)
		var elbow_local := _solve_ik_local(
			shoulder_local, hand_local, upper_len, lower_len, bend_sign, fold_min, fold_max, false
		)
		var elbow_pick_a := elbow_local.distance_squared_to(candidates[0]) <= elbow_local.distance_squared_to(candidates[1])
		if elbow_pick_a == pick_a:
			return


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
	var relax_min_reach := (
		(
			mode == WeaponLimbPreset.TunerAnimMode.WALK
			or mode == WeaponLimbPreset.TunerAnimMode.WALK1
		) and _walk.is_moving()
	) or (mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and _gather.playing)
	var walk_keyframe := (
		_walk.is_keyframe_playing()
		and mode == WeaponLimbPreset.TunerAnimMode.WALK1
	)
	var walk_motion := (
		_walk.is_moving()
		and WeaponLimbPreset.is_walk_mode(mode)
		and not walk_keyframe
	)
	if walk_motion:
		if not _walk_elbow_pick_locked:
			_walk_support_elbow_pick_a = _compute_tuner_walk_elbow_pick_a(preset, false, mode)
			_walk_weapon_elbow_pick_a = _compute_tuner_walk_elbow_pick_a(preset, true, mode)
			_walk_elbow_pick_locked = true
		var candidates: Array = ProceduralArmScript.ik_elbow_candidates(
			shoulder_local, hand_local, upper_len, lower_len, relax_min_reach
		)
		var pick_a := _walk_weapon_elbow_pick_a if dominant else _walk_support_elbow_pick_a
		var elbow_local: Vector2 = candidates[0] if pick_a else candidates[1]
		return to_global(elbow_local)
	elif _walk_elbow_pick_locked:
		_walk_elbow_pick_locked = false
	var pole_px := _resolve_tuner_elbow_pole_px(preset, dominant, mode)
	if pole_px.length_squared() > 0.0001:
		return _elbow_global_from_pole_pick(
			shoulder_global, hand_global, pole_px, upper_len, lower_len, relax_min_reach
		)
	var bend_sign: float = resolve_elbow_bend_sign(preset, dominant, mode)
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
	var clamped_hand := IKUtils.clamp_hand_for_fold_limits(
		shoulder, hand, upper_len, lower_len, fold_min_deg, fold_max_deg, relax_min_reach
	)
	return IKUtils.calculate_elbow_from_bend_sign(
		shoulder, clamped_hand, bend_sign, upper_len, lower_len
	)


func _compute_tuner_walk_elbow_pick_a(
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode
) -> bool:
	if preset == null or sprite == null or arm_controller == null or arm_controller.config == null:
		return true
	var cfg: ProceduralArmConfig = arm_controller.config
	var sx: float = absf(sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var shoulder_px: Vector2
	var hand_px: Vector2
	if dominant:
		shoulder_px = cfg.weapon_shoulder_offset_px
		hand_px = preset.resolve_walk_rest_hand_grip()
	else:
		shoulder_px = cfg.shoulder_offset_left
		hand_px = preset.resolve_walk_rest_support_hand()
	var pole_px := preset.resolve_elbow_pole_for_mode(dominant, mode)
	var shoulder := LimbPresetCoords.body_display_to_rig_local(sprite, shoulder_px)
	var hand := LimbPresetCoords.body_display_to_rig_local(sprite, hand_px)
	var pole := LimbPresetCoords.body_display_to_rig_local(sprite, pole_px)
	var upper := preset.resolve_upper_arm_length(dominant) * sx
	var lower := preset.resolve_lower_arm_length(dominant) * sx
	return ProceduralArmScript.prefers_elbow_a_near_pole(shoulder, hand, upper, lower, pole, true)


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
	if mode == WeaponLimbPreset.TunerAnimMode.WALK1 and _walk.is_pose_edit_b():
		if preset.resolve_walk1_elbow_pole_px(dominant, true).length_squared() > 0.0001:
			return
	elif mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and _gather.is_pose_edit_pull():
		if preset.resolve_gather1_elbow_pole_px(dominant, true).length_squared() > 0.0001:
			return
	elif preset.resolve_elbow_pole_for_mode(dominant, mode).length_squared() > 0.0001:
		return
	var bend_sign := resolve_elbow_bend_sign(preset, dominant, mode)
	var auto_px := LimbPresetCoords.auto_elbow_pole_display_from_global(
		sprite, shoulder_global, hand_global, preset.elbow_hint_outward, bend_sign
	)
	var pose_b := mode == WeaponLimbPreset.TunerAnimMode.WALK1 and _walk.is_pose_edit_b()
	var gather_pull := mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and _gather.is_pose_edit_pull()
	if mode == WeaponLimbPreset.TunerAnimMode.WALK1 and _walk.is_pose_edit_b():
		preset.set_walk1_elbow_pole(dominant, true, auto_px)
	elif mode == WeaponLimbPreset.TunerAnimMode.GATHER1 and _gather.is_pose_edit_pull():
		preset.set_gather1_elbow_pole(dominant, true, auto_px)
	else:
		preset.set_elbow_pole_for_mode(dominant, mode, auto_px)
	sync_elbow_bend_sign_override_from_pole_px(
		preset, dominant, mode, pose_b, gather_pull, shoulder_global, hand_global, auto_px
	)


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
	var hand_px := preset.resolve_support_hand_idle_for_idle_scan(
		raise_blend,
		_idle.scan_blend() if _idle else 0.0,
		is_idle_arm2_lowering()
	)
	if _idle != null and _idle.is_pose_edit_b():
		hand_px = preset.resolve_support_hand_idle_raised_lookback_px()
	elif _idle != null and _idle.is_pose_edit_active():
		hand_px = preset.resolve_support_hand_idle_raised_px()
	return LimbPresetCoords.body_global_from_display(sprite, hand_px)


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


func commit_row_hand_pins_from_global(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	pose_b: bool,
	gather_pull: bool,
	dominant_hand_global: Vector2,
	support_hand_global: Vector2
) -> void:
	if preset == null:
		return
	var row_id := WeaponLimbPreset.resolve_pose_row_id(mode, pose_b, gather_pull)
	if row_id == &"walk1_b" or row_id == &"gather_pull":
		var dom_px := LimbPresetCoords.body_display_from_global(sprite, dominant_hand_global)
		var sup_px := LimbPresetCoords.body_display_from_global(sprite, support_hand_global)
		preset.commit_row_hand_display_px(mode, pose_b, gather_pull, dom_px, sup_px)
		return
	set_hand_grip_from_global(preset, dominant_hand_global, mode)
	set_support_hand_for_mode(preset, mode, support_hand_global)


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
		aim_dir = _get_combat_aim_direction()
		if PlaceholderCardService:
			PlaceholderCardService.update_weapon_overlay_combat(self, weapon_type, aim_dir)
		if combat_component and combat_component.state == CombatComponent.CombatState.READY:
			combat_component.update_ready_aim(aim_dir)
	elif combat_component and combat_component.state == CombatComponent.CombatState.READY:
		if _uses_spear_keyframed_strike():
			combat_component.update_ready_aim(_get_combat_aim_direction())
		else:
			combat_component.update_ready_aim(aim_dir)
			if PlaceholderCardService:
				PlaceholderCardService.update_weapon_overlay_combat(self, weapon_type, aim_dir)
