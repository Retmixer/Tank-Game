extends Node

const DATA_PATH := "res://data/game_data.json"
const SAVE_PATH := "user://steel_frontier_save.json"
var tanks: Array[Dictionary] = []
var maps: Dictionary = {}
var armor_zones: Array = []
var save: Dictionary = {}
var persistence_enabled := true

func battle_scene_path(map_id: String) -> String:
	# Active authored environments; the original scenes remain in scenes/levels/.
	var id := map_id if map_id in ["training","desert","winter"] else "training"
	return "res://scenes/levels/polyhaven/%s.tscn" % id

func _ready() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing native game data: " + DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Invalid game_data.json")
		return
	tanks.assign(parsed.get("tanks", []))
	for i in tanks.size():
		var resource_path := "res://resources/vehicles/%s.tres" % tanks[i].id
		if ResourceLoader.exists(resource_path):
			var definition := load(resource_path) as VehicleDefinition
			tanks[i] = definition.apply_to(tanks[i])
	maps = parsed.get("maps", {})
	armor_zones = parsed.get("armorZones", [])
	save = _load_save()

func defaults() -> Dictionary:
	var levels := {}
	var modules := {}
	for tank in tanks:
		levels[tank.id] = 1
		modules[tank.id] = {"gun": 1, "armor": 1, "engine": 1, "tracks": 1}
	return {"silver": 0, "xp": 0, "battles": 0, "wins": 0, "selected": "0-1", "map": "training", "team_size": 3, "owned": {"0-1": true}, "levels": levels, "modules": modules, "settings": {"volume": .45, "quality": "high", "render_scale": 1.0, "shadows": true, "difficulty": "normal", "sensitivity": 1.0, "postprocessing": true, "camera_shake": true}}

func _load_save() -> Dictionary:
	var result := defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		return result
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var raw: Variant = JSON.parse_string(file.get_as_text()) if file else null
	if not raw is Dictionary:
		return result
	for key in ["silver", "xp", "battles", "wins"]:
		result[key] = maxi(0, int(raw.get(key, result[key])))
	if int(raw.get("teamSize", raw.get("team_size", 3))) in [3, 5, 7]:
		result.team_size = int(raw.get("teamSize", raw.get("team_size", 3)))
	if raw.get("owned") is Dictionary:
		result.owned.merge(raw.owned, true)
	if raw.get("levels") is Dictionary:
		result.levels.merge(raw.levels, true)
	if raw.get("modules") is Dictionary:
		result.modules.merge(raw.modules, true)
	if maps.has(raw.get("map", "")):
		result.map = raw.map
	if tanks.any(func(item: Dictionary) -> bool: return item.id == raw.get("selected", "")):
		result.selected = raw.selected
	if raw.get("settings") is Dictionary:
		result.settings.merge(raw.settings, true)
	result.owned["0-1"] = true
	if not result.owned.get(result.selected, false):
		result.selected = "0-1"
	return result

func persist() -> void:
	if not persistence_enabled:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save, "\t"))

func tank_by_id(id: String) -> Dictionary:
	for tank in tanks:
		if tank.id == id:
			return tank
	return tanks[1] if tanks.size() > 1 else {}

func stats(tank: Dictionary, installed: Dictionary) -> Dictionary:
	var s := tank.duplicate(true)
	var gun: int = int(installed.get("gun", 1)) - 1
	var armor: int = int(installed.get("armor", 1)) - 1
	var engine: int = int(installed.get("engine", 1)) - 1
	var tracks: int = int(installed.get("tracks", 1)) - 1
	s.hp = roundi(tank.hp * (1.0 + armor * .075))
	s.damage = roundi(tank.damage * (1.0 + gun * .065))
	s.reload = tank.reload * (1.0 - gun * .025)
	s.armor = tank.armor + armor * 2
	s.speed = tank.speed * (1.0 + engine * .025)
	s.turn = tank.turn * (1.0 + tracks * .03)
	s.zoom = tank.zoom + gun * .12
	s.modules = installed.duplicate(true)
	return s

func tank_price(tank: Dictionary) -> Dictionary:
	var tier: int = int(tank.c)
	var nation: int = int(tank.n)
	return {"xp": [350, 850, 1500, 2100][tier] + nation * 150, "silver": [1200, 2800, 4800, 6500][tier] + nation * 400}

func unlock(tank_id: String) -> bool:
	if save.owned.get(tank_id, false):
		return false
	var tank := tank_by_id(tank_id)
	var price := tank_price(tank)
	if save.xp < price.xp or save.silver < price.silver:
		return false
	save.xp -= price.xp
	save.silver -= price.silver
	save.owned[tank_id] = true
	persist()
	return true

func armor_mm(tank: Dictionary, zone: String) -> float:
	var c: int = int(tank.c)
	var n: int = int(tank.n)
	var base: Array = [[48, 95, 150, 45], [65, 125, 165, 35], [38, 78, 135, 30]][n]
	var index := armor_zones.find(zone)
	var plate: float = base[mini(index, base.size() - 1)] if index >= 0 and index < 4 else base[0]
	return plate * (1.0 + (int(tank.get("modules", {}).get("armor", 1)) - 1) * .025)

func penetration(power: float, armor: float, impact_cos: float) -> float:
	var effective: float = armor / maxf(.2, absf(impact_cos))
	return clampf((power / effective - .75) / .5, 0.0, 1.0)

func standings(rows: Array[Dictionary]) -> Array[Dictionary]:
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.damage == b.damage:
			return a.kills > b.kills
		return a.damage > b.damage)
	var place := 0
	var previous_damage := -1
	var previous_kills := -1
	for i in rows.size():
		if rows[i].damage != previous_damage or rows[i].kills != previous_kills:
			place = i + 1
		rows[i].place = place
		previous_damage = rows[i].damage
		previous_kills = rows[i].kills
	return rows

func award(row: Dictionary) -> Dictionary:
	var rank: int = maxi(0, 7 - int(row.get("place", 7)))
	var parts := {"participation": 300, "damage": roundi(row.get("damage", 0) * .2), "kills": row.get("kills", 0) * 150, "victory": 200 if row.get("win", false) else 0, "spotting": row.get("spotted", 0) * 25, "objective": roundi(row.get("capture", 0) * 4.0), "survival": 75 if row.get("survived", false) else 0, "placement": rank * 75}
	return {"parts": parts, "silver": parts.values().reduce(func(a: int, b: int) -> int: return a + b, 0), "xp": 70 + roundi(row.get("damage", 0) * .12) + row.get("kills", 0) * 60 + (100 if row.get("win", false) else 0) + rank * 30}
