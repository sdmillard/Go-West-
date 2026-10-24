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
var map_canvas: Control
var zoom := 1.0
var pan := Vector2.ZERO
var dragging := false
var zoom_label: Label
const MAP_SIZE := Vector2(616, 288)
const MAX_ZOOM := 4.0

func _init(simulation) -> void:
	game = simulation

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	size = Vector2(640, 360)
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json"))
	for id in data.stops:
		stops[id] = project(data.stops[id])
	map_canvas = Control.new()
	map_canvas.position = ORIGIN
	map_canvas.size = MAP_SIZE
	map_canvas.clip_contents = true
	map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_canvas.draw.connect(_draw_map)
	add_child(map_canvas)
	status = Label.new()
	status.add_theme_color_override("font_color", PAPER)
	status.position = Vector2(12, 319)
	status.size = Vector2(616, 20)
	status.add_theme_font_size_override("font_size", 8)
	status.clip_text = true
	status.max_lines_visible = 1
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status)
	status.size = Vector2(616, 20)
	for spec in [["-", 12, 30, -1], ["+", 46, 30, 1], ["FIT", 80, 42, 0], ["PARTY", 126, 60, 2], ["CACHE",190,52,3]]:
		var button := Button.new()
		button.text = spec[0]
		button.position = Vector2(spec[1], 340)
		button.size = Vector2(spec[2], 18)
		button.add_theme_font_size_override("font_size", 8)
		var action: int = spec[3]
		button.pressed.connect(func():
			if action == 0: reset_view()
			elif action == 2: focus_wagon()
			elif action == 3: focus_cache()
			else: set_zoom(zoom + action, ORIGIN + MAP_SIZE / 2))
		add_child(button)
		button.size = Vector2(spec[2], 18)
	zoom_label = Label.new()
	zoom_label.position = Vector2(250, 343)
	zoom_label.add_theme_font_size_override("font_size", 8)
	zoom_label.add_theme_color_override("font_color", PAPER)
	zoom_label.text = "1X"
	add_child(zoom_label)
	var hint := Label.new()
	hint.add_theme_color_override("font_color", PAPER)
	hint.text = "SCROLL TO ZOOM / DRAG TO PAN"
	hint.position = Vector2(282, 343)
	hint.add_theme_font_size_override("font_size", 8)
	add_child(hint)
	close_button = Button.new()
	close_button.text = "X"
	close_button.tooltip_text="Close map (Escape)"
	close_button.position = Vector2(618, 6)
	close_button.size = Vector2(14, 14)
	close_button.add_theme_font_size_override("font_size", 8)
	for state in ["normal","hover","pressed","focus"]:close_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	close_button.pressed.connect(close)
	add_child(close_button)
	close_button.size = Vector2(14, 14)
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
	if game.Direction.heading(game)=="east" and j.on_road:where="%d miles east toward %s" % [s.leg_miles,game.route.nodes[s.landmark].name]
	status.text = ("Day %d  -  guide mile %d  -  %s  -  %s" % [s.day,s.miles,game.Direction.heading(game),where]).to_upper()
	status.tooltip_text = status.text
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	show()
	queue_redraw()

func close() -> void:
	dragging = false
	hide()
	closed.emit()

func _process(delta: float) -> void:
	if visible:
		blink = fmod(blink + delta, 1.0)
		map_canvas.queue_redraw()

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
				map_canvas.draw_rect(Rect2(p - Vector2(width / 2, width / 2), Vector2(width, width)), color)
			count += 1

func text(at: Vector2, value: String, color: Color = LABEL) -> void:
	var y := at.y
	for line in value.split("\n"):
		var width := PIXEL_FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var x := clampf(roundf(at.x - width / 2.0), 5.0, data.projection.width - width - 5.0)
		map_canvas.draw_string(PIXEL_FONT, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
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
	var box := Rect2(Vector2(x, y), Vector2(width, 11))
	map_canvas.draw_rect(box, PAPER)
	map_canvas.draw_rect(box, INK, false, 1.0)
	map_canvas.draw_string(PIXEL_FONT, box.position + Vector2(3, 9), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)

func _draw() -> void:
	if data.is_empty() or game == null:
		return
	draw_rect(Rect2(0, 0, 640, 360), Color("302b2c"))
	for y in range(0, 360, 12):
		draw_rect(Rect2(0, y, 640, 11), Color("45372f" if y % 24 == 0 else "4e3c31"))
	draw_string(PIXEL_FONT, Vector2(14, 21), "THE ROUTE TO OREGON, 1848", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, PAPER)
	# Legend, top right: the red road taken, the dotted roads not (yet) taken.
	draw_rect(Rect2(428, 15, 12, 2), JOURNEY)
	draw_string(PIXEL_FONT, Vector2(444, 20), "YOUR ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, PAPER)
	for x in range(512, 524, 2):
		draw_rect(Rect2(x, 15, 1, 1), PAPER)
	draw_string(PIXEL_FONT, Vector2(528, 20), "OTHER ROADS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, PAPER)

func _draw_map() -> void:
	if data.is_empty(): return
	map_canvas.draw_set_transform(pan, 0.0, Vector2.ONE * zoom)
	map_canvas.draw_texture(MAP_ART, Vector2.ZERO)
	for label in data.labels:
		text(project(label.at), label.text)
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
	if game.state.has("trail_history"):
		for key in game.state.trail_history:
			var from: String=key.get_slice(">",0)
			var to: String=key.get_slice(">",1)
			var edge: Dictionary=game.route.edge_between(from,to)
			trace(part_of(road(from,to),float(game.state.trail_history[key])/float(edge.miles)),JOURNEY,2)
	for id in stops:
		if not game.route.nodes.has(id):
			continue
		var p: Vector2 = stops[id]
		var kind: String = game.route.nodes[id].kind
		var visited: bool = id in path
		var r := 2.0 if kind in ["fort", "town", "destination"] else 1.0
		map_canvas.draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2 + 1, r * 2 + 1)), INK)
		map_canvas.draw_rect(Rect2(p - Vector2(r - 1, r - 1), Vector2(r * 2 - 1, r * 2 - 1)), JOURNEY if visited else PAPER)
	tag(stops["independence"], "INDEPENDENCE", "below")
	tag(stops["oregon_city"], "OREGON CITY", "left")
	var cache_at: Variant=cache_point()
	if cache_at is Vector2:
		map_canvas.draw_rect(Rect2(cache_at-Vector2(3,3),Vector2(7,5)),Color("e2ab4c"))
		map_canvas.draw_rect(Rect2(cache_at-Vector2(3,3),Vector2(7,5)),INK,false,1.0)
		tag(cache_at,"WAGON CACHE","left" if cache_at.distance_to(stops["independence"])<25 else "below")

	var marked: Array=[]
	for trip in game.field_outings.record.trips:
		var point: Variant=outing_point(trip.origin)
		if not point is Vector2 or point in marked:continue
		marked.append(point)
		map_canvas.draw_rect(Rect2(point-Vector2(2,2),Vector2(5,5)),Color("9d78aa"))
		map_canvas.draw_rect(Rect2(point-Vector2(2,2),Vector2(5,5)),INK,false,1.0)
		tag(point,"HUNTERS' CAMP","above")
	# The wagon: a small covered wagon standing on the party's spot, with a blinking ring.
	var here: Vector2 = (j.here).round()
	if blink < 0.6:
		map_canvas.draw_arc(here + Vector2(0.5, 0.5), 5.0, 0.0, TAU, 16, PAPER, 1.0)
	var w := here + Vector2(-5, -12)
	map_canvas.draw_rect(Rect2(w + Vector2(1, 0), Vector2(8, 1)), INK)
	map_canvas.draw_rect(Rect2(w + Vector2(0, 1), Vector2(10, 4)), INK)
	map_canvas.draw_rect(Rect2(w + Vector2(2, 1), Vector2(6, 1)), PAPER)
	map_canvas.draw_rect(Rect2(w + Vector2(1, 2), Vector2(8, 3)), PAPER)
	map_canvas.draw_rect(Rect2(w + Vector2(0, 5), Vector2(10, 2)), Color("76503c"))
	map_canvas.draw_rect(Rect2(w + Vector2(1, 7), Vector2(2, 2)), INK)
	map_canvas.draw_rect(Rect2(w + Vector2(7, 7), Vector2(2, 2)), INK)
	map_canvas.draw_rect(Rect2(here + Vector2(0, -3), Vector2(1, 3)), INK)
	tag(j.here, "YOU ARE HERE", "above", JOURNEY_DARK)

func _get_tooltip(at: Vector2) -> String:
	if status != null and status.get_rect().has_point(at): return status.text
	if data.is_empty() or not Rect2(ORIGIN, MAP_SIZE).has_point(at):
		return ""
	at = screen_to_map(at)
	var cache_at: Variant=cache_point()
	if cache_at is Vector2 and cache_at.distance_to(at)<7.0/zoom:return "Abandoned wagon · guide mile %d. Travel there to inspect it." % game.wagon_cache.mile
	var names: Array[String]=[]
	for trip in game.field_outings.record.trips:
		var point: Variant=outing_point(trip.origin)
		if point is Vector2 and point.distance_to(at)<7.0/zoom:names.append("%s: %s; expected day %d. Departure camp at mile %d." % [game.party_health.members[trip.member].name,trip.stage,trip.due,trip.mile])
	if not names.is_empty():return "\n".join(names)+" Travel here and use Camp > Field trips to look for stranded hunters."
	var best := ""
	var nearest := 6.0 / zoom
	for id in stops:
		if game.route.nodes.has(id) and stops[id].distance_to(at) < nearest:
			nearest = stops[id].distance_to(at)
			best = id
	if best == "":
		return ""
	var node: Dictionary = game.route.nodes[best]
	var notes := ""
	if best in game.travelled_path():
		notes = "\nYou passed here." if best != game.state.landmark else "\nYou are here."
	return node.name + notes


func screen_to_map(at: Vector2) -> Vector2:
	return (at - ORIGIN - pan) / zoom

func map_to_screen(at: Vector2) -> Vector2:
	return ORIGIN + pan + at * zoom

func clamp_pan() -> void:
	pan = pan.clamp(MAP_SIZE - MAP_SIZE * zoom, Vector2.ZERO).round()
	map_canvas.queue_redraw()

func set_zoom(value: float, anchor: Vector2) -> void:
	var point := screen_to_map(anchor)
	zoom = clampf(roundf(value), 1.0, MAX_ZOOM)
	pan = anchor - ORIGIN - point * zoom
	clamp_pan()
	zoom_label.text = "%dX" % int(zoom)

func reset_view() -> void:
	set_zoom(1.0, ORIGIN + MAP_SIZE / 2)

func focus_wagon() -> void:
	set_zoom(maxf(2.0, zoom), ORIGIN + MAP_SIZE / 2)
	pan = MAP_SIZE / 2 - journey().here * zoom
	clamp_pan()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed and Rect2(ORIGIN, MAP_SIZE).has_point(event.position)
		elif event.pressed and Rect2(ORIGIN, MAP_SIZE).has_point(event.position):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				set_zoom(zoom + 1, event.position)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				set_zoom(zoom - 1, event.position)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		pan += event.relative
		clamp_pan()
		accept_event()

func cache_point() -> Variant:
	var at: Dictionary=game.Direction.cache_position(game)
	if at.is_empty() or not stops.has(at.from) or not stops.has(at.to):return null
	var edge: Dictionary=game.route.edge_between(at.from,at.to)
	return part_of(road(at.from,at.to),float(at.offset)/float(edge.miles))[-1]

func focus_cache() -> void:
	var at: Variant=cache_point()
	if not at is Vector2:return
	pan=MAP_SIZE/2-at*zoom
	clamp_pan()

func outing_point(at: Dictionary) -> Variant:
	if not stops.has(at.from) or not stops.has(at.to):return null
	if at.from==at.to:return stops[at.from]
	var edge: Dictionary=game.route.edge_between(at.from,at.to)
	if edge.is_empty():return null
	return part_of(road(at.from,at.to),float(at.offset)/float(edge.miles))[-1]
