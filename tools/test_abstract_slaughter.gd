extends SceneTree
## Headless: AbstractSlaughter last-resort + skip paths.
## Run: godot --path . --headless -s res://tools/test_abstract_slaughter.gd

const AbstractSlaughterScript = preload("res://scripts/systems/abstract_slaughter.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== ABSTRACT_SLAUGHTER_TEST start ===")
	var err := change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		_fail("load Main.tscn", "err=%s" % err)
		_summary()
		quit(1)
		return
	for _i in 8:
		await process_frame
	_test_skip_when_not_starving()
	_test_skip_when_pantry_has_food()
	_test_slaughter_owned_sheep()
	_summary()
	quit(0 if _failed == 0 else 1)


func _test_skip_when_not_starving() -> void:
	var claim := _make_claim("SLAU_A")
	var inv: InventoryData = claim.inventory
	var hunt: Dictionary = {"hunted": false}
	var ev: Dictionary = AbstractSlaughterScript.slaughter_for_claim(claim, false, hunt, inv)
	if str(ev.get("skip_reason")) == "not_starving":
		_pass("skip when not starving")
	else:
		_fail("skip when not starving", str(ev))
	claim.queue_free()


func _test_skip_when_pantry_has_food() -> void:
	var claim := _make_claim("SLAU_B")
	var inv: InventoryData = claim.inventory
	inv.add_item(ResourceData.ResourceType.BERRIES, 3)
	var hunt: Dictionary = {"hunted": false}
	var ev: Dictionary = AbstractSlaughterScript.slaughter_for_claim(claim, true, hunt, inv)
	if str(ev.get("skip_reason")) == "pantry_has_food":
		_pass("skip when pantry has food")
	else:
		_fail("skip when pantry has food", str(ev))
	claim.queue_free()


func _test_slaughter_owned_sheep() -> void:
	var claim := _make_claim("SLAU_C")
	var inv: InventoryData = claim.inventory
	var sheep := Node2D.new()
	sheep.set_script(load("res://tools/test_abstract_slaughter_livestock_stub.gd"))
	sheep.set("clan_name", "SLAU_C")
	sheep.add_to_group("npcs")
	sheep.global_position = claim.global_position + Vector2(20, 0)
	current_scene.add_child(sheep)
	var hunt: Dictionary = {"hunted": false}
	var ev: Dictionary = AbstractSlaughterScript.slaughter_for_claim(claim, true, hunt, inv)
	var meat: int = inv.get_count(ResourceData.ResourceType.MEAT)
	if bool(ev.get("slaughtered")) and meat >= 2:
		_pass("slaughter owned sheep adds meat", "meat=%d" % meat)
	else:
		_fail("slaughter owned sheep adds meat", "ev=%s meat=%d" % [ev, meat])
	claim.queue_free()


func _make_claim(clan: String) -> LandClaim:
	var claim := LandClaim.new()
	claim.clan_name = clan
	claim.global_position = Vector2(9000, 9000)
	claim.inventory = InventoryData.new()
	claim.inventory.slot_count = 20
	claim.inventory.max_stack = 999
	claim.radius = 400.0
	current_scene.add_child(claim)
	return claim


func _pass(label: String, detail: String = "") -> void:
	_passed += 1
	print("  PASS: %s %s" % [label, detail])


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	print("  FAIL: %s %s" % [label, detail])


func _summary() -> void:
	print("=== ABSTRACT_SLAUGHTER_TEST: %d pass, %d fail ===" % [_passed, _failed])
