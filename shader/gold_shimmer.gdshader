shader_type canvas_item;

uniform vec4 normal_color = vec4(1.0, 0.843137, 0.0, 1.0);
uniform vec4 shine_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    //COLOR = texture(TEXTURE, UV);
	int shine = int((SCREEN_UV.x*15.0 + SCREEN_UV.y*6.0) * 400.0) % 1200;
	if (shine < 180) {
    	COLOR.rgb =  mix(normal_color.rgb, shine_color.rgb, float(shine) / 180.0);
	}
}