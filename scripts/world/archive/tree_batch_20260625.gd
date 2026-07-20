extends Node2D
class_name TreeBatch
## Batched decorative tree visuals (non-choppable backdrop). Matches GatherableResource tree layout.

const TREE_SCALE := 1.15


static func build(parent: Node2D, visual_trees: Array) -> TreeBatch:
	var batch := TreeBatch.new()
	batch.name = "TreeBatch"
	parent.add_child(batch)
	batch._build(visual_trees)
	return batch


func _build(trees: Array) -> void:
	var tex := AssetRegistry.get_treess_sprite() if AssetRegistry else null
	if tex == null:
		return
	var cols := 5
	var rows := 3
	var cell_w: float = float(tex.get_width()) / float(cols)
	var cell_h: float = float(tex.get_height()) / float(rows)
	var foot_off_y: float = 0.0
	if YSortUtils:
		foot_off_y = YSortUtils.get_tree_sprite_position_for_cell_height(cell_h, TREE_SCALE).y
	var buckets: Dictionary = {}
	for desc in trees:
		if typeof(desc) != TYPE_DICTIONARY:
			continue
		var sid: String = str(desc.get("stable_id", ""))
		if MutationStore and sid != "" and MutationStore.is_depleted(sid):
			continue
		var pos: Vector2 = desc.get("position", Vector2.ZERO) as Vector2
		if MutationStore and MutationStore.is_position_grass_cleared(pos):
			continue
		var tree_idx: int = clampi(int(desc.get("tree_idx", 0)), 0, 14)
		if not buckets.has(tree_idx):
			buckets[tree_idx] = []
		(buckets[tree_idx] as Array).append(desc)
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
		quad.size = Vector2(cell_w * TREE_SCALE, cell_h * TREE_SCALE)
		mm.mesh = quad
		var mmi := MultiMeshInstance2D.new()
		mmi.multimesh = mm
		mmi.texture = atlas
		var avg_foot_y: float = 0.0
		for i in list.size():
			var desc: Dictionary = list[i] as Dictionary
			var pos: Vector2 = desc.get("position", Vector2.ZERO) as Vector2
			# MultiMesh Y axis is flipped vs Sprite2D — negative scale fixes upside-down trees.
			var center := pos + Vector2(0.0, foot_off_y)
			avg_foot_y += pos.y
			var xform := Transform2D(Vector2(TREE_SCALE, 0.0), Vector2(0.0, -TREE_SCALE), center)
			mm.set_instance_transform_2d(i, xform)
		if list.size() > 0:
			avg_foot_y /= float(list.size())
			mmi.z_as_relative = false
			mmi.z_index = clampi(
				YSortUtils.Z_BASE + int(avg_foot_y),
				YSortUtils.CANVAS_Z_MIN,
				YSortUtils.CANVAS_Z_MAX - 1
			) if YSortUtils else 2048
		add_child(mmi)
