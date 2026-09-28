shader_type canvas_item;

uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D texture4;
uniform vec2 world_center = vec2(0.0);
uniform vec2 world_size = vec2(5120.0);
uniform float tile_px = 64.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// World-locked UVs so the carpet can follow the camera without the grass sliding.
	vec2 world = world_center + (UV - 0.5) * world_size;
	float tpx = max(tile_px, 1.0);
	vec2 uv = world / tpx;
	vec2 tile = floor(uv);
	float h = hash(tile);
	vec2 frac_uv = fract(uv);
	vec4 c1 = texture(TEXTURE, frac_uv);
	vec4 c2 = texture(texture2, frac_uv);
	vec4 c3 = texture(texture3, frac_uv);
	vec4 c4 = texture(texture4, frac_uv);
	vec4 c = mix(c1, c2, step(0.25, h));
	c = mix(c, c3, step(0.5, h));
	c = mix(c, c4, step(0.75, h));
	COLOR = c;
}
