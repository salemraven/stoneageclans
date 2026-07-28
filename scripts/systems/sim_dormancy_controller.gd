extends Node
## Applies lightweight dormancy to NPCs + Area2D resources in loaded-but-cold chunks.
## Runs after WorldInterestManager.recompute (via ChunkManager.update_streaming).

var _party_ids_cache: Dictionary = {}
var _party_cache_frame: int = -1


func apply(main: Node) -> void:
	if main == null or not is_instance_valid(main):
		return
	var mp: MultiplayerAPI = get_tree().get_multiplayer()
	if mp.has_multiplayer_peer() and not mp.is_server():
		return
	_refresh_party_cache(main)
	_apply_npc_dormancy(main)
	_apply_resource_monitoring(main)
	_apply_land_claim_zones(main)


func _refresh_party_cache(main: Node) -> void:
	var frame := Engine.get_process_frames()
	if frame == _party_cache_frame:
		return
	_party_cache_frame = frame
	_party_ids_cache.clear()
	if main.has_method("_get_party_follower_network_ids"):
		for id in main.call("_get_party_follower_network_ids") as Array:
			_party_ids_cache[int(id)] = true


func _apply_npc_dormancy(main: Node) -> void:
	var player: Node = main.get("player") if main.get("player") != null else null
	for npc in main.get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if player and npc == player:
			continue
		var want_awake: bool = _npc_should_sim_awake(npc as Node, main)
		if npc.has_method("set_sim_dormant"):
			npc.call("set_sim_dormant", not want_awake)


func _apply_resource_monitoring(main: Node) -> void:
	for node in main.get_tree().get_nodes_in_group("resources"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var pos := (node as Node2D).global_position
		var hot := _is_sim_hot_for_position(pos, main)
		if node.has_method("apply_sim_monitoring"):
			node.call("apply_sim_monitoring", hot)


func _apply_land_claim_zones(main: Node) -> void:
	var interest: Node = get_node_or_null("/root/WorldInterestManager")
	for claim in main.get_tree().get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim):
			continue
		var active: bool = interest == null or bool(interest.call("is_claim_active", claim))
		if claim.has_method("set_sim_zones_monitoring"):
			claim.call("set_sim_zones_monitoring", active)


func _npc_should_sim_awake(npc: Node, main: Node) -> bool:
	if npc.get("npc_type") == "player":
		return true
	if npc.is_in_group("player"):
		return true
	var hc: Node = npc.get_node_or_null("HealthComponent")
	if hc and hc.get("is_dead") == true:
		return false
	var nid: int = EntityRegistry.get_network_id(npc) if EntityRegistry else -1
	if nid > 0 and _party_ids_cache.has(nid):
		return true
	var ct: Variant = npc.get("combat_target")
	if ct != null and is_instance_valid(ct):
		return true
	if npc.get("is_agro") == true:
		return true
	if not (npc is Node2D):
		return true
	return _is_sim_hot_for_position((npc as Node2D).global_position, main)


func _is_sim_hot_for_position(pos: Vector2, main: Node) -> bool:
	var interest: Node = get_node_or_null("/root/WorldInterestManager")
	if interest and interest.has_method("is_chunk_sim_active") and ChunkUtils:
		var cc := ChunkUtils.get_chunk_coords(pos)
		if bool(interest.call("is_chunk_sim_active", cc)):
			return true
	var wake_r: float = 960.0
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	if wgc:
		wake_r = float(wgc.get("sim_wake_player_radius_px"))
	return _is_near_any_player(pos, main, wake_r)


func _is_near_any_player(pos: Vector2, main: Node, radius_px: float) -> bool:
	var player: Node2D = main.get("player") as Node2D if main.get("player") != null else null
	if player and is_instance_valid(player):
		if pos.distance_to(player.global_position) <= radius_px:
			return true
	for p in main.get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p is Node2D and p != player:
			if pos.distance_to((p as Node2D).global_position) <= radius_px:
				return true
	return false
