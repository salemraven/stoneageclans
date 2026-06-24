extends Node
## Tier-B NPC storage — data-only records for off-chunk / sleeping clan members.

var _sleeping: Dictionary = {}  # network_id -> Dictionary record
var _by_chunk: Dictionary = {}  # "cx,cy" -> Array[int network_ids]


func _chunk_key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


func sleep_npc(npc: Node) -> void:
	if npc == null or not is_instance_valid(npc):
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
		main.call("spawn_npc_from_sleep_data", data, parent)
		_sleeping.erase(int(nid))
	_by_chunk.erase(ck)


func get_sleeping_count() -> int:
	return _sleeping.size()
