extends "res://scripts/npc/states/base_state.gd"

# Raid State - NPCs participating in a clan raid
# Phase 3 Part C: Pull-based raiding system
#
# Responsibilities:
# - Move toward raid target with group
# - Engage enemies aggressively
# - Break and retreat on panic / losses
#
# ClanBrain decides WHEN to raid
# This state decides HOW to raid moment-to-moment

enum RaidPhase { ASSEMBLING, MOVING, ENGAGING, RETREATING }

var raid_phase: RaidPhase = RaidPhase.ASSEMBLING
var land_claim: Node = null
var clan_brain: RefCounted = null
var assembly_timeout: float = 30.0  # Max time waiting to assemble
var assembly_timer: float = 0.0

func enter() -> void:
	if not npc:
		return
	
	# Task System: Cancel current job when entering raid
	_cancel_tasks_if_active()
	
	# Find our land claim and clan brain
	_find_clan_brain()
	
	if not clan_brain:
		print("⚔️ RAID_STATE: %s cannot raid - no clan brain found" % npc.npc_name)
		if fsm:
			fsm.change_state("wander")
		return
	
	# Join the raid
	if clan_brain.has_method("npc_join_raid"):
		clan_brain.npc_join_raid(npc)
	
	# Set hostile mode for combat
	npc.set("is_hostile", true)
	
	# Start in assembling phase
	raid_phase = RaidPhase.ASSEMBLING
	assembly_timer = 0.0
	
	var npc_name_str: String = npc.get("npc_name") if npc.get("npc_name") != null else str(npc.name)
	print("⚔️ RAID_STATE: %s joined raid (phase: ASSEMBLING)" % npc_name_str)
	var tree = npc.get_tree() if npc else null
	if tree:
		var pi = tree.root.get_node_or_null("PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("raid_joined"):
			pi.raid_joined(npc_name_str, RaidPhase.keys()[raid_phase])

func exit() -> void:
	_cancel_tasks_if_active()
	
	# Leave the raid
	if clan_brain and clan_brain.has_method("npc_leave_raid"):
		clan_brain.npc_leave_raid(npc)
	
	# Clear hostile mode
	if npc:
		npc.set("is_hostile", false)
		npc.remove_meta("raid_joined")
	
	print("⚔️ RAID_STATE: %s left raid" % (npc.npc_name if npc else "NPC"))

func update(delta: float) -> void:
	if not npc:
		return
	
	# CRITICAL: Exit if following - following takes priority
	if _is_following():
		if fsm:
			fsm.change_state("herd")
		return
	
	# Check if raid is still active
	if not clan_brain or not clan_brain.is_raiding():
		print("⚔️ RAID_STATE: %s - raid ended, exiting" % npc.npc_name)
		if fsm:
			fsm.change_state("wander")
		return
	
	# Get raid intent from clan brain
	var raid_intent: Dictionary = clan_brain.get_raid_intent() if clan_brain.has_method("get_raid_intent") else {}
	var raid_state_enum: int = raid_intent.get("state", 0)
	
	# Update phase based on clan brain raid state
	match raid_state_enum:
		0:  # NONE - raid ended
			if fsm:
				fsm.change_state("wander")
			return
		1:  # RECRUITING
			raid_phase = RaidPhase.ASSEMBLING
		2:  # ACTIVE
			if raid_phase == RaidPhase.ASSEMBLING:
				raid_phase = RaidPhase.MOVING
		3:  # RETREATING
			raid_phase = RaidPhase.RETREATING
	
	# Execute current phase
	match raid_phase:
		RaidPhase.ASSEMBLING:
			_update_assembling(delta)
		RaidPhase.MOVING:
			_update_moving(delta)
		RaidPhase.ENGAGING:
			_update_engaging(delta)
		RaidPhase.RETREATING:
			_update_retreating(delta)

func _update_assembling(delta: float) -> void:
	"""Move to rally point and wait for others."""
	assembly_timer += delta
	
	# Timeout - if we can't assemble, exit
	if assembly_timer > assembly_timeout:
		print("⚔️ RAID_STATE: %s - assembly timeout, exiting" % npc.npc_name)
		if fsm:
			fsm.change_state("wander")
		return
	
	# Move to rally point
	var rally_point: Vector2 = clan_brain.get_raid_rally_point() if clan_brain.has_method("get_raid_rally_point") else Vector2.ZERO
	if rally_point != Vector2.ZERO and npc.steering_agent:
		npc.steering_agent.set_target_position(rally_point)
	
	# Check if we've arrived at rally point
	var distance: float = npc.global_position.distance_to(rally_point)
	if distance < 50.0:
		# Wait at rally point - phase will advance when ClanBrain says raid is ACTIVE
		pass

func _update_moving(_delta: float) -> void:
	"""Move toward raid target."""
	var target_pos: Vector2 = clan_brain.get_raid_target_position() if clan_brain.has_method("get_raid_target_position") else Vector2.ZERO
	
	if target_pos == Vector2.ZERO:
		# No target - retreat
		raid_phase = RaidPhase.RETREATING
		return
	
	if npc.steering_agent:
		npc.steering_agent.set_target_position(target_pos)
	
	# Check if we've arrived at target
	var distance: float = npc.global_position.distance_to(target_pos)
	var raid_target = clan_brain.raid_intent.get("target") if clan_brain else null
	var target_radius: float = 400.0
	if raid_target and is_instance_valid(raid_target) and "radius" in raid_target:
		target_radius = raid_target.radius
	
	if distance < target_radius:
		# Arrived at target - start engaging
		raid_phase = RaidPhase.ENGAGING
		print("⚔️ RAID_STATE: %s arrived at target, engaging" % npc.npc_name)

func _update_engaging(_delta: float) -> void:
	"""Engage enemies at the target. Combat state will take over if we find targets."""
	# Look for enemies to fight
	var raid_target = clan_brain.raid_intent.get("target") if clan_brain else null
	if not raid_target or not is_instance_valid(raid_target):
		raid_phase = RaidPhase.RETREATING
		return
	
	var enemy_clan: String = raid_target.get("clan_name") if "clan_name" in raid_target else ""
	
	# Find nearest enemy
	var nearest_enemy: Node = _find_nearest_enemy(enemy_clan, raid_target.global_position, raid_target.radius * 1.5)
	
	if nearest_enemy:
		# Set combat target - FSM will transition to combat state
		npc.set("combat_target", nearest_enemy)
		npc.set("agro_meter", 100.0)
		# Combat state has higher priority (9.0 > 8.5), will take over
	else:
		# No enemies - stay at target or retreat
		var target_pos: Vector2 = raid_target.global_position
		if npc.steering_agent:
			npc.steering_agent.set_target_position(target_pos)

func _update_retreating(_delta: float) -> void:
	"""Return home."""
	if not land_claim or not is_instance_valid(land_claim):
		_find_clan_brain()
	
	if land_claim and is_instance_valid(land_claim):
		var home_pos: Vector2 = land_claim.global_position
		if npc.steering_agent:
			npc.steering_agent.set_target_position(home_pos)
		
		# Check if we're home
		var distance: float = npc.global_position.distance_to(home_pos)
		if distance < land_claim.radius:
			print("⚔️ RAID_STATE: %s returned home, exiting raid" % npc.npc_name)
			if fsm:
				fsm.change_state("wander")
	else:
		# No home - just exit
		if fsm:
			fsm.change_state("wander")

func _find_nearest_enemy(enemy_clan: String, center: Vector2, search_radius: float) -> Node:
	"""Find the nearest enemy NPC of the specified clan."""
	if enemy_clan == "":
		return null
	
	var nearest: Node = null
	var nearest_dist: float = INF
	
	var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
	for other in all_npcs:
		if not is_instance_valid(other):
			continue
		if other == npc:
			continue
		if other.has_method("is_dead") and other.is_dead():
			continue
		
		# Check clan
		var other_clan: String = ""
		if other.has_method("get_clan_name"):
			other_clan = other.get_clan_name()
		else:
			var clan_prop = other.get("clan_name")
			other_clan = clan_prop as String if clan_prop != null else ""
		
		if other_clan != enemy_clan:
			continue
		
		# Check type (only fight cavemen/clansmen)
		var other_type: String = other.get("npc_type") if "npc_type" in other else ""
		if other_type != "caveman" and other_type != "clansman":
			continue
		
		# Check distance to search center
		var dist_to_center: float = other.global_position.distance_to(center)
		if dist_to_center > search_radius:
			continue
		
		var dist: float = npc.global_position.distance_to(other.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	
	return nearest

func _find_clan_brain() -> void:
	"""Find the clan brain for this NPC's clan."""
	land_claim = null
	clan_brain = null
	var claim = npc.get_my_land_claim() if npc and npc.has_method("get_my_land_claim") else null
	if not claim or not is_instance_valid(claim):
		return
	land_claim = claim
	if claim.has_method("get_clan_brain"):
		clan_brain = claim.get_clan_brain()
	elif "clan_brain" in claim:
		clan_brain = claim.clan_brain

func can_enter() -> bool:
	if not npc:
		return false
	# Agro combat test leaders are driven by main — must not join ClanBrain raid
	if npc.has_meta("agro_combat_test_leader"):
		return false
	# Only cavemen and clansmen can raid
	var tp: String = npc.get("npc_type") if npc else ""
	if tp != "caveman" and tp != "clansman":
		return false
	
	# Don't raid while ordered to follow
	if npc.get("follow_is_ordered"):
		return false
	
	# Don't raid if defending (defenders stay home)
	var defend_target = npc.get("defend_target")
	if defend_target and is_instance_valid(defend_target):
		return false
	
	# Find clan brain and check if raid is active
	_find_clan_brain()
	
	if not clan_brain:
		return false
	
	# Check if raid is active and we should join
	if not clan_brain.is_raiding():
		return false
	
	if clan_brain.has_method("should_npc_raid") and not clan_brain.should_npc_raid(npc):
		return false
	
	return true

func get_priority() -> float:
	# Raid priority: 8.5
	# Below combat (9.0) - combat takes over when fighting
	# Above defend (8.0) - raids override normal defense
	return 8.5

func get_data() -> Dictionary:
	return {
		"raid_phase": RaidPhase.keys()[raid_phase],
		"has_clan_brain": clan_brain != null,
		"assembly_timer": assembly_timer
	}
