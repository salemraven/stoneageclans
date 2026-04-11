extends Node

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

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

func _neutralize_rate() -> float:
	return NPCConfig.get("agro_combat_neutralize_rate") as float if NPCConfig and NPCConfig.get("agro_combat_neutralize_rate") != null else 52.0

func _outranged_extra_decay() -> float:
	return NPCConfig.get("agro_outranged_extra_decay") as float if NPCConfig and NPCConfig.get("agro_outranged_extra_decay") != null else 18.0

func _far_break_distance() -> float:
	return NPCConfig.get("agro_far_instant_break_distance") as float if NPCConfig and NPCConfig.get("agro_far_instant_break_distance") != null else 560.0

func _give_up_seconds() -> float:
	return NPCConfig.get("agro_lost_target_give_up_seconds") as float if NPCConfig and NPCConfig.get("agro_lost_target_give_up_seconds") != null else 7.0

const META_OUTRANGED_ACCUM := "agro_target_out_of_perception_accum"

var _agro_events: Array = []  # { npc, amount, reason, nearest (optional) }
var _timer: Timer = null

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = TICK_INTERVAL
	_timer.one_shot = false
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	_timer.start()

func push_agro_event(npc: Node, amount: float, reason: String, nearest: Node2D = null) -> void:
	if not npc or not is_instance_valid(npc):
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

# Step 7: Phase order (validate → command → combat target → intent → events). Single intent per tick: Combat > Recover > Command > Work.
func _on_tick() -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	var tree = get_tree()
	if not tree:
		return
	# Phase 1: Process agro event queue (agro increase, set target from events)
	while _agro_events.size() > 0:
		var ev = _agro_events.pop_front()
		var n = ev.npc
		if not is_instance_valid(n):
			continue
		var old_agro: float = n.get("agro_meter") as float if n.get("agro_meter") != null else 0.0
		var cap: float = NPCConfig.get("agro_max") as float if NPCConfig and NPCConfig.get("agro_max") != null else 100.0
		var new_agro: float = min(cap, old_agro + ev.amount)
		n.set("agro_meter", new_agro)
		if n.has_method("set_meta"):
			n.set_meta("last_agro_event_time", Time.get_ticks_msec() / 1000.0)
		# Optional: set combat target from nearest when crossing into combat zone (Step 3: set ID)
		if ev.get("nearest") and is_instance_valid(ev.nearest) and new_agro >= _enter_threshold():
			var cur_target = n.get("combat_target")
			if not cur_target or not is_instance_valid(cur_target):
				var nearest = ev.nearest
				if nearest and CombatAllyCheck.is_ally(n, nearest):
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
			pi.agro_increased(n.get("npc_name") if n.get("npc_name") != null else "unknown", new_agro, ev.reason)
			if old_agro < _enter_threshold() and new_agro >= _enter_threshold():
				pi.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", true)
	# Phase 2: Decay and threshold (hysteresis 70 enter / 60 exit); combat enter/exit via FSM eval
	var npcs: Array = []
	var main_node = tree.current_scene
	if main_node and main_node.has_method("get_cached_npcs"):
		npcs = main_node.get_cached_npcs()
	else:
		npcs = tree.get_nodes_in_group("npcs")
	for n in npcs:
		if not is_instance_valid(n):
			continue
		var agro: float = n.get("agro_meter") as float if n.get("agro_meter") != null else 0.0
		if agro <= 0.0:
			if n.has_method("remove_meta"):
				n.remove_meta(META_OUTRANGED_ACCUM)
			continue
		var in_combat: bool = false
		var fsm = n.get("fsm")
		if fsm and fsm.has_method("get_current_state_name"):
			in_combat = (fsm.get_current_state_name() == "combat")
		var ct: Node2D = _resolve_combat_target_node(n)
		var per: float = _perception_range()
		var far_d: float = _far_break_distance()
		# Hard leash: target sprinted away — drop immediately
		if ct and is_instance_valid(ct):
			var dist_leash: float = n.global_position.distance_to(ct.global_position)
			if dist_leash > far_d:
				var old_hi: float = agro
				n.set("agro_meter", 0.0)
				if "agro_meter" in n:
					n.agro_meter = 0.0
				_clear_combat_target_and_reeval(n)
				if old_hi >= _exit_threshold():
					var pi2 = n.get_node_or_null("/root/PlaytestInstrumentor")
					if pi2 and pi2.is_enabled():
						pi2.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", false)
				continue
			# Beyond perception: track time for failsafe clear; fast decay applied below
			if dist_leash > per:
				var accum: float = (n.get_meta(META_OUTRANGED_ACCUM, 0.0) as float) + TICK_INTERVAL
				n.set_meta(META_OUTRANGED_ACCUM, accum)
				if accum >= _give_up_seconds():
					var old_g: float = agro
					n.set("agro_meter", 0.0)
					if "agro_meter" in n:
						n.agro_meter = 0.0
					_clear_combat_target_and_reeval(n)
					if old_g >= _exit_threshold():
						var pi3 = n.get_node_or_null("/root/PlaytestInstrumentor")
						if pi3 and pi3.is_enabled():
							pi3.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", false)
					continue
			else:
				if n.has_method("remove_meta"):
					n.remove_meta(META_OUTRANGED_ACCUM)
		else:
			if n.has_method("remove_meta"):
				n.remove_meta(META_OUTRANGED_ACCUM)

		var rate: float = _decay_combat() if in_combat else _decay_idle()
		# Proximity / AOA / intrusion add ~50/s while enemies are in range — overwhelms base combat decay (~2/s).
		# While in combat with a resolved target in perception, add neutralizing decay so the meter can cross exit hysteresis.
		if in_combat and ct and is_instance_valid(ct):
			var d_ct: float = n.global_position.distance_to(ct.global_position)
			if d_ct <= per:
				rate += _neutralize_rate()
			else:
				rate += _outranged_extra_decay()
		elif ct and is_instance_valid(ct):
			var d_o: float = n.global_position.distance_to(ct.global_position)
			if d_o > per:
				rate += _outranged_extra_decay()
		# Herd leader: decay agro faster (don't take risks, stay focused on claim)
		var herded_count: int = int(n.get("herded_count")) if n.get("herded_count") != null else 0
		if herded_count > 0:
			rate *= 2.5
		var old_a: float = agro
		agro = max(0.0, agro - rate * TICK_INTERVAL)
		n.set("agro_meter", agro)
		# Hysteresis: exit only when below 60
		if old_a >= _exit_threshold() and agro < _exit_threshold():
			var pi = n.get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled():
				pi.agro_threshold_crossed(n.get("npc_name") if n.get("npc_name") != null else "unknown", false)
			var ct_clear = n.get("combat_target")
			if ct_clear != null:
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
				if fsm and fsm.has_method("_evaluate_states"):
					fsm.evaluation_timer = 0.0
					fsm._evaluate_states()
