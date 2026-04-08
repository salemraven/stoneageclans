extends Object
class_name CombatAllyCheck

## Single source of truth: two units should not target or damage each other.
## Used by perception, hostile index, combat tick, combat state, hit validation, and retaliation.


static func _clan_str(n: Node) -> String:
	if not n or not is_instance_valid(n):
		return ""
	if n.has_method("get_clan_name"):
		return n.get_clan_name()
	if "clan_name" in n and n.get("clan_name") != null:
		return str(n.get("clan_name"))
	return ""


static func _player_npc_ally(player: Node, npc: Node) -> bool:
	if not npc or not is_instance_valid(npc):
		return false
	if npc.get("herder") == player:
		return true
	var dt = npc.get("defend_target")
	var shc = npc.get("search_home_claim")
	if (dt != null and is_instance_valid(dt) and dt.get("player_owned") == true) or (shc != null and is_instance_valid(shc) and shc.get("player_owned") == true):
		return true
	var pc: String = _clan_str(player)
	var nc: String = _clan_str(npc)
	if pc != "" and nc != "" and pc == nc:
		return true
	return false


static func is_ally(a: Node, b: Node) -> bool:
	if not a or not b or not is_instance_valid(a) or not is_instance_valid(b):
		return false
	if a == b:
		return true
	# Direct herder / leader relationship
	if b.get("herder") == a or a.get("herder") == b:
		return true
	# Same commander (party, herd, ordered follow)
	var ha: Variant = a.get("herder")
	var hb: Variant = b.get("herder")
	if ha != null and is_instance_valid(ha) and ha == hb:
		return true
	# Same non-empty clan (symmetric; get_clan_name may recover from meta on NPCBase)
	var ca: String = _clan_str(a)
	var cb: String = _clan_str(b)
	if ca != "" and cb != "" and ca == cb:
		return true
	# Same resolved land claim (authoritative when both NPCs have clan-backed claims)
	if a.has_method("get_my_land_claim") and b.has_method("get_my_land_claim"):
		var la: Node = a.get_my_land_claim()
		var lb: Node = b.get_my_land_claim()
		if la != null and is_instance_valid(la) and la == lb:
			return true
	# Co-defenders or co-searchers on the same claim
	var dta: Variant = a.get("defend_target")
	var dtb: Variant = b.get("defend_target")
	if dta != null and is_instance_valid(dta) and dtb != null and is_instance_valid(dtb) and dta == dtb:
		return true
	var sha: Variant = a.get("search_home_claim")
	var shb: Variant = b.get("search_home_claim")
	if sha != null and is_instance_valid(sha) and shb != null and is_instance_valid(shb) and sha == shb:
		return true
	# Player in either role
	if a.is_in_group("player"):
		return _player_npc_ally(a, b)
	if b.is_in_group("player"):
		return _player_npc_ally(b, a)
	return false
