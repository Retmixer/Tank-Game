extends CanvasLayer
## Shared loading artwork for startup and every map transition.
var view: Control
var started_at := 0

func load_scene(path: String) -> PackedScene:
	layer=100
	view=load("res://scenes/ui/loading.tscn").instantiate()
	add_child(view)
	started_at=Time.get_ticks_msec()
	progress(0)
	await get_tree().process_frame
	var error := ResourceLoader.load_threaded_request(path)
	if error != OK:
		failure("Не удалось начать загрузку: %s" % error)
		return null
	while true:
		var values: Array=[]
		var status := ResourceLoader.load_threaded_get_status(path,values)
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			progress(94)
			return ResourceLoader.load_threaded_get(path) as PackedScene
		if status==ResourceLoader.THREAD_LOAD_FAILED or status==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			failure("Не удалось загрузить сцену. Перезапустите игру или проверьте файлы проекта.")
			return null
		progress(5+float(values[0] if values.size()>0 else 0)*85)
		await get_tree().process_frame
	return null

func progress(value: float) -> void:
	view.find_child("Progress",true,false).value=value
	view.find_child("Percent",true,false).text="%d%%" % roundi(value)

func failure(message: String) -> void:
	view.find_child("Failure",true,false).text=message
	var retry := Button.new()
	retry.text="ПЕРЕЗАПУСТИТЬ"
	retry.position=Vector2(710,710)
	retry.size=Vector2(300,48)
	view.get_node("Design").add_child(retry)
	retry.pressed.connect(func() -> void: get_tree().reload_current_scene())

func finish() -> void:
	var remaining := maxi(0,650-(Time.get_ticks_msec()-started_at))
	if remaining>0:
		await get_tree().create_timer(remaining/1000.0).timeout
	progress(100)
	await get_tree().create_timer(.15).timeout
	queue_free()
