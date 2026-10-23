extends Control
## Original pixel art. All movement, cover, time and shots resolve in the activity model.
signal aim(point: Vector2)
signal move_requested(point: Vector2)
signal elapsed(delta: float)
var traveler_profile: Dictionary={}
const Palette=preload("res://ui/traveler_palette.gd")
const PRAIRIE = preload("res://art/pixels/prairie.png")
# Eight-frame sheets sized to data/hunting.json species; rows walk, run (after a shot) and down.
const ANIMALS = [preload("res://art/pixels/hunt_bison.png"), preload("res://art/pixels/hunt_deer.png"), preload("res://art/pixels/hunt_rabbit.png")]
const COVER = preload("res://art/pixels/hunt_cover.png") # the model's 12 x 14 cover
const HUNTER = preload("res://art/pixels/hunt_hunter.png") # 16x18 frames; rows standing, walking
const SMOKE = preload("res://art/pixels/hunt_smoke.png") # 16x16 frames
const FRAMES := 8
const SMOKE_SECONDS := 0.8
var active := false
var encounter: Dictionary = {}
var scenes = preload("res://ui/location_scenes.gd").new()
var model = preload("res://simulation/hunting.gd").new()
var smoke_at := Vector2.ZERO
var smoke_age := SMOKE_SECONDS
var last_shots := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	clip_contents = true

func target_rect(index: int) -> Rect2:
	return model.bounds(encounter, index)

func _process(delta: float) -> void:
	if active:
		elapsed.emit(delta)
		smoke_age += delta
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
	var running: bool = encounter.shots > 0
	for index in range(encounter.animals.size()):
		var down: bool = index in encounter.targets
		if encounter.animals[index].escaped and not down:
			continue
		var bounds := target_rect(index)
		var p := bounds.position
		if encounter.animals[index].direction < 0:
			draw_set_transform(Vector2(bounds.position.x * 2 + bounds.size.x, 0), 0, Vector2(-1, 1))
		var kind: int = encounter.animals[index].kind
		# Game walks until the first shot, then runs flat out; shot animals stay where they fell.
		var frame := 0 if down else int(encounter.elapsed * (14.0 if running else 8.0) + index * 3) % FRAMES
		var row := 2 if down else (1 if running else 0)
		draw_texture_rect_region(ANIMALS[kind], Rect2(p, bounds.size), Rect2(frame * bounds.size.x, row * bounds.size.y, bounds.size.x, bounds.size.y))
		draw_set_transform(Vector2.ZERO)
	# Foreground cover masks animals and blocks the rifle's line of fire.
	var cover_frame := 0 if encounter.region in ["woodland","forest"] else 1
	for obstacle in encounter.cover:
		draw_texture_rect_region(COVER, obstacle, Rect2(cover_frame * 12, 0, 12, 14))
	var hunter: Vector2 = encounter.hunter.round()
	var direction: Vector2 = (get_local_mouse_position() - hunter).normalized()
	var walking: bool = encounter.hunter.distance_to(encounter.destination) > 0.5
	var step := int(encounter.elapsed * (10.0 if walking else 3.0)) % FRAMES
	# Feet on the hunter's position; he turns to face where the rifle points.
	if direction.x < 0:
		draw_set_transform(Vector2(hunter.x * 2, 0), 0, Vector2(-1, 1))
	draw_texture_rect_region(Palette.texture(HUNTER,traveler_profile,true), Rect2(hunter - Vector2(8, 17), Vector2(16, 18)), Rect2(step * 16, (1 if walking else 0) * 18, 16, 18))
	draw_set_transform(Vector2.ZERO)
	# The rifle: walnut stock at the shoulder, a long dark barrel toward the aim.
	var shoulder := hunter + Vector2(0, -9)
	var kick := 2.0 if encounter.flash > 0 else 0.0
	var butt := shoulder - direction * (2.0 + kick)
	draw_line(butt, butt + direction * 5, Color("76503c"), 2)
	draw_line(butt + direction * 5, butt + direction * 15, Color("302b2c"), 1)
	if encounter.shots != last_shots:
		last_shots = encounter.shots
		smoke_at = (butt + direction * 15).round()
		smoke_age = 0.0
	if encounter.flash > 0:
		draw_line(hunter, encounter.aim, Color("f7d88d"), 1)
	if smoke_age < SMOKE_SECONDS:
		var puff := mini(FRAMES - 1, int(smoke_age / SMOKE_SECONDS * FRAMES))
		draw_texture_rect_region(SMOKE, Rect2(smoke_at - Vector2(8, 12), Vector2(16, 16)), Rect2(puff * 16, 0, 16, 16))
