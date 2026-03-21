extends Node

# Competition Tracker - Tracks items deposited by each caveman and per-clan totals
# Singleton to track competition stats across all NPCs

var caveman_stats: Dictionary = {}  # {npc_name: {"items_deposited": int, "npcs_herded": int, "clan_name": String, "resources": {ResourceType: int}}}
# Clan-level aggregation: {clan_name: {total_items: int, resources: {ResourceType: int}}}
var clan_deposits: Dictionary = {}

func _ready() -> void:
	add_to_group("competition_tracker")
	print("🏆 Competition Tracker initialized (tracking deposits by resource type and per clan)")

func record_deposit(npc_name: String, clan_name: String, item_type: ResourceData.ResourceType, item_count: int) -> void:
	if not caveman_stats.has(npc_name):
		caveman_stats[npc_name] = {
			"items_deposited": 0,
			"npcs_herded": 0,
			"clan_name": clan_name,
			"resources": {}
		}
	
	caveman_stats[npc_name]["items_deposited"] += item_count
	caveman_stats[npc_name]["clan_name"] = clan_name
	
	# Track by resource type
	if not caveman_stats[npc_name]["resources"].has(item_type):
		caveman_stats[npc_name]["resources"][item_type] = 0
	caveman_stats[npc_name]["resources"][item_type] += item_count
	
	# Clan-level instrumentation: aggregate deposits per clan
	if clan_name != "":
		if not clan_deposits.has(clan_name):
			clan_deposits[clan_name] = {"total_items": 0, "resources": {}}
		clan_deposits[clan_name]["total_items"] += item_count
		if not clan_deposits[clan_name]["resources"].has(item_type):
			clan_deposits[clan_name]["resources"][item_type] = 0
		clan_deposits[clan_name]["resources"][item_type] += item_count
	
	var total_deposited: int = caveman_stats[npc_name]["items_deposited"]
	var _resource_total: int = caveman_stats[npc_name]["resources"][item_type]
	var resource_name: String = ResourceData.get_resource_name(item_type)
	
	var leaderboard = get_leaderboard()
	var rank: int = 1
	for i in range(leaderboard.size()):
		if leaderboard[i][0] == npc_name:
			rank = i + 1
			break
	
	# Get rank for this specific resource type
	var resource_leaderboard = get_resource_leaderboard(item_type)
	var resource_rank: int = 1
	for i in range(resource_leaderboard.size()):
		if resource_leaderboard[i][0] == npc_name:
			resource_rank = i + 1
			break
	
	print("📊 Competition: %s (%s) deposited %d %s → Total: %d items (Overall Rank: #%d, %s Rank: #%d)" % [
		npc_name, 
		clan_name, 
		item_count,
		resource_name,
		total_deposited,
		rank,
		resource_name,
		resource_rank
	])

func record_herding_delivery(herder_name: String, clan_name: String, npc_type: String) -> void:
	if not caveman_stats.has(herder_name):
		caveman_stats[herder_name] = {
			"items_deposited": 0,
			"npcs_herded": 0,
			"clan_name": clan_name,
			"resources": {}
		}
	caveman_stats[herder_name]["npcs_herded"] += 1
	caveman_stats[herder_name]["clan_name"] = clan_name
	var total_herded: int = caveman_stats[herder_name]["npcs_herded"]
	var herd_leaderboard = get_herding_leaderboard()
	var rank: int = 1
	for i in range(herd_leaderboard.size()):
		if herd_leaderboard[i][0] == herder_name:
			rank = i + 1
			break
	print("📊 Competition: %s (%s) herded 1 %s → Total: %d NPCs herded (Herding Rank: #%d)" % [
		herder_name, clan_name, npc_type, total_herded, rank
	])

func get_herding_leaderboard() -> Array:
	var entries: Array = []
	for npc_name in caveman_stats:
		var stats = caveman_stats[npc_name]
		var count: int = stats.get("npcs_herded", 0)
		if count > 0:
			entries.append([npc_name, stats])
	entries.sort_custom(func(a, b): return a[1]["npcs_herded"] > b[1]["npcs_herded"])
	return entries

func get_leaderboard() -> Array:
	# Returns sorted array of [npc_name, stats] tuples, highest first
	var entries: Array = []
	for npc_name in caveman_stats:
		entries.append([npc_name, caveman_stats[npc_name]])
	
	# Sort by items_deposited (descending)
	entries.sort_custom(func(a, b): return a[1]["items_deposited"] > b[1]["items_deposited"])
	return entries

func get_winner() -> Dictionary:
	var leaderboard = get_leaderboard()
	if leaderboard.is_empty():
		return {}
	
	var winner_name = leaderboard[0][0]
	var winner_stats = leaderboard[0][1]
	
	return {
		"npc_name": winner_name,
		"clan_name": winner_stats["clan_name"],
		"items_deposited": winner_stats["items_deposited"]
	}

func get_resource_leaderboard(resource_type: ResourceData.ResourceType) -> Array:
	# Returns sorted array of [npc_name, count] tuples for a specific resource type, highest first
	var entries: Array = []
	for npc_name in caveman_stats:
		var stats = caveman_stats[npc_name]
		var resources = stats.get("resources", {})
		var count = resources.get(resource_type, 0)
		if count > 0:
			entries.append([npc_name, count])
	
	# Sort by count (descending)
	entries.sort_custom(func(a, b): return a[1] > b[1])
	return entries

func get_resource_winner(resource_type: ResourceData.ResourceType) -> Dictionary:
	var leaderboard = get_resource_leaderboard(resource_type)
	if leaderboard.is_empty():
		return {}
	
	var winner_name = leaderboard[0][0]
	var winner_count = leaderboard[0][1]
	var winner_stats = caveman_stats[winner_name]
	
	return {
		"npc_name": winner_name,
		"clan_name": winner_stats["clan_name"],
		"count": winner_count,
		"resource_type": resource_type
	}

## Returns deposits aggregated by clan. Dict: {clan_name: {total_items: int, resources: {ResourceType: int}}}
func get_clan_deposits() -> Dictionary:
	return clan_deposits.duplicate(true)

## Log deposits per clan to console
func print_clan_deposits() -> void:
	if clan_deposits.is_empty():
		print("📦 Clan deposits: No deposits recorded yet")
		return
	var sep = "============================================================"
	print("")
	print(sep)
	print("📦 DEPOSITS PER CLAN")
	print(sep)
	var resource_types = [
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.GRAIN,
		ResourceData.ResourceType.WHEAT,
		ResourceData.ResourceType.FIBER
	]
	for clan_name in clan_deposits:
		var data = clan_deposits[clan_name]
		var total: int = data.get("total_items", 0)
		var parts: Array[String] = []
		for rt in resource_types:
			var count = data.get("resources", {}).get(rt, 0)
			if count > 0:
				parts.append("%s: %d" % [ResourceData.get_resource_name(rt), count])
		print("  %s: %d total (%s)" % [clan_name, total, ", ".join(parts)])
	print(sep)

func print_leaderboard() -> void:
	var leaderboard = get_leaderboard()
	if leaderboard.is_empty():
		print("🏆 Competition: No deposits recorded yet")
		return
	
	var separator = "============================================================"
	print("")
	print(separator)
	print("🏆 COMPETITION LEADERBOARD - TOTAL ITEMS")
	print(separator)
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		var npc_name = entry[0]
		var stats = entry[1]
		var rank_emoji = "🥇" if i == 0 else ("🥈" if i == 1 else ("🥉" if i == 2 else "  "))
		var herded: int = stats.get("npcs_herded", 0)
		var line: String = "%s %d. %s (%s): %d items" % [
			rank_emoji, i + 1, npc_name, stats["clan_name"], stats["items_deposited"]
		]
		if herded > 0:
			line += ", %d herded" % herded
		print(line)
	print(separator)
	
	# Print resource-specific leaderboards
	print("")
	print(separator)
	print("🏆 RESOURCE-SPECIFIC LEADERBOARDS")
	print(separator)
	
	var resource_types = [
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.STONE,
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.WHEAT,
		ResourceData.ResourceType.FIBER
	]
	
	for resource_type in resource_types:
		var resource_leaderboard = get_resource_leaderboard(resource_type)
		if resource_leaderboard.is_empty():
			continue
		
		var resource_name = ResourceData.get_resource_name(resource_type)
		print("")
		print("📦 %s:" % resource_name)
		for i in range(min(resource_leaderboard.size(), 4)):  # Show top 4
			var entry = resource_leaderboard[i]
			var npc_name = entry[0]
			var count = entry[1]
			var stats = caveman_stats[npc_name]
			var rank_emoji = "🥇" if i == 0 else ("🥈" if i == 1 else ("🥉" if i == 2 else "  "))
			print("  %s %d. %s (%s): %d %s" % [
				rank_emoji,
				i + 1,
				npc_name,
				stats["clan_name"],
				count,
				resource_name
			])
	
	print(separator)

	# Herding leaderboard
	var herd_leaderboard = get_herding_leaderboard()
	if not herd_leaderboard.is_empty():
		print("")
		print(separator)
		print("🐑 HERDING LEADERBOARD")
		print(separator)
		for i in range(min(herd_leaderboard.size(), 6)):
			var entry = herd_leaderboard[i]
			var npc_name = entry[0]
			var stats = entry[1]
			var rank_emoji = "🥇" if i == 0 else ("🥈" if i == 1 else ("🥉" if i == 2 else "  "))
			print("%s %d. %s (%s): %d NPCs herded" % [
				rank_emoji, i + 1, npc_name, stats["clan_name"], stats["npcs_herded"]
			])
		print(separator)
	
	var winner = get_winner()
	if winner:
		print("")
		var items: int = winner.get("items_deposited", 0)
		var herd_leaderboard_entries = get_herding_leaderboard()
		var herd_count: int = herd_leaderboard_entries[0][1]["npcs_herded"] if not herd_leaderboard_entries.is_empty() else 0
		print("🏆 GATHERING WINNER: %s (%s) with %d items!" % [winner["npc_name"], winner["clan_name"], items])
		if herd_count > 0:
			print("🐑 HERDING WINNER: %s (%s) with %d NPCs herded!" % [
				herd_leaderboard_entries[0][0], herd_leaderboard_entries[0][1]["clan_name"], herd_count
			])
		print("")
	# Playtest: emit competition_complete with structured data
	var pi = get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("competition_complete"):
		var data: Dictionary = {}
		var gw = get_winner()
		if gw:
			data["gathering_winner"] = gw["npc_name"]
			data["gathering_clan"] = gw["clan_name"]
			data["gathering_items"] = gw["items_deposited"]
		var hl = get_herding_leaderboard()
		if not hl.is_empty():
			data["herding_winner"] = hl[0][0]
			data["herding_clan"] = hl[0][1]["clan_name"]
			data["herding_count"] = hl[0][1]["npcs_herded"]
		var cd = get_clan_deposits()
		if not cd.is_empty():
			var deposits_serializable: Dictionary = {}
			for cname in cd:
				var d = cd[cname]
				deposits_serializable[cname] = {"total": d.get("total_items", 0)}
				var res = d.get("resources", {})
				if not res.is_empty() and ResourceData:
					var res_str: Dictionary = {}
					for rt in res:
						res_str[ResourceData.get_resource_name(rt)] = res[rt]
					deposits_serializable[cname]["resources"] = res_str
			data["clan_deposits"] = deposits_serializable
		pi.competition_complete(data)

