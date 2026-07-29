extends RefCounted
class_name CharacterAnimationCatalog

## Holdable × category × variant catalog for Character Tuner animation picker.
## Single source of truth — LimbTunerApp reads this instead of a flat pose dropdown.

const AnimMode = WeaponLimbPreset.TunerAnimMode

const CATEGORY_IDLE := &"idle"
const CATEGORY_WALK := &"walk"
const CATEGORY_ATTACK := &"attack"
const CATEGORY_GATHER := &"gather"
const CATEGORY_TAUNT := &"taunt"
const CATEGORY_RANGED := &"ranged"

const CATEGORY_ORDER: Array[StringName] = [
	CATEGORY_IDLE,
	CATEGORY_WALK,
	CATEGORY_ATTACK,
	CATEGORY_GATHER,
	CATEGORY_TAUNT,
	CATEGORY_RANGED,
]

const CATEGORY_LABELS: Dictionary = {
	CATEGORY_IDLE: "Idle",
	CATEGORY_WALK: "Walk",
	CATEGORY_ATTACK: "Attack",
	CATEGORY_GATHER: "Gather",
	CATEGORY_TAUNT: "Taunt",
	CATEGORY_RANGED: "Ranged",
}

const MODE_LABELS: Dictionary = {
	AnimMode.IDLE: "Idle",
	AnimMode.IDLE1: "Idle 1",
	AnimMode.WALK: "Walk",
	AnimMode.WALK1: "Walk 1",
	AnimMode.GATHER1: "Gather",
	AnimMode.ATTACK: "Windup",
	AnimMode.IDLE_CLUB1: "Club grip",
}

const HOLDABLES: Array[Dictionary] = [
	{
		"label": "Empty hands",
		"short": "None",
		"type": ResourceData.ResourceType.NONE,
		"categories": {
			CATEGORY_IDLE: [AnimMode.IDLE, AnimMode.IDLE1],
			CATEGORY_WALK: [AnimMode.WALK, AnimMode.WALK1],
			CATEGORY_GATHER: [AnimMode.GATHER1],
		},
	},
	{
		"label": "Club",
		"short": "Club",
		"type": ResourceData.ResourceType.WOOD,
		"categories": {
			CATEGORY_IDLE: [AnimMode.IDLE, AnimMode.IDLE_CLUB1],
			CATEGORY_ATTACK: [AnimMode.ATTACK],
		},
	},
	{
		"label": "Spear",
		"short": "Spear",
		"type": ResourceData.ResourceType.SPEAR,
		"categories": {
			CATEGORY_IDLE: [AnimMode.IDLE],
			CATEGORY_WALK: [AnimMode.WALK, AnimMode.WALK1],
			CATEGORY_ATTACK: [AnimMode.ATTACK],
		},
	},
	{
		"label": "Axe",
		"short": "Axe",
		"type": ResourceData.ResourceType.AXE,
		"categories": {
			CATEGORY_IDLE: [AnimMode.IDLE, AnimMode.IDLE1],
			CATEGORY_WALK: [AnimMode.WALK, AnimMode.WALK1],
			CATEGORY_GATHER: [AnimMode.GATHER1],
			CATEGORY_ATTACK: [AnimMode.ATTACK],
		},
	},
	{
		"label": "Pick",
		"short": "Pick",
		"type": ResourceData.ResourceType.PICK,
		"categories": {
			CATEGORY_IDLE: [AnimMode.IDLE, AnimMode.IDLE1],
			CATEGORY_WALK: [AnimMode.WALK, AnimMode.WALK1],
			CATEGORY_GATHER: [AnimMode.GATHER1],
			CATEGORY_ATTACK: [AnimMode.ATTACK],
		},
	},
	{
		"label": "Oldowan",
		"short": "Oldowan",
		"type": ResourceData.ResourceType.OLDOWAN,
		"categories": {
			CATEGORY_IDLE: [AnimMode.IDLE, AnimMode.IDLE1],
			CATEGORY_WALK: [AnimMode.WALK, AnimMode.WALK1],
			CATEGORY_GATHER: [AnimMode.GATHER1],
			CATEGORY_ATTACK: [AnimMode.ATTACK],
		},
	},
]


static func holdable_entry(weapon_type: ResourceData.ResourceType) -> Dictionary:
	for entry in HOLDABLES:
		if entry.get("type") == weapon_type:
			return entry
	return HOLDABLES[0]


static func holdable_categories(weapon_type: ResourceData.ResourceType) -> Dictionary:
	return holdable_entry(weapon_type).get("categories", {}) as Dictionary


static func category_has_modes(
	weapon_type: ResourceData.ResourceType,
	category: StringName
) -> bool:
	var cats := holdable_categories(weapon_type)
	return cats.has(category) and (cats[category] as Array).size() > 0


static func modes_for_category(
	weapon_type: ResourceData.ResourceType,
	category: StringName
) -> Array:
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
	return default_mode_for_category(weapon_type, CATEGORY_IDLE)


static func category_for_mode(
	weapon_type: ResourceData.ResourceType,
	mode: AnimMode
) -> StringName:
	var cats := holdable_categories(weapon_type)
	for category in CATEGORY_ORDER:
		if not cats.has(category):
			continue
		for m in cats[category] as Array:
			if m == mode:
				return category
	return CATEGORY_IDLE


static func mode_label(mode: AnimMode, weapon_type: ResourceData.ResourceType = ResourceData.ResourceType.NONE) -> String:
	if mode == AnimMode.ATTACK:
		if weapon_type == ResourceData.ResourceType.WOOD or weapon_type == ResourceData.ResourceType.SPEAR:
			return "Windup"
		return "Attack"
	return MODE_LABELS.get(mode, str(mode)) as String


static func holdable_short_label(weapon_type: ResourceData.ResourceType) -> String:
	return holdable_entry(weapon_type).get("short", "?") as String


static func mode_supported(weapon_type: ResourceData.ResourceType, mode: AnimMode) -> bool:
	var cats := holdable_categories(weapon_type)
	for category in cats:
		for m in cats[category] as Array:
			if m == mode:
				return true
	return false
