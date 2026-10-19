extends RefCounted
class_name PlayerPartyHunt

## Player RTS HUNT: one engagement token per ordered clansman.
## Only this script sets or clears hunt_engagement. States read it; they do not force combat.

const FightOverScript = preload("res://scripts/systems/fight_over.gd")

const TOKEN_META := "hunt_engagement"
const DEFAULT_ACQUIRE_RADIUS_PX := 520.0
const RELEASE_RADIUS_PX := 750.0


static func is_player_rts_hunt_mode(tree: SceneTree) -> bool:
	if tree == null:
		return false
	var main: Node = tree.get_first_node_in_group("main")
	if main and main.has_method("is_player_rts_hunt_mode"):
		return bool(main.call("is_player_rts_hunt_mode"))
	return false


static func is_active_follower(npc: Node) -> bool:
	if npc == null or not is_instance_valid(npc):
		return false
	if npc.get("follow_is_ordered") != true:
		return false
	var herder: Variant = npc.get("herder")
	if herder == null or not is_instance_valid(herder):
		return false
	if not (herder as Node).is_in_group("player"):
		return false
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if nt != "caveman" and nt != "clansman":
		return false
	var ctx: Dictionary = npc.get("command_context") if npc.get("command_context") != null else {}
	if bool(ctx.get("rts_hunt", false)):
		return true
	return is_player_rts_hunt_mode(npc.get_tree())


static func acquire_radius_px() -> float:
	var r: float = DEFAULT_ACQUIRE_RADIUS_PX
	if NPCConfig and NPCConfig.get("agro_perception_range") != null:
		r = maxf(r, float(NPCConfig.agro_perception_range))
	return r


static func release_radius_px() -> float:
	return maxf(RELEASE_RADIUS_PX, acquire_radius_px() + 80.0)


static func is_huntable_prey(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if not FightOverScript.is_living_attack_target(body):
		return false
	var kind: String = str(body.get("npc_type")) if body.get("npc_type") != null else ""
	if NPCConfig == null or not NPCConfig.has_method("is_ai_hunt_prey_type"):
		return false
	return NPCConfig.is_ai_hunt_prey_type(kind)


static func token_prey(npc: Node) -> Node2D:
	if npc == null or not npc.has_meta(TOKEN_META):
		return null
	var raw: Variant = npc.get_meta(TOKEN_META)
	if not (raw is Dictionary):
		return null
	var body: Variant = (raw as Dictionary).get("target")
	if body is Node2D and is_instance_valid(body):
		return body as Node2D
	return null


static func token_is_live(npc: Node) -> bool:
	var prey := token_prey(npc)
	return prey != null and is_huntable_prey(prey) and in_release_range(npc, prey)


static func should_keep_fighting(npc: Node) -> bool:
	return token_is_live(npc)


static func _party_anchor(npc: Node) -> Vector2:
	if npc == null or not (npc is Node2D):
		return Vector2.ZERO
	var herder: Variant = npc.get("herder")
	if herder != null and is_instance_valid(herder) and herder is Node2D:
		return (herder as Node2D).global_position
	return (npc as Node2D).global_position


static func _within(npc: Node, prey: Node2D, radius: float) -> bool:
	if npc == null or prey == null or not is_instance_valid(prey) or not (npc is Node2D):
		return false
	var body: Node2D = npc as Node2D
	if body.global_position.distance_to(prey.global_position) <= radius:
		return true
	return _party_anchor(npc).distance_to(prey.global_position) <= radius


static func in_acquire_range(npc: Node, prey: Node2D) -> bool:
	return _within(npc, prey, acquire_radius_px())


static func in_release_range(npc: Node, prey: Node2D) -> bool:
	return _within(npc, prey, release_radius_px())


static func pick_nearest_prey(npc: Node) -> Node2D:
	if npc == null or not is_instance_valid(npc) or not (npc is Node2D):
		return null
	var origin: Vector2 = (npc as Node2D).global_position
	var radius: float = acquire_radius_px()
	var candidates: Array = []
	if HostileEntityIndex:
		candidates = HostileEntityIndex.get_in_range(
			origin,
			radius,
			HostileEntityIndex.FILTER_HUNT_PREY,
			npc
		)
	else:
		var tree := npc.get_tree()
		if tree == null:
			return null
		for node in tree.get_nodes_in_group("npcs"):
			if not is_huntable_prey(node) or not (node is Node2D):
				continue
			if origin.distance_to((node as Node2D).global_position) > radius:
				continue
			candidates.append(node)
	var best: Node2D = null
	var best_d: float = INF
	for c in candidates:
		if not is_huntable_prey(c) or not (c is Node2D):
			continue
		if not in_acquire_range(npc, c as Node2D):
			continue
		var d: float = origin.distance_to((c as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = c as Node2D
	return best


static func _bind_combat(npc: Node, prey: Node2D) -> void:
	if npc.has_method("equip_work_weapon_spear"):
		npc.call("equip_work_weapon_spear")
	npc.set("is_hostile", true)
	if npc.has_method("assign_combat_target_node"):
		npc.assign_combat_target_node(prey)
	else:
		npc.set("combat_target", prey)
	npc.set("agro_meter", 100.0)
	if "agro_meter" in npc:
		npc.agro_meter = 100.0
	npc.set_meta("volley_prey", prey)
	npc.remove_meta("volley_attacker")


static func _write_token(npc: Node, prey: Node2D) -> void:
	npc.set_meta(TOKEN_META, {
		"target": prey,
		"acquired_at": Time.get_ticks_msec() / 1000.0,
	})


static func engage(npc: Node, prey: Node2D) -> void:
	if npc == null or prey == null or not is_instance_valid(npc) or not is_instance_valid(prey):
		return
	var already: Node2D = token_prey(npc)
	_bind_combat(npc, prey)
	if already == prey and npc.has_meta(TOKEN_META):
		_note_held(npc, prey)
		return
	_write_token(npc, prey)
	_emit(npc, "hunt_engage", prey, "acquire")
	_note_held(npc, prey)


## Acquire or keep the token. Does not change FSM state. True while combat should own the man.
static func refresh(npc: Node) -> bool:
	if npc == null or not is_instance_valid(npc):
		return false
	if not is_active_follower(npc):
		if token_prey(npc) != null or npc.has_meta(TOKEN_META):
			release(npc, "mode_exit")
		return false
	var held: Node2D = token_prey(npc)
	if held != null:
		if not is_huntable_prey(held):
			release(npc, "dead")
			return false
		if not in_release_range(npc, held):
			release(npc, "out_of_range")
			return false
		_bind_combat(npc, held)
		_note_held(npc, held)
		return true
	var prey: Node2D = pick_nearest_prey(npc)
	if prey == null:
		return false
	engage(npc, prey)
	return true


static func release(npc: Node, reason: String) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	var prey: Node2D = token_prey(npc)
	if npc.has_meta(TOKEN_META):
		npc.remove_meta(TOKEN_META)
	if npc.has_meta("hunt_held_at"):
		npc.remove_meta("hunt_held_at")
	if npc.has_meta("volley_prey"):
		var volley: Variant = npc.get_meta("volley_prey")
		if prey == null or volley == prey:
			npc.remove_meta("volley_prey")
	_emit(npc, "hunt_release", prey, reason)
	var ct: Variant = npc.get("combat_target")
	if prey != null and ct == prey:
		npc.set("combat_target", null)
		npc.set("combat_target_id", -1)
		if "combat_target" in npc:
			npc.combat_target = null
		if "combat_target_id" in npc:
			npc.combat_target_id = -1


static func clear_hunt_engagement(npc: Node) -> void:
	release(npc, "mode_exit")
	if npc == null or not is_instance_valid(npc):
		return
	var fsm: Node = npc.get("fsm") as Node
	if fsm and fsm.has_method("get_current_state_name"):
		if str(fsm.get_current_state_name()) == "combat":
			fsm.set("evaluation_timer", 0.0)


static func _note_held(npc: Node, prey: Node2D) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var last: float = float(npc.get_meta("hunt_held_at", 0.0)) if npc.has_meta("hunt_held_at") else 0.0
	if now - last < 1.0:
		return
	npc.set_meta("hunt_held_at", now)
	var state_name := ""
	var fsm: Node = npc.get("fsm") as Node
	if fsm and fsm.has_method("get_current_state_name"):
		state_name = str(fsm.get_current_state_name())
	var dist := -1.0
	if npc is Node2D and prey != null:
		dist = (npc as Node2D).global_position.distance_to(prey.global_position)
	var pi: Node = _instrument(npc)
	if pi and pi.has_method("hunt_state_held"):
		pi.hunt_state_held(str(npc.get("npc_name")), state_name, dist)


static func _emit(npc: Node, method: String, prey: Node, reason: String) -> void:
	var pi: Node = _instrument(npc)
	if pi == null or not pi.has_method(method):
		return
	var prey_name := ""
	if prey != null and is_instance_valid(prey):
		prey_name = str(prey.get("npc_name"))
	pi.call(method, str(npc.get("npc_name")), prey_name, reason)


static func _instrument(npc: Node) -> Node:
	if npc == null or not npc.is_inside_tree():
		return null
	return npc.get_node_or_null("/root/PlaytestInstrumentor")
