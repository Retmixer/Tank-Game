extends SceneTree
## Headless integration checks; never touches the player's real save.
var game: Node
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var data := root.get_node("GameData")
	data.set("persistence_enabled",false)
	data.save = data.defaults()
	data.save.silver = 99999
	data.save.xp = 99999
	for spec in data.tanks:
		var vehicle: Node = load("res://scenes/vehicles/%s.tscn" % spec.id).instantiate()
		check(vehicle.find_children("*","MeshInstance3D",true,false).size() > 20,"Detailed mesh count: "+spec.id)
		check(vehicle.find_child("Muzzle",true,false)!=null,"Missing muzzle: "+spec.id)
		check(vehicle.definition != null,"Missing Inspector definition: "+spec.id)
		var belts: Array[Node] = vehicle.find_children("*","MultiMeshInstance3D",true,false)
		check(belts.size()==4,"Missing complete track belts: "+spec.id)
		for belt in belts:
			check(belt.multimesh.instance_count==72,"Track link instances lost: "+spec.id)
		vehicle.free()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.arena.map_id == "hangar","Hangar scene not loaded")
	game.interface.setup()
	check(game.interface.field("training")!=null,"Map selector missing")
	game.interface.research()
	game.interface.hangar()
	for id in ["training","desert","winter"]:
		game.selected_map = id
		game._start_battle()
		await physics_frame
		await physics_frame
		check(game.tanks.size()==6,"Roster not 3x3: "+id)
		check(game.arena.find_children("*","CollisionShape3D",true,false).size()>50,"Missing level collisions: "+id)
		check(game.arena.get_node("Spawns/TeamA").get_child_count()==7,"Spawn markers: "+id)
		game.countdown = 0.0
		var start: Vector3 = game.player.global_position
		Input.action_press("forward")
		for frame in 120:
			await physics_frame
		Input.action_release("forward")
		check(game.player.global_position.distance_to(start) > .1,"Vehicle cannot leave spawn: "+id)
		check(game.player.global_position.y > -25,"Vehicle fell through terrain: "+id)
		game._fire_shell(game.player,1)
		await physics_frame
		check(game.shells.size()>0,"Shot not created: "+id)
		game._show_pause()
		var paused: Vector3 = game.player.global_position
		for frame in 4:
			await physics_frame
		check(game.player.global_position.is_equal_approx(paused),"Pause does not freeze: "+id)
		game._show_settings()
		game._close_settings()
		check(game.screen == game.Screen.PAUSE,"Settings should return to pause")
		game._resume_battle()
		game._finish_battle(true,"Integration test")
		check(game.interface.field("Title").text=="ПОБЕДА!","Results screen missing")
		game._return_to_hangar()
		await process_frame
		print("PASS level flow: ",id)
	game.free()
	await process_frame
	print("PORT VERIFICATION: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
