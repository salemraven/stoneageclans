extends Control
class_name LimbTunerApp

enum AppMode { ASSEMBLE, LOCKED, TEST }

const AnimMode = WeaponLimbPreset.TunerAnimMode
const WEAPON_MENU: Array[Dictionary] = [
	{"label": "None", "type": ResourceData.ResourceType.NONE},
	{"label": "Club", "type": ResourceData.ResourceType.WOOD},
]

const LimbTunerHandleScript = preload("res://scripts/tools/limb_tuner_handle.gd")
const LimbTunerRigScript = preload("res://scripts/tools/limb_tuner_rig.gd")
const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

@onready var _stage: Node2D = $World/Stage
@onready var _rig: LimbTunerRig = $World/Stage/TunerRig
@onready var _handle_stage: Node2D = $World/HandleLayer/HandleStage
@onready var _mode_label: Label = $UI/Panel/VBox/ModeLabel
@onready var _anim_mode_option: OptionButton = $UI/Panel/VBox/Toolbar/AnimModeOption
@onready var _weapon_option: OptionButton = $UI/Panel/VBox/Toolbar/WeaponOption
@onready var _values_label: Label = $UI/Panel/VBox/ValuesLabel
@onready var _export_label: Label = $UI/Panel/VBox/ExportLabel
@onready var _status_label: Label = $UI/Panel/VBox/StatusLabel
@onready var _upper_arm_length_spin: SpinBox = $UI/Panel/VBox/ArmLengthRow/UpperArmLengthSpin
@onready var _lower_arm_length_spin: SpinBox = $UI/Panel/VBox/ArmLengthRow/LowerArmLengthSpin

@export var stage_scale: float = 4.0

var _mode: AppMode = AppMode.ASSEMBLE
var _anim_mode: AnimMode = AnimMode.IDLE
var _selected_weapon: ResourceData.ResourceType = ResourceData.ResourceType.NONE
var _preset: WeaponLimbPreset
var _shoulder_handle: LimbTunerHandle
var _hand_handle: LimbTunerHandle
var _support_shoulder_handle: LimbTunerHandle
var _support_hand_handle: LimbTunerHandle
var _spear_handle: LimbTunerHandle
var _weapon_elbow_handle: LimbTunerHandle
var _support_elbow_handle: LimbTunerHandle
var _head_handle: LimbTunerHandle
const HANDLE_RADIUS := 6.0
const HAND_HANDLE_RADIUS := 9.0
const HAND_PICK_EXTRA := 16.0
const ELBOW_CLICK_MAX_PX := 12.0
const HANDLE_Z_INDEX := 64

var _dragging_spear: bool = false
var _active_drag_handle: LimbTunerHandle = null
var _drag_start_global: Vector2 = Vector2.ZERO
var _spear_grab_offset: Vector2 = Vector2.ZERO
var _syncing_arm_length_ui: bool = false
var _syncing_dropdown_ui: bool = false


func _ready() -> void:
	_ensure_weapon_ready_action()
	process_priority = 1
	_apply_ui_theme()
	_setup_dropdowns()
	_setup_arm_length_fields()
	_spawn_handles()
	call_deferred("_finish_startup")
	if _status_label:
		_status_label.text = "Pick animation + weapon, drag handles, Save."
	var assemble_btn: Button = $UI/Panel/VBox/Buttons/AssembleBtn
	var lock_btn: Button = $UI/Panel/VBox/Buttons/LockBtn
	var test_btn: Button = $UI/Panel/VBox/Buttons/TestBtn
	var save_btn: Button = $UI/Panel/VBox/Buttons/SaveBtn
	var refresh_btn: Button = $UI/Panel/VBox/Buttons/RefreshBtn
	var reset_btn: Button = $UI/Panel/VBox/Buttons/ResetBtn
	var copy_btn: Button = $UI/Panel/VBox/Buttons/CopyBtn
	if assemble_btn:
		assemble_btn.pressed.connect(_on_assemble_pressed)
	if lock_btn:
		lock_btn.pressed.connect(_on_lock_pressed)
	if test_btn:
		test_btn.pressed.connect(_on_test_pressed)
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
	if refresh_btn:
		refresh_btn.pressed.connect(_on_refresh_pressed)
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
	if copy_btn:
		copy_btn.pressed.connect(_on_copy_pressed)


func _finish_startup() -> void:
	process_priority = -100
	_stage.scale = Vector2(stage_scale, stage_scale)
	_sync_handle_stage_transform()
	_refresh_all_handle_radii()
	if _rig:
		_rig.weapon_type = _selected_weapon
		_rig.refresh_weapon_overlay()
	_reload_all_from_disk()
	if _rig and _rig.arm_controller:
		_rig.arm_controller.set_show_endpoint_markers(false)
		_rig.arm_controller.set_show_elbow_joints(false)
		_rig.arm_controller.set_debug_draw(false)
	_update_ui()
	if _status_label:
		_status_label.text = "Loaded %s / %s. Tune each combo, then Save." % [
			_anim_mode_label(),
			_weapon_label(),
		]


func _setup_dropdowns() -> void:
	if _anim_mode_option:
		_anim_mode_option.clear()
		_anim_mode_option.add_item("Idle", AnimMode.IDLE)
		_anim_mode_option.add_item("Walk", AnimMode.WALK)
		_anim_mode_option.add_item("Attack", AnimMode.ATTACK)
		_anim_mode_option.select(AnimMode.IDLE)
		_anim_mode_option.item_selected.connect(_on_anim_mode_selected)
	if _weapon_option:
		_weapon_option.clear()
		for i in WEAPON_MENU.size():
			_weapon_option.add_item(WEAPON_MENU[i]["label"] as String, i)
		_weapon_option.select(0)
		_weapon_option.item_selected.connect(_on_weapon_selected)


func _on_anim_mode_selected(index: int) -> void:
	if _syncing_dropdown_ui:
		return
	_set_anim_mode(index as AnimMode)


func _on_weapon_selected(index: int) -> void:
	if _syncing_dropdown_ui or index < 0 or index >= WEAPON_MENU.size():
		return
	_set_weapon(WEAPON_MENU[index]["type"] as ResourceData.ResourceType)


func _set_weapon(weapon_type: ResourceData.ResourceType) -> void:
	if weapon_type == _selected_weapon:
		return
	if _mode == AppMode.ASSEMBLE and _preset != null:
		_commit_anim_mode(_anim_mode)
		LimbPresetRegistry.stage_preset(_preset)
	_selected_weapon = weapon_type
	_preset = LimbPresetRegistry.get_preset(_selected_weapon, "clansmen_1", 1)
	if _rig:
		_rig.weapon_type = _selected_weapon
		_rig.refresh_weapon_overlay()
	_refresh_rig_from_preset()
	_sync_weapon_dropdown()
	_update_weapon_handle_visibility()
	if _status_label:
		_status_label.text = "Weapon: %s — tuning %s pose." % [_weapon_label(), _anim_mode_label()]


func _sync_anim_mode_dropdown() -> void:
	if _anim_mode_option == null:
		return
	_syncing_dropdown_ui = true
	_anim_mode_option.select(_anim_mode)
	_syncing_dropdown_ui = false


func _sync_weapon_dropdown() -> void:
	if _weapon_option == null:
		return
	_syncing_dropdown_ui = true
	for i in WEAPON_MENU.size():
		if WEAPON_MENU[i]["type"] == _selected_weapon:
			_weapon_option.select(i)
			break
	_syncing_dropdown_ui = false


func _update_weapon_handle_visibility() -> void:
	if _spear_handle == null:
		return
	var show_weapon := _rig != null and _rig.has_weapon_overlay()
	_spear_handle.visible = show_weapon
	if not show_weapon:
		_spear_handle.set_draggable(false)
	else:
		_apply_handle_draggable()


func _anim_mode_label() -> String:
	match _anim_mode:
		AnimMode.WALK:
			return "Walk"
		AnimMode.ATTACK:
			return "Attack"
		_:
			return "Idle"


func _is_walk_preview_active() -> bool:
	return _anim_mode == AnimMode.WALK


func _is_attack_preview_active() -> bool:
	return _anim_mode == AnimMode.ATTACK


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center_stage()


func _center_stage() -> void:
	if _stage:
		_stage.position = _workspace_center_screen()
	_sync_handle_stage_transform()


func _sync_handle_stage_transform() -> void:
	if _handle_stage == null or _stage == null:
		return
	_handle_stage.position = _stage.position
	_handle_stage.scale = _stage.scale


func _workspace_center_screen() -> Vector2:
	var panel := get_node_or_null("UI/Panel") as Control
	var left_margin := 0.0
	if panel:
		left_margin = panel.position.x + panel.size.x + 24.0
	var workspace_w: float = maxf(size.x - left_margin, 1.0)
	return Vector2(left_margin + workspace_w * 0.5, size.y * 0.5)


func _center_character_on_stage() -> void:
	if _rig == null:
		return
	_rig.position = Vector2.ZERO
	var center := _rig.get_visual_center_on_stage()
	if center.length_squared() < 0.01:
		return
	_rig.position = -center


func _center_view() -> void:
	_center_character_on_stage()
	_sync_handle_positions()
	_center_stage()


func _apply_ui_theme() -> void:
	var panel: PanelContainer = $UI/Panel as PanelContainer
	if panel and UITheme:
		panel.add_theme_stylebox_override("panel", UITheme.get_panel_style())
	for label_path in [
		"UI/Panel/VBox/Title",
		"UI/Panel/VBox/ModeLabel",
		"UI/Panel/VBox/HelpLabel",
		"UI/Panel/VBox/ArmLengthRow/ArmLengthLabel",
		"UI/Panel/VBox/ValuesLabel",
		"UI/Panel/VBox/StatusLabel",
		"UI/Panel/VBox/ExportLabel",
	]:
		var label: Label = get_node_or_null(label_path) as Label
		if label and UITheme:
			label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)


func _input(event: InputEvent) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start_global = get_global_mouse_position()
			_active_drag_handle = _pick_handle_at(get_global_mouse_position())
			if _active_drag_handle != null:
				if _active_drag_handle == _spear_handle and _rig.weapon_overlay:
					_spear_grab_offset = _rig.weapon_handle_anchor_global() - get_global_mouse_position()
					_dragging_spear = true
				get_viewport().set_input_as_handled()
		else:
			if _active_drag_handle != null:
				var elbow_click := (
					_is_elbow_handle(_active_drag_handle)
					and _drag_start_global.distance_to(get_global_mouse_position()) <= ELBOW_CLICK_MAX_PX
				)
				if elbow_click:
					_flip_elbow_bend(_active_drag_handle == _weapon_elbow_handle)
				else:
					_commit_all_poses_to_preset()
				_clear_elbow_drag_overrides()
				get_viewport().set_input_as_handled()
			_active_drag_handle = null
			_dragging_spear = false
			_spear_grab_offset = Vector2.ZERO
			_drag_start_global = Vector2.ZERO
	elif event is InputEventMouseMotion and _active_drag_handle != null:
		_move_active_handle(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func _pick_handle_at(global_pos: Vector2) -> LimbTunerHandle:
	var best: LimbTunerHandle = null
	var best_dist: float = INF
	# Hands first — easiest to grab when overlapping club / elbow.
	for handle in [
		_hand_handle,
		_support_hand_handle,
		_weapon_elbow_handle,
		_support_elbow_handle,
		_shoulder_handle,
		_support_shoulder_handle,
		_head_handle,
		_spear_handle,
	]:
		if handle == null or not handle.draggable:
			continue
		var pick_slop := HAND_PICK_EXTRA if _is_hand_handle(handle) else 7.0
		var pick_radius: float = handle.handle_radius * absf(handle.global_scale.x) + pick_slop
		var dist: float = global_pos.distance_to(_handle_pick_center_global(handle))
		if dist <= pick_radius and dist <= best_dist:
			best_dist = dist
			best = handle
	return best


func _is_hand_handle(handle: LimbTunerHandle) -> bool:
	return handle == _hand_handle or handle == _support_hand_handle


func _is_elbow_handle(handle: LimbTunerHandle) -> bool:
	return handle == _weapon_elbow_handle or handle == _support_elbow_handle


func _flip_elbow_bend(dominant: bool) -> void:
	if _rig == null or _preset == null:
		return
	var auto_sign := _rig.elbow_bend_sign_auto_for_facing(dominant)
	var new_sign := _preset.toggle_elbow_bend_sign(dominant, _anim_mode, auto_sign)
	_preset.set_elbow_pole_for_mode(dominant, _anim_mode, Vector2.ZERO)
	_sync_active_bend_signs_to_config()
	_seed_one_elbow_pole(dominant, _anim_mode)
	_lock_arm_lines_to_handles()
	call_deferred("_sync_elbow_handles_from_arm_lines")
	if _status_label:
		var label := "1e" if dominant else "2e"
		var side := "outward +" if new_sign > 0.0 else "outward -"
		_status_label.text = "%s elbow flipped (%s) — saved with %s / %s." % [
			label,
			side,
			_anim_mode_label(),
			_weapon_label(),
		]


func _sync_active_bend_signs_to_config() -> void:
	if _preset == null or _rig == null or _rig.arm_controller == null:
		return
	var cfg := _rig.arm_controller.config
	if cfg == null:
		return
	cfg.weapon_elbow_bend_sign_active = _rig.resolve_elbow_bend_sign(_preset, true, _anim_mode)
	cfg.support_elbow_bend_sign_active = _rig.resolve_elbow_bend_sign(_preset, false, _anim_mode)


func _handle_pick_center_global(handle: LimbTunerHandle) -> Vector2:
	return handle.global_position if handle else Vector2.ZERO


func _move_active_handle(global_pos: Vector2) -> void:
	if _active_drag_handle == null:
		return
	if _active_drag_handle == _shoulder_handle:
		_shoulder_handle.global_position = global_pos
		_on_shoulder_dragged(global_pos)
	elif _active_drag_handle == _hand_handle:
		_on_hand_dragged(global_pos)
	elif _active_drag_handle == _support_shoulder_handle:
		_support_shoulder_handle.global_position = global_pos
		_on_support_shoulder_dragged(global_pos)
	elif _active_drag_handle == _support_hand_handle:
		_on_support_hand_dragged(global_pos)
	elif _active_drag_handle == _weapon_elbow_handle:
		_weapon_elbow_handle.global_position = global_pos
		_on_weapon_elbow_dragged(global_pos)
	elif _active_drag_handle == _support_elbow_handle:
		_support_elbow_handle.global_position = global_pos
		_on_support_elbow_dragged(global_pos)
	elif _active_drag_handle == _head_handle:
		_head_handle.global_position = global_pos
		_on_head_dragged(global_pos)
	elif _active_drag_handle == _spear_handle:
		var target_global: Vector2 = global_pos + _spear_grab_offset
		_on_spear_dragged(target_global)
		if _rig.uses_weapon_grip_anchor_hand() and _hand_handle:
			_set_hand_handle_position(_hand_handle, _spear_handle.global_position)
		else:
			_sync_hands_with_spear()
		_sync_spear_handle()
	_lock_arm_lines_to_handles()
	_push_preset_to_arms()
	_apply_elbow_drag_overrides()
	_sync_elbow_handles()


func _setup_arm_length_fields() -> void:
	if _upper_arm_length_spin:
		_upper_arm_length_spin.min_value = WeaponLimbPreset.TUNER_MIN_SEGMENT_PX
		_upper_arm_length_spin.max_value = 400.0
		_upper_arm_length_spin.step = 1.0
		_upper_arm_length_spin.rounded = true
		_upper_arm_length_spin.value_changed.connect(_on_arm_length_field_changed)
	if _lower_arm_length_spin:
		_lower_arm_length_spin.min_value = WeaponLimbPreset.TUNER_MIN_SEGMENT_PX
		_lower_arm_length_spin.max_value = 400.0
		_lower_arm_length_spin.step = 1.0
		_lower_arm_length_spin.rounded = true
		_lower_arm_length_spin.value_changed.connect(_on_arm_length_field_changed)


func _on_arm_length_field_changed(_value: float) -> void:
	if _syncing_arm_length_ui or _preset == null:
		return
	_apply_arm_length_from_fields()


func _apply_arm_length_from_fields() -> void:
	if _preset == null or _upper_arm_length_spin == null or _lower_arm_length_spin == null:
		return
	_preset.apply_tuner_arm_lengths(
		float(_upper_arm_length_spin.value),
		float(_lower_arm_length_spin.value)
	)
	_clamp_dominant_hand_to_reach()
	_clamp_support_hand_to_reach()
	_push_preset_to_arms()
	_lock_arm_lines_to_handles()
	_sync_elbow_handles()
	if _status_label:
		_status_label.text = "Arm length set to %.0f / %.0f (shared, both arms)" % [
			_preset.upper_arm_length,
			_preset.lower_arm_length,
		]


func _sync_arm_length_fields_from_preset() -> void:
	if _preset == null or _upper_arm_length_spin == null or _lower_arm_length_spin == null:
		return
	_syncing_arm_length_ui = true
	_upper_arm_length_spin.value = _preset.upper_arm_length
	_lower_arm_length_spin.value = _preset.lower_arm_length
	_syncing_arm_length_ui = false


func _ensure_weapon_ready_action() -> void:
	if InputMap.has_action("weapon_ready"):
		return
	InputMap.add_action("weapon_ready")
	var ev := InputEventKey.new()
	ev.keycode = KEY_SHIFT
	InputMap.action_add_event("weapon_ready", ev)


func _spawn_handles() -> void:
	var parent := _handle_stage if _handle_stage else _stage
	_shoulder_handle = LimbTunerHandleScript.new()
	_shoulder_handle.name = "ShoulderHandle"
	_shoulder_handle.set_handle_color(Color(0.9, 0.2, 0.2, 1.0))
	parent.add_child(_shoulder_handle)

	_hand_handle = LimbTunerHandleScript.new()
	_hand_handle.name = "HandHandle"
	_hand_handle.set_handle_color(Color(0.2, 0.85, 0.25, 1.0))
	parent.add_child(_hand_handle)

	_support_shoulder_handle = LimbTunerHandleScript.new()
	_support_shoulder_handle.name = "SupportShoulderHandle"
	_support_shoulder_handle.set_handle_color(Color(0.75, 0.15, 0.15, 1.0))
	parent.add_child(_support_shoulder_handle)

	_support_hand_handle = LimbTunerHandleScript.new()
	_support_hand_handle.name = "SupportHandHandle"
	_support_hand_handle.set_handle_color(Color(0.15, 0.7, 0.2, 1.0))
	parent.add_child(_support_hand_handle)

	_spear_handle = LimbTunerHandleScript.new()
	_spear_handle.name = "SpearHandle"
	_spear_handle.set_handle_color(Color(0.95, 0.75, 0.15, 1.0))
	parent.add_child(_spear_handle)

	_weapon_elbow_handle = LimbTunerHandleScript.new()
	_weapon_elbow_handle.name = "WeaponElbowHandle"
	_weapon_elbow_handle.set_handle_color(Color(0.95, 0.55, 0.1, 1.0))
	parent.add_child(_weapon_elbow_handle)

	_support_elbow_handle = LimbTunerHandleScript.new()
	_support_elbow_handle.name = "SupportElbowHandle"
	_support_elbow_handle.set_handle_color(Color(0.2, 0.75, 0.85, 1.0))
	parent.add_child(_support_elbow_handle)

	_head_handle = LimbTunerHandleScript.new()
	_head_handle.name = "HeadNeckHandle"
	_head_handle.set_handle_color(Color(0.45, 0.75, 0.95, 1.0))
	parent.add_child(_head_handle)
	for handle in [
		_shoulder_handle,
		_hand_handle,
		_support_shoulder_handle,
		_support_hand_handle,
		_spear_handle,
		_weapon_elbow_handle,
		_support_elbow_handle,
		_head_handle,
	]:
		_apply_uniform_handle_radius(handle)
	_apply_handle_number_labels()


func _apply_uniform_handle_radius(handle: LimbTunerHandle) -> void:
	if handle == null:
		return
	var base_radius := HAND_HANDLE_RADIUS if _is_hand_handle(handle) else HANDLE_RADIUS
	var target_global: float = base_radius * absf(_handle_stage.scale.x if _handle_stage else 1.0)
	var parent_scale: float = absf(handle.global_scale.x)
	if parent_scale < 0.001:
		parent_scale = 1.0
	handle.set_handle_radius(target_global / parent_scale)
	handle.z_as_relative = false
	handle.z_index = HANDLE_Z_INDEX


func _refresh_all_handle_radii() -> void:
	for handle in [
		_shoulder_handle,
		_hand_handle,
		_support_shoulder_handle,
		_support_hand_handle,
		_spear_handle,
		_weapon_elbow_handle,
		_support_elbow_handle,
		_head_handle,
	]:
		_apply_uniform_handle_radius(handle)


func _apply_handle_number_labels() -> void:
	## 1 = dominant arm, 2 = off arm, 3 = weapon — fixed; never swaps with facing.
	if _shoulder_handle:
		_shoulder_handle.set_side_label("1")
	if _hand_handle:
		_hand_handle.set_side_label("1h")
	if _weapon_elbow_handle:
		_weapon_elbow_handle.set_side_label("1e")
	if _support_shoulder_handle:
		_support_shoulder_handle.set_side_label("2")
	if _support_hand_handle:
		_support_hand_handle.set_side_label("2h")
	if _support_elbow_handle:
		_support_elbow_handle.set_side_label("2e")
	if _spear_handle:
		_spear_handle.set_side_label("3")
	if _head_handle:
		_head_handle.set_side_label("H")


func _sync_spear_handle() -> void:
	if _rig == null or _spear_handle == null:
		return
	_ensure_handle_on_stage(_spear_handle)
	if _active_drag_handle == _spear_handle:
		return
	if _rig.uses_weapon_grip_anchor_hand() and _hand_handle:
		_spear_handle.global_position = _hand_handle.global_position
	elif _active_drag_handle != _spear_handle:
		_spear_handle.global_position = _rig.weapon_handle_anchor_global()


func _sync_dominant_grip_stack(mode: AnimMode) -> void:
	if _rig == null or _preset == null or not _rig.uses_weapon_grip_anchor_hand():
		return
	if _active_drag_handle == _hand_handle or _active_drag_handle == _spear_handle:
		return
	_rig.snap_hand_grip_to_weapon_anchor(_preset, mode == AnimMode.ATTACK)
	var grip_global := _rig.dominant_grip_global_from_preset(_preset, mode)
	grip_global = _rig.clamp_hand_global_to_arm_reach(
		_preset, _shoulder_handle.global_position, grip_global
	)
	_rig.align_weapon_overlay_to_hand_grip_global(_preset, grip_global, mode)
	grip_global = _rig.dominant_grip_global_from_preset(_preset, mode)
	_set_hand_handle_position(_hand_handle, grip_global)
	_set_hand_handle_position(_spear_handle, grip_global)


func _process(_delta: float) -> void:
	if _rig == null or _preset == null:
		return
	_poll_walk_input()
	_poll_attack_preview()
	_process_combat_input()
	_push_preset_to_arms()
	if _mode == AppMode.ASSEMBLE:
		if _is_shift_ready_preview():
			_apply_shift_ready_preview()
		elif _is_thrust_animating():
			_sync_spear_grip_handles()
		_sync_assemble_preview()
	else:
		if _rig.arm_controller:
			_rig.arm_controller.clear_all_endpoint_overrides()
		if _active_drag_handle == null and not _is_thrust_animating():
			_sync_handle_positions()
		if _is_thrust_animating():
			_sync_handles_from_live_arms()
	_update_ui()
	if _mode == AppMode.ASSEMBLE and _active_drag_handle == null:
		call_deferred("_sync_elbow_handles_from_arm_lines")


func _sync_elbow_handles_from_arm_lines() -> void:
	if _rig == null or _rig.arm_controller == null or _active_drag_handle != null:
		return
	if _weapon_elbow_handle and _active_drag_handle != _weapon_elbow_handle:
		_weapon_elbow_handle.global_position = _rig.elbow_joint_global_from_arms(true)
	if (
		_support_elbow_handle
		and _active_drag_handle != _support_elbow_handle
		and _active_drag_handle != _weapon_elbow_handle
	):
		_support_elbow_handle.global_position = _rig.elbow_joint_global_from_arms(false)


func _poll_walk_input() -> void:
	if _rig == null:
		return
	if _is_thrust_animating():
		_rig.set_walk_direction(0)
		return
	var dir := 0
	if _is_walk_preview_active():
		dir = 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_LEFT):
		dir = -1
	elif Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_RIGHT):
		dir = 1
	_rig.set_walk_direction(dir)


func _poll_attack_preview() -> void:
	if not _is_attack_preview_active() or _mode != AppMode.ASSEMBLE:
		return
	if _rig == null or _rig.combat_component == null or _preset == null:
		return
	if _active_drag_handle != null or _dragging_spear:
		return
	if _attack_preview_busy():
		return
	_prepare_attack_preview_pose()
	_trigger_assemble_strike()


func _attack_preview_busy() -> bool:
	if _rig == null or _rig.combat_component == null:
		return true
	if _is_thrust_animating():
		return true
	var ostate: int = WeaponOverlayCombat.get_overlay_state(_rig)
	if (
		ostate == WeaponOverlayCombat.OverlayState.STRIKING
		or ostate == WeaponOverlayCombat.OverlayState.RECOVERING
	):
		return true
	var cstate: int = _rig.combat_component.state
	return cstate != CombatComponent.CombatState.IDLE


func _prepare_attack_preview_pose() -> void:
	if _rig == null or _preset == null:
		return
	if _anim_mode == AnimMode.IDLE:
		_rig.apply_preset_overlay_idle(_preset)
		if _rig.uses_weapon_grip_anchor_hand():
			_rig.snap_dominant_hand_grip_to_weapon_anchor(_preset)
		_sync_hands_with_spear()
		_lock_arm_lines_to_handles()


func _trigger_assemble_strike() -> void:
	if _rig == null or _rig.combat_component == null:
		return
	var aim := Vector2(1.0, 0.0)
	if _rig.aim_dir.length_squared() > 0.0001:
		aim = _rig.aim_dir.normalized()
	_rig.aim_dir = aim
	if _rig.combat_component.state != CombatComponent.CombatState.READY:
		_enter_assemble_combat_ready_for_attack_preview()
	var aim_strike := _rig._get_cursor_aim_direction()
	if aim_strike.length_squared() < 0.0001:
		aim_strike = aim
	_rig.combat_component.commit_strike(aim_strike)


func _enter_assemble_combat_ready_for_attack_preview() -> void:
	if _rig == null or _rig.combat_component == null or _preset == null:
		return
	var aim := Vector2(1.0, 0.0)
	_rig.aim_dir = aim
	_rig.combat_component.aim_dir = aim
	if _rig.combat_component.state == CombatComponent.CombatState.IDLE:
		_rig.combat_component.state = CombatComponent.CombatState.READY
	WeaponOverlayCombat.set_overlay_state(_rig, WeaponOverlayCombat.OverlayState.READY)
	_rig.apply_preset_overlay_idle(_preset)
	_sync_spear_grip_handles()


func _process_combat_input() -> void:
	if _rig.combat_component == null:
		return
	if _mode == AppMode.ASSEMBLE:
		_process_combat_input_assemble()
		return
	var can_interact := _mode == AppMode.TEST and Input.is_action_pressed("weapon_ready")
	if not can_interact:
		if _rig.combat_component.state == CombatComponent.CombatState.READY:
			_rig.combat_component.cancel_ready()
			WeaponOverlayCombat.set_overlay_state(_rig, WeaponOverlayCombat.OverlayState.IDLE)
			_refresh_rig_from_preset()
		return

	if Input.is_action_just_pressed("weapon_ready") and _rig.combat_component.state == CombatComponent.CombatState.IDLE:
		var aim := _rig._get_cursor_aim_direction()
		_rig.combat_component.enter_ready(aim)
	if Input.is_action_pressed("weapon_ready") and not _dragging_spear and _active_drag_handle != _spear_handle:
		_rig.sync_combat_overlay(true)
	if Input.is_action_pressed("weapon_ready") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if _rig.combat_component.state == CombatComponent.CombatState.READY:
			if _active_drag_handle == _spear_handle or _dragging_spear:
				return
			var aim := _rig._get_cursor_aim_direction()
			_rig.aim_dir = aim
			_rig.combat_component.commit_strike(aim)


func _process_combat_input_assemble() -> void:
	## Preset overlay for preview; combat READY only so Shift+click can play strike tween.
	if Input.is_action_just_pressed("weapon_ready"):
		_enter_assemble_combat_ready()
	elif Input.is_action_just_released("weapon_ready"):
		_exit_assemble_combat_ready()
	elif Input.is_action_pressed("weapon_ready") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if _active_drag_handle == _spear_handle or _dragging_spear:
			return
		if _rig.combat_component.state != CombatComponent.CombatState.READY:
			_enter_assemble_combat_ready()
		var aim := _rig._get_cursor_aim_direction()
		_rig.aim_dir = aim
		_rig.combat_component.commit_strike(aim)


func _enter_assemble_combat_ready() -> void:
	if _rig == null or _rig.combat_component == null:
		return
	var aim := _rig._get_cursor_aim_direction()
	if aim.length_squared() > 0.0001:
		_rig.aim_dir = aim.normalized()
	_rig.combat_component.aim_dir = _rig.aim_dir
	if _rig.combat_component.state == CombatComponent.CombatState.IDLE:
		_rig.combat_component.state = CombatComponent.CombatState.READY
	WeaponOverlayCombat.set_overlay_state(_rig, WeaponOverlayCombat.OverlayState.READY)
	_apply_shift_ready_preview()


func _exit_assemble_combat_ready() -> void:
	if _rig == null or _rig.combat_component == null:
		return
	if _rig.combat_component.state == CombatComponent.CombatState.READY:
		_rig.combat_component.state = CombatComponent.CombatState.IDLE
	_refresh_rig_from_preset()
	_sync_handle_positions()
	_lock_arm_lines_to_handles()


func _weapon_label() -> String:
	match _selected_weapon:
		ResourceData.ResourceType.NONE:
			return "none"
		ResourceData.ResourceType.WOOD:
			return "club"
		ResourceData.ResourceType.SPEAR:
			return "spear"
		ResourceData.ResourceType.AXE:
			return "axe"
		_:
			return "weapon"


func _hand_sync_mode() -> AnimMode:
	if _rig and _rig.arm_controller and _rig.arm_controller.is_combat_pose_active():
		return AnimMode.ATTACK
	return _anim_mode


func _is_shift_ready_preview() -> bool:
	return (
		_mode == AppMode.ASSEMBLE
		and Input.is_action_pressed("weapon_ready")
		and not _is_thrust_animating()
		and _active_drag_handle == null
	)


func _apply_shift_ready_preview() -> void:
	## Hold Shift in Assemble: show ready spear pose + both hands on shaft (from preset).
	if _rig == null or _preset == null:
		return
	var aim := _rig._get_cursor_aim_direction()
	_rig.aim_dir = aim
	_rig.apply_preset_overlay_ready(_preset, aim)
	_sync_spear_grip_handles()


func _sync_assemble_preview() -> void:
	_sync_hands_with_spear()
	_sync_spear_handle()
	_lock_arm_lines_to_handles()
	_apply_elbow_drag_overrides()
	_sync_elbow_handles()


func _ensure_handle_on_stage(handle: LimbTunerHandle) -> void:
	if handle == null or _handle_stage == null:
		return
	if handle.get_parent() != _handle_stage:
		var grip_global := handle.global_position
		handle.reparent(_handle_stage)
		handle.global_position = grip_global
		_apply_uniform_handle_radius(handle)


func _sync_handle_positions() -> void:
	if _rig == null or _preset == null:
		return
	if _active_drag_handle != _shoulder_handle:
		_shoulder_handle.global_position = _rig.shoulder_global_from_preset(_preset)
	if _active_drag_handle != _support_shoulder_handle:
		_support_shoulder_handle.global_position = _rig.support_shoulder_global_from_preset(_preset)
	_sync_hands_with_spear()
	_sync_spear_handle()
	_sync_elbow_handles()


func _sync_elbow_handles() -> void:
	if _rig == null or _preset == null:
		return
	var mode := _hand_sync_mode()
	if _active_drag_handle != _weapon_elbow_handle:
		_sync_one_elbow_from_ik(true, mode)
	if _active_drag_handle != _support_elbow_handle and _active_drag_handle != _weapon_elbow_handle:
		_sync_one_elbow_from_ik(false, mode)
	if _active_drag_handle != _head_handle and _head_handle:
		_head_handle.global_position = _rig.neck_socket_global()


func _sync_one_elbow_from_ik(dominant: bool, mode: AnimMode) -> void:
	var elbow_handle: LimbTunerHandle = _weapon_elbow_handle if dominant else _support_elbow_handle
	var shoulder_handle: LimbTunerHandle = _shoulder_handle if dominant else _support_shoulder_handle
	var hand_handle: LimbTunerHandle = _hand_handle if dominant else _support_hand_handle
	if elbow_handle == null or shoulder_handle == null or hand_handle == null:
		return
	if _rig.arm_controller:
		var live := _rig.elbow_joint_global_from_arms(dominant)
		elbow_handle.global_position = live
		return
	elbow_handle.global_position = _rig.elbow_joint_global_from_handles(
		_preset,
		dominant,
		mode,
		shoulder_handle.global_position,
		hand_handle.global_position
	)


func _push_preset_to_arms() -> void:
	if _preset == null or LimbPresetRegistry == null:
		return
	LimbPresetRegistry.stage_preset(_preset)
	if _rig and _rig.arm_controller and _rig.arm_controller.config:
		LimbPresetRegistry.apply_to_arm_config(_rig.arm_controller.config, _preset)
		_sync_active_bend_signs_to_config()


func _lock_arm_lines_to_handles() -> void:
	if _rig == null or _rig.arm_controller == null:
		return
	if _shoulder_handle and _hand_handle:
		_rig.arm_controller.set_weapon_endpoints_from_global(
			_shoulder_handle.global_position,
			_hand_handle.global_position
		)
	if _support_shoulder_handle and _support_hand_handle:
		_rig.arm_controller.set_support_endpoints_from_global(
			_support_shoulder_handle.global_position,
			_support_hand_handle.global_position
		)


func _apply_elbow_drag_overrides() -> void:
	if _rig == null or _rig.arm_controller == null:
		return
	var ac := _rig.arm_controller
	if _active_drag_handle == _weapon_elbow_handle and _weapon_elbow_handle:
		ac.set_weapon_elbow_override_from_global(_weapon_elbow_handle.global_position)
		ac.clear_support_elbow_override()
	elif _active_drag_handle == _support_elbow_handle and _support_elbow_handle:
		ac.set_support_elbow_override_from_global(_support_elbow_handle.global_position)
		ac.clear_weapon_elbow_override()
	else:
		ac.clear_all_elbow_overrides()


func _clear_elbow_drag_overrides() -> void:
	if _rig and _rig.arm_controller:
		_rig.arm_controller.clear_all_elbow_overrides()


func _set_hand_handle_position(handle: LimbTunerHandle, global_pos: Vector2) -> void:
	if handle == null:
		return
	_ensure_handle_on_stage(handle)
	handle.global_position = global_pos


func _sync_hands_with_spear() -> void:
	if _rig == null or _preset == null:
		return
	var mode := _hand_sync_mode()
	var ready_hands := _use_ready_support_hand()
	if _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay():
		_sync_dominant_grip_stack(mode)
	elif _active_drag_handle != _hand_handle:
		var hand_global := _rig.hand_grip_global_from_preset(_preset, mode)
		hand_global = _rig.clamp_hand_global_to_arm_reach(
			_preset, _shoulder_handle.global_position, hand_global
		)
		_set_hand_handle_position(_hand_handle, hand_global)
	if ready_hands:
		if _active_drag_handle != _support_hand_handle:
			var support_global := _rig.support_hand_global_for_mode(_preset, mode)
			support_global = _rig.clamp_hand_global_to_arm_reach(
				_preset, _support_shoulder_handle.global_position, support_global
			)
			_set_hand_handle_position(_support_hand_handle, support_global)
	elif _active_drag_handle != _support_hand_handle:
		var idle_global := _rig.support_hand_global_for_mode(_preset, mode)
		idle_global = _rig.clamp_hand_global_to_arm_reach(
			_preset, _support_shoulder_handle.global_position, idle_global
		)
		_set_hand_handle_position(_support_hand_handle, idle_global)


func _use_ready_support_hand() -> bool:
	if not WeaponLimbPreset.uses_two_hand_grip(_selected_weapon):
		return false
	if _rig and _rig.arm_controller and _rig.arm_controller.is_combat_pose_active():
		return true
	return _anim_mode == AnimMode.ATTACK


func _sync_spear_grip_handles() -> void:
	## Ready/attack: yellow spear moves, both green grips follow.
	_sync_hands_with_spear()
	_sync_spear_handle()


func _is_thrust_animating() -> bool:
	if _rig == null or _rig.arm_controller == null:
		return false
	return _rig.arm_controller.is_thrust_active()


func _sync_handles_from_live_arms() -> void:
	if _rig == null or _rig.arm_controller == null:
		return
	var weapon: Dictionary = _rig.arm_controller.get_weapon_arm_global_endpoints()
	var support: Dictionary = _rig.arm_controller.get_support_arm_global_endpoints()
	if _shoulder_handle:
		_shoulder_handle.global_position = weapon.get("shoulder", _shoulder_handle.global_position)
	if _support_shoulder_handle:
		_support_shoulder_handle.global_position = support.get("shoulder", _support_shoulder_handle.global_position)
	_sync_hands_with_spear()
	_sync_spear_handle()


func _refresh_rig_from_preset() -> void:
	if _rig == null or _preset == null:
		return
	_rig.apply_preset_overlay_for_mode(_preset, _anim_mode)
	_push_preset_to_arms()
	_maybe_seed_hand_grip_at_weapon_anchor()
	if _rig and _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay():
		_rig.snap_hand_grip_to_weapon_anchor(_preset, _anim_mode == AnimMode.ATTACK)
	_preset.set_shared_arm_lengths(_preset.upper_arm_length, _preset.lower_arm_length)
	_seed_elbow_poles_for_mode(_anim_mode)
	_sync_handle_positions()
	_apply_handle_draggable()
	_update_weapon_handle_visibility()


func _maybe_seed_hand_grip_at_weapon_anchor() -> void:
	if _rig == null or _preset == null:
		return
	if not _rig.uses_weapon_grip_anchor_hand() or not _rig.has_weapon_overlay():
		return
	if _preset.resolve_hand_grip_for_mode(AnimMode.IDLE).length_squared() > 0.01:
		return
	_rig.snap_dominant_hand_grip_to_weapon_anchor(_preset)


func _seed_elbow_poles_for_mode(mode: AnimMode) -> void:
	if _rig == null or _preset == null:
		return
	_seed_one_elbow_pole(true, mode)
	_seed_one_elbow_pole(false, mode)


func _seed_one_elbow_pole(dominant: bool, mode: AnimMode) -> void:
	if _shoulder_handle == null or _hand_handle == null:
		return
	if _support_shoulder_handle == null or _support_hand_handle == null:
		return
	var shoulder_g := _shoulder_handle.global_position if dominant else _support_shoulder_handle.global_position
	var hand_g := _hand_handle.global_position if dominant else _support_hand_handle.global_position
	_rig.seed_elbow_pole_if_unset(_preset, dominant, mode, shoulder_g, hand_g)


func _set_anim_mode(mode: AnimMode) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if mode != _anim_mode:
		_commit_anim_mode(_anim_mode)
	_anim_mode = mode
	if mode == AnimMode.WALK:
		_preset.seed_walk_from_idle_if_unset()
	elif mode == AnimMode.ATTACK:
		_preset.seed_attack_from_idle_if_unset()
	if mode != AnimMode.WALK and _rig:
		_rig.set_walk_direction(0)
	if mode != AnimMode.ATTACK:
		_exit_assemble_combat_ready()
	_refresh_rig_from_preset()
	_sync_anim_mode_dropdown()
	if _status_label:
		_status_label.text = "Tuning %s — %s (shoulders shared across modes)." % [
			_anim_mode_label(),
			_weapon_label(),
		]
	_update_ui()


func _apply_handle_draggable() -> void:
	var can_drag := _mode == AppMode.ASSEMBLE
	var two_hand := WeaponLimbPreset.uses_two_hand_grip(_selected_weapon)
	_shoulder_handle.set_draggable(can_drag)
	_hand_handle.set_draggable(can_drag)
	_support_shoulder_handle.set_draggable(can_drag)
	_support_hand_handle.set_draggable(
		can_drag and (_anim_mode != AnimMode.ATTACK or two_hand)
	)
	var weapon_drag := can_drag and _rig != null and _rig.has_weapon_overlay()
	_spear_handle.set_draggable(weapon_drag)
	if _weapon_elbow_handle:
		_weapon_elbow_handle.set_draggable(can_drag)
	if _support_elbow_handle:
		_support_elbow_handle.set_draggable(can_drag)
	if _head_handle:
		_head_handle.set_draggable(can_drag)


func _on_shoulder_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	_rig.set_shoulder_from_global(_preset, global_pos)
	_clamp_dominant_hand_to_reach()


func _clamp_dominant_hand_to_reach() -> void:
	if _rig == null or _preset == null or _shoulder_handle == null or _hand_handle == null:
		return
	var mode := _anim_mode
	var clamped := _rig.clamp_hand_global_to_arm_reach(
		_preset, _shoulder_handle.global_position, _hand_handle.global_position
	)
	_set_hand_handle_position(_hand_handle, clamped)
	if _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay():
		_rig.align_weapon_overlay_to_hand_grip_global(_preset, clamped, mode)
		var stacked := _rig.dominant_grip_global_from_preset(_preset, mode)
		_set_hand_handle_position(_hand_handle, stacked)
		_set_hand_handle_position(_spear_handle, stacked)
	else:
		_rig.set_hand_grip_from_global(_preset, clamped, mode)


func _clamp_support_hand_to_reach() -> void:
	if _rig == null or _preset == null or _support_shoulder_handle == null or _support_hand_handle == null:
		return
	var clamped := _rig.clamp_hand_global_to_arm_reach(
		_preset, _support_shoulder_handle.global_position, _support_hand_handle.global_position
	)
	_set_hand_handle_position(_support_hand_handle, clamped)
	_rig.set_support_hand_for_mode(_preset, _anim_mode, clamped)


func _on_hand_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	var mode := _anim_mode
	var clamped := _rig.clamp_hand_global_to_arm_reach(
		_preset, _shoulder_handle.global_position, global_pos
	)
	if _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay():
		_rig.align_weapon_overlay_to_hand_grip_global(_preset, clamped, mode)
		var stacked := _rig.dominant_grip_global_from_preset(_preset, mode)
		_set_hand_handle_position(_hand_handle, stacked)
		_set_hand_handle_position(_spear_handle, stacked)
	else:
		var adjusted := _rig.project_hand_grip_drag_global(clamped, _preset, mode)
		_rig.set_hand_grip_from_global(_preset, adjusted, mode)
		_set_hand_handle_position(_hand_handle, _rig.hand_grip_global_from_preset(_preset, mode))


func _on_support_shoulder_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	_rig.set_support_shoulder_from_global(_preset, global_pos)
	_clamp_support_hand_to_reach()


func _on_support_hand_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	var clamped := _rig.clamp_hand_global_to_arm_reach(
		_preset, _support_shoulder_handle.global_position, global_pos
	)
	if _anim_mode == AnimMode.ATTACK and WeaponLimbPreset.uses_two_hand_grip(_selected_weapon):
		var adjusted := _rig.project_support_hand_grip_drag_global(clamped, _preset)
		_rig.set_support_hand_from_global(_preset, adjusted)
		_set_hand_handle_position(
			_support_hand_handle, _rig.support_hand_global_from_preset(_preset)
		)
	else:
		_rig.set_support_hand_for_mode(_preset, _anim_mode, clamped)
		_set_hand_handle_position(_support_hand_handle, clamped)


func _on_weapon_elbow_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if _shoulder_handle == null or _hand_handle == null:
		return
	_rig.set_elbow_joint_from_global(
		_preset,
		true,
		_anim_mode,
		global_pos,
		_shoulder_handle.global_position,
		_hand_handle.global_position
	)


func _on_support_elbow_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if _support_shoulder_handle == null or _support_hand_handle == null:
		return
	_rig.set_elbow_joint_from_global(
		_preset,
		false,
		_anim_mode,
		global_pos,
		_support_shoulder_handle.global_position,
		_support_hand_handle.global_position
	)


func _on_head_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	_rig.set_neck_socket_from_global(global_pos)


func _on_spear_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if _rig.weapon_overlay == null or not _rig.has_weapon_overlay():
		return
	if _rig.uses_weapon_grip_anchor_hand():
		var mode := _anim_mode
		var clamped := _rig.clamp_hand_global_to_arm_reach(
			_preset, _shoulder_handle.global_position, global_pos
		)
		_rig.align_weapon_overlay_to_hand_grip_global(_preset, clamped, mode)
		var stacked := _rig.dominant_grip_global_from_preset(_preset, mode)
		_set_hand_handle_position(_hand_handle, stacked)
		_set_hand_handle_position(_spear_handle, stacked)
		return
	var display_px := _rig.move_weapon_overlay_global(global_pos)
	_preset.set_overlay_for_mode(_anim_mode, display_px)


func _commit_anim_mode(mode: AnimMode) -> void:
	if _rig == null or _preset == null:
		return
	if _shoulder_handle:
		_rig.set_shoulder_from_global(_preset, _shoulder_handle.global_position)
	if _support_shoulder_handle:
		_rig.set_support_shoulder_from_global(_preset, _support_shoulder_handle.global_position)
	if _hand_handle:
		_rig.set_hand_grip_from_global(_preset, _hand_handle.global_position, mode)
	if _support_hand_handle:
		if mode == AnimMode.ATTACK and WeaponLimbPreset.uses_two_hand_grip(_selected_weapon):
			_rig.set_support_hand_from_global(_preset, _support_hand_handle.global_position)
		else:
			_rig.set_support_hand_for_mode(_preset, mode, _support_hand_handle.global_position)
	if _rig.has_weapon_overlay():
		var display_px := _rig.display_px_from_overlay_position()
		_preset.set_overlay_for_mode(mode, display_px)
	if _weapon_elbow_handle and _shoulder_handle and _hand_handle:
		_rig.set_elbow_joint_from_global(
			_preset,
			true,
			mode,
			_weapon_elbow_handle.global_position,
			_shoulder_handle.global_position,
			_hand_handle.global_position
		)
	if _support_elbow_handle and _support_shoulder_handle and _support_hand_handle:
		_rig.set_elbow_joint_from_global(
			_preset,
			false,
			mode,
			_support_elbow_handle.global_position,
			_support_shoulder_handle.global_position,
			_support_hand_handle.global_position
		)


func _commit_all_poses_to_preset() -> void:
	## Shared anchors + active animation mode; other modes stay from last switch / disk.
	_commit_anim_mode(_anim_mode)
	if _head_handle and _rig:
		_rig.set_neck_socket_from_global(_head_handle.global_position)


func _on_assemble_pressed() -> void:
	_mode = AppMode.ASSEMBLE
	if _rig.combat_component and _rig.combat_component.state == CombatComponent.CombatState.READY:
		_rig.combat_component.cancel_ready()
	_refresh_rig_from_preset()
	_update_ui()


func _on_lock_pressed() -> void:
	_mode = AppMode.LOCKED
	if _rig.combat_component and _rig.combat_component.state == CombatComponent.CombatState.READY:
		_rig.combat_component.cancel_ready()
	_refresh_rig_from_preset()
	_update_ui()


func _on_test_pressed() -> void:
	_mode = AppMode.TEST
	_refresh_rig_from_preset()
	_update_ui()


func _on_save_pressed() -> void:
	if LimbPresetRegistry == null or _preset == null:
		return
	_commit_all_poses_to_preset()
	var err := LimbPresetRegistry.save_preset(_preset)
	var layout := _rig.get_layer_layout() if _rig else null
	var layout_err := OK
	if layout == null:
		layout_err = ERR_CANT_CREATE
	else:
		layout_err = CharacterCardPartsRegistry.save_layout(layout)
	if err == OK and layout_err == OK:
		_reload_all_from_disk()
	if _status_label:
		if err == OK and layout_err == OK:
			_status_label.text = (
				"Saved + refreshed. Preset: %s | head layout: %s"
				% [
					LimbPresetRegistry.preset_path(_preset.weapon_type, _preset.body_card_id),
					CharacterCardPartsRegistry.DEFAULT_LAYOUT_PATH,
				]
			)
		else:
			_status_label.text = "Save failed (arms=%s, head=%s)" % [str(err), str(layout_err)]


func _on_refresh_pressed() -> void:
	_reload_all_from_disk()
	if _status_label:
		_status_label.text = "Reloaded presets + head layout from disk."


func _reload_all_from_disk() -> void:
	_preset = LimbPresetRegistry.reload_preset(_selected_weapon, "clansmen_1")
	if _rig:
		_rig.reload_mannequin_from_layout()
		_rig.refresh_weapon_overlay()
	_refresh_rig_from_preset()
	_center_view()
	_update_ui()


func _on_reset_pressed() -> void:
	_reload_all_from_disk()
	_mode = AppMode.ASSEMBLE
	_anim_mode = AnimMode.IDLE
	_sync_anim_mode_dropdown()
	_refresh_rig_from_preset()
	if _status_label:
		_status_label.text = "Reloaded %s preset from disk: %s" % [
			_weapon_label(),
			LimbPresetRegistry.preset_path(_selected_weapon, "clansmen_1"),
		]


func _on_copy_pressed() -> void:
	if _export_label == null or _preset == null:
		return
	_commit_all_poses_to_preset()
	var json := JSON.stringify(_preset.to_export_dict(), "\t")
	_export_label.text = json
	DisplayServer.clipboard_set(json)
	if _status_label:
		_status_label.text = "Copied JSON to clipboard"


func _update_ui() -> void:
	if _mode_label:
		var walk_name := ""
		if _rig and _rig.is_walking():
			walk_name = " | walking %s" % ("left" if _rig.get_walk_direction() < 0 else "right")
		_mode_label.text = "Mode: %s | Animation: %s | Weapon: %s%s" % [
			_mode_name(), _anim_mode_label(), _weapon_label(), walk_name
		]
	if _values_label and _preset:
		var two_hand := WeaponLimbPreset.uses_two_hand_grip(_selected_weapon)
		var off_attack := str(_preset.support_hand_offset_px) if two_hand else "(one-hand: body only)"
		var head_line := ""
		if _rig:
			var layer := _rig.get_layer_layout()
			if layer:
				head_line = "H head: neck socket %s | head pivot %s\n" % [
					str(layer.body_neck_socket_px),
					str(layer.head_pivot_px),
				]
		_values_label.text = (
			head_line
			+ "Idle — hand %s | elbow %s | overlay %s\n"
			+ "Walk — hand %s | elbow %s | overlay %s\n"
			+ "Attack — hand %s | elbow %s | overlay %s\n"
			+ "Off arm idle/walk %s | attack %s\n"
			+ "Arm length (shared, cap %.0f/%.0f): %.0f / %.0f%s"
		) % [
			str(_preset.hand_grip_offset_px),
			str(_preset.weapon_elbow_pole_idle_px),
			str(_preset.overlay_offset_idle_px),
			str(_preset.resolve_hand_grip_for_mode(AnimMode.WALK)),
			str(_preset.walk_weapon_elbow_pole_px),
			str(_preset.resolve_overlay_for_mode(AnimMode.WALK)),
			str(_preset.resolve_hand_grip_ready_px()),
			str(_preset.weapon_elbow_pole_ready_px),
			str(_preset.ready_offset_px),
			str(_preset.support_hand_idle_offset_px),
			off_attack,
			WeaponLimbPreset.TUNER_MAX_UPPER_ARM_PX,
			WeaponLimbPreset.TUNER_MAX_LOWER_ARM_PX,
			_preset.upper_arm_length,
			_preset.lower_arm_length,
			_reach_warning_suffix(),
		]
	_sync_arm_length_fields_from_preset()
	_sync_anim_mode_dropdown()
	_sync_weapon_dropdown()
	_apply_handle_draggable()
	_update_weapon_handle_visibility()


func _reach_warning_suffix() -> String:
	var warnings := _collect_reach_warnings()
	if warnings.is_empty():
		return ""
	return "\n⚠ Reach: " + ", ".join(warnings)


func _collect_reach_warnings() -> PackedStringArray:
	var out: PackedStringArray = []
	if _is_out_of_reach(_shoulder_handle, _hand_handle):
		out.append("dominant hand")
	if _is_out_of_reach(_support_shoulder_handle, _support_hand_handle):
		out.append("off hand")
	return out


func _is_out_of_reach(shoulder_handle: LimbTunerHandle, hand_handle: LimbTunerHandle) -> bool:
	if _rig == null or _rig.sprite == null or _preset == null:
		return false
	if shoulder_handle == null or hand_handle == null:
		return false
	var rig := _rig.sprite.get_parent() as Node2D
	if rig == null:
		return false
	var shoulder_rig := rig.to_local(shoulder_handle.global_position)
	var hand_rig := rig.to_local(hand_handle.global_position)
	var sx: float = absf(_rig.sprite.scale.x)
	if sx < 0.001:
		sx = 1.0
	var max_reach: float = _preset.tuner_max_reach_px() * sx
	return shoulder_rig.distance_to(hand_rig) > max_reach + 0.5


func _mode_name() -> String:
	match _mode:
		AppMode.ASSEMBLE:
			return "ASSEMBLE"
		AppMode.LOCKED:
			return "LOCKED"
		AppMode.TEST:
			return "TEST"
	return "?"
