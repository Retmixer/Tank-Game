shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D wear_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 paint_color : source_color = vec4(0.45,0.52,0.39,1.0);
uniform float texture_scale = 1.8;
uniform float metalness : hint_range(0.0,1.0) = 0.13;
varying vec3 model_position;
varying vec3 model_normal;
void vertex() { model_position = VERTEX; model_normal = NORMAL; }
void fragment() {
	vec3 weights = pow(abs(normalize(model_normal)),vec3(4.0));
	weights /= max(dot(weights,vec3(1.0)),0.001);
	vec3 p = model_position * texture_scale;
	vec3 sample_color = texture(wear_map,p.yz).rgb*weights.x + texture(wear_map,p.xz).rgb*weights.y + texture(wear_map,p.xy).rgb*weights.z;
	float grain = dot(sample_color,vec3(0.2126,0.7152,0.0722));
	ALBEDO = paint_color.rgb * (0.62 + grain*0.65);
	ROUGHNESS = 0.88;
	METALLIC = metalness;
	SPECULAR = 0.25;
}
