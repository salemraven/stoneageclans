extends Node
## Minimal Main stand-in for inventory validation tests.

var player: Node2D = null
var player_inventory_ui: Node = null


func _ready() -> void:
	add_to_group("main")
	player = Node2D.new()
	player.name = "TestPlayer"
	add_child(player)
