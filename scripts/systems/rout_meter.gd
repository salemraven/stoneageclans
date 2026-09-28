extends RefCounted
class_name RoutMeter

## Legacy entry points — morale bar owns panic; no second flee threshold.


static func add_on_ally_death(dead: Node) -> void:
	const MoraleBarScript = preload("res://scripts/combat/morale_bar.gd")
	var leader_death: bool = dead != null and str(dead.get("npc_type")) == "caveman"
	MoraleBarScript.apply_clan_man_death(dead, leader_death)


static func add_on_ally_rout(router: Node) -> void:
	const MoraleBarScript = preload("res://scripts/combat/morale_bar.gd")
	MoraleBarScript.apply_ally_entered_flight(router)


static func effective_flee_threshold(_n: Node) -> float:
	return 100.0
