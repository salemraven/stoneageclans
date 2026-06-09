extends Node2D
class_name Campfire

const _TerritoryJobService = preload("res://scripts/systems/territory_job_service.gd")

signal campfire_despawned(campfire_node: Node2D)
signal emergency_defend_triggered

# Small base (radius 250), clan name on placement, inventory, fire on/off
# LandClaim-compatible interface for NPCs (defend_target, search_home_claim)

@export var clan_name: String = "CLAN"
@export var radius: float = 250.0
@export var player_owned: bool = false
## 0 = auto (ClanBrain baseline n/4 + drag); >0 = min slots ceil(n * ratio). Persisted with territory.
@export var player_defend_ratio: float = 0.0
var defend_ratio: float = 0.0
var search_ratio: float = 0.2
## Nomadic: max living huts before overcrowding (design: 6)
const MAX_LIVING_HUTS_NOMADIC: int = 6

var sprite: Sprite2D = null
var radius_indicator: Node2D = null
var _collision_area: Area2D = null
var inventory: InventoryData = null

var is_fire_on: bool = false
const WOOD_CONSUME_INTERVAL: float = 30.0  # 1 wood per 30 sec
var _wood_consume_timer: float = 0.0

# Abandonment: when extinguished + player far for X sec, despawn
const ABANDON_RADIUS: float = 600.0
const ABANDON_SEC: float = 120.0
var _abandonment_timer: float = 0.0

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
	
	# Manual z_index by sprite foot (draw_order.md)
	if sprite:
		sprite.z_as_relative = false
		YSortUtils.update_building_draw_order(sprite, self)
	
	add_to_group("buildings")
	add_to_group("campfires")
	add_to_group("land_claims")
	set_meta("searcher_quota", 0)
	set_meta("defender_quota", 0)
	_initialize_clan_brain()
	set_process(true)

func _setup_sprite() -> void:
	if sprite:
		var tex = AssetRegistry.get_campfire_sprite()
		if tex:
			sprite.texture = tex
		sprite.modulate = Color(0.6, 0.6, 0.6)  # Dim when off

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
	# Abandonment: when extinguished, timer runs if player far
	if not is_fire_on:
		var player = get_tree().get_first_node_in_group("player")
		var dist: float = 9999.0
		if player and is_instance_valid(player):
			dist = global_position.distance_to(player.global_position)
		if dist > ABANDON_RADIUS:
			_abandonment_timer += delta
			if _abandonment_timer >= ABANDON_SEC:
				_release_nearby_herdables()
				var pi = get_node_or_null("/root/PlaytestInstrumentor")
				if pi and pi.has_method("campfire_despawned"):
					pi.campfire_despawned(clan_name, "abandoned")
				campfire_despawned.emit(self)
				queue_free()
				return
		else:
			_abandonment_timer = 0.0
		return
	_abandonment_timer = 0.0
	if not inventory:
		return
	_wood_consume_timer += delta
	if _wood_consume_timer >= WOOD_CONSUME_INTERVAL:
		_wood_consume_timer = 0.0
		if inventory.get_count(ResourceData.ResourceType.WOOD) > 0:
			inventory.remove_item(ResourceData.ResourceType.WOOD, 1)
		else:
			is_fire_on = false
			_update_fire_visual()
	# Despawn when stone = 0 or inventory empty
	var stone_count := inventory.get_count(ResourceData.ResourceType.STONE)
	var total_items := 0
	for i in inventory.slot_count:
		var slot = inventory.get_slot(i)
		if not slot.is_empty():
			total_items += slot.get("count", 1) as int
	if stone_count <= 0 or total_items <= 0:
		_release_nearby_herdables()
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("campfire_despawned"):
			pi.campfire_despawned(clan_name, "empty")
		campfire_despawned.emit(self)
		queue_free()

func _update_nomadic_crowding() -> void:
	var huts: int = 0
	var cn: String = clan_name
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
	if huts >= 6:
		pen = 0.35
	elif huts >= 4:
		pen = 0.15
	set_meta("nomadic_crowding_penalty", pen)
	set_meta("nomadic_living_hut_count", huts)


func set_fire_on(on: bool) -> void:
	is_fire_on = on
	_update_fire_visual()

func _update_fire_visual() -> void:
	if sprite:
		sprite.modulate = Color.WHITE if is_fire_on else Color(0.6, 0.6, 0.6)

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

# Same gather/craft job API as LandClaim (Tier 2 flag) — earlygame.md: shared territory behavior.
func generate_gather_job(worker: Node) -> Job:
	return _TerritoryJobService.generate_gather_job(self, worker)

func generate_craft_job(worker: Node) -> Job:
	return _TerritoryJobService.generate_craft_job(self, worker)

func _release_nearby_herdables() -> void:
	# When campfire despawns: nearby herdable NPCs lose anchor, become neutral/wild
	# Do NOT auto-assign herder - player must herd again manually
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var npc_type: String = npc.get("npc_type") if npc else ""
		if npc_type != "woman" and npc_type != "sheep" and npc_type != "goat":
			continue
		var dist: float = global_position.distance_to(npc.global_position)
		if dist > radius:
			continue
		# Clear clan/home association - they lose anchor
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
