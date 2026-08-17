extends RefCounted
class_name CharacterAnimationCatalog

## Holdable × animation clip catalog — unified clips with legacy mode shims for cutover.

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")

const AnimMode = WeaponLimbPresetScript.TunerAnimMode
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)

const CLIP_IDLE := CharacterAnimationPresetStoreScript.CLIP_IDLE
const CLIP_WALK := CharacterAnimationPresetStoreScript.CLIP_WALK
const CLIP_GATHER := CharacterAnimationPresetStoreScript.CLIP_GATHER
const CLIP_WINDUP := CharacterAnimationPresetStoreScript.CLIP_WINDUP
const CLIP_STRIKE := CharacterAnimationPresetStoreScript.CLIP_STRIKE

const CATEGORY_IDLE := &"idle"
const CATEGORY_WALK := &"walk"
const CATEGORY_GATHER := &"gather"
const CATEGORY_ATTACK := &"attack"

const CATEGORY_ORDER: Array[StringName] = [
	CATEGORY_IDLE,
	CATEGORY_WALK,
	CATEGORY_GATHER,
	CATEGORY_ATTACK,
]

const CATEGORY_LABELS: Dictionary = {
	CATEGORY_IDLE: "Idle",
	CATEGORY_WALK: "Walk",
	CATEGORY_GATHER: "Gather",
	CATEGORY_ATTACK: "Attack",
}

const CLIP_LABELS: Dictionary = {
	CLIP_IDLE: "Idle",
	CLIP_WALK: "Walk",
	CLIP_GATHER: "Gather",
	CLIP_WINDUP: "Windup",
	CLIP_STRIKE: "Strike",
}

const MODE_LABELS: Dictionary = {
	AnimMode.IDLE: "Idle",
	AnimMode.WALK1: "Walk",
	AnimMode.GATHER1: "Gather",
	AnimMode.ATTACK: "Windup",
}

const HOLDABLES: Array[Dictionary] = [
	{
		"label": "Empty hands",
		"short": "None",
		"type": ResourceData.ResourceType.NONE,
		"clips": [CLIP_IDLE, CLIP_WALK, CLIP_GATHER],
	},
	{
		"label": "Club",
		"short": "Club",
		"type": ResourceData.ResourceType.WOOD,
		"clips": [CLIP_IDLE, CLIP_WALK, CLIP_WINDUP, CLIP_STRIKE],
	},
	{
		"label": "Spear",
		"short": "Spear",
		"type": ResourceData.ResourceType.SPEAR,
		"clips": [CLIP_IDLE, CLIP_WALK, CLIP_WINDUP, CLIP_STRIKE],
	},
	{
		"label": "Axe",
		"short": "Axe",
		"type": ResourceData.ResourceType.AXE,
		"clips": [CLIP_IDLE, CLIP_WALK, CLIP_GATHER],
	},
	{
		"label": "Pick",
		"short": "Pick",
		"type": ResourceData.ResourceType.PICK,
		"clips": [CLIP_IDLE, CLIP_WALK, CLIP_GATHER],
	},
	{
		"label": "Oldowan",
		"short": "Oldowan",
		"type": ResourceData.ResourceType.OLDOWAN,
		"clips": [CLIP_IDLE, CLIP_WALK, CLIP_GATHER],
	},
]


static func holdable_entry(weapon_type: ResourceData.ResourceType) -> Dictionary:
	for entry in HOLDABLES:
		if entry.get("type") == weapon_type:
			return entry
	return HOLDABLES[0]


static func clips_for_holdable(weapon_type: ResourceData.ResourceType) -> Array[StringName]:
	var entry := holdable_entry(weapon_type)
	var clips: Array = entry.get("clips", [])
	var out: Array[StringName] = []
	for c in clips:
		out.append(c as StringName)
	return out


static func clip_label(clip_id: StringName) -> String:
	return CLIP_LABELS.get(clip_id, String(clip_id)) as String


static func holdable_short_label(weapon_type: ResourceData.ResourceType) -> String:
	return holdable_entry(weapon_type).get("short", "?") as String


static func clip_supported(weapon_type: ResourceData.ResourceType, clip_id: StringName) -> bool:
	return clip_id in clips_for_holdable(weapon_type)


static func default_clip(weapon_type: ResourceData.ResourceType) -> StringName:
	var clips := clips_for_holdable(weapon_type)
	if clips.is_empty():
		return CLIP_IDLE
	return clips[0]


static func clip_id_for_mode(mode: AnimMode, weapon_type: ResourceData.ResourceType) -> StringName:
	match mode:
		AnimMode.IDLE, AnimMode.IDLE1, AnimMode.IDLE_CLUB1:
			return CLIP_IDLE
		AnimMode.WALK, AnimMode.WALK1:
			return CLIP_WALK
		AnimMode.GATHER1:
			return CLIP_GATHER
		AnimMode.ATTACK:
			if weapon_type == ResourceData.ResourceType.WOOD or weapon_type == ResourceData.ResourceType.SPEAR:
				return CLIP_WINDUP
			return CLIP_IDLE
		_:
			return CLIP_IDLE


static func mode_for_clip_id(clip_id: StringName) -> AnimMode:
	match clip_id:
		CLIP_WALK:
			return AnimMode.WALK1
		CLIP_GATHER:
			return AnimMode.GATHER1
		CLIP_WINDUP, CLIP_STRIKE:
			return AnimMode.ATTACK
		_:
			return AnimMode.IDLE


static func holdable_categories(weapon_type: ResourceData.ResourceType) -> Dictionary:
	var cats: Dictionary = {}
	var clips := clips_for_holdable(weapon_type)
	if CLIP_IDLE in clips:
		cats[CATEGORY_IDLE] = [AnimMode.IDLE]
	if CLIP_WALK in clips:
		cats[CATEGORY_WALK] = [AnimMode.WALK1]
	if CLIP_GATHER in clips:
		cats[CATEGORY_GATHER] = [AnimMode.GATHER1]
	if CLIP_WINDUP in clips or CLIP_STRIKE in clips:
		var attack_modes: Array = []
		if CLIP_WINDUP in clips:
			attack_modes.append(AnimMode.ATTACK)
		cats[CATEGORY_ATTACK] = attack_modes
	return cats


static func category_has_modes(weapon_type: ResourceData.ResourceType, category: StringName) -> bool:
	return holdable_categories(weapon_type).has(category)


static func modes_for_category(weapon_type: ResourceData.ResourceType, category: StringName) -> Array:
	var cats := holdable_categories(weapon_type)
	if not cats.has(category):
		return []
	return (cats[category] as Array).duplicate()


static func default_mode_for_category(
	weapon_type: ResourceData.ResourceType,
	category: StringName
) -> AnimMode:
	var modes := modes_for_category(weapon_type, category)
	if modes.is_empty():
		return AnimMode.IDLE
	return modes[0] as AnimMode


static func default_holdable_mode(weapon_type: ResourceData.ResourceType) -> AnimMode:
	return AnimMode.IDLE


static func category_for_mode(weapon_type: ResourceData.ResourceType, mode: AnimMode) -> StringName:
	var clip_id := clip_id_for_mode(mode, weapon_type)
	match clip_id:
		CLIP_WALK:
			return CATEGORY_WALK
		CLIP_GATHER:
			return CATEGORY_GATHER
		CLIP_WINDUP, CLIP_STRIKE:
			return CATEGORY_ATTACK
		_:
			return CATEGORY_IDLE


static func mode_label(mode: AnimMode, weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE) -> String:
	if mode == AnimMode.ATTACK:
		if weapon_type == ResourceData.ResourceType.WOOD or weapon_type == ResourceData.ResourceType.SPEAR:
			return "Windup"
		return "Attack"
	return MODE_LABELS.get(mode, str(mode)) as String


static func mode_supported(weapon_type: ResourceData.ResourceType, mode: AnimMode) -> bool:
	var clip_id := clip_id_for_mode(mode, weapon_type)
	return clip_supported(weapon_type, clip_id)


static func all_clips() -> Array[Dictionary]:
	var clips: Array[Dictionary] = []
	for entry in HOLDABLES:
		var weapon_type: ResourceData.ResourceType = entry["type"] as ResourceData.ResourceType
		var short: String = entry.get("short", "?") as String
		for clip_id in entry.get("clips", []) as Array:
			var mode := mode_for_clip_id(clip_id as StringName)
			clips.append({
				"weapon": weapon_type,
				"clip_id": clip_id,
				"mode": mode,
				"label": "%s · %s" % [short, clip_label(clip_id as StringName)],
			})
	return clips


static func clip_can_loop(_weapon_type: ResourceData.ResourceType, _mode: AnimMode) -> bool:
	return true
