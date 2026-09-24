extends Control
@export var minimum_radius := 3.0
@export var line_width := 1.5
@export var dot_radius := 2.6
var game: Node

func _draw() -> void:
	if not is_instance_valid(game) or game.screen != game.Screen.BATTLE:
		return
	var center := size*.5
	if not is_instance_valid(game.player):
		return
	var camera: Camera3D=game.view_camera
	var gun_center := center
	if not camera.is_position_behind(game.gun_aim_point):
		gun_center=camera.unproject_position(game.gun_aim_point)
	var focal: float=size.y/(2*tan(deg_to_rad(camera.fov)*.5))
	var radius := maxf(minimum_radius,tan(game.player.dispersion_angle())*focal)
	gun_center=gun_center.clamp(Vector2.ONE*(radius+8),size-Vector2.ONE*(radius+8))
	var color: Color = game.aim_color
	# Mouse/camera target is separate from the slower physical gun marker.
	var neutral := Color(1,1,1,.75)
	draw_line(center-Vector2(8,0),center-Vector2(3,0),neutral,1,true)
	draw_line(center+Vector2(3,0),center+Vector2(8,0),neutral,1,true)
	draw_line(center-Vector2(0,8),center-Vector2(0,3),neutral,1,true)
	draw_line(center+Vector2(0,3),center+Vector2(0,8),neutral,1,true)
	for i in 48:
		var start := TAU*i/48
		draw_arc(gun_center,radius,start,start+TAU/72,3,color,line_width,true)
	draw_circle(gun_center,dot_radius,color)
	if game.player.reload_left>0:
		var progress: float=1-game.player.reload_left/game.player.spec.reload
		draw_arc(gun_center,radius+5,-PI/2,-PI/2+TAU*progress,48,Color("dfc181"),2,true)
