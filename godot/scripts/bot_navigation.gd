extends RefCounted
## Shared per-match A* grid built from actual authored collision geometry.
const STEP := 10.0
var graph := AStar3D.new()
var game: Node
var cells: Array[Vector2i]=[]
var ids: Dictionary={}
var cursor := 0
var connecting := false
var ready := false
var excluded: Array[RID]=[]
var shape := SphereShape3D.new()

func setup(owner_game: Node) -> void:
	game=owner_game
	shape.radius=1.6
	for tank in game.tanks:
		excluded.append(tank.get_rid())
	var half := floori(float(game.arena.world_size)*.46/STEP)
	for x in range(-half,half+1):
		for z in range(-half,half+1):
			cells.append(Vector2i(x,z))

func ray(from: Vector3,to: Vector3) -> Dictionary:
	return game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1,excluded))

func update() -> void:
	if ready:
		return
	for work in 90:
		if cursor>=cells.size():
			if connecting:
				ready=true
				return
			connecting=true
			cursor=0
		var cell := cells[cursor]
		cursor+=1
		if connecting:
			connect_cell(cell)
		else:
			var point := Vector3(cell.x*STEP,0,cell.y*STEP)
			var ground := ray(point+Vector3.UP*200,point-Vector3.UP*100)
			if ground.is_empty() or ground.normal.y<.78:
				continue
			# Rooftops are not navigable tank surfaces.
			if not "Terrain" in str(ground.collider.get_path()):
				continue
			point=ground.position
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape=shape
			query.transform=Transform3D(Basis.IDENTITY,point+Vector3.UP*1.85)
			query.exclude=excluded
			query.collision_mask=1
			if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
				continue
			var id := graph.get_available_point_id()
			graph.add_point(id,point)
			ids[cell]=id

func connect_cell(cell: Vector2i) -> void:
	if not ids.has(cell):
		return
	var from := graph.get_point_position(ids[cell])
	for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,-1)]:
		var other: Vector2i=cell+offset
		if not ids.has(other):
			continue
		var to := graph.get_point_position(ids[other])
		if absf(to.y-from.y)>STEP*.4:
			continue
		var side := (to-from).normalized().cross(Vector3.UP)*1.65
		var clear := true
		for shift in [Vector3.ZERO,side,-side]:
			if not ray(from+Vector3.UP*1.1+shift,to+Vector3.UP*1.1+shift).is_empty():
				clear=false
				break
		if clear:
			graph.connect_points(ids[cell],ids[other])

func route(from: Vector3,to: Vector3) -> PackedVector3Array:
	if not ready or graph.get_point_count()==0:
		return PackedVector3Array()
	to.y=game.arena.height_at(to.x,to.z)
	var a := graph.get_closest_point(from)
	var b := graph.get_closest_point(to)
	return graph.get_point_path(a,b)
