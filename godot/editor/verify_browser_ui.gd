extends SceneTree
var game: Node
var failures: Array[String] = []
var capture := false

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func shot(id: String) -> void:
	await process_frame
	await process_frame
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/ui-"+id+".png")

func run() -> void:
	var data := root.get_node("GameData")
	data.persistence_enabled=false
	data.save=data.defaults()
	data.save.silver=99999
	data.save.xp=99999
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await shot("hangar")
	var ui: Node=game.interface
	ui.research()
	await shot("research")
	ui.hangar()
	var before: int=data.save.silver
	ui.field("Upgrade_armor").pressed.emit()
	check(data.save.silver==before,"Selecting module must not purchase it")
	ui.field("UpgradeConfirm").pressed.emit()
	check(data.save.silver==before-300,"Upgrade confirmation price")
	ui.setup()
	await shot("maps")
	ui.field("desert").pressed.emit()
	check(game.selected_map=="desert","Map selection")
	game._show_settings()
	var volume: float=game.runtime_settings.volume
	ui.field("Volume").value=.1
	ui.field("Back").pressed.emit()
	check(is_equal_approx(game.runtime_settings.volume,volume),"Cancel settings changed volume")
	game._show_settings()
	await shot("settings")
	ui.field("TabSound").pressed.emit()
	check(ui.field("Sound").visible and not ui.field("Graphics").visible,"Settings tabs")
	ui.field("Volume").value=.2
	ui.field("Apply").pressed.emit()
	check(is_equal_approx(game.runtime_settings.volume,.2),"Apply settings")
	var loader: Node=load("res://scripts/screen_loader.gd").new()
	game.add_child(loader)
	var loaded: PackedScene=await loader.load_scene("res://scenes/levels/training.tscn")
	check(loaded!=null,"Threaded loading")
	loader.progress(47)
	await shot("loading")
	await loader.finish()
	game.selected_map="training"
	await ui.load_battle()
	check(not ui.busy and game.countdown>4.8,"Countdown advanced behind loading screen")
	game._show_pause()
	await shot("pause")
	game._resume_battle()
	game._finish_battle(true,"Команда выполнила задачу")
	await shot("results")
	ui.field("TabTeam").pressed.emit()
	check(ui.field("Team").visible and not ui.field("Personal").visible,"Results tabs")
	game.free()
	await process_frame
	print("BROWSER UI VERIFICATION: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
