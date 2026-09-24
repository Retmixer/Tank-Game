extends SceneTree
## Offline native reconstruction of index.html and src/*-ui.css/battle-menus.css.
## Coordinates follow the browser's 1280x720 design, not a new visual design.
var theme_resource: Theme
var gold := Color("dfc181")
var ink := Color("152119ed")

func _initialize() -> void:
	if not "--replace-authored" in OS.get_cmdline_user_args():
		push_error("Use --replace-authored only after saving editor changes in Git.")
		quit(2)
		return
	_theme()
	_hangar()
	_loading()
	_setup()
	_pause()
	_settings()
	_results()
	_research()
	_card()
	print("Browser interface restored as editable native scenes")
	quit()

func _style(color: Color, border := Color("a79b6260")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	return box

func _theme() -> void:
	theme_resource = Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial Narrow","Roboto Condensed","Arial"])
	theme_resource.default_font = font
	theme_resource.default_font_size = 13
	theme_resource.set_color("font_color","Label",Color("d7d6c2"))
	for type in ["Button","OptionButton"]:
		theme_resource.set_stylebox("normal",type,_style(Color("18251eee")))
		theme_resource.set_stylebox("hover",type,_style(Color("374237"),gold))
		theme_resource.set_stylebox("pressed",type,_style(Color("48472f"),gold))
		theme_resource.set_stylebox("focus",type,_style(Color.TRANSPARENT,gold))
		theme_resource.set_color("font_color",type,Color("d9d2b4"))
		theme_resource.set_color("font_pressed_color",type,Color("fff1ce"))
	theme_resource.take_over_path("res://scenes/ui/military_theme.tres")
	ResourceSaver.save(theme_resource,theme_resource.resource_path)

func _base(name: String, dimensions := Vector2(1280,720), dark := true) -> Control:
	var root_node := Control.new()
	root_node.name = name
	root_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_node.set_script(load("res://scripts/browser_layout.gd"))
	root_node.set("design_size",dimensions)
	root_node.theme = theme_resource
	root_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dark:
		var backdrop := ColorRect.new()
		backdrop.name = "Backdrop"
		backdrop.color = Color("070c0b") if name=="Loading" else Color("070c0bf5") if name=="Settings" else Color("070c0bd0")
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root_node.add_child(backdrop)
	var design := Control.new()
	design.name = "Design"
	design.size = dimensions
	design.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_node.add_child(design)
	return root_node

func _at(node: Control, parent: Node, name: String, rect: Rect2) -> Control:
	node.name = name
	node.position = rect.position
	node.size = rect.size
	parent.add_child(node)
	return node

func _label(parent: Node,name: String,text: String,rect: Rect2,font_size := 13,color := Color("d7d6c2"),center := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	if font_size>=20:
		var heading_font := SystemFont.new()
		heading_font.font_names=PackedStringArray(["Arial Narrow","Roboto Condensed","Arial"])
		heading_font.font_weight=700
		label.add_theme_font_override("font",heading_font)
	label.add_theme_color_override("font_color",color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_at(label,parent,name,rect)
	return label

func _panel(parent: Node,name: String,rect: Rect2,color := Color("152119ed")) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel",_style(color))
	_at(panel,parent,name,rect)
	return panel

func _button(parent: Node,name: String,text: String,rect: Rect2,primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_stylebox_override("normal",_style(Color("18251e")))
	if primary:
		button.add_theme_stylebox_override("normal",_style(Color("d3b276"),Color("f0d693")))
		button.add_theme_color_override("font_color",Color("202b20"))
	_at(button,parent,name,rect)
	return button

func _image(parent: Node,name: String,path: String,rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_at(image,parent,name,rect)
	return image

func _progress(parent: Node,name: String,rect: Rect2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.value = 60
	bar.add_theme_stylebox_override("background",_style(Color("344030"),Color("596047")))
	bar.add_theme_stylebox_override("fill",_style(Color("dec080"),Color("dec080")))
	_at(bar,parent,name,rect)
	return bar

func _hangar() -> void:
	var root_node := _base("Hangar",Vector2(1280,720),false)
	var d: Control = root_node.get_node("Design")
	_panel(d,"Header",Rect2(0,0,1280,65),Color("141d18eb"))
	_label(d,"BrandIcon","◇",Rect2(26,5,48,52),48,gold)
	_label(d,"Logo","СТАЛЬНОЙ РУБЕЖ",Rect2(80,8,260,31),22,Color("e4d8ad"))
	_label(d,"Slogan","Т А К Т И К А .  Б Р О Н Я .  П О Б Е Д А .",Rect2(82,41,250,12),8,gold)
	_button(d,"HangarTab","▰  АНГАР",Rect2(346,11,182,46),true)
	_button(d,"Research","♜  ИССЛЕДОВАНИЯ",Rect2(533,11,205,46))
	_button(d,"Tasks","▤  ЗАДАЧИ",Rect2(743,11,162,46))
	_label(d,"Currency","◉  99 999      ◆  99 999",Rect2(936,12,225,24),14,gold)
	_label(d,"CurrencyUnits","СЕРЕБРО                 ОПЫТ",Rect2(957,36,190,13),8,Color("89917e"))
	_button(d,"Fullscreen","⛶",Rect2(1160,11,42,42))
	_button(d,"Settings","⚙",Rect2(1212,11,42,42))
	var left := _panel(d,"VehicleInfo",Rect2(19,86,307,476))
	for i in 3:
		_button(left,"Nation%d" % i,["СССР","Германия","Франция"][i],Rect2(16+i*92,12,89,24))
	_label(left,"Nation","СРЕДНИЙ ТАНК",Rect2(17,45,225,18),10,Color("9ba58a"))
	_label(left,"Tier","I",Rect2(259,54,31,43),24,gold,true)
	_label(left,"VehicleName","205 «ОПЛОТ»",Rect2(17,68,238,40),28,Color("ece2bd"))
	var desc := _label(left,"Description","Надёжность в каждом километре",Rect2(17,113,260,29),9,Color("929c87"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in 5:
		_label(left,"StatIcon%d" % i,["♨","◇","◴","▰","▣"][i],Rect2(17,150+i*38,23,27),23,gold)
		_label(left,"StatTitle%d" % i,["ОГНЕВАЯ МОЩЬ","ПРОЧНОСТЬ","СКОРОСТЬ","МАССА","ДВИГАТЕЛЬ"][i],Rect2(48,150+i*38,145,18),10)
		_label(left,"StatValue%d" % i,"—",Rect2(190,150+i*38,95,18),12,Color("e3e3ca")).horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		_progress(left,"StatBar%d" % i,Rect2(48,174+i*38,235,5))
	var passport := _panel(left,"Passport",Rect2(16,350,275,70),Color("14201880"))
	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.modulate = Color(.7,.73,.63,.65)
	_at(portrait,passport,"Blueprint",Rect2(6,3,162,62))
	_label(passport,"Dimensions","МАССА\nОБЗОР\nБРОНЯ",Rect2(171,3,100,60),8,Color("b9bda2"))
	_button(left,"Armor","◈ МАСКА БРОНИ",Rect2(16,429,160,25))
	_button(left,"PassportButton","ПАСПОРТ ↗",Rect2(183,429,108,25))
	_label(left,"Motto","★   В Е Р Н Ы  Т А М ,  Г Д Е  Т Р У Д Н О",Rect2(16,458,275,14),8,gold)
	var right := _panel(d,"Modules",Rect2(954,86,307,476))
	_label(right,"ModulesTitle","⚒   МОДЕРНИЗАЦИЯ",Rect2(16,13,225,20),13,gold)
	_label(right,"VehicleCode","P-205",Rect2(249,13,44,20),10,Color("909b85"))
	for i in 4:
		var id: String = ["gun","armor","engine","tracks"][i]
		var button := _button(right,"Upgrade_"+id,["▰\nОРУДИЕ","◇\nБРОНЯ","▣\nДВИГАТЕЛЬ","▱\nХОДОВАЯ"][i]+"\nУР. I",Rect2(16+(i%2)*142,48+(i/2)*98,133,89))
		button.toggle_mode = true
	var details := _panel(right,"ModuleDetail",Rect2(16,254,275,140),Color("18231b"))
	_label(details,"ModuleName","ОРУДИЕ",Rect2(11,8,175,23),17,Color("e1dfbd"))
	_label(details,"ModuleLevel","УР. I / V",Rect2(192,8,70,23),10)
	_label(details,"ModuleStats","Средний урон\nПробитие\nСкорострельность",Rect2(11,41,251,65),11,Color("a4ad95"))
	_progress(details,"ModuleProgress",Rect2(11,115,251,4))
	_label(right,"Hint","Улучшайте технику перед выходом в бой",Rect2(16,399,275,27),10,Color("a1ad92"))
	_button(right,"UpgradeConfirm","⌃   УЛУЧШИТЬ     300 ◉",Rect2(16,432,275,32),true)
	var scroll := ScrollContainer.new()
	scroll.set_script(load("res://scripts/vehicle_shelf.gd"))
	_at(scroll,d,"VehicleScroll",Rect2(350,591,580,105))
	var cards := HBoxContainer.new()
	cards.name = "Vehicles"
	cards.add_theme_constant_override("separation",8)
	scroll.add_child(cards)
	_button(d,"ShelfPrev","‹",Rect2(319,610,26,57))
	_button(d,"ShelfNext","›",Rect2(935,610,26,57))
	_label(d,"PreviewHint","+      ОБЗОР МАШИНЫ      +\nПеретащите мышью для вращения",Rect2(433,544,414,35),10,Color("cdd0b5"),true)
	var operation := _panel(d,"Operation",Rect2(954,588,307,70))
	_button(operation,"Battle","В БОЙ     ⟶",Rect2(10,10,287,50),true).add_theme_font_size_override("font_size",24)
	_label(d,"SaveStatus","● Локальное сохранение",Rect2(26,701,265,15),9,Color("9caa9f"))
	_label(d,"Career","0 боёв · 0 побед",Rect2(555,701,220,15),9,Color("9caa9f"),true)
	_button(d,"Help","Управление и обучение ↗",Rect2(1030,682,225,30)).add_theme_font_size_override("font_size",10)
	_save(root_node,"hangar")

func _card() -> void:
	var card := Button.new()
	card.name = "VehicleCard"
	card.theme = theme_resource
	card.custom_minimum_size = Vector2(184,100)
	card.toggle_mode = true
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_at(image,card,"Portrait",Rect2(5,3,174,76))
	_label(card,"Caption","205 «Оплот»",Rect2(9,78,170,20),11)
	_label(card,"Tier","I",Rect2(9,4,30,20),11,gold)
	_save(card,"vehicle_card")

func _loading() -> void:
	var root_node := _base("Loading",Vector2(1719,915))
	var d := root_node.get_node("Design")
	_image(d,"Artwork","res://assets/ui/loading-screen.png",Rect2(0,0,1719,915))
	_progress(d,"Progress",Rect2(495.9,793.5,681.6,23.8)).value=0
	_panel(d,"PercentageMask",Rect2(1179.2,791.5,77.4,31.1),Color("171b1c"))
	_label(d,"Percent","0%",Rect2(1179.2,791.5,77.4,31.1),24,Color("eeeeee"),true)
	_label(d,"Failure","",Rect2(270,650,1170,60),22,Color("efb283"),true)
	_save(root_node,"loading")

func _setup() -> void:
	var root_node := _base("BattleSetup",Vector2(1672,941))
	var d := root_node.get_node("Design")
	_image(d,"Artwork","res://assets/ui/battle-select.png",Rect2(0,0,1672,941))
	_panel(d,"HeadingMask",Rect2(0,0,1672,235),Color("15231ffb"))
	_label(d,"Title","ВЫБЕРИТЕ КАРТУ",Rect2(180,75,1312,66),50,Color("ebd29b"),true)
	_label(d,"Subtitle","Настройте формат боя и сложность ботов",Rect2(180,154,1312,36),19,Color("c4c5b8"),true)
	for i in 3:
		var id: String = ["training","desert","winter"][i]
		var x: float = [103.7,600.2,1095.2][i]
		var button := _button(d,id,"",Rect2(x,250.3,473.2,458.3))
		button.toggle_mode=true
		var photo := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/ui/battle-select.png")
		atlas.region = Rect2(x,257.5,473.2,320.8)
		photo.texture = atlas
		photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_at(photo,button,"Photo",Rect2(2,2,469.2,319))
		_panel(button,"CaptionPanel",Rect2(2,279,469.2,114),Color("101a14fa")).mouse_filter=Control.MOUSE_FILTER_IGNORE
		_label(button,"Caption",["УЧЕБНЫЙ ПОЛИГОН","ПУСТЫННЫЙ ПОЛИГОН","ЗИМНИЙ ЗАВОД"][i],Rect2(25,298,435,40),28,Color("e6dbc0"))
		_label(button,"Subtitle",["ОТРАБАТЫВАЙТЕ ТАКТИКУ","ЖАРКИЕ СРАЖЕНИЯ","ХОЛОД НЕ ПРОЩАЕТ ОШИБОК"][i],Rect2(25,342,420,25),14,Color("b6b19a"))
		_label(button,"Action","ВЫБРАТЬ       →",Rect2(2,395,469.2,61),20,gold,true)
	_button(d,"Back","← НАЗАД",Rect2(46.8,828,247.5,60.2))
	_button(d,"Start","НАЧАТЬ БОЙ →",Rect2(1389.4,828,234.1,60.2),true)
	_option(d,"TeamSize",Rect2(727.3,828,292.6,60.2),["БОЙ 3 × 3","БОЙ 5 × 5","БОЙ 7 × 7"])
	_option(d,"Difficulty",Rect2(1036.6,828,326,60.2),["БОТЫ: ЛЁГКИЕ","БОТЫ: ОБЫЧНЫЕ","БОТЫ: СЛОЖНЫЕ"])
	_save(root_node,"battle_setup")

func _pause() -> void:
	var root_node := _base("Pause")
	var d := root_node.get_node("Design")
	_label(d,"Meta","ПОЛЕ БОЯ",Rect2(32,25,470,40),12,Color("9da5a4"))
	_label(d,"Title","ПАУЗА",Rect2(350,169,580,85),74,Color("ecebe5"),true)
	_label(d,"Subtitle","ИГРА ПРИОСТАНОВЛЕНА",Rect2(350,260,580,28),14,Color("b9bfba"),true)
	for i in 4:
		_button(d,["Resume","Settings","Hangar","Leave"][i],["ПРОДОЛЖИТЬ ИГРУ","НАСТРОЙКИ","ВЕРНУТЬСЯ В АНГАР","ПОКИНУТЬ БОЙ"][i],Rect2(460,317+i*54,360,44),i==0)
	_button(d,"Back","Esc  Назад",Rect2(32,652,125,40))
	_label(d,"Motto","СРАЖАЙСЯ ДАЛЬШЕ. ПОБЕДА БЛИЖЕ.",Rect2(840,656,408,30),11,Color("868e8e"))
	_save(root_node,"pause")

func _option(parent: Node,name: String,rect: Rect2,options: Array) -> OptionButton:
	var option := OptionButton.new()
	option.add_theme_stylebox_override("normal",_style(Color("18251e")))
	for text in options:
		option.add_item(str(text))
	_at(option,parent,name,rect)
	return option

func _settings() -> void:
	var root_node := _base("Settings")
	var d := root_node.get_node("Design")
	_label(d,"Title","⚙  НАСТРОЙКИ",Rect2(36,24,600,48),32,Color("dddeda"))
	_label(d,"Motto","НАСТРОЙ СВОЮ БИТВУ",Rect2(1050,33,194,24),10,Color("798385"))
	for i in 4:
		var button := _button(d,["TabGraphics","TabSound","TabControls","TabGameplay"][i],["▣   ГРАФИКА","♫   ЗВУК","⌘   УПРАВЛЕНИЕ","⚙   ИГРОВОЙ ПРОЦЕСС"][i],Rect2(36,110+i*69,205,62))
		button.toggle_mode=true
	for id in ["Graphics","Sound","Controls","Gameplay"]:
		_at(Control.new(),d,id,Rect2(280,110,540,450))
	var graphics := d.get_node("Graphics")
	_label(graphics,"Heading","ГРАФИКА",Rect2(0,0,500,26),15)
	for row in [["Quality","Качество графики",["Высокое","Производительность"]],["RenderScale","Масштаб рендеринга",["50%","75%","100%","125%","150%"]]]:
		var y := 50 if row[0]=="Quality" else 100
		_label(graphics,row[0]+"Label",row[1],Rect2(0,y,260,35),13)
		_option(graphics,row[0],Rect2(280,y,240,35),row[2])
	_check(graphics,"Shadows","Динамические тени",Rect2(0,155,520,35))
	_check(graphics,"Postprocessing","Постобработка / AO",Rect2(0,205,520,35))
	_button(graphics,"Fullscreen","ПОЛНЫЙ ЭКРАН ↗",Rect2(0,260,250,44))
	_label(graphics,"Note","Масштаб меняет чёткость 3D-сцены, не интерфейса.\nВ режиме производительности постобработка отключена.",Rect2(0,335,535,90),12,Color("889593"))
	var sound := d.get_node("Sound")
	_label(sound,"Heading","ЗВУК",Rect2(0,0,500,26),15)
	_label(sound,"VolumeLabel","Общая громкость",Rect2(0,56,500,30),13)
	_slider(sound,"Volume",Rect2(0,102,520,30),0,1)
	var controls := d.get_node("Controls")
	_label(controls,"Heading","УПРАВЛЕНИЕ",Rect2(0,0,500,26),15)
	_label(controls,"SensitivityLabel","Чувствительность мыши и касаний",Rect2(0,50,500,30),13)
	_slider(controls,"Sensitivity",Rect2(0,93,520,30),.25,2.5)
	_check(controls,"CameraShake","Тряска камеры при попаданиях",Rect2(0,146,520,35))
	_label(controls,"Keys","W A S D     Движение\nМышь         Башня и камера\nЛКМ          Выстрел\nShift          Оптика\nTab           Состав команд\nEsc           Пауза / назад",Rect2(0,205,520,205),14,Color("a7b4b4"))
	var gameplay := d.get_node("Gameplay")
	_label(gameplay,"Heading","ИГРОВОЙ ПРОЦЕСС",Rect2(0,0,500,26),15)
	_label(gameplay,"DifficultyLabel","Сложность ботов",Rect2(0,55,260,35),13)
	_option(gameplay,"Difficulty",Rect2(280,55,240,35),["Лёгкие","Обычные","Сложные"])
	_label(gameplay,"Note","Применяется со следующего боя с ботами.\n\nЯзык интерфейса: русский.",Rect2(0,130,520,150),13,Color("889593"))
	var preview := _image(d,"Preview","res://assets/ui/loading-screen.png",Rect2(858,110,386,340))
	var crop := AtlasTexture.new()
	crop.atlas=preview.texture
	crop.region=Rect2(570,285,800,400)
	preview.texture=crop
	preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_label(d,"PreviewCaption","КРАСИВЫЙ МИР. БОЛЬШИЕ СРАЖЕНИЯ.",Rect2(858,458,386,45),12,Color("c3c8bc"),true)
	_button(d,"Defaults","ПО УМОЛЧАНИЮ",Rect2(36,644,210,44))
	_button(d,"Apply","ПРИМЕНИТЬ",Rect2(892,644,170,44),true)
	_button(d,"Back","НАЗАД",Rect2(1074,644,170,44))
	_save(root_node,"settings")

func _check(parent: Node,name: String,text: String,rect: Rect2) -> void:
	var check := CheckButton.new()
	check.text=text
	_at(check,parent,name,rect)

func _slider(parent: Node,name: String,rect: Rect2,minimum: float,maximum: float) -> void:
	var slider := HSlider.new()
	slider.min_value=minimum
	slider.max_value=maximum
	slider.step=.05
	_at(slider,parent,name,rect)

func _results() -> void:
	var root_node := _base("Results")
	var d := root_node.get_node("Design")
	_label(d,"Heading","РЕЗУЛЬТАТЫ БОЯ",Rect2(41,15,260,40),12,Color("929d9c"))
	for i in 3:
		var button := _button(d,["TabPersonal","TabTeam","TabDetails"][i],["ЛИЧНЫЙ РЕЗУЛЬТАТ","КОМАНДНЫЙ РЕЗУЛЬТАТ","СТАТИСТИКА"][i],Rect2(388+i*220,10,212,45))
		button.toggle_mode=true
	_label(d,"MapMeta","Карта · Время боя",Rect2(1020,65,220,26),11,Color("929d9c"))
	_label(d,"Title","ПОБЕДА!",Rect2(41,96,1158,106),78,Color("eed599"))
	_label(d,"Reason","Вся команда выполнила задачу",Rect2(41,207,1158,35),18,Color("d1b47f"))
	for name in ["Personal","Team","Details"]:
		_at(Control.new(),d,name,Rect2(41,280,1198,340))
	var personal := d.get_node("Personal")
	_panel(personal,"Metrics",Rect2(0,0,1198,78),Color("080d10a6"))
	for i in 4:
		_label(personal,"Metric%d" % i,"0",Rect2(26+i*294,8,268,36),27)
		_label(personal,"MetricLabel%d" % i,["СЕРЕБРО","ОПЫТ","УНИЧТОЖЕНО","НАНЕСЕНО УРОНА"][i],Rect2(26+i*294,46,268,22),11,Color("889897"))
	_panel(personal,"Summary",Rect2(0,79,1198,251),Color("0a0f12c9"))
	_label(personal,"Rank","БОЕВОЙ РЕЗУЛЬТАТ\n\n1 МЕСТО",Rect2(22,96,352,190),22,gold)
	_label(personal,"Rewards","НАГРАДА ЗА БОЙ",Rect2(415,96,352,225),14)
	_label(personal,"PersonalStats","ЛИЧНАЯ СТАТИСТИКА",Rect2(809,96,365,225),14)
	var scroll := ScrollContainer.new()
	_at(scroll,d.get_node("Team"),"Scroll",Rect2(0,0,1198,340))
	var rows := VBoxContainer.new()
	rows.name="TeamRows"
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	_label(d.get_node("Details"),"DetailStats","ВАШ ВКЛАД В СРАЖЕНИЕ",Rect2(20,10,1160,310),18)
	_button(d,"Hangar","ВЕРНУТЬСЯ В АНГАР",Rect2(41,650,240,44))
	_button(d,"Again","СЫГРАТЬ ЕЩЁ РАЗ",Rect2(293,650,240,44),true)
	_label(d,"Footer","КАЖДЫЙ БОЙ ДЕЛАЕТ ТЕБЯ СИЛЬНЕЕ.",Rect2(887,650,352,44),11,Color("8a9392"))
	_save(root_node,"results")

func _research() -> void:
	var root_node := _base("Research")
	var d := root_node.get_node("Design")
	_label(d,"Title","ИССЛЕДОВАНИЯ ТЕХНИКИ",Rect2(40,25,700,50),30,gold)
	_label(d,"Currency","",Rect2(935,25,300,50),18,gold)
	for i in 3:
		_button(d,"Nation%d" % i,["СССР","ГЕРМАНИЯ","ФРАНЦИЯ"][i],Rect2(40+i*225,87,210,42)).toggle_mode=true
	for i in 4:
		var at := Vector2(105+i*370,160) if i<3 else Vector2(475,416)
		var card := _button(d,"Tank%d" % i,"",Rect2(at,Vector2(325,225)))
		var portrait := TextureRect.new()
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_at(portrait,card,"Portrait",Rect2(10,8,305,130))
		_label(card,"Caption","",Rect2(12,144,300,27),18)
		_label(card,"Price","",Rect2(12,181,300,25),12,gold)
	for i in 2:
		_label(d,"Arrow%d" % i,"→",Rect2(435+i*370,242,38,48),30,gold,true)
	_label(d,"Branch","↓",Rect2(605,382,65,32),26,gold,true)
	_button(d,"Back","← НАЗАД В АНГАР",Rect2(40,661,230,40))
	_save(root_node,"research")

func _own(node: Node,root_node: Node) -> void:
	if node != root_node:
		node.owner=root_node
	for child in node.get_children():
		_own(child,root_node)

func _save(node: Node,name: String) -> void:
	_own(node,node)
	var scene := PackedScene.new()
	assert(scene.pack(node)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/ui/%s.tscn" % name)==OK)
	node.free()
