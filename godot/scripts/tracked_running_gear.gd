extends Node
## Kinematic suspension: contact probes, independent belt travel and wheel rotation.
## No mesh regeneration and no changes to shared MultiMesh resources.
@export var suspension_travel := .28
@export var response := 12.0
var tank: CharacterBody3D
var wheels: Array[Dictionary]=[]
var belts: Array[Dictionary]=[]
var last_position := Vector3.ZERO
var last_heading := 0.0

func setup(vehicle: CharacterBody3D) -> void:
	tank=vehicle
	last_position=tank.global_position
	last_heading=tank.rotation.y
	for wheel in tank.find_children("Wheel_*","Node3D",true,false):
		wheels.append({"node":wheel,"rest":wheel.position,"offset":0.0,"spin":0.0,"basis":wheel.basis})
	# Dummy headless RenderingServer does not retain instance transforms.
	if DisplayServer.get_name()=="headless":
		return
	for belt in tank.find_children("Instances_*","MultiMeshInstance3D",true,false):
		belt.multimesh=belt.multimesh.duplicate()
		var rest: Array[Transform3D]=[]
		var length := 0.0
		var lowest := 0
		for i in belt.multimesh.instance_count:
			rest.append(belt.multimesh.get_instance_transform(i))
			if rest[i].origin.y<rest[lowest].origin.y:
				lowest=i
		for i in rest.size():
			length+=rest[i].origin.distance_to(rest[(i+1)%rest.size()].origin)
		if length<.1:
			continue
		var direction := -signf((rest[(lowest+1)%rest.size()].origin-rest[lowest].origin).z)
		belts.append({"node":belt,"rest":rest,"phase":0.0,"length":length,"direction":direction,"side":signf(rest[0].origin.x),"width":absf(rest[0].origin.x)})

func update(delta: float, broken: bool) -> void:
	var forward := -tank.global_basis.z
	var travel := (tank.global_position-last_position).dot(forward)
	var yaw := wrapf(tank.rotation.y-last_heading,-PI,PI)
	last_position=tank.global_position
	last_heading=tank.rotation.y
	if absf(travel)>3.0:
		travel=0.0 # Teleports must not explode belt phase.
	var visual := tank.get_node("Visual") as Node3D
	if tank.is_on_floor():
		var normal := tank.global_basis.inverse()*tank.get_floor_normal()
		normal=Vector3(clampf(normal.x,-.35,.35),maxf(.7,normal.y),clampf(normal.z,-.45,.45)).normalized()
		# Preserve the authored 180-degree visual orientation while aligning its up axis.
		var target := (Basis(Quaternion(Vector3.UP,normal))*Basis(Vector3.UP,PI)).get_rotation_quaternion()
		visual.quaternion=visual.quaternion.slerp(target,1-exp(-delta*response))
	for wheel in wheels:
		var node: Node3D=wheel.node
		var rest: Vector3=wheel.rest
		var center: Vector3=node.get_parent().to_global(rest)
		var query := PhysicsRayQueryParameters3D.create(center+Vector3.UP*.7,center-Vector3.UP*1.4,1,[tank.get_rid()])
		var hit := tank.get_world_3d().direct_space_state.intersect_ray(query)
		var desired := -suspension_travel
		if not hit.is_empty() and hit.normal.y>.55:
			var local_hit: Vector3=node.get_parent().to_local(hit.position)
			desired=clampf(local_hit.y+.60-rest.y,-suspension_travel,suspension_travel)
		wheel.offset=lerpf(wheel.offset,desired,1-exp(-delta*response))
		node.position=rest+Vector3.UP*wheel.offset
		var side_travel: float=0.0 if broken else travel+yaw*rest.x
		wheel.spin=wrapf(wheel.spin+side_travel/.6,-PI,PI)
		node.basis=Basis(Vector3.RIGHT,wheel.spin)*wheel.basis
	for belt in belts:
		var rest: Array[Transform3D]=belt.rest
		var side_travel: float=0.0 if broken else travel+yaw*belt.side*belt.width
		belt.phase=fposmod(belt.phase+side_travel/belt.length*rest.size()*belt.direction,rest.size())
		for i in rest.size():
			var at: float=fposmod(i+belt.phase,rest.size())
			var index := int(at)
			var transform := rest[index].interpolate_with(rest[(index+1)%rest.size()],at-index)
			var offset := 0.0
			var weight := 0.0
			for wheel in wheels:
				if signf(wheel.rest.x)!=belt.side:
					continue
				var influence: float=1.0/maxf(.1,absf(wheel.rest.z-transform.origin.z))
				offset+=wheel.offset*influence
				weight+=influence
			if weight>0:
				transform.origin.y+=offset/weight*clampf(1.3-transform.origin.y,.15,1.0)
			belt.node.multimesh.set_instance_transform(i,transform)
