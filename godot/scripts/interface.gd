extends CanvasLayer
## Native bindings for the browser layout. Screens remain editable in Godot.
var game: Node
var page: Control
var busy := false
var selected_module := "gun"
var research_nation := 0
var shelf_offset := 0
var armor_visible := false
const MODULES := {"gun":"ОРУДИЕ","armor":"БРОНЯ","engine":"ДВИГАТЕЛЬ","tracks":"ХОДОВАЯ"}
const SCALES := [.5,.75,1.0,1.25,1.5]
const DIFFICULTIES := ["easy","normal","hard"]

func close() -> void:
	if is_instance_valid(page):
		var shelf := page.find_child("VehicleScroll",true,false) as ScrollContainer
		if shelf:
			shelf_offset=shelf.scroll_horizontal
		page.queue_free()
		page = null

func show_page(id: String) -> void:
	close()
	page = load("res://scenes/ui/%s.tscn" % id).instantiate()
	add_child(page)

func field(id: String) -> Node:
	return page.find_child(id,true,false)

func bind(id: String, action: Callable) -> void:
	field(id).pressed.connect(action)

func fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func hangar() -> void:
	game.screen = game.Screen.HANGAR
	show_page("hangar")
	var spec: Dictionary = GameData.stats(GameData.tank_by_id(game.selected_tank_id),GameData.save.modules[game.selected_tank_id])
	field("Currency").text = "◉ %d     ◆ %d" % [GameData.save.silver,GameData.save.xp]
	field("VehicleName").text = spec.name
	field("Nation").text = "%s · %s" % [spec.nation,spec.cls]
	field("Tier").text = str(spec.get("tier",1))
	field("Description").text = spec.get("description","ТАКТИКА. БРОНЯ. ПОБЕДА.")
	var values := [spec.damage,spec.hp,roundi(spec.speed*3.6),spec.mass,spec.get("power",520)]
	for i in 5:
		field("StatValue%d" % i).text = "%s %s" % [values[i],["ед.","HP","км/ч","т","л.с."][i]]
		field("StatBar%d" % i).value = clampf(float(values[i])/float([400,1800,65,85,1000][i])*100,0,100)
	var portrait := "res://assets/ui/vehicles/%s.png" % spec.id
	if ResourceLoader.exists(portrait):
		field("Blueprint").texture = load(portrait)
	field("Dimensions").text = "МАССА   %s т\nОБЗОР   %s м\nБРОНЯ   %s мм" % [spec.mass,spec.view,spec.armor]
	field("Career").text = "%d боёв · %d побед" % [GameData.save.battles,GameData.save.wins]
	field("VehicleCode").text = spec.id
	bind("Settings",game._show_settings)
	bind("Fullscreen",fullscreen)
	bind("HangarTab",hangar)
	bind("Research",research)
	bind("Armor",game._show_armor_preview)
	field("Armor").text="◈ МАСКА: ВКЛ" if armor_visible else "◈ МАСКА БРОНИ"
	if armor_visible:
		field("Description").text="Зелёный — пробивается · жёлтый — риск\nКрасный — не пробивается. Зависит от угла обзора."
	bind("PassportButton",game._show_armor_report)
	bind("Battle",setup)
	bind("Tasks",func() -> void: game._show_message("БОЕВЫЕ ЗАДАЧИ","Участвуйте в боях, наносите урон и захватывайте базу.\nНаграда рассчитывается по вашему вкладу в бой.",game._rebuild_hangar))
	bind("Help",func() -> void: game._show_message("УПРАВЛЕНИЕ","WASD — движение · Мышь — башня\nЛКМ — выстрел · Shift — оптика · Esc — пауза",game._rebuild_hangar))
	for nation in 3:
		bind("Nation%d" % nation,func() -> void:
			for id in GameData.save.owned:
				if GameData.save.owned[id] and str(id).begins_with(str(nation)+"-"):
					select_vehicle(id)
					return
			research())
	var selected_card: Control
	for id in GameData.save.owned:
		if not GameData.save.owned[id]:
			continue
		var vehicle := GameData.tank_by_id(id)
		var card := load("res://scenes/ui/vehicle_card.tscn").instantiate() as Button
		card.get_node("Caption").text = vehicle.name
		card.get_node("Tier").text = str(vehicle.get("tier",1))
		var image_path := "res://assets/ui/vehicles/%s.png" % id
		if ResourceLoader.exists(image_path):
			card.get_node("Portrait").texture = load(image_path)
		card.button_pressed = id == game.selected_tank_id
		field("Vehicles").add_child(card)
		field("VehicleScroll").attach(card)
		card.pressed.connect(func() -> void:
			if not field("VehicleScroll").suppress_click:
				select_vehicle(id))
		if id==game.selected_tank_id:
			selected_card=card
	field("VehicleScroll").restore(shelf_offset,selected_card)
	bind("ShelfPrev",func() -> void: field("VehicleScroll").scroll_horizontal -= 192)
	bind("ShelfNext",func() -> void: field("VehicleScroll").scroll_horizontal += 192)
	for module in MODULES:
		bind("Upgrade_"+module,func() -> void:
			selected_module = module
			module_details(spec))
	bind("UpgradeConfirm",func() -> void:
		var level := int(GameData.save.modules[spec.id][selected_module])
		if level >= 5:
			return
		var price: int = [300,1900,4300,7200][level-1]
		if GameData.save.silver < price:
			return
		GameData.save.silver -= price
		GameData.save.modules[spec.id][selected_module] = level+1
		GameData.persist()
		game._rebuild_hangar())
	module_details(spec)
	game._apply_armor_preview(armor_visible)

func select_vehicle(id: String) -> void:
	game.selected_tank_id = id
	GameData.save.selected = id
	GameData.persist()
	game._rebuild_hangar()

func module_details(spec: Dictionary) -> void:
	for module in MODULES:
		field("Upgrade_"+module).button_pressed = selected_module == module
		field("Upgrade_"+module).text = "%s\nУР. %d" % [MODULES[module],GameData.save.modules[spec.id][module]]
	var level := int(GameData.save.modules[spec.id][selected_module])
	field("ModuleName").text = MODULES[selected_module]
	field("ModuleLevel").text = "УР. %d / V" % level
	field("ModuleProgress").value = level*20
	field("ModuleStats").text = {"gun":"Урон: %d\nПробитие: %d мм\nПерезарядка: %.1f с" % [spec.damage,roundi(spec.damage*.74),spec.reload],"armor":"Прочность: %d HP\nБроня: %s мм" % [spec.hp,spec.armor],"engine":"Скорость: %d км/ч\nМасса: %s т" % [roundi(spec.speed*3.6),spec.mass],"tracks":"Поворот: %.2f\nРемонт гусеницы: 10 с" % spec.get("turn",1.0)}[selected_module]
	var price: int = [300,1900,4300,7200,0][clampi(level-1,0,4)]
	field("UpgradeConfirm").text = "МАКСИМУМ" if level>=5 else "УЛУЧШИТЬ    %d ◉" % price
	field("UpgradeConfirm").disabled = level>=5 or GameData.save.silver<price

func setup() -> void:
	show_page("battle_setup")
	for id in GameData.maps:
		field(id).button_pressed = id == game.selected_map
		field(id).get_node("Action").text = "ВЫБРАНО   ✓" if id == game.selected_map else "ВЫБРАТЬ   →"
		bind(id,func() -> void:
			game.selected_map = id
			GameData.save.map = id
			GameData.persist()
			setup())
	field("TeamSize").select(maxi(0,[3,5,7].find(int(GameData.save.team_size))))
	field("TeamSize").item_selected.connect(func(index: int) -> void:
		GameData.save.team_size = [3,5,7][index]
		GameData.persist())
	field("Difficulty").select(maxi(0,DIFFICULTIES.find(game.runtime_settings.get("difficulty","normal"))))
	field("Difficulty").item_selected.connect(func(index: int) -> void:
		game.runtime_settings.difficulty = DIFFICULTIES[index]
		GameData.save.settings = game.runtime_settings.duplicate(true)
		GameData.persist())
	bind("Back",hangar)
	bind("Start",load_battle)

func load_battle() -> void:
	if busy:
		return
	busy = true
	var loader := load("res://scripts/screen_loader.gd").new() as CanvasLayer
	game.add_child(loader)
	var scene: PackedScene = await loader.load_scene("res://scenes/levels/%s.tscn" % game.selected_map)
	if scene == null:
		return
	game._start_battle()
	game._freeze_vehicles(true)
	await loader.finish()
	game._freeze_vehicles(false)
	busy = false

func research() -> void:
	show_page("research")
	field("Currency").text = "%d ◉    %d ✦" % [GameData.save.silver,GameData.save.xp]
	for nation in 3:
		field("Nation%d" % nation).button_pressed=research_nation==nation
		bind("Nation%d" % nation,func() -> void:
			research_nation=nation
			research())
	for tier in 4:
		var vehicle := GameData.tank_by_id("%d-%d" % [research_nation,tier])
		var price := GameData.tank_price(vehicle)
		var card: Button=field("Tank%d" % tier)
		var owned: bool=bool(GameData.save.owned.get(vehicle.id,false))
		card.get_node("Caption").text=vehicle.name
		card.get_node("Price").text="В АНГАРЕ" if owned else "%d ◉ · %d ✦" % [price.silver,price.xp]
		var portrait := "res://assets/ui/vehicles/%s.png" % vehicle.id
		if ResourceLoader.exists(portrait):
			card.get_node("Portrait").texture=load(portrait)
		card.disabled=owned or GameData.save.silver<price.silver or GameData.save.xp<price.xp
		card.pressed.connect(func() -> void:
			GameData.unlock(vehicle.id)
			research())
	bind("Back",hangar)

func pause() -> void:
	show_page("pause")
	field("Meta").text = "ПОЛЕ БОЯ\n%s" % GameData.maps[game.selected_map].get("name",game.selected_map)
	bind("Resume",game._resume_battle)
	bind("Back",game._resume_battle)
	bind("Settings",game._show_settings)
	bind("Hangar",game._return_to_hangar)
	bind("Leave",game._return_to_hangar)

func tabs(ids: Array, selected: String) -> void:
	for id in ids:
		field(id).visible = id == selected
		field("Tab"+id).button_pressed = id == selected

func settings() -> void:
	show_page("settings")
	fill_settings(game.runtime_settings)
	for tab in ["Graphics","Sound","Controls","Gameplay"]:
		bind("Tab"+tab,tabs.bind(["Graphics","Sound","Controls","Gameplay"],tab))
	tabs(["Graphics","Sound","Controls","Gameplay"],"Graphics")
	bind("Fullscreen",fullscreen)
	bind("Back",game._close_settings)
	bind("Defaults",func() -> void: fill_settings(GameData.defaults().settings))
	bind("Apply",func() -> void:
		var config: Dictionary = game.runtime_settings
		config.render_scale = SCALES[field("RenderScale").selected]
		config.quality = ["high","low"][field("Quality").selected]
		config.difficulty = DIFFICULTIES[field("Difficulty").selected]
		config.volume = field("Volume").value
		config.sensitivity = field("Sensitivity").value
		config.shadows = field("Shadows").button_pressed
		config.postprocessing = field("Postprocessing").button_pressed
		config.camera_shake = field("CameraShake").button_pressed
		GameData.save.settings = config.duplicate(true)
		GameData.persist()
		game._apply_settings()
		game._close_settings())

func fill_settings(config: Dictionary) -> void:
	field("RenderScale").select(maxi(0,SCALES.find(float(config.get("render_scale",1.0)))))
	field("Quality").select(0 if config.get("quality","high")=="high" else 1)
	field("Difficulty").select(maxi(0,DIFFICULTIES.find(config.get("difficulty","normal"))))
	field("Volume").value = config.volume
	field("Sensitivity").value = config.sensitivity
	field("Shadows").button_pressed = config.get("shadows",true)
	field("Postprocessing").button_pressed = config.get("postprocessing",true)
	field("CameraShake").button_pressed = config.get("camera_shake",true)

func results(won: bool, reason: String, own: Dictionary) -> void:
	show_page("results")
	field("Title").text = "ПОБЕДА!" if won else "ПОРАЖЕНИЕ"
	field("Reason").text = reason
	field("MapMeta").text = GameData.maps[game.selected_map].get("name",game.selected_map)
	var values := [own.reward.silver,own.reward.xp,own.kills,own.damage]
	for i in 4:
		field("Metric%d" % i).text = str(values[i])
	field("Rank").text = "БОЕВОЙ РЕЗУЛЬТАТ\n\n%d МЕСТО" % own.get("place",1)
	field("Rewards").text = "НАГРАДА ЗА БОЙ\n\nСеребро: +%d\n\nОпыт: +%d" % [own.reward.silver,own.reward.xp]
	field("PersonalStats").text = "ЛИЧНАЯ СТАТИСТИКА\n\nНанесено урона: %d\n\nУничтожено: %d" % [own.damage,own.kills]
	field("DetailStats").text = "ВАШ ВКЛАД В СРАЖЕНИЕ\n\nУрон: %d\nУничтожено: %d\nЗаблокировано: %s\nОбнаружено: %s\nЗахват: %s" % [own.damage,own.kills,own.get("blocked",0),own.get("spotted",0),own.get("capture",0)]
	for row in game.latest_results:
		var label := Label.new()
		label.text = "%d. %s · %s     %d урона     %d уничтожено" % [row.place,row.name,row.tank,row.damage,row.kills]
		label.custom_minimum_size.y = 35
		field("TeamRows").add_child(label)
	for tab in ["Personal","Team","Details"]:
		bind("Tab"+tab,tabs.bind(["Personal","Team","Details"],tab))
	tabs(["Personal","Team","Details"],"Personal")
	bind("Hangar",game._return_to_hangar)
	bind("Again",load_battle)
