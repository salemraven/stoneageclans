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
	_cache[key] = preset
	return preset


func reload_all_presets(body_card_id: String = "clansmen_1") -> void:
	for weapon_type in TUNER_HOLDABLES:
		reload_preset(weapon_type, body_card_id)


## Write every in-memory preset the tuner touched this session (weapon switches stage edits).
func save_all_staged() -> Dictionary:
	var out := {"err": OK, "count": 0, "failed_keys": [] as Array[String]}
	if _cache.is_empty():
		return out
	for key in _cache.keys():
		var preset := _cache[key] as WeaponLimbPreset
		if preset == null:
			continue
		var err := save_preset(preset)
		out.count = int(out.count) + 1
		if err != OK:
			out.err = err
			(out.failed_keys as Array).append(String(key))
	return out


## Keep in-memory preset edits visible to ProceduralArmController before Save.
func stage_preset(preset: WeaponLimbPreset) -> void:
	if preset == null:
		return
	var key := "%d:%s" % [int(preset.weapon_type), preset.body_card_id]
	_cache[key] = preset


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
	if absf(preset.ready_rotation_offset_deg) > 0.001:
		out["ready_rotation_offset_deg"] = preset.ready_rotation_offset_deg
	if absf(preset.swing_windup_deg) > 0.001:
		out["swing_windup_deg"] = preset.swing_windup_deg
	return out


func get_overlay_offset_idle_px(weapon_type: ResourceData.ResourceType) -> Vector2:
	var preset := get_preset(weapon_type)
	if preset == null:
		return Vector2.ZERO
	if weapon_type == ResourceData.ResourceType.WOOD:
		if preset.idle_club1_grip_authoritative or preset.idle_club1_overlay_is_plausible():
			return preset.idle_club1_overlay_offset_px
	return preset.overlay_offset_idle_px


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
