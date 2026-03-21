shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.95, 0.88, 1.0);
uniform float outline_width : hint_range(0.5, 6.0) = 2.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // Sprite modulate (skin tone) - pass from script to avoid double-apply

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float a = col.a;
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;

	// Sample 8 neighbors
	float neighbor_max = 0.0;
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(-ps.x, 0)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(ps.x, 0)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(0, -ps.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(0, ps.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(-ps.x, -ps.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(-ps.x, ps.y)).a);
	neighbor_max = max(neighbor_max, texture(TEXTURE, UV + vec2(ps.x, ps.y)).a);

	// Outline: we're in the expanded border (neighbor has sprite, we're on edge)
	if (neighbor_max > 0.3 && a < 0.5) {
		COLOR = outline_color;
	} else {
		// Apply tint once (skin tone) - sprite modulate set to white while outlined to avoid engine double-apply
		COLOR = col * tint;
	}
}
