extends Node

func _ready() -> void:
	var loader := preload("res://scripts/screen_loader.gd").new()
	add_child(loader)
	var packed: PackedScene = await loader.load_scene("res://scenes/main.tscn")
	if packed==null:
		return
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	game.interface.busy=true
	get_tree().current_scene=game
	await get_tree().process_frame
	await loader.finish()
	game.interface.busy=false
	queue_free()
