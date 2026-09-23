extends Control
@export var minimum_radius := 21.0
@export var spread_radius := 31.0
@export var line_width := 1.5
@export var dot_radius := 2.6
var game: Node

func _draw() -> void:
	if not is_instance_valid(game) or game.screen != game.Screen.BATTLE:
		return
	var center := size*.5
	var radius: float = minimum_radius + (game.player.aim_spread*spread_radius if is_instance_valid(game.player) else spread_radius)
	var color: Color = game.aim_color
	draw_arc(center,radius,0,TAU,60,color,line_width,true)
	draw_circle(center,dot_radius,color)
