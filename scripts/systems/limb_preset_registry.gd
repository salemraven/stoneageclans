extends Node

## Loads/saves WeaponLimbPreset .tres files; single source of truth for procedural limbs in game + tuner.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const PRESETS_DIR := "res://assets/limb_presets/"

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
	return get_preset(weapon_type, body_card_id)


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
	config.hand_grip_offset_px = preset.hand_grip_offset_px
	config.hand_grip_ready_offset_px = preset.hand_grip_ready_offset_px
	config.support_hand_grip_offset_px = preset.support_hand_offset_px
	config.support_hand_idle_offset_px = preset.support_hand_idle_offset_px
	config.upper_arm_length = preset.upper_arm_length
	config.lower_arm_length = preset.lower_arm_length
	config.elbow_hint_outward = preset.elbow_hint_outward
	config.shoulder_offset_left = preset.support_shoulder_offset_px
	config.shoulder_offset_right = Vector2(-preset.support_shoulder_offset_px.x, preset.support_shoulder_offset_px.y)


func apply_combat_profile_overrides(profile: Dictionary, weapon_type: ResourceData.ResourceType) -> Dictionary:
	var preset := get_preset(weapon_type)
	if preset == null:
		return profile
	var out: Dictionary = profile.duplicate(true)
	out["ready_offset_px"] = preset.ready_offset_px
	out["ready_forward_px"] = preset.ready_forward_px
	out["idle_rotation_deg"] = preset.idle_rotation_deg
	return out


func get_overlay_offset_idle_px(weapon_type: ResourceData.ResourceType) -> Vector2:
	var preset := get_preset(weapon_type)
	if preset:
		return preset.overlay_offset_idle_px
	return Vector2.ZERO


func _weapon_slug(weapon_type: ResourceData.ResourceType) -> String:
	match weapon_type:
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
