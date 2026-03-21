extends Job
class_name GatherJob

# Preload task scripts once at parse time
const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")
const GatherTaskScript = preload("res://scripts/ai/tasks/gather_task.gd")

# Gather Job System - Refactor: Single deposit path via auto-deposit
# Sequence: MoveTo(resource) → GatherTask → [MoveTo(land_claim) if not skip_deposit]
# Job ends at claim; auto-deposit (_check_and_deposit_items) handles transfer

# Resource node to gather from
var resource_node: Node2D

# Land claim to deposit at
var land_claim: Node

# Resource type (legacy, kept for compatibility)
var resource_type: ResourceData.ResourceType

# Amount expected (usually 1)
var amount: int = 1

# Whether to skip deposit (only gather, don't move to claim)
var skip_deposit: bool = false

# Lease: job expires after this time (releases resource if NPC stalls)
var expire_time: float = 0.0
var gather_until_pct: float = 0.8
var deposit_at_pct: float = 0.4

func _init(resource: Node2D, claim: Node, skip_dep: bool = false) -> void:
	resource_node = resource
	land_claim = claim
	skip_deposit = skip_dep
	var lease_sec: float = BalanceConfig.lease_expire_seconds if BalanceConfig else 60.0
	expire_time = Time.get_ticks_msec() / 1000.0 + lease_sec
	gather_until_pct = NPCConfig.gather_same_node_until_pct if NPCConfig else 1.0
	deposit_at_pct = NPCConfig.gather_deposit_threshold if NPCConfig else 0.4
	
	if resource and resource.has_method("get") and "resource_type" in resource:
		resource_type = resource.get("resource_type")
		if resource_type == ResourceData.ResourceType.WHEAT:
			resource_type = ResourceData.ResourceType.GRAIN
		amount = 1
	
	_build_task_sequence()

func _build_task_sequence() -> void:
	if not resource_node or not land_claim:
		return
	
	# Task 1: MoveTo(resource_node)
	var resource_pos: Vector2 = resource_node.global_position
	var gather_dist: float = NPCConfig.gather_distance if NPCConfig else 48.0
	var move_to_resource: Task = MoveToTaskScript.new(resource_pos, gather_dist) as Task
	if move_to_resource:
		add_task(move_to_resource)
	
	# Task 2: GatherTask(resource_node)
	var gather_dur: float = 0.5
	if NPCConfig:
		gather_dur = NPCConfig.gather_duration
	var gather_task: Task = GatherTaskScript.new(resource_node, gather_dur, 56.0) as Task
	if gather_task:
		add_task(gather_task)
	
	# Task 3: MoveTo(land_claim) only - auto-deposit handles transfer when NPC arrives
	if not skip_deposit:
		var claim_pos: Vector2 = land_claim.global_position
		var deposit_range: float = NPCConfig.deposit_range if NPCConfig else 100.0
		var deposit_move_speed: float = 120.0
		var move_to_claim: Task = MoveToTaskScript.new(claim_pos, deposit_range, deposit_move_speed) as Task
		if move_to_claim:
			add_task(move_to_claim)
