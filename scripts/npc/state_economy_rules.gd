extends Object
class_name StateEconomyRules

## Shared economy rules for FSM states (fighter counts, craft vs gather). Server-safe; no autoload.

static func count_fighters_in_clan(npc: Node) -> int:
	"""Male fighters in this clan (caveman or clansman). Matches craft_state / ClanBrain semantics."""
	if not npc:
		return 0
	var clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.get("clan_name") as String if npc.get("clan_name") != null else "")
	if clan == "":
		return 0
	var tree: SceneTree = npc.get_tree() if npc else null
	if not tree:
		return 0
	var count: int = 0
	for n in tree.get_nodes_in_group("npcs"):
		if not is_instance_valid(n):
			continue
		var nclan: String = n.get_clan_name() if n.has_method("get_clan_name") else (n.get("clan_name") as String if n.get("clan_name") != null else "")
		if nclan != clan:
			continue
		var nt: String = n.get("npc_type") if "npc_type" in n else ""
		if nt == "caveman" or nt == "clansman":
			count += 1
	return count


static func should_deprioritize_craft_vs_gather(npc: Node) -> bool:
	"""True when craft should not outrank gather (tiny clan economy)."""
	if not NPCConfig:
		return true
	var need: int = NPCConfig.min_fighters_for_craft_priority_over_gather as int
	return count_fighters_in_clan(npc) < need
