shader_type canvas_item;

#include "res://source/shaders/spell_constants.gdshaderinc"
#include "res://source/shaders/reshade.gdshaderinc"
#include "res://source/shaders/outline.gdshaderinc"

uniform vec3 imaginary_dark: source_color;
uniform vec3 imaginary_light: source_color;

instance uniform int render_flags;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec2 modified_uv=vec2(UV.x+sin((4.*UV.y+TIME)/PI*2.)/16.,UV.y);
	COLOR=texture(TEXTURE,modified_uv);
	
	if (COLOR.a > 0.0001 && (COLOR.r > 0.0001 || COLOR.g > 0.0001 || COLOR.b > 0.0001)) {
		COLOR.rgb /= vertex_color.rgb;

		COLOR.rgb = reshade(COLOR.rgb, imaginary_light, true, imaginary_dark, .75, .5);

		COLOR.rgb *= vertex_color.rgb;
		
	} else if ((render_flags & OUTLINE_FLAG) != 0) {
		vec4 outline_color = (render_flags & CURSED_FLAG) != 0 ? CURSED_OUTLINE_COLOR : OUTLINE_COLOR;
		COLOR = apply_outline(COLOR, outline_color, TEXTURE, modified_uv, TEXTURE_PIXEL_SIZE, REGION_RECT);
	}
}
