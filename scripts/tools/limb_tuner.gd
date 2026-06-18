extends Control
class_name LimbTunerApp

enum AppMode { ASSEMBLE, LOCKED, TEST }
enum PoseTab { IDLE, READY }

const LimbTunerHandleScript = preload("res://scripts/tools/limb_tuner_handle.gd")
const LimbTunerRigScript = preload("res://scripts/tools/limb_tuner_rig.gd")
const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")

@onready var _stage: Node2D = $World/Stage
@onready var _rig: LimbTunerRig = $World/Stage/TunerRig
@onready var _mode_label: Label = $UI/Panel/VBox/ModeLabel
@onready var _pose_tab_idle: Button = $UI/Panel/VBox/PoseTabs/IdleTab
@onready var _pose_tab_ready: Button = $UI/Panel/VBox/PoseTabs/ReadyTab
@onready var _values_label: Label = $UI/Panel/VBox/ValuesLabel
@onready var _export_label: Label = $UI/Panel/VBox/ExportLabel
@onready var _status_label: Label = $UI/Panel/VBox/StatusLabel

@export var stage_scale: float = 4.0
@export var tuning_weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.WOOD

var _mode: AppMode = AppMode.ASSEMBLE
var _pose_tab: PoseTab = PoseTab.IDLE
var _preset: WeaponLimbPreset
var _shoulder_handle: LimbTunerHandle
var _hand_handle: LimbTunerHandle
var _support_shoulder_handle: LimbTunerHandle
var _support_hand_handle: LimbTunerHandle
var _spear_handle: LimbTunerHandle
var _dragging_spear: bool = false
var _active_drag_handle: LimbTunerHandle = null
var _spear_grab_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_ensure_weapon_ready_action()
	process_priority = 1
	_apply_ui_theme()
	_spawn_handles()
	call_deferred("_finish_startup")
	if _pose_tab_idle:
		_pose_tab_idle.pressed.connect(func() -> void: _set_pose_tab(PoseTab.IDLE))
	if _pose_tab_ready:
		_pose_tab_ready.pressed.connect(func() -> void: _set_pose_tab(PoseTab.READY))
	if _status_label:
		_status_label.text = "Assemble: drag handles. Shift = ready | Shift+click = attack swing."
	var assemble_btn: Button = $UI/Panel/VBox/Buttons/AssembleBtn
	var lock_btn: Button = $UI/Panel/VBox/Buttons/LockBtn
	var test_btn: Button = $UI/Panel/VBox/Buttons/TestBtn
	var save_btn: Button = $UI/Panel/VBox/Buttons/SaveBtn
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
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
	if copy_btn:
		copy_btn.pressed.connect(_on_copy_pressed)


func _finish_startup() -> void:
	_center_stage()
	_stage.scale = Vector2(stage_scale, stage_scale)
	if _rig:
		_rig.weapon_type = tuning_weapon_type
		_rig.refresh_weapon_overlay()
	_preset = LimbPresetRegistry.reload_preset(tuning_weapon_type, "clansmen_1")
	_refresh_rig_from_preset()
	if _rig and _rig.arm_controller:
		_rig.arm_controller.set_show_endpoint_markers(false)
	_update_ui()
	if _status_label:
		_status_label.text = "Loaded %s preset. Tune idle + ready tabs, then Save." % _weapon_label()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center_stage()


func _center_stage() -> void:
	if _stage:
		_stage.position = size * 0.5


func _apply_ui_theme() -> void:
	var panel: PanelContainer = $UI/Panel as PanelContainer
	if panel and UITheme:
		panel.add_theme_stylebox_override("panel", UITheme.get_panel_style())
	for label_path in [
		"UI/Panel/VBox/Title",
		"UI/Panel/VBox/ModeLabel",
		"UI/Panel/VBox/HelpLabel",
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
			_active_drag_handle = _pick_handle_at(get_global_mouse_position())
			if _active_drag_handle != null:
				if _active_drag_handle == _spear_handle and _rig.weapon_overlay:
					_spear_grab_offset = _rig.weapon_overlay.global_position - get_global_mouse_position()
					_dragging_spear = true
				get_viewport().set_input_as_handled()
		else:
			if _active_drag_handle != null:
				_commit_all_poses_to_preset()
				get_viewport().set_input_as_handled()
			_active_drag_handle = null
			_dragging_spear = false
			_spear_grab_offset = Vector2.ZERO
	elif event is InputEventMouseMotion and _active_drag_handle != null:
		_move_active_handle(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func _pick_handle_at(global_pos: Vector2) -> LimbTunerHandle:
	var best: LimbTunerHandle = null
	var best_dist: float = INF
	for handle in [
		_shoulder_handle,
		_hand_handle,
		_support_shoulder_handle,
		_support_hand_handle,
		_spear_handle,
	]:
		if handle == null or not handle.draggable:
			continue
		var pick_radius: float = handle.handle_radius * handle.global_scale.x + 7.0
		var dist: float = global_pos.distance_to(handle.global_position)
		if dist <= pick_radius and dist <= best_dist:
			best_dist = dist
			best = handle
	return best


func _move_active_handle(global_pos: Vector2) -> void:
	if _active_drag_handle == null:
		return
	if _active_drag_handle == _shoulder_handle:
		_shoulder_handle.global_position = global_pos
		_on_shoulder_dragged(global_pos)
	elif _active_drag_handle == _hand_handle:
		_hand_handle.global_position = global_pos
		_on_hand_dragged(global_pos)
	elif _active_drag_handle == _support_shoulder_handle:
		_support_shoulder_handle.global_position = global_pos
		_on_support_shoulder_dragged(global_pos)
	elif _active_drag_handle == _support_hand_handle:
		_support_hand_handle.global_position = global_pos
		_on_support_hand_dragged(global_pos)
	elif _active_drag_handle == _spear_handle:
		var target_global: Vector2 = global_pos + _spear_grab_offset
		_on_spear_dragged(target_global)
		if _rig.weapon_overlay:
			_spear_handle.global_position = _rig.weapon_overlay.global_position
		_sync_hands_with_spear()
	_lock_arm_lines_to_handles()
	_push_preset_to_arms()


func _ensure_weapon_ready_action() -> void:
	if InputMap.has_action("weapon_ready"):
		return
	InputMap.add_action("weapon_ready")
	var ev := InputEventKey.new()
	ev.keycode = KEY_SHIFT
	InputMap.action_add_event("weapon_ready", ev)


func _spawn_handles() -> void:
	_shoulder_handle = LimbTunerHandleScript.new()
	_shoulder_handle.name = "ShoulderHandle"
	_shoulder_handle.set_handle_color(Color(0.9, 0.2, 0.2, 1.0))
	_shoulder_handle.handle_radius = 6.0
	_stage.add_child(_shoulder_handle)

	_hand_handle = LimbTunerHandleScript.new()
	_hand_handle.name = "HandHandle"
	_hand_handle.set_handle_color(Color(0.2, 0.85, 0.25, 1.0))
	_hand_handle.handle_radius = 5.5
	_stage.add_child(_hand_handle)

	_support_shoulder_handle = LimbTunerHandleScript.new()
	_support_shoulder_handle.name = "SupportShoulderHandle"
	_support_shoulder_handle.set_handle_color(Color(0.75, 0.15, 0.15, 1.0))
	_support_shoulder_handle.handle_radius = 5.5
	_stage.add_child(_support_shoulder_handle)

	_support_hand_handle = LimbTunerHandleScript.new()
	_support_hand_handle.name = "SupportHandHandle"
	_support_hand_handle.set_handle_color(Color(0.15, 0.7, 0.2, 1.0))
	_support_hand_handle.handle_radius = 5.0
	_stage.add_child(_support_hand_handle)

	_spear_handle = LimbTunerHandleScript.new()
	_spear_handle.name = "SpearHandle"
	_spear_handle.set_handle_color(Color(0.95, 0.75, 0.15, 1.0))
	_spear_handle.handle_radius = 5.0
	_stage.add_child(_spear_handle)
	_apply_handle_number_labels()


func _apply_handle_number_labels() -> void:
	## 1 = dominant arm, 2 = off arm, 3 = weapon — fixed; never swaps with facing.
	if _shoulder_handle:
		_shoulder_handle.set_side_label("1")
	if _hand_handle:
		_hand_handle.set_side_label("1")
	if _support_shoulder_handle:
		_support_shoulder_handle.set_side_label("2")
	if _support_hand_handle:
		_support_hand_handle.set_side_label("2")
	if _spear_handle:
		_spear_handle.set_side_label("3")


func _process(_delta: float) -> void:
	if _rig == null or _preset == null:
		return
	_process_combat_input()
	_push_preset_to_arms()
	if _mode == AppMode.ASSEMBLE:
		if _is_shift_ready_preview():
			_apply_shift_ready_preview()
		elif _is_thrust_animating():
			_sync_spear_grip_handles()
		_lock_arm_lines_to_handles()
	else:
		if _rig.arm_controller:
			_rig.arm_controller.clear_all_endpoint_overrides()
		if _active_drag_handle == null and not _is_thrust_animating():
			_sync_handle_positions()
		if _is_thrust_animating():
			_sync_handles_from_live_arms()
	_update_ui()


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
	match tuning_weapon_type:
		ResourceData.ResourceType.WOOD:
			return "club"
		ResourceData.ResourceType.SPEAR:
			return "spear"
		ResourceData.ResourceType.AXE:
			return "axe"
		_:
			return "weapon"


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


func _sync_handle_positions() -> void:
	if _rig == null or _preset == null:
		return
	if _active_drag_handle != _shoulder_handle:
		_shoulder_handle.global_position = _rig.shoulder_global_from_preset(_preset)
	if _active_drag_handle != _support_shoulder_handle:
		_support_shoulder_handle.global_position = _rig.support_shoulder_global_from_preset(_preset)
	_sync_hand_handles_from_spear()
	if _active_drag_handle != _spear_handle and _rig.weapon_overlay:
		_spear_handle.global_position = _rig.weapon_overlay.global_position


func _push_preset_to_arms() -> void:
	if _preset == null or LimbPresetRegistry == null:
		return
	LimbPresetRegistry.stage_preset(_preset)
	if _rig and _rig.arm_controller and _rig.arm_controller.config:
		LimbPresetRegistry.apply_to_arm_config(_rig.arm_controller.config, _preset)


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


func _sync_hand_handles_from_spear() -> void:
	_sync_hands_with_spear()


func _sync_hands_with_spear() -> void:
	if _rig == null or _preset == null:
		return
	var ready_hands := _use_ready_support_hand()
	if _active_drag_handle != _hand_handle:
		_hand_handle.global_position = _rig.hand_grip_global_from_preset(_preset, ready_hands)
	if ready_hands:
		if _active_drag_handle != _support_hand_handle:
			_support_hand_handle.global_position = _rig.support_hand_global_from_preset(_preset)
	elif _active_drag_handle != _support_hand_handle:
		_support_hand_handle.global_position = _rig.support_hand_idle_global_from_preset(_preset)


func _sync_support_hand_handle() -> void:
	if _rig == null or _preset == null or _support_hand_handle == null:
		return
	if _active_drag_handle == _support_hand_handle:
		return
	if _use_ready_support_hand():
		_support_hand_handle.global_position = _rig.support_hand_global_from_preset(_preset)
	else:
		_support_hand_handle.global_position = _rig.support_hand_idle_global_from_preset(_preset)


func _use_ready_support_hand() -> bool:
	if not WeaponLimbPreset.uses_two_hand_grip(tuning_weapon_type):
		return false
	if _rig and _rig.arm_controller and _rig.arm_controller.is_combat_pose_active():
		return true
	return _pose_tab == PoseTab.READY


func _sync_spear_grip_handles() -> void:
	## Ready/attack: yellow spear moves, both green grips follow.
	_sync_hands_with_spear()
	if _rig and _rig.weapon_overlay and _spear_handle:
		_spear_handle.global_position = _rig.weapon_overlay.global_position


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
	_sync_hand_handles_from_spear()
	if _rig.weapon_overlay and _spear_handle:
		_spear_handle.global_position = _rig.weapon_overlay.global_position


func _refresh_rig_from_preset() -> void:
	if _rig == null or _preset == null:
		return
	if _pose_tab == PoseTab.IDLE:
		_rig.apply_preset_overlay_idle(_preset)
	else:
		_rig.apply_preset_overlay_ready(_preset, Vector2(1.0, 0.0))
	_push_preset_to_arms()
	_sync_handle_positions()
	_apply_handle_draggable()


func _set_pose_tab(tab: PoseTab) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if tab != _pose_tab:
		_commit_pose_tab(_pose_tab)
	_pose_tab = tab
	if tab == PoseTab.READY and _preset.hand_grip_ready_offset_px.length_squared() < 0.0001:
		# Seed upper-shaft grip so dominant + off hands don't start stacked in Ready tab.
		_preset.hand_grip_ready_offset_px = Vector2(0.0, 95.0)
	_refresh_rig_from_preset()
	if _status_label:
		_status_label.text = "Loaded %s pose from memory (shoulders shared; off-hand has idle + ready slots)." % (
			"IDLE" if tab == PoseTab.IDLE else "READY"
		)
	_update_ui()


func _apply_handle_draggable() -> void:
	var can_drag := _mode == AppMode.ASSEMBLE
	var two_hand := WeaponLimbPreset.uses_two_hand_grip(tuning_weapon_type)
	_shoulder_handle.set_draggable(can_drag)
	_hand_handle.set_draggable(can_drag)
	_support_shoulder_handle.set_draggable(can_drag)
	# One-handed weapons: off-hand only tunable in Idle (rest pose), never on weapon in Ready.
	_support_hand_handle.set_draggable(can_drag and (_pose_tab == PoseTab.IDLE or two_hand))
	_spear_handle.set_draggable(can_drag)


func _on_shoulder_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	_rig.set_shoulder_from_global(_preset, global_pos)


func _on_hand_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	_rig.set_hand_grip_from_global(_preset, global_pos, _pose_tab == PoseTab.READY)


func _on_support_shoulder_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	_rig.set_support_shoulder_from_global(_preset, global_pos)


func _on_support_hand_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if _pose_tab == PoseTab.READY and WeaponLimbPreset.uses_two_hand_grip(tuning_weapon_type):
		_rig.set_support_hand_from_global(_preset, global_pos)
	else:
		_rig.set_support_hand_idle_from_global(_preset, global_pos)


func _on_spear_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if _rig.weapon_overlay == null:
		return
	var display_px := _rig.move_weapon_overlay_global(global_pos)
	if _use_ready_support_hand():
		_preset.ready_offset_px = display_px
	else:
		_preset.overlay_offset_idle_px = display_px


func _commit_pose_tab(tab: PoseTab) -> void:
	if _rig == null or _preset == null:
		return
	if _shoulder_handle:
		_rig.set_shoulder_from_global(_preset, _shoulder_handle.global_position)
	if _support_shoulder_handle:
		_rig.set_support_shoulder_from_global(_preset, _support_shoulder_handle.global_position)
	if _hand_handle:
		_rig.set_hand_grip_from_global(_preset, _hand_handle.global_position, tab == PoseTab.READY)
	if _support_hand_handle:
		if tab == PoseTab.READY and WeaponLimbPreset.uses_two_hand_grip(tuning_weapon_type):
			_rig.set_support_hand_from_global(_preset, _support_hand_handle.global_position)
		else:
			_rig.set_support_hand_idle_from_global(_preset, _support_hand_handle.global_position)
	if _rig.weapon_overlay:
		var display_px := _rig.display_px_from_overlay_position()
		if tab == PoseTab.READY:
			_preset.ready_offset_px = display_px
		else:
			_preset.overlay_offset_idle_px = display_px


func _commit_all_poses_to_preset() -> void:
	## Shared anchors + active tab go live; other tab stays from last tab switch / disk.
	_commit_pose_tab(_pose_tab)


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
	if _status_label:
		if err == OK:
			_status_label.text = (
				"Saved idle + ready: %s"
				% LimbPresetRegistry.preset_path(_preset.weapon_type, _preset.body_card_id)
			)
		else:
			_status_label.text = "Save failed (%s)" % str(err)


func _on_reset_pressed() -> void:
	_preset = LimbPresetRegistry.reload_preset(tuning_weapon_type, "clansmen_1")
	_mode = AppMode.ASSEMBLE
	_pose_tab = PoseTab.IDLE
	_refresh_rig_from_preset()
	if _status_label:
		_status_label.text = "Reloaded %s preset from disk: %s" % [
			_weapon_label(),
			LimbPresetRegistry.preset_path(tuning_weapon_type, "clansmen_1"),
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
		var pose_name := "IDLE" if _pose_tab == PoseTab.IDLE else "READY"
		_mode_label.text = "Mode: %s | Pose: %s | %s" % [_mode_name(), pose_name, _weapon_label()]
	if _values_label and _preset:
		var two_hand := WeaponLimbPreset.uses_two_hand_grip(tuning_weapon_type)
		var off_ready := str(_preset.support_hand_offset_px) if two_hand else "(one-hand: idle only)"
		_values_label.text = (
			"1 arm (dominant): shoulder %s | hand %s | ready hand %s\n"
			+ "2 arm (off): shoulder %s | idle hand %s | ready hand %s\n"
			+ "3 weapon: idle %s | ready %s\n"
			+ "Arm length: %.0f / %.0f"
		) % [
			str(_preset.shoulder_offset_px),
			str(_preset.hand_grip_offset_px),
			str(_preset.resolve_hand_grip_ready_px()),
			str(_preset.support_shoulder_offset_px),
			str(_preset.support_hand_idle_offset_px),
			off_ready,
			str(_preset.overlay_offset_idle_px),
			str(_preset.ready_offset_px),
			_preset.upper_arm_length,
			_preset.lower_arm_length,
		]
	_apply_handle_draggable()


func _mode_name() -> String:
	match _mode:
		AppMode.ASSEMBLE:
			return "ASSEMBLE"
		AppMode.LOCKED:
			return "LOCKED"
		AppMode.TEST:
			return "TEST"
	return "?"
