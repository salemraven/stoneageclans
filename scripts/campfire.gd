extends Node2D
class_name Campfire

const _TerritoryJobService = preload("res://scripts/systems/territory_job_service.gd")
const CAMPFIRE_SCENE = preload("res://scenes/Campfire.tscn")

enum NomadState { NONE, PREPARING, WALKING, PLACING }

signal campfire_despawned(campfire_node: Node2D)
signal emergency_defend_triggered
signal nomad_state_changed(new_state: int)
signal resources_status_changed(has_wood: bool, has_food: bool)

# Small base (radius 250), clan name on placement, inventory, fire on/off
# LandClaim-compatible interface for NPCs (defend_target, search_home_claim)

@export var clan_name: String = "CLAN"
@export var radius: float = 250.0
@export var player_owned: bool = false
## 0 = auto (ClanBrain baseline n/4 + drag); >0 = min slots ceil(n * ratio). Persisted with territory.
@export var player_defend_ratio: float = 0.0
var defend_ratio: float = 0.0
var search_ratio: float = 0.2

var sprite: Sprite2D = null
var radius_indicator: Node2D = null
var _collision_area: Area2D = null
var inventory: InventoryData = null

var is_fire_on: bool = false
var _wood_consume_timer: float = 0.0
var _fire_off_from_depletion: bool = false
var _last_has_wood: bool = true
var _last_has_food: bool = true

# Abandonment: when extinguished + player far for X sec, despawn
const ABANDON_RADIUS: float = 600.0
const ABANDON_SEC: float = 120.0
var _abandonment_timer: float = 0.0

# Nomad Mode
var nomad_state: int = NomadState.NONE
var nomad_target_pos: Vector2 = Vector2.ZERO
var nomad_cooldown_until: float = 0.0
var owner_npc: Node2D = null
var _ai_low_resource_timer: float = 0.0

# LandClaim-compatible interface
var assigned_defenders: Array = []
var assigned_searchers: Array = []

# Phase 3: ClanBrain (same script as LandClaim; nomadic mode in brain)
var clan_brain: RefCounted = null

# Alert throttling (mirror land_claim.gd)
var _last_alert_time: float = 0.0
var _last_alert_level: int = 0
const ALERT_THROTTLE_SEC: float = 0.5


func _ready() -> void:
	sprite = get_node_or_null("Sprite") as Sprite2D
	radius_indicator = get_node_or_null("RadiusIndicator") as Node2D
	
	if not inventory:
		var n: int = BalanceConfig.campfire_inventory_slots if BalanceConfig else 20
		var mx: int = BalanceConfig.campfire_inventory_max_stack if BalanceConfig else 999
		inventory = InventoryData.new(n, true, mx)
	
	_setup_sprite()
	_setup_collision()
	_draw_radius()
	
	if sprite:
		sprite.z_as_relative = false
		YSortUtils.update_building_draw_order(sprite, self)
	
	add_to_group("buildings")
	add_to_group("campfires")
	add_to_group("land_claims")
	set_meta("searcher_quota", 0)
	set_meta("defender_quota", 0)
	_initialize_clan_brain()
	_refresh_resource_flags(true)
	set_process(true)


func get_wood_burn_interval() -> float:
	if BalanceConfig:
		return BalanceConfig.campfire_wood_burn_interval
	return 60.0


func get_max_living_huts() -> int:
	if BalanceConfig:
		return BalanceConfig.campfire_max_living_huts
	return 3


func get_wood_count() -> int:
	if not inventory:
		return 0
	return inventory.get_count(ResourceData.ResourceType.WOOD)


func get_total_food_count() -> int:
	if not inventory:
		return 0
	var total := 0
	for food_type in ResourceData.EDIBLE_FOOD_TYPES:
		total += inventory.get_count(food_type)
	return total


func has_panic_wood() -> bool:
	var threshold: int = BalanceConfig.campfire_panic_threshold_wood if BalanceConfig else 0
	return get_wood_count() > threshold


func has_panic_food() -> bool:
	var threshold: int = BalanceConfig.campfire_panic_threshold_food if BalanceConfig else 0
	return get_total_food_count() > threshold


func _is_panic_resource_depleted() -> bool:
	return not has_panic_wood() or not has_panic_food()


func _refresh_resource_flags(force_emit: bool = false) -> void:
	var has_wood: bool = has_panic_wood()
	var has_food: bool = has_panic_food()
	if force_emit or has_wood != _last_has_wood or has_food != _last_has_food:
		_last_has_wood = has_wood
		_last_has_food = has_food
		resources_status_changed.emit(has_wood, has_food)


func _setup_sprite() -> void:
	if sprite:
		var tex = AssetRegistry.get_campfire_sprite()
		if tex:
			sprite.texture = tex
		sprite.modulate = Color(0.6, 0.6, 0.6)


func _setup_collision() -> void:
	_collision_area = Area2D.new()
	_collision_area.name = "InteractionArea"
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 32.0
	shape.shape = circle
	_collision_area.add_child(shape)
	add_child(_collision_area)
	_collision_area.input_event.connect(_on_input_event)


func _draw_radius() -> void:
	if not radius_indicator:
		return
	for c in radius_indicator.get_children():
		c.queue_free()
	var line := Line2D.new()
	line.width = YSortUtils.WORLD_OVERLAY_LINE_WIDTH_PX
	line.default_color = Color(0.8, 0.4, 0.1, YSortUtils.WORLD_OVERLAY_LINE_HERD_COLOR.a)
	var steps := 32
	for i in steps + 1:
		var a := TAU * float(i) / float(steps)
		line.add_point(Vector2(cos(a), sin(a)) * radius)
	radius_indicator.add_child(line)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var main = get_tree().get_first_node_in_group("main")
		if main and main.has_method("_on_campfire_clicked"):
			main._on_campfire_clicked(self)


func _process(delta: float) -> void:
	if clan_brain and not is_queued_for_deletion():
		var mp: MultiplayerAPI = get_multiplayer()
		if mp == null or not mp.has_multiplayer_peer() or mp.is_server():
			clan_brain.update(delta)
	_update_nomadic_crowding()

	if nomad_state != NomadState.NONE:
		_abandonment_timer = 0.0
		if nomad_state == NomadState.WALKING and not player_owned:
			_tick_ai_nomad_walk(delta)
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	if not is_fire_on:
		var player = get_tree().get_first_node_in_group("player")
		var dist: float = 9999.0
		if player and is_instance_valid(player):
			dist = global_position.distance_to(player.global_position)
		if dist > ABANDON_RADIUS:
			_abandonment_timer += delta
			if _abandonment_timer >= ABANDON_SEC:
				_despawn_campfire("abandoned")
				return
		else:
			_abandonment_timer = 0.0
		return

	_abandonment_timer = 0.0
	if not inventory:
		return

	_wood_consume_timer += delta
	var burn_interval: float = get_wood_burn_interval()
	if _wood_consume_timer >= burn_interval:
		_wood_consume_timer = 0.0
		if get_wood_count() > 0:
			inventory.remove_item(ResourceData.ResourceType.WOOD, 1)
			_refresh_resource_flags()
		else:
			is_fire_on = false
			_fire_off_from_depletion = true
			_update_fire_visual()
			_refresh_resource_flags()

	_track_ai_low_resources(delta)


func _track_ai_low_resources(delta: float) -> void:
	if player_owned or nomad_state != NomadState.NONE:
		_ai_low_resource_timer = 0.0
		return
	if not clan_brain:
		return
	var wood_threshold: int = BalanceConfig.ai_nomad_wood_threshold if BalanceConfig else 2
	var food_threshold: int = BalanceConfig.ai_nomad_food_threshold if BalanceConfig else 3
	var low: bool = get_wood_count() <= wood_threshold or get_total_food_count() <= food_threshold
	if not low:
		_ai_low_resource_timer = 0.0
		return
	_ai_low_resource_timer += delta
	var need_sec: float = BalanceConfig.ai_nomad_low_resource_sec if BalanceConfig else 60.0
	var now: float = Time.get_ticks_msec() / 1000.0
	if _ai_low_resource_timer >= need_sec and now >= nomad_cooldown_until:
		var trigger: String = "ai_wood" if get_wood_count() <= wood_threshold else "ai_food"
		begin_nomad_mode(trigger)


func _tick_ai_nomad_walk(_delta: float) -> void:
	if not owner_npc or not is_instance_valid(owner_npc):
		return
	if owner_npc.has_method("is_dead") and owner_npc.is_dead():
		return
	if nomad_target_pos == Vector2.ZERO:
		return
	if owner_npc.global_position.distance_to(nomad_target_pos) <= _ai_arrival_radius():
		_finish_ai_nomad_placement()
	elif owner_npc.steering_agent and owner_npc.steering_agent.has_method("set_target_position"):
		owner_npc.steering_agent.set_target_position(nomad_target_pos)


func _ai_arrival_radius() -> float:
	if BalanceConfig:
		return BalanceConfig.ai_nomad_arrival_radius
	return 50.0


func _update_nomadic_crowding() -> void:
	var huts: int = 0
	var cn: String = clan_name
	var max_huts: int = get_max_living_huts()
	for b in get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(b):
			continue
		if b is LandClaim:
			continue
		if not (b is BuildingBase):
			continue
		var bb: BuildingBase = b as BuildingBase
		if bb.building_type != ResourceData.ResourceType.LIVING_HUT:
			continue
		if bb.get("clan_name") != cn:
			continue
		if global_position.distance_to(bb.global_position) > radius:
			continue
		huts += 1
	var pen: float = 0.0
	if huts >= max_huts + 3:
		pen = 0.35
	elif huts >= max_huts + 1:
		pen = 0.15
	set_meta("nomadic_crowding_penalty", pen)
	set_meta("nomadic_living_hut_count", huts)


func set_fire_on(on: bool) -> void:
	if on:
		_fire_off_from_depletion = false
	is_fire_on = on
	_update_fire_visual()
	if not on:
		_refresh_resource_flags()


func _update_fire_visual() -> void:
	if sprite:
		sprite.modulate = Color.WHITE if is_fire_on else Color(0.6, 0.6, 0.6)


func begin_nomad_mode(trigger: String = "player") -> void:
	if nomad_state != NomadState.NONE:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < nomad_cooldown_until:
		return

	nomad_state = NomadState.PREPARING
	nomad_state_changed.emit(nomad_state)
	_sync_nomad_player_meta()

	var collected := _collect_all_clan_members()
	UnifiedLogger.log_system("NOMAD_MODE_START", {
		"clan": clan_name,
		"trigger": trigger,
		"npc_count": collected.size(),
		"target_pos": nomad_target_pos,
	})

	_freeze_clan_pregnancies(collected)
	_convert_clan_babies_to_icons(collected)
	_clear_clan_roles(collected)
	_unassign_clan_women(collected)
	_drop_clan_herded_animals(collected)

	if trigger.begins_with("ai"):
		if owner_npc == null or not is_instance_valid(owner_npc):
			owner_npc = _find_ai_clan_leader()
		if owner_npc == null or not is_instance_valid(owner_npc):
			_abort_nomad_mode("no_leader")
			return
		if nomad_target_pos == Vector2.ZERO:
			nomad_target_pos = _pick_ai_nomad_target()
		if nomad_target_pos == Vector2.ZERO:
			_abort_nomad_mode("no_valid_target")
			return
		_apply_nomad_follow_for_leader(collected, owner_npc)
	else:
		var leader := _get_player_leader()
		if leader:
			_apply_nomad_follow_for_leader(collected, leader)

	_orphan_buildings_in_radius()
	nomad_state = NomadState.WALKING
	nomad_state_changed.emit(nomad_state)
	_sync_nomad_player_meta()


func _complete_nomad_mode() -> void:
	UnifiedLogger.log_system("NOMAD_MODE_COMPLETE", {"clan": clan_name})
	nomad_state = NomadState.NONE
	nomad_state_changed.emit(nomad_state)
	_clear_nomad_player_meta()
	var cooldown: float = BalanceConfig.nomad_cooldown_sec if BalanceConfig else 30.0
	nomad_cooldown_until = Time.get_ticks_msec() / 1000.0 + cooldown
	queue_free()


func _abort_nomad_mode(reason: String) -> void:
	UnifiedLogger.log_system("NOMAD_MODE_ABORT", {"clan": clan_name, "reason": reason})
	nomad_state = NomadState.NONE
	nomad_target_pos = Vector2.ZERO
	nomad_state_changed.emit(nomad_state)
	_clear_nomad_player_meta()


func _despawn_campfire(reason: String) -> void:
	if nomad_state != NomadState.NONE:
		return
	_release_nearby_herdables()
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("campfire_despawned"):
		pi.campfire_despawned(clan_name, reason)
	campfire_despawned.emit(self)
	queue_free()


func _find_ai_clan_leader() -> Node2D:
	var best: Node2D = null
	var best_age: int = -1
	for npc in _collect_all_clan_members():
		if not is_instance_valid(npc):
			continue
		var npc_type: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
		if npc_type != "caveman" and npc_type != "clansman":
			continue
		var age: int = int(npc.get("age")) if npc.get("age") != null else 0
		if age > best_age:
			best_age = age
			best = npc as Node2D
	return best


func _collect_all_clan_members() -> Array:
	var result: Array = []
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_dead") and npc.is_dead():
			continue
		var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else str(npc.get("clan_name") if npc.get("clan_name") else "")
		if npc_clan == clan_name:
			result.append(npc)
	return result


func _get_player_leader() -> Node:
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_active_leader"):
		return main.get_active_leader()
	return get_tree().get_first_node_in_group("player")


func _apply_nomad_follow_for_leader(collected: Array, leader: Node) -> void:
	var main = get_tree().get_first_node_in_group("main")
	for npc in collected:
		if not is_instance_valid(npc):
			continue
		var npc_type: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
		if npc_type != "woman" and npc_type != "clansman" and npc_type != "caveman":
			continue
		if main and main.has_method("_set_nomad_follow"):
			main._set_nomad_follow(npc, leader, "nomad_mode")
		elif main and main.has_method("_set_ordered_follow") and (npc_type == "clansman" or npc_type == "caveman"):
			main._set_ordered_follow(npc, "nomad_mode")


func _clear_clan_roles(collected: Array) -> void:
	for npc in collected:
		if not is_instance_valid(npc):
			continue
		remove_npc_from_pools(npc)
		if npc.get("defend_target") == self:
			npc.set("defend_target", null)
		if npc.get("search_home_claim") == self:
			npc.set("search_home_claim", null)


func _unassign_clan_women(collected: Array) -> void:
	for npc in collected:
		if not is_instance_valid(npc):
			continue
		if str(npc.get("npc_type")) != "woman":
			continue
		if OccupationSystem:
			OccupationSystem.unassign(npc, "nomad_mode")


func _drop_clan_herded_animals(collected: Array) -> void:
	for npc in collected:
		if not is_instance_valid(npc):
			continue
		var npc_type: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
		if npc_type != "clansman" and npc_type != "caveman":
			continue
		var herded_count: int = int(npc.get("herded_count")) if npc.get("herded_count") != null else 0
		if herded_count <= 0:
			continue
		for animal in get_tree().get_nodes_in_group("npcs"):
			if not is_instance_valid(animal):
				continue
			if animal.get("herder") == npc and animal.get("is_herded") == true:
				var hc = animal.get_node_or_null("HerdableComponent")
				if hc and hc.has_method("detach"):
					hc.detach()
				else:
					animal.set("is_herded", false)
					animal.set("herder", null)
		npc.set("herded_count", 0)


func _freeze_clan_pregnancies(collected: Array) -> void:
	for npc in collected:
		if not is_instance_valid(npc):
			continue
		if str(npc.get("npc_type")) != "woman":
			continue
		var repro = npc.get("reproduction_component")
		if repro == null:
			repro = npc.get_node_or_null("ReproductionComponent")
		if repro and repro.get("is_pregnant"):
			npc.set_meta("nomad_pregnancy_frozen", true)
			npc.set_meta("nomad_pregnancy_timer", repro.birth_timer)


func _convert_clan_babies_to_icons(collected: Array) -> void:
	var women_names: Dictionary = {}
	for npc in collected:
		if not is_instance_valid(npc):
			continue
		if str(npc.get("npc_type")) != "woman":
			continue
		var wname: String = str(npc.get("npc_name")) if npc.get("npc_name") else ""
		if wname != "":
			women_names[wname] = npc

	for baby in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(baby):
			continue
		if str(baby.get("npc_type")) != "baby":
			continue
		if str(baby.get("clan_name")) != clan_name:
			continue
		var mother_name: String = str(baby.get("mother_name")) if baby.get("mother_name") else ""
		if mother_name == "" and baby.has_meta("mother_name"):
			mother_name = str(baby.get_meta("mother_name"))
		if not women_names.has(mother_name):
			continue
		var mother: Node = women_names[mother_name]
		var carried: Array = mother.get_meta("nomad_carried_babies", []) as Array
		carried.append({
			"name": str(baby.get("npc_name")) if baby.get("npc_name") else "Baby",
			"father_name": str(baby.get("father_name")) if baby.get("father_name") else "",
			"mother_name": mother_name,
		})
		mother.set_meta("nomad_carried_babies", carried)
		baby.queue_free()


static func resume_clan_after_nomad(clan: String, tree: SceneTree) -> void:
	if tree == null:
		return
	for npc in tree.get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else str(npc.get("clan_name") if npc.get("clan_name") else "")
		if npc_clan != clan:
			continue
		if npc.has_meta("nomad_pregnancy_frozen"):
			var repro = npc.get("reproduction_component")
			if repro == null:
				repro = npc.get_node_or_null("ReproductionComponent")
			if repro and npc.has_meta("nomad_pregnancy_timer"):
				repro.birth_timer = float(npc.get_meta("nomad_pregnancy_timer"))
				repro.is_pregnant = true
			npc.remove_meta("nomad_pregnancy_frozen")
			npc.remove_meta("nomad_pregnancy_timer")
		if npc.has_meta("nomad_carried_babies"):
			npc.remove_meta("nomad_carried_babies")


func _orphan_buildings_in_radius() -> void:
	for b in get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(b) or not (b is BuildingBase):
			continue
		var bb: BuildingBase = b as BuildingBase
		if bb.clan_name != clan_name:
			continue
		if global_position.distance_to(bb.global_position) > radius:
			continue
		bb.set_orphaned(true)


func _sync_nomad_player_meta() -> void:
	if not player_owned:
		return
	var leader := _get_player_leader()
	if leader and is_instance_valid(leader):
		leader.set_meta("nomad_state", nomad_state)
		leader.set_meta("nomad_clan_name", clan_name)


func _clear_nomad_player_meta() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(node):
			continue
		if node.has_meta("nomad_state"):
			node.remove_meta("nomad_state")
		if node.has_meta("nomad_clan_name"):
			node.remove_meta("nomad_clan_name")


func _pick_ai_nomad_target() -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var min_dist: float = BalanceConfig.ai_nomad_reloc_min_dist if BalanceConfig else 800.0
	var max_dist: float = BalanceConfig.ai_nomad_reloc_max_dist if BalanceConfig else 1500.0
	var min_center: float = BalanceConfig.get_land_claim_min_center_distance() if BalanceConfig else 1200.0
	for _attempt in range(5):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(min_dist, max_dist)
		var candidate: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * dist
		if _is_valid_nomad_site(candidate, min_center):
			return candidate
	return Vector2.ZERO


func _is_valid_nomad_site(candidate: Vector2, min_center: float) -> bool:
	for claim in get_tree().get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim) or claim == self:
			continue
		var other_radius: float = float(claim.get("radius")) if claim.get("radius") != null else 400.0
		if candidate.distance_to(claim.global_position) < min_center:
			return false
		if candidate.distance_to(claim.global_position) < other_radius + radius:
			return false
	return true


func _finish_ai_nomad_placement() -> void:
	nomad_state = NomadState.PLACING
	nomad_state_changed.emit(nomad_state)
	var new_cf: Campfire = CAMPFIRE_SCENE.instantiate() as Campfire
	if new_cf == null:
		_abort_nomad_mode("spawn_failed")
		return
	new_cf.global_position = nomad_target_pos
	new_cf.clan_name = clan_name
	new_cf.player_owned = false
	new_cf.owner_npc = owner_npc
	new_cf.inventory = InventoryData.new(
		BalanceConfig.campfire_inventory_slots if BalanceConfig else 20,
		true,
		BalanceConfig.campfire_inventory_max_stack if BalanceConfig else 999
	)
	new_cf.is_fire_on = true
	new_cf._fire_off_from_depletion = false
	var parent := get_parent()
	if parent:
		parent.add_child(new_cf)
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("register_land_claim"):
		main.register_land_claim(new_cf)
	for npc in _collect_all_clan_members():
		if not is_instance_valid(npc):
			continue
		if npc.get("defend_target") == self:
			npc.set("defend_target", new_cf)
		if npc.get("search_home_claim") == self:
			npc.set("search_home_claim", new_cf)
	Campfire.resume_clan_after_nomad(clan_name, get_tree())
	_complete_nomad_mode()


# LandClaim-compatible interface
func _prune_defenders() -> void:
	var valid: Array = []
	for n in assigned_defenders:
		if is_instance_valid(n) and not (n.has_method("is_dead") and n.is_dead()):
			valid.append(n)
	assigned_defenders = valid


func add_defender(npc: Node) -> void:
	if not npc or not is_instance_valid(npc):
		return
	_prune_defenders()
	if npc in assigned_defenders:
		return
	assigned_defenders.append(npc)


func should_i_defend(npc: Node) -> bool:
	if not npc or not is_instance_valid(npc):
		return false
	_prune_defenders()
	if npc not in assigned_defenders:
		return false
	var quota: int = get_meta("defender_quota", 10)
	var current_count: int = assigned_defenders.size()
	if current_count > quota:
		var npc_index: int = assigned_defenders.find(npc)
		if npc_index >= quota:
			return false
	return true


func start_player_emergency_defend() -> void:
	if clan_brain and clan_brain.has_method("start_player_emergency_defend"):
		clan_brain.start_player_emergency_defend()
	emergency_defend_triggered.emit()


func trigger_alert(level: int) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if level <= _last_alert_level and (now - _last_alert_time) < ALERT_THROTTLE_SEC:
		return
	_last_alert_level = level
	_last_alert_time = now
	if clan_brain:
		clan_brain.on_alert(level)
	if level >= 3:
		emergency_defend_triggered.emit()


func report_intruder() -> void:
	trigger_alert(1)


func report_skirmish() -> void:
	trigger_alert(2)


func report_raid() -> void:
	trigger_alert(3)


func get_threat_level() -> float:
	if clan_brain:
		return clan_brain.get_threat_level()
	return 0.0


func _initialize_clan_brain() -> void:
	if clan_brain != null:
		return
	var ClanBrainClass = load("res://scripts/ai/clan_brain.gd")
	if ClanBrainClass:
		clan_brain = ClanBrainClass.new(self)


func _update_player_defender_quota() -> void:
	if clan_brain and clan_brain.has_method("_refresh_clan_members"):
		clan_brain._refresh_clan_members()
	if clan_brain and clan_brain.has_method("_update_defender_assignments"):
		clan_brain._update_defender_assignments()


func remove_defender(npc: Node) -> void:
	_prune_defenders()
	assigned_defenders.erase(npc)


func _prune_searchers() -> void:
	var valid: Array = []
	for n in assigned_searchers:
		if is_instance_valid(n) and not (n.has_method("is_dead") and n.is_dead()):
			valid.append(n)
	assigned_searchers = valid


func add_searcher(npc: Node) -> void:
	if not npc or not is_instance_valid(npc):
		return
	_prune_searchers()
	if npc in assigned_searchers:
		return
	assigned_searchers.append(npc)


func remove_searcher(npc: Node) -> void:
	_prune_searchers()
	assigned_searchers.erase(npc)


func remove_npc_from_pools(npc: Node) -> void:
	remove_defender(npc)
	remove_searcher(npc)


func generate_gather_job(worker: Node) -> Job:
	return _TerritoryJobService.generate_gather_job(self, worker)


func generate_craft_job(worker: Node) -> Job:
	return _TerritoryJobService.generate_craft_job(self, worker)


func _release_nearby_herdables() -> void:
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var npc_type: String = npc.get("npc_type") if npc else ""
		if npc_type != "woman" and npc_type != "sheep" and npc_type != "goat":
			continue
		var dist: float = global_position.distance_to(npc.global_position)
		if dist > radius:
			continue
		if npc.get("herder") and npc.get("herder") != null:
			npc.set("herder", null)
		if npc.get("is_herded"):
			npc.set("is_herded", false)
		if npc.get("clan_name") == clan_name:
			npc.set("clan_name", "")
		if npc.get("defend_target") == self:
			npc.set("defend_target", null)
		if npc.get("search_home_claim") == self:
			npc.set("search_home_claim", null)
		remove_defender(npc)
		remove_searcher(npc)
