extends SceneTree
## Lightweight headless unit test for InventoryActionBridge (no Main boot).

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var bridge: Node = root.get_node_or_null("/root/InventoryActionBridge")
	if bridge == null or not bridge.has_method("propose_inventory_mutate"):
		push_error("InventoryActionBridge autoload missing or not compiled")
		quit(1)
		return
	var inv := InventoryData.new(5, false, 1)
	inv.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1, "quality": 0})
	var MainStub := load("res://tools/inventory_test_main_stub.gd")
	var fake_main: Node = MainStub.new()
	root.add_child(fake_main)
	await process_frame
	var StubScript := load("res://tools/inventory_ui_test_stub.gd")
	var stub_ui: Node = StubScript.new()
	stub_ui.inventory_data = inv
	stub_ui.set_meta("hotbar_data", InventoryData.new(10, false, 1))
	fake_main.player_inventory_ui = stub_ui
	bridge.inventory_mutate_rejected.connect(func(_op: Dictionary, reason: String) -> void:
		print("inventory_mutate_rejected: ", reason)
	)
	var bad_op: Dictionary = {
		"type": "move",
		"from_inventory": "player",
		"from_slot": 0,
		"from_entity_id": -1,
		"to_inventory": "player",
		"to_slot": 99,
		"to_entity_id": -1,
		"item_type": int(ResourceData.ResourceType.WOOD),
		"count": 1,
		"mode": "move",
		"to_can_stack": false,
		"to_max_stack": 1,
	}
	if bridge.propose_inventory_mutate(bad_op):
		push_error("Expected invalid slot op to be rejected")
		quit(1)
		return
	var good_op: Dictionary = bad_op.duplicate(true)
	good_op["to_slot"] = 1
	if not bridge.propose_inventory_mutate(good_op):
		push_error("Expected valid move op to pass")
		quit(1)
		return
	var dest: Dictionary = inv.get_slot(1)
	if dest.is_empty() or int(dest.get("type", -1)) != int(ResourceData.ResourceType.WOOD):
		push_error("Move op did not apply to destination slot")
		quit(1)
		return
	print("test_inventory_validation: PASS")
	quit(0)
