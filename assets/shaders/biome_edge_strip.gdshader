shader_type canvas_item;

// Lab only: 4 stacked climate cells. Left = hard IDs. Right = warped blend.
// pair 0 = grass/snow, pair 1 = grass/sand, pair 2 = grass/forest floor
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear;
uniform sampler2D sand_tex : source_color, repeat_enable, filter_linear;
uniform int pair = 2;
uniform float grass_tile = 6.0;
uniform float warp_amp = 0.09;
uniform float blend_width = 0.10;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// t = 0 at bottom (grass), 1 at top (snow). Four equal cells: 0,0,1,1.
float height_t(vec2 uv) {
	return 1.0 - uv.y;
}

vec3 grass_albedo(vec2 uv) {
	vec2 g_uv = uv * grass_tile;
	vec3 g = texture(grass_tex, g_uv).rgb;
	float n = fbm(uv * 18.0);
	g *= 0.78 + n * 0.32;
	g = mix(g, vec3(0.28, 0.38, 0.16), smoothstep(0.55, 0.85, n) * 0.25);
	return g;
}

vec3 sand_albedo(vec2 uv) {
	vec3 dirt = texture(sand_tex, uv * grass_tile).rgb;
	float dunes = fbm(uv * vec2(6.5, 11.0));
	float grit = fbm(uv * 28.0);
	vec3 tan = vec3(0.82, 0.70, 0.48);
	vec3 deep = vec3(0.62, 0.48, 0.30);
	vec3 s = mix(dirt, tan, 0.55);
	s = mix(s, deep, smoothstep(0.35, 0.75, dunes) * 0.35);
	s *= 0.85 + grit * 0.22;
	return s;
}

vec3 forest_albedo(vec2 uv) {
	vec3 dirt = texture(sand_tex, uv * grass_tile).rgb;
	float litter = fbm(uv * 16.0);
	float moss = fbm(uv * vec2(9.0, 13.0) + 1.7);
	vec3 humus = vec3(0.22, 0.16, 0.10);
	vec3 moss_g = vec3(0.16, 0.28, 0.12);
	vec3 leaf = vec3(0.38, 0.22, 0.10);
	vec3 f = mix(dirt, humus, 0.62);
	f = mix(f, moss_g, smoothstep(0.40, 0.78, moss) * 0.45);
	f = mix(f, leaf, smoothstep(0.62, 0.88, litter) * 0.28);
	float speck = step(0.93, hash21(floor(uv * 90.0)));
	f = mix(f, leaf * 1.15, speck * 0.5);
	f *= 0.72 + litter * 0.2;
	return f;
}

vec3 snow_albedo(vec2 uv) {
	float lumps = fbm(uv * 14.0);
	float fine = fbm(uv * 42.0);
	vec3 ice = vec3(0.72, 0.80, 0.88);
	vec3 powder = vec3(0.94, 0.96, 0.98);
	vec3 crust = vec3(0.82, 0.88, 0.93);
	vec3 s = mix(ice, powder, lumps);
	s = mix(s, crust, smoothstep(0.45, 0.75, fine) * 0.35);
	float spark = step(0.97, hash21(floor(uv * 220.0)));
	s += vec3(spark * 0.18);
	s += vec3(0.02, 0.04, 0.08) * (1.0 - lumps);
	return s;
}

float hard_snow(float t) {
	// Cells 2 and 3 (t >= 0.5) are snow.
	return step(0.5, t);
}

float wobbly_snow(vec2 uv, float t) {
	float n = fbm(uv * vec2(9.0, 7.0)) * 2.0 - 1.0;
	float n2 = fbm(uv * vec2(22.0, 18.0) + 3.1) * 2.0 - 1.0;
	float tw = t + n * warp_amp + n2 * (warp_amp * 0.35);
	return smoothstep(0.5 - blend_width, 0.5 + blend_width, tw);
}

void fragment() {
	vec2 uv = UV;
	bool right = uv.x >= 0.5;
	vec2 local = uv;
	if (right) {
		local.x = (uv.x - 0.5) * 2.0;
	} else {
		local.x = uv.x * 2.0;
	}

	float t = height_t(local);
	float snow_amt = right ? wobbly_snow(local, t) : hard_snow(t);

	vec3 grass = grass_albedo(local);
	vec3 top = snow_albedo(local);
	if (pair == 1) {
		top = sand_albedo(local);
	} else if (pair == 2) {
		top = forest_albedo(local);
	}
	vec3 col = mix(grass, top, snow_amt);

	// Left: faint cell borders so the four squares read as squares.
	if (!right) {
		float cell = fract(t * 4.0);
		float line = smoothstep(0.02, 0.0, cell) + smoothstep(0.98, 1.0, cell);
		col = mix(col, vec3(0.05, 0.06, 0.07), line * 0.55);
	}

	// Center split.
	float mid = smoothstep(0.004, 0.0, abs(uv.x - 0.5));
	col = mix(col, vec3(0.08, 0.08, 0.09), mid);

	COLOR = vec4(col, 1.0);
}
