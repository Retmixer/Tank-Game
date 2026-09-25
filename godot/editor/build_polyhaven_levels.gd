extends SceneTree
## Offline authoring tool. Output is editable .tscn; legacy scenes are read only.
const OUT := "res://scenes/levels/polyhaven/"
const PREFABS := "res://assets/polyhaven/prepared/"
var library: Dictionary={}
var factory: Dictionary={}
var arena: Node3D
var rng := RandomNumberGenerator.new()
var routes: Array[PackedVector2Array]=[]
var occupied: Array[Vector3]=[]
var buildings: Array[Rect2]=[]
var terrain_body: StaticBody3D
var material_cache: Dictionary={}

func _initialize() -> void:
	if not "--rebuild" in OS.get_cmdline_user_args():
		push_error("Pass -- --rebuild to regenerate the Poly Haven scenes")
		quit(2)
		return
	call_deferred("run")

func own_tree(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner=scene_root
		# Instances already own their contents; saving those contents again
		# duplicates each mesh and collider in the generated level.
		if child.scene_file_path.is_empty(): own_tree(child,scene_root)

func save_scene(node: Node, path: String) -> void:
	own_tree(node,node)
	var packed := PackedScene.new()
	assert(packed.pack(node)==OK)
	assert(ResourceSaver.save(packed,path)==OK)

func corrected_material(source: Material, foliage: bool) -> Material:
	if not source is StandardMaterial3D: return source
	var key := str(source.get_instance_id())+str(foliage)
	if material_cache.has(key): return material_cache[key]
	var mat := source.duplicate() as StandardMaterial3D
	mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if foliage:
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		if mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
			mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mat.alpha_scissor_threshold=.10
			mat.albedo_color=Color(1.22,1.35,1.15)
	mat.normal_scale=.65
	material_cache[key]=mat
	return mat

func prepare_assets() -> void:
	DirAccess.make_dir_recursive_absolute(PREFABS)
	for file in DirAccess.get_files_at("res://assets/polyhaven"):
		if not file.ends_with(".glb"): continue
		var id := file.get_basename()
		var source: Node3D=load("res://assets/polyhaven/"+file).instantiate()
		var variants: Array[PackedScene]=[]
		var is_factory := id=="modular_factory_facade"
		var foliage := "sapling" in id or "fern" in id or "grass" in id or "bush" in id
		for src in source.find_children("*","MeshInstance3D",true,false):
			var part := MeshInstance3D.new()
			part.name=src.name
			part.mesh=src.mesh
			# External binary meshes are shared by every placed instance and remain editable.
			var mesh_path := PREFABS+id+"_"+str(src.name)+".res"
			assert(ResourceSaver.save(part.mesh,mesh_path)==OK)
			part.mesh=load(mesh_path)
			part.lod_bias=1.6 if "sapling" in id else 1.0
			part.visibility_range_end=310 if "sapling_medium" in id else (130 if foliage else 420)
			if foliage and "sapling_medium" not in id:
				part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for surface in part.mesh.get_surface_count():
				part.set_surface_override_material(surface,corrected_material(src.get_active_material(surface),foliage))
			if is_factory:
				factory[str(src.name)]=part
				continue
			var prefab := Node3D.new()
			prefab.name=id+"_"+str(variants.size())
			prefab.set_meta("source","https://polyhaven.com/a/"+id)
			prefab.set_meta("license","CC0")
			prefab.add_child(part)
			var box: AABB=part.get_aabb()
			part.position=Vector3(-box.get_center().x,-box.position.y,-box.get_center().z)
			prefab.set_meta("size",box.size)
			if "rock" in id or "boulder" in id or "cliff" in id or "stump" in id:
				var body := StaticBody3D.new()
				body.name="CoverCollision"
				part.add_child(body)
				var shape := CollisionShape3D.new()
				shape.shape=part.mesh.create_convex_shape(true,true)
				body.add_child(shape)
			elif "sapling" in id or "quiver_tree" in id:
				var body := StaticBody3D.new()
				body.name="TrunkCollision"
				prefab.add_child(body)
				var shape := CollisionShape3D.new()
				var cylinder := CylinderShape3D.new()
				cylinder.radius=maxf(.08,box.size.y*.022)
				cylinder.height=box.size.y*.65
				shape.shape=cylinder
				shape.position=Vector3(part.position.x,cylinder.height*.5,part.position.z)
				body.add_child(shape)
			var path := PREFABS+prefab.name+".tscn"
			save_scene(prefab,path)
			variants.append(load(path))
			prefab.free()
		library[id]=variants
		source.free()
	# Matching wall and window meshes share the original module coordinate system.
	for kind in ["solid","window","door"]:
		var module := Node3D.new()
		module.name="Factory_"+kind
		module.set_meta("source","https://polyhaven.com/a/modular_factory_facade")
		var names: Array[String]=["wall_standard_standard_01"]
		if kind=="window": names=["wall_window_centered_large_01","window_centered_large_01"]
		if kind=="door": names=["wall_door_centered_large_01","door_centered_large_01"]
		for mesh_name in names:
			if not factory.has(mesh_name):
				push_warning("Optional factory part missing: "+mesh_name)
				continue
			var part: MeshInstance3D=factory[mesh_name].duplicate()
			part.position=Vector3(1.5,0,0)
			module.add_child(part)
		save_scene(module,PREFABS+"factory_"+kind+".tscn")
		module.free()
	for part in factory.values(): part.free()
	factory.clear()

func group(label: String) -> Node3D:
	var node := Node3D.new()
	node.name=label
	arena.get_node("Geometry").add_child(node)
	return node

func ground(p: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(p.x,180,p.y),Vector3(p.x,-100,p.y),128)
	return arena.get_world_3d().direct_space_state.intersect_ray(query)

func height(p: Vector2) -> float:
	var hit := ground(p)
	return float(hit.position.y) if not hit.is_empty() else -100.0

func route_distance(p: Vector2) -> float:
	var best := INF
	for route in routes:
		for i in range(route.size()-1):
			best=minf(best,p.distance_to(Geometry2D.get_closest_point_to_segment(p,route[i],route[i+1])))
	return best

func can_place(p: Vector2, radius: float) -> bool:
	if absf(p.x)>arena.world_size*.475 or absf(p.y)>arena.world_size*.475: return false
	if p.length()<28.0+radius or route_distance(p)<12.0+radius: return false
	for team in ["TeamA","TeamB"]:
		for marker in arena.get_node("Spawns/"+team).get_children():
			if p.distance_to(Vector2(marker.position.x,marker.position.z))<32.0+radius: return false
	for rect in buildings:
		if rect.grow(radius+8).has_point(p): return false
	for other in occupied:
		if p.distance_to(Vector2(other.x,other.z))<radius+other.y+2.0: return false
	return not ground(p).is_empty()

func place_asset(parent: Node3D, id: String, p: Vector2, desired_height: float, solid := true) -> bool:
	var variants: Array=library[id]
	var model: Node3D=variants[rng.randi_range(0,variants.size()-1)].instantiate()
	var dimensions: Vector3=model.get_meta("size")
	var factor := desired_height/maxf(dimensions.y,.1)
	var radius := maxf(dimensions.x,dimensions.z)*factor*.5
	if not can_place(p,radius if solid else .2):
		model.free()
		return false
	parent.add_child(model)
	model.name=id+"_%04d"%parent.get_child_count()
	model.position=Vector3(p.x,height(p)-minf(.2,desired_height*.03),p.y)
	model.rotation.y=rng.randf_range(-PI,PI)
	model.scale=Vector3.ONE*factor
	if solid: occupied.append(Vector3(p.x,radius,p.y))
	return true

func box(parent: Node3D, label: String, size: Vector3, position: Vector3, material: Material, collision := true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name=label
	var shape := BoxMesh.new()
	shape.size=size
	mesh.mesh=shape
	mesh.material_override=material
	mesh.position=position
	parent.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		mesh.add_child(body)
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size=size
		collider.shape=bounds
		body.add_child(collider)
	return mesh

func plain(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=.86
	return mat

func workshop(parent: Node3D, p: Vector2, width: float, depth: float, snowy: bool) -> void:
	var base_y := -100.0
	var bottom_y := 100.0
	for x in [-width*.5,0.0,width*.5]:
		for z in [-depth*.5,0.0,depth*.5]:
			var y := height(p+Vector2(x,z))
			base_y=maxf(base_y,y)
			bottom_y=minf(bottom_y,y)
	base_y+=.15
	var building := Node3D.new()
	building.name="Workshop_%02d"%parent.get_child_count()
	parent.add_child(building)
	building.position=Vector3(p.x,base_y,p.y)
	building.set_meta("source","https://polyhaven.com/a/modular_factory_facade")
	buildings.append(Rect2(p-Vector2(width,depth)*.5,Vector2(width,depth)))
	# One solid body per building prevents entering a sealed workshop or driving through windows.
	var core_mat := plain(Color(.19,.20,.19))
	box(building,"FoundationAndInterior",Vector3(width-1.8,6+base_y-bottom_y,depth-1.8),Vector3(0,3-(base_y-bottom_y)*.5,0),core_mat)
	for side in 4:
		var length: float=width if side<2 else depth
		var count := roundi(length/6.0)
		for index in count:
			var along := -length*.5+3+index*6
			var kind := "door" if index==count/2 and side<2 else "window"
			var panel: Node3D=load(PREFABS+"factory_"+kind+".tscn").instantiate()
			building.add_child(panel)
			panel.name="Facade_%d_%02d"%[side,index]
			panel.scale=Vector3(2,2,2)
			if side<2:
				panel.position=Vector3(along,0,depth*.5*(1 if side==0 else -1))
				panel.rotation.y=0 if side==0 else PI
			else:
				panel.position=Vector3(width*.5*(1 if side==2 else -1),0,along)
				panel.rotation.y=PI*.5 if side==2 else -PI*.5
	var roof_mat := plain(Color(.68,.73,.76) if snowy else Color(.20,.23,.20))
	roof_mat.albedo_texture=load("res://assets/textures/winter-color.jpg" if snowy else "res://assets/textures/steel-color.jpg")
	roof_mat.uv1_scale=Vector3(width/6,depth/6,1)
	box(building,"Roof",Vector3(width+.5,.38,depth+.5),Vector3(0,6.1,0),roof_mat,false)
	# Raised roof monitors give the factory a recognizable industrial silhouette.
	box(building,"RoofMonitor",Vector3(width*.56,1.3,depth*.24),Vector3(0,6.8,0),core_mat,false)
	box(building,"MonitorRoof",Vector3(width*.58,.22,depth*.26),Vector3(0,7.5,0),roof_mat,false)

func chimney(parent: Node3D,p: Vector2) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name="BrickChimney_%d"%parent.get_child_count()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius=1.8
	cylinder.bottom_radius=2.6
	cylinder.height=30
	cylinder.radial_segments=24
	mesh.mesh=cylinder
	var mat := plain(Color(.48,.39,.33))
	mat.albedo_texture=load("res://assets/textures/brick-color.jpg")
	mat.normal_enabled=true
	mat.normal_texture=load("res://assets/textures/brick-normal.jpg")
	mat.uv1_scale=Vector3(4,10,1)
	mesh.material_override=mat
	mesh.position=Vector3(p.x,height(p)+15,p.y)
	parent.add_child(mesh)
	var body := StaticBody3D.new()
	mesh.add_child(body)
	var shape := CollisionShape3D.new()
	var bounds := CylinderShape3D.new()
	bounds.radius=2.6
	bounds.height=30
	shape.shape=bounds
	body.add_child(shape)
	occupied.append(Vector3(p.x,3,p.y))

func road(parent: Node3D, points: PackedVector2Array, id: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distance := 0.0
	for segment in range(points.size()-1):
		var start := points[segment]
		var end := points[segment+1]
		var length := start.distance_to(end)
		var steps := ceili(length/2.0)
		var side := (end-start).normalized().orthogonal()*9.0
		for i in steps:
			var a := start.lerp(end,float(i)/steps)
			var b := start.lerp(end,float(i+1)/steps)
			for lane in 6:
				var left := float(lane)/6.0
				var right := float(lane+1)/6.0
				var positions := [a+side*(left*2-1),a+side*(right*2-1),b+side*(left*2-1),b+side*(right*2-1)]
				var uvs := [Vector2(left,distance/5),Vector2(right,distance/5),Vector2(left,(distance+length/steps)/5),Vector2(right,(distance+length/steps)/5)]
				# World X/Z coordinates reverse the apparent 2D winding.
				for index in [0,1,2,1,3,2]:
					var point: Vector2=positions[index]
					st.set_uv(uvs[index])
					st.set_normal(Vector3.UP)
					st.add_vertex(Vector3(point.x,height(point)+.11,point.y))
			distance+=length/steps
	var mesh := MeshInstance3D.new()
	mesh.name="ServiceRoute_%d"%parent.get_child_count()
	mesh.mesh=st.commit()
	var mat := ShaderMaterial.new()
	mat.shader=load("res://materials/terrain_path.gdshader")
	var texture := "gravelly_sand" if id=="desert" else "rocky_trail"
	mat.set_shader_parameter("color_map",load("res://assets/polyhaven/ground/"+texture+"-color.jpg"))
	mat.set_shader_parameter("normal_map",load("res://assets/polyhaven/ground/"+texture+"-normal.jpg"))
	mat.set_shader_parameter("tint",Color(.60,.63,.66,.80) if id=="winter" else Color(1,1,1,.92))
	mesh.material_override=mat
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)

func build_level(id: String) -> void:
	rng.seed=20260925+id.hash()
	occupied.clear()
	buildings.clear()
	var legacy: Node3D=load("res://scenes/levels/"+id+".tscn").instantiate()
	arena=Node3D.new()
	arena.set_script(load("res://scripts/arena.gd"))
	arena.name=id.capitalize()+"PolyHaven"
	arena.map_id=id
	arena.world_size=legacy.world_size
	arena.set_meta("environment_revision","polyhaven-2026-09")
	root.add_child(arena)
	var geometry := Node3D.new()
	geometry.name="Geometry"
	arena.add_child(geometry)
	var terrain: Node3D=legacy.get_node("Geometry/Terrain_0000").duplicate()
	for child in terrain.get_children():
		if child.name!="Mesh": child.free()
	for child in terrain.get_node("Mesh").get_children():
		if child.name!="Collision": child.free()
	geometry.add_child(terrain)
	terrain_body=terrain.get_node("Mesh/Collision")
	terrain_body.collision_layer=129
	for node_name in ["Spawns","CapturePoint","Environment","Sun","EditorOverview"]:
		var copy: Node=legacy.get_node(node_name).duplicate()
		arena.add_child(copy)
	legacy.free()
	var terrain_mesh: MeshInstance3D=terrain.get_node("Mesh")
	if id!="winter":
		var mat: ShaderMaterial=terrain_mesh.material_override.duplicate()
		var texture := "forest_ground_04" if id=="training" else "gravelly_sand"
		for pair in [["ground_map","color"],["ground_normal","normal"],["ground_roughness","rough"]]:
			mat.set_shader_parameter(pair[0],load("res://assets/polyhaven/ground/"+texture+"-"+pair[1]+".jpg"))
		if id=="desert":
			mat.set_shader_parameter("rock_map",load("res://assets/polyhaven/ground/rock_face-color.jpg"))
			mat.set_shader_parameter("rock_normal",load("res://assets/polyhaven/ground/rock_face-normal.jpg"))
		mat.set_shader_parameter("tint",Color(1,1,1))
		mat.set_shader_parameter("texture_scale",.09)
		terrain_mesh.material_override=mat
	else:
		var winter_mat: ShaderMaterial=terrain_mesh.material_override.duplicate()
		winter_mat.set_shader_parameter("texture_scale",.025)
		terrain_mesh.material_override=winter_mat
	var env: WorldEnvironment=arena.get_node("Environment")
	env.environment=env.environment.duplicate(true)
	env.environment.ambient_light_energy=.38
	env.environment.fog_enabled=true
	env.environment.fog_density=.00035
	env.environment.fog_light_color=Color(.58,.66,.73) if id!="desert" else Color(.77,.64,.46)
	if env.environment.sky and env.environment.sky.sky_material is ProceduralSkyMaterial:
		var sky: ProceduralSkyMaterial=env.environment.sky.sky_material.duplicate()
		sky.sky_top_color=Color(.23,.34,.42) if id!="desert" else Color(.40,.49,.56)
		sky.sky_horizon_color=Color(.66,.73,.77) if id!="desert" else Color(.83,.72,.57)
		env.environment.sky.sky_material=sky
	arena.get_node("Sun").directional_shadow_max_distance=130.0
	await physics_frame
	await physics_frame
	for team in arena.get_node("Spawns").get_children():
		for marker in team.get_children(): marker.position.y=height(Vector2(marker.position.x,marker.position.z))+1.0
	var span: float=arena.world_size*.4
	var home := Vector2(-span,-span)
	var away := -home
	routes=[PackedVector2Array([home,Vector2(-span*.6,-span*.65),Vector2.ZERO,Vector2(span*.6,span*.65),away]),PackedVector2Array([home,Vector2(-span*.88,0),Vector2(-span*.6,span*.65),Vector2(0,span*.86),away]),PackedVector2Array([home,Vector2(0,-span*.86),Vector2(span*.6,-span*.65),Vector2(span*.88,0),away])]
	if id=="winter":
		routes[0]=PackedVector2Array([home,Vector2(-125,-125),Vector2(-125,-25),Vector2(0,-25),Vector2.ZERO,Vector2(0,25),Vector2(125,25),Vector2(125,125),away])
	var paths := group("ServiceRoads")
	for route in routes: road(paths,route,id)
	var covers := group("RockCover")
	var vegetation := group("Trees")
	var details := group("GroundVegetation")
	if id=="winter":
		var industry := group("FactoryBlocks")
		for p in [Vector2(-78,-80),Vector2(78,80),Vector2(-78,80),Vector2(78,-80),Vector2(-160,0),Vector2(160,0)]:
			workshop(industry,p,48,30,true)
		for p in [Vector2(-88,-76),Vector2(-70,-76),Vector2(70,76),Vector2(88,76)]: chimney(industry,p)
		for p in [Vector2(-42,30),Vector2(42,-30),Vector2(-20,-53),Vector2(20,53)]:
			place_asset(covers,"rock_moss_set_02",p,2.5)
	for attempt in (11000 if id=="training" else 5000):
		var p := Vector2(rng.randf_range(-span*1.16,span*1.16),rng.randf_range(-span*1.16,span*1.16))
		if id=="training":
			# Forest groves alternate with open fire lanes and the central clearing.
			if sin(p.x*.025)*cos(p.y*.03)<-.2: continue
			if vegetation.get_child_count()<1100:
				place_asset(vegetation,"fir_sapling_medium",p,rng.randf_range(6.5,12.5))
			elif covers.get_child_count()<150:
				place_asset(covers,"rock_moss_set_02",p,rng.randf_range(1.2,3.4))
		elif id=="desert":
			if covers.get_child_count()<320:
				var asset := "namaqualand_cliff_02" if attempt%7==0 else ("namaqualand_boulder_02" if attempt%2==0 else "namaqualand_boulder_04")
				place_asset(covers,asset,p,rng.randf_range(3.5,6.5) if "cliff" in asset else rng.randf_range(1.5,4.0))
			elif vegetation.get_child_count()<150: place_asset(vegetation,"quiver_tree_01",p,rng.randf_range(2.8,5.0))
		else:
			if p.length()>125 and vegetation.get_child_count()<350: place_asset(vegetation,"fir_sapling_medium",p,rng.randf_range(7,11))
	for attempt in 2500:
		var p := Vector2(rng.randf_range(-span*1.15,span*1.15),rng.randf_range(-span*1.15,span*1.15))
		if details.get_child_count()>=(700 if id=="training" else 600): break
		if id=="training":
			place_asset(details,["fern_02","grass_medium_01","pine_sapling_small","fir_sapling","tree_stump_01"][attempt%5],p,rng.randf_range(.35,1.3),false)
		elif id=="desert": place_asset(details,"wild_rooibos_bush",p,rng.randf_range(.4,1.0),false)
		elif p.length()>120: place_asset(details,"pine_sapling_small",p,rng.randf_range(.5,1.5),false)
	# Last-resort limits lie at the terrain edge; no perimeter fence or giant rock ring.
	var limits := group("PlayableLimits")
	var half: float=arena.world_size*.5
	for axis in 2:
		for direction in [-1,1]:
			var body := StaticBody3D.new()
			limits.add_child(body)
			body.name="Boundary_%d_%d"%[axis,direction]
			var shape := CollisionShape3D.new()
			var bounds := BoxShape3D.new()
			bounds.size=Vector3(3,160,arena.world_size+6) if axis==0 else Vector3(arena.world_size+6,160,3)
			shape.shape=bounds
			body.add_child(shape)
			body.position=Vector3(direction*half,30,0) if axis==0 else Vector3(0,30,direction*half)
	arena.get_node("CapturePoint").position.y=height(Vector2.ZERO)
	arena.get_node("EditorOverview").current=false
	save_scene(arena,OUT+id+".tscn")
	print("BUILT ",id,": trees=",vegetation.get_child_count()," cover=",covers.get_child_count()," details=",details.get_child_count())
	arena.free()
	await physics_frame

func run() -> void:
	root.get_node("GameData").persistence_enabled=false
	DirAccess.make_dir_recursive_absolute(OUT)
	prepare_assets()
	for id in ["training","desert","winter"]: await build_level(id)
	print("Poly Haven level authoring complete; legacy scenes retained")
	quit()
