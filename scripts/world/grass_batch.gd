extends Node2D
class_name GrassBatch
## Batched tallgrass visuals — MultiMesh per texture variant and Y-sort bucket.

const TEXTURE_PATHS: Array[String] = [
	"res://assets/sprites/tallgrass1.png",
	"res://assets/sprites/tallgrass2.png",
	"res://assets/sprites/tallgrass3.png",
	"res://assets/sprites/tallgrass4.png",
	"res://assets/sprites/tallgrass5.png",
	"res://assets/sprites/tallgrass6.png",
]
## One mesh per bucket so each blade sorts by foot Y (avg bucket z was drawing grass over tree tops).
const FOOT_Y_BUCKET_PX: int = 16


static func build(parent: Node2D, points: Array, chunk: Vector2i) -> GrassBatch:
	var batch := GrassBatch.new()
	batch.name = "GrassBatch"
	batch._chunk_coords = chunk
	parent.add_child(batch)
	batch._build_meshes(points, chunk)
	if TallGrassCover:
		TallGrassCover.register_chunk_blades(chunk, points)
	return batch


func _exit_tree() -> void:
	if TallGrassCover:
		TallGrassCover.clear_chunk(_chunk_coords)


var _chunk_coords: Vector2i = Vector2i.ZERO


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
		_add_meshes_for_texture(tex, list)


func _add_meshes_for_texture(tex: Texture2D, points: Array) -> void:
	var w: float = float(tex.get_width())
	var h: float = float(tex.get_height())
	var wps: float = YSortUtils.get_world_prop_scale() if YSortUtils else 1.15
	var foot_off: Vector2 = (
		YSortUtils.get_grass_sprite_position_for_texture(tex, wps)
		if YSortUtils
		else Vector2(0, -h * wps * 0.5)
	)
	var by_bucket: Dictionary = {}
	for pt in points:
		var pos: Vector2 = (pt as Dictionary).get("position", Vector2.ZERO) as Vector2
		var foot_y: float = pos.y + foot_off.y
		var bucket_key: int = int(floor(foot_y / float(FOOT_Y_BUCKET_PX)))
		if not by_bucket.has(bucket_key):
			by_bucket[bucket_key] = [] as Array
		(by_bucket[bucket_key] as Array).append(pt)
	for bucket_key: int in by_bucket.keys():
		var bucket_pts: Array = by_bucket[bucket_key] as Array
		var sort_foot_y: float = (float(bucket_key) + 0.5) * float(FOOT_Y_BUCKET_PX)
		var mm_node := _make_mesh_for_texture(tex, bucket_pts, w, h, wps, foot_off, sort_foot_y)
		if mm_node:
			add_child(mm_node)


func _make_mesh_for_texture(
	tex: Texture2D,
	points: Array,
	w: float,
	h: float,
	wps: float,
	foot_off: Vector2,
	sort_foot_y: float,
) -> MultiMeshInstance2D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = false
	mm.instance_count = points.size()
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	mm.mesh = quad
	var mmi := MultiMeshInstance2D.new()
	mmi.name = "GrassTex_%d_%d" % [points.size(), int(sort_foot_y)]
	mmi.multimesh = mm
	mmi.texture = tex
	for i in points.size():
		var pt: Dictionary = points[i] as Dictionary
		var pos: Vector2 = pt.get("position", Vector2.ZERO) as Vector2
		# MultiMesh Y axis is flipped vs Sprite2D — match TreeBatch + legacy tallgrass Sprite2D.
		var center := pos + foot_off
		var xform := Transform2D(Vector2(wps, 0.0), Vector2(0.0, -wps), center)
		mm.set_instance_transform_2d(i, xform)
	mmi.z_as_relative = false
	if YSortUtils:
		mmi.z_index = YSortUtils.world_sort_z_from_y(sort_foot_y)
	else:
		mmi.z_index = 2048
	return mmi
