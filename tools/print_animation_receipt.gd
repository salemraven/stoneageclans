extends SceneTree

## Headless: print AnimationReceipt for a saved preset row.
## Usage: godot --headless -s res://tools/print_animation_receipt.gd
## Optional args after --: <mode_slug> <holdable_slug>  (default walk1 none)

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const AnimationReceiptScript = preload("res://scripts/tools/animation_receipt.gd")
const AnimCatalog = preload("res://scripts/config/character_animation_catalog.gd")

const HOLDABLE_SLUGS: Dictionary = {
	"none": ResourceData.ResourceType.NONE,
	"spear": ResourceData.ResourceType.SPEAR,
	"club": ResourceData.ResourceType.WOOD,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var mode_slug := "walk1"
	var holdable_slug := "none"
	var extra := OS.get_cmdline_args()
	var dash := extra.find("--")
	if dash >= 0 and dash + 1 < extra.size():
		mode_slug = extra[dash + 1]
	if dash >= 0 and dash + 2 < extra.size():
		holdable_slug = extra[dash + 2]
	var mode: WeaponLimbPreset.TunerAnimMode = _mode_from_slug(mode_slug)
	var weapon_type: ResourceData.ResourceType = HOLDABLE_SLUGS.get(
		holdable_slug, ResourceData.ResourceType.NONE
	)
	var registry := LimbPresetRegistryScript.new()
	var preset: WeaponLimbPreset = registry.reload_preset(weapon_type, "clansmen_1")
	if preset == null:
		push_error("Preset missing for %s clansmen_1" % holdable_slug)
		quit(1)
		return
	var label: String = AnimCatalog.MODE_LABELS.get(mode, mode_slug)
	var receipt := AnimationReceiptScript.build(preset, mode, holdable_slug, label, null)
	print(AnimationReceiptScript.format_clipboard(receipt))
	quit(0)


func _mode_from_slug(slug: String) -> WeaponLimbPreset.TunerAnimMode:
	match slug:
		"idle":
			return WeaponLimbPreset.TunerAnimMode.IDLE
		"idle1":
			return WeaponLimbPreset.TunerAnimMode.IDLE1
		"walk":
			return WeaponLimbPreset.TunerAnimMode.WALK
		"walk1":
			return WeaponLimbPreset.TunerAnimMode.WALK1
		"gather1":
			return WeaponLimbPreset.TunerAnimMode.GATHER1
		"attack":
			return WeaponLimbPreset.TunerAnimMode.ATTACK
		"idle_club1":
			return WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1
		_:
			return WeaponLimbPreset.TunerAnimMode.WALK1
