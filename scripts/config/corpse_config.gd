extends Node

# Autoload: CorpseConfig - Yields per NPC type when butchered (meat, hide, bone)
static var YIELDS: Dictionary = {
	"sheep": {"meat": 2, "hide": 1, "bone": 0},
	"goat": {"meat": 2, "hide": 1, "bone": 0},
	"woman": {"meat": 2, "hide": 1, "bone": 2},
	"caveman": {"meat": 3, "hide": 1, "bone": 2},
	"clansman": {"meat": 3, "hide": 1, "bone": 2},
	"baby": {"meat": 0, "hide": 0, "bone": 0},
}

static func get_yields(npc_type: String) -> Dictionary:
	return YIELDS.get(npc_type.to_lower(), {"meat": 0, "hide": 0, "bone": 0})
