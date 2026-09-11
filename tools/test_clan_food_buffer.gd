extends SceneTree
## Headless: ClanFoodBuffer pantry days (single ruler) + claim meta publish.

const ClanFoodBufferScript = preload("res://scripts/systems/clan_food_buffer.gd")
const SettlementRosterScript = preload("res://scripts/systems/settlement_roster.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_pantry_days_formula()
	_test_publish_unifies_metas()
	_test_roster_daily_need()
	print("=== CLAN_FOOD_BUFFER_TEST done: passed=%d failed=%d ===" % [_passed, _failed])
	quit()


func _test_pantry_days_formula() -> void:
	var days: float = ClanFoodBufferScript.pantry_days_from_calories(2200, 2200)
	if days >= 0.99 and days <= 1.01:
		_pass("pantry_days formula: 2200 kcal / 2200 need ≈ 1.0 day")
	else:
		_fail("pantry_days formula", "days=%.2f" % days)


func _test_publish_unifies_metas() -> void:
	var claim := LandClaim.new()
	var inv := InventoryData.new()
	inv.add_item(ResourceData.ResourceType.BERRIES, 20)
	claim.inventory = inv
	var roster := SettlementRosterScript.new()
	roster.members.append({
		"id": 1, "type": "leader", "alive": true, "name": "L",
	})
	var metrics: Dictionary = ClanFoodBufferScript.compute(claim, roster, [])
	ClanFoodBufferScript.publish_to_claim(claim, metrics)
	var food_meta: float = float(claim.get_meta("food_days_buffer"))
	var cal_meta: float = float(claim.get_meta("calories_days_buffer"))
	if absf(food_meta - cal_meta) < 0.001 and absf(food_meta - float(metrics.get("pantry_days", -1.0))) < 0.001:
		_pass("food_days_buffer meta matches calories_days_buffer and compute")
	else:
		_fail("meta unify", "food=%.3f cal=%.3f pantry=%.3f" % [food_meta, cal_meta, metrics.get("pantry_days", -1.0)])
	claim.free()


func _test_roster_daily_need() -> void:
	var roster := SettlementRosterScript.new()
	roster.members.append({"id": 1, "type": "leader", "alive": true})
	roster.members.append({"id": 2, "type": "woman", "alive": true})
	var daily: int = ClanFoodBufferScript.daily_need_from_roster(roster)
	if daily == 2200 + 1800:
		_pass("roster daily need sums member types")
	else:
		_fail("roster daily need", "got %d expected 4000" % daily)


func _pass(label: String) -> void:
	_passed += 1
	print("CLAN_FOOD_BUFFER_PASS: %s" % label)


func _fail(label: String, detail: String = "") -> void:
	_failed += 1
	if detail.is_empty():
		print("CLAN_FOOD_BUFFER_FAIL: %s" % label)
	else:
		print("CLAN_FOOD_BUFFER_FAIL: %s — %s" % [label, detail])
