shader_type canvas_item;

// How many times to repeat the texture over the sprite (sprite is 1024*scale pixels)
// e.g. 8 = one repeat every 128 world px (scale 1), or every 128*scale with larger scale
uniform float repeat_count : hint_range(1.0, 200.0) = 8.0;

void fragment() {
	vec2 uv = UV * repeat_count;
	COLOR = texture(TEXTURE, fract(uv));
}
