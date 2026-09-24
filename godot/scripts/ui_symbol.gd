@tool
extends Control
## Resolution-independent native icon set, editable through the Inspector.
@export_enum("tank","research","tasks","gear","profile","fire","shield","speed","weight","engine","tracks","gun","star","cross","lily","logo","passport","wrench") var symbol := "tank"
@export var tint := Color("d2d0bf")

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func line(points: Array, width := 2.0) -> void:
	var p := PackedVector2Array()
	for v in points: p.append(Vector2(v[0],v[1]))
	draw_polyline(p,tint,width,true)

func solid(points: Array) -> void:
	var p := PackedVector2Array()
	for v in points: p.append(Vector2(v[0],v[1]))
	draw_colored_polygon(p,tint)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/32.0)
	match symbol:
		"logo":
			line([[16,1],[31,16],[16,31],[1,16],[16,1]],2.4)
			solid([[16,10],[22,16],[16,22],[10,16]])
		"tank":
			solid([[2,18],[28,18],[30,22],[25,26],[6,26],[2,23]])
			solid([[10,12],[20,12],[23,18],[7,18]])
			line([[18,14],[31,14]],3)
			line([[12,10],[19,10]],2)
		"research":
			line([[12,3],[20,3],[18,5],[18,13],[26,27],[24,29],[8,29],[6,27],[14,13],[14,5],[12,3]])
			solid([[11,22],[21,22],[24,27],[8,27]])
		"tasks","passport":
			line([[24,6],[27,6],[27,29],[5,29],[5,5],[10,5]])
			line([[11,3],[21,3],[21,8],[11,8],[11,3]])
			if symbol=="tasks": line([[9,16],[14,21],[28,9]],3)
			else:
				for y in [13,18,23]: line([[10,y],[22,y]])
		"profile":
			draw_circle(Vector2(16,10),5,tint,false,2,true)
			line([[6,28],[7,22],[12,18],[20,18],[25,22],[26,28],[6,28]])
		"gear","engine","wrench":
			if symbol=="wrench":
				line([[5,28],[23,10]],6)
				line([[23,3],[18,7],[19,13],[25,15],[30,10]],4)
			elif symbol=="engine":
				line([[7,11],[25,11],[25,26],[7,26],[7,11]],3)
				line([[12,4],[21,4],[21,8],[12,8]])
				for x in [11,16,21]: line([[x,15],[x,23]])
				line([[3,15],[3,23]],3)
				line([[29,15],[29,23]],3)
			else:
				draw_circle(Vector2(16,16),9,tint,false,5,true)
				for i in 8:
					var v := Vector2.from_angle(i*PI/4)
					draw_line(Vector2(16,16)+v*9,Vector2(16,16)+v*14,tint,5,true)
		"shield":
			line([[16,3],[27,7],[26,19],[22,25],[16,30],[10,25],[6,19],[5,7],[16,3]],2.5)
			solid([[16,8],[22,10],[22,18],[19,23],[16,25]])
		"fire":
			line([[17,2],[11,12],[12,18],[8,14],[5,22],[9,28],[16,30],[24,27],[27,20],[21,9],[21,19],[17,22],[15,17],[17,2]],2.5)
		"speed":
			draw_arc(Vector2(16,16),12,0,TAU,40,tint,2,true)
			line([[16,16],[24,7]],2.5)
			for i in 5:
				var v := Vector2.from_angle(PI+i*PI/4)
				draw_line(Vector2(16,16)+v*8,Vector2(16,16)+v*11,tint,2,true)
		"weight":
			line([[12,10],[12,4],[20,4],[20,10]])
			solid([[7,11],[25,11],[28,29],[4,29]])
		"tracks":
			line([[5,14],[21,4],[28,7],[30,13],[26,19],[11,28],[5,27],[2,22],[5,14]],2.5)
			for p in [Vector2(9,21),Vector2(17,16),Vector2(24,11)]: draw_circle(p,3,tint,false,2,true)
		"gun":
			solid([[4,23],[15,12],[22,18],[12,29]])
			line([[18,15],[28,4]],4)
			line([[24,6],[29,10]],2)
		"star":
			var points := []
			for i in 10:
				var v := Vector2(16,16)+Vector2.from_angle(-PI/2+i*PI/5)*(14 if i%2==0 else 6)
				points.append([v.x,v.y])
			solid(points)
		"cross":
			line([[10,3],[22,3],[20,12],[29,10],[29,22],[20,20],[22,29],[10,29],[12,20],[3,22],[3,10],[12,12],[10,3]],2)
		"lily":
			line([[16,30],[16,5]],3)
			solid([[16,1],[21,8],[16,18],[11,8]])
			line([[16,21],[8,9],[3,11],[4,17],[11,20],[21,20],[28,17],[29,11],[24,9],[16,21]],3)
