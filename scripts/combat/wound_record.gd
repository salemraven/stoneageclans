extends RefCounted
class_name WoundRecord

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

## One landed strike rolls a body part. A survivor keeps the line. A killing blow is a kill, not an injury.

const PARTS := [
	{"id": "chest", "label": "chest", "weight": 22},
	{"id": "waist", "label": "waist", "weight": 16},
	{"id": "back", "label": "back", "weight": 14},
	{"id": "left_arm", "label": "left arm", "weight": 12},
	{"id": "right_arm", "label": "right arm", "weight": 12},
	{"id": "head", "label": "head", "weight": 10},
	{"id": "left_eye", "label": "left eye", "weight": 7},
	{"id": "right_eye", "label": "right eye", "weight": 7},
]

const PEOPLE := ["caveman", "clansman", "woman"]
const MAX_LINES := 24


static func roll_part() -> Dictionary:
	var total := 0
	for row in PARTS:
		total += int(row["weight"])
	var pick := randi() % maxi(total, 1)
	var acc := 0
	for row in PARTS:
		acc += int(row["weight"])
		if pick < acc:
			return {"id": str(row["id"]), "label": str(row["label"])}
	return {"id": "chest", "label": "chest"}


static func is_person(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.is_in_group("player"):
		return true
	var t: String = str(node.get("npc_type")) if node.get("npc_type") != null else ""
	return PEOPLE.has(t)


static func is_animal(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var t: String = str(node.get("npc_type")) if node.get("npc_type") != null else ""
	return t != "" and not PEOPLE.has(t) and not node.is_in_group("player")


static func should_keep(victim: Node, attacker: Node, amount: int) -> bool:
	if amount <= 0 or victim == null or attacker == null:
		return false
	if not is_instance_valid(victim) or not is_instance_valid(attacker) or attacker == victim:
		return false
	if CombatAllyCheck.is_ally(attacker, victim):
		return false
	return is_person(victim) or is_person(attacker)


static func note_survived_hit(victim: Node, attacker: Node, weapon_type: ResourceData.ResourceType, part: Dictionary) -> void:
	if not is_person(victim) or attacker == null or not is_instance_valid(attacker):
		return
	var line: Dictionary = _make_line(victim, attacker, weapon_type, part, false)
	_append(victim, "injury_records", line)
	print("WOUND %s" % str(line.get("text", "")))


static func note_kill(killer: Node, victim: Node, weapon_type: ResourceData.ResourceType, part: Dictionary) -> void:
	if victim == null or not is_instance_valid(victim):
		return
	if is_person(killer):
		var line: Dictionary = _make_line(victim, killer, weapon_type, part, true)
		_append(killer, "kill_records", line)
		print("KILL %s" % str(line.get("text", "")))
	if is_person(victim):
		var fallen: Dictionary = _make_line(victim, killer, weapon_type, part, true)
		var by_whom: String = _source_phrase(killer, weapon_type)
		if is_person(killer):
			by_whom = "%s with %s" % [_display_name(killer), _source_phrase(killer, weapon_type)]
		fallen["text"] = "Killed by %s, %s, in a %s" % [
			by_whom,
			str(part.get("label", "chest")),
			str(fallen.get("context", "fight"))
		]
		_append(victim, "death_records", fallen)


static func _make_line(victim: Node, attacker: Node, weapon_type: ResourceData.ResourceType, part: Dictionary, killing: bool) -> Dictionary:
	var part_label: String = str(part.get("label", "chest"))
	var context: String = _encounter_context(victim, attacker)
	var attacker_name: String = _display_name(attacker)
	var attacker_kind: String = _kind(attacker)
	var source: String = _source_phrase(attacker, weapon_type)
	var victim_name: String = _species_name(victim) if is_animal(victim) else _display_name(victim)
	var text: String = _sentence(killing, source, part_label, context, attacker_name, attacker_kind, victim_name)
	return {
		"text": text,
		"part": str(part.get("id", "chest")),
		"weapon": _weapon_label(weapon_type),
		"attacker_name": attacker_name,
		"attacker_kind": attacker_kind,
		"context": context,
		"victim_name": victim_name,
		"time_sec": Time.get_ticks_msec() / 1000.0,
	}


static func _sentence(killing: bool, source: String, part_label: String, context: String, attacker_name: String, attacker_kind: String, victim_name: String) -> String:
	if killing:
		if attacker_kind == "animal":
			return "Killed %s" % victim_name
		return "Killed %s with %s" % [victim_name, source]
	if attacker_kind == "animal" and context == "hunt":
		return "Survived damage from %s to the %s in a hunt" % [source, part_label]
	if context == "raid":
		return "Survived damage from %s to the %s, in a raid with %s" % [source, part_label, attacker_name]
	if context == "hunt":
		return "Survived damage from %s to the %s, in a hunt with %s" % [source, part_label, attacker_name]
	return "Survived damage from %s to the %s, in a fight with %s" % [source, part_label, attacker_name]


static func _append(owner: Node, key: String, line: Dictionary) -> void:
	var rows: Array = owner.get_meta(key, []) if owner.has_meta(key) else []
	rows.append(line)
	while rows.size() > MAX_LINES:
		rows.pop_front()
	owner.set_meta(key, rows)


static func _display_name(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return "unknown"
	if node.is_in_group("player"):
		var pn = node.get("player_name")
		if pn != null and str(pn) != "":
			return str(pn)
		return "Player"
	var nm = node.get("npc_name")
	if nm != null and str(nm) != "":
		return str(nm)
	return node.name


static func _kind(node: Node) -> String:
	if is_animal(node):
		return "animal"
	if is_person(node):
		var t: String = str(node.get("npc_type")) if node.get("npc_type") != null else ""
		if t == "":
			return "player"
		return t
	return "unknown"


static func _source_phrase(attacker: Node, weapon_type: ResourceData.ResourceType) -> String:
	if is_animal(attacker):
		return _species_name(attacker)
	var weapon: String = _weapon_label(weapon_type)
	if weapon != "":
		var article := "an" if "aeiou".contains(weapon.substr(0, 1)) else "a"
		return "%s %s" % [article, weapon]
	var t: String = str(attacker.get("npc_type")) if attacker and attacker.get("npc_type") != null else ""
	if t == "caveman" or t == "clansman":
		return "a caveman"
	if t == "woman":
		return "a woman"
	return _display_name(attacker)


static func _weapon_label(weapon_type: ResourceData.ResourceType) -> String:
	match weapon_type:
		ResourceData.ResourceType.WOOD:
			return "club"
		ResourceData.ResourceType.SPEAR:
			return "spear"
		ResourceData.ResourceType.STONE:
			return "stone"
		ResourceData.ResourceType.AXE:
			return "axe"
		ResourceData.ResourceType.PICK:
			return "pick"
		ResourceData.ResourceType.OLDOWAN:
			return "stone"
		ResourceData.ResourceType.NONE:
			return ""
		_:
			var named: String = ResourceData.get_resource_name(weapon_type)
			if named == "" or named == "Unknown":
				return ""
			return named.to_lower()


static func _species_name(node: Node) -> String:
	var t: String = str(node.get("npc_type")) if node.get("npc_type") != null else "animal"
	if t == "":
		return "Animal"
	return t.capitalize()


static func _encounter_context(victim: Node, attacker: Node) -> String:
	if _node_in_context(victim, "hunt") or _node_in_context(attacker, "hunt"):
		return "hunt"
	if _node_in_context(victim, "raid") or _node_in_context(attacker, "raid"):
		return "raid"
	return "fight"


static func _node_in_context(node: Node, which: String) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if which == "hunt":
		if bool(node.get_meta("hunt_after_combat", false)) or bool(node.get_meta("allow_last_spear_throw", false)):
			return true
	if which == "raid" and bool(node.get_meta("raid_joined", false)):
		return true
	var fsm = node.get("fsm")
	if fsm and fsm.has_method("get_current_state_name"):
		return str(fsm.get_current_state_name()) == which
	return false
