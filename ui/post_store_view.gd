extends Panel
## A trading post's store counter: buy and sell by the lot within the post's stock and buying demand, settled as one visit.
signal settled
var game
var buys: Dictionary = {}
var sells: Dictionary = {}
var held: Dictionary = {}
var title: Label
var totals: Label
var feedback: Label
var settle_button: Button
var background: TextureRect
var rows_layer: Control
var scenes = preload("res://ui/location_scenes.gd").new()
var refreshing := false

func _init(simulation) -> void:
	game = simulation

func put(node: Control, bounds: Rect2, parent: Node = self) -> Control:
	parent.add_child(node)
	node.position = bounds.position
	node.size = bounds.size
	return node

func text(value: String, bounds: Rect2, parent: Node = self) -> Label:
	var node := Label.new()
	node.text = value
	put(node, bounds, parent)
	return node

func paper(bounds: Rect2) -> void:
	var panel := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("ecd097")
	box.border_color = Color("a16b43")
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", box)
	put(panel, bounds)

func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(622, 273)
	background = TextureRect.new()
	background.texture = scenes.texture_for("post_store")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(background, Rect2(0, 0, 622, 273))
	# The counter and keeper stay visible on the left, as in the Independence store.
	paper(Rect2(267, 0, 355, 236))
	paper(Rect2(0, 236, 622, 37))
	title = text("", Rect2(278, 6, 330, 12))
	text("GOODS", Rect2(278, 24, 150, 12))
	text("BUY", Rect2(388, 24, 90, 12))
	text("SELL", Rect2(492, 24, 90, 12))
	rows_layer = Control.new()
	put(rows_layer, Rect2(0, 0, 622, 236))
	totals = text("", Rect2(278, 204, 330, 30))
	feedback = text("", Rect2(10, 240, 440, 30))
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settle_button = Button.new()
	settle_button.text = "SETTLE UP"
	settle_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	settle_button.pressed.connect(settle)
	put(settle_button, Rect2(478, 242, 130, 25))

## Rebuild the counter from the post's current stock; quantities reset to zero.
func open() -> void:
	for child in rows_layer.get_children():
		rows_layer.remove_child(child)
		child.queue_free()
	buys.clear()
	sells.clear()
	held.clear()
	var store: Dictionary = game.post_store()
	if store.is_empty():
		return
	title.text = store.name.to_upper() + " · TRADING POST"
	refreshing = true
	for i in range(store.rows.size()):
		var row: Dictionary = store.rows[i]
		var y := 40 + i * 18
		var name := text(row.label.to_upper(), Rect2(278, y + 2, 108, 16), rows_layer)
		text("$%.2f" % (row.buy_cents / 100.0), Rect2(388, y + 2, 40, 16), rows_layer)
		text("$%.2f" % (row.sell_cents / 100.0), Rect2(492, y + 2, 40, 16), rows_layer)
		name.tooltip_text = "Buy at $%.2f or sell at $%.2f per lot. You hold %d. The post can sell %d more and buy %d." % [row.buy_cents / 100.0, row.sell_cents / 100.0, row.held, row.can_buy, row.can_sell]
		name.mouse_filter = Control.MOUSE_FILTER_PASS
		buys[row.item] = spin(row.can_buy, Rect2(430, y, 56, 18))
		sells[row.item] = spin(row.can_sell, Rect2(534, y, 56, 18))
		held[row.item] = row
	refreshing = false
	update_quote()

func spin(limit: int, bounds: Rect2) -> SpinBox:
	var box := SpinBox.new()
	box.min_value = 0
	box.max_value = limit
	box.step = 1
	box.editable = limit > 0
	box.get_line_edit().add_theme_constant_override("minimum_character_width", 1)
	box.value_changed.connect(func(_value): update_quote())
	put(box, bounds, rows_layer)
	return box

## Buying and selling the same goods in one visit nets out; the post settles the difference.
func cart() -> Dictionary:
	var result := {}
	for item in buys:
		var n := int(buys[item].value) - int(sells[item].value)
		if n != 0:
			result[item] = n
	return result

func update_quote() -> void:
	if refreshing or held.is_empty():
		return
	var quote: Dictionary = game.post_quote(cart())
	var cents: int = roundi(float(game.state.money) * 100.0)
	totals.text = "%s $%.2f · CASH AFTER $%.2f\nTRADING TIME: %s" % ["YOU RECEIVE" if quote.net_cents > 0 else "YOU PAY", absi(quote.net_cents) / 100.0, (cents + quote.net_cents) / 100.0, ("ONE DAY FOR THIS VISIT" if quote.days > 0 else "ALREADY SPENT TODAY")]
	feedback.text = quote.message
	settle_button.disabled = not quote.valid

func settle() -> void:
	if game.post_checkout(cart()):
		open()
		feedback.text = "Settled. Further trades at this stop take no extra time."
		settled.emit()
