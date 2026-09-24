shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D ground_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_roughness : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
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
	// Two real photographed scales suppress repetition without a procedural replacement texture.
	vec3 ground = texture(ground_map,p.xz).rgb;
	vec3 macro = texture(ground_map,p.xz*0.173+vec2(0.31,0.67)).rgb;
	ground *= clamp(macro*0.5+0.78,vec3(0.8),vec3(1.14));
	float slope = smoothstep(0.16,0.48,1.0-abs(world_normal.y));
	ALBEDO = mix(ground*mix(vec3(1.0),tint.rgb,0.25),rock,slope);
	ROUGHNESS = clamp(texture(ground_roughness,p.xz).r*0.3+0.65,0.65,1.0);
	SPECULAR = 0.22;
	vec2 gn = texture(ground_normal,p.xz).xy*2.0-1.0;
	vec2 rx = texture(rock_normal,p.yz).xy*2.0-1.0;
	vec2 ry = texture(rock_normal,p.xz).xy*2.0-1.0;
	vec2 rz = texture(rock_normal,p.xy).xy*2.0-1.0;
	vec3 rn = vec3(0.0,rx.x,rx.y)*weights.x+vec3(ry.x,0.0,ry.y)*weights.y+vec3(rz.x,rz.y,0.0)*weights.z;
	vec3 detail = mix(vec3(gn.x,0.0,gn.y),rn,slope);
	NORMAL = normalize(mat3(VIEW_MATRIX)*(world_normal+detail*0.5));
}
