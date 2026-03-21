extends "res://scripts/npc/states/base_state.gd"

# Occupy Building State - Women moving to unoccupied buildings
# Priority: 7.5 (below reproduction 8.0, above gathering 3.0)

var target_building: Node = null
var occupation_range: float = 500.0  # Range to find buildings

func enter() -> void:
	target_building = null
	_find_available_building()

func exit() -> void:
	_cancel_tasks_if_active()
	target_building = null

func update(delta: float) -> void:
	if not npc:
		return
	
	# Dead NPCs can't occupy buildings
	if npc.is_dead():
		return
	
	# CRITICAL: Exit immediately if defending or in combat - these take priority
	if _is_defending():
		if fsm:
			fsm.change_state("defend")
		return
	
	if _is_in_combat():
		if fsm:
			fsm.change_state("combat")
		return
	
	# OPTIMIZATION: Tasks are cancelled on enter() - no need to cancel every frame
	# Removed per-frame _cancel_tasks_if_active() call for performance
	
	# If we found a building, move to it
	if target_building and is_instance_valid(target_building):
		var distance: float = npc.global_position.distance_to(target_building.global_position)
		var arrive_distance: float = 18.0  # Walk right up to building before disappearing inside
		
		if distance > arrive_distance:
			# Move to building - override any task movement
			if npc.steering_agent:
				npc.steering_agent.set_arrive_target(target_building.global_position)
		else:
			# Close enough - occupy the building
			_occupy_building()
	else:
		# No building found, try to find one
		_find_available_building()

func can_enter() -> bool:
	# Only women can occupy buildings
	if not npc:
		return false
	
	if npc.get("npc_type") != "woman":
		return false
	
	# Must be in clan
	if npc.is_wild():
		return false
	
	# CRITICAL: Cannot occupy while defending or in combat - these take priority
	if _is_defending():
		return false  # Defending - cannot occupy
	
	if _is_in_combat():
		return false  # In combat - cannot occupy
	
	# CRITICAL: Cannot occupy while following (ordered follow takes priority)
	if _is_following():
		return false  # Following - cannot occupy
	
	# Skip building scan when NPC has no clan (avoids wasted work and log noise)
	var npc_clan_check: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan_check == "":
		return false
	
	# Check if there's an available building to occupy
	return _has_available_building()

func get_priority() -> float:
	return 7.5  # Below reproduction (8.0), above gathering (3.0)

func _find_available_building() -> void:
	if not npc or not OccupationSystem:
		return
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan == "":
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var next_retry: float = npc.get_meta("next_occupation_retry_time", 0.0) as float
	if now < next_retry:
		return
	var result: Dictionary = OccupationSystem.request_slot(npc)
	if result.is_empty():
		npc.set_meta("next_occupation_retry_time", now + 1.5)
		return
	var bld: BuildingBase = result.get("building") as BuildingBase
	if not bld or not is_instance_valid(bld):
		return
	var dist: float = npc.global_position.distance_to(bld.global_position)
	if dist > occupation_range:
		OccupationSystem.unassign(npc, "too_far")
		npc.set_meta("next_occupation_retry_time", now + 1.5)
		return
	target_building = bld
	npc.set_meta("next_occupation_retry_time", now + 1.5)
	OccupationDiagLogger.log("WOMAN_FOUND_BUILDING", {"npc": npc.get("npc_name"), "building": bld.name, "dist": roundf(dist)})

func _has_available_building() -> bool:
	if not npc:
		return false
	
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan == "":
		return false  # Safeguard: can_enter() should have already returned false
	
	# Find all buildings in the "buildings" group
	var buildings = get_tree().get_nodes_in_group("buildings")
	var last_log_key := "occupy_avail_log_%s" % npc.get("npc_name")
	var last_log: float = npc.get_meta(last_log_key, 0.0) as float
	var now := Time.get_ticks_msec() / 1000.0
	var should_log := (now - last_log) > 3.0
	
	for building in buildings:
		if not is_instance_valid(building):
			continue
		
		# Skip LandClaim objects - only check BuildingBase objects
		if not building.has_method("is_occupied"):
			continue
		
		var building_base = building as BuildingBase
		if not building_base:
			continue
		
		var building_clan = building_base.clan_name if building_base.clan_name != null else ""
		if not building_base.requires_woman:
			continue
		if building_clan != npc_clan:
			continue
		
		# Occupiable if active, OR Farm/Dairy with empty animal slots, OR Farm/Dairy with at least one animal
		# OR requires_woman building with empty woman slot (e.g. Oven - woman enters to activate)
		var occupiable: bool = building_base.is_active
		if not occupiable and building_base.building_type in [ResourceData.ResourceType.FARM, ResourceData.ResourceType.DAIRY_FARM]:
			for slot in building_base.animal_slots:
				if slot == null or not is_instance_valid(slot):
					occupiable = true
					break
			if not occupiable:
				for slot in building_base.animal_slots:
					if slot != null and is_instance_valid(slot):
						occupiable = true
						break
		if not occupiable and building_base.requires_woman and not building_base.is_occupied():
			occupiable = true
		if not occupiable:
			if should_log:
				npc.set_meta(last_log_key, now)
				OccupationDiagLogger.log("WOMAN_OCCUPY_FAIL", {"npc": npc.get("npc_name"), "reason": "H2_not_occupiable", "building": building_base.name, "is_active": building_base.is_active, "bt": int(building_base.building_type), "animal_slots": building_base.animal_slots.size()})
			continue
		if building_base.is_occupied():
			if should_log:
				npc.set_meta(last_log_key, now)
				OccupationDiagLogger.log("WOMAN_OCCUPY_FAIL", {"npc": npc.get("npc_name"), "reason": "H5_already_occupied", "building": building_base.name})
			continue
		var distance: float = npc.global_position.distance_to(building_base.global_position)
		if distance > occupation_range:
			if should_log:
				npc.set_meta(last_log_key, now)
				OccupationDiagLogger.log("WOMAN_OCCUPY_FAIL", {"npc": npc.get("npc_name"), "reason": "H4_too_far", "building": building_base.name, "dist": roundf(distance), "range": occupation_range})
			continue
		# Within range - success
		if should_log:
			npc.set_meta(last_log_key, now)
			OccupationDiagLogger.log("WOMAN_OCCUPY_CAN_ENTER", {"npc": npc.get("npc_name"), "building": building_base.name, "dist": roundf(distance)})
		return true
	
	# No building found - log occasionally
	if should_log:
		npc.set_meta(last_log_key, now)
		OccupationDiagLogger.log("WOMAN_OCCUPY_NO_BUILDING", {"npc": npc.get("npc_name"), "buildings_count": buildings.size()})
	return false

func _occupy_building() -> void:
	if not target_building or not is_instance_valid(target_building):
		return
	if not npc:
		return
	var npc_name = npc.get("npc_name") if npc else "unknown"
	if OccupationSystem and OccupationSystem.confirm_arrival(npc):
		OccupationDiagLogger.log("WOMAN_OCCUPIED_BUILDING", {"npc": npc_name, "building": ResourceData.get_resource_name(target_building.building_type), "building_name": target_building.name})
		UnifiedLogger.log("Woman %s occupied building %s" % [npc_name, ResourceData.get_resource_name(target_building.building_type)], UnifiedLogger.Category.BUILDING)
		print("[MONITOR] Woman %s occupied building %s" % [npc_name, ResourceData.get_resource_name(target_building.building_type)])
		
		# Hide woman's sprite (she's inside the building)
		var npc_sprite = npc.get_node_or_null("Sprite")
		if npc_sprite:
			npc_sprite.visible = false
		
		# Clear target so can_enter() will return false for this state
		target_building = null
		
		# Force FSM to re-evaluate states (so it transitions to work_at_building)
		if fsm and fsm.has_method("force_evaluation"):
			fsm.force_evaluation()
	else:
		# Slot taken by another woman - clear target so we retry with a different building (or give up)
		target_building = null
		npc.set_meta("next_occupation_retry_time", Time.get_ticks_msec() / 1000.0 + 1.5)

func get_data() -> Dictionary:
	return {
		"state": "occupy_building",
		"target_building": ResourceData.get_resource_name(target_building.building_type) if target_building and is_instance_valid(target_building) else "none"
	}
