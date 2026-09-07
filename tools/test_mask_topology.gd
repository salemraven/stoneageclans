extends SceneTree
## Headless: validate island mask topology (see mask_topology.gd).

const MaskTopologyRes := preload("res://scripts/world/mask_topology.gd")
const MASK_PATH := "res://maps/island/biome_mask.png"
const WATER_PATH := "res://maps/island/water_layer.png"


func _initialize() -> void:
	var mask := _load_l8(MASK_PATH)
	var water := _load_l8(WATER_PATH)
	if mask == null:
		push_error("test_mask_topology: missing biome mask")
		quit(1)
		return
	if water == null:
		water = Image.create(mask.get_width(), mask.get_height(), false, Image.FORMAT_L8)
		water.fill(Color.BLACK)

	var report: Dictionary = MaskTopologyRes.validate(mask, water)
	print(MaskTopologyRes.format_report(report))
	quit(0 if report.get("ok", false) else 1)


func _load_l8(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null or img.is_empty():
		return null
	img.convert(Image.FORMAT_L8)
	return img
