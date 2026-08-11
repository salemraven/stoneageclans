extends Control
class_name LimbTunerApp

enum AppMode { ASSEMBLE, LOCKED, TEST }

const AnimMode = WeaponLimbPreset.TunerAnimMode
const TunerIdlePreviewScript = preload("res://scripts/tools/tuner_idle_preview.gd")
const WalkArmSwingScript = preload("res://scripts/systems/walk_arm_swing.gd")
const GatherArmMotionScript = preload("res://scripts/systems/gather_arm_motion.gd")
const TunerPreviewInstrumentationScript = preload(
	"res://scripts/tools/tuner_preview_instrumentation.gd"
)
const AnimCatalog = preload("res://scripts/config/character_animation_catalog.gd")
const HOLDABLE_MENU: Array[Dictionary] = [
	{"label": "Nothing (empty hands)", "type": ResourceData.ResourceType.NONE},
	{"label": "Club", "type": ResourceData.ResourceType.WOOD},
	{"label": "Spear", "type": ResourceData.ResourceType.SPEAR},
	{"label": "Axe", "type": ResourceData.ResourceType.AXE},
	{"label": "Pick", "type": ResourceData.ResourceType.PICK},
	{"label": "Oldowan tool", "type": ResourceData.ResourceType.OLDOWAN},
]
## Back-compat alias for tests / older references.
const WEAPON_MENU: Array[Dictionary] = HOLDABLE_MENU

const LimbTunerHandleScript = preload("res://scripts/tools/limb_tuner_handle.gd")
const LimbTunerRigScript = preload("res://scripts/tools/limb_tuner_rig.gd")
const LimbAnimationBakerScript = preload("res://scripts/tools/limb_animation_baker.gd")
const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

@onready var _stage: Node2D = $World/Stage
@onready var _rig: LimbTunerRig = $World/Stage/TunerRig
@onready var _handle_stage: Node2D = $World/HandleLayer/HandleStage
@onready var _panel: PanelContainer = $UI/Panel
@onready var _holdable_grid: GridContainer = $UI/Panel/Margin/VBox/SelectSection/HoldableRow/HoldableGrid
@onready var _category_buttons: HBoxContainer = $UI/Panel/Margin/VBox/SelectSection/CategoryRow/CategoryButtons
@onready var _variant_buttons: HBoxContainer = $UI/Panel/Margin/VBox/SelectSection/VariantRow/VariantButtons
@onready var _play_pause_btn: Button = $UI/Panel/Margin/VBox/PreviewSection/PlayPauseBtn
@onready var _weapon_section: VBoxContainer = $UI/Panel/Margin/VBox/WeaponSection
@onready var _weapon_rotation_spin: SpinBox = $UI/Panel/Margin/VBox/WeaponSection/WeaponRotationRow/WeaponRotationSpin
@onready var _summary_label: Label = $UI/Panel/Margin/VBox/SummaryLabel
@onready var _status_label: Label = $UI/Panel/Margin/VBox/StatusLabel
@onready var _upper_arm_length_spin: SpinBox = $UI/Panel/Margin/VBox/ArmsSection/ArmLengthRow/UpperArmLengthSpin
@onready var _lower_arm_length_spin: SpinBox = $UI/Panel/Margin/VBox/ArmsSection/ArmLengthRow/LowerArmLengthSpin
@onready var _arm_thickness_spin: SpinBox = $UI/Panel/Margin/VBox/ArmsSection/ArmThicknessRow/ArmThicknessSpin

@export var stage_scale: float = 1.0
## Screen-space pin size only — character scale stays 1:1 with Main (stage_scale = 1).
@export var handle_ui_scale: float = 4.0
## Preview-only camera zoom (does not change saved poses or in-game scale). Scroll wheel over workspace.
@export var view_zoom: float = 3.0
@export var view_zoom_min: float = 1.0
@export var view_zoom_max: float = 6.0
@export var view_zoom_step: float = 1.12
const VIEW_FIT_PADDING_PX := 24.0

var _mode: AppMode = AppMode.ASSEMBLE
var _anim_mode: AnimMode = AnimMode.IDLE
var _selected_weapon: ResourceData.ResourceType = ResourceData.ResourceType.NONE
var _preset: WeaponLimbPreset
var _shoulder_handle: LimbTunerHandle
var _hand_handle: LimbTunerHandle
var _support_shoulder_handle: LimbTunerHandle
var _support_hand_handle: LimbTunerHandle
var _spear_handle: LimbTunerHandle
var _spear_grip_2_handle: LimbTunerHandle
var _weapon_elbow_handle: LimbTunerHandle
var _support_elbow_handle: LimbTunerHandle
var _head_handle: LimbTunerHandle
var _was_combat_preview_busy: bool = false
var _club_combat_pins_sync_queued: bool = false
## Attack row spear: "windup" | "strike" — which overlay row Save all writes.
var _spear_attack_edit_target: String = ""
var _baker
var _bake_review: Window
var _bake_in_progress: bool = false
const SHOULDER_HANDLE_RADIUS := 5.0
const HANDLE_RADIUS := 6.0
const HAND_HANDLE_RADIUS := 9.0
const HAND_PICK_EXTRA := 16.0
const ELBOW_CLICK_MAX_PX := 12.0
const PIN_CLICK_MAX_PX := 18.0
const _IDLE_CLUB_UI_HIDE_PATHS: Array[String] = [
	"UI/Panel/Margin/VBox/SelectSection",
	"UI/Panel/Margin/VBox/PreviewSection",
	"UI/Panel/Margin/VBox/ArmsSection",
	"UI/Panel/Margin/VBox/SummaryLabel",
	"UI/Panel/Margin/VBox/ActionsSection/ActionGrid/ResetPoseBtn",
	"UI/Panel/Margin/VBox/ActionsSection/ActionGrid/ReloadBtn",
	"UI/Panel/Margin/VBox/ActionsSection/ActionGrid/ResetAnchorsBtn",
	"UI/Panel/Margin/VBox/ActionsSection/CopyBtn",
]
const PIN_DRAG_MIN_PX := 10.0
const WINDUP_IDLE_PREVIEW_AMP_SCALE := 0.72
const TUNER_MOVE_SPEED_PX := 200.0
const HANDLE_Z_INDEX := 64
const TUNER_Z_ARM1 := 0
const TUNER_Z_HEAD := 2
const TUNER_Z_ARM2 := 3

var _dragging_spear: bool = false
var _dragging_spear_grip_2: bool = false
var _active_drag_handle: LimbTunerHandle = null
var _pending_drag_handle: LimbTunerHandle = null
var _pending_elbow_click: LimbTunerHandle = null
var _handle_drag_active: bool = false
var _drag_start_global: Vector2 = Vector2.ZERO
var _spear_grab_offset: Vector2 = Vector2.ZERO
var _spear_grip_2_grab_offset: Vector2 = Vector2.ZERO
var _syncing_arm_length_ui: bool = false
var _syncing_weapon_rotation_ui: bool = false
var _syncing_arm_thickness_ui: bool = false
var _syncing_picker_ui: bool = false
var _idle_club_minimal_active: bool = false
var _elbow_click_target: LimbTunerHandle = null
var _anim_playing: bool = false
var _selected_category: StringName = AnimCatalog.CATEGORY_IDLE
var _holdable_button_map: Dictionary = {}
var _category_button_map: Dictionary = {}
var _variant_button_map: Dictionary = {}
var _stage_view_initialized: bool = false
var _preview_instrumentation: RefCounted


func _ready() -> void:
	_ensure_weapon_ready_action()
	process_priority = 1
	_apply_ui_theme()
	_setup_animation_picker()
	_setup_arm_length_fields()
	_setup_arm_thickness_fields()
	_setup_weapon_rotation_field()
	_spawn_handles()
	call_deferred("_finish_startup")
	if _status_label:
		_status_label.text = "Pick a pose, Play to preview, drag pins, Save."
	var save_btn: Button = $UI/Panel/Margin/VBox/ActionsSection/ActionGrid/SaveBtn
	var reset_pose_btn: Button = $UI/Panel/Margin/VBox/ActionsSection/ActionGrid/ResetPoseBtn
	var reload_btn: Button = $UI/Panel/Margin/VBox/ActionsSection/ActionGrid/ReloadBtn
	var reset_anchors_btn: Button = $UI/Panel/Margin/VBox/ActionsSection/ActionGrid/ResetAnchorsBtn
	var copy_btn: Button = $UI/Panel/Margin/VBox/ActionsSection/CopyBtn
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
	if reset_pose_btn:
		reset_pose_btn.pressed.connect(_on_reset_pose_pressed)
	if reload_btn:
		reload_btn.pressed.connect(_on_reload_pressed)
	if reset_anchors_btn:
		reset_anchors_btn.pressed.connect(_on_reset_anchors_pressed)
	if copy_btn:
		copy_btn.pressed.connect(_on_copy_pressed)
	var bake_btn: Button = $UI/Panel/Margin/VBox/ActionsSection/ActionGrid/BakeBtn
	if bake_btn:
		bake_btn.pressed.connect(_on_bake_pressed)
	if _play_pause_btn:
		_play_pause_btn.pressed.connect(_on_play_pause_pressed)


func _finish_startup() -> void:
	# Run after TunerRig + strike tweens so yellow grip pin reads the live club pose.
	process_priority = -128
	if _wants_club_windup_edit_startup() or _wants_idle_club1_edit_startup() or _wants_idle_club1_place_startup():
		_selected_weapon = ResourceData.ResourceType.WOOD
	if _wants_spear_preview_startup() or _wants_spear_windup_edit_startup():
		_selected_weapon = ResourceData.ResourceType.SPEAR
	if _rig:
		_rig.weapon_type = _selected_weapon
		_rig.refresh_weapon_overlay()
		if _rig.arm_controller:
			_rig.arm_controller.set_show_endpoint_markers(false)
			_rig.arm_controller.set_show_elbow_joints(false)
			_rig.arm_controller.set_debug_draw(false)
			_rig.arm_controller.initialize_tuner_arm_layers()
		_apply_tuner_draw_layers()
		if _rig.has_method("_sync_tuner_arm_process"):
			_rig.call("_sync_tuner_arm_process")
	_load_preset_from_disk()
	_sync_animation_picker_ui()
	if _wants_gather1_edit_startup():
		call_deferred("_begin_gather1_edit_session")
	if _wants_club_windup_edit_startup():
		call_deferred("_begin_club_windup_edit_session")
	if _wants_idle_club1_edit_startup():
		call_deferred("_begin_idle_club1_edit_session")
	if _wants_idle_club1_place_startup():
		call_deferred("_begin_idle_club1_place_session")
	elif _wants_spear_windup_edit_startup():
		call_deferred("_begin_spear_windup_edit_session")
	elif _wants_spear_strike_edit_startup():
		call_deferred("_begin_spear_strike_edit_session")
	elif _wants_spear_preview_startup():
		call_deferred("_begin_spear_preview_session")
	elif not _has_special_startup():
		call_deferred("_begin_club_preview_session")
	_update_ui()
	_sync_preview_playback()
	call_deferred("_apply_fixed_stage_view")
	call_deferred("_ensure_handles_on_overlay")
	_baker = LimbAnimationBakerScript.new()
	_bake_review = get_node_or_null("BakeReviewWindow") as Window
	_preview_instrumentation = TunerPreviewInstrumentationScript.new()
	if TunerPreviewInstrumentationScript.wants_cli_instrument():
		_preview_instrumentation.enabled = true
		_preview_instrumentation.log_to_file = true
		_preview_instrumentation.reset_session()
		if _status_label:
			_status_label.text = "Instrumentation ON — log: Tests/logs/tuner_preview_instrument.jsonl"


func prepare_bake_sample(clip: String, phase: float) -> void:
	if _rig == null or _preset == null:
		return
	var grip_mode := _grip_mode_for_bake_clip(clip)
	var overlay_mode := _overlay_mode_for_bake_clip(clip)
	_rig.apply_preset_overlay_for_mode(_preset, overlay_mode)
	_rig.apply_bake_sample(clip, phase)
	var walk_swing := clip == LimbAnimationBakerScript.CLIP_WALK
	var gather_motion := clip == LimbAnimationBakerScript.CLIP_GATHER1
	_rig.sync_bake_weapon_overlay(_preset, grip_mode, walk_swing, gather_motion)


## Headless / cloud agent: pick holdable + clip before bake_from_tuner().
func configure_for_cli_bake(weapon_slug: String, clip: String) -> Dictionary:
	var normalized_clip := clip.strip_edges().to_lower()
	if normalized_clip.is_empty() or LimbAnimationBakerScript.anim_mode_for_clip(normalized_clip) < 0:
		return {"ok": false, "error": "Unknown clip %r (idle, idle1, walk, gather1)." % clip}
	if not LimbAnimationBakerScript.is_known_weapon_slug(weapon_slug):
		return {"ok": false, "error": "Unknown weapon %r (none, club, spear, axe, pick, oldowan)." % weapon_slug}
	var weapon_type: ResourceData.ResourceType = LimbAnimationBakerScript.weapon_type_from_slug(weapon_slug)
	var anim_mode: AnimMode = LimbAnimationBakerScript.anim_mode_for_clip(normalized_clip) as AnimMode
	_set_weapon(weapon_type, false)
	_set_anim_mode(anim_mode)
	return {
		"ok": true,
		"clip": normalized_clip,
		"weapon": LimbAnimationBakerScript.weapon_slug(weapon_type),
	}


func _grip_mode_for_bake_clip(clip: String) -> AnimMode:
	match clip:
		LimbAnimationBakerScript.CLIP_WALK:
			if WeaponLimbPreset.is_walk_mode(_anim_mode):
				return _anim_mode
			return AnimMode.WALK
		LimbAnimationBakerScript.CLIP_GATHER1:
			return AnimMode.GATHER1
		LimbAnimationBakerScript.CLIP_IDLE1:
			return AnimMode.IDLE1
		_:
			return AnimMode.IDLE


func _overlay_mode_for_bake_clip(clip: String) -> AnimMode:
	if clip == LimbAnimationBakerScript.CLIP_WALK:
		return _grip_mode_for_bake_clip(clip)
	if clip == LimbAnimationBakerScript.CLIP_GATHER1:
		return AnimMode.GATHER1
	if clip == LimbAnimationBakerScript.CLIP_IDLE1:
		return AnimMode.IDLE1
	return AnimMode.IDLE


func _on_bake_pressed() -> void:
	if _bake_in_progress or _baker == null:
		return
	var clip := LimbAnimationBakerScript.clip_for_anim_mode(_anim_mode)
	if clip.is_empty():
		if _status_label:
			_status_label.text = "Pick Idle, Walk, or Gather to bake this pose."
		return
	_bake_in_progress = true
	if _status_label:
		_status_label.text = "Baking %s for %s…" % [clip, _holdable_label()]
	var result: Dictionary = await _baker.bake_from_tuner(self, clip)
	_bake_in_progress = false
	if result.get("ok", false):
		if _status_label:
			_status_label.text = "Baked %s → %s" % [clip, str(result.get("png_path", "")).get_file()]
		if _bake_review and _bake_review.has_method("show_bake"):
			_bake_review.call("show_bake", result)
	else:
		if _status_label:
			_status_label.text = "Bake failed: %s" % str(result.get("error", "unknown"))


func _sync_bake_button() -> void:
	var bake_btn: Button = $UI/Panel/Margin/VBox/ActionsSection/ActionGrid/BakeBtn
	if bake_btn == null:
		return
	var clip := LimbAnimationBakerScript.clip_for_anim_mode(_anim_mode)
	bake_btn.disabled = _bake_in_progress or clip.is_empty()
	bake_btn.tooltip_text = (
		"Export looping %s strip + JSON, then open bake review."
		% clip if not clip.is_empty() else "Attack poses are not baked yet — use Idle or Walk."
	)


func _apply_tuner_draw_layers() -> void:
	if _rig == null or _rig.body_visual == null:
		return
	if _rig.body_visual.has_method("apply_tuner_draw_layers"):
		_rig.body_visual.call("apply_tuner_draw_layers")


func _load_preset_from_disk() -> void:
	_preset = LimbPresetRegistry.reload_preset(_selected_weapon, "clansmen_1")
	if _rig:
		_rig.reload_mannequin_from_layout()
		_rig.refresh_weapon_overlay()
		_apply_tuner_draw_layers()
	_refresh_rig_from_preset()


func _ensure_handles_on_overlay() -> void:
	if _handle_stage == null:
		return
	_sync_weapon_pin_parenting()
	for handle in [
		_shoulder_handle,
		_support_shoulder_handle,
		_support_hand_handle,
		_weapon_elbow_handle,
		_support_elbow_handle,
		_head_handle,
	]:
		if handle == null:
			continue
		if handle.get_parent() != _handle_stage:
			_reparent_handle_preserve_global(handle, _handle_stage)
		_apply_uniform_handle_radius(handle)
	if _hand_handle and _hand_handle.get_parent() != _handle_stage:
		_reparent_handle_preserve_global(_hand_handle, _handle_stage)
		_apply_uniform_handle_radius(_hand_handle)
	if _spear_handle and _spear_handle.get_parent() != _handle_stage:
		_reparent_handle_preserve_global(_spear_handle, _handle_stage)
		_apply_uniform_handle_radius(_spear_handle)
	if _spear_grip_2_handle and _spear_grip_2_handle.get_parent() != _handle_stage:
		_reparent_handle_preserve_global(_spear_grip_2_handle, _handle_stage)
		_apply_uniform_handle_radius(_spear_grip_2_handle)


func _sync_weapon_pin_parenting() -> void:
	_sync_idle_club_grip_handle()


func _reparent_handle_preserve_global(handle: LimbTunerHandle, new_parent: Node2D) -> void:
	if handle == null or new_parent == null or handle.get_parent() == new_parent:
		return
	var keep_global: Vector2 = handle.global_position
	handle.reparent(new_parent)
	handle.global_position = keep_global


func _uses_world_draw_layer(_handle: LimbTunerHandle) -> bool:
	return false


func _is_idle_anim_mode() -> bool:
	return WeaponLimbPreset.is_idle_mode(_anim_mode)


func _is_idle1_anim_mode() -> bool:
	return _anim_mode == AnimMode.IDLE1


func _is_gather_anim_mode() -> bool:
	return _anim_mode == AnimMode.GATHER1


func _is_idle_club_anim_mode() -> bool:
	return _anim_mode == AnimMode.IDLE_CLUB1


func _club_windup_handle_drag_active() -> bool:
	return _is_club_windup_edit() and (
		_active_drag_handle == _hand_handle or _active_drag_handle == _spear_handle
	)


func _spear_windup_handle_drag_active() -> bool:
	return _is_spear_shaft_pose_edit() and _active_drag_handle != null and (
		_active_drag_handle == _hand_handle
		or _active_drag_handle == _spear_handle
		or _active_drag_handle == _spear_grip_2_handle
		or _active_drag_handle == _support_hand_handle
	)


func _ensure_tuner_arms_visible() -> void:
	if _rig == null or _rig.arm_controller == null:
		return
	if _is_idle_club_anim_mode() and _idle_club_minimal_active:
		return
	_rig.arm_controller.visible = true
	_rig.arm_controller.enabled = true
	_rig.arm_controller.force_show_arms = true
	_rig.arm_controller.set_process(true)
	if not _rig.arm_controller.is_tuner_arm_layers_ready():
		_rig.arm_controller.initialize_tuner_arm_layers()
	for arm_draw_name in ["Arm1Draw", "Arm2Draw"]:
		var arm_draw := _rig.get_node_or_null(arm_draw_name) as CanvasItem
		if arm_draw:
			arm_draw.visible = true


func _uses_decoupled_weapon_hand_pins() -> bool:
	## Idle Club 1 / Attack windup: club pose from overlay row — do not snap overlay to hand stack.
	if _rig == null or not _rig.uses_weapon_grip_anchor_hand():
		return false
	return _is_idle_club_anim_mode() or _is_club_windup_edit()


func _idle_club_pins_independent() -> bool:
	return _idle_club_minimal_active


func _uses_spear_grip_on_art_pins() -> bool:
	if _selected_weapon != ResourceData.ResourceType.SPEAR:
		return false
	if _is_spear_windup_pin_mode():
		return false
	if _is_idle_club_anim_mode() and _idle_club_minimal_active:
		return false
	if _is_thrust_animating():
		return false
	return true


func _is_spear_windup_pin_mode() -> bool:
	## Two-hand shaft grips: Y1/Y2 on art, 1h/2h stacked (edit row or Shift-ready preview).
	if _selected_weapon != ResourceData.ResourceType.SPEAR:
		return false
	if _is_spear_windup_edit() or _is_spear_strike_edit():
		return true
	if _mode != AppMode.ASSEMBLE:
		return false
	if _is_combat_ready_preview() or _combat_animation_busy() or _is_shift_ready_preview():
		return true
	return false


func _sync_spear_grip_pin_on_art() -> void:
	## Yellow 3 sits on saved grip px on spear art; green 1h stacks on yellow.
	if _rig == null or _spear_handle == null or _preset == null or not _rig.has_weapon_overlay():
		return
	_ensure_handle_on_stage(_spear_handle)
	if _active_drag_handle == _spear_handle:
		return
	var grip_px := _preset.resolve_hand_grip_for_mode(_hand_storage_mode())
	var grip_global := LimbPresetCoords.overlay_grip_global(_rig.weapon_overlay, grip_px)
	_set_hand_handle_position(_spear_handle, grip_global)
	if _active_drag_handle != _hand_handle:
		_set_hand_handle_position(_hand_handle, grip_global)


func _sync_spear_grip_pins_from_overlay(storage_mode: AnimMode) -> void:
	_sync_spear_grip_pin_on_art()


func _wants_idle_club1_place_startup() -> bool:
	if "--idle-club1-place" in OS.get_cmdline_user_args():
		return true
	return "--idle-club1-place" in OS.get_cmdline_args()


func _sync_idle_club_grip_handle() -> void:
	if _rig == null or _spear_handle == null or _preset == null:
		return
	if not _is_idle_club_anim_mode() or not _rig.has_weapon_overlay():
		return
	_ensure_handle_on_stage(_spear_handle)
	if _active_drag_handle == _spear_handle:
		return
	var grip_px := _preset.resolve_hand_grip_for_mode(_anim_mode)
	_spear_handle.global_position = LimbPresetCoords.overlay_grip_global(_rig.weapon_overlay, grip_px)
	_apply_uniform_handle_radius(_spear_handle)


func _wants_idle_club1_edit_startup() -> bool:
	if "--idle-club1-edit" in OS.get_cmdline_user_args():
		return true
	return "--idle-club1-edit" in OS.get_cmdline_args()


func _begin_idle_club1_edit_session() -> void:
	_ensure_club_holdable_for_idle_club1()
	_set_anim_mode(AnimMode.IDLE_CLUB1)
	_anim_playing = false
	_sync_preview_playback()
	_refresh_rig_from_preset()
	_apply_idle_club_minimal_view(true)
	_sync_idle_club_grip_handle()
	_sync_handle_positions()
	if not _rig or not _rig.has_weapon_overlay():
		push_error("Idle Club 1 failed: club overlay not visible")
		if _status_label:
			_status_label.text = "Club art failed to load — check club_clansmen_1 preset."
		return
	if _spear_handle == null or not _spear_handle.visible:
		push_error("Idle Club 1 failed: yellow grip handle not visible")
		if _status_label:
			_status_label.text = "Grip handle failed to load."
		return
	call_deferred("_center_view")
	if _status_label:
		_status_label.text = "Drag the yellow circle to the grip spot on the club, then Save all."
	var help: Label = get_node_or_null("UI/Panel/Margin/VBox/HelpLabel") as Label
	if help:
		help.text = "Club grip — drag yellow circle onto the club art, then Save all."
	var title: Label = get_node_or_null("UI/Panel/Margin/VBox/Title") as Label
	if title:
		title.text = "Club grip"
	_update_idle_club_handle_visibility()


func _is_idle_club_place_mode() -> bool:
	return _is_idle_club_anim_mode() and not _idle_club_minimal_active


func _overlay_storage_mode() -> AnimMode:
	return WeaponLimbPreset.tuner_overlay_storage_mode(_anim_mode, _selected_weapon)


func _hand_storage_mode() -> AnimMode:
	return WeaponLimbPreset.tuner_hand_grip_storage_mode(_anim_mode, _selected_weapon)


func _travel_walk_input_allowed() -> bool:
	## Idle / walk rows: A/D or arrows start in-place walk preview (like in-game travel).
	return (
		_is_idle_anim_mode()
		or _anim_mode == AnimMode.IDLE_CLUB1
		or WeaponLimbPreset.is_walk_mode(_anim_mode)
	)


func _travel_walk_swing_active() -> bool:
	return _rig != null and _rig.is_walking() and _travel_walk_input_allowed()


func _walk_swing_mode() -> AnimMode:
	if WeaponLimbPreset.is_walk_mode(_anim_mode):
		return _anim_mode
	if _travel_walk_swing_active():
		return AnimMode.WALK
	return _anim_mode


func _uses_club_walk_carry_pose() -> bool:
	## Walk + club: weapon arm uses the idle standing snapshot; support arm still swings.
	return (
		_selected_weapon == ResourceData.ResourceType.WOOD
		and _travel_walk_input_allowed()
		and (_travel_walk_swing_active() or WeaponLimbPreset.is_walk_mode(_anim_mode))
		and not _idle_club_minimal_active
	)


func _club_idle_handle_drag_active() -> bool:
	return (
		(_uses_club_walk_carry_pose() or _anim_mode == AnimMode.IDLE_CLUB1)
		and (_active_drag_handle == _hand_handle or _active_drag_handle == _spear_handle)
	)


func _hand_align_mode() -> AnimMode:
	return _hand_storage_mode()


func _apply_club_idle_body_from_none_only() -> void:
	if _preset == null or LimbPresetRegistry == null:
		return
	var none_preset: WeaponLimbPreset = LimbPresetRegistry.get_preset(
		ResourceData.ResourceType.NONE, "clansmen_1", 1
	)
	if none_preset == null:
		return
	_preset.apply_idle_club1_body_from_none(none_preset)


func _align_club_idle_club1_to_none_hand() -> void:
	if _anim_mode != AnimMode.IDLE_CLUB1 or _rig == null or _preset == null:
		return
	if not _rig.has_weapon_overlay():
		return
	_rig.apply_preset_overlay_for_mode(_preset, AnimMode.IDLE_CLUB1)
	if not _preset.idle_club1_hand_grip_is_plausible():
		return
	var none_preset: WeaponLimbPreset = LimbPresetRegistry.get_preset(
		ResourceData.ResourceType.NONE, "clansmen_1", 1
	)
	if none_preset == null:
		return
	var idle_hand_global := LimbPresetCoords.body_global_from_display(
		_rig.sprite, none_preset.hand_grip_offset_px
	)
	_rig.align_weapon_overlay_to_hand_grip_global(_preset, idle_hand_global, AnimMode.IDLE_CLUB1)


func _stack_idle_club_place_handles() -> void:
	_sync_club_idle_grip_pins_from_overlay()


func _sync_club_grip_pins_from_storage(storage_mode: AnimMode) -> void:
	## Read-only: yellow 3 + green 1h follow the club grip on the overlay art (never moves overlay).
	if _rig == null or _preset == null or not _rig.has_weapon_overlay():
		return
	if _active_drag_handle == _hand_handle or _active_drag_handle == _spear_handle:
		return
	_stack_club_grip_pins(storage_mode)


func _stack_club_grip_pins(storage_mode: AnimMode) -> void:
	if _rig == null or _preset == null or not _rig.has_weapon_overlay():
		return
	var grip_global: Vector2
	if _rig.is_windup_idle_sample_active():
		grip_global = _rig.hand_grip_global_from_windup_sample()
	else:
		grip_global = _rig.hand_grip_global_from_preset(_preset, storage_mode)
	_set_hand_handle_position(_spear_handle, grip_global)
	_set_hand_handle_position(_hand_handle, grip_global)


func _sync_club_idle_grip_pins_from_overlay() -> void:
	_sync_club_grip_pins_from_storage(_hand_storage_mode())


func _layout_club_idle_handles_and_arms() -> void:
	_sync_body_pinned_handles()
	if _support_hand_handle and _active_drag_handle != _support_hand_handle:
		var support_global := _rig.support_hand_global_for_mode(_preset, _anim_mode)
		_set_hand_handle_position(_support_hand_handle, support_global)
	_stack_idle_club_place_handles()
	_seed_elbow_poles_for_mode(_anim_mode)
	_lock_arm_lines_to_handles()
	_sync_elbow_handles()


func _bootstrap_idle_club1_from_idle_pose() -> void:
	_apply_club_idle_body_from_none_only()
	_align_club_idle_club1_to_none_hand()
	_layout_club_idle_handles_and_arms()
	_push_preset_to_arms()


func _begin_idle_club1_place_session() -> void:
	_ensure_club_holdable_for_idle_club1()
	_idle_club_minimal_active = false
	_apply_idle_club_minimal_view(false)
	_set_anim_mode(AnimMode.IDLE_CLUB1)
	_bootstrap_idle_club1_from_idle_pose()
	_anim_playing = false
	_sync_preview_playback()
	call_deferred("_center_view")
	if _status_label:
		_status_label.text = (
			"Place club in hand: drag yellow 3 (moves club) or green 1h (moves hand). "
			+ "They snap together. Save all when done."
		)
	var help: Label = get_node_or_null("UI/Panel/Margin/VBox/HelpLabel") as Label
	if help:
		help.text = (
			"Idle Club 1 placement — grip on club art is locked from step 1. "
			+ "Drag yellow 3 or green 1h; club and hand stay aligned."
		)
	var title: Label = get_node_or_null("UI/Panel/Margin/VBox/Title") as Label
	if title:
		title.text = "Club in hand"


func _ensure_club_holdable_for_idle_club1() -> void:
	if _selected_weapon == ResourceData.ResourceType.WOOD:
		return
	_selected_weapon = ResourceData.ResourceType.WOOD
	_preset = LimbPresetRegistry.get_preset(_selected_weapon, "clansmen_1", 1)
	if _rig:
		_rig.weapon_type = _selected_weapon
		_rig.refresh_weapon_overlay()
		_rig.refresh_weapon_combat_timing()
	_sync_animation_picker_ui()
	_update_weapon_handle_visibility()


func _wants_gather1_edit_startup() -> bool:
	return "--gather1-edit" in OS.get_cmdline_user_args() or "--gather1-preview" in OS.get_cmdline_user_args()


func _wants_club_windup_edit_startup() -> bool:
	if "--club-windup-edit" in OS.get_cmdline_user_args():
		return true
	return "--club-windup-edit" in OS.get_cmdline_args()


func _wants_spear_preview_startup() -> bool:
	if "--spear-preview" in OS.get_cmdline_user_args():
		return true
	return "--spear-preview" in OS.get_cmdline_args()


func _wants_spear_windup_edit_startup() -> bool:
	if "--spear-windup-edit" in OS.get_cmdline_user_args():
		return true
	return "--spear-windup-edit" in OS.get_cmdline_args()


func _wants_spear_strike_edit_startup() -> bool:
	if "--spear-strike-edit" in OS.get_cmdline_user_args():
		return true
	return "--spear-strike-edit" in OS.get_cmdline_args()


func _has_special_startup() -> bool:
	return (
		_wants_gather1_edit_startup()
		or _wants_club_windup_edit_startup()
		or _wants_idle_club1_edit_startup()
		or _wants_idle_club1_place_startup()
		or _wants_spear_preview_startup()
		or _wants_spear_windup_edit_startup()
		or _wants_spear_strike_edit_startup()
	)


func _is_club_combat_preview_mode() -> bool:
	return (
		_selected_weapon == ResourceData.ResourceType.WOOD
		and (_is_idle_anim_mode() or _anim_mode == AnimMode.IDLE_CLUB1)
	)


func _club_combat_controls_hint() -> String:
	if _preset != null and _preset.has_club_keyframed_strike():
		return "A/D walk · Shift windup · Shift+click swing"
	return "A/D walk · Shift = windup loop"


func _club_strike_input_blocked() -> bool:
	if _selected_weapon != ResourceData.ResourceType.WOOD or _preset == null:
		return false
	return not _preset.has_club_keyframed_strike()


func _apply_club_idle_carry_pose() -> void:
	## Established club idle row: overlay_offset_idle_px + hand_grip_offset_px @ 0° carry.
	if _rig == null or _preset == null:
		return
	_rig.set_shift_ready_windup_loop(false)
	_rig.clear_windup_idle_preview_sample()
	if _rig.combat_component:
		_rig.combat_component.state = CombatComponent.CombatState.IDLE
	WeaponOverlayCombat.set_overlay_state(_rig, WeaponOverlayCombat.OverlayState.IDLE)
	if _is_club_combat_preview_mode() and _anim_mode != AnimMode.IDLE:
		_set_anim_mode(AnimMode.IDLE)
	_refresh_rig_from_preset()
	_sync_handle_positions()
	_lock_arm_lines_to_handles()


func _apply_spear_idle_carry_pose() -> void:
	## Established spear idle row: overlay_offset_idle_px + hand_grip on shaft; yellow 3 + 1h stacked.
	if _rig == null or _preset == null:
		return
	if _preset:
		_preset.ensure_spear_grip_defaults()
	if _rig.combat_component:
		_rig.combat_component.state = CombatComponent.CombatState.IDLE
	WeaponOverlayCombat.set_overlay_state(_rig, WeaponOverlayCombat.OverlayState.IDLE)
	if _is_spear_combat_preview_mode() and _anim_mode != AnimMode.IDLE:
		_set_anim_mode(AnimMode.IDLE)
	_refresh_rig_from_preset()
	_sync_handle_positions()
	_lock_arm_lines_to_handles()


func _begin_club_preview_session() -> void:
	## Default entry: club combat preview on idle standing (tune before lock-in).
	_set_weapon(ResourceData.ResourceType.WOOD, false)
	_set_anim_mode(AnimMode.IDLE)
	_anim_playing = false
	_apply_club_idle_carry_pose()
	_sync_preview_playback()
	_update_ui()
	if _status_label:
		_status_label.text = (
			"Club eval · Idle — %s · yellow 3 on grip, 1h+arms follow"
			% _club_combat_controls_hint()
		)


func _begin_spear_preview_session() -> void:
	## Entry for spear tuning: idle standing + Shift ready thrust test.
	_set_weapon(ResourceData.ResourceType.SPEAR, false)
	_set_anim_mode(AnimMode.IDLE)
	_anim_playing = false
	_apply_spear_idle_carry_pose()
	_sync_preview_playback()
	_update_ui()
	if _status_label:
		_status_label.text = (
			"Spear eval · Idle — %s · yellow 3 on shaft, 1h stacked"
			% _spear_combat_controls_hint()
		)


func _begin_spear_windup_edit_session() -> void:
	_spear_attack_edit_target = "windup"
	_apply_pose_catalog_entry(ResourceData.ResourceType.SPEAR, AnimMode.ATTACK)
	_load_preset_from_disk()
	if _preset:
		_preset.seed_spear_attack_windup_if_unset()
		_preset.ensure_spear_grip_defaults()
	_refresh_rig_from_preset()
	_sync_spear_windup_handles()
	_sync_elbow_handles()
	_anim_playing = false
	_sync_preview_playback()
	_update_ui()
	if _status_label:
		_status_label.text = (
			"Spear windup edit — drag green 1h OR yellow Y1 (move spear) · Y2/2h off-hand · "
			+ "Copy = handoff · Save all = .tres"
		)


func _begin_spear_strike_edit_session() -> void:
	## Thrust peak / furthest extension — Attack row overlay writes strike_offset_px on Save all.
	_spear_attack_edit_target = "strike"
	_apply_pose_catalog_entry(ResourceData.ResourceType.SPEAR, AnimMode.ATTACK)
	_load_preset_from_disk()
	if _preset:
		_preset.seed_spear_attack_windup_if_unset()
		_preset.ensure_spear_grip_defaults()
	_refresh_rig_from_preset()
	_sync_spear_windup_handles()
	_sync_elbow_handles()
	_anim_playing = false
	_sync_preview_playback()
	_update_ui()
	if _status_label:
		_status_label.text = (
			"Spear strike peak — drag 1h/Y1 to set furthest extension · rotation spin = attack angle · "
			+ "Copy = handoff · Save all = strike_offset_px"
		)


func _spear_combat_controls_hint() -> String:
	return "A/D walk · Shift ready · Shift+click thrust"


func _is_spear_combat_preview_mode() -> bool:
	return _selected_weapon == ResourceData.ResourceType.SPEAR and _is_idle_anim_mode()


func _begin_club_windup_edit_session() -> void:
	_apply_pose_catalog_entry(ResourceData.ResourceType.WOOD, AnimMode.ATTACK)
	_load_preset_from_disk()
	_refresh_rig_from_preset()
	_sync_handle_positions()
	_lock_arm_lines_to_handles()
	_anim_playing = true
	_sync_preview_playback()
	if _status_label:
		if _preset and _preset.attack_pose_inherits_idle():
			_status_label.text = (
				"Club windup — starts from idle until Save all. "
				+ "One hand on club (1h/3); off-hand on body (2h)."
			)
		else:
			_status_label.text = (
				"Club windup — drag 1h or 3 (club + pins move together) · off-hand on body (2h) · Save all."
			)
	if _status_label and _preset and _preset.has_club_windup_idle_loop():
		_status_label.text = (
			"Club windup idle loop — rest → A → B → rest (%.0fs). Pause or drag a pin to edit."
			% _preset.club_windup_idle_loop_sec
		)


func _wants_gather1_preview_startup() -> bool:
	return "--gather1-preview" in OS.get_cmdline_user_args()


func _begin_gather1_edit_session() -> void:
	_set_anim_mode(AnimMode.GATHER1)
	_anim_playing = _wants_gather1_preview_startup()
	_sync_preview_playback()
	_refresh_rig_from_preset()
	_sync_handle_positions()
	_lock_arm_lines_to_handles()
	if _status_label:
		if _anim_playing:
			_status_label.text = (
				"Gather 1 preview — idle → bend → pick → stand. Pause to edit reach pins."
			)
		else:
			_status_label.text = (
				"Gather 1 — bent over (paused). Drag 1h / 2h for reach pose, then Save all."
			)


func _idle_preview_variant() -> String:
	return TunerIdlePreviewScript.VARIANT_ID if _is_idle1_anim_mode() else TunerIdlePreviewScript.VARIANT_BASE


func _windup_idle_preview_active() -> bool:
	return _windup_pose_edit_only()


func _sync_preview_playback() -> void:
	var idle_mode := _is_idle_anim_mode()
	var gather_mode := _is_gather_anim_mode()
	var windup_idle := _windup_idle_preview_active()
	var use_windup_loop := (
		windup_idle and _preset != null and _preset.has_club_windup_idle_loop()
	)
	var can_loop := idle_mode or gather_mode or windup_idle
	if _rig:
		_rig.set_preview_windup_mode(use_windup_loop)
		if windup_idle and not use_windup_loop and _selected_weapon == ResourceData.ResourceType.SPEAR:
			## Spear windup edit: static pose while paused (no idle bob fighting pin drags).
			_rig.set_preview_idle_mode(_anim_playing)
			_rig.set_preview_idle_variant(TunerIdlePreviewScript.VARIANT_BASE)
			_rig.set_idle_preview_amplitude_scale(WINDUP_IDLE_PREVIEW_AMP_SCALE)
		else:
			_rig.set_preview_idle_mode(idle_mode or (windup_idle and not use_windup_loop))
		_rig.set_preview_gather_mode(gather_mode)
		if idle_mode:
			_rig.set_preview_idle_variant(_idle_preview_variant())
		elif windup_idle and not use_windup_loop:
			_rig.set_preview_idle_variant(TunerIdlePreviewScript.VARIANT_BASE)
			_rig.set_idle_preview_amplitude_scale(WINDUP_IDLE_PREVIEW_AMP_SCALE)
		else:
			_rig.set_idle_preview_amplitude_scale(1.0)
		if not can_loop:
			_anim_playing = false
		_rig.set_preview_playing(_anim_playing and can_loop)
	_update_play_button()


func _update_play_button() -> void:
	if _play_pause_btn == null:
		return
	if WeaponLimbPreset.is_walk_mode(_anim_mode):
		_play_pause_btn.disabled = true
		_play_pause_btn.text = "A/D or ← → to walk"
	elif _anim_mode == AnimMode.ATTACK and _windup_idle_preview_active():
		_play_pause_btn.disabled = false
		_play_pause_btn.text = (
			"⏸  Pause windup idle" if _anim_playing else "▶  Play windup idle"
		)
	elif _anim_mode == AnimMode.ATTACK:
		_play_pause_btn.disabled = true
		if _selected_weapon == ResourceData.ResourceType.WOOD:
			_play_pause_btn.text = "Drag pins — test swing on Idle standing"
		elif _selected_weapon == ResourceData.ResourceType.SPEAR:
			_play_pause_btn.text = "Drag pins — test thrust on Idle standing"
		else:
			_play_pause_btn.text = "Shift+click to swing"
	elif _is_gather_anim_mode():
		_play_pause_btn.disabled = false
		_play_pause_btn.text = (
			"⏸  Pause gather" if _anim_playing else "▶  Play gather"
		)
	elif _is_idle_anim_mode():
		_play_pause_btn.disabled = false
		if _selected_weapon == ResourceData.ResourceType.WOOD:
			var ctrl := _club_combat_controls_hint()
			_play_pause_btn.text = (
				"⏸  Pause · %s" % ctrl if _anim_playing else "▶  Play idle · %s" % ctrl
			)
		elif _selected_weapon == ResourceData.ResourceType.SPEAR:
			_play_pause_btn.text = (
				"⏸  Pause · Shift+click thrust" if _anim_playing else "▶  Play idle · Shift+click thrust"
			)
		else:
			_play_pause_btn.text = (
				"⏸  Pause idle" if _anim_playing else "▶  Play idle"
			)
	else:
		_play_pause_btn.disabled = true
		_play_pause_btn.text = "No loop preview"


func _on_play_pause_pressed() -> void:
	if not _is_idle_anim_mode() and not _is_gather_anim_mode() and not _windup_idle_preview_active():
		return
	_anim_playing = not _anim_playing
	_sync_preview_playback()
	if _status_label:
		if _anim_playing:
			if _is_gather_anim_mode():
				_status_label.text = "Gather playing — Pause or drag a pin to edit."
			elif _windup_idle_preview_active():
				if _preset and _preset.has_club_windup_idle_loop():
					_status_label.text = "Windup idle loop playing — Pause or drag a pin to edit."
				else:
					_status_label.text = "Windup idle playing — Pause or drag a pin to edit."
			else:
				_status_label.text = "Idle playing — Pause or drag a pin to edit."
		else:
			if _is_gather_anim_mode():
				_status_label.text = "Gather paused — drag pins, then Save all."
			else:
				_status_label.text = "Idle paused — drag pins, then Save all."


func _make_picker_button(text: String, min_width: float = 0.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(min_width, 32.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn


func _setup_animation_picker() -> void:
	_build_holdable_buttons()
	_build_category_buttons()
	_rebuild_variant_buttons()
	_sync_animation_picker_ui()


func _build_holdable_buttons() -> void:
	if _holdable_grid == null:
		return
	for child in _holdable_grid.get_children():
		child.queue_free()
	_holdable_button_map.clear()
	for entry in AnimCatalog.HOLDABLES:
		var weapon_type: ResourceData.ResourceType = entry["type"] as ResourceData.ResourceType
		var short_label: String = entry.get("short", "?") as String
		var btn := _make_picker_button(short_label, 96.0)
		btn.pressed.connect(_on_holdable_button_pressed.bind(weapon_type))
		_holdable_grid.add_child(btn)
		_holdable_button_map[weapon_type] = btn


func _build_category_buttons() -> void:
	if _category_buttons == null:
		return
	for child in _category_buttons.get_children():
		child.queue_free()
	_category_button_map.clear()
	for category in AnimCatalog.CATEGORY_ORDER:
		var label: String = AnimCatalog.CATEGORY_LABELS.get(category, str(category)) as String
		var btn := _make_picker_button(label, 52.0)
		btn.pressed.connect(_on_category_button_pressed.bind(category))
		_category_buttons.add_child(btn)
		_category_button_map[category] = btn


func _rebuild_variant_buttons() -> void:
	if _variant_buttons == null:
		return
	for child in _variant_buttons.get_children():
		child.queue_free()
	_variant_button_map.clear()
	var modes := AnimCatalog.modes_for_category(_selected_weapon, _selected_category)
	for mode in modes:
		var mode_enum := mode as AnimMode
		var label := AnimCatalog.mode_label(mode_enum, _selected_weapon)
		var btn := _make_picker_button(label, 72.0)
		btn.pressed.connect(_on_variant_button_pressed.bind(mode_enum))
		_variant_buttons.add_child(btn)
		_variant_button_map[mode_enum] = btn
	var variant_row: Control = get_node_or_null(
		"UI/Panel/Margin/VBox/SelectSection/VariantRow"
	) as Control
	if variant_row:
		variant_row.visible = modes.size() > 1


func _on_holdable_button_pressed(weapon_type: ResourceData.ResourceType) -> void:
	if _syncing_picker_ui:
		return
	_select_holdable(weapon_type)


func _on_category_button_pressed(category: StringName) -> void:
	if _syncing_picker_ui:
		return
	_select_category(category)


func _on_variant_button_pressed(mode: AnimMode) -> void:
	if _syncing_picker_ui:
		return
	_select_variant(mode)


func _select_holdable(weapon_type: ResourceData.ResourceType) -> void:
	if weapon_type == _selected_weapon:
		_sync_animation_picker_ui()
		return
	_set_weapon(weapon_type)


func _select_category(category: StringName) -> void:
	if not AnimCatalog.category_has_modes(_selected_weapon, category):
		_sync_animation_picker_ui()
		return
	if category == _selected_category and _anim_mode == AnimCatalog.default_mode_for_category(_selected_weapon, category):
		_sync_animation_picker_ui()
		return
	_selected_category = category
	var mode := AnimCatalog.default_mode_for_category(_selected_weapon, category)
	_rebuild_variant_buttons()
	_set_anim_mode(mode)
	_sync_animation_picker_ui()


func _select_variant(mode: AnimMode) -> void:
	if mode == _anim_mode:
		_sync_animation_picker_ui()
		return
	_selected_category = AnimCatalog.category_for_mode(_selected_weapon, mode)
	_set_anim_mode(mode)
	_sync_animation_picker_ui()


func _apply_pose_catalog_entry(weapon: ResourceData.ResourceType, mode: AnimMode) -> void:
	if weapon != _selected_weapon:
		_set_weapon(weapon, false)
	_selected_category = AnimCatalog.category_for_mode(weapon, mode)
	if mode != _anim_mode:
		_set_anim_mode(mode)
	else:
		_rebuild_variant_buttons()
		_sync_animation_picker_ui()
	_recenter_character_only()


func _set_weapon(weapon_type: ResourceData.ResourceType, reset_to_idle: bool = true) -> void:
	if _anim_mode == AnimMode.IDLE_CLUB1 and weapon_type != ResourceData.ResourceType.WOOD:
		_sync_animation_picker_ui()
		if _status_label:
			_status_label.text = "Club grip needs Club holdable — pick Club first."
		return
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
		_rig.refresh_weapon_combat_timing()
	_update_weapon_handle_visibility()
	if reset_to_idle:
		_selected_category = AnimCatalog.CATEGORY_IDLE
		_set_anim_mode(AnimMode.IDLE)
	else:
		_refresh_rig_from_preset()
		_rebuild_variant_buttons()
		_sync_animation_picker_ui()
		_recenter_character_only()
		if _status_label:
			_status_label.text = "Pose: %s — editing %s snapshot." % [_holdable_label(), _anim_mode_label()]


func _sync_animation_picker_ui() -> void:
	if _holdable_grid == null:
		return
	_syncing_picker_ui = true
	for weapon_type in _holdable_button_map:
		var btn: Button = _holdable_button_map[weapon_type] as Button
		if btn:
			btn.button_pressed = weapon_type == _selected_weapon
	for category in _category_button_map:
		var cat_btn: Button = _category_button_map[category] as Button
		if cat_btn:
			var enabled := AnimCatalog.category_has_modes(_selected_weapon, category)
			cat_btn.disabled = not enabled
			cat_btn.button_pressed = enabled and category == _selected_category
	for mode in _variant_button_map:
		var var_btn: Button = _variant_button_map[mode] as Button
		if var_btn:
			var_btn.button_pressed = mode == _anim_mode
	_syncing_picker_ui = false


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
	return AnimCatalog.mode_label(_anim_mode, _selected_weapon)


func _is_walk_preview_active() -> bool:
	return WeaponLimbPreset.is_walk_mode(_anim_mode)


func _is_attack_preview_active() -> bool:
	return _anim_mode == AnimMode.ATTACK


func _attack_edit_facing_allowed() -> bool:
	## Match in-game: cursor owns facing during Shift ready and mid-swing; A/D when editing pins only.
	if not _is_attack_preview_active():
		return false
	if _combat_animation_busy():
		return false
	if _rig == null or _rig.combat_component == null:
		return true
	return _rig.combat_component.state != CombatComponent.CombatState.READY


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_center_view")


func _center_stage() -> void:
	if _stage:
		_stage.position = _workspace_center_screen()
	_sync_handle_stage_transform()


func _sync_handle_stage_transform() -> void:
	if _handle_stage == null or _stage == null:
		return
	# HandleLayer is a nested CanvasLayer — local position ≠ Stage position; match world transform.
	_handle_stage.global_transform = _stage.global_transform


func _workspace_rect() -> Rect2:
	var panel := _panel if _panel else get_node_or_null("UI/Panel") as Control
	var left_margin := 0.0
	if panel:
		left_margin = panel.position.x + panel.size.x + 24.0
	var workspace_w: float = maxf(size.x - left_margin, 1.0)
	var workspace_h: float = maxf(size.y, 1.0)
	return Rect2(left_margin, 0.0, workspace_w, workspace_h)


func _workspace_center_screen() -> Vector2:
	var workspace := _workspace_rect()
	return Vector2(workspace.position.x + workspace.size.x * 0.5, workspace.size.y * 0.5)


func _uses_body_anchor_view_center() -> bool:
	return true


func _center_character_on_stage() -> void:
	if _rig == null:
		return
	_rig.position = Vector2.ZERO
	var center := Vector2.ZERO
	if _idle_club_minimal_active and _rig.has_weapon_overlay():
		var bounds := _rig.get_weapon_overlay_bounds_on_stage()
		if bounds.size.length_squared() > 0.01:
			center = bounds.get_center()
	else:
		center = _rig.get_body_center_on_stage()
		if center.length_squared() < 0.01 and _rig.get_visual_bounds_on_stage().size.length_squared() > 0.01:
			center = _rig.get_visual_center_on_stage()
	if center.length_squared() < 0.01:
		return
	_rig.position = -center


func _apply_fixed_stage_view() -> void:
	if _rig == null or _stage == null:
		return
	_apply_stage_display_scale()
	_refresh_all_handle_radii()
	_center_character_on_stage()
	_center_stage()
	if _uses_club_walk_carry_pose():
		_layout_club_idle_handles_and_arms()
	elif _preset != null:
		_sync_handle_positions()
		_lock_arm_lines_to_handles()
	_stage_view_initialized = true


func _recenter_character_only() -> void:
	if not _stage_view_initialized:
		call_deferred("_apply_fixed_stage_view")
		return
	_center_character_on_stage()
	if _uses_club_walk_carry_pose():
		_layout_club_idle_handles_and_arms()
	elif _preset != null and _mode == AppMode.ASSEMBLE:
		_sync_handle_positions()


func _center_view() -> void:
	_apply_fixed_stage_view()


func _apply_stage_display_scale() -> void:
	if _stage == null:
		return
	var display_scale: float = stage_scale * view_zoom
	_stage.scale = Vector2(display_scale, display_scale)
	_sync_handle_stage_transform()
	_update_view_zoom_hint()


func _set_view_zoom(z: float) -> void:
	view_zoom = clampf(z, view_zoom_min, view_zoom_max)
	_apply_fixed_stage_view()


func _update_view_zoom_hint() -> void:
	var help: Label = get_node_or_null("UI/Panel/Margin/VBox/HelpLabel") as Label
	if help:
		var z_text := "%.1f" % view_zoom
		help.text = (
			"Pick a pose, Play to preview, drag pins, Save. "
			+ "Scroll wheel over character to zoom preview (" + z_text + "x, preview only). "
			+ "[+/-] zoom, [0] reset zoom."
		)


func _try_handle_view_zoom_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return false
		if not _workspace_rect().has_point(mb.position):
			return false
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_view_zoom(view_zoom * view_zoom_step)
			get_viewport().set_input_as_handled()
			return true
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_view_zoom(view_zoom / view_zoom_step)
			get_viewport().set_input_as_handled()
			return true
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_EQUAL, KEY_KP_ADD:
				_set_view_zoom(view_zoom * view_zoom_step)
				get_viewport().set_input_as_handled()
				return true
			KEY_MINUS, KEY_KP_SUBTRACT:
				_set_view_zoom(view_zoom / view_zoom_step)
				get_viewport().set_input_as_handled()
				return true
			KEY_0, KEY_KP_0:
				_set_view_zoom(1.0)
				get_viewport().set_input_as_handled()
				return true
	return false


func _apply_ui_theme() -> void:
	var panel: PanelContainer = $UI/Panel as PanelContainer
	if panel and UITheme:
		panel.add_theme_stylebox_override("panel", UITheme.get_panel_style())
	for label_path in [
		"UI/Panel/Margin/VBox/Title",
		"UI/Panel/Margin/VBox/HelpLabel",
		"UI/Panel/Margin/VBox/SelectSection/SelectHeader",
		"UI/Panel/Margin/VBox/SelectSection/HoldableRow/HoldableLabel",
		"UI/Panel/Margin/VBox/SelectSection/CategoryRow/CategoryLabel",
		"UI/Panel/Margin/VBox/SelectSection/VariantRow/VariantLabel",
		"UI/Panel/Margin/VBox/PreviewSection/PreviewHeader",
		"UI/Panel/Margin/VBox/ActionsSection/ActionsHeader",
		"UI/Panel/Margin/VBox/ArmsSection/ArmsHeader",
		"UI/Panel/Margin/VBox/SummaryLabel",
		"UI/Panel/Margin/VBox/StatusLabel",
	]:
		var label: Label = get_node_or_null(label_path) as Label
		if label and UITheme:
			label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)


func _input(event: InputEvent) -> void:
	if _try_handle_view_zoom_input(event):
		return
	if _mode != AppMode.ASSEMBLE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start_global = get_global_mouse_position()
			_pending_elbow_click = _pick_elbow_at(get_global_mouse_position())
			if _pending_elbow_click != null:
				if _anim_playing and (
					_is_idle_anim_mode() or _is_gather_anim_mode() or _windup_idle_preview_active()
				):
					_anim_playing = false
					_sync_preview_playback()
				get_viewport().set_input_as_handled()
				return
			_pending_drag_handle = _pick_handle_at(get_global_mouse_position())
			_handle_drag_active = false
			if _pending_drag_handle != null:
				if _anim_playing and (
					_is_idle_anim_mode() or _is_gather_anim_mode() or _windup_idle_preview_active()
				):
					_anim_playing = false
					_sync_preview_playback()
				get_viewport().set_input_as_handled()
		else:
			if _pending_elbow_click != null:
				if _drag_start_global.distance_to(get_global_mouse_position()) <= PIN_CLICK_MAX_PX:
					_flip_elbow_bend(_pending_elbow_click == _weapon_elbow_handle)
				_pending_elbow_click = null
				get_viewport().set_input_as_handled()
				return
			if _pending_drag_handle != null and not _handle_drag_active:
				if _drag_start_global.distance_to(get_global_mouse_position()) <= PIN_CLICK_MAX_PX:
					if not _is_idle_club_anim_mode():
						_on_pin_clicked(_pending_drag_handle)
				get_viewport().set_input_as_handled()
			if _active_drag_handle != null:
				_commit_all_poses_to_preset()
				get_viewport().set_input_as_handled()
			_pending_drag_handle = null
			_handle_drag_active = false
			_active_drag_handle = null
			_dragging_spear = false
			_dragging_spear_grip_2 = false
			_spear_grab_offset = Vector2.ZERO
			_spear_grip_2_grab_offset = Vector2.ZERO
			_drag_start_global = Vector2.ZERO
			call_deferred("_sync_weapon_pin_parenting")
	elif event is InputEventMouseMotion:
		if _pending_drag_handle != null and not _handle_drag_active:
			if _drag_start_global.distance_to(get_global_mouse_position()) >= PIN_DRAG_MIN_PX:
				_handle_drag_active = true
				_active_drag_handle = _pending_drag_handle
				if _active_drag_handle == _spear_handle and _rig.weapon_overlay:
					var grab_global: Vector2
					if _is_spear_shaft_pose_edit():
						grab_global = _rig.spear_windup_dominant_grip_global(_preset)
					elif _is_club_windup_edit():
						grab_global = _rig.hand_grip_global_from_preset(_preset, AnimMode.ATTACK)
					elif _uses_club_walk_carry_pose() or _is_idle_club_anim_mode():
						grab_global = _rig.hand_grip_global_from_preset(_preset, _hand_storage_mode())
					else:
						grab_global = _rig.weapon_handle_anchor_global()
					_spear_grab_offset = grab_global - get_global_mouse_position()
					_dragging_spear = true
				elif _active_drag_handle == _spear_grip_2_handle and _rig.weapon_overlay:
					var grab2 := _rig.spear_windup_support_grip_global(_preset)
					_spear_grip_2_grab_offset = grab2 - get_global_mouse_position()
					_dragging_spear_grip_2 = true
		if _active_drag_handle != null:
			_move_active_handle(get_global_mouse_position())
			get_viewport().set_input_as_handled()


func _pick_handle_at(global_pos: Vector2) -> LimbTunerHandle:
	var best: LimbTunerHandle = null
	var best_dist: float = INF
	var handle_order: Array[LimbTunerHandle] = [
		_hand_handle,
		_support_hand_handle,
		_shoulder_handle,
		_support_shoulder_handle,
		_head_handle,
		_spear_handle,
	]
	if _is_spear_shaft_pose_edit():
		handle_order = [
			_spear_handle,
			_hand_handle,
			_spear_grip_2_handle,
			_support_hand_handle,
			_shoulder_handle,
			_support_shoulder_handle,
		]
	elif _is_club_windup_edit():
		handle_order = [
			_spear_handle,
			_hand_handle,
			_support_hand_handle,
			_shoulder_handle,
			_support_shoulder_handle,
			_head_handle,
		]
	# Idle Club 1: only yellow grip pin — club art stays fixed.
	if _is_idle_club_anim_mode() and _idle_club_minimal_active and _spear_handle != null:
		handle_order = [_spear_handle]
	for handle in handle_order:
		if handle == null or not handle.draggable:
			continue
		var pick_slop := HAND_PICK_EXTRA if _is_hand_handle(handle) else 7.0
		var pick_radius: float = handle.handle_radius * absf(handle.global_scale.x) + pick_slop
		var dist: float = global_pos.distance_to(_handle_pick_center_global(handle))
		if dist <= pick_radius and dist <= best_dist:
			best_dist = dist
			best = handle
	return best


func _pick_elbow_at(global_pos: Vector2) -> LimbTunerHandle:
	var best: LimbTunerHandle = null
	var best_dist: float = INF
	for handle in [_weapon_elbow_handle, _support_elbow_handle]:
		if handle == null or not handle.visible:
			continue
		var pick_radius: float = handle.handle_radius * absf(handle.global_scale.x) + 7.0
		var dist: float = global_pos.distance_to(handle.global_position)
		if dist <= pick_radius and dist <= best_dist:
			best_dist = dist
			best = handle
	return best


func _is_hand_handle(handle: LimbTunerHandle) -> bool:
	return handle == _hand_handle or handle == _support_hand_handle


func _is_shoulder_handle(handle: LimbTunerHandle) -> bool:
	return handle == _shoulder_handle or handle == _support_shoulder_handle


func _on_pin_clicked(_handle: LimbTunerHandle) -> void:
	pass


func _apply_idle_club_minimal_view(on: bool) -> void:
	_idle_club_minimal_active = on
	if _rig:
		if _rig.body_visual:
			_rig.body_visual.visible = not on
		if _rig.arm_controller:
			_rig.arm_controller.visible = not on
			_rig.arm_controller.enabled = not on
			if not on and _rig.has_method("_sync_tuner_arm_process"):
				_rig.call("_sync_tuner_arm_process")
			elif on:
				_rig.arm_controller.set_process(false)
		var head_pivot := _rig.get_node_or_null("Sprite/HeadPivot") as CanvasItem
		if head_pivot:
			head_pivot.visible = not on
		for arm_draw_name in ["Arm1Draw", "Arm2Draw"]:
			var arm_draw := _rig.get_node_or_null(arm_draw_name) as CanvasItem
			if arm_draw:
				arm_draw.visible = not on
		if _rig.sprite:
			_rig.sprite.self_modulate = Color(1.0, 1.0, 1.0, 0.0 if on else 1.0)
		if _rig.weapon_overlay and on:
			_rig.weapon_overlay.visible = _rig.weapon_type != ResourceData.ResourceType.NONE
	for path in _IDLE_CLUB_UI_HIDE_PATHS:
		var node := get_node_or_null(path) as CanvasItem
		if node:
			node.visible = not on
	for handle in [
		_shoulder_handle,
		_hand_handle,
		_support_shoulder_handle,
		_support_hand_handle,
		_weapon_elbow_handle,
		_support_elbow_handle,
		_head_handle,
	]:
		if handle:
			handle.visible = not on
	if _spear_handle:
		_spear_handle.visible = on or (_rig != null and _rig.has_weapon_overlay())
		if on:
			_spear_handle.set_side_label("")
			_spear_handle.set_handle_color(Color(0.95, 0.75, 0.15, 1.0))
	if on:
		return
	_restore_standard_ui_labels()


func _restore_standard_ui_labels() -> void:
	var help: Label = get_node_or_null("UI/Panel/Margin/VBox/HelpLabel") as Label
	if help:
		help.text = "Pose dropdown · Play/Pause to preview · drag pins · Save."
	var title: Label = get_node_or_null("UI/Panel/Margin/VBox/Title") as Label
	if title:
		title.text = "Pose Map"


func _update_idle_club_handle_visibility() -> void:
	if not _is_idle_club_anim_mode() or not _idle_club_minimal_active:
		return
	_apply_idle_club_minimal_view(true)


func _stack_spear_windup_dominant_pins() -> void:
	## After moving horizontal spear art, refresh Y1 + green 1h from overlay (same idea as club windup 3/1h).
	if _rig == null or _preset == null:
		return
	var y1 := _rig.spear_windup_dominant_grip_global(_preset)
	_set_hand_handle_position(_spear_handle, y1)
	_set_hand_handle_position(_hand_handle, y1)


func _stack_spear_windup_support_pins() -> void:
	if _rig == null or _preset == null:
		return
	var y2 := _rig.spear_windup_support_grip_global(_preset)
	if _spear_grip_2_handle:
		_set_hand_handle_position(_spear_grip_2_handle, y2)
	if _support_hand_handle:
		_set_hand_handle_position(_support_hand_handle, y2)


func _on_spear_windup_grip_dragged(global_pos: Vector2) -> void:
	## Windup edit: move spear overlay so Y1 shaft grip follows (free 2D, no reach clamp).
	if _rig == null or _preset == null or not _rig.has_weapon_overlay():
		return
	_rig.align_spear_windup_overlay_to_grip_global(_preset, global_pos, true)
	_stack_spear_windup_dominant_pins()


func _on_club_windup_grip_dragged(global_pos: Vector2) -> void:
	## Windup pose edit: free 2D like spear windup — no arm-reach clamp, no shaft-axis slide.
	_rig.align_weapon_overlay_to_hand_grip_global(_preset, global_pos, AnimMode.ATTACK)
	_stack_club_grip_pins(AnimMode.ATTACK)


func _on_idle_club_grip_dragged(global_pos: Vector2) -> void:
	var adjusted := _rig.project_hand_grip_drag_global(global_pos, _preset, _anim_mode)
	_rig.set_hand_grip_from_global(_preset, adjusted, _anim_mode)
	if _spear_handle:
		_spear_handle.global_position = adjusted


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
		_status_label.text = "%s elbow now %s (%s / %s). Copy JSON to share." % [
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
	var support_bend := _rig.resolve_elbow_bend_sign(_preset, false, _anim_mode)
	if (
		_is_idle1_anim_mode()
		and _rig.is_preview_playing()
		and _preset.has_idle_arm2_raise_pose()
	):
		var raise_blend := _rig.get_idle_arm2_raise_blend()
		if raise_blend > 0.0001:
			support_bend = _preset.resolve_support_elbow_bend_sign_for_idle_raise(
				raise_blend,
				_rig.elbow_bend_sign_auto_for_facing(false)
			)
	cfg.support_elbow_bend_sign_active = support_bend


func _clamp_dominant_hand_global(
	shoulder_global: Vector2,
	hand_global: Vector2,
	motion_relaxed: bool = false,
	gather_motion: bool = false
) -> Vector2:
	var slack := 0.0
	if gather_motion:
		slack = GatherArmMotionScript.reach_slack_ratio(true)
	elif motion_relaxed:
		slack = WalkArmSwingScript.reach_slack_ratio(true)
	return _rig.clamp_hand_global_to_arm_reach(
		_preset,
		shoulder_global,
		hand_global,
		true,
		slack,
		motion_relaxed or gather_motion
	)


func _clamp_support_hand_global(
	shoulder_global: Vector2,
	hand_global: Vector2,
	motion_relaxed: bool = false,
	gather_motion: bool = false
) -> Vector2:
	var slack := 0.0
	if gather_motion:
		slack = GatherArmMotionScript.reach_slack_ratio(false)
	elif motion_relaxed:
		slack = WalkArmSwingScript.reach_slack_ratio(false)
	return _rig.clamp_hand_global_to_arm_reach(
		_preset,
		shoulder_global,
		hand_global,
		false,
		slack,
		motion_relaxed or gather_motion
	)


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
	elif _active_drag_handle == _head_handle:
		_head_handle.global_position = global_pos
		_on_head_dragged(global_pos)
	elif _active_drag_handle == _spear_handle:
		_on_spear_dragged(global_pos + _spear_grab_offset)
	elif _active_drag_handle == _spear_grip_2_handle:
		_on_spear_grip_2_dragged(global_pos + _spear_grip_2_grab_offset)
	_lock_arm_lines_to_handles()
	_push_preset_to_arms()
	_sync_elbow_handles()


func _setup_weapon_rotation_field() -> void:
	if _weapon_rotation_spin == null:
		return
	_weapon_rotation_spin.min_value = 0.0
	_weapon_rotation_spin.max_value = 360.0
	_weapon_rotation_spin.step = 1.0
	_weapon_rotation_spin.rounded = true
	_weapon_rotation_spin.value_changed.connect(_on_weapon_rotation_changed)


func _live_weapon_rotation_deg() -> float:
	if _rig == null or _rig.weapon_overlay == null:
		return 0.0
	return WeaponLimbPreset.normalize_rotation_deg(rad_to_deg(_rig.weapon_overlay.rotation))


func _sync_weapon_rotation_spin_from_rig() -> void:
	if _weapon_rotation_spin == null or _rig == null:
		return
	_syncing_weapon_rotation_ui = true
	if _preset != null and _selected_weapon == ResourceData.ResourceType.WOOD and _rig != null and _rig.is_shift_ready_windup_loop():
		if _preset.club_windup_idle_key_b_rotation_deg > WeaponLimbPreset.ROTATION_UNSET + 1.0:
			_weapon_rotation_spin.value = WeaponLimbPreset.signed_rotation_deg(
				_preset.club_windup_idle_key_b_rotation_deg
			)
		else:
			_weapon_rotation_spin.value = _live_weapon_rotation_deg()
	elif _preset != null and _preset.rotation_deg_is_custom(_anim_mode):
		_weapon_rotation_spin.value = WeaponLimbPreset.normalize_rotation_deg(
			_preset.get_rotation_deg_for_mode(_anim_mode)
		)
	else:
		_weapon_rotation_spin.value = _live_weapon_rotation_deg()
	_syncing_weapon_rotation_ui = false


func _on_weapon_rotation_changed(value: float) -> void:
	if _syncing_weapon_rotation_ui or _preset == null or _rig == null:
		return
	if _combat_animation_busy():
		return
	if _selected_weapon == ResourceData.ResourceType.WOOD and _rig.is_shift_ready_windup_loop():
		_preset.club_windup_idle_key_b_rotation_deg = WeaponLimbPreset.normalize_rotation_deg(value)
	elif _anim_mode == AnimMode.ATTACK:
		_preset.set_rotation_deg_for_mode(AnimMode.ATTACK, value)
	else:
		_preset.set_rotation_deg_for_mode(_anim_mode, value)
	_apply_weapon_rotation_preview()


func _apply_weapon_rotation_preview() -> void:
	if _rig == null or _preset == null or not _rig.has_weapon_overlay():
		return
	var aim := _rig.aim_from_facing() if _rig.has_method("aim_from_facing") else Vector2(1.0, 0.0)
	_rig.apply_weapon_rotation_for_mode(_preset, _anim_mode, aim)
	if _mode == AppMode.ASSEMBLE:
		if _combat_preview_needs_arm_pins():
			_sync_combat_overlay_arm_pins()
		else:
			_sync_hands_with_spear()
			_sync_spear_handle()
		_lock_arm_lines_to_handles()


func _update_weapon_rotation_section_visibility() -> void:
	if _weapon_section == null:
		return
	var show := _rig != null and _rig.has_weapon_overlay() and _mode == AppMode.ASSEMBLE
	_weapon_section.visible = show
	if _weapon_rotation_spin:
		_weapon_rotation_spin.editable = show and not _combat_animation_busy()


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


func _setup_arm_thickness_fields() -> void:
	if _arm_thickness_spin == null:
		return
	_arm_thickness_spin.min_value = WeaponLimbPreset.TUNER_MIN_ARM_WIDTH
	_arm_thickness_spin.max_value = WeaponLimbPreset.TUNER_MAX_ARM_WIDTH
	_arm_thickness_spin.step = 1.0
	_arm_thickness_spin.rounded = true
	_arm_thickness_spin.value_changed.connect(_on_arm_thickness_field_changed)


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


func _on_arm_thickness_field_changed(_value: float) -> void:
	if _syncing_arm_thickness_ui or _preset == null:
		return
	_apply_arm_thickness_from_fields()


func _apply_arm_thickness_from_fields() -> void:
	if _preset == null or _arm_thickness_spin == null:
		return
	_preset.apply_tuner_arm_thickness(float(_arm_thickness_spin.value))
	_push_preset_to_arms()
	if _status_label:
		_status_label.text = "Arm thickness set to %.0f px (both arms)" % [_preset.arm_width]


func _sync_arm_thickness_field_from_preset() -> void:
	if _preset == null or _arm_thickness_spin == null:
		return
	_syncing_arm_thickness_ui = true
	_arm_thickness_spin.value = _preset.arm_width
	_syncing_arm_thickness_ui = false


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

	_spear_grip_2_handle = LimbTunerHandleScript.new()
	_spear_grip_2_handle.name = "SpearGrip2Handle"
	_spear_grip_2_handle.set_handle_color(Color(0.95, 0.75, 0.15, 1.0))
	parent.add_child(_spear_grip_2_handle)

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
		_spear_grip_2_handle,
		_weapon_elbow_handle,
		_support_elbow_handle,
		_head_handle,
	]:
		_apply_uniform_handle_radius(handle)
	_apply_handle_number_labels()


func _apply_uniform_handle_radius(handle: LimbTunerHandle) -> void:
	if handle == null:
		return
	var base_radius := HAND_HANDLE_RADIUS if _is_hand_handle(handle) else (
		SHOULDER_HANDLE_RADIUS if _is_shoulder_handle(handle) else HANDLE_RADIUS
	)
	var target_global: float = base_radius * handle_ui_scale
	var parent_scale: float = absf(handle.global_scale.x)
	if parent_scale < 0.001:
		parent_scale = 1.0
	handle.set_handle_radius(target_global / parent_scale)
	_apply_handle_draw_layer(handle)


func _apply_handle_draw_layer(handle: LimbTunerHandle) -> void:
	if handle == null:
		return
	# Pins live on HandleLayer (canvas layer 1) — always above the character for editing.
	handle.z_as_relative = false
	handle.z_index = HANDLE_Z_INDEX


func _refresh_all_handle_radii() -> void:
	for handle in [
		_shoulder_handle,
		_hand_handle,
		_support_shoulder_handle,
		_support_hand_handle,
		_spear_handle,
		_spear_grip_2_handle,
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
		_spear_handle.set_side_label("Y1" if _is_spear_windup_pin_mode() else "3")
	if _spear_grip_2_handle:
		_spear_grip_2_handle.set_side_label("Y2")
		_spear_grip_2_handle.visible = _is_spear_windup_pin_mode() and (
			_rig != null and _rig.has_weapon_overlay()
		)
	if _head_handle:
		_head_handle.set_side_label("H")


func _sync_spear_windup_handles() -> void:
	if _rig == null or _preset == null or not _is_spear_windup_pin_mode():
		return
	if _spear_windup_handle_drag_active():
		_sync_spear_windup_handles_during_drag()
		return
	_ensure_handle_on_stage(_spear_handle)
	if _spear_grip_2_handle:
		_ensure_handle_on_stage(_spear_grip_2_handle)
	## Yellow pins stay on spear art; green hands stack on yellow (never clamp yellow to reach).
	var y1 := _rig.spear_windup_dominant_grip_global(_preset)
	var y2 := _rig.spear_windup_support_grip_global(_preset)
	_set_hand_handle_position(_spear_handle, y1)
	_set_hand_handle_position(_hand_handle, y1)
	if _spear_grip_2_handle:
		_set_hand_handle_position(_spear_grip_2_handle, y2)
	if _support_hand_handle:
		_set_hand_handle_position(_support_hand_handle, y2)
	_seed_elbow_poles_for_mode(AnimMode.ATTACK)
	_lock_arm_lines_to_handles()


func _sync_spear_windup_handles_during_drag() -> void:
	## While dragging: read pin positions from spear art — handle nodes are not moved by overlay align alone.
	_stack_spear_windup_dominant_pins()
	_stack_spear_windup_support_pins()
	_lock_arm_lines_to_handles()


func _sync_spear_handle() -> void:
	if _rig == null or _spear_handle == null:
		return
	if _is_spear_windup_pin_mode():
		_sync_spear_windup_handles()
		return
	if _is_idle_club_anim_mode() and _idle_club_minimal_active:
		_sync_idle_club_grip_handle()
		return
	if _uses_spear_grip_on_art_pins():
		_sync_spear_grip_pin_on_art()
		return
	_ensure_handle_on_stage(_spear_handle)
	if _active_drag_handle == _spear_handle:
		return
	if _rig.uses_weapon_grip_anchor_hand() and not _idle_club_pins_independent():
		if _uses_club_walk_carry_pose():
			if _active_drag_handle == _hand_handle or _active_drag_handle == _spear_handle:
				return
			var grip_global := _rig.hand_grip_global_from_preset(_preset, _hand_storage_mode())
			_spear_handle.global_position = grip_global
		else:
			var stacked := _rig.dominant_grip_global_from_preset(_preset, _anim_mode)
			_spear_handle.global_position = stacked
	else:
		if _preset != null and _rig.has_weapon_overlay():
			if _preset.uses_saved_club_grip_on_art() or _preset.uses_saved_spear_grip_on_art():
				_spear_handle.global_position = _rig.hand_grip_global_from_preset(
					_preset, _hand_storage_mode()
				)
				return
		_spear_handle.global_position = _rig.weapon_handle_anchor_global()


func _sync_dominant_grip_stack(mode: AnimMode, walk_swing: bool = false, gather_motion: bool = false) -> void:
	if _rig == null or _preset == null or not _rig.uses_weapon_grip_anchor_hand():
		return
	if _active_drag_handle == _hand_handle or _active_drag_handle == _spear_handle:
		return
	if (
		not _preset.uses_saved_club_grip_on_art()
		and _preset.resolve_hand_grip_for_mode(mode).length_squared() < 0.0001
	):
		_rig.snap_hand_grip_to_weapon_anchor(_preset, mode == AnimMode.ATTACK)
	var grip_global: Vector2
	if gather_motion:
		grip_global = _rig.hand_grip_global_with_gather_motion(_preset, mode)
	elif walk_swing:
		grip_global = _rig.hand_grip_global_with_walk_swing(_preset, mode)
	else:
		grip_global = _rig.dominant_grip_global_from_preset(_preset, mode)
	grip_global = _clamp_dominant_hand_global(
		_shoulder_handle.global_position, grip_global, walk_swing, gather_motion
	)
	_rig.align_weapon_overlay_to_hand_grip_global(_preset, grip_global, mode)
	_set_hand_handle_position(_hand_handle, grip_global)
	_set_hand_handle_position(_spear_handle, grip_global)


func _process(delta: float) -> void:
	if _rig == null or _preset == null:
		return
	if _rig.has_method("set_walk_preview_context"):
		_rig.set_walk_preview_context(_preset, _hand_storage_mode())
	_poll_tuner_movement(delta)
	_poll_walk_input()
	if _rig.has_method("sync_travel_facing"):
		_rig.sync_travel_facing()
	_process_combat_input()
	_sync_shift_ready_windup_loop()
	_push_preset_to_arms()
	var combat_busy := _combat_animation_busy()
	if _mode == AppMode.ASSEMBLE and _was_combat_preview_busy and not combat_busy:
		_restore_tuner_pose_after_combat_preview()
	_was_combat_preview_busy = combat_busy
	if _mode == AppMode.ASSEMBLE:
		if _combat_preview_needs_arm_pins():
			if _selected_weapon == ResourceData.ResourceType.WOOD:
				_queue_club_combat_grip_pin_sync()
			elif _is_spear_windup_pin_mode():
				_sync_spear_windup_handles()
			else:
				_sync_combat_overlay_arm_pins()
			if (
				_selected_weapon == ResourceData.ResourceType.WOOD
				and _rig.is_shift_ready_windup_loop()
				and not _combat_animation_busy()
			):
				_apply_club_tuner_windup_aim(_rig._get_cursor_aim_direction())
		elif _combat_animation_busy():
			_sync_combat_strike_preview()
		elif _is_shift_ready_preview():
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
		if _anim_playing and (
			_is_idle_anim_mode() or _is_gather_anim_mode() or _windup_idle_preview_active()
		):
			_sync_elbow_handles_from_arm_lines()
		else:
			call_deferred("_sync_elbow_handles_from_arm_lines")
	_tick_preview_instrumentation()


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
	if _is_thrust_animating() or _combat_animation_busy():
		_rig.set_walk_direction(0)
		return
	var combat_ready := (
		_rig.combat_component != null
		and _rig.combat_component.state == CombatComponent.CombatState.READY
	)
	var dir := 0
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_LEFT):
		dir = -1
	elif Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_RIGHT):
		dir = 1
	if combat_ready:
		_rig.set_walk_direction(0)
		if dir != 0 and _travel_facing_input_allowed():
			_rig.apply_travel_facing_direction(dir)
			var aim := Vector2(float(dir), 0.0)
			if _selected_weapon == ResourceData.ResourceType.WOOD:
				_apply_club_tuner_windup_ready(aim)
			else:
				_rig.aim_dir = aim
				_rig.combat_component.update_ready_aim(aim)
		return
	if _travel_walk_input_allowed():
		if dir != 0 and _preset != null:
			_preset.seed_walk_from_idle_if_unset()
		_rig.set_walk_direction(dir)
		return
	if _travel_facing_input_allowed():
		_rig.set_walk_direction(0)
		if dir != 0:
			_rig.apply_travel_facing_direction(dir)
			if _attack_edit_facing_allowed():
				_sync_attack_windup_facing(dir)
	else:
		_rig.set_walk_direction(0)


func _travel_facing_input_allowed() -> bool:
	return (
		_is_idle_anim_mode()
		or _anim_mode == AnimMode.IDLE_CLUB1
		or _is_gather_anim_mode()
		or WeaponLimbPreset.is_walk_mode(_anim_mode)
		or _attack_edit_facing_allowed()
	)


func _sync_attack_windup_facing(dir: int) -> void:
	if _rig == null or _preset == null or dir == 0:
		return
	var aim := Vector2(float(dir), 0.0)
	if _selected_weapon == ResourceData.ResourceType.SPEAR:
		_rig.apply_tuner_spear_windup_overlay(_preset, aim)
	elif not _preset.attack_pose_inherits_idle():
		_rig.apply_preset_overlay_ready(_preset, aim)
	_seed_elbow_poles_for_mode(AnimMode.ATTACK)
	_sync_handle_positions()
	_lock_arm_lines_to_handles()


func _poll_tuner_movement(delta: float) -> void:
	if _rig == null or _mode != AppMode.ASSEMBLE or _active_drag_handle != null:
		return
	if not _is_attack_preview_active():
		return
	## Attack pin-edit: W/S/Q/E pan canvas — A/D stay reserved for facing (see _poll_walk_input).
	var move := Vector2.ZERO
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W):
		move.y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S):
		move.y += 1.0
	if Input.is_key_pressed(KEY_Q):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_E):
		move.x += 1.0
	if move.length_squared() < 0.001:
		return
	move = move.normalized()
	_rig.position += move * TUNER_MOVE_SPEED_PX * delta


func _combat_animation_busy() -> bool:
	if _rig == null or _rig.combat_component == null:
		return false
	var cc := _rig.combat_component
	if cc.state == CombatComponent.CombatState.WINDUP or cc.state == CombatComponent.CombatState.RECOVERY:
		return true
	var ostate: int = WeaponOverlayCombat.get_overlay_state(_rig)
	return (
		ostate == WeaponOverlayCombat.OverlayState.STRIKING
		or ostate == WeaponOverlayCombat.OverlayState.RECOVERING
	)


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
			_commit_club_strike(aim)


func _windup_pose_edit_only() -> bool:
	return (
		_anim_mode == AnimMode.ATTACK
		and (
			_selected_weapon == ResourceData.ResourceType.WOOD
			or _selected_weapon == ResourceData.ResourceType.SPEAR
		)
	)


func _is_spear_strike_edit() -> bool:
	return (
		_selected_weapon == ResourceData.ResourceType.SPEAR
		and _windup_pose_edit_only()
		and _spear_attack_edit_target == "strike"
	)


func _is_spear_shaft_pose_edit() -> bool:
	return _is_spear_windup_edit() or _is_spear_strike_edit()


func _is_spear_windup_edit() -> bool:
	return (
		_selected_weapon == ResourceData.ResourceType.SPEAR
		and _windup_pose_edit_only()
		and _spear_attack_edit_target != "strike"
	)


func _is_club_windup_edit() -> bool:
	return _selected_weapon == ResourceData.ResourceType.WOOD and _windup_pose_edit_only()


func _combat_test_status_label() -> String:
	if _selected_weapon == ResourceData.ResourceType.SPEAR:
		return "Striking — same overlay thrust as in-game."
	return "Striking — same overlay swing as in-game."


func _process_combat_input_assemble() -> void:
	if _selected_weapon == ResourceData.ResourceType.NONE:
		return
	if _active_drag_handle == _spear_handle or _dragging_spear:
		return
	if _active_drag_handle == _spear_grip_2_handle or _dragging_spear_grip_2:
		return
	if _windup_pose_edit_only():
		return
	if _anim_mode == AnimMode.ATTACK:
		_process_attack_mode_combat()
		return
	## Idle/walk: Shift = windup loop only (club strike disabled until re-authored).
	if Input.is_action_just_pressed("weapon_ready"):
		_enter_assemble_combat_ready()
	elif Input.is_action_just_released("weapon_ready"):
		_exit_assemble_combat_ready()
	elif Input.is_action_pressed("weapon_ready") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if _club_strike_input_blocked():
			return
		if _rig.combat_component.state != CombatComponent.CombatState.READY:
			_enter_assemble_combat_ready()
		if _rig.combat_component.state != CombatComponent.CombatState.READY:
			return
		var aim := _rig._get_cursor_aim_direction()
		_commit_combat_strike(aim)
		if _status_label:
			_status_label.text = _combat_test_status_label()


func _commit_combat_strike(aim: Vector2) -> void:
	if _rig == null or _rig.combat_component == null:
		return
	if _selected_weapon == ResourceData.ResourceType.WOOD:
		_commit_club_strike(aim)
		return
	_rig.aim_dir = aim
	_rig.combat_component.commit_strike(aim)


func _prepare_club_strike_from_windup() -> void:
	if _rig == null or _selected_weapon != ResourceData.ResourceType.WOOD:
		return
	if _rig.has_method("seed_club_strike_start_from_windup"):
		_rig.seed_club_strike_start_from_windup()


func _commit_club_strike(aim: Vector2) -> void:
	_prepare_club_strike_from_windup()
	_rig.aim_dir = aim
	_rig.combat_component.commit_strike(aim)


func _process_attack_mode_combat() -> void:
	if _rig == null or _rig.combat_component == null:
		return
	if _selected_weapon == ResourceData.ResourceType.NONE:
		return
	var cc := _rig.combat_component
	var busy := _combat_animation_busy()
	if Input.is_action_just_pressed("weapon_ready") and not busy and cc.state == CombatComponent.CombatState.IDLE:
		var aim := _rig._get_cursor_aim_direction()
		if aim.length_squared() < 0.0001:
			aim = Vector2(1.0, 0.0)
		if _selected_weapon == ResourceData.ResourceType.WOOD:
			_apply_club_tuner_windup_ready(aim)
		elif _selected_weapon == ResourceData.ResourceType.SPEAR:
			_apply_spear_tuner_windup_ready(aim)
		else:
			_rig.aim_dir = aim.normalized()
			cc.enter_ready(aim)
		if _status_label:
			_status_label.text = (
				"Windup stance (Shift) — Shift+click to test swing."
				if _selected_weapon == ResourceData.ResourceType.WOOD
				else "Windup stance (Shift) — click to swing."
			)
	elif Input.is_action_just_released("weapon_ready"):
		if cc.state == CombatComponent.CombatState.READY:
			_exit_assemble_combat_ready()
	elif cc.state == CombatComponent.CombatState.READY:
		var aim := _rig._get_cursor_aim_direction()
		if aim.length_squared() > 0.0001:
			if _selected_weapon == ResourceData.ResourceType.WOOD:
				_apply_club_tuner_windup_ready(aim)
			elif _selected_weapon == ResourceData.ResourceType.SPEAR:
				_apply_spear_tuner_windup_ready(aim)
			else:
				_rig.aim_dir = aim.normalized()
				_rig.sync_combat_overlay(true)
		if Input.is_action_pressed("weapon_ready") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not busy:
			if _club_strike_input_blocked():
				return
			var strike_aim := _rig._get_cursor_aim_direction()
			if strike_aim.length_squared() < 0.0001:
				strike_aim = _rig.aim_dir
			_commit_combat_strike(strike_aim)
			if _status_label:
				_status_label.text = _combat_test_status_label()


func _cancel_attack_mode_combat() -> void:
	if _rig == null or _rig.combat_component == null:
		return
	var cc := _rig.combat_component
	if cc.state == CombatComponent.CombatState.READY:
		cc.cancel_ready()
	_refresh_rig_from_preset()


func _apply_spear_tuner_windup_ready(raw_aim: Vector2) -> void:
	## Spear Shift: preset windup row + Y1/Y2 shaft pins (same overlay path as windup edit).
	if _rig == null or _preset == null or _rig.combat_component == null:
		return
	var aim := raw_aim
	if aim.length_squared() < 0.0001:
		if _rig.aim_dir.length_squared() > 0.0001:
			aim = _rig.aim_dir
		else:
			aim = Vector2(1.0, 0.0)
	aim = aim.normalized()
	_rig.aim_dir = aim
	_rig.combat_component.aim_dir = aim
	if absf(aim.x) > 0.05:
		_rig.apply_travel_facing_direction(-1 if aim.x < 0.0 else 1)
	if _rig.combat_component.state == CombatComponent.CombatState.IDLE:
		_rig.combat_component.state = CombatComponent.CombatState.READY
	WeaponOverlayCombat.set_overlay_state(_rig, WeaponOverlayCombat.OverlayState.READY)
	_preset.seed_spear_attack_windup_if_unset()
	_rig.apply_tuner_spear_windup_overlay(_preset, aim)
	_sync_spear_windup_handles()


func _exit_spear_tuner_combat_ready() -> void:
	_apply_spear_idle_carry_pose()


func _enter_assemble_combat_ready() -> void:
	if _rig == null or _rig.combat_component == null:
		return
	if _selected_weapon == ResourceData.ResourceType.NONE:
		return
	var aim := _rig._get_cursor_aim_direction()
	if _selected_weapon == ResourceData.ResourceType.WOOD:
		_apply_club_tuner_windup_ready(aim)
		return
	if _selected_weapon == ResourceData.ResourceType.SPEAR:
		_apply_spear_tuner_windup_ready(aim)
		return
	if aim.length_squared() > 0.0001:
		_rig.aim_dir = aim.normalized()
	if _rig.combat_component.state == CombatComponent.CombatState.IDLE:
		_rig.combat_component.enter_ready(aim)


func _exit_assemble_combat_ready() -> void:
	if _rig == null or _rig.combat_component == null:
		return
	if _selected_weapon == ResourceData.ResourceType.WOOD:
		_exit_club_tuner_combat_ready()
		return
	if _selected_weapon == ResourceData.ResourceType.SPEAR:
		_exit_spear_tuner_combat_ready()
		return
	if _rig.combat_component.state == CombatComponent.CombatState.READY:
		_rig.combat_component.cancel_ready()
	_refresh_rig_from_preset()
	_sync_handle_positions()
	_lock_arm_lines_to_handles()


func _apply_club_tuner_windup_ready(raw_aim: Vector2) -> void:
	## Club Shift: play saved windup idle loop (rest→A→B→rest) when keyframes exist.
	if _rig == null or _preset == null or _rig.combat_component == null:
		return
	var aim := raw_aim
	if aim.length_squared() < 0.0001:
		if _rig.aim_dir.length_squared() > 0.0001:
			aim = _rig.aim_dir
		else:
			aim = Vector2(1.0, 0.0)
	aim = aim.normalized()
	_rig.aim_dir = aim
	_rig.combat_component.aim_dir = aim
	if absf(aim.x) > 0.05:
		_rig.apply_travel_facing_direction(-1 if aim.x < 0.0 else 1)
	if _rig.combat_component.state == CombatComponent.CombatState.IDLE:
		_rig.combat_component.state = CombatComponent.CombatState.READY
	WeaponOverlayCombat.set_overlay_state(_rig, WeaponOverlayCombat.OverlayState.READY)
	if _preset.has_club_windup_idle_loop():
		_rig.set_shift_ready_windup_loop(true)
	else:
		_rig.apply_preset_overlay_ready(_preset, aim)
	_sync_combat_overlay_arm_pins()


func _apply_club_tuner_windup_aim(raw_aim: Vector2) -> void:
	if _rig == null or _rig.combat_component == null:
		return
	var aim := raw_aim
	if aim.length_squared() < 0.0001:
		return
	aim = aim.normalized()
	_rig.aim_dir = aim
	_rig.combat_component.aim_dir = aim
	if absf(aim.x) > 0.05:
		_rig.apply_travel_facing_direction(-1 if aim.x < 0.0 else 1)


func _club_shift_windup_loop_wanted() -> bool:
	return (
		_selected_weapon == ResourceData.ResourceType.WOOD
		and _preset != null
		and _preset.has_club_windup_idle_loop()
		and Input.is_action_pressed("weapon_ready")
		and _active_drag_handle == null
		and (_is_club_combat_preview_mode() or _anim_mode == AnimMode.ATTACK)
	)


func _sync_shift_ready_windup_loop() -> void:
	if _rig == null:
		return
	if _selected_weapon != ResourceData.ResourceType.WOOD:
		_rig.set_shift_ready_windup_loop(false)
		return
	_rig.set_shift_ready_windup_loop(_club_shift_windup_loop_wanted())


func _exit_club_tuner_combat_ready() -> void:
	if _rig == null or _rig.combat_component == null:
		return
	_apply_club_idle_carry_pose()


func _club_combat_support_global() -> Vector2:
	if _rig == null or _preset == null or _rig.sprite == null:
		return Vector2.ZERO
	if _rig.has_meta(WeaponOverlayCombat.CLUB_STRIKE_SUPPORT_META):
		var strike_support: Variant = _rig.get_meta(WeaponOverlayCombat.CLUB_STRIKE_SUPPORT_META)
		if strike_support is Vector2:
			return LimbPresetCoords.body_global_from_display(_rig.sprite, strike_support)
	if _rig.is_windup_idle_sample_active():
		return _rig.support_hand_global_from_windup_sample()
	var support_px := _preset.resolve_club_strike_loop_seam_support_px()
	return LimbPresetCoords.body_global_from_display(_rig.sprite, support_px)


func _holdable_label() -> String:
	return _weapon_label()


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
		ResourceData.ResourceType.PICK:
			return "pick"
		ResourceData.ResourceType.OLDOWAN:
			return "oldowan"
		_:
			return "weapon"


func _hand_sync_mode() -> AnimMode:
	if _rig and _rig.arm_controller and _rig.arm_controller.is_combat_pose_active():
		return AnimMode.ATTACK
	return _anim_mode


func _is_shift_ready_preview() -> bool:
	return (
		_mode == AppMode.ASSEMBLE
		and _anim_mode != AnimMode.ATTACK
		and Input.is_action_pressed("weapon_ready")
		and not _is_thrust_animating()
		and not _combat_animation_busy()
		and _active_drag_handle == null
	)


func _apply_shift_ready_preview() -> void:
	## Hold Shift: club windup loop or spear preset windup overlay.
	if _rig == null or _preset == null or _rig.combat_component == null:
		return
	var aim := _rig._get_cursor_aim_direction()
	if _selected_weapon == ResourceData.ResourceType.WOOD:
		if _rig.is_shift_ready_windup_loop():
			_apply_club_tuner_windup_aim(aim)
			_sync_combat_overlay_arm_pins()
		else:
			_apply_club_tuner_windup_ready(aim)
		return
	if _selected_weapon == ResourceData.ResourceType.SPEAR:
		_apply_spear_tuner_windup_ready(aim)
		return
	if aim.length_squared() > 0.0001:
		_rig.aim_dir = aim.normalized()
	if _rig.combat_component.state == CombatComponent.CombatState.IDLE:
		_rig.combat_component.enter_ready(aim)
	else:
		_rig.sync_combat_overlay(true)
	_sync_combat_overlay_arm_pins()


func _combat_preview_needs_arm_pins() -> bool:
	return (
		_combat_animation_busy()
		or _is_combat_ready_preview()
		or (_rig != null and _rig.is_shift_ready_windup_loop())
	)


func _is_combat_ready_preview() -> bool:
	return (
		_rig != null
		and _rig.combat_component != null
		and _rig.combat_component.state == CombatComponent.CombatState.READY
	)


func _resolve_club_live_grip_global() -> Vector2:
	if _rig == null or _preset == null or not _rig.has_weapon_overlay():
		return Vector2.ZERO
	var strike_active := (
		_combat_animation_busy()
		or WeaponOverlayCombat.get_overlay_state(_rig) == WeaponOverlayCombat.OverlayState.STRIKING
	)
	if _rig.is_windup_idle_sample_active() and not strike_active:
		return _rig.hand_grip_global_from_windup_sample()
	var grip_px := _preset.resolve_club_overlay_grip_px(AnimMode.ATTACK)
	if _rig.has_meta(WeaponOverlayCombat.CLUB_STRIKE_HAND_META):
		var live_grip: Variant = _rig.get_meta(WeaponOverlayCombat.CLUB_STRIKE_HAND_META)
		if live_grip is Vector2:
			grip_px = live_grip
	return LimbPresetCoords.overlay_grip_global(_rig.weapon_overlay, grip_px)


func _resolve_club_live_support_global() -> Vector2:
	if _rig == null or _preset == null:
		return Vector2.ZERO
	var strike_active := (
		_combat_animation_busy()
		or WeaponOverlayCombat.get_overlay_state(_rig) == WeaponOverlayCombat.OverlayState.STRIKING
	)
	if _rig.is_windup_idle_sample_active() and not strike_active:
		return _rig.support_hand_global_from_windup_sample()
	return _club_combat_support_global()


func _sync_club_combat_grip_pins_from_overlay() -> void:
	## Yellow 3 stays on saved grip px on club art; green 1h + arms follow.
	if _rig == null or _preset == null or _active_drag_handle != null:
		return
	if _selected_weapon != ResourceData.ResourceType.WOOD or not _rig.has_weapon_overlay():
		return
	var grip_global := _resolve_club_live_grip_global()
	_set_hand_handle_position(_spear_handle, grip_global)
	_set_hand_handle_position(_hand_handle, grip_global)
	if _support_hand_handle and _active_drag_handle != _support_hand_handle:
		_set_hand_handle_position(_support_hand_handle, _resolve_club_live_support_global())
	_sync_body_pinned_handles()
	_seed_elbow_poles_for_mode(AnimMode.ATTACK)
	_lock_arm_lines_to_handles()
	_sync_elbow_handles()


func _queue_club_combat_grip_pin_sync() -> void:
	if _club_combat_pins_sync_queued:
		return
	_club_combat_pins_sync_queued = true
	call_deferred("_flush_club_combat_grip_pin_sync")


func _flush_club_combat_grip_pin_sync() -> void:
	_club_combat_pins_sync_queued = false
	if not is_inside_tree() or _active_drag_handle != null:
		return
	_sync_club_combat_grip_pins_from_overlay()


func _sync_combat_overlay_arm_pins() -> void:
	## Club strike test: hands follow live overlay + saved attack row (not idle pins).
	if _rig == null or _preset == null or _active_drag_handle != null:
		return
	if _selected_weapon == ResourceData.ResourceType.WOOD and _rig.has_weapon_overlay():
		_sync_club_combat_grip_pins_from_overlay()
	elif _selected_weapon == ResourceData.ResourceType.SPEAR and _is_spear_windup_pin_mode():
		_sync_spear_windup_handles()
	elif _selected_weapon == ResourceData.ResourceType.SPEAR:
		_sync_spear_grip_handles()


func _tick_preview_instrumentation() -> void:
	if _preview_instrumentation == null or not _preview_instrumentation.enabled:
		return
	var snap: Dictionary = _preview_instrumentation.tick(
		_anim_mode,
		_selected_weapon,
		_rig,
		_preset,
		_hand_handle,
		_support_hand_handle
	)
	if snap.is_empty() or _status_label == null:
		return
	var base := _walk_or_combat_status_hint()
	var hud: String = _preview_instrumentation.hud_line(snap)
	if not hud.is_empty():
		_status_label.text = base + "\n" + hud
	var viol: Array = _preview_instrumentation.violations
	if not viol.is_empty() and int(snap.get("frame", 0)) % 30 == 0:
		print("[TunerInstrument] ", viol)


func _walk_or_combat_status_hint() -> String:
	if _is_club_combat_preview_mode() and not _combat_preview_needs_arm_pins():
		return "Club · %s" % _club_combat_controls_hint()
	if _travel_walk_input_allowed() and _rig and not _rig.is_walking():
		return "Hold A/D or ← → to walk."
	if _is_combat_ready_preview() and _selected_weapon == ResourceData.ResourceType.WOOD:
		return "Shift ready — %s" % _club_combat_controls_hint()
	if _is_combat_ready_preview() and _selected_weapon == ResourceData.ResourceType.SPEAR:
		return "Shift ready — %s · Y1+Y2 on shaft, 1h+2h stacked" % _spear_combat_controls_hint()
	if _combat_animation_busy() and _selected_weapon == ResourceData.ResourceType.WOOD:
		return "Striking — release Shift after swing to exit ready."
	return "Tuner instrumentation active."


func _sync_combat_strike_preview() -> void:
	## During overlay swing/recovery: arms follow live overlay grip, not stale idle pins.
	if _selected_weapon == ResourceData.ResourceType.WOOD:
		_sync_club_combat_grip_pins_from_overlay()
		return
	if _selected_weapon == ResourceData.ResourceType.SPEAR and _is_spear_windup_pin_mode():
		_sync_spear_windup_handles()
		return
	_sync_combat_overlay_arm_pins()


func _restore_tuner_pose_after_combat_preview() -> void:
	if _rig == null or _rig.combat_component == null or _preset == null:
		return
	## Shift still held after strike → resume windup, not idle.
	if (
		_selected_weapon == ResourceData.ResourceType.WOOD
		and _is_club_combat_preview_mode()
		and Input.is_action_pressed("weapon_ready")
	):
		_apply_club_tuner_windup_ready(_rig._get_cursor_aim_direction())
		_sync_windup_loop_phase_after_strike()
		return
	if (
		_selected_weapon == ResourceData.ResourceType.SPEAR
		and _is_spear_combat_preview_mode()
		and Input.is_action_pressed("weapon_ready")
	):
		_apply_spear_tuner_windup_ready(_rig._get_cursor_aim_direction())
		return
	var cc := _rig.combat_component
	if cc.state == CombatComponent.CombatState.READY:
		cc.cancel_ready()
	elif cc.state != CombatComponent.CombatState.IDLE:
		cc.state = CombatComponent.CombatState.IDLE
	if _selected_weapon == ResourceData.ResourceType.SPEAR:
		_apply_spear_idle_carry_pose()
	else:
		_apply_club_idle_carry_pose()


func _sync_windup_loop_phase_after_strike() -> void:
	## Strike recovery ends on windup key B — continue loop from there.
	if _rig == null or _preset == null or not _preset.has_club_windup_idle_loop():
		return
	_rig.seek_windup_idle_loop_phase(2.0 / 3.0)


func _sync_assemble_preview() -> void:
	if _combat_animation_busy():
		return
	if (
		_rig.combat_component != null
		and _rig.combat_component.state == CombatComponent.CombatState.READY
		and not _is_spear_shaft_pose_edit()
		and not _is_club_windup_edit()
	):
		return
	_sync_body_pinned_handles()
	_sync_weapon_pin_parenting()
	if _uses_spear_grip_on_art_pins():
		var storage := _hand_storage_mode()
		var walk_swing := _travel_walk_swing_active()
		var gather_motion := (
			WeaponLimbPreset.is_gather_mode(_anim_mode) and _rig.is_gather_preview_playing()
		)
		_rig.sync_spear_overlay_motion_preview(_preset, storage, walk_swing, gather_motion)
	if _club_idle_handle_drag_active():
		_sync_club_idle_handles_during_drag()
	elif _club_windup_handle_drag_active():
		_sync_club_windup_handles_during_drag()
	elif _spear_windup_handle_drag_active():
		_sync_spear_windup_handles_during_drag()
	else:
		_sync_hands_with_spear()
		_sync_spear_handle()
	if _uses_spear_grip_on_art_pins() and (
		_active_drag_handle == _hand_handle or _active_drag_handle == _spear_handle
	):
		_sync_spear_yellow_hand_stack_during_drag()
	_lock_arm_lines_to_handles()
	_sync_elbow_handles()


func _sync_club_windup_handles_during_drag() -> void:
	## Club windup: keep green 1h + yellow 3 on the saved grip on club art while dragging.
	_stack_club_grip_pins(AnimMode.ATTACK)


func _sync_club_idle_handles_during_drag() -> void:
	## Keep green 1h + yellow 3 stacked while dragging either; do not snap back to preset.
	if _active_drag_handle == _hand_handle and _spear_handle:
		_spear_handle.global_position = _hand_handle.global_position
	elif _active_drag_handle == _spear_handle and _hand_handle:
		_hand_handle.global_position = _spear_handle.global_position


func _sync_spear_yellow_hand_stack_during_drag() -> void:
	if not _uses_spear_grip_on_art_pins():
		return
	if _active_drag_handle == _hand_handle and _spear_handle:
		_spear_handle.global_position = _hand_handle.global_position
	elif _active_drag_handle == _spear_handle and _hand_handle:
		_hand_handle.global_position = _spear_handle.global_position


func _sync_body_pinned_handles() -> void:
	if _rig == null or _preset == null:
		return
	if _active_drag_handle != _shoulder_handle and _shoulder_handle:
		_shoulder_handle.global_position = _rig.shoulder_global_from_preset(_preset)
	if _active_drag_handle != _support_shoulder_handle and _support_shoulder_handle:
		_support_shoulder_handle.global_position = _rig.support_shoulder_global_from_preset(_preset)
	if _active_drag_handle != _head_handle and _head_handle:
		_head_handle.global_position = _rig.neck_socket_global()


func _ensure_handle_on_stage(handle: LimbTunerHandle) -> void:
	if handle == null or _handle_stage == null or _uses_world_draw_layer(handle):
		return
	if handle.get_parent() != _handle_stage:
		var grip_global := handle.global_position
		handle.reparent(_handle_stage)
		handle.global_position = grip_global
		_apply_uniform_handle_radius(handle)


func _sync_handle_positions() -> void:
	if _rig == null or _preset == null:
		return
	_sync_body_pinned_handles()
	_sync_weapon_pin_parenting()
	_sync_hands_with_spear()
	_sync_spear_handle()
	_sync_elbow_handles()
	_lock_arm_lines_to_handles()


func _sync_elbow_handles() -> void:
	if _rig == null or _preset == null:
		return
	var mode := _hand_sync_mode()
	if _active_drag_handle != _weapon_elbow_handle:
		_sync_one_elbow_from_ik(true, mode)
	if _active_drag_handle != _support_elbow_handle and _active_drag_handle != _weapon_elbow_handle:
		_sync_one_elbow_from_ik(false, mode)


func _sync_one_elbow_from_ik(dominant: bool, mode: AnimMode) -> void:
	var elbow_handle: LimbTunerHandle = _weapon_elbow_handle if dominant else _support_elbow_handle
	var shoulder_handle: LimbTunerHandle = _shoulder_handle if dominant else _support_shoulder_handle
	var hand_handle: LimbTunerHandle = _hand_handle if dominant else _support_hand_handle
	if elbow_handle == null or shoulder_handle == null or hand_handle == null:
		return
	if _rig.arm_controller and not _is_club_windup_edit() and not _is_spear_shaft_pose_edit():
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
	if _is_idle_club_anim_mode() and _idle_club_minimal_active:
		return
	if _preset == null or LimbPresetRegistry == null:
		return
	LimbPresetRegistry.stage_preset(_preset)
	if _rig and _rig.arm_controller and _rig.arm_controller.config:
		LimbPresetRegistry.apply_to_arm_config(_rig.arm_controller.config, _preset)
		_rig.arm_controller.refresh_line_styles_from_config()
		_sync_active_bend_signs_to_config()


func _lock_arm_lines_to_handles() -> void:
	if _is_idle_club_anim_mode() and _idle_club_minimal_active:
		return
	if _rig == null or _rig.arm_controller == null:
		return
	_ensure_tuner_arms_visible()
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


func _set_hand_handle_position(handle: LimbTunerHandle, global_pos: Vector2) -> void:
	if handle == null:
		return
	_ensure_handle_on_stage(handle)
	handle.global_position = global_pos


func _sync_hands_with_spear() -> void:
	if _rig == null or _preset == null:
		return
	if _is_spear_windup_pin_mode():
		_sync_spear_windup_handles()
		return
	var mode := _hand_sync_mode()
	var ready_hands := _use_ready_support_hand()
	var gather_motion := WeaponLimbPreset.is_gather_mode(mode) and _rig.is_gather_preview_playing()
	var walk_swing := _travel_walk_swing_active()
	var swing_mode := _walk_swing_mode() if walk_swing else mode
	if _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay() and not _idle_club_pins_independent():
		if _uses_club_walk_carry_pose():
			_sync_club_grip_pins_from_storage(_hand_storage_mode())
		elif _is_club_windup_edit():
			_sync_club_grip_pins_from_storage(AnimMode.ATTACK)
		elif _anim_mode == AnimMode.IDLE_CLUB1:
			_sync_club_grip_pins_from_storage(AnimMode.IDLE_CLUB1)
		else:
			_sync_dominant_grip_stack(mode, walk_swing, gather_motion)
	elif _uses_spear_grip_on_art_pins():
		_sync_spear_grip_pins_from_overlay(_hand_storage_mode())
	elif _active_drag_handle != _hand_handle and _active_drag_handle != _spear_handle:
		var hand_global: Vector2
		if gather_motion:
			hand_global = _rig.hand_grip_global_with_gather_motion(_preset, mode)
		elif walk_swing:
			hand_global = _rig.hand_grip_global_with_walk_swing(_preset, swing_mode)
		else:
			hand_global = _rig.hand_grip_global_from_preset(_preset, mode)
		hand_global = _clamp_dominant_hand_global(
			_shoulder_handle.global_position, hand_global, walk_swing, gather_motion
		)
		_set_hand_handle_position(_hand_handle, hand_global)
	if ready_hands:
		if _active_drag_handle != _support_hand_handle:
			var support_global: Vector2
			if gather_motion:
				support_global = _rig.support_hand_global_with_gather_motion(_preset, mode)
			elif walk_swing:
				support_global = _rig.support_hand_global_with_walk_swing(_preset, swing_mode)
			else:
				support_global = _rig.support_hand_global_for_mode(_preset, mode)
			support_global = _clamp_support_hand_global(
				_support_shoulder_handle.global_position, support_global, walk_swing, gather_motion
			)
			_set_hand_handle_position(_support_hand_handle, support_global)
	elif _active_drag_handle != _support_hand_handle:
		var support_global: Vector2
		if _rig.is_windup_idle_sample_active():
			support_global = _rig.support_hand_global_from_windup_sample()
		elif (
			_is_idle1_anim_mode()
			and _rig.is_preview_playing()
			and not _use_ready_support_hand()
			and _preset.has_idle_arm2_raise_pose()
		):
			var raise_blend := _rig.get_idle_arm2_raise_blend()
			if raise_blend > 0.0001:
				support_global = _rig.support_hand_idle_global_with_raise(_preset, raise_blend)
			else:
				support_global = _rig.support_hand_global_for_mode(_preset, mode)
		elif gather_motion:
			support_global = _rig.support_hand_global_with_gather_motion(_preset, mode)
		elif walk_swing:
			support_global = _rig.support_hand_global_with_walk_swing(_preset, swing_mode)
		else:
			support_global = _rig.support_hand_global_for_mode(_preset, mode)
		support_global = _clamp_support_hand_global(
			_support_shoulder_handle.global_position, support_global, walk_swing, gather_motion
		)
		_set_hand_handle_position(_support_hand_handle, support_global)


func _use_ready_support_hand() -> bool:
	if not WeaponLimbPreset.uses_two_hand_grip(_selected_weapon):
		return false
	if _is_spear_windup_pin_mode():
		return true
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
	var overlay_mode := _overlay_storage_mode()
	if _is_spear_strike_edit():
		_preset.seed_spear_attack_windup_if_unset()
		_rig.apply_tuner_spear_strike_overlay(_preset, Vector2(1.0, 0.0))
	elif _is_spear_windup_edit() or (
		_selected_weapon == ResourceData.ResourceType.SPEAR and _anim_mode == AnimMode.ATTACK
	):
		_preset.seed_spear_attack_windup_if_unset()
		_rig.apply_tuner_spear_windup_overlay(_preset, Vector2(1.0, 0.0))
	else:
		_rig.apply_preset_overlay_for_mode(_preset, overlay_mode)
	_verify_tuner_snapshot_isolation(overlay_mode)
	_push_preset_to_arms()
	_maybe_seed_hand_grip_at_weapon_anchor()
	if _rig and _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay() and not _uses_decoupled_weapon_hand_pins():
		if not _preset.uses_saved_club_grip_on_art():
			var hand_storage := _hand_storage_mode()
			var overlay_set := _preset.resolve_overlay_for_mode(_overlay_storage_mode()).length_squared() > 0.0001
			var grip_set := _preset.resolve_hand_grip_for_mode(hand_storage).length_squared() > 0.0001
			if not grip_set and not overlay_set:
				_rig.snap_hand_grip_to_weapon_anchor(_preset, _anim_mode == AnimMode.ATTACK)
	_preset.set_shared_arm_lengths(_preset.upper_arm_length, _preset.lower_arm_length)
	if _anim_mode == AnimMode.IDLE_CLUB1:
		_align_club_idle_club1_to_none_hand()
		_layout_club_idle_handles_and_arms()
	elif _uses_club_walk_carry_pose():
		_layout_club_idle_handles_and_arms()
	else:
		_seed_elbow_poles_for_mode(_anim_mode)
		_sync_handle_positions()
	_apply_handle_draggable()
	_lock_arm_lines_to_handles()
	_update_weapon_handle_visibility()


func _verify_tuner_snapshot_isolation(overlay_storage_mode: AnimMode) -> void:
	if not OS.is_debug_build() or _rig == null or _preset == null:
		return
	if not _rig.has_weapon_overlay():
		return
	var live := _rig.display_px_from_overlay_position()
	if not _preset.verify_tuner_overlay_matches(_anim_mode, live):
		var expected := _preset.resolve_overlay_for_mode(overlay_storage_mode)
		push_error(
			"LimbTuner snapshot leak: pose=%s storage=%s expected_overlay=%s live=%s"
			% [
				str(_anim_mode),
				str(overlay_storage_mode),
				str(expected),
				str(live),
			]
		)


func _maybe_seed_hand_grip_at_weapon_anchor() -> void:
	if _rig == null or _preset == null or not _rig.has_weapon_overlay():
		return
	if _uses_decoupled_weapon_hand_pins():
		return
	if _rig.uses_weapon_grip_anchor_hand():
		if _preset.uses_saved_club_grip_on_art():
			return
		if _preset.resolve_hand_grip_for_mode(_anim_mode).length_squared() > 0.01:
			return
		_rig.snap_dominant_hand_grip_to_weapon_anchor(_preset)
	elif _selected_weapon == ResourceData.ResourceType.SPEAR and _preset.spear_hand_grip_needs_reseed():
		_rig.snap_hand_grip_to_weapon_anchor(_preset, _anim_mode == AnimMode.ATTACK)


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
	var prev_mode := _anim_mode
	_anim_mode = mode
	if mode == AnimMode.WALK1:
		_preset.seed_walk1_from_walk_if_unset()
	elif mode == AnimMode.WALK:
		_preset.seed_walk_from_idle_if_unset()
	elif mode == AnimMode.GATHER1:
		_preset.seed_gather1_from_idle_if_unset()
	elif mode == AnimMode.IDLE_CLUB1:
		_ensure_club_holdable_for_idle_club1()
		_preset.seed_idle_club1_from_idle_if_unset()
	elif mode == AnimMode.ATTACK:
		if _selected_weapon == ResourceData.ResourceType.SPEAR:
			_preset.seed_spear_attack_windup_if_unset()
		else:
			_preset.seed_attack_from_idle_if_unset()
	if not WeaponLimbPreset.is_walk_mode(mode) and _rig:
		_rig.set_walk_direction(0)
	if mode != AnimMode.ATTACK and prev_mode == AnimMode.ATTACK:
		_cancel_attack_mode_combat()
	elif mode == AnimMode.ATTACK:
		_exit_assemble_combat_ready()
	if mode == AnimMode.ATTACK and (
		_selected_weapon == ResourceData.ResourceType.WOOD
		or _selected_weapon == ResourceData.ResourceType.SPEAR
	):
		_anim_playing = true
	else:
		_anim_playing = false
	_refresh_rig_from_preset()
	if prev_mode == AnimMode.IDLE_CLUB1 and mode != AnimMode.IDLE_CLUB1:
		_idle_club_minimal_active = false
		_apply_idle_club_minimal_view(false)
	_apply_handle_number_labels()
	_selected_category = AnimCatalog.category_for_mode(_selected_weapon, mode)
	_rebuild_variant_buttons()
	_sync_animation_picker_ui()
	_update_ui()
	_sync_preview_playback()
	if _status_label:
		if _anim_mode == AnimMode.ATTACK:
			if _selected_weapon == ResourceData.ResourceType.WOOD:
				_status_label.text = (
					"Attack peak — drag pins · Shift+click test swing on Club · Idle standing."
				)
			elif _selected_weapon == ResourceData.ResourceType.SPEAR:
				if _preset and _preset.attack_pose_inherits_idle():
					_status_label.text = (
						"Attack windup — drag Y1 to move spear · Y2 = hand-2 snap (independent of 2h) · Save all. "
						+ "Test thrust on Spear · Idle standing: Shift+click."
					)
				else:
					_status_label.text = (
						"Attack windup — drag Y1 to position spear · drag Y2 for hand-2 snap on shaft · Save all. "
						+ "Test thrust on Spear · Idle standing: Shift+click."
					)
			else:
				_status_label.text = "Attack ready — drag pins · Shift+click to test swing."
		elif WeaponLimbPreset.is_walk_mode(_anim_mode):
			_status_label.text = "Walk pose — drag pins · A/D or ← → to preview walk."
		elif _is_gather_anim_mode():
			_status_label.text = "Gather pose — Play to preview cycle, Pause to edit pins."
		elif _is_idle_anim_mode():
			if _selected_weapon == ResourceData.ResourceType.WOOD:
				_status_label.text = (
					"Idle standing — A/D walk · Shift = windup · Shift+click = swing · drag pins."
				)
			elif _selected_weapon == ResourceData.ResourceType.SPEAR:
				_status_label.text = (
					"Idle standing — Shift = windup · Shift+click = test thrust · drag pins to edit carry."
				)
			else:
				_status_label.text = "Idle pose — Play to preview bob, Pause to edit pins."
		else:
			_status_label.text = "Editing %s · %s." % [_holdable_label(), _anim_mode_label()]
	_recenter_character_only()


func _apply_handle_draggable() -> void:
	var can_drag := _mode == AppMode.ASSEMBLE
	var two_hand := WeaponLimbPreset.uses_two_hand_grip(_selected_weapon)
	var spear_windup_edit := _is_spear_shaft_pose_edit()
	var spear_windup_pins := _is_spear_windup_pin_mode()
	var club_windup := _is_club_windup_edit()
	_shoulder_handle.set_draggable(can_drag)
	_hand_handle.set_draggable(
		can_drag and not (_is_idle_club_anim_mode() and _idle_club_minimal_active)
	)
	_support_shoulder_handle.set_draggable(can_drag)
	_support_hand_handle.set_draggable(
		can_drag
		and (
			spear_windup_edit
			or (
				not spear_windup_edit
				and (_anim_mode != AnimMode.ATTACK or two_hand or club_windup)
			)
		)
	)
	var weapon_drag := can_drag and _rig != null and _rig.has_weapon_overlay()
	_spear_handle.set_draggable(weapon_drag and (spear_windup_edit or club_windup))
	if _spear_grip_2_handle:
		_spear_grip_2_handle.set_draggable(weapon_drag and spear_windup_edit)
		_spear_grip_2_handle.visible = weapon_drag and spear_windup_pins
	if _weapon_elbow_handle:
		_weapon_elbow_handle.set_draggable(false)
	if _support_elbow_handle:
		_support_elbow_handle.set_draggable(false)
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
	var mode := _hand_align_mode()
	var clamped := _clamp_dominant_hand_global(
		_shoulder_handle.global_position, _hand_handle.global_position
	)
	_set_hand_handle_position(_hand_handle, clamped)
	if _is_club_windup_edit():
		_on_club_windup_grip_dragged(_hand_handle.global_position)
	elif _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay() and not _idle_club_pins_independent():
		_rig.align_weapon_overlay_to_hand_grip_global(_preset, clamped, mode)
		var stacked := _rig.hand_grip_global_from_preset(_preset, _hand_storage_mode())
		_set_hand_handle_position(_hand_handle, stacked)
		_set_hand_handle_position(_spear_handle, stacked)
	else:
		var adjusted := _rig.project_hand_grip_drag_global(clamped, _preset, mode)
		_rig.set_hand_grip_from_global(_preset, adjusted, mode)
		_set_hand_handle_position(_hand_handle, _rig.hand_grip_global_from_preset(_preset, mode))
		_sync_spear_grip_pin_on_art()


func _clamp_support_hand_to_reach() -> void:
	if _rig == null or _preset == null or _support_shoulder_handle == null or _support_hand_handle == null:
		return
	var clamped := _clamp_support_hand_global(
		_support_shoulder_handle.global_position, _support_hand_handle.global_position
	)
	_set_hand_handle_position(_support_hand_handle, clamped)
	_rig.set_support_hand_for_mode(_preset, _anim_mode, clamped)


func _on_hand_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	var mode := _hand_align_mode()
	if _is_spear_shaft_pose_edit():
		_on_spear_windup_grip_dragged(global_pos)
		return
	if _is_club_windup_edit():
		_on_club_windup_grip_dragged(global_pos)
		return
	var clamped := _clamp_dominant_hand_global(_shoulder_handle.global_position, global_pos)
	if _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay() and not _idle_club_pins_independent():
		_rig.align_weapon_overlay_to_hand_grip_global(_preset, clamped, mode)
		var stacked := _rig.hand_grip_global_from_preset(_preset, _hand_storage_mode())
		_set_hand_handle_position(_hand_handle, stacked)
		_set_hand_handle_position(_spear_handle, stacked)
	else:
		var adjusted := _rig.project_hand_grip_drag_global(clamped, _preset, mode)
		_rig.set_hand_grip_from_global(_preset, adjusted, mode)
		_set_hand_handle_position(_hand_handle, _rig.hand_grip_global_from_preset(_preset, mode))
		_sync_spear_grip_pin_on_art()


func _on_support_shoulder_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	_rig.set_support_shoulder_from_global(_preset, global_pos)
	_clamp_support_hand_to_reach()


func _on_support_hand_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	var clamped := _clamp_support_hand_global(
		_support_shoulder_handle.global_position, global_pos
	)
	if _anim_mode == AnimMode.ATTACK and WeaponLimbPreset.uses_two_hand_grip(_selected_weapon):
		var adjusted := _rig.project_support_hand_grip_drag_global(clamped, _preset)
		_rig.set_support_hand_from_global(_preset, adjusted)
		if _is_spear_shaft_pose_edit():
			_sync_spear_windup_handles_during_drag()
		else:
			_set_hand_handle_position(
				_support_hand_handle, _rig.support_hand_global_from_preset(_preset)
			)
	else:
		_rig.set_support_hand_for_mode(_preset, _anim_mode, clamped)
		_set_hand_handle_position(_support_hand_handle, clamped)


func _on_head_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	_rig.set_neck_socket_from_global(global_pos)


func _on_spear_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE:
		return
	if _rig.weapon_overlay == null or not _rig.has_weapon_overlay():
		return
	if _is_idle_club_anim_mode() and _idle_club_minimal_active:
		_on_idle_club_grip_dragged(global_pos)
		return
	if _is_club_windup_edit():
		_on_club_windup_grip_dragged(global_pos)
		return
	if _rig.uses_weapon_grip_anchor_hand() and _rig.has_weapon_overlay() and not _idle_club_pins_independent():
		var mode := _hand_align_mode()
		var clamped := _clamp_dominant_hand_global(_shoulder_handle.global_position, global_pos)
		_rig.align_weapon_overlay_to_hand_grip_global(_preset, clamped, mode)
		var stacked := _rig.hand_grip_global_from_preset(_preset, _hand_storage_mode())
		_set_hand_handle_position(_hand_handle, stacked)
		_set_hand_handle_position(_spear_handle, stacked)
		return
	if _selected_weapon == ResourceData.ResourceType.SPEAR:
		if _is_spear_shaft_pose_edit():
			_on_spear_windup_grip_dragged(global_pos)
			return
		var grip_mode := _hand_storage_mode()
		var clamped_spear := _clamp_dominant_hand_global(_shoulder_handle.global_position, global_pos)
		var adjusted := _rig.project_hand_grip_drag_global(clamped_spear, _preset, grip_mode)
		_rig.set_hand_grip_from_global(_preset, adjusted, grip_mode)
		var grip_global := _rig.hand_grip_global_from_preset(_preset, grip_mode)
		_set_hand_handle_position(_hand_handle, grip_global)
		_set_hand_handle_position(_spear_handle, grip_global)
		return
	var display_px := _rig.move_weapon_overlay_global(global_pos)
	_preset.set_overlay_for_mode(_anim_mode, display_px)


func _on_spear_grip_2_dragged(global_pos: Vector2) -> void:
	if _mode != AppMode.ASSEMBLE or not _is_spear_shaft_pose_edit():
		return
	if _rig.weapon_overlay == null or not _rig.has_weapon_overlay():
		return
	## Free placement on spear art — no shaft-axis lock (horizontal windup needs 2D tuning).
	_rig.set_support_hand_from_global(_preset, global_pos)
	_stack_spear_windup_support_pins()


func _commit_anim_mode(mode: AnimMode) -> void:
	if _rig == null or _preset == null:
		return
	var committed_attack := (
		mode == AnimMode.ATTACK
		and (
			_selected_weapon == ResourceData.ResourceType.WOOD
			or _selected_weapon == ResourceData.ResourceType.SPEAR
		)
	)
	var grip_mode := WeaponLimbPreset.tuner_commit_storage_mode(mode)
	if mode == AnimMode.IDLE_CLUB1:
		grip_mode = AnimMode.IDLE_CLUB1
	if mode != AnimMode.IDLE_CLUB1:
		if _shoulder_handle:
			_rig.set_shoulder_from_global(_preset, _shoulder_handle.global_position)
		if _support_shoulder_handle:
			_rig.set_support_shoulder_from_global(_preset, _support_shoulder_handle.global_position)
	if mode == AnimMode.IDLE_CLUB1 and _idle_club_minimal_active and _spear_handle and _rig.has_weapon_overlay():
		_rig.set_hand_grip_from_global(_preset, _spear_handle.global_position, mode)
	elif (
		mode == AnimMode.ATTACK
		and _selected_weapon == ResourceData.ResourceType.SPEAR
		and _spear_handle
		and _rig.has_weapon_overlay()
	):
		## Y1 on shaft art is authoritative for dominant windup grip.
		_rig.set_hand_grip_from_global(_preset, _spear_handle.global_position, AnimMode.ATTACK)
	elif _hand_handle and not (mode == AnimMode.IDLE_CLUB1):
		_rig.set_hand_grip_from_global(_preset, _hand_handle.global_position, grip_mode)
	if _support_hand_handle:
		if (
			mode == AnimMode.ATTACK
			and _selected_weapon == ResourceData.ResourceType.SPEAR
			and _spear_grip_2_handle
		):
			## Hand 2 snap target is Y2 on spear art, not green 2h pin position.
			_rig.set_support_hand_from_global(_preset, _spear_grip_2_handle.global_position)
		elif mode == AnimMode.ATTACK and WeaponLimbPreset.uses_two_hand_grip(_selected_weapon):
			_rig.set_support_hand_from_global(_preset, _support_hand_handle.global_position)
		else:
			_rig.set_support_hand_for_mode(_preset, mode, _support_hand_handle.global_position)
	if _rig.has_weapon_overlay():
		var display_px := _rig.display_px_from_overlay_position()
		if (
			mode == AnimMode.ATTACK
			and _selected_weapon == ResourceData.ResourceType.SPEAR
			and _spear_attack_edit_target == "windup"
		):
			_preset.ready_offset_px = display_px
		elif (
			mode == AnimMode.ATTACK
			and _selected_weapon == ResourceData.ResourceType.SPEAR
			and _spear_attack_edit_target == "strike"
		):
			_preset.strike_offset_px = display_px
		else:
			_preset.set_overlay_for_mode(grip_mode, display_px)
		if _weapon_rotation_spin:
			_preset.set_rotation_deg_for_mode(mode, float(_weapon_rotation_spin.value))
	if _weapon_elbow_handle:
		_rig.set_elbow_pole_from_global(_preset, true, grip_mode, _weapon_elbow_handle.global_position)
	if _support_elbow_handle:
		_rig.set_elbow_pole_from_global(_preset, false, grip_mode, _support_elbow_handle.global_position)
	if committed_attack:
		_preset.mark_attack_windup_pose_saved()


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
	LimbPresetRegistry.stage_preset(_preset)
	var save_result: Dictionary = LimbPresetRegistry.save_all_staged()
	var err: Error = save_result.get("err", ERR_CANT_CREATE) as Error
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
			var saved_count: int = int(save_result.get("count", 0))
			if saved_count <= 1:
				_status_label.text = "Saved all poses for %s to disk." % _holdable_label()
			else:
				_status_label.text = (
					"Saved %d holdable presets to disk (current: %s)."
					% [saved_count, _holdable_label()]
				)
		else:
			_status_label.text = "Save failed (arms=%s, head=%s)" % [str(err), str(layout_err)]


func _on_reload_pressed() -> void:
	_reload_all_from_disk()
	if _status_label:
		_status_label.text = "Reloaded saved file from disk."


func _on_reset_pose_pressed() -> void:
	if _preset == null:
		return
	_preset.reset_mode_to_defaults(_anim_mode)
	_refresh_rig_from_preset()
	_center_view()
	_update_ui()
	if _status_label:
		_status_label.text = "Reset %s pose on %s to defaults." % [_anim_mode_label(), _holdable_label()]


func _on_reset_anchors_pressed() -> void:
	if _preset == null:
		return
	_preset.reset_anchors_to_defaults()
	if _rig:
		_rig.reset_head_layout_to_defaults()
	_refresh_rig_from_preset()
	_center_view()
	_update_ui()
	if _status_label:
		_status_label.text = "Reset shoulders, head, and arm length to defaults."


func _reload_all_from_disk() -> void:
	LimbPresetRegistry.reload_all_presets("clansmen_1")
	_preset = LimbPresetRegistry.get_preset(_selected_weapon, "clansmen_1", 1)
	if _rig:
		_rig.reload_mannequin_from_layout()
		_rig.refresh_weapon_overlay()
		if _rig.arm_controller:
			_rig.arm_controller.initialize_tuner_arm_layers()
		_apply_tuner_draw_layers()
		if _rig.has_method("_sync_tuner_arm_process"):
			_rig.call("_sync_tuner_arm_process")
	_refresh_rig_from_preset()
	_update_ui()
	call_deferred("_apply_fixed_stage_view")
	call_deferred("_ensure_handles_on_overlay")


func _on_copy_pressed() -> void:
	if _preset == null:
		return
	_commit_all_poses_to_preset()
	var summary := _preset.to_chat_handoff(_holdable_label())
	var json := JSON.stringify(_preset.to_export_dict(), "\t")
	var clipboard := summary + "\n\n--- JSON (paste to agent / lock-in script) ---\n" + json
	DisplayServer.clipboard_set(clipboard)
	if _status_label:
		var hint := "Copied summary + JSON."
		if _is_spear_shaft_pose_edit():
			hint += " Spear attack block includes Y1/Y2, ready, strike, elbows."
		hint += " Use Save all to write .tres."
		_status_label.text = hint


func _update_ui() -> void:
	if _summary_label and _preset:
		var editing: Dictionary = _format_pose_row(_anim_mode, true) as Dictionary
		var reach := _reach_warning_suffix()
		var reach_line := ""
		if not reach.is_empty():
			reach_line = "\n" + reach.strip_edges()
		var pin_help := (
			"\nIdle Club: drag yellow 3 on club art (grip). Club position locked."
			if _is_idle_club_anim_mode()
			else (
				"\nSpear attack edit: Y1 moves spear + 1h · strike row = furthest extension."
				if _is_spear_strike_edit()
				else (
					"\nSpear windup: Y1 moves spear + 1h · Pause to freeze."
					if _is_spear_windup_edit()
					else (
						"\nClub windup: drag 1h/3 · subtle idle loop · Pause to freeze pins."
						if _is_club_windup_edit()
						else "\nPins: hold+drag · click 1e/2e flip elbow"
					)
				)
			)
		)
		_summary_label.text = (
			"%s · %s\n"
			+ "Hand %s · Holdable %s\n"
			+ "Elbows: 1e %s · 2e %s\n"
			+ "Arms: %.0f / %.0f px · thickness %.0f px\n"
			+ "Idle preview: %s\n"
			+ "Shoulders 1/2 · hands 1h/2h · holdable 3 · head H%s"
		) % [
			_holdable_label(),
			_anim_mode_label(),
			editing["hand"],
			editing["overlay"],
			editing["bend_1e"],
			editing["bend_2e"],
			_preset.upper_arm_length,
			_preset.lower_arm_length,
			_preset.arm_width,
			"playing" if (_anim_playing and _windup_idle_preview_active()) else (
				"playing" if (_anim_playing and _is_idle_anim_mode()) else (
					"playing" if (_anim_playing and _is_gather_anim_mode()) else (
						"paused" if _is_idle_anim_mode() else (
							"paused" if _is_gather_anim_mode() else (
								"paused" if _windup_idle_preview_active() else "n/a"
							)
						)
					)
				)
			),
			pin_help + reach_line,
		]
	_update_idle_club_handle_visibility()
	_sync_arm_length_fields_from_preset()
	_sync_arm_thickness_field_from_preset()
	_sync_animation_picker_ui()
	_apply_handle_draggable()
	_apply_handle_number_labels()
	_update_weapon_handle_visibility()
	_sync_bake_button()
	_update_weapon_rotation_section_visibility()
	_sync_weapon_rotation_spin_from_rig()
	if (
		_status_label
		and _is_club_combat_preview_mode()
		and not _combat_preview_needs_arm_pins()
		and (_preview_instrumentation == null or not _preview_instrumentation.enabled)
	):
		_status_label.text = "Club · Idle — %s" % _club_combat_controls_hint()
	elif (
		_status_label
		and _travel_walk_input_allowed()
		and _rig
		and not _rig.is_walking()
		and not _combat_preview_needs_arm_pins()
		and (_preview_instrumentation == null or not _preview_instrumentation.enabled)
	):
		_status_label.text = "Hold A/D or ← → to walk."


func _format_pose_row(mode: AnimMode, for_editing: bool) -> Variant:
	var hand := _preset.resolve_hand_grip_for_mode(mode)
	var overlay := _preset.resolve_overlay_for_mode(mode)
	if mode == AnimMode.ATTACK and _selected_weapon == ResourceData.ResourceType.SPEAR:
		hand = _preset.hand_grip_ready_offset_px
		overlay = _preset.ready_offset_px
	var bend_1e := WeaponLimbPreset.bend_sign_chat_label(
		_preset.resolve_elbow_bend_sign_override(true, mode)
	)
	var bend_2e := WeaponLimbPreset.bend_sign_chat_label(
		_preset.resolve_elbow_bend_sign_override(false, mode)
	)
	var hand_2 := _preset.support_hand_idle_offset_px
	if WeaponLimbPreset.is_walk_mode(mode) or WeaponLimbPreset.is_gather_mode(mode):
		var mode_hand := _preset.resolve_support_hand_for_mode(mode)
		if mode_hand.length_squared() > 0.0001:
			hand_2 = mode_hand
	elif mode == AnimMode.ATTACK and WeaponLimbPreset.uses_two_hand_grip(_selected_weapon):
		hand_2 = _preset.support_hand_offset_px
	if for_editing:
		return {
			"hand": str(hand),
			"overlay": str(overlay),
			"bend_1e": bend_1e,
			"bend_2e": bend_2e,
			"hand_2": str(hand_2),
		}
	var mode_name := "Idle"
	match mode:
		AnimMode.IDLE1:
			mode_name = "Idle 1"
		AnimMode.WALK:
			mode_name = "Walk"
		AnimMode.WALK1:
			mode_name = "Walk 1"
		AnimMode.GATHER1:
			mode_name = "Gather 1"
		AnimMode.IDLE_CLUB1:
			mode_name = "Idle Club 1"
		AnimMode.ATTACK:
			if _selected_weapon == ResourceData.ResourceType.WOOD or _selected_weapon == ResourceData.ResourceType.SPEAR:
				mode_name = "Attack windup"
			else:
				mode_name = "Attack"
	return "%s — hand %s | weapon %s | 1e %s | 2e %s" % [
		mode_name, str(hand), str(overlay), bend_1e, bend_2e
	]


func _reach_warning_suffix() -> String:
	var warnings := _collect_reach_warnings()
	if warnings.is_empty():
		return ""
	return "\n⚠ Reach: " + ", ".join(warnings)


func _collect_reach_warnings() -> PackedStringArray:
	var out: PackedStringArray = []
	if _is_out_of_reach(_shoulder_handle, _hand_handle, true):
		out.append("dominant hand")
	if _is_out_of_reach(_support_shoulder_handle, _support_hand_handle, false):
		out.append("off hand")
	return out


func _is_out_of_reach(shoulder_handle: LimbTunerHandle, hand_handle: LimbTunerHandle, dominant: bool) -> bool:
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
	var max_reach: float = _preset.tuner_ik_max_reach_px(dominant) * sx
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
