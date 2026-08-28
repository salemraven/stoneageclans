extends Node
class_name BabyPoolManager

## Per-clan baby slot capacity: base + living huts + fertility stub (baby_cap_bonus on women).
## enforce_baby_cap on ReproductionConfig gates new pregnancies only — not birth at timer end.

const META_FERTILITY_CAP_BONUS := &"baby_cap_bonus"

var config: ReproductionConfig = null

func _ready() -> void:
	config = _ensure_config()


func _ensure_config() -> ReproductionConfig:
	if config == null:
		config = ReproductionConfig.new()
	if BalanceConfig:
		config.pregnancy_cancel_food_buffer_days = maxf(
			config.pregnancy_cancel_food_buffer_days,
			float(BalanceConfig.reproduction_min_food_buffer_days)
		)
	return config


func refresh_clan_modifiers(clan_name: String) -> void:
	if clan_name.is_empty():
		return
	var breakdown := get_capacity_breakdown(clan_name)
	_log_cap_snapshot(clan_name, breakdown)


func get_effective_capacity(clan_name: String) -> int:
	var cfg := _ensure_config()
	var base_cap: int = cfg.baby_pool_base_capacity
	var hut_bonus: int = _get_living_hut_count(clan_name) * cfg.living_hut_capacity_bonus
	var fertility_bonus: int = _get_fertility_cap_bonus(clan_name)
	return maxi(0, base_cap + hut_bonus + fertility_bonus)


func get_capacity(clan_name: String) -> int:
	return get_effective_capacity(clan_name)


func get_current_count(clan_name: String) -> int:
	if clan_name.is_empty():
		return 0
	var count: int = 0
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		var npc_clan: String = ""
		if npc.has_method("get_clan_name"):
			npc_clan = str(npc.get_clan_name()).strip_edges()
		elif npc.get("clan_name") != null:
			npc_clan = str(npc.get("clan_name")).strip_edges()
		if npc_clan != clan_name:
			continue
		if str(npc.get("npc_type")) == "baby":
			count += 1
	return count


func has_baby_room(clan_name: String) -> bool:
	var cfg := _ensure_config()
	if not cfg.enforce_baby_cap:
		return true
	return get_current_count(clan_name) < get_effective_capacity(clan_name)


func can_add_baby(clan_name: String) -> bool:
	return has_baby_room(clan_name)


func get_capacity_breakdown(clan_name: String) -> Dictionary:
	var cfg := _ensure_config()
	var base_cap: int = cfg.baby_pool_base_capacity
	var hut_count: int = _get_living_hut_count(clan_name)
	var hut_bonus: int = hut_count * cfg.living_hut_capacity_bonus
	var fertility_bonus: int = _get_fertility_cap_bonus(clan_name)
	var total: int = maxi(0, base_cap + hut_bonus + fertility_bonus)
	var current: int = get_current_count(clan_name)
	return {
		"base": base_cap,
		"living_huts": hut_count,
		"living_hut_bonus": hut_bonus,
		"fertility_bonus": fertility_bonus,
		"total": total,
		"current": current,
		"enforce": cfg.enforce_baby_cap,
		"has_room": current < total or not cfg.enforce_baby_cap,
	}


func set_modifier(_clan_name: String, _source_id: String, _delta: int) -> void:
	push_warning("BabyPoolManager.set_modifier: use refresh_clan_modifiers; dynamic modifiers are derived from world state in v1")


func clear_modifier(_clan_name: String, _source_id: String) -> void:
	set_modifier(_clan_name, _source_id, 0)


func on_living_hut_built(clan_name: String) -> void:
	refresh_clan_modifiers(clan_name)


func on_living_hut_destroyed(clan_name: String) -> void:
	refresh_clan_modifiers(clan_name)


func _get_living_hut_count(clan_name: String) -> int:
	var count: int = 0
	for building in get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(building):
			continue
		if not ("building_type" in building and "clan_name" in building):
			continue
		if building.building_type != ResourceData.ResourceType.LIVING_HUT:
			continue
		if str(building.clan_name).strip_edges() == clan_name.strip_edges():
			count += 1
	return count


func _get_fertility_cap_bonus(clan_name: String) -> int:
	var bonus: int = 0
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if str(npc.get("npc_type")) != "woman":
			continue
		var npc_clan: String = ""
		if npc.has_method("get_clan_name"):
			npc_clan = str(npc.get_clan_name()).strip_edges()
		elif npc.get("clan_name") != null:
			npc_clan = str(npc.get("clan_name")).strip_edges()
		if npc_clan != clan_name.strip_edges():
			continue
		if npc.has_meta(META_FERTILITY_CAP_BONUS):
			bonus += int(npc.get_meta(META_FERTILITY_CAP_BONUS))
	return bonus


func _log_cap_snapshot(clan_name: String, breakdown: Dictionary) -> void:
	UnifiedLogger.log_system("BABY_CAP: clan capacity snapshot", {
		"clan": clan_name,
		"breakdown": breakdown,
	})
	var pi := get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("baby_cap_snapshot"):
		pi.baby_cap_snapshot(clan_name, breakdown)
