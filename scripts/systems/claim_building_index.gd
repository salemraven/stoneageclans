extends Node
# Runtime index: clan_name -> buildings in that claim. O(1) lookup instead of iterating all buildings.
# Register when building placed, unregister when building destroyed.

var _buildings_by_clan: Dictionary = {}  # clan_name (String) -> Array[BuildingBase]
var _building_to_clan: Dictionary = {}  # building (ref) -> clan_name (for unregister)


func register_building(building: BuildingBase, claim: LandClaim) -> void:
	if not building or not claim:
		return
	var clan: String = claim.clan_name if "clan_name" in claim else ""
	if clan.is_empty():
		return
	if not _buildings_by_clan.has(clan):
		_buildings_by_clan[clan] = []
	var arr: Array = _buildings_by_clan[clan]
	if building in arr:
		return
	arr.append(building)
	_building_to_clan[building] = clan


func unregister_building(building: BuildingBase) -> void:
	if not _building_to_clan.has(building):
		return
	var clan: String = _building_to_clan[building]
	_building_to_clan.erase(building)
	if _buildings_by_clan.has(clan):
		var arr: Array = _buildings_by_clan[clan]
		arr.erase(building)


func get_buildings_in_claim(claim: Node) -> Array:
	if not claim or not is_instance_valid(claim):
		return []
	# Campfire has no buildings in the index - only LandClaim has registered buildings
	if not (claim is LandClaim):
		return []
	var clan: String = claim.clan_name if "clan_name" in claim else ""
	if clan.is_empty():
		return []
	if not _buildings_by_clan.has(clan):
		return []
	var arr: Array = _buildings_by_clan[clan]
	# Filter out freed buildings
	var valid: Array = []
	for b in arr:
		if is_instance_valid(b) and b is BuildingBase:
			valid.append(b)
	return valid


func invalidate_claim(claim: LandClaim) -> void:
	if not claim:
		return
	var clan: String = claim.clan_name if "clan_name" in claim else ""
	invalidate_by_clan(clan)


func invalidate_by_clan(clan_name: String) -> void:
	if clan_name.is_empty():
		return
	_buildings_by_clan.erase(clan_name)
	var to_remove: Array = []
	for building in _building_to_clan:
		if _building_to_clan[building] == clan_name:
			to_remove.append(building)
	for b in to_remove:
		_building_to_clan.erase(b)


func _on_claim_destroyed(clan_name: String) -> void:
	invalidate_by_clan(clan_name)
