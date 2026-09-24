extends SceneTree
var failures: Array[String]=[]
var capture := false
func _initialize() -> void:
	capture="--capture" in OS.get_cmdline_user_args()
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func frames() -> void:
	for i in 6: await process_frame
func shot(id: String) -> void:
	await frames()
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/reference-"+id+".png")
func run() -> void:
	var data := root.get_node("GameData")
	data.persistence_enabled=false
	data.save=data.defaults()
	data.save.silver=99999
	data.save.xp=99999
	var game: Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var ui: Node=game.interface
	await frames()
	check(ui.field("Workshop")==null,"Hangar must use actual 3D environment, not a background image")
	check(game.arena.map_id=="hangar" and game.view_camera.cull_mask!=0,"3D hangar rendered")
	game._show_armor_preview()
	await frames()
	check(ui.armor_visible,"Hangar mask state")
	check(game.tanks[0].find_children("*","MeshInstance3D",true,false)[0].material_overlay!=null,"Hangar armor overlay")
	game._show_armor_preview()
	ui.research()
	var before: int=data.save.silver
	ui.field("Tank2").pressed.emit()
	check(data.save.silver==before,"Card selection must never spend currency")
	check(ui.field("VehicleName").text==data.tank_by_id("0-2").name,"Selected detail matches actual tank")
	ui.field("Unlock").pressed.emit()
	check(data.save.owned.get("0-2",false),"Explicit research purchase")
	check(data.save.silver==before-4800,"Correct research price")
	ui.field("Unlock").pressed.emit()
	check(game.selected_tank_id=="0-2","Owned tank goes to hangar")
	check(ui.field("Vehicles").get_child_count()==3,"Purchased tank appended before buy shortcut")
	check(ui.field("Vehicles").get_child(1).get_node("Caption").text==data.tank_by_id("0-2").name,"Acquisition order")
	ui.research()
	ui.field("Filter1").pressed.emit()
	check(ui.field("Tank0").visible and not ui.field("Tank1").visible,"Class filter")
	ui.field("Filter0").pressed.emit()
	ui.field("OwnedFilter").pressed.emit()
	check(not ui.field("Tank0").visible and ui.field("Tank1").visible,"Owned filter")
	ui.field("OwnedFilter").pressed.emit()
	ui.field("Nation2").pressed.emit()
	check(ui.field("VehicleName").text==data.tank_by_id("2-2").name,"Nation switches entire tree and detail")
	data.save.silver=0
	ui.research()
	check(ui.field("Unlock").disabled,"Insufficient funds block purchase")
	data.save.silver=99999
	ui.research_nation=0
	ui.research_selection=0
	ui.research()
	ui.field("InfoTab1").pressed.emit()
	check(ui.field("InfoContent").visible and not ui.field("StatContent").visible,"Module detail tab")
	ui.field("InfoTab0").pressed.emit()
	await shot("research")
	for spec in data.tanks: data.save.owned[spec.id]=true
	ui.select_vehicle("0-1")
	await shot("hangar")
	# The full design must fit common phone-landscape, laptop and ultrawide viewports.
	for resolution in [Vector2i(960,540),Vector2i(1280,800),Vector2i(2560,1080)]:
		root.size=resolution
		await frames()
		var rect: Rect2=ui.field("VehicleInfo").get_global_rect()
		var logical_size := root.get_visible_rect().size
		check(rect.position.x>=0 and rect.end.y<=logical_size.y+1,"Hangar fits "+str(resolution))
		check(not rect.intersects(ui.field("Modules").get_global_rect()),"Side panels must never overlap")
	root.size=Vector2i(1672,941)
	game._start_battle()
	check(game.view_camera.cull_mask!=0,"World visible after closing showroom")
	check(game.arena.get_node("Environment").environment.ssao_enabled,"Saved graphics applied to new battlefield")
	game._show_pause()
	await shot("battle")
	game.free()
	await process_frame
	print("REFERENCE UI VERIFICATION: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
