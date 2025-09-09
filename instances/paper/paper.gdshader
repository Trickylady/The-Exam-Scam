shader_type canvas_item;

uniform sampler2D mask_tex;
uniform bool invert_mask = false;
uniform float threshold : hint_range(0.0,1.0) = 0.5;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float m = texture(mask_tex, UV).a;
	float keep = invert_mask ? (1.0 - m) : m;
	base.a *= step(threshold, keep);
	COLOR = base;
}
