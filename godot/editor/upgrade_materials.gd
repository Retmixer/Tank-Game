extends SceneTree
## Material-only migration. Never serializes or rebuilds user-authored geometry.
func _initialize() -> void:
	var updated := 0
	for file in DirAccess.get_files_at("res://materials"):
		if not file.ends_with(".tres"): continue
		var path := "res://materials/"+file
		var mat := load(path) as Material
		var changed := false
		if mat is ShaderMaterial and mat.shader.resource_path.ends_with("vehicle_paint.gdshader"):
			# Preserve national texture assignments when rerunning the migration.
			var stem := "res://assets/textures/armor-worn"
			if file=="surface_7ed8764aa1c3.tres": stem="res://assets/textures/armor-german"
			if file=="surface_d7adcffc9575.tres": stem="res://assets/textures/armor-french"
			mat.set_shader_parameter("wear_map",load(stem+"-color.jpg"))
			mat.set_shader_parameter("normal_map",load(stem+"-normal.jpg"))
			mat.set_shader_parameter("roughness_map",load(stem+"-rough.jpg"))
			mat.set_shader_parameter("texture_scale",.75)
			changed=true
		elif mat is ShaderMaterial and mat.shader.resource_path.ends_with("terrain.gdshader"):
			var ground: Texture2D=mat.get_shader_parameter("ground_map")
			var stem := ground.resource_path.replace("-color.jpg","")
			mat.set_shader_parameter("ground_normal",load(stem+"-normal.jpg"))
			mat.set_shader_parameter("ground_roughness",load(stem+"-rough.jpg"))
			mat.set_shader_parameter("rock_normal",load("res://assets/textures/rock-normal.jpg"))
			changed=true
		elif mat is StandardMaterial3D and mat.albedo_texture:
			var source: String = mat.albedo_texture.resource_path
			if source.ends_with("-color.jpg"):
				var stem: String = source.replace("-color.jpg","")
				if ResourceLoader.exists(stem+"-normal.jpg"):
					mat.normal_enabled=true
					mat.normal_texture=load(stem+"-normal.jpg")
					mat.normal_scale=.65 if "rock" in stem or "brick" in stem else .35
				if ResourceLoader.exists(stem+"-rough.jpg"):
					mat.roughness_texture=load(stem+"-rough.jpg")
					mat.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
				mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				changed=true
		if changed:
			assert(ResourceSaver.save(mat,path)==OK)
			updated+=1
	print("PBR material resources upgraded: ",updated)
	quit()
