shader_type canvas_item;

// Discrete gameplay biomes + organic visual edges.
// Water tiles are ALWAYS solid — soft edges only on grass banks.
uniform sampler2D biome_mask : filter_nearest;
uniform sampler2D water_mask : filter_nearest;
uniform bool use_water_layer = false;
uniform vec2 world_size = vec2(65536.0, 65536.0);

uniform bool enable_noise = true;
uniform bool enable_grass_detail = true;
uniform bool enable_river_detail = true;
uniform bool enable_organic_edges = true;
uniform bool enable_biome_blending = true;
uniform float biome_blend_strength = 0.7;

uniform float tile_scale = 0.015;
uniform float detail_intensity = 0.25;

const vec3 COLOR_OCEAN = vec3(0.18, 0.44, 0.65);
const vec3 COLOR_GRASS = vec3(0.62, 0.65, 0.42);
const vec3 COLOR_DESERT = vec3(0.82, 0.72, 0.50);
const vec3 COLOR_DESERT_DARK = vec3(0.72, 0.60, 0.40);
const vec3 COLOR_JUNGLE = vec3(0.18, 0.38, 0.14);
const vec3 COLOR_JUNGLE_DARK = vec3(0.12, 0.28, 0.10);
const vec3 COLOR_SWAMP = vec3(0.38, 0.30, 0.20);
const vec3 COLOR_SWAMP_DARK = vec3(0.28, 0.22, 0.15);
const vec3 COLOR_BEACH = vec3(0.90, 0.86, 0.68);
const vec3 COLOR_GLACIER = vec3(0.88, 0.94, 1.0);
const vec3 COLOR_GRASS_DIRT = vec3(0.55, 0.50, 0.35);
const vec3 COLOR_RIVER = vec3(0.48, 0.62, 0.78);
const vec3 COLOR_GLACIER_RIVER = vec3(0.42, 0.68, 0.95);
const vec3 COLOR_RIVER_DEEP = vec3(0.38, 0.55, 0.72);
const vec3 COLOR_BANK = vec3(0.52, 0.55, 0.38);  // Muddy grass near water

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(127.1, 311.7));
	float c = hash21(i + vec2(269.5, 183.3));
	float d = hash21(i + vec2(419.2, 371.9));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, int octaves) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < octaves; i++) {
		value += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return value;
}

int mask_to_biome_id(float biome_val) {
	return clamp(int(round(biome_val * 9.0)), 0, 8);
}

bool is_river_id(int id) {
	return id == 7;
}

bool is_grass_id(int id) {
	return id == 1;
}

bool is_land_id(int id) {
	return id != 0;
}

int sample_biome_id(vec2 uv) {
	return mask_to_biome_id(texture(biome_mask, uv).r);
}

// Check if this pixel is water (from water_mask or biome_mask)
bool sample_is_water(vec2 uv) {
	if (use_water_layer) {
		return texture(water_mask, uv).r > 0.5;
	} else {
		return is_river_id(mask_to_biome_id(texture(biome_mask, uv).r));
	}
}

// Orphan ocean specks inside land (mask noise) — render as grass, not dark-blue squares.
bool is_ocean_speck_in_land(vec2 uv, vec2 texel) {
	if (sample_biome_id(uv) != 0) {
		return false;
	}
	int land_neighbors = 0;
	land_neighbors += int(is_land_id(sample_biome_id(uv + vec2(texel.x, 0.0))));
	land_neighbors += int(is_land_id(sample_biome_id(uv - vec2(texel.x, 0.0))));
	land_neighbors += int(is_land_id(sample_biome_id(uv + vec2(0.0, texel.y))));
	land_neighbors += int(is_land_id(sample_biome_id(uv - vec2(0.0, texel.y))));
	return land_neighbors >= 3;
}

// Grass specks fully surrounded by water — render as wet, not green squares.
bool is_wet_neighbor(vec2 uv) {
	if (sample_biome_id(uv) == 0) {
		return true;
	}
	if (use_water_layer && texture(water_mask, uv).r > 0.5) {
		return true;
	}
	return false;
}

bool is_land_speck_in_water(vec2 uv, vec2 biome_texel, vec2 water_texel) {
	if (!is_land_id(sample_biome_id(uv))) {
		return false;
	}
	int wet_neighbors = 0;
	vec2 offsets[4];
	offsets[0] = vec2(biome_texel.x, 0.0);
	offsets[1] = vec2(-biome_texel.x, 0.0);
	offsets[2] = vec2(0.0, biome_texel.y);
	offsets[3] = vec2(0.0, -biome_texel.y);
	for (int i = 0; i < 4; i++) {
		if (is_wet_neighbor(uv + offsets[i])) {
			wet_neighbors++;
		}
	}
	return wet_neighbors >= 3;
}

// Painted water tile mostly surrounded by land — render as grass until data fix runs.
bool is_water_speck_in_land(vec2 uv, vec2 biome_texel) {
	if (!use_water_layer || texture(water_mask, uv).r <= 0.5) {
		return false;
	}
	int land_neighbors = 0;
	vec2 offsets[4];
	offsets[0] = vec2(biome_texel.x, 0.0);
	offsets[1] = vec2(-biome_texel.x, 0.0);
	offsets[2] = vec2(0.0, biome_texel.y);
	offsets[3] = vec2(0.0, -biome_texel.y);
	for (int i = 0; i < 4; i++) {
		vec2 nuv = uv + offsets[i];
		if (!sample_is_water(nuv) && sample_biome_id(nuv) != 0) {
			land_neighbors++;
		}
	}
	return land_neighbors >= 3;
}

bool is_ocean_speck_in_river(vec2 uv, vec2 texel) {
	if (sample_biome_id(uv) != 0 || (use_water_layer && texture(water_mask, uv).r > 0.5)) {
		return false;
	}
	int river_neighbors = 0;
	vec2 offsets[4];
	offsets[0] = vec2(texel.x, 0.0);
	offsets[1] = vec2(-texel.x, 0.0);
	offsets[2] = vec2(0.0, texel.y);
	offsets[3] = vec2(0.0, -texel.y);
	for (int i = 0; i < 4; i++) {
		vec2 nuv = uv + offsets[i];
		if (use_water_layer && texture(water_mask, nuv).r > 0.5) {
			river_neighbors++;
		}
	}
	return river_neighbors >= 3;
}

bool is_grass_speck_in_ocean(vec2 uv, vec2 texel) {
	if (sample_biome_id(uv) != 1) {
		return false;
	}
	int ocean_neighbors = 0;
	vec2 offsets[4];
	offsets[0] = vec2(texel.x, 0.0);
	offsets[1] = vec2(-texel.x, 0.0);
	offsets[2] = vec2(0.0, texel.y);
	offsets[3] = vec2(0.0, -texel.y);
	for (int i = 0; i < 4; i++) {
		if (sample_biome_id(uv + offsets[i]) == 0) {
			ocean_neighbors++;
		}
	}
	return ocean_neighbors >= 3;
}

// Count how many neighbors are water (0-4)
float neighbor_water_strength(vec2 uv, vec2 texel) {
	float s = 0.0;
	s += float(sample_is_water(uv + vec2(texel.x, 0.0)));
	s += float(sample_is_water(uv - vec2(texel.x, 0.0)));
	s += float(sample_is_water(uv + vec2(0.0, texel.y)));
	s += float(sample_is_water(uv - vec2(0.0, texel.y)));
	return s / 4.0;
}

// Sample biome colors in a 3x3 kernel and blend for smooth transitions
vec3 sample_blended_biome_color(vec2 uv, vec2 texel, vec2 world_pos) {
	// Sample 9 points in a 3x3 grid
	vec3 colors[9];
	float weights[9];
	float total_weight = 0.0;
	int idx = 0;

	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			vec2 sample_uv = uv + vec2(float(dx), float(dy)) * texel;
			int bid = sample_biome_id(sample_uv);

			// Skip ocean/water for land blending
			if (bid == 0 || sample_is_water(sample_uv)) {
				colors[idx] = vec3(-1.0); // marker for skip
				weights[idx] = 0.0;
			} else {
				vec3 base = land_base_color(bid);
				colors[idx] = add_land_detail(base, world_pos, bid);
				// Center pixel gets more weight, diagonal neighbors less
				float dist = length(vec2(float(dx), float(dy)));
				weights[idx] = 1.0 / (1.0 + dist * 0.5);
				total_weight += weights[idx];
			}
			idx++;
		}
	}

	// Weighted average of sampled colors
	if (total_weight < 0.001) {
		return land_base_color(1); // fallback to grass
	}

	vec3 blended = vec3(0.0);
	for (int i = 0; i < 9; i++) {
		if (colors[i].r >= 0.0) {
			blended += colors[i] * (weights[i] / total_weight);
		}
	}
	return blended;
}

// Biome edge detection: check if we're near a biome transition
bool is_near_biome_edge(vec2 uv, vec2 texel, int center_id) {
	if (center_id == 0) return false; // ocean doesn't blend
	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			if (dx == 0 && dy == 0) continue;
			vec2 sample_uv = uv + vec2(float(dx), float(dy)) * texel;
			int neighbor_id = sample_biome_id(sample_uv);
			// Different land biome = edge
			if (neighbor_id != center_id && neighbor_id != 0 && !sample_is_water(sample_uv)) {
				return true;
			}
		}
	}
	return false;
}

vec3 add_grass_detail(vec3 base, vec2 world_pos) {
	if (!enable_grass_detail) {
		return base;
	}
	float grass_n = fbm(world_pos * tile_scale * 2.0, 3);
	base = mix(base, COLOR_GRASS_DIRT, smoothstep(0.50, 0.65, grass_n) * 0.25);
	return base;
}

vec3 land_base_color(int biome_id) {
	if (biome_id == 5) {
		return COLOR_GLACIER;
	}
	if (biome_id == 2) {
		return COLOR_DESERT;
	}
	if (biome_id == 3) {
		return COLOR_JUNGLE;
	}
	if (biome_id == 4) {
		return COLOR_SWAMP;
	}
	if (biome_id == 8) {
		return COLOR_BEACH;
	}
	return COLOR_GRASS;
}

vec3 add_land_detail(vec3 base, vec2 world_pos, int biome_id) {
	if (biome_id == 1) {
		return add_grass_detail(base, world_pos);
	}
	if (biome_id == 2 && enable_noise) {
		float n = fbm(world_pos * tile_scale * 2.5, 3);
		base = mix(base, COLOR_DESERT_DARK, smoothstep(0.45, 0.70, n) * 0.22);
		return base;
	}
	if (biome_id == 3 && enable_noise) {
		float n = fbm(world_pos * tile_scale * 2.2, 3);
		base = mix(base, COLOR_JUNGLE_DARK, smoothstep(0.40, 0.68, n) * 0.28);
		return base;
	}
	if (biome_id == 4 && enable_noise) {
		float n = fbm(world_pos * tile_scale * 2.0, 3);
		base = mix(base, COLOR_SWAMP_DARK, smoothstep(0.42, 0.72, n) * 0.24);
		return base;
	}
	if (biome_id == 8 && enable_noise) {
		float n = fbm(world_pos * tile_scale * 3.0, 2);
		base = mix(base, COLOR_DESERT, smoothstep(0.50, 0.75, n) * 0.12);
		return base;
	}
	if (enable_noise && biome_id == 5) {
		float n = fbm(world_pos * tile_scale * 3.0, 3);
		base = mix(base, vec3(0.85, 0.90, 0.95), smoothstep(0.55, 0.75, n) * 0.12);
	}
	return base;
}

vec3 add_river_detail(vec3 base, vec2 world_pos) {
	if (!enable_river_detail) {
		return base;
	}
	float flow = sin(world_pos.x * tile_scale * 12.0 + world_pos.y * tile_scale * 6.0) * 0.5 + 0.5;
	base = mix(base, COLOR_RIVER_DEEP, flow * 0.18);
	return base;
}

void fragment() {
	vec2 world_uv = UV;
	vec2 world_pos = world_uv * world_size;

	// Get biome from biome_mask (grass, desert, etc.)
	float biome_val = texture(biome_mask, world_uv).r;
	int biome_id = mask_to_biome_id(biome_val);

	// Painted water always renders as river — topology fixes happen in data, not by hiding water.
	bool is_water = sample_is_water(world_uv);
	vec2 biome_texel = vec2(1.0) / vec2(textureSize(biome_mask, 0));

	vec3 grass = add_land_detail(land_base_color(biome_id), world_pos, biome_id);
	vec3 river_base = biome_id == 5 ? COLOR_GLACIER_RIVER : COLOR_RIVER;
	vec3 river = add_river_detail(river_base, world_pos);

	vec3 color;

	// Rivers (authored water layer) win over ocean biome — light blue only on painted paths.
	if (is_water) {
		color = river;
		if (enable_noise) {
			float n = fbm(world_pos * tile_scale, 4);
			color += vec3((n - 0.5) * detail_intensity * 0.04);
		}
	} else if (biome_id == 0) {
		vec2 biome_texel = vec2(1.0) / vec2(textureSize(biome_mask, 0));
		if (is_ocean_speck_in_land(world_uv, biome_texel)) {
			color = grass;
			if (enable_noise) {
				float n = fbm(world_pos * tile_scale, 4);
				color += vec3((n - 0.5) * detail_intensity * 0.06);
			}
		} else if (is_ocean_speck_in_river(world_uv, biome_texel)) {
			color = river;
		} else {
		// OCEAN — impassible dark blue; never overlaps painted rivers.
		color = COLOR_OCEAN;
		float wave = sin(world_pos.x * tile_scale * 8.0 - world_pos.y * tile_scale * 3.0) * 0.5 + 0.5;
		color = mix(color, vec3(0.12, 0.35, 0.58), wave * 0.10);
		}
	} else if (biome_id == 5) {
		// GLACIER — bright ice cap (center watershed)
		vec2 biome_texel = vec2(1.0) / vec2(textureSize(biome_mask, 0));
		color = add_land_detail(COLOR_GLACIER, world_pos, biome_id);

		// Blend at glacier edges for soft snow line
		if (enable_biome_blending && is_near_biome_edge(world_uv, biome_texel, biome_id)) {
			vec3 blended = sample_blended_biome_color(world_uv, biome_texel, world_pos);
			float edge_noise = fbm(world_pos * 0.01, 3);
			float blend_factor = biome_blend_strength * smoothstep(0.3, 0.7, edge_noise);
			color = mix(color, blended, blend_factor);
		}

		if (enable_noise) {
			float n = fbm(world_pos * tile_scale, 4);
			color += vec3((n - 0.5) * detail_intensity * 0.04);
		}
	} else {
		vec2 biome_texel = vec2(1.0) / vec2(textureSize(biome_mask, 0));
		vec2 water_texel = vec2(1.0) / vec2(textureSize(water_mask, 0));

		if (is_land_speck_in_water(world_uv, biome_texel, water_texel)) {
			color = river;
		} else if (is_grass_speck_in_ocean(world_uv, biome_texel)) {
			color = COLOR_OCEAN;
			float wave = sin(world_pos.x * tile_scale * 8.0 - world_pos.y * tile_scale * 3.0) * 0.5 + 0.5;
			color = mix(color, vec3(0.12, 0.35, 0.58), wave * 0.10);
		} else {
			// LAND BIOMES — blend at edges for natural transitions
			if (enable_biome_blending && is_near_biome_edge(world_uv, biome_texel, biome_id)) {
				// Near a biome border: weighted blend of neighbor colors
				vec3 blended = sample_blended_biome_color(world_uv, biome_texel, world_pos);
				// Add noise to the blend boundary for organic look
				float edge_noise = fbm(world_pos * 0.012, 3);
				float blend_factor = biome_blend_strength * smoothstep(0.25, 0.75, edge_noise);
				color = mix(grass, blended, blend_factor);
			} else {
				color = grass;
			}

			if (enable_organic_edges) {
				vec2 texel = vec2(1.0) / vec2(textureSize(biome_mask, 0));
				if (use_water_layer) {
					texel = vec2(1.0) / vec2(textureSize(water_mask, 0));
				}
				float near_water = neighbor_water_strength(world_uv, texel);

				if (near_water > 0.0) {
					// Grass near water gets a muddy bank look
					float edge_noise = fbm(world_pos * 0.008, 3);
					float bank_strength = near_water * smoothstep(0.3, 0.6, edge_noise);
					color = mix(color, COLOR_BANK, bank_strength * 0.4);
				}
			}

			if (enable_noise) {
				float n = fbm(world_pos * tile_scale, 4);
				color += vec3((n - 0.5) * detail_intensity * 0.06);
			}
		}
	}

	COLOR = vec4(color, 1.0);
}
