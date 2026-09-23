extends SceneTree
## Offline converter only. Never runs at game startup.
var source: Dictionary
var materials: Dictionary = {}

func _initialize() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Scene conversion needs a rendering device to serialize MultiMesh buffers. Run without --headless.")
		quit(2)
		return
	if FileAccess.file_exists("res://scenes/levels/training.tscn") and not "--replace-authored" in OS.get_cmdline_user_args():
		push_error("Authored scenes exist. Commit editor changes before using --replace-authored.")
		quit(2)
		return
	source = JSON.parse_string(FileAccess.get_file_as_string("res://editor/source_manifest.json"))
	for folder in ["materials", "resources/vehicles", "scenes/vehicles", "scenes/levels", "scenes/props"]:
		DirAccess.make_dir_recursive_absolute("res://" + folder)
	_build_materials()
	for data in source.tanks:
		_build_vehicle(data)
	for data in source.maps:
		_build_level(data)
	for data in source.assets:
		var prop := _visual(data.file)
		prop.name = data.name
		_collision(prop)
		_save(prop, "res://scenes/props/%s.tscn" % data.name)
	print("EDITOR SCENES BUILT: 12 vehicles, 4 levels, reusable props and shared materials")
	quit()

func _save(node: Node, path: String) -> void:
	var asset_folder := "res://assets/native/" + path.get_file().get_basename()
	DirAccess.make_dir_recursive_absolute(asset_folder)
	_externalize(node,asset_folder,[0])
	_own(node, node)
	var packed := PackedScene.new()
	assert(packed.pack(node) == OK, path)
	assert(ResourceSaver.save(packed, path) == OK, path)
	node.free()

func _externalize(node: Node, folder: String, counter: Array) -> void:
	# Individual mesh/shape files keep authored scenes small and merge-friendly.
	counter[0] += 1
	var stem := "%s/%04d_%s" % [folder,counter[0],node.name]
	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh.duplicate()
		for surface in mesh.get_surface_count():
			mesh.surface_set_material(surface,node.get_active_material(surface))
		mesh.take_over_path(stem+".res")
		ResourceSaver.save(mesh,stem+".res",ResourceSaver.FLAG_COMPRESS)
		node.mesh = mesh
	elif node is CollisionShape3D:
		node.shape.take_over_path(stem+".res")
		ResourceSaver.save(node.shape,stem+".res",ResourceSaver.FLAG_COMPRESS)
	elif node is MultiMeshInstance3D:
		node.multimesh.take_over_path(stem+".res")
		ResourceSaver.save(node.multimesh,stem+".res",ResourceSaver.FLAG_COMPRESS)
	for child in node.get_children():
		_externalize(child,folder,counter)

func _own(node: Node, root_node: Node) -> void:
	node.scene_file_path = ""
	if node != root_node:
		node.owner = root_node
	for child in node.get_children():
		_own(child, root_node)

func _matrix(a: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(a[0],a[1],a[2]),Vector3(a[4],a[5],a[6]),Vector3(a[8],a[9],a[10])),Vector3(a[12],a[13],a[14]))

func _build_materials() -> void:
	for key in source.materials:
		var data: Dictionary = source.materials[key]
		var material := StandardMaterial3D.new()
		material.resource_name = key
		material.albedo_color = Color(data.color[0],data.color[1],data.color[2],data.alpha).linear_to_srgb()
		material.roughness = data.roughness
		material.metallic = data.metallic
		material.vertex_color_use_as_albedo = data.vertex_color
		if data.texture:
			material.albedo_texture = load("res://" + data.texture)
		if data.normal:
			material.normal_enabled = true
			material.normal_texture = load("res://" + data.normal)
			material.normal_scale = .4
		if data.roughness_texture:
			material.roughness_texture = load("res://" + data.roughness_texture)
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		material.uv1_scale = Vector3(data.repeat[0],data.repeat[1],1)
		if data.double_sided:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if data.alpha_test > 0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold = data.alpha_test
		elif data.get("transparent",false) or data.alpha < 1:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var final_material: Material = material
		if data.texture and "paint-color" in str(data.texture):
			var paint := ShaderMaterial.new()
			paint.shader = load("res://materials/vehicle_paint.gdshader")
			paint.set_shader_parameter("wear_map",material.albedo_texture)
			paint.set_shader_parameter("paint_color",material.albedo_color)
			paint.set_shader_parameter("metalness",float(data.metallic))
			final_material = paint
		final_material.take_over_path("res://materials/%s.tres" % key)
		ResourceSaver.save(final_material, "res://materials/%s.tres" % key)
		materials[key] = final_material

func _visual(file: String) -> Node3D:
	var scene := load("res://" + file) as PackedScene
	assert(scene != null, file)
	var node := scene.instantiate() as Node3D
	for mesh in _meshes(node):
		for i in mesh.mesh.get_surface_count():
			var old: Material = mesh.mesh.surface_get_material(i)
			if old and materials.has(old.resource_name):
				mesh.set_surface_override_material(i, materials[old.resource_name])
	_collapse_instances(node)
	return node

func _collapse_instances(node: Node) -> void:
	for child in node.get_children():
		if child.name.begins_with("Instances_"):
			var instances := child.get_children()
			var first := instances[0] as MeshInstance3D
			assert(first != null)
			var mesh: Mesh = first.mesh.duplicate()
			for surface in mesh.get_surface_count():
				mesh.surface_set_material(surface,first.get_active_material(surface))
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = mesh
			multimesh.instance_count = instances.size()
			for i in instances.size():
				multimesh.set_instance_transform(i,instances[i].transform)
			var batch := MultiMeshInstance3D.new()
			batch.name = child.name
			batch.multimesh = multimesh
			batch.transform = child.transform
			node.remove_child(child)
			node.add_child(batch)
			child.free()
		else:
			_collapse_instances(child)

func _meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_meshes(child))
	return result

func _collision(node: Node) -> void:
	for mesh in _meshes(node):
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape := CollisionShape3D.new()
		shape.name = "Shape"
		shape.shape = mesh.mesh.create_trimesh_shape()
		body.add_child(shape)
		mesh.add_child(body)

func _build_vehicle(data: Dictionary) -> void:
	var definition := load("res://scripts/vehicle_definition.gd").new() as Resource
	var mapping := {"vehicle_id":"id","display_name":"name","hit_points":"hp","damage":"damage","armor":"armor","reload_seconds":"reload","track_health":"tracks","speed":"speed","reverse_speed":"reverse","turn_speed":"turn","turret_speed":"turret","view_distance":"view","dispersion":"spread","aim_seconds":"aim","zoom":"zoom"}
	for key in mapping:
		definition.set(key, data[mapping[key]])
	definition.take_over_path("res://resources/vehicles/%s.tres" % data.id)
	ResourceSaver.save(definition,"res://resources/vehicles/%s.tres" % data.id)
	var tank := CharacterBody3D.new()
	tank.name = "Tank_" + data.id.replace("-","_")
	tank.set_script(load("res://scripts/tank.gd"))
	tank.set("definition", definition)
	tank.floor_snap_length = .8
	tank.floor_max_angle = deg_to_rad(38)
	var visual := _visual(data.file)
	visual.name = "Visual"
	visual.rotation.y = PI
	tank.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.name = "HullCollision"
	var box := BoxShape3D.new()
	box.size = Vector3(data.width+.28,1.7,data.length)
	collision.shape = box
	collision.position.y = 1.03
	tank.add_child(collision)
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position.z = data.barrel_length + .5
	var pivot := visual.find_child("GunPivot",true,false)
	assert(pivot != null, data.id)
	pivot.add_child(muzzle)
	var audio := AudioStreamPlayer3D.new()
	audio.name = "EngineAudio"
	audio.stream = load("res://assets/audio/engine.ogg")
	audio.max_distance = 90
	audio.unit_size = 16
	tank.add_child(audio)
	_save(tank,"res://scenes/vehicles/%s.tscn" % data.id)

func _build_level(data: Dictionary) -> void:
	var level := Node3D.new()
	level.name = data.id.capitalize()
	level.set_script(load("res://scripts/arena.gd"))
	level.set("map_id",data.id)
	level.set("world_size",float(data.size))
	var geometry := Node3D.new()
	geometry.name = "Geometry"
	level.add_child(geometry)
	for record in data.objects:
		var visual := _visual(record.file)
		visual.name = record.name
		if record.has("instances"):
			var meshes := _meshes(visual)
			assert(meshes.size() == 1, record.name)
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			var mesh: Mesh = meshes[0].mesh.duplicate()
			for surface in mesh.get_surface_count():
				mesh.surface_set_material(surface,meshes[0].get_active_material(surface))
			multimesh.mesh = mesh
			multimesh.instance_count = record.instances.size()
			for i in record.instances.size():
				multimesh.set_instance_transform(i,_matrix(record.instances[i]))
			var batch := MultiMeshInstance3D.new()
			batch.name = record.name
			batch.multimesh = multimesh
			batch.transform = _matrix(record.transform)
			geometry.add_child(batch)
			visual.free()
			continue
		visual.transform = _matrix(record.transform)
		geometry.add_child(visual)
		if record.name.begins_with("Terrain"):
			_collision(visual)
			var ground_material := ShaderMaterial.new()
			ground_material.shader = load("res://materials/terrain.gdshader")
			var texture_id: String = data.id if data.id != "hangar" else "road"
			ground_material.set_shader_parameter("ground_map",load("res://assets/textures/%s-color.jpg" % texture_id))
			ground_material.set_shader_parameter("rock_map",load("res://assets/textures/rock-color.jpg"))
			ground_material.set_shader_parameter("tint",Color("899783") if data.id == "training" else Color.WHITE)
			ground_material.take_over_path("res://materials/terrain_%s.tres" % data.id)
			ResourceSaver.save(ground_material,"res://materials/terrain_%s.tres" % data.id)
			for mesh in _meshes(visual):
				mesh.material_override = ground_material
		else:
			for solid_name in record.solid_nodes:
				var solid: Node = visual if record.solid else visual.find_child(solid_name,true,false)
				if solid:
					_collision(solid)
	var spawns := Node3D.new()
	spawns.name = "Spawns"
	level.add_child(spawns)
	for team in 2:
		var group := Node3D.new()
		group.name = "TeamA" if team == 0 else "TeamB"
		spawns.add_child(group)
		for i in data.spawns[team].size():
			var marker := Marker3D.new()
			marker.name = "Spawn%d" % i
			var xyz: Array = data.spawns[team][i]
			marker.position = Vector3(xyz[0],xyz[1],xyz[2])
			marker.rotation.y = -3*PI/4 if team == 0 else PI/4
			group.add_child(marker)
	var capture := Marker3D.new()
	capture.name = "CapturePoint"
	level.add_child(capture)
	var env_node := WorldEnvironment.new()
	env_node.name = "Environment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color.hex(int(data.sky)*256+255)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = .35
	if data.id == "hangar":
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("a9b5c1")
		env.ambient_light_energy = .45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	level.add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48,-30,0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160
	level.add_child(sun)
	if data.id == "hangar":
		var fill := OmniLight3D.new()
		fill.name = "WorkshopLight"
		fill.position = Vector3(-3,7,3)
		fill.omni_range = 26
		fill.light_color = Color("ffdfad")
		fill.light_energy = 1.3
		level.add_child(fill)
	var overview := Camera3D.new()
	overview.name = "EditorOverview"
	overview.position = Vector3(18,12,22) if data.id == "hangar" else Vector3(0,data.size*.68,data.size*.43)
	overview.rotation_degrees.x = -30 if data.id == "hangar" else -58
	level.add_child(overview)
	_save(level,"res://scenes/levels/%s.tscn" % data.id)
