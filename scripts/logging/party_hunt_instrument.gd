extends Node
## Debug stuck AI hunt/raid parties (red follow lines = follow_is_ordered).
## Console: `--party-hunt-debug`
## JSONL: add `--playtest-capture` (or `--playtest-log-dir Tests/logs`)

const TRACKED_FSM: Array[String] = ["party", "hunt", "raid", "search", "agro", "combat"]
const SCAN_INTERVAL_SEC: float = 8.0
const STUCK_PARTY_SEC: float = 45.0

var _scan_timer: float = 0.0
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
		3: return "RETREATING"
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


func _format_stuck_followers(rows: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for r in rows:
		if r is Dictionary:
			parts.append("%s(%ss)" % [r.get("name", "?"), r.get("party_sec", "?")])
	return ", ".join(parts)
