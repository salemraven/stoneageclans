extends Node

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")
const FightOverScript = preload("res://scripts/systems/fight_over.gd")
const FightFlight = preload("res://scripts/combat/fight_flight.gd")

# CombatTick - fixed timestep (20-30 Hz) for agro decay, threshold, combat enter/exit. Step 2.
# Remove agro logic from npc_base _physics_process; feed via push_agro_event().

const TICK_INTERVAL: float = 0.04  # 25 Hz
# Step 8: Thresholds from config (fallback defaults)
func _enter_threshold() -> float:
	return NPCConfig.get("agro_enter_threshold") as float if NPCConfig and NPCConfig.get("agro_enter_threshold") != null else 70.0
func _exit_threshold() -> float:
	return NPCConfig.get("agro_exit_threshold") as float if NPCConfig and NPCConfig.get("agro_exit_threshold") != null else 60.0
func _decay_combat() -> float:
	return NPCConfig.get("agro_decay_combat") as float if NPCConfig and NPCConfig.get("agro_decay_combat") != null else 2.0
func _decay_idle() -> float:
	return NPCConfig.get("agro_decay_idle") as float if NPCConfig and NPCConfig.get("agro_decay_idle") != null else 5.0

func _perception_range() -> float:
	return NPCConfig.get("agro_perception_range") as float if NPCConfig and NPCConfig.get("agro_perception_range") != null else 300.0

func _outranged_extra_decay() -> float:
	return NPCConfig.get("agro_outranged_extra_decay") as float if NPCConfig and NPCConfig.get("agro_outranged_extra_decay") != null else 18.0

func _far_break_distance() -> float:
	return NPCConfig.get("agro_far_instant_break_distance") as float if NPCConfig and NPCConfig.get("agro_far_instant_break_distance") != null else 560.0

func _give_up_seconds() -> float:
	return NPCConfig.get("agro_lost_target_give_up_seconds") as float if NPCConfig and NPCConfig.get("agro_lost_target_give_up_seconds") != null else 7.0

func _absolute_max_seconds() -> float:
	return NPCConfig.get("agro_absolute_max_seconds") as float if NPCConfig and NPCConfig.get("agro_absolute_max_seconds") != null else 45.0

const META_OUTRANGED_ACCUM := "agro_target_out_of_perception_accum"
const META_AGRO_POSITIVE_SINCE := "agro_meter_positive_since_sec"
const META_DISENGAGE_UNTIL := "agro_disengage_until_sec"

var _agro_events: Array = []  # { npc, amount, reason, nearest (optional) }
var _timer: Timer = null
var _stuck_log_accum: float = 0.0
var _stuck_summary_accum: float = 0.0
var _stuck_reason_counts: Dictionary = {}

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = TICK_INTERVAL
	_timer.one_shot = false
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	_timer.start()

func is_disengaged(npc: Node) -> bool:
	if npc == null or not is_instance_valid(npc) or not npc.has_meta(META_DISENGAGE_UNTIL):
		return false
	return Time.get_ticks_msec() / 1000.0 < float(npc.get_meta(META_DISENGAGE_UNTIL))


func break_contact(npc: Node) -> void:
	## End a fight that is not resolving, and block the instant re-agro.
	if npc == null or not is_instance_valid(npc):
		return
	var hold: float = 8.0
	if NPCConfig and NPCConfig.get("agro_disengage_seconds") != null:
		hold = float(NPCConfig.agro_disengage_seconds)
	npc.set_meta(META_DISENGAGE_UNTIL, Time.get_ticks_msec() / 1000.0 + hold)
	npc.set_meta("agro_last_break_sec", Time.get_ticks_msec() / 1000.0)
	npc.set_meta("agro_last_break_reason", "break_contact")
	npc.set("combat_locked", false)
	if "combat_locked" in npc:
		npc.combat_locked = false
	npc.set("agro_meter", 0.0)
	if "agro_meter" in npc:
		npc.agro_meter = 0.0
	if npc.has_method("remove_meta"):
		npc.remove_meta(META_AGRO_POSITIVE_SINCE)
		npc.remove_meta(META_OUTRANGED_ACCUM)
	_clear_combat_target_and_reeval(npc)


func push_agro_event(npc: Node, amount: float, reason: String, nearest: Node2D = null) -> void:
	if not npc or not is_instance_valid(npc) or is_disengaged(npc):
		return
	_agro_events.append({
		"npc": npc,
		"amount": amount,
		"reason": reason,
		"nearest": nearest
	})

func _resolve_combat_target_node(n: Node) -> Node2D:
	if not n or not is_instance_valid(n):
		return null
	if n.has_method("resolve_combat_target"):
		return n.resolve_combat_target() as Node2D
	var raw: Variant = n.get("combat_target")
	if raw != null and is_instance_valid(raw):
		return raw as Node2D
	return null

func _clear_combat_target_and_reeval(n: Node) -> void:
	if not n or not is_instance_valid(n):
		return
	n.set("combat_target_id", -1)
	n.set("combat_target", null)
	if "combat_target_id" in n:
		n.combat_target_id = -1
	if "combat_target" in n:
		n.combat_target = null
	var comp: Node = n.get_node_or_null("CombatComponent")
	if comp and comp.has_method("clear_target"):
		comp.clear_target()
	if n.has_method("remove_meta"):
		n.remove_meta(META_OUTRANGED_ACCUM)
	var fsm = n.get("fsm")
	if fsm and fsm.has_method("_evaluate_states"):
		fsm.evaluation_timer = 0.0
		fsm._evaluate_states()

func _target_is_routing(ct: Node) -> bool:
	if ct == null or not is_instance_valid(ct):
		return false
	var kind: String = str(ct.get("npc_type")) if ct.get("npc_type") != null else ""
	var person: bool = ct.is_in_group("player") or kind == "caveman" or kind == "clansman" or kind == "woman"
	if not person:
		return false
	var body_fsm: Node = ct.get("fsm") as Node
	return body_fsm != null and body_fsm.has_method("get_current_state_name") and str(body_fsm.get_current_state_name()) == "flee_combat"


func _body_is_out_of_fight(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return true
	if n.has_meta("is_corpse") and bool(n.get_meta("is_corpse")):
		return true
	if n.has_meta("is_dead") and bool(n.get_meta("is_dead")):
		return true
	if n.has_method("is_dead") and bool(n.is_dead()):
		return true
	return false


func _process_merged_agro_event(ev: Dictionary) -> void:
	var n: Node = ev.get("npc") as Node
	if not is_instance_valid(n) or is_disengaged(n) or _body_is_out_of_fight(n):
		return
	var old_agro: float = n.get("agro_meter") as float if n.get("agro_meter") != null else 0.0
	var cap: float = NPCConfig.get("agro_max") as float if NPCConfig and NPCConfig.get("agro_max") != null else 100.0
	var add_amt: float = ev.get("amount", 0.0) as float
	var new_agro: float = min(cap, old_agro + add_amt)
	n.set("agro_meter", new_agro)
	if "agro_meter" in n:
		n.agro_meter = new_agro
	if old_agro <= 0.0 and new_agro > 0.0 and n.has_method("set_meta"):
		n.set_meta(META_AGRO_POSITIVE_SINCE, Time.get_ticks_msec() / 1000.0)
	if n.has_method("set_meta"):
		n.set_meta("last_agro_event_time", Time.get_ticks_msec() / 1000.0)
		n.set_meta("last_agro_reason", str(ev.get("reason", "")))
	var nearest_ev: Variant = ev.get("nearest")
	if nearest_ev and is_instance_valid(nearest_ev) and new_agro >= _enter_threshold():
		var cur_target = n.get("combat_target")
		if not cur_target or not is_instance_valid(cur_target) or not FightOverScript.is_living_attack_target(cur_target):
			var nearest: Node2D = nearest_ev as Node2D
			if nearest and CombatAllyCheck.is_ally(n, nearest):
				nearest = null
			if nearest and not FightOverScript.is_living_attack_target(nearest):
				nearest = null
			if nearest and n.has_method("is_fight_over_latched") and n.is_fight_over_latched():
				nearest = null
			if nearest:
				var tid: int = EntityRegistry.get_id(nearest) if EntityRegistry else -1
				n.set("combat_target_id", tid)
				n.set("combat_target", nearest)
				if "combat_target" in n:
					n.combat_target = nearest
				if "combat_target_id" in n:
					n.combat_target_id = tid
	var pi = n.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled():
		pi.agro_increased(n.get("npc_name") if n.get("npc_name") != null else "unknown", new_agro, ev.get("reason", ""))
		if old_agro < _enter_threshold() and new_agro >= _enter_threshold():
			pi.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", true)

# Step 7: Phase order (validate → command → combat target → intent → events). Single intent per tick: Combat > Recover > Command > Work.
func _on_tick() -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	var tree = get_tree()
	if not tree:
		return
	# Phase 1: Coalesce multiple events per NPC per tick (sum amounts; keep last non-null nearest)
	if _agro_events.size() > 0:
		var merged: Dictionary = {}
		var order: Array[int] = []
		for ev in _agro_events:
			var nn: Node = ev.get("npc") as Node
			if not is_instance_valid(nn):
				continue
			var iid: int = nn.get_instance_id()
			if not merged.has(iid):
				merged[iid] = {"npc": nn, "amount": 0.0, "reason": "", "nearest": null}
				order.append(iid)
			var m: Dictionary = merged[iid]
			m["amount"] = (m["amount"] as float) + float(ev.get("amount", 0.0))
			if ev.get("nearest"):
				m["nearest"] = ev.get("nearest")
			var rsn: String = str(ev.get("reason", ""))
			if rsn != "":
				m["reason"] = rsn
		_agro_events.clear()
		for iid in order:
			_process_merged_agro_event(merged[iid] as Dictionary)

	var now_sec: float = Time.get_ticks_msec() / 1000.0
	var abs_max: float = _absolute_max_seconds()
	# Phase 2: Decay and threshold (hysteresis 70 enter / 60 exit); combat enter/exit via FSM eval
	var npcs: Array = []
	var main_node = tree.current_scene
	if main_node and main_node.has_method("get_cached_npcs"):
		npcs = main_node.get_cached_npcs()
	else:
		npcs = tree.get_nodes_in_group("npcs")
	for n in npcs:
		if not is_instance_valid(n) or _body_is_out_of_fight(n):
			continue
		var agro: float = n.get("agro_meter") as float if n.get("agro_meter") != null else 0.0
		if agro <= 0.0:
			if n.has_method("remove_meta"):
				n.remove_meta(META_OUTRANGED_ACCUM)
				n.remove_meta(META_AGRO_POSITIVE_SINCE)
			continue
		# Safety: agro stuck positive too long
		if n.has_meta(META_AGRO_POSITIVE_SINCE):
			var t0: float = float(n.get_meta(META_AGRO_POSITIVE_SINCE, 0.0))
			if now_sec - t0 > abs_max:
				var old_abs: float = agro
				if old_abs >= _exit_threshold():
					var pi_abs = n.get_node_or_null("/root/PlaytestInstrumentor")
					if pi_abs and pi_abs.is_enabled():
						pi_abs.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", false)
				break_contact(n)
				continue

		var in_combat_like: bool = false
		var fsm = n.get("fsm")
		var st_name: String = ""
		if fsm and fsm.has_method("get_current_state_name"):
			st_name = str(fsm.get_current_state_name())
			in_combat_like = (st_name == "combat" or st_name == "flee_combat")
		var ct: Node2D = _resolve_combat_target_node(n)
		var per: float = _perception_range()
		var far_d: float = _far_break_distance()
		# Hard leash: target sprinted away — drop immediately
		if ct and is_instance_valid(ct):
			var dist_leash: float = n.global_position.distance_to(ct.global_position)
			var village_hold: bool = n.has_meta("village_defense") and int(n.get_meta("village_defense")) == ct.get_instance_id()
			if village_hold and dist_leash > far_d and not bool(n.get_meta("village_far_logged", false)):
				n.set_meta("village_far_logged", true)
				print("NPC_VILLAGE_FAR name=%s target=%s dist=%.0f" % [str(n.get("npc_name")), str(ct.get("npc_name")), dist_leash])
			if dist_leash > far_d and not _target_is_routing(ct) and not village_hold:
				var old_hi: float = agro
				if old_hi >= _exit_threshold():
					var pi2 = n.get_node_or_null("/root/PlaytestInstrumentor")
					if pi2 and pi2.is_enabled():
						pi2.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", false)
				break_contact(n)
				continue
			# Beyond perception: track time for failsafe clear; fast decay applied below
			if dist_leash > per:
				var accum: float = (n.get_meta(META_OUTRANGED_ACCUM, 0.0) as float) + TICK_INTERVAL
				n.set_meta(META_OUTRANGED_ACCUM, accum)
				if accum >= _give_up_seconds():
					var old_g: float = agro
					if old_g >= _exit_threshold():
						var pi3 = n.get_node_or_null("/root/PlaytestInstrumentor")
						if pi3 and pi3.is_enabled():
							pi3.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", false)
					break_contact(n)
					continue
			else:
				if n.has_method("remove_meta"):
					n.remove_meta(META_OUTRANGED_ACCUM)
		else:
			if n.has_method("remove_meta"):
				n.remove_meta(META_OUTRANGED_ACCUM)

		if not in_combat_like and ct and is_instance_valid(ct) and agro >= _enter_threshold() and not FightFlight.is_woman(n):
			var spare_ranged: bool = false
			if fsm and fsm.has_method("_get_state"):
				var spare_state: Node = fsm._get_state("combat")
				if spare_state and spare_state.has_method("has_spare_ranged"):
					spare_ranged = bool(spare_state.has_spare_ranged())
			var village_holds: bool = false
			if fsm and fsm.has_method("_get_state"):
				var home_st: Node = fsm._get_state("flee_combat")
				if home_st and home_st.has_method("village_holds"):
					village_holds = bool(home_st.village_holds())
			if not village_holds and not _target_is_routing(ct) and (not spare_ranged or FightFlight.leader_shock_active(n)) and FightFlight.should_break(n, ct) and fsm and fsm.has_method("change_state"):
				var phi_hot: Node = n.get_node_or_null("/root/PartyHuntInstrument")
				if phi_hot and phi_hot.has_method("note_fight_break"):
					phi_hot.note_fight_break(n, "morale", ct)
				fsm.change_state("flee_combat")
				continue

		var rate: float = _decay_combat() if in_combat_like else _decay_idle()
		# Pumps suppressed in npc_base during combat/flee; extra decay when target is out of range
		if ct and is_instance_valid(ct):
			var d_ct: float = n.global_position.distance_to(ct.global_position)
			if d_ct > per:
				rate += _outranged_extra_decay()
		# Herd leader: decay agro faster (don't take risks, stay focused on claim)
		var herded_count: int = int(n.get("herded_count")) if n.get("herded_count") != null else 0
		if herded_count > 0:
			rate *= 2.5
		var old_a: float = agro
		agro = max(0.0, agro - rate * TICK_INTERVAL)
		n.set("agro_meter", agro)
		if "agro_meter" in n:
			n.agro_meter = agro
		if agro <= 0.0 and n.has_method("remove_meta"):
			n.remove_meta(META_AGRO_POSITIVE_SINCE)
		# Hysteresis: exit only when below 60
		if old_a >= _exit_threshold() and agro < _exit_threshold():
			var pi = n.get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled():
				pi.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", false)
			if ct != null or in_combat_like:
				break_contact(n)
	_stuck_log_accum += TICK_INTERVAL
	_stuck_summary_accum += TICK_INTERVAL
	if _stuck_log_accum >= 2.0:
		_stuck_log_accum = 0.0
		_log_stuck_agro(npcs, now_sec)
	if _stuck_summary_accum >= 15.0:
		_stuck_summary_accum = 0.0
		_print_stuck_agro_summary()


func _log_stuck_agro(npcs: Array, now_sec: float) -> void:
	var enter: float = _enter_threshold()
	for n in npcs:
		if not is_instance_valid(n) or _body_is_out_of_fight(n):
			continue
		var agro: float = float(n.get("agro_meter")) if n.get("agro_meter") != null else 0.0
		if agro < enter:
			continue
		var since: float = float(n.get_meta(META_AGRO_POSITIVE_SINCE, now_sec)) if n.has_meta(META_AGRO_POSITIVE_SINCE) else now_sec
		var held: float = now_sec - since
		if held < 8.0:
			continue
		var hold: String = _stuck_hold_reason(n, now_sec)
		_stuck_reason_counts[hold] = int(_stuck_reason_counts.get(hold, 0)) + 1
		var fsm = n.get("fsm")
		var state_name: String = str(fsm.get_current_state_name()) if fsm and fsm.has_method("get_current_state_name") else ""
		var target: Node2D = _resolve_combat_target_node(n)
		var target_name: String = "none"
		var dist: float = -1.0
		if target and is_instance_valid(target):
			target_name = str(target.get("npc_name")) if target.get("npc_name") != null else target.name
			dist = n.global_position.distance_to(target.global_position)
		var hp_ratio: float = 1.0
		var hc: Node = n.get_node_or_null("HealthComponent")
		if hc and float(hc.get("max_hp")) > 0.0:
			hp_ratio = float(hc.get("current_hp")) / float(hc.get("max_hp"))
		var fill: String = str(n.get_meta("last_agro_reason", "")) if n.has_meta("last_agro_reason") else ""
		var ammo_word: String = "none"
		var pose_word: String = "none"
		if fsm and fsm.has_method("_get_state"):
			var pose_state: Node = fsm._get_state("combat")
			if pose_state and pose_state.has_method("ammo_label"):
				ammo_word = str(pose_state.ammo_label())
			if pose_state and pose_state.has_method("pose_label"):
				pose_word = str(pose_state.pose_label())
		var spd: float = 0.0
		if n.get("velocity") != null:
			spd = (n.get("velocity") as Vector2).length()
		var leader_dist: float = -1.0
		if bool(n.get("follow_is_ordered")):
			var leader: Variant = n.get("herder")
			if leader != null and is_instance_valid(leader) and leader is Node2D and n is Node2D:
				leader_dist = (n as Node2D).global_position.distance_to((leader as Node2D).global_position)
		print("STUCK_AGRO name=%s state=%s agro=%.0f held=%.0fs hold=%s target=%s dist=%.0f hp=%.2f fill=%s ammo=%s pose=%s spd=%.0f leader=%.0f" % [
			str(n.get("npc_name")), state_name, agro, held, hold, target_name, dist, hp_ratio, fill, ammo_word, pose_word, spd, leader_dist
		])


func _stuck_hold_reason(n: Node, now_sec: float) -> String:
	var broke: float = float(n.get_meta("agro_last_break_sec", -999.0)) if n.has_meta("agro_last_break_sec") else -999.0
	if now_sec - broke < 2.0:
		return "instant_refill"
	var ordered: bool = bool(n.get("follow_is_ordered"))
	var ctx: Dictionary = n.get("command_context") if n.get("command_context") != null else {}
	var hostile_order: bool = bool(ctx.get("is_hostile", false))
	var target: Node2D = _resolve_combat_target_node(n)
	var dist: float = INF
	if target and is_instance_valid(target):
		dist = n.global_position.distance_to(target.global_position)
	if ordered and hostile_order and (target == null or dist > _perception_range()):
		return "armed_leader_pin"
	if target == null:
		return "no_living_target"
	if dist > _perception_range():
		return "target_out_of_reach"
	var flee_reason: String = ""
	var fsm = n.get("fsm")
	if fsm and fsm.has_method("_get_state"):
		var combat_state: Node = fsm._get_state("combat")
		if combat_state and combat_state.has_method("_flee_reason"):
			flee_reason = str(combat_state._flee_reason())
	if flee_reason != "":
		return "should_flee_" + flee_reason
	var mode: String = str(ctx.get("mode", ""))
	if mode == "ATTACK" or mode == "ARC" or mode == "AMBUSH":
		return "attack_order"
	return "active_fight"


func _print_stuck_agro_summary() -> void:
	if _stuck_reason_counts.is_empty():
		return
	print("STUCK_AGRO_SUMMARY %s" % str(_stuck_reason_counts))
	_stuck_reason_counts.clear()
