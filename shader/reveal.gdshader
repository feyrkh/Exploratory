shader_type canvas_item;

uniform float reveal=0.5;
uniform vec2 rect_global_position;
uniform vec2 rect_size;

void fragment() {
	vec2 frag_uv = (SCREEN_UV - rect_global_position) / rect_size;
	vec4 color = texture(TEXTURE, frag_uv);
	if (frag_uv.x > reveal) {
		COLOR = vec4(color.rgb, 0.0);
	} else {
		COLOR = vec4(color.rgb, 1.0);
	}
}