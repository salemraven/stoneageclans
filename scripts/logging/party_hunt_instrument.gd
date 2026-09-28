extends Node
## Debug stuck AI hunt/raid parties (red follow lines = follow_is_ordered).
## Console: `--party-hunt-debug`
## JSONL: add `--playtest-capture` (or `--playtest-log-dir Tests/logs`)

const TRACKED_FSM: Array[String] = ["party", "hunt", "raid", "search", "agro", "combat"]
const SCAN_INTERVAL_SEC: float = 8.0
const STUCK_PARTY_SEC: float = 45.0
const COMBAT_SNAPSHOT_SEC: float = 10.0
const FightFlight = preload("res://scripts/combat/fight_flight.gd")

var _scan_timer: float = 0.0
var _combat_timer: float = 0.0
var _stuck_warned: Dictionary = {}  # group_key -> last warn time


func _ready() -> void:
	if OS.get_name() == "Web":
		return
	if is_active():
		print(
			"✓ Party/hunt debug: FSM traces for %s + party group scan every %.0fs (stuck threshold %.0fs)"
			% [", ".join(TRACKED_FSM), SCAN_INTERVAL_SEC, STUCK_PARTY_SEC]
		)
		print("  Tip: add --playtest-capture --playtest-log-dir Tests/logs to save JSONL for analysis")


func is_active() -> bool:
	var dc: Node = get_node_or_null("/root/DebugConfig")
	return dc != null and dc.get("enable_party_hunt_debug") == true


func _process(delta: float) -> void:
	_combat_timer += delta
	if _combat_timer >= COMBAT_SNAPSHOT_SEC:
		_combat_timer = 0.0
		_print_clan_combat_snapshot()
	if not is_active():
		return
	_scan_timer += delta
	if _scan_timer >= SCAN_INTERVAL_SEC:
		_scan_timer = 0.0
		_scan_party_groups()


func on_fsm_transition(npc: Node, from_state: String, to_state: String) -> void:
	if not is_active() or npc == null or not is_instance_valid(npc):
		return
	if to_state not in TRACKED_FSM and from_state not in TRACKED_FSM:
		return
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if nt != "caveman" and nt != "clansman":
		return
	if npc.is_in_group("player"):
		return
	var npc_name: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else str(npc.name)
	var clan: String = str(npc.get("clan_name")) if npc.get("clan_name") != null else ""
	var fo: bool = npc.get("follow_is_ordered") == true
	var herder_name: String = _node_name(npc.get("herder"))
	var hunt_j: bool = npc.has_meta("hunt_joined") and npc.get_meta("hunt_joined") == true
	var raid_j: bool = npc.has_meta("raid_joined") and npc.get_meta("raid_joined") == true
	print(
		"🟥 PARTY/HUNT FSM: %s (%s) %s → %s | clan=%s ordered=%s herder=%s hunt=%s raid=%s"
		% [npc_name, nt, from_state, to_state, clan, fo, herder_name, hunt_j, raid_j]
	)


func on_party_formed(
		clan_name: String,
		leader: Node,
		followers: Array,
		source: String,
		brain_hunt_state: String = "",
		brain_raid_state: String = "") -> void:
	if leader == null or not is_instance_valid(leader):
		return
	var leader_name: String = _node_name(leader)
	var follower_names: PackedStringArray = PackedStringArray()
	for f in followers:
		if f != null and is_instance_valid(f):
			follower_names.append(_node_name(f))
	var extra: Dictionary = {
		"clan": clan_name,
		"followers": follower_names,
		"hunt_state": brain_hunt_state,
		"raid_state": brain_raid_state,
	}
	if is_active():
		print(
			"🟥 PARTY/HUNT FORMED [%s] leader=%s followers=[%s] hunt=%s raid=%s"
			% [source, leader_name, ", ".join(follower_names), brain_hunt_state, brain_raid_state]
		)
	var pi: Node = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("party_formed"):
		pi.party_formed(leader_name, followers.size(), source, extra)


func on_party_disbanded(
		clan_name: String,
		leader: Node,
		followers: Array,
		reason: String,
		brain_hunt_state: String = "",
		brain_raid_state: String = "") -> void:
	var leader_name: String = _node_name(leader) if leader != null and is_instance_valid(leader) else "?"
	var follower_names: PackedStringArray = PackedStringArray()
	for f in followers:
		if f != null and is_instance_valid(f):
			follower_names.append(_node_name(f))
	if is_active():
		print(
			"🟥 PARTY/HUNT DISBAND [%s] clan=%s leader=%s followers=[%s] hunt=%s raid=%s"
			% [reason, clan_name, leader_name, ", ".join(follower_names), brain_hunt_state, brain_raid_state]
		)
	var pi: Node = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("party_disbanded"):
		pi.party_disbanded(leader_name, reason, {
			"clan": clan_name,
			"followers": follower_names,
			"hunt_state": brain_hunt_state,
			"raid_state": brain_raid_state,
		})
	_stuck_warned.clear()


func on_follow_cleared(npc: Node, reason: String = "") -> void:
	if not is_active() or npc == null or not is_instance_valid(npc):
		return
	var npc_name: String = _node_name(npc)
	var clan: String = str(npc.get("clan_name")) if npc.get("clan_name") != null else ""
	var fsm: Node = npc.get("fsm") as Node
	var st: String = fsm.get_current_state_name() if fsm and fsm.has_method("get_current_state_name") else "?"
	print("🟥 PARTY/HUNT CLEARED: %s clan=%s state=%s reason=%s" % [npc_name, clan, st, reason])
	var pi: Node = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("party_follow_cleared"):
		pi.party_follow_cleared(npc_name, clan, st, reason)


func _scan_party_groups() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var groups: Dictionary = {}  # leader_id -> {leader, followers[], clan, ...}
	for n in tree.get_nodes_in_group("npcs"):
		if not is_instance_valid(n) or (n.has_method("is_dead") and n.is_dead()):
			continue
		if n.get("follow_is_ordered") != true:
			continue
		var hr = n.get("herder")
		if hr == null or not is_instance_valid(hr):
			continue
		var nt: String = str(n.get("npc_type")) if n.get("npc_type") != null else ""
		if nt != "caveman" and nt != "clansman":
			continue
		var lid: int = hr.get_instance_id()
		if not groups.has(lid):
			groups[lid] = {"leader": hr, "followers": []}
		(groups[lid]["followers"] as Array).append(n)
	if groups.is_empty():
		return
	var scan_rows: Array = []
	var now: float = Time.get_ticks_msec() / 1000.0
	for lid in groups.keys():
		var g: Dictionary = groups[lid]
		var leader: Node = g["leader"]
		var followers: Array = g["followers"]
		if leader == null or not is_instance_valid(leader):
			continue
		var clan: String = str(leader.get("clan_name")) if leader.get("clan_name") != null else ""
		var brain: Variant = _clan_brain_for_clan(clan)
		var hunt_st: String = _brain_hunt_state(brain)
		var raid_st: String = _brain_raid_state(brain)
		var leader_fsm: Node = leader.get("fsm") as Node
		var leader_state: String = (
			leader_fsm.get_current_state_name()
			if leader_fsm and leader_fsm.has_method("get_current_state_name")
			else "?"
		)
		var follower_rows: Array = []
		var stuck_followers: Array = []
		for f in followers:
			if not is_instance_valid(f):
				continue
			var fsm_f = f.get("fsm")
			var fst: String = fsm_f.get_current_state_name() if fsm_f and fsm_f.has_method("get_current_state_name") else "?"
			var entry_t: float = float(fsm_f.get_meta("entry_time", now)) if fsm_f else now
			var dur: float = now - entry_t
			var row: Dictionary = {
				"name": _node_name(f),
				"state": fst,
				"party_sec": snappedf(dur, 1),
			}
			follower_rows.append(row)
			if fst == "party" and dur >= STUCK_PARTY_SEC:
				stuck_followers.append(row)
		var brain_idle: bool = hunt_st == "NONE" and raid_st == "NONE"
		var leader_idle: bool = leader_state in ["wander", "gather", "idle", "craft", "herd_wildnpc"]
		var is_stuck: bool = stuck_followers.size() > 0 and brain_idle and leader_idle
		var row_out: Dictionary = {
			"clan": clan,
			"leader": _node_name(leader),
			"leader_state": leader_state,
			"hunt_state": hunt_st,
			"raid_state": raid_st,
			"followers": follower_rows,
			"stuck": is_stuck,
		}
		scan_rows.append(row_out)
		if is_stuck and is_active():
			var key: String = "%s|%s" % [clan, _node_name(leader)]
			var last_warn: float = float(_stuck_warned.get(key, 0.0))
			if now - last_warn >= SCAN_INTERVAL_SEC:
				_stuck_warned[key] = now
				print(
					"🟥 PARTY/HUNT STUCK? clan=%s leader=%s (%s) hunt=%s raid=%s — followers in party >%.0fs: %s"
					% [
						clan,
						_node_name(leader),
						leader_state,
						hunt_st,
						raid_st,
						STUCK_PARTY_SEC,
						_format_stuck_followers(stuck_followers),
					]
				)
	var pi: Node = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("party_group_scan"):
		pi.party_group_scan(scan_rows)


func _clan_brain_for_clan(clan_name: String) -> Variant:
	if clan_name == "":
		return null
	for lc in get_tree().get_nodes_in_group("land_claims"):
		if not is_instance_valid(lc):
			continue
		if str(lc.get("clan_name")) != clan_name:
			continue
		return lc.get("clan_brain")
	return null


func _brain_hunt_state(brain: Variant) -> String:
	if brain == null or not brain.has_method("get_hunt_intent"):
		return "?"
	var intent: Dictionary = brain.get_hunt_intent()
	var st: int = int(intent.get("state", 0))
	# HuntIntentState: NONE=0, RECRUITING=1, ACTIVE=2, LOOTING=3, RETREATING=4
	match st:
		0: return "NONE"
		1: return "RECRUITING"
		2: return "ACTIVE"
		3: return "LOOTING"
		4: return "RETREATING"
		_: return str(st)


func _brain_raid_state(brain: Variant) -> String:
	if brain == null or not brain.has_method("get_raid_state"):
		return "?"
	var st: int = int(brain.get_raid_state())
	match st:
		0: return "NONE"
		1: return "RECRUITING"
		2: return "ACTIVE"
		3: return "RETREATING"
		_: return str(st)


func _node_name(n: Variant) -> String:
	if n == null or not (n is Node) or not is_instance_valid(n):
		return ""
	var node := n as Node
	var nn = node.get("npc_name")
	return str(nn) if nn != null else str(node.name)


func note_fight_enter(npc: Node, target: Node) -> void:
	if not _is_ai_fighter(npc):
		return
	var mode := _ordered_mode(npc)
	var fill := str(npc.get_meta("last_agro_reason", "")) if npc.has_meta("last_agro_reason") else ""
	var odd := ""
	if mode == "FOLLOW" and fill != "" and fill != "hit":
		odd = " follow_acquired_without_hit"
	print(
		"CLAN_COMBAT ENGAGE clan=%s name=%s mode=%s ordered=%s target=%s score=%.2f clan_leader=%s leads=%s fill=%s%s"
		% [
			_clan_of(npc),
			_node_name(npc),
			mode if mode != "" else "-",
			str(npc.get("follow_is_ordered") == true),
			_node_name(target),
			_score_of(npc, target),
			_clan_leader_name(_clan_of(npc)),
			str(_is_clan_leader(npc)),
			fill,
			odd,
		]
	)


func note_fight_break(npc: Node, why: String, target: Node) -> void:
	if not _is_ai_fighter(npc) and not (npc != null and str(npc.get("npc_type")) == "woman" and not npc.is_in_group("player")):
		return
	print(
		"CLAN_COMBAT BREAK clan=%s name=%s why=%s mode=%s score=%.2f target=%s"
		% [
			_clan_of(npc),
			_node_name(npc),
			why,
			_ordered_mode(npc) if _ordered_mode(npc) != "" else "-",
			_score_of(npc, target),
			_node_name(target),
		]
	)


func note_leash(npc: Node, mode: String, dist: float, max_dist: float) -> void:
	if not _is_ai_fighter(npc):
		return
	print(
		"CLAN_COMBAT LEASH clan=%s name=%s mode=%s dist=%.0f max=%.0f"
		% [_clan_of(npc), _node_name(npc), mode, dist, max_dist]
	)


func note_hunt_arc(clan_name: String, leader: Node, follower_count: int) -> void:
	var same := _is_clan_leader(leader)
	print(
		"CLAN_COMBAT ARC clan=%s party_leader=%s clan_leader=%s same=%s followers=%d"
		% [clan_name, _node_name(leader), _clan_leader_name(clan_name), str(same), follower_count]
	)


func _print_clan_combat_snapshot() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for lc in tree.get_nodes_in_group("land_claims"):
		if not is_instance_valid(lc) or lc.get("player_owned") == true:
			continue
		var clan := str(lc.get("clan_name"))
		if clan == "":
			continue
		var brain: Variant = lc.get("clan_brain")
		var hunt_st := _brain_hunt_state(brain)
		var raid_st := _brain_raid_state(brain)
		var counts := _clan_fight_counts(clan)
		var busy: bool = hunt_st != "NONE" or raid_st != "NONE" or int(counts["combat"]) > 0 or int(counts["flee"]) > 0
		if not busy:
			continue
		var party_leader: String = str(counts["party_leader"])
		var clan_leader := _clan_leader_name(clan)
		var same := party_leader != "" and party_leader == clan_leader
		var odd: Array = counts["odd"]
		var odd_text := ""
		if odd.size() > 0:
			odd_text = " odd=%s" % ",".join(PackedStringArray(odd))
		print(
			"CLAN_COMBAT clan=%s hunt=%s raid=%s clan_leader=%s(%s) party_leader=%s same=%s modes=%s combat=%d flee=%d women_combat=%d%s"
			% [
				clan,
				hunt_st,
				raid_st,
				clan_leader,
				counts["leader_state"],
				party_leader if party_leader != "" else "-",
				str(same) if party_leader != "" else "-",
				counts["modes"],
				int(counts["combat"]),
				int(counts["flee"]),
				int(counts["women_combat"]),
				odd_text,
			]
		)


func _clan_fight_counts(clan_name: String) -> Dictionary:
	var combat := 0
	var flee := 0
	var women_combat := 0
	var modes: Dictionary = {}
	var party_leader := ""
	var leader_state := "-"
	var odd: Array = []
	var leader := _clan_leader_node(clan_name)
	if leader != null:
		leader_state = _state_name(leader)
	for n in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(n) or str(n.get("clan_name")) != clan_name:
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		var st := _state_name(n)
		var nt := str(n.get("npc_type"))
		if nt == "woman" and st == "combat":
			women_combat += 1
			if not odd.has("woman_in_combat"):
				odd.append("woman_in_combat")
		if st == "combat":
			combat += 1
		elif st == "flee_combat":
			flee += 1
		if n.get("follow_is_ordered") == true:
			var mode := _ordered_mode(n)
			var key := mode if mode != "" else "-"
			modes[key] = int(modes.get(key, 0)) + 1
			if key != "FOLLOW" and key != "ARC" and not odd.has("unexpected_%s" % key):
				odd.append("unexpected_%s" % key)
			var hr = n.get("herder")
			if hr != null and is_instance_valid(hr) and party_leader == "":
				party_leader = _node_name(hr)
			if key == "FOLLOW" and st == "combat":
				var fill := str(n.get_meta("last_agro_reason", "")) if n.has_meta("last_agro_reason") else ""
				if fill != "" and fill != "hit" and not odd.has("follow_without_hit"):
					odd.append("follow_without_hit")
	var mode_bits: PackedStringArray = PackedStringArray()
	for k in modes.keys():
		mode_bits.append("%s:%d" % [k, int(modes[k])])
	return {
		"combat": combat,
		"flee": flee,
		"women_combat": women_combat,
		"modes": ",".join(mode_bits) if mode_bits.size() > 0 else "-",
		"party_leader": party_leader,
		"leader_state": leader_state,
		"odd": odd,
	}


func _is_ai_fighter(npc: Node) -> bool:
	if npc == null or not is_instance_valid(npc) or npc.is_in_group("player"):
		return false
	var nt := str(npc.get("npc_type"))
	if nt != "caveman" and nt != "clansman":
		return false
	var claim := _claim_for_clan(_clan_of(npc))
	return claim != null and claim.get("player_owned") != true


func _ordered_mode(npc: Node) -> String:
	if npc == null or npc.get("follow_is_ordered") != true:
		return ""
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	return str(ctx.get("mode", "FOLLOW"))


func _score_of(npc: Node, target: Node) -> float:
	if npc == null or target == null or not is_instance_valid(target):
		return 0.0
	if FightFlight.is_building(target):
		return 0.0
	return FightFlight.score(npc, target)


func _state_name(npc: Node) -> String:
	var fsm: Node = npc.get("fsm") as Node
	if fsm and fsm.has_method("get_current_state_name"):
		return str(fsm.get_current_state_name())
	return "?"


func _clan_of(npc: Node) -> String:
	if npc == null:
		return ""
	return str(npc.get("clan_name")) if npc.get("clan_name") != null else ""


func _claim_for_clan(clan_name: String) -> Node:
	if clan_name == "" or get_tree() == null:
		return null
	for lc in get_tree().get_nodes_in_group("land_claims"):
		if is_instance_valid(lc) and str(lc.get("clan_name")) == clan_name:
			return lc
	return null


func _clan_leader_node(clan_name: String) -> Node:
	var claim := _claim_for_clan(clan_name)
	if claim == null:
		return null
	var owner: Variant = claim.get("owner_npc")
	if owner is Node and is_instance_valid(owner):
		return owner
	return null


func _clan_leader_name(clan_name: String) -> String:
	var leader := _clan_leader_node(clan_name)
	return _node_name(leader) if leader != null else "-"


func _is_clan_leader(npc: Node) -> bool:
	if npc == null:
		return false
	return npc == _clan_leader_node(_clan_of(npc))


func _format_stuck_followers(rows: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for r in rows:
		if r is Dictionary:
			parts.append("%s(%ss)" % [r.get("name", "?"), r.get("party_sec", "?")])
	return ", ".join(parts)
