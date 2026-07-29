extends Node
## Multiplayer: spawn zones (chunk centers), world snapshot, tick sync hooks.

signal server_player_joined(peer_id: int)
signal need_world_snapshot_for_peer(peer_id: int)

var _spawn_slot: int = 0
var _peer_spawn_zone_index: Dictionary = {}


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm and nm.has_signal("peer_connected_to_game"):
		nm.peer_connected_to_game.connect(_on_net_peer_connected)
	var sm := get_node_or_null("/root/SimulationManager")
	if sm and sm.has_signal("simulation_tick") and not sm.simulation_tick.is_connected(_on_simulation_tick_sync):
		sm.simulation_tick.connect(_on_simulation_tick_sync)


func _on_net_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		server_player_joined.emit(id)
		need_world_snapshot_for_peer.emit(id)


## Server: assign next spawn zone from WorldGenConfig; stable for same peer_id.
func consume_spawn_world_position_for_peer(peer_id: int) -> Vector2:
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	if not wgc:
		return Vector2.ZERO
	var zones: Array = wgc.player_spawn_zones
	if zones.is_empty():
		return Vector2.ZERO
	if _peer_spawn_zone_index.has(peer_id):
		var zi0: int = int(_peer_spawn_zone_index[peer_id])
		var c0: Vector2i = zones[zi0] as Vector2i
		return ChunkUtils.get_chunk_center(c0)
	var zi: int = _spawn_slot % zones.size()
	_spawn_slot += 1
	_peer_spawn_zone_index[peer_id] = zi
	var c: Vector2i = zones[zi] as Vector2i
	return ChunkUtils.get_chunk_center(c)


@rpc("authority", "call_remote", "reliable")
func apply_spawn_position(world_pos: Vector2) -> void:
	var main_n := get_tree().get_first_node_in_group("main")
	if main_n == null:
		return
	var pl: Node2D = main_n.get("player") as Node2D
	if pl and is_instance_valid(pl):
		pl.global_position = world_pos


func server_send_spawn_to_peer(peer_id: int, world_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	apply_spawn_position.rpc_id(peer_id, world_pos)


@rpc("authority", "call_local", "unreliable")
func broadcast_player_state(_network_id: int, _pos: Vector2, _vel: Vector2) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func receive_world_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	var ms: Node = get_node_or_null("/root/MutationStore")
	if wgc:
		wgc.world_seed = int(snapshot.get("seed", wgc.world_seed))
	if ms and snapshot.has("mutations") and ms.has_method("load_from_dict"):
		ms.call("load_from_dict", snapshot["mutations"])


## Client → server: authoritative gather by stable_id (spatial radius validated on server).
@rpc("any_peer", "call_remote", "reliable")
func request_gather(stable_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var main_n: Node = get_tree().get_first_node_in_group("main")
	if main_n == null or stable_id.is_empty():
		return
	var player_node: Node2D = _resolve_player_for_peer(main_n, sender_id)
	if player_node == null:
		return
	var resource: Node2D = _find_resource_by_stable_id(stable_id)
	if resource == null or not is_instance_valid(resource):
		return
	if not resource.has_method("is_player_in_gather_range"):
		return
	if not resource.is_player_in_gather_range(player_node.global_position):
		return
	if main_n.get("active_collection_resource") != resource:
		main_n.active_collection_resource = resource
	if resource.has_method("set_player_proximity"):
		resource.set_player_proximity(player_node)
	if resource.has_method("try_player_gather_press"):
		resource.try_player_gather_press(main_n)


func _resolve_player_for_peer(main_n: Node, peer_id: int) -> Node2D:
	if peer_id == 0 or peer_id == multiplayer.get_unique_id():
		return main_n.get("player") as Node2D if main_n.get("player") != null else null
	for p in main_n.get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		if int(p.get_multiplayer_authority()) == peer_id:
			return p as Node2D
	return main_n.get("player") as Node2D if main_n.get("player") != null else null


func _find_resource_by_stable_id(stable_id: String) -> Node2D:
	for node in get_tree().get_nodes_in_group("resources"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		if node.has_meta(&"stable_id") and str(node.get_meta(&"stable_id")) == stable_id:
			return node as Node2D
		var parent := node.get_parent()
		if parent and parent.has_meta(&"stable_id") and str(parent.get_meta(&"stable_id")) == stable_id:
			return node as Node2D
	return null


func _on_simulation_tick_sync(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	var tree := get_tree()
	if tree == null:
		return
	for claim in tree.get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim) or not claim.has_method("get_clan_brain"):
			continue
		var cb: RefCounted = claim.get_clan_brain()
		if cb == null or cb.get("clan_metrics") == null:
			continue
		var cn: String = str(cb.clan_name) if cb.get("clan_name") != null else ""
		if cn.is_empty():
			continue
		receive_clan_metrics.rpc(cb.clan_metrics, cn)


@rpc("authority", "call_remote", "unreliable")
func receive_clan_metrics(metrics: Dictionary, clan_name: String) -> void:
	if clan_name.is_empty():
		return
	var tree := get_tree()
	if tree == null:
		return
	for claim in tree.get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim):
			continue
		var cn: String = str(claim.get("clan_name")) if claim.get("clan_name") != null else ""
		if cn != clan_name:
			continue
		if claim.has_method("get_clan_brain"):
			var cb: RefCounted = claim.get_clan_brain()
			if cb:
				cb.clan_metrics = metrics
		for key in ["calories_days_buffer", "calories_in_storage", "calories_daily_need", "food_days_buffer"]:
			if metrics.has(key):
				claim.set_meta(key, metrics[key])
		break
