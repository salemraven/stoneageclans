extends SceneTree
## Headless verification for InventoryActionBridge validation + apply.

var _bridge: Node = null
var _main: Node = null
var _player_ui: Node = null
var _player: Node2D = null
var _last_reject_reason: String = ""
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for _i in 12:
		await process_frame
	_bridge = root.get_node_or_null("/root/InventoryActionBridge")
	if _bridge == null or not _bridge.has_method("propose_inventory_mutate"):
		_fail("InventoryActionBridge autoload missing")
		_finish()
		return
	if not _bridge.inventory_mutate_rejected.is_connected(_on_rejected):
		_bridge.inventory_mutate_rejected.connect(_on_rejected)
	if not await _wait_for_inventory_data():
		_fail("InventoryData not ready after boot")
		_finish()
		return
	await _setup_world()
	if not _verify_setup():
		_finish()
		return
	_test_reject_out_of_bounds()
	_test_valid_player_move()
	_test_reject_hotbar_equipment_slot_for_food()
	_test_accept_hotbar_food_slot()
	_test_build_move_op_modes()
	_test_stack_full_on_building()
	_test_reject_building_out_of_range()
	_test_accept_player_owned_building_in_range()
	_test_reject_enemy_building_without_raid()
	_test_accept_raidable_enemy_building()
	_test_craft_consume_and_finish()
	_test_reject_craft_without_materials()
	_finish()


func _on_rejected(_op: Dictionary, reason: String) -> void:
	_last_reject_reason = reason


func _wait_for_inventory_data() -> bool:
	for _i in 60:
		var probe: InventoryData = InventoryData.new(1, false, 1)
		if probe != null and probe.slot_count == 1:
			return true
		await process_frame
	return false


func _verify_setup() -> bool:
	if _player_ui == null or _main == null or _player == null:
		_fail("test world missing main/player/ui nodes")
		return false
	var inv: InventoryData = _player_ui.inventory_data
	var hotbar: InventoryData = _player_ui.get_meta("hotbar_data") as InventoryData
	if inv == null or hotbar == null:
		_fail("player inventory_data or hotbar_data is null after setup")
		return false
	return true


func _setup_world() -> void:
	var MainStub := load("res://tools/inventory_test_main_stub.gd")
	_main = MainStub.new()
	root.add_child(_main)
	_player = Node2D.new()
	_player.name = "TestPlayer"
	_player.global_position = Vector2.ZERO
	_player.set_script(load("res://tools/inventory_player_test_stub.gd"))
	_main.add_child(_player)
	_main.player = _player
	_player_ui = load("res://tools/inventory_ui_test_stub.gd").new()
	var inv := InventoryData.new(5, false, 1)
	var hotbar := InventoryData.new(10, false, 1)
	if inv == null or hotbar == null:
		_fail("InventoryData.new failed during setup")
		return
	_player_ui.inventory_data = inv
	_player_ui.set_meta("hotbar_data", hotbar)
	_main.add_child(_player_ui)
	_main.player_inventory_ui = _player_ui
	await process_frame
	await process_frame
	await process_frame
	_ensure_test_main()


func _register_entity(node: Node) -> int:
	var er: Node = _main.get_node_or_null("/root/EntityRegistry")
	if er == null:
		er = _main.get_node_or_null("/EntityRegistry")
	if er and er.has_method("register"):
		return int(er.register(node))
	return node.get_instance_id()


func _unregister_entity(node: Node) -> void:
	var er: Node = _main.get_node_or_null("/root/EntityRegistry")
	if er == null:
		er = _main.get_node_or_null("/EntityRegistry")
	if er and er.has_method("unregister"):
		er.unregister(node)


func _reset_player_inventory() -> void:
	var inv: InventoryData = _player_ui.inventory_data
	if inv == null:
		_fail("inventory_data missing during reset")
		return
	for i in inv.slot_count:
		inv.set_slot(i, {})
	var hotbar: InventoryData = _player_ui.get_meta("hotbar_data") as InventoryData
	if hotbar == null:
		_fail("hotbar_data missing during reset")
		return
	for i in hotbar.slot_count:
		hotbar.set_slot(i, {})


func _move_op(
	from_kind: String,
	from_slot: int,
	to_kind: String,
	to_slot: int,
	item_type: ResourceData.ResourceType,
	count: int,
	mode: String,
	to_entity_id: int = -1,
	extra: Dictionary = {},
	from_entity_id: int = -1
) -> Dictionary:
	var op: Dictionary = {
		"type": "move",
		"from_inventory": from_kind,
		"from_slot": from_slot,
		"from_entity_id": from_entity_id,
		"to_inventory": to_kind,
		"to_slot": to_slot,
		"to_entity_id": to_entity_id,
		"item_type": int(item_type),
		"count": count,
		"mode": mode,
		"to_can_stack": false,
		"to_max_stack": 1,
	}
	for key in extra:
		op[key] = extra[key]
	return op


func _ensure_test_main() -> void:
	if not is_instance_valid(_main):
		return
	if not _main.is_in_group("main"):
		_main.add_to_group("main")
	for n in _main.get_tree().get_nodes_in_group("main"):
		if n != _main:
			n.remove_from_group("main")
	if _main.get("player") == null and is_instance_valid(_player):
		_main.player = _player
	if _main.get("player_inventory_ui") == null and _player_ui != null:
		_main.player_inventory_ui = _player_ui


func _expect_reject(op: Dictionary, reason_substr: String, label: String) -> void:
	_ensure_test_main()
	_last_reject_reason = ""
	if _bridge.propose_inventory_mutate(op):
		_fail("%s: expected reject, got accept" % label)
		return
	if reason_substr != "" and not _last_reject_reason.contains(reason_substr):
		_fail("%s: expected reason containing '%s', got '%s'" % [label, reason_substr, _last_reject_reason])


func _expect_accept(op: Dictionary, label: String) -> void:
	_ensure_test_main()
	_last_reject_reason = ""
	if not _bridge.propose_inventory_mutate(op):
		_fail("%s: expected accept, got reject (%s)" % [label, _last_reject_reason])


func _make_building() -> Node2D:
	var building: Node2D = Node2D.new()
	building.set_script(load("res://tools/inventory_building_test_stub.gd"))
	building.inventory = InventoryData.new(6, true, 10)
	root.add_child(building)
	_register_entity(building)
	return building


func _test_reject_out_of_bounds() -> void:
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1})
	var op := _move_op("player", 0, "player", 99, ResourceData.ResourceType.WOOD, 1, "move")
	_expect_reject(op, "slot_out_of_bounds", "reject_out_of_bounds")


func _test_valid_player_move() -> void:
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1})
	var op := _move_op("player", 0, "player", 1, ResourceData.ResourceType.WOOD, 1, "move")
	_expect_accept(op, "valid_player_move")
	var dest: Dictionary = _player_ui.inventory_data.get_slot(1)
	if dest.is_empty() or int(dest.get("type", -1)) != int(ResourceData.ResourceType.WOOD):
		_fail("valid_player_move: wood not in destination slot")


func _test_reject_hotbar_equipment_slot_for_food() -> void:
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.BERRIES, "count": 1})
	var op := _move_op("player", 0, "hotbar", 0, ResourceData.ResourceType.BERRIES, 1, "move", -1, {
		"to_can_stack": true,
		"to_max_stack": 5,
	})
	_expect_reject(op, "slot_rejects_item", "reject_food_in_equipment_slot")


func _test_accept_hotbar_food_slot() -> void:
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.BERRIES, "count": 1})
	var op := _move_op("player", 0, "hotbar", 8, ResourceData.ResourceType.BERRIES, 1, "move", -1, {
		"to_can_stack": true,
		"to_max_stack": 5,
	})
	_expect_accept(op, "accept_food_in_food_slot")
	var dest: Dictionary = (_player_ui.get_meta("hotbar_data") as InventoryData).get_slot(8)
	if dest.is_empty():
		_fail("accept_food_in_food_slot: berries missing from slot 9")


func _test_build_move_op_modes() -> void:
	var wood := {"type": ResourceData.ResourceType.WOOD, "count": 2}
	var stone := {"type": ResourceData.ResourceType.STONE, "count": 1}
	if str(_bridge.build_move_op("player", -1, 0, "player", -1, 1, wood, {}, false, 1).get("mode", "")) != "move":
		_fail("build_move_op: empty target should be move")
	if str(_bridge.build_move_op("player", -1, 0, "player", -1, 1, wood, wood, true, 10).get("mode", "")) != "stack_full":
		_fail("build_move_op: same type with room should stack_full")
	if str(_bridge.build_move_op("player", -1, 0, "player", -1, 1, wood, {"type": ResourceData.ResourceType.WOOD, "count": 9}, true, 10).get("mode", "")) != "stack_partial":
		_fail("build_move_op: overflow stack should be partial")
	if str(_bridge.build_move_op("player", -1, 0, "player", -1, 1, wood, stone, false, 1).get("mode", "")) != "swap":
		_fail("build_move_op: different types should swap")


func _test_stack_full_on_building() -> void:
	var building: Node2D = _make_building()
	building.player_owned = true
	building.global_position = Vector2(20, 0)
	building.inventory.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 3})
	var entity_id: int = _bridge.get_entity_id(building)
	var op := _move_op("player", 0, "building", 0, ResourceData.ResourceType.WOOD, 2, "stack_full", entity_id, {
		"to_can_stack": true,
		"to_max_stack": 10,
	})
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 2})
	_expect_accept(op, "stack_full_on_building")
	if building.inventory.get_count(ResourceData.ResourceType.WOOD) != 5:
		_fail("stack_full_on_building: expected 5 wood, got %d" % building.inventory.get_count(ResourceData.ResourceType.WOOD))
	_unregister_entity(building)
	building.queue_free()


func _test_reject_building_out_of_range() -> void:
	var building: Node2D = _make_building()
	building.player_owned = true
	building.global_position = Vector2(500, 0)
	var entity_id: int = _bridge.get_entity_id(building)
	var op := _move_op("player", 0, "building", 0, ResourceData.ResourceType.WOOD, 1, "move", entity_id)
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1})
	_expect_reject(op, "to_access_denied", "reject_building_out_of_range")
	_unregister_entity(building)
	building.queue_free()


func _test_accept_player_owned_building_in_range() -> void:
	var building: Node2D = _make_building()
	building.player_owned = true
	building.global_position = Vector2(30, 0)
	var entity_id: int = _bridge.get_entity_id(building)
	var op := _move_op("player", 0, "building", 1, ResourceData.ResourceType.WOOD, 1, "move", entity_id)
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1})
	_expect_accept(op, "accept_player_owned_building")
	if building.inventory.get_slot(1).is_empty():
		_fail("accept_player_owned_building: item not deposited")
	_unregister_entity(building)
	building.queue_free()


func _test_reject_enemy_building_without_raid() -> void:
	var building: Node2D = _make_building()
	building.clan_name = "ENEMY"
	building.player_owned = false
	building.is_raidable = false
	building.global_position = Vector2(30, 0)
	var entity_id: int = _bridge.get_entity_id(building)
	var op := _move_op("player", 0, "building", 0, ResourceData.ResourceType.WOOD, 1, "move", entity_id)
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1})
	_expect_reject(op, "to_access_denied", "reject_enemy_building")
	_unregister_entity(building)
	building.queue_free()


func _test_accept_raidable_enemy_building() -> void:
	var building: Node2D = _make_building()
	building.clan_name = "ENEMY"
	building.is_raidable = true
	building.global_position = Vector2(30, 0)
	var entity_id: int = _bridge.get_entity_id(building)
	var op := _move_op("player", 0, "building", 0, ResourceData.ResourceType.WOOD, 1, "move", entity_id)
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1})
	_expect_accept(op, "accept_raidable_building")
	_unregister_entity(building)
	building.queue_free()


func _test_craft_consume_and_finish() -> void:
	_reset_player_inventory()
	_player_ui.inventory_data.set_slot(0, {"type": ResourceData.ResourceType.STONE, "count": 2})
	var consume_op: Dictionary = {
		"type": "craft",
		"craft_output": int(ResourceData.ResourceType.OLDOWAN),
		"craft_phase": "consume",
	}
	_expect_accept(consume_op, "craft_consume")
	if _player_ui.inventory_data.get_count(ResourceData.ResourceType.STONE) != 0:
		_fail("craft_consume: stone should be consumed")
	var finish_op: Dictionary = {
		"type": "craft",
		"craft_output": int(ResourceData.ResourceType.OLDOWAN),
		"craft_phase": "finish",
	}
	_expect_accept(finish_op, "craft_finish")
	if _player_ui.inventory_data.get_count(ResourceData.ResourceType.OLDOWAN) != 1:
		_fail("craft_finish: oldowan not added")


func _test_reject_craft_without_materials() -> void:
	_reset_player_inventory()
	var op: Dictionary = {
		"type": "craft",
		"craft_output": int(ResourceData.ResourceType.OLDOWAN),
		"craft_phase": "consume",
	}
	_expect_reject(op, "cannot_afford", "reject_craft_without_materials")


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("TEST_INVENTORY_VALIDATION_FAIL: %s" % msg)


func _finish() -> void:
	if _failures.is_empty():
		print("TEST_INVENTORY_VALIDATION: all 13 checks passed")
		quit(0)
	else:
		for msg in _failures:
			print("FAIL: ", msg)
		quit(1)
