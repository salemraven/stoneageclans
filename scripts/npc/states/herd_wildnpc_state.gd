extends "res://scripts/npc/states/base_state.gd"

# Preload PerceptionArea for herdable detection (AOP Phase 2)
const PerceptionArea = preload("res://scripts/npc/components/perception_area.gd")

# Herd Wild NPC State - Target-less, animal-authoritative
# Cavemen/clansmen search for herdables. Animals attach via HerdInfluenceArea.
# If herded_count > 0: lead to claim. Else: ray/cone search (walk straight-ish lines from claim).
# No target_woman - herded_count is source of truth.

var no_target_time: float = 0.0  # Time with no animals attached (searching)
var max_no_target_time: float = 7.0  # Base; exit after 2x this (14s) with no attaches
var search_angle: float = 0.0  # Ray direction (radians)
var search_distance: float = 0.0  # Distance along current ray
var search_center: Vector2 = Vector2.ZERO

var last_exit_time: float = 0.0
var exit_cooldown: float = 0.2
var search_start_time: float = 0.0  # When we entered herd_wildnpc (for min search duration)
const DELIVERY_COOLDOWN_SEC: float = 28.0

func _get_delivery_cooldown_sec() -> float:
	if NPCConfig and "herd_delivery_cooldown_sec" in NPCConfig:
		return NPCConfig.herd_delivery_cooldown_sec as float
	return DELIVERY_COOLDOWN_SEC

func enter() -> void:
	if not npc:
		return
	var npc_type_str: String = npc.get("npc_type") if npc else ""
	if npc_type_str != "caveman" and npc_type_str != "clansman":
		return
	var current_time: float = Time.get_ticks_msec() / 1000.0
	search_start_time = current_time
	if npc:
		npc.set_meta("entry_time", current_time)
	if NPCConfig:
		if "herd_max_no_target_time" in NPCConfig:
			max_no_target_time = NPCConfig.herd_max_no_target_time as float
	no_target_time = current_time
	var land_claim = _get_land_claim(npc.get_clan_name() if npc else "")
	if land_claim:
		search_center = land_claim.global_position
		var claim_radius_prop = land_claim.get("radius")
		var claim_radius: float = claim_radius_prop as float if claim_radius_prop != null else 400.0
		search_distance = claim_radius  # Start just outside claim
	else:
		search_center = npc.global_position if npc else Vector2.ZERO
		search_distance = 100.0
	search_angle = randf() * TAU  # Random first ray direction
	var herded_count: int = npc.herded_count if "herded_count" in npc else 0
	UnifiedLogger.log_npc("Action started: herd_wildnpc (target-less, herded_count=%d)" % herded_count, {
		"npc": npc.npc_name,
		"action": "herd_wildnpc",
		"herded_count": herded_count
	})
	if npc:
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			pi.herd_wildnpc_enter(npc.npc_name, herded_count)
	# Lead to claim immediately when we have herd (no waiting for first update)
	if herded_count > 0 and land_claim and npc.steering_agent:
		var mult: float = NPCConfig.herd_leader_speed_multiplier if NPCConfig and "herd_leader_speed_multiplier" in NPCConfig else 0.97
		npc.steering_agent.set_speed_multiplier(mult)
		npc.steering_agent.set_target_position_immediate(land_claim.global_position)

func exit() -> void:
	_cancel_tasks_if_active()
	var current_time: float = Time.get_ticks_msec() / 1000.0
	last_exit_time = current_time
	if npc:
		npc.set_meta("herd_wildnpc_last_exit_time", current_time)
	if npc:
		var clan_name_val: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
		if clan_name_val != "":
			var land_claims = npc.get_tree().get_nodes_in_group("land_claims")
			for claim in land_claims:
				if not is_instance_valid(claim):
					continue
				var claim_clan: String = claim.get("clan_name") if "clan_name" in claim else ""
				if claim_clan == clan_name_val:
					claim.remove_searcher(npc)
					break
	if npc and npc.steering_agent:
		if npc.steering_agent.has_method("restore_original_speed"):
			npc.steering_agent.restore_original_speed()
		var center: Vector2 = npc.global_position if npc else Vector2.ZERO
		npc.steering_agent.set_wander(center, 200.0)
	if npc:
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			var hc: int = npc.herded_count if "herded_count" in npc else 0
			pi.herd_wildnpc_exit(npc.npc_name, hc)
	if fsm:
		fsm.evaluation_timer = 0.0

func update(delta: float) -> void:
	if not npc:
		return
	var npc_type_str: String = npc.get("npc_type") if npc else ""
	if npc_type_str != "caveman" and npc_type_str != "clansman":
		return
	var clan_name: String = npc.get_clan_name() if npc else ""
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var herded_count: int = npc.herded_count if "herded_count" in npc else 0
	var land_claim = _get_land_claim(clan_name)

	# Dynamic search params from reproduction pressure (set by ClanBrain on land_claim)
	# Return/ray: 600 baseline (guide), 1500 max (tamed from 2400 - long rays create unstable behavior)
	var pressure: float = land_claim.get_meta("reproduction_pressure", 0.5) if land_claim else 0.5
	var return_baseline: float = 600.0
	if NPCConfig and "herd_return_to_claim_distance" in NPCConfig:
		return_baseline = NPCConfig.herd_return_to_claim_distance as float
	const RETURN_MAX: float = 1500.0  # Cap ray/return - pressure scales attempts/duration, not extreme distance
	var return_dist: float = lerpf(return_baseline, RETURN_MAX, pressure)
	var min_search_time: float = lerpf(5.0, 20.0, pressure)
	var search_elapsed: float = current_time - search_start_time

	# Exit to wander for deposit when inventory 50%+ or herded_count >= 2 and near claim
	if npc.inventory and clan_name != "":
		var used_slots: int = npc.inventory.get_used_slots() if npc.inventory.has_method("get_used_slots") else 0
		var max_slots: int = npc.inventory.slot_count if npc.inventory else 10
		var inv_full: bool = max_slots > 0 and float(used_slots) / float(max_slots) >= 0.5
		var herd_deposit_trigger: bool = herded_count >= 2
		var near_claim: bool = false
		if land_claim:
			var dist: float = npc.global_position.distance_to(land_claim.global_position)
			near_claim = dist < 150.0
		if inv_full or (herd_deposit_trigger and near_claim):
			npc.set_meta("moving_to_deposit", true)
			npc.set_meta("is_depositing", true)
			if fsm:
				fsm.change_state("wander")
			return

	# Return to claim when too far with no herd (only after min_search_time)
	# When breeding_females == 0: never exit - caveman MUST keep searching until he gets a woman
	var bf: int = land_claim.get_meta("breeding_females", 1) if land_claim else 1
	if bf > 0 and herded_count == 0 and land_claim:
		var dist_to_claim: float = npc.global_position.distance_to(land_claim.global_position)
		var past_min_search: bool = search_elapsed >= min_search_time
		if past_min_search and dist_to_claim > return_dist:
			if fsm:
				fsm.change_state("wander")
			return

	if herded_count > 0:
		# Lead to claim - use set_target_position (not immediate) to avoid zeroing velocity every frame
		# set_target_position_immediate zeros velocity each call; called every frame = herder never accelerates
		no_target_time = 0.0  # Reset - we have herd
		if npc.steering_agent:
			var mult: float = NPCConfig.herd_leader_speed_multiplier if NPCConfig and "herd_leader_speed_multiplier" in NPCConfig else 0.97
			npc.steering_agent.set_speed_multiplier(mult)
		if land_claim:
			npc.steering_agent.set_target_position(land_claim.global_position)
		return

	# Active seeking: women first, else nearest herdable
	# When breeding_females == 0: use full detection range for women so caveman can walk toward them
	var detection_range: float = 1700.0
	if NPCConfig and "herd_detection_range" in NPCConfig:
		detection_range = NPCConfig.herd_detection_range as float
	var perception_range: float = 250.0
	if NPCConfig and "herd_mentality_detection_range" in NPCConfig:
		perception_range = NPCConfig.herd_mentality_detection_range as float
	var woman_range: float = perception_range
	if bf == 0:
		woman_range = detection_range  # Must find women - use full range
	var target = _find_nearest_herdable_target(detection_range, woman_range)
	if target and is_instance_valid(target):
		no_target_time = current_time  # Have target, don't timeout
		if npc.steering_agent:
			npc.steering_agent.set_speed_multiplier(1.0)
			npc.steering_agent.set_target_position(target.global_position)
		return

	# Search pattern (herded_count == 0, no target): ray/cone - walk straight-ish lines from claim
	if search_center == Vector2.ZERO and land_claim:
		search_center = land_claim.global_position
	if npc.steering_agent:
		var ray_stride: float = 120.0  # px/s along the ray (how fast we walk outward)
		if NPCConfig and "herd_ray_stride" in NPCConfig:
			ray_stride = NPCConfig.herd_ray_stride as float
		elif NPCConfig and "herd_spiral_expansion_rate" in NPCConfig:
			ray_stride = NPCConfig.herd_spiral_expansion_rate as float * 1.5  # Legacy: convert spiral rate to stride
		# Search pattern matches return_dist (dynamic with pressure)
		var max_ray_distance: float = return_dist
		search_distance += ray_stride * delta
		if search_distance >= max_ray_distance:
			search_distance = 100.0  # Reset to near claim
			search_angle += PI / 4.0  # Next ray: 45° rotation (8 rays per sweep)
			if search_angle >= TAU:
				search_angle -= TAU
		var cone_wobble: float = sin(current_time * 1.5) * 0.12  # Slight cone sway ±7°
		var actual_angle: float = search_angle + cone_wobble
		var search_direction: Vector2 = Vector2(cos(actual_angle), sin(actual_angle))
		var search_target: Vector2 = search_center + search_direction * search_distance
		npc.steering_agent.set_target_position(search_target)
		if "speed_multiplier" in npc.steering_agent:
			npc.steering_agent.speed_multiplier = 1.0

	# Exit when no animals attached for extended timeout (only after min_search_time)
	# When breeding_females == 0: never exit - caveman MUST keep searching until he gets a woman
	if bf > 0:
		var time_without_herd: float = current_time - no_target_time
		var extended_timeout: float = max_no_target_time * 2.0
		if search_elapsed >= min_search_time and time_without_herd >= extended_timeout:
			if fsm:
				fsm.change_state("wander")
				npc.set_meta("wander_reset_timer", 1.0)
				fsm.evaluation_timer = 0.0
			return

func can_enter() -> bool:
	if not npc:
		return false
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")

	if npc.has_meta("herd_wildnpc_last_exit_time"):
		var last_exit: float = npc.get_meta("herd_wildnpc_last_exit_time")
		if current_time - last_exit < exit_cooldown:
			if pi and pi.is_enabled():
				pi.herd_wildnpc_can_enter(npc.npc_name, false, "exit_cooldown")
			return false

	if npc.has_meta("herd_wildnpc_delivery_cooldown_until"):
		var cooldown_until: float = npc.get_meta("herd_wildnpc_delivery_cooldown_until")
		if current_time < cooldown_until:
			if pi and pi.is_enabled():
				pi.herd_wildnpc_can_enter(npc.npc_name, false, "delivery_cooldown")
			return false
		npc.remove_meta("herd_wildnpc_delivery_cooldown_until")

	var npc_type_str: String = npc.get("npc_type") if npc else ""
	if npc_type_str != "caveman" and npc_type_str != "clansman":
		if pi and pi.is_enabled():
			pi.herd_wildnpc_can_enter(npc.npc_name, false, "not_caveman_or_clansman")
		return false

	# Deposit block: allow override if herdable very close (drop berries, grab target)
	if npc.has_meta("is_depositing") or npc.has_meta("moving_to_deposit"):
		var close_target = _find_nearest_herdable_target(350.0)
		if not (close_target and is_instance_valid(close_target)):
			if pi and pi.is_enabled():
				pi.herd_wildnpc_can_enter(npc.npc_name, false, "is_depositing")
			return false

	var clan_name_val: String = npc.get_clan_name() if npc else ""
	if clan_name_val == "":
		if pi and pi.is_enabled():
			pi.herd_wildnpc_can_enter(npc.npc_name, false, "no_land_claim")
		return false

	# Active herder cap: max NPCs in herd_wildnpc at once (prevents swarm)
	var land_claim = _get_land_claim(clan_name_val)
	if land_claim and is_instance_valid(land_claim):
		var max_herders: int = land_claim.get_meta("max_active_herders", 2)
		var active_herders: int = _count_clan_in_herd_wildnpc(clan_name_val)
		if active_herders >= max_herders:
			if pi and pi.is_enabled():
				pi.herd_wildnpc_can_enter(npc.npc_name, false, "max_active_herders")
			return false

	# Searcher quota
	var land_claims = npc.get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan: String = claim.get("clan_name") if "clan_name" in claim else ""
		if claim_clan != clan_name_val:
			continue
		var already_searcher: bool = npc in claim.assigned_searchers
		if not already_searcher:
			var quota: int = claim.get_meta("searcher_quota", 1)
			claim._prune_searchers()
			var current_count: int = claim.assigned_searchers.size()
			var defenders_can_search: bool = claim.get_meta("defenders_can_search", true)
			var is_defender: bool = npc in claim.assigned_defenders
			if current_count >= quota and not (defenders_can_search and is_defender):
				if pi and pi.is_enabled():
					pi.herd_wildnpc_can_enter(npc.npc_name, false, "searcher_quota_full")
				return false
			claim.add_searcher(npc)
		break

	if npc.inventory:
		var inventory_slots: int = npc.inventory.get("slot_count") if npc.inventory else 10
		var used_slots: int = npc.inventory.get_used_slots() if npc.inventory.has_method("get_used_slots") else 0
		var threshold: float = 0.65
		if NPCConfig and "herd_inventory_entry_threshold" in NPCConfig:
			threshold = NPCConfig.herd_inventory_entry_threshold as float
		if inventory_slots > 0 and float(used_slots) / float(inventory_slots) >= threshold:
			if pi and pi.is_enabled():
				pi.herd_wildnpc_can_enter(npc.npc_name, false, "inventory_full")
			return false

	# Re-entry: must be within 90% of max distance from claim
	land_claim = _get_land_claim(clan_name_val)
	if land_claim and is_instance_valid(land_claim):
		var npc_to_claim: float = npc.global_position.distance_to(land_claim.global_position)
		var base_max_distance: float = 2000.0
		if NPCConfig and "herd_max_distance_from_claim" in NPCConfig:
			base_max_distance = NPCConfig.herd_max_distance_from_claim as float
		if npc_to_claim > base_max_distance * 0.9:
			if pi and pi.is_enabled():
				pi.herd_wildnpc_can_enter(npc.npc_name, false, "too_far_from_claim")
			return false

	if pi and pi.is_enabled():
		pi.herd_wildnpc_can_enter(npc.npc_name, true, "ok")
	return true

func get_priority() -> float:
	if not npc:
		return 0.0
	var base: float = 11.5
	var woman_priority: float = 12.0
	if NPCConfig:
		if "priority_herd_wildnpc" in NPCConfig:
			base = NPCConfig.priority_herd_wildnpc as float
		if "priority_herd_wildnpc_woman" in NPCConfig:
			woman_priority = NPCConfig.priority_herd_wildnpc_woman as float
	# If herded_count > 0, we're leading - use woman priority if any follower is a woman
	var herded_count: int = npc.herded_count if "herded_count" in npc else 0
	if herded_count > 0:
		if _is_leading_woman():
			return woman_priority
		return base
	# No herd: check for valid target; if target CLOSE use woman/base priority
	# If target is FAR (>500px), use searching priority
	# If NO target at all: use no_target priority (below gather) so cavemen GATHER instead of walking empty rays
	var detection_range: float = 1700.0
	if NPCConfig and "herd_detection_range" in NPCConfig:
		detection_range = NPCConfig.herd_detection_range as float
	const CLOSE_TARGET_RANGE: float = 500.0  # Within this: high priority (go herd). Beyond: low (gather)
	var target = _find_nearest_herdable_target(detection_range)
	if target and is_instance_valid(target):
		var d: float = npc.global_position.distance_to(target.global_position)
		if d <= CLOSE_TARGET_RANGE:
			var otype: String = target.get("npc_type") as String if target.get("npc_type") != null else ""
			if otype == "woman":
				return woman_priority
			return base
		# Target exists but far - use searching priority; boost when clan needs women (reproduction_pressure high)
		var searching: float = 5.5
		if NPCConfig and "priority_herd_wildnpc_searching" in NPCConfig:
			searching = NPCConfig.priority_herd_wildnpc_searching as float
		var land_claim_node = _get_land_claim(npc.get_clan_name() if npc.has_method("get_clan_name") else "")
		if land_claim_node:
			var pressure: float = land_claim_node.get_meta("reproduction_pressure", 0.5)
			if pressure >= 0.8:
				searching = 6.1  # Beat gather when clan needs women
		return searching
	# NO target in range: use low priority so gather (5.8) wins - cavemen gather instead of walking empty rays
	const NO_TARGET_PRIORITY: float = 5.2  # Below gather 5.8 - stay productive
	return NO_TARGET_PRIORITY

func _is_leading_woman() -> bool:
	"""True if any NPC currently following this herder is a woman."""
	if not npc:
		return false
	var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
	for other in all_npcs:
		if not is_instance_valid(other) or other == npc:
			continue
		var h = other.get("herder") if "herder" in other else null
		if h != npc:
			continue
		var otype: String = other.get("npc_type") as String if other.get("npc_type") != null else ""
		if otype == "woman":
			return true
	return false

func _count_clan_in_herd_wildnpc(clan_name: String) -> int:
	"""Count clan NPCs currently in herd_wildnpc state (active herders)."""
	if not npc or not npc.get_tree():
		return 0
	var count: int = 0
	var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
	for other in all_npcs:
		if not is_instance_valid(other) or (other.has_method("is_dead") and other.is_dead()):
			continue
		var oc: String = other.get_clan_name() if other.has_method("get_clan_name") else (str(other.get("clan_name")) if other.get("clan_name") != null else "")
		if oc != clan_name:
			continue
		var fsm = other.get("fsm")
		if fsm and fsm.has_method("get_current_state_name") and fsm.get_current_state_name() == "herd_wildnpc":
			count += 1
	return count

func _get_land_claim(clan_name: String) -> Node2D:
	if not npc:
		return null
	var land_claims = npc.get_tree().get_nodes_in_group("land_claims")
	for claim in land_claims:
		if not is_instance_valid(claim):
			continue
		var claim_clan_prop = claim.get("clan_name")
		var claim_clan: String = claim_clan_prop as String if claim_clan_prop != null else ""
		if claim_clan == clan_name:
			return claim
	return null

func _find_nearest_herdable_target(max_range: float, perception_range: float = 250.0) -> Node2D:
	"""Hard-prioritize women within perception; else nearest herdable in full range. Uses PerceptionArea when range <= AOP (380px)."""
	if not npc:
		return null
	var npc_pos: Vector2 = npc.global_position
	var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
	var aop_radius: float = 380.0
	if NPCConfig and "aop_radius_default" in NPCConfig:
		aop_radius = NPCConfig.aop_radius_default as float

	# 1. Woman within perception_range (reproduction resource)
	if pa and perception_range <= aop_radius:
		var herdables = pa.get_herdables_in_range(npc_pos, perception_range, npc)
		for h in herdables:
			if h.get("npc_type") == "woman":
				return h
	else:
		var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
		var woman: Node2D = _find_nearest_wild_in_range(all_npcs, npc_pos, perception_range, "woman")
		if woman:
			return woman

	# 2. Sheep/goat within max_range (economic resource)
	if pa and max_range <= aop_radius:
		var herdables = pa.get_herdables_in_range(npc_pos, max_range, npc)
		for h in herdables:
			if h.get("npc_type") in ["sheep", "goat"]:
				return h
	else:
		var all_npcs = npc.get_tree().get_nodes_in_group("npcs")
		return _find_nearest_wild_in_range(all_npcs, npc_pos, max_range, "sheep", "goat")
	return null

func _find_nearest_wild_in_range(all_npcs: Array, npc_pos: Vector2, max_range: float, type_a: String, type_b: String = "") -> Node2D:
	"""Find closest wild NPC of given type(s) within max_range. type_b optional for woman-only."""
	if not npc:
		return null
	var best: Node2D = null
	var best_dist: float = INF
	var types: Array = [type_a]
	if type_b != "":
		types.append(type_b)
	for other in all_npcs:
		if not is_instance_valid(other) or other == npc:
			continue
		var otype: String = other.get("npc_type") as String if other.get("npc_type") != null else ""
		if otype not in types:
			continue
		var clan: String = other.get("clan_name") as String if other.get("clan_name") != null else ""
		if clan != "":
			continue
		if other.has_method("can_join_clan") and not other.can_join_clan():
			continue
		var d: float = npc_pos.distance_to(other.global_position)
		if d <= max_range and d < best_dist:
			best_dist = d
			best = other as Node2D
	return best
