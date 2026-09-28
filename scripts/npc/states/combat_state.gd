extends "res://scripts/npc/states/base_state.gd"

# Preload PerceptionArea so it resolves (avoids "Could not find type" when run from CLI)
const PerceptionArea = preload("res://scripts/npc/components/perception_area.gd")
const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")
const FightFlight = preload("res://scripts/combat/fight_flight.gd")
const CombatTargetPick = preload("res://scripts/combat/combat_target_pick.gd")
const WeaponOverlayCombat = preload("res://scripts/systems/weapon_overlay_combat.gd")
const ThrowHitResolver = preload("res://scripts/combat/throw_hit_resolver.gd")
const CombatStance = preload("res://scripts/systems/combat_stance.gd")

# Combat State - NPCs attack enemies when agro_meter >= 70
# Agro meter increases when attacked, decreases over time when not in combat

var combat_target: Node2D = null  # NPCBase or player when defending vs intruders
var attack_range: float = 100.0
const TARGET_CHECK_INTERVAL := 2.0  # Check for new targets every 2 seconds (reduced frequency)
var next_target_check_time := 0
var _next_flee_check_sec: float = 0.0

# Defenders: max distance from claim center to chase (prevents kiting)
const DEFENDER_PURSUIT_FACTOR := 1.4  # claim_radius * this = max chase distance (e.g. 560px for 400 radius)
static var _raid_blocked_logged: bool = false

func _clear_combat_target_and_exit() -> void:
	"""Clear combat target and force FSM re-evaluation (used when target is invalid e.g. player when following)."""
	clear_npc_combat_target()
	if fsm and fsm.has_method("force_evaluation"):
		fsm.force_evaluation()
	combat_target = null

func enter() -> void:
	if not npc:
		return
	_next_flee_check_sec = 0.0
	
	# Task System - Step 18: Cancel current job when entering combat
	_cancel_tasks_if_active()
	if npc and npc.task_runner and npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		var npc_name_safe: String = "unknown"
		if npc:
			var name_val = npc.get("npc_name")
			if name_val != null:
				npc_name_safe = str(name_val)
		UnifiedLogger.log_npc("COMBAT: %s cancelled gather job due to combat" % npc_name_safe, {
			"npc": npc_name_safe,
			"event": "job_cancelled_combat"
		})
	
	# Get combat target (set by FSM or intrusion) — NPCBase or player
	var target_prop = npc.get("combat_target")
	if target_prop != null and target_prop is Node2D:
		combat_target = target_prop as Node2D
	
	# Never enter combat vs allies (clan, herder, shared claim, player membership — see CombatAllyCheck)
	if combat_target and npc and is_instance_valid(combat_target) and CombatAllyCheck.is_ally(npc, combat_target):
		_clear_combat_target_and_exit()
		return
	
	# Set target in combat component
	var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
	if combat_comp:
		combat_comp.set_target(combat_target)
	_next_flee_check_sec = Time.get_ticks_msec() / 1000.0 + 1.5
	
	var target_name: String = "none"
	var npc_clan: String = ""
	var target_clan: String = ""
	if npc:
		npc_clan = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if combat_target:
		if combat_target is NPCBase:
			target_name = combat_target.npc_name
			target_clan = combat_target.get_clan_name() if combat_target.has_method("get_clan_name") else ""
		elif combat_target.is_in_group("player"):
			target_name = "Player"
			target_clan = combat_target.get_clan_name() if combat_target.has_method("get_clan_name") else ""
		else:
			target_name = "unknown"
	# Only log combat entry once (not every frame)
	var last_combat_entry = npc.get_meta("last_combat_entry_logged", null) if npc and npc.has_meta("last_combat_entry_logged") else null
	if not last_combat_entry or last_combat_entry != combat_target:
		var npc_name_safe: String = "NPC"
		if npc and is_instance_valid(npc):
			var name_val = npc.get("npc_name")
			if name_val != null:
				npc_name_safe = str(name_val)
		UnifiedLogger.log(
			"COMBAT state enter: %s target=%s clans=%s/%s" % [npc_name_safe, target_name, npc_clan, target_clan],
			UnifiedLogger.Category.COMBAT,
			UnifiedLogger.Level.DEBUG
		)
		if npc:
			npc.set_meta("last_combat_entry_logged", combat_target)
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			var ff: bool = combat_target != null and is_instance_valid(combat_target) and CombatAllyCheck.is_ally(npc, combat_target)
			var extras: Dictionary = {}
			if pi.has_method("morale_of"):
				extras = pi.morale_of(npc)
			pi.combat_started(npc_name_safe, target_name, npc_clan, target_clan, ff, extras)
		var phi_enter := npc.get_node_or_null("/root/PartyHuntInstrument")
		if phi_enter and phi_enter.has_method("note_fight_enter"):
			phi_enter.note_fight_enter(npc, combat_target)
	
	if npc.hostile_indicator:
		npc.hostile_indicator.visible = true
	
	if npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()

func refuses_entry_for_break() -> bool:
	## A score that is already a break. The state machine sends him to the run instead.
	## A chaser stays, because a pursuit target clears the break.
	if not npc:
		return false
	var raw: Variant = npc.get("combat_target")
	if raw is Node2D and is_instance_valid(raw):
		combat_target = raw as Node2D
	if _flee_reason() == "":
		return false
	if combat_target and is_instance_valid(combat_target):
		npc.set_meta("flee_from_position", combat_target.global_position)
	return true


func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		var next_state: String = str(npc.get_meta("fsm_next_state", ""))
		var leaving_for_flee: bool = next_state == "flee_combat"
		var fought_person: bool = _is_person_body(combat_target) and is_attack_target_alive(combat_target)
		if leaving_for_flee and combat_target and is_instance_valid(combat_target):
			npc.set_meta("flee_from_position", combat_target.global_position)
		if leaving_for_flee or fought_person:
			npc.set_meta("hunt_after_combat", false)
		var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
		if combat_comp:
			if combat_comp.state == CombatComponent.CombatState.READY:
				combat_comp.cancel_ready()
			combat_comp.clear_target()
		# CRITICAL: Clear combat_target when exiting combat state
		# This prevents NPCs from retaining invalid targets (like dead enemies or same-clan players)
		npc.set("combat_target_id", -1)
		npc.set("combat_target", null)
		combat_target = null
		if "combat_target_id" in npc:
			npc.combat_target_id = -1
		if npc.hostile_indicator:
			npc.hostile_indicator.visible = false
		if npc.has_meta("pursue_logged_id"):
			npc.remove_meta("pursue_logged_id")
		if npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
			npc.steering_agent.restore_original_speed()
		if npc.steering_agent and npc.steering_agent.has_method("hold_still"):
			npc.steering_agent.hold_still()
		if npc.has_method("reset_agro_after_combat"):
			npc.reset_agro_after_combat()
			var pi_ar: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi_ar and pi_ar.is_enabled():
				var _ctx_ar: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
				var _mode_ar: String = str(_ctx_ar.get("mode", "NONE"))
				var _new_agro: float = npc.get("agro_meter") as float if npc.get("agro_meter") != null else 0.0
				pi_ar.clansman_agro_reset(str(npc.get("npc_name")), _mode_ar, _new_agro)
		# Clear combat entry logging meta when exiting
		if npc.has_meta("last_combat_entry_logged"):
			npc.remove_meta("last_combat_entry_logged")
		if npc.has_meta("allow_last_spear_throw"):
			npc.remove_meta("allow_last_spear_throw")
		_try_nomad_rejoin_after_combat()
		# Safe access to npc_name (might be null if NPC is being destroyed)
		var npc_name_str: String = "unknown"
		if npc and is_instance_valid(npc):
			var name_value = npc.get("npc_name")
			if name_value != null:
				npc_name_str = str(name_value)
		UnifiedLogger.log("COMBAT state exit: %s" % npc_name_str, UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.DEBUG)
		var pi = npc.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			pi.combat_ended(npc_name_str, "unknown")
		# Hunt party: resume hunt only after the animal fight. A person fight or a run does not.
		if npc.get_meta("hunt_after_combat", false) == true and str(npc.get_meta("fsm_next_state", "")) != "flee_combat":
			npc.set_meta("hunt_after_combat", false)
			if fsm:
				fsm.change_state("hunt", true)
			return

func update(_delta: float) -> void:
	if not npc:
		return
	
	# Check if dead
	var health_comp: HealthComponent = npc.get_node_or_null("HealthComponent")
	if health_comp and health_comp.is_dead:
		return
	
	# Step 3: Resolve combat_target from combat_target_id; invalid target → agro 69, clear intent
	combat_target = npc.resolve_combat_target() as Node2D
	if combat_target and not is_attack_target_alive(combat_target):
		var corpse_node: Node2D = combat_target
		var resume_hunt: bool = npc.get_meta("hunt_after_combat", false)
		if npc.has_method("end_fight_target_dead"):
			npc.end_fight_target_dead(corpse_node)
		else:
			clear_npc_combat_target()
		combat_target = null
		if resume_hunt and fsm:
			_notify_hunt_prey_dead_loot(corpse_node)
			fsm.change_state("hunt", true)
		elif fsm and fsm.has_method("force_evaluation"):
			fsm.force_evaluation()
		return
	if not combat_target:
		if npc.has_method("leave_combat_lost_target"):
			npc.leave_combat_lost_target()
		elif fsm and fsm.has_method("force_evaluation"):
			fsm.force_evaluation()
		return

	var now_sec_f: float = Time.get_ticks_msec() / 1000.0
	var flee_iv: float = 1.5
	if NPCConfig:
		flee_iv = maxf(NPCConfig.flee_check_interval_sec, 1.5)
	# A swing is 0.45s windup plus 0.8s recovery. Do not pull him out mid-attack.
	if now_sec_f >= _next_flee_check_sec and not _strike_in_progress():
		_next_flee_check_sec = now_sec_f + flee_iv
		var flee_why: String = _flee_reason()
		if flee_why != "":
			var pi_fd = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi_fd and pi_fd.has_method("is_enabled") and pi_fd.is_enabled() and pi_fd.has_method("flee_decide"):
				if not bool(npc.get_meta("_flee_decide_logged", false)):
					npc.set_meta("_flee_decide_logged", true)
					var pay: Dictionary = {}
					if pi_fd.has_method("morale_of"):
						pay = pi_fd.morale_of(npc)
					pay["npc"] = str(npc.get("npc_name"))
					pay["clan"] = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
					pay["rule"] = flee_why
					if npc.has_meta("_flee_counts"):
						var fc: Variant = npc.get_meta("_flee_counts")
						if fc is Dictionary:
							pay["enemies"] = int(fc.get("enemies", 0))
							pay["allies"] = int(fc.get("allies", 0))
							pay["routing_allies"] = int(fc.get("routing_allies", 0))
					pi_fd.flee_decide(pay)
			var phi_br := npc.get_node_or_null("/root/PartyHuntInstrument")
			if phi_br and phi_br.has_method("note_fight_break"):
				phi_br.note_fight_break(npc, flee_why, combat_target)
			if fsm:
				fsm.change_state("flee_combat")
			return

	# Defenders: don't chase too far from border (prevents kiting)
	if combat_target and is_instance_valid(combat_target):
		var dt = npc.get("defend_target")
		if dt and is_instance_valid(dt):
			var claim_pos: Vector2 = dt.global_position
			var rp = dt.get("radius")
			var claim_radius: float = rp as float if rp != null else 400.0
			var pursuit_limit: float = claim_radius * DEFENDER_PURSUIT_FACTOR
			var target_dist: float = claim_pos.distance_to(combat_target.global_position)
			if target_dist > pursuit_limit:
				npc.set("combat_target_id", -1)
				npc.set("combat_target", null)
				combat_target = null
				if "combat_target_id" in npc:
					npc.combat_target_id = -1
				var combat_comp_drop: CombatComponent = npc.get_node_or_null("CombatComponent")
				if combat_comp_drop:
					combat_comp_drop.clear_target()
				if fsm and fsm.has_method("force_evaluation"):
					fsm.force_evaluation()
				return
	
	var pursuit_now: Node2D = _find_pursuit_target()
	if pursuit_now == null and npc.has_meta("pursue_logged_id"):
		npc.remove_meta("pursue_logged_id")
		if npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
			npc.steering_agent.restore_original_speed()
	# Ordered followers: don't chase beyond mode-specific distance from leader.
	# A routing man is finished, so the short leash does not drop that chase.
	if pursuit_now == null and npc.has_meta("village_defense") and npc.get("follow_is_ordered") and npc.get("herder") and is_instance_valid(npc.get("herder")):
		var held_leader: Vector2 = npc.herder.global_position
		var held_dist: float = npc.global_position.distance_to(held_leader)
		var held_ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
		var held_mode: String = str(held_ctx.get("mode", "FOLLOW"))
		var held_max: float = 150.0
		if _npc_has_spare_ranged():
			held_max = _npc_active_throw_range()
		elif held_mode == "GUARD":
			held_max = 200.0
		elif held_mode == "ATTACK":
			held_max = 400.0
		if held_dist > held_max and not bool(npc.get_meta("village_leash_logged", false)):
			npc.set_meta("village_leash_logged", true)
			print("NPC_VILLAGE_LEASH name=%s dist=%.0f max=%.0f" % [str(npc.get("npc_name")), held_dist, held_max])
	if pursuit_now == null and not npc.has_meta("village_defense") and npc.get("follow_is_ordered") and npc.get("herder") and is_instance_valid(npc.get("herder")):
		var leader_pos: Vector2 = npc.herder.global_position
		var dist_from_leader: float = npc.global_position.distance_to(leader_pos)
		var ctx_leash: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
		var mode_leash: String = str(ctx_leash.get("mode", "FOLLOW"))
		var max_chase: float = 150.0
		if _npc_has_spare_ranged():
			max_chase = _npc_active_throw_range()
		elif mode_leash == "GUARD":
			max_chase = 200.0
		elif mode_leash == "ATTACK":
			max_chase = 400.0
		if dist_from_leader > max_chase:
			var pi_lb: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi_lb and pi_lb.is_enabled():
				pi_lb.clansman_leash_break(str(npc.get("npc_name")), mode_leash, dist_from_leader, max_chase)
			_clear_combat_target_and_exit()
			var phi_leash := npc.get_node_or_null("/root/PartyHuntInstrument")
			if phi_leash and phi_leash.has_method("note_leash"):
				phi_leash.note_leash(npc, mode_leash, dist_from_leader, max_chase)
			return
	
	# CRITICAL: Combat takes priority over following - life over orders
	# Even if NPC is following, combat (12.0) beats following (11.0)
	# This ensures NPCs defend themselves even when ordered to follow
	
	# OPTIMIZATION: Tasks are cancelled on enter() - no need to cancel every frame
	# Removed per-frame _cancel_tasks_if_active() call for performance
	
	# Log position for combat state (throttled to once per second)
	var now = Time.get_ticks_msec()
	if not npc.has_meta("last_combat_position_log"):
		npc.set_meta("last_combat_position_log", 0)
	var last_log = npc.get_meta("last_combat_position_log", 0)
	if now - last_log >= 1000:  # Log once per second
		var velocity = npc.get("velocity") as Vector2 if npc.has_method("get") else Vector2.ZERO
		var velocity_magnitude = velocity.length() if velocity else 0.0
		var distance_to_claim = 0.0
		var claim_radius = 400.0
		# Try to get land claim info if available
		var land_claims = npc.get_tree().get_nodes_in_group("land_claims") if npc.get_tree() else []
		for claim in land_claims:
			if claim and is_instance_valid(claim):
				var claim_clan = claim.get("clan_name") if claim else ""
				var npc_clan = npc.get("clan_name") if npc.has_method("get") else ""
				if claim_clan == npc_clan and npc_clan != "":
					var claim_pos = claim.global_position if claim else Vector2.ZERO
					distance_to_claim = npc.global_position.distance_to(claim_pos)
					claim_radius = claim.get("radius") if claim else 400.0
					break
		var npc_name_safe: String = "unknown"
		var npc_pos_x: float = 0.0
		var npc_pos_y: float = 0.0
		if npc and is_instance_valid(npc):
			var name_val = npc.get("npc_name")
			if name_val != null:
				npc_name_safe = str(name_val)
			npc_pos_x = npc.global_position.x
			npc_pos_y = npc.global_position.y
		UnifiedLogger.log_npc("POSITION: %s at (%.1f, %.1f), state=combat, distance_to_claim=%.1f/%.1f, velocity=%.1f" % [
			npc_name_safe,
			npc_pos_x,
			npc_pos_y,
			distance_to_claim,
			claim_radius,
			velocity_magnitude
		], {
			"npc": npc_name_safe,
			"pos": "%f,%f" % [npc_pos_x, npc_pos_y],
			"state": "combat",
			"distance_to_claim": distance_to_claim,
			"claim_radius": claim_radius,
			"velocity": velocity_magnitude
		})
		npc.set_meta("last_combat_position_log", now)
	
	# Update targeting (with throttling)
	_update_targeting()
	_hold_volley_target()
	
	if not combat_target or not is_instance_valid(combat_target):
		return
	
	# Get combat component for attack range
	var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
	var optimal_attack_range = combat_comp.attack_range if combat_comp else attack_range
	
	# Calculate distances and direction
	var distance = npc.global_position.distance_to(combat_target.global_position)
	if pursuit_now != null:
		_run_down_router(pursuit_now, combat_comp, distance)
		return
	if _npc_has_spare_ranged():
		_try_ranged_throw(combat_comp, distance, optimal_attack_range)
		return
	if _try_ranged_throw(combat_comp, distance, optimal_attack_range):
		return
	if _npc_throw_ammo_type() == ResourceData.ResourceType.NONE and is_attack_target_alive(combat_target):
		_note_melee_step()
	var direction_to_target = (combat_target.global_position - npc.global_position).normalized()
	var stance: String = CombatStance.decide(distance, optimal_attack_range)
	if stance == "hold":
		if _stalemate_should_break(combat_target):
			if CombatTick and CombatTick.has_method("break_contact"):
				CombatTick.break_contact(npc)
			return
		if npc.steering_agent and npc.steering_agent.has_method("hold_still"):
			npc.steering_agent.hold_still()
	else:
		if npc.has_meta("_fight_stale_since"):
			npc.remove_meta("_fight_stale_since")
		if npc.steering_agent and npc.steering_agent.has_method("retarget_seek"):
			var stand_at: Vector2 = CombatStance.approach_point(npc.global_position, combat_target.global_position, optimal_attack_range)
			npc.steering_agent.retarget_seek(stand_at)
	if stance == "hold" and combat_comp and distance <= combat_comp.attack_range:
		if combat_comp.state == CombatComponent.CombatState.READY:
			now = Time.get_ticks_msec()
			if not npc.has_meta("last_attack_request_time"):
				npc.set_meta("last_attack_request_time", 0)
			var last_attack_time: int = npc.get_meta("last_attack_request_time", 0)
			if now - last_attack_time >= 220:
				combat_comp.commit_strike(direction_to_target)
				npc.set_meta("last_attack_request_time", now)
		elif combat_comp.state == CombatComponent.CombatState.IDLE and not combat_comp._uses_overlay_combat():
			var sprite: Sprite2D = npc.get_node_or_null("Sprite")
			var facing_dir: Vector2 = Vector2(1, 0)
			if sprite:
				facing_dir = Vector2(-1 if sprite.flip_h else 1, 0)
			if abs(direction_to_target.angle_to(facing_dir)) < PI / 1.8:
				now = Time.get_ticks_msec()
				if not npc.has_meta("last_attack_request_time"):
					npc.set_meta("last_attack_request_time", 0)
				var last_attack_time: int = npc.get_meta("last_attack_request_time", 0)
				if now - last_attack_time >= 220:
					combat_comp.request_attack(combat_target)
					npc.set_meta("last_attack_request_time", now)

func _hp_of(body: Node) -> int:
	if body == null or not is_instance_valid(body):
		return -1
	var hc: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null:
		return -1
	return int(hc.current_hp)


func _stalemate_should_break(target: Node2D) -> bool:
	## Close, and nobody's HP has moved. A real hit resets the clock.
	if npc == null or target == null:
		return false
	var stamp: int = _hp_of(npc) * 1000 + _hp_of(target)
	var now: float = Time.get_ticks_msec() / 1000.0
	var last: int = int(npc.get_meta("_fight_stale_hp", stamp)) if npc.has_meta("_fight_stale_hp") else stamp
	if stamp != last or not npc.has_meta("_fight_stale_since"):
		npc.set_meta("_fight_stale_hp", stamp)
		npc.set_meta("_fight_stale_since", now)
		return false
	var limit: float = 6.0
	if NPCConfig and NPCConfig.get("agro_stalemate_seconds") != null:
		limit = float(NPCConfig.agro_stalemate_seconds)
	return CombatStance.stalemate_break(now - float(npc.get_meta("_fight_stale_since")), limit, false)


func _update_targeting() -> void:
	if combat_target and is_instance_valid(combat_target) and CombatStance.keep_target(_is_target_still_valid(combat_target)):
		var focus: int = CombatTargetPick.count_allies_focusing_on(npc, combat_target)
		if focus < 2:
			return
		var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
		if pa:
			var better: Node = CombatTargetPick.pick_from_perception(pa, npc.global_position, npc)
			if better != null and better != combat_target:
				var new_focus: int = CombatTargetPick.count_allies_focusing_on(npc, better)
				if new_focus + 1 < focus:
					_log_spread_target_swap(combat_target, better, focus)
					_assign_combat_target(better)
					return
		return
	
	# Throttle target checks to reduce frequency (2 seconds instead of 1)
	var now = Time.get_ticks_msec()
	if now < next_target_check_time:
		# Early exit if we have a valid target and check time hasn't elapsed
		if combat_target and is_instance_valid(combat_target):
			if _is_target_still_valid(combat_target):
				return
	
	# Update check time
	next_target_check_time = now + int(TARGET_CHECK_INTERVAL * 1000)
	
	# Re-validate existing target before searching for new one
	if combat_target and is_instance_valid(combat_target):
		if _is_target_still_valid(combat_target):
			return
	
	# Target invalid or missing - find new one
	_find_nearest_enemy()


func _assign_combat_target(target: Node2D) -> void:
	if not npc or target == null or not is_instance_valid(target):
		return
	var old: Node2D = combat_target
	combat_target = target
	var tid: int = EntityRegistry.get_id(combat_target) if EntityRegistry else -1
	npc.set("combat_target_id", tid)
	npc.set("combat_target", combat_target)
	if "combat_target_id" in npc:
		npc.combat_target_id = tid
	if npc.has_method("assign_combat_target_node"):
		npc.assign_combat_target_node(target)
	var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
	if combat_comp:
		combat_comp.set_target(combat_target)


func _log_spread_target_swap(old_t: Node2D, new_t: Node2D, allies_on_old: int) -> void:
	if npc == null or old_t == null or new_t == null:
		return
	if not _is_living_enemy_person(old_t) or not _is_living_enemy_person(new_t):
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(npc.get_meta("npc_target_log_time", 0.0)) < 1.5:
		return
	npc.set_meta("npc_target_log_time", now)
	var oname: String = str(old_t.get("npc_name")) if old_t.get("npc_name") != null else "?"
	var nname: String = str(new_t.get("npc_name")) if new_t.get("npc_name") != null else "?"
	print("NPC_TARGET name=%s old=%s new=%s allies_on_old=%d" % [
		str(npc.get("npc_name")), oname, nname, allies_on_old
	])


func _is_living_enemy_person(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if CombatAllyCheck.is_ally(npc, body):
		return false
	if body.has_method("is_dead") and body.is_dead():
		return false
	var hp: Node = body.get_node_or_null("HealthComponent")
	if hp and bool(hp.get("is_dead")):
		return false
	if body.is_in_group("player"):
		return true
	var kind: String = str(body.get("npc_type")) if body.get("npc_type") != null else ""
	return kind == "caveman" or kind == "clansman"

func _notify_hunt_prey_dead_loot(corpse: Node) -> void:
	if not npc or not corpse or not is_instance_valid(corpse):
		return
	var claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not claim or not is_instance_valid(claim):
		return
	var brain = claim.get_clan_brain() if claim.has_method("get_clan_brain") else null
	if brain and brain.has_method("open_corpse_job_site"):
		brain.open_corpse_job_site(corpse)

func _target_display_name(t: Node2D) -> String:
	if not t or not is_instance_valid(t):
		return "unknown"
	if t is NPCBase:
		return (t as NPCBase).npc_name
	if t.is_in_group("player"):
		return "Player"
	return "unknown"

func _is_target_still_valid(t: Node2D) -> bool:
	if not is_attack_target_alive(t):
		return false
	# Never target the player if we're following them, same clan, or defending/searching their claim
	if t.is_in_group("player") and npc:
		var herder_val = npc.get("herder")
		if herder_val == t:
			return false  # Invalid: we're following the player, can't attack them
		if npc.has_method("get_clan_name") and t.has_method("get_clan_name"):
			var npc_clan = npc.get_clan_name()
			var player_clan = t.get_clan_name()
			if npc_clan != "" and npc_clan == player_clan:
				return false  # Invalid: same clan as player
		# Defending or searching player's claim = player's clansman, never attack
		var dt = npc.get("defend_target")
		var shc = npc.get("search_home_claim")
		if (dt != null and is_instance_valid(dt) and dt.get("player_owned") == true) or (shc != null and is_instance_valid(shc) and shc.get("player_owned") == true):
			return false
		return true  # Player is valid target (not following, different clan, not player's clansman)
	# NPC target: same-clan allies invalid (e.g. joined clan mid-fight)
	if not t.is_in_group("player") and npc:
		if npc.has_method("get_clan_name") and t.has_method("get_clan_name"):
			var my_c: String = npc.get_clan_name()
			var tgt_c: String = t.get_clan_name()
			if my_c != "" and tgt_c != "" and my_c == tgt_c:
				return false
	return true

func _stance_combat_agro_threshold() -> float:
	"""Defenders / non-ordered: 70. Ordered: FOLLOW 90, GUARD 70, ATTACK 50."""
	if not npc or not npc.get("follow_is_ordered"):
		return 70.0
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var mode: String = str(ctx.get("mode", "FOLLOW"))
	if mode == "GUARD":
		return 70.0
	elif mode == "ATTACK":
		return 50.0
	return 90.0

func can_enter() -> bool:
	if not npc:
		return false
	var nt_combat: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if NPCConfig and NPCConfig.is_passive_hunt_prey(nt_combat):
		return false
	var health_comp: HealthComponent = npc.get_node_or_null("HealthComponent")
	if health_comp and health_comp.is_dead:
		return false
	if FightFlight.is_woman(npc):
		return false
	# After fleeing, need agro to refill past stance threshold again (avoids combat/flee flip)
	if npc.has_meta("last_flee_combat_time"):
		var lf: float = float(npc.get_meta("last_flee_combat_time", 0.0))
		var cd: float = 10.0
		if NPCConfig:
			cd = NPCConfig.flee_combat_cooldown
		var am_now: float = npc.get("agro_meter") as float if npc.get("agro_meter") != null else 0.0
		var thr: float = _stance_combat_agro_threshold()
		if Time.get_ticks_msec() / 1000.0 - lf < cd and am_now < thr:
			return false
	
	if npc.has_method("is_fight_over_latched") and npc.is_fight_over_latched():
		return false
	if FightFlight.ordered_mode(npc) == "FOLLOW":
		var held = npc.get("combat_target")
		if held != null and is_instance_valid(held) and _is_target_still_valid(held):
			combat_target = held as Node2D
			return true
		return false
	# If combat_target already set (e.g. intrusion → player), validate it first
	var combat_target_prop = npc.get("combat_target")
	if combat_target_prop != null and is_instance_valid(combat_target_prop):
		combat_target = combat_target_prop as Node2D
		# CRITICAL: Validate target before allowing entry (prevents attacking player/friends)
		var target_valid: bool = _is_target_still_valid(combat_target)
		if target_valid:
			return true
		else:
			# Invalid/dead target — do not evaluate here (would recurse).
			npc.set("combat_target", null)
			npc.set("combat_target_id", -1)
			combat_target = null
	
	# When combat is disabled (testing), never enter combat
	if NPCConfig and NPCConfig.get("combat_disabled"):
		return false
	
	# Check if agro meets stance threshold (ordered followers: FOLLOW 90 / GUARD 70 / ATTACK 50)
	var agro_meter_prop = npc.get("agro_meter")
	var agro_meter: float = agro_meter_prop as float if agro_meter_prop != null else 0.0
	var agro_thr: float = _stance_combat_agro_threshold()
	
	# Debug logging (disabled to reduce console spam)
	# var npc_name = npc.get("npc_name") if npc else "unknown"
	# print("🔍 COMBAT_STATE: can_enter() check for %s - agro_meter=%.1f" % [npc_name, agro_meter])
	
	if agro_meter < agro_thr and npc.get("follow_is_ordered"):
		var _last_blocked_agro: float = npc.get_meta("_combat_blocked_last_agro", -1.0) if npc.has_meta("_combat_blocked_last_agro") else -1.0
		if abs(agro_meter - _last_blocked_agro) > 2.0:
			npc.set_meta("_combat_blocked_last_agro", agro_meter)
			var pi_cb: Node = npc.get_node_or_null("/root/PlaytestInstrumentor")
			if pi_cb and pi_cb.is_enabled():
				var _ctx_cb: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
				pi_cb.clansman_combat_blocked(str(npc.get("npc_name")), str(_ctx_cb.get("mode", "FOLLOW")), agro_meter, agro_thr)
	if agro_meter >= agro_thr:
		# Use PerceptionArea (AOP) - node name "DetectionArea" in NPC.tscn
		var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
		if pa:
			if pa.has_enemies(npc):
				var raw: Node = pa.get_nearest_enemy(npc.global_position, npc)
				combat_target = raw as Node2D if raw else null
		else:
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled() and pi.has_method("combat_detection_null"):
				pi.combat_detection_null(npc.get("npc_name") if npc else "?")
			push_warning("Combat: DetectionArea null for %s - no target" % (npc.get("npc_name") if npc else "?"))
			combat_target = null
		
		if combat_target != null and not FightOverScript.is_living_attack_target(combat_target):
			combat_target = null
		if combat_target != null and npc.has_method("assign_combat_target_node"):
			npc.assign_combat_target_node(combat_target)
		if combat_target != null and FightFlight.ordered_mode(npc) == "GUARD":
			if npc.global_position.distance_to(combat_target.global_position) > FightFlight.GUARD_ACQUIRE_RADIUS:
				combat_target = null
				npc.set("combat_target", null)
				npc.set("combat_target_id", -1)
		return combat_target != null
	
	# Raid path: Followers in Hostile Mode (herder == player, or agro-combat-test with herder == leader) attack enemy in range
	var hostile: bool = npc.get("is_hostile") as bool if npc.get("is_hostile") != null else false
	var h: Node = npc.get("herder")
	var ordered: bool = npc.get("follow_is_ordered") as bool if npc.get("follow_is_ordered") != null else false
	var raid_allow: bool = h != null and h.is_in_group("player")
	if not raid_allow and DebugConfig and DebugConfig.get("enable_agro_combat_test") and DebugConfig.get("test_overrides") is Dictionary:
		raid_allow = DebugConfig.test_overrides.get("allow_raid_without_player", true)
	var raid_ok: bool = hostile and h != null and is_instance_valid(h) and ordered and raid_allow
	if FightFlight.ordered_mode(npc) == "FOLLOW" or FightFlight.ordered_mode(npc) == "GUARD":
		raid_ok = false
	if raid_ok and npc.get("follow_is_ordered"):
		if agro_meter < _stance_combat_agro_threshold():
			raid_ok = false
	if DebugConfig and DebugConfig.get("enable_agro_combat_test") and raid_allow and ordered and h != null and is_instance_valid(h) and not hostile:
		if not _raid_blocked_logged:
			_raid_blocked_logged = true
			push_warning("COMBAT: raid path blocked (is_hostile=false) — set npc.is_hostile when command_context.is_hostile")
	if raid_ok:
		# Agro combat test: use boosted range via get_combat_target_candidates so followers engage sooner
		var radius: float = 300.0
		if DebugConfig and DebugConfig.get("enable_agro_combat_test") and DebugConfig.get("test_overrides") is Dictionary:
			radius = DebugConfig.test_overrides.get("detection_range_boost", 300.0)
		if npc.has_method("get_combat_target_candidates") and radius > 300.0:
			var candidates: Array = npc.get_combat_target_candidates(npc.global_position, radius)
			if candidates.size() > 0:
				var nearest: Node2D = null
				var best_dist := INF
				for c in candidates:
					if is_instance_valid(c):
						var d: float = npc.global_position.distance_squared_to(c.global_position)
						if d < best_dist:
							best_dist = d
							nearest = c as Node2D
				if nearest:
					combat_target = nearest
					var tid: int = EntityRegistry.get_id(combat_target) if EntityRegistry else -1
					npc.set("combat_target_id", tid)
					npc.set("combat_target", combat_target)
					if "combat_target_id" in npc:
						npc.combat_target_id = tid
					return true
		# Use PerceptionArea (AOP) - node name "DetectionArea" in NPC.tscn
		var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
		if pa:
			var raw: Node = pa.get_nearest_enemy(npc.global_position, npc)
			combat_target = raw as Node2D if raw else null
			if combat_target:
				var tid: int = EntityRegistry.get_id(combat_target) if EntityRegistry else -1
				npc.set("combat_target_id", tid)
				npc.set("combat_target", combat_target)
				if "combat_target_id" in npc:
					npc.combat_target_id = tid
				return true
		else:
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled() and pi.has_method("combat_detection_null"):
				pi.combat_detection_null(npc.get("npc_name") if npc else "?")
		if combat_target:
			var tid: int = EntityRegistry.get_id(combat_target) if EntityRegistry else -1
			npc.set("combat_target_id", tid)
			npc.set("combat_target", combat_target)
			if "combat_target_id" in npc:
				npc.combat_target_id = tid
			return true
	
	return false

func get_priority() -> float:
	if NPCConfig:
		return NPCConfig.priority_combat_state
	return 12.0

func _find_nearest_enemy() -> void:
	if not npc:
		return
	
	combat_target = null
	
	# Use PerceptionArea (AOP) - node name "DetectionArea" in NPC.tscn
	var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
	if pa:
		var raw: Node = pa.get_nearest_enemy(npc.global_position, npc)
		combat_target = raw as Node2D if raw else null
	else:
		# DetectionArea null - should never happen. Log and fail gracefully.
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled() and pi.has_method("combat_detection_null"):
			pi.combat_detection_null(npc.get("npc_name") if npc else "?")
		push_warning("Combat: DetectionArea null for %s - no target" % (npc.get("npc_name") if npc else "?"))
		return
	
	if combat_target:
		_assign_combat_target(combat_target)

func _flee_bravery() -> float:
	var def_b: float = 0.5
	if NPCConfig:
		def_b = NPCConfig.flee_default_bravery
	if not npc:
		return def_b
	var bvar: Variant = npc.get("bravery")
	if bvar == null:
		return def_b
	var bf: float = float(bvar)
	if bf < 0.0:
		return def_b
	return clampf(bf, 0.0, 1.0)

func _is_person_body(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if body.is_in_group("player"):
		return true
	var kind: String = str(body.get("npc_type")) if body.get("npc_type") != null else ""
	return kind == "caveman" or kind == "clansman" or kind == "woman"


func _is_routing_person(body: Node) -> bool:
	if not _is_person_body(body) or not is_attack_target_alive(body):
		return false
	var body_fsm: Node = body.get("fsm") as Node
	return body_fsm != null and body_fsm.has_method("get_current_state_name") and str(body_fsm.get_current_state_name()) == "flee_combat"


func _party_mates() -> Array:
	var mates: Array = []
	if npc == null:
		return mates
	var leader: Node = npc
	if bool(npc.get("follow_is_ordered")):
		var herder: Variant = npc.get("herder")
		if herder != null and is_instance_valid(herder):
			leader = herder
			mates.append(herder)
	if HerdManager and leader != null:
		for follower in HerdManager.get_herd(leader):
			if follower != npc:
				mates.append(follower)
	if not bool(npc.get("follow_is_ordered")) and mates.is_empty():
		return []
	return mates


func _mate_target(mate: Node) -> Node2D:
	if mate == null or not is_instance_valid(mate):
		return null
	if mate.has_method("resolve_combat_target"):
		return mate.resolve_combat_target() as Node2D
	var raw: Variant = mate.get("combat_target")
	if raw is Node2D and is_instance_valid(raw):
		return raw as Node2D
	return null


func _find_pursuit_target() -> Node2D:
	if _is_routing_person(combat_target):
		return combat_target
	if combat_target == null or not _is_person_body(combat_target):
		return null
	var best: Node2D = null
	var best_d: float = INF
	for mate in _party_mates():
		var ct: Node2D = _mate_target(mate as Node)
		if not _is_routing_person(ct):
			continue
		var d: float = npc.global_position.distance_to(ct.global_position)
		if d < best_d:
			best_d = d
			best = ct
	return best


func _run_down_router(router: Node2D, combat_comp: CombatComponent, distance: float) -> void:
	if router == null or not is_instance_valid(router):
		return
	if combat_target != router:
		_assign_combat_target(router)
	distance = npc.global_position.distance_to(router.global_position)
	var mult: float = 2.2
	if NPCConfig and NPCConfig.get("pursue_rout_speed_multiplier") != null:
		mult = float(NPCConfig.pursue_rout_speed_multiplier)
	if npc.steering_agent and npc.steering_agent.has_method("set_speed_multiplier"):
		npc.steering_agent.set_speed_multiplier(mult)
	var rid: int = router.get_instance_id()
	if int(npc.get_meta("pursue_logged_id", 0)) != rid:
		npc.set_meta("pursue_logged_id", rid)
		print("NPC_PURSUE name=%s target=%s" % [str(npc.get("npc_name")), _target_display_name(router)])
	WeaponOverlayCombat.set_throw_stance(npc, false)
	var reach: float = combat_comp.attack_range if combat_comp else attack_range
	if npc.steering_agent and npc.steering_agent.has_method("retarget_seek"):
		npc.steering_agent.retarget_seek(router.global_position)
	elif distance > reach and npc.steering_agent and npc.steering_agent.has_method("set_target_position_immediate"):
		npc.steering_agent.set_target_position_immediate(router.global_position)
	if distance > reach or combat_comp == null:
		return
	var aim: Vector2 = router.global_position - npc.global_position
	if aim.length_squared() < 0.0001:
		aim = Vector2.RIGHT
	aim = aim.normalized()
	if combat_comp.state == CombatComponent.CombatState.READY:
		var now_ms: int = Time.get_ticks_msec()
		var last_attack_time: int = int(npc.get_meta("last_attack_request_time", 0))
		if now_ms - last_attack_time >= 220:
			combat_comp.commit_strike(aim)
			npc.set_meta("last_attack_request_time", now_ms)
	elif combat_comp.state == CombatComponent.CombatState.IDLE:
		combat_comp.request_attack(router)


func _village_holds_him() -> bool:
	if fsm == null or not fsm.has_method("_get_state"):
		return false
	var flee_st: Node = fsm._get_state("flee_combat")
	return flee_st != null and flee_st.has_method("village_holds") and bool(flee_st.village_holds())


func _should_flee() -> bool:
	return _flee_reason() != ""


func _flee_reason() -> String:
	if not npc:
		return ""
	if FightFlight.is_woman(npc):
		return "shelter"
	if _find_pursuit_target() != null:
		return ""
	if _village_holds_him():
		return ""
	if _npc_has_spare_ranged() and combat_target and is_instance_valid(combat_target) and not FightFlight.is_building(combat_target):
		if not FightFlight.leader_shock_active(npc):
			return ""
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if nt != "caveman" and nt != "clansman" and not npc.is_in_group("player"):
		return ""
	if combat_target and FightFlight.should_break(npc, combat_target):
		return "morale"
	return ""


func _try_nomad_rejoin_after_combat() -> void:
	if not npc or not is_instance_valid(npc):
		return
	var tree := npc.get_tree()
	if tree == null:
		return
	var main = tree.get_first_node_in_group("main")
	if main == null or not main.has_method("is_clan_in_nomad_mode"):
		return
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	if npc_clan == "" or not main.is_clan_in_nomad_mode(npc_clan):
		return
	if npc.get("follow_is_ordered") and npc.get("herder") != null and is_instance_valid(npc.get("herder")):
		return
	var leader: Node = main.get_active_leader() if main.has_method("get_active_leader") else null
	if leader and main.has_method("_set_nomad_follow"):
		main._set_nomad_follow(npc, leader, "nomad_rejoin")


func _npc_item_count(item_type: ResourceData.ResourceType) -> int:
	if npc == null:
		return 0
	var n: int = 0
	var inv: Variant = npc.get("inventory")
	if inv is InventoryData:
		n += (inv as InventoryData).get_count(item_type)
	var hb: Variant = npc.get("hotbar")
	if hb is InventoryData:
		n += (hb as InventoryData).get_count(item_type)
	return n


func has_spare_ranged() -> bool:
	return _npc_has_spare_ranged()


func ammo_label() -> String:
	var ammo: ResourceData.ResourceType = _npc_throw_ammo_type()
	if ammo == ResourceData.ResourceType.SPEAR:
		return "spear"
	if ammo == ResourceData.ResourceType.STONE:
		return "stone"
	return "none"


func pose_label() -> String:
	if npc == null:
		return "none"
	var target: Node2D = combat_target
	if target == null or not is_instance_valid(target):
		if npc.has_method("resolve_combat_target"):
			target = npc.resolve_combat_target() as Node2D
	if target == null or not is_instance_valid(target):
		return "none"
	if _npc_has_spare_ranged():
		return "throw"
	var dist: float = npc.global_position.distance_to(target.global_position)
	var reach: float = 100.0
	var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
	if combat_comp:
		reach = combat_comp.attack_range
	if dist <= reach:
		return "hold"
	return "approach"


func _npc_has_spare_ranged() -> bool:
	if _npc_item_count(ResourceData.ResourceType.SPEAR) > 1:
		return true
	return _npc_item_count(ResourceData.ResourceType.STONE) > 0


func _npc_active_throw_range() -> float:
	return ThrowHitResolver.throw_range_px_for(_npc_throw_ammo_type())


func _npc_throw_ammo_type() -> ResourceData.ResourceType:
	if _npc_item_count(ResourceData.ResourceType.SPEAR) > 1:
		return ResourceData.ResourceType.SPEAR
	if _npc_item_count(ResourceData.ResourceType.STONE) > 0:
		return ResourceData.ResourceType.STONE
	return ResourceData.ResourceType.NONE


func _npc_stone_count() -> int:
	if npc == null:
		return 0
	var n: int = 0
	var inv: Variant = npc.get("inventory")
	if inv is InventoryData:
		n += (inv as InventoryData).get_count(ResourceData.ResourceType.STONE)
	var hb: Variant = npc.get("hotbar")
	if hb is InventoryData:
		n += (hb as InventoryData).get_count(ResourceData.ResourceType.STONE)
	return n


func _party_ranged_ratio() -> float:
	if npc == null:
		return 0.5
	var herder: Variant = npc.get("herder")
	if npc.get("follow_is_ordered") and herder != null and is_instance_valid(herder) and (herder as Node).is_in_group("player"):
		var tree := npc.get_tree()
		if tree:
			var main: Node = tree.get_first_node_in_group("main")
			if main and main.get("player_party_ranged_ratio") != null:
				return clampf(float(main.get("player_party_ranged_ratio")), 0.0, 1.0)
	var claim: Variant = npc.get("land_claim")
	if claim == null:
		claim = npc.get("defend_target")
	if claim != null and is_instance_valid(claim as Object) and (claim as Object).get("ranged_ratio") != null:
		return clampf(float((claim as Object).get("ranged_ratio")), 0.0, 1.0)
	return 0.5


func _try_ranged_throw(combat_comp: CombatComponent, distance: float, melee_range: float) -> bool:
	if combat_comp == null or combat_target == null or not is_instance_valid(combat_target):
		return false
	var ammo: ResourceData.ResourceType = _npc_throw_ammo_type()
	if ammo == ResourceData.ResourceType.NONE:
		WeaponOverlayCombat.set_throw_stance(npc, false)
		return false
	npc.remove_meta("npc_melee_logged")
	npc.set_meta("pending_throw_item", ammo)
	var throw_range: float = ThrowHitResolver.throw_range_px_for(ammo)
	WeaponOverlayCombat.set_throw_stance(npc, true)
	var to_t: Vector2 = combat_target.global_position - npc.global_position
	if to_t.length_squared() < 0.0001:
		to_t = Vector2.RIGHT
	var aim: Vector2 = to_t.normalized()
	if distance > throw_range:
		npc.remove_meta("ranged_hold_since")
		if npc.steering_agent and npc.steering_agent.has_method("retarget_seek"):
			npc.steering_agent.retarget_seek(combat_target.global_position)
		return true
	if distance < throw_range * 0.85:
		npc.remove_meta("ranged_hold_since")
		if npc.steering_agent and npc.steering_agent.has_method("retarget_seek"):
			npc.steering_agent.retarget_seek(combat_target.global_position + (-aim) * (throw_range * 0.92))
		return true
	if combat_comp.state == CombatComponent.CombatState.WINDUP or combat_comp.state == CombatComponent.CombatState.RECOVERY:
		return true
	if npc.steering_agent and npc.steering_agent.has_method("hold_still"):
		npc.steering_agent.hold_still()
	var now_ms: int = Time.get_ticks_msec()
	var threw: bool = false
	if combat_comp.state == CombatComponent.CombatState.READY:
		var last_attack_time: int = int(npc.get_meta("last_attack_request_time", 0))
		if now_ms - last_attack_time >= 220:
			_note_throw_release(ammo)
			combat_comp.commit_strike(aim)
			npc.set_meta("last_attack_request_time", now_ms)
			threw = true
	elif combat_comp.state == CombatComponent.CombatState.IDLE:
		if combat_comp._uses_overlay_combat():
			_note_throw_release(ammo)
			combat_comp.enter_ready(aim)
			combat_comp.commit_strike(aim)
			npc.set_meta("last_attack_request_time", now_ms)
			threw = true
		else:
			combat_comp.request_attack(combat_target)
			threw = true
	if threw:
		npc.remove_meta("ranged_hold_since")
		return true
	var now_s: float = now_ms / 1000.0
	if not npc.has_meta("ranged_hold_since"):
		npc.set_meta("ranged_hold_since", now_s)
	elif now_s - float(npc.get_meta("ranged_hold_since")) >= 2.5:
		npc.remove_meta("ranged_hold_since")
		if CombatTick and CombatTick.has_method("break_contact"):
			CombatTick.break_contact(npc)
	return true


func _strike_in_progress() -> bool:
	if npc == null:
		return false
	var combat_comp: CombatComponent = npc.get_node_or_null("CombatComponent")
	if combat_comp == null:
		return false
	return combat_comp.state == CombatComponent.CombatState.WINDUP or combat_comp.state == CombatComponent.CombatState.RECOVERY


func _note_throw_release(ammo: ResourceData.ResourceType) -> void:
	var kind := "stone"
	if ammo == ResourceData.ResourceType.SPEAR:
		kind = "spear"
	var target_name := _target_display_name(combat_target)
	print("NPC_THROW name=%s ammo=%s target=%s" % [str(npc.get("npc_name")), kind, target_name])


func _note_melee_step() -> void:
	if npc == null or npc.has_meta("npc_melee_logged"):
		return
	if _npc_throw_ammo_type() != ResourceData.ResourceType.NONE:
		return
	if combat_target == null or not is_instance_valid(combat_target) or not is_attack_target_alive(combat_target):
		return
	npc.set_meta("npc_melee_logged", true)
	print("NPC_MELEE name=%s target=%s" % [str(npc.get("npc_name")), _target_display_name(combat_target)])


func _hold_volley_target() -> void:
	if npc == null:
		return
	var attacker: Node = _volley_meta_node("volley_attacker")
	if attacker != null and _volley_body_alive(attacker):
		_assign_combat_target(attacker as Node2D)
		return
	if npc.has_meta("volley_attacker"):
		npc.remove_meta("volley_attacker")
	if not _npc_has_spare_ranged():
		return
	var prey: Node = _volley_meta_node("volley_prey")
	if prey != null and _volley_body_alive(prey):
		_assign_combat_target(prey as Node2D)
	elif npc.has_meta("volley_prey"):
		npc.remove_meta("volley_prey")


func _volley_meta_node(key: String) -> Node:
	if npc == null or not npc.has_meta(key):
		return null
	var body: Variant = npc.get_meta(key)
	if body == null or not is_instance_valid(body):
		return null
	if not (body is Node):
		return null
	return body as Node


func _volley_body_alive(body: Node) -> bool:
	if body.has_method("is_dead") and body.is_dead():
		return false
	var hc: Node = body.get_node_or_null("HealthComponent")
	if hc and bool(hc.get("is_dead")):
		return false
	return true

