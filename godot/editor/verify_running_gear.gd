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
	for spec in data.tanks:
		data.save.owned[spec.id]=true
	var game: Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var ui: Node=game.interface
	var shelf: ScrollContainer=ui.field("VehicleScroll")
	check(ui.field("Vehicles").get_child_count()==12,"Owned collection")
	shelf.scroll_horizontal=900
	ui.select_vehicle("2-3")
	await process_frame
	await process_frame
	shelf=ui.field("VehicleScroll")
	check(shelf.scroll_horizontal>900,"Selected card should be visible after rebuild")
	var scroll_before := shelf.scroll_horizontal
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_WHEEL_UP
	event.pressed=true
	shelf.handle_input(event)
	check(shelf.scroll_horizontal<scroll_before,"Mouse wheel must scroll horizontally")
	game._show_armor_preview()
	check(ui.armor_visible,"Armor toggle")
	check(game.tanks[0].find_children("*","MeshInstance3D",true,false)[0].material_overlay!=null,"Armor shader on model")
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/godot-armor-fixed.png")
	game._show_armor_preview()
	check(game.tanks[0].find_children("*","MeshInstance3D",true,false)[0].material_overlay==null,"Original materials restored")
	check(InputMap.action_get_events("turn_left")[0].physical_keycode==KEY_D,"D binding")
	check(InputMap.action_get_events("turn_right")[0].physical_keycode==KEY_A,"A binding")
	game._start_battle()
	check(ui.page==null,"Hangar must close when battle starts")
	game.countdown=0
	var tank: Node=game.player
	Input.action_press("forward")
	for i in 50:
		await physics_frame
	Input.action_release("forward")
	tank.tracks_broken=true
	tank.repair_left=10
	var heading: float=tank.hull_heading
	Input.action_press("turn_right")
	for i in 8:
		await physics_frame
	Input.action_release("turn_right")
	check(is_equal_approx(tank.hull_heading,heading),"Broken track must prevent pivot turn")
	check(absf(tank.move_speed)<.01,"Broken track must stop propulsion")
	for wheel in tank.running_gear.wheels:
		check(absf(wheel.offset)<=tank.running_gear.suspension_travel+.001,"Suspension bounded")
	tank.repair_left=.03
	for i in 4:
		await physics_frame
	check(not tank.tracks_broken,"Track repair restores propulsion")
	game.screen=game.Screen.PAUSE
	tank.move_speed=0
	tank.set_controls(Vector2(1,0),Vector3.ZERO,false)
	for wheel in tank.running_gear.wheels:
		wheel.spin=0
	for i in 8:
		await physics_frame
	var left_spin := 0.0
	var right_spin := 0.0
	for wheel in tank.running_gear.wheels:
		if wheel.rest.x<0:
			left_spin+=wheel.spin
		else:
			right_spin+=wheel.spin
	check(left_spin*right_spin<0,"Pivot turn needs opposite wheel rotation")
	if DisplayServer.get_name()!="headless":
		check(tank.running_gear.belts.size()==4,"Four animated belt meshes")
		for belt in tank.running_gear.belts:
			check(belt.node.multimesh!=load(belt.node.multimesh.resource_path) if not belt.node.multimesh.resource_path.is_empty() else true,"Private belt resource")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/godot-tracks-fixed.png")
	game.free()
	await process_frame
	print("RUNNING GEAR / HANGAR: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
