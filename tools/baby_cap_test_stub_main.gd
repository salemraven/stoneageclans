extends Node
## Minimal Main stand-in for headless baby cap tests.

var baby_pool_manager: BabyPoolManager = null
var spawn_calls: int = 0


func _ready() -> void:
	add_to_group("main")
	baby_pool_manager = BabyPoolManager.new()
	baby_pool_manager.name = "BabyPoolManager"
	add_child(baby_pool_manager)


func get_baby_pool_manager() -> BabyPoolManager:
	return baby_pool_manager


func _spawn_baby(_clan_name: String, _spawn_pos: Vector2, _mother: NPCBase, _father: NPCBase = null) -> void:
	spawn_calls += 1
