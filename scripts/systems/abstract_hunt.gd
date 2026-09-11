class_name AbstractHunt
extends RefCounted
## Off-screen hunting: dormant clans hunt one wild prey per settlement tick (Phase 4).

const HUNT_INTENT_NONE: int = 0

const HUNTABLE_TYPES: Array[String] = ["deer", "sheep", "goat"]

const YIELD_KEY_TO_TYPE: Dictionary = {
	"meat": ResourceData.ResourceType.MEAT,
	"hide": ResourceData.ResourceType.HIDE,
	"bone": ResourceData.ResourceType.BONE,
}


static func hunt_for_claim(
	claim: Node,
	roster: RefCounted,
	chunk_coords: Vector2i,
	_clan_starving: bool = false,
	hunt_intent_state: int = HUNT_INTENT_NONE
) -> Dictionary:
	var events: Dictionary = {
		"hunted": false,
		"prey_type": "",
		"prey_stable_id": "",
		"loot": {"meat": 0, "hide": 0, "bone": 0},
		"chunk_x": chunk_coords.x,
		"chunk_y": chunk_coords.y,
		"skip_reason": "",
	}
	if claim == null or not is_instance_valid(claim) or roster == null:
		events["skip_reason"] = "invalid_claim_or_roster"
		return events
	if WorldGenConfig == null or not bool(WorldGenConfig.abstract_hunt_enabled):
		events["skip_reason"] = "disabled"
		return events
	if hunt_intent_state != HUNT_INTENT_NONE:
		events["skip_reason"] = "live_hunt_active"
		return events
	if not claim.get("inventory"):
		events["skip_reason"] = "no_inventory"
		return events
	var inventory: InventoryData = claim.get("inventory") as InventoryData
	if inventory == null:
		events["skip_reason"] = "no_inventory"
		return events
	if int(roster.call("get_population")) <= 0:
		events["skip_reason"] = "empty_roster"
		return events

	var meat_thresh: int = int(WorldGenConfig.abstract_hunt_meat_threshold)
	var meat_count: int = inventory.get_count(ResourceData.ResourceType.MEAT)
	meat_count += inventory.get_count(ResourceData.ResourceType.COOKED_MEAT)
	if meat_count >= meat_thresh:
		events["skip_reason"] = "meat_sufficient"
		return events

	var tree: SceneTree = claim.get_tree()
	if tree == null:
		events["skip_reason"] = "no_scene_tree"
		return events

	var claim_clan: String = str(claim.get("clan_name") if claim.get("clan_name") != null else "")
	var candidates: Array = _collect_huntable_prey(tree, chunk_coords, claim_clan)
	if candidates.is_empty():
		events["skip_reason"] = "no_prey"
		return events

	var prey: Node = _pick_prey(candidates, chunk_coords, claim_clan, meat_count)
	if prey == null or not is_instance_valid(prey):
		events["skip_reason"] = "pick_failed"
		return events

	var prey_type: String = str(prey.get("npc_type") if prey.get("npc_type") != null else "")
	var yields: Dictionary = CorpseConfig.get_yields(prey_type)
	var loot: Dictionary = {"meat": 0, "hide": 0, "bone": 0}
	for key in YIELD_KEY_TO_TYPE.keys():
		var amount: int = int(yields.get(key, 0))
		if amount <= 0:
			continue
		var rt: ResourceData.ResourceType = YIELD_KEY_TO_TYPE.get(key, ResourceData.ResourceType.NONE) as ResourceData.ResourceType
		if rt == ResourceData.ResourceType.NONE:
			continue
		var added: int = _add_loot_to_inventory(inventory, rt, amount)
		loot[key] = added

	var stable_id: String = ""
	if prey.has_meta(&"stable_id"):
		stable_id = str(prey.get_meta(&"stable_id"))
	if MutationStore:
		MutationStore.deplete_node_if_stable(prey)
	prey.queue_free()

	events["hunted"] = true
	events["prey_type"] = prey_type
	events["prey_stable_id"] = stable_id
	events["loot"] = loot
	return events


static func _collect_huntable_prey(tree: SceneTree, chunk_coords: Vector2i, claim_clan: String) -> Array:
	var out: Array = []
	for npc in tree.get_nodes_in_group("npcs"):
		if npc == null or not is_instance_valid(npc):
			continue
		if not (npc is Node2D):
			continue
		var npc_type: String = str(npc.get("npc_type") if npc.get("npc_type") != null else "").to_lower()
		if npc_type not in HUNTABLE_TYPES:
			continue
		if npc.has_method("is_dead") and npc.is_dead():
			continue
		var herded_val = npc.get("is_herded")
		if herded_val == true:
			continue
		var prey_clan: String = str(npc.get("clan_name") if npc.get("clan_name") != null else "")
		if not prey_clan.is_empty() and not claim_clan.is_empty():
			if prey_clan.strip_edges().to_lower() == claim_clan.strip_edges().to_lower():
				continue
		if ChunkUtils:
			var prey_chunk: Vector2i = ChunkUtils.get_chunk_coords((npc as Node2D).global_position)
			if prey_chunk != chunk_coords:
				continue
		out.append(npc)
	return out


static func _pick_prey(candidates: Array, chunk_coords: Vector2i, claim_clan: String, meat_count: int) -> Node:
	if candidates.is_empty():
		return null
	var ws: int = int(WorldGenConfig.world_seed) if WorldGenConfig else 0
	var salt: int = hash("%s|%d,%d|%d|%d" % [claim_clan, chunk_coords.x, chunk_coords.y, meat_count, candidates.size()])
	var rng: RandomNumberGenerator
	if SimRng:
		rng = SimRng.make_scoped_rng(ws, salt)
	else:
		rng = RandomNumberGenerator.new()
		rng.seed = salt
	var idx: int = rng.randi() % candidates.size()
	return candidates[idx] as Node


static func _add_loot_to_inventory(inventory: InventoryData, item_type: ResourceData.ResourceType, amount: int) -> int:
	var added := 0
	for _i in amount:
		if not inventory.has_space() and inventory.get_count(item_type) >= inventory.max_stack:
			break
		inventory.add_item(item_type, 1)
		added += 1
	return added
