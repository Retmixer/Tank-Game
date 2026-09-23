shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D ground_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float texture_scale = 0.12;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal = normalize(mat3(MODEL_MATRIX)*NORMAL);
}
void fragment() {
	vec3 p = world_position*texture_scale;
	vec3 weights = pow(abs(world_normal),vec3(4.0));
	weights /= max(dot(weights,vec3(1.0)),0.001);
	vec3 rock = texture(rock_map,p.yz).rgb*weights.x + texture(rock_map,p.xz).rgb*weights.y + texture(rock_map,p.xy).rgb*weights.z;
	vec3 ground = texture(ground_map,p.xz).rgb;
	float slope = smoothstep(0.16,0.48,1.0-abs(world_normal.y));
	ALBEDO = mix(ground*tint.rgb,rock,slope);
	ROUGHNESS = 0.97;
	SPECULAR = 0.12;
}
