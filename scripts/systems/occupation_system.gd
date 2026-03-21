extends Node
# OccupationSystem - Single authority for building occupation (women, animals).
# All occupation changes go through this system. No direct building slot mutation from clients.

enum OccupationState { NONE, RESERVED, OCCUPIED }

# Per-NPC assignment: npc -> { building, slot_index, slot_type, state }
var _npc_to_ref: Dictionary = {}

signal occupation_reserved(npc: Node, building: Node)
signal occupation_confirmed(npc: Node, building: Node)
signal occupation_cleared(npc: Node, building: Node, reason: String)


func _ready() -> void:
	add_to_group("occupation_system")


func request_slot(npc: Node) -> Dictionary:
	"""Request a slot for this NPC. Returns { building, slot_index, slot_type } or empty dict.
	Sets state to RESERVED. NPC must call confirm_arrival when they arrive."""
	if not npc or not is_instance_valid(npc):
		return {}
	# Skip if already assigned
	if _npc_to_ref.has(npc):
		var ref = _npc_to_ref[npc]
		if ref.state == OccupationState.RESERVED or ref.state == OccupationState.OCCUPIED:
			return { "building": ref.building, "slot_index": ref.slot_index, "slot_type": ref.slot_type }
	# Skip cooldown (e.g. after drag removal)
	var now := Time.get_ticks_msec() / 1000.0
	var cooldown: float = npc.get_meta("occupation_cooldown_until", 0.0) as float
	if cooldown > now:
		return {}
	var npc_type: String = npc.get("npc_type") as String if npc.get("npc_type") != null else ""
	var clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.get("clan_name") as String if npc.get("clan_name") != null else "")
	if clan.is_empty():
		return {}
	if npc_type == "sheep" or npc_type == "goat":
		return _request_slot_animal(npc, npc_type, clan)
	elif npc_type == "woman":
		return _request_slot_woman(npc, clan)
	return {}


func _request_slot_animal(npc: Node, npc_type: String, clan: String) -> Dictionary:
	var want_type := "sheep" if npc_type == "sheep" else "goat"
	var land_claims := _get_tree().get_nodes_in_group("land_claims")
	var my_claim: Node = null
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan: String = claim.get("clan_name") if claim.get("clan_name") != null else ""
		if claim_clan == clan:
			my_claim = claim
			break
	if not my_claim:
		return {}
	var buildings: Array = []
	if ClaimBuildingIndex:
		buildings = ClaimBuildingIndex.get_buildings_in_claim(my_claim)
	var nearest_building: BuildingBase = null
	var nearest_slot: int = -1
	var nearest_dist: float = 1e9
	for b in buildings:
		if not is_instance_valid(b) or not (b is BuildingBase):
			continue
		var building: BuildingBase = b as BuildingBase
		var want := building.get_animal_type_for_building()
		if want != want_type:
			continue
		# Skip if NPC already in this building
		for i in building.animal_slots.size():
			if building.animal_slots[i] == npc:
				return {}
		# Find empty or unreserved slot
		for i in building.animal_slots.size():
			if building.animal_slots[i] != null and is_instance_valid(building.animal_slots[i]):
				continue
			var reserved = building.animal_slot_reserved_by[i] if i < building.animal_slot_reserved_by.size() else null
			if reserved != null and reserved != npc:
				continue
			var dist: float = npc.global_position.distance_to(building.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_building = building
				nearest_slot = i
				break
	if not nearest_building or nearest_slot < 0:
		return {}
	# Reserve the slot
	if not nearest_building.reserve_slot(nearest_slot, false, npc):
		if OccupationDiagLogger and OccupationDiagLogger.enabled:
			OccupationDiagLogger.log("REQUEST_SLOT_DENIED", {"npc": npc.get("npc_name") if npc else "?", "type": npc_type, "reason": "reserve_failed", "building": nearest_building.name})
		return {}
	_npc_to_ref[npc] = {
		"building": nearest_building,
		"slot_index": nearest_slot,
		"slot_type": "animal",
		"state": OccupationState.RESERVED
	}
	occupation_reserved.emit(npc, nearest_building)
	if OccupationDiagLogger and OccupationDiagLogger.enabled:
		OccupationDiagLogger.log("REQUEST_SLOT_GRANTED", {"npc": npc.get("npc_name") if npc else "?", "type": npc_type, "building": nearest_building.name, "slot": nearest_slot, "state": "RESERVED"})
	return { "building": nearest_building, "slot_index": nearest_slot, "slot_type": "animal" }


func _request_slot_woman(npc: Node, clan: String) -> Dictionary:
	var buildings := _get_tree().get_nodes_in_group("buildings")
	var best_building: BuildingBase = null
	var best_slot: int = -1
	for b in buildings:
		if not is_instance_valid(b) or not (b is BuildingBase):
			continue
		var building: BuildingBase = b as BuildingBase
		if not building.requires_woman:
			continue
		if building.clan_name != clan:
			continue
		var occupiable := building.is_active
		if not occupiable and building.building_type in [ResourceData.ResourceType.FARM, ResourceData.ResourceType.DAIRY_FARM]:
			if building.has_animal_type(building.get_animal_type_for_building()):
				occupiable = true
		# Oven and other requires_woman buildings: allow woman to enter when empty (she will activate on arrival)
		if not occupiable and building.requires_woman and not building.is_occupied():
			occupiable = true
		if not occupiable:
			continue
		if building.is_occupied():
			continue
		for i in building.woman_slots.size():
			if building.woman_slots[i] != null and is_instance_valid(building.woman_slots[i]):
				continue
			# Skip if another NPC has already RESERVED this slot
			if _is_woman_slot_reserved(building, i, npc):
				continue
			best_building = building
			best_slot = i
			break
		if best_building:
			break
	if not best_building or best_slot < 0:
		return {}
	# Reserve (woman slots don't use reserved_by array in current design - we just hold the ref)
	_npc_to_ref[npc] = {
		"building": best_building,
		"slot_index": best_slot,
		"slot_type": "woman",
		"state": OccupationState.RESERVED
	}
	occupation_reserved.emit(npc, best_building)
	if OccupationDiagLogger and OccupationDiagLogger.enabled:
		OccupationDiagLogger.log("REQUEST_SLOT_GRANTED", {"npc": npc.get("npc_name") if npc else "?", "type": "woman", "building": best_building.name, "slot": best_slot, "state": "RESERVED"})
	return { "building": best_building, "slot_index": best_slot, "slot_type": "woman" }


func confirm_arrival(npc: Node) -> bool:
	"""Convert RESERVED to OCCUPIED. Call when NPC reaches building."""
	if not npc or not _npc_to_ref.has(npc):
		return false
	var ref = _npc_to_ref[npc]
	if ref.state != OccupationState.RESERVED:
		return false
	var building: BuildingBase = ref.building
	if not is_instance_valid(building):
		unassign(npc, "invalid_building")
		return false
	# Woman slot race: another woman may have won; check before overwriting
	if ref.slot_type == "woman":
		var current = building.woman_slots[ref.slot_index] if ref.slot_index < building.woman_slots.size() else null
		if current != null and is_instance_valid(current) and current != npc:
			unassign(npc, "slot_taken")
			return false
	ref.state = OccupationState.OCCUPIED
	if ref.slot_type == "animal":
		building.set_occupant(ref.slot_index, npc, false)
		building.unreserve_slot(ref.slot_index, false)
	else:
		building.set_occupant(ref.slot_index, npc, true)
	occupation_confirmed.emit(npc, building)
	if OccupationDiagLogger and OccupationDiagLogger.enabled:
		OccupationDiagLogger.log("CONFIRM_ARRIVAL", {"npc": npc.get("npc_name") if npc else "?", "type": ref.slot_type, "building": building.name, "slot": ref.slot_index, "state": "OCCUPIED"})
	return true


func unassign(npc: Node, reason: String = "") -> void:
	"""Clear NPC's assignment (occupant or reserved)."""
	if not npc:
		return
	if not _npc_to_ref.has(npc):
		return
	var ref = _npc_to_ref[npc]
	var building: BuildingBase = ref.building
	_npc_to_ref.erase(npc)
	npc.set("workplace_building", null)
	if building and is_instance_valid(building):
		if ref.state == OccupationState.OCCUPIED:
			building.clear_occupant_for_npc(npc)
		elif ref.state == OccupationState.RESERVED and ref.slot_type == "animal":
			building.unreserve_slot(ref.slot_index, false)
	occupation_cleared.emit(npc, building, reason)
	if OccupationDiagLogger and OccupationDiagLogger.enabled:
		OccupationDiagLogger.log("UNASSIGN", {"npc": npc.get("npc_name") if npc else "?", "reason": reason, "building": building.name if building else "?", "had_state": "RESERVED" if ref.state == OccupationState.RESERVED else "OCCUPIED"})
	if reason == "player_drag":
		npc.set_meta("occupation_cooldown_until", Time.get_ticks_msec() / 1000.0 + 5.0)


func force_assign(npc: Node, building: BuildingBase, slot_index: int, slot_type: String) -> bool:
	"""Immediate assign (for UI manual drop). Unassigns previous, then reserves and confirms."""
	if not npc or not building or not is_instance_valid(building):
		return false
	unassign(npc, "force_assign_replace")
	var slots = building.woman_slots if slot_type == "woman" else building.animal_slots
	if slot_index < slots.size():
		var current = slots[slot_index]
		if current != null and is_instance_valid(current) and current != npc:
			unassign(current, "force_assign_replace")
	# Reserve and confirm in one step
	if slot_type == "animal":
		if not building.reserve_slot(slot_index, false, npc):
			return false
	_npc_to_ref[npc] = {
		"building": building,
		"slot_index": slot_index,
		"slot_type": slot_type,
		"state": OccupationState.OCCUPIED
	}
	npc.set("workplace_building", building)
	if slot_type == "animal":
		building.set_occupant(slot_index, npc, false)
		building.unreserve_slot(slot_index, false)
	else:
		building.set_occupant(slot_index, npc, true)
	occupation_confirmed.emit(npc, building)
	if OccupationDiagLogger and OccupationDiagLogger.enabled:
		OccupationDiagLogger.log("FORCE_ASSIGN", {"npc": npc.get("npc_name") if npc else "?", "type": slot_type, "building": building.name, "slot": slot_index, "state": "OCCUPIED"})
	return true


func _is_woman_slot_reserved(building: BuildingBase, slot_index: int, exclude_npc: Node) -> bool:
	"""True if another NPC (not exclude_npc) has RESERVED this woman slot."""
	for other_npc in _npc_to_ref:
		if other_npc == exclude_npc:
			continue
		var ref = _npc_to_ref[other_npc]
		if ref.state != OccupationState.RESERVED or ref.slot_type != "woman":
			continue
		if ref.building == building and ref.slot_index == slot_index:
			return true
	return false

func get_workplace(npc: Node) -> Node2D:
	"""Return the building this NPC is assigned to, or null."""
	if not npc or not _npc_to_ref.has(npc):
		return null
	var ref = _npc_to_ref[npc]
	var b = ref.building
	if not is_instance_valid(b):
		_npc_to_ref.erase(npc)
		return null
	return b as Node2D


func notify_building_destroyed(building: BuildingBase) -> void:
	"""Call before building queue_free. Unassigns all occupants."""
	if not building:
		return
	var to_unassign: Array = []
	for npc in _npc_to_ref:
		var ref = _npc_to_ref[npc]
		if ref.building == building:
			to_unassign.append(npc)
	if OccupationDiagLogger and OccupationDiagLogger.enabled:
		OccupationDiagLogger.log("BUILDING_DESTROYED", {"building": building.name, "unassign_count": to_unassign.size()})
	for npc in to_unassign:
		unassign(npc, "building_destroyed")


func has_ref(npc: Node) -> bool:
	return npc != null and _npc_to_ref.has(npc)


func get_ref_state(npc: Node) -> int:
	if not _npc_to_ref.has(npc):
		return OccupationState.NONE
	return _npc_to_ref[npc].state


func get_diagnostic_summary() -> Array[String]:
	"""For OccupationDiagLogger snapshot - list all NPC assignments."""
	var lines: Array[String] = []
	for npc in _npc_to_ref:
		if not is_instance_valid(npc):
			lines.append("  [invalid_npc]")
			continue
		var ref = _npc_to_ref[npc]
		var b: BuildingBase = ref.building
		var state_str: String = "RESERVED" if ref.state == OccupationState.RESERVED else "OCCUPIED"
		var npc_name: String = npc.get("npc_name") as String if npc.get("npc_name") != null else "?"
		var b_name: String = b.name if b and is_instance_valid(b) else "?"
		lines.append("  %s -> %s slot=%d %s" % [npc_name, b_name, ref.slot_index, state_str])
	return lines


func _get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree
