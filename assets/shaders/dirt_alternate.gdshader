shader_type canvas_item;

uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D texture4;
uniform float repeat_count : hint_range(1.0, 200.0) = 80.0;

// Deterministic hash so each tile picks one texture (stable, no flicker)
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * repeat_count;
	vec2 tile = floor(uv);
	float h = hash(tile);
	vec4 c1 = texture(TEXTURE, fract(uv));
	vec4 c2 = texture(texture2, fract(uv));
	vec4 c3 = texture(texture3, fract(uv));
	vec4 c4 = texture(texture4, fract(uv));
	// Pick one of 4 based on hash: [0,0.25)->1, [0.25,0.5)->2, [0.5,0.75)->3, [0.75,1)->4
	vec4 c = mix(c1, c2, step(0.25, h));
	c = mix(c, c3, step(0.5, h));
	c = mix(c, c4, step(0.75, h));
	COLOR = c;
}
