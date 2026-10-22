extends Control
## Composites original native-resolution pixel assets. All motion lands on whole pixels.
const PRAIRIE = preload("res://art/pixels/prairie.png")
const RIVER = preload("res://art/pixels/river.png")
const WAGON = preload("res://art/pixels/wagon.png")
const OXEN = preload("res://art/pixels/oxen.png")
const CAR = preload("res://art/pixels/corolla.png")
const ELDER = preload("res://art/pixels/elder.png")
const SABER = preload("res://art/pixels/lightsaber.png")
const HORIZON = preload("res://art/pixels/travel_horizon.png")
const GROUND = preload("res://art/pixels/travel_ground.png")
const NEAR_BANK = [Vector2(0, 96), Vector2(43, 108), Vector2(84, 150), Vector2(0, 150)]
const FAR_BANK = [Vector2(432, 82), Vector2(399, 86), Vector2(333, 150), Vector2(432, 150)]
signal crossing_finished
var scenes = preload("res://ui/location_scenes.gd").new()
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
var crossing_duration := 2.8
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
	# Derive shoreline clipping from the same polygons that paint the banks.
	var near_polygon := PackedVector2Array(NEAR_BANK)
	var far_polygon := PackedVector2Array(FAR_BANK)
	for y in range(150):
		var left := 432
		var right := 0
		for x in range(432):
			var point := Vector2(x + 0.5, y + 0.5)
			if y >= 78 and not Geometry2D.is_point_in_polygon(point, near_polygon) and not Geometry2D.is_point_in_polygon(point, far_polygon):
				left = mini(left, x)
				right = x + 1
		water_spans.append(Vector2i(left, right))

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
		if vehicle=="foot":_draw_walkers(Vector2(140,135),false)
		_draw_weather()
		return # Parked wagons/people are composed into each arrival illustration.
	if terrain in ["mountains","desert","forest"] and not river_scene:
		var background: Texture2D = scenes.texture_for("travel_"+terrain)
		draw_texture(background,Vector2.ZERO)
		var offset := int(scroll_distance) % 432
		for x in [-offset,432-offset]:
			draw_texture_rect_region(background,Rect2(x,100,432,50),Rect2(0,100,432,50))
	else:
		draw_texture(RIVER if river_scene else PRAIRIE, Vector2.ZERO)
		_tile(HORIZON, 65, int(scroll_distance / 7.0) % 432)
		_tile(GROUND, 100, int(scroll_distance) % 432)
	var frame := int(clock_time * 8) % 4 if scrolling or motion > 0 else 0
	var bob := -1 if frame == 1 or frame == 3 else 0
	var shift := int(sin(clock_time * 3) * 3) if motion > 0 else 0
	if vehicle=="foot":
		_draw_walkers(Vector2(150+shift,132+bob),scrolling or motion>0)
	elif vehicle == "corolla":
		draw_texture(CAR, Vector2(173 + shift, 96 + bob))
	else:
		draw_texture_rect_region(WAGON, Rect2(137 + shift, 75 + bob, 96, 64), Rect2(frame * 96, 0, 96, 64))
		draw_line(Vector2(220 + shift, 117), Vector2(262 + shift, 117), Color("76503c"), 1)
		draw_texture_rect_region(OXEN, Rect2(227 + shift, 103, 48, 32), Rect2(frame * 48, 0, 48, 32))
		draw_texture_rect_region(OXEN, Rect2(261 + shift, 103, 48, 32), Rect2(((frame + 2) % 4) * 48, 0, 48, 32))
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
		var stride:=2 if moving and int(clock_time*6+index)%2==0 else -1
		draw_rect(Rect2(x,y-20,5,5),Color("ecd097"))
		draw_rect(Rect2(x-1,y-22,8,2),Color("76503c"))
		draw_rect(Rect2(x,y-15,6,9),Color("37688e") if index%2==0 else Color("a16b43"))
		draw_rect(Rect2(x-3,y-14,3,7),Color("76503c"))
		draw_line(Vector2(x+1,y-6),Vector2(x+1+stride,y),Color("45372f"),2)
		draw_line(Vector2(x+4,y-6),Vector2(x+4-stride,y),Color("45372f"),2)

func _draw_weather() -> void:
	if weather_id in ["rain", "heavy_rain", "hail", "blizzard"]:
		var snow := weather_id in ["hail", "blizzard"]
		for index in range(45 if weather_id in ["heavy_rain", "blizzard"] else 22):
			var x := posmod(index * 37 - int(clock_time * 13), 432)
			var y := posmod(index * 19 + int(clock_time * (24 if snow else 70)), 150)
			draw_rect(Rect2(x, y, 2 if snow else 1, 2 if snow else 4), Color("f6e7bc") if snow else Color("8db8c3"))
	elif weather_id == "fog":
		for y in [24, 51, 79, 105]:
			draw_rect(Rect2(0, y, 432, 16), Color(0.75, 0.78, 0.73, 0.3))

func _tile(texture: Texture2D, y: int, offset: int) -> void:
	draw_texture(texture, Vector2(-offset, y))
	draw_texture(texture, Vector2(432 - offset, y))

func _water_rect(bounds: Rect2, color: Color) -> void:
	# Water can occlude a sprite only inside the river, never on either bank.
	for y in range(maxi(0, int(bounds.position.y)), mini(150, int(bounds.end.y))):
		var span: Vector2i = water_spans[y]
		var left := maxi(span.x, int(bounds.position.x))
		var right := mini(span.y, int(bounds.end.x))
		if right > left:
			draw_rect(Rect2(left, y, right - left, 1), color)

func _draw_swimming_party(x: int, rough: bool) -> void:
	for index in range(walkers):
		var px := x + index * 19
		var py := 118 + (index % 2) * 9
		var span: Vector2i = water_spans[py]
		if px < span.x or px >= span.y:
			# Individual travelers stand up only after reaching dry land.
			var count := walkers
			walkers = 1
			_draw_walkers(Vector2(px, py), true)
			walkers = count
			continue
		var stroke := int(crossing_elapsed * 7 + index) % 4
		var dip := 3 if rough and index == 0 else (1 if stroke == 2 else 0)
		var shirt := Color("37688e") if index % 2 == 0 else Color("a16b43")
		# Horizontal bodies, heads and packs sit at the water surface.
		draw_rect(Rect2(px - 10, py - 3 + dip, 10, 3), shirt)
		draw_rect(Rect2(px - 9, py - 6 + dip, 6, 4), Color("76503c"))
		draw_rect(Rect2(px + 1, py - 7 + dip, 5, 5), Color("ecd097"))
		draw_rect(Rect2(px, py - 9 + dip, 8, 2), Color("76503c"))
		var reach := 8 if stroke < 2 else -5
		draw_line(Vector2(px - 2, py - 2 + dip), Vector2(px + reach, py - 5 - stroke), Color("ecd097"), 2)
		if rough and index == 0:
			draw_line(Vector2(px, py - 1), Vector2(px + 4, py - 13), Color("ecd097"), 2)
		_water_rect(Rect2(px - 14, py + dip, 25, 1), Color("afd5ce"))
		_water_rect(Rect2(px + reach, py - 2 - stroke, 2, 2), Color("f6e7bc"))

func _draw_crossing() -> void:
	var progress := clampf(crossing_elapsed / crossing_duration, 0.0, 1.0)
	# An accident pauses forward motion while the current carries cargo away.
	var travel_progress := progress
	if crossing.get("mishap", false):
		travel_progress = progress * 1.4 if progress < 0.3 else (0.42 if progress < 0.6 else lerpf(0.42, 1.0, (progress - 0.6) / 0.4))
	var x := roundi(lerpf(-40, 420, travel_progress))
	var method: String = crossing.method
	var water := Color("927e62") if method == "ferry" else Color("3d7f99")
	draw_rect(Rect2(0, 0, 432, 75), Color("8db8c3"))
	draw_rect(Rect2(0, 64, 432, 14), Color("425e3b"))
	draw_rect(Rect2(0, 78, 432, 72), water)
	draw_colored_polygon(PackedVector2Array(NEAR_BANK), Color("ecd097"))
	draw_colored_polygon(PackedVector2Array(FAR_BANK), Color("8d9b53"))
	for i in range(30):
		var ripple_x := posmod(i * 43 - int(crossing_elapsed * 18), 432)
		_water_rect(Rect2(ripple_x, 86 + (i * 17) % 60, 5 + i % 8, 1), Color("afd5ce"))
	var bob := roundi(sin(progress * TAU * 3.0) * 2)
	var rough: bool = crossing.get("mishap", false) and progress > 0.4 and progress < 0.75
	if rough:
		bob += 7
	if vehicle == "foot":
		if method == "ferry":
			for y in [126, 133]:
				draw_rect(Rect2(x - 9, y, 115, 4), Color("45372f"))
			draw_rect(Rect2(x - 12, 119, 121, 8), Color("c18d4d"))
			for plank in range(0, 121, 9):
				draw_rect(Rect2(x - 12 + plank, 119, 1, 8), Color("ecd097"))
			_draw_walkers(Vector2(x + 3, 119), false)
		else:
			_draw_swimming_party(x, rough)
	elif method == "ferry":
		# Wooden platform supported by two dugout-like hulls; wheels stay aboard.
		for y in [126, 133]:
			draw_rect(Rect2(x - 9, y, 115, 4), Color("45372f"))
		draw_rect(Rect2(x - 12, 119, 121, 11), Color("c18d4d"))
		for plank in range(0, 121, 9):
			draw_rect(Rect2(x - 12 + plank, 119, 1, 11), Color("ecd097"))
		draw_texture_rect_region(WAGON, Rect2(x, 65, 96, 64), Rect2(0, 0, 96, 64))
		draw_rect(Rect2(x + 98, 98, 5, 5), Color("ecd097"))
		draw_rect(Rect2(x + 96, 96, 9, 2), Color("45372f"))
		draw_rect(Rect2(x + 98, 103, 5, 13), Color("37688e"))
		draw_line(Vector2(x + 102, 91), Vector2(x + 117, 137), Color("76503c"), 2)
	else:
		var frame := int(crossing_elapsed * 8) % 4 if method == "ford" else 0
		draw_texture_rect_region(WAGON, Rect2(x, 64 + bob, 96, 64), Rect2(frame * 96, 0, 96, 64))
		var ox_x := x + 86 if method == "ford" else x - 52
		var ox_y := 100 if method == "ford" else 103
		draw_texture_rect_region(OXEN, Rect2(ox_x, ox_y, 48, 32), Rect2((int(crossing_elapsed * 8) % 4) * 48, 0, 48, 32))
		if method == "ford":
			draw_line(Vector2(x + 83, 111), Vector2(ox_x + 14, 114), Color("76503c"), 1)
		# Floating wagon is unhitched; livestock move separately in the water.
		var waterline := 119 if method == "ford" else 111 + bob
		_water_rect(Rect2(x - 2, waterline, 98, 30), water)
		if method == "float":
			_water_rect(Rect2(ox_x, 126, 48, 24), water)
			_water_rect(Rect2(ox_x + 8, 125, 29, 1), Color("afd5ce"))
		for i in range(5):
			_water_rect(Rect2(x + i * 19 - 4, waterline + 2 + i % 2, 13, 1), Color("afd5ce"))
	if rough:
		for i in range(7):
			_water_rect(Rect2(x + 10 + i * 12, 101 - (i % 3) * 5, 2, 4), Color("f6e7bc"))
	if crossing.get("mishap", false) and progress >= 0.35 and progress < 0.85:
		# Original pixel cargo boxes drift downstream, then disappear in the water.
		var drift := (progress - 0.35) / 0.5
		for i in range(3):
			var crate_x := roundi(158 + drift * 120 + i * 17)
			var crate_y := roundi(117 + drift * 21 + i * 3)
			_water_rect(Rect2(crate_x, crate_y, 9, 7), Color("76503c"))
			_water_rect(Rect2(crate_x + 1, crate_y + 1, 7, 4), Color("c18d4d"))
			_water_rect(Rect2(crate_x - 4, crate_y + 7, 14, 1), Color("afd5ce"))
