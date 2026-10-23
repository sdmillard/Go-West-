extends Control
## Composites original native-resolution pixel assets. All motion lands on whole pixels.
const Palette=preload("res://ui/traveler_palette.gd")
var traveler_profiles: Array = []
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
# Weather and event overlays (art/aseprite/scenes/weather.lua).
const STORM_CLOUDS = preload("res://art/pixels/storm_clouds.png") # 432x56, tiles sideways
const BOLT = preload("res://art/pixels/weather_bolt.png") # three 32x96 bolts
const DUST_DEVIL = preload("res://art/pixels/dust_devil.png") # four 16x40 frames, ground point (8, 39)
const TRAIL_DUST = preload("res://art/pixels/trail_dust.png") # three 16x12 puffs
const STAMPEDE_OX = preload("res://art/pixels/stampede_ox.png") # four 26x16 frames, rump at (0, 15)
const FLOTSAM = preload("res://art/pixels/flotsam.png") # two 24x12 pieces, water line at y 9
const RAIN_CLOUDS = preload("res://art/pixels/rain_clouds.png") # 432x56, tiles sideways
const RAIN_SPLASH = preload("res://art/pixels/rain_splash.png") # four 8x4 frames
const FOG_BANK = preload("res://art/pixels/fog_bank.png") # 432x40, tiles sideways
const SNOW_SQUALL = preload("res://art/pixels/snow_squall.png") # 432x150, tiles both ways
# The crossing is seen from above at three-quarters with no sky, so its weather lies on the ground.
const CROSS_RIPPLE = preload("res://art/pixels/cross_ripple.png") # four 12x6 frames, flat on the water
const CLOUD_SHADOW = preload("res://art/pixels/cloud_shadow.png") # two 128x64 shadows
const MIST_WISP = preload("res://art/pixels/mist_wisp.png") # two 128x48 wisps
const NEAR_BANK = [Vector2(0, 178), Vector2(25, 189), Vector2(50, 204), Vector2(75, 212), Vector2(100, 220), Vector2(125, 237), Vector2(150, 248), Vector2(175, 269), Vector2(200, 275), Vector2(225, 288), Vector2(250, 295), Vector2(260, 300), Vector2(0, 300)]
const FAR_BANK = [Vector2(330, 0), Vector2(360, 21), Vector2(390, 26), Vector2(420, 43), Vector2(450, 62), Vector2(480, 77), Vector2(510, 90), Vector2(540, 99), Vector2(570, 125), Vector2(600, 136), Vector2(630, 150), Vector2(660, 161), Vector2(690, 182), Vector2(720, 200), Vector2(720, 0)]
signal crossing_finished
var scenes = preload("res://ui/location_scenes.gd").new()
var ambience = preload("res://ui/scene_ambience.gd").new()
var scene_id := ""
var miles := 0
var vehicle := "wagon"
var herded_oxen := 0
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
		_draw_crossing_sky()
		return
	if not scene_id.is_empty():
		draw_texture(scenes.texture_for(scene_id), Vector2.ZERO)
		ambience.draw(self, scene_id, scenes.texture_for(scene_id), clock_time)
		if vehicle=="foot":
			_draw_herd(false)
			_draw_walkers(Vector2(140,135),false)
		_draw_weather()
		return # Parked wagons/people are composed into each arrival illustration.
	# Parallax: each layer of the backdrop slides at its own speed, nearest fastest, and the
	# clouds also drift on the wind whether or not the party is moving.
	var set_name: String = "river" if river_scene else ("travel_" + terrain if terrain in ["mountains", "desert", "forest"] else "prairie")
	var layers: Array = PARALLAX[set_name]
	for layer in layers:
		if layer[0] == "clouds" and weather_id in ["thunderstorm", "hail", "rain", "heavy_rain", "blizzard", "fog"]:
			continue # fair-weather clouds are lost under the overcast
		var texture: Texture2D = _layer_texture(set_name + "_" + layer[0])
		var drift: float = clock_time * 1.5 if layer[0] == "clouds" else 0.0
		_tile(texture, 0, posmod(int(scroll_distance * layer[1] + drift), 432))
	if set_name in ["prairie", "river"]:
		_tile(HORIZON, 65, int(scroll_distance / 7.0) % 432)
		_tile(GROUND, 100, int(scroll_distance) % 432)
	_draw_fog_banks()
	var frame := int(clock_time * FPS) % FRAMES if scrolling or motion > 0 else 0
	var bob := -1 if frame % 4 >= 2 else 0
	var shift := int(sin(clock_time * 3) * 3) if motion > 0 else 0
	if vehicle=="foot":
		_draw_herd(scrolling or motion>0)
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
		"stampede":
			_draw_stampede()
		"muddy_trail":
			draw_rect(Rect2(150, 130, 80, 7), Color("76503c"))
			draw_rect(Rect2(159, 132, 60, 2), Color("a16b43"))
	_draw_weather()

func _draw_herd(moving: bool) -> void:
	# A small representative herd follows the walkers; the ledger gives the exact count.
	for index in range(mini(herded_oxen,3)):
		var step:=int(clock_time*FPS+index*3)%FRAMES if moving else 0
		draw_texture_rect_region(OXEN,Rect2(25+index*31,106-(index%2)*4,48,32),Rect2(step*48,0,48,32))

func _draw_walkers(origin: Vector2,moving: bool) -> void:
	for index in range(walkers):
		var x:=origin.x+index*19
		var y:=origin.y-(index%2)*3
		var step:=int(clock_time*FPS+index*3)%FRAMES if moving else 0
		var profile: Dictionary=traveler_profiles[index] if index<traveler_profiles.size() else {"id":index}
		var row: int=int(profile.get("appearance",{}).get("outfit",index%2))
		draw_texture_rect_region(Palette.texture(WALKER,profile),Rect2(x-5,y-23,16,24),Rect2(step*16,row*24,16,24))

func _draw_weather() -> void:
	var full := Rect2(0, 0, 432, 150)
	if weather_id in ["thunderstorm", "hail"]:
		# The light goes under a thunderhead whose base drifts slowly across the top of the view.
		draw_rect(full, Color(0.13, 0.15, 0.2, 0.28))
		_tile(STORM_CLOUDS, 0, posmod(int(clock_time * 3.0), 432))
	if weather_id == "thunderstorm":
		# A strike every few seconds somewhere new: the bolt, and a double flash over everything.
		var strike := int(clock_time / 4.3)
		var into := fmod(clock_time, 4.3)
		if into < 0.22:
			if into < 0.07 or (into > 0.12 and into < 0.17):
				draw_rect(full, Color(1, 1, 0.92, 0.3))
			draw_texture_rect_region(BOLT, Rect2(30 + posmod(strike * 151, 350), 30, 32, 96), Rect2((strike % 3) * 32, 0, 32, 96))
		for index in range(70):
			var x := posmod(index * 37 - int(clock_time * 40), 432)
			var y := posmod(index * 19 + int(clock_time * 110), 150)
			draw_line(Vector2(x, y), Vector2(x - 2, y + 6), Color("8db8c3"))
	elif weather_id == "hail":
		for index in range(40):
			var x := posmod(index * 37 - int(clock_time * 8), 432)
			var y := posmod(index * 23 + int(clock_time * 120), 150)
			draw_rect(Rect2(x, y, 2, 2), Color("fff4d4"))
			draw_rect(Rect2(x + 1, y + 1, 1, 1), Color("b7d2c6"))
		if crossing.is_empty() and scene_id.is_empty():
			# Stones lying white on the road and grass, a few bouncing.
			for index in range(70):
				var gx := posmod(index * 61 + int(scroll_distance), 432)
				var gy := 112 + posmod(index * 29, 38)
				var hop := 2 if posmod(index * 7 + int(clock_time * 12), 23) == 0 else 0
				draw_rect(Rect2(gx, gy - hop, 1 + index % 2, 1), Color("fff4d4"))
	elif weather_id == "heat":
		# A white-hot sky, the horizon swimming in mirage, and a dust devil wandering the flats.
		draw_rect(full, Color(1, 0.88, 0.6, 0.1))
		var horizon := 66 if scene_id.is_empty() else 84
		for row in range(8):
			var y := horizon + row * 2
			var wave := int(sin(clock_time * 2.3 + row * 1.7) * 6)
			for band in range(0, 432, 36):
				draw_rect(Rect2(band + posmod(wave + row * 11, 36), y, 10 + row % 3 * 4, 1), Color(1, 0.95, 0.78, 0.35))
		if crossing.is_empty():
			var devil_x := posmod(int(clock_time * 7.0) + 300, 560) - 64
			var sway := int(sin(clock_time * 1.3) * 4)
			draw_texture_rect_region(DUST_DEVIL, Rect2(devil_x - 8, 118 + sway - 39, 16, 40), Rect2((int(clock_time * 10) % 4) * 16, 0, 16, 40))
	elif weather_id in ["rain", "heavy_rain"]:
		# A low grey overcast, rain on the wind, and drops splashing on the ground.
		var heavy := weather_id == "heavy_rain"
		draw_rect(full, Color(0.2, 0.24, 0.28, 0.26 if heavy else 0.16))
		draw_rect(Rect2(0, 0, 432, 90), Color(0.5, 0.55, 0.58, 0.4)) # the sky goes grey
		_tile(RAIN_CLOUDS, 0, posmod(int(clock_time * 2.0), 432))
		var slant := 2 if heavy else 1
		for index in range(80 if heavy else 40):
			var x := posmod(index * 37 - int(clock_time * 20.0 * slant), 432)
			var y := posmod(index * 19 + int(clock_time * 95), 150)
			draw_line(Vector2(x, y), Vector2(x - slant, y + 5 + slant), Color(0.55, 0.72, 0.76, 0.85))
		for index in range(24 if heavy else 12):
			var phase := int(clock_time * 12.0) + index * 5
			var spot := Vector2(posmod(index * 71 + (phase / 4) * 53, 432), 112 + posmod(index * 23 + (phase / 4) * 17, 36))
			draw_texture_rect_region(RAIN_SPLASH, Rect2(spot, Vector2(8, 4)), Rect2((phase % 4) * 8, 0, 8, 4))
	elif weather_id == "blizzard":
		# Whiteout: snow driven sideways in two depths, the far ground lost behind it.
		draw_rect(full, Color(0.84, 0.87, 0.9, 0.5))
		for depth in range(2):
			var speed := 90.0 if depth == 0 else 150.0
			var ox := posmod(int(clock_time * speed) + depth * 200, 432)
			var oy := posmod(int(clock_time * speed * 0.25) + depth * 70, 150)
			for tx in [-1, 0]:
				for ty in [-1, 0]:
					draw_texture(SNOW_SQUALL, Vector2(ox + tx * 432, oy + ty * 150))
	elif weather_id == "fog":
		# A pale wash and two banks of mist drifting at their own pace.
		draw_rect(full, Color(0.8, 0.83, 0.78, 0.3))
		if not scene_id.is_empty() or not crossing.is_empty():
			_draw_fog_banks() # on the road the banks lie behind the wagon instead

func _draw_fog_banks() -> void:
	if weather_id == "fog":
		_tile(FOG_BANK, 44, posmod(int(clock_time * 4.0), 432))
		_tile(FOG_BANK, 70, posmod(int(clock_time * 7.0) + 150, 432))

func _draw_crossing_weather(cam: Vector2) -> void:
	# World coordinates: what the weather leaves on the ground and water of the crossing.
	if weather_id in ["rain", "heavy_rain", "thunderstorm", "hail"]:
		# Shadows of the clouds sliding over water and banks alike.
		for i in range(5):
			var at := Vector2(fposmod(clock_time * 8.0 + i * 197.0, WORLD.x + 256.0) - 128.0, i * 62.0 - 10.0).round()
			draw_texture_rect_region(CLOUD_SHADOW, Rect2(at, Vector2(128, 64)), Rect2((i % 2) * 128, 0, 128, 64), Color(1, 1, 1, 0.28))
		# Drops ring the water and splash on the banks; hailstones bounce white.
		var count: int = {"rain": 30, "heavy_rain": 60, "thunderstorm": 60, "hail": 40}[weather_id]
		for index in range(count):
			var beat := clock_time * 3.0 + index * 0.37
			var cycle := int(beat)
			var frame := int(fposmod(beat, 1.0) * 4.0)
			var spot := (cam + Vector2(posmod(index * 71 + cycle * 37, 432), posmod(index * 43 + cycle * 29, 150))).round()
			if weather_id == "hail" and not _in_water(spot):
				draw_rect(Rect2(spot.x, spot.y - (2 if frame == 1 else 0), 2, 1), Color("fff4d4"))
			elif _in_water(spot):
				draw_texture_rect_region(CROSS_RIPPLE, Rect2(spot - Vector2(6, 3), Vector2(12, 6)), Rect2(frame * 12, 0, 12, 6))
			else:
				draw_texture_rect_region(RAIN_SPLASH, Rect2(spot - Vector2(4, 3), Vector2(8, 4)), Rect2(frame * 8, 0, 8, 4))
	elif weather_id == "fog":
		# Low wisps lying on the river, drifting down it with the current.
		for i in range(12):
			var lane := Vector2(1, -2) * (i % 4 - 1.5) * 40.0
			var at := (Vector2(-110, 20) + lane + Vector2(2, 1) * fposmod(clock_time * 5.0 + i * 83.0, 460.0)).round()
			draw_texture_rect_region(MIST_WISP, Rect2(at, Vector2(128, 48)), Rect2((i % 2) * 128, 0, 128, 48), Color(1, 1, 1, 0.45))

func _draw_crossing_sky() -> void:
	# Screen coordinates: light and falling weather over the crossing. There is no sky in this
	# view, so no cloud banks, horizon mirage or dust devils.
	var full := Rect2(0, 0, 432, 150)
	match weather_id:
		"thunderstorm", "hail", "heavy_rain", "rain":
			draw_rect(full, Color(0.13, 0.15, 0.2, {"thunderstorm": 0.3, "hail": 0.28, "heavy_rain": 0.26, "rain": 0.16}[weather_id]))
			if weather_id == "thunderstorm":
				var into := fmod(clock_time, 4.3)
				if into < 0.07 or (into > 0.12 and into < 0.17):
					draw_rect(full, Color(1, 1, 0.92, 0.3))
			var hail: bool = weather_id == "hail"
			for index in range(40 if weather_id == "rain" else 70):
				var x := posmod(index * 37 - int(clock_time * 20), 432)
				var y := posmod(index * 19 + int(clock_time * (120 if hail else 100)), 150)
				if hail:
					draw_rect(Rect2(x, y, 2, 2), Color("fff4d4"))
				else:
					draw_line(Vector2(x, y), Vector2(x - 1, y + 5), Color(0.55, 0.72, 0.76, 0.85))
		"heat":
			draw_rect(full, Color(1, 0.88, 0.6, 0.1))
		"fog":
			draw_rect(full, Color(0.8, 0.83, 0.78, 0.25))
		"blizzard":
			_draw_weather()

func _draw_stampede() -> void:
	# Two oxen broken loose and running off ahead of the wagon in their own dust.
	for i in range(2):
		var at := Vector2(318 + i * 52, 116 - i * 9)
		var frame := (int(clock_time * 14.0) + i * 2) % 4
		var bob := -1 if frame == 2 else 0
		for k in range(3):
			var puff := (int(clock_time * 8.0) + k + i) % 3
			draw_texture_rect_region(TRAIL_DUST, Rect2(at.x - 12 - k * 9, at.y - 11 - k, 16, 12), Rect2(puff * 16, 0, 16, 12))
		draw_texture_rect_region(STAMPEDE_OX, Rect2(at.x, at.y - 15 + bob, 26, 16), Rect2(frame * 26, 0, 26, 16))

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

func _draw_high_water(water: Color) -> void:
	# The river laps a few pixels up over both banks, foam at the edge, and drift rides the current.
	for y in range(WORLD.y):
		var span: Vector2i = water_spans[y]
		if span.y <= span.x:
			continue
		var lap := 12 + int(2.0 * sin(y * 0.4 + crossing_elapsed * 3.0))
		var foam := Color("f6e7bc") if (y + int(crossing_elapsed * 8.0)) % 5 == 0 else Color("afd5ce")
		if span.x > 0:
			draw_rect(Rect2(span.x - lap, y, lap, 1), water)
			draw_rect(Rect2(span.x - lap - 1, y, 1, 1), foam)
		if span.y < WORLD.x:
			draw_rect(Rect2(span.y, y, lap, 1), water)
			draw_rect(Rect2(span.y + lap, y, 1, 1), foam)
	for i in range(4):
		var along := fmod(crossing_elapsed * 22.0 + i * 70.0, 300.0)
		# Along the middle of the channel, each piece in its own lane.
		var spot := (Vector2(90, 70) + Vector2(1, -2) * (i - 1.5) * 11.0 + Vector2(2, 1) * along).round()
		var afloat := true
		for corner in [Vector2(0, 1), Vector2(23, 1), Vector2(0, 11), Vector2(23, 11)]:
			afloat = afloat and _in_water(spot + corner)
		if afloat:
			draw_texture_rect_region(FLOTSAM, Rect2(spot, Vector2(24, 12)), Rect2((i % 2) * 24, 0, 24, 12))

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
		var profile: Dictionary=traveler_profiles[index] if index<traveler_profiles.size() else {"id":index}
		var row: int=int(profile.get("appearance",{}).get("outfit",index%2))
		var step := (frame + index * 3) % FRAMES
		if lift == Vector2.ZERO and _in_water(at):
			_sprite(Palette.texture(CROSS_SWIMMER,profile), Vector2i(16, 12), Vector2i(6, 8), step, 2 if rough and index == 0 else row, at)
		else:
			_sprite(Palette.texture(CROSS_PEOPLE,profile), Vector2i(16, 20), Vector2i(8, 17), step if frame > 0 or lift == Vector2.ZERO else 0, row, at)

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
	# The Kansas runs yellow-brown with silt, matching its location picture; the others run clearer.
	var silty: bool = crossing.get("place", "") == "Kansas River"
	var water := Color("a38b64") if silty else Color("3d7f99")
	# Snowmelt high water runs fast, swollen and muddier, over the gravel at its edges.
	var high: bool = crossing.get("stage", "") == "high"
	if high:
		water = Color("8f7a58") if silty else Color("5a7c7c")
	var cam := _camera()
	draw_set_transform(-cam)
	draw_rect(Rect2(cam, Vector2(432, 150)), water)
	# The current: short streaks drifting downstream, parallel to the banks.
	for i in range(170 if high else 110):
		var drift := crossing_elapsed * (30.0 if high else 16.0)
		var sx := posmod(i * 97 + int(drift * 2.0), WORLD.x)
		var sy := posmod(i * 53 + int(drift), WORLD.y)
		var length := 2 + i % 3
		for k in range(length):
			_water_rect(Rect2(sx + k * 2, sy + k, 3, 1), Color("afd5ce") if i % 4 else Color("f6e7bc"))
	draw_texture(CROSSING, Vector2.ZERO)
	if high:
		_draw_high_water(water)
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
	_draw_crossing_weather(cam)
	draw_set_transform(Vector2.ZERO)
