extends RefCounted
class_name NPCRoleBody

## Single source of truth: which types need a HealthComponent and who can be melee targets.

const HEALTH_BODY_TYPES: Array[String] = [
	"caveman", "clansman", "woman", "sheep", "goat", "deer", "mammoth",
]

const FIGHTER_WEAPON_TYPES: Array[String] = [
	"caveman", "clansman",
]

const UNHITTABLE_TYPES: Array[String] = [
	"baby", "generic",
]


static func type_needs_health_body(npc_type: String) -> bool:
	return HEALTH_BODY_TYPES.has(npc_type)


static func type_is_melee_target(npc_type: String) -> bool:
	if UNHITTABLE_TYPES.has(npc_type):
		return false
	return type_needs_health_body(npc_type)


static func npc_type_of(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return ""
	if node.get("npc_type") != null:
		return str(node.get("npc_type"))
	return ""


## Empty string = valid living target; else machine-readable (combat_whiff / fight_over).
static func attack_target_issue(target: Node) -> String:
	if target == null or not is_instance_valid(target):
		return "invalid_target"
	if bool(target.get_meta("is_corpse", false)):
		return "corpse"
	var t: String = npc_type_of(target)
	if UNHITTABLE_TYPES.has(t):
		return "unhittable"
	if type_needs_health_body(t):
		var hc: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
		if hc == null:
			return "no_body"
		if hc.is_dead:
			return "dead"
	elif target.has_method("is_dead") and bool(target.is_dead()):
		return "dead"
	return ""


static func is_living_attack_target(target: Node) -> bool:
	return attack_target_issue(target) == ""
