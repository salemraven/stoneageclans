extends Node
## Applies lightweight dormancy to NPCs + Area2D resources in loaded-but-cold chunks.
## Runs after WorldInterestManager.recompute (via ChunkManager.update_streaming).

var _party_ids_cache: Dictionary = {}
var _party_cache_frame: int = -1
## A seeker who has reached the wake edge is still this close to a woman just outside it.
## Her circle has to be on or he stands on her and never catches.
const HERD_WAKE_RADIUS := 310.0
var _awake_herder_points: Array[Vector2] = []


func apply(main: Node) -> void:
	if main == null or not is_instance_valid(main):
		return
	var mp: MultiplayerAPI = get_tree().get_multiplayer()
	if mp.has_multiplayer_peer() and not mp.is_server():
		return
	_refresh_party_cache(main)
	_apply_npc_dormancy(main)
	# Resources use ResourceIndex spatial gather — no Area2D monitoring to toggle.
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
	_awake_herder_points.clear()
	if player is Node2D and is_instance_valid(player):
		_awake_herder_points.append((player as Node2D).global_position)
	for npc in main.get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc) or not (npc is Node2D):
			continue
		if player and npc == player:
			continue
		var herder_type: String = str(npc.get("npc_type"))
		if herder_type != "caveman" and herder_type != "clansman":
			continue
		if npc.has_method("is_dead") and npc.is_dead():
			continue
		if npc.has_method("is_sim_dormant") and npc.is_sim_dormant():
			continue
		_awake_herder_points.append((npc as Node2D).global_position)
	for npc in main.get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if player and npc == player:
			continue
		var want_awake: bool = _npc_should_sim_awake(npc as Node, main)
		if want_awake:
			var home: Node = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
			if home != null:
				SettlementParty.release_unpaid_field_trip(home, npc)
		else:
			SettlementParty.park_field_gather(npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null, npc)
		if npc.has_method("set_sim_dormant"):
			if want_awake:
				npc.call("set_sim_dormant", false)
			elif _holds_field_trip(npc):
				if npc.has_method("is_sim_dormant") and not npc.is_sim_dormant():
					npc.call("set_sim_dormant", true)
			elif SettlementParty.has_haul_job(npc):
				# A bush or chunk job with no ticket keeps walking. Freezing him is how he never came home.
				npc.call("set_sim_dormant", false)
			else:
				npc.call("set_sim_dormant", true)


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


func _holds_field_trip(npc: Node) -> bool:
	var home: Node = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if home == null or not home.has_meta("field_trips"):
		return false
	var stored: Variant = home.get_meta("field_trips")
	if not (stored is Array):
		return false
	var body_id := npc.get_instance_id()
	for trip_v in stored:
		if trip_v is Dictionary and int((trip_v as Dictionary).get("body_id", 0)) == body_id:
			return true
	return false


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
	var home: Node = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if home and home.has_method("has_village_intruder") and bool(home.call("has_village_intruder")):
		return true
	if not (npc is Node2D):
		return true
	# Eval watch modes: keep claim NPCs awake so you can see AI walk/work.
	var dc: Node = get_node_or_null("/root/DebugConfig")
	if dc and (bool(dc.get("enable_eval_camp")) or bool(dc.get("enable_eval_ai_arena")) or bool(dc.get("enable_ai_combat_observe"))):
		var interest: Node = get_node_or_null("/root/WorldInterestManager")
		var claim: Node = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
		if claim and (interest == null or bool(interest.call("is_claim_active", claim))):
			return true
	# Idle NPCs wake on player proximity only — not the whole sim-active chunk ring.
	var wake_r: float = 1200.0
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	if wgc:
		wake_r = float(wgc.get("sim_wake_player_radius_px"))
	if _is_near_any_player((npc as Node2D).global_position, main, wake_r):
		return true
	return _herdable_near_awake_herder(npc)


func _herdable_near_awake_herder(npc: Node) -> bool:
	var npc_type: String = str(npc.get("npc_type"))
	if npc_type != "woman" and npc_type != "sheep" and npc_type != "goat":
		return false
	if npc.has_method("is_wild") and not npc.is_wild():
		return false
	if not (npc is Node2D):
		return false
	var pos: Vector2 = (npc as Node2D).global_position
	for herder_pos in _awake_herder_points:
		if pos.distance_to(herder_pos) <= HERD_WAKE_RADIUS:
			return true
	return false


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
