extends SceneTree
## Headless layout + stockpile rules check (bible/UI.md).

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for _i in 8:
		await process_frame
	_test_stockpile_rules()
	await _test_slot_clip()
	await _test_stockpile_count_on_screen()
	_test_panel_gap_math()
	await _test_window_layout_memory()
	_finish()


func _test_stockpile_rules() -> void:
	var stock := InventoryData.new(6, true, 999)
	stock.add_item(ResourceData.ResourceType.WOOD, 20)
	stock.add_item(ResourceData.ResourceType.WOOD, 27)
	stock.consolidate_stacks()
	if stock.get_used_slots() != 1:
		_fail("stockpile should be one Wood row, used=%d" % stock.get_used_slots())
	if stock.get_count(ResourceData.ResourceType.WOOD) != 47:
		_fail("wood count %d" % stock.get_count(ResourceData.ResourceType.WOOD))
	var bag := InventoryData.new(5, false, 1)
	# Drag-to-bag fills one slot (count 1 for wood). Helper still exists for other uses.
	bag.set_slot(0, {"type": ResourceData.ResourceType.WOOD, "count": 1})
	if bag.get_used_slots() != 1 or bag.get_count(ResourceData.ResourceType.WOOD) != 1:
		_fail("one bag slot should hold 1 wood, used=%d count=%d" % [bag.get_used_slots(), bag.get_count(ResourceData.ResourceType.WOOD)])
	var full := InventoryData.new(5, false, 1)
	for i in 5:
		full.set_slot(i, {"type": ResourceData.ResourceType.STONE, "count": 1})
	if full.can_add_item(ResourceData.ResourceType.WOOD, 1):
		_fail("full bag should reject wood")


func _test_slot_clip() -> void:
	var row := InventorySlot.new()
	row.is_hotbar = false
	root.add_child(row)
	await process_frame
	if row.clip_contents:
		_fail("list slot should not clip the count column")
	if row.custom_minimum_size.x < InventorySlot.COUNT_COL.x:
		_fail("list row min width too small for count")
	var hot := InventorySlot.new()
	hot.is_hotbar = true
	root.add_child(hot)
	await process_frame
	if not hot.clip_contents:
		_fail("hotbar slot clip_contents off")
	if hot.custom_minimum_size != Vector2(InventorySlot.HOTBAR_CELL, InventorySlot.HOTBAR_CELL):
		_fail("hotbar cell size %s" % str(hot.custom_minimum_size))
	row.queue_free()
	hot.queue_free()


func _test_stockpile_count_on_screen() -> void:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.custom_minimum_size = Vector2(1280, 720)
	host.size = Vector2(1280, 720)
	root.add_child(host)
	var ui := BuildingInventoryUI.new()
	host.add_child(ui)
	for _i in 8:
		await process_frame
	var inv := InventoryData.new(6, true, 999)
	inv.add_item(ResourceData.ResourceType.WOOD, 47)
	ui.setup_inventory(inv)
	ui.visible = true
	if ui.has_method("show_inventory"):
		ui.show_inventory()
	for _j in 8:
		await process_frame
	var found := false
	for s in ui.slots:
		if not is_instance_valid(s) or not s.visible:
			continue
		var item: Dictionary = s.get_item()
		if item.is_empty():
			continue
		if int(item.get("count", 1)) != 47:
			continue
		found = true
		if s.count_label == null:
			_fail("stockpile count_label missing")
			break
		if not s.count_label.visible:
			_fail("stockpile count_label hidden")
			break
		if str(s.count_label.text) != "47":
			_fail("stockpile count text '%s'" % s.count_label.text)
			break
		if s.count_label.size.x < 40.0 or s.count_label.size.y < 10.0:
			_fail("stockpile count size %s" % str(s.count_label.size))
			break
		var panel: Control = ui.inventory_panel
		if panel:
			var count_r: Rect2 = s.count_label.get_global_rect()
			var panel_r: Rect2 = panel.get_global_rect()
			if not panel_r.encloses(count_r) and panel_r.intersection(count_r).size.x < 40.0:
				_fail("stockpile count not inside panel: count=%s panel=%s" % [count_r, panel_r])
		break
	if not found:
		_fail("no visible Wood x47 row")
	ui.queue_free()
	host.queue_free()


func _test_panel_gap_math() -> void:
	var gap: float = float(BuildingInventoryUI.PANEL_GAP)
	var bw: float = float(BuildingInventoryUI.PANEL_WIDTH)
	var pw: float = float(PlayerInventoryUI.PANEL_WIDTH)
	var player_left: float = -pw / 2.0
	var b_left: float = player_left - gap - bw
	var b_right: float = player_left - gap
	if b_right > player_left:
		_fail("building panel overlaps player (right %s > left %s)" % [b_right, player_left])
	if absf(player_left - b_right - gap) > 0.01:
		_fail("gap between panels is not %s" % gap)
	if bw < pw:
		_fail("stockpile width %s narrower than bag %s" % [bw, pw])


func _test_window_layout_memory() -> void:
	InventoryUI.persist_window_layout_to_disk = false
	InventoryUI._window_layout_loaded = true
	InventoryUI._window_layout["building_stockpile"] = Vector2(48, 72)
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.custom_minimum_size = Vector2(1280, 720)
	host.size = Vector2(1280, 720)
	root.add_child(host)
	var ui := BuildingInventoryUI.new()
	host.add_child(ui)
	for _i in 8:
		await process_frame
	ui.show_inventory()
	for _j in 6:
		await process_frame
	var gp: Vector2 = ui.inventory_panel.global_position
	if absf(gp.x - 48.0) > 2.0 or absf(gp.y - 72.0) > 2.0:
		_fail("remembered stockpile pos %s expected (48, 72)" % gp)
	InventoryUI._window_layout.erase("building_stockpile")
	InventoryUI.persist_window_layout_to_disk = true
	ui.queue_free()
	host.queue_free()


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("TEST_UI_LAYOUT_AUDIT_FAIL: %s" % msg)


func _finish() -> void:
	if _failures.is_empty():
		print("TEST_UI_LAYOUT_AUDIT: all checks passed")
		quit(0)
	else:
		for msg in _failures:
			print("FAIL: ", msg)
		quit(1)
