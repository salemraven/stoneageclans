extends Job
class_name ButcherCorpseJob

## One trip: move to hunt corpse → butcher until threshold/full → walk to claim (auto-deposit on arrival).

const MoveToTaskScript := preload("res://scripts/ai/tasks/move_to_task.gd")
const ButcherCorpseTaskScript := preload("res://scripts/ai/tasks/butcher_corpse_task.gd")

var corpse: Node = null
var land_claim: Node = null
var deposit_at_pct: float = 0.4


func _init(corpse_node: Node, claim: Node) -> void:
	corpse = corpse_node
	land_claim = claim
	deposit_at_pct = NPCConfig.gather_deposit_threshold if NPCConfig else 0.4
	building = claim
	_build_task_sequence()


func _build_task_sequence() -> void:
	if not corpse or not is_instance_valid(corpse) or not land_claim:
		return
	var butcher_dist: float = 52.0
	var butcher_dur: float = 1.0
	if NPCConfig:
		butcher_dur = NPCConfig.gather_duration
	var move_to_corpse: Task = MoveToTaskScript.new(corpse.global_position, butcher_dist) as Task
	if move_to_corpse:
		add_task(move_to_corpse)
	var butcher_task: Task = ButcherCorpseTaskScript.new(corpse, butcher_dur, butcher_dist, deposit_at_pct) as Task
	if butcher_task:
		add_task(butcher_task)
	var deposit_range: float = NPCConfig.deposit_range if NPCConfig else 100.0
	var move_home: Task = MoveToTaskScript.new(land_claim.global_position, deposit_range, 120.0) as Task
	if move_home:
		add_task(move_home)
