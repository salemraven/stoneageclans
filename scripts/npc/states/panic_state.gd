extends "res://scripts/npc/states/base_state.gd"

## Panic — women erratically wander inside campfire radius when wood OR food hits zero.
## Only when fire went out from resource depletion (manual fire-off is disabled).

const PANIC_SPEED_MULT: float = 1.15
const PANIC_IDLE_SEC: float = 3.5
const PANIC_ARRIVE_DIST: float = 28.0

var _idle_timer: float = 0.0
var _home_campfire: Campfire = null

func enter() -> void:
	_cancel_tasks_if_active()
	_idle_timer = 0.0
	_home_campfire = _find_home_campfire()
	_pick_panic_target()

func update(delta: float) -> void:
	if not npc or npc.is_dead():
		return
	if not _can_stay_in_panic():
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	if npc.steering_agent and npc.steering_agent.has_method("set_speed_multiplier"):
		npc.steering_agent.set_speed_multiplier(PANIC_SPEED_MULT)
	var cf := _home_campfire if _home_campfire and is_instance_valid(_home_campfire) else _find_home_campfire()
	if cf == null or npc.steering_agent == null:
		return
	var goal: Vector2 = npc.steering_agent.target_position
	if npc.global_position.distance_to(goal) > PANIC_ARRIVE_DIST:
		_idle_timer = 0.0
		return
	npc.velocity = Vector2.ZERO
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_idle_timer = PANIC_IDLE_SEC
		_pick_panic_target()

func exit() -> void:
	if npc and npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()

func can_enter() -> bool:
	if not npc:
		return false
	var npc_type: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if npc_type != "woman":
		return false
	if _is_in_combat() or _is_fleeing():
		return false
	var cf := _find_home_campfire()
	if cf == null:
		return false
	if cf.nomad_state != Campfire.NomadState.NONE:
		return false
	if not cf._is_panic_resource_depleted():
		return false
	if cf.global_position.distance_to(npc.global_position) > cf.radius:
		return false
	# A living hut is her place to stand. Panic was pinning her on the fire.
	if OccupationSystem:
		var home = OccupationSystem.get_home_living_hut(npc)
		if home != null and is_instance_valid(home):
			return false
	return true

func get_priority() -> float:
	return 8.2

func _can_stay_in_panic() -> bool:
	return can_enter()

func _find_home_campfire() -> Campfire:
	if not npc:
		return null
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan == "":
		return null
	for node in get_tree().get_nodes_in_group("campfires"):
		if not is_instance_valid(node) or not (node is Campfire):
			continue
		var cf: Campfire = node as Campfire
		if cf.clan_name != npc_clan:
			continue
		if cf.global_position.distance_to(npc.global_position) <= cf.radius:
			return cf
	return null

func _pick_panic_target() -> void:
	if not npc or not npc.steering_agent:
		return
	var cf := _home_campfire if _home_campfire and is_instance_valid(_home_campfire) else _find_home_campfire()
	if cf == null:
		return
	var angle: float = npc.npc_randf() * TAU
	var dist: float = cf.radius * 0.55
	var offset := Vector2(cos(angle), sin(angle)) * dist
	if npc.steering_agent.has_method("set_target_position_immediate"):
		npc.steering_agent.set_target_position_immediate(cf.global_position + offset)
	else:
		npc.steering_agent.set_target_position(cf.global_position + offset)

func _is_fleeing() -> bool:
	if not fsm:
		return false
	return fsm.current_state_name == "flee_combat" or fsm.current_state_name == "flee_prey"
