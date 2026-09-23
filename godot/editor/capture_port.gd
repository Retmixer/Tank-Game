extends SceneTree
## Developer-only screenshot capture; no save writes.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.get_node("GameData").persistence_enabled = false
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../work/godot-hangar.png")
	game.interface.setup()
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../work/godot-map-select.png")
	DirAccess.make_dir_recursive_absolute("res://assets/ui/maps")
	DirAccess.make_dir_recursive_absolute("res://assets/ui/vehicles")
	for spec in root.get_node("GameData").tanks:
		game.selected_tank_id = spec.id
		game._rebuild_hangar()
		game.interface.close()
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		var portrait := root.get_texture().get_image().get_region(Rect2i(360,180,720,500))
		portrait.resize(360,250)
		portrait.save_png("res://assets/ui/vehicles/%s.png" % spec.id)
	for id in ["training","desert","winter"]:
		game.selected_map = id
		game._start_battle()
		game.screen = game.Screen.PAUSE
		game._freeze_vehicles(true)
		game.hud.hide()
		game.countdown_label.hide()
		game.reticle.hide()
		game.view_camera.fov = 55
		game.view_camera.position = Vector3(0,game.arena.world_size*.65,game.arena.world_size*.5)
		game.view_camera.look_at(Vector3.ZERO)
		for i in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var preview := root.get_texture().get_image()
		preview.resize(640,360)
		preview.save_png("res://assets/ui/maps/%s.png" % id)
	game.free()
	quit()
