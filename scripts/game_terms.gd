extends Object
class_name GameTerms

## See guides/game_dictionary.md — "fighter activity" = combat/defend/agro/raid state, NOT clansman roster count.

const FIGHTER_ACTIVITY_STATE_NAMES: Array[String] = ["combat", "defend", "agro", "raid"]


static func is_fighter_activity(npc: Node) -> bool:
	if not npc or not is_instance_valid(npc):
		return false
	var dt: Variant = npc.get("defend_target") if "defend_target" in npc else null
	if dt != null and is_instance_valid(dt as Object):
		return true
	var fsm: Node = npc.get_node_or_null("FSM") as Node
	if not fsm:
		return false
	var st: String = str(fsm.get("current_state_name")) if fsm.get("current_state_name") != null else ""
	return st in FIGHTER_ACTIVITY_STATE_NAMES
