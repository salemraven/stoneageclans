extends Job
class_name CraftJob

# Preload task scripts once at parse time
const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")
const PickUpTaskScript = preload("res://scripts/ai/tasks/pick_up_task.gd")
const KnapTaskScript = preload("res://scripts/ai/tasks/knap_task.gd")
const DropOffTaskScript = preload("res://scripts/ai/tasks/drop_off_task.gd")

# Craft Job System - Knapping stones into blades at land claim
# Uses stones FROM land claim storage - no need for worker to have stones
# Sequence: MoveTo(claim) → PickUp(2 stone) → Knap → DropOff(blade) → DropOff(stone)

var land_claim: Node

func _init(claim: Node) -> void:
	land_claim = claim
	_build_task_sequence()

func _build_task_sequence() -> void:
	if not land_claim:
		return

	var claim_pos: Vector2 = land_claim.global_position
	var craft_duration: float = NPCConfig.craft_knap_duration if NPCConfig else 1.5

	# Task 1: MoveTo land claim
	var move_task: Task = MoveToTaskScript.new(claim_pos, 50.0) as Task
	if move_task:
		add_task(move_task)

	# Task 2: PickUp 2 stones from land claim storage
	var pick_up_task: Task = PickUpTaskScript.new(land_claim, ResourceData.ResourceType.STONE, 2) as Task
	if pick_up_task:
		add_task(pick_up_task)

	# Task 3: Knap (we're at claim, have stones)
	var knap_task: Task = KnapTaskScript.new(land_claim, craft_duration, 50.0) as Task
	if knap_task:
		add_task(knap_task)

	# Task 4: DropOff blade
	var drop_blade: Task = DropOffTaskScript.new(land_claim, ResourceData.ResourceType.BLADE, 1, 50.0) as Task
	if drop_blade:
		add_task(drop_blade)

	# Task 5: DropOff stone
	var drop_stone: Task = DropOffTaskScript.new(land_claim, ResourceData.ResourceType.STONE, 1, 50.0) as Task
	if drop_stone:
		add_task(drop_stone)
