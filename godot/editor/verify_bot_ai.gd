extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func run() -> void:
	var data := root.get_node("GameData")
	data.persistence_enabled=false
	data.save=data.defaults()
	data.save.team_size=7
	var game: Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game._start_battle()
	game.screen=game.Screen.PAUSE
	game._freeze_vehicles(true)
	check(game.bot_brains.size()==13,"13 individual brains in 7x7")
	var roles := {}
	for brain in game.bot_brains:
		roles[brain.role]=true
	check(roles.size()>=3,"Distinct class roles")
	var brain=game.bot_brains[0]
	var bot: Node=brain.tank
	var enemy: Node
	for tank in game.tanks:
		tank.position=Vector3(3000+100*tank.get_index(),1000,3000)
		if tank.team!=bot.team:
			enemy=tank
	bot.position=Vector3(0,1000,0)
	bot.rotation=Vector3.ZERO
	bot.hull_heading=0
	enemy.position=Vector3(0,1000,-45)
	await physics_frame
	await physics_frame
	brain.perceive()
	check(brain.target==enemy,"Visible enemy acquired")
	var spotted: int=bot.spotted
	brain.perceive()
	check(bot.spotted==spotted,"Spot reward is not farmed every tick")
	check(brain.reaction_left>0,"Reaction time before shooting")
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(30,8,3)
	shape.shape=box
	wall.add_child(shape)
	game.add_child(wall)
	wall.position=Vector3(0,1002,-22)
	await physics_frame
	await physics_frame
	brain.perceive()
	check(brain.target==null,"Cannot see through cover")
	check(brain.memory_left>0,"Remembers last seen position")
	var last_seen: Vector3=brain.last_seen
	enemy.position.x=5
	await physics_frame
	await physics_frame
	brain.perceive()
	check(brain.last_seen==last_seen,"Cannot track invisible enemy")
	brain.memory_left=0
	brain.role="assault"
	game.capture_progress=-60 if bot.team==0 else 60
	brain.choose_goal()
	check(brain.goal=="defend","Responds to enemy base capture")
	bot.hp=bot.max_hp*.1
	brain.choose_goal()
	check(brain.goal=="retreat","Damaged bot retreats")
	bot.hp=bot.max_hp
	game.capture_progress=0
	wall.queue_free()
	await process_frame
	brain.objective=bot.position+Vector3(80,0,0)
	# Add ground for the local driver probes in the isolated test area.
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size=Vector3(300,2,300)
	floor_shape.shape=floor_box
	floor_body.add_child(floor_shape)
	game.add_child(floor_body)
	floor_body.position=Vector3(0,999,0)
	await physics_frame
	await physics_frame
	brain.previous_position=bot.position
	bot.drive_input=Vector2.ZERO
	check(brain.steer(.22).x<0,"Correct steering toward right-hand waypoint")
	bot.drive_input=Vector2(0,1)
	brain.previous_position=bot.position
	check(brain.steer(2.5).y<0,"Stuck recovery reverses")
	enemy.position=Vector3(0,1000,-45)
	await physics_frame
	brain.perceive()
	brain.reaction_left=0
	bot.reload_left=0
	bot.aim_spread=.2
	var aiming: Vector3=enemy.position+Vector3.UP*1.2
	for i in 80:
		bot._update_turret(aiming,.1)
	check(brain.ready_to_fire(aiming),"Aimed clear shot permitted")
	var ally: Node=game.player if game.player.team==bot.team else game.ai_tanks[1]
	if ally==bot or ally.team!=bot.team:
		for tank in game.tanks:
			if tank!=bot and tank.team==bot.team:
				ally=tank
	ally.position=Vector3(0,1000,-20)
	await physics_frame
	await physics_frame
	check(not brain.ready_to_fire(aiming),"Ally in firing line prevents shot")
	game.free()
	await process_frame
	print("TACTICAL BOT AI: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
