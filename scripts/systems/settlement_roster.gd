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
var _next_offscreen_id: int = -1


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
	var growth_timer: float = -1.0
	var designated_father_id: int = -1
	var last_birth_time: float = -1.0
	var father_absent_ticks: int = 0
	var repro = npc.get_node_or_null("ReproductionComponent")
	if repro and repro.get("is_pregnant") and repro.get("birth_timer") != null:
		pregnancy_timer = float(repro.birth_timer)
	if repro and repro.get("last_birth_time") != null:
		last_birth_time = float(repro.last_birth_time)
	if repro and repro.get("designated_father") != null:
		var df: Node = repro.designated_father as Node
		if df and is_instance_valid(df) and EntityRegistry:
			var dfid: int = EntityRegistry.get_network_id(df)
			if dfid > 0:
				designated_father_id = dfid
	var growth = npc.get_node_or_null("BabyGrowthComponent")
	if growth and growth.get("growth_timer") != null:
		growth_timer = float(growth.growth_timer)
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
		"growth_timer": growth_timer,
		"designated_father_id": designated_father_id,
		"last_birth_time": last_birth_time,
		"father_absent_ticks": father_absent_ticks,
		"is_leader": is_leader,
		"is_player": member_type == "player" or npc.is_in_group("player"),
		"quality_tier": str(npc.get("quality_tier") if npc.get("quality_tier") != null else "Flawed"),
		"skin_tone": str(npc.get("skin_tone") if npc.get("skin_tone") != null else "Medium"),
		"card_index": int(npc.get("card_index") if npc.get("card_index") != null else 0),
		"hair_id": int(npc.get("hair_id") if npc.get("hair_id") != null else 0),
		"hair_tone": str(npc.get("hair_tone") if npc.get("hair_tone") != null else ""),
		"genetics_profile": (npc.get("genetics_profile") as Dictionary).duplicate(true) if npc.get("genetics_profile") is Dictionary else {},
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
		"pregnancy_timer": float(data.get("pregnancy_timer", -1.0)),
		"growth_timer": float(data.get("growth_timer", -1.0)),
		"designated_father_id": int(data.get("designated_father_id", -1)),
		"last_birth_time": float(data.get("last_birth_time", -1.0)),
		"father_absent_ticks": int(data.get("father_absent_ticks", 0)),
		"is_leader": is_leader,
		"is_player": member_type == "player",
		"quality_tier": str(data.get("quality_tier", "Flawed")),
		"skin_tone": str(data.get("skin_tone", "Medium")),
		"card_index": int(data.get("card_index", 0)),
		"hair_id": int(data.get("hair_id", 0)),
		"hair_tone": str(data.get("hair_tone", "")),
		"genetics_profile": (data.get("genetics_profile") as Dictionary).duplicate(true) if data.get("genetics_profile") is Dictionary else {},
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
		"hair_id": int(member.get("hair_id", 0)),
		"hair_tone": str(member.get("hair_tone", "")),
		"genetics_profile": (member.get("genetics_profile") as Dictionary).duplicate(true) if member.get("genetics_profile") is Dictionary else {},
		"traits": (member.get("traits", []) as Array).duplicate(),
		"clan_name": clan_name,
		"position": pos,
		"hunger_percent": float(member.get("hunger", 100.0)) / 100.0,
		"pregnancy_timer": float(member.get("pregnancy_timer", -1.0)),
		"growth_timer": float(member.get("growth_timer", -1.0)),
		"designated_father_id": int(member.get("designated_father_id", -1)),
		"last_birth_time": float(member.get("last_birth_time", -1.0)),
		"father_absent_ticks": int(member.get("father_absent_ticks", 0)),
		"mother_name": str(member.get("mother_name", "")),
		"father_name": str(member.get("father_name", "")),
	}


func get_pregnant_women() -> Array:
	var out: Array = []
	for m in members:
		if not bool(m.get("alive", false)):
			continue
		if str(m.get("type", "")) != "woman":
			continue
		if float(m.get("pregnancy_timer", -1.0)) > 0.0:
			out.append(m)
	return out


func get_fertile_women(now_sec: float, birth_cooldown: float) -> Array:
	var out: Array = []
	for m in members:
		if not bool(m.get("alive", false)):
			continue
		if str(m.get("type", "")) != "woman":
			continue
		if float(m.get("pregnancy_timer", -1.0)) > 0.0:
			continue
		var last: float = float(m.get("last_birth_time", -1.0))
		if last >= 0.0 and (now_sec - last) < birth_cooldown:
			continue
		out.append(m)
	return out


func get_babies() -> Array:
	var out: Array = []
	for m in members:
		if not bool(m.get("alive", false)):
			continue
		if str(m.get("type", "")) == "baby":
			out.append(m)
	return out


func get_alive_males() -> Array:
	var out: Array = []
	for m in members:
		if not bool(m.get("alive", false)):
			continue
		var t: String = str(m.get("type", ""))
		if t in ["caveman", "clansman", "leader"]:
			out.append(m)
	return out


func get_member_name(member_id: int) -> String:
	var m: Dictionary = find_member(member_id)
	if m.is_empty():
		return "?"
	return str(m.get("name", "?"))


func generate_baby_name(seed_salt: int) -> String:
	var ws: int = int(WorldGenConfig.world_seed) if WorldGenConfig else 0
	var salt: int = hash("%s|%d|%d" % [clan_name, seed_salt, ws])
	return NamingUtils.generate_caveman_name_seeded(salt)


func add_baby_member(mother_id: int, father_id: int, baby_name: String, fallback_pos: Vector2) -> Dictionary:
	_next_offscreen_id -= 1
	var baby_id: int = _next_offscreen_id
	var mother: Dictionary = find_member(mother_id)
	var father: Dictionary = find_member(father_id) if father_id > 0 else {}
	var entry: Dictionary = {
		"id": baby_id,
		"name": baby_name,
		"type": "baby",
		"npc_type": "baby",
		"age": 0,
		"alive": true,
		"hunger": 100.0,
		"pregnancy_timer": -1.0,
		"growth_timer": 0.0,
		"designated_father_id": father_id,
		"last_birth_time": -1.0,
		"father_absent_ticks": 0,
		"is_leader": false,
		"is_player": false,
		"quality_tier": "Flawed",
		"skin_tone": "Medium",
		"card_index": int(father.get("card_index", 0)) if not father.is_empty() else 0,
		"hair_id": int(father.get("hair_id", 0)) if not father.is_empty() else 0,
		"hair_tone": "",
		"genetics_profile": {},
		"traits": [],
		"position": mother.get("position", fallback_pos) if not mother.is_empty() else fallback_pos,
		"mother_name": str(mother.get("name", "unknown")) if not mother.is_empty() else "unknown",
		"father_name": str(father.get("name", "unknown")) if not father.is_empty() else "unknown",
	}
	var BirthEngineScript = load("res://scripts/genetics/birth_engine.gd")
	var ws: int = int(WorldGenConfig.world_seed) if WorldGenConfig else 0
	var gene_rng: RandomNumberGenerator = SimRng.make_scoped_rng(ws, int(baby_id) ^ int(hash("roster_baby_genome")))
	BirthEngineScript.apply_child_to_entity(entry, mother, father, gene_rng)
	members.append(entry)
	return entry


func start_pregnancy(mother_id: int, father_id: int, pregnancy_seconds: float, now_sec: float) -> bool:
	var m: Dictionary = find_member(mother_id)
	if m.is_empty() or not bool(m.get("alive", false)):
		return false
	if str(m.get("type", "")) != "woman":
		return false
	m["pregnancy_timer"] = pregnancy_seconds
	m["designated_father_id"] = father_id
	m["last_birth_time"] = now_sec
	return true


func cancel_pregnancy(member_id: int) -> Dictionary:
	var m: Dictionary = find_member(member_id)
	if m.is_empty():
		return {}
	if float(m.get("pregnancy_timer", -1.0)) <= 0.0:
		return {}
	m["pregnancy_timer"] = -1.0
	return m.duplicate()


func promote_baby_to_clansman(member_id: int) -> Dictionary:
	var m: Dictionary = find_member(member_id)
	if m.is_empty() or not bool(m.get("alive", false)):
		return {}
	if str(m.get("type", "")) != "baby":
		return {}
	m["type"] = "clansman"
	m["npc_type"] = "clansman"
	m["age"] = 13
	m["growth_timer"] = -1.0
	return m.duplicate()


func get_baby_count() -> int:
	return get_babies().size()


func _balance_type_for(member_type: String) -> String:
	match member_type:
		"leader":
			return "caveman"
		"player":
			return "player"
		_:
			return member_type
