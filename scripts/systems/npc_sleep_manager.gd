extends Node
## Tier-B NPC storage — data-only records for off-chunk / sleeping clan members.

var _sleeping: Dictionary = {}  # network_id -> Dictionary record
var _by_chunk: Dictionary = {}  # "cx,cy" -> Array[int network_ids]


func _chunk_key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


func sleep_npc(npc: Node) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	if _is_clan_person(npc):
		_keep_clan_person_on_record(npc)
		npc.queue_free()
		return
	if not npc.has_method("serialize_to_sleep_data"):
		return
	var data: Dictionary = npc.call("serialize_to_sleep_data") as Dictionary
	if data.is_empty():
		return
	var nid: int = int(data.get("network_id", -1))
	if nid < 1:
		return
	_sleeping[nid] = data
	var pos: Vector2 = data.get("position", Vector2.ZERO) as Vector2
	var ck := _chunk_key(ChunkUtils.get_chunk_coords(pos) if ChunkUtils else Vector2i.ZERO)
	if not _by_chunk.has(ck):
		_by_chunk[ck] = []
	var arr: Array = _by_chunk[ck] as Array
	if nid not in arr:
		arr.append(nid)
	_by_chunk[ck] = arr
	npc.queue_free()


func sleep_npcs_in_chunk(chunk: Vector2i, main: Node) -> void:
	if main == null or ChunkUtils == null:
		return
	var player: Node = main.get("player") if main.get("player") != null else null
	var party_ids: Dictionary = {}
	if main.has_method("_get_party_follower_network_ids"):
		for id in main.call("_get_party_follower_network_ids") as Array:
			party_ids[int(id)] = true
	var origin := Vector2(float(chunk.x), float(chunk.y)) * ChunkUtils.CHUNK_SIZE
	var size := ChunkUtils.CHUNK_SIZE
	for npc in main.get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if player and npc == player:
			continue
		var pos: Vector2 = npc.global_position if npc is Node2D else Vector2.ZERO
		if pos.x < origin.x or pos.y < origin.y or pos.x >= origin.x + size or pos.y >= origin.y + size:
			continue
		var nid: int = EntityRegistry.get_network_id(npc) if EntityRegistry else -1
		if nid > 0 and party_ids.has(nid):
			continue
		if npc.get("npc_type") == "player":
			continue
		# Keep wild migratory and critical combat NPCs awake for now.
		if npc.has_method("is_wild") and npc.is_wild() and npc.has_method("is_migratory") and npc.is_migratory():
			continue
		var ct = npc.get("combat_target")
		if ct != null and is_instance_valid(ct):
			continue
		sleep_npc(npc)


func wake_npcs_in_chunk(chunk: Vector2i, parent: Node2D, main: Node) -> void:
	if main == null or not main.has_method("spawn_npc_from_sleep_data"):
		return
	var ck := _chunk_key(chunk)
	if not _by_chunk.has(ck):
		return
	var ids: Array = (_by_chunk[ck] as Array).duplicate()
	for nid in ids:
		var data: Dictionary = _sleeping.get(int(nid), {}) as Dictionary
		if data.is_empty():
			continue
		var ntype: String = str(data.get("npc_type", ""))
		if ntype in ["woman", "baby", "clansman", "caveman"]:
			_sleeping.erase(int(nid))
			continue
		main.call("spawn_npc_from_sleep_data", data, parent)
		_sleeping.erase(int(nid))
	_by_chunk.erase(ck)


func get_sleeping_count() -> int:
	return _sleeping.size()


func get_sleeping_for_clan(clan_name: String) -> Array:
	var out: Array = []
	if clan_name.is_empty():
		return out
	var target := clan_name.to_upper()
	for data in _sleeping.values():
		if not (data is Dictionary):
			continue
		var rec: Dictionary = data as Dictionary
		if str(rec.get("clan_name", "")).to_upper() == target:
			out.append(rec.duplicate())
	return out


func discard_people_for_clan(clan_name: String) -> int:
	if clan_name.is_empty():
		return 0
	var target := clan_name.to_upper()
	var removed := 0
	var to_erase: Array[int] = []
	for nid in _sleeping.keys():
		var data: Dictionary = _sleeping[nid] as Dictionary
		if str(data.get("clan_name", "")).to_upper() != target:
			continue
		var ntype: String = str(data.get("npc_type", ""))
		if ntype not in ["woman", "baby", "clansman", "caveman"]:
			continue
		to_erase.append(int(nid))
	for nid in to_erase:
		_sleeping.erase(nid)
		removed += 1
		_remove_from_chunk_index(nid)
	return removed


func _is_clan_person(npc: Node) -> bool:
	var ntype: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if ntype not in ["woman", "baby", "clansman", "caveman"]:
		return false
	var clan: String = str(npc.get("clan_name")) if npc.get("clan_name") != null else ""
	return not clan.strip_edges().is_empty()


func _keep_clan_person_on_record(npc: Node) -> void:
	var claim: Node = npc.call("get_my_land_claim") if npc.has_method("get_my_land_claim") else null
	if claim == null or not is_instance_valid(claim):
		var clan_key: String = str(npc.get("clan_name")).strip_edges().to_lower()
		var tree: SceneTree = npc.get_tree()
		if tree:
			for node in tree.get_nodes_in_group("land_claims"):
				if node and is_instance_valid(node) and str(node.get("clan_name")).strip_edges().to_lower() == clan_key:
					claim = node
					break
	var brain: Variant = claim.get("clan_brain") if claim else null
	if brain and brain.has_method("note_body_sleeping"):
		brain.call("note_body_sleeping", npc)


func clear_sleeping_for_clan(clan_name: String) -> int:
	if clan_name.is_empty():
		return 0
	var target := clan_name.to_upper()
	var removed := 0
	var to_erase: Array[int] = []
	for nid in _sleeping.keys():
		var data: Dictionary = _sleeping[nid] as Dictionary
		if str(data.get("clan_name", "")).to_upper() != target:
			continue
		to_erase.append(int(nid))
	for nid in to_erase:
		_sleeping.erase(nid)
		removed += 1
		_remove_from_chunk_index(nid)
	return removed


func _remove_from_chunk_index(network_id: int) -> void:
	for ck in _by_chunk.keys():
		var arr: Array = _by_chunk[ck] as Array
		arr.erase(network_id)
		if arr.is_empty():
			_by_chunk.erase(ck)
