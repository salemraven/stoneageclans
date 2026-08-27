class_name ChunkRng
extends RefCounted
## Deterministic RNG for chunk-scoped world layout (world_seed + chunk + salt).


static func create(world_seed: int, cx: int, cy: int, salt: StringName) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var h: int = hash(Vector3i(int(world_seed), cx, cy))
	h = hash(str(h) + str(salt))
	rng.seed = int(h) if h != 0 else 1
	return rng
