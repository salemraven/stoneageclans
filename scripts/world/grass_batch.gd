extends Node2D
class_name GrassBatch
## Batched tallgrass visuals — one MultiMeshInstance2D per texture variant.

const TEXTURE_PATHS: Array[String] = [
	"res://assets/sprites/tallgrass1.png",
	"res://assets/sprites/tallgrass2.png",
	"res://assets/sprites/tallgrass3.png",
	"res://assets/sprites/tallgrass4.png",
	"res://assets/sprites/tallgrass5.png",
	"res://assets/sprites/tallgrass6.png",
]


static func build(parent: Node2D, points: Array, chunk: Vector2i) -> GrassBatch:
	var batch := GrassBatch.new()
	batch.name = "GrassBatch"
	parent.add_child(batch)
	batch._build_meshes(points, chunk)
	return batch


func _build_meshes(points: Array, _chunk: Vector2i) -> void:
	var buckets: Array = []
	for _i in TEXTURE_PATHS.size():
		buckets.append([] as Array)
	for pt in points:
		if typeof(pt) != TYPE_DICTIONARY:
			continue
		var pos: Vector2 = pt.get("position", Vector2.ZERO) as Vector2
		if MutationStore and MutationStore.is_position_grass_cleared(pos):
			continue
		var tidx: int = clampi(int(pt.get("texture_idx", 0)), 0, TEXTURE_PATHS.size() - 1)
		(buckets[tidx] as Array).append(pt)
	for tidx in buckets.size():
		var list: Array = buckets[tidx] as Array
		if list.is_empty():
			continue
		var tex := load(TEXTURE_PATHS[tidx]) as Texture2D
		if tex == null:
			continue
		var mm_node := _make_mesh_for_texture(tex, list)
		if mm_node:
			add_child(mm_node)


func _make_mesh_for_texture(tex: Texture2D, points: Array) -> MultiMeshInstance2D:
	var w: float = float(tex.get_width())
	var h: float = float(tex.get_height())
	var foot_off: Vector2 = YSortUtils.get_grass_sprite_position_for_texture(tex) if YSortUtils else Vector2(0, -h * 0.5)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = false
	mm.instance_count = points.size()
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	mm.mesh = quad
	var mmi := MultiMeshInstance2D.new()
	mmi.name = "GrassTex_%d" % points.size()
	mmi.multimesh = mm
	mmi.texture = tex
	var avg_foot_y: float = 0.0
	for i in points.size():
		var pt: Dictionary = points[i] as Dictionary
		var pos: Vector2 = pt.get("position", Vector2.ZERO) as Vector2
		avg_foot_y += pos.y + foot_off.y
		var xform := Transform2D.IDENTITY
		xform.origin = pos + foot_off
		mm.set_instance_transform_2d(i, xform)
	if points.size() > 0:
		avg_foot_y /= float(points.size())
		mmi.z_as_relative = false
		mmi.z_index = clampi(YSortUtils.Z_BASE + int(avg_foot_y), YSortUtils.CANVAS_Z_MIN, YSortUtils.CANVAS_Z_MAX - 1) if YSortUtils else 2048
	return mmi
