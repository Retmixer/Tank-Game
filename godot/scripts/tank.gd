extends CharacterBody3D
class_name BattleTank

var spec: Dictionary = {}
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

func configure(vehicle: Dictionary, side: int, player_controlled: bool) -> void:
	spec = vehicle
	team = side
	is_player = player_controlled
	hp = vehicle.hp
	max_hp = vehicle.hp
	track_hp = vehicle.tracks
	_setup_body()
	_build_model()
	_setup_audio()

func _setup_body() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.8, 1.8, 7.6) if spec.c >= 2 else Vector3(3.3, 1.8, 6.5)
	collision.shape = shape
	collision.position.y = .95
	add_child(collision)
	floor_snap_length = .5
	floor_max_angle = deg_to_rad(40)
	floor_stop_on_slope = true
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

func _paint(color: Color, texture_name := "paint") -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .78
	material.metallic = .12
	var path := "res://assets/textures/%s-color.jpg" % texture_name
	if ResourceLoader.exists(path):
		material.albedo_texture = load(path)
		material.uv1_scale = Vector3(2.5, 2.5, 2.5)
	var normal_path := "res://assets/textures/%s-normal.jpg" % texture_name
	if ResourceLoader.exists(normal_path):
		material.normal_enabled = true
		material.normal_texture = load(normal_path)
		material.normal_scale = .3
	return material

func _add_box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance

func _add_cylinder(parent: Node3D, radius: float, height: float, at: Vector3, material: Material, sides := 20) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	instance.mesh = mesh
	instance.position = at
	instance.rotation_degrees.z = 90.0
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance

func _build_model() -> void:
	var hull_color := Color("67785d") if spec.n == 0 else Color("697377") if spec.n == 1 else Color("76745e")
	var paint := _paint(hull_color)
	var steel := _paint(Color("404745"), "steel")
	var rubber := _paint(Color("222522"), "rubber")
	var bright := _paint(Color("828779"), "steel")
	var width := 3.5 if spec.c == 2 else 3.0 if spec.c == 1 or spec.c == 3 else 2.55
	var length := 7.2 if spec.c == 2 else 6.2 if spec.c == 1 or spec.c == 3 else 4.8
	var wheels := 8 if spec.c == 2 else 6 if spec.c == 1 or spec.c == 3 else 5
	_add_box(self, Vector3(width, .72, length), Vector3(0, .93, 0), paint)
	_add_box(self, Vector3(width * .92, .55, length * .68), Vector3(0, 1.5, -.35), paint)
	_add_box(self, Vector3(width * .9, .16, 1.35), Vector3(0, 1.45, length * .36), paint).rotation.x = -.25
	if spec.id == "0-2":
		_add_box(self, Vector3(width, .52, 1.4), Vector3(0, 1.12, length * .36), paint).rotation.x = -.5
	if spec.id == "1-1":
		_add_box(self, Vector3(width * .92, .48, 1.1), Vector3(0, 1.23, length * .34), paint).rotation.x = -.37
	if spec.id == "1-2":
		_add_box(self, Vector3(width * 1.03, .48, length * .3), Vector3(0, 1.42, .15), paint)
	if spec.id == "2-2":
		_add_box(self, Vector3(width, .7, 1.25), Vector3(0, 1.02, length * .35), paint)
	var wheel_radius := .49 if wheels <= 5 else .43 if wheels <= 6 else .38
	for side in [-1.0, 1.0]:
		for i in wheels:
			var z := -length * .39 + float(i) * length * .78 / float(wheels - 1)
			_add_cylinder(self, wheel_radius, .42, Vector3(side * (width * .5 + .05), .63, z), rubber, 24)
			_add_cylinder(self, wheel_radius * .71, .46, Vector3(side * (width * .5 + .065), .63, z), paint, 24)
			_add_cylinder(self, .105, .5, Vector3(side * (width * .5 + .08), .63, z), bright, 12)
		_add_box(self, Vector3(.34, .21, length + .28), Vector3(side * (width * .5 + .12), .63, 0), steel)
		if spec.c >= 1:
			var skirt := _add_box(self, Vector3(.12, .58, length * .72), Vector3(side * (width * .5 + .23), 1.05, -.05), paint)
			skirt.visible = spec.c != 3
	turret = Node3D.new()
	turret.position = Vector3(0, 1.78, .18 if spec.c == 2 else 0.0)
	add_child(turret)
	_add_cylinder(turret, width * .34, .17, Vector3.ZERO, steel, 32).rotation_degrees.z = 0
	if spec.c == 0:
		_add_cylinder(turret, 1.0, .72, Vector3(0, .4, 0), paint, 12)
	elif spec.id == "0-1" or spec.id == "0-2":
		var cast := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = .92 if spec.c == 1 else 1.12
		sphere.height = 1.08 if spec.c == 1 else 1.34
		cast.mesh = sphere
		cast.position = Vector3(0, .39, -.16)
		cast.scale = Vector3(1.32, 1.0, 1.47)
		cast.material_override = paint
		turret.add_child(cast)
	elif spec.id == "1-1" or spec.id == "1-2":
		_add_box(turret, Vector3(2.35, .94, 2.6), Vector3(0, .43, -.12), paint)
		_add_box(turret, Vector3(2.25, .56, 1.45), Vector3(0, .63, -1.35), paint)
	elif spec.id == "2-1":
		_add_box(turret, Vector3(2.0, .85, 2.05), Vector3(0, .42, -.3), paint)
		_add_box(turret, Vector3(1.9, .63, 1.45), Vector3(0, .53, -1.35), paint)
	else:
		_add_cylinder(turret, 1.15, .92, Vector3(0, .48, 0), paint, 8 if spec.c >= 2 else 6)
	if spec.c == 3:
		_add_box(turret, Vector3(2.2, 1.1, 2.5), Vector3(0, .5, -.3), paint)
		_add_box(turret, Vector3(2.3, .14, 1.1), Vector3(0, .72, -1.7), steel)
	cannon = Node3D.new()
	cannon.position = Vector3(0, .45, .55)
	turret.add_child(cannon)
	_add_box(cannon, Vector3(.86 if spec.c > 1 else .64, .48, .48), Vector3(0, 0, -.1), paint)
	var barrel_length := 5.2 if spec.c == 3 else 4.65 if spec.c == 2 else 3.75 if spec.c == 1 else 2.7
	_add_cylinder(cannon, .13 if spec.c < 2 else .17, barrel_length, Vector3(0, 0, -barrel_length * .56), bright, 28).rotation_degrees.x = 90
	_add_cylinder(cannon, .21, .28, Vector3(0, 0, -barrel_length * .83), steel, 24).rotation_degrees.x = 90
	_add_cylinder(cannon, .18, .18, Vector3(0, 0, -barrel_length - .28), rubber, 20).rotation_degrees.x = 90
	for side in [-1.0, 1.0]:
		_add_box(self, Vector3(.28, .28, .75), Vector3(side * width * .36, 1.5, -length * .28), paint)
		_add_cylinder(self, .12, .8, Vector3(side * width * .32, 1.31, -length * .49), steel, 12)
	_add_box(self, Vector3(.52, .19, .85), Vector3(0, 1.89, -.42), paint)
	var antenna := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = .012
	rod.bottom_radius = .026
	rod.height = 1.6
	antenna.mesh = rod
	antenna.position = Vector3(-width * .28, 2.5, -.9)
	antenna.material_override = steel
	turret.add_child(antenna)

func _setup_audio() -> void:
	engine_audio = AudioStreamPlayer3D.new()
	engine_audio.unit_size = 16.0
	engine_audio.max_distance = 90.0
	var stream_path := "res://assets/audio/engine.ogg"
	if ResourceLoader.exists(stream_path):
		engine_audio.stream = load(stream_path)
		add_child(engine_audio)
		engine_audio.call_deferred("play")

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
	var target_spread: float = .19 + minf(1.0, moving / maxf(.1, spec.speed)) * .72
	aim_spread = move_toward(aim_spread, target_spread, delta * (1.45 / maxf(.2, spec.aim)))
	if engine_audio and engine_audio.playing:
		engine_audio.pitch_scale = .74 + moving * .045

func _apply_drive(input: Vector2, delta: float) -> void:
	var steering_scale: float = clampf(1.0 - absf(move_speed) / maxf(.1, spec.speed) * .42, .3, 1.0)
	hull_heading += input.x * spec.turn * steering_scale * delta
	rotation.y = hull_heading
	var throttle := input.y
	var target_speed: float = spec.speed if throttle > 0.0 else spec.reverse
	if tracks_broken:
		target_speed = 0.0
	var forward := -global_transform.basis.z
	var desired := throttle * target_speed
	var response := 1.0 if not is_zero_approx(throttle) else 4.0
	move_speed = move_toward(move_speed, desired, response * delta)
	velocity.x = forward.x * move_speed
	velocity.z = forward.z * move_speed
	velocity.y = -1.0
	move_and_slide()
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is BattleTank:
			move_speed *= .62
			velocity.x *= .55
			velocity.z *= .55

func set_controls(movement: Vector2, aim_point: Vector3, shoot: bool) -> void:
	drive_input = movement
	look_target = aim_point
	trigger = shoot

func _update_turret(point: Vector3, delta: float) -> void:
	if point.is_zero_approx():
		return
	var local_target := turret.to_local(point)
	var target_yaw := atan2(local_target.x, local_target.z) + PI
	turret.rotation.y = rotate_toward(turret.rotation.y, target_yaw, spec.turret * delta)
	var planar := Vector2(local_target.x, local_target.z).length()
	var target_pitch := atan2(local_target.y - 1.0, maxf(1.0, planar))
	cannon.rotation.x = move_toward(cannon.rotation.x, clampf(target_pitch, -.18, .34), .55 * delta)

func muzzle_transform() -> Transform3D:
	return cannon.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, -5.4 if spec.c == 3 else -4.7 if spec.c >= 2 else -3.8 if spec.c == 1 else -2.9))

func apply_shell_hit(power: float, direction: Vector3, point: Vector3, normal: Vector3, shell_owner: BattleTank) -> Dictionary:
	if destroyed or shell_owner == self or shell_owner.team == team:
		return {"hit": false, "chance": 0.0, "zone": ""}
	var local_point := global_transform.affine_inverse() * point
	var zone := "side" if absf(local_point.x) > 1.12 else "roof" if local_point.y > 2.1 else "turret" if local_point.y > 1.65 else "front" if -local_point.z > .65 else "rear"
	var chance := GameData.penetration(power, GameData.armor_mm(spec, zone), normal.dot(-direction))
	if zone == "front" and chance >= .28 and absf(normal.dot(-direction)) < .43:
		return {"hit": true, "ricochet": true, "chance": chance, "zone": zone}
	if chance >= .3:
		var damage: int = roundi(spec.damage * clampf(chance + .25, .45, 1.0) * randf_range(.88, 1.12))
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
