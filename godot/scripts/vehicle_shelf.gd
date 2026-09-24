extends ScrollContainer
## Dragging a card scrolls the collection without selecting it or rotating the tank.
var dragging := false
var suppress_click := false
var distance := 0.0

func _ready() -> void:
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	get_h_scroll_bar().value_changed.connect(func(_value: float) -> void: update_arrows())

func attach(card: Control) -> void:
	card.gui_input.connect(handle_input)

func _gui_input(event: InputEvent) -> void:
	handle_input(event)

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			if event.pressed:
				scroll_horizontal += -192 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 192
			accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			dragging=event.pressed
			if dragging:
				distance=0
				suppress_click=false
			elif suppress_click:
				accept_event()
	elif event is InputEventMouseMotion and dragging:
		distance+=absf(event.relative.x)
		if distance>6:
			suppress_click=true
			scroll_horizontal-=roundi(event.relative.x)
			accept_event()
	elif event is InputEventPanGesture:
		scroll_horizontal+=roundi(event.delta.x*35+event.delta.y*35)
		accept_event()

func restore(offset: int, selected: Control) -> void:
	await get_tree().process_frame
	if not is_instance_valid(selected):
		return
	scroll_horizontal=offset
	ensure_control_visible(selected)
	update_arrows()

func update_arrows() -> void:
	var bar := get_h_scroll_bar()
	var previous := get_parent().get_node_or_null("ShelfPrev") as Button
	var next := get_parent().get_node_or_null("ShelfNext") as Button
	if previous:
		previous.disabled=bar.value<=bar.min_value
	if next:
		next.disabled=bar.value>=bar.max_value-bar.page-1
