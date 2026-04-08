extends Node
class_name HerdableComponent

## Single source of truth for woman/sheep/goat herd attachment. Syncs with HerdManager.

signal attached(herder: Node2D)
signal detached(old_herder: Node2D)
signal contested(challenger: Node2D)

@export var max_herd_size: int = 8
@export var hard_limit: int = 10
@export var break_distance: float = 300.0

var herder_instance_id: int = 0

var _npc: Node = null

func _ready() -> void:
	_npc = get_parent()
	if not _npc:
		push_error("HerdableComponent must be child of NPC")
		return
	if NPCConfig and "herd_max_distance_before_break" in NPCConfig:
		break_distance = NPCConfig.herd_max_distance_before_break as float
	# MP: add MultiplayerSynchronizer + replication config on scenes when enabling networked play


func get_npc() -> Node:
	return _npc


## Wild herdables: move straight toward herder (replaces inline block in herd_state).
func update_follow_wild(_delta: float) -> bool:
	if not _npc or not _npc.herder or not is_instance_valid(_npc.herder):
		return false
	var herder_ref: Node2D = _npc.herder
	var dist: float = _npc.global_position.distance_to(herder_ref.global_position)
	var herd_break_dist: float = break_distance
	if NPCConfig and "herd_max_distance_before_break" in NPCConfig:
		herd_break_dist = NPCConfig.herd_max_distance_before_break as float
	if dist >= herd_break_dist:
		_npc._clear_herd()
		if _npc.progress_display:
			_npc.progress_display.stop_collection()
		if _npc.fsm:
			_npc.fsm.evaluation_timer = 0.0
		return false
	if _npc.steering_agent:
		_npc.steering_agent.set_target_position(herder_ref.global_position)
		if "speed_multiplier" in _npc.steering_agent:
			_npc.steering_agent.speed_multiplier = 1.0
	return true


func attach(new_herder: Node2D) -> void:
	if not _npc or not new_herder or not is_instance_valid(new_herder):
		return
	if _npc.is_herded and _npc.herder == new_herder:
		return
	if HerdManager and not HerdManager.can_add_herd_animal(new_herder, _npc):
		return
	# Switch away from old herder
	var old_count: int = 0
	if _npc.is_herded and _npc.herder and is_instance_valid(_npc.herder) and _npc.herder != new_herder:
		if HerdManager:
			HerdManager.unregister_follower(_npc.herder, _npc)
		if "herded_count" in _npc.herder:
			old_count = _npc.herder.herded_count
			_npc.herder.herded_count = max(0, _npc.herder.herded_count - 1)
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled():
				var hname: String = str(_npc.herder.get("npc_name")) if _npc.herder.get("npc_name") != null else (str(_npc.herder.name) if _npc.herder else "?")
				pi.herd_count_change(hname, old_count, _npc.herder.herded_count, "switch_away")
	_npc.is_herded = true
	_npc.herder = new_herder
	_npc.herd_mentality_active = true
	if HerdManager:
		HerdManager.register_follower(new_herder, _npc)
	if "herded_count" in new_herder:
		old_count = new_herder.herded_count
		new_herder.herded_count += 1
		var pi2 = get_node_or_null("/root/PlaytestInstrumentor")
		if pi2 and pi2.is_enabled():
			var hname2: String = str(new_herder.get("npc_name")) if new_herder.get("npc_name") != null else (str(new_herder.name) if new_herder else "?")
			pi2.herd_count_change(hname2, old_count, new_herder.herded_count, "attach")
	if not new_herder.is_in_group("player"):
		var herder_type: String = new_herder.get("npc_type") as String if new_herder.get("npc_type") != null else ""
		if herder_type == "caveman" or herder_type == "clansman":
			# Never force-enter herd_wildnpc if ordered to follow player or in ATTACK/GUARD
			var blocked: bool = new_herder.get("follow_is_ordered") as bool if new_herder.get("follow_is_ordered") != null else false
			if not blocked:
				var ctx_hc: Dictionary = new_herder.get("command_context") if new_herder.get("command_context") != null else {}
				var mode_hc: String = ctx_hc.get("mode", "FOLLOW") as String
				if mode_hc != "FOLLOW":
					blocked = true
			if not blocked:
				var herder_fsm = new_herder.get_node_or_null("FSM")
				if herder_fsm and herder_fsm.has_method("change_state"):
					herder_fsm.change_state("herd_wildnpc")
	herder_instance_id = new_herder.get_instance_id()
	attached.emit(new_herder)


func detach() -> void:
	if not _npc or not _npc.is_herded:
		return
	var old: Node2D = _npc.herder
	if _npc.herder and is_instance_valid(_npc.herder):
		if HerdManager:
			HerdManager.unregister_follower(_npc.herder, _npc)
		if "herded_count" in _npc.herder:
			var old_c: int = _npc.herder.herded_count
			_npc.herder.herded_count = max(0, _npc.herder.herded_count - 1)
			var pi = get_node_or_null("/root/PlaytestInstrumentor")
			if pi and pi.is_enabled():
				var hname: String = str(_npc.herder.get("npc_name")) if _npc.herder.get("npc_name") != null else (str(_npc.herder.name) if _npc.herder else "?")
				pi.herd_count_change(hname, old_c, _npc.herder.herded_count, "clear_herd")
	_npc.is_herded = false
	_npc.herder = null
	_npc.follow_is_ordered = false
	_npc.herd_mentality_active = false
	herder_instance_id = 0
	if old:
		detached.emit(old)
