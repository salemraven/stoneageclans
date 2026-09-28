extends RefCounted
class_name FightOver

## Single path: everyone targeting a dead/corpse node leaves combat.


static func is_corpse_node(n: Node) -> bool:
	if not n or not is_instance_valid(n):
		return false
	return bool(n.get_meta("is_corpse", false))


static func is_living_attack_target(target: Node) -> bool:
	if not target or not is_instance_valid(target):
		return false
	if is_corpse_node(target):
		return false
	var hc: Node = target.get_node_or_null("HealthComponent")
	if hc != null and "is_dead" in hc and bool(hc.is_dead):
		return false
	if target.has_method("is_dead") and bool(target.is_dead()):
		return false
	return true


static func actor_targets_node(actor: Node, corpse: Node) -> bool:
	if not actor or not corpse or not is_instance_valid(actor) or not is_instance_valid(corpse):
		return false
	var ct: Variant = actor.get("combat_target")
	if ct != null and is_instance_valid(ct) and ct == corpse:
		return true
	var at: Variant = actor.get("agro_target")
	if at != null and is_instance_valid(at) and at == corpse:
		return true
	var cid: int = int(actor.get("combat_target_id")) if actor.get("combat_target_id") != null else -1
	if cid >= 0:
		var n: Node = null
		if Engine.get_main_loop() and Engine.get_main_loop().root:
			var er: Node = Engine.get_main_loop().root.get_node_or_null("EntityRegistry")
			if er and er.has_method("get_entity_node"):
				n = er.get_entity_node(cid)
		if n == null:
			n = instance_from_id(cid)
		if n == corpse:
			return true
	var cc: Node = actor.get_node_or_null("CombatComponent")
	if cc and cc.has_method("get_target"):
		var gt: Node = cc.get_target()
		if gt == corpse:
			return true
	return false


static func _clear_volley_meta(actor: Node, corpse: Node) -> void:
	if actor == null or not is_instance_valid(actor) or not actor.has_method("has_meta"):
		return
	for key in ["volley_attacker", "volley_prey"]:
		if not actor.has_meta(key):
			continue
		var body: Variant = actor.get_meta(key)
		if body == null or not is_instance_valid(body):
			continue
		if body == corpse:
			actor.remove_meta(key)


static func end_fight_for_all_targeting(corpse: Node) -> int:
	if not corpse or not is_instance_valid(corpse):
		return 0
	var tree: SceneTree = corpse.get_tree()
	if tree == null:
		return 0
	var cleared: int = 0
	for npc in tree.get_nodes_in_group("npcs"):
		if not is_instance_valid(npc) or npc == corpse:
			continue
		if bool(npc.get_meta("is_dead", false)):
			continue
		_clear_volley_meta(npc, corpse)
		if actor_targets_node(npc, corpse):
			if npc.has_method("end_fight_target_dead"):
				npc.end_fight_target_dead(corpse)
				cleared += 1
	for pl in tree.get_nodes_in_group("player"):
		if not is_instance_valid(pl) or pl == corpse:
			continue
		_clear_volley_meta(pl, corpse)
		if actor_targets_node(pl, corpse) and pl.has_method("end_fight_target_dead"):
			pl.end_fight_target_dead(corpse)
			cleared += 1
	var pi: Node = tree.root.get_node_or_null("PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("fight_over_broadcast"):
		pi.fight_over_broadcast(str(corpse.get("npc_name")), cleared)
	return cleared
