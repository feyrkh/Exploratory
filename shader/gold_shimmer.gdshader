shader_type canvas_item;

uniform vec4 normal_color = vec4(1.0, 0.843137, 0.0, 1.0);
uniform vec4 shine_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	float shine = smoothstep(0.0, 1.8, 1.0 - abs(sin(SCREEN_UV.x * 30.0) - 0.6*cos(SCREEN_UV.y * 60.0) + 0.05*sin(SCREEN_UV.y)));
	//float shine = smoothstep(0.0, 1.4, 1.0 - abs(SCREEN_UV.x - SCREEN_UV.y));
	COLOR.rgb =  mix(normal_color.rgb, shine_color.rgb, float(shine));
}