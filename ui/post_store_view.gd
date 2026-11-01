extends Panel
## A trading counter (a post's store or a passing party's goods): buy and sell by the unit within its stock and buying demand, settled as one visit.
signal settled
signal sale_requested
var game
var buys: Dictionary = {}
var sells: Dictionary = {}
var held: Dictionary = {}
var title: Label
var wagon_title: Label
var counts: Dictionary = {}
var kind := "post"
var venue := ""
var purse_cents := -1
var totals: Label
var feedback: Label
var sale_button: Button
var settle_button: Button
var news_button: Button
var bubble: Control
var background: TextureRect
var rows_scroll: ScrollContainer
var rows_layer: Control
var scenes = preload("res://ui/location_scenes.gd").new()
const SpeechBubble = preload("res://ui/speech_bubble.gd")
var refreshing := false
const GOODS := {"wagon":"WAGON","produce":"FRUIT/GRN","dried_produce":"DRY FRUIT","food": "FOOD LB", "bullets": "BULLETS", "medicine": "CARE KITS", "clothing": "CLOTHES", "oxen": "OXEN", "wheels": "WHEELS", "axles": "AXLES", "tongues": "TONGUES", "salt": "SALT LB", "horses": "HORSES", "mules": "MULES", "saddles": "SADDLES", "pack_saddles": "PACK SDL", "saddlebags": "SADDLEBAG", "rifles": "RIFLES", "shotguns": "SHOTGUNS", "pistols": "PISTOLS", "revolvers": "COLT", "knives": "KNIVES", "hatchets": "HATCHETS"}
## Each column's paper starts 20 px left of its text, leaving a gutter for the arms pictures.
const POST_X := 236
const PARTY_X := 438
const ROW := 17

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

func right(node: Label) -> Label:
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	# Laid out like a barter screen: the post's goods on the left, the party's on the right, the reckoning below.
	# Both sit to the right so the keeper and the room stay in view.
	paper(Rect2(POST_X - 20, 6, 198, 194))
	paper(Rect2(PARTY_X - 20, 6, 198, 194))
	paper(Rect2(POST_X - 20, 204, 400, 30))
	paper(Rect2(0, 236, 622, 37))
	title = text("", Rect2(POST_X, 10, 172, 12))
	wagon_title = text("", Rect2(PARTY_X, 10, 172, 12))
	columns(POST_X, "STOCK", "BUY")
	columns(PARTY_X, "HAVE", "SELL")
	rows_layer = Control.new()
	rows_scroll=ScrollContainer.new()
	rows_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	put(rows_scroll,Rect2(POST_X - 20,40,400,9*ROW))
	# Scroll a whole row at a time so no row sits half hidden under the headings.
	rows_scroll.get_v_scroll_bar().step=ROW
	rows_scroll.add_child(rows_layer)
	rows_layer.custom_minimum_size=Vector2(384,200)
	sale_button=Button.new()
	sale_button.text="SELL WAGON / PACK >"
	sale_button.pressed.connect(func():sale_requested.emit())
	put(sale_button,Rect2(10,207,222,25))
	totals = text("", Rect2(POST_X, 207, 362, 26))
	feedback = text("", Rect2(10, 240, 322, 30))
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settle_button = Button.new()
	settle_button.text = "SETTLE UP"
	settle_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	settle_button.pressed.connect(settle)
	put(settle_button, Rect2(478, 242, 130, 25))
	news_button = Button.new()
	news_button.text = "ASK FOR NEWS"
	news_button.tooltip_text = "Hear a bit of what they know: news from the States and Oregon, the road ahead, or word of your party. Ask again for more. Takes no time."
	news_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	news_button.pressed.connect(say_news)
	put(news_button, Rect2(340, 242, 130, 25))
	# News comes as a speech bubble over the picture, from the keeper, the trader or the family.
	bubble = SpeechBubble.new()
	put(bubble, Rect2(0, 0, 622, 236))

func columns(x: int, count: String, action: String) -> void:
	text("GOODS", Rect2(x, 26, 50, 12))
	right(text(count, Rect2(x + 44, 26, 36, 12)))
	text("EACH", Rect2(x + 85, 26, 34, 12))
	text(action, Rect2(x + 126, 26, 42, 12))

## Rebuild the counter from the post's current stock; quantities reset to zero.
func open(where: String = "") -> void:
	venue = where
	for child in rows_layer.get_children():
		rows_layer.remove_child(child)
		child.queue_free()
	buys.clear()
	sells.clear()
	held.clear()
	counts.clear()
	hide_bubble()
	var store: Dictionary = game.trade_counter(venue)
	if store.is_empty():
		return
	sale_button.visible=store.kind=="post" and game.state.vehicle=="wagon"
	kind = store.kind
	purse_cents = int(store.purse_cents)
	# A passing party's temper shows beside its name; its camp is a different picture from the post's room.
	title.text = {"post": store.name.to_upper(), "traders": "TRADERS · " + str(store.get("mood", "")).to_upper(), "camp": "EMIGRANT FAMILY"}[kind]
	background.texture = scenes.texture_for({"post": "post_store", "traders": "trader_camp", "camp": "camp_trade"}[kind])
	refreshing = true
	for i in range(store.rows.size()):
		var row: Dictionary = store.rows[i]
		var y := 40 + i * ROW
		var goods: String = game.leathercraft.label_for(row.item).to_upper() if game.leathercraft.is_good(row.item) else game.income.label_for(game,row.item).to_upper() if game.income.is_keepsake(row.item) else game.provisions.data.pelts.goods.get(row.item,{}).get("short_label",GOODS.get(row.item, row.item.to_upper()))
		var unit: String = "lb" if row.item in ["food", "salt"] else "each"
		var tip := "Buy at $%.3f or sell at $%.3f %s. You hold %d. The post can sell %d more and buy %d." % [row.buy_cents / 100.0 / row.amount, row.sell_cents / 100.0 / row.amount, "a pound" if unit == "lb" else "each", row.held, row.can_buy, row.can_sell]
		if row.item=="wagon":tip="Empty covered wagon: no oxen, food or new household outfit. Your current belongings are loaded. One per store; team and supplies are bought separately."
		if row.item in game.Produce.ITEMS:tip="One basket = one food unit from 4 lb fresh produce. "+("Dried: lighter, up to 90 days, less vitamin C." if row.item=="dried_produce" else "Fresh: 4 lb, spoils in 3 days, more vitamin C.")+" Only eating it helps; prices are per basket."
		if row.item in game.provisions.data.pelts.goods:tip="Rough prepared trade skin, not a finished robe. Weight %.1f lb each. This buyer pays $%.2f each and will buy %d more; resale only." % [float(game.provisions.data.pelts.goods[row.item].weight_lb),row.sell_cents/100.0,row.can_sell]
		if game.income.is_keepsake(row.item):tip="Personal property, %.2f lb; consent from a present trusting owner is required before sale. Manage permission through Supplies > Keepsakes. Deceased owners leave estate goods. Retaining this item until Oregon earns 100 keepsake points." % float(game.income.data.keepsake.weight_lb)
		if game.leathercraft.is_good(row.item):tip="Crafted trade good: %.2f lb each. Sell through this counter within its remaining demand. Glove pairs do not replace a full clothing set." % float(game.leathercraft.data.goods[row.item].weight_lb)
		# Goods move by the unit (a pound, a bullet, an ox). Counts follow the basket, so goods cross over as you choose them.
		# A passing party prices only what it carries and what it wants; the rest shows a dash.
		# Arms carry their small picture beside each column.
		var arms_icon: Texture2D = preload("res://simulation/armory.gd").icon(str(row.item))
		if arms_icon != null:
			for column in [POST_X, PARTY_X]:
				var picture := TextureRect.new()
				picture.texture = arms_icon
				picture.mouse_filter = Control.MOUSE_FILTER_PASS
				picture.tooltip_text = tip
				put(picture, Rect2(column - 18, y, 16, 16), rows_layer)
		var stock := line(POST_X, y, goods, row.buy_cents / float(row.amount) if row.get("sells", true) else -1.0, tip)
		var have := line(PARTY_X, y, goods, row.sell_cents / float(row.amount) if row.get("buys", true) else -1.0, tip)
		# A family pays over the odds for what it is short of: those prices show in green.
		if float(row.get("premium", 1.0)) >= 1.3:
			rows_layer.get_child(rows_layer.get_child_count() - 2).add_theme_color_override("font_color", Color("2f6b2f"))
		buys[row.item] = spin(row.can_buy, Rect2(POST_X + 124, y, 44, 17))
		sells[row.item] = spin(row.can_sell, Rect2(PARTY_X + 124, y, 44, 17))
		counts[row.item] = [have, stock]
		held[row.item] = row
	for child in rows_layer.get_children():child.position-=Vector2(POST_X - 20,40)
	rows_layer.custom_minimum_size.y=store.rows.size()*ROW
	rows_scroll.scroll_vertical=0
	refreshing = false
	update_news_button()
	update_quote()

func line(x: int, y: int, goods: String, cents: float, tip: String) -> Label:
	var name := text(goods, Rect2(x, y + 2, 56, 16), rows_layer)
	name.tooltip_text = tip
	name.mouse_filter = Control.MOUSE_FILTER_PASS
	text("$%.2f" % (cents / 100.0) if cents >= 0 else "  -", Rect2(x + 85, y + 2, 38, 16), rows_layer)
	return right(text("", Rect2(x + 56, y + 2, 24, 16), rows_layer))

func spin(limit: int, bounds: Rect2) -> SpinBox:
	var box := SpinBox.new()
	box.min_value = 0
	box.max_value = limit
	box.step = 1
	box.editable = limit > 0
	# Room for four digits (selling 1,998 lb of food or bullets): slim padding, arrows flush to the field, figures right-aligned.
	box.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_theme_constant_override("field_and_buttons_separation", 0)
	var field := box.get_line_edit()
	field.add_theme_constant_override("minimum_character_width", 1)
	box.value_changed.connect(func(_value): update_quote())
	put(box, bounds, rows_layer)
	# The parchment field style comes from the window's theme, so it is read once the box is on screen.
	for state in ["normal", "focus", "read_only"]:
		var look: StyleBox = field.get_theme_stylebox(state).duplicate()
		look.content_margin_left = 2
		look.content_margin_right = 2
		field.add_theme_stylebox_override(state, look)
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
	var quote: Dictionary = game.counter_quote(cart(), venue)
	var cents: int = roundi(float(game.state.money) * 100.0)
	for item in counts:
		var row: Dictionary = held[item]
		var n: int = int(buys[item].value) - int(sells[item].value)
		counts[item][0].text = str(row.held + n)
		counts[item][1].text = str(row.can_buy - int(buys[item].value))
	wagon_title.text = "YOUR PACKS" if game.state.vehicle == "foot" else "YOUR WAGON"
	var cargo: float = quote.get("cargo_after_lb", game.provisions.cargo(game.state))
	var capacity: float = quote.get("capacity_after_lb", game.provisions.capacity(game.state))
	totals.text = "%s $%.2f · CASH $%.2f > $%.2f · %s\n%s %.0f / %.0f LB%s" % ["YOU GET" if quote.net_cents > 0 else "YOU PAY", absi(quote.net_cents) / 100.0, cents / 100.0, (cents + quote.net_cents) / 100.0, ("1 DAY" if quote.days > 0 else "NO EXTRA TIME"), ("PACKS" if game.state.vehicle == "foot" else "CARGO") + (" AFTER" if not quote.effects.is_empty() else ""), cargo, capacity, " · OVERLOADED" if cargo > capacity else ""]
	if purse_cents >= 0:
		totals.text += " · THEIR CASH $%.2f" % (purse_cents / 100.0)
	if cargo > capacity:
		totals.add_theme_color_override("font_color", Color("8c2b1c"))
	else:
		totals.remove_theme_color_override("font_color")
	feedback.text = quote.message
	settle_button.disabled = not quote.valid

func settle() -> void:
	if game.counter_checkout(cart(), venue):
		open(venue)
		feedback.text = "Settled." if kind == "camp" else "Settled. Further trades at this stop take no extra time."
		settled.emit()

## Where each picture's speaker stands: the tip of the bubble's tail.
const SPEAKERS := {"post": Vector2(150, 104), "traders": Vector2(186, 170), "camp": Vector2(150, 166)}

## One fragment of what they have heard. How many times they answer depends on how generous they are.
func say_news() -> void:
	var said: String = game.ask_news(venue)
	update_news_button()
	if said.is_empty():
		return
	bubble.say(said, SPEAKERS.get(kind, SPEAKERS.post))

func update_news_button() -> void:
	var left: int = game.news_left(venue)
	news_button.disabled = left <= 0
	news_button.text = "ASK FOR NEWS (%d)" % left if left > 0 else "NO MORE NEWS"
	news_button.tooltip_text = "Hear a bit of what they know: news from the States and Oregon, the road ahead, or word of your party. Generous people tell more. Takes no time." if left > 0 else "They have told you all they care to."

func hide_bubble() -> void:
	if bubble:
		bubble.hide()
