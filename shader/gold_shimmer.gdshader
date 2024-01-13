shader_type canvas_item;

uniform vec4 normal_color = vec4(1.0, 0.843137, 0.0, 1.0);
uniform vec4 shine_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// honeycomb: 
	//float shine = smoothstep(0.0, 1.8, 1.0 - abs(sin(SCREEN_UV.x * 30.0) - 0.6*cos(SCREEN_UV.y * 60.0) + 0.05*sin(SCREEN_UV.y)));
	// diffuse diagonals
	// increase spread between 1st and 2nd number to get more diffuse lines
	// Change SCREEN_UV.x or .y multiplier to get a different angle
	// Change final multiplier to change number of lines on the screen
	float shine = smoothstep(5.6, 6.40, 6.0 * abs(sin((SCREEN_UV.x*2.0 + SCREEN_UV.y) * 7.0)));
	// wide diagonal: float shine = smoothstep(0.0, 1.4, 1.0 - abs(SCREEN_UV.x - SCREEN_UV.y));
	/* // diagonals 
	int shine = int((SCREEN_UV.x*15.0 + SCREEN_UV.y*6.0) * 600.0) % 1200;
	if (shine < 280) {
    	COLOR.rgba =  mix(normal_color.rgba, shine_color.rgba, float(shine) / 280.0);
	}*/
    //float shine = step(slope * UV.x - UV.y, progress + shine_size + shine_size * slope) - step(slope * UV.x - UV.y, progress);
	COLOR.rgba =  mix(normal_color.rgba, shine_color.rgba, float(shine));
}