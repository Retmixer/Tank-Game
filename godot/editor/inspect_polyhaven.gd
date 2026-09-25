extends SceneTree
func _initialize() -> void:
	for file in DirAccess.get_files_at("res://assets/polyhaven"):
		if not file.ends_with(".glb"): continue
		var node: Node3D=load("res://assets/polyhaven/"+file).instantiate()
		print("ASSET ",file)
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			print("  ",mesh.name," ",mesh.transform," bounds=",mesh.get_aabb())
		node.free()
	for id in ["training","desert","winter"]:
		var arena: Node3D=load("res://scenes/levels/"+id+".tscn").instantiate()
		print("TERRAIN ",id," ",arena.get_node("Geometry/Terrain_0000/Mesh").get_aabb())
		arena.free()
	quit()
