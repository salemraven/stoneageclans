shader_type canvas_item;

// Earthy clan tint on leather/hide. Near-white pixels (teeth on hide3) stay untinted.
uniform vec4 dye_color : source_color = vec4(1.0);
uniform float preserve_bright_min : hint_range(0.0, 1.0) = 0.91;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float mn = min(tex.r, min(tex.g, tex.b));
	float keep_white = step(preserve_bright_min, mn);
	vec4 tint = mix(dye_color, vec4(1.0), keep_white);
	COLOR = tex * tint * COLOR;
}
