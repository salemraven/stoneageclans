extends Area2D
class_name GrassBugPatch
## Lightweight sim marker for forageable bugs — visual grass is in GrassBatch MultiMesh.

var decor_kind: StringName = &"grass_bug"
var stable_id: String = ""
var bugs_remaining: int = 1
var chunk_coords: Vector2i = Vector2i.ZERO


func setup(world_pos: Vector2, sid: String, chunk: Vector2i, charges: int = 1) -> void:
	position = world_pos
	stable_id = sid
	chunk_coords = chunk
	bugs_remaining = maxi(1, charges)
	set_meta(&"stable_id", sid)
	set_meta(&"chunk_coords", chunk)
	set_meta(&"has_bugs", true)
	set_meta(&"bugs_remaining", bugs_remaining)


func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)
	call_deferred("_register_decor")


func _register_decor() -> void:
	if DecorIndex and is_inside_tree():
		DecorIndex.register(self)


func _exit_tree() -> void:
	if DecorIndex:
		DecorIndex.unregister(self)


func is_forageable() -> bool:
	return bugs_remaining > 0 and not _is_depleted()


func _is_depleted() -> bool:
	return MutationStore != null and stable_id != "" and MutationStore.is_depleted(stable_id)


func consume_one() -> bool:
	if not is_forageable():
		return false
	bugs_remaining -= 1
	set_meta(&"bugs_remaining", bugs_remaining)
	if bugs_remaining <= 0:
		_mark_depleted()
	return true


func force_deplete() -> void:
	bugs_remaining = 0
	_mark_depleted()
	queue_free()


func _mark_depleted() -> void:
	if MutationStore and stable_id != "":
		MutationStore.deplete_stable_id(stable_id)
	remove_meta(&"has_bugs")
	if has_meta(&"bugs_remaining"):
		remove_meta(&"bugs_remaining")
