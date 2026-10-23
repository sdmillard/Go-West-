extends Control
const Simulation = preload("res://simulation/trail_engine.gd")
const Landscape = preload("res://ui/trail_view.gd")
const Departure = preload("res://ui/departure_view.gd")
const GraveStore = preload("res://simulation/grave_store.gd")
const GraveView = preload("res://ui/grave_view.gd")
const SaveStore = preload("res://simulation/save_store.gd")
const HuntView = preload("res://ui/hunt_view.gd")
const PostStoreView = preload("res://ui/post_store_view.gd")
const MapView = preload("res://ui/map_view.gd")
const PIXEL_FONT = preload("res://art/pixels/trail_font.fnt")
const LEDGER_ICONS = preload("res://art/pixels/ledger_icons.png")
const TOOLTIP_WIDTH := 240.0
const NOTICE_WIDTH := 460
var game = Simulation.new(1848, "classic", true)
var landscape: Control
var date_label: Label
var stats: Label
var ledger_title: Label
var progress: ProgressBar
var event_title: Label
var event_text: Label
var choices: VBoxContainer
var journal: RichTextLabel
var pace: OptionButton
var rations: OptionButton
var mode: OptionButton
var seed_input: SpinBox
var travel_settings_label: Label
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
var section_window: AcceptDialog
var section_rows: VBoxContainer
var ribbon_buttons: Dictionary={}
var crime_category := ""
## The VILLAINY section a crime, attack or remains preview was opened from; its back button returns there.
var crime_back := ""
const SECTION_PARENTS={"Attack someone":"Villainy","Party member":"Attack someone","Someone here":"Attack someone","Steal":"Villainy","Rob":"Villainy","Preserve meat":"Camp"}
var window_scale: OptionButton
var fullscreen: CheckBox
var travel_speed: OptionButton
var preferences_path := "user://preferences.cfg"
var hunt_window: AcceptDialog
var hunt_view: Control
var hunt_report: Label
var supplies_window: AcceptDialog
var supplies_rows: VBoxContainer
var drop_window: ConfirmationDialog
var slaughter_confirmation: ConfirmationDialog
var slaughter_by_hand := false
var packing_window: AcceptDialog
var packing_quantities: Dictionary={}
var packing_quote: Label
var packing_cache_mode:=false
var dismiss_button: Button
var show_past_travelers := false
var service_window: AcceptDialog
var post_store_window: AcceptDialog
var post_store_view: Panel
var service_rows: VBoxContainer
var story_scroll: ScrollContainer
var place_actions: HFlowContainer
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
var grave_remains: Dictionary = {}
var crossing_result: Dictionary = {}
var map_view: Control
var map_button: Button

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_theme()
	_build_ui()
	travel_timer = Timer.new()
	travel_timer.wait_time = 1.25
	travel_timer.timeout.connect(_advance_day)
	add_child(travel_timer)
	_build_preferences()
	_load_preferences()
	landscape.crossing_finished.connect(_crossing_finished)
	guide.visibility_changed.connect(_update_animation_pause)
	map_view = MapView.new(game)
	add_child(map_view)
	map_view.hide()
	map_view.visibility_changed.connect(_update_animation_pause)
	journal_window.visibility_changed.connect(_update_animation_pause)
	party_window.visibility_changed.connect(_update_animation_pause)
	options_window.visibility_changed.connect(_update_animation_pause)
	section_window.visibility_changed.connect(_update_animation_pause)
	service_window.visibility_changed.connect(_update_animation_pause)
	get_tree().node_added.connect(_wrap_tooltip)
	_normalize_dialog_tree(self)
	grave_store.read_records()
	_open_departure()
	_refresh()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 800, 360), Color("302b2c"))
	# Narrow wood grain bands and brass corner pins, deliberately integer aligned.
	for y in range(0, 360, 12):
		draw_rect(Rect2(0, y, 800, 11), Color("45372f" if y % 24 == 0 else "4e3c31"))
		for x in range(0, 800, 67):
			draw_rect(Rect2(x + (y % 31), y+4, 22, 1), Color("594232"))
	draw_rect(Rect2(3, 3, 794, 354), Color("a16b43"), false, 1)
	draw_rect(Rect2(5, 5, 790, 350), Color("241f22"), false, 1)
	for pos in [Vector2(3, 3), Vector2(794, 3), Vector2(3, 354), Vector2(794, 354)]:
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
	skin.set_stylebox("panel","TabContainer",style("f6e7bc","a16b43",7))
	for tab in ["tab_selected","tab_hovered"]:skin.set_stylebox(tab,"TabBar",style("f6e7bc","a16b43",5))
	skin.set_stylebox("tab_unselected","TabBar",style("76503c","a16b43",5))
	skin.set_color("font_selected_color","TabBar",Color("45372f"))
	skin.set_color("font_hovered_color","TabBar",Color("45372f"))
	skin.set_color("font_unselected_color","TabBar",Color("f6e7bc"))
	skin.set_stylebox("normal", "LineEdit", style("ecd097", "76503c", 3))
	skin.set_stylebox("focus", "LineEdit", style("f6e7bc", "ddb461", 3))
	skin.set_color("font_color", "LineEdit", Color("45372f"))
	skin.set_stylebox("panel", "PopupMenu", style("45372f", "ddb461", 5))
	skin.set_stylebox("hover", "PopupMenu", style("a16b43", "ddb461", 2))
	skin.set_color("font_color", "PopupMenu", Color("f6e7bc"))
	skin.set_color("font_disabled_color", "PopupMenu", Color("aa947b"))
	# Tooltips: dark ink on parchment, like the panels they describe. Wrapping happens in _wrap_tooltip.
	skin.set_stylebox("panel", "TooltipPanel", style("f6e7bc", "76503c", 4))
	skin.set_color("font_color", "TooltipLabel", Color("45372f"))
	skin.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0))
	skin.set_font_size("font_size", "TooltipLabel", 8)
	# SpinBox arrows default to near-white, which vanishes on parchment.
	for arrow in ["up", "down"]:
		skin.set_color(arrow + "_icon_modulate", "SpinBox", Color("76503c"))
		skin.set_color(arrow + "_hover_icon_modulate", "SpinBox", Color("a16b43"))
		skin.set_color(arrow + "_pressed_icon_modulate", "SpinBox", Color("45372f"))
		skin.set_color(arrow + "_disabled_icon_modulate", "SpinBox", Color("c9ad7a"))
	skin.set_stylebox("panel", "AcceptDialog", style("ecd097", "76503c", 10))
	var window_border := style("76503c", "ddb461", 3)
	window_border.expand_margin_top = 15
	skin.set_stylebox("embedded_border", "Window", window_border)
	skin.set_stylebox("embedded_unfocused_border", "Window", window_border)
	skin.set_font("title_font", "Window", PIXEL_FONT)
	skin.set_font_size("title_font_size", "Window", 8)
	skin.set_constant("title_height", "Window", 15)
	var close_image:=Image.create(14,14,false,Image.FORMAT_RGBA8)
	close_image.blit_rect(PIXEL_FONT.get_texture_image(0,Vector2i(8,0),0),Rect2i(64,30,5,7),Vector2i(4,3))
	var close_glyph:=ImageTexture.create_from_image(close_image)
	skin.set_icon("close","Window",close_glyph)
	skin.set_icon("close_pressed","Window",close_glyph)
	skin.set_constant("close_h_offset","Window",18)
	skin.set_constant("close_v_offset","Window",15)
	skin.set_stylebox("background", "ProgressBar", style("302b2c", "76503c", 0))
	skin.set_stylebox("fill", "ProgressBar", style("ddb461", "f6e7bc", 0))
	theme = skin

## Breaks text into lines no wider than width pixels in the pixel font, keeping existing line breaks.
static func wrap_text(text: String, width: float, font_size: int = 8) -> String:
	var lines: Array = []
	for paragraph in text.split("\n"):
		var line := ""
		for word in paragraph.split(" ", false):
			var trial: String = word if line.is_empty() else line + " " + word
			if not line.is_empty() and PIXEL_FONT.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
				lines.append(line)
				line = word
			else:
				line = trial
		lines.append(line)
	return "\n".join(lines)

## Godot's own tooltip label never wraps, so every hint is broken into lines before its popup sizes itself.
func _wrap_tooltip(node: Node) -> void:
	if node is AcceptDialog:_normalize_dialog_tree.call_deferred(node)
	if node is Label and node.theme_type_variation == &"TooltipLabel":
		node.text = wrap_text(node.text, TOOLTIP_WIDTH)

## Notices wrap to a fixed reading width; the height follows the text.
func wrap_dialog(dialog: AcceptDialog, width: int = NOTICE_WIDTH) -> void:
	dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.get_label().custom_minimum_size.x = width

## The shared trail notice, resized to its text so a short message never keeps an earlier long one's size.
func notice(heading: String, text: String) -> void:
	record_notice.title = heading
	record_notice.dialog_text = text
	popup_fitted(record_notice)

## Shrinks a dialog to its current content, then centers it at that size. A bare popup_centered()
## centers a zero-sized window and lets it grow rightward and down off the screen.
func popup_fitted(dialog: Window) -> void:
	dialog.reset_size()
	dialog.popup_centered(dialog.size)

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
	place(subtitle, Rect2(330, 11, 180, 23))
	map_button = button("MAP", _show_map)
	map_button.tooltip_text = "See where you are on a map of the West, with the road you have taken in red."

	date_label = label("")
	date_label.add_theme_color_override("font_color", Color("f6e7bc"))
	place(date_label, Rect2(14, 39, 612, 12))
	panel(Rect2(9, 55, 436, 154), false)
	landscape = Landscape.new()
	place(landscape, Rect2(11, 57, 432, 150))
	var ledger := panel(Rect2(451, 55, 180, 154))
	ledger_title=label("* WAGON LEDGER *")
	place(ledger_title, Rect2(9, 8, 164, 12), ledger)
	stats = label("")
	stats.add_theme_constant_override("line_spacing", 1)
	place(stats, Rect2(21, 25, 152, 100), ledger)
	# One 8 x 8 icon per ledger line (9 px font line + 1 px spacing): food, health, cash, oxen, bullets, spares.
	for row in range(6):
		var icon := AtlasTexture.new()
		icon.atlas = LEDGER_ICONS
		icon.region = Rect2(row * 8, 0, 8, 8)
		var mark := TextureRect.new()
		mark.texture = icon
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		place(mark, Rect2(9, 25 + row * 10, 8, 8), ledger)
	party_button = button("VIEW PARTY", _show_party)
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
	place_actions=HFlowContainer.new()
	place_actions.add_theme_constant_override("h_separation",4)
	place_actions.add_theme_constant_override("v_separation",3)
	story_column.add_child(place_actions)
	event_text = label("")
	event_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_column.add_child(event_text)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 3)
	story_column.add_child(choices)
	panel(Rect2(451, 222, 180, 106))
	travel_settings_label=label("")
	place(travel_settings_label,Rect2(459,231,165,42))
	pace = OptionButton.new()
	for text in ["STEADY", "STRENUOUS", "GRUELING"]:
		pace.add_item(text)
	pace.selected = 1
	pace.item_selected.connect(_settings_changed)
	pace.tooltip_text = "Nominal 22/26/30 miles per day before weather, load, team condition and stops. Faster travel costs health."
	for index in range(3):
		pace.get_popup().set_item_tooltip(index, ["Steady: about 22 miles a day. Easiest on people and oxen.", "Strenuous: about 26 miles a day. More strain on the party and team.", "Grueling: about 30 miles a day. Hard on health; sick travelers suffer most."][index])
	add_child(pace)
	pace.hide()
	rations = OptionButton.new()
	for text in ["BARE", "MEAGER", "FILLING"]:
		rations.add_item(text)
	rations.selected = 1
	rations.item_selected.connect(_settings_changed)
	rations.tooltip_text = "Bare 1, meager 2, filling 3 food units per living traveler per day. Low rations slow recovery even in camp."
	for index in range(3):
		rations.get_popup().set_item_tooltip(index, ["Bare: 1 food unit per traveler a day. Recovery slows and illness risk rises.", "Meager: 2 food units per traveler a day.", "Filling: 3 food units per traveler a day. Best for health and recovery."][index])
	add_child(rations)
	rations.hide()
	travel_button = button("CONTINUE >", _travel)
	place(travel_button, Rect2(459, 282, 91, 37))
	rest_button = button("CAMP", _enter_camp)
	place(rest_button, Rect2(557, 282, 66, 37))
	travel_button.tooltip_text = "Travel automatically. Click Pause to stop; encounters stop the wagon."
	rest_button.tooltip_text = "Set up camp without spending time. Choose rest, preservation or care inside."
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
	wrap_dialog(record_notice)
	add_child(record_notice)
	options_button = button("OPTIONS", _show_preferences)
	options_button.tooltip_text = "Display and automatic travel preferences"
	place(options_button, Rect2(548, 334, 80, 17))
	grave_window = AcceptDialog.new()
	grave_window.title = "A GRAVESTONE ON THE TRAIL"
	grave_window.confirmed.connect(_leave_gravestone)
	grave_window.visibility_changed.connect(_grave_window_closed)
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
	# The guide is longer than the screen is tall, so it scrolls inside a fixed frame.
	var guide_scroll := ScrollContainer.new()
	guide_scroll.custom_minimum_size = Vector2(500, 250)
	guide_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	guide.add_child(guide_scroll)
	var guide_text := label("""Name five travelers, choose a profession and month, then buy supplies. Care kits are optional; keep cash for the road.

Continue advances days; Pause stops the wagon. Encounters and landmarks stop travel. Map, Guide, History, Party and the ribbon sections let you take stock without spending another day. The map shows where you are, with the road you have taken in red. Hover over a control for a short explanation.

Entering Camp spends no time. Choose Rest inside camp to rest people and livestock, using food. Faster travel strains the team; low rations raise illness risk. Clothing protects people in rough weather. Inspect individual travelers.

The right ribbon groups trail actions under Supplies and Hunt & forage, with local opportunities below the picture. Foraging costs one day and meals. Seasonal greens and berries supplement food and supply vitamin C when eaten; fresh meat alone does not prevent scurvy. Hunting costs a day and ammunition. Left-click fires; right-click walks. Cover blocks shots. Game flees; reload between shots. Carry back what your health and willing helpers allow (200 lb maximum). Broken legs prevent hauling.

Each trading visit costs one day, however many trades you make. Trading posts keep a store counter with limited stock; passing traders offer fixed lots at higher prices. Care takes a day each; check costs first.

Recent rain can raise a river while you wait. Low water favors fording; high water is dangerous. Watch team condition and supplies as well as the weather.

This chapter follows Palmer's reported opening route from Independence to Oregon City: 1,938 reported guide miles. The southern road via Bridger and the Barlow Road is playable. The suggested staples provision most of the journey, with resupply. Plan bulk resupply at trading posts; allow for weather delays.

Camp > Preserve meat lets you dry fresh meat, with optional salt. This takes a day. Food units and physical weight are separate: two pounds of new meat supply one food unit. Dried meat weighs less in cargo. Preserved meat also eventually spoils.

Northern shortcuts and Columbia rafting are not yet playable. Weather, medical effects and other survival values remain simplified game rules, not reconstructed conditions for 1848.""")
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_scroll.add_child(guide_text)
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
	var roster_scroll:=ScrollContainer.new()
	roster_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	place(roster_scroll,Rect2(0,22,245,190),party_content)
	party_rows = VBoxContainer.new()
	party_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	party_rows.add_theme_constant_override("separation", 5)
	roster_scroll.add_child(party_rows)
	member_details = RichTextLabel.new()
	member_details.selection_enabled = true
	place(member_details, Rect2(261, 0, 291, 188), party_content)
	wages_button=button("PAY WAGES",_pay_selected_wages)
	place(wages_button,Rect2(261,194,291,22),party_content)
	dismiss_button=button("ASK TO LEAVE",_dismiss_selected)
	place(dismiss_button,Rect2(410,194,142,22),party_content)
	# Gameplay sections have short, contextual trees; Options contains preferences only.
	options_window = AcceptDialog.new()
	options_window.title = "GAME OPTIONS"
	add_child(options_window)
	section_window=AcceptDialog.new()
	section_window.title="TRAIL ACTIONS"
	section_window.get_ok_button().text="BACK"
	section_window.confirmed.connect(_section_back)
	add_child(section_window)
	var section_scroll:=ScrollContainer.new()
	section_scroll.custom_minimum_size=Vector2(380,150)
	section_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	section_window.add_child(section_scroll)
	section_rows=VBoxContainer.new()
	section_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	section_rows.add_theme_constant_override("separation",7)
	section_scroll.add_child(section_rows)
	_build_ribbon()
	food_notice=AcceptDialog.new()
	food_notice.title="FOOD WARNING"
	wrap_dialog(food_notice)
	food_notice.get_ok_button().text="RETURN TO CAMP"
	add_child(food_notice)
	rest_window=ConfirmationDialog.new()
	rest_window.title="REST IN CAMP"
	rest_window.get_ok_button().text="REST"
	rest_window.confirmed.connect(_confirm_rest)
	add_child(rest_window)
	var rest_rows:=Control.new()
	rest_rows.custom_minimum_size=Vector2(460,185)
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
	place(rest_quote,Rect2(0,68,460,117),rest_rows)
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
	hunt_report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(hunt_report, Rect2(0, 154, 432, 57), hunt_content)
	supplies_window = AcceptDialog.new()
	supplies_window.title = "PROVISIONS AND WAGON CARGO"
	add_child(supplies_window)
	var supplies_scroll := ScrollContainer.new()
	supplies_scroll.custom_minimum_size = Vector2(580,250)
	supplies_window.add_child(supplies_scroll)
	drop_window=preload("res://ui/drop_supplies.gd").new()
	add_child(drop_window)
	drop_window.discarded.connect(func():_refresh();_show_supplies())
	drop_window.inventory_requested.connect(_show_supplies)
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
	post_store_window = AcceptDialog.new()
	post_store_window.get_ok_button().text = "BACK TO THE POST"
	post_store_window.confirmed.connect(_close_post_store)
	post_store_window.canceled.connect(_close_post_store)
	add_child(post_store_window)
	post_store_view = PostStoreView.new(game)
	post_store_window.add_child(post_store_view)
	post_store_view.settled.connect(_refresh)

func _build_ribbon() -> void:
	var rail:=panel(Rect2(640,9,150,342))
	place(label("TRAIL ACTIONS"),Rect2(13,10,130,12),rail)
	var specs: Array=[
		["MAP",_show_map,"The road traveled; zoom and pan."],
		["GUIDE",_show_guide,"Read the overland guide."],
		["PARTY",_show_party,"Health, bonds, wages and dismissal."],
		["TRAVEL",_show_section.bind("Travel"),"Choose pace and rations."],
		["SUPPLIES",_show_supplies,"Inventory, drop supplies and abandon/recover the wagon."],
		["HUNT & FORAGE",_show_section.bind("Hunt & forage"),"Find food; review time and ammunition costs."],
		["VILLAINY",_show_section.bind("Villainy"),"Attacks, theft, robbery and handling the dead."],
		["HISTORY",_show_section.bind("History"),"Journal and memorial book."]]
	for index in range(specs.size()):
		var entry: Button=map_button if index==0 else (party_button if index==2 else button(specs[index][0],specs[index][1]))
		entry.text=specs[index][0]
		entry.tooltip_text=specs[index][2]
		place(entry,Rect2(8,29+index*29,134,25),rail)
		ribbon_buttons[specs[index][0]]=entry
	place(label("STOP · CHOOSE · CONTINUE"),Rect2(5,323,140,10),rail)

func _show_options() -> void:
	_show_preferences()

func _section_action(action: Callable) -> void:
	section_window.hide()
	action.call()

func _show_section(section: String) -> void:
	if section!="History" and (not game.can_service() or not landscape.crossing.is_empty() or _reviewing_crossing()):return
	if section=="Drop supplies":
		_show_drop_supplies()
		return
	if section=="Supplies":
		_show_supplies()
		return
	_pause_travel()
	if section in ["Camp","Preserve meat"]:camping=true
	_refresh()
	for setting in [pace,rations]:
		if setting.get_parent()==section_rows:
			section_rows.remove_child(setting)
			add_child(setting)
			setting.hide()
	for child in section_rows.get_children():
		section_rows.remove_child(child)
		child.queue_free()
	map_view.hide()
	section_window.get_child(0).custom_minimum_size.y=190 if section=="Camp" else 150
	section_window.title=section.to_upper()
	section_window.get_ok_button().text="BACK" if SECTION_PARENTS.has(section) else "BACK TO TRAIL"
	var entries: Array=[]
	match section:
		"Travel":
			for setting in [["PACE",pace],["RATIONS",rations]]:
				section_rows.add_child(label(setting[0]))
				if setting[1].get_parent():setting[1].get_parent().remove_child(setting[1])
				section_rows.add_child(setting[1])
				setting[1].show()
				setting[1].custom_minimum_size=Vector2(350,24)
			section_rows.add_child(label("Choices take effect on the next trail day."))
		"Camp":
			var note:=label("Opening camp spends no time or supplies.\nChoose an activity; rest is optional.")
			note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			section_rows.add_child(note)
			entries=[["REST · CHOOSE DAYS",_rest],["PRESERVE MEAT >",_show_section.bind("Preserve meat")],["CARE / MEDICAL ATTENTION",_open_care]]
		"Preserve meat":
			section_rows.add_child(label("Processing uses a work day, not a rest day.\nMeals and spoilage happen before processing."))
			var available:=false
			for salted in [false,true]:
				var offer: Dictionary=game.preservation_offer(salted)
				if offer.is_empty():continue
				available=true
				var caption := "SALT + DRY" if salted else "DRY MEAT"
				var preserve:=button("%s %.0f LB > %d FOOD UNITS · 1 DAY · %d LB SALT" % [caption,offer.mass,offer.kept,offer.salt],_section_action.bind(_preserve_in_camp.bind(salted)))
				preserve.tooltip_text="Keeps up to %d days after processing; meals are separate." % offer.days
				section_rows.add_child(preserve)
			if not available:section_rows.add_child(label("No suitable fresh meat can be preserved now.\nSalt-assisted drying also requires enough salt."))
		"Hunt & forage":entries=[["HUNT · 1 DAY, UP TO 5 SHOTS",_start_hunt],["FORAGE FOR GREENS AND BERRIES",_open_forage]]
		"Villainy":entries=[["ATTACK SOMEONE >",_show_section.bind("Attack someone")],["STEAL >",_show_section.bind("Steal")],["ROB >",_show_section.bind("Rob")],["THE DEAD: BURY, CARRY OR SEARCH >",_open_villainy_remains]]
		"Attack someone":
			entries=[["PARTY MEMBER >",_show_section.bind("Party member")],["SOMEONE HERE >",_show_section.bind("Someone here")]]
		"Someone here":
			var targets: Array=game.crime.local_targets(game)
			for person in targets:
				var target:=button(person.name.to_upper()+" >",_section_action.bind(_open_local_attack.bind(person.uid)))
				target.custom_minimum_size.y=27
				target.set_meta("local_target",person.uid)
				section_rows.add_child(target)
			if targets.is_empty():section_rows.add_child(label("No local encounter targets are present."))
		"Party member":
			for member in game.party_health.members:
				if int(member.id)==0 or not game.party_health.is_active(member):continue
				var target:=button(member.name.to_upper()+" >",_section_action.bind(_open_party_attack.bind(int(member.id))))
				target.custom_minimum_size.y=27
				target.set_meta("attack_target",int(member.id))
				target.disabled=not game.crime.can_attack(game,int(member.id))
				section_rows.add_child(target)
			if section_rows.get_child_count()==0:section_rows.add_child(label("No companion is here to target."))
		"Steal","Rob":
			# Every store, post, gate, ferry, trading party or camp within reach is its own branch, like ATTACK SOMEONE > SOMEONE HERE.
			var category: String="theft" if section=="Steal" else "robbery"
			var places: Array=game.crime.local_places(game,game.pending) if game.crime.incident().is_empty() else []
			for place in places:
				var target:=button(game.crime.place_label(game,place).to_upper()+" >",_section_action.bind(_open_crime_at.bind(place,category)))
				target.custom_minimum_size.y=27
				target.set_meta("crime_place",place)
				section_rows.add_child(target)
			if places.is_empty():
				var none:=label("Nobody here to %s. Stop at a trading post, the Kansas River ferry, Fort Kearny once soldiers are there, or the Barlow Road toll gate, or meet passing traders or an emigrant camp on the road." % ("steal from" if section=="Steal" else "rob"))
				none.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				none.custom_minimum_size.x=330
				section_rows.add_child(none)
		"History":entries=[["TRAIL JOURNAL",_show_journal],["MEMORIAL BOOK",_show_memorials]]
	for item in entries:
		var entry:=button(item[0],_section_action.bind(item[1]))
		entry.custom_minimum_size.y=27
		if item[1]==Callable(self,"_start_hunt"):entry.disabled=not game.pending.is_empty() or game.state.bullets==0
		section_rows.add_child(entry)
	if SECTION_PARENTS.has(section):section_rows.add_child(button("< "+str(SECTION_PARENTS[section]).to_upper(),_section_action.bind(_show_section.bind(SECTION_PARENTS[section]))))
	section_window.reset_size()
	section_window.popup_centered()

func _enter_camp() -> void:
	_show_section("Camp")

func _show_drop_supplies() -> void:
	if not game.can_service() or not landscape.crossing.is_empty() or _reviewing_crossing():return
	_pause_travel()
	section_window.hide()
	supplies_window.hide()
	drop_window.open(game)

func _preserve_in_camp(salted: bool) -> void:
	if not camping:return
	if game.preserve_meat(salted):
		_refresh()
		if game.can_service():_show_section("Preserve meat")

func _section_back() -> void:
	var parent := ""
	# Titles are upper case; match the authored section spelling.
	for child in SECTION_PARENTS:
		if child.to_upper()==section_window.title:parent=SECTION_PARENTS[child]
	if not parent.is_empty():_show_section.call_deferred(parent)

func _open_party_attack(id: int) -> void:
	section_window.hide()
	selected_member=id
	crime_back="Party member"
	_attack_selected()

func _open_local_attack(uid: String) -> void:
	section_window.hide()
	crime_category="attack"
	crime_back="Someone here"
	if game.open_local_attack(uid):_show_service()
	_refresh()

func _open_crime_category(category: String) -> void:
	crime_category=category
	_open_crime()

## VILLAINY > STEAL or ROB > a place: the preview shows only that act against that place.
func _open_crime_at(place: String,category: String) -> void:
	crime_category=category
	crime_back="Steal" if category=="theft" else "Rob"
	if game.open_crime(place):_show_service()
	_refresh()

func _open_villainy_remains() -> void:
	crime_back="Villainy"
	_open_remains()

## Leave a preview opened from VILLAINY without acting and return to the branch it came from.
func _villainy_back() -> void:
	var section:=crime_back
	crime_category=""
	_cancel_service()
	if game.pending.is_empty() or not game.pending.get("service_menu",false):_show_section(section)

func _filter_crime(category: String) -> void:
	crime_category=category
	_show_service()

func _open_trade() -> void:
	options_window.hide()
	crossing_result = {}
	# A post or passing party that will deal with the party opens the trading counter; refusals and waiting use the menu.
	if _open_counter(""):return
	if game.open_trade():
		_show_service()
	_refresh()

## Open the trading counter for a post, a passing party, or (venue "camp") the emigrant family; false when nobody will trade.
func _open_counter(venue: String) -> bool:
	var counter: Dictionary = game.trade_counter(venue)
	if counter.is_empty():return false
	_pause_travel()
	post_store_view.game = game
	post_store_window.title = {"post": "TRADING AT " + str(counter.name).to_upper(), "traders": "TRADING WITH PASSING TRADERS", "camp": "TRADING WITH AN EMIGRANT FAMILY"}[counter.kind]
	post_store_view.open(venue)
	post_store_window.popup_centered()
	return true

func _close_post_store() -> void:
	post_store_window.hide()
	_refresh()
	# Trading with a family returns to their camp's menu.
	if post_store_view.venue == "camp" and game.pending.get("service_menu",false):_show_service()

func _open_forage() -> void:
	options_window.hide()
	crossing_result = {}
	if game.open_forage(): _show_service()
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
	section_window.hide()
	options_window.hide()
	if game.open_crime():_show_service()
	else:
		notice("NOTHING TO TAKE HERE","Stop at a trading post, the Kansas River ferry, Fort Kearny once soldiers are there, or the Barlow Road toll gate, or meet passing traders on the road, to use these actions.")

func _open_camp() -> void:
	options_window.hide()
	crime_category=""
	if game.open_camp():_show_service()
	else:
		notice("NO CAMP NEARBY","Emigrant families camp near the road every so often. When one is close, you can visit, trade, ask for help or swap news.")

func _open_remains() -> void:
	options_window.hide()
	if game.open_remains():_show_service()
	else:
		notice("NOBODY TO TEND","There are no remains here or in the wagon. A body stays where its person died unless you carry it.")

func _show_service() -> void:
	for child in service_rows.get_children():
		service_rows.remove_child(child)
		child.queue_free()
	service_window.title = game.pending.title
	service_window.get_ok_button().text="CLOSE PANEL" if game.pending.get("crime_menu",false) and not game.crime.record.active.is_empty() else "BACK TO TRAIL"
	var description: String=game.pending.text
	if game.pending.get("crime_menu",false) and game.crime.incident().get("stage","")=="loot":
		var current: Dictionary=game.crime.incident()
		if int(game.crime.rules(current.place).loot_limit)>0:
			var quote: Dictionary=game.crime.loot_quote(game,current.place)
			description+="\n"+("The wagon is alongside for loading." if quote.wagon_access else "Carry it away on foot: willing helpers can haul up to %d lb at their current health. Broken legs prevent hauling." % quote.haul_limit_lb)
	# An emigrant camp is a place of its own: its picture heads the menu.
	if game.pending.has("camp"):
		var camp_picture:=TextureRect.new()
		var camp_atlas:=AtlasTexture.new()
		camp_atlas.atlas=landscape.scenes.texture_for("camp_trade")
		camp_atlas.region=Rect2(0,98,432,134)
		camp_picture.texture=camp_atlas
		camp_picture.custom_minimum_size=Vector2(432,134)
		camp_picture.stretch_mode=TextureRect.STRETCH_KEEP_CENTERED
		service_rows.add_child(camp_picture)
	var explanation := label(description)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	service_rows.add_child(explanation)
	if game.pending.get("recruit_menu",false):
		var candidate: Dictionary=game.recruitment.candidate(game)
		if not candidate.is_empty():
			var picture:=TextureRect.new()
			var atlas:=AtlasTexture.new()
			atlas.atlas=preload("res://ui/traveler_palette.gd").texture(preload("res://art/pixels/walker.png"),candidate.profile)
			atlas.region=Rect2(0,int(candidate.profile.appearance.outfit)*24,16,24)
			picture.texture=atlas
			picture.custom_minimum_size=Vector2(32,48)
			picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			service_rows.add_child(picture)
	var crime_preview: bool=game.pending.get("crime_menu",false) and game.crime.record.active.is_empty()
	# Only a preview reached through VILLAINY keeps its way back there.
	if not (crime_preview or game.pending.get("attack_menu",false) or game.pending.get("remains_menu",false)):crime_back=""
	# At an emigrant camp, nursing requests sit behind one ASK FOR CARE branch listing the travelers.
	var camp_menu: bool=game.pending.has("camp")
	var care_offered:=false
	for index in range(game.pending.choices.size() - 1):
		if camp_menu:
			var care: bool=game.pending.choices[index].has("care")
			if care and crime_category!="care":
				if not care_offered:service_rows.add_child(button("ASK FOR CARE >",_filter_crime.bind("care")))
				care_offered=true
				continue
			if crime_category=="care" and not care:continue
		if crime_preview:
			var command: String=game.pending.choices[index].get("crime_command","")
			# VILLAINY picked the act; a preview restored from a save without one lists every act.
			if not crime_category.is_empty() and command not in (["shoot","assault"] if crime_category=="attack" else [crime_category,"raid"]):continue
		# Fixed offers the trading counter already covers are kept for the study policies only.
		if game.pending.choices[index].get("policy_only",false):continue
		var option := button(game.pending.choices[index].label, _service_choice.bind(index))
		option.disabled = not game.can_choose(index)
		service_rows.add_child(option)
	if not crime_back.is_empty():service_rows.add_child(button("< "+crime_back.to_upper(),_villainy_back))
	elif camp_menu and not crime_category.is_empty():service_rows.add_child(button("OTHER ACTIONS HERE <",_filter_crime.bind("")))
	elif camp_menu:service_rows.add_child(button("LEAVE CAMP <",_cancel_service))
	service_window.popup_centered()

func _service_choice(index: int) -> void:
	crime_category=""
	service_window.hide()
	if game.pending.choices[index].has("counter"):
		_open_counter(str(game.pending.choices[index].counter))
		return
	var burial: int = int(game.pending.choices[index].get("remains_id",-1)) if game.pending.get("remains_menu",false) and game.pending.choices[index].get("remains_command","")=="bury" else -1
	var shooting: bool = game.pending.get("attack_menu",false) and int(game.pending.choices[index].get("attack_target",-1)) >= 0
	var attacks: int = game.crime.record.attacks.size()
	var written: int = game.journal.size()
	_choose(index)
	if shooting and game.crime.record.attacks.size() > attacks:
		_show_attack_result(game.journal.slice(written))
	if burial >= 0 and game.state.status == "traveling":
		var grave: Dictionary = game.Remains.entry(game,burial)
		if grave.get("state","") == "buried":
			# One dialog at a time: the remains panel returns once the stone is set or declined.
			service_window.hide()
			_edit_gravestone(grave)

## Everything the shot set off, at once: the result, who fought back, who objected and who left with what.
## The journal keeps the full per-person record; this notice summarizes it in a few short lines.
func _show_attack_result(lines: Array) -> void:
	var attack: Dictionary = game.crime.record.attacks.back()
	var members: Array = game.party_health.members
	var target: String = members[int(attack.target)].name
	var names := func(ids: Array) -> String: return ", ".join(ids.map(func(id): return members[int(id)].name))
	var verb: String = "attacked unarmed" if attack.get("weapon","gun") == "unarmed" else "shot at"
	var said: Array = ["You %s %s: %s." % [verb, target, attack.attempt]]
	for line in lines:
		var text: String = str(line)
		if " fought back" in text or "unarmed struggle" in text:
			said.append(text.substr(text.find(" · ") + 3) if " · " in text else text)
	var helpers: Array = attack.joining.filter(func(id): return int(id) > 0)
	if not helpers.is_empty():
		said.append("Joined you: %s." % names.call(helpers))
	var by_answer := func(answers: Array) -> Array: return attack.responses.keys().filter(func(key): return attack.responses[key] in answers).map(func(key): return int(key))
	var gone: Array = by_answer.call(["fled", "retaliated"]).filter(func(id): return members[id].get("departed", false))
	if not gone.is_empty():
		var food := 0
		var clothing := 0
		var gear := 0
		for id in gone:
			var share: Dictionary = members[id].get("departure_supplies", {})
			food += int(share.get("food", 0))
			clothing += int(share.get("clothing", 0))
			gear += int(share.get("gear_lb", 0))
		said.append("Fled: %s. They took %d ration-lb food, %d clothing set%s and %d lb personal gear." % [names.call(gone), food, clothing, "" if clothing == 1 else "s", gear])
	var objecting: Array = by_answer.call(["objected"])
	if not objecting.is_empty():
		said.append("Objected: %s." % names.call(objecting))
	var standing: Array = by_answer.call(["stood by"])
	if not standing.is_empty():
		said.append("Stood by: %s." % names.call(standing))
	said.append(("No ammunition used." if attack.get("weapon","gun")=="unarmed" else "One bullet used.")+" The journal and View Party have the details.")
	notice("YOU %s %s" % [verb.to_upper(),target.to_upper()], "\n".join(said))

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
		# Use the first active traveler for the visible hunter, including after a leader death.
		var shooter: Dictionary=game.party_health.members.filter(func(member):return game.party_health.is_active(member))[0]
		hunt_view.traveler_profile=game.characters.profiles[int(shooter.id)]
		hunt_view.encounter = game.hunt
		hunt_view.active = true
		_update_hunt_report()
		hunt_window.popup_centered()
	_refresh()

func _update_hunt_report() -> void:
	if not game.hunt.is_empty():
		hunt_report.text = "%s · %ds · %s · SHOTS %d/5 · AMMO %d\nLEFT: FIRE · RIGHT: WALK · MEAT %d LB / HAUL LIMIT %d LB\n%s" % [game.hunt.region_label.to_upper(), ceili(30 - game.hunt.elapsed), "RELOAD" if game.hunt.reload > 0 else "READY", game.hunt.shots, game.state.bullets, game.hunt.meat, game.hunting_capacity(), game.hunt.message]


func _finish_hunt() -> void:
	hunt_window.hide()
	hunt_view.active = false
	if game.hunt.is_empty():
		return
	var outing: Dictionary = game.hunt.duplicate(true)
	var recovered: Dictionary=game.hunt_recovery()
	var before: int = game.state.food
	if game.finish_hunt():
		var carried: int = game.state.food - before
		notice("HUNTING REPORT","%d shots · %d lb meat obtained\n%d lb brought to camp · %d lb left behind\nUse fresh meat within two trail days, or dry it through Camp > Preserve meat. Salt improves the result.\nRecovered meat supplies %d food units.\nThe outing used one day and that day's rations." % [outing.shots,outing.meat,recovered.mass,recovered.left,carried])
	camping = true
	_refresh()

func _show_party() -> void:
	section_window.hide()
	map_view.hide()
	if game.party_health.members.is_empty():
		return
	_pause_travel()
	_refresh()
	_refresh_party()
	party_window.popup_centered()

func _select_member(index: int) -> void:
	if index<game.party_health.members.size() and not game.party_health.is_active(game.party_health.members[index]):show_past_travelers=true
	selected_member = index
	_refresh_party()

func _refresh_party() -> void:
	wages_button.hide()
	dismiss_button.hide()
	wages_button.size.x=291
	member_details.size.y=216
	for node in party_rows.get_children():
		party_rows.remove_child(node)
		node.queue_free()
	if game.party_health.members.is_empty():
		member_details.text = "Outfit your party before departure."
		return
	selected_member = clampi(selected_member, 0, game.party_health.members.size() - 1)
	for id in game.current_party_slots():
		if int(id)<0:
			var vacancy:=button("EMPTY SLOT · FIND A COMPANION",_open_companions)
			vacancy.custom_minimum_size.y=33
			vacancy.disabled=not game.can_service() or game.recruitment.site(game).is_empty()
			party_rows.add_child(vacancy)
		else:_add_party_row(game.party_health.members[int(id)])
	var past: Array=game.party_health.members.filter(func(member):return not game.party_health.is_active(member))
	if not past.is_empty():
		var history:=button(("HIDE" if show_past_travelers else "SHOW")+" PAST TRAVELERS · %d" % past.size(),_toggle_party_history)
		history.name="PartyHistory"
		party_rows.add_child(history)
		if show_past_travelers:
			for member in past:_add_party_row(member)
	member_details.text = game.party_health.description(selected_member).replace("PERSONAL HISTORY",game.characters.description(selected_member)+("\n\n"+game.social.description(game,selected_member) if selected_member>0 else "")+"\n\nHEALTH HISTORY")
	if selected_member<game.characters.profiles.size():
		var contract: Dictionary=game.characters.profiles[selected_member].contract
		if not contract.is_empty():
			member_details.size.y=188
			wages_button.show()
			wages_button.text="PAY WAGES OWED · $%.2f" % (contract.arrears_cents/100.0)
			wages_button.disabled=contract.arrears_cents<=0 or roundi(game.state.money*100)<contract.arrears_cents or not game.characters.can_receive_wages(game,selected_member)
	if selected_member>0 and game.party_health.is_active(game.party_health.members[selected_member]):
		member_details.size.y=188
		dismiss_button.show()
		dismiss_button.disabled=not game.recruitment.eligible_dismiss(game,selected_member)
		dismiss_button.position.x=410 if wages_button.visible else 261
		dismiss_button.size.x=142 if wages_button.visible else 291
		if wages_button.visible:wages_button.size.x=143

func _add_party_row(member: Dictionary) -> void:
	var condition: String = "LEFT PARTY" if member.get("departed",false) else (game.PartyHealth.condition_label(member.health) if member.alive else "DECEASED")
	var text: String = member.name.to_upper() + " · " + condition
	if game.party_health.is_active(member) and not member.conditions.is_empty():
		var active: Dictionary = member.conditions[0]
		text += "\n" + str(game.party_health.conditions[active.id].name)
	var row := button(text, _select_member.bind(int(member.id)))
	var portrait := AtlasTexture.new()
	var profile: Dictionary=game.characters.profiles[int(member.id)] if int(member.id)<game.characters.profiles.size() else {"id":int(member.id)}
	portrait.atlas=preload("res://ui/traveler_palette.gd").texture(preload("res://art/pixels/walker.png"),profile)
	portrait.region=Rect2(0,int(profile.get("appearance",{}).get("outfit",int(member.id)%2))*24,16,24)
	row.icon=portrait
	row.add_theme_constant_override("icon_max_width",16)
	row.custom_minimum_size.y = 33
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.tooltip_text = "View condition and personal history"
	party_rows.add_child(row)
	row.set_meta("traveler_id",int(member.id))

func _toggle_party_history() -> void:
	show_past_travelers=not show_past_travelers
	_refresh_party()

func _open_companions() -> void:
	options_window.hide()
	party_window.hide()
	_pause_travel()
	if game.open_companions():_show_service()
	_refresh()

func _dismiss_selected() -> void:
	if game.open_dismiss(selected_member):
		party_window.hide()
		_show_service()

func _attack_selected() -> void:
	if game.open_attack(selected_member):
		party_window.hide()
		_show_service()

func _pay_selected_wages() -> void:
	if game.characters.pay_wages(game,selected_member):
		_refresh()
		_refresh_party()

func _show_map() -> void:
	section_window.hide()
	_pause_travel()
	map_view.game = game
	move_child(map_view, -1)
	map_view.open()
	_refresh()

func _show_guide() -> void:
	section_window.hide()
	_pause_travel()
	_refresh()
	guide.popup_centered()

func _show_journal() -> void:
	section_window.hide()
	_pause_travel()
	_refresh()
	journal_window.popup_centered()

func _new_journey() -> void:
	drop_window.hide()
	section_window.hide()
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
	popup_fitted(food_notice)
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
	if game.pending.get("crime_menu",false):_show_service()
	if game.characters.due_total()>wages_before:
		_pause_travel()
		_refresh()
		notice("WAGES DUE","Agreed wages are due. Open View Party and select the mercenary to pay. Another day without full payment counts as a missed payment.")
	_check_roadside_graves(before, int(game.state.miles))

func _rest() -> void:
	section_window.hide()
	if not landscape.crossing.is_empty() or _reviewing_crossing():
		return
	if not game.can_service() and not game._can_act():return
	crossing_result = {}
	_pause_travel()
	rest_days_input.text="1"
	_update_rest_quote()
	rest_window.popup_centered(Vector2i(490,252))
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
	rest_quote.text="%d days: %d food units at current rations (%d/day).\nFood on hand: %d units; spoilage can reduce it. Weather, illness and recovery continue. Events, health news or new food warnings stop the rest early." % [value.to_int(),value.to_int()*meal,meal,game.state.food]

	var season: String=game.season_notice()
	if season.is_empty():season=game.season_notice(value.to_int())
	if not season.is_empty():rest_quote.text+="\n"+season

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
	if game.pending.get("crime_menu",false):
		_show_service()
		return
	if not food_notice.visible:
		notice("CAMP REST",report+"\nFood remaining: %d units. See the journal and party details for daily changes." % game.state.food)

func _choose(index: int) -> void:
	if not landscape.crossing.is_empty() or _reviewing_crossing():
		return
	if game.can_choose(index) and game.pending.has("landmark") and game.pending.choices[index].get("action", "")=="rest":
		_rest()
		return
	_pause_travel()
	if game.can_choose(index) and (game.pending.choices[index].get("action","") in ["leave","cross"] or game.pending.choices[index].has("method")):camping=false
	var is_crossing: bool = game.can_choose(index) and game.pending.has("landmark") and game.pending.choices[index].has("method")
	var return_to_camp: bool=game.pending.get("id","") in ["packs_too_heavy","no_team"]
	var accepted: bool = game.choose(index)
	if accepted and return_to_camp and game.can_service():_enter_camp()
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
	landscape.crossing_paused = map_view.visible or drop_window.visible or section_window.visible or guide.visible or journal_window.visible or party_window.visible or options_window.visible or service_window.visible or supplies_window.visible or grave_window.visible or memorial_window.visible or record_notice.visible

func _refresh() -> void:
	var s: Dictionary = game.state
	_refresh_place_actions()
	pace.selected = int(s.pace)
	rations.selected = int(s.rations)
	travel_settings_label.text="PACE: %s\nRATIONS: %s\nCHANGE: TRAVEL >" % [pace.get_item_text(pace.selected),rations.get_item_text(rations.selected)]
	save_button.disabled = s.status not in ["traveling", "arrived", "lost"] or not game.hunt.is_empty() or not landscape.crossing.is_empty() or _reviewing_crossing()
	load_button.disabled = not game.hunt.is_empty() or not landscape.crossing.is_empty() or _reviewing_crossing()
	party_button.disabled = game.party_health.members.is_empty()
	options_button.disabled = not game.hunt.is_empty() or not landscape.crossing.is_empty() or _reviewing_crossing()
	for key in ribbon_buttons:
		if key not in ["MAP","GUIDE","PARTY","HISTORY"]:ribbon_buttons[key].disabled=not game.can_service() or not landscape.crossing.is_empty() or _reviewing_crossing()
	if party_window.visible:
		_refresh_party()
	var date: Dictionary = game.calendar()
	var months := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
	date_label.text = "%s %d, %d   |   GUIDE MILES %d / %d   |   %s" % [months[date.month - 1], date.day, date.year, s.miles, game.destination(), s.mode.to_upper()]
	if s.status == "outfitting":
		date_label.text = "INDEPENDENCE, 1848   |   PREPARING FOR DEPARTURE   |   CLASSIC"
	ledger_title.text="* PACKS & LIVESTOCK *" if s.vehicle=="foot" else "* WAGON LEDGER *"
	stats.text = "FOOD    %4d UNITS\nHEALTH    %s\nCASH      $%.2f\nOXEN %d   CLOTHES %d\nBULLETS   %d\nSPARES W%d A%d T%d" % [s.food, game.party_condition(), s.money, s.oxen, s.clothing, s.bullets, s.wheels, s.axles, s.tongues]
	stats.text += "\nCARE %d CARGO %.0f/%.0f\n%s\n%s" % [s.medicine, game.provisions.cargo(s),game.provisions.capacity(s), s.weather.to_upper(),"ON FOOT / PACKS" if s.vehicle=="foot" else "TEAM %s / %s" % [game.PartyHealth.condition_label(s.ox_health), "TIRED" if s.fatigue >= 50 else "FRESH"]]
	if s.vehicle=="foot" and s.oxen>0:stats.text+="\nHERD "+game.PartyHealth.condition_label(s.ox_health).to_upper()
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
	landscape.herded_oxen=int(s.oxen) if s.vehicle=="foot" else 0
	landscape.walkers=int(s.party_size)
	landscape.traveler_profiles=game.characters.profiles.filter(func(profile):return int(profile.id)<game.party_health.members.size() and game.party_health.is_active(game.party_health.members[int(profile.id)]))
	landscape.encounter = game.pending.get("id", "")
	landscape.weather_id = str(game.survival.weather.get("id", "clear")) if s.extended_route else "clear"
	landscape.scene_id = ""
	if s.extended_route:
		if camping and s.status=="traveling":
			landscape.scene_id="camp"
		elif game.pending.has("landmark") or s.status == "arrived":
			landscape.scene_id = s.landmark
		elif s.miles == 0:
			landscape.scene_id = "independence"
		if _reviewing_crossing():
			landscape.scene_id = crossing_result.landmark
		elif game.service_return.has("landmark") and not camping:
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
		var season: String=game.season_notice()
		if not season.is_empty():event_text.text+="\n"+season
		var concern: String=""
		if not game.pending.is_empty() and game.pending.get("choices",[]).any(func(option):return option.get("combat","")=="defend"):concern=game.characters.concern(game,"defend")
		elif game.pending.is_empty() and s.pace==2 and game.characters.has_sick(game):concern=game.characters.concern(game,"push_sick")
		if not concern.is_empty():event_text.text+="\n"+concern
		if game.pending.has("landmark") and not game.health_events.is_empty():event_text.text+="\nParty news: "+"\n".join(game.health_events)
	journal.text = "\n\n".join(game.journal)
	story_scroll.scroll_vertical = 0

func _show_supplies() -> void:
	if not game.can_service() or not landscape.crossing.is_empty() or _reviewing_crossing():return
	for setting in [pace,rations]:setting.hide()
	section_window.hide()
	options_window.hide()
	_pause_travel()
	for child in supplies_rows.get_children():
		supplies_rows.remove_child(child)
		child.queue_free()
	supplies_window.title="SUPPLIES & PACKS" if game.state.vehicle=="foot" else "SUPPLIES & WAGON CARGO"
	var actions:=HBoxContainer.new()
	actions.name="InventoryActions"
	actions.add_theme_constant_override("separation",8)
	supplies_rows.add_child(actions)
	var drop:=button("DROP SUPPLIES >",func():
		supplies_window.hide()
		_show_drop_supplies())
	drop.name="DropSupplies"
	actions.add_child(drop)
	if game.CacheSupport.can_pack(game,false):
		var abandon:=button("ABANDON WAGON / CHOOSE PACKS",func():_show_packing(false))
		abandon.name="AbandonWagon"
		actions.add_child(abandon)
	var load: float=game.provisions.cargo(game.state)
	var capacity: float=game.provisions.storage_capacity(game.state)
	supplies_rows.add_child(label("%s %.1f / %.0f LB · %s" % ["PACKS" if game.state.vehicle=="foot" else "WAGON CARGO",load,capacity,"OVERLOADED" if load>capacity else "WITHIN LIMIT"]))
	var meter:=ProgressBar.new()
	meter.custom_minimum_size.y=7
	meter.max_value=maxf(1,capacity)
	meter.value=load
	meter.show_percentage=false
	supplies_rows.add_child(meter)
	var ledger:=preload("res://ui/inventory_ledger.gd").new(game)
	ledger.name="InventoryLedger"
	supplies_rows.add_child(ledger)
	var transport: VBoxContainer=ledger.get_meta("transport_rows")
	if game.state.vehicle=="foot" and not game.wagon_cache.is_empty():
		var recover:=button("RECOVER WAGON · MILE %d" % game.wagon_cache.mile,_recover_wagon)
		recover.disabled=not game._can_act()
		transport.add_child(recover)
		if game.CacheSupport.can_pack(game,true):transport.add_child(button("REPACK FROM THE CACHED WAGON",func():_show_packing(true)))
	var ox_offer: Dictionary = game.ox_slaughter_offer()
	if not ox_offer.is_empty():
		var slaughter := button("SHOOT / BUTCHER 1 OX · %d LB · 1 BULLET · 1 DAY" % ox_offer.meat,func():_confirm_slaughter(false))
		slaughter.tooltip_text = "Smaller teams pull less cargo and travel slowly. No oxen means no wagon movement. Meat may spoil."
		transport.add_child(slaughter)
	var hand_offer: Dictionary = game.ox_slaughter_offer(true)
	if not hand_offer.is_empty():
		transport.add_child(button("BUTCHER BY HAND · NO AMMO · %d%% INJURY RISK · 1 DAY" % roundi(hand_offer.injury_chance*100),func():_confirm_slaughter(true)))
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
		wrap_dialog(slaughter_confirmation)
		slaughter_confirmation.confirmed.connect(func():
			slaughter_confirmation.hide()
			if game.slaughter_ox(slaughter_by_hand):
				_refresh()
				_show_supplies())
		slaughter_confirmation.canceled.connect(func():
			slaughter_confirmation.hide()
			_show_supplies())
		add_child(slaughter_confirmation)
	slaughter_confirmation.dialog_text="Lose one ox and use %d bullet; spend one camp day.\n%d oxen remain. Below four, pulling speed falls.\nRecover all %d lb usable meat without a hunting carry limit.\nMeat supplies %d food units before meals. Extra load slows travel; fresh meat spoils.\nYou may need to dry meat or discard cargo.\nThis cannot be undone within the current journey." % [offer.bullets,offer.remaining,offer.meat,game.provisions.meat_units(int(offer.meat))]
	if offer.remaining==0:slaughter_confirmation.dialog_text+="\nNO TEAM REMAINS. Wagon stops until you acquire another ox."
	elif offer.remaining==1:slaughter_confirmation.dialog_text+="\nONE OX: very slow; load guideline %.0f lb." % game.provisions.team_capacity(1)
	if by_hand:slaughter_confirmation.dialog_text+="\nHousehold tools included; %d%% chance of wounding a traveler." % roundi(offer.injury_chance*100)
	supplies_window.hide()
	popup_fitted(slaughter_confirmation)


func _save_journey() -> void:
	if save_button.disabled:
		return
	_pause_travel()
	options_window.hide()
	_refresh()
	notice("TRAIL RECORD","Journey saved. The previous record is kept as a backup." if save_store.save_game(game, save_path) else save_store.error)

func _load_journey() -> void:
	crime_category=""
	if load_button.disabled:
		return
	_pause_travel()
	var result: Dictionary = save_store.load_game(save_path)
	if not result.is_empty():
		for window in [guide,journal_window,party_window,drop_window,section_window,options_window,food_notice,rest_window,stop_window,service_window,hunt_window,supplies_window,grave_window,memorial_window]:
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
	notice("TRAIL RECORD",result.message if not result.is_empty() else save_store.error)

## With a buried companion's remains entry, marks that grave; otherwise the lost party's own stone.
func _edit_gravestone(grave: Dictionary = {}) -> void:
	if grave.is_empty() and game.state.status != "lost":
		return
	_pause_travel()
	grave_editing = true
	grave_remains = grave.duplicate(true)
	epitaph_input.show()
	epitaph_input.text = "They followed the western road." if grave.is_empty() else "Rest easy by the western road."
	grave_view.record = grave_store.make_record(game,epitaph_input.text,grave_remains)
	grave_view.queue_redraw()
	grave_window.title = "A GRAVESTONE ON THE TRAIL" if grave.is_empty() else "MARK %s'S GRAVE" % str(grave.name).to_upper()
	grave_window.get_ok_button().text = "LEAVE THIS STONE"
	grave_window.popup_centered()

func _grave_window_closed() -> void:
	if not grave_window.visible:
		_return_to_remains.call_deferred()

func _return_to_remains() -> void:
	var open: bool = [guide,journal_window,party_window,drop_window,section_window,options_window,service_window,supplies_window,grave_window,memorial_window,record_notice].any(func(window): return window.visible)
	if not open and game.state.status == "traveling" and game.pending.get("remains_menu",false):
		_show_service()

func _preview_epitaph(text: String) -> void:
	if grave_editing:
		grave_view.record = grave_store.make_record(game,text,grave_remains)
		grave_view.queue_redraw()

func _leave_gravestone() -> void:
	if not grave_editing:
		return
	if grave_store.leave_memorial(game,epitaph_input.text,grave_remains):
		var record: Dictionary = grave_store.make_record(game,epitaph_input.text,grave_remains)
		game.journal.append(("Left a gravestone at guide mile %d: %s" % [record.miles,record.epitaph]) if grave_remains.is_empty() else ("Marked %s's grave at guide mile %d: %s" % [record.name,record.miles,record.epitaph]))
		# This journey already knows the stone it just set; later journeys find it on the road.
		visited_graves.append(record.id)
		grave_editing = false
		grave_remains = {}
		_refresh()
	else:
		notice("A GRAVESTONE ON THE TRAIL",grave_store.error)

func _read_gravestone(record: Dictionary) -> void:
	_pause_travel()
	grave_editing = false
	grave_remains = {}
	grave_window.title = "A GRAVESTONE ON THE TRAIL"
	epitaph_input.hide()
	grave_view.record = record.duplicate(true)
	grave_view.queue_redraw()
	grave_window.get_ok_button().text = "CONTINUE"
	grave_window.popup_centered()

func _show_memorials() -> void:
	section_window.hide()
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
			memorial_rows.add_child(button("%s%s · MILE %d · %s" % [record.name," (GRAVE)" if record.get("kind","party")=="companion" else "",record.miles,record.date],_read_gravestone.bind(record)))
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



func _build_preferences() -> void:
	var rows:=VBoxContainer.new()
	rows.custom_minimum_size=Vector2(360,160)
	rows.add_theme_constant_override("separation",7)
	options_window.add_child(rows)
	fullscreen=CheckBox.new()
	fullscreen.text="FULL SCREEN"
	rows.add_child(fullscreen)
	rows.add_child(label("WINDOW SIZE · CRISP INTEGER PIXELS"))
	window_scale=OptionButton.new()
	window_scale.add_item("1X · 800 BY 360")
	window_scale.add_item("2X · 1600 BY 720")
	rows.add_child(window_scale)
	rows.add_child(label("AUTOMATIC TRAVEL DISPLAY SPEED"))
	travel_speed=OptionButton.new()
	for text in ["SLOW · 2.5 SECONDS PER DAY","NORMAL · 1.25 SECONDS PER DAY","FAST · 0.75 SECONDS PER DAY"]:travel_speed.add_item(text)
	rows.add_child(travel_speed)
	rows.add_child(label("Display speed changes no daily travel or survival rules."))
	fullscreen.toggled.connect(func(_value):_change_preferences())
	window_scale.item_selected.connect(func(_value):_change_preferences())
	travel_speed.item_selected.connect(func(_value):_change_preferences())

func _show_preferences() -> void:
	if not game.hunt.is_empty() or not landscape.crossing.is_empty() or _reviewing_crossing():return
	section_window.hide()
	_pause_travel()
	options_window.popup_centered()

func _load_preferences() -> void:
	var file:=ConfigFile.new()
	file.load(preferences_path)
	var scale_value: Variant=file.get_value("display","scale",2)
	var speed_value: Variant=file.get_value("travel","speed",1)
	var full_value: Variant=file.get_value("display","fullscreen",false)
	window_scale.select(int(scale_value)-1 if scale_value is int and scale_value in [1,2] else 1)
	travel_speed.select(int(speed_value) if speed_value is int and speed_value in [0,1,2] else 1)
	fullscreen.set_pressed_no_signal(full_value if full_value is bool else false)
	_apply_preferences()

func _apply_preferences() -> void:
	travel_timer.wait_time=[2.5,1.25,0.75][travel_speed.selected]
	window_scale.disabled=fullscreen.button_pressed
	if DisplayServer.get_name()=="headless":return
	var window:=get_window()
	window.mode=Window.MODE_FULLSCREEN if fullscreen.button_pressed else Window.MODE_WINDOWED
	if not fullscreen.button_pressed:
		var available:=DisplayServer.screen_get_usable_rect(window.current_screen)
		var target:=Vector2i(800,360)*(window_scale.selected+1)
		if target.x>available.size.x or target.y>available.size.y:target=Vector2i(800,360)
		window.size=target
		window.position=available.position+(available.size-target)/2

func _change_preferences() -> void:
	_apply_preferences()
	var file:=ConfigFile.new()
	file.set_value("display","scale",window_scale.selected+1)
	file.set_value("display","fullscreen",fullscreen.button_pressed)
	file.set_value("travel","speed",travel_speed.selected)
	if file.save(preferences_path)!=OK:notice("GAME OPTIONS","These preferences could not be saved for next time.")


func _refresh_place_actions() -> void:
	for child in place_actions.get_children():
		place_actions.remove_child(child)
		child.queue_free()
	if not game.can_service() or not landscape.crossing.is_empty() or _reviewing_crossing():return
	var entries: Array=[]
	var market: Dictionary=game.context.market(game)
	if market.available:entries.append(["STORE" if market.post else "TALK TO TRADERS",_open_trade])
	if not game.crime.camp(game).is_empty():entries.append(["VISIT EMIGRANT CAMP",_open_camp])
	if not game.recruitment.site(game).is_empty() and game.current_party_slots().has(-1) and game.party_health.members.size()<game.MAX_TRAVELERS:entries.append(["FIND COMPANIONS",_open_companions])
	if game.pending.has("landmark"):entries.append(["LOCAL ACTIVITIES",_show_stop_activities])
	for entry in entries:
		var option:=button(entry[0],entry[1])
		option.tooltip_text="Available here. Opens a preview before you spend time or supplies."
		place_actions.add_child(option)


func _normalize_dialog_tree(node) -> void:
	if not is_instance_valid(node):return
	if node is AcceptDialog:
		if not node.has_meta("normalized_exit"):
			node.set_meta("normalized_exit",true)
			node.visibility_changed.connect(func():
				if node.visible:_normalize_dialog_buttons(node))
		_normalize_dialog_buttons(node)
	for child in node.get_children():_normalize_dialog_tree(child)

func _normalize_dialog_buttons(dialog: AcceptDialog) -> void:
	# Only real committing actions remain below; X/Escape is the one exit convention.
	var commits: Array=["REST","SLAUGHTER","REPACK","LEAVE WAGON","LEAVE THIS STONE"]
	dialog.get_ok_button().visible=dialog is ConfirmationDialog or dialog.get_ok_button().text in commits
	if dialog is ConfirmationDialog:dialog.get_cancel_button().hide()


func _recover_wagon() -> void:
	supplies_window.hide()
	var day: int=game.state.day
	if not game.recover_wagon():return
	_refresh()
	var message: String
	if game.state.status!="traveling":message="The recovery journey ended. See the journal for the outcome."
	elif game.state.vehicle=="wagon":message="Wagon recovered and hitched."
	elif game.wagon_cache.is_empty():message="The wagon and its cached supplies were lost. You remain on foot."
	elif game.state.miles>game.wagon_cache.mile:message="Backtracking stopped at mile %d. The wagon remains at mile %d; it has not been reached on this attempt. Reduce your packs before walking back." % [game.state.miles,game.wagon_cache.mile]
	elif game.wagon_cache.found and game.state.oxen==0:message="Wagon located, but no ox can pull it. Repack here or trade for an animal."
	else:message="Recovery is incomplete. Resolve the current notice before trying again."
	notice("WAGON RECOVERY","%d day(s) passed. Now at mile %d.\n%s" % [game.state.day-day,game.state.miles,message])
