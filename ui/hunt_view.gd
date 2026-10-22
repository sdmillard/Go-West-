extends Control
## Original pixel art. All movement, cover, time and shots resolve in the activity model.
signal aim(point: Vector2)
signal move_requested(point: Vector2)
signal elapsed(delta: float)
const PRAIRIE = preload("res://art/pixels/prairie.png")
var active := false
var encounter: Dictionary = {}
var scenes = preload("res://ui/location_scenes.gd").new()
var model = preload("res://simulation/hunting.gd").new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	clip_contents = true

func target_rect(index: int) -> Rect2:
	return model.bounds(encounter, index)

func _process(delta: float) -> void:
	if active:
		elapsed.emit(delta)
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not active or not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		aim.emit(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		move_requested.emit(event.position)
	accept_event()

func _draw() -> void:
	var region: String = encounter.get("region","woodland")
	var scenery: String = {"highcountry":"travel_mountains","sagebrush":"travel_desert","forest":"travel_forest"}.get(region,"")
	draw_texture(PRAIRIE if scenery.is_empty() else scenes.texture_for(scenery), Vector2.ZERO)
	if encounter.is_empty():
		return
	for index in range(encounter.animals.size()):
		if index in encounter.targets or encounter.animals[index].escaped:
			continue
		var bounds := target_rect(index)
		var p := bounds.position
		if encounter.animals[index].direction < 0:
			draw_set_transform(Vector2(bounds.position.x * 2 + bounds.size.x, 0), 0, Vector2(-1, 1))
		var kind: int = encounter.animals[index].kind
		var body := Color("76503c" if kind == 0 else "a16b43")
		if kind == 0:
			draw_rect(Rect2(p + Vector2(3, 3), Vector2(29, 15)), body)
			draw_rect(Rect2(p + Vector2(0, 0), Vector2(17, 15)), Color("45372f"))
			draw_rect(Rect2(p + Vector2(29, 8), Vector2(10, 11)), Color("45372f"))
			draw_rect(Rect2(p + Vector2(31, 4), Vector2(2, 5)), Color("ecd097"))
		elif kind == 1:
			draw_rect(Rect2(p + Vector2(0, 6), Vector2(23, 10)), Color("45372f"))
			draw_rect(Rect2(p + Vector2(1, 7), Vector2(20, 7)), Color("ddb461"))
			draw_rect(Rect2(p + Vector2(19, 2), Vector2(6, 11)), body)
			draw_rect(Rect2(p + Vector2(23, 0), Vector2(2, 5)), Color("45372f"))
			draw_rect(Rect2(p + Vector2(24, 4), Vector2(2, 1)), Color("241f22"))
		else:
			draw_rect(Rect2(p + Vector2(0, 3), Vector2(14, 7)), Color("45372f"))
			draw_rect(Rect2(p + Vector2(1, 4), Vector2(12, 5)), Color("ecd097"))
			draw_rect(Rect2(p + Vector2(9, 0), Vector2(2, 6)), Color("ecd097"))
			draw_rect(Rect2(p + Vector2(12, 1), Vector2(2, 5)), Color("ecd097"))
		for leg in [4, 14, 24] if kind == 0 else ([3, 17] if kind == 1 else [3, 10]):
			draw_rect(Rect2(p + Vector2(leg, 14 if kind < 2 else 8), Vector2(2, (7 if kind < 2 else 3) + (int(encounter.elapsed * 8 + leg) % 2))), Color("45372f"))
		draw_set_transform(Vector2.ZERO)
	# Foreground cover masks animals and blocks the rifle's line of fire.
	for obstacle in encounter.cover:
		var p: Vector2 = obstacle.position
		draw_rect(obstacle, Color("596442"))
		if encounter.region in ["woodland","forest"]:
			draw_rect(Rect2(p + Vector2(4, 4), Vector2(4, 10)), Color("76503c"))
			draw_rect(Rect2(p, Vector2(12, 8)), Color("3f563a"))
		else:
			for x in [0, 4, 8]:
				draw_rect(Rect2(p + Vector2(x, 0), Vector2(2, 14)), Color("85864c"))
	var hunter: Vector2 = encounter.hunter.round()
	draw_rect(Rect2(hunter - Vector2(3, 10), Vector2(6, 7)), Color("42636b"))
	draw_rect(Rect2(hunter - Vector2(2, 14), Vector2(4, 4)), Color("ecc78a"))
	draw_rect(Rect2(hunter - Vector2(5, 15), Vector2(10, 2)), Color("554335"))
	for x in [-3, 1]:
		draw_rect(Rect2(hunter + Vector2(x, -3), Vector2(2, 4)), Color("45372f"))
	var direction: Vector2 = (get_local_mouse_position() - hunter).normalized()
	draw_line(hunter + Vector2(0, -6), hunter + Vector2(0, -6) + direction * 12, Color("45372f"), 2)
	if encounter.flash > 0:
		draw_line(hunter, encounter.aim, Color("f7d88d"), 1)
