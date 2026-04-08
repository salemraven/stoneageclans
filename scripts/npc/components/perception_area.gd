extends Area2D
class_name PerceptionArea

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

# PerceptionArea - Implements AOP (Area of Perception). Event-driven spatial tracking.
# Base layer for AOA, combat target selection, and agro.
# Replaces get_nodes_in_group() performance bottleneck.

var nearby_enemies := {}
var nearby_herdables := {}  # instance_id -> Node2D; only populated for cavemen/clansmen
var detection_range: float = 300.0  # Set from config in _ready()

const PRUNE_INTERVAL: float = 0.5
var _prune_timer: float = 0.0
static var _layer_logged_once := false

func _ready() -> void:
	# Multiplayer: disable on non-authority
	if multiplayer.has_multiplayer_peer():
		var parent = get_parent()
		if parent and not parent.is_multiplayer_authority():
			monitoring = false
			set_process(false)
			UnifiedLogger.log_system("PerceptionArea disabled (non-authority): %s" % (parent.get("npc_name") if parent else "?"), {}, UnifiedLogger.Level.DEBUG)
			return

	monitoring = true
	monitorable = false
	collision_mask = 3  # Layers 1+2 (player + NPCs)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Set radius from NPCConfig based on parent npc_type
	var parent = get_parent()
	if parent:
		var npc_type: String = parent.get("npc_type") as String if parent.get("npc_type") != null else ""
		if NPCConfig:
			if npc_type == "mammoth":
				detection_range = NPCConfig.aop_radius_mammoth
			elif npc_type in ["caveman", "clansman", "woman", "sheep", "goat"]:
				detection_range = NPCConfig.aop_radius_default
			else:
				detection_range = 300.0
		# Trait overrides (AOP Phase 2): leader/searcher radii when traits exist
		if NPCConfig:
			if parent.get("is_leader") == true and NPCConfig.aop_radius_leader > 0.0:
				detection_range = NPCConfig.aop_radius_leader
			elif parent.get("is_searcher") == true and NPCConfig.aop_radius_searcher > 0.0:
				detection_range = NPCConfig.aop_radius_searcher

	# Sync CollisionShape2D radius
	var shape_node = get_node_or_null("CollisionShape2D")
	if shape_node and shape_node is CollisionShape2D:
		var shape = (shape_node as CollisionShape2D).shape
		if shape is CircleShape2D:
			(shape as CircleShape2D).radius = detection_range

	# Layer verification (first-spawn DEBUG log)
	if not _layer_logged_once and not Engine.is_editor_hint():
		var dc = get_node_or_null("/root/DebugConfig")
		if dc and (dc.get("enable_agro_combat_test") or dc.get("enable_verbose_npc_logging")):
			_layer_logged_once = true
			var parent_layer = parent.collision_layer if parent is PhysicsBody2D else -1
			UnifiedLogger.log_debug("PerceptionArea init: parent_layer=%d collision_mask=%d radius=%.0f" % [parent_layer, collision_mask, detection_range], UnifiedLogger.Category.SYSTEM, {"npc": parent.get("npc_name") if parent else "?"})

func _process(delta: float) -> void:
	# Disable when parent dead
	var parent = get_parent()
	if parent and parent.has_method("is_dead") and parent.is_dead():
		monitoring = false
		set_process(false)
		return

	_prune_timer += delta
	if _prune_timer >= PRUNE_INTERVAL:
		_prune_timer = 0.0
		_prune_invalid()

func _prune_invalid() -> void:
	var to_remove: Array = []
	for instance_id in nearby_enemies:
		var enemy = nearby_enemies[instance_id]
		if not is_instance_valid(enemy):
			to_remove.append(instance_id)
			continue
		var target_health: HealthComponent = enemy.get_node_or_null("HealthComponent")
		if target_health and target_health.is_dead:
			to_remove.append(instance_id)
	for id in to_remove:
		nearby_enemies.erase(id)
	# Prune herdables
	to_remove.clear()
	for instance_id in nearby_herdables:
		var h = nearby_herdables[instance_id]
		if not is_instance_valid(h):
			to_remove.append(instance_id)
			continue
		var h_health: HealthComponent = h.get_node_or_null("HealthComponent")
		if h_health and h_health.is_dead:
			to_remove.append(instance_id)
			continue
		var clan: String = h.get("clan_name") as String if h.get("clan_name") != null else ""
		if clan != "":
			to_remove.append(instance_id)
	for id in to_remove:
		nearby_herdables.erase(id)

func _on_body_entered(body: Node2D) -> void:
	if not body:
		return
	if body == get_parent():
		return  # Skip self
	if not _is_authority():
		return

	if body.is_in_group("npcs") or body.is_in_group("player"):
		nearby_enemies[body.get_instance_id()] = body
	# Herdables: only for cavemen/clansmen (herders)
	var parent = get_parent()
	if parent:
		var npc_type: String = parent.get("npc_type") as String if parent.get("npc_type") != null else ""
		if npc_type == "caveman" or npc_type == "clansman":
			var btype: String = body.get("npc_type") as String if body.get("npc_type") != null else ""
			if btype in ["woman", "sheep", "goat"]:
				var clan: String = body.get("clan_name") as String if body.get("clan_name") != null else ""
				if clan == "":
					nearby_herdables[body.get_instance_id()] = body

func _on_body_exited(body: Node2D) -> void:
	if not body:
		return
	if not _is_authority():
		return
	var instance_id = body.get_instance_id()
	if nearby_enemies.has(instance_id):
		nearby_enemies.erase(instance_id)
	if nearby_herdables.has(instance_id):
		nearby_herdables.erase(instance_id)

func _is_authority() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	var parent = get_parent()
	if not parent:
		return true
	return parent.is_multiplayer_authority()

func get_nearest_enemy(origin: Vector2, npc: NPCBase = null) -> Node:
	_prune_invalid()
	var closest: Node = null
	var best_dist := INF
	var npc_name: String = npc.npc_name if npc else "unknown"

	for enemy in nearby_enemies.values():
		if not is_instance_valid(enemy):
			continue
		var target_health: HealthComponent = enemy.get_node_or_null("HealthComponent")
		if target_health and target_health.is_dead:
			continue
		var target_type_prop = enemy.get("npc_type") if enemy else null
		var target_type: String = target_type_prop as String if target_type_prop != null else ""
		var is_player: bool = enemy.is_in_group("player") if enemy else false
		if target_type != "caveman" and target_type != "clansman" and not is_player:
			continue
		if npc and CombatAllyCheck.is_ally(npc, enemy):
			continue
		var distance = origin.distance_squared_to(enemy.global_position)
		if distance < best_dist and distance <= detection_range * detection_range:
			best_dist = distance
			closest = enemy

	if closest:
		var target_name: String = "unknown"
		var target_clan: String = ""
		if closest is NPCBase:
			target_name = closest.npc_name
			target_clan = closest.get_clan_name() if closest.has_method("get_clan_name") else ""
		elif closest.is_in_group("player"):
			target_name = "Player"
			target_clan = closest.get_clan_name() if closest.has_method("get_clan_name") else ""
		var npc_clan: String = npc.get_clan_name() if npc and npc.has_method("get_clan_name") else ""
		if npc:
			var last_target = npc.get_meta("last_detection_target_logged", null) if npc.has_meta("last_detection_target_logged") else null
			if closest != last_target:
				UnifiedLogger.log("TARGET_SELECTED: %s (clan: %s) → %s (clan: %s, distance: %.1f)" % [npc_name, npc_clan, target_name, target_clan, sqrt(best_dist)], UnifiedLogger.Category.COMBAT, UnifiedLogger.Level.DEBUG, {"npc": npc_name, "target": target_name})
				npc.set_meta("last_detection_target_logged", closest)

	return closest

func get_enemies_in_range(origin: Vector2, radius: float, npc: NPCBase = null) -> Array:
	_prune_invalid()
	var out: Array = []
	var r2 := radius * radius
	for enemy in nearby_enemies.values():
		if not is_instance_valid(enemy):
			continue
		var target_health: HealthComponent = enemy.get_node_or_null("HealthComponent")
		if target_health and target_health.is_dead:
			continue
		var target_type_prop = enemy.get("npc_type") if enemy else null
		var target_type: String = target_type_prop as String if target_type_prop != null else ""
		var is_player: bool = enemy.is_in_group("player") if enemy else false
		if target_type != "caveman" and target_type != "clansman" and not is_player:
			continue
		if npc and CombatAllyCheck.is_ally(npc, enemy):
			continue
		var dist_sq = origin.distance_squared_to(enemy.global_position)
		if dist_sq <= r2:
			out.append(enemy)
	return out

func get_threats_in_range(origin: Vector2, radius: float, npc: NPCBase = null) -> Array:
	"""For mammoth: cavemen, clansmen, predator, player. Same validity as get_enemies_in_range but includes predator."""
	_prune_invalid()
	var out: Array = []
	var r2 := radius * radius
	for enemy in nearby_enemies.values():
		if not is_instance_valid(enemy):
			continue
		var target_health: HealthComponent = enemy.get_node_or_null("HealthComponent")
		if target_health and target_health.is_dead:
			continue
		var target_type_prop = enemy.get("npc_type") if enemy else null
		var target_type: String = target_type_prop as String if target_type_prop != null else ""
		var is_player: bool = enemy.is_in_group("player") if enemy else false
		if target_type != "caveman" and target_type != "clansman" and target_type != "predator" and not is_player:
			continue
		if npc and CombatAllyCheck.is_ally(npc, enemy):
			continue
		var dist_sq = origin.distance_squared_to(enemy.global_position)
		if dist_sq <= r2:
			out.append(enemy)
	return out

func has_enemies(npc: NPCBase = null) -> bool:
	_prune_invalid()
	for enemy in nearby_enemies.values():
		if not is_instance_valid(enemy):
			continue
		var target_health: HealthComponent = enemy.get_node_or_null("HealthComponent")
		if target_health and target_health.is_dead:
			continue
		var target_type_prop = enemy.get("npc_type") if enemy else null
		var target_type: String = target_type_prop as String if target_type_prop != null else ""
		var is_player: bool = enemy.is_in_group("player") if enemy else false
		if npc and CombatAllyCheck.is_ally(npc, enemy):
			continue
		if target_type == "caveman" or target_type == "clansman" or is_player:
			return true
	return false

func get_all_enemies() -> Array:
	_prune_invalid()
	var valid_enemies := []
	for enemy in nearby_enemies.values():
		if is_instance_valid(enemy):
			var target_health: HealthComponent = enemy.get_node_or_null("HealthComponent")
			if target_health and not target_health.is_dead:
				valid_enemies.append(enemy)
	return valid_enemies

func get_herdables_in_range(origin: Vector2, radius: float, npc: NPCBase = null) -> Array:
	"""Return valid wild herdables (woman, sheep, goat) within radius, sorted by distance. Filter by can_join_clan()."""
	_prune_invalid()
	var out: Array = []
	var r2 := radius * radius
	for h in nearby_herdables.values():
		if not is_instance_valid(h):
			continue
		var h_health: HealthComponent = h.get_node_or_null("HealthComponent")
		if h_health and h_health.is_dead:
			continue
		var clan: String = h.get("clan_name") as String if h.get("clan_name") != null else ""
		if clan != "":
			continue
		if h.has_method("can_join_clan") and not h.can_join_clan():
			continue
		var dist_sq := origin.distance_squared_to(h.global_position)
		if dist_sq <= r2:
			out.append({"node": h, "distance": sqrt(dist_sq)})
	out.sort_custom(func(a, b): return a.distance < b.distance)
	var nodes: Array = []
	for item in out:
		nodes.append(item.node)
	return nodes

func has_herdables(npc: NPCBase = null) -> bool:
	"""Quick check: any valid herdables in range."""
	var origin: Vector2 = npc.global_position if npc else (get_parent().global_position if get_parent() else Vector2.ZERO)
	var arr = get_herdables_in_range(origin, detection_range, npc)
	return arr.size() > 0
