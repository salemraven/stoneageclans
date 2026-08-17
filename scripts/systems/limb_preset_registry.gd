extends Node

## Loads/saves WeaponLimbPreset .tres files; single source of truth for procedural limbs in game + tuner.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const PRESETS_DIR := "res://assets/limb_presets/"

## Holdables edited in LimbTuner — reload_all_presets refreshes every file.
const TUNER_HOLDABLES: Array[ResourceData.ResourceType] = [
	ResourceData.ResourceType.NONE,
	ResourceData.ResourceType.WOOD,
	ResourceData.ResourceType.SPEAR,
	ResourceData.ResourceType.AXE,
	ResourceData.ResourceType.PICK,
	ResourceData.ResourceType.OLDOWAN,
]

var _cache: Dictionary = {}
## Presets edited this session (Save all writes only these — not every cached holdable).
var _dirty_keys: Dictionary = {}


func _ready() -> void:
	_ensure_presets_dir()


func _ensure_presets_dir() -> void:
	var abs_dir := ProjectSettings.globalize_path(PRESETS_DIR)
	if not DirAccess.dir_exists_absolute(abs_dir):
		DirAccess.make_dir_recursive_absolute(abs_dir)


func preset_path(weapon_type: ResourceData.ResourceType, body_card_id: String = "clansmen_1") -> String:
	var weapon_slug := _weapon_slug(weapon_type)
	return PRESETS_DIR + "%s_%s.tres" % [weapon_slug, body_card_id]


func get_preset(
	weapon_type: ResourceData.ResourceType,
	body_card_id: String = "clansmen_1",
	body_index: int = 1
) -> WeaponLimbPreset:
	var key := "%d:%s" % [int(weapon_type), body_card_id]
	if _cache.has(key):
		return _cache[key] as WeaponLimbPreset
	var path := preset_path(weapon_type, body_card_id)
	var preset: WeaponLimbPreset = null
	if ResourceLoader.exists(path):
		preset = load(path) as WeaponLimbPreset
	if preset == null:
		preset = WeaponLimbPresetScript.defaults_for(weapon_type, body_index)
	if preset != null:
		preset.migrate_legacy_club_grip_on_art()
		preset.ensure_unified_clips(self)
	_cache[key] = preset
	return preset


func save_preset(preset: WeaponLimbPreset) -> Error:
	if preset == null:
		return ERR_INVALID_PARAMETER
	_ensure_presets_dir()
	var path := preset_path(preset.weapon_type, preset.body_card_id)
	var err := ResourceSaver.save(preset, path)
	if err == OK:
		var key := "%d:%s" % [int(preset.weapon_type), preset.body_card_id]
		_cache[key] = preset
	return err


func reload_preset(weapon_type: ResourceData.ResourceType, body_card_id: String = "clansmen_1") -> WeaponLimbPreset:
	var key := "%d:%s" % [int(weapon_type), body_card_id]
	_cache.erase(key)
	var path := preset_path(weapon_type, body_card_id)
	var preset: WeaponLimbPreset = null
	if ResourceLoader.exists(path):
		preset = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as WeaponLimbPreset
	if preset == null:
		preset = WeaponLimbPresetScript.defaults_for(weapon_type, 1)
		preset.body_card_id = body_card_id
	if preset != null:
		preset.migrate_legacy_club_grip_on_art()
		preset.ensure_unified_clips(self)
	_cache[key] = preset
	return preset


func reload_all_presets(body_card_id: String = "clansmen_1") -> void:
	for weapon_type in TUNER_HOLDABLES:
		reload_preset(weapon_type, body_card_id)
	clear_staged_dirty()


## Write presets the user actually edited this session (see mark_staged_dirty).
func save_all_staged() -> Dictionary:
	var out := {"err": OK, "count": 0, "failed_keys": [] as Array[String], "skipped": 0}
	if _dirty_keys.is_empty():
		return out
	for key in _dirty_keys.keys():
		if not _cache.has(key):
			continue
		var preset := _cache[key] as WeaponLimbPreset
		if preset == null:
			continue
		var err := save_preset(preset)
		out.count = int(out.count) + 1
		if err != OK:
			out.err = err
			(out.failed_keys as Array).append(String(key))
	_dirty_keys.clear()
	return out


func mark_staged_dirty(preset: WeaponLimbPreset) -> void:
	if preset == null:
		return
	var key := _preset_cache_key(preset.weapon_type, preset.body_card_id)
	_dirty_keys[key] = true
	stage_preset(preset)


func clear_staged_dirty() -> void:
	_dirty_keys.clear()


func is_staged_dirty(preset: WeaponLimbPreset) -> bool:
	if preset == null:
		return false
	return _dirty_keys.has(_preset_cache_key(preset.weapon_type, preset.body_card_id))


## Keep in-memory preset edits visible to ProceduralArmController before Save.
func stage_preset(preset: WeaponLimbPreset) -> void:
	if preset == null:
		return
	var key := _preset_cache_key(preset.weapon_type, preset.body_card_id)
	_cache[key] = preset


func _preset_cache_key(weapon_type: ResourceData.ResourceType, body_card_id: String) -> String:
	return "%d:%s" % [int(weapon_type), body_card_id]


func apply_to_arm_config(config: ProceduralArmConfig, preset: WeaponLimbPreset) -> void:
	if config == null or preset == null:
		return
	config.weapon_shoulder_offset_px = preset.shoulder_offset_px
	if (
		preset.weapon_type == ResourceData.ResourceType.WOOD
		and preset.uses_saved_club_grip_on_art()
	):
		config.hand_grip_offset_px = preset.idle_club1_hand_grip_offset_px
	else:
		config.hand_grip_offset_px = preset.hand_grip_offset_px
	config.hand_grip_ready_offset_px = preset.hand_grip_ready_offset_px
	config.support_hand_grip_offset_px = preset.support_hand_offset_px
	config.support_hand_idle_offset_px = preset.support_hand_idle_offset_px
	config.upper_arm_length = preset.upper_arm_length
	config.lower_arm_length = preset.lower_arm_length
	config.weapon_upper_arm_length = preset.weapon_upper_arm_length
	config.weapon_lower_arm_length = preset.weapon_lower_arm_length
	config.support_upper_arm_length = preset.support_upper_arm_length
	config.support_lower_arm_length = preset.support_lower_arm_length
	config.arm_width = preset.arm_width
	config.hand_width = preset.hand_width
	config.elbow_hint_outward = preset.elbow_hint_outward
	config.weapon_elbow_pole_idle_px = preset.weapon_elbow_pole_idle_px
	config.weapon_elbow_pole_ready_px = preset.weapon_elbow_pole_ready_px
	config.support_elbow_pole_idle_px = preset.support_elbow_pole_idle_px
	config.support_elbow_pole_ready_px = preset.support_elbow_pole_ready_px
	config.shoulder_offset_left = preset.support_shoulder_offset_px
	config.shoulder_offset_right = Vector2(-preset.support_shoulder_offset_px.x, preset.support_shoulder_offset_px.y)


func apply_combat_profile_overrides(profile: Dictionary, weapon_type: ResourceData.ResourceType) -> Dictionary:
	var preset := get_preset(weapon_type)
	if preset == null:
		return profile
	var out: Dictionary = profile.duplicate(true)
	out["ready_offset_px"] = preset.ready_offset_px
	out["strike_offset_px"] = preset.strike_offset_px
	out["ready_forward_px"] = preset.ready_forward_px
	out["idle_rotation_deg"] = preset.idle_rotation_deg
	if preset.attack_rotation_deg > WeaponLimbPreset.ROTATION_UNSET + 1.0:
		out["attack_rotation_deg"] = preset.attack_rotation_deg
	if preset.has_club_keyframed_strike():
		out["club_strike_use_keyframes"] = true
		var windup_kf: Dictionary = preset.club_strike_windup_keyframe()
		var peak_kf: Dictionary = preset.club_strike_peak_keyframe()
		out["club_strike_windup_overlay_px"] = windup_kf["overlay_px"]
		out["club_strike_peak_overlay_px"] = peak_kf["overlay_px"]
		out["club_strike_windup_hand_px"] = windup_kf["hand_grip_px"]
		out["club_strike_peak_hand_px"] = peak_kf["hand_grip_px"]
		out["club_strike_windup_support_px"] = windup_kf["support_hand_px"]
		out["club_strike_peak_support_px"] = peak_kf["support_hand_px"]
		out["club_strike_windup_rotation_deg"] = preset.resolve_club_windup_rotation_deg(
			&"b", out
		)
		out["club_strike_support_motion_frac"] = preset.club_strike_support_motion_frac
	if preset.has_spear_keyframed_strike():
		out["spear_strike_use_keyframes"] = true
		var spear_windup: Dictionary = preset.spear_strike_windup_keyframe()
		var spear_peak: Dictionary = preset.spear_strike_peak_keyframe()
		out["spear_strike_windup_overlay_px"] = spear_windup["overlay_px"]
		out["spear_strike_peak_overlay_px"] = spear_peak["overlay_px"]
		out["spear_strike_windup_hand_px"] = spear_windup["hand_grip_px"]
		out["spear_strike_peak_hand_px"] = spear_peak["hand_grip_px"]
		out["spear_strike_windup_support_px"] = spear_windup["support_hand_px"]
		out["spear_strike_peak_support_px"] = spear_peak["support_hand_px"]
	return out


func get_overlay_offset_idle_px(weapon_type: ResourceData.ResourceType) -> Vector2:
	var preset := get_preset(weapon_type)
	if preset:
		return preset.overlay_offset_idle_px
	return Vector2.ZERO


func _weapon_slug(weapon_type: ResourceData.ResourceType) -> String:
	match weapon_type:
		ResourceData.ResourceType.NONE:
			return "none"
		ResourceData.ResourceType.SPEAR:
			return "spear"
		ResourceData.ResourceType.WOOD:
			return "club"
		ResourceData.ResourceType.AXE:
			return "axe"
		ResourceData.ResourceType.PICK:
			return "pick"
		ResourceData.ResourceType.OLDOWAN:
			return "oldowan"
		_:
			return "weapon_%d" % int(weapon_type)
