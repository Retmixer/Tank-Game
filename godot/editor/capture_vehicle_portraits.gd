extends SceneTree
## Render the actual editable models, not invented promotional tanks. Transparent PNGs.
func _initialize() -> void:
	if DisplayServer.get_name()=="headless":
		quit(2)
		return
	call_deferred("run")

func run() -> void:
	var data := root.get_node("GameData")
	data.persistence_enabled=false
	DirAccess.make_dir_recursive_absolute("res://assets/ui/portraits")
	var viewport := SubViewport.new()
	viewport.size=Vector2i(640,360)
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.msaa_3d=Viewport.MSAA_4X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_CLEAR_COLOR
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("b8c7d8")
	env.ambient_light_energy=.5
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled=true
	env.ssao_intensity=2.0
	env_node.environment=env
	world.add_child(env_node)
	for i in 2:
		var light := DirectionalLight3D.new()
		light.rotation_degrees=Vector3(-40,-35 if i==0 else 140,0)
		light.light_color=Color("fff0ce") if i==0 else Color("afc6e0")
		light.light_energy=2.0 if i==0 else .65
		light.shadow_enabled=i==0
		world.add_child(light)
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=5.0
	world.add_child(camera)
	camera.position=Vector3(9,4.8,11)
	camera.look_at(Vector3(0,1.4,0))
	for spec in data.tanks:
		var vehicle: Node=load("res://scenes/vehicles/%s.tscn"%spec.id).instantiate()
		# Extract only the visual branch: no physics/audio/scripts tick in the preview renderer.
		var visual: Node3D=vehicle.get_node("Visual").duplicate()
		vehicle.free()
		world.add_child(visual)
		visual.rotation.y=0
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		var img := viewport.get_texture().get_image()
		assert(img.save_png("res://assets/ui/portraits/%s.png"%spec.id)==OK)
		visual.free()
	viewport.queue_free()
	await process_frame
	print("12 transparent vehicle portraits rendered")
	quit()
