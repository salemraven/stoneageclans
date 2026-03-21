extends "res://scripts/npc/states/base_state.gd"

# Reproduction State - Women seeking mates or gestating
# Priority: 8.0 (below herding 10.6, above gathering 3.0)

func can_enter() -> bool:
	# Only women can enter this state
	if not npc:
		return false
	
	if npc.get("npc_type") != "woman":
		return false
	
	# Must be in clan (wild NPCs cannot reproduce)
	# Use get_clan_name() to properly check clan (checks meta as backup)
	var npc_clan = ""
	if npc.has_method("get_clan_name"):
		npc_clan = npc.get_clan_name()
	else:
		npc_clan = npc.clan_name if npc else ""
	
	if not npc_clan or npc_clan == "":
		return false
	
	# Must have reproduction component
	if not npc.reproduction_component:
		return false
	
	# Must have Living Hut (or Oven/Farm/Dairy) to reproduce - otherwise occupy_building takes priority
	if not npc.reproduction_component.has_living_hut_assigned():
		return false
	
	return true

func get_priority() -> float:
	return 8.0  # Below herding (10.6), above gathering (3.0)

func enter() -> void:
	# State entered - reproduction logic handled by component
	pass

func update(_delta: float) -> void:
	# Reproduction logic is handled by reproduction_component.update()
	# This state just ensures woman can enter reproduction mode
	# The FSM priority system will ensure this state is selected when appropriate
	pass

func exit() -> void:
	# State exited
	pass

func get_data() -> Dictionary:
	# Return debug data about reproduction state
	if not npc or not npc.reproduction_component:
		return {}
	
	var repro_status = npc.reproduction_component.get_pregnancy_status()
	return {
		"state": "reproduction",
		"is_pregnant": repro_status.get("is_pregnant", false),
		"birth_timer": repro_status.get("birth_timer", 0.0),
		"time_remaining": repro_status.get("time_remaining", 0.0),
		"mate": repro_status.get("mate", "none")
	}
