extends Node

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")
const FightOverScript = preload("res://scripts/systems/fight_over.gd")

## Spatial cell grid. One near-list for combat, AOH prey, and claim hostiles.

const FILTER_FIGHTERS := 0
const FILTER_HUNT_PREY := 1
const FILTER_CLAIM_HOSTILES := 2
const FILTER_NEARBY := 3

var _cell_size: int = 512
var _cells: Dictionary = {}  # Vector2i -> Dictionary[int, Node]
var _by_id: Dictionary = {}  # int -> Vector2i
var _cell_size_ready: bool = false


func grid_cell_size_px() -> int:
	if _cell_size_ready:
		return _cell_size
	var aop: float = 380.0
	if NPCConfig:
		aop = float(NPCConfig.aop_radius_default)
	_cell_size = _ceil_pow2(maxi(1, int(ceil(aop))))
	_cell_size_ready = true
	return _cell_size


func _ceil_pow2(n: int) -> int:
	var p := 1
	while p < n:
		p *= 2
	return p


func _authority_ok() -> bool:
	var mp: MultiplayerAPI = get_tree().get_multiplayer() if get_tree() else null
	if mp == null or not mp.has_multiplayer_peer():
		return true
	return mp.is_server()


func cell_of(world_pos: Vector2) -> Vector2i:
	var cs := float(grid_cell_size_px())
	return Vector2i(int(floor(world_pos.x / cs)), int(floor(world_pos.y / cs)))


func register(node: Node) -> void:
	if not _authority_ok():
		return
	if node == null or not is_instance_valid(node) or not (node is Node2D):
		return
	if DebugConfig and DebugConfig.has_method("is_ignored_by_npcs") and DebugConfig.is_ignored_by_npcs(node):
		unregister(node)
		return
	if bool(node.get_meta("is_corpse", false)):
		return
	var hc: Node = node.get_node_or_null("HealthComponent")
	if hc != null and bool(hc.get("is_dead")):
		return
	if node.get("is_sim_dormant") != null and node.has_method("is_sim_dormant") and bool(node.is_sim_dormant()):
		return
	var id := node.get_instance_id()
	var cell := cell_of((node as Node2D).global_position)
	if _by_id.has(id):
		var old: Vector2i = _by_id[id]
		if old == cell:
			return
		_remove_from_cell(old, id)
	if not _cells.has(cell):
		_cells[cell] = {}
	(_cells[cell] as Dictionary)[id] = node
	_by_id[id] = cell


func unregister(node: Node) -> void:
	if node == null:
		return
	var id := node.get_instance_id()
	if not _by_id.has(id):
		return
	var cell: Vector2i = _by_id[id]
	_remove_from_cell(cell, id)
	_by_id.erase(id)


func sync_cell(node: Node) -> void:
	if not _authority_ok():
		return
	if node == null or not is_instance_valid(node):
		return
	register(node)


func _remove_from_cell(cell: Vector2i, id: int) -> void:
	if not _cells.has(cell):
		return
	var bag: Dictionary = _cells[cell]
	bag.erase(id)
	if bag.is_empty():
		_cells.erase(cell)


func get_enemies_in_range(origin: Vector2, radius: float, npc: Node) -> Array:
	return get_in_range(origin, radius, FILTER_FIGHTERS, npc)


func get_in_range(origin: Vector2, radius: float, filter: int, viewer: Node) -> Array:
	var out: Array = []
	if radius <= 0.0:
		return out
	var cs := float(grid_cell_size_px())
	var rings: int = int(ceil(radius / cs))
	var origin_cell := cell_of(origin)
	var r2: float = radius * radius
	for dx in range(-rings, rings + 1):
		for dy in range(-rings, rings + 1):
			var cell := origin_cell + Vector2i(dx, dy)
			if not _cells.has(cell):
				continue
			var bag: Dictionary = _cells[cell]
			for id in bag.keys():
				var target: Node = bag[id]
				if not _passes_filter(origin, r2, filter, viewer, target):
					continue
				out.append(target)
	return out


func _passes_filter(origin: Vector2, r2: float, filter: int, viewer: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target) or target == viewer:
		return false
	if DebugConfig and DebugConfig.has_method("is_ignored_by_npcs") and DebugConfig.is_ignored_by_npcs(target):
		return false
	if not (target is Node2D):
		return false
	if not FightOverScript.is_living_attack_target(target):
		return false
	if origin.distance_squared_to((target as Node2D).global_position) > r2:
		return false
	var target_type: String = str(target.get("npc_type")) if target.get("npc_type") != null else ""
	var is_player: bool = target.is_in_group("player")
	match filter:
		FILTER_FIGHTERS:
			if target_type != "caveman" and target_type != "clansman" and not is_player:
				return false
			if viewer and CombatAllyCheck.is_ally(viewer, target):
				return false
			return true
		FILTER_HUNT_PREY:
			if NPCConfig == null or not NPCConfig.is_ai_hunt_prey_type(target_type):
				return false
			if viewer:
				var vclan := _clan_of(viewer)
				var tclan := _clan_of(target)
				if vclan != "" and tclan != "" and vclan.to_lower() == tclan.to_lower():
					return false
			return true
		FILTER_CLAIM_HOSTILES:
			if target_type != "caveman" and target_type != "clansman" and not is_player:
				return false
			if viewer:
				var vclan2 := _clan_of(viewer)
				var tclan2 := _clan_of(target)
				if vclan2 != "" and tclan2 == vclan2:
					return false
			return true
		FILTER_NEARBY:
			return true
	return false


func _clan_of(n: Node) -> String:
	if n.has_method("get_clan_name"):
		return str(n.get_clan_name())
	if n.get("clan_name") != null:
		return str(n.get("clan_name"))
	return ""
