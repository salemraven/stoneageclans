extends SceneTree

const BuildingScene = preload("res://scenes/Building.tscn")
const NPCScene = preload("res://scenes/NPC.tscn")
const LandClaimScript = preload("res://scripts/land_claim.gd")

const START_HEALTH := 100.0


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_BUILDING_MELEE_DAMAGE_FAIL: %s" % msg)
	quit(1)


func _run() -> void:
	await process_frame
	var root_node := get_root()

	# --- Direct take_damage (building + land claim) ---
	var building: BuildingBase = BuildingScene.instantiate() as BuildingBase
	building.building_type = ResourceData.ResourceType.LIVING_HUT
	building.clan_name = "ENEMY"
	building.player_owned = false
	building.current_health = START_HEALTH
	root_node.add_child(building)
	await process_frame

	building.take_damage(15.0)
	if not is_equal_approx(building.current_health, 85.0):
		_fail("BuildingBase take_damage expected 85 got %.1f" % building.current_health)
	var bar: Control = building.get_node_or_null("HealthBar") as Control
	if bar == null or not bar.visible:
		_fail("Building health bar should show after damage")

	var claim := Node2D.new()
	claim.set_script(LandClaimScript)
	claim.set("clan_name", "ENEMY_CLAN")
	claim.set("player_owned", false)
	claim.set("decay_health", START_HEALTH)
	root_node.add_child(claim)
	await process_frame
	if not claim.has_method("take_damage"):
		_fail("LandClaim missing take_damage")
	claim.call("take_damage", 20.0)
	var claim_health: float = float(claim.get("decay_health"))
	if not is_equal_approx(claim_health, 80.0):
		_fail("LandClaim take_damage expected 80 got %.1f" % claim_health)
	var claim_bar: Control = claim.get_node_or_null("HealthBar") as Control
	if claim_bar == null or not claim_bar.visible:
		_fail("Land claim health bar should show after damage")

	# --- Combat validation must accept buildings (no HealthComponent) ---
	var npc: Node = NPCScene.instantiate()
	npc.set("npc_type", "caveman")
	npc.set("npc_name", "RAIDER")
	npc.set("clan_name", "RAIDERS")
	root_node.add_child(npc)
	await process_frame

	var weapon_comp: Node = npc.get_node_or_null("WeaponComponent")
	if weapon_comp and weapon_comp.has_method("equip_weapon"):
		weapon_comp.equip_weapon(ResourceData.ResourceType.SPEAR)
	var svc = root_node.get_node_or_null("/root/PlaceholderCardService")
	if svc:
		svc.apply_to_npc(npc)

	var combat: CombatComponent = npc.get_node_or_null("CombatComponent") as CombatComponent
	if combat == null:
		_fail("NPC CombatComponent missing")

	building.current_health = START_HEALTH
	building.global_position = Vector2(70.0, 0.0)
	npc.global_position = Vector2(0.0, 0.0)
	var npc_sprite: Sprite2D = npc.get_node_or_null("Sprite") as Sprite2D
	if npc_sprite:
		npc_sprite.flip_h = false
	await process_frame

	combat.enter_ready(Vector2(1.0, 0.0))
	if combat.state != CombatComponent.CombatState.READY:
		_fail("NPC should enter READY with spear equipped")

	if combat._hit_validation_failure_reason(building) != "":
		_fail("Building should pass hit validation, got: %s" % combat._hit_validation_failure_reason(building))

	# --- Full overlay strike from NPC ---
	combat.commit_strike(Vector2(1.0, 0.0))
	if combat.current_target != building:
		_fail("Strike should target building, got %s" % str(combat.current_target))

	await create_timer(0.35).timeout
	if is_equal_approx(building.current_health, START_HEALTH):
		_fail("Building health unchanged after melee strike (still %.1f)" % building.current_health)
	if building.current_health >= START_HEALTH:
		_fail("Building should have lost health after strike")

	print("TEST_BUILDING_MELEE_DAMAGE_OK")
	quit(0)
