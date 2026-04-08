extends Object

## Shared RTS formation tuning (main.gd + party_state.gd + FormationUtils); load via preload(...).RTS_CONFIG
const RTS_CONFIG := {
	"rally_radius": 1500.0,
	"war_horn_cooldown": 0.35,
	"break_herd_cooldown": 8.0,
	"break_return_boost_sec": 15.0,
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
}
