@tool
extends Control
## Browser design coordinates, fitted without cropping or stretching artwork.
@export var design_size := Vector2(1280,720)

func _ready() -> void:
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	var design := get_node_or_null("Design") as Control
	if design == null:
		return
	var factor := minf(size.x/design_size.x,size.y/design_size.y)
	design.scale = Vector2.ONE*factor
	design.position = (size-design_size*factor)*.5
