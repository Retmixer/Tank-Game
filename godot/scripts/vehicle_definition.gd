extends Resource
class_name VehicleDefinition

@export var vehicle_id: String
@export var display_name: String
@export_category("Combat")
@export var hit_points: float = 820
@export var damage: float = 161
@export var armor: float = 17
@export var reload_seconds: float = 3.6
@export var track_health: float = 125
@export_category("Mobility and optics")
@export var speed: float = 8.05
@export var reverse_speed: float = 3.05
@export var turn_speed: float = 1.0
@export var turret_speed: float = 1.4
@export var view_distance: float = 118
@export var dispersion: float = .015
@export var aim_seconds: float = 1.1
@export var zoom: float = 3.2

func apply_to(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	result.merge({"hp":hit_points,"damage":damage,"armor":armor,"reload":reload_seconds,
		"tracks":track_health,"speed":speed,"reverse":reverse_speed,"turn":turn_speed,
		"turret":turret_speed,"view":view_distance,"spread":dispersion,"aim":aim_seconds,
		"zoom":zoom,"name":display_name}, true)
	return result
