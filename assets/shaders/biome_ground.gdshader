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
uniform bool enable_biome_blending = false;
uniform float biome_blend_strength = 0.7;
uniform bool climate_debug_ids = false;
uniform bool climate_enabled = false;
uniform int climate_world_seed = 882001;
uniform float climate_temp[9];
uniform float climate_rain[9];
uniform sampler2D river_distance_tex : filter_nearest;
uniform bool use_river_distance = false;
uniform float u_snow_temp = -0.45;
uniform float u_tundra_temp = -0.22;
uniform float u_desert_rain = -0.40;
uniform float u_wetland_rain = 0.32;
uniform float u_water_widen = 0.12;
uniform float u_water_narrow = 0.85;
uniform float u_forest_thin = -0.2;
uniform float u_center_snow_bias = 0.22;
uniform float u_ice_radius = 0.0;
uniform float u_season_cold = 0.0;
uniform float u_season_wet = 0.0;
uniform float u_oasis_boost = 0.42;
uniform float u_plains_convert = -0.18;
uniform float u_desert_river_keep = 0.14;
uniform float u_tundra_ring = 0.06;
uniform float u_river_base_width = 0.018;
uniform sampler2D succession_tex : filter_nearest;
uniform bool use_succession = false;
uniform bool climate_force_uv = false;
uniform vec2 climate_query_uv = vec2(0.5);

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
const vec3 COLOR_TUNDRA = vec3(0.78, 0.82, 0.75);

uint climate_hash_u32(int seed, int x, int y) {
	uint h = uint(seed);
	h += uint(x) * 374761393u;
	h += uint(y) * 668265263u;
	h = (h ^ (h >> 13u)) * 1274126177u;
	h = h ^ (h >> 16u);
	return h;
}

float climate_hash_01(int seed, int x, int y) {
	return float(climate_hash_u32(seed, x, y)) / 4294967295.0;
}

int climate_ridx(int ix, int iy) {
	ix = clamp(ix, 0, 2);
	iy = clamp(iy, 0, 2);
	return iy * 3 + ix;
}

vec2 climate_sample_temp_rain(vec2 uv) {
	float gx = clamp(uv.x, 0.0, 1.0) * 2.0;
	float gy = clamp(uv.y, 0.0, 1.0) * 2.0;
	int ix = clamp(int(floor(gx)), 0, 1);
	int iy = clamp(int(floor(gy)), 0, 1);
	float fx = gx - float(ix);
	float fy = gy - float(iy);
	float t00 = climate_temp[climate_ridx(ix, iy)];
	float t10 = climate_temp[climate_ridx(ix + 1, iy)];
	float t01 = climate_temp[climate_ridx(ix, iy + 1)];
	float t11 = climate_temp[climate_ridx(ix + 1, iy + 1)];
	float r00 = climate_rain[climate_ridx(ix, iy)];
	float r10 = climate_rain[climate_ridx(ix + 1, iy)];
	float r01 = climate_rain[climate_ridx(ix, iy + 1)];
	float r11 = climate_rain[climate_ridx(ix + 1, iy + 1)];
	float t = mix(mix(t00, t10, fx), mix(t01, t11, fx), fy);
	float r = mix(mix(r00, r10, fx), mix(r01, r11, fx), fy);
	return vec2(t, r);
}

int climate_classify(int base_biome, bool is_base_water, float river_dist01, float temperature, float rainfall, float noise01, bool region_is_center, float dist_from_center) {
	if (base_biome == 0 && !is_base_water) {
		return 0;
	}
	float rain_eff = rainfall + u_season_wet;
	float oasis = 0.0;
	if (rain_eff < 0.0) {
		oasis = (1.0 - clamp(river_dist01, 0.0, 1.0)) * u_oasis_boost;
	}
	float local_rain = rain_eff + oasis;
	bool water = false;
	if (rain_eff > 0.0 && river_dist01 < u_water_widen * rain_eff) {
		water = true;
	}
	float width = u_river_base_width;
	if (rain_eff >= 0.0) {
		width = u_river_base_width + rain_eff * u_water_widen;
	} else {
		width = max(0.003, u_river_base_width * (1.0 + rain_eff * u_water_narrow));
	}
	if (is_base_water && river_dist01 <= width) {
		water = true;
	}
	if (water) {
		return 7;
	}
	float rad = u_ice_radius;
	if (rad <= 0.0 && temperature < -0.22 && region_is_center) {
		rad = clamp((-temperature - 0.22) / 0.78 * 0.52, 0.0, 0.52);
	}
	float edge = 0.035 * (noise01 - 0.5);
	if (rad > 0.001 && dist_from_center <= rad + edge) {
		return 5;
	}
	if (rad > 0.001 && dist_from_center <= rad + u_tundra_ring + edge) {
		return 9;
	}
	if (base_biome == 5 && rad <= 0.001 && temperature > u_snow_temp + 0.2) {
	} else if (base_biome == 5 && rad <= 0.001) {
		return 5;
	}
	float cold_eff = temperature - u_season_cold;
	if (cold_eff < u_tundra_temp && dist_from_center < 0.22 && noise01 < 0.55) {
		return 9;
	}
	int biome = base_biome;
	if (biome == 6 || biome == 3 || biome == 4) {
		if (local_rain < u_plains_convert && noise01 < 0.62) {
			biome = 1;
		}
	}
	if (biome == 6 && local_rain < u_forest_thin && noise01 < -local_rain) {
		biome = 1;
	}
	if (biome == 1 && local_rain < u_desert_rain && river_dist01 > u_desert_river_keep && cold_eff >= u_tundra_temp && noise01 < (-local_rain)) {
		return 2;
	}
	if (rain_eff > u_wetland_rain && river_dist01 < 0.18) {
		if (noise01 < rain_eff && base_biome != 0) {
			return 4;
		}
	}
	if (biome == 1 && rain_eff > 0.2 && noise01 > 0.72) {
		biome = 6;
	}
	return biome;
}

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

vec3 add_grass_detail(vec3 base, vec2 world_pos) {
	if (!enable_grass_detail) {
		return base;
	}
	float grass_n = fbm(world_pos * tile_scale * 2.0, 3);
	base = mix(base, COLOR_GRASS_DIRT, smoothstep(0.50, 0.65, grass_n) * 0.25);
	return base;
}

vec3 land_base_color(int biome_id) {
	if (biome_id == 9) {
		return COLOR_TUNDRA;
	}
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
	if (biome_id == 9 && enable_noise) {
		float n = fbm(world_pos * tile_scale * 2.4, 2);
		base = mix(base, vec3(0.70, 0.74, 0.68), smoothstep(0.45, 0.75, n) * 0.18);
		return base;
	}
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

vec3 add_river_detail(vec3 base, vec2 world_pos) {
	if (!enable_river_detail) {
		return base;
	}
	float flow = sin(world_pos.x * tile_scale * 12.0 + world_pos.y * tile_scale * 6.0) * 0.5 + 0.5;
	base = mix(base, COLOR_RIVER_DEEP, flow * 0.18);
	return base;
}

void fragment() {
	vec2 world_uv = climate_force_uv ? climate_query_uv : UV;
	vec2 world_pos = world_uv * world_size;

	float biome_val = texture(biome_mask, world_uv).r;
	int base_biome = mask_to_biome_id(biome_val);
	bool is_base_water = sample_is_water(world_uv);
	ivec2 mask_sz = textureSize(biome_mask, 0);
	ivec2 cell = ivec2(clamp(ivec2(floor(world_uv * vec2(mask_sz))), ivec2(0), mask_sz - ivec2(1)));
	float dist01 = 1.0;
	if (use_river_distance) {
		dist01 = texture(river_distance_tex, world_uv).r;
	} else if (is_base_water) {
		dist01 = 0.0;
	}
	vec2 tr = vec2(0.0);
	if (climate_enabled) {
		tr = climate_sample_temp_rain(world_uv);
	}
	float n01 = climate_hash_01(climate_world_seed, cell.x, cell.y);
	bool center = distance(world_uv, vec2(0.5, 0.5)) < 0.18;
	float dist_from_center = clamp(distance(world_uv, vec2(0.5, 0.5)) / 0.7071, 0.0, 1.0);
	int biome_id = climate_classify(base_biome, is_base_water, dist01, tr.x, tr.y, n01, center, dist_from_center);
	if (use_succession && climate_enabled && biome_id != 0) {
		int sid = int(round(texture(succession_tex, world_uv).r * 255.0));
		if (sid > 0) {
			biome_id = sid;
		}
	}
	if (climate_debug_ids) {
		COLOR = vec4(float(biome_id) / 255.0, 0.0, 0.0, 1.0);
	} else {
	bool is_water = biome_id == 7;
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
}
