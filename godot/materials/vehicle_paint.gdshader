shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D wear_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 paint_color : source_color = vec4(0.45,0.52,0.39,1.0);
uniform float texture_scale = 1.8;
uniform float metalness : hint_range(0.0,1.0) = 0.13;
varying vec3 model_position;
varying vec3 model_normal;
varying mat3 surface_to_view;
void vertex() {
	// Keep texel density in metres, including scaled primitive panels; never swim as the tank moves.
	model_position = VERTEX * vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	model_normal = NORMAL;
	surface_to_view = mat3(VIEW_MATRIX) * MODEL_NORMAL_MATRIX;
}
void fragment() {
	vec3 weights = pow(abs(normalize(model_normal)),vec3(4.0));
	weights /= max(dot(weights,vec3(1.0)),0.001);
	vec3 p = model_position * texture_scale;
	vec3 sample_color = texture(wear_map,p.yz).rgb*weights.x + texture(wear_map,p.xz).rgb*weights.y + texture(wear_map,p.xy).rgb*weights.z;
	float grain = dot(sample_color,vec3(0.2126,0.7152,0.0722));
	float wear = 1.0-smoothstep(0.025,0.08,grain);
	float rust = smoothstep(0.95,1.4,sample_color.r/max(sample_color.g,0.001));
	vec3 steel = vec3(0.10,0.11,0.10);
	vec3 coat = paint_color.rgb*clamp(0.45+grain*4.5,0.55,1.35);
	ALBEDO = mix(mix(coat,vec3(0.15,0.065,0.025),rust*0.5),steel,wear*0.48);
	float rough = texture(roughness_map,p.yz).r*weights.x+texture(roughness_map,p.xz).r*weights.y+texture(roughness_map,p.xy).r*weights.z;
	ROUGHNESS = clamp(rough*0.64+0.28-wear*0.12,0.48,0.9);
	METALLIC = mix(metalness*0.3,0.66,wear);
	SPECULAR = 0.42;
	vec2 nx = texture(normal_map,p.yz).xy*2.0-1.0;
	vec2 ny = texture(normal_map,p.xz).xy*2.0-1.0;
	vec2 nz = texture(normal_map,p.xy).xy*2.0-1.0;
	vec3 detail = vec3(0.0,nx.x,nx.y)*weights.x+vec3(ny.x,0.0,ny.y)*weights.y+vec3(nz.x,nz.y,0.0)*weights.z;
	NORMAL = normalize(surface_to_view*(normalize(model_normal)+detail*0.38));
}
