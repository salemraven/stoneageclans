extends RefCounted
class_name ClubWindupMotion

## Club windup idle loop — rest → key A → key B → rest.
## Isolated from walk/gather/spear idle motion.

const DEFAULT_CYCLE_SEC := 5.0


static func cycle_phase(cycle_time: float, cycle_sec: float) -> float:
	if cycle_sec <= 0.001:
		return 0.0
	return fposmod(cycle_time, cycle_sec) / cycle_sec


## 0–1 blend weights for rest, A, B segments (equal thirds + rest bookends).
static func segment_weights(phase: float) -> Dictionary:
	var p := clampf(phase, 0.0, 1.0)
	var rest_w := 0.0
	var a_w := 0.0
	var b_w := 0.0
	if p < 0.25:
		rest_w = 1.0 - smoothstep(0.0, 0.25, p)
		a_w = smoothstep(0.0, 0.25, p)
	elif p < 0.5:
		var t := (p - 0.25) / 0.25
		a_w = 1.0 - smoothstep(0.0, 1.0, t)
		b_w = smoothstep(0.0, 1.0, t)
	elif p < 0.75:
		b_w = 1.0 - smoothstep(0.0, 0.25, (p - 0.5) / 0.25)
		rest_w = smoothstep(0.0, 0.25, (p - 0.5) / 0.25)
	else:
		rest_w = 1.0
	var total := rest_w + a_w + b_w
	if total < 0.001:
		return {"rest": 1.0, "a": 0.0, "b": 0.0}
	return {"rest": rest_w / total, "a": a_w / total, "b": b_w / total}


static func blend_vec3(rest: Vector2, a: Vector2, b: Vector2, weights: Dictionary) -> Vector2:
	return (
		rest * float(weights.get("rest", 0.0))
		+ a * float(weights.get("a", 0.0))
		+ b * float(weights.get("b", 0.0))
	)
