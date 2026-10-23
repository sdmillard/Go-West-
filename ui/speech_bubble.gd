extends Control
## A speech bubble laid over a picture, its tail pointing at whoever is talking. Clicking the bubble dismisses it.
var panel: PanelContainer
var text: Label
var tail: Polygon2D
var edge: Line2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("fbf3dc")
	box.border_color = Color("2b1d12")
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_input_on_bubble)
	add_child(panel)
	text = Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_color_override("font_color", Color("2b1d12"))
	panel.add_child(text)
	tail = Polygon2D.new()
	tail.color = Color("fbf3dc")
	add_child(tail)
	edge = Line2D.new()
	edge.width = 1
	edge.default_color = Color("2b1d12")
	tail.add_child(edge)
	hide()

## Say something from the speaker at tip: the bubble sits above, its left edge at left, as wide as width.
func say(words: String, tip: Vector2, left: float = 12.0, width: float = 206.0) -> void:
	text.text = words
	text.custom_minimum_size = Vector2(width, 0)
	show()
	# Size the bubble to the wrapped text now; a container's cached minimum can lag a frame behind the new words.
	text.size = Vector2(width, 0)
	var margin: float = 10.0
	panel.size = Vector2(width + margin, text.get_minimum_size().y + margin)
	panel.position = Vector2(left, maxf(2.0, tip.y - 12.0 - panel.size.y))
	var base: float = panel.position.y + panel.size.y - 1.0
	tail.polygon = PackedVector2Array([Vector2(tip.x - 14, base), Vector2(tip.x - 4, base), tip])
	edge.points = PackedVector2Array([Vector2(tip.x - 14, base + 0.5), tip, Vector2(tip.x - 4, base + 0.5)])

func _input_on_bubble(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide()
