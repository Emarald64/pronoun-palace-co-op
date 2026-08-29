shader_type canvas_item;
render_mode blend_mix;

const float animation_time=0.2;
//const vec2 spritesheet_size=vec2(10,4);
const vec2 grid_size = vec2(8);
instance uniform float time = 0.0;

// 3D Noise with friendly permission by Inigo Quilez
vec3 hash_noise_range( vec3 p ) {
	p *= mat3(vec3(127.1, 311.7, -53.7), vec3(269.5, 183.3, 77.1), vec3(-301.7, 27.3, 215.3));
	return 2.0 * fract(fract(p)*4375.55) -1.;
}


void fragment() {
	vec2 adjusted_grid_size=grid_size/REGION_RECT.zw;
	lowp vec2 grid_uv = floor(UV*adjusted_grid_size)/adjusted_grid_size;
	lowp int rounded_global_time=int(TIME*10.0);
	
	
	COLOR.rgb = vec3(mix(0.2,0.8,hash_noise_range(vec3(grid_uv, float(rounded_global_time))).y));
	float max_alpha=2.0-abs(time-animation_time)*2.0/animation_time;
	float min_alpha=min(max_alpha-.5,1.0);
	float max_alpha_clamped=min(max_alpha,1.0);
	COLOR.a*=mix(min_alpha,max_alpha_clamped,hash_noise_range(vec3(grid_uv,float(rounded_global_time+1))).x);
}
