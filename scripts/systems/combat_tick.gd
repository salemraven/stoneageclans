extends Node

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

# Step 7: Phase order (validate → command → combat target → intent → events). Single intent per tick: Combat > Recover > Command > Work.
func _on_tick() -> void:
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
				# Clansmen must never target the player (same clan, or defending/searching player's claim)
				if nearest.is_in_group("player"):
					var npc_clan: String = n.get_clan_name() if n.has_method("get_clan_name") else ""
					var player_clan: String = nearest.get_clan_name() if nearest.has_method("get_clan_name") else ""
					if npc_clan != "" and npc_clan == player_clan:
						nearest = null
					var dt = n.get("defend_target")
					var shc = n.get("search_home_claim")
					if (dt != null and is_instance_valid(dt) and dt.get("player_owned") == true) or (shc != null and is_instance_valid(shc) and shc.get("player_owned") == true):
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
			continue
		var in_combat: bool = false
		var fsm = n.get("fsm")
		if fsm and fsm.has_method("get_current_state_name"):
			in_combat = (fsm.get_current_state_name() == "combat")
		var rate: float = _decay_combat() if in_combat else _decay_idle()
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
			var ct = n.get("combat_target")
			if ct != null:
				n.set("combat_target_id", -1)
				n.set("combat_target", null)
				if "combat_target_id" in n:
					n.combat_target_id = -1
				if "combat_target" in n:
					n.combat_target = null
				var comp: Node = n.get_node_or_null("CombatComponent")
				if comp and comp.has_method("clear_target"):
					comp.clear_target()
				if fsm and fsm.has_method("_evaluate_states"):
					fsm.evaluation_timer = 0.0
					fsm._evaluate_states()
