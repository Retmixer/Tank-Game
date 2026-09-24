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
	game.set_process(false)
	game.set_physics_process(false)
	game._freeze_vehicles(true)
	game.countdown_label.hide()
	game.hud.hide()
	game.reticle.hide()
	var origin: Vector3=game.player.global_position+Vector3.UP*4
	game.view_camera.global_position=origin+Vector3(3,3,12)
	game.view_camera.look_at(origin)
	var originals := []
	for i in 5:
		var effect: Node=game._combat_burst(origin+Vector3((i-2)*3,0,0),["muzzle","penetration","ricochet","blocked","ground"][i],Vector3(.7,.7,0))
		check(effect!=null,"Effect created")
		originals.append(effect.get_node("Sparks").process_material)
	check(originals[0]!=originals[1],"Particle settings must not be shared")
	await create_timer(.35).timeout
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/godot-combat-effects.png")
	for i in 40:
		game._combat_burst(origin,"ground",Vector3.UP)
	check(get_nodes_in_group("combat_effects").size()<=32,"Concurrent visual effect limit")
	await create_timer(1.6).timeout
	check(get_nodes_in_group("combat_effects").is_empty(),"Effects are cleaned up")
	game._fire_shell(game.player,1)
	check(game.player.recoil_amount>0,"Physical barrel recoil")
	check(game.camera_trauma>0,"Camera feedback")
	# Actual grazing hit: ensure the ricochet callback occurs before the shell bounces.
	var target: Node
	for tank in game.tanks:
		if tank.team!=game.player.team:
			target=tank
			break
	target.position=Vector3(0,1000,0)
	target.rotation=Vector3.ZERO
	await physics_frame
	await physics_frame
	var hull: CollisionShape3D=target.get_node("HullCollision")
	var shape: BoxShape3D=hull.shape
	var direction := Vector3(.98,0,.2).normalized()
	var hit_point: Vector3=target.position+Vector3(0,1.1,-shape.size.z*.5)
	var shell: Node=load("res://scenes/projectiles/shell.tscn").instantiate()
	game.add_child(shell)
	shell.launch(game.player,10000,direction)
	shell.global_position=hit_point-direction*4
	var calls := [0,false]
	shell.impact_event=func(_point: Vector3,_vehicle: bool,outcome: Dictionary) -> void:
		calls[0]+=1
		calls[1]=outcome.get("ricochet",false)
	for i in 3:
		await physics_frame
	check(calls[0]>0 and calls[1],"Ricochet sends visual/audio event")
	check(is_instance_valid(shell) and shell.ricochets>0,"Ricochet shell continues flying")
	if is_instance_valid(shell):
		shell.queue_free()
	game.free()
	await process_frame
	print("COMBAT EFFECTS: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
