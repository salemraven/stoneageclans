extends RefCounted
class_name CombatStance

## Melee stand-or-walk choice. One rule so combat does not also slide, match height, and back up.


static func decide(distance: float, attack_range: float) -> String:
	var reach: float = maxf(attack_range, 1.0)
	if distance <= reach:
		return "hold"
	return "approach"


static func approach_point(from: Vector2, enemy: Vector2, attack_range: float) -> Vector2:
	var away: Vector2 = from - enemy
	if away.length_squared() < 0.01:
		away = Vector2.RIGHT
	else:
		away = away.normalized()
	var stand: float = maxf(attack_range, 1.0) * 0.85
	return enemy + away * stand


static func keep_target(target_alive: bool) -> bool:
	return target_alive


static func stalemate_break(elapsed_sec: float, limit_sec: float, hp_changed: bool) -> bool:
	## Close fight with no HP change is stuck. A hit resets the clock.
	if hp_changed:
		return false
	return elapsed_sec >= limit_sec
