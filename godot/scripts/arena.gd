extends Node3D
class_name BattleArena

var map_id := "training"
var map_data: Dictionary
var world_size := 560.0
var seed_value := 123
var rng := RandomNumberGenerator.new()
var terrain_material: StandardMaterial3D
var obstacles: Array[Node3D] = []
var base_marker: MeshInstance3D
var environment_node: WorldEnvironment
var high_quality := true

func build(which: String, quality := "high") -> void:
	map_id = which if GameData.maps.has(which) else "training"
	map_data = GameData.maps[map_id]
	world_size = float(map_data.size)
	seed_value = int(map_data.seed)
	high_quality = quality == "high"
	rng.seed = seed_value
	_create_environment()
	_create_terrain(120 if quality == "high" else 80)
	_create_level()
	_create_boundary()
	_create_base()

func height_at(x: float, z: float) -> float:
	var h := 0.0
	match map_id:
		"training":
			h = 2.3 * sin(x * .018) + 2.0 * cos(z * .015) + 1.4 * sin((x + z) * .029) + 1.0 * cos((x - z) * .035)
			h += _hill(x + 90.0, z - 75.0, 43.0, 7.0) + _hill(x - 115.0, z + 85.0, 53.0, 9.0)
		"desert":
			h = 3.2 * sin(x * .021 + z * .008) + 2.4 * cos(z * .019) + 1.3 * sin((x - z) * .026)
			h += _hill(x + 110.0, z - 30.0, 64.0, 8.0) + _hill(x - 150.0, z + 55.0, 47.0, 6.0)
		"winter":
			h = 1.0 * sin(x * .02) + 1.0 * cos(z * .016) + .45 * sin((x + z) * .029)
			h += _hill(x - 170.0, z - 110.0, 40.0, 2.5) + _hill(x + 155.0, z + 110.0, 44.0, 2.0)
	# Spawn aprons are gently graded so a vehicle can start moving uphill.
	var side_distance: float = absf(absf(x) - world_size * .4)
	var depth_distance: float = absf(absf(z) - world_size * .4)
	if side_distance < 22.0 and depth_distance < 26.0:
		var weight := smoothstep(26.0, 10.0, maxf(side_distance, depth_distance))
		var pad := 0.0
		h = lerpf(h, pad, weight)
	return h

func _map_color(key: String) -> Color:
	var packed: int = int(map_data.get(key, 0x808080))
	return Color8((packed >> 16) & 255, (packed >> 8) & 255, packed & 255)

func _hill(x: float, z: float, radius: float, amplitude: float) -> float:
	var d := sqrt(x * x + z * z) / radius
	return amplitude * exp(-d * d * 1.5)

func _create_environment() -> void:
	var postprocessing := high_quality and bool(GameData.save.settings.get("postprocessing", true))
	environment_node = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = _map_color("sky").lightened(.1)
	sky_material.sky_horizon_color = _map_color("fog")
	sky_material.ground_bottom_color = _map_color("ground").darkened(.35)
	sky_material.ground_horizon_color = _map_color("fog")
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = .65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.fog_enabled = true
	env.fog_light_color = _map_color("fog")
	env.fog_density = .00055
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.ssr_enabled = postprocessing
	env.ssao_enabled = postprocessing
	env.ssil_enabled = postprocessing
	environment_node.environment = env
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-43.0, 24.0, 0.0)
	sun.light_energy = 1.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 280.0 if high_quality else 120.0
	add_child(sun)

func _create_terrain(resolution: int) -> void:
	var heights := PackedFloat32Array()
	heights.resize(resolution * resolution)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := _map_color("ground")
	var texture_name := "training" if map_id == "training" else map_id
	terrain_material = StandardMaterial3D.new()
	terrain_material.albedo_color = Color(1, 1, 1)
	terrain_material.albedo_texture = load("res://assets/textures/%s-color.jpg" % texture_name)
	terrain_material.normal_enabled = true
	terrain_material.normal_texture = load("res://assets/textures/%s-normal.jpg" % texture_name)
	terrain_material.normal_scale = .38
	terrain_material.uv1_scale = Vector3(42, 42, 42)
	terrain_material.roughness = .94
	terrain_material.vertex_color_use_as_albedo = true
	for z in resolution:
		for x in resolution:
			var wx := (float(x) / float(resolution - 1) - .5) * world_size
			var wz := (float(z) / float(resolution - 1) - .5) * world_size
			var h := height_at(wx, wz)
			heights[z * resolution + x] = h
			var tint := rng.randf_range(.93, 1.04)
			var color := base * tint
			var a := Vector3(wx, h, wz)
			var b := Vector3(wx + world_size / float(resolution - 1), height_at(wx + world_size / float(resolution - 1), wz), wz)
			var c := Vector3(wx + world_size / float(resolution - 1), height_at(wx + world_size / float(resolution - 1), wz + world_size / float(resolution - 1)), wz + world_size / float(resolution - 1))
			var d := Vector3(wx, height_at(wx, wz + world_size / float(resolution - 1)), wz + world_size / float(resolution - 1))
			for v in [a, c, b, a, d, c]:
				surface.set_color(color)
				surface.set_uv(Vector2(v.x / 7.0, v.z / 7.0))
				surface.add_vertex(v)
	surface.generate_normals()
	var mesh := surface.commit()
	var ground := MeshInstance3D.new()
	ground.mesh = mesh
	ground.material_override = terrain_material
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)
	# A native height map supplies continuous collision across the same hills.
	var body := StaticBody3D.new()
	body.name = "TerrainCollision"
	var collision := CollisionShape3D.new()
	var shape := HeightMapShape3D.new()
	shape.map_width = resolution
	shape.map_depth = resolution
	shape.map_data = heights
	collision.shape = shape
	collision.scale = Vector3(world_size / float(resolution - 1), 1.0, world_size / float(resolution - 1))
	collision.position = Vector3.ZERO
	body.add_child(collision)
	add_child(body)

func _create_level() -> void:
	match map_id:
		"training":
			_path([[0, -world_size * .38], [0, 0], [0, world_size * .38]], 16.0, "road")
			for side in [-1.0, 1.0]:
				_path([[0, -world_size * .37], [side * 95, -world_size * .19], [side * 90, world_size * .12], [0, world_size * .37]], 13.0, "road")
				for i in 5:
					var x: float = side * (45.0 + i * 31.0)
					var z: float = side * (70.0 + (i % 3) * 32.0)
					_building(Vector3(x, height_at(x, z), z), Vector3(15, 8, 19), Color("777263"))
					_tree_cluster(Vector3(-x * .8, height_at(-x * .8, z + 22), z + 22), 4)
				_tower(Vector3(side * 156, height_at(side * 156, -125), -125))
				for i in 12:
					var z := float(i - 6) * 18.0
					_building(Vector3(side * (80 + (i % 3) * 12), height_at(side * (80 + (i % 3) * 12), z), z), Vector3(9, 5, 10), Color("96866b"))
		"desert":
			_path([[0, -world_size * .42], [20, -110], [-18, 15], [25, world_size * .41]], 21.0, "sand")
			_path([[-world_size * .32, 0], [0, -20], [world_size * .34, 12]], 14.0, "sand")
			for side in [-1.0, 1.0]:
				for i in 11:
					var x: float = side * (54 + i * 13)
					var z: float = -150 + (i % 6) * 58
					_rock(Vector3(x, height_at(x, z), z), rng.randf_range(9.0, 20.0))
				for i in 7:
					var x: float = side * (40 + (i % 3) * 24)
					var z: float = side * (45 + i * 24)
					_building(Vector3(x, height_at(x, z), z), Vector3(20, 6, 13), Color("826c54"))
					_cover(Vector3(x + 24, height_at(x + 24, z + 16), z + 16), Vector3(9, 2, 2), Color("817c67"))
				_tower(Vector3(side * 134, height_at(side * 134, side * 202), side * 202))
		"winter":
			_path([[0, -world_size * .4], [0, 0], [0, world_size * .4]], 19.0, "road")
			_path([[-world_size * .34, 0], [world_size * .34, 0]], 16.0, "road")
			for side_x in [-1.0, 1.0]:
				for side_z in [-1.0, 1.0]:
					var x: float = side_x * 76.0
					var z: float = side_z * 106.0
					for i in 5:
						var pos := Vector3(x + side_x * (i % 2) * 32, 0, z + side_z * (i / 2) * 27)
						pos.y = height_at(pos.x, pos.z)
						_building(pos, Vector3(27, 13 + i % 3 * 4, 33), Color("545f61"), true)
					_cover(Vector3(side_x * 35, height_at(side_x * 35, side_z * 56), side_z * 56), Vector3(12, 2, 2), Color("575c5b"))
			for side in [-1.0, 1.0]:
				_chimney(Vector3(side * 138, height_at(side * 138, 132) + 16, 132))
				for z in range(-150, 155, 8):
					_cover(Vector3(-world_size * .30, height_at(-world_size * .30, z), z), Vector3(5, .18, .3), Color("4b5558"))
	_add_distant_scenery()

func _add_distant_scenery() -> void:
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var distance := world_size * .48
		var pos := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		if map_id == "training":
			_rock(Vector3(pos.x, height_at(pos.x, pos.z) + 8, pos.z), rng.randf_range(22.0, 47.0), false)
		elif map_id == "desert":
			_rock(Vector3(pos.x, height_at(pos.x, pos.z) + 13, pos.z), rng.randf_range(25.0, 54.0), false)
		else:
			_tree_cluster(Vector3(pos.x, height_at(pos.x, pos.z), pos.z), 5, false)

func _path(points: Array, width: float, kind: String) -> void:
	var material := StandardMaterial3D.new()
	var texture_name := "road" if kind == "road" else "mud"
	material.albedo_texture = load("res://assets/textures/%s-color.jpg" % texture_name)
	material.uv1_scale = Vector3(6, 6, 6)
	material.roughness = .96
	var polygon := PackedVector3Array()
	for i in points.size() - 1:
		var a := Vector2(points[i][0], points[i][1])
		var b := Vector2(points[i + 1][0], points[i + 1][1])
		var direction := (b - a).normalized()
		var side := Vector2(-direction.y, direction.x) * width * .5
		for p in [a - side, a + side, b + side, a - side, b + side, b - side]:
			polygon.append(Vector3(p.x, height_at(p.x, p.y) + .08, p.y))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = polygon
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var road := MeshInstance3D.new()
	road.mesh = mesh
	road.material_override = material
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road)

func _building(at: Vector3, size: Vector3, color: Color, factory := false) -> void:
	var root := StaticBody3D.new()
	root.position = at
	add_child(root)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.albedo_texture = load("res://assets/textures/brick-color.jpg" if map_id != "winter" else "res://assets/textures/steel-color.jpg")
	material.uv1_scale = Vector3(2, 2, 2)
	material.roughness = .94
	_box(root, size, Vector3(0, size.y * .5, 0), material, true)
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color("363d3d") if factory else Color("544b3c")
	_box(root, Vector3(size.x * 1.04, .45, size.z * 1.04), Vector3(0, size.y + .22, 0), roof_mat)
	if factory:
		for side in [-1.0, 1.0]:
			_box(root, Vector3(.7, size.y * .8, .3), Vector3(side * size.x * .28, size.y * .47, -size.z * .5 - .17), roof_mat)
		var window_material := StandardMaterial3D.new()
		window_material.albedo_color = Color("e7ba6d")
		window_material.emission_enabled = true
		window_material.emission = Color("ad7436")
		for x in [-.3, .3]:
			_box(root, Vector3(size.x * .15, 2, .2), Vector3(x * size.x, size.y * .46, -size.z * .5 - .19), window_material)
	_add_collision(root, size, Vector3(0, size.y * .5, 0))
	obstacles.append(root)

func _cover(at: Vector3, size: Vector3, color: Color) -> void:
	var root := StaticBody3D.new()
	root.position = at
	add_child(root)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .95
	_box(root, size, Vector3(0, size.y * .5, 0), material)
	_add_collision(root, size, Vector3(0, size.y * .5, 0))
	obstacles.append(root)

func _rock(at: Vector3, radius: float, solid := true) -> void:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.position = at
	add_child(root)
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.35
	mesh.radial_segments = 9
	mesh.rings = 5
	rock.mesh = mesh
	rock.scale = Vector3(rng.randf_range(.8, 1.6), rng.randf_range(.55, .9), rng.randf_range(.8, 1.55))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("756e61") if map_id != "winter" else Color("9aa7a8")
	material.albedo_texture = load("res://assets/textures/rock-color.jpg")
	material.normal_enabled = true
	material.normal_texture = load("res://assets/textures/rock-normal.jpg")
	material.roughness = 1.0
	rock.material_override = material
	rock.position.y = radius * .35
	root.add_child(rock)
	if solid:
		_add_collision(root, Vector3(radius * 1.4, radius * .9, radius * 1.35), Vector3(0, radius * .4, 0))
		obstacles.append(root)

func _tree_cluster(at: Vector3, count: int, solid := true) -> void:
	for i in count:
		var x := at.x + rng.randf_range(-13.0, 13.0)
		var z := at.z + rng.randf_range(-13.0, 13.0)
		var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
		root.position = Vector3(x, height_at(x, z), z)
		add_child(root)
		var trunk_material := StandardMaterial3D.new()
		trunk_material.albedo_color = Color("514735")
		_add_primitive(root, CylinderMesh.new(), Vector3(.24, 2.2, .24), Vector3(0, 1.1, 0), trunk_material)
		var crown_material := StandardMaterial3D.new()
		crown_material.albedo_color = Color("394a3b") if map_id != "winter" else Color("68716d")
		crown_material.albedo_texture = load("res://assets/textures/leaf-color.jpg")
		var crown := SphereMesh.new()
		var leaf := _add_primitive(root, crown, Vector3(rng.randf_range(2.8, 4.6), rng.randf_range(3.0, 5.2), rng.randf_range(2.8, 4.6)), Vector3(0, rng.randf_range(3.4, 4.3), 0), crown_material)
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if solid:
			_add_collision(root, Vector3(.7, 3.3, .7), Vector3(0, 1.65, 0))
			obstacles.append(root)

func _tower(at: Vector3) -> void:
	var root := StaticBody3D.new()
	root.position = at
	add_child(root)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("4c5853")
	for x in [-1.8, 1.8]:
		for z in [-1.8, 1.8]:
			_box(root, Vector3(.23, 8, .23), Vector3(x, 4, z), metal)
	_box(root, Vector3(5, .3, 5), Vector3(0, 8, 0), metal)
	_box(root, Vector3(5.4, .4, 5.4), Vector3(0, 9, 0), metal)
	_add_collision(root, Vector3(4, 8, 4), Vector3(0, 4, 0))
	obstacles.append(root)

func _chimney(at: Vector3) -> void:
	var root := StaticBody3D.new()
	root.position = at
	add_child(root)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("656361")
	material.albedo_texture = load("res://assets/textures/brick-color.jpg")
	_add_primitive(root, CylinderMesh.new(), Vector3(4.2, 32, 4.2), Vector3(0, 0, 0), material)
	_add_collision(root, Vector3(4.5, 34, 4.5), Vector3(0, 0, 0))
	obstacles.append(root)

func _add_primitive(parent: Node3D, mesh: PrimitiveMesh, scale: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.scale = scale
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _box(parent: Node3D, size: Vector3, position: Vector3, material: Material, receives_shadows := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC if receives_shadows else GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(instance)
	return instance

func _add_collision(parent: Node3D, size: Vector3, at: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = at
	parent.add_child(collision)

func _create_boundary() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = _map_color("ground").darkened(.32)
	var extent := world_size * .5 + 12.0
	for point in [Vector3(-extent, 18, 0), Vector3(extent, 18, 0), Vector3(0, 18, -extent), Vector3(0, 18, extent)]:
		var root := StaticBody3D.new()
		root.position = point
		add_child(root)
		_box(root, Vector3(14, 36, world_size + 70) if point.x != 0 else Vector3(world_size + 70, 36, 14), Vector3.ZERO, material)
		_add_collision(root, Vector3(14, 36, world_size + 70) if point.x != 0 else Vector3(world_size + 70, 36, 14), Vector3.ZERO)

func _create_base() -> void:
	base_marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 10.5
	ring.outer_radius = 11.0
	ring.rings = 3
	ring.ring_segments = 48
	base_marker.mesh = ring
	base_marker.position = Vector3(0, height_at(0, 0) + .16, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("e3b95e")
	material.emission_enabled = true
	material.emission = Color("8c571e")
	base_marker.material_override = material
	add_child(base_marker)
