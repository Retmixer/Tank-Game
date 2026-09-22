extends Node3D
class_name BattleShell

var velocity := Vector3.ZERO
var power := 100.0
var owner_tank: BattleTank
var traveled := 0.0
var lifetime := 8.0
var ricochets := 0
var impact_event: Callable

func launch(source: BattleTank, shot_power: float, direction: Vector3) -> void:
	owner_tank = source
	power = shot_power
	global_transform = source.muzzle_transform()
	velocity = direction.normalized() * 285.0
	var mesh_instance := MeshInstance3D.new()
	var shell_mesh := CylinderMesh.new()
	shell_mesh.top_radius = .075
	shell_mesh.bottom_radius = .12
	shell_mesh.height = .62
	shell_mesh.radial_segments = 12
	mesh_instance.mesh = shell_mesh
	mesh_instance.rotation_degrees.x = 90
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("e8b868")
	material.metallic = .72
	material.roughness = .33
	material.emission_enabled = true
	material.emission = Color("c47d34")
	mesh_instance.material_override = material
	add_child(mesh_instance)
	look_at(global_position + velocity.normalized(), Vector3.UP)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or traveled > 1100.0:
		queue_free()
		return
	velocity.y -= 9.81 * .1 * delta
	var destination := global_position + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, destination)
	query.exclude = [owner_tank.get_rid()] if is_instance_valid(owner_tank) else []
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		var collider: Object = hit.collider
		var outcome := {}
		if collider is BattleTank and is_instance_valid(owner_tank):
			outcome = collider.apply_shell_hit(power, velocity.normalized(), hit.position, hit.normal, owner_tank)
			if outcome.get("ricochet", false) and ricochets < 2:
				velocity = velocity.bounce(hit.normal) * .58
				power *= .58
				global_position = hit.position + hit.normal * .16
				ricochets += 1
				return
		if impact_event.is_valid():
			impact_event.call(hit.position, collider is BattleTank, outcome)
		queue_free()
		return
	traveled += global_position.distance_to(destination)
	global_position = destination
	look_at(global_position + velocity.normalized(), Vector3.UP)
