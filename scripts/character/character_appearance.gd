extends Resource
class_name CharacterAppearance
## Serializable character appearance data for body proportions, weapon, preset, hair, and future outfit/color customization.

@export var preset_id: String = ""
@export var body_proportion_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var weapon_id: String = ""
@export var hair_id: String = ""
# Future: @export var outfit_slots: Dictionary, @export var paint_color: Color


func save_to_file(path: String) -> void:
	var err := ResourceSaver.save(self, path)
	if err != OK:
		push_error("CharacterAppearance: save failed to %s (err %d)" % [path, err])


static func load_from_file(path: String) -> CharacterAppearance:
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path) as CharacterAppearance
		if res == null:
			push_error("CharacterAppearance: load failed from %s" % path)
		return res
	return null
