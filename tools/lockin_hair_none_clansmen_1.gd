extends SceneTree

## Lock-in: hair1 attach on clansmen_1 layered mannequin (HeadPivot local px).
## Run: godot --headless -s res://tools/lockin_hair_none_clansmen_1.gd

const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const CharacterCardPartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

const TOLERANCE_PX := 0.05

const NECK_SOCKET_PX := Vector2(181.2, 77.12)
const HEAD_PIVOT_PX := Vector2(153.0, 345.0)
const HAIR_TEXTURE_PATH := CharacterCardPartsRegistry.HAIR1_PATH
const HAIR_PIVOT_PX := Vector2(249.5, 655.0)
const HAIR_ATTACH_LOCAL_PX := Vector2(-36.607056, -487.67432)

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	print("=== Hair attach lock-in (none / clansmen_1 / hair1) ===")
	_apply_layout()
	_validate()

	var layout := CharacterCardPartsRegistry.get_layout()
	var layout_err := CharacterCardPartsRegistry.save_layout(layout)
	if layout_err != OK:
		_fail("layout save failed: %s" % error_string(layout_err))

	CharacterCardPartsRegistry.reload_layout()
	_validate()

	_report()
	quit(0 if _failures.is_empty() else 1)


func _apply_layout() -> void:
	var layout := CharacterCardPartsRegistry.get_layout()
	if layout == null:
		_fail("layer layout missing")
		return
	layout.body_texture_path = CharacterCardPartsRegistry.BLANK_BODY_PATH
	layout.head_texture_path = CharacterCardPartsRegistry.BLANK_HEAD_PATH
	layout.body_neck_socket_px = NECK_SOCKET_PX
	layout.head_pivot_px = HEAD_PIVOT_PX
	layout.body_offset_px = Vector2.ZERO
	layout.hair_texture_path = HAIR_TEXTURE_PATH
	layout.hair_pivot_px = HAIR_PIVOT_PX
	layout.hair_attach_local_px = HAIR_ATTACH_LOCAL_PX


func _validate() -> void:
	var layout := CharacterCardPartsRegistry.get_layout()
	if layout == null:
		_fail("layout missing on validate")
		return
	print("\n-- Hair layer layout --")
	_expect_vec("neck socket", layout.body_neck_socket_px, NECK_SOCKET_PX)
	_expect_vec("head pivot", layout.head_pivot_px, HEAD_PIVOT_PX)
	_expect_vec("hair attach (HeadPivot local)", layout.hair_attach_local_px, HAIR_ATTACH_LOCAL_PX)
	if layout.hair_texture_path != HAIR_TEXTURE_PATH:
		_fail("hair_texture_path expected %s got %s" % [HAIR_TEXTURE_PATH, layout.hair_texture_path])
	var hair_tex := CharacterCardPartsRegistry.load_hair_texture(layout)
	if hair_tex == null:
		_fail("hair1.png missing or failed to load")
	else:
		print("  hair sheet = %dx%d" % [hair_tex.get_width(), hair_tex.get_height()])


func _expect_vec(label: String, got: Vector2, want: Vector2) -> void:
	print("  %s = (%.2f, %.2f)" % [label, got.x, got.y])
	if got.distance_to(want) > TOLERANCE_PX:
		_fail("%s expected (%.2f, %.2f) got (%.2f, %.2f)" % [label, want.x, want.y, got.x, got.y])


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Lock-in summary ===")
	if _failures.is_empty():
		print("lockin_hair_none_clansmen_1: PASS")
	else:
		print("lockin_hair_none_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
