class_name AbstractSlaughter
extends RefCounted
## Last-resort off-screen slaughter: owned sheep/goats when clan is starving and pantry has no food.

const LIVESTOCK_TYPES: Array[String] = ["sheep", "goat"]

const YIELD_KEY_TO_TYPE: Dictionary = {
	"meat": ResourceData.ResourceType.MEAT,
	"hide": ResourceData.ResourceType.HIDE,
	"bone": ResourceData.ResourceType.BONE,
}

const FOOD_TYPES: Array = [
	ResourceData.ResourceType.COOKED_MEAT,
	ResourceData.ResourceType.BREAD,
	ResourceData.ResourceType.MEAT,
	ResourceData.ResourceType.GRAIN,
	ResourceData.ResourceType.BERRIES,
	ResourceData.ResourceType.MILK,
	ResourceData.ResourceType.MUSHROOM,
	ResourceData.ResourceType.NUTS,
	ResourceData.ResourceType.BUGS,
]


static func slaughter_for_claim(
	claim: Node,
	clan_starving: bool,
	hunt_events: Dictionary,
	inventory: InventoryData
) -> Dictionary:
	var events: Dictionary = {
		"slaughtered": false,
		"animal_type": "",
		"animal_name": "",
		"loot": {"meat": 0, "hide": 0, "bone": 0},
		"skip_reason": "",
	}
	if claim == null or not is_instance_valid(claim) or inventory == null:
		events["skip_reason"] = "invalid_claim"
		return events
	if not clan_starving:
		events["skip_reason"] = "not_starving"
		return events
	if _total_food_count(inventory) > 0:
		events["skip_reason"] = "pantry_has_food"
		return events
	if bool(hunt_events.get("hunted", false)):
		events["skip_reason"] = "hunt_succeeded"
		return events

	var claim_clan: String = str(claim.get("clan_name") if claim.get("clan_name") != null else "")
	var tree: SceneTree = claim.get_tree()
	if tree == null:
		events["skip_reason"] = "no_scene_tree"
		return events

	var candidates: Array = _collect_owned_livestock(tree, claim, claim_clan)
	if candidates.is_empty():
		events["skip_reason"] = "no_owned_livestock"
		return events

	var animal: Node = _pick_livestock(candidates, claim_clan, claim)
	if animal == null or not is_instance_valid(animal):
		events["skip_reason"] = "pick_failed"
		return events

	var animal_type: String = str(animal.get("npc_type") if animal.get("npc_type") != null else "").to_lower()
	var animal_name: String = str(animal.get("npc_name") if animal.get("npc_name") != null else animal_type)
	var yields: Dictionary = CorpseConfig.get_yields(animal_type)
	var loot: Dictionary = {"meat": 0, "hide": 0, "bone": 0}
	for key in YIELD_KEY_TO_TYPE.keys():
		var amount: int = int(yields.get(key, 0))
		if amount <= 0:
			continue
		var rt: ResourceData.ResourceType = YIELD_KEY_TO_TYPE.get(key, ResourceData.ResourceType.NONE) as ResourceData.ResourceType
		if rt == ResourceData.ResourceType.NONE:
			continue
		loot[key] = _add_loot_to_inventory(inventory, rt, amount)

	if OccupationSystem and OccupationSystem.has_ref(animal):
		OccupationSystem.unassign(animal, "starvation_slaughter")

	if MutationStore:
		MutationStore.deplete_node_if_stable(animal)
	animal.queue_free()

	events["slaughtered"] = true
	events["animal_type"] = animal_type
	events["animal_name"] = animal_name
	events["loot"] = loot
	return events


static func _collect_owned_livestock(tree: SceneTree, claim: Node, claim_clan: String) -> Array:
	var out: Array = []
	if claim_clan.is_empty():
		return out
	var claim_pos: Vector2 = Vector2.ZERO
	var claim_radius: float = 400.0
	if claim is Node2D:
		claim_pos = (claim as Node2D).global_position
	if claim.get("radius") != null:
		claim_radius = float(claim.get("radius"))
	for npc in tree.get_nodes_in_group("npcs"):
		if npc == null or not is_instance_valid(npc):
			continue
		if not (npc is Node2D):
			continue
		var npc_type: String = str(npc.get("npc_type") if npc.get("npc_type") != null else "").to_lower()
		if npc_type not in LIVESTOCK_TYPES:
			continue
		if npc.has_method("is_dead") and npc.is_dead():
			continue
		var npc_clan: String = ""
		if npc.has_method("get_clan_name"):
			npc_clan = str(npc.get_clan_name())
		elif npc.get("clan_name") != null:
			npc_clan = str(npc.get("clan_name"))
		if npc_clan.strip_edges().to_lower() != claim_clan.strip_edges().to_lower():
			continue
		if (npc as Node2D).global_position.distance_to(claim_pos) > claim_radius + 80.0:
			continue
		out.append(npc)
	return out


static func _pick_livestock(candidates: Array, claim_clan: String, claim: Node) -> Node:
	if candidates.is_empty():
		return null
	var salt_chunk := Vector2i.ZERO
	if ChunkUtils and claim is Node2D:
		salt_chunk = ChunkUtils.get_chunk_coords((claim as Node2D).global_position)
	var ws: int = int(WorldGenConfig.world_seed) if WorldGenConfig else 0
	var salt: int = hash("%s|slaughter|%d,%d|%d" % [claim_clan, salt_chunk.x, salt_chunk.y, candidates.size()])
	var rng: RandomNumberGenerator
	if SimRng:
		rng = SimRng.make_scoped_rng(ws, salt)
	else:
		rng = RandomNumberGenerator.new()
		rng.seed = salt
	return candidates[rng.randi() % candidates.size()] as Node


static func _total_food_count(inventory: InventoryData) -> int:
	var total := 0
	for ft in FOOD_TYPES:
		total += inventory.get_count(ft)
	return total


static func _add_loot_to_inventory(inventory: InventoryData, item_type: ResourceData.ResourceType, amount: int) -> int:
	var added := 0
	for _i in amount:
		if not inventory.has_space() and inventory.get_count(item_type) >= inventory.max_stack:
			break
		inventory.add_item(item_type, 1)
		added += 1
	return added
