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
