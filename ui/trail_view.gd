extends Control
## Composites original native-resolution pixel assets. All motion lands on whole pixels.
const WAGON = preload("res://art/pixels/wagon.png")
const OXEN = preload("res://art/pixels/oxen.png")
const WALKER = preload("res://art/pixels/walker.png")
const FRAMES := 8 # wagon, oxen and walker sheets hold eight frames side by side
const FPS := 12.0
# River crossings are drawn in a three-quarter view on a 720x300 world that the view pans across.
# Sprite frames are placed by their anchor, the ground point under the rear of the piece.
const CROSSING = preload("res://art/pixels/river_crossing.png")
const CROSS_WAGON = preload("res://art/pixels/cross_wagon.png") # 64x48; rows: team, wading, alone, floating
const CROSS_SWIM_OX = preload("res://art/pixels/cross_swim_ox.png") # 32x24
const CROSS_RAFT = preload("res://art/pixels/cross_raft.png")
const CROSS_FERRYMAN = preload("res://art/pixels/cross_ferryman.png") # 32x40
const CROSS_PEOPLE = preload("res://art/pixels/cross_people.png") # 16x20; rows: man, woman
const CROSS_SWIMMER = preload("res://art/pixels/cross_swimmer.png") # 16x12; rows: man, woman, in trouble
const WORLD := Vector2i(720, 300)
const PATH_START := Vector2(90, 282) # the wagon's rear on the near landing; the road runs (2, -1)
const NEAR_SHORE := 31.0 # path distances where the near and far shorelines cross the road
const FAR_SHORE := 201.0
const PATH_END := 214.0
const RAFT_LENGTH := 25.0 # path units; one unit is (2, -1) pixels, 2.24 sprite pixels along the deck
const CAR = preload("res://art/pixels/corolla.png")
const ELDER = preload("res://art/pixels/elder.png")
const SABER = preload("res://art/pixels/lightsaber.png")
const HORIZON = preload("res://art/pixels/travel_horizon.png")
# Backdrop layers drawn far to near, with how fast each slides relative to the road.
const PARALLAX := {
	"prairie": [["sky", 0.0], ["clouds", 0.04], ["far", 0.1], ["floor", 0.0]],
	"river": [["sky", 0.0], ["clouds", 0.04], ["far", 0.1], ["floor", 0.0]],
	"travel_mountains": [["sky", 0.0], ["clouds", 0.04], ["far", 0.1], ["mid", 0.35], ["ground", 1.0]],
	"travel_desert": [["sky", 0.0], ["clouds", 0.04], ["far", 0.12], ["mid", 0.3], ["ground", 1.0]],
	"travel_forest": [["sky", 0.0], ["clouds", 0.04], ["far", 0.15], ["mid", 0.5], ["ground", 1.0]],
}
const GROUND = preload("res://art/pixels/travel_ground.png")
const NEAR_BANK = [Vector2(0, 178), Vector2(25, 189), Vector2(50, 204), Vector2(75, 212), Vector2(100, 220), Vector2(125, 237), Vector2(150, 248), Vector2(175, 269), Vector2(200, 275), Vector2(225, 288), Vector2(250, 295), Vector2(260, 300), Vector2(0, 300)]
const FAR_BANK = [Vector2(330, 0), Vector2(360, 21), Vector2(390, 26), Vector2(420, 43), Vector2(450, 62), Vector2(480, 77), Vector2(510, 90), Vector2(540, 99), Vector2(570, 125), Vector2(600, 136), Vector2(630, 150), Vector2(660, 161), Vector2(690, 182), Vector2(720, 200), Vector2(720, 0)]
signal crossing_finished
var scenes = preload("res://ui/location_scenes.gd").new()
var ambience = preload("res://ui/scene_ambience.gd").new()
var scene_id := ""
var miles := 0
var vehicle := "wagon"
var walkers := 5
var encounter := ""
var motion := 0.0
var clock_time := 0.0
var river_scene := false
var scrolling := false
var scroll_distance := 0.0
var crossing: Dictionary = {}
var crossing_elapsed := 0.0
var crossing_duration := 4.5
var crossing_paused := false
var water_spans: Array[Vector2i] = []
var weather_id := "clear"
var terrain := "plains"

func start_crossing(result: Dictionary) -> void:
	crossing = result.duplicate(true)
	crossing_elapsed = 0.0
	motion = 0.0
	scrolling = false
	queue_redraw()

func finish_crossing() -> void:
	if crossing.is_empty():
		return
	crossing = {}
	crossing_elapsed = 0.0
	queue_redraw()
	crossing_finished.emit()

func cancel_crossing() -> void:
	crossing = {}
	crossing_elapsed = 0.0
	crossing_paused = false
	queue_redraw()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	# Derive shoreline clipping from the same outlines that the crossing picture paints.
	for y in range(WORLD.y):
		var left := maxf(0.0, _bank_edge(NEAR_BANK, y + 0.5, true))
		var right := minf(WORLD.x, _bank_edge(FAR_BANK, y + 0.5, false))
		water_spans.append(Vector2i(ceili(left), floori(right)))

func _bank_edge(polygon: Array, y: float, rightmost: bool) -> float:
	# Where a bank outline crosses row y: its rightmost point (near bank) or leftmost (far bank).
	var edge := -1.0 if rightmost else float(WORLD.x) + 1.0
	for i in range(polygon.size()):
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
			var x := a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y)
			edge = maxf(edge, x) if rightmost else minf(edge, x)
	return edge

func _process(delta: float) -> void:
	clock_time += delta
	if not crossing.is_empty():
		if not crossing_paused:
			crossing_elapsed += delta
			if crossing_elapsed >= crossing_duration:
				finish_crossing()
	elif scrolling and scene_id.is_empty():
		scroll_distance = fposmod(scroll_distance + delta * 28.0, 432.0 * 7.0)
	motion = maxf(0.0, motion - delta)
	queue_redraw()

func _draw() -> void:
	if not crossing.is_empty():
		_draw_crossing()
		_draw_weather()
		return
	if not scene_id.is_empty():
		draw_texture(scenes.texture_for(scene_id), Vector2.ZERO)
		ambience.draw(self, scene_id, scenes.texture_for(scene_id), clock_time)
		if vehicle=="foot":_draw_walkers(Vector2(140,135),false)
		_draw_weather()
		return # Parked wagons/people are composed into each arrival illustration.
	# Parallax: each layer of the backdrop slides at its own speed, nearest fastest, and the
	# clouds also drift on the wind whether or not the party is moving.
	var set_name: String = "river" if river_scene else ("travel_" + terrain if terrain in ["mountains", "desert", "forest"] else "prairie")
	var layers: Array = PARALLAX[set_name]
	for layer in layers:
		var texture: Texture2D = _layer_texture(set_name + "_" + layer[0])
		var drift: float = clock_time * 1.5 if layer[0] == "clouds" else 0.0
		_tile(texture, 0, posmod(int(scroll_distance * layer[1] + drift), 432))
	if set_name in ["prairie", "river"]:
		_tile(HORIZON, 65, int(scroll_distance / 7.0) % 432)
		_tile(GROUND, 100, int(scroll_distance) % 432)
	var frame := int(clock_time * FPS) % FRAMES if scrolling or motion > 0 else 0
	var bob := -1 if frame % 4 >= 2 else 0
	var shift := int(sin(clock_time * 3) * 3) if motion > 0 else 0
	if vehicle=="foot":
		_draw_walkers(Vector2(150+shift,132+bob),scrolling or motion>0)
	elif vehicle == "corolla":
		draw_texture(CAR, Vector2(173 + shift, 96 + bob))
	else:
		draw_texture_rect_region(WAGON, Rect2(137 + shift, 75 + bob, 96, 64), Rect2(frame * 96, 0, 96, 64))
		draw_line(Vector2(220 + shift, 117), Vector2(262 + shift, 117), Color("76503c"), 1)
		draw_texture_rect_region(OXEN, Rect2(227 + shift, 103, 48, 32), Rect2(frame * 48, 0, 48, 32))
		draw_texture_rect_region(OXEN, Rect2(261 + shift, 103, 48, 32), Rect2(((frame + 4) % FRAMES) * 48, 0, 48, 32))
	match encounter:
		"elder_god":
			draw_texture(ELDER, Vector2(51, 48))
		"found_lightsaber":
			draw_texture(SABER, Vector2(83, 120))
		"corolla":
			if vehicle != "corolla":
				draw_texture(CAR, Vector2(39, 99))
		"muddy_trail":
			draw_rect(Rect2(150, 130, 80, 7), Color("76503c"))
			draw_rect(Rect2(159, 132, 60, 2), Color("a16b43"))
	_draw_weather()

func _draw_walkers(origin: Vector2,moving: bool) -> void:
	for index in range(walkers):
		var x:=origin.x+index*19
		var y:=origin.y-(index%2)*3
		var step:=int(clock_time*FPS+index*3)%FRAMES if moving else 0
		draw_texture_rect_region(WALKER,Rect2(x-5,y-23,16,24),Rect2(step*16,(index%2)*24,16,24))

func _draw_weather() -> void:
	# Placeholder thunderstorm and heat effects until the Aseprite overlays land.
	if weather_id == "thunderstorm" and posmod(int(clock_time * 10), 37) == 0:
		draw_rect(Rect2(0, 0, 432, 150), Color(1, 1, 0.9, 0.35))
	if weather_id == "heat":
		for y in [92, 104, 116]:
			var x := posmod(int(clock_time * 9) + y * 5, 48)
			for band in range(0, 432, 48):
				draw_rect(Rect2(band + x, y, 18, 1), Color(1, 0.93, 0.7, 0.25))
	if weather_id in ["rain", "heavy_rain", "hail", "blizzard", "thunderstorm"]:
		var snow := weather_id in ["hail", "blizzard"]
		for index in range(45 if weather_id in ["heavy_rain", "blizzard", "thunderstorm"] else 22):
			var x := posmod(index * 37 - int(clock_time * 13), 432)
			var y := posmod(index * 19 + int(clock_time * (24 if snow else 70)), 150)
			draw_rect(Rect2(x, y, 2 if snow else 1, 2 if snow else 4), Color("f6e7bc") if snow else Color("8db8c3"))
	elif weather_id == "fog":
		for y in [24, 51, 79, 105]:
			draw_rect(Rect2(0, y, 432, 16), Color(0.75, 0.78, 0.73, 0.3))

var layer_textures: Dictionary = {}
func _layer_texture(name: String) -> Texture2D:
	if not layer_textures.has(name):
		layer_textures[name] = load("res://art/pixels/" + name + ".png")
	return layer_textures[name]

func _tile(texture: Texture2D, y: int, offset: int) -> void:
	draw_texture(texture, Vector2(-offset, y))
	draw_texture(texture, Vector2(432 - offset, y))

func _water_rect(bounds: Rect2, color: Color) -> void:
	# Water can cover a sprite only inside the river, never on either bank (world coordinates).
	for y in range(maxi(0, int(bounds.position.y)), mini(WORLD.y, int(bounds.end.y))):
		var span: Vector2i = water_spans[y]
		var left := maxi(span.x, int(bounds.position.x))
		var right := mini(span.y, int(bounds.end.x))
		if right > left:
			draw_rect(Rect2(left, y, right - left, 1), color)

func _in_water(point: Vector2) -> bool:
	var y := int(point.y)
	return y >= 0 and y < WORLD.y and point.x >= water_spans[y].x and point.x < water_spans[y].y

func _on_path(t: float, side := 0.0) -> Vector2:
	# A point t units along the road, shifted `side` pixels to the right of it (downstream).
	return (PATH_START + Vector2(2, -1) * t + Vector2(2, 1) * side * 0.447).round()

func _sprite(texture: Texture2D, size: Vector2i, anchor: Vector2i, frame: int, row: int, at: Vector2) -> void:
	draw_texture_rect_region(texture, Rect2(at - Vector2(anchor), size), Rect2(frame * size.x, row * size.y, size.x, size.y))

func _ease(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

func _draw_wagon_at(t: float, frame: int, ford: bool, bob := 0, aboard := false) -> void:
	# The wagon and its team: hitched on land, wading in a ford, or floated with the team swimming.
	var at := _on_path(t) + Vector2(0, bob)
	var team_front := _on_path(t + 20.0)
	var wet := not aboard and (_in_water(at) or _in_water(team_front))
	if not wet:
		_sprite(CROSS_WAGON, Vector2i(64, 48), Vector2i(10, 42), frame, 0, at)
	elif ford:
		_sprite(CROSS_WAGON, Vector2i(64, 48), Vector2i(10, 42), frame, 1, at)
	else:
		var team_t := t + 17.5
		for side in [-3.6, 3.6]:
			_sprite(CROSS_SWIM_OX, Vector2i(32, 24), Vector2i(8, 19), (frame + (4 if side < 0 else 0)) % FRAMES, 0, _on_path(team_t, side))
		_sprite(CROSS_WAGON, Vector2i(64, 48), Vector2i(10, 42), frame, 3 if _in_water(at) else 2, at)

func _draw_ferry(t_raft: float, cargo_t: float, foot: bool) -> void:
	var raft_at := _on_path(t_raft)
	_sprite(CROSS_RAFT, Vector2i(72, 40), Vector2i(14, 32), 0, 0, raft_at)
	var aboard := cargo_t >= t_raft and cargo_t <= t_raft + RAFT_LENGTH
	var lift := Vector2(0, -2) if aboard else Vector2.ZERO
	var moving := not is_equal_approx(cargo_t, t_raft + 2.0)
	var frame := int(crossing_elapsed * FPS) % FRAMES if moving else 0
	if foot:
		_draw_party_on_foot(cargo_t, frame, lift)
	else:
		draw_set_transform(-_camera() + lift)
		_draw_wagon_at(cargo_t, frame, false, 0, aboard)
		draw_set_transform(-_camera())
	# The ferryman stands at the bow on the downstream side, poling.
	var pole := int(crossing_elapsed * FPS * 0.75) % FRAMES
	_sprite(CROSS_FERRYMAN, Vector2i(32, 40), Vector2i(12, 30), pole, 0, _on_path(t_raft + 22.0, 9.0) + Vector2(0, -2))

func _draw_party_on_foot(t: float, frame: int, lift := Vector2.ZERO, rough := false) -> void:
	# Walkers in a loose file; anyone in the river swims, anyone on land walks.
	for index in range(walkers):
		var pt := t + 14.0 - (index / 2) * 5.0
		var side := 5.0 if index % 2 == 0 else -5.0
		var at := _on_path(pt, side) + lift
		var row := index % 2
		var step := (frame + index * 3) % FRAMES
		if lift == Vector2.ZERO and _in_water(at):
			_sprite(CROSS_SWIMMER, Vector2i(16, 12), Vector2i(6, 8), step, 2 if rough and index == 0 else row, at)
		else:
			_sprite(CROSS_PEOPLE, Vector2i(16, 20), Vector2i(8, 17), step if frame > 0 or lift == Vector2.ZERO else 0, row, at)

func _focus() -> Vector2:
	# The point the view follows: the middle of the wagon (or the party) as it crosses.
	var phase := _crossing_phase()
	return _on_path(phase.cargo + 9.0) + Vector2(0, -12)

func _camera() -> Vector2:
	var focus := _focus()
	return Vector2(clampf(focus.x - 216.0, 0.0, WORLD.x - 432.0), clampf(focus.y - 80.0, 0.0, WORLD.y - 150.0)).round()

func _crossing_phase() -> Dictionary:
	# Where the cargo (wagon or party) and the raft are along the road at this moment.
	var progress := clampf(crossing_elapsed / crossing_duration, 0.0, 1.0)
	# An accident stalls the crossing midstream while the current carries cargo away.
	if crossing.get("mishap", false):
		progress = progress * 1.4 if progress < 0.3 else (0.42 if progress < 0.6 else lerpf(0.42, 1.0, (progress - 0.6) / 0.4))
	if crossing.get("method", "") in ["ferry", "seized"]:
		var dock := NEAR_SHORE - 2.0
		var land := FAR_SHORE - RAFT_LENGTH
		if progress < 0.15:
			return {"cargo": lerpf(0.0, dock + 2.0, _ease(progress / 0.15)), "raft": dock, "moving": true}
		if progress < 0.85:
			var r := lerpf(dock, land, _ease((progress - 0.15) / 0.7))
			return {"cargo": r + 2.0, "raft": r, "moving": false}
		return {"cargo": lerpf(land + 2.0, PATH_END, _ease((progress - 0.85) / 0.15)), "raft": land, "moving": true}
	var t := lerpf(0.0, PATH_END, _ease(progress * 1.1 - 0.05))
	return {"cargo": t, "raft": -100.0, "moving": progress > 0.0 and progress < 0.97}

func _draw_crossing() -> void:
	var progress := clampf(crossing_elapsed / crossing_duration, 0.0, 1.0)
	# A ferry taken by force crosses the same way as a hired one.
	var method: String = "ferry" if crossing.method == "seized" else crossing.method
	# Ferried rivers (the Kansas above all) run yellow-brown with silt, matching their location pictures.
	var water := Color("a38b64") if method == "ferry" else Color("3d7f99")
	var cam := _camera()
	draw_set_transform(-cam)
	draw_rect(Rect2(cam, Vector2(432, 150)), water)
	# The current: short streaks drifting downstream, parallel to the banks.
	for i in range(110):
		var drift := crossing_elapsed * 16.0
		var sx := posmod(i * 97 + int(drift * 2.0), WORLD.x)
		var sy := posmod(i * 53 + int(drift), WORLD.y)
		var length := 2 + i % 3
		for k in range(length):
			_water_rect(Rect2(sx + k * 2, sy + k, 3, 1), Color("afd5ce") if i % 4 else Color("f6e7bc"))
	draw_texture(CROSSING, Vector2.ZERO)
	var phase := _crossing_phase()
	var rough: bool = crossing.get("mishap", false) and progress > 0.4 and progress < 0.75
	var bob := roundi(sin(progress * TAU * 4.0)) + (2 if rough else 0)
	var frame := int(crossing_elapsed * FPS) % FRAMES if phase.moving or method != "ferry" else 0
	if method == "ferry":
		_draw_ferry(phase.raft, phase.cargo, vehicle == "foot")
	elif vehicle == "foot":
		_draw_party_on_foot(phase.cargo, frame, Vector2.ZERO, rough)
	else:
		_draw_wagon_at(phase.cargo, frame, method == "ford", bob if _in_water(_on_path(phase.cargo)) and method != "ford" else 0)
		# A wake spreading behind the wagon while it is in the water.
		var stern := _on_path(phase.cargo - 2.0, 6.0)
		if _in_water(stern):
			for i in range(4):
				_water_rect(Rect2(stern.x - 6 - i * 5 + (frame % 2), stern.y + i * 3, 4, 1), Color("f6e7bc"))
	if rough:
		var spot := _on_path(phase.cargo + 8.0)
		for i in range(7):
			_water_rect(Rect2(spot.x - 10 + i * 6, spot.y - 4 - (i * 7 + frame) % 9, 2, 3), Color("f6e7bc"))
	if crossing.get("mishap", false) and progress >= 0.35 and progress < 0.85:
		# Cargo boxes go overboard and drift downstream with the current, then sink.
		var lost := (progress - 0.35) / 0.5
		var start := _on_path(phase.cargo + 6.0, 8.0)
		for i in range(3):
			var box := (start + Vector2(2, 1) * (lost * 46.0 + i * 9.0) + Vector2(i * 3, -i * 2)).round()
			_water_rect(Rect2(box.x, box.y, 7, 5), Color("76503c"))
			_water_rect(Rect2(box.x + 1, box.y + 1, 5, 2), Color("c18d4d"))
			_water_rect(Rect2(box.x - 3, box.y + 5, 12, 1), Color("afd5ce"))
	draw_set_transform(Vector2.ZERO)
