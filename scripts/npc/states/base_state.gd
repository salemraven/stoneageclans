extends Node
class_name BaseState

# Base class for all FSM states
# All states should extend this

var npc: Node = null
var fsm: Node = null

func initialize(npc_ref: Node) -> void:
	npc = npc_ref
	# Safely get FSM reference
	# Directly access fsm property if it exists (it's set in npc_base.gd)
	if npc:
		# Try to get the fsm property directly
		var fsm_ref = npc.get("fsm")
		fsm = fsm_ref if fsm_ref != null else null
	else:
		fsm = null

func enter() -> void:
	# Called when entering this state
	# OPTIMIZATION: Reset cancellation guard on state entry
	_tasks_cancelled_this_state = false
	pass

func exit() -> void:
	# Called when exiting this state
	pass

func update(_delta: float) -> void:
	# Called every frame while in this state
	pass

func can_enter() -> bool:
	# Return true if this state can be entered
	return false

func get_priority() -> float:
	# Return priority of this state (higher = more important)
	return 1.0

# State completion: return true when this state is "done" (e.g. inventory full, eat finished)
# Used for clarity and optional FSM/UI; states may still transition themselves.
func is_complete() -> bool:
	return false

func get_data() -> Dictionary:
	# Return debug data about this state
	return {}

# Helper function to check if a position is inside an enemy land claim
# Returns true if position is inside a land claim that doesn't belong to this NPC
func _is_position_in_enemy_land_claim(position: Vector2) -> bool:
	if not npc:
		return false
	
	# Only cavemen need to avoid enemy land claims
	var nt_prop = npc.get("npc_type") if npc else null
	var npc_type: String = (nt_prop as String) if nt_prop != null else ""
	if npc_type != "caveman":
		return false  # Only cavemen avoid enemy land claims
	
	# Get NPC's clan name
	var gn_prop = npc.get_clan_name() if npc else null
	var npc_clan: String = (gn_prop as String) if gn_prop != null else ""
	if npc_clan == "":
		return false  # No clan = no enemy land claims to avoid
	
	# Check all land claims
	var land_claims := get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		
		var claim_clan_prop = claim.get("clan_name")
		var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
		
		# Skip if this is our own land claim
		if claim_clan == npc_clan:
			continue
		
		# Skip if land claim has no clan (shouldn't happen, but safety check)
		if claim_clan == "":
			continue
		
		# Check if position is inside this enemy land claim
		var claim_pos: Vector2 = claim.global_position
		var claim_radius_prop = claim.get("radius")
		var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
		
		var distance_to_claim: float = position.distance_to(claim_pos)
		if distance_to_claim <= claim_radius:
			return true  # Position is inside enemy land claim
	
	return false  # Not inside any enemy land claim

# Helper function to check if NPC is inside their own land claim
# Returns true if position is inside the NPC's own land claim
func _is_position_in_own_land_claim(position: Vector2) -> bool:
	if not npc:
		return false
	
	# Only cavemen have land claims
	var nt_prop2 = npc.get("npc_type") if npc else null
	var npc_type: String = (nt_prop2 as String) if nt_prop2 != null else ""
	if npc_type != "caveman":
		return false  # Only cavemen have land claims
	
	var land_claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not land_claim or not is_instance_valid(land_claim):
		return false
	
	var claim_pos: Vector2 = land_claim.global_position
	var claim_radius_prop = land_claim.get("radius")
	var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
	var distance_to_claim: float = position.distance_to(claim_pos)
	return distance_to_claim <= claim_radius

# Helper function to check if land claim has 10+ items of each resource type
# Returns true if land claim has enough resources to prioritize defense (10+ of each type)
func _is_land_claim_ready_for_defense() -> bool:
	if not npc:
		return false
	
	# Only cavemen with land claims need this check
	var nt_prop3 = npc.get("npc_type") if npc else null
	var npc_type: String = (nt_prop3 as String) if nt_prop3 != null else ""
	if npc_type != "caveman":
		return false
	
	var land_claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not land_claim or not is_instance_valid(land_claim):
		return false
	
	# Get land claim inventory
	var land_claim_inventory = land_claim.get("inventory")
	if not land_claim_inventory:
		return false  # No inventory
	
	# Check if we have 10+ of each resource type
	# Resource types to check: BERRIES, WOOD, STONE, FIBER, GRAIN
	var required_types: Array = [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.FIBER,
		ResourceData.ResourceType.GRAIN
	]
	
	var min_threshold: int = 10  # Need 10 of each type (defense threshold)
	
	for resource_type in required_types:
		var count: int = land_claim_inventory.get_count(resource_type)
		if count < min_threshold:
			return false  # Not ready for defense yet
	
	return true  # All types have 10+

# Helper function to check if land claim has 20+ items of each resource type
# Returns true if land claim is well-stocked (20+ of each type)
func _is_land_claim_well_stocked() -> bool:
	if not npc:
		return false
	
	# Only cavemen with land claims need this check
	var nt_prop3 = npc.get("npc_type") if npc else null
	var npc_type: String = (nt_prop3 as String) if nt_prop3 != null else ""
	if npc_type != "caveman":
		return false
	
	var land_claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not land_claim or not is_instance_valid(land_claim):
		return false
	
	# Get land claim inventory
	var land_claim_inventory = land_claim.get("inventory")
	if not land_claim_inventory:
		return false  # No inventory
	
	# Check if we have 20+ of each resource type
	# Resource types to check: BERRIES, WOOD, STONE, FIBER, GRAIN
	var required_types: Array = [
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.FIBER,
		ResourceData.ResourceType.GRAIN
	]
	
	var min_threshold: int = 20  # Need 20 of each type
	
	for resource_type in required_types:
		var count: int = land_claim_inventory.get_count(resource_type)
		if count < min_threshold:
			return false  # Not well-stocked yet
	
	return true  # All types have 20+

# Helper function to check if NPC is defending
func _is_defending() -> bool:
	if not npc:
		return false
	var defend_target = npc.get("defend_target")
	return defend_target != null and is_instance_valid(defend_target)

# Helper function to check if NPC is in combat
func _is_in_combat() -> bool:
	if not npc:
		return false
	var combat_target = npc.get("combat_target")
	return combat_target != null and is_instance_valid(combat_target)

# Helper function to check if NPC is following (ordered follow)
func _is_following() -> bool:
	if not npc:
		return false
	return npc.get("follow_is_ordered") == true

# Cancel tasks if active (standardized pattern)
# OPTIMIZATION: Added guard to prevent double-cancels (only cancel once per state transition)
var _tasks_cancelled_this_state: bool = false

func _cancel_tasks_if_active() -> void:
	if not npc or not npc.task_runner:
		return
	# OPTIMIZATION: Guard against double-cancels - only cancel once per state
	if _tasks_cancelled_this_state:
		return
	if npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		npc.task_runner.cancel_current_job()
		_tasks_cancelled_this_state = true
