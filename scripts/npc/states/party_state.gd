extends "res://scripts/npc/states/base_state.gd"

## Party state — cavemen/clansmen in ordered follow (Follow/Guard/Attack) behind player or NPC leader.
## Wild herdables use herd_state.gd instead.

const _RTS_CFG = {
	"ordered_leash_max": 1200.0,
	"slot_settled_dist": 35.0,
	"catchup_speed_mult": 2.0,
	"backing_dist": 10.0,
	"backing_target_dist": 30.0,
	"formation_lookahead_px": 80.0,
	"leader_move_speed_sq": 4.0,
}

var needs_catchup: bool = false
var last_target_update_time: float = 0.0
var target_update_interval: float = 0.3
var current_target: Vector2 = Vector2.ZERO
var _party_instrument_timer: float = 0.0
const PARTY_INSTRUMENT_INTERVAL: float = 2.0

func enter() -> void:
	if not npc or not npc.herder or not is_instance_valid(npc.herder):
		if npc:
			npc._clear_herd()
		return
	_cancel_tasks_if_active()
	if npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		UnifiedLogger.log_npc("PARTY: %s cancelled job due to following" % npc.npc_name, {
			"npc": npc.npc_name,
			"event": "job_cancelled_party"
		})
	last_target_update_time = Time.get_ticks_msec() / 1000.0
	var herder_name: String = npc.herder.name if is_instance_valid(npc.herder) else "unknown"
	UnifiedLogger.log_npc("NPC entered party mode, following %s" % herder_name, {
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
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return

	_check_clan_joining()

	var herder_ref: Node2D = npc.herder
	if not is_instance_valid(herder_ref):
		npc._clear_herd()
		if fsm:
			fsm.evaluation_timer = 0.0
		return

	var herder_is_player: bool = herder_ref.is_in_group("player")
	var follow_ordered: bool = npc.get("follow_is_ordered") as bool if npc.get("follow_is_ordered") != null else false
	if follow_ordered and not herder_is_player:
		var ht: String = herder_ref.get("npc_type") as String if herder_ref.get("npc_type") != null else ""
		if ht == "caveman" or ht == "clansman":
			var tree = npc.get_tree()
			if tree:
				FormationUtils.publish_slots_for_npc_leader(herder_ref, npc, tree)

	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var mode: String = ctx.get("mode", "FOLLOW") as String

	var agro: float = npc.get("agro_meter") as float if npc.get("agro_meter") != null else 0.0
	var agro_break_threshold: float = 70.0
	if mode == "ATTACK":
		agro_break_threshold = 100.0
	elif mode == "FOLLOW":
		agro_break_threshold = 40.0
	var formation_active: bool = (agro < agro_break_threshold)

	var distance_min: float
	var distance_max: float
	var max_distance: float = _RTS_CFG["ordered_leash_max"]
	if mode == "GUARD":
		distance_min = 55.0
		distance_max = 110.0
	elif mode == "ATTACK":
		distance_min = 60.0
		distance_max = 200.0
	else:
		distance_min = 60.0
		distance_max = 180.0

	var leader_fv_early: Vector2 = Vector2.ZERO
	if follow_ordered and herder_ref.has_meta("formation_velocity"):
		leader_fv_early = herder_ref.get_meta("formation_velocity") as Vector2
	var leader_moving_early: bool = leader_fv_early.length_squared() > _RTS_CFG["leader_move_speed_sq"]

	if not npc.is_herded:
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
			fsm.change_state("wander")
		return

	if not npc.herder or not is_instance_valid(npc.herder):
		npc._clear_herd()
		if npc.progress_display:
			npc.progress_display.stop_collection()
		if fsm:
			fsm.evaluation_timer = 0.0
		return

	herder_ref = npc.herder
	if not is_instance_valid(herder_ref):
		npc._clear_herd()
		if fsm:
			fsm.evaluation_timer = 0.0
		return

	var herder_pos: Vector2 = herder_ref.global_position
	var distance_to_herder: float = npc.global_position.distance_to(herder_pos)

	if npc.get("follow_is_ordered"):
		var max_ordered_leash: float = _RTS_CFG["ordered_leash_max"]
		if distance_to_herder > max_ordered_leash:
			var in_combat: bool = (agro >= 70.0)
			if not in_combat and npc.fsm:
				var st2: String = npc.fsm.get_current_state_name() if npc.fsm.has_method("get_current_state_name") else ""
				in_combat = (st2 == "combat")
			if not in_combat:
				npc._clear_herd()
				if npc.progress_display:
					npc.progress_display.stop_collection()
				if fsm:
					fsm.evaluation_timer = 0.0
				return
	elif not npc.get("follow_is_ordered"):
		if distance_to_herder > 5000.0:
			npc._clear_herd()
			if npc.progress_display:
				npc.progress_display.stop_collection()
			if fsm:
				fsm.evaluation_timer = 0.0
			return
		if distance_to_herder >= max_distance:
			npc._clear_herd()
			if npc.progress_display:
				npc.progress_display.stop_collection()
			if fsm:
				fsm.evaluation_timer = 0.0
			return

	needs_catchup = distance_to_herder > distance_max

	var current_time: float = Time.get_ticks_msec() / 1000.0
	var update_interval: float = target_update_interval
	if mode == "GUARD" and follow_ordered:
		update_interval = 0.15
	var should_update_target: bool = false
	if formation_active:
		if follow_ordered and leader_moving_early:
			should_update_target = true
		else:
			should_update_target = (current_time - last_target_update_time >= update_interval)
	if needs_catchup or distance_to_herder < distance_min:
		should_update_target = should_update_target or formation_active
	if should_update_target and not formation_active:
		should_update_target = false

	var slots_meta: Dictionary = {}
	var use_slot_formation: bool = follow_ordered and (
		herder_is_player or (
			herder_ref.has_meta("formation_slots")
			and not (herder_ref.get_meta("formation_slots", {}) as Dictionary).is_empty()
		)
	)

	if should_update_target:
		last_target_update_time = current_time
		var slot_for_speed: Vector2 = Vector2.ZERO
		var use_formation_speed: bool = false

		var ideal_distance: float = (distance_min + distance_max) / 2.0
		var distance_variation: float = randf_range(-15.0, 15.0)
		if mode == "GUARD" and follow_ordered:
			distance_variation = randf_range(-6.0, 6.0)
		var target_distance: float = ideal_distance + distance_variation
		if mode == "GUARD" and follow_ordered:
			target_distance = clampf(target_distance, distance_min, distance_max)

		var target: Vector2
		var backing_up: bool = false

		if follow_ordered and mode == "GUARD" and use_slot_formation and not herder_is_player:
			var co_followers: Array = []
			var npcs_list = npc.get_tree().get_nodes_in_group("npcs")
			for n in npcs_list:
				if not is_instance_valid(n) or n.get("herder") != herder_ref:
					continue
				if not (n.get("is_herded") == true):
					continue
				co_followers.append(n)
			co_followers.sort_custom(func(a, b): return a.get_instance_id() < b.get_instance_id())
			var my_index: int = co_followers.find(npc)
			if my_index < 0:
				my_index = 0
			var count: int = co_followers.size()
			var facing: Vector2 = Vector2(1, 0)
			var leader_sa = herder_ref.get("steering_agent")
			if leader_sa:
				var leader_target: Vector2 = leader_sa.target_position
				var to_target: Vector2 = leader_target - herder_pos
				if to_target.length_squared() > 100.0:
					facing = to_target.normalized()
			var spread_angle: float = (TAU * my_index) / max(1, count) + PI if count > 1 else PI
			var formation_dir: Vector2 = facing.rotated(spread_angle)
			target = herder_pos + formation_dir * target_distance
		elif follow_ordered and use_slot_formation:
			if npc.steering_agent and npc.steering_agent.max_speed != npc.steering_agent.original_max_speed:
				npc.steering_agent.max_speed = npc.steering_agent.original_max_speed
			var my_entity_id: int = npc.get_instance_id()
			slots_meta = herder_ref.get_meta("formation_slots", {}) as Dictionary
			var my_slot: Dictionary = slots_meta.get(my_entity_id, {}) as Dictionary
			if not my_slot.is_empty():
				var slot_pos: Vector2 = my_slot.get("slot_pos", herder_pos) as Vector2
				var steer_target: Vector2 = my_slot.get("steer_target", slot_pos) as Vector2
				var leader_stopped_slot: bool = my_slot.get("player_stopped", true) as bool
				if leader_stopped_slot and current_target != Vector2.ZERO:
					var dist_to_target: float = npc.global_position.distance_to(slot_pos)
					if dist_to_target < 25.0:
						target = current_target
						slot_for_speed = slot_pos
						use_formation_speed = true
					else:
						target = slot_pos
						slot_for_speed = slot_pos
						use_formation_speed = true
				else:
					target = steer_target
					slot_for_speed = slot_pos
					use_formation_speed = true
			else:
				target = herder_pos
				slot_for_speed = herder_pos
				use_formation_speed = true
		elif distance_to_herder < distance_min:
			var direction: Vector2 = (npc.global_position - herder_pos).normalized()
			if direction == Vector2.ZERO:
				var angle: float = randf() * TAU
				direction = Vector2(cos(angle), sin(angle))
			target = herder_pos + direction * target_distance
			backing_up = true
		elif distance_to_herder > distance_max:
			target = herder_pos
			if npc.progress_display:
				npc.progress_display.stop_collection()
		else:
			var direction_to_herder: Vector2 = (herder_pos - npc.global_position).normalized()
			target = herder_pos - direction_to_herder * target_distance

		current_target = target

		if npc.steering_agent:
			npc.steering_agent.set_target_position(current_target)
			if follow_ordered and use_slot_formation and use_formation_speed:
				var dist_slot: float = npc.global_position.distance_to(slot_for_speed)
				_apply_formation_speed(npc, mode, backing_up, dist_slot, leader_moving_early)
			elif "speed_multiplier" in npc.steering_agent:
				if backing_up:
					npc.steering_agent.speed_multiplier = 0.15
				else:
					npc.steering_agent.speed_multiplier = 1.0
	else:
		if npc.steering_agent and current_target != Vector2.ZERO:
			npc.steering_agent.set_target_position(current_target)
			if "speed_multiplier" in npc.steering_agent:
				npc.steering_agent.speed_multiplier = 1.0

	_party_instrument_timer += delta
	if _party_instrument_timer >= PARTY_INSTRUMENT_INTERVAL:
		_party_instrument_timer = 0.0
		var pi2 = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi2 and pi2.is_enabled() and pi2.has_method("party_formation_tick"):
			var lname: String = str(herder_ref.get("npc_name")) if herder_ref.get("npc_name") != null else str(herder_ref.name)
			var followers_data: Array = []
			var tree2 = npc.get_tree()
			if tree2:
				for n in tree2.get_nodes_in_group("npcs"):
					if not is_instance_valid(n) or n.get("herder") != herder_ref:
						continue
					if n.get("follow_is_ordered") != true:
						continue
					var t = n.get("npc_type") as String if n.get("npc_type") != null else ""
					if t != "caveman" and t != "clansman":
						continue
					var ctx2: Dictionary = n.get("command_context") if n.get("command_context") != null else {}
					var md: String = ctx2.get("mode", "FOLLOW") as String
					var sm: float = float(FormationUtils.STANCE_SPEED_MULT.get(md, 1.0))
					followers_data.append({
						"name": str(n.get("npc_name")),
						"dist": n.global_position.distance_to(herder_ref.global_position),
						"mode": md,
						"speed_mult": sm,
					})
			pi2.party_formation_tick(lname, followers_data)

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
		UnifiedLogger.log_npc("NPC (caveman) cannot join clan - released from party mode", {
			"npc": npc.npc_name,
			"reason": "caveman_cannot_join"
		}, UnifiedLogger.Level.WARNING)
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
	if npc_type_str != "caveman" and npc_type_str != "clansman":
		return false
	var herder_valid: bool = npc.herder != null and is_instance_valid(npc.herder)
	if not npc.get("follow_is_ordered") or not herder_valid:
		if npc_type_str == "caveman":
			npc._clear_herd()
		return false
	var ordered_follow_player: bool = npc.herder.is_in_group("player")
	var agro_test_npc_leader: bool = _is_agro_combat_test() and not ordered_follow_player
	var same_clan_npc: bool = PartyCommandUtils.same_clan_warband_herder(npc.herder, npc)
	if not ordered_follow_player and not agro_test_npc_leader and not same_clan_npc:
		if npc_type_str == "caveman":
			npc._clear_herd()
		return false
	return npc.is_herded and npc.herder != null and is_instance_valid(npc.herder)

func get_priority() -> float:
	if not npc:
		return 0.0
	if needs_catchup:
		var catchup_priority: float = 15.0
		if NPCConfig:
			var config_priority = NPCConfig.get("herd_catchup_priority")
			if config_priority != null:
				catchup_priority = config_priority as float
		return max(catchup_priority, 11.0)
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
		"needs_catchup": needs_catchup if npc else false,
		"state": "party",
	}
	if npc and npc.herder:
		var distance: float = npc.global_position.distance_to(npc.herder.global_position) if is_instance_valid(npc.herder) else 0.0
		data["herder_distance"] = distance
		data["herder_name"] = npc.herder.name if is_instance_valid(npc.herder) else "unknown"
	return data

func _apply_formation_speed(npc_node: Node, mode_str: String, backing: bool, dist_to_slot: float = 0.0, leader_moving: bool = false) -> void:
	var sa = npc_node.get("steering_agent") if npc_node else null
	if not sa:
		return
	var rts: Dictionary = _RTS_CFG
	var mult: float
	if backing:
		mult = 0.15
	elif dist_to_slot > rts["slot_settled_dist"]:
		mult = rts["catchup_speed_mult"]
	elif leader_moving:
		if mode_str == "GUARD":
			mult = 0.75
		elif mode_str == "ATTACK":
			mult = 0.85
		else:
			mult = 1.0
	elif mode_str == "GUARD":
		mult = 0.75
	elif mode_str == "ATTACK":
		mult = 0.85
	else:
		mult = 1.0
	if sa.has_method("set_speed_multiplier"):
		sa.call("set_speed_multiplier", mult)
	elif "speed_multiplier" in sa:
		sa.speed_multiplier = mult

func _is_agro_combat_test() -> bool:
	var dc = get_node_or_null("/root/DebugConfig")
	return dc != null and dc.get("enable_agro_combat_test") == true

func exit() -> void:
	_cancel_tasks_if_active()
