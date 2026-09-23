extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.get_node("GameData").persistence_enabled=false
	var boot: Node=load("res://scenes/boot.tscn").instantiate()
	root.add_child(boot)
	current_scene=boot
	var started := Time.get_ticks_msec()
	while is_instance_valid(boot) and Time.get_ticks_msec()-started<30000:
		await process_frame
	if current_scene==boot or current_scene==null:
		push_error("Startup did not transition into hangar")
		quit(1)
		return
	assert(current_scene.interface.page.name=="Hangar")
	assert(not current_scene.interface.busy)
	current_scene.free()
	await process_frame
	print("BOOT VERIFICATION: PASS")
	quit()
