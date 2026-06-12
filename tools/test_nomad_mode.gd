extends SceneTree
# Headless Nomad Mode tests
# SKIP_SINGLE_INSTANCE=1 godot --headless --path <repo> --script res://tools/test_nomad_mode.gd

const CampfireScript = preload("res://scripts/campfire.gd")
const CAMPFIRE_SCENE = preload("res://scenes/Campfire.tscn")


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_NOMAD_MODE_FAIL: %s" % msg)
	quit(1)


func _pass(label: String) -> void:
	print("  ok: %s" % label)


func _run() -> void:
	await process_frame
	_test_food_count_helper()
	_test_stone_despawn_removed()
	_test_nomad_state_enum()
	_test_building_orphan_grace()
	print("All Nomad Mode tests passed")
	quit(0)


func _test_food_count_helper() -> void:
	var cf: CampfireScript = CAMPFIRE_SCENE.instantiate() as CampfireScript
	if cf == null:
		_fail("campfire instantiate")
		return
	cf.inventory = InventoryData.new(10, true, 999)
	cf.inventory.add_item(ResourceData.ResourceType.BERRIES, 2)
	cf.inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	if cf.get_total_food_count() != 2:
		_fail("food count expected 2 got %d" % cf.get_total_food_count())
		return
	if not cf.has_panic_wood():
		_fail("expected wood > 0")
		return
	cf.inventory.remove_item(ResourceData.ResourceType.WOOD, 1)
	if cf.has_panic_wood():
		_fail("expected wood depleted")
		return
	cf.queue_free()
	_pass("food count helper")


func _test_stone_despawn_removed() -> void:
	var src := load("res://scripts/campfire.gd") as GDScript
	if src == null:
		_fail("load campfire script")
		return
	var text: String = src.source_code
	if text.contains("stone_count <= 0") or text.contains("total_items <= 0"):
		_fail("stone/empty inventory despawn still present")
		return
	_pass("stone despawn removed")


func _test_nomad_state_enum() -> void:
	if CampfireScript.NomadState.NONE != 0:
		_fail("NomadState.NONE")
		return
	if CampfireScript.NomadState.WALKING != 2:
		_fail("NomadState.WALKING")
		return
	_pass("NomadState enum")


func _test_building_orphan_grace() -> void:
	var bb := BuildingBase.new()
	bb.building_type = ResourceData.ResourceType.LIVING_HUT
	bb.set_orphaned(true)
	if not bb.is_orphaned:
		_fail("set_orphaned true")
		return
	if bb.orphaned_at_game_time < 0.0:
		_fail("orphaned_at_game_time not set")
		return
	bb.set_orphaned(false)
	if bb.is_orphaned:
		_fail("set_orphaned false")
		return
	bb.queue_free()
	_pass("building orphan grace fields")
