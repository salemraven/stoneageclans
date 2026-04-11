extends "res://scripts/npc/states/base_state.gd"

# Build Hut For Woman - Herder builds Living Hut when woman joins clan (campfire or land claim)
# 20s timer, then spawn hut and assign woman

const BUILD_DURATION: float = 20.0
const MAX_DISTANCE_FROM_CLAIM: float = 150.0  # Cancel if herder moves too far from claim center

var woman: Node = null
var claim: Node = null  # Campfire or LandClaim (claim where woman joined)
var build_timer: float = 0.0

func enter() -> void:
	build_timer = 0.0
	woman = npc.get_meta("build_hut_for_woman") if npc.has_meta("build_hut_for_woman") else null
	# Use stored claim (where woman joined) - herder may be from different clan
	claim = npc.get_meta("build_hut_for_woman_claim") if npc.has_meta("build_hut_for_woman_claim") else null
	if not claim or not is_instance_valid(claim):
		claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	# Validate woman before starting
	if woman and not is_instance_valid(woman):
		woman = null
	if woman and OccupationSystem and OccupationSystem.get_workplace(woman) != null:
		woman = null  # Already in a hut
	if npc and npc.progress_display:
		var icon_path: String = ResourceData.get_resource_icon_path(ResourceData.ResourceType.LIVING_HUT)
		var icon: Texture2D = load(icon_path) as Texture2D if icon_path else null
		npc.progress_display.collection_time = BUILD_DURATION
		npc.progress_display.start_collection(icon)

func exit() -> void:
	if npc and npc.progress_display:
		npc.progress_display.stop_collection()
	woman = null
	claim = null

func update(delta: float) -> void:
	if not npc:
		return
	if not claim or not is_instance_valid(claim):
		_fail_and_exit()
		return
	# Cancel if herder moved too far from claim center
	var dist: float = npc.global_position.distance_to(claim.global_position)
	if dist > MAX_DISTANCE_FROM_CLAIM:
		_fail_and_exit()
		return
	# Validate woman still valid
	if woman:
		if not is_instance_valid(woman):
			woman = null
		elif OccupationSystem and OccupationSystem.get_workplace(woman) != null:
			woman = null
	build_timer += delta
	if build_timer >= BUILD_DURATION:
		_finish_build()

func can_enter() -> bool:
	if not npc:
		return false
	if npc.get("npc_type") != "caveman" and npc.get("npc_type") != "clansman":
		return false
	if not npc.has_meta("build_hut_for_woman"):
		return false
	var c = npc.get_meta("build_hut_for_woman")
	if not c or not is_instance_valid(c):
		return false
	# Must be inside claim (campfire or land claim) where woman joined
	var the_claim: Node = npc.get_meta("build_hut_for_woman_claim") if npc.has_meta("build_hut_for_woman_claim") else null
	if not the_claim or not is_instance_valid(the_claim):
		the_claim = npc.get_my_land_claim() if npc.has_method("get_my_land_claim") else null
	if not the_claim or not is_instance_valid(the_claim):
		return false
	var claim_pos: Vector2 = the_claim.global_position
	var radius: float = the_claim.get("radius") if the_claim.get("radius") != null else 400.0
	var dist: float = npc.global_position.distance_to(claim_pos)
	return dist <= radius

func get_priority() -> float:
	return 12.5  # Above herd_wildnpc (12) so timed hut build runs after delivery if FSM evaluates

func _fail_and_exit() -> void:
	if npc:
		npc.remove_meta("build_hut_for_woman")
		npc.remove_meta("build_hut_for_woman_claim")
	if fsm:
		fsm.change_state("wander")

func _finish_build() -> void:
	var main = get_tree().get_first_node_in_group("main")
	if not main or not main.has_method("_place_herder_hut"):
		_fail_and_exit()
		return
	main._place_herder_hut(claim, woman, npc)
	npc.remove_meta("build_hut_for_woman")
	npc.remove_meta("build_hut_for_woman_claim")
	if fsm:
		fsm.change_state("wander")
