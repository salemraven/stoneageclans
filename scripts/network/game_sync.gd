extends Node
## Phases 4–5 stubs: player spawn, movement sync, world snapshot. Extend when scenes register RPC targets.
## Connect `peer_connected_to_game` from Main to spawn remote players; implement spawn_entity RPCs here or on Main.

signal server_player_joined(peer_id: int)
signal need_world_snapshot_for_peer(peer_id: int)


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


## Placeholder: server broadcasts authoritative player state at fixed rate (e.g. 20 Hz). Wire from Main/player scene.
@rpc("authority", "call_local", "unreliable")
func broadcast_player_state(_network_id: int, _pos: Vector2, _vel: Vector2) -> void:
	pass


## Placeholder: full world for late join. Deserialize on client and instantiate by network_id.
@rpc("authority", "call_remote", "reliable")
func receive_world_snapshot(_snapshot: Dictionary) -> void:
	pass
