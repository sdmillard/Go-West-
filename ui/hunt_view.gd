extends Control
## Original pixel art. All movement, cover, time and shots resolve in the activity model.
signal aim(point: Vector2)
signal move_requested(point: Vector2)
signal elapsed(delta: float)
const PRAIRIE = preload("res://art/pixels/prairie.png")
# Two-frame sheets sized to data/hunting.json species and the model's 12 x 14 cover.
const ANIMALS = [preload("res://art/pixels/hunt_bison.png"), preload("res://art/pixels/hunt_deer.png"), preload("res://art/pixels/hunt_rabbit.png")]
const COVER = preload("res://art/pixels/hunt_cover.png")
const HUNTER = preload("res://art/pixels/hunt_hunter.png")
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
		var frame := int(encounter.elapsed * 8 + index) % 2
		draw_texture_rect_region(ANIMALS[kind], Rect2(p, bounds.size), Rect2(frame * bounds.size.x, 0, bounds.size.x, bounds.size.y))
		draw_set_transform(Vector2.ZERO)
	# Foreground cover masks animals and blocks the rifle's line of fire.
	var cover_frame := 0 if encounter.region in ["woodland","forest"] else 1
	for obstacle in encounter.cover:
		draw_texture_rect_region(COVER, obstacle, Rect2(cover_frame * 12, 0, 12, 14))
	var hunter: Vector2 = encounter.hunter.round()
	# Feet on the hunter's position, as the old rectangles were.
	draw_texture(HUNTER, hunter - Vector2(8, 17))
	var direction: Vector2 = (get_local_mouse_position() - hunter).normalized()
	draw_line(hunter + Vector2(0, -6), hunter + Vector2(0, -6) + direction * 12, Color("45372f"), 2)
	if encounter.flash > 0:
		draw_line(hunter, encounter.aim, Color("f7d88d"), 1)
