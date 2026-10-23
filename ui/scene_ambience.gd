extends RefCounted
## Looping life laid over the still location pictures: chimney and cook-fire smoke, flags,
## sparks, glints on open water and the odd bird. Presentation only; nothing here touches the
## simulation. Positions come from data/scene_ambience.json.
const SMOKE = preload("res://art/pixels/ambient_smoke.png") # 12x24 frames, source at (6, 23)
const FLAG = preload("res://art/pixels/ambient_flag.png") # 14x8 frames; rows HBC ensign, US flag
const BIRD = preload("res://art/pixels/ambient_bird.png") # 7x5 frames
const FRAMES := 8
const WATER := [Color("37688e"), Color("4a7fa6"), Color("fff4d4")]
var places: Dictionary = {}
var no_birds: Array = []
var glints: Dictionary = {} # scene id -> PackedVector2Array of open-water pixels that may sparkle

func _init() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/scene_ambience.json"))
	if data is Dictionary:
		places = data.get("scenes", {})
		no_birds = data.get("no_birds", [])

func draw(canvas: CanvasItem, id: String, texture: Texture2D, time: float) -> void:
	var place: Dictionary = places.get(id, {})
	for i in range(_glints(id, texture).size()):
		# Each glint winks on for a moment at its own rhythm.
		var point: Vector2 = glints[id][i]
		var phase := fposmod(time * (0.35 + float(i % 7) * 0.06) + float(i) * 0.618, 1.0)
		if phase < 0.12:
			canvas.draw_rect(Rect2(point, Vector2(2 if phase < 0.06 else 1, 1)), Color("fff4d4"))
	for point in place.get("smoke", []):
		var frame := int(time * 7.0 + point[0]) % FRAMES
		canvas.draw_texture_rect_region(SMOKE, Rect2(point[0] - 6, point[1] - 23, 12, 24), Rect2(frame * 12, 0, 12, 24))
	for point in place.get("sparks", []):
		for k in range(4):
			var age := fposmod(time * 0.9 + k * 0.27, 1.0)
			var x := float(point[0]) + sin(time * 3.0 + k * 2.0) * 3.0
			canvas.draw_rect(Rect2(roundf(x), roundf(point[1] - age * 16.0), 1, 1), Color("ddb461") if age < 0.5 else Color("9e3f33"))
	for point in place.get("flag", []):
		var frame := int(time * 9.0) % FRAMES
		canvas.draw_texture_rect_region(FLAG, Rect2(point[0], point[1], 14, 8), Rect2(frame * 14, int(point[2]) * 8, 14, 8))
	if id not in no_birds:
		# Now and then a pair of birds crosses the sky.
		var cycle := fposmod(time, 26.0)
		if cycle < 18.0:
			for k in range(2):
				var x := -10.0 + cycle * 26.0 - k * 11.0
				var y := 22.0 + k * 4.0 + sin(time * 0.8 + k) * 3.0
				var frame := int(time * 10.0 + k * 3) % FRAMES
				canvas.draw_texture_rect_region(BIRD, Rect2(roundf(x), roundf(y), 7, 5), Rect2(frame * 7, 0, 7, 5))

func _glints(id: String, texture: Texture2D) -> PackedVector2Array:
	# Open water: pixels below the horizon inside a 5x5 block of water colours, sampled sparsely,
	# so wagon beds and thin ribbons of creek stay still.
	if glints.has(id):
		return glints[id]
	var found := PackedVector2Array()
	var image := texture.get_image()
	if image != null:
		if image.is_compressed():
			image.decompress()
		var w := image.get_width()
		var h := image.get_height()
		for y in range(int(h * 0.55), h - 2, 3):
			for x in range(2, w - 2, 5):
				if (x * 7 + y * 13) % 11 != 0:
					continue
				var open := true
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if not _is_water(image.get_pixel(x + dx, y + dy)):
							open = false
				if open:
					found.append(Vector2(x, y))
	glints[id] = found
	return found

func _is_water(color: Color) -> bool:
	for water in WATER:
		if color.is_equal_approx(water):
			return true
	return false
