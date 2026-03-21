extends "res://scripts/npc/states/base_state.gd"

# Search state — ant-style: pick outward direction, move to waypoint, scan (stub), return home after 5 failed attempts.
# Guide: SEARCHING discovers resources/herds; avoid combat; return to landclaim.

const WAYPOINT_ARRIVAL_DIST := 55.0
const HOME_ARRIVAL_DIST := 80.0
const MAX_ATTEMPTS := 5
const OUTWARD_FACTOR := 2.0  # waypoint at radius * this from home

var phase: String = "outbound"  # "outbound" | "return_home"
var attempt_count: int = 0
var waypoint: Vector2 = Vector2.ZERO
var home_center: Vector2 = Vector2.ZERO
var home_radius: float = 400.0

func enter() -> void:
	if not npc:
		return
	var home = npc.get("search_home_claim")
	if not home or not is_instance_valid(home):
		if fsm:
			fsm.change_state("wander")
		return
	home_center = home.global_position
	home_radius = home.get("radius") as float if home.get("radius") != null else 400.0
	phase = "outbound"
	attempt_count = 0
	_pick_waypoint()

func exit() -> void:
	_cancel_tasks_if_active()

func _pick_waypoint() -> void:
	var angle := randf() * TAU
	var dist := home_radius * OUTWARD_FACTOR
	waypoint = home_center + Vector2(cos(angle), sin(angle)) * dist
	if npc and npc.steering_agent:
		npc.steering_agent.set_target_position(waypoint)

func update(_delta: float) -> void:
	if not npc:
		return
	var home = npc.get("search_home_claim")
	if not home or not is_instance_valid(home):
		if fsm:
			fsm.change_state("wander")
		return

	if phase == "outbound":
		var d: float = npc.global_position.distance_to(waypoint)
		if d < WAYPOINT_ARRIVAL_DIST:
			attempt_count += 1
			if attempt_count >= MAX_ATTEMPTS:
				phase = "return_home"
				if npc.steering_agent:
					npc.steering_agent.set_target_position(home_center)
			else:
				_pick_waypoint()
	elif phase == "return_home":
		var d: float = npc.global_position.distance_to(home_center)
		if d < HOME_ARRIVAL_DIST:
			if fsm:
				fsm.change_state("wander")

func can_enter() -> bool:
	if not npc:
		return false
	var tp: String = npc.get("npc_type") if npc else ""
	if tp != "caveman" and tp != "clansman":
		return false
	if npc.get("follow_is_ordered"):
		return false
	var assigned: bool = npc.get("assigned_to_search") as bool if npc.get("assigned_to_search") != null else false
	if not assigned:
		return false
	var home = npc.get("search_home_claim")
	return home != null and is_instance_valid(home)

func get_priority() -> float:
	return 5.5  # Below defend (6.0), above gather/wander

func get_data() -> Dictionary:
	return {
		"phase": phase,
		"attempts": attempt_count,
		"waypoint": "%v" % waypoint
	}
