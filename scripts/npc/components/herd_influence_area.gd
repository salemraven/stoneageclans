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

var _influence_radius: float = 200.0
var _influence_base_rate: float = 40.0  # Faster accumulation for quicker follow
var _influence_threshold: float = 50.0
var _influence_decay_rate: float = 1.0
var _contest_min_duration: float = 0.08  # Near-instant (~5 frames) once above threshold
var _initial_influence: float = 55.0  # Start above threshold when herder enters - instant follow
var _max_herd_size: int = 8

# Align distance check with Area2D overlap: herder can overlap when center is beyond radius
const BODY_RADIUS_BUFFER: float = 60.0

func _ready() -> void:
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
		_herder_data[instance_id] = {"node": body, "influence": _initial_influence, "time_above_threshold": 0.0}
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled():
		var animal = get_parent()
		var aname: String = str(animal.get("npc_name")) if animal and animal.get("npc_name") != null else "?"
		var hname: String = str(body.name) if body else "?"
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
	var animal = get_parent()
	if not animal or not is_instance_valid(animal):
		return
	if not animal.has_method("is_wild") or not animal.is_wild():
		return
	if animal.has_method("is_dead") and animal.is_dead():
		return

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

	# First pass: update influence for all herders
	for instance_id in _herder_data:
		var data = _herder_data[instance_id]
		var herder: Node2D = data.node
		if not is_instance_valid(herder) or (herder.has_method("is_dead") and herder.is_dead()):
			continue

		# max_herd_size: don't accumulate for herder at cap
		var herded_count: int = herder.get("herded_count") as int if herder.get("herded_count") != null else 0
		if herded_count >= _max_herd_size and (not is_herded or herder != current_herder):
			data.influence = 0.0
			data.time_above_threshold = 0.0
			continue

		var dist: float = animal_pos.distance_to(herder.global_position)
		if dist > _influence_radius + BODY_RADIUS_BUFFER:
			data.influence = max(0.0, data.influence - _influence_decay_rate * delta)
			data.time_above_threshold = 0.0
			continue

		# Accumulate influence (closer = faster)
		var proximity_factor: float = 1.0 - (dist / _influence_radius) * 0.5
		data.influence = min(100.0, data.influence + _influence_base_rate * delta * (1.0 + proximity_factor))

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

		if data.influence >= _influence_threshold:
			data.time_above_threshold += delta
		else:
			data.time_above_threshold = 0.0

	# Second pass: find best candidate (highest influence, tie-break by distance), then transfer if ready
	var best_herder: Node2D = null
	var best_influence: float = -1.0
	var best_distance: float = INF
	for instance_id in _herder_data:
		var data = _herder_data[instance_id]
		var herder: Node2D = data.node
		if not is_instance_valid(herder) or (herder.has_method("is_dead") and herder.is_dead()):
			continue
		if data.influence < _influence_threshold or data.time_above_threshold < _contest_min_duration:
			continue
		var dist: float = animal_pos.distance_to(herder.global_position)
		var is_better: bool = data.influence > best_influence
		if not is_better and data.influence == best_influence:
			is_better = dist < best_distance  # Tie-breaker: smaller distance
		if is_better:
			best_herder = herder
			best_influence = data.influence
			best_distance = dist

	if best_herder and animal.has_method("_try_herd_chance"):
		var old_herder = animal.get("herder") if animal.get("herder") != null else null
		var old_name: String = str(old_herder.get("npc_name")) if old_herder and is_instance_valid(old_herder) else "none"
		var new_name: String = str(best_herder.get("npc_name")) if best_herder.get("npc_name") != null else (str(best_herder.name) if best_herder else "?")
		if animal._try_herd_chance(best_herder, true):
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
	else:
		# Emit contested_started for UI/debug when we have a candidate above threshold
		for instance_id in _herder_data:
			var data = _herder_data[instance_id]
			if data.influence >= _influence_threshold and data.time_above_threshold > 0:
				if _contest_challenger != data.node:
					_contest_challenger = data.node
					_contest_start_time = current_time
					var pi = get_node_or_null("/root/PlaytestInstrumentor")
					if pi and pi.is_enabled():
						var aname: String = str(animal.get("npc_name")) if animal.get("npc_name") != null else "?"
						var cname: String = str(data.node.get("npc_name")) if data.node.get("npc_name") != null else (str(data.node.name) if data.node else "?")
						pi.herd_influence_contested(aname, cname, data.influence)
					contested_started.emit(animal, data.node)
				break
