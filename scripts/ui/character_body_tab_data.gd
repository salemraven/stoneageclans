extends RefCounted
class_name CharacterBodyTabData

## UI + future sim: active wounds heal over time; at 100% they become scars (grey in Body tab).
## Today: derives from `injury_records` meta until server-owned `active_wounds` exists.

const HEAL_DURATION_SEC := 120.0
const SCAR_META_KEY := "scar_records"


static func get_display_state(npc: Node) -> Dictionary:
	# Returns { "active": Array[Dictionary], "scars": Array[Dictionary] }
	# active row: part_id, part_label, detail, heal_progress 0..1 (0 = full red bar, 1 = healed)
	# scar row: part_id, part_label, detail
	if npc == null or not is_instance_valid(npc):
		return {"active": [], "scars": []}
	_sync_healed_into_scars(npc)
	var scars: Array = _get_scars(npc)
	var scar_parts: Dictionary = {}
	for s in scars:
		if s is Dictionary:
			scar_parts[str(s.get("part", ""))] = true
	var active: Array = []
	var wounds_meta = npc.get_meta("active_wounds", []) if npc.has_meta("active_wounds") else []
	if wounds_meta is Array and not wounds_meta.is_empty():
		active = _active_from_sim_wounds(wounds_meta, scar_parts)
	else:
		active = _active_from_injury_records(npc, scar_parts)
	return {"active": active, "scars": scars}


static func _get_scars(npc: Node) -> Array:
	if not npc.has_meta(SCAR_META_KEY):
		return []
	var raw = npc.get_meta(SCAR_META_KEY)
	return raw if raw is Array else []


static func _sync_healed_into_scars(npc: Node) -> void:
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	var scars: Array = _get_scars(npc).duplicate()
	var scar_parts: Dictionary = {}
	for s in scars:
		if s is Dictionary:
			scar_parts[str(s.get("part", ""))] = true
	var injuries: Array = npc.get_meta("injury_records", []) if npc.has_meta("injury_records") else []
	if not injuries is Array:
		return
	var latest_per_part: Dictionary = {}
	for line in injuries:
		if not line is Dictionary:
			continue
		var part: String = str(line.get("part", "chest"))
		latest_per_part[part] = line
	for part in latest_per_part:
		if scar_parts.has(part):
			continue
		var line: Dictionary = latest_per_part[part]
		var started: float = float(line.get("time_sec", now_sec))
		var progress: float = clampf((now_sec - started) / HEAL_DURATION_SEC, 0.0, 1.0)
		if progress < 1.0:
			continue
		var weapon: String = _weapon_from_line(line)
		scars.append({
			"part": part,
			"part_label": _part_label(line, part),
			"weapon": weapon,
			"display_title": format_injury_title(_part_label(line, part), weapon),
			"detail": str(line.get("text", "")),
		})
		scar_parts[part] = true
	if scars.size() != _get_scars(npc).size():
		npc.set_meta(SCAR_META_KEY, scars)


static func _active_from_injury_records(npc: Node, scar_parts: Dictionary) -> Array:
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	var injuries: Array = npc.get_meta("injury_records", []) if npc.has_meta("injury_records") else []
	if not injuries is Array:
		return []
	var latest_per_part: Dictionary = {}
	for line in injuries:
		if not line is Dictionary:
			continue
		var part: String = str(line.get("part", "chest"))
		latest_per_part[part] = line
	var active: Array = []
	for part in latest_per_part:
		if scar_parts.has(part):
			continue
		var line: Dictionary = latest_per_part[part]
		var started: float = float(line.get("time_sec", now_sec))
		var progress: float = clampf((now_sec - started) / HEAL_DURATION_SEC, 0.0, 1.0)
		if progress >= 1.0:
			continue
		var weapon: String = _weapon_from_line(line)
		var part_label: String = _part_label(line, part)
		active.append({
			"part_id": part,
			"part_label": part_label,
			"weapon": weapon,
			"display_title": format_injury_title(part_label, weapon),
			"detail": str(line.get("text", "")),
			"heal_progress": progress,
		})
	active.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("part_label", "")) < str(b.get("part_label", ""))
	)
	return active


static func _active_from_sim_wounds(wounds_meta: Array, scar_parts: Dictionary) -> Array:
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	var active: Array = []
	for w in wounds_meta:
		if not w is Dictionary:
			continue
		var part: String = str(w.get("part_id", w.get("part", "")))
		if part == "" or scar_parts.has(part):
			continue
		var duration: float = float(w.get("heal_duration_sec", HEAL_DURATION_SEC))
		if duration <= 0.0:
			duration = HEAL_DURATION_SEC
		var started: float = float(w.get("heal_started_sec", now_sec))
		var progress: float = clampf((now_sec - started) / duration, 0.0, 1.0)
		if progress >= 1.0:
			continue
		var part_label: String = str(w.get("part_label", part))
		var weapon: String = str(w.get("weapon", w.get("weapon_source", "")))
		active.append({
			"part_id": part,
			"part_label": part_label,
			"weapon": weapon,
			"display_title": format_injury_title(part_label, weapon),
			"detail": str(w.get("detail", w.get("text", ""))),
			"heal_progress": progress,
		})
	return active


static func format_injury_title(part_label: String, weapon: String) -> String:
	var part_text: String = _title_case_words(part_label.replace("_", " "))
	var weapon_text: String = weapon.strip_edges()
	if weapon_text == "":
		return part_text
	return "%s - %s" % [part_text, _title_case_words(weapon_text)]


static func _weapon_from_line(line: Dictionary) -> String:
	var w: String = str(line.get("weapon", "")).strip_edges()
	if w != "":
		return w
	# Animal / fists: no weapon id on record yet.
	var kind: String = str(line.get("attacker_kind", ""))
	if kind == "animal":
		return str(line.get("attacker_name", "Animal"))
	return ""


static func _title_case_words(text: String) -> String:
	if text == "":
		return ""
	var parts: PackedStringArray = text.split(" ", false)
	var out: Array[String] = []
	for p in parts:
		if p.length() == 0:
			continue
		out.append(p.substr(0, 1).to_upper() + p.substr(1).to_lower())
	return " ".join(out)


static func _part_label(line: Dictionary, part_id: String) -> String:
	var from_line: String = str(line.get("part", ""))
	if from_line != "" and not from_line.contains("_"):
		return from_line
	return part_id.replace("_", " ")
