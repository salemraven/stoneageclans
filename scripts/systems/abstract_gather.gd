class_name AbstractGather
extends RefCounted
## Off-screen biome-aware gathering with chunk pool depletion (Settlement Sim Phase 3).

const ChunkGeneratorScript = preload("res://scripts/world/chunk_generator.gd")
const TerrainQueryScript = preload("res://scripts/world/terrain_query.gd")
const RESOURCE_KEY_TO_TYPE: Dictionary = {
	"wood": ResourceData.ResourceType.WOOD,
	"stone": ResourceData.ResourceType.STONE,
	"berries": ResourceData.ResourceType.BERRIES,
	"grain": ResourceData.ResourceType.GRAIN,
	"fiber": ResourceData.ResourceType.FIBER,
	"nuts": ResourceData.ResourceType.NUTS,
	"bugs": ResourceData.ResourceType.BUGS,
}


static func gather_for_claim(
	claim: Node,
	roster: RefCounted,
	chunk_coords: Vector2i,
	elapsed_sec: float,
	clan_starving: bool = false
) -> Dictionary:
	var events: Dictionary = {
		"gathered": [],
		"depleted": [],
		"biome": "",
	}
	if claim == null or not is_instance_valid(claim) or roster == null:
		return events
	if not claim.get("inventory"):
		return events
	var inventory: InventoryData = claim.get("inventory") as InventoryData
	if inventory == null:
		return events
	if MutationStore == null or WorldGenConfig == null:
		return events

	var world_seed: int = int(WorldGenConfig.world_seed)
	var biome: String
	var available: Array
	var tq: Node = _get_terrain_query()
	if tq and tq.is_authored():
		biome = tq.get_chunk_biome(world_seed, chunk_coords, WorldGenConfig)
		available = tq.get_biome_available_resources(world_seed, chunk_coords, WorldGenConfig) as Array
	else:
		var gen := ChunkGeneratorScript.new()
		biome = str(gen.call("get_chunk_biome", world_seed, chunk_coords, WorldGenConfig))
		available = gen.call("get_biome_available_resources", world_seed, chunk_coords, WorldGenConfig) as Array
	events["biome"] = biome
	if available.is_empty():
		return events

	MutationStore.ensure_abstract_resource_pool(chunk_coords, world_seed, WorldGenConfig)
	var regen_events: Dictionary = MutationStore.regen_abstract_resources(
		chunk_coords, elapsed_sec, WorldGenConfig
	)
	if not regen_events.get("regen", []).is_empty():
		events["regen"] = regen_events.get("regen", [])

	var pop: int = int(roster.call("get_population"))
	if pop <= 0:
		return events

	var worker_units: float = float(pop) * float(WorldGenConfig.gather_population_efficiency)
	if clan_starving:
		worker_units *= float(WorldGenConfig.gather_starvation_penalty)
	worker_units = maxf(worker_units, 0.0)

	var tick_interval: float = maxf(float(WorldGenConfig.settlement_tick_interval_sec), 1.0)
	var tick_fraction: float = elapsed_sec / tick_interval

	var carry_bonus: int = _consume_gather_carryover(claim)
	if carry_bonus > 0:
		_apply_carry_bonus(inventory, available, carry_bonus, events)

	for key_val in available:
		var resource_key: String = str(key_val)
		if resource_key.is_empty():
			continue
		var yield_cfg: float = float(WorldGenConfig.gather_yield_per_population.get(resource_key, 0.0))
		if yield_cfg <= 0.0:
			continue
		var desired: int = int(floor(worker_units * yield_cfg * tick_fraction))
		if desired <= 0:
			continue
		var remaining_pool: int = MutationStore.get_abstract_resource_remaining(chunk_coords, resource_key)
		if remaining_pool <= 0:
			continue
		var rt: ResourceData.ResourceType = RESOURCE_KEY_TO_TYPE.get(resource_key, ResourceData.ResourceType.NONE) as ResourceData.ResourceType
		if rt == ResourceData.ResourceType.NONE:
			continue
		var gathered: int = 0
		for _i in desired:
			if remaining_pool <= 0:
				break
			if not inventory.has_space() and inventory.get_count(rt) >= inventory.max_stack:
				break
			var taken: int = MutationStore.deplete_abstract_resource(chunk_coords, resource_key, 1)
			if taken <= 0:
				break
			inventory.add_item(rt, 1)
			gathered += 1
			remaining_pool -= 1
		if gathered > 0:
			events["gathered"].append({
				"resource_key": resource_key,
				"item_type": int(rt),
				"count": gathered,
			})
			events["depleted"].append({
				"resource_key": resource_key,
				"remaining": remaining_pool,
				"chunk_x": chunk_coords.x,
				"chunk_y": chunk_coords.y,
			})
	return events


static func snapshot_gather_carryover(claim: Node, npcs: Array) -> void:
	if claim == null or not is_instance_valid(claim):
		return
	var bonus: int = 0
	for npc in npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		var fsm = npc.get("fsm") if npc.get("fsm") != null else null
		if fsm == null:
			continue
		var state_name: String = str(fsm.get("current_state_name") if fsm.get("current_state_name") != null else "")
		if state_name == "gather":
			bonus += 1
	if bonus > 0:
		claim.set_meta("settlement_gather_carryover", bonus)
	else:
		if claim.has_meta("settlement_gather_carryover"):
			claim.remove_meta("settlement_gather_carryover")


static func _consume_gather_carryover(claim: Node) -> int:
	if claim == null or not claim.has_meta("settlement_gather_carryover"):
		return 0
	var bonus: int = int(claim.get_meta("settlement_gather_carryover"))
	claim.remove_meta("settlement_gather_carryover")
	return maxi(bonus, 0)


static func _apply_carry_bonus(inventory: InventoryData, available: Array, bonus: int, events: Dictionary) -> void:
	if bonus <= 0 or inventory == null:
		return
	var key: String = str(available[0]) if available.size() > 0 else "berries"
	var rt: ResourceData.ResourceType = RESOURCE_KEY_TO_TYPE.get(key, ResourceData.ResourceType.BERRIES) as ResourceData.ResourceType
	if rt == ResourceData.ResourceType.NONE:
		return
	var added: int = 0
	for _i in bonus:
		if not inventory.has_space() and inventory.get_count(rt) >= inventory.max_stack:
			break
		inventory.add_item(rt, 1)
		added += 1
	if added > 0:
		events["gathered"].append({
			"resource_key": key,
			"item_type": int(rt),
			"count": added,
			"carryover": true,
		})


static func _get_terrain_query() -> Node:
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	return (tree as SceneTree).root.get_node_or_null("/root/TerrainQuery")
