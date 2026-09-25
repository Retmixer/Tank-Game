extends SceneTree
func _initialize() -> void:
	if DisplayServer.get_name()=="headless":
		quit(2)
		return
	call_deferred("run")
func run() -> void:
	var data := root.get_node("GameData")
	data.persistence_enabled=false
	data.save=data.defaults()
	root.size=Vector2i(1280,720)
	var game: Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../work/polyhaven-captures"))
	for id in ["training","desert","winter"]:
		game.selected_map=id
		game._start_battle()
		game.screen=game.Screen.PAUSE
		game._freeze_vehicles(true)
		game.interface.close()
		game.hud.hide()
		game.reticle.hide()
		game.countdown_label.hide()
		game.view_camera.make_current()
		for view in ["ground","overview"]:
			game.view_camera.fov=65
			game.view_camera.position=Vector3(-105,65,135) if view=="ground" else Vector3(0,145,190)
			game.view_camera.look_at(Vector3(0,5,0))
			for frame in 12: await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.save_png("res://../work/polyhaven-captures/"+id+"-"+view+".png")
			print("CAPTURE ",id," ",view," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	game.free()
	await process_frame
	quit()
