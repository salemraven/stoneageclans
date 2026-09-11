extends Node
## Rituals only change ClimateState.ritual_pressure (rate/target), capped per day.

const ClimateConstantsRes = preload("res://scripts/world/climate_constants.gd")

var _applied_today: float = 0.0
var _day_seen: int = -1


func apply_ritual(amount: float) -> float:
	var cs: Node = get_node_or_null("/root/ClimateState")
	if cs == null or not bool(cs.climate_enabled):
		return 0.0
	if int(cs.sim_day) != _day_seen:
		_day_seen = int(cs.sim_day)
		_applied_today = 0.0
	var cap: float = ClimateConstantsRes.RITUAL_CAP_PER_REGION_PER_DAY
	var room: float = cap - absf(_applied_today)
	var add: float = clampf(amount, -room, room)
	_applied_today += add
	cs.ritual_pressure = clampf(float(cs.ritual_pressure) + add, -cap, cap)
	return add
