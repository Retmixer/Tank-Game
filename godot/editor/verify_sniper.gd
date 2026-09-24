extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func run() -> void:
	root.get_node("GameData").persistence_enabled=false
	var game: Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game._start_battle()
	game.countdown=0
	game.countdown_label.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game._freeze_vehicles(true)
	var tank: Node=game.player
	game._update_camera(.2)
	var entry_position: Vector3=game.view_camera.global_position
	var entry_fov: float=game.view_camera.fov
	game._set_scoped(true)
	game._update_camera(1.0/60)
	check(game.view_camera.global_position.distance_to(entry_position)<.2,"Scope entry must not teleport in first frame")
	check(absf(game.view_camera.fov-entry_fov)<1.0,"Scope FOV starts smoothly")
	var toward: Vector3=-tank.global_position
	game.camera_yaw=atan2(-toward.x,-toward.z)
	game.camera_pitch=0
	for i in 90:
		game._update_camera(1.0/60)
		game._update_aim()
		tank._update_turret(game.aim_point,1.0/60)
		await process_frame
	check(game.view_camera.global_position.distance_to(tank.cannon.global_position)<.5,"Sniper camera must be at gun, not behind tank")
	check(game.view_camera.fov<30,"Tank-specific optical zoom")
	check(game.reticle.size.x>1000,"Reticle uses viewport coordinates")
	var barrel: Vector3=tank.cannon.global_basis.z.normalized()
	tank.aim_spread=.19
	var max_angle: float=tank.dispersion_angle()
	for i in 500:
		var shot: Vector3=game._aim_direction(tank)
		check(barrel.angle_to(shot)<=max_angle+.0002,"Shot outside displayed dispersion cone")
	var before: float=tank.aim_spread
	game._fire_shell(tank,1)
	check(tank.aim_spread>before,"Shot must expand reticle")
	for i in 240:
		tank._update_dispersion(1.0/60,0)
	check(tank.aim_spread<.25,"Reticle converges while stationary")
	for i in 30:
		tank._update_dispersion(1.0/60,tank.spec.speed)
	check(tank.aim_spread>.65,"Movement expands reticle")
	game.camera_yaw+=.5
	game._update_camera(.2)
	game._update_aim()
	check(barrel.angle_to(-game.view_camera.global_basis.z)>.3,"Camera should be able to lead turret")
	for i in 2:
		await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/godot-sniper.png")
	for i in 180:
		game._update_camera(1.0/60)
		game._update_aim()
		tank._update_turret(game.aim_point,1.0/60)
		tank._update_dispersion(1.0/60,0)
	game._update_hud()
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/godot-sniper-settled.png")
	game._set_scoped(false)
	var exit_position: Vector3=game.view_camera.global_position
	game._update_camera(1.0/60)
	check(game.view_camera.global_position.distance_to(exit_position)<.2,"Scope exit starts smoothly")
	game._update_camera(1)
	game._set_scope_model_visibility()
	for mesh in tank.find_children("*","GeometryInstance3D",true,false):
		check(mesh.layers==int(mesh.get_meta("normal_layers")),"Restore tank render layers")
	check(game.view_camera.global_position.distance_to(tank.global_position)>8,"Return to third person")
	game.free()
	await process_frame
	print("SNIPER VERIFICATION: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
