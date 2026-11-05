extends Area2D
class_name HerdInfluenceArea

# HerdInfluenceArea - Animal-authoritative influence-based herding
# Tracks herders (cavemen, clansmen, player) in radius. Influence accumulates over time.
# When influence exceeds threshold for contest_min_duration, transfer occurs (deterministic).
# Tie-breaker: smaller distance wins when influence equal.
# Herd locked when leader in combat. max_herd_size enforced per herder.

signal contested_started(animal: Node, challenger: Node)
signal contested_ended(animal: Node, new_herder: Node)

var _herder_data: Dictionary = {}  # instance_id -> {node, influence, time_above_threshold}
var _contest_challenger: Node2D = null
var _contest_start_time: float = 0.0
var _nearby_seed_wait: float = 0.0

var _influence_radius: float = 200.0
var _influence_base_rate: float = 40.0  # Faster accumulation for quicker follow
var _influence_threshold: float = 50.0
var _influence_decay_rate: float = 1.0
var _contest_min_duration: float = 0.08  # Near-instant (~5 frames) once above threshold
var _initial_influence: float = 55.0  # Start above threshold when herder enters - instant follow
var _max_herd_size: int = 8

# Align distance check with Area2D overlap: herder can overlap when center is beyond radius
const BODY_RADIUS_BUFFER: float = 60.0
## Guide follow band. A catch out by the 300px snap lets him walk her off the leash.
const ATTACH_DISTANCE: float = 150.0
## Outsider steal only. Same-clan brothers never enter this timer.
const OUTSIDER_CONTEST_SEC: float = 0.75

func _ready() -> void:
	# Multiplayer: only server resolves steals / HerdManager.try_transfer (plan §9.2).
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		monitoring = false
		set_physics_process(false)
		return
	monitoring = true
	monitorable = false
	# Cavemen/clansmen use collision_layer 2; default mask=1 only detects player (layer 1)
	# Set mask=3 (1|2) to detect both player and cavemen/clansmen
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_load_config()
	_setup_collision_shape()


func _load_config() -> void:
	if not NPCConfig:
		return
	if "herd_mentality_detection_range" in NPCConfig:
		_influence_radius = NPCConfig.herd_mentality_detection_range as float
	if "attraction_base_rate" in NPCConfig:
		_influence_base_rate = NPCConfig.attraction_base_rate as float
	if "attraction_threshold" in NPCConfig:
		_influence_threshold = NPCConfig.attraction_threshold as float
	if "attraction_decay_rate" in NPCConfig:
		_influence_decay_rate = NPCConfig.attraction_decay_rate as float
	if "influence_base_rate" in NPCConfig:
		_influence_base_rate = NPCConfig.influence_base_rate as float
	if "influence_threshold" in NPCConfig:
		_influence_threshold = NPCConfig.influence_threshold as float
	if "influence_decay_rate" in NPCConfig:
		_influence_decay_rate = NPCConfig.influence_decay_rate as float
	if "contest_min_duration" in NPCConfig:
		_contest_min_duration = NPCConfig.contest_min_duration as float
	if "initial_influence" in NPCConfig:
		_initial_influence = NPCConfig.initial_influence as float
	if "max_herd_size" in NPCConfig:
		_max_herd_size = NPCConfig.max_herd_size as int


func _setup_collision_shape() -> void:
	if get_child_count() > 0:
		return
	var shape = CircleShape2D.new()
	shape.radius = _influence_radius
	var cs = CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)


func _on_body_entered(body: Node2D) -> void:
	if not body or not _is_valid_herder(body):
		return
	var instance_id: int = body.get_instance_id()
	if not _herder_data.has(instance_id):
		_herder_data[instance_id] = {"node": body, "influence": 0.0, "time_above_threshold": 0.0}
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled():
		var animal = get_parent()
		var aname: String = str(animal.get("npc_name")) if animal and animal.get("npc_name") != null else "?"
		var hname: String = str(body.get("npc_name")) if body and body.get("npc_name") != null else str(body.name)
		var htype: String = "player" if body.is_in_group("player") else (str(body.get("npc_type")) if body.get("npc_type") != null else "?")
		pi.herd_influence_body_entered(aname, hname, htype)


func _on_body_exited(body: Node2D) -> void:
	if not body:
		return
	var instance_id: int = body.get_instance_id()
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled():
		var animal = get_parent()
		var aname: String = str(animal.get("npc_name")) if animal and animal.get("npc_name") != null else "?"
		var hname: String = str(body.name) if body else "?"
		pi.herd_influence_body_exited(aname, hname)
	_herder_data.erase(instance_id)
	if _contest_challenger == body:
		_contest_challenger = null
		_contest_start_time = 0.0


func _seed_herders_already_inside(animal: Node, delta: float) -> void:
	_nearby_seed_wait -= delta
	if _nearby_seed_wait > 0.0:
		return
	_nearby_seed_wait = 0.25
	var tree := animal.get_tree()
	if tree == null:
		return
	var reach: float = _influence_radius + BODY_RADIUS_BUFFER
	var pos: Vector2 = (animal as Node2D).global_position
	var bodies: Array = tree.get_nodes_in_group("npcs")
	for player_node in tree.get_nodes_in_group("player"):
		bodies.append(player_node)
	for body in bodies:
		if body == animal or not (body is Node2D) or not is_instance_valid(body):
			continue
		if not _is_valid_herder(body):
			continue
		if pos.distance_to((body as Node2D).global_position) > reach:
			continue
		var instance_id: int = body.get_instance_id()
		if _herder_data.has(instance_id):
			continue
		_herder_data[instance_id] = {"node": body, "influence": 0.0, "time_above_threshold": 0.0}
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.is_enabled():
			var aname: String = str(animal.get("npc_name")) if animal.get("npc_name") != null else "?"
			var hname: String = str(body.get("npc_name")) if body.get("npc_name") != null else str(body.name)
			var htype: String = "player" if body.is_in_group("player") else str(body.get("npc_type"))
			pi.herd_influence_body_entered(aname, hname, htype)


func _clan_of(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("get_clan_name"):
		return str(node.get_clan_name())
	if node.get("clan_name") != null:
		return str(node.get("clan_name"))
	return ""


func _same_clan(a: Node, b: Node) -> bool:
	var ca := _clan_of(a)
	var cb := _clan_of(b)
	return ca != "" and ca == cb


func _herder_blocked(herder: Node, animal: Node, current: Node, already: bool) -> bool:
	if not is_instance_valid(herder) or (herder.has_method("is_dead") and herder.is_dead()):
		return true
	if herder.get("follow_is_ordered"):
		return true
	if herder.get("npc_type") == "clansman":
		var ctx: Dictionary = herder.get("command_context") if herder.get("command_context") != null else {}
		if str(ctx.get("mode", "FOLLOW")) != "FOLLOW":
			return true
	var herd_n := 0
	if HerdManager:
		herd_n = HerdManager.get_herd_animal_count(herder)
	elif herder.get("herded_count") != null:
		herd_n = int(herder.get("herded_count"))
	if herd_n >= _max_herd_size and herder != current:
		return true
	if already and current and is_instance_valid(current):
		var ct = current.get("combat_target")
		if ct != null and is_instance_valid(ct) and herder != current:
			return true
	if animal.get("follow_is_ordered") and already and current and herder != current:
		return true
	return false


func _consider_attach(animal: Node, animal_pos: Vector2, delta: float, is_server: bool, already: bool, current: Node) -> void:
	var closest: Node2D = null
	var closest_dist := INF
	var outsider: Node2D = null
	var outsider_dist := INF
	var current_dist := INF
	if already and current and is_instance_valid(current):
		current_dist = animal_pos.distance_to(current.global_position)
	for instance_id in _herder_data:
		var data = _herder_data[instance_id]
		var herder: Node2D = data.node
		if _herder_blocked(herder, animal, current, already):
			data.time_above_threshold = 0.0
			continue
		var dist: float = animal_pos.distance_to(herder.global_position)
		if dist > ATTACH_DISTANCE:
			data.time_above_threshold = 0.0
			continue
		if already and current and herder != current and _same_clan(herder, current):
			data.time_above_threshold = 0.0
			data.influence = 0.0
			continue
		if not already:
			if dist < closest_dist:
				closest = herder
				closest_dist = dist
			continue
		if herder == current:
			data.time_above_threshold = 0.0
			continue
		if dist >= current_dist:
			data.time_above_threshold = 0.0
			continue
		data.time_above_threshold += delta
		if data.time_above_threshold >= OUTSIDER_CONTEST_SEC and dist < outsider_dist:
			outsider = herder
			outsider_dist = dist
	if not already and closest:
		_commit_transfer(animal, closest, is_server)
	elif outsider:
		_commit_transfer(animal, outsider, is_server)


func _commit_transfer(animal: Node, best_herder: Node2D, is_server: bool) -> void:
	var old_herder = animal.get("herder") if animal.get("herder") != null else null
	if old_herder == best_herder:
		return
	var old_name: String = str(old_herder.get("npc_name")) if old_herder and is_instance_valid(old_herder) else "none"
	var new_name: String = str(best_herder.get("npc_name")) if best_herder.get("npc_name") != null else str(best_herder.name)
	var transferred := false
	if is_server:
		if HerdManager:
			transferred = HerdManager.try_transfer(animal as Node2D, best_herder)
		elif animal.has_method("_try_herd_chance"):
			transferred = animal._try_herd_chance(best_herder, true)
	if not transferred or animal.get("herder") == old_herder:
		return
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled():
		var aname: String = str(animal.get("npc_name")) if animal.get("npc_name") != null else "?"
		pi.herd_influence_transfer(aname, old_name, new_name)
	var best_data = _herder_data.get(best_herder.get_instance_id())
	if best_data:
		best_data.time_above_threshold = 0.0
		best_data.influence = 0.0
	_contest_challenger = null
	contested_ended.emit(animal, best_herder)


func _follow_break_distance() -> float:
	var break_dist := 300.0
	if NPCConfig and "herd_max_distance_before_break" in NPCConfig:
		break_dist = float(NPCConfig.herd_max_distance_before_break)
	return break_dist


func _is_valid_herder(body: Node) -> bool:
	if not body or not is_instance_valid(body):
		return false
	if body.is_in_group("player"):
		return true
	if body.has_method("is_dead") and body.is_dead():
		return false
	var npc_type: String = body.get("npc_type") as String if body.get("npc_type") != null else ""
	return npc_type in ["caveman", "clansman"]


func _physics_process(delta: float) -> void:
	if LagProfiler and LagProfiler.is_enabled():
		LagProfiler.record_herd_influence_physics()
	var animal = get_parent()
	if not animal or not is_instance_valid(animal):
		return
	if not animal.has_method("is_wild") or not animal.is_wild():
		return
	if animal.has_method("is_dead") and animal.is_dead():
		return
	# body_entered does not fire for a man already standing inside when this circle wakes.
	_seed_herders_already_inside(animal, delta)

	# Clean invalid entries (freed nodes + dead herders)
	var to_erase: Array = []
	for instance_id in _herder_data:
		var data = _herder_data[instance_id]
		var node = data.node
		if not is_instance_valid(node):
			to_erase.append(instance_id)
			continue
		if node.has_method("is_dead") and node.is_dead():
			to_erase.append(instance_id)
	for id in to_erase:
		_herder_data.erase(id)
		if _herder_data.size() == 0:
			_contest_challenger = null

	var animal_pos: Vector2 = animal.global_position
	var current_herder = animal.get("herder") if animal.get("herder") != null else null
	var is_herded: bool = animal.get("is_herded") as bool if animal.get("is_herded") != null else false

	# Combat lock: herd locked when leader in combat
	var herd_locked: bool = false
	if is_herded and current_herder and is_instance_valid(current_herder):
		var ct = current_herder.get("combat_target")
		if ct != null and is_instance_valid(ct):
			herd_locked = true

	var current_time: float = Time.get_ticks_msec() / 1000.0
	var is_server_or_offline: bool = (not multiplayer.has_multiplayer_peer()) or multiplayer.is_server()

	# First pass: update influence for all herders
	for instance_id in _herder_data:
		var data = _herder_data[instance_id]
		var herder: Node2D = data.node
		if not is_instance_valid(herder) or (herder.has_method("is_dead") and herder.is_dead()):
			continue

		# max_herd_size: don't accumulate for herder at cap (HerdManager = herd animals only)
		var herd_n: int = 0
		if HerdManager:
			herd_n = HerdManager.get_herd_animal_count(herder)
		else:
			herd_n = herder.get("herded_count") as int if herder.get("herded_count") != null else 0
		if herd_n >= _max_herd_size and (not is_herded or herder != current_herder):
			data.influence = 0.0
			data.time_above_threshold = 0.0
			continue

		var dist: float = animal_pos.distance_to(herder.global_position)
		if dist > _influence_radius + BODY_RADIUS_BUFFER:
			data.influence = max(0.0, data.influence - _influence_decay_rate * delta)
			data.time_above_threshold = 0.0
			continue

		# Don't accumulate on ordered followers or clansmen in ATTACK/GUARD
		if herder.get("follow_is_ordered"):
			data.influence = max(0.0, data.influence - _influence_decay_rate * delta)
			data.time_above_threshold = 0.0
			continue
		if herder.get("npc_type") == "clansman":
			var ctx_ia: Dictionary = herder.get("command_context") if herder.get("command_context") != null else {}
			var mode_ia: String = ctx_ia.get("mode", "FOLLOW") as String
			if mode_ia != "FOLLOW":
				data.influence = max(0.0, data.influence - _influence_decay_rate * delta)
				data.time_above_threshold = 0.0
				continue

		# Accumulate influence (closer = faster)
		var proximity_factor: float = 1.0 - (dist / _influence_radius) * 0.5
		data.influence = min(100.0, data.influence + _influence_base_rate * delta * (1.0 + proximity_factor))

		# The follow snaps at this distance. A catch past it drops her on the next frame.
		if dist >= _follow_break_distance():
			data.time_above_threshold = 0.0
			continue

		# Already following this man. Do not open a contest he would win against himself.
		if is_herded and current_herder and herder == current_herder:
			data.time_above_threshold = 0.0
			continue

		# Check if this herder can challenge
		if herd_locked and (not is_herded or herder != current_herder):
			data.time_above_threshold = 0.0
			continue

		# Same-clan no steal
		if is_herded and current_herder and herder != current_herder:
			var herder_clan: String = ""
			var current_clan: String = ""
			if herder.has_method("get_clan_name"):
				herder_clan = herder.get_clan_name()
			elif herder.get("clan_name") != null:
				herder_clan = herder.get("clan_name") as String
			if current_herder.has_method("get_clan_name"):
				current_clan = current_herder.get_clan_name()
			elif current_herder.get("clan_name") != null:
				current_clan = current_herder.get("clan_name") as String
			if herder_clan != "" and herder_clan == current_clan:
				data.time_above_threshold = 0.0
				continue

		# follow_is_ordered: cannot steal
		if animal.get("follow_is_ordered") and is_herded and current_herder and herder != current_herder:
			data.time_above_threshold = 0.0
			continue

	_consider_attach(animal, animal_pos, delta, is_server_or_offline, is_herded, current_herder)
