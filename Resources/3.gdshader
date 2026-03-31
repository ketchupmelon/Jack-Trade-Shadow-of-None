shader_type canvas_item;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 tex_color = texture(TEXTURE, UV);
	if(tex_color.a != 0.0){
		COLOR = vec4(0.0, 0.0, 1.0, COLOR.a * 0.5);
	}
}