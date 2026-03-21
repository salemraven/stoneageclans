extends "res://scripts/npc/states/base_state.gd"

# Seek state - NPC moves toward a target

var target_position: Vector2 = Vector2.ZERO
var target_node: Node2D = null

func enter() -> void:
	if npc and npc.steering_agent:
		if target_node:
			npc.steering_agent.set_target_node(target_node)
		else:
			npc.steering_agent.set_target_position(target_position)

func set_target(pos: Vector2) -> void:
	target_position = pos
	target_node = null

func set_target_node(node: Node2D) -> void:
	target_node = node
	if node:
		target_position = node.global_position

func can_enter() -> bool:
	var npc_name: String = npc.get("npc_name") if npc else "unknown"
	
	# Can seek if we have a target
	var can_enter_result: bool = target_node != null or target_position != Vector2.ZERO
	var reason: String = ""
	if target_node != null:
		reason = "has_target_node"
	elif target_position != Vector2.ZERO:
		reason = "has_target_position"
	else:
		reason = "no_target"
	UnifiedLogger.log_npc("Can enter check: %s %s enter seek (%s)" % [npc_name, "can" if can_enter_result else "cannot", reason], {
		"npc": npc_name,
		"state": "seek",
		"can_enter": can_enter_result,
		"reason": reason
	}, UnifiedLogger.Level.DEBUG)
	return can_enter_result

func get_priority() -> float:
	return 2.0

func get_data() -> Dictionary:
	return {
		"target_position": target_position,
		"has_target_node": target_node != null
	}

