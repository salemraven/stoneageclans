class_name ClimateHash
extends Object
## 32-bit integer blotch hash. Must match biome_ground.gdshader climate_hash_u32.

static func hash_u32(mask_x: int, mask_y: int, world_seed: int) -> int:
	## Must match GLSL uint wrap: add after 32-bit multiplies.
	var h: int = world_seed & 0xFFFFFFFF
	h = (h + ((mask_x * 374761393) & 0xFFFFFFFF)) & 0xFFFFFFFF
	h = (h + ((mask_y * 668265263) & 0xFFFFFFFF)) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = (h ^ (h >> 16)) & 0xFFFFFFFF
	return h


static func hash_01(mask_x: int, mask_y: int, world_seed: int) -> float:
	return float(hash_u32(mask_x, mask_y, world_seed)) / 4294967295.0
