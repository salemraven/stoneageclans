extends RefCounted
class_name CharacterKinTabData

## Lineage tab data: ancestor groups (scroll up) + descendant groups (scroll down).
## Replace name lookup with person_id when LineageRegistry ships.


static func get_lineage_display(subject: NPCBase) -> Dictionary:
	# focal_name, ancestor_groups[], descendant_groups[]
	# group: { "title": String, "rows": Array[Dictionary] }
	if subject == null or not is_instance_valid(subject):
		return _empty()
	var tree: SceneTree = subject.get_tree()
	if tree == null:
		return _empty()
	var clan: String = _clan_name(subject)
	var self_name: String = _npc_name(subject)
	var parent_rows: Array = []
	_add_parent_row(parent_rows, tree, "Mother", _read_name(subject, "mother_name"), clan)
	_add_parent_row(parent_rows, tree, "Father", _read_name(subject, "father_name"), clan)
	var ancestor_groups: Array = [{"title": "Parents", "rows": parent_rows}]
	# Future: push grandparent group from person_id walk
	var child_rows: Array = _find_children(tree, self_name, clan, subject)
	var descendant_groups: Array = []
	if not child_rows.is_empty():
		descendant_groups.append({"title": "Children", "rows": child_rows})
	return {
		"focal_name": self_name if self_name != "" else "Unknown",
		"ancestor_groups": ancestor_groups,
		"descendant_groups": descendant_groups,
	}


static func get_kin_display(subject: NPCBase) -> Dictionary:
	# Legacy flat shape for callers that still use parents/children keys.
	var line: Dictionary = get_lineage_display(subject)
	var parents: Array = []
	var children: Array = []
	for g in line.get("ancestor_groups", []):
		if g is Dictionary:
			parents.append_array(g.get("rows", []))
	for g in line.get("descendant_groups", []):
		if g is Dictionary:
			children.append_array(g.get("rows", []))
	return {"parents": parents, "children": children}


static func _empty() -> Dictionary:
	return {
		"focal_name": "Unknown",
		"ancestor_groups": [],
		"descendant_groups": [],
	}


static func _add_parent_row(out: Array, tree: SceneTree, role: String, name: String, clan: String) -> void:
	if name.strip_edges() == "" or name.to_lower() == "unknown":
		out.append({"label": role, "display_name": "Unknown", "npc": null, "note": ""})
		return
	var resolved: NPCBase = _resolve_by_name(tree, name, clan, null)
	var note: String = ""
	if resolved == null:
		note = "not here"
	out.append({
		"label": role,
		"display_name": name,
		"npc": resolved,
		"note": note,
	})


static func _find_children(tree: SceneTree, parent_name: String, clan: String, subject: NPCBase) -> Array:
	var out: Array = []
	if parent_name.strip_edges() == "":
		return out
	var seen: Dictionary = {}
	for node in tree.get_nodes_in_group("npcs"):
		if not node is NPCBase or not is_instance_valid(node):
			continue
		if node == subject:
			continue
		var mother: String = _read_name(node as NPCBase, "mother_name")
		var father: String = _read_name(node as NPCBase, "father_name")
		if _normalize_name(mother) != _normalize_name(parent_name) and _normalize_name(father) != _normalize_name(parent_name):
			continue
		var child_name: String = _npc_name(node as NPCBase)
		if child_name == "" or seen.has(child_name):
			continue
		seen[child_name] = true
		out.append({
			"display_name": child_name,
			"npc": node as NPCBase,
			"note": "" if node != null else "not here",
		})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	return out


static func _resolve_by_name(tree: SceneTree, name: String, clan: String, skip: NPCBase) -> NPCBase:
	var name_key: String = _normalize_name(name)
	if name_key == "":
		return null
	var clan_match: NPCBase = null
	var any_match: NPCBase = null
	for node in tree.get_nodes_in_group("npcs"):
		if not node is NPCBase or not is_instance_valid(node):
			continue
		if skip != null and node == skip:
			continue
		if _normalize_name(_npc_name(node as NPCBase)) != name_key:
			continue
		any_match = node as NPCBase
		if clan != "" and _clan_name(node as NPCBase) == clan:
			clan_match = node as NPCBase
	if clan_match != null:
		return clan_match
	return any_match


static func _read_name(npc: NPCBase, key: String) -> String:
	var v = npc.get(key) if npc else null
	if v != null and v is String and str(v) != "":
		return str(v)
	if npc and npc.has_meta(key):
		var m = npc.get_meta(key)
		if m != null:
			return str(m)
	return ""


static func _npc_name(npc: NPCBase) -> String:
	var v = npc.get("npc_name") if npc else null
	if v != null and str(v) != "":
		return str(v)
	return ""


static func _normalize_name(name: String) -> String:
	return name.strip_edges().to_lower().replace("  ", " ")


static func _clan_name(npc: NPCBase) -> String:
	var v = npc.get("clan_name") if npc else null
	if v != null and v is String:
		return str(v)
	if npc and npc.has_method("get_clan_name"):
		var c = npc.get_clan_name()
		if c != null:
			return str(c)
	return ""
