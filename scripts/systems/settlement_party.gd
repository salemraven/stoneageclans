class_name SettlementParty
extends RefCounted
## A hunt or raid that has left the claim. The record stays home. Bodies are only the view.

const MARCH_PX_PER_SEC := 120.0
const CHUNK_PX := 2048.0


static func home_fighter_count(roster: RefCounted) -> int:
	if roster == null:
		return 0
	var count := 0
	for m in roster.get("members"):
		if not (m is Dictionary):
			continue
		var rec: Dictionary = m as Dictionary
		if not bool(rec.get("alive", false)) or bool(rec.get("away", false)):
			continue
		var kind: String = str(rec.get("type", ""))
		if kind in ["clansman", "caveman", "leader"]:
			count += 1
	return count


static func mark_away(roster: RefCounted, member_ids: Array, away: bool) -> void:
	if roster == null:
		return
	for mid in member_ids:
		var rec: Dictionary = roster.find_member(int(mid))
		if rec.is_empty():
			continue
		rec["away"] = away


static func should_spawn_at_claim(rec: Dictionary) -> bool:
	return bool(rec.get("alive", false)) and not bool(rec.get("away", false))


static func write_back_keeps_away(roster: RefCounted, member_ids: Array) -> void:
	mark_away(roster, member_ids, true)


## Unwatched scout: one gather from his chunk into the pantry, then he is home.
## A second call deposits nothing. The live pack is cleared so waking cannot deposit it again.
static func resolve_unwatched_trip(claim: Node, roster: RefCounted, member_id: int, chunk: Vector2i, worker: Node = null) -> int:
	if claim == null or roster == null:
		return 0
	var done: Dictionary = {}
	if claim.has_meta("away_trip_resolved"):
		var stored: Variant = claim.get_meta("away_trip_resolved")
		if stored is Dictionary:
			done = stored
	if done.has(member_id):
		return 0
	var rec: Dictionary = roster.find_member(member_id)
	if rec.is_empty() or not bool(rec.get("away", false)):
		return 0
	var taken: int = 0
	var added_type: int = ResourceData.ResourceType.BERRIES
	if MutationStore:
		var keys: Array[String] = ["berries", "grain", "nuts", "bugs"]
		var types: Array[int] = [
			ResourceData.ResourceType.BERRIES,
			ResourceData.ResourceType.GRAIN,
			ResourceData.ResourceType.NUTS,
			ResourceData.ResourceType.BUGS,
		]
		for i in keys.size():
			var n: int = int(MutationStore.deplete_abstract_resource(chunk, keys[i], 1))
			if n > 0:
				taken = n
				added_type = types[i]
				break
	var inv: Variant = claim.get("inventory")
	if taken > 0 and inv and inv.has_method("add_item"):
		inv.add_item(added_type, taken)
	done[member_id] = true
	claim.set_meta("away_trip_resolved", done)
	mark_away(roster, [member_id], false)
	if claim.has_meta("away_trip_chunks"):
		var blocked: Variant = claim.get_meta("away_trip_chunks")
		if blocked is Array:
			(blocked as Array).erase(chunk)
			claim.set_meta("away_trip_chunks", blocked)
	if worker != null and is_instance_valid(worker):
		_clear_worker_pack(worker)
	return taken


static func _clear_worker_pack(worker: Node) -> void:
	var inv: Variant = worker.get("inventory")
	if inv == null or not inv.has_method("remove_item") or not inv.has_method("get_count"):
		return
	var types: Array[int] = [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.GRAIN,
		ResourceData.ResourceType.NUTS,
		ResourceData.ResourceType.BUGS,
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.FIBER,
		ResourceData.ResourceType.MEAT,
	]
	for item_type in types:
		var count: int = int(inv.get_count(item_type))
		if count > 0:
			inv.remove_item(item_type, count)


static func begin_hunt(roster: RefCounted, home_chunk: Vector2i, inventory: InventoryData, active: Dictionary = {}) -> Dictionary:
	if roster == null or MutationStore == null:
		return {}
	if not active.is_empty() and str(active.get("phase", "")) != "done":
		return {}
	var fighter_ids: Array = _home_fighter_ids(roster)
	if fighter_ids.size() < 2:
		return {}
	var target := home_chunk
	var travel := 0.0
	if MutationStore.get_wildlife(home_chunk) <= 0:
		var found := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var coords := home_chunk + Vector2i(dx, dy)
				if MutationStore.get_wildlife(coords) <= 0:
					continue
				target = coords
				travel = Vector2(dx, dy).length() * CHUNK_PX / MARCH_PX_PER_SEC
				found = true
				break
			if found:
				break
		if not found:
			return {}
	var sent: Array = [fighter_ids[0], fighter_ids[1]]
	var bundle := _take_bundle(inventory, sent.size())
	mark_away(roster, sent, true)
	return {
		"kind": "hunt",
		"phase": "out",
		"member_ids": sent,
		"target_chunk": target,
		"travel_left": travel,
		"travel_total": travel,
		"bundle": bundle,
		"bundle_start": bundle,
		"resolved": false,
		"materialized": false,
	}


static func advance(token: Dictionary, roster: RefCounted, inventory: InventoryData, elapsed: float, watching: bool) -> void:
	if token.is_empty():
		return
	if watching:
		token["materialized"] = true
		return
	if bool(token.get("materialized", false)) or bool(token.get("resolved", false)) and str(token.get("phase", "")) == "done":
		return
	if int(token.get("bundle_start", 0)) > 0:
		token["bundle"] = maxi(int(token.get("bundle", 0)) - 1, 0)
		if int(token.get("bundle", 0)) <= 0 and str(token.get("phase", "")) == "out":
			token["phase"] = "back"
			token["travel_left"] = float(token.get("travel_total", 0.0))
	var left: float = float(token.get("travel_left", 0.0)) - elapsed
	token["travel_left"] = left
	if left > 0.0:
		return
	if str(token.get("phase", "")) == "out":
		if str(token.get("kind", "")) == "hunt":
			_resolve_hunt(token, inventory)
		token["phase"] = "back"
		token["travel_left"] = float(token.get("travel_total", 0.0))
		if float(token.get("travel_left", 0.0)) <= 0.0:
			_finish_party(token, roster)
		return
	_finish_party(token, roster)


static func resolve_food_once(attacker: InventoryData, defender: InventoryData, token: Dictionary) -> int:
	if attacker == null or defender == null or token.is_empty():
		return 0
	if bool(token.get("resolved", false)) or bool(token.get("materialized", false)):
		return 0
	var moved := 0
	var edible: Array = [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.GRAIN,
		ResourceData.ResourceType.MEAT,
		ResourceData.ResourceType.BREAD,
	]
	while moved < 8:
		var took := false
		for rt in edible:
			var food_type: ResourceData.ResourceType = rt
			if defender.get_count(food_type) <= 0:
				continue
			if not attacker.has_space() and attacker.get_count(food_type) >= attacker.max_stack:
				continue
			defender.remove_item(food_type, 1)
			attacker.add_item(food_type, 1)
			moved += 1
			took = true
			break
		if not took:
			break
	token["resolved"] = true
	token["phase"] = "back"
	return moved


static func _resolve_hunt(token: Dictionary, inventory: InventoryData) -> void:
	if bool(token.get("resolved", false)):
		return
	var chunk: Vector2i = token.get("target_chunk", Vector2i.ZERO)
	if MutationStore.take_wildlife(chunk, 1) <= 0:
		token["resolved"] = true
		return
	var yields: Dictionary = {}
	if CorpseConfig:
		yields = CorpseConfig.get_yields("deer")
	var meat: int = int(yields.get("meat", 2))
	var hide: int = int(yields.get("hide", 0))
	if inventory:
		for _i in maxi(meat, 0):
			inventory.add_item(ResourceData.ResourceType.MEAT, 1)
		for _i in maxi(hide, 0):
			inventory.add_item(ResourceData.ResourceType.HIDE, 1)
	token["resolved"] = true
	token["meat"] = meat


static func _finish_party(token: Dictionary, roster: RefCounted) -> void:
	mark_away(roster, token.get("member_ids", []), false)
	token["phase"] = "done"
	token["away"] = false


static func _home_fighter_ids(roster: RefCounted) -> Array:
	var ids: Array = []
	for m in roster.get("members"):
		if not (m is Dictionary):
			continue
		var rec: Dictionary = m as Dictionary
		if not bool(rec.get("alive", false)) or bool(rec.get("away", false)):
			continue
		if str(rec.get("type", "")) in ["clansman", "caveman", "leader"]:
			ids.append(int(rec.get("id", 0)))
	return ids


static func _take_bundle(inventory: InventoryData, people: int) -> int:
	if inventory == null or people <= 0:
		return 0
	var taken := 0
	while taken < people and inventory.get_count(ResourceData.ResourceType.BERRIES) > 0:
		inventory.remove_item(ResourceData.ResourceType.BERRIES, 1)
		taken += 1
	return taken
