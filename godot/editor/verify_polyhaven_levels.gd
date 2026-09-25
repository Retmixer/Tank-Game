extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
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
		await physics_frame
		await physics_frame
		check(game.arena.get_meta("environment_revision","")=="polyhaven-2026-09",id+" active replacement scene")
		check(game.arena.get_node("Geometry/Trees").get_child_count()>=70,id+" photogrammetry vegetation")
		var terrain: StaticBody3D=game.arena.get_node("Geometry/Terrain_0000/Mesh/Collision")
		var shape := BoxShape3D.new()
		shape.size=Vector3(4.0,1.5,6.0)
		for team in ["TeamA","TeamB"]:
			for marker in game.arena.get_node("Spawns/"+team).get_children():
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape=shape
				query.transform=marker.global_transform.translated(Vector3.UP*1.1)
				var excluded: Array[RID]=[terrain.get_rid()]
				for tank in game.tanks: excluded.append(tank.get_rid())
				query.exclude=excluded
				query.collision_mask=1
				check(game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(),id+" spawn clearance "+team+str(marker.name))
		var nav=game.ai_navigation
		var work := 0
		while not nav.ready and work<500:
			nav.update()
			work+=1
		check(nav.ready,id+" navigation completed")
		for team in 2:
			var start: Vector3=game.arena.spawn_transform(team,3).origin
			var route: PackedVector3Array=nav.route(start,game.arena.get_node("CapturePoint").global_position)
			check(route.size()>2,id+" team "+str(team)+" can reach center")
		game.countdown=0
		var before: Vector3=game.player.position
		Input.action_press("forward")
		for frame in 150: await physics_frame
		Input.action_release("forward")
		check(game.player.position.distance_to(before)>2,id+" player leaves spawn")
		check(game.player.position.y>-30,id+" terrain collision")
		print("MAP CHECK ",id," nodes=",game.arena.find_children("*","MeshInstance3D",true,false).size()," nav=",nav.graph.get_point_count())
	game.free()
	await process_frame
	print("POLY HAVEN MAPS: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
