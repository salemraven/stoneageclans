extends SceneTree
## Map viewer is drawable and climate toggles exist. Time ticks.

var _failed := 0
var _ice_btn: Button
var _dry_btn: Button


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== MAP_VIEWER_READY start ===")
	var packed: PackedScene = load("res://scenes/WorldMapEditor.tscn")
	if packed == null:
		_fail("missing WorldMapEditor.tscn")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	if scene.get_script() == null:
		_fail("editor script missing")
	var ground: Sprite2D = scene.get_node_or_null("GroundSprite")
	if ground == null or ground.texture == null:
		_fail("ground sprite/texture")
	elif ground.scale.x < 1000.0:
		_fail("ground scale %s" % ground.scale)
	else:
		print("PASS ground scale=%s" % ground.scale)
	if ground and ground.material == null:
		_fail("ground shader material")
	else:
		print("PASS ground has shader")
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	if tq:
		var ocean: int = int(tq.get_base_biome(Vector2(80, 80)))
		var mid: int = int(tq.get_base_biome(Vector2(32768, 32768)))
		print("biome corner=%d center=%d" % [ocean, mid])
		if ocean != 0:
			_fail("corner should be ocean got %d" % ocean)
		if mid == 4:
			_fail("center still swamp (mask luma bug)")
		else:
			print("PASS center land id=%d" % mid)
	_find_toggles(scene)
	if _ice_btn == null or _dry_btn == null:
		_fail("missing Ice age / Drought buttons")
	elif not _ice_btn.toggle_mode or not _dry_btn.toggle_mode:
		_fail("Ice age / Drought must be toggle buttons")
	else:
		print("PASS toggles present")
	var bar: Control = scene.get_node_or_null("UI/Screen/BottomBar") as Control
	if bar == null:
		_fail("missing bottom bar")
	else:
		print("PASS bottom bar")
	var extra: Node = scene.get_node_or_null("UI/Screen/BottomBar/Margin/ControlsRow/ExtraSlot")
	if extra == null:
		_fail("missing ExtraSlot for future controls")
	else:
		print("PASS ExtraSlot")
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	_ice_btn.button_pressed = true
	await process_frame
	if not bool(cs.event_ice):
		_fail("ice toggle did not start ice age")
	_dry_btn.button_pressed = true
	await process_frame
	if bool(cs.event_ice) and bool(cs.event_drought):
		_fail("ice and drought both on")
	elif not bool(cs.event_drought):
		_fail("drought toggle did not start drought")
	else:
		print("PASS exclusive ice/drought")
	_dry_btn.button_pressed = false
	await process_frame
	if bool(cs.event_ice) or bool(cs.event_drought):
		_fail("both-off still has event")
	else:
		print("PASS both off = normal climate")
	var d0: int = int(cs.sim_day) if cs else -1
	var waited := 0.0
	while waited < 0.35:
		await process_frame
		waited += 1.0 / 60.0
	var d1: int = int(cs.sim_day) if cs else -1
	if d1 <= d0:
		_fail("time did not advance %d -> %d" % [d0, d1])
	else:
		print("PASS time %d -> %d" % [d0, d1])
	print("=== MAP_VIEWER_READY done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _find_toggles(n: Node) -> void:
	if n is Button:
		var b := n as Button
		if b.text == "Ice age":
			_ice_btn = b
		elif b.text == "Drought":
			_dry_btn = b
	for c in n.get_children():
		_find_toggles(c)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
