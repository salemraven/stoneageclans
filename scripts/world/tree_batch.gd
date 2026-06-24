extends Node2D
class_name TreeBatch
## Batched decorative tree visuals (non-choppable backdrop).

const TREE_SHEET_PATH := "res://assets/sprites/environment/treess.png"


static func build(parent: Node2D, visual_trees: Array) -> TreeBatch:
	var batch := TreeBatch.new()
	batch.name = "TreeBatch"
	parent.add_child(batch)
	batch._build(visual_trees)
	return batch


func _build(trees: Array) -> void:
	var tex := AssetRegistry.get_treess_sprite() if AssetRegistry else load(TREE_SHEET_PATH) as Texture2D
	if tex == null:
		return
	var cols := 5
	var rows := 3
	var cell_w := tex.get_width() / cols
	var cell_h := tex.get_height() / rows
	var buckets: Dictionary = {}
	for desc in trees:
		if typeof(desc) != TYPE_DICTIONARY:
			continue
		var pos: Vector2 = desc.get("position", Vector2.ZERO) as Vector2
		if MutationStore and MutationStore.is_depleted(str(desc.get("stable_id", ""))):
			continue
		var tree_idx: int = clampi(int(desc.get("tree_idx", 0)), 0, 14)
		if not buckets.has(tree_idx):
			buckets[tree_idx] = []
		(buckets[tree_idx] as Array).append(desc)
	var sort_offset: float = YSortUtils.tree_sort_offset_y if YSortUtils else 240.0
	for tree_idx in buckets.keys():
		var list: Array = buckets[tree_idx] as Array
		if list.is_empty():
			continue
		var col: int = int(tree_idx) % cols
		var row: int = int(tree_idx) / cols
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
		atlas.filter_clip = true
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		mm.instance_count = list.size()
		var quad := QuadMesh.new()
		quad.size = Vector2(cell_w * 1.15, cell_h * 1.15)
		mm.mesh = quad
		var mmi := MultiMeshInstance2D.new()
		mmi.multimesh = mm
		mmi.texture = atlas
		var avg_y: float = 0.0
		for i in list.size():
			var desc: Dictionary = list[i] as Dictionary
			var pos: Vector2 = desc.get("position", Vector2.ZERO) as Vector2
			var foot := YSortUtils.get_tree_sprite_position_for_cell_height(cell_h, 1.15) if YSortUtils else Vector2(0, -cell_h * 0.575)
			var world := pos + Vector2(0, sort_offset)
			avg_y += world.y + foot.y + (cell_h * 1.15) * 0.5
			var xform := Transform2D.IDENTITY
			xform.origin = world + foot
			mm.set_instance_transform_2d(i, xform)
		if list.size() > 0:
			avg_y /= float(list.size())
			mmi.z_as_relative = false
			mmi.z_index = clampi(YSortUtils.Z_BASE + int(avg_y + sort_offset), YSortUtils.CANVAS_Z_MIN, YSortUtils.CANVAS_Z_MAX - 1) if YSortUtils else 2048
		add_child(mmi)
