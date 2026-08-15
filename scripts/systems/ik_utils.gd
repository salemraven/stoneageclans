class_name IKUtils

## Pure IK calculation utilities — no state, no side effects.
## Any animation can safely use these functions.

## Calculate elbow position using pole-pick IK.
## Returns elbow global position based on shoulder, hand, and pole positions.
static func calculate_elbow_from_pole(
	shoulder_global: Vector2,
	hand_global: Vector2,
	pole_global: Vector2,
	upper_length: float,
	lower_length: float
) -> Vector2:
	var reach := shoulder_global.distance_to(hand_global)
	var total_length := upper_length + lower_length
	
	# If unreachable, extend straight toward hand
	if reach >= total_length - 0.01:
		var dir := (hand_global - shoulder_global).normalized()
		return shoulder_global + dir * upper_length
	
	# Use pole to determine elbow side
	var mid := (shoulder_global + hand_global) * 0.5
	var line_dir := (hand_global - shoulder_global).normalized()
	var perp := Vector2(-line_dir.y, line_dir.x)
	
	# Project pole onto perpendicular to get side preference
	var pole_offset := pole_global - mid
	var side_sign := signf(pole_offset.dot(perp))
	if abs(side_sign) < 0.01:
		side_sign = 1.0
	
	# Calculate elbow offset from line using triangle math
	var half_reach := reach * 0.5
	var elbow_offset_sq := upper_length * upper_length - half_reach * half_reach
	if elbow_offset_sq < 0.0:
		elbow_offset_sq = 0.0
	
	var elbow_offset := sqrt(elbow_offset_sq)
	return mid + perp * side_sign * elbow_offset


## Calculate elbow using bend sign (fallback when no pole).
## Returns elbow global position based on shoulder, hand, and bend direction.
static func calculate_elbow_from_bend_sign(
	shoulder_global: Vector2,
	hand_global: Vector2,
	bend_sign: float,
	upper_length: float,
	lower_length: float
) -> Vector2:
	var reach := shoulder_global.distance_to(hand_global)
	var total_length := upper_length + lower_length
	
	# If unreachable, extend straight
	if reach >= total_length - 0.01:
		var dir := (hand_global - shoulder_global).normalized()
		return shoulder_global + dir * upper_length
	
	# Calculate elbow offset perpendicular to shoulder-hand line
	var mid := (shoulder_global + hand_global) * 0.5
	var line_dir := (hand_global - shoulder_global).normalized()
	var perp := Vector2(-line_dir.y, line_dir.x)
	
	var half_reach := reach * 0.5
	var elbow_offset_sq := upper_length * upper_length - half_reach * half_reach
	if elbow_offset_sq < 0.0:
		elbow_offset_sq = 0.0
	
	var elbow_offset := sqrt(elbow_offset_sq)
	return mid + perp * bend_sign * elbow_offset


## Derive bend sign from pole position relative to shoulder-hand line.
## Returns 1.0 or -1.0 based on which side of the line the pole is on.
static func derive_bend_sign_from_pole(
	shoulder_global: Vector2,
	hand_global: Vector2,
	pole_global: Vector2
) -> float:
	var mid := (shoulder_global + hand_global) * 0.5
	var line_dir := (hand_global - shoulder_global).normalized()
	var perp := Vector2(-line_dir.y, line_dir.x)
	
	var pole_offset := pole_global - mid
	var dot := pole_offset.dot(perp)
	
	if abs(dot) < 0.01:
		return 1.0
	return signf(dot)


## Interpolate between two elbow positions using a blend factor.
## Returns interpolated elbow position (0.0 = from, 1.0 = to).
static func lerp_elbow_positions(
	from_elbow: Vector2,
	to_elbow: Vector2,
	blend: float
) -> Vector2:
	return from_elbow.lerp(to_elbow, clampf(blend, 0.0, 1.0))


## Check if a target position is reachable from shoulder with given arm lengths.
## Returns true if hand can reach target without over-extension.
static func is_reachable(
	shoulder_global: Vector2,
	target_global: Vector2,
	upper_length: float,
	lower_length: float,
	slack: float = 0.01
) -> bool:
	var reach := shoulder_global.distance_to(target_global)
	var total_length := upper_length + lower_length
	return reach <= total_length - slack


## Calculate bezier point for elbow arc animation.
## Returns point on quadratic bezier curve (0.0 = start, 1.0 = end).
static func bezier_point(
	start: Vector2,
	control: Vector2,
	end: Vector2,
	t: float
) -> Vector2:
	var t_clamped := clampf(t, 0.0, 1.0)
	var one_minus_t := 1.0 - t_clamped
	return one_minus_t * one_minus_t * start + \
		   2.0 * one_minus_t * t_clamped * control + \
		   t_clamped * t_clamped * end
