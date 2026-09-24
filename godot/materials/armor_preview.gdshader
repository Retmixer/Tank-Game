shader_type spatial;
render_mode unshaded;
uniform mat4 world_to_tank;
uniform vec4 plates = vec4(95.0,78.0,48.0,38.0);
uniform float turret_plate = 95.0;
uniform float penetration = 119.0;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal=normalize(mat3(MODEL_MATRIX)*NORMAL);
}
void fragment() {
	vec3 p=(world_to_tank*vec4(world_position,1.0)).xyz;
	vec3 n=normalize(mat3(world_to_tank)*world_normal);
	float armor = abs(n.x)>abs(n.z) ? plates.y : (n.z<0.0 ? plates.x : plates.z);
	if(n.y>0.65) armor=plates.w;
	else if(p.y>1.65) armor=turret_plate;
	float angle=max(0.2,abs(dot(normalize(world_normal),normalize(CAMERA_POSITION_WORLD-world_position))));
	float chance=clamp((penetration/(armor/angle)-0.75)/0.5,0.0,1.0);
	vec3 red=vec3(0.88,0.12,0.09);
	vec3 yellow=vec3(0.98,0.62,0.08);
	vec3 green=vec3(0.18,0.78,0.32);
	ALBEDO=chance<0.5 ? mix(red,yellow,chance*2.0) : mix(yellow,green,(chance-0.5)*2.0);
	ALBEDO*=0.65+0.35*angle;
}
