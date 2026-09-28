extends RefCounted
class_name CorpseHarvest

## Only place that applies death yields, slices meat→hide→bone, and despawns empty corpses.

const CANDIDATE_META := "corpse_job_candidate_ids"
const CorpseJobs = preload("res://scripts/systems/corpse_job_service.gd")
const FightOverScript = preload("res://scripts/systems/fight_over.gd")
const CorpseConfigScript = preload("res://scripts/config/corpse_config.gd")

static func _npc_type_of(n: Node) -> String:
	if n == null:
		return ""
	if n.get("npc_type") != null and str(n.get("npc_type")) != "":
		return str(n.get("npc_type"))
	if n.has_meta("npc_type"):
		return str(n.get_meta("npc_type"))
	return ""

static func _fallback_yields(npc_type: String) -> Dictionary:
	var key: String = npc_type.to_lower()
	var table: Dictionary = {
		"sheep": {"meat": 2, "hide": 1, "bone": 0},
		"goat": {"meat": 2, "hide": 1, "bone": 0},
		"deer": {"meat": 5, "hide": 4, "bone": 3},
		"woman": {"meat": 2, "hide": 1, "bone": 2},
		"caveman": {"meat": 3, "hide": 1, "bone": 2},
		"clansman": {"meat": 3, "hide": 1, "bone": 2},
		"baby": {"meat": 0, "hide": 0, "bone": 0},
	}
	return table.get(key, {"meat": 0, "hide": 0, "bone": 0})


static func apply_death_yields(npc: Node) -> Dictionary:
	var empty: Dictionary = {"meat": 0, "hide": 0, "bone": 0}
	if not npc or not is_instance_valid(npc):
		return empty
	var npc_type_str: String = _npc_type_of(npc)
	var yields: Dictionary = CorpseConfigScript.get_yields(npc_type_str)
	if yields.is_empty() or (int(yields.get("meat", 0)) + int(yields.get("hide", 0)) + int(yields.get("bone", 0)) == 0 and npc_type_str != "baby"):
		yields = _fallback_yields(npc_type_str)
	npc.set_meta("meat_remaining", int(yields.get("meat", 0)))
	npc.set_meta("hide_remaining", int(yields.get("hide", 0)))
	npc.set_meta("bone_remaining", int(yields.get("bone", 0)))
	npc.set_meta("corpse_created_at", Time.get_ticks_msec() / 1000.0)
	npc.set_meta("last_butcher_time", npc.get_meta("corpse_created_at"))
	return yields


static func yield_total(corpse: Node) -> int:
	if not corpse or not is_instance_valid(corpse):
		return 0
	return int(corpse.get_meta("meat_remaining", 0)) + int(corpse.get_meta("hide_remaining", 0)) + int(corpse.get_meta("bone_remaining", 0))


static func next_slice_type(corpse: Node) -> int:
	if not corpse or not is_instance_valid(corpse):
		return ResourceData.ResourceType.NONE
	if int(corpse.get_meta("meat_remaining", 0)) > 0:
		return ResourceData.ResourceType.MEAT
	if int(corpse.get_meta("hide_remaining", 0)) > 0:
		return ResourceData.ResourceType.HIDE
	if int(corpse.get_meta("bone_remaining", 0)) > 0:
		return ResourceData.ResourceType.BONE
	return ResourceData.ResourceType.NONE


static func _undo_slice(corpse: Node, took: int) -> void:
	if took == ResourceData.ResourceType.MEAT:
		corpse.set_meta("meat_remaining", int(corpse.get_meta("meat_remaining", 0)) + 1)
	elif took == ResourceData.ResourceType.HIDE:
		corpse.set_meta("hide_remaining", int(corpse.get_meta("hide_remaining", 0)) + 1)
	elif took == ResourceData.ResourceType.BONE:
		corpse.set_meta("bone_remaining", int(corpse.get_meta("bone_remaining", 0)) + 1)


static func take_slice(corpse: Node, add_item: Callable, actor_name: String = "") -> Dictionary:
	var result: Dictionary = {"ok": false, "type": ResourceData.ResourceType.NONE, "empty": true}
	if not corpse or not is_instance_valid(corpse):
		return result
	var took: int = next_slice_type(corpse)
	if took == ResourceData.ResourceType.NONE:
		despawn_if_empty(corpse, actor_name)
		return result
	if took == ResourceData.ResourceType.MEAT:
		corpse.set_meta("meat_remaining", int(corpse.get_meta("meat_remaining", 0)) - 1)
	elif took == ResourceData.ResourceType.HIDE:
		corpse.set_meta("hide_remaining", int(corpse.get_meta("hide_remaining", 0)) - 1)
	else:
		corpse.set_meta("bone_remaining", int(corpse.get_meta("bone_remaining", 0)) - 1)
	corpse.set_meta("last_butcher_time", Time.get_ticks_msec() / 1000.0)
	if add_item.is_valid():
		var added: Variant = add_item.call(took)
		if added != true:
			_undo_slice(corpse, took)
			return {"ok": false, "type": took, "empty": false, "undone": true}
	result = {"ok": true, "type": took, "empty": yield_total(corpse) <= 0}
	_log_slice(corpse, actor_name, took)
	if bool(result["empty"]):
		despawn_if_empty(corpse, actor_name)
	return result


static func _log_slice(corpse: Node, actor_name: String, took: int) -> void:
	if not corpse or not corpse.is_inside_tree():
		return
	var pi: Node = corpse.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("butcher_slice"):
		var ctype: String = str(corpse.get("npc_type")) if corpse.get("npc_type") != null else "unknown"
		pi.butcher_slice(actor_name, ctype, ResourceData.get_resource_name(took), yield_total(corpse))


static func despawn_if_empty(corpse: Node, who: String = "") -> bool:
	if not corpse or not is_instance_valid(corpse):
		return false
	if yield_total(corpse) > 0:
		return false
	_clear_claim_refs(corpse)
	_clear_player_nearby(corpse)
	var ctype: String = str(corpse.get("npc_type")) if corpse.get("npc_type") != null else "unknown"
	if corpse.is_inside_tree():
		var pi: Node = corpse.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("corpse_despawned"):
			pi.corpse_despawned(ctype, who)
		corpse.queue_free()
	return true


static func despawn_idle(corpse: Node) -> void:
	if not corpse or not is_instance_valid(corpse):
		return
	_clear_claim_refs(corpse)
	_clear_player_nearby(corpse)
	var ctype: String = str(corpse.get("npc_type")) if corpse.get("npc_type") != null else "unknown"
	if corpse.is_inside_tree():
		var pi: Node = corpse.get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("corpse_despawned"):
			pi.corpse_despawned(ctype, "idle_timer")
		corpse.queue_free()


static func _clear_claim_refs(corpse: Node) -> void:
	if not corpse or not corpse.is_inside_tree():
		return
	var cid: int = corpse.get_instance_id()
	for claim in corpse.get_tree().get_nodes_in_group("land_claims"):
		if not is_instance_valid(claim):
			continue
		if int(claim.get_meta(CorpseJobs.META_CORPSE_ID, -1)) == cid:
			CorpseJobs.clear_site(claim)
		remove_candidate(claim, corpse)


static func _clear_player_nearby(corpse: Node) -> void:
	if not corpse or not corpse.is_inside_tree():
		return
	var main: Node = corpse.get_tree().root.get_node_or_null("Main")
	if main == null:
		return
	if main.get("nearby_corpse") == corpse:
		main.set("nearby_corpse", null)
	if main.get("butchering_corpse") == corpse:
		if main.has_method("_clear_butcher"):
			main._clear_butcher()
	var ui: Node = main.get("building_inventory_ui")
	if ui and ui.has_method("is_visible") and ui.visible:
		var bound: Variant = ui.get("current_building") if "current_building" in ui else null
		if bound == corpse and ui.has_method("hide"):
			ui.hide()


static func add_candidate(claim: Node, corpse: Node) -> void:
	if not claim or not corpse or not is_instance_valid(claim) or not is_instance_valid(corpse):
		return
	if yield_total(corpse) <= 0:
		return
	var ids: Array = claim.get_meta(CANDIDATE_META, []) as Array
	var cid: int = corpse.get_instance_id()
	if not ids.has(cid):
		ids.append(cid)
	claim.set_meta(CANDIDATE_META, ids)


static func remove_candidate(claim: Node, corpse: Node) -> void:
	if not claim:
		return
	var ids: Array = claim.get_meta(CANDIDATE_META, []) as Array
	var cid: int = corpse.get_instance_id() if corpse and is_instance_valid(corpse) else -1
	ids.erase(cid)
	claim.set_meta(CANDIDATE_META, ids)


static func clan_needs_meat(claim: Node) -> bool:
	if not claim:
		return false
	var meat: int = 0
	var inv: Variant = claim.get("inventory")
	if inv == null and claim.has_meta("inventory"):
		inv = claim.get_meta("inventory")
	if inv and inv.has_method("get_count"):
		meat = int(inv.get_count(ResourceData.ResourceType.MEAT))
	var thresh: int = 2
	if NPCConfig:
		thresh = int(NPCConfig.hunt_meat_threshold)
	if meat < thresh:
		return true
	var buf: float = float(claim.get_meta("food_days_buffer", 999.0))
	var crit: float = 0.5
	if BalanceConfig:
		crit = float(BalanceConfig.clan_food_buffer_critical_days)
	return buf < crit


static func is_own_clan_human(corpse: Node, clan_name: String) -> bool:
	if clan_name == "" or not corpse:
		return false
	var nt: String = _npc_type_of(corpse)
	if nt != "caveman" and nt != "clansman" and nt != "woman":
		return false
	var cc: String = str(corpse.get("clan_name")) if corpse.get("clan_name") != null else ""
	if cc == "" and corpse.has_method("get_clan_name"):
		cc = str(corpse.get_clan_name())
	if cc == "" and corpse.has_meta("clan_name"):
		cc = str(corpse.get_meta("clan_name"))
	return cc != "" and cc == clan_name


static func corpse_allowed_for_claim(corpse: Node, claim: Node) -> bool:
	if yield_total(corpse) <= 0:
		return false
	var clan: String = str(claim.get("clan_name")) if claim and claim.get("clan_name") != null else ""
	if clan == "" and claim and claim.has_meta("clan_name"):
		clan = str(claim.get_meta("clan_name"))
	if is_own_clan_human(corpse, clan):
		return clan_needs_meat(claim)
	return true


static func claim_has_living_threat(claim: Node) -> bool:
	if not claim or not claim.is_inside_tree():
		return false
	var clan: String = str(claim.get("clan_name")) if claim.get("clan_name") != null else ""
	if clan == "" and claim.has_meta("clan_name"):
		clan = str(claim.get_meta("clan_name"))
	for npc in claim.get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		if bool(npc.get_meta("is_dead", false)) or FightOverScript.is_corpse_node(npc):
			continue
		var nc: String = str(npc.get("clan_name")) if npc.get("clan_name") != null else ""
		if npc.has_method("get_clan_name"):
			nc = str(npc.get_clan_name())
		if nc == "" and npc.has_meta("clan_name"):
			nc = str(npc.get_meta("clan_name"))
		if clan == "" or nc != clan:
			continue
		var ct: Variant = npc.get("combat_target")
		if (ct == null or not is_instance_valid(ct)) and npc.has_meta("combat_target"):
			ct = npc.get_meta("combat_target")
		if FightOverScript.is_living_attack_target(ct):
			return true
		var fsm: Node = npc.get_node_or_null("FSM")
		if fsm and fsm.has_method("get_current_state_name"):
			var st: String = str(fsm.get_current_state_name())
			if st == "combat" or st == "agro" or st == "flee_combat":
				return true
		var pa: Node = npc.get_node_or_null("DetectionArea")
		if pa and pa.has_method("has_enemies") and pa.has_enemies(npc):
			return true
	return false


static func pick_closest_allowed(claim: Node, from_pos: Vector2) -> Node:
	if not claim:
		return null
	var best: Node = null
	var best_d: float = INF
	var ids: Array = claim.get_meta(CANDIDATE_META, []) as Array
	var kept: Array = []
	for raw in ids:
		var n: Node = instance_from_id(int(raw))
		if not n or not is_instance_valid(n) or yield_total(n) <= 0:
			continue
		kept.append(int(raw))
		if not corpse_allowed_for_claim(n, claim):
			continue
		var d: float = from_pos.distance_to((n as Node2D).global_position) if n is Node2D else INF
		if d < best_d:
			best_d = d
			best = n
	claim.set_meta(CANDIDATE_META, kept)
	return best


static func try_refresh_safe_site(claim: Node, source: String = "agro") -> bool:
	if not claim:
		return false
	if claim_has_living_threat(claim):
		_log_deferred(claim, "threat")
		return false
	var origin: Vector2 = Vector2.ZERO
	if claim is Node2D:
		origin = (claim as Node2D).global_position
	var closest: Node = pick_closest_allowed(claim, origin)
	if closest == null:
		var site: Node = CorpseJobs.get_site_corpse(claim)
		if site and not corpse_allowed_for_claim(site, claim):
			CorpseJobs.clear_site(claim)
			_log_skipped_own(claim)
		return CorpseJobs.is_site_active(claim)
	var px: float = origin.distance_to((closest as Node2D).global_position) if closest is Node2D else 0.0
	CorpseJobs.register_site(claim, closest)
	_log_opened(claim, closest, source, px)
	return true


static func register_kill_candidate(killer: Node, corpse: Node, source: String) -> void:
	if not corpse or not is_instance_valid(corpse) or yield_total(corpse) <= 0:
		return
	if not killer or not is_instance_valid(killer):
		return
	if bool(killer.get_meta("is_dead", false)):
		return
	var claim: Node = null
	if killer.has_method("get_my_land_claim"):
		claim = killer.get_my_land_claim()
	if claim == null and killer.is_in_group("player") and killer.is_inside_tree():
		var clan: String = ""
		if killer.has_method("get_clan_name"):
			clan = str(killer.get_clan_name())
		for c in killer.get_tree().get_nodes_in_group("land_claims"):
			if str(c.get("clan_name")) == clan:
				claim = c
				break
	if claim == null:
		_log_deferred_no_claim(killer)
		return
	add_candidate(claim, corpse)
	if is_own_clan_human(corpse, str(claim.get("clan_name"))) and not clan_needs_meat(claim):
		_log_skipped_own(claim)
		return
	try_refresh_safe_site(claim, source)


static func _log_opened(claim: Node, corpse: Node, source: String, closest_px: float) -> void:
	if not claim.is_inside_tree():
		return
	var pi: Node = claim.get_tree().root.get_node_or_null("PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("corpse_job_opened"):
		var clan: String = str(claim.get("clan_name"))
		var ctype: String = str(corpse.get("npc_type")) if corpse.get("npc_type") != null else "unknown"
		pi.corpse_job_opened(clan, ctype, source, yield_total(corpse), closest_px)


static func _log_deferred(claim: Node, reason: String) -> void:
	if not claim.is_inside_tree():
		return
	var pi: Node = claim.get_tree().root.get_node_or_null("PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("butcher_deferred"):
		pi.butcher_deferred(str(claim.get("clan_name")), reason)


static func _log_deferred_no_claim(killer: Node) -> void:
	if not killer or not killer.is_inside_tree():
		return
	var pi: Node = killer.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("butcher_deferred"):
		var clan: String = str(killer.get("clan_name")) if killer.get("clan_name") != null else ""
		pi.butcher_deferred(clan, "no_claim")


static func _log_skipped_own(claim: Node) -> void:
	if not claim.is_inside_tree():
		return
	var pi: Node = claim.get_tree().root.get_node_or_null("PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("butcher_skipped_own_clan"):
		pi.butcher_skipped_own_clan(str(claim.get("clan_name")))
