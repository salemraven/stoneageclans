class_name AbstractGather
extends RefCounted
## Off-screen biome-aware gathering with chunk pool depletion (Settlement Sim Phase 3).

const ChunkGeneratorScript = preload("res://scripts/world/chunk_generator.gd")
const TerrainQueryScript = preload("res://scripts/world/terrain_query.gd")
const EDIBLE_KEYS: Array[String] = ["berries", "grain", "nuts", "bugs"]
const OTHER_KEYS: Array[String] = ["wood", "stone", "fiber", "hide"]

const RESOURCE_KEY_TO_TYPE: Dictionary = {
	"wood": ResourceData.ResourceType.WOOD,
	"stone": ResourceData.ResourceType.STONE,
	"berries": ResourceData.ResourceType.BERRIES,
	"grain": ResourceData.ResourceType.GRAIN,
	"fiber": ResourceData.ResourceType.FIBER,
	"nuts": ResourceData.ResourceType.NUTS,
	"bugs": ResourceData.ResourceType.BUGS,
}


static func ring_chunks(home: Vector2i) -> Array:
	var out: Array = [home]
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var coords := home + Vector2i(dx, dy)
			if coords != home:
				out.append(coords)
	return out


static func home_worker_count(roster: RefCounted) -> int:
	if roster == null:
		return 0
	var count := 0
	for m in roster.get("members"):
		if not (m is Dictionary):
			continue
		var rec: Dictionary = m as Dictionary
		if not bool(rec.get("alive", false)):
			continue
		if bool(rec.get("away", false)):
			continue
		var kind: String = str(rec.get("type", ""))
		if kind in ["woman", "clansman", "caveman", "leader"]:
			count += 1
	return count


static func gather_for_claim(
	claim: Node,
	roster: RefCounted,
	chunk_coords: Vector2i,
	elapsed_sec: float,
	clan_starving: bool = false,
	slice_id: int = -1
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
	var ring: Array = ring_chunks(chunk_coords)
	var regen_all: Array = []
	for ring_chunk in ring:
		var coords: Vector2i = ring_chunk as Vector2i
		MutationStore.ensure_abstract_resource_pool(coords, world_seed, WorldGenConfig)
		var regen_events: Dictionary = MutationStore.regen_abstract_resources(
			coords, elapsed_sec, WorldGenConfig, slice_id
		)
		for row in regen_events.get("regen", []):
			regen_all.append(row)
	if not regen_all.is_empty():
		events["regen"] = regen_all

	var workers: int = home_worker_count(roster)
	if workers <= 0:
		return events

	var worker_units: float = float(workers) * float(WorldGenConfig.gather_population_efficiency)
	if clan_starving:
		worker_units *= float(WorldGenConfig.gather_starvation_penalty)
	worker_units = maxf(worker_units, 0.0)

	var tick_interval: float = maxf(float(WorldGenConfig.settlement_tick_interval_sec), 1.0)
	var tick_fraction: float = elapsed_sec / tick_interval

	var carry_bonus: int = _consume_gather_carryover(claim)
	if carry_bonus > 0:
		_apply_carry_bonus(inventory, available, carry_bonus, events)

	var ordered: Array[String] = []
	ordered.append_array(EDIBLE_KEYS)
	ordered.append_array(OTHER_KEYS)
	for resource_key in ordered:
		if resource_key.is_empty():
			continue
		var yield_cfg: float = float(WorldGenConfig.gather_yield_per_population.get(resource_key, 0.0))
		if yield_cfg <= 0.0:
			continue
		var desired: int = int(floor(worker_units * yield_cfg * tick_fraction))
		if desired <= 0:
			continue
		var rt: ResourceData.ResourceType = RESOURCE_KEY_TO_TYPE.get(resource_key, ResourceData.ResourceType.NONE) as ResourceData.ResourceType
		if rt == ResourceData.ResourceType.NONE:
			continue
		var gathered: int = 0
		var last_remaining := 0
		var last_chunk := chunk_coords
		for ring_chunk in ring:
			if desired <= 0:
				break
			var coords: Vector2i = ring_chunk as Vector2i
			if _away_trip_blocks(claim, coords):
				continue
			var chunk_keys: Array = _available_keys(world_seed, coords)
			if resource_key not in chunk_keys:
				continue
			var remaining_pool: int = MutationStore.get_abstract_resource_remaining(coords, resource_key)
			if remaining_pool <= 0:
				continue
			while desired > 0 and remaining_pool > 0:
				if not inventory.has_space() and inventory.get_count(rt) >= inventory.max_stack:
					desired = 0
					break
				var taken: int = MutationStore.deplete_abstract_resource(coords, resource_key, 1)
				if taken <= 0:
					break
				inventory.add_item(rt, 1)
				gathered += 1
				remaining_pool -= 1
				desired -= 1
			last_remaining = remaining_pool
			last_chunk = coords
		if gathered > 0:
			events["gathered"].append({
				"resource_key": resource_key,
				"item_type": int(rt),
				"count": gathered,
			})
			events["depleted"].append({
				"resource_key": resource_key,
				"remaining": last_remaining,
				"chunk_x": last_chunk.x,
				"chunk_y": last_chunk.y,
			})
	return events


static func _away_trip_blocks(claim: Node, coords: Vector2i) -> bool:
	if claim == null or not claim.has_meta("away_trip_chunks"):
		return false
	var raw: Variant = claim.get_meta("away_trip_chunks")
	if not (raw is Array):
		return false
	for item in raw as Array:
		if item is Vector2i and (item as Vector2i) == coords:
			return true
	return false


static func _available_keys(world_seed: int, chunk_coords: Vector2i) -> Array:
	var tq: Node = _get_terrain_query()
	if tq and tq.is_authored():
		return tq.get_biome_available_resources(world_seed, chunk_coords, WorldGenConfig) as Array
	var gen := ChunkGeneratorScript.new()
	return gen.call("get_biome_available_resources", world_seed, chunk_coords, WorldGenConfig) as Array


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
