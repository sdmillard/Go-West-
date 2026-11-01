extends RefCounted
## The Onyx Sphere seen from miles off (Unhinged mode): a black ball standing on the horizon of
## the travel view and of the stop pictures while it is in view (events.json "visible_from").
## It is so far away that it never moves with the scroll, and so big that it grows from a dot
## at Fort Bridger to a dome over the Salt Lake valley.
##
## In a stop picture it is painted only over sky pixels, so the hills, trees and buildings of
## the picture stand in front of it; in the travel view it is drawn just after the sky layer and
## the scrolling layers cover its foot.

const ONYX := Color("141218")
const ONYX_HI := Color("2c2a36")
const ONYX_GLINT := Color("5e5e74")
const STORM_DK := Color("3b414c")
const STORM := Color("555d68")
const STORM_LT := Color("7b8389")
## The sky colours of the pictures (K.sky bands): the sphere shows through only these.
const SKY := ["4a7fa6", "548db3", "8db8c3", "b7d2c6", "37688e"]
## Cloud colours (K.cloud): they float in front of it, and do not count as the skyline.
const CLOUD := ["f6e7bc", "fff4d4"]

var _cache: Dictionary = {}

## Miles between two [lat, lon] points (flat-earth, fine at this scale).
static func miles_between(a: Array, b: Array) -> float:
	var lat := deg_to_rad((float(a[0]) + float(b[0])) * 0.5)
	var dy := (float(a[0]) - float(b[0])) * 69.0
	var dx := (float(a[1]) - float(b[1])) * 69.0 * cos(lat)
	return sqrt(dx * dx + dy * dy)

## How it looks from `here` when it stands at `there`: {"size", "x", "tier"}, or {} if too far.
## Westward travel runs to the right of the screen, so a sphere to the west sits right of centre,
## one behind the party sits left, one abeam stands in the middle.
static func view(here: Array, there: Array) -> Dictionary:
	var dist := maxf(4.0, miles_between(here, there))
	if dist > 260.0:
		return {}
	var size := clampi(int(2600.0 / dist), 8, 120)
	var lat := deg_to_rad(float(here[0]))
	var east := (float(there[1]) - float(here[1])) * 69.0 * cos(lat)
	var x := int(216.0 - 170.0 * clampf(east / dist, -1.0, 1.0))
	var tier := 0 if dist < 45.0 else (1 if dist < 110.0 else 2) # air between greys it
	return {"size": size, "x": x, "tier": tier}

## The sphere alone, `size` pixels across, shaded for its distance tier.
func sphere_image(size: int, tier: int) -> Image:
	var key := "s:%d:%d" % [size, tier]
	if _cache.has(key):
		return _cache[key]
	var body: Color = [ONYX, STORM_DK, STORM][tier]
	var hi: Color = [ONYX_HI, STORM, STORM_LT][tier]
	var glint: Color = [ONYX_GLINT, STORM_LT, STORM_LT][tier]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size * 0.5
	for y in size:
		for x in size:
			var nx := (x + 0.5 - r) / r
			var ny := (y + 0.5 - r) / r
			if nx * nx + ny * ny > 1.0:
				continue
			var c := body
			# the bright sky mirrored high on the upper left, the pale ground along the bottom
			var hx := nx + 0.38
			var hy := ny + 0.42
			var h := hx * hx / 0.09 + hy * hy / 0.05
			if h < 1.0:
				c = glint if h < 0.35 and size >= 16 else hi
			elif ny > 0.78 and nx * nx + ny * ny > 0.82:
				c = hi
			img.set_pixel(x, y, c)
	_cache[key] = img
	return img

## A stop picture with the sphere standing behind its land: bottom just below the skyline in
## the sphere's column, painted over sky pixels only.
func over_scene(scene_id: String, picture: Texture2D, look: Dictionary) -> Texture2D:
	var key := "%s:%d:%d:%d" % [scene_id, look.size, look.x, look.tier]
	if _cache.has(key):
		return _cache[key]
	var base: Image = picture.get_image()
	if base.is_compressed():
		base.decompress()
	var texture := ImageTexture.create_from_image(paint(base, look))
	_cache[key] = texture
	return texture

## Paint the sphere into a copy of a stop picture (see over_scene).
func paint(picture: Image, look: Dictionary) -> Image:
	var base: Image = picture.duplicate()
	base.convert(Image.FORMAT_RGBA8)
	var size: int = look.size
	var left: int = look.x - size / 2
	# the far skyline: in each column the first row that is neither sky nor cloud, and the
	# value three quarters of the way down across the picture, so a near roof or tree standing
	# up into the sky does not count as the horizon
	var tops: Array = [] # first land row of every column
	for x in base.get_width():
		tops.append(_land_top(base, x))
	var rows: Array = []
	for x in range(0, tops.size(), 4):
		rows.append(tops[x])
	rows.sort()
	var skyline: int = rows[rows.size() * 3 / 4] if not rows.is_empty() else base.get_height() / 2
	# a small sphere sitting just over a roof reads as a cupola: slide it a little along the
	# horizon to where nothing near stands up in front of it (a few degrees of bearing, no more)
	if size < 40:
		# the far land's own colour: the commonest colour where the skyline is at its usual height
		var counts: Dictionary = {}
		for x in tops.size():
			if absi(tops[x] - skyline) <= 3 and tops[x] < base.get_height():
				var k: String = base.get_pixel(x, tops[x]).to_html(false)
				counts[k] = counts.get(k, 0) + 1
		var far_land := ""
		for k in counts:
			if far_land == "" or counts[k] > counts[far_land]:
				far_land = k
		var best := 0
		var best_cost := 1 << 30
		for shift in range(-96, 97, 4):
			var cost := 0
			for x in range(left + shift - 8, left + shift + size + 8): # with a little room round it
				if x < 0 or x >= tops.size() or tops[x] < skyline - 3:
					cost += 1
				elif tops[x] < base.get_height() and base.get_pixel(x, tops[x]).to_html(false) != far_land:
					cost += 1 # a wall or roof at skyline height
			if cost < best_cost or (cost == best_cost and absi(shift) < absi(best)):
				best_cost = cost
				best = shift
		left += best
	# stand it in the deepest notch of the skyline across its width and sink it further the
	# farther off it is (the land between hides its foot), so it rises from behind the hills as a
	# dome instead of sitting on them like a ball
	var foot := skyline
	for x in range(maxi(0, left), mini(tops.size(), left + size)):
		foot = maxi(foot, tops[x])
	var sink: float = [0.25, 0.45, 0.55][look.tier]
	var top := foot + int(size * sink) - size
	var ball := sphere_image(size, look.tier)
	var haze: Color = [STORM, STORM_LT, STORM_LT][look.tier]
	for y in size:
		for x in size:
			var px := left + x
			var py := top + y
			if px < 0 or py < 0 or px >= base.get_width() or py >= base.get_height():
				continue
			var c := ball.get_pixel(x, y)
			var under := base.get_pixel(px, py)
			if c.a > 0.5 and _is_sky(under):
				# its foot fades into the pale haze band low on the sky
				base.set_pixel(px, py, haze if under.to_html(false) == "b7d2c6" else c)
	return base

## The sphere as a texture for the travel view, and where its top-left goes: its foot at
## `foot`, low enough that the layers drawn after it cover the bottom.
func for_travel(look: Dictionary, foot: int) -> Array:
	var key := "t:%d:%d" % [look.size, look.tier]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(sphere_image(look.size, look.tier))
	return [_cache[key], Vector2(look.x - look.size / 2, foot - look.size)]

## The first row of column `x` that is land: past the sky, and past any cloud with sky below it
## (a cream wall or tent is cloud-coloured too, but it has no sky under it).
static func _land_top(base: Image, x: int) -> int:
	var y := 0
	var h := base.get_height()
	while y < h:
		var c := base.get_pixel(x, y)
		if _is_sky(c):
			y += 1
			continue
		if c.to_html(false) in CLOUD:
			var end := y
			while end < h and base.get_pixel(x, end).to_html(false) in CLOUD:
				end += 1
			if end < h and _is_sky(base.get_pixel(x, end)):
				y = end
				continue
		return y
	return h

static func _is_sky(c: Color) -> bool:
	return c.a > 0.5 and c.to_html(false) in SKY
