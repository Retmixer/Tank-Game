extends CharacterBody3D
class_name BattleTank

@export var definition: VehicleDefinition
var spec: Dictionary = {}
var muzzle: Marker3D
var wheel_nodes: Array[Node] = []
var team := 0
var is_player := false
var hp := 1.0
var max_hp := 1.0
var reload_left := 0.0
var turret: Node3D
var cannon: Node3D
var track_hp := 0.0
var tracks_broken := false
var repair_left := 0.0
var damage_total := 0
var kills := 0
var spotted := 0
var capture_seconds := 0.0
var destroyed := false
var aim_spread := 1.0
var shot_sequence := 0
var engine_audio: AudioStreamPlayer3D
var drive_input := Vector2.ZERO
var look_target := Vector3.ZERO
var trigger := false
var shot_request: Callable
var move_speed := 0.0
var hull_heading := 0.0
var running_gear: Node
var previous_aim_yaw := 0.0
var previous_hull_yaw := 0.0

func configure(vehicle: Dictionary, side: int, player_controlled: bool) -> void:
	spec = vehicle
	team = side
	is_player = player_controlled
	hp = vehicle.hp
	max_hp = vehicle.hp
	track_hp = vehicle.tracks
	turret = find_child("Turret", true, false) as Node3D
	cannon = find_child("GunPivot", true, false) as Node3D
	muzzle = find_child("Muzzle", true, false) as Marker3D
	wheel_nodes = find_children("Wheel_*","Node3D",true,false)
	engine_audio = get_node("EngineAudio")
	assert(turret != null and cannon != null and muzzle != null, "Use the authored vehicle scene, not BattleTank.new()")

func _ready() -> void:
	if spec.is_empty() and definition:
		configure(GameData.tank_by_id(definition.vehicle_id), 0, false)
	running_gear=preload("res://scripts/tracked_running_gear.gd").new()
	add_child(running_gear)
	running_gear.setup(self)
	if engine_audio and DisplayServer.get_name() != "headless":
		engine_audio.play()

func _exit_tree() -> void:
	if engine_audio:
		engine_audio.stop()

func _physics_process(delta: float) -> void:
	if destroyed:
		velocity.x = move_toward(velocity.x, 0.0, 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 7.0 * delta)
		move_and_slide()
		return
	reload_left = maxf(0.0, reload_left - delta)
	if tracks_broken:
		repair_left -= delta
		if repair_left <= 0.0:
			tracks_broken = false
			track_hp = spec.tracks
	_apply_drive(drive_input, delta)
	if not look_target.is_zero_approx():
		_update_turret(look_target, delta)
	if trigger and reload_left <= 0.0 and shot_request.is_valid():
		trigger = false
		reload_left = spec.reload
		shot_sequence += 1
		shot_request.call(self, shot_sequence)
	var moving := Vector2(velocity.x, velocity.z).length()
	running_gear.update(delta,tracks_broken)
	_update_dispersion(delta,moving)
	if engine_audio and engine_audio.playing:
		engine_audio.pitch_scale = .74 + moving * .045

func _update_dispersion(delta: float,moving: float) -> void:
	var traverse := absf(wrapf(turret.rotation.y-previous_aim_yaw,-PI,PI))/maxf(delta,.001)
	var hull_turn := absf(wrapf(rotation.y-previous_hull_yaw,-PI,PI))/maxf(delta,.001)
	previous_aim_yaw=turret.rotation.y
	previous_hull_yaw=rotation.y
	var target_spread: float=clampf(.19+moving/maxf(.1,spec.speed)*.65+traverse*.24+hull_turn*.3,.19,1.0)
	aim_spread=move_toward(aim_spread,target_spread,delta*(3.0 if target_spread>aim_spread else .81/maxf(.2,spec.aim)))

func _apply_drive(input: Vector2, delta: float) -> void:
	var steering_scale: float = clampf(1.0 - absf(move_speed) / maxf(.1, spec.speed) * .42, .3, 1.0)
	if not tracks_broken:
		hull_heading += input.x * spec.turn * steering_scale * delta
	rotation.y = hull_heading
	var throttle := input.y
	var target_speed: float = spec.speed if throttle > 0.0 else spec.reverse
	if tracks_broken:
		target_speed = 0.0
		move_speed = 0.0
	var forward := -global_transform.basis.z
	var desired := throttle * target_speed
	var response := 1.0 if not is_zero_approx(throttle) else 4.0
	move_speed = move_toward(move_speed, desired, response * delta)
	velocity.x = forward.x * move_speed
	velocity.z = forward.z * move_speed
	velocity.y = -1.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if absf(collision.get_normal().y) < .65:
			var impact := absf(forward.dot(collision.get_normal()))
			move_speed *= 0.0 if impact > .55 else .7
			velocity.x = forward.x * move_speed
			velocity.z = forward.z * move_speed

func set_controls(movement: Vector2, aim_point: Vector3, shoot: bool) -> void:
	drive_input = movement
	look_target = aim_point
	trigger = shoot

func _update_turret(point: Vector3, delta: float) -> void:
	if point.is_zero_approx():
		return
	var local_target: Vector3 = turret.get_parent().to_local(point) - turret.position
	var target_yaw := atan2(local_target.x, local_target.z)
	turret.rotation.y = rotate_toward(turret.rotation.y, target_yaw, spec.turret * delta)
	var gun_target := turret.to_local(point)-cannon.position
	var planar := Vector2(gun_target.x,gun_target.z).length()
	var target_pitch := atan2(gun_target.y,maxf(1.0,planar))
	cannon.rotation.x = move_toward(cannon.rotation.x, clampf(-target_pitch, -.34, .18), .55 * delta)

func muzzle_transform() -> Transform3D:
	return muzzle.global_transform

func dispersion_angle() -> float:
	return float(spec.spread)*maxf(.19,aim_spread)

func apply_shell_hit(power: float, direction: Vector3, point: Vector3, normal: Vector3, shell_owner: BattleTank) -> Dictionary:
	if destroyed or shell_owner == self or shell_owner.team == team:
		return {"hit": false, "chance": 0.0, "zone": ""}
	var local_point := global_transform.affine_inverse() * point
	var zone := "side" if absf(local_point.x) > 1.12 else "roof" if local_point.y > 2.1 else "turret" if local_point.y > 1.65 else "front" if -local_point.z > .65 else "rear"
	var chance := GameData.penetration(power, GameData.armor_mm(spec, zone), normal.dot(-direction))
	if zone == "front" and chance >= .28 and absf(normal.dot(-direction)) < .43:
		return {"hit": true, "ricochet": true, "chance": chance, "zone": zone}
	if chance >= .3:
		var damage: int = roundi(shell_owner.spec.damage * clampf(chance + .25, .45, 1.0) * randf_range(.88, 1.12))
		hp = maxf(0.0, hp - damage)
		shell_owner.damage_total += damage
		if zone == "side" and absf(local_point.x) > 1.2:
			track_hp -= power * .35
			if track_hp <= 0.0:
				tracks_broken = true
				repair_left = 10.0
		if hp <= 0.0:
			destroyed = true
			shell_owner.kills += 1
			var wreck_material := StandardMaterial3D.new()
			wreck_material.albedo_color = Color("292d2b")
			wreck_material.roughness = .96
			for mesh_node in find_children("*", "MeshInstance3D", true, false):
				mesh_node.material_override = wreck_material
	return {"hit": true, "ricochet": false, "chance": chance, "zone": zone}
