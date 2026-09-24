extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var data := root.get_node("GameData")
	data.persistence_enabled=false
	data.save=data.defaults()
	data.save.team_size=7
	var game: Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	Engine.time_scale=4
	var failed := false
	for id in ["training","desert","winter"]:
		game.selected_map=id
		game._start_battle()
		game.countdown=0
		var starts: Array[Vector3]=[]
		for bot in game.ai_tanks:
			starts.append(bot.global_position)
		for i in 1800:
			await physics_frame
		var moved := 0
		var shots := 0
		var nearest := INF
		var goals := {}
		for i in game.ai_tanks.size():
			var bot: Node=game.ai_tanks[i]
			if bot.global_position.distance_to(starts[i])>8:
				moved+=1
			shots+=bot.shot_sequence
			nearest=minf(nearest,Vector2(bot.position.x,bot.position.z).length())
			goals[bot.get_meta("ai_goal","")]=true
		print("AI SIM ",id,": progressed ",moved,"/13; shots ",shots,"; nearest base ",snappedf(nearest,.1),"; goals ",goals.keys())
		if moved<9:
			failed=true
			push_error("Most bots failed to leave spawn: "+id)
		if shots==0:
			failed=true
			push_error("No combat during long simulation: "+id)
		if not game.ai_navigation.ready or game.ai_navigation.graph.get_point_count()<100:
			failed=true
			push_error("Navigation graph missing: "+id)
		game._return_to_hangar()
		await process_frame
	Engine.time_scale=1
	game.free()
	await process_frame
	quit(1 if failed else 0)
