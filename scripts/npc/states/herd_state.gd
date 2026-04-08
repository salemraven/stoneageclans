extends "res://scripts/npc/states/base_state.gd"

## Herd state — wild herdables (woman, sheep, goat) following a herder.
## Fighters in ordered follow use party_state.gd.

var last_target_update_time: float = 0.0
var _herd_instrument_timer: float = 0.0
const HERD_INSTRUMENT_INTERVAL: float = 2.0

func enter() -> void:
	if not npc or not npc.herder or not is_instance_valid(npc.herder):
		if npc:
			npc._clear_herd()
		return
	_cancel_tasks_if_active()
	last_target_update_time = Time.get_ticks_msec() / 1000.0
	var herder_name: String = npc.herder.name if is_instance_valid(npc.herder) else "unknown"
	UnifiedLogger.log_npc("NPC entered herd mode (wild), following %s" % herder_name, {
		"npc": npc.npc_name,
		"leader": herder_name
	}, UnifiedLogger.Level.INFO)

func update(delta: float) -> void:
	if not npc:
		return
	if npc.is_dead():
		return
	if not npc.herder or not is_instance_valid(npc.herder):
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	if npc.herder.has_method("is_dead") and npc.herder.is_dead():
		npc._clear_herd()
		var npc_type_str: String = npc.get("npc_type") if npc else ""
		if npc_type_str == "woman" or npc_type_str == "sheep" or npc_type_str == "goat":
			if npc.clan_name != "":
				npc.clan_name = ""
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return

	_check_clan_joining()

	if npc.npc_type == "sheep" or npc.npc_type == "goat":
		var ab = OccupationSystem.get_workplace(npc) if OccupationSystem else null
		if ab and is_instance_valid(ab):
			if npc.steering_agent:
				npc.steering_agent.set_target_position(ab.global_position)
			return

	var herder_ref: Node2D = npc.herder
	if not is_instance_valid(herder_ref):
		npc._clear_herd()
		if fsm:
			fsm.evaluation_timer = 0.0
		return

	var herder_type: String = herder_ref.get("npc_type") as String if herder_ref.get("npc_type") != null else ""
	var herder_is_player: bool = herder_ref.is_in_group("player")
	var is_wild_following_leader: bool = (npc.npc_type in ["woman", "sheep", "goat"]) and (herder_type in ["caveman", "clansman"] or herder_is_player)
	if not is_wild_following_leader or not npc.steering_agent:
		if fsm:
			fsm.change_state("wander")
		return

	var refresh_interval: float = 0.3
	if NPCConfig and "herd_follow_refresh_interval" in NPCConfig:
		refresh_interval = NPCConfig.herd_follow_refresh_interval as float
	var herd_speed_mult: float = 0.85
	if NPCConfig and "herd_follower_speed_multiplier" in NPCConfig:
		herd_speed_mult = NPCConfig.herd_follower_speed_multiplier as float

	var herder_pos: Vector2 = herder_ref.global_position
	var dist_to_herder: float = npc.global_position.distance_to(herder_pos)
	var herd_break_dist: float = 300.0
	if NPCConfig and "herd_max_distance_before_break" in NPCConfig:
		herd_break_dist = NPCConfig.herd_max_distance_before_break as float
	if dist_to_herder >= herd_break_dist:
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return

	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_target_update_time >= refresh_interval:
		last_target_update_time = current_time
		npc.steering_agent.set_target_position(herder_pos)
	if "speed_multiplier" in npc.steering_agent:
		npc.steering_agent.speed_multiplier = herd_speed_mult

	_herd_instrument_timer += delta
	if _herd_instrument_timer >= HERD_INSTRUMENT_INTERVAL:
		_herd_instrument_timer = 0.0
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("herd_follow_tick"):
			var aname: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else "?"
			var hname: String = str(herder_ref.get("npc_name")) if herder_ref.get("npc_name") != null else str(herder_ref.name)
			pi.herd_follow_tick(aname, hname, dist_to_herder, herd_speed_mult, herd_break_dist)

func _check_clan_joining() -> void:
	if not npc.can_join_clan():
		var inside: Dictionary = npc.is_inside_land_claim() if npc.has_method("is_inside_land_claim") else {}
		if inside.is_empty():
			return
		if npc.get("follow_is_ordered"):
			return
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return
	var skip_release: bool = npc.get("follow_is_ordered") as bool if npc.get("follow_is_ordered") != null else false
	if npc._try_join_clan_from_claim(skip_release):
		if not skip_release:
			if npc.progress_display and is_instance_valid(npc.progress_display):
				npc.progress_display.stop_collection()

func can_enter() -> bool:
	if not npc or npc.is_dead():
		return false
	if _is_defending():
		return false
	if _is_in_combat():
		return false
	var npc_type_str: String = npc.get("npc_type") if npc else ""
	if npc_type_str != "woman" and npc_type_str != "sheep" and npc_type_str != "goat":
		return false
	return npc.is_herded and npc.herder != null and is_instance_valid(npc.herder)

func get_priority() -> float:
	if not npc:
		return 0.0
	var priority: float = 11.0
	if NPCConfig:
		var config_priority = NPCConfig.get("priority_herd")
		if config_priority != null:
			priority = config_priority as float
		priority = max(priority, 11.0)
	return priority

func get_data() -> Dictionary:
	var data: Dictionary = {
		"is_herded": npc.is_herded if npc else false,
		"has_herder": npc.herder != null if npc else false,
		"state": "herd",
	}
	if npc and npc.herder:
		var distance: float = npc.global_position.distance_to(npc.herder.global_position) if is_instance_valid(npc.herder) else 0.0
		data["herder_distance"] = distance
		data["herder_name"] = npc.herder.name if is_instance_valid(npc.herder) else "unknown"
	return data

func exit() -> void:
	_cancel_tasks_if_active()
