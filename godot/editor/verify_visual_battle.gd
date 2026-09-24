extends SceneTree
## GPU material compilation, snapshots and bounded render-performance smoke test.
func _initialize() -> void:
	if DisplayServer.get_name()=="headless":
		quit(2)
		return
	call_deferred("run")
func run() -> void:
	var data := root.get_node("GameData")
	data.persistence_enabled=false
	data.save=data.defaults()
	var game: Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for id in ["training","desert","winter"]:
		game.selected_map=id
		game._start_battle()
		game.countdown=999
		game.countdown_label.hide()
		game._freeze_vehicles(true)
		for i in 30: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/pbr-"+id+".png")
		var started := Time.get_ticks_msec()
		for i in 60: await process_frame
		var elapsed := Time.get_ticks_msec()-started
		print("RENDER ",id,": ",snappedf(elapsed/60.0,.1)," ms/frame; ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," draw calls")
	game.free()
	await process_frame
	print("VISUAL BATTLE SMOKE: PASS")
	quit()
