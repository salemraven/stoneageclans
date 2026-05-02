extends Object

## Shared RTS formation tuning (main.gd + party_state.gd + FormationUtils); load via preload(...).RTS_CONFIG
const RTS_CONFIG := {
	"rally_radius": 1500.0,
	"war_horn_cooldown": 0.35,
	"break_herd_cooldown": 8.0,
	# After Break: max wall-clock time to keep steering home (arrival clears earlier).
	"break_return_max_sec": 300.0,
	"ordered_leash_max": 1200.0,
	"leash_tight_px": 40.0,
	"leash_loose_px": 160.0,
	"leash_min_mult": 0.4,
	"slot_settled_dist": 35.0,
	"catchup_speed_mult": 2.0,
	"backing_dist": 10.0,
	"backing_target_dist": 30.0,
	"formation_lookahead_px": 80.0,
	"leader_move_speed_sq": 4.0,  # 2 px/frame equivalent threshold squared
	"rts_snapshot_interval": 5.0,
	# Player-led formation: soft dead zone on **world X** (east/west — same axis as left/right arrows).
	"formation_world_deadzone_x_px": 28.0,
	# FOLLOW: rear arc behind leader (facing-relative); radius and half-angle of the arc.
	"follow_formation_ideal_dist_px": 130.0,
	"follow_formation_arc_half_rad": 1.047197551,  # PI/3 (~60° each side of straight back)
	# ATTACK: line ahead of leader along facing, spread perpendicular (not world-X-only).
	"attack_formation_forward_px": 120.0,
	"attack_formation_lateral_spacing_px": 60.0,
	# ARC: curved formation ahead of leader (same forward anchor as attack).
	"arc_formation_span_deg": 120.0,
	# STALK: wider rear arc + slightly farther slots than FOLLOW.
	"stalk_formation_arc_half_rad": 1.57079632679,
	"stalk_formation_dist_mult": 1.08,
}
