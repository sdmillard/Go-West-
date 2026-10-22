extends Control
const Simulation = preload("res://simulation/trail_engine.gd")
const Landscape = preload("res://ui/trail_view.gd")
const Departure = preload("res://ui/departure_view.gd")
const GraveStore = preload("res://simulation/grave_store.gd")
const GraveView = preload("res://ui/grave_view.gd")
const SaveStore = preload("res://simulation/save_store.gd")
const HuntView = preload("res://ui/hunt_view.gd")
const PIXEL_FONT = preload("res://art/pixels/trail_font.fnt")
var game = Simulation.new(1848, "classic", true)
var landscape: Control
var date_label: Label
var stats: Label
var progress: ProgressBar
var event_title: Label
var event_text: Label
var choices: VBoxContainer
var journal: RichTextLabel
var pace: OptionButton
var rations: OptionButton
var mode: OptionButton
var seed_input: SpinBox
var travel_button: Button
var rest_button: Button
var guide: AcceptDialog
var journal_window: AcceptDialog
var party_window: AcceptDialog
var party_button: Button
var party_rows: VBoxContainer
var member_details: RichTextLabel
var selected_member := 0
var wages_button: Button
var stop_window: AcceptDialog
var stop_rows: VBoxContainer
var options_window: AcceptDialog
var options_button: Button
var hunt_button: Button
var hunt_window: AcceptDialog
var hunt_view: Control
var hunt_report: Label
var supplies_window: AcceptDialog
var supplies_rows: VBoxContainer
var slaughter_confirmation: ConfirmationDialog
var slaughter_by_hand := false
var packing_window: AcceptDialog
var packing_quantities: Dictionary={}
var packing_quote: Label
var packing_cache_mode:=false
var service_window: AcceptDialog
var service_rows: VBoxContainer
var story_scroll: ScrollContainer
var story_column: VBoxContainer
var departure_view: Panel
var travel_timer: Timer
var traveling := false
var camping := false
var save_store = SaveStore.new()
var save_path := SaveStore.DEFAULT_PATH
var save_button: Button
var load_button: Button
var food_notice: AcceptDialog
var last_food_alert:=0
var rest_window: ConfirmationDialog
var rest_days_input: LineEdit
var rest_quote: Label
var record_notice: AcceptDialog
var grave_store = GraveStore.new()
var grave_window: AcceptDialog
var grave_view: Control
var epitaph_input: LineEdit
var memorial_window: AcceptDialog
var memorial_rows: VBoxContainer
var visited_graves: Array = []
var grave_editing := false
var crossing_result: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_theme()
	_build_ui()
	travel_timer = Timer.new()
	travel_timer.wait_time = 1.25
	travel_timer.timeout.connect(_advance_day)
	add_child(travel_timer)
	landscape.crossing_finished.connect(_crossing_finished)
	guide.visibility_changed.connect(_update_animation_pause)
	journal_window.visibility_changed.connect(_update_animation_pause)
	party_window.visibility_changed.connect(_update_animation_pause)
	options_window.visibility_changed.connect(_update_animation_pause)
	service_window.visibility_changed.connect(_update_animation_pause)
	grave_store.read_records()
	_open_departure()
	_refresh()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("302b2c"))
	# Narrow wood grain bands and brass corner pins, deliberately integer aligned.
	for y in range(0, 360, 12):
		draw_rect(Rect2(0, y, 640, 11), Color("45372f" if y % 24 == 0 else "4e3c31"))
		for x in range(0, 640, 67):
			draw_rect(Rect2(x + (y % 31), y+4, 22, 1), Color("594232"))
	draw_rect(Rect2(3, 3, 634, 354), Color("a16b43"), false, 1)
	draw_rect(Rect2(5, 5, 630, 350), Color("241f22"), false, 1)
	for pos in [Vector2(3, 3), Vector2(634, 3), Vector2(3, 354), Vector2(634, 354)]:
		draw_rect(Rect2(pos, Vector2(3, 3)), Color("ddb461"))
		draw_rect(Rect2(pos + Vector2.ONE, Vector2.ONE), Color("f6e7bc"))

func style(bg: String, border: String, padding: int = 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(bg)
	box.border_color = Color(border)
	box.set_border_width_all(1)
	box.set_content_margin_all(padding)
	box.shadow_color = Color("241f22")
	box.shadow_size = 1
	box.shadow_offset = Vector2(1, 1)
	return box

func _build_theme() -> void:
	var skin := Theme.new()
	skin.default_font = PIXEL_FONT
	skin.default_font_size = 8
	for kind in ["Label", "RichTextLabel"]:
		skin.set_color("font_color" if kind == "Label" else "default_color", kind, Color("45372f"))
	for kind in ["Button", "OptionButton", "MenuButton"]:
		skin.set_color("font_color", kind, Color("f6e7bc"))
		skin.set_color("font_hover_color", kind, Color("fff4d4"))
		skin.set_color("font_pressed_color", kind, Color("fff4d4"))
		skin.set_color("font_disabled_color", kind, Color("aa947b"))
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var bg: String = "76503c" if state == "normal" else "a16b43"
			if state == "disabled":
				bg = "45372f"
			skin.set_stylebox(state, kind, style(bg, "ddb461" if state in ["hover", "focus"] else "c18d4d"))
		skin.set_constant("outline_size", kind, 0)
	skin.set_stylebox("normal", "LineEdit", style("ecd097", "76503c", 3))
	skin.set_stylebox("focus", "LineEdit", style("f6e7bc", "ddb461", 3))
	skin.set_color("font_color", "LineEdit", Color("45372f"))
	skin.set_stylebox("panel", "PopupMenu", style("45372f", "ddb461", 5))
	skin.set_stylebox("hover", "PopupMenu", style("a16b43", "ddb461", 2))
	skin.set_color("font_color", "PopupMenu", Color("f6e7bc"))
	skin.set_stylebox("panel", "AcceptDialog", style("ecd097", "76503c", 10))
	var window_border := style("76503c", "ddb461", 3)
	window_border.expand_margin_top = 15
	skin.set_stylebox("embedded_border", "Window", window_border)
	skin.set_stylebox("embedded_unfocused_border", "Window", window_border)
	skin.set_font("title_font", "Window", PIXEL_FONT)
	skin.set_font_size("title_font_size", "Window", 8)
	skin.set_constant("title_height", "Window", 15)
	skin.set_stylebox("background", "ProgressBar", style("302b2c", "76503c", 0))
	skin.set_stylebox("fill", "ProgressBar", style("ddb461", "f6e7bc", 0))
	theme = skin

func place(node: Control, bounds: Rect2, parent: Node = self) -> Control:
	parent.add_child(node)
	node.position = bounds.position
	node.size = bounds.size
	return node

func label(text: String, font_size: int = 8) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	return node

func button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(action)
	return node

func panel(bounds: Rect2, parchment: bool = true) -> Panel:
	var node := Panel.new()
	node.add_theme_stylebox_override("panel", style("ecd097" if parchment else "302b2c", "a16b43", 4))
	place(node, bounds)
	return node

func _build_ui() -> void:
	var title := label("WESTWARD, PROBABLY", 16)
	title.add_theme_color_override("font_color", Color("f6e7bc"))
	title.add_theme_color_override("font_shadow_color", Color("241f22"))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	place(title, Rect2(12, 10, 300, 22))
	var subtitle := label("AN OVERLAND ADVENTURE\nINDEPENDENCE > OREGON CITY")
	subtitle.add_theme_color_override("font_color", Color("ddb461"))
	place(subtitle, Rect2(358, 11, 204, 23))
	place(button("GUIDE", _show_guide), Rect2(576, 10, 52, 22))
	date_label = label("")
	date_label.add_theme_color_override("font_color", Color("f6e7bc"))
	place(date_label, Rect2(14, 39, 612, 12))
	panel(Rect2(9, 55, 436, 154), false)
	landscape = Landscape.new()
	place(landscape, Rect2(11, 57, 432, 150))
	var ledger := panel(Rect2(451, 55, 180, 154))
	place(label("* WAGON LEDGER *"), Rect2(9, 8, 164, 12), ledger)
	stats = label("")
	stats.add_theme_constant_override("line_spacing", 1)
	place(stats, Rect2(9, 25, 164, 100), ledger)
	party_button = button("VIEW PARTY", _show_party)
	place(party_button, Rect2(9, 130, 162, 17), ledger)
	progress = ProgressBar.new()
	progress.max_value = Simulation.DESTINATION
	progress.show_percentage = false
	place(progress, Rect2(10, 213, 620, 4))
	var story := panel(Rect2(9, 222, 436, 106))
	story_scroll = ScrollContainer.new()
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	place(story_scroll, Rect2(7, 5, 422, 96), story)
	story_column = VBoxContainer.new()
	story_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_column.add_theme_constant_override("separation", 3)
	story_scroll.add_child(story_column)
	event_title = label("")
	event_title.add_theme_color_override("font_color", Color("76503c"))
	story_column.add_child(event_title)
	event_text = label("")
	event_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_column.add_child(event_text)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 3)
	story_column.add_child(choices)
	panel(Rect2(451, 222, 180, 106))
	place(label("PACE"), Rect2(459, 231, 42, 10))
	pace = OptionButton.new()
	for text in ["STEADY", "STRENUOUS", "GRUELING"]:
		pace.add_item(text)
	pace.selected = 1
	pace.item_selected.connect(_settings_changed)
	pace.tooltip_text = "Nominal 22/26/30 miles per day before weather, load, team condition and stops. Faster travel costs health."
	place(pace, Rect2(508, 226, 115, 21))
	place(label("RATIONS"), Rect2(459, 257, 46, 10))
	rations = OptionButton.new()
	for text in ["BARE", "MEAGER", "FILLING"]:
		rations.add_item(text)
	rations.selected = 1
	rations.item_selected.connect(_settings_changed)
	rations.tooltip_text = "Bare 1, meager 2, filling 3 lb per living traveler per day. Low rations slow recovery even in camp."
	place(rations, Rect2(508, 251, 115, 21))
	travel_button = button("CONTINUE >", _travel)
	place(travel_button, Rect2(459, 282, 91, 37))
	rest_button = button("CAMP", _rest)
	place(rest_button, Rect2(557, 282, 66, 37))
	travel_button.tooltip_text = "Travel automatically. Click Pause to stop; encounters stop the wagon."
	rest_button.tooltip_text = "Choose how many days to rest in camp. Meals and daily health rules still apply."
	mode = OptionButton.new()
	mode.add_item("CLASSIC")
	mode.disabled = true
	mode.tooltip_text = "Classic is the current development focus. Unhinged mode will return after the classic systems are established."
	place(mode, Rect2(11, 334, 104, 17))
	var seed_label := label("SEED")
	seed_label.add_theme_color_override("font_color", Color("f6e7bc"))
	place(seed_label, Rect2(128, 338, 28, 10))
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 999999999
	seed_input.value = 1848
	seed_input.get_line_edit().add_theme_constant_override("minimum_character_width", 1)
	place(seed_input, Rect2(161, 334, 102, 17))
	place(button("NEW JOURNEY", _new_journey), Rect2(274, 334, 90, 17))
	save_button = button("SAVE", _save_journey)
	place(save_button, Rect2(370, 334, 47, 17))
	load_button = button("LOAD", _load_journey)
	place(load_button, Rect2(422, 334, 47, 17))
	place(button("JOURNAL", _show_journal), Rect2(474, 334, 67, 17))
	record_notice = AcceptDialog.new()
	record_notice.title = "TRAIL RECORD"
	add_child(record_notice)
	options_button = button("OPTIONS", _show_options)
	options_button.tooltip_text = "Hunt, trade, and care for travelers"
	place(options_button, Rect2(548, 334, 80, 17))
	grave_window = AcceptDialog.new()
	grave_window.title = "A GRAVESTONE ON THE TRAIL"
	grave_window.confirmed.connect(_leave_gravestone)
	add_child(grave_window)
	var grave_content := Control.new()
	grave_content.custom_minimum_size = Vector2(432,196)
	grave_window.add_child(grave_content)
	grave_view = GraveView.new()
	place(grave_view,Rect2(0,0,432,150),grave_content)
	epitaph_input = LineEdit.new()
	epitaph_input.max_length = 90
	epitaph_input.placeholder_text = "Write an epitaph (90 characters)"
	epitaph_input.text_changed.connect(_preview_epitaph)
	place(epitaph_input,Rect2(0,158,432,24),grave_content)
	memorial_window = AcceptDialog.new()
	memorial_window.title = "THE MEMORIAL BOOK"
	add_child(memorial_window)
	var memorial_scroll := ScrollContainer.new()
	memorial_scroll.custom_minimum_size = Vector2(480,218)
	memorial_window.add_child(memorial_scroll)
	memorial_rows = VBoxContainer.new()
	memorial_scroll.add_child(memorial_rows)
	guide = AcceptDialog.new()
	guide.title = "THE OVERLAND GUIDE"
	guide.dialog_text = """Name five travelers, choose a profession and month, then buy
supplies. Care kits are optional; keep cash for the road.

Continue advances days; Pause stops the wagon. Encounters
and landmarks stop travel. Guide, Journal, View Party and
Options let you take stock without spending another day.

Camp rests people and livestock, using food. Faster travel
strains the team; low rations raise illness risk. Clothing
protects people in rough weather. Inspect individual travelers.

Options offers hunting, trading and medical care. Hunting
costs a day and ammunition. Left-click fires; right-click walks.
Cover blocks shots. Game flees; reload between shots. Carry
back up to 100 lb. Buying, selling,
bartering and care take a day each; check costs first.

Recent rain can raise a river while you wait. Low water favors
fording; high water is dangerous. Watch team condition and
supplies as well as the weather.

This chapter follows Palmer's reported opening route from
Independence to Oregon City: 1,938 reported guide miles.
The southern road via Bridger and the Barlow Road is playable.
The suggested staples provision most of the journey, with resupply.
Plan bulk resupply at trading posts; allow for weather delays.
Options > Provisions lets you dry fresh meat, with optional salt.
This takes a day. Food uses ration-equivalent pounds; dried meat
weighs less in cargo. Preserved meat also eventually spoils.
Northern shortcuts and Columbia rafting are not yet playable.
Weather, medical effects and other survival values remain
simplified game rules, not reconstructed conditions for 1848."""
	add_child(guide)
	journal_window = AcceptDialog.new()
	journal_window.title = "TRAIL JOURNAL"
	journal_window.min_size = Vector2i(530, 240)
	add_child(journal_window)
	journal = RichTextLabel.new()
	journal.scroll_following = true
	journal.selection_enabled = true
	journal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	journal.offset_left = 12
	journal.offset_top = 10
	journal.offset_right = -12
	journal.offset_bottom = -35
	journal_window.add_child(journal)
	party_window = AcceptDialog.new()
	party_window.title = "YOUR TRAVELING PARTY"
	party_window.min_size = Vector2i(580, 270)
	add_child(party_window)
	# AcceptDialog sizes each direct Control child as content. A single wrapper
	# keeps the roster and detail columns in their own fixed pixel layout.
	var party_content := Control.new()
	party_content.custom_minimum_size = Vector2(552, 216)
	party_window.add_child(party_content)
	var party_heading := label("SELECT A TRAVELER")
	place(party_heading, Rect2(0, 0, 245, 12), party_content)
	party_rows = VBoxContainer.new()
	party_rows.add_theme_constant_override("separation", 5)
	place(party_rows, Rect2(0, 22, 245, 190), party_content)
	member_details = RichTextLabel.new()
	member_details.selection_enabled = true
	place(member_details, Rect2(261, 0, 291, 188), party_content)
	wages_button=button("PAY WAGES",_pay_selected_wages)
	place(wages_button,Rect2(261,194,291,22),party_content)
	options_window = AcceptDialog.new()
	options_window.title = "TRAIL OPTIONS"
	add_child(options_window)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(350, 110)
	options_window.add_child(actions)
	hunt_button = button("HUNT · 1 DAY, UP TO 5 SHOTS", _start_hunt)
	actions.add_child(hunt_button)
	actions.add_child(button("LOCAL CONDITIONS / STOP ACTIVITIES", _show_stop_activities))
	actions.add_child(button("LOOK FOR TRADERS / TRADE", _open_trade))
	actions.add_child(button("ROB, STEAL OR ATTACK HERE", _open_crime))
	actions.add_child(button("CARE / MEDICAL ATTENTION", _open_care))
	actions.add_child(button("PROVISIONS / CARGO", _show_supplies))
	actions.add_child(button("MEMORIAL BOOK", _show_memorials))
	actions.add_child(label("Each activity stops travel.\nCheck costs before committing."))
	food_notice=AcceptDialog.new()
	food_notice.title="FOOD WARNING"
	food_notice.min_size=Vector2i(520,170)
	food_notice.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	food_notice.get_label().custom_minimum_size.x=500
	food_notice.get_ok_button().text="RETURN TO CAMP"
	add_child(food_notice)
	rest_window=ConfirmationDialog.new()
	rest_window.title="REST IN CAMP"
	rest_window.get_ok_button().text="REST"
	rest_window.confirmed.connect(_confirm_rest)
	add_child(rest_window)
	var rest_rows:=Control.new()
	rest_rows.custom_minimum_size=Vector2(460,153)
	place(label("How many days? Enter a whole number, 1–30."),Rect2(0,0,460,23),rest_rows)
	rest_days_input=LineEdit.new()
	rest_days_input.text="1"
	rest_days_input.max_length=3
	rest_days_input.text_changed.connect(func(_text: String): _update_rest_quote())
	rest_days_input.text_submitted.connect(func(_text: String):
		if not rest_window.get_ok_button().disabled:
			rest_window.hide()
			_confirm_rest())
	place(rest_days_input,Rect2(0,28,460,23),rest_rows)
	rest_quote=Label.new()
	rest_quote.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(rest_quote,Rect2(0,68,460,85),rest_rows)
	rest_window.add_child(rest_rows)
	stop_window=AcceptDialog.new()
	stop_window.title="LOCAL CONDITIONS"
	add_child(stop_window)
	var stop_scroll:=ScrollContainer.new()
	stop_scroll.custom_minimum_size=Vector2(530,190)
	stop_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	stop_window.add_child(stop_scroll)
	stop_rows=VBoxContainer.new()
	stop_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stop_rows.add_theme_constant_override("separation",8)
	stop_scroll.add_child(stop_rows)
	hunt_window = AcceptDialog.new()
	hunt_window.title = "HUNTING ON THE PRAIRIE"
	hunt_window.get_ok_button().text = "RETURN TO CAMP"
	hunt_window.confirmed.connect(_finish_hunt)
	hunt_window.canceled.connect(_finish_hunt)
	add_child(hunt_window)
	var hunt_content := Control.new()
	hunt_content.custom_minimum_size = Vector2(432, 212)
	hunt_window.add_child(hunt_content)
	hunt_view = HuntView.new()
	place(hunt_view, Rect2(0, 0, 432, 150), hunt_content)
	hunt_view.aim.connect(func(point: Vector2):
		game.hunt_fire_at(point)
		_update_hunt_report())
	hunt_view.move_requested.connect(func(point: Vector2): game.move_hunter(point))
	hunt_view.elapsed.connect(func(delta: float):
		game.advance_hunt(delta)
		_update_hunt_report())
	hunt_report = label("")
	place(hunt_report, Rect2(0, 154, 432, 57), hunt_content)
	supplies_window = AcceptDialog.new()
	supplies_window.title = "PROVISIONS AND WAGON CARGO"
	add_child(supplies_window)
	var supplies_scroll := ScrollContainer.new()
	supplies_scroll.custom_minimum_size = Vector2(500, 218)
	supplies_window.add_child(supplies_scroll)
	supplies_rows = VBoxContainer.new()
	supplies_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	supplies_scroll.add_child(supplies_rows)
	service_window = AcceptDialog.new()
	service_window.min_size = Vector2i(580, 280)
	service_window.get_ok_button().text = "BACK TO TRAIL"
	service_window.confirmed.connect(_cancel_service)
	service_window.canceled.connect(_cancel_service)
	add_child(service_window)
	var service_scroll := ScrollContainer.new()
	service_scroll.custom_minimum_size = Vector2(552, 218)
	service_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	service_window.add_child(service_scroll)
	service_rows = VBoxContainer.new()
	service_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	service_rows.add_theme_constant_override("separation", 4)
	service_scroll.add_child(service_rows)

func _show_options() -> void:
	if not game.can_service() or not landscape.crossing.is_empty() or _reviewing_crossing():
		return
	_pause_travel()
	_refresh()
	hunt_button.disabled = not game.pending.is_empty() or game.state.bullets == 0
	options_window.popup_centered()

func _open_trade() -> void:
	options_window.hide()
	crossing_result = {}
	if game.open_trade():
		_show_service()
	_refresh()

func _open_care() -> void:
	options_window.hide()
	crossing_result = {}
	if game.open_care():
		_show_service()
	_refresh()

func _show_stop_activities() -> void:
	options_window.hide()
	_pause_travel()
	for child in stop_rows.get_children():
		stop_rows.remove_child(child)
		child.queue_free()
	var region: Dictionary=game.context.region(game)
	var heading:=label(region.label+"\n"+region.note)
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stop_rows.add_child(heading)
	var offer: Dictionary=game.context.market(game)
	stop_rows.add_child(label("Trading post: limited stock and buying demand." if offer.post else ("Passing traders are nearby today; their supplies are limited." if offer.available else "No passing trading party is available today.")))
	if game.pending.has("landmark"):
		stop_window.title="AT "+game.pending.title
		for index in range(game.pending.choices.size()):
			var choice: Dictionary=game.pending.choices[index]
			if choice.get("action","") in ["notes","activity"]:
				var option:=button(choice.label,_stop_choice.bind(str(game.pending.landmark),index))
				option.disabled=not game.can_choose(index)
				stop_rows.add_child(option)
	else:stop_window.title="LOCAL CONDITIONS"
	stop_window.popup_centered()

func _stop_choice(place_id: String,index: int) -> void:
	stop_window.hide()
	if game.pending.get("landmark","")==place_id:_choose(index)

func _open_crime() -> void:
	options_window.hide()
	if game.open_crime():_show_service()
	else:
		record_notice.title="NOTHING TO TAKE HERE"
		record_notice.dialog_text="Stop at a trading post, the Kansas River ferry, Fort Kearny once soldiers are there, or the Barlow Road toll gate to use these actions."
		record_notice.popup_centered()

func _show_service() -> void:
	for child in service_rows.get_children():
		service_rows.remove_child(child)
		child.queue_free()
	service_window.title = game.pending.title
	service_window.get_ok_button().text="CLOSE PANEL" if game.pending.get("crime_menu",false) and not game.crime.record.active.is_empty() else "BACK TO TRAIL"
	var explanation := label(game.pending.text)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	service_rows.add_child(explanation)
	for index in range(game.pending.choices.size() - 1):
		var option := button(game.pending.choices[index].label, _service_choice.bind(index))
		option.disabled = not game.can_choose(index)
		service_rows.add_child(option)
	service_window.popup_centered()

func _service_choice(index: int) -> void:
	service_window.hide()
	_choose(index)

func _cancel_service() -> void:
	service_window.hide()
	if game.pending.get("crime_menu",false) and not game.crime.record.active.is_empty():
		_refresh()
		return
	if game.pending.get("service_menu", false):
		_choose(game.pending.choices.size() - 1)

func _start_hunt() -> void:
	options_window.hide()
	crossing_result = {}
	if game.start_hunt():
		hunt_view.encounter = game.hunt
		hunt_view.active = true
		_update_hunt_report()
		hunt_window.popup_centered()
	_refresh()

func _update_hunt_report() -> void:
	if not game.hunt.is_empty():
		hunt_report.text = "%s · %ds · %s · SHOTS %d/5 · AMMO %d\nLEFT: FIRE · RIGHT: WALK · MEAT %d / 100 LB\n%s" % [game.hunt.region_label.to_upper(), ceili(30 - game.hunt.elapsed), "RELOAD" if game.hunt.reload > 0 else "READY", game.hunt.shots, game.state.bullets, game.hunt.meat, game.hunt.message]


func _finish_hunt() -> void:
	hunt_window.hide()
	hunt_view.active = false
	if game.hunt.is_empty():
		return
	var outing: Dictionary = game.hunt.duplicate(true)
	var before: int = game.state.food
	if game.finish_hunt():
		var carried: int = game.state.food - before
		record_notice.title = "HUNTING REPORT"
		record_notice.dialog_text = "%d shots · %d lb meat obtained\n%d lb brought to camp · %d lb left behind\nUse fresh meat within two trail days, or dry it through\nOptions > Provisions. Salt improves the result.\nThe outing used one day and that day's rations." % [outing.shots,outing.meat,carried,int(outing.meat)-carried]
		record_notice.popup_centered()
	camping = true
	_refresh()

func _show_party() -> void:
	if game.party_health.members.is_empty():
		return
	_pause_travel()
	_refresh()
	_refresh_party()
	party_window.popup_centered()

func _select_member(index: int) -> void:
	selected_member = index
	_refresh_party()

func _refresh_party() -> void:
	wages_button.hide()
	member_details.size.y=216
	for node in party_rows.get_children():
		party_rows.remove_child(node)
		node.queue_free()
	if game.party_health.members.is_empty():
		member_details.text = "Outfit your party before departure."
		return
	selected_member = clampi(selected_member, 0, game.party_health.members.size() - 1)
	for member in game.party_health.members:
		var condition: String = "LEFT PARTY" if member.get("departed",false) else (game.PartyHealth.condition_label(member.health) if member.alive else "DECEASED")
		var text: String = member.name.to_upper() + " · " + condition
		if game.party_health.is_active(member) and not member.conditions.is_empty():
			var active: Dictionary = member.conditions[0]
			text += "\n" + str(game.party_health.conditions[active.id].name)
		var row := button(text, _select_member.bind(int(member.id)))
		row.custom_minimum_size.y = 33
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.tooltip_text = "View condition and personal history"
		party_rows.add_child(row)
	member_details.text = game.party_health.description(selected_member).replace("PERSONAL HISTORY",game.characters.description(selected_member)+"\n\nHEALTH HISTORY")
	if selected_member<game.characters.profiles.size():
		var contract: Dictionary=game.characters.profiles[selected_member].contract
		if not contract.is_empty():
			member_details.size.y=188
			wages_button.show()
			wages_button.text="PAY WAGES OWED · $%.2f" % (contract.arrears_cents/100.0)
			wages_button.disabled=contract.arrears_cents<=0 or roundi(game.state.money*100)<contract.arrears_cents or not game.characters.can_receive_wages(game,selected_member)

func _pay_selected_wages() -> void:
	if game.characters.pay_wages(game,selected_member):
		_refresh()
		_refresh_party()

func _show_guide() -> void:
	_pause_travel()
	_refresh()
	guide.popup_centered()

func _show_journal() -> void:
	_pause_travel()
	_refresh()
	journal_window.popup_centered()

func _new_journey() -> void:
	rest_window.hide()
	food_notice.hide()
	last_food_alert=0
	stop_window.hide()
	grave_window.hide()
	memorial_window.hide()
	visited_graves.clear()
	supplies_window.hide()
	service_window.hide()
	options_window.hide()
	hunt_window.hide()
	hunt_view.active = false
	party_window.hide()
	selected_member = 0
	landscape.cancel_crossing()
	crossing_result = {}
	_pause_travel()
	camping = false
	game = Simulation.new(int(seed_input.value), "classic", true)
	pace.selected = 0
	rations.selected = 2
	_open_departure()
	_refresh()

func _open_departure() -> void:
	if is_instance_valid(departure_view):
		remove_child(departure_view)
		departure_view.queue_free()
		departure_view = null
	if game.state.status != "outfitting":
		return
	departure_view = Departure.new(game)
	place(departure_view, Rect2(9, 55, 622, 273))
	departure_view.departure_requested.connect(_depart)

func _depart(profession: String, names: Array, month: int, cart: Dictionary) -> void:
	if game.depart(profession, names, month, cart,departure_view.customization()):
		departure_view.hide()
		camping = false
		pace.selected = game.state.pace
		rations.selected = game.state.rations
		_refresh()
	else:
		departure_view.feedback.text = game.departure_error

func _settings_changed(_index: int) -> void:
	_pause_travel()
	game.configure(pace.selected, rations.selected)
	_refresh()

func _travel() -> void:
	if not landscape.crossing.is_empty() or _reviewing_crossing():
		return
	crossing_result = {}
	if traveling:
		_pause_travel()
	elif game._can_act():
		camping = false
		traveling = true
		travel_timer.start()
	_refresh()

func _pause_travel() -> void:
	traveling = false
	if travel_timer != null:
		travel_timer.stop()
	if is_instance_valid(landscape):
		landscape.motion = 0.0

func _warn_food() -> bool:
	if not game.state.extended_route or game.state.status!="traveling":return false
	var fed_days: int=game.provisions.forecast_days(game.state.food,game.state.party_size,game.state.rations,game.state.day)
	var level:=2 if game.state.food==0 else (1 if fed_days<3 else 0)
	if level<last_food_alert:last_food_alert=level
	if level==0 or level<=last_food_alert:return false
	last_food_alert=level
	_pause_travel()
	_refresh()
	food_notice.title="NO FOOD — STARVATION RISK" if level==2 else "LOW FOOD / SPOILAGE WARNING"
	food_notice.dialog_text=("There is no food. Another day can cause starvation damage. " if level==2 else "Your supplies cannot cover three full days at the current ration setting, including known spoilage. ")+"Resting and waiting also use meals.\nConsider hunting, available traders, or emergency slaughter through Provisions / Cargo.\nTravel is paused. No extra day passed for this warning."
	food_notice.popup_centered(Vector2i(540,190))
	return true

func _advance_day() -> void:
	if not traveling:
		return
	if _warn_food():return
	var before: int = game.state.miles
	var wages_before: int=game.characters.due_total()
	if game.travel():
		landscape.motion = 1.3
	if not game._can_act():
		_pause_travel()
	_refresh()
	if game.characters.due_total()>wages_before:
		_pause_travel()
		_refresh()
		record_notice.title="WAGES DUE"
		record_notice.dialog_text="Agreed wages are due. Open View Party and select the mercenary to pay. Another day without full payment counts as a missed payment."
		record_notice.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		record_notice.get_label().custom_minimum_size.x=500
		record_notice.popup_centered(Vector2i(530,180))
	_check_roadside_graves(before, int(game.state.miles))

func _rest() -> void:
	if not landscape.crossing.is_empty() or _reviewing_crossing():
		return
	if not game.can_service() and not game._can_act():return
	crossing_result = {}
	_pause_travel()
	rest_days_input.text="1"
	_update_rest_quote()
	rest_window.popup_centered(Vector2i(490,220))
	rest_days_input.grab_focus()
	rest_days_input.select_all()

func _update_rest_quote() -> void:
	var value:=rest_days_input.text.strip_edges()
	var valid:=value.is_valid_int() and value.to_int()>=1 and value.to_int()<=30
	rest_window.get_ok_button().disabled=not valid
	if not valid:
		rest_quote.text="Enter a whole number from 1 to 30. No days pass until you confirm."
		return
	var meal:=maxi(1,int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations]))
	rest_quote.text="%d days: %d lb of meals at current rations (%d lb/day).\nFood on hand: %d lb; spoilage can reduce it. Weather, illness and recovery continue. Events, health news or new food warnings stop the rest early." % [value.to_int(),value.to_int()*meal,meal,game.state.food]

func _confirm_rest() -> void:
	_update_rest_quote()
	if rest_window.get_ok_button().disabled:return
	if not landscape.crossing.is_empty() or _reviewing_crossing():return
	_pause_travel()
	var requested:=rest_days_input.text.strip_edges().to_int()
	var completed:=0
	var reason:="Completed the planned rest."
	for day in range(requested):
		if _warn_food():
			reason="Stopped for a food warning."
			break
		var health_news: int=game.health_events.size()
		var living: int=game.state.party_size
		var wages_before: int=game.characters.due_total()
		if not game.rest_in_camp():
			reason="Resolve the current event before resting."
			break
		completed+=1
		camping=true
		if game.characters.due_total()>wages_before:
			reason="Wages are due. Open View Party to pay before another day passes."
			break
		if game.state.status!="traveling":
			reason="The journey has ended."
			break
		if (not game.pending.is_empty() and not game.pending.has("landmark")) or game.health_events.size()>health_news or game.state.party_size!=living:
			reason="Stopped for an event or news from your party."
			break
	var report:="Camp rest: %d of %d day(s). %s" % [completed,requested,reason]
	game.journal.append("Day %d · %s" % [game.state.day,report])
	_refresh()
	if not food_notice.visible:
		record_notice.title="CAMP REST"
		record_notice.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		record_notice.get_label().custom_minimum_size.x=500
		record_notice.dialog_text=report+"\nFood remaining: %d lb. See the journal and party details for daily changes." % game.state.food
		record_notice.popup_centered(Vector2i(530,180))

func _choose(index: int) -> void:
	if not landscape.crossing.is_empty() or _reviewing_crossing():
		return
	if game.can_choose(index) and game.pending.has("landmark") and game.pending.choices[index].get("action", "")=="rest":
		_rest()
		return
	_pause_travel()
	camping = false
	var is_crossing: bool = game.can_choose(index) and game.pending.has("landmark") and game.pending.choices[index].has("method")
	var accepted: bool = game.choose(index)
	if accepted and game.pending.get("service_menu",false):
		_show_service()
	if accepted and is_crossing:
		crossing_result = game.last_crossing.duplicate(true)
		landscape.start_crossing(crossing_result)
	_refresh()

func _crossing_finished() -> void:
	_refresh() # Time and outcome were committed before the animation began.

func _reviewing_crossing() -> bool:
	return not crossing_result.is_empty() and (crossing_result.mishap or crossing_result.lost)

func _acknowledge_crossing() -> void:
	crossing_result = {}
	_refresh()

func _update_animation_pause() -> void:
	landscape.crossing_paused = guide.visible or journal_window.visible or party_window.visible or options_window.visible or service_window.visible or supplies_window.visible or grave_window.visible or memorial_window.visible or record_notice.visible

func _refresh() -> void:
	var s: Dictionary = game.state
	pace.selected = int(s.pace)
	rations.selected = int(s.rations)
	save_button.disabled = s.status not in ["traveling", "arrived", "lost"] or not game.hunt.is_empty() or not landscape.crossing.is_empty() or _reviewing_crossing()
	load_button.disabled = not game.hunt.is_empty() or not landscape.crossing.is_empty() or _reviewing_crossing()
	party_button.disabled = game.party_health.members.is_empty()
	options_button.disabled = not game.can_service() or not landscape.crossing.is_empty() or _reviewing_crossing()
	if party_window.visible:
		_refresh_party()
	var date: Dictionary = game.calendar()
	var months := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
	date_label.text = "%s %d, %d   |   GUIDE MILES %d / %d   |   %s" % [months[date.month - 1], date.day, date.year, s.miles, game.destination(), s.mode.to_upper()]
	if s.status == "outfitting":
		date_label.text = "INDEPENDENCE, 1848   |   PREPARING FOR DEPARTURE   |   CLASSIC"
	stats.text = "FOOD    %4d LB EQ\nHEALTH    %s\nCASH      $%.2f\nOXEN %d   CLOTHES %d\nBULLETS   %d\nSPARES W%d A%d T%d" % [s.food, game.party_condition(), s.money, s.oxen, s.clothing, s.bullets, s.wheels, s.axles, s.tongues]
	stats.text += "\nCARE %d CARGO %.0f/%.0f\n%s\n%s" % [s.medicine, game.provisions.cargo(s),game.provisions.capacity(s), s.weather.to_upper(),"ON FOOT / PACKS" if s.vehicle=="foot" else "TEAM %s / %s" % [game.PartyHealth.condition_label(s.ox_health), "TIRED" if s.fatigue >= 50 else "FRESH"]]
	if s.extended_route:
		var nearby: Dictionary=game.context.market(game)
		stats.text+="\nPOST: STOCK LIMITED" if nearby.post else ("\nTRADERS NEARBY" if nearby.available else "\nNO TRADERS IN SIGHT")
	if s.vehicle == "corolla":
		stats.text += "\nFUEL      %d" % s.fuel
	if not s.items.is_empty():
		stats.text += "\nPACK: " + ", ".join(s.items).to_upper()
	progress.max_value = game.destination()
	progress.value = s.miles
	landscape.terrain = s.terrain
	landscape.miles = s.miles
	landscape.vehicle = s.vehicle
	landscape.walkers=int(s.party_size)
	landscape.encounter = game.pending.get("id", "")
	landscape.weather_id = str(game.survival.weather.get("id", "clear")) if s.extended_route else "clear"
	landscape.scene_id = ""
	if s.extended_route:
		if game.pending.has("landmark") or s.status == "arrived":
			landscape.scene_id = s.landmark
		elif camping and game.pending.is_empty() and s.status == "traveling":
			landscape.scene_id = "camp"
		elif s.miles == 0:
			landscape.scene_id = "independence"
		if _reviewing_crossing():
			landscape.scene_id = crossing_result.landmark
		elif game.service_return.has("landmark"):
			landscape.scene_id = game.service_return.landmark
		elif game.pending.get("service_menu", false):
			landscape.scene_id = "camp"
	if landscape.scene_id == "fort_kearny" and date.year == 1848 and date.month < 6:
		landscape.scene_id = "fort_kearny_early"
	landscape.river_scene = not s.extended_route and s.miles >= 90
	if s.extended_route and not s.next_landmark.is_empty():
		landscape.river_scene = game.route.nodes[s.next_landmark].kind == "river" and s.leg_length - s.leg_miles <= 12
	var animating: bool = not landscape.crossing.is_empty()
	landscape.scrolling = traveling and landscape.scene_id.is_empty() and not animating
	var blocked: bool = animating or _reviewing_crossing() or not game.pending.is_empty() or s.status != "traveling"
	travel_button.disabled = blocked
	travel_button.text = "PAUSE" if traveling else "CONTINUE >"
	rest_button.disabled = animating or _reviewing_crossing() or not (game.can_service() or game._can_act())
	pace.disabled = blocked
	rations.disabled = blocked
	for node in choices.get_children():
		choices.remove_child(node)
		node.queue_free()
	if animating:
		event_title.text = "Crossing " + crossing_result.place
		event_text.text = {"ford": "The oxen pull the wagon through the water.", "float": "The unhitched wagon floats while the oxen cross separately.", "ferry": "The ferry carries the party and their packs." if s.vehicle=="foot" else "The ferry carries the wagon on its wooden platform.","swim":"The party swims across with their packs. The current threatens people and supplies."}.get(crossing_result.method,"The party crosses the river.")
		choices.add_child(button("SKIP ANIMATION", landscape.finish_crossing))
	elif _reviewing_crossing():
		event_title.text = "Crossing mishap!" if crossing_result.mishap else "The journey ends here."
		event_text.text = crossing_result.summary + "\nThe crossing day's rations are counted separately. Recorded in your trail journal."
		choices.add_child(button("ACKNOWLEDGE", _acknowledge_crossing))
	elif not game.pending.is_empty():
		event_title.text = game.pending.title
		event_text.text = game.pending.text
		for i in range(game.pending.choices.size()):
			var choice_label: String=game.pending.choices[i].label
			if game.pending.has("landmark") and game.pending.choices[i].get("action", "")=="rest":choice_label="Rest here · choose number of days"
			var option := button(choice_label, _choose.bind(i))
			option.disabled = not game.can_choose(i)
			choices.add_child(option)
	elif s.status == "arrived":
		event_title.text = game.route.nodes[s.landmark].name if s.extended_route else "The far bank. A beginning."
		event_text.text = (game.journey_summary() + "\n\n" + game.route.nodes[s.landmark].text) if s.extended_route else "The first test leg is complete."
	elif s.status == "lost":
		if game.party_health.members.any(func(member):return not member.alive):choices.add_child(button("LEAVE A GRAVESTONE", _edit_gravestone))
		choices.add_child(button("MEMORIAL BOOK", _show_memorials))
		event_title.text = "The journey ends here."
		event_text.text = s.loss_reason if not s.loss_reason.is_empty() else "Your party can go no farther. Try a new journey with slower travel, fuller rations, or time to camp."
	elif s.status == "error":
		event_title.text = "Content could not be loaded"
		event_text.text = game.error
	elif s.status == "outfitting":
		event_title.text = "Independence"
		event_text.text = "Prepare your wagon before setting out."
	elif not crossing_result.is_empty():
		event_title.text = "Across " + crossing_result.place
		event_text.text = crossing_result.summary
	else:
		event_title.text = "Open prairie"
		var target: String = "Kansas River"
		if s.extended_route:
			target = "%s · %d guide miles ahead" % [game.route.nodes[s.next_landmark].name, s.leg_length - s.leg_miles]
		event_text.text = ("The wagon is rolling." if traveling else "The wagon is stopped. Continue or rest in camp.") + "\nNEXT: " + target + "\nPARTY: " + ", ".join(game.party_health.members.filter(func(member):return game.party_health.is_active(member)).map(func(member):return member.name))
		event_text.text+="\n"+game.context.region(game).label+": "+game.context.region(game).note
		if s.vehicle=="foot":event_text.text=("The party is walking." if traveling else "On foot. Continue or rest; supplies are limited to your packs.")+"\nNEXT: "+target+"\nPARTY: "+", ".join(game.party_health.members.filter(func(member):return game.party_health.is_active(member)).map(func(member):return member.name))+"\n"+game.context.region(game).note
	if s.status=="traveling":
		var concern: String=""
		if not game.pending.is_empty() and game.pending.get("choices",[]).any(func(option):return option.get("combat","")=="defend"):concern=game.characters.concern(game,"defend")
		elif game.pending.is_empty() and s.pace==2 and game.characters.has_sick(game):concern=game.characters.concern(game,"push_sick")
		if not concern.is_empty():event_text.text+="\n"+concern
		if game.pending.has("landmark") and not game.health_events.is_empty():event_text.text+="\nParty news: "+"\n".join(game.health_events)
	journal.text = "\n\n".join(game.journal)
	story_scroll.scroll_vertical = 0

func _show_supplies() -> void:
	options_window.hide()
	_pause_travel()
	for child in supplies_rows.get_children():
		supplies_rows.remove_child(child)
		child.queue_free()
	var fresh: int = game.provisions.fresh_pounds(int(game.state.food))
	var dried: int = game.provisions.preserved_pounds(int(game.state.food))
	var storage_limit: float=game.provisions.storage_capacity(game.state)
	var gear: float=float(game.provisions.data.walking.personal_gear_lb_per_person)*game.state.party_size if game.state.vehicle=="foot" else float(game.provisions.data.household_gear_lb)-float(game.state.get("departed_gear_lb",0))
	var text := "CARGO %.1f / %.0f LB · %s\nSTAPLES %d · FRESH %d · DRIED %d RATION-LB\nSALT %d LB · UP TO %d PARTY-DAYS BEFORE SPOILAGE\nFood uses staple-equivalent pounds; dried meat weighs less.\nFresh lasts two days. Drying costs one day and some food;\nsalt improves yield/storage. Meals are eaten before processing.\nCargo includes %.0f lb personal/household gear. Discards are permanent." % [game.provisions.cargo(game.state), storage_limit,"OVERLOADED" if game.provisions.cargo(game.state) > storage_limit else "WITHIN GUIDELINE", game.state.food - fresh - dried, fresh, dried, game.state.salt, game.provisions.expected_days(game.state.food, game.state.party_size, game.state.rations),gear]
	supplies_rows.add_child(label(text))
	supplies_rows.add_child(label("OXEN %d · GRAZE; DO NOT USE THE PARTY'S FOOD\n%s" % [game.state.oxen,"PACK LIMIT %.0f LB; REDUCE EXCESS BEFORE WALKING" % storage_limit if game.state.vehicle=="foot" else "TEAM LOAD GUIDELINE %.0f LB; EXCESS LOAD SLOWS TRAVEL" % game.provisions.team_capacity(game.state.oxen)]))
	if game.state.vehicle!="foot":supplies_rows.add_child(label("TEAM PULLING SPEED %d%% · 4 NORMAL; 5 +5%%; 6+ +10%%" % roundi(game.survival.team_factor(game.state.oxen)*100)))
	if game.CacheSupport.can_pack(game,false):supplies_rows.add_child(button("ABANDON WAGON / CHOOSE WHAT TO CARRY",func():_show_packing(false)))
	if game.state.vehicle=="foot" and not game.wagon_cache.is_empty():
		var recover:=button("BACKTRACK TO WAGON · MILE %d · LOSS RISK" % game.wagon_cache.mile,func():
			supplies_window.hide()
			var day: int=game.state.day
			if game.recover_wagon():
				_refresh()
				record_notice.title="WAGON RECOVERY"
				record_notice.dialog_text="%d day(s) passed. Now at mile %d.\n%s\nRead the Journal for the journey and supply losses." % [game.state.day-day,game.state.miles,"Wagon recovered." if game.state.vehicle=="wagon" else ("The wagon and its supplies were lost." if game.wagon_cache.is_empty() else "Wagon found. Repack supplies or trade for an ox.")]
				record_notice.popup_centered())
		recover.disabled=not game._can_act()
		supplies_rows.add_child(recover)
		if game.CacheSupport.can_pack(game,true):supplies_rows.add_child(button("REPACK FROM THE CACHED WAGON",func():_show_packing(true)))
	var ox_offer: Dictionary = game.ox_slaughter_offer()
	if not ox_offer.is_empty():
		var slaughter := button("SHOOT / BUTCHER 1 OX · %d LB · 1 BULLET · 1 DAY" % ox_offer.meat,func():_confirm_slaughter(false))
		slaughter.tooltip_text = "Smaller teams pull less cargo and travel slowly. No oxen means no wagon movement. Meat may spoil."
		supplies_rows.add_child(slaughter)
	var hand_offer: Dictionary = game.ox_slaughter_offer(true)
	if not hand_offer.is_empty():
		supplies_rows.add_child(button("BUTCHER BY HAND · NO AMMO · %d%% INJURY RISK · 1 DAY" % roundi(hand_offer.injury_chance*100),func():_confirm_slaughter(true)))
	for salted in [false,true]:
		var offer: Dictionary = game.preservation_offer(salted)
		if offer.is_empty():continue
		var caption := "SALT + DRY" if salted else "DRY MEAT"
		var preserve := button("%s %d LB > %d RATION-LB · 1 DAY · %d LB SALT" % [caption,offer.input,offer.kept,offer.salt],func():
			if game.preserve_meat(salted):
				_refresh()
				_show_supplies())
		preserve.tooltip_text = "Retained food keeps up to %d days after processing. The day's meals are separate." % offer.days
		supplies_rows.add_child(preserve)
	for item in game.provisions.data.weights_lb:
		var amount := mini(int(game.state.get(item, 0)), 50 if item == "food" else (20 if item == "bullets" else 1))
		if amount > 0:
			var discard := button("LEAVE %d %s BEHIND" % [amount, str(item).to_upper()], func():
				game.discard_supply(item, amount)
				_refresh()
				_show_supplies())
			discard.disabled = not game.can_service()
			supplies_rows.add_child(discard)
	supplies_window.popup_centered()

func _packing_cart() -> Dictionary:
	var cart: Dictionary={}
	for key in packing_quantities:cart[key]=int(packing_quantities[key].value)
	return cart
func _update_packing_quote() -> void:
	var quote: Dictionary=game.pack_quote(_packing_cart(),packing_cache_mode)
	packing_quote.text="PACK %.1f / %.1f LB\n%s" % [quote.get("cargo_lb",0),quote.get("capacity_lb",0),quote.message]
	packing_window.get_ok_button().disabled=not quote.valid
func _show_packing(from_cache: bool=false) -> void:
	supplies_window.hide()
	if is_instance_valid(packing_window):packing_window.queue_free()
	packing_cache_mode=from_cache
	packing_quantities={}
	packing_window=AcceptDialog.new()
	packing_window.title="REPACK AT WAGON" if from_cache else "ABANDON THE WAGON?"
	packing_window.get_ok_button().text="REPACK" if from_cache else "LEAVE WAGON"
	packing_window.add_cancel_button("CANCEL")
	add_child(packing_window)
	var content:=VBoxContainer.new()
	content.custom_minimum_size=Vector2(475,0)
	packing_window.add_child(content)
	content.add_child(label("Carry only your packs. Everything else stays at the wagon.\nReturning costs real travel; the cache may be gone or spoiled."))
	var stock: Dictionary=game.CacheSupport.available(game,from_cache)
	var defaults: Dictionary={"clothing":mini(game.state.party_size,stock.clothing),"bullets":mini(40,stock.bullets),"medicine":mini(2,stock.medicine),"salt":mini(2,stock.salt)}
	for key in stock:
		var row:=HBoxContainer.new()
		content.add_child(row)
		var name_label:=label(str(key).to_upper()+" · AVAILABLE %d" % stock[key])
		name_label.custom_minimum_size.x=340
		row.add_child(name_label)
		var quantity:=SpinBox.new()
		quantity.min_value=0
		quantity.max_value=stock[key]
		quantity.step=1
		quantity.custom_minimum_size=Vector2(100,18)
		quantity.value=defaults.get(key,0)
		row.add_child(quantity)
		packing_quantities[key]=quantity
	packing_quote=label("")
	content.add_child(packing_quote)
	var starting_quote: Dictionary=game.pack_quote(_packing_cart(),from_cache)
	packing_quantities.food.value=mini(int(stock.food),maxi(0,floori(float(starting_quote.get("capacity_lb",0))-float(starting_quote.get("cargo_lb",0)))))
	for quantity in packing_quantities.values():quantity.value_changed.connect(func(_value):_update_packing_quote())
	packing_window.confirmed.connect(func():
		packing_window.hide()
		var cart:=_packing_cart()
		if game.repack_wagon_cache(cart) if packing_cache_mode else game.abandon_wagon(cart):
			_refresh()
			_show_supplies())
	packing_window.canceled.connect(func():
		packing_window.hide()
		_show_supplies())
	_update_packing_quote()
	packing_window.popup_centered()

func _confirm_slaughter(by_hand: bool = false) -> void:
	var offer: Dictionary = game.ox_slaughter_offer(by_hand)
	if offer.is_empty():return
	slaughter_by_hand=by_hand
	if not is_instance_valid(slaughter_confirmation):
		slaughter_confirmation=ConfirmationDialog.new()
		slaughter_confirmation.title="SLAUGHTER AN OX?"
		slaughter_confirmation.get_ok_button().text="SLAUGHTER"
		slaughter_confirmation.confirmed.connect(func():
			slaughter_confirmation.hide()
			if game.slaughter_ox(slaughter_by_hand):
				_refresh()
				_show_supplies())
		slaughter_confirmation.canceled.connect(func():
			slaughter_confirmation.hide()
			_show_supplies())
		add_child(slaughter_confirmation)
	slaughter_confirmation.dialog_text="Lose one ox and use %d bullet; spend one camp day.\n%d oxen remain. Below four, pulling speed falls.\nRecover all %d lb usable meat without a hunting carry limit.\nMeals still count. Extra load slows travel; fresh meat spoils.\nYou may need to dry meat or discard cargo.\nThis cannot be undone within the current journey." % [offer.bullets,offer.remaining,offer.meat]
	if offer.remaining==0:slaughter_confirmation.dialog_text+="\nNO TEAM REMAINS. Wagon stops until you acquire another ox."
	elif offer.remaining==1:slaughter_confirmation.dialog_text+="\nONE OX: very slow; load guideline %.0f lb." % game.provisions.team_capacity(1)
	if by_hand:slaughter_confirmation.dialog_text+="\nHousehold tools included; %d%% chance of wounding a traveler." % roundi(offer.injury_chance*100)
	supplies_window.hide()
	slaughter_confirmation.popup_centered()


func _save_journey() -> void:
	if save_button.disabled:
		return
	_pause_travel()
	options_window.hide()
	_refresh()
	record_notice.title = "TRAIL RECORD"
	record_notice.dialog_text = "Journey saved. The previous record is kept as a backup." if save_store.save_game(game, save_path) else save_store.error
	record_notice.popup_centered()

func _load_journey() -> void:
	if load_button.disabled:
		return
	_pause_travel()
	record_notice.title = "TRAIL RECORD"
	var result: Dictionary = save_store.load_game(save_path)
	if not result.is_empty():
		for window in [guide,journal_window,party_window,options_window,food_notice,rest_window,stop_window,service_window,hunt_window,supplies_window,grave_window,memorial_window]:
			window.hide()
		hunt_view.active = false
		landscape.cancel_crossing()
		crossing_result = {}
		camping = false
		selected_member = 0
		game = result.game
		last_food_alert=0
		pace.selected = game.state.pace
		rations.selected = game.state.rations
		seed_input.value = game.state.seed
		_open_departure()
		_refresh()
	visited_graves.clear()
	record_notice.dialog_text = result.message if not result.is_empty() else save_store.error
	record_notice.popup_centered()

func _edit_gravestone() -> void:
	if game.state.status != "lost":
		return
	_pause_travel()
	grave_editing = true
	epitaph_input.show()
	epitaph_input.text = "They followed the western road."
	grave_view.record = grave_store.make_record(game,epitaph_input.text)
	grave_view.queue_redraw()
	grave_window.get_ok_button().text = "LEAVE THIS STONE"
	grave_window.popup_centered()

func _preview_epitaph(text: String) -> void:
	if grave_editing:
		grave_view.record = grave_store.make_record(game,text)
		grave_view.queue_redraw()

func _leave_gravestone() -> void:
	if not grave_editing:
		return
	if grave_store.leave_memorial(game,epitaph_input.text):
		game.journal.append("Left a gravestone at guide mile %d: %s" % [game.state.miles,grave_store.make_record(game,epitaph_input.text).epitaph])
		grave_editing = false
		_refresh()
	else:
		record_notice.dialog_text = grave_store.error
		record_notice.popup_centered()

func _read_gravestone(record: Dictionary) -> void:
	_pause_travel()
	grave_editing = false
	epitaph_input.hide()
	grave_view.record = record.duplicate(true)
	grave_view.queue_redraw()
	grave_window.get_ok_button().text = "CONTINUE"
	grave_window.popup_centered()

func _show_memorials() -> void:
	_pause_travel()
	options_window.hide()
	for child in memorial_rows.get_children():
		memorial_rows.remove_child(child)
		child.queue_free()
	if not grave_store.read_records():
		memorial_rows.add_child(label(grave_store.error))
	elif grave_store.records.is_empty():
		memorial_rows.add_child(label("No gravestones have been left on this trail."))
	else:
		for record in grave_store.records:
			memorial_rows.add_child(button("%s · MILE %d · %s" % [record.name,record.miles,record.date],_read_gravestone.bind(record)))
	memorial_window.popup_centered()

func _check_roadside_graves(before: int, after: int) -> void:
	if game.state.status != "traveling" or after <= before:
		return
	var found: Array[Dictionary] = grave_store.along_route(before,after,visited_graves)
	if found.is_empty():
		return
	# Keep landmark/event state intact; reading a stone advances no simulation time.
	for record in found:
		game.journal.append("Passed a gravestone for %s at guide mile %d." % [record.name,record.miles])
		visited_graves.append(record.id)
	_read_gravestone(found[0])
	_refresh()

