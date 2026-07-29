extends Node
## Single source of truth for which chunks and claims are simulation-active.

const CLAIM_ACTIVE_WORLD_RADIUS: float = 2400.0

var _active_chunks: Dictionary = {}  # Vector2i -> true
var _sim_active_chunks: Dictionary = {}  # Vector2i -> true (smaller radius — full sim)
var _active_claims: Dictionary = {}  # instance_id -> true


func recompute(main: Node) -> void:
	_active_chunks.clear()
	_sim_active_chunks.clear()
	_active_claims.clear()
	if main == null:
		return
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	var radius: int = 1
	if wgc and wgc.has_method("get_effective_load_radius"):
		radius = int(wgc.call("get_effective_load_radius"))
	if wgc:
		radius = maxi(radius, int(wgc.get("single_player_initial_load_radius")))
	var sim_radius: int = 1
	if wgc:
		sim_radius = maxi(0, int(wgc.get("sim_active_chunk_radius")))
	var player_centers: Array[Vector2] = []
	var player: Node2D = main.get("player") as Node2D if main.get("player") != null else null
	if player and is_instance_valid(player):
		player_centers.append(player.global_position)
	for p in main.get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p is Node2D and p != player:
			player_centers.append((p as Node2D).global_position)
	for center in player_centers:
		if ChunkUtils == null:
			continue
		var cc := ChunkUtils.get_chunk_coords(center)
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				_active_chunks[cc + Vector2i(dx, dy)] = true
		for dx in range(-sim_radius, sim_radius + 1):
			for dy in range(-sim_radius, sim_radius + 1):
				_sim_active_chunks[cc + Vector2i(dx, dy)] = true
	for claim in main.get_tree().get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim) or not (claim is Node2D):
			continue
		var cp: Vector2 = (claim as Node2D).global_position
		for pc in player_centers:
			if cp.distance_to(pc) <= CLAIM_ACTIVE_WORLD_RADIUS:
				_active_claims[claim.get_instance_id()] = true
				break


func is_chunk_active(chunk: Vector2i) -> bool:
	return _active_chunks.has(chunk)


func is_chunk_sim_active(chunk: Vector2i) -> bool:
	return _sim_active_chunks.has(chunk)


func is_claim_active(claim: Node) -> bool:
	if claim == null:
		return false
	return _active_claims.has(claim.get_instance_id())


func get_active_chunk_list() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in _active_chunks.keys():
		out.append(k as Vector2i)
	return out


func get_primary_stream_position(main: Node) -> Vector2:
	var player: Node2D = main.get("player") as Node2D if main and main.get("player") != null else null
	if player and is_instance_valid(player):
		return player.global_position
	return Vector2.ZERO


func get_player_centers(main: Node) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	if main == null:
		return centers
	var primary: Node2D = main.get("player") as Node2D if main.get("player") != null else null
	if primary and is_instance_valid(primary):
		centers.append(primary.global_position)
	for p in main.get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		if p == primary:
			continue
		centers.append((p as Node2D).global_position)
	return centers


## Server: union of all peer positions. Client: local player only.
func get_stream_centers_for_main(main: Node) -> Array[Vector2]:
	if main == null:
		return []
	var mp: MultiplayerAPI = main.get_tree().get_multiplayer()
	if mp.has_multiplayer_peer() and mp.is_server():
		return get_player_centers(main)
	var local := get_primary_stream_position(main)
	if local != Vector2.ZERO:
		return [local]
	return []
