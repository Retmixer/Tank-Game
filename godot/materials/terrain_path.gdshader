shader_type spatial;
render_mode depth_draw_never, cull_disabled;
uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
void fragment() {
	ALBEDO = texture(color_map,UV*vec2(3.0,1.0)).rgb*tint.rgb;
	NORMAL_MAP = texture(normal_map,UV*vec2(3.0,1.0)).rgb;
	NORMAL_MAP_DEPTH = 0.25;
	ROUGHNESS = 0.95;
	ALPHA = smoothstep(0.0,0.13,UV.x)*(1.0-smoothstep(0.87,1.0,UV.x))*tint.a;
}
