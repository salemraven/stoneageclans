extends SceneTree

## Grid range + filters.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var idx: Node = root.get_node_or_null("/root/HostileEntityIndex")
	if idx == null:
		push_error("TEST_HOSTILE_GRID: HostileEntityIndex missing")
		quit(1)
		return
	idx._cells.clear()
	idx._by_id.clear()
	var cell: int = idx.grid_cell_size_px()
	if cell != 512:
		push_error("TEST_HOSTILE_GRID: cell_size expected 512 got %d" % cell)
		quit(1)
		return
	var a := _dummy("caveman", "RED", Vector2(10, 10))
	var b := _dummy("caveman", "BLUE", Vector2(40, 10))
	var dead := _dummy("caveman", "BLUE", Vector2(20, 10))
	dead.set_meta("is_corpse", true)
	root.add_child(a)
	root.add_child(b)
	root.add_child(dead)
	idx.register(a)
	idx.register(b)
	idx.register(dead)
	var hit: Array = idx.get_enemies_in_range(a.global_position, 80.0, a)
	if hit.find(b) < 0:
		push_error("TEST_HOSTILE_GRID: in-cell miss")
		quit(1)
		return
	if hit.find(dead) >= 0:
		push_error("TEST_HOSTILE_GRID: corpse should skip")
		quit(1)
		return
	var corner := Vector2(float(cell) - 1.0, float(cell) - 1.0)
	var far := _dummy("caveman", "BLUE", corner + Vector2(20, 20))
	root.add_child(far)
	idx.register(far)
	var across: Array = idx.get_in_range(corner, 80.0, idx.FILTER_FIGHTERS, a)
	if across.find(far) < 0:
		push_error("TEST_HOSTILE_GRID: corner radius miss")
		quit(1)
		return
	var sheep := _dummy("sheep", "", Vector2(15, 10))
	root.add_child(sheep)
	idx.register(sheep)
	var near: Array = idx.get_in_range(a.global_position, 30.0, idx.FILTER_NEARBY, a)
	if near.find(sheep) < 0:
		push_error("TEST_HOSTILE_GRID: FILTER_NEARBY missed sheep")
		quit(1)
		return
	idx.unregister(b)
	var after: Array = idx.get_enemies_in_range(a.global_position, 80.0, a)
	if after.find(b) >= 0:
		push_error("TEST_HOSTILE_GRID: unregister failed")
		quit(1)
		return
	print("TEST_HOSTILE_GRID: ok cell=%d" % cell)
	quit(0)


func _dummy(nt: String, clan: String, pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.set_script(_dummy_script())
	n.position = pos
	n.npc_type = nt
	n.clan_name = clan
	return n


func _dummy_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """
extends Node2D
var npc_type: String = ""
var clan_name: String = ""
func get_clan_name() -> String:
	return clan_name
"""
	s.reload()
	return s
