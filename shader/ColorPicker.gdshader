shader_type canvas_item;

uniform float r = 0.0;
uniform float g = 0.0;
uniform float b = 0.0;
uniform int controlling = 0;


void fragment() {
	if (controlling == 0) {
		COLOR.rgb = vec3(UV.x, g, b);
	} else if (controlling == 1) {
		COLOR.rgb = vec3(r, UV.x, b);
	} else if (controlling == 2) {
		COLOR.rgb = vec3(r, g, UV.x);
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
