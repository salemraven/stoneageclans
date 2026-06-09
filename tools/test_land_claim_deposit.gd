extends SceneTree

## Headless checks for land-claim deposit stacking / capacity rules.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_LAND_CLAIM_DEPOSIT_FAIL: %s" % msg)
	quit(1)


func _pass(msg: String) -> void:
	print("TEST_LAND_CLAIM_DEPOSIT_OK: %s" % msg)


func _run() -> void:
	await process_frame
	_test_stack_existing_type_when_slots_full()
	_test_new_type_needs_empty_slot()
	_test_consolidate_frees_slot_for_berries()
	_test_upgrade_campfire_inventory()
	_test_can_add_item_with_partial_stack()
	print("TEST_LAND_CLAIM_DEPOSIT: all checks passed")
	quit(0)


func _test_stack_existing_type_when_slots_full() -> void:
	var inv := InventoryData.new(3, true, 999)
	inv.add_item(ResourceData.ResourceType.STONE, 1)
	inv.add_item(ResourceData.ResourceType.WOOD, 1)
	inv.add_item(ResourceData.ResourceType.FIBER, 1)
	if inv.has_space():
		_fail("expected no empty slots")
	if not inv.can_add_item(ResourceData.ResourceType.STONE, 1):
		_fail("stone should stack even when all slots used")
	if not inv.add_item(ResourceData.ResourceType.STONE, 1):
		_fail("add_item stone should succeed on existing stack")
	if inv.get_count(ResourceData.ResourceType.STONE) != 2:
		_fail("stone count should be 2 after stack deposit")
	_pass("stack on full inventory")


func _test_new_type_needs_empty_slot() -> void:
	var inv := InventoryData.new(2, true, 999)
	inv.add_item(ResourceData.ResourceType.STONE, 1)
	inv.add_item(ResourceData.ResourceType.WOOD, 1)
	if inv.can_add_item(ResourceData.ResourceType.BERRIES, 1):
		_fail("berries should not fit without empty slot")
	if inv.add_item(ResourceData.ResourceType.BERRIES, 1):
		_fail("berries add should fail when no slot and no berry stack")
	_pass("new type blocked when full")


func _test_consolidate_frees_slot_for_berries() -> void:
	var inv := InventoryData.new(3, true, 999)
	inv.slots[0] = {"type": ResourceData.ResourceType.STONE, "count": 5, "quality": 0}
	inv.slots[1] = {"type": ResourceData.ResourceType.STONE, "count": 3, "quality": 0}
	inv.slots[2] = {"type": ResourceData.ResourceType.WOOD, "count": 2, "quality": 0}
	inv.consolidate_stacks()
	if inv.get_used_slots() != 2:
		_fail("consolidate should merge duplicate stone stacks (used=%d)" % inv.get_used_slots())
	if not inv.can_add_item(ResourceData.ResourceType.BERRIES, 1):
		_fail("berries should fit after consolidate freed a slot")
	if not inv.add_item(ResourceData.ResourceType.BERRIES, 1):
		_fail("berries add should succeed after consolidate")
	_pass("consolidate frees slot for new food")


func _test_upgrade_campfire_inventory() -> void:
	var inv := InventoryData.new(20, true, 999)
	for t in [ResourceData.ResourceType.STONE, ResourceData.ResourceType.WOOD, ResourceData.ResourceType.FIBER]:
		inv.add_item(t, 1)
	inv.upgrade_storage(40, 999999)
	if inv.slot_count != 40:
		_fail("upgrade should expand to 40 slots")
	if inv.max_stack != 999999:
		_fail("upgrade should raise max_stack")
	if inv.get_count(ResourceData.ResourceType.STONE) != 1:
		_fail("upgrade should preserve items")
	if not inv.can_add_item(ResourceData.ResourceType.BERRIES, 1):
		_fail("berries should fit after campfire upgrade expansion")
	_pass("campfire -> land claim inventory upgrade")


func _test_can_add_item_with_partial_stack() -> void:
	var inv := InventoryData.new(1, true, 10)
	inv.add_item(ResourceData.ResourceType.BERRIES, 8)
	if not inv.can_add_item(ResourceData.ResourceType.BERRIES, 2):
		_fail("should fit 2 more berries on partial stack")
	if inv.can_add_item(ResourceData.ResourceType.BERRIES, 3):
		_fail("should not fit 3 more berries on stack with 2 space left")
	_pass("can_add_item respects max_stack")
