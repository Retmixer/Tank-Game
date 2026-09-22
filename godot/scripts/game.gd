extends Node3D

enum Screen { HANGAR, BATTLE, PAUSE, SETTINGS, RESULT, LAN_LOBBY }
enum Page { GARAGE, RESEARCH }

const TankScript = preload("res://scripts/tank.gd")
const ShellScript = preload("res://scripts/shell.gd")
const ArenaScript = preload("res://scripts/arena.gd")
const PALETTE := {
	"background": Color("081013"), "panel": Color("11191c"), "line": Color("303a3a"),
	"gold": Color("e3bd73"), "gold_dark": Color("92713d"), "text": Color("e7e4da"),
	"muted": Color("98a09b"), "blue": Color("68b9d5"), "red": Color("e77662"),
	"green": Color("82c8a7")
}

var screen := Screen.HANGAR
var garage_page := Page.GARAGE
var arena: BattleArena
var view_camera: Camera3D
var tanks: Array[BattleTank] = []
var shells: Array[BattleShell] = []
var player: BattleTank
var ai_tanks: Array[BattleTank] = []
var world_ui: CanvasLayer
var root_panel: Control
var notice_label: Label
var countdown_label: Label
var hud: Control
var selected_map := "training"
var selected_tank_id := "0-1"
var battle_mode := "solo"
var duration_left := 420.0
var elapsed := 0.0
var countdown := 5.0
var battle_live := false
var paused_from := Screen.HANGAR
var aim_point := Vector3.ZERO
var aim_color := PALETTE.green
var camera_yaw := 0.0
var camera_pitch := -.22
var camera_distance := 22.0
var scoped := false
var firing := false
var capture_progress := 0.0
var ai_clock := 0.0
var effect_clock := 0.0
var fire_clock := 0.0
var damage_events: Array[Dictionary] = []
var latest_results: Array[Dictionary] = []
var runtime_settings: Dictionary
var lan_peer: ENetMultiplayerPeer
var lan_host := false
var remote_tank: BattleTank
var remote_controls := Vector2.ZERO
var lan_code := ""
var lan_wait_seconds := 0.0
var remote_last_shot := -1
var labels: Dictionary = {}
var reticle: Control

func _ready() -> void:
	runtime_settings = GameData.save.settings.duplicate(true)
	selected_map = GameData.save.map
	selected_tank_id = GameData.save.selected
	_create_ui()
	_show_hangar()
	set_process(true)

func _process(delta: float) -> void:
	if screen == Screen.LAN_LOBBY and lan_peer != null:
		if lan_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
			lan_wait_seconds -= delta
			if lan_wait_seconds <= 0.0:
				_notify("Не удалось подключиться. Проверьте IP Radmin и порт 28765.")
				_leave_lan()
			return
		if lan_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED and not lan_host:
			_notify("Соединение с хостом потеряно.")
			_leave_lan()
			return
	if screen == Screen.BATTLE and battle_live:
		elapsed += delta
		duration_left = maxf(0.0, duration_left - delta)
		countdown -= delta
		if countdown <= 0.0 and not countdown_label.visible:
			countdown_label.show()
			countdown_label.text = "БОЙ НАЧАЛСЯ"
			get_tree().create_timer(.9).timeout.connect(func() -> void:
				if is_instance_valid(countdown_label):
					countdown_label.hide())
		if countdown > 0.0:
			countdown_label.text = "ПРИГОТОВИТЬСЯ\n%d" % ceili(countdown)
		_ai_process(delta)
		_update_camera(delta)
		_update_aim()
		_update_hud()
		_update_effects(delta)
		_network_process(delta)
		if duration_left <= 0.0:
			_finish_battle(capture_progress >= 0.0, "Время боя истекло")
		elif capture_progress >= 100.0:
			_finish_battle(true, "База под контролем вашей команды")
		elif capture_progress <= -100.0:
			_finish_battle(false, "Противник захватил базу")

func _physics_process(_delta: float) -> void:
	if screen != Screen.BATTLE or player == null or not is_instance_valid(player) or player.destroyed:
		return
	var movement := Vector2(Input.get_axis("turn_left", "turn_right"), Input.get_axis("backward", "forward"))
	var hit_point := aim_point
	if hit_point.is_zero_approx():
		hit_point = player.global_position + Vector3.FORWARD * 100.0
	player.set_controls(movement, hit_point, firing and battle_live and countdown <= 0.0)
	if lan_peer != null and not lan_host and remote_tank != null:
		rpc_id(1, "submit_remote_state", player.global_position, player.rotation.y, player.turret.rotation.y, player.cannon.rotation.x, player.hp, movement, hit_point, firing)

func _create_ui() -> void:
	world_ui = CanvasLayer.new()
	world_ui.layer = 4
	add_child(world_ui)
	root_panel = Control.new()
	root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_ui.add_child(root_panel)
	_build_reticle()
	countdown_label = _label(root_panel, "", 40, PALETTE.text, HORIZONTAL_ALIGNMENT_CENTER)
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown_label.offset_left = -210
	countdown_label.offset_right = 210
	countdown_label.offset_top = -90
	countdown_label.offset_bottom = 100
	countdown_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	countdown_label.add_theme_constant_override("shadow_offset_x", 2)
	countdown_label.add_theme_constant_override("shadow_offset_y", 3)
	countdown_label.hide()
	notice_label = _label(root_panel, "", 15, PALETTE.gold, HORIZONTAL_ALIGNMENT_CENTER)
	notice_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notice_label.offset_left = -310
	notice_label.offset_right = 310
	notice_label.offset_top = 76
	notice_label.offset_bottom = 116
	notice_label.hide()
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_panel.add_child(hud)
	hud.hide()

func _show_hangar() -> void:
	screen = Screen.HANGAR
	battle_live = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_panel()
	hud.hide()
	if not is_instance_valid(arena):
		_build_hangar_world()
	root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := _panel(root_panel, Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size), Color("080c0ddd"), false)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.position = Vector2(36, 22)
	top.size = Vector2(get_viewport().get_visible_rect().size.x - 72, 70)
	root_panel.add_child(top)
	var logo := _label(top, "◇  СТАЛЬНОЙ РУБЕЖ\n    ТАКТИКА · БРОНЯ · ПОБЕДА", 26, PALETTE.text)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var money := _label(top, "◉  %s   ✦  %s" % [GameData.save.silver, GameData.save.xp], 17, PALETTE.gold, HORIZONTAL_ALIGNMENT_RIGHT)
	money.custom_minimum_size.x = 300
	var content := HBoxContainer.new()
	content.position = Vector2(36, 117)
	content.size = Vector2(get_viewport().get_visible_rect().size.x - 72, get_viewport().get_visible_rect().size.y - 220)
	content.add_theme_constant_override("separation", 20)
	root_panel.add_child(content)
	var left := _panel(content, Rect2(Vector2.ZERO, Vector2.ZERO), Color("10171aeb"), true)
	left.custom_minimum_size = Vector2(310, 0)
	left.size_flags_horizontal = Control.SIZE_FILL
	var left_col := VBoxContainer.new()
	left_col.position = Vector2(20, 18)
	left_col.size = Vector2(270, content.size.y - 36)
	left.add_child(left_col)
	_label(left_col, "БОЕВОЙ ПАРК", 12, PALETTE.gold)
	var page_row := HBoxContainer.new()
	left_col.add_child(page_row)
	_button(page_row, "АНГАР", func() -> void: garage_page = Page.GARAGE; _show_hangar(), garage_page == Page.GARAGE)
	_button(page_row, "ИССЛЕДОВАНИЯ", func() -> void: garage_page = Page.RESEARCH; _show_hangar(), garage_page == Page.RESEARCH)
	if garage_page == Page.RESEARCH:
		_build_research(left_col)
	else:
		_build_hangar_tanks(left_col)
	var preview := VBoxContainer.new()
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.add_theme_constant_override("separation", 8)
	content.add_child(preview)
	_label(preview, "ОБЗОР МАШИНЫ · ПЕРЕТАЩИТЕ МЫШЬЮ ДЛЯ ПОВОРОТА", 11, PALETTE.muted, HORIZONTAL_ALIGNMENT_CENTER)
	var spec := GameData.stats(GameData.tank_by_id(selected_tank_id), GameData.save.modules[selected_tank_id])
	_label(preview, spec.name, 32, PALETTE.text, HORIZONTAL_ALIGNMENT_CENTER)
	_label(preview, "%s · %d HP · %d мм брони · %.1f× оптика" % [spec.cls.to_upper(), spec.hp, spec.armor, spec.zoom], 14, PALETTE.gold, HORIZONTAL_ALIGNMENT_CENTER)
	var stats := _panel(preview, Rect2(Vector2.ZERO, Vector2.ZERO), Color("0b1116cb"), true)
	stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats.custom_minimum_size.y = 64
	var stat_line := _label(stats, "  ОРУДИЕ   %d ед.     │     ПРОЧНОСТЬ   %d HP     │     СКОРОСТЬ   %d км/ч     │     МАССА   %d т     │     ДВИГАТЕЛЬ   %d л.с." % [spec.damage, spec.hp, roundi(spec.speed * 3.6), spec.mass, spec.power], 13, PALETTE.text)
	stat_line.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	stat_line.offset_left = 14
	stat_line.offset_right = -8
	var bottom := HBoxContainer.new()
	bottom.position = Vector2(36, get_viewport().get_visible_rect().size.y - 82)
	bottom.size = Vector2(get_viewport().get_visible_rect().size.x - 72, 56)
	bottom.add_theme_constant_override("separation", 10)
	root_panel.add_child(bottom)
	var armor := _button(bottom, "МАСКА БРОНИ", _show_armor_preview)
	armor.custom_minimum_size.x = 160
	var map_picker := OptionButton.new()
	map_picker.custom_minimum_size = Vector2(245, 48)
	for id in GameData.maps:
		map_picker.add_item(GameData.maps[id].name)
		map_picker.set_item_metadata(map_picker.item_count - 1, id)
		if id == selected_map:
			map_picker.select(map_picker.item_count - 1)
	map_picker.item_selected.connect(func(index: int) -> void:
		selected_map = str(map_picker.get_item_metadata(index))
		GameData.save.map = selected_map
		GameData.persist())
	bottom.add_child(map_picker)
	var team_picker := OptionButton.new()
	team_picker.custom_minimum_size = Vector2(142, 48)
	for team_count in [3, 5, 7]:
		team_picker.add_item("БОЙ %d × %d" % [team_count, team_count])
		if team_count == GameData.save.team_size:
			team_picker.select(team_picker.item_count - 1)
	team_picker.item_selected.connect(func(index: int) -> void:
		GameData.save.team_size = [3, 5, 7][index]
		GameData.persist())
	bottom.add_child(team_picker)
	var mode_picker := OptionButton.new()
	mode_picker.custom_minimum_size = Vector2(205, 48)
	mode_picker.add_item("КОМАНДНЫЙ БОЙ · БОТЫ")
	mode_picker.add_item("ЛОКАЛЬНАЯ СЕТЬ · 1 × 1")
	mode_picker.select(0 if battle_mode == "solo" else 1)
	mode_picker.item_selected.connect(func(index: int) -> void: battle_mode = "solo" if index == 0 else "lan")
	bottom.add_child(mode_picker)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)
	_button(bottom, "⚙ НАСТРОЙКИ", _show_settings).custom_minimum_size = Vector2(150, 48)
	_button(bottom, "В  Б О Й   →", _open_selected_mode, true).custom_minimum_size = Vector2(210, 48)

func _build_hangar_world() -> void:
	arena = ArenaScript.new()
	arena.build("training", "low")
	add_child(arena)
	_create_camera()
	var preview_spec := GameData.stats(GameData.tank_by_id(selected_tank_id), GameData.save.modules[selected_tank_id])
	var preview_tank := TankScript.new() as BattleTank
	preview_tank.configure(preview_spec, 0, false)
	preview_tank.name = "TankPreview"
	preview_tank.position = Vector3(0, arena.height_at(0, 0) + .5, 0)
	add_child(preview_tank)
	tanks.append(preview_tank)
	view_camera.global_position = Vector3(9, 7, 16)
	view_camera.look_at(Vector3(0, 2, 0))

func _build_hangar_tanks(parent: VBoxContainer) -> void:
	var owned: Array = []
	for tank in GameData.tanks:
		if GameData.save.owned.get(tank.id, false):
			owned.append(tank)
	for tank in owned:
		var owned_id: String = tank.id
		var label := "%s  ·  %s\nРУБЕЖНЫЙ ЭКИПАЖ  ·  УРОВЕНЬ %s" % [tank.name, tank.cls.to_upper(), _roman(GameData.save.levels[owned_id])]
		_button(parent, label, func() -> void:
			selected_tank_id = owned_id
			GameData.save.selected = owned_id
			GameData.persist()
			_rebuild_hangar())
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(filler)
	_label(parent, "ДОСТУПНО МАШИН: %d / %d" % [owned.size(), GameData.tanks.size()], 11, PALETTE.muted)
	_button(parent, "ДЕРЕВО ИССЛЕДОВАНИЙ →", func() -> void: garage_page = Page.RESEARCH; _show_hangar())

func _build_research(parent: VBoxContainer) -> void:
	for nation in 3:
		_label(parent, ["СССР", "ГЕРМАНИЯ", "ФРАНЦИЯ"][nation], 14, PALETTE.gold)
		for tank in GameData.tanks:
			if tank.n != nation:
				continue
			var id: String = tank.id
			var cost := GameData.tank_price(tank)
			if GameData.save.owned.get(id, false):
				_button(parent, "✓ %s · УРОВЕНЬ %s" % [tank.name, _roman(GameData.save.levels[id])], func() -> void:
					selected_tank_id = id
					garage_page = Page.GARAGE
					_show_hangar())
			else:
				var locked := _button(parent, "🔒 %s  ·  %s\n%d ✦   /   %d ◉" % [tank.name, tank.cls, cost.xp, cost.silver], func() -> void:
					if GameData.unlock(id):
						selected_tank_id = id
						_show_hangar()
					else:
						_notify("Не хватает опыта или серебра для исследования.")
					_show_hangar())
				locked.disabled = GameData.save.xp < cost.xp or GameData.save.silver < cost.silver
				locked.custom_minimum_size.y = 58

func _rebuild_hangar() -> void:
	# Refresh the preview model while keeping the current level lighting.
	for tank in tanks:
		if is_instance_valid(tank):
			tank.queue_free()
	tanks.clear()
	var chosen := TankScript.new() as BattleTank
	chosen.configure(GameData.stats(GameData.tank_by_id(selected_tank_id), GameData.save.modules[selected_tank_id]), 0, false)
	chosen.name = "TankPreview"
	chosen.position = Vector3(0, arena.height_at(0, 0) + .5, 0)
	add_child(chosen)
	tanks.append(chosen)
	_show_hangar()

func _show_armor_preview() -> void:
	var spec := GameData.stats(GameData.tank_by_id(selected_tank_id), GameData.save.modules[selected_tank_id])
	var report := "МАСКА БРОНИ · ТОЛЩИНА В МИЛЛИМЕТРАХ\n"
	for zone in GameData.armor_zones:
		report += "\n%s: %d мм" % [str(zone).to_upper(), roundi(GameData.armor_mm(spec, zone))]
	_show_message("ПАСПОРТ БРОНИ", report, func() -> void: _show_hangar())

func _open_selected_mode() -> void:
	if battle_mode == "lan":
		_show_lan_lobby()
	else:
		_start_battle()

func _create_camera() -> void:
	view_camera = Camera3D.new()
	view_camera.current = true
	view_camera.fov = 60
	view_camera.far = 1600
	view_camera.near = .1
	add_child(view_camera)

func _start_battle() -> void:
	for tank in tanks:
		if is_instance_valid(tank):
			tank.queue_free()
	tanks.clear()
	for shell in shells:
		if is_instance_valid(shell):
			shell.queue_free()
	shells.clear()
	if is_instance_valid(arena):
		arena.queue_free()
	arena = ArenaScript.new()
	arena.build(selected_map, str(runtime_settings.get("quality", "high")))
	add_child(arena)
	if not is_instance_valid(view_camera):
		_create_camera()
	if lan_peer == null:
		_spawn_solo_roster()
	else:
		_spawn_lan_roster()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	screen = Screen.BATTLE
	battle_live = true
	duration_left = float(GameData.maps[selected_map].time)
	elapsed = 0.0
	capture_progress = 0.0
	countdown = 5.0
	scoped = false
	firing = false
	camera_yaw = player.rotation.y
	camera_pitch = -.16
	camera_distance = 24.0
	_create_hud()
	countdown_label.show()
	countdown_label.text = "ПРИГОТОВИТЬСЯ\n5"
	AudioServer.set_bus_volume_db(0, linear_to_db(float(runtime_settings.volume)))

func _spawn_lan_roster() -> void:
	var local_spec := GameData.stats(GameData.tank_by_id(selected_tank_id), GameData.save.modules[selected_tank_id])
	var opposing_spec: Dictionary = local_spec
	var home := Vector2(-arena.world_size * .4, -arena.world_size * .4)
	var away := Vector2(arena.world_size * .4, arena.world_size * .4)
	var home_team := 0 if lan_host else 1
	var home_name := "Вы · Хост" if lan_host else "Вы · Гость"
	var enemy_name := "Соперник · Гость" if lan_host else "Соперник · Хост"
	player = _make_tank(local_spec, home_team, true, home_name)
	remote_tank = _make_tank(opposing_spec, 1 - home_team, false, enemy_name)
	var player_spawn := home if lan_host else away
	var enemy_spawn := away if lan_host else home
	player.position = Vector3(player_spawn.x, arena.height_at(player_spawn.x, player_spawn.y) + .55, player_spawn.y)
	remote_tank.position = Vector3(enemy_spawn.x, arena.height_at(enemy_spawn.x, enemy_spawn.y) + .55, enemy_spawn.y)
	player.hull_heading = PI / 4.0 if lan_host else -3.0 * PI / 4.0
	remote_tank.hull_heading = -player.hull_heading
	player.rotation.y = player.hull_heading
	remote_tank.rotation.y = remote_tank.hull_heading
	tanks = [player, remote_tank] if lan_host else [remote_tank, player]
	ai_tanks.clear()

func _spawn_solo_roster() -> void:
	var selected := GameData.stats(GameData.tank_by_id(selected_tank_id), GameData.save.modules[selected_tank_id])
	var roster: Array = GameData.tanks.duplicate()
	roster.shuffle()
	var specs: Array[Dictionary] = []
	for spec in roster:
		if spec.id != selected_tank_id:
			specs.append(spec)
	var team_names := ["Кедр", "Сокол", "Риф", "Коршун", "Кремень", "Буран", "Тайфун"]
	var team_count: int = int(GameData.save.team_size)
	var roster_index := 0
	for team_id in 2:
		for slot in team_count:
			var is_player := team_id == 0 and slot == 0
			var spec: Dictionary = selected if is_player else specs[posmod(roster_index, specs.size())]
			if not is_player:
				roster_index += 1
			var tank := _make_tank(spec, team_id, is_player, "Вы" if is_player else team_names[slot])
			var side := -1.0 if team_id == 0 else 1.0
			var lateral := (float(slot) - float(team_count - 1) * .5) * 10.0
			var x: float = side * arena.world_size * .39 + lateral
			var z: float = side * arena.world_size * .39 - lateral
			tank.position = Vector3(x, arena.height_at(x, z) + .55, z)
			tank.hull_heading = PI / 4.0 if team_id == 0 else -3.0 * PI / 4.0
			tank.rotation.y = tank.hull_heading
			tanks.append(tank)
			if is_player:
				player = tank
				tank.shot_request = _fire_shell
	if arena.map_id == "training":
		_ai_obstacle_check()
	ai_tanks.clear()
	for tank in tanks:
		if tank != player:
			ai_tanks.append(tank)

func _make_tank(spec: Dictionary, team: int, player_controlled: bool, callsign := "Командир") -> BattleTank:
	var tank := TankScript.new() as BattleTank
	tank.name = "Tank_%s" % spec.id
	tank.configure(spec, team, player_controlled)
	tank.set_meta("callsign", "Вы" if player_controlled else callsign)
	tank.shot_request = _fire_shell
	add_child(tank)
	return tank

func _ai_obstacle_check() -> void:
	# spawn aprons are graded in the terrain generator; the nearest rock cluster leaves them clear.
	pass

func _fire_shell(source: BattleTank, _sequence: int) -> void:
	if lan_peer != null and not lan_host and source == player:
		rpc_id(1, "request_remote_shot", source.shot_sequence, source.spec.damage, source.muzzle_transform().origin, _aim_direction(source))
		return
	if lan_peer != null and not lan_host and source == remote_tank:
		return
	var direction := _aim_direction(source)
	var shell := ShellScript.new() as BattleShell
	shell.launch(source, float(source.spec.damage), direction)
	shell.impact_event = _on_impact
	add_child(shell)
	shells.append(shell)
	if source == player or source.team == 1:
		_play_one_shot("shot", source.global_position, .8)
	if lan_peer != null and lan_host and source == player:
		rpc("server_shot", source.global_position, direction, source.spec.damage, source.shot_sequence)

func _aim_direction(source: BattleTank) -> Vector3:
	var muzzle := source.muzzle_transform().origin
	var target := aim_point if source == player and not aim_point.is_zero_approx() else source.global_position + Vector3.FORWARD * 180.0
	if source != player:
		var target_tank := _nearest_enemy(source)
		if target_tank:
			target = target_tank.global_position + Vector3.UP * 1.2
	var direction := (target - muzzle).normalized()
	var easy_bot: bool = source != player and runtime_settings.get("difficulty", "normal") == "easy"
	var hard_bot: bool = source != player and runtime_settings.get("difficulty", "normal") == "hard"
	var spread: float = source.spec.spread * maxf(.22, source.aim_spread) * (1.5 if easy_bot else .68 if hard_bot else 1.0)
	direction = (direction + Vector3(randf_range(-spread, spread), randf_range(-spread, spread), randf_range(-spread, spread))).normalized()
	return direction

func _on_impact(point: Vector3, vehicle: bool, outcome: Dictionary) -> void:
	_effect(point, Color("efb66d") if vehicle else Color("b9a681"), 16 if vehicle else 8)
	if not outcome.is_empty() and not outcome.get("ricochet", false):
		_notify("ПРОБИТИЕ · %d%%" % roundi(outcome.chance * 100.0) if outcome.chance >= .3 else "НЕ ПРОБИТО")

func _ai_process(delta: float) -> void:
	if not battle_live or countdown > 0.0:
		return
	ai_clock -= delta
	if ai_clock > 0.0:
		_update_capture(delta)
		return
	var difficulty: String = str(runtime_settings.get("difficulty", "normal"))
	ai_clock = .52 if difficulty == "easy" else .13 if difficulty == "hard" else .27
	for bot in ai_tanks:
		if not is_instance_valid(bot) or bot.destroyed:
			continue
		var target := _nearest_enemy(bot)
		var waypoint := target.global_position if target else Vector3.ZERO
		var distance: float
		if target:
			distance = bot.global_position.distance_to(target.global_position)
			if distance < target.spec.view * (1.0 if target.is_player else .8):
				bot.spotted += 1 if target == player else 0
		else:
			waypoint = Vector3(0, 0, 0)
			distance = bot.global_position.length()
		var engagement_distance := 98.0 if difficulty == "easy" else 130.0 if difficulty == "hard" else 115.0
		if target and distance < engagement_distance:
			bot.set_controls(Vector2.ZERO, target.global_position + Vector3.UP * 1.3, bot.reload_left < .12)
		else:
			var desired := waypoint - bot.global_position
			desired.y = 0.0
			var local := bot.global_transform.basis.inverse() * desired.normalized()
			var movement := Vector2(clampf(local.x * 2.6, -1.0, 1.0), 1.0 if distance > 45.0 else 0.0)
			bot.set_controls(movement, waypoint, target != null and bot.reload_left < .12)
	_update_capture(delta)

func _nearest_enemy(source: BattleTank) -> BattleTank:
	var candidate: BattleTank
	var closest := INF
	var optics := [1.9, 1.65, 1.45, 2.1]
	var view_multiplier: float = optics[clampi(int(source.spec.c), 0, 3)] if source == player and scoped else 1.0
	for other in tanks:
		if not is_instance_valid(other) or other == source or other.team == source.team or other.destroyed:
			continue
		var distance := source.global_position.distance_to(other.global_position)
		if distance > float(source.spec.view) * view_multiplier:
			continue
		var sight_ray := PhysicsRayQueryParameters3D.create(source.global_position + Vector3.UP * 1.7, other.global_position + Vector3.UP * 1.3)
		sight_ray.exclude = [source.get_rid()]
		var obstruction := get_world_3d().direct_space_state.intersect_ray(sight_ray)
		if obstruction and obstruction.collider != other:
			continue
		if distance < closest:
			closest = distance
			candidate = other
	return candidate

func _update_capture(delta: float) -> void:
	var team_a := 0
	var team_b := 0
	for tank in tanks:
		if tank.destroyed or Vector2(tank.global_position.x, tank.global_position.z).length() > 12.0:
			continue
		if tank.team == player.team:
			team_a += 1
			tank.capture_seconds += delta
		else:
			team_b += 1
	if team_a > team_b:
		capture_progress = minf(100.0, capture_progress + delta * 5.2 * (team_a - team_b))
	elif team_b > team_a:
		capture_progress = maxf(-100.0, capture_progress - delta * 5.2 * (team_b - team_a))

func _update_camera(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var target_distance := camera_distance
	var target_fov := 60.0
	if scoped:
		target_distance = maxf(8.0, camera_distance / sqrt(player.spec.zoom))
		target_fov = clampf(60.0 / player.spec.zoom, 13.0, 30.0)
	var yaw := camera_yaw
	var behind := Vector3(sin(yaw) * target_distance, 0, cos(yaw) * target_distance)
	var desired := player.global_position + Vector3(0, 6.3 if not scoped else 4.0, 0) + behind
	var origin := player.global_position + Vector3.UP * 2.1
	var query := PhysicsRayQueryParameters3D.create(origin, desired)
	query.exclude = [player.get_rid()]
	query.collide_with_bodies = true
	var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
	if obstruction:
		desired = obstruction.position + obstruction.normal * .65
	view_camera.global_position = view_camera.global_position.lerp(desired, 1.0 - exp(-delta * 8.0))
	var look := player.global_position + Vector3(0, 2.0 + tan(camera_pitch) * target_distance * .6, 0) - Vector3(sin(yaw) * 2.0, 0, cos(yaw) * 2.0)
	view_camera.look_at(look)
	view_camera.fov = lerpf(view_camera.fov, target_fov, 1.0 - exp(-delta * 7.0))
	view_camera.force_update_transform()

func _update_aim() -> void:
	if not is_instance_valid(player) or view_camera == null:
		return
	var center := get_viewport().get_visible_rect().size * .5
	var start := view_camera.project_ray_origin(center)
	var finish := start + view_camera.project_ray_normal(center) * 1100.0
	var query := PhysicsRayQueryParameters3D.create(start, finish)
	query.exclude = [player.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	aim_point = result.position if result else finish
	aim_color = PALETTE.text
	if result and result.collider is BattleTank:
		var target: BattleTank = result.collider
		var normal: Vector3 = result.normal
		var chance := GameData.penetration(float(player.spec.damage) * .74, GameData.armor_mm(target.spec, "front"), normal.dot(-view_camera.project_ray_normal(center)))
		aim_color = Color("72d28d") if chance >= .75 else Color("e8b65b") if chance >= .25 else Color("e86e61")
	if is_instance_valid(reticle):
		reticle.queue_redraw()

func _update_hud() -> void:
	if player == null or not is_instance_valid(player):
		return
	if labels.has("timer"):
		labels.timer.text = "%02d:%02d" % [floori(duration_left / 60.0), floori(fmod(duration_left, 60.0))]
		labels.hp.text = "%s   %d / %d HP" % [player.spec.name, roundi(player.hp), roundi(player.max_hp)]
		labels.health.size.x = maxf(1.0, 250.0 * player.hp / player.max_hp)
		labels.speed.text = "ГУСЕНИЦА · %d с" % ceili(player.repair_left) if player.tracks_broken else "%d КМ/Ч" % roundi(Vector2(player.velocity.x, player.velocity.z).length() * 3.6)
		labels.reload.text = "ГУСЕНИЦА · РЕМОНТ %d С" % ceili(player.repair_left) if player.tracks_broken else "ГОТОВО" if player.reload_left <= 0.0 else "ПЕРЕЗАРЯДКА %.1f С" % player.reload_left
		labels.objective.text = "ВАША КОМАНДА · БАЗА A %d%%" % roundi(capture_progress) if capture_progress > 1.0 else "ПРОТИВНИК · БАЗА A %d%%" % roundi(absf(capture_progress)) if capture_progress < -1.0 else "ЗАХВАТИТЕ БАЗУ A"
		labels.sight.text = "%d М · СВЕДЕНИЕ %d%%" % [roundi(player.global_position.distance_to(aim_point)), roundi((1.0 - player.aim_spread) * 100.0)]
		labels.score.text = "%d   :   %d" % [_alive_count(player.team), _alive_count(1 - player.team)]

func _alive_count(team_id: int) -> int:
	var count := 0
	for tank in tanks:
		if tank.team == team_id and not tank.destroyed:
			count += 1
	return count

func _update_effects(delta: float) -> void:
	effect_clock -= delta
	if effect_clock > 0.0:
		return
	effect_clock = .16
	for tank in tanks:
		if not is_instance_valid(tank) or tank.destroyed or Vector2(tank.velocity.x, tank.velocity.z).length() < 1.1:
			continue
		var rear := tank.global_position + tank.global_transform.basis.z * 2.5
		var dust := _effect(rear, Color("ddd2b4") if selected_map == "winter" else Color("a89b7b"), 3, .72)
		if dust:
			var puff := dust.get_child(0) as MeshInstance3D
			if puff:
				puff.scale = Vector3(.15, .15, .15)

func _effect(at: Vector3, color: Color, amount: int, lifetime := .45) -> Node3D:
	var effect := Node3D.new()
	effect.position = at
	add_child(effect)
	for i in amount:
		var puff := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(.11, .28)
		mesh.height = mesh.radius * 1.7
		mesh.radial_segments = 8
		puff.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = material
		puff.position = Vector3(randf_range(-.35, .35), randf_range(-.05, .3), randf_range(-.35, .35))
		effect.add_child(puff)
	var flash := OmniLight3D.new()
	flash.light_color = color
	flash.light_energy = 1.4
	flash.omni_range = 4.5
	flash.shadow_enabled = false
	effect.add_child(flash)
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3(2.2, 2.2, 2.2), lifetime)
	for child in effect.get_children():
		if child is GeometryInstance3D:
			tween.parallel().tween_property(child, "transparency", 1.0, lifetime)
		elif child is OmniLight3D:
			tween.parallel().tween_property(child, "light_energy", 0.0, lifetime)
	tween.tween_callback(effect.queue_free)
	return effect

func _play_one_shot(kind: String, at: Vector3, volume := .8) -> void:
	var path := "res://assets/audio/%s.ogg" % kind
	if not ResourceLoader.exists(path):
		return
	var audio := AudioStreamPlayer3D.new()
	audio.stream = load(path)
	audio.volume_db = linear_to_db(volume)
	audio.position = at
	audio.max_distance = 130.0
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

func _finish_battle(won: bool, reason: String) -> void:
	if not battle_live:
		return
	battle_live = false
	screen = Screen.RESULT
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var rows: Array[Dictionary] = []
	for tank in tanks:
		var row := {"id": tank.get_instance_id(), "name": str(tank.get_meta("callsign", "Командир")), "tank": tank.spec.name, "team": tank.team, "damage": tank.damage_total, "kills": tank.kills, "spotted": tank.spotted, "capture": tank.capture_seconds, "survived": not tank.destroyed, "win": (tank.team == player.team) == won}
		rows.append(row)
	latest_results = GameData.standings(rows)
	var own: Dictionary
	for row in latest_results:
		if int(row.id) == player.get_instance_id():
			own = row
	own.reward = GameData.award(own)
	GameData.save.silver += own.reward.silver
	GameData.save.xp += own.reward.xp
	GameData.save.battles += 1
	if won:
		GameData.save.wins += 1
	GameData.persist()
	if lan_peer != null and lan_host:
		rpc("client_match_finished", won, reason, GameData.save.silver, GameData.save.xp)
	_show_result(won, reason, own)

func _show_result(won: bool, reason: String, own: Dictionary) -> void:
	_clear_panel()
	root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := _panel(root_panel, Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size), Color("090e12df"), false)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(root_panel, "РЕЗУЛЬТАТЫ БОЯ                    ЛИЧНЫЙ РЕЗУЛЬТАТ       КОМАНДНЫЙ РЕЗУЛЬТАТ        СТАТИСТИКА", 12, PALETTE.muted).position = Vector2(40, 26)
	_label(root_panel, "ПОБЕДА!" if won else "ПОРАЖЕНИЕ", 76, PALETTE.gold if won else PALETTE.text).position = Vector2(46, 119)
	_label(root_panel, reason, 17, PALETTE.text).position = Vector2(50, 217)
	var reward: Dictionary = own.get("reward", {"silver": 0, "xp": 0, "parts": {}})
	var line := _panel(root_panel, Rect2(40, 294, get_viewport().get_visible_rect().size.x - 80, 80), Color("10171ddd"), true)
	_label(line, "◉  %d         ✦  %d         ♜  %d         ◎  %d" % [reward.silver, reward.xp, own.kills, own.damage], 25, PALETTE.text).position = Vector2(24, 12)
	_label(line, "СЕРЕБРО                       ОПЫТ                        УНИЧТОЖЕНО                 НАНЕСЕНО УРОНА", 11, PALETTE.muted).position = Vector2(26, 49)
	var columns := HBoxContainer.new()
	columns.position = Vector2(45, 410)
	columns.size = Vector2(get_viewport().get_visible_rect().size.x - 90, 250)
	columns.add_theme_constant_override("separation", 30)
	root_panel.add_child(columns)
	var personal := _panel(columns, Rect2(Vector2.ZERO, Vector2.ZERO), Color("10171ac9"), true)
	personal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(personal, "БОЕВОЙ РЕЗУЛЬТАТ\n\n%d МЕСТО ИЗ %d\n\nНАНЕСЕНО УРОНА  %d\nУНИЧТОЖЕНО  %d" % [own.place, latest_results.size(), own.damage, own.kills], 19, PALETTE.text).position = Vector2(22, 18)
	var awards := _panel(columns, Rect2(Vector2.ZERO, Vector2.ZERO), Color("10171ac9"), true)
	awards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var award_text := "НАГРАДЫ\n"
	for key in reward.parts:
		if reward.parts[key] > 0:
			award_text += "\n%s  +%d ◉" % [str(key).to_upper(), reward.parts[key]]
	_label(awards, award_text, 14, PALETTE.text).position = Vector2(22, 18)
	var table_button := _button(root_panel, "КОМАНДНЫЙ РЕЗУЛЬТАТ", func() -> void: _show_team_results())
	table_button.position = Vector2(44, 694)
	table_button.size = Vector2(210, 50)
	var garage_button := _button(root_panel, "ВЕРНУТЬСЯ В АНГАР", func() -> void: _return_to_hangar())
	garage_button.position = Vector2(44, get_viewport().get_visible_rect().size.y - 80)
	garage_button.size = Vector2(240, 50)
	var replay_button := _button(root_panel, "СЫГРАТЬ ЕЩЁ РАЗ", func() -> void: _start_battle(), true)
	replay_button.position = Vector2(298, get_viewport().get_visible_rect().size.y - 80)
	replay_button.size = Vector2(220, 50)

func _show_team_results() -> void:
	if screen != Screen.RESULT:
		return
	_clear_panel()
	var bg := _panel(root_panel, Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size), Color("091014f0"), false)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(root_panel, "РЕЗУЛЬТАТЫ КОМАНДЫ     ·     %s" % GameData.maps[selected_map].name, 20, PALETTE.gold).position = Vector2(42, 32)
	var y := 106.0
	for row in latest_results:
		var card := _panel(root_panel, Rect2(42, y, get_viewport().get_visible_rect().size.x - 84, 62), Color("142024e8") if row.team == player.team else Color("1e1817e8"), true)
		_label(card, "#%d     %-16s %-25s     УРОН %4d     УНИЧТОЖЕНО %d     +%d ◉   +%d ✦" % [row.place, row.name, row.tank, row.damage, row.kills, row.reward.silver, row.reward.xp], 14, PALETTE.text).position = Vector2(16, 18)
		y += 69.0
	_button(root_panel, "НАЗАД К ЛИЧНОМУ РЕЗУЛЬТАТУ", func() -> void:
		var own: Dictionary
		for row in latest_results:
			if int(row.id) == player.get_instance_id():
				own = row
				own.reward = GameData.award(own)
		_show_result(bool(own.get("win", false)), "Бой завершён", own)).position = Vector2(42, get_viewport().get_visible_rect().size.y - 82)

func _show_pause() -> void:
	if screen != Screen.BATTLE or not battle_live or lan_peer != null:
		return
	screen = Screen.PAUSE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_panel()
	var bg := _panel(root_panel, Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size), Color("080d11c9"), false)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(root_panel, "ПОЛЕ БОЯ\n%s  ·  %s" % [GameData.maps[selected_map].name, "КОМАНДНЫЙ БОЙ"], 12, PALETTE.muted).position = Vector2(24, 18)
	_label(root_panel, "ПАУЗА", 76, PALETTE.text, HORIZONTAL_ALIGNMENT_CENTER).position = Vector2(get_viewport().get_visible_rect().size.x * .5 - 260, 132)
	_label(root_panel, "ИГРА ПРИОСТАНОВЛЕНА", 16, PALETTE.muted, HORIZONTAL_ALIGNMENT_CENTER).position = Vector2(get_viewport().get_visible_rect().size.x * .5 - 260, 220)
	var choices := VBoxContainer.new()
	choices.position = Vector2(get_viewport().get_visible_rect().size.x * .5 - 165, 294)
	choices.size = Vector2(330, 234)
	choices.add_theme_constant_override("separation", 10)
	root_panel.add_child(choices)
	_button(choices, "ПРОДОЛЖИТЬ ИГРУ", _resume_battle, true)
	_button(choices, "НАСТРОЙКИ", _show_settings)
	_button(choices, "ВЕРНУТЬСЯ В АНГАР", func() -> void: _finish_battle(false, "Бой прерван"); _return_to_hangar())
	_button(choices, "ПОКИНУТЬ БОЙ", func() -> void: _finish_battle(false, "Досрочный выход из боя"))
	_button(root_panel, "ESC   Назад", _resume_battle).position = Vector2(24, get_viewport().get_visible_rect().size.y - 63)

func _resume_battle() -> void:
	if screen != Screen.PAUSE and screen != Screen.SETTINGS:
		return
	screen = Screen.BATTLE
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_clear_panel()
	countdown_label.hide()
	_update_hud()

func _show_settings() -> void:
	paused_from = screen
	screen = Screen.SETTINGS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_panel()
	var viewport := get_viewport().get_visible_rect().size
	var bg := _panel(root_panel, Rect2(Vector2.ZERO, viewport), Color("080d10f0"), false)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(root_panel, "⚙  НАСТРОЙКИ", 34, PALETTE.text).position = Vector2(36, 22)
	_label(root_panel, "НАСТРОЙ СВОЮ БИТВУ", 11, PALETTE.muted, HORIZONTAL_ALIGNMENT_RIGHT).position = Vector2(viewport.x - 290, 35)
	var content := HBoxContainer.new()
	content.position = Vector2(34, 100)
	content.size = Vector2(viewport.x - 68, viewport.y - 188)
	content.add_theme_constant_override("separation", 20)
	root_panel.add_child(content)
	var nav := VBoxContainer.new()
	nav.custom_minimum_size.x = 205
	content.add_child(nav)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	var preview := _panel(content, Rect2(Vector2.ZERO, Vector2.ZERO), Color("12191be0"), true)
	preview.custom_minimum_size = Vector2(225, 275)
	_label(preview, "ЯЗЫК\nРусский\n\nИНТЕРФЕЙС\nТёмный металл\n\nКАЖДЫЙ БОЙ\nДЕЛАЕТ ТЕБЯ\nСИЛЬНЕЕ.", 18, PALETTE.text).position = Vector2(22, 28)
	for section in ["ГРАФИКА", "ЗВУК", "УПРАВЛЕНИЕ", "ИГРОВОЙ ПРОЦЕСС"]:
		_button(nav, "▣   " + section, func() -> void: _fill_settings(section, body))
	_fill_settings("ГРАФИКА", body)
	var footer := HBoxContainer.new()
	footer.position = Vector2(34, viewport.y - 72)
	footer.size = Vector2(viewport.x - 68, 48)
	footer.add_theme_constant_override("separation", 10)
	root_panel.add_child(footer)
	_button(footer, "ПО УМОЛЧАНИЮ", func() -> void:
		runtime_settings = {"volume": .45, "quality": "high", "render_scale": 1.0, "shadows": true, "difficulty": "normal", "sensitivity": 1.0}
		GameData.save.settings = runtime_settings.duplicate(true)
		GameData.persist()
		_show_settings()).custom_minimum_size.x = 185
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	_button(footer, "ПРИМЕНИТЬ", func() -> void:
		GameData.save.settings = runtime_settings.duplicate(true)
		GameData.persist()
		_apply_settings()
		_close_settings(), true).custom_minimum_size.x = 170
	_button(footer, "НАЗАД", _close_settings).custom_minimum_size.x = 120

func _fill_settings(section: String, body: VBoxContainer) -> void:
	for child in body.get_children():
		child.queue_free()
	_label(body, section, 19, PALETTE.text)
	match section:
		"ГРАФИКА":
			var quality := _option(body, "Качество графики", ["Высокое", "Производительность"])
			quality.select(0 if runtime_settings.quality == "high" else 1)
			quality.item_selected.connect(func(index: int) -> void: runtime_settings.quality = "high" if index == 0 else "low")
			var scale := _option(body, "Разрешение 3D", ["50%", "75%", "100%", "125%", "150%"])
			var choices := [.5, .75, 1.0, 1.25, 1.5]
			scale.select(choices.find(float(runtime_settings.get("render_scale", 1.0))))
			scale.item_selected.connect(func(index: int) -> void: runtime_settings.render_scale = choices[index])
			_toggle(body, "Динамические тени", "shadows")
			_toggle(body, "Постобработка, AO и отражения", "postprocessing")
			_label(body, "Режим производительности снижает детализацию окружения; интерфейс сохраняет чёткость.", 12, PALETTE.muted)
		"ЗВУК":
			var volume := HSlider.new()
			volume.min_value = 0
			volume.max_value = 1
			volume.step = .05
			volume.value = runtime_settings.volume
			volume.value_changed.connect(func(value: float) -> void:
				runtime_settings.volume = value
				AudioServer.set_bus_volume_db(0, linear_to_db(value)))
			body.add_child(volume)
			_label(body, "Общая громкость: %d%%" % roundi(runtime_settings.volume * 100.0), 14, PALETTE.text)
		"УПРАВЛЕНИЕ":
			var sensitivity := HSlider.new()
			sensitivity.min_value = .25
			sensitivity.max_value = 2.5
			sensitivity.step = .05
			sensitivity.value = runtime_settings.sensitivity
			sensitivity.value_changed.connect(func(value: float) -> void: runtime_settings.sensitivity = value)
			body.add_child(sensitivity)
			_label(body, "WASD — движение   ·   Мышь — башня   ·   ЛКМ — выстрел\nShift — оптика   ·   Tab — команды   ·   Esc — пауза", 14, PALETTE.text)
		"ИГРОВОЙ ПРОЦЕСС":
			var difficulty := _option(body, "Сложность ботов", ["Лёгкие", "Обычные", "Сложные"])
			var difficulties := ["easy", "normal", "hard"]
			difficulty.select(difficulties.find(runtime_settings.difficulty))
			difficulty.item_selected.connect(func(index: int) -> void: runtime_settings.difficulty = difficulties[index])
			_label(body, "Применяется со следующего боя.", 13, PALETTE.muted)

func _toggle(parent: Control, text: String, setting: String) -> void:
	var checkbox := CheckButton.new()
	checkbox.text = text
	checkbox.button_pressed = bool(runtime_settings.get(setting, true))
	checkbox.toggled.connect(func(value: bool) -> void: runtime_settings[setting] = value)
	parent.add_child(checkbox)

func _option(parent: Control, label_text: String, options: Array) -> OptionButton:
	_label(parent, label_text, 14, PALETTE.text)
	var control := OptionButton.new()
	control.custom_minimum_size = Vector2(245, 42)
	for option in options:
		control.add_item(str(option))
	parent.add_child(control)
	return control

func _close_settings() -> void:
	if paused_from == Screen.PAUSE:
		_show_pause()
	elif paused_from == Screen.BATTLE:
		screen = Screen.BATTLE
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_clear_panel()
	else:
		screen = Screen.HANGAR
		_show_hangar()

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(float(runtime_settings.volume)))
	get_viewport().scaling_3d_scale = float(runtime_settings.get("render_scale", 1.0))
	for light in find_children("*", "DirectionalLight3D", true, false):
		light.shadow_enabled = bool(runtime_settings.shadows) and runtime_settings.quality == "high"
	for world in find_children("*", "WorldEnvironment", true, false):
		if world.environment:
			var postprocessing: bool = runtime_settings.quality == "high" and bool(runtime_settings.get("postprocessing", true))
			world.environment.ssao_enabled = postprocessing
			world.environment.ssil_enabled = postprocessing
			world.environment.ssr_enabled = postprocessing

func _show_lan_lobby() -> void:
	screen = Screen.LAN_LOBBY
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_panel()
	var bg := _panel(root_panel, Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size), Color("080d11e8"), false)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(root_panel, "ЛОКАЛЬНАЯ СЕТЬ · RADMIN VPN", 15, PALETTE.gold, HORIZONTAL_ALIGNMENT_CENTER).position = Vector2(0, 110)
	_label(root_panel, "БОЙ 1 × 1", 48, PALETTE.text, HORIZONTAL_ALIGNMENT_CENTER).position = Vector2(0, 150)
	var lobby := VBoxContainer.new()
	lobby.position = Vector2(get_viewport().get_visible_rect().size.x * .5 - 245, 245)
	lobby.size = Vector2(490, 340)
	lobby.add_theme_constant_override("separation", 12)
	root_panel.add_child(lobby)
	_button(lobby, "СОЗДАТЬ ЛОББИ", _host_lan, true)
	_label(lobby, "ДРУГ ПОДКЛЮЧАЕТСЯ К IP-АДРЕСУ RADMIN ХОСТА", 11, PALETTE.muted, HORIZONTAL_ALIGNMENT_CENTER)
	var ip_input := LineEdit.new()
	ip_input.name = "LanAddress"
	ip_input.placeholder_text = "IP-АДРЕС RADMIN VPN"
	ip_input.custom_minimum_size.y = 46
	lobby.add_child(ip_input)
	_button(lobby, "ВОЙТИ В ЛОББИ", func() -> void: _join_lan(ip_input.text))
	_label(lobby, "Оба игрока должны иметь доступ к одному адресу Radmin VPN.\nРазрешите TCP/UDP-порт 28765 в брандмауэре Windows.", 12, PALETTE.muted)
	_button(lobby, "← НАЗАД В АНГАР", func() -> void: _show_hangar())

func _host_lan() -> void:
	lan_peer = ENetMultiplayerPeer.new()
	var error := lan_peer.create_server(28765, 1)
	if error != OK:
		lan_peer = null
		_notify("Не удалось открыть порт 28765. Проверьте брандмауэр.")
		return
	multiplayer.multiplayer_peer = lan_peer
	lan_host = true
	lan_code = "%04d" % randi_range(1000, 9999)
	lan_wait_seconds = 600.0
	multiplayer.peer_connected.connect(_on_peer_connected)
	_show_lobby_wait()

func _join_lan(address: String) -> void:
	if address.strip_edges().is_empty():
		_notify("Введите IP-адрес Radmin хоста.")
		return
	lan_peer = ENetMultiplayerPeer.new()
	var error := lan_peer.create_client(address.strip_edges(), 28765)
	if error != OK:
		lan_peer = null
		_notify("Не удалось подключиться к хосту.")
		return
	multiplayer.multiplayer_peer = lan_peer
	lan_host = false
	lan_wait_seconds = 12.0
	_show_lobby_wait()

func _show_lobby_wait() -> void:
	_clear_panel()
	var bg := _panel(root_panel, Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size), Color("080d11ed"), false)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(root_panel, "ЛОКАЛЬНАЯ СЕТЬ · RADMIN VPN", 15, PALETTE.gold, HORIZONTAL_ALIGNMENT_CENTER).position = Vector2(0, 134)
	_label(root_panel, "ОЖИДАНИЕ СОПЕРНИКА…", 31, PALETTE.text, HORIZONTAL_ALIGNMENT_CENTER).position = Vector2(0, 215)
	if lan_host:
		var addresses := []
		for address in IP.get_local_addresses():
			if address.begins_with("26.") or address.begins_with("25."):
				addresses.append(address)
		var text := "ХОСТ · ПОРТ 28765 · КОД %s\n%s\nПЕРЕДАЙТЕ ДРУГУ IP ИЗ RADMIN VPN" % [lan_code, "\n".join(addresses) if not addresses.is_empty() else "IP ПОКА НЕ ОБНАРУЖЕН — ВВЕДИТЕ ЕГО ВРУЧНУЮ"]
		_label(root_panel, text, 15, PALETTE.muted, HORIZONTAL_ALIGNMENT_CENTER).position = Vector2(0, 290)
	_button(root_panel, "ОТМЕНА", _leave_lan).position = Vector2(get_viewport().get_visible_rect().size.x * .5 - 95, 456)

func _on_peer_connected(id: int) -> void:
	if lan_host:
		_start_lan_match(id)

func _start_lan_match(peer_id: int) -> void:
	selected_map = GameData.save.map
	var host_spec := GameData.stats(GameData.tank_by_id(selected_tank_id), GameData.save.modules[selected_tank_id])
	rpc_id(peer_id, "client_start_match", selected_map, host_spec)
	_start_battle()

@rpc("authority", "call_remote", "reliable")
func client_start_match(map_id: String, host_spec: Dictionary) -> void:
	selected_map = map_id
	_start_battle()

@rpc("any_peer", "call_remote", "unreliable_ordered")
func submit_remote_state(position: Vector3, yaw: float, turret_yaw: float, pitch: float, health: float, movement: Vector2, target: Vector3, shoot: bool) -> void:
	if not multiplayer.is_server() or remote_tank == null:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0 and remote_tank:
		remote_tank.global_position = position
		remote_tank.hull_heading = yaw
		remote_tank.rotation.y = yaw
		remote_tank.turret.rotation.y = turret_yaw
		remote_tank.cannon.rotation.x = pitch
		remote_tank.hp = health
		remote_tank.set_controls(Vector2.ZERO, target, false)

@rpc("any_peer", "call_remote", "reliable")
func request_remote_shot(sequence: int, shot_power: int, origin: Vector3, direction: Vector3) -> void:
	if not multiplayer.is_server() or remote_tank == null:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0 or sender != lan_peer.get_peers()[0] or sequence <= remote_last_shot:
		return
	remote_last_shot = sequence
	var shell := ShellScript.new() as BattleShell
	shell.owner_tank = remote_tank
	shell.power = shot_power
	shell.global_position = origin
	shell.velocity = direction.normalized() * 285.0
	shell.impact_event = _on_impact
	add_child(shell)
	shells.append(shell)
	rpc("server_shot", origin, direction, shot_power, sequence)

@rpc("authority", "call_remote", "unreliable_ordered")
func server_broadcast_state(snapshot: Array) -> void:
	for i in mini(snapshot.size(), tanks.size()):
		var data: Dictionary = snapshot[i]
		var team_id: int = int(data.team)
		var tank: BattleTank = player if player.team == team_id else remote_tank
		if not is_instance_valid(tank):
			continue
		tank.global_position = data.position
		tank.rotation.y = data.yaw
		tank.turret.rotation.y = data.turret
		tank.cannon.rotation.x = data.pitch
		tank.hp = data.hp
		tank.destroyed = data.destroyed
		duration_left = data.time
		capture_progress = data.capture

@rpc("any_peer", "call_remote", "unreliable")
func server_shot(origin: Vector3, direction: Vector3, shot_power: int, sequence: int) -> void:
	if lan_peer == null or not lan_host:
		var source := remote_tank if remote_tank else player
		var shell := ShellScript.new() as BattleShell
		shell.owner_tank = source
		shell.power = shot_power
		shell.global_position = origin
		shell.velocity = direction.normalized() * 285.0
		shell.impact_event = _on_impact
		add_child(shell)
		shells.append(shell)
		remote_last_shot = sequence

@rpc("authority", "call_remote", "reliable")
func client_match_finished(won: bool, reason: String, silver: int, xp: int) -> void:
	GameData.save.silver = silver
	GameData.save.xp = xp
	GameData.persist()
	_finish_battle(won, reason)

func _network_process(delta: float) -> void:
	if lan_peer == null or lan_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	fire_clock -= delta
	if lan_host:
		if fire_clock <= 0.0:
			fire_clock = .07
			var snapshot: Array = []
			for tank in tanks:
				snapshot.append({"team": tank.team, "position": tank.global_position, "yaw": tank.rotation.y, "turret": tank.turret.rotation.y, "pitch": tank.cannon.rotation.x, "hp": tank.hp, "destroyed": tank.destroyed, "time": duration_left, "capture": capture_progress})
			rpc("server_broadcast_state", snapshot)

func _leave_lan() -> void:
	multiplayer.multiplayer_peer = null
	lan_peer = null
	lan_host = false
	remote_tank = null
	_show_hangar()

func _return_to_hangar() -> void:
	if lan_peer != null:
		_leave_lan()
	for shell in shells:
		if is_instance_valid(shell):
			shell.queue_free()
	shells.clear()
	for tank in tanks:
		if is_instance_valid(tank):
			tank.queue_free()
	tanks.clear()
	ai_tanks.clear()
	if is_instance_valid(arena):
		arena.queue_free()
	arena = null
	player = null
	remote_tank = null
	_show_hangar()

func _create_hud() -> void:
	hud.show()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in hud.get_children():
		child.queue_free()
	labels.clear()
	var top := _panel(hud, Rect2(0, 0, get_viewport().get_visible_rect().size.x, 68), Color("081014cc"), false)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.score = _label(top, "3   :   3", 23, PALETTE.text, HORIZONTAL_ALIGNMENT_CENTER)
	labels.score.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	labels.score.offset_left = -120
	labels.score.offset_right = 120
	labels.score.offset_top = 10
	labels.score.offset_bottom = 50
	labels.timer = _label(top, "08:00", 20, PALETTE.text, HORIZONTAL_ALIGNMENT_CENTER)
	labels.timer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	labels.timer.offset_left = -40
	labels.timer.offset_right = 40
	labels.timer.offset_top = 36
	labels.timer.offset_bottom = 66
	labels.objective = _label(top, "ЗАХВАТИТЕ БАЗУ A", 12, PALETTE.gold, HORIZONTAL_ALIGNMENT_CENTER)
	labels.objective.position = Vector2(12, 20)
	labels.objective.size = Vector2(get_viewport().get_visible_rect().size.x - 24, 25)
	var bottom := _panel(hud, Rect2(26, get_viewport().get_visible_rect().size.y - 113, 325, 88), Color("0b1115dc"), true)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.hp = _label(bottom, "", 17, PALETTE.text)
	labels.hp.position = Vector2(14, 9)
	labels.hp.size = Vector2(300, 30)
	labels.health = ColorRect.new()
	labels.health.color = PALETTE.green
	labels.health.position = Vector2(14, 43)
	labels.health.size = Vector2(250, 7)
	bottom.add_child(labels.health)
	labels.reload = _label(bottom, "", 11, PALETTE.gold)
	labels.reload.position = Vector2(14, 56)
	labels.reload.size = Vector2(280, 23)
	labels.speed = _label(hud, "0 КМ/Ч", 12, PALETTE.text)
	labels.speed.position = Vector2(get_viewport().get_visible_rect().size.x - 166, get_viewport().get_visible_rect().size.y - 55)
	labels.sight = _label(hud, "", 10, PALETTE.text, HORIZONTAL_ALIGNMENT_CENTER)
	labels.sight.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	labels.sight.offset_left = -115
	labels.sight.offset_right = 115
	labels.sight.offset_top = -42
	labels.sight.offset_bottom = -17
	_button(hud, "Ⅱ", _show_pause).position = Vector2(get_viewport().get_visible_rect().size.x - 64, 20)
	reticle.hide()
	_add_touch_controls()
	_update_hud()

func _add_touch_controls() -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	var size := get_viewport().get_visible_rect().size
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(layer)
	var pad_x := 34.0
	var pad_y := size.y - 222.0
	for item in [["▲", "forward", Vector2(pad_x + 62, pad_y)], ["◀", "turn_left", Vector2(pad_x, pad_y + 62)], ["▼", "backward", Vector2(pad_x + 62, pad_y + 124)], ["▶", "turn_right", Vector2(pad_x + 124, pad_y + 62)]]:
		var drive_button := _touch_button(layer, item[0], item[2], Vector2(58, 58))
		var action_name: String = item[1]
		drive_button.button_down.connect(func() -> void: Input.action_press(action_name))
		drive_button.button_up.connect(func() -> void: Input.action_release(action_name))
	var fire_button := _touch_button(layer, "ОГОНЬ", Vector2(size.x - 150, size.y - 176), Vector2(112, 112), true)
	fire_button.button_down.connect(func() -> void: firing = true)
	fire_button.button_up.connect(func() -> void: firing = false)
	var aim_button := _touch_button(layer, "ОПТИКА", Vector2(size.x - 264, size.y - 116), Vector2(98, 54))
	aim_button.button_down.connect(func() -> void:
		scoped = true
		reticle.show())
	aim_button.button_up.connect(func() -> void:
		scoped = false
		reticle.hide())

func _touch_button(parent: Control, title: String, at: Vector2, dimensions: Vector2, primary := false) -> Button:
	var control := _button(parent, title, func() -> void: pass, primary)
	control.position = at
	control.size = dimensions
	control.custom_minimum_size = dimensions
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	control.add_theme_font_size_override("font_size", 12)
	return control

func _build_reticle() -> void:
	reticle = Control.new()
	reticle.name = "Reticle"
	reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reticle.offset_left = -75
	reticle.offset_right = 75
	reticle.offset_top = -75
	reticle.offset_bottom = 75
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.draw.connect(func() -> void:
		if not scoped and screen != Screen.BATTLE:
			return
		var center := reticle.size * .5
		var radius: float = 21.0 + (player.aim_spread * 31.0 if is_instance_valid(player) else 18.0)
		reticle.draw_arc(center, radius, 0.0, TAU, 60, aim_color, 1.5, true)
		reticle.draw_circle(center, 2.6, aim_color)
		for angle in [0.0, PI * .5, PI, PI * 1.5]:
			var point := center + Vector2(cos(angle), sin(angle)) * (radius + 10.0)
			reticle.draw_line(center + Vector2(cos(angle), sin(angle)) * (radius - 6.0), point, aim_color, 1.2, true))
	root_panel.add_child(reticle)
	reticle.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if screen == Screen.BATTLE:
			_show_pause()
		elif screen == Screen.PAUSE or screen == Screen.SETTINGS:
			_close_settings() if screen == Screen.SETTINGS else _resume_battle()
	if event.is_action_pressed("scoreboard") and screen == Screen.BATTLE:
		_show_scoreboard(true)
	if event.is_action_released("scoreboard"):
		_show_scoreboard(false)
	if event.is_action_pressed("aim") and screen == Screen.BATTLE:
		scoped = true
		camera_distance = 23.0
		reticle.show()
	if event.is_action_released("aim"):
		scoped = false
		if screen == Screen.BATTLE:
			reticle.hide()
	if event is InputEventMouseMotion:
		if screen == Screen.BATTLE and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			camera_yaw -= event.relative.x * .0028 * float(runtime_settings.sensitivity)
			camera_pitch = clampf(camera_pitch - event.relative.y * .0015 * float(runtime_settings.sensitivity), -.35, .44)
		elif screen == Screen.HANGAR and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			camera_yaw -= event.relative.x * .008
			view_camera.global_position = Vector3(sin(camera_yaw) * 17, 7, cos(camera_yaw) * 17)
			view_camera.look_at(Vector3.ZERO)
	if event is InputEventScreenDrag and screen == Screen.BATTLE:
		camera_yaw -= event.relative.x * .0035 * float(runtime_settings.sensitivity)
		camera_pitch = clampf(camera_pitch - event.relative.y * .0018 * float(runtime_settings.sensitivity), -.35, .44)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			firing = event.pressed and screen == Screen.BATTLE
			if event.pressed and screen == Screen.HANGAR:
				pass

func _show_scoreboard(visible: bool) -> void:
	if not visible or screen != Screen.BATTLE:
		if labels.has("scoreboard") and is_instance_valid(labels.scoreboard):
			labels.scoreboard.queue_free()
			labels.erase("scoreboard")
		return
	if labels.has("scoreboard"):
		return
	var panel := _panel(hud, Rect2(get_viewport().get_visible_rect().size * .18, get_viewport().get_visible_rect().size * .14), Color("0a1015ee"), true)
	panel.size = get_viewport().get_visible_rect().size * .64
	labels.scoreboard = panel
	_label(panel, "БОЕВОЙ ПОРЯДОК\n", 24, PALETTE.text).position = Vector2(24, 18)
	var y := 72.0
	for team_id in [player.team, 1 - player.team]:
		_label(panel, "ВАША КОМАНДА" if team_id == player.team else "ПРОТИВНИК", 14, PALETTE.green if team_id == player.team else PALETTE.red).position = Vector2(26, y)
		y += 28
		for tank in tanks:
			if tank.team == team_id:
				_label(panel, "%s   %s    %d HP     %d УРОНА" % [tank.get_meta("callsign", "Командир"), tank.spec.name, roundi(tank.hp), tank.damage_total], 12, PALETTE.muted if tank.destroyed else PALETTE.text).position = Vector2(36, y)
				y += 24

func _clear_panel() -> void:
	for child in root_panel.get_children():
		if child == hud or child == countdown_label or child == notice_label or child == reticle:
			continue
		child.queue_free()

func _show_message(title: String, message: String, on_close: Callable) -> void:
	_clear_panel()
	screen = Screen.SETTINGS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var size := get_viewport().get_visible_rect().size
	var bg := _panel(root_panel, Rect2(Vector2.ZERO, size), Color("080d11e8"), false)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := _panel(root_panel, Rect2(size * .25, size * .5), Color("10191beF"), true)
	frame.size = Vector2(size.x * .5, 300)
	_label(frame, title, 24, PALETTE.gold).position = Vector2(24, 20)
	_label(frame, message, 15, PALETTE.text).position = Vector2(24, 70)
	_button(frame, "НАЗАД", on_close).position = Vector2(24, 230)

func _panel(parent: Control, rect: Rect2, color: Color, bordered: bool) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = PALETTE.line if not bordered else PALETTE.gold_dark
	style.set_border_width_all(1 if bordered else 0)
	style.set_corner_radius_all(3)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _label(parent: Control, text: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Control, text: String, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", PALETTE.text)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("222a2b") if not primary else Color("d9b574")
	normal.border_color = Color("545e5d") if not primary else PALETTE.gold
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("303a39") if not primary else Color("f0ce89")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("171f20")
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _notify(text: String) -> void:
	notice_label.text = text
	notice_label.show()
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if is_instance_valid(notice_label):
			notice_label.hide())

func _roman(value: int) -> String:
	return ["I", "II", "III", "IV", "V"][clampi(value - 1, 0, 4)]
