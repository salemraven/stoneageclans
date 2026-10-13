extends Node
## Keeps an unloaded AI camp's claim, huts, and roster alive. Does not run a second production sim.
## Parked claims do not _process. This node advances at most a few brains per frame on the server.

const MAX_CAMPS_PER_FRAME := 2
const PARKED_CHUNK_META := &"parked_chunk"

var _parked: Array[Node] = []
var _cursor: int = 0
var _pending_stock: Dictionary = {}


func _process(delta: float) -> void:
	if _parked.is_empty():
		return
	if not _server_sim():
		return
	var n: int = mini(MAX_CAMPS_PER_FRAME, _parked.size())
	for _i in n:
		if _parked.is_empty():
			return
		_cursor = _cursor % _parked.size()
		var claim: Node = _parked[_cursor]
		_cursor += 1
		if not is_instance_valid(claim):
			_parked.erase(claim)
			continue
		var brain: Variant = claim.get("clan_brain")
		if brain and brain.has_method("dormant_update"):
			brain.call("dormant_update", delta)


func park_chunk_root(chunk_root: Node, chunk: Vector2i) -> void:
	if chunk_root == null or not is_instance_valid(chunk_root):
		return
	var claims: Array[Node] = []
	_collect_claims(chunk_root, claims)
	for claim in claims:
		park_claim(claim, chunk)


func park_claim(claim: Node, chunk: Vector2i) -> void:
	if claim == null or not is_instance_valid(claim):
		return
	if bool(claim.get("player_owned")):
		return
	if claim in _parked:
		return
	claim.set_meta(PARKED_CHUNK_META, chunk)
	var buildings: Array = []
	if ClaimBuildingIndex:
		buildings = ClaimBuildingIndex.get_buildings_in_claim(claim)
	_reparent_keep_global(claim, self)
	claim.visible = false
	claim.set_process(false)
	var slot := 0
	for building in buildings:
		if building == null or not is_instance_valid(building):
			continue
		_ensure_hut_net_id(claim, building, slot)
		slot += 1
		_reparent_keep_global(building, self)
		building.visible = false
		building.set_process(false)
	var brain: Variant = claim.get("clan_brain")
	if brain and brain.has_method("set_dormant"):
		brain.call("set_dormant", true)
	# The leader lives under the chunk root and is freed with it; the parked claim must not keep a dead reference.
	var leader: Variant = claim.get("owner_npc")
	if leader is Node and is_instance_valid(leader):
		var cb := _forget_owner.bind(claim, leader)
		if not (leader as Node).tree_exiting.is_connected(cb):
			(leader as Node).tree_exiting.connect(cb, CONNECT_ONE_SHOT)
	_parked.append(claim)
	_log_camp("camp_parked", claim, chunk)


func has_parked_chunk(chunk: Vector2i) -> bool:
	return _claim_for_chunk(chunk) != null


func restore_chunk(chunk: Vector2i, chunk_root: Node) -> bool:
	var claim: Node = _claim_for_chunk(chunk)
	if claim == null or chunk_root == null:
		return false
	_parked.erase(claim)
	var buildings: Array = []
	if ClaimBuildingIndex:
		buildings = ClaimBuildingIndex.get_buildings_in_claim(claim)
	_reparent_keep_global(claim, chunk_root)
	claim.visible = true
	claim.set_process(true)
	for building in buildings:
		if building == null or not is_instance_valid(building):
			continue
		_reparent_keep_global(building, chunk_root)
		building.visible = true
		building.set_process(true)
		_apply_pending_stock(building)
	var brain: Variant = claim.get("clan_brain")
	if brain and brain.has_method("materialize_clan_for_combat"):
		brain.call("materialize_clan_for_combat")
	_rebind_owner(claim)
	_log_camp("camp_restored", claim, chunk)
	return true


func _forget_owner(claim: Node, leader: Node) -> void:
	if not is_instance_valid(claim) or not (claim in _parked):
		return
	if claim.get("owner_npc") == leader:
		claim.set("owner_npc", null)


func _rebind_owner(claim: Node) -> void:
	var current: Variant = claim.get("owner_npc")
	if current is Node and is_instance_valid(current):
		return
	claim.set("owner_npc", null)
	var brain: Variant = claim.get("clan_brain")
	if brain == null or brain.get("roster") == null:
		return
	var leader_id := 0
	for m in brain.roster.members:
		if bool(m.get("alive", false)) and bool(m.get("is_leader", false)):
			leader_id = int(m.get("id", 0))
			break
	if leader_id == 0:
		return
	var clan_key: String = str(claim.get("clan_name")).strip_edges().to_lower()
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc == null or not is_instance_valid(npc) or npc.is_queued_for_deletion():
			continue
		if str(npc.get("clan_name")).strip_edges().to_lower() != clan_key:
			continue
		if int(npc.get_meta("settlement_member_id", 0)) == leader_id and npc is Node2D:
			claim.set("owner_npc", npc)
			return


func stash_stock(hut_net_id: String, clan_name: String, hut_rows: Array, claim_rows: Array) -> void:
	if hut_net_id.is_empty():
		return
	_pending_stock[hut_net_id] = {
		"clan": clan_name,
		"hut": hut_rows,
		"claim": claim_rows,
	}


func take_pending(hut_net_id: String) -> Dictionary:
	if not _pending_stock.has(hut_net_id):
		return {}
	var row: Dictionary = _pending_stock[hut_net_id] as Dictionary
	_pending_stock.erase(hut_net_id)
	return row


func _apply_pending_stock(building: Node) -> void:
	if building == null or not building.has_meta("hut_net_id"):
		return
	var row: Dictionary = take_pending(str(building.get_meta("hut_net_id")))
	if row.is_empty():
		return
	var hut_inv: InventoryData = building.get("inventory") as InventoryData
	_write_inventory(hut_inv, row.get("hut", []) as Array)
	var claim: Node = building.get("land_claim") as Node
	if claim and claim.get("inventory") is InventoryData:
		_write_inventory(claim.get("inventory") as InventoryData, row.get("claim", []) as Array)


func _claim_for_chunk(chunk: Vector2i) -> Node:
	for claim in _parked:
		if not is_instance_valid(claim):
			continue
		var stored: Variant = claim.get_meta(PARKED_CHUNK_META)
		if stored is Vector2i and (stored as Vector2i) == chunk:
			return claim
	return null


func _collect_claims(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		if child is LandClaim:
			out.append(child)
		_collect_claims(child, out)


func _ensure_hut_net_id(claim: Node, building: Node, slot: int) -> void:
	if building.has_meta("hut_net_id") and str(building.get_meta("hut_net_id")) != "":
		return
	var clan: String = str(claim.get("clan_name"))
	building.set_meta("hut_net_id", "%s#%d" % [clan, slot])


func _reparent_keep_global(node: Node, next_parent: Node) -> void:
	if node == null or next_parent == null or node.get_parent() == next_parent:
		return
	var global_pos := Vector2.ZERO
	if node is Node2D:
		global_pos = (node as Node2D).global_position
	var old := node.get_parent()
	if old:
		old.remove_child(node)
	next_parent.add_child(node)
	if node is Node2D:
		(node as Node2D).global_position = global_pos


func _write_inventory(inv: InventoryData, rows: Array) -> void:
	if inv == null:
		return
	for i in inv.slot_count:
		inv.set_slot(i, {})
	for row in rows:
		if not (row is Dictionary):
			continue
		var rec: Dictionary = row as Dictionary
		inv.add_item(int(rec.get("type", 0)) as ResourceData.ResourceType, int(rec.get("count", 0)))


func _server_sim() -> bool:
	var mp := multiplayer
	if mp == null or not mp.has_multiplayer_peer():
		return true
	return mp.is_server()


func _log_camp(evt_name: String, claim: Node, chunk: Vector2i) -> void:
	var pi: Node = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("camp_park_event"):
		pi.call("camp_park_event", evt_name, str(claim.get("clan_name")), chunk.x, chunk.y)
