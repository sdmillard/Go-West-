extends Control
## The trail map: every road of the route over a map of the West in 1848, the roads the party
## has taken in red, and the wagon where it stands now. Stops sit at their real latitude and
## longitude (data/map.json), projected the same way as the picture (art/aseprite/scenes/trail_map.lua).
signal closed
const MAP_ART = preload("res://art/pixels/trail_map.png")
const PIXEL_FONT = preload("res://art/pixels/trail_font.fnt")
const ORIGIN := Vector2(12, 30) # top-left of the map picture on the screen
const INK := Color("302b2c")
const ROAD := Color("45372f")
const JOURNEY := Color("c8302a")
const JOURNEY_DARK := Color("7a1f1a")
const LABEL := Color("45372f")
const PAPER := Color("f6e7bc")
var game
var data: Dictionary = {}
var stops: Dictionary = {} # id -> Vector2, pixel position on the map picture
var roads: Dictionary = {} # "from>to" -> PackedVector2Array along the road
var status: Label
var close_button: Button
var blink := 0.0

func _init(simulation) -> void:
	game = simulation

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	size = Vector2(640, 360)
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json"))
	for id in data.stops:
		stops[id] = project(data.stops[id])
	status = Label.new()
	status.add_theme_color_override("font_color", PAPER)
	status.position = Vector2(14, 325)
	status.size = Vector2(500, 24)
	add_child(status)
	close_button = Button.new()
	close_button.text = "BACK TO THE TRAIL"
	close_button.position = Vector2(500, 327)
	close_button.size = Vector2(128, 20)
	close_button.pressed.connect(close)
	add_child(close_button)
	tooltip_text = " "

## Latitude/longitude pair to a pixel on the map picture.
func project(at: Array) -> Vector2:
	var p: Dictionary = data.projection
	var sx: float = float(p.width) / (float(p.east) - float(p.west))
	var sy: float = sx / cos(deg_to_rad(float(p.parallel)))
	return Vector2(round((float(at[1]) - float(p.west)) * sx), round((float(p.north) - float(at[0])) * sy))

## The road between two stops as map pixels, bent along its waypoints.
func road(from: String, to: String) -> PackedVector2Array:
	var key := from + ">" + to
	if not roads.has(key):
		var points := PackedVector2Array([stops[from]])
		for at in data.waypoints.get(key, []):
			points.append(project(at))
		points.append(stops[to])
		roads[key] = points
	return roads[key]

## The first `fraction` of a road, by length along it.
static func part_of(points: PackedVector2Array, fraction: float) -> PackedVector2Array:
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	var left := clampf(fraction, 0.0, 1.0) * total
	var out := PackedVector2Array([points[0]])
	for i in range(points.size() - 1):
		var step := points[i].distance_to(points[i + 1])
		if left <= step:
			out.append(points[i].lerp(points[i + 1], left / step if step > 0.0 else 0.0))
			return out
		left -= step
		out.append(points[i + 1])
	return out

## Where the party is on the map now, and the stops and part-road it has covered.
func journey() -> Dictionary:
	var s: Dictionary = game.state
	var path: Array = game.travelled_path()
	var here: Vector2 = stops.get(s.landmark, stops[game.route.start])
	var partial := PackedVector2Array()
	var on_road: bool = s.next_landmark != "" and s.next_landmark != s.landmark and stops.has(s.next_landmark) and int(s.leg_length) > 0
	if on_road:
		partial = part_of(road(s.landmark, s.next_landmark), float(s.leg_miles) / float(s.leg_length))
		here = partial[-1]
	return {"path": path, "partial": partial, "here": here, "on_road": on_road}

func open() -> void:
	roads.clear()
	var s: Dictionary = game.state
	var where: String = game.route.nodes[s.landmark].name
	var j := journey()
	if j.on_road:
		where = "%d of %d miles from %s toward %s" % [s.leg_miles, s.leg_length, where, game.route.nodes[s.next_landmark].name]
	elif s.status == "outfitting":
		where = "outfitting at " + where
	else:
		where = "at " + where
	status.text = ("Day %d  -  %d guide miles traveled  -  %s" % [s.day, s.miles, where]).to_upper()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	show()
	queue_redraw()

func close() -> void:
	hide()
	closed.emit()

func _process(delta: float) -> void:
	if visible:
		blink = fmod(blink + delta, 1.0)
		queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

## A pixel line along a polyline: every `gap`-th pixel for dotted roads, `width` square pen.
func trace(points: PackedVector2Array, color: Color, width: int = 1, gap: int = 1) -> void:
	var count := 0
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
		for t in range(steps + (1 if i == points.size() - 2 else 0)):
			var p := a.lerp(b, float(t) / maxf(1.0, float(steps))).round()
			if count % gap == 0:
				draw_rect(Rect2(ORIGIN + p - Vector2(width / 2, width / 2), Vector2(width, width)), color)
			count += 1

func text(at: Vector2, value: String, color: Color = LABEL) -> void:
	var y := at.y
	for line in value.split("\n"):
		var width := PIXEL_FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var x := clampf(roundf(at.x - width / 2.0), ORIGIN.x + 5.0, ORIGIN.x + data.projection.width - width - 5.0)
		draw_string(PIXEL_FONT, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
		y += 9

## A name on a small paper tag beside a map point (side: "above", "below" or "left"), kept inside the map.
func tag(at: Vector2, value: String, side: String, ink: Color = INK) -> void:
	var width := PIXEL_FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 6
	var x := roundf(at.x - width / 2.0)
	var y := at.y + 6.0
	if side == "above":
		y = at.y - 27.0
	elif side == "left":
		x = at.x - width - 4.0
		y = at.y - 5.0
	x = clampf(x, 4.0, data.projection.width - width - 4.0)
	y = clampf(y, 4.0, data.projection.height - 15.0)
	var box := Rect2(ORIGIN + Vector2(x, y), Vector2(width, 11))
	draw_rect(box, PAPER)
	draw_rect(box, INK, false, 1.0)
	draw_string(PIXEL_FONT, box.position + Vector2(3, 9), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)

func _draw() -> void:
	if data.is_empty() or game == null:
		return
	draw_rect(Rect2(0, 0, 640, 360), Color("302b2c"))
	for y in range(0, 360, 12):
		draw_rect(Rect2(0, y, 640, 11), Color("45372f" if y % 24 == 0 else "4e3c31"))
	draw_string(PIXEL_FONT, Vector2(14, 21), "THE ROUTE TO OREGON, 1848", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PAPER)
	# Legend, top right: the red road taken, the dotted roads not (yet) taken.
	draw_rect(Rect2(452, 15, 12, 2), JOURNEY)
	draw_string(PIXEL_FONT, Vector2(468, 20), "YOUR ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, PAPER)
	for x in range(536, 548, 2):
		draw_rect(Rect2(x, 15, 1, 1), PAPER)
	draw_string(PIXEL_FONT, Vector2(552, 20), "OTHER ROADS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, PAPER)
	draw_texture(MAP_ART, ORIGIN)
	for label in data.labels:
		text(project(label.at) + ORIGIN, label.text)
	# Every road on the route, dotted; then the journey in red over it.
	for id in game.route.nodes:
		for edge in game.route.nodes[id].next:
			trace(road(id, edge.to), ROAD, 1, 2)
	var j := journey()
	var path: Array = j.path
	for i in range(path.size() - 1):
		trace(road(path[i], path[i + 1]), JOURNEY, 2)
	if j.on_road:
		trace(j.partial, JOURNEY, 2)
	for id in stops:
		if not game.route.nodes.has(id):
			continue
		var p: Vector2 = ORIGIN + stops[id]
		var kind: String = game.route.nodes[id].kind
		var visited: bool = id in path
		var r := 2.0 if kind in ["fort", "town", "destination"] else 1.0
		draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2 + 1, r * 2 + 1)), INK)
		draw_rect(Rect2(p - Vector2(r - 1, r - 1), Vector2(r * 2 - 1, r * 2 - 1)), JOURNEY if visited else PAPER)
	tag(stops["independence"], "INDEPENDENCE", "below")
	tag(stops["oregon_city"], "OREGON CITY", "left")
	# The wagon: a small covered wagon standing on the party's spot, with a blinking ring.
	var here: Vector2 = (ORIGIN + j.here).round()
	if blink < 0.6:
		draw_arc(here + Vector2(0.5, 0.5), 5.0, 0.0, TAU, 16, PAPER, 1.0)
	var w := here + Vector2(-5, -12)
	draw_rect(Rect2(w + Vector2(1, 0), Vector2(8, 1)), INK)
	draw_rect(Rect2(w + Vector2(0, 1), Vector2(10, 4)), INK)
	draw_rect(Rect2(w + Vector2(2, 1), Vector2(6, 1)), PAPER)
	draw_rect(Rect2(w + Vector2(1, 2), Vector2(8, 3)), PAPER)
	draw_rect(Rect2(w + Vector2(0, 5), Vector2(10, 2)), Color("76503c"))
	draw_rect(Rect2(w + Vector2(1, 7), Vector2(2, 2)), INK)
	draw_rect(Rect2(w + Vector2(7, 7), Vector2(2, 2)), INK)
	draw_rect(Rect2(here + Vector2(0, -3), Vector2(1, 3)), INK)
	tag(j.here, "YOU ARE HERE", "above", JOURNEY_DARK)

func _get_tooltip(at: Vector2) -> String:
	if data.is_empty():
		return ""
	var best := ""
	var nearest := 6.0
	for id in stops:
		if game.route.nodes.has(id) and (ORIGIN + stops[id]).distance_to(at) < nearest:
			nearest = (ORIGIN + stops[id]).distance_to(at)
			best = id
	if best == "":
		return ""
	var node: Dictionary = game.route.nodes[best]
	var notes := ""
	if best in game.travelled_path():
		notes = "\nYou passed here." if best != game.state.landmark else "\nYou are here."
	return node.name + notes
