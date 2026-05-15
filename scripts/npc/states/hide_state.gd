extends "res://scripts/npc/states/base_state.gd"

## Hide / ambush: move to cover (or crouch in open), stay hidden; ambush joins leader’s attack.

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")
const CoverQuery = preload("res://scripts/systems/cover_query.gd")
const PerceptionArea = preload("res://scripts/npc/components/perception_area.gd")

var _hide_world: Vector2 = Vector2.ZERO
var _cover_node: Node2D = null
var _has_cover: bool = false


func enter() -> void:
	_cancel_tasks_if_active()
	_hide_world = Vector2.ZERO
	_cover_node = null
	_has_cover = false
	if npc:
		npc.remove_meta("is_hidden")
		npc.remove_meta("hide_has_cover")
	_pick_hide_destination()


func exit() -> void:
	_cancel_tasks_if_active()
	if npc:
		npc.remove_meta("is_hidden")
		npc.remove_meta("hide_has_cover")
	if npc and npc.steering_agent and npc.steering_agent.has_method("restore_original_speed"):
		npc.steering_agent.restore_original_speed()


func _pick_hide_destination() -> void:
	if npc == null:
		return
	var tree: SceneTree = npc.get_tree()
	var threat: Vector2 = _estimate_threat_position()
	var cover: Node2D = CoverQuery.find_nearest_cover(npc.global_position, tree)
	if cover and is_instance_valid(cover):
		_cover_node = cover
		_has_cover = true
		_hide_world = CoverQuery.get_hide_position(cover, threat)
	else:
		_cover_node = null
		_has_cover = false
		var away: Vector2 = (npc.global_position - threat)
		if away.length_squared() < 4.0:
			away = Vector2(1, 0).rotated(_npc_rngf()() * TAU) * 40.0
		else:
			away = away.normalized() * 40.0
		_hide_world = npc.global_position + away
	if npc.steering_agent and npc.steering_agent.has_method("set_arrive_target"):
		npc.steering_agent.set_arrive_target(_hide_world)


func _estimate_threat_position() -> Vector2:
	var herder: Node2D = npc.herder as Node2D if npc and npc.herder else null
	if herder and is_instance_valid(herder):
		return herder.global_position
	var pa: PerceptionArea = npc.get_node_or_null("DetectionArea") as PerceptionArea
	if pa:
		var c: Vector2 = pa.get_deer_threat_centroid(npc.global_position, pa.detection_range * 1.2, npc)
		if c != Vector2.ZERO:
			return c
	return npc.global_position + Vector2(0, -120.0)


func _leader_attack_target() -> Node2D:
	if npc == null or EntityRegistry == null:
		return null
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var cid: int = int(ctx.get("commander_id", -1))
	if cid < 0:
		return null
	var leader: Node = EntityRegistry.get_entity_node(cid)
	if leader == null or not is_instance_valid(leader):
		return null
	var cc: CombatComponent = leader.get_node_or_null("CombatComponent") as CombatComponent
	if cc == null:
		return null
	var t: Node2D = cc.current_target
	if t and is_instance_valid(t):
		return t
	return null


func _leader_is_attacking() -> bool:
	if npc == null or EntityRegistry == null:
		return false
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var cid: int = int(ctx.get("commander_id", -1))
	if cid < 0:
		return false
	var leader: Node = EntityRegistry.get_entity_node(cid)
	if leader == null or not is_instance_valid(leader):
		return false
	var cc: CombatComponent = leader.get_node_or_null("CombatComponent") as CombatComponent
	if cc == null:
		return false
	return cc.state != CombatComponent.CombatState.IDLE


func _try_ambush_release() -> void:
	if npc == null or fsm == null:
		return
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var mode: String = str(ctx.get("mode", "FOLLOW"))
	if mode != "AMBUSH":
		return
	if not _leader_is_attacking():
		return
	var tgt: Node2D = _leader_attack_target()
	if tgt == null or not is_instance_valid(tgt):
		return
	if CombatAllyCheck.is_ally(npc, tgt):
		return
	npc.remove_meta("is_hidden")
	npc.remove_meta("hide_has_cover")
	var tid: int = EntityRegistry.get_id(tgt) if EntityRegistry else -1
	npc.set("combat_target_id", tid)
	if "combat_target_id" in npc:
		npc.combat_target_id = tid
	npc.set("combat_target", tgt)
	if "combat_target" in npc:
		npc.combat_target = tgt
	npc.set("agro_meter", 96.0)
	if "agro_meter" in npc:
		npc.agro_meter = 96.0
	fsm.change_state("combat")


func update(delta: float) -> void:
	if npc == null:
		return
	if npc.is_dead():
		return
	if not npc.herder or not is_instance_valid(npc.herder):
		if fsm:
			fsm.change_state("wander")
		return
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var mode: String = str(ctx.get("mode", "FOLLOW"))
	if mode != "HIDE" and mode != "AMBUSH":
		if fsm:
			fsm.change_state("party")
		return

	_try_ambush_release()
	if fsm and fsm.get_current_state_name() == "combat":
		return

	if _cover_node != null and not is_instance_valid(_cover_node):
		_pick_hide_destination()

	var dist: float = npc.global_position.distance_to(_hide_world)
	if dist > 22.0:
		if npc.steering_agent:
			if npc.steering_agent.has_method("restore_original_speed"):
				npc.steering_agent.restore_original_speed()
			npc.steering_agent.set_arrive_target(_hide_world)
		npc.remove_meta("is_hidden")
	else:
		if npc.steering_agent and npc.steering_agent.has_method("set_speed_multiplier"):
			npc.steering_agent.set_speed_multiplier(0.12)
		npc.set_meta("is_hidden", true)
		npc.set_meta("hide_has_cover", _has_cover)
		if npc.steering_agent:
			npc.steering_agent.set_arrive_target(npc.global_position)


func can_enter() -> bool:
	if npc == null or npc.is_dead():
		return false
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if nt != "caveman" and nt != "clansman":
		return false
	if npc.get("follow_is_ordered") != true:
		return false
	if npc.herder == null or not is_instance_valid(npc.herder):
		return false
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	var mode: String = str(ctx.get("mode", "FOLLOW"))
	return mode == "HIDE" or mode == "AMBUSH"


func get_priority() -> float:
	return 11.9


func get_data() -> Dictionary:
	return {"state": "hide", "has_cover": _has_cover}
