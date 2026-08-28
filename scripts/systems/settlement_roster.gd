class_name SettlementRoster
extends RefCounted
## Off-screen clan population — source of truth while claim is dormant (warm tier).

const DEATH_TIER: Dictionary = {
	"baby": 0,
	"woman": 1,
	"clansman": 2,
	"caveman": 2,
	"leader": 3,
	"player": 99,
}

var clan_name: String = ""
var members: Array = []


static func normalize_member_type(npc_type: String, is_leader: bool = false) -> String:
	if is_leader:
		return "leader"
	match npc_type:
		"baby":
			return "baby"
		"woman":
			return "woman"
		"clansman":
			return "clansman"
		"caveman":
			return "caveman"
		"player":
			return "player"
		_:
			return "clansman"


static func death_tier_for(member_type: String) -> int:
	return int(DEATH_TIER.get(member_type, 2))


func clear() -> void:
	members.clear()


func get_population() -> int:
	var count := 0
	for m in members:
		if bool(m.get("alive", false)):
			count += 1
	return count


func find_member(member_id: int) -> Dictionary:
	for m in members:
		if int(m.get("id", -1)) == member_id:
			return m
	return {}


func snapshot_from_live_npcs(
	npcs: Array,
	clan: String,
	leader_npc: Node = null,
	sleep_records: Array = []
) -> void:
	clan_name = clan
	members.clear()
	var seen_ids: Dictionary = {}
	for npc in npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		var entry := _member_from_live_npc(npc, leader_npc)
		if entry.is_empty():
			continue
		var nid: int = int(entry.get("id", -1))
		if nid > 0:
			seen_ids[nid] = true
		members.append(entry)
	for data in sleep_records:
		if not (data is Dictionary):
			continue
		var rec: Dictionary = data as Dictionary
		if str(rec.get("clan_name", "")).to_upper() != clan.to_upper():
			continue
		var nid: int = int(rec.get("network_id", -1))
		if nid > 0 and seen_ids.has(nid):
			continue
		var sleep_entry := _member_from_sleep_record(rec, leader_npc)
		if sleep_entry.is_empty():
			continue
		if nid > 0:
			seen_ids[nid] = true
		members.append(sleep_entry)


func _member_from_live_npc(npc: Node, leader_npc: Node) -> Dictionary:
	if npc == null or not is_instance_valid(npc):
		return {}
	var nid: int = EntityRegistry.get_network_id(npc) if EntityRegistry else -1
	if nid < 1:
		nid = npc.get_instance_id()
	var is_leader: bool = leader_npc != null and npc == leader_npc
	var npc_type: String = str(npc.get("npc_type") if npc.get("npc_type") != null else "clansman")
	var member_type := normalize_member_type(npc_type, is_leader)
	var hunger_pct: float = 100.0
	if npc.has_method("get") and npc.get("stats_component"):
		var stats = npc.get("stats_component")
		if stats and stats.has_method("get_hunger_percent"):
			hunger_pct = float(stats.get_hunger_percent())
	var pregnancy_timer: float = -1.0
	var repro = npc.get_node_or_null("ReproductionComponent")
	if repro and repro.get("is_pregnant") and repro.get("birth_timer") != null:
		pregnancy_timer = float(repro.birth_timer)
	var pos: Vector2 = npc.global_position if npc is Node2D else Vector2.ZERO
	var traits_val = npc.get("traits")
	var traits: Array = []
	if traits_val is Array:
		traits = (traits_val as Array).duplicate()
	return {
		"id": nid,
		"name": str(npc.get("npc_name") if npc.get("npc_name") != null else "NPC"),
		"type": member_type,
		"age": float(npc.get("age") if npc.get("age") != null else 13),
		"alive": true,
		"hunger": clampf(hunger_pct, 0.0, 100.0),
		"pregnancy_timer": pregnancy_timer,
		"is_leader": is_leader,
		"is_player": member_type == "player" or npc.is_in_group("player"),
		"quality_tier": str(npc.get("quality_tier") if npc.get("quality_tier") != null else "Flawed"),
		"skin_tone": str(npc.get("skin_tone") if npc.get("skin_tone") != null else "Medium"),
		"card_index": int(npc.get("card_index") if npc.get("card_index") != null else 0),
		"traits": traits,
		"position": pos,
		"npc_type": npc_type,
	}


func _member_from_sleep_record(data: Dictionary, leader_npc: Node) -> Dictionary:
	var nid: int = int(data.get("network_id", -1))
	if nid < 1:
		return {}
	var npc_type: String = str(data.get("npc_type", "clansman"))
	var is_leader: bool = false
	if leader_npc and is_instance_valid(leader_npc):
		var leader_id: int = EntityRegistry.get_network_id(leader_npc) if EntityRegistry else -1
		is_leader = leader_id > 0 and leader_id == nid
	var member_type := normalize_member_type(npc_type, is_leader)
	var hunger_pct: float = float(data.get("hunger_percent", 1.0))
	if hunger_pct <= 1.0:
		hunger_pct *= 100.0
	var traits_val = data.get("traits", [])
	var traits: Array = []
	if traits_val is Array:
		traits = (traits_val as Array).duplicate()
	return {
		"id": nid,
		"name": str(data.get("npc_name", "NPC")),
		"type": member_type,
		"age": float(data.get("age", 13)),
		"alive": true,
		"hunger": clampf(hunger_pct, 0.0, 100.0),
		"pregnancy_timer": -1.0,
		"is_leader": is_leader,
		"is_player": member_type == "player",
		"quality_tier": str(data.get("quality_tier", "Flawed")),
		"skin_tone": str(data.get("skin_tone", "Medium")),
		"card_index": int(data.get("card_index", 0)),
		"traits": traits,
		"position": data.get("position", Vector2.ZERO),
		"npc_type": npc_type,
	}


func get_leader() -> Dictionary:
	for m in members:
		if not bool(m.get("alive", false)):
			continue
		if bool(m.get("is_leader", false)) or m.get("type") == "leader":
			return m
	return {}


func get_hungriest(exclude_ids: Dictionary = {}) -> Dictionary:
	var best: Dictionary = {}
	var best_hunger: float = 999.0
	for m in members:
		if not bool(m.get("alive", false)):
			continue
		var mid: int = int(m.get("id", -1))
		if exclude_ids.has(mid):
			continue
		var h: float = float(m.get("hunger", 100.0))
		if h < best_hunger:
			best_hunger = h
			best = m
	return best


func get_next_to_die() -> Dictionary:
	var candidates: Array = []
	for m in members:
		if not bool(m.get("alive", false)):
			continue
		if bool(m.get("is_player", false)):
			continue
		if float(m.get("hunger", 100.0)) > 0.0:
			continue
		candidates.append(m)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ta: int = death_tier_for(str(a.get("type", "clansman")))
		var tb: int = death_tier_for(str(b.get("type", "clansman")))
		if ta != tb:
			return ta < tb
		return float(a.get("hunger", 0.0)) < float(b.get("hunger", 0.0))
	)
	return candidates[0]


func feed_member(member_id: int, calories_gained: float, member_type: String) -> float:
	var m: Dictionary = find_member(member_id)
	if m.is_empty() or not bool(m.get("alive", false)):
		return 0.0
	var daily: float = float(BalanceConfig.get_base_daily_calories(_balance_type_for(member_type)))
	if daily <= 0.0:
		daily = 2000.0
	var hunger_gain: float = (calories_gained / daily) * 100.0
	m["hunger"] = clampf(float(m.get("hunger", 0.0)) + hunger_gain, 0.0, 100.0)
	return hunger_gain


func drain_hunger(member: Dictionary, elapsed_sec: float) -> void:
	if member.is_empty() or not bool(member.get("alive", false)):
		return
	var member_type: String = str(member.get("type", "clansman"))
	var daily: float = float(BalanceConfig.get_base_daily_calories(_balance_type_for(member_type)))
	if daily <= 0.0:
		daily = 2000.0
	var sim_day_sec: float = 600.0
	if BalanceConfig:
		sim_day_sec = maxf(BalanceConfig.sim_day_length_minutes * 60.0, 60.0)
	var calories_drain: float = daily * (elapsed_sec / sim_day_sec)
	var hunger_drain: float = (calories_drain / daily) * 100.0
	member["hunger"] = clampf(float(member.get("hunger", 100.0)) - hunger_drain, 0.0, 100.0)


func kill_member(member_id: int) -> Dictionary:
	var m: Dictionary = find_member(member_id)
	if m.is_empty() or not bool(m.get("alive", false)):
		return {}
	if bool(m.get("is_player", false)):
		return {}
	m["alive"] = false
	return m.duplicate()


func to_spawn_data(member: Dictionary, fallback_pos: Vector2) -> Dictionary:
	var pos: Vector2 = member.get("position", fallback_pos) as Vector2
	return {
		"network_id": int(member.get("id", -1)),
		"npc_name": str(member.get("name", "NPC")),
		"npc_type": str(member.get("npc_type", member.get("type", "clansman"))),
		"age": int(member.get("age", 13)),
		"quality_tier": str(member.get("quality_tier", "Flawed")),
		"skin_tone": str(member.get("skin_tone", "Medium")),
		"card_index": int(member.get("card_index", 0)),
		"traits": (member.get("traits", []) as Array).duplicate(),
		"clan_name": clan_name,
		"position": pos,
		"hunger_percent": float(member.get("hunger", 100.0)) / 100.0,
	}


func _balance_type_for(member_type: String) -> String:
	match member_type:
		"leader":
			return "caveman"
		"player":
			return "player"
		_:
			return member_type
