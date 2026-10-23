extends Panel
## Party preparation and the illustrated store share one pending purchase transaction.
signal departure_requested(profession: String, names: Array, month: int, cart: Dictionary)
var game
var profession: OptionButton
var month: OptionButton
var names: Array[LineEdit] = []
var quantities: Dictionary = {}
var totals: Label
var feedback: Label
var depart_button: Button
var next_button: Button
var back_button: Button
var party_layer: Control
var shop_layer: Control
var background: TextureRect
var scene_id := "town_setup"
var scenes = preload("res://ui/location_scenes.gd").new()
var draft=preload("res://simulation/party_character.gd").new()
var companion: OptionButton
var personality: OptionButton
var values: OptionButton
var background_choice: OptionButton
var relationship: OptionButton
var special_checks: Dictionary={}
var special_count_label: Label
var flaw_choice: OptionButton
var flaw_description: Label
var accepted_flaw: String=""
var wage: SpinBox
var interval: SpinBox
var edited_member:=1
var draft_terms: Dictionary={}
var wage_quote_label: Label
var loading_companion:=false
var generation_index:=0
var generate_button: Button
var character_summary: Label

func _init(simulation) -> void:
	game = simulation

func put(node: Control, bounds: Rect2, parent: Node = self) -> Control:
	parent.add_child(node)
	node.position = bounds.position
	node.size = bounds.size
	return node

func text(value: String, bounds: Rect2, parent: Node) -> Label:
	var node := Label.new()
	node.text = value
	put(node, bounds, parent)
	return node

func paper(bounds: Rect2, parent: Node) -> void:
	var panel := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("ecd097")
	box.border_color = Color("a16b43")
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", box)
	put(panel, bounds, parent)

func _ready() -> void:
	clip_contents = true
	background = TextureRect.new()
	background.texture = scenes.texture_for(scene_id)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(background, Rect2(0, 0, 622, 273))
	party_layer = Control.new()
	put(party_layer, Rect2(0, 0, 622, 273))
	shop_layer = Control.new()
	put(shop_layer, Rect2(0, 0, 622, 273))
	paper(Rect2(0, 0, 259, 273), party_layer)
	text("PREPARE FOR THE TRAIL", Rect2(12, 10, 235, 12), party_layer)
	text("Name your five travelers:", Rect2(12, 30, 235, 12), party_layer)
	for i in range(5):
		text("LEADER" if i == 0 else "TRAVELER %d" % (i + 1), Rect2(12, 50 + i * 23, 78, 18), party_layer)
		var entry := LineEdit.new()
		entry.max_length = 14
		entry.text = game.state.party[i]
		entry.text_changed.connect(func(_value): _update_quote())
		put(entry, Rect2(95, 48 + i * 23, 150, 21), party_layer)
		names.append(entry)
	text("PROFESSION / TRAIL FUNDS", Rect2(12, 169, 235, 12), party_layer)
	profession = OptionButton.new()
	for entry in game.outfitter.professions:
		profession.add_item("%s  $%d" % [entry.label, int(entry.cash_cents) / 100])
	profession.item_selected.connect(func(_value): _update_quote())
	put(profession, Rect2(12, 185, 233, 22), party_layer)
	text("DEPARTURE MONTH", Rect2(12, 212, 235, 12), party_layer)
	month = OptionButton.new()
	for name in ["MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST"]:
		month.add_item(name)
	month.selected = 1
	put(month, Rect2(12, 227, 233, 22), party_layer)
	next_button = Button.new()
	next_button.text = "ENTER THE STORE >"
	next_button.pressed.connect(show_store)
	put(next_button, Rect2(420, 240, 190, 25), party_layer)
	_build_companions()
	# Keep the left half of the store painting visible: shelves, attendant and counter.
	paper(Rect2(267, 0, 355, 236), shop_layer)
	paper(Rect2(0, 236, 622, 37), shop_layer)
	text("THE GENERAL STORE", Rect2(278, 10, 320, 12), shop_layer)
	text("Wagon/gear owned. Buy trail supplies.", Rect2(278, 30, 330, 12), shop_layer)
	for i in range(game.outfitter.goods.size()):
		var good: Dictionary = game.outfitter.goods[i]
		text(good.label, Rect2(278, 46 + i * 18, 230, 18), shop_layer)
		var quantity := SpinBox.new()
		quantity.min_value = 0
		quantity.max_value = good.maximum
		quantity.step = good.step
		quantity.value = good.suggested
		quantity.get_line_edit().add_theme_constant_override("minimum_character_width", 1)
		quantity.value_changed.connect(func(_value): _update_quote())
		put(quantity, Rect2(521, 44 + i * 18, 86, 18), shop_layer)
		quantities[good.id] = quantity
	totals = text("", Rect2(278, 212, 330, 24), shop_layer)
	feedback = text("", Rect2(137, 240, 330, 29), shop_layer)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	back_button = Button.new()
	back_button.text = "< PARTY"
	back_button.pressed.connect(show_party)
	put(back_button, Rect2(12, 242, 111, 25), shop_layer)
	depart_button = Button.new()
	depart_button.text = "DEPART >"
	depart_button.pressed.connect(_request_departure)
	put(depart_button, Rect2(478, 242, 130, 25), shop_layer)
	for node in [next_button, back_button, depart_button]:
		node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	show_party()
	_update_quote()

func show_store() -> void:
	scene_id = "store"
	background.texture = scenes.texture_for(scene_id)
	party_layer.hide()
	shop_layer.show()
	_update_quote()

func show_party() -> void:
	scene_id = "town_setup"
	background.texture = scenes.texture_for(scene_id)
	shop_layer.hide()
	party_layer.show()

func cart() -> Dictionary:
	var result := {}
	for key in quantities:
		quantities[key].apply()
		result[key] = int(quantities[key].value)
	return result

func _current_cart() -> Dictionary:
	var result := {}
	for key in quantities:
		result[key] = int(quantities[key].value)
	return result

func party_names() -> Array:
	var result: Array = []
	for entry in names:
		result.append(entry.text)
	return result

func _update_quote() -> void:
	if depart_button == null:
		return
	var quote: Dictionary = game.outfitter.quote(game.outfitter.professions[profession.selected].id, _current_cart())
	totals.text = "SUPPLIES $%.2f  CASH LEFT $%.2f\nCARGO %.0f · TEAM %.0f LB · FOOD %d DAYS" % [float(quote.total_cents) / 100.0, float(quote.remaining_cents) / 100.0, quote.get("cargo_lb", 0),quote.get("team_capacity_lb",0), game.provisions.expected_days(int(_current_cart().get("food", 0)), 5, 2)]
	feedback.text = quote.message + " Team pulling speed: %d%% (4 normal; 5 +5%%; 6+ +10%%)." % roundi(game.survival.team_factor(int(_current_cart().get("oxen",0)))*100)
	var agreements: Dictionary={}
	for profile in draft.profiles:
		if profile.id!=edited_member and "Mercenary" in profile.specials:agreements[str(profile.id)]=draft_terms[str(profile.id)]
	if special_checks.Mercenary.button_pressed:agreements[str(edited_member)]={"wage_cents":roundi(wage.value*100),"interval_days":int(interval.value)}
	if not agreements.is_empty():
		var weekly:=0.0
		var first_due:=30
		for terms in agreements.values():
			weekly+=float(terms.wage_cents)*7.0/float(terms.interval_days)/100.0
			first_due=mini(first_due,int(terms.interval_days))
		feedback.text="Wages average $%.2f/week; first bill day %d.\nWages come out of your remaining trail funds." % [weekly,first_due]
	depart_button.disabled = not quote.valid
	next_button.disabled = false
	for entry in names:
		if entry.text.strip_edges().is_empty():
			feedback.text = "Every traveler needs a name."
			depart_button.disabled = true
			next_button.disabled = true

func _request_departure() -> void:
	var purchases := cart()
	departure_requested.emit(game.outfitter.professions[profession.selected].id, party_names(), month.selected + 3, purchases)

func select_box(items: Array, parent: Node) -> OptionButton:
	var box:=OptionButton.new()
	for item in items:box.add_item(item)
	parent.add_child(box)
	return box

## Hover text for each entry of a drop-down list, in list order.
func describe_items(box: OptionButton, descriptions: Array) -> void:
	for index in range(mini(box.item_count,descriptions.size())):box.get_popup().set_item_tooltip(index,str(descriptions[index]))

func _build_companions() -> void:
	draft.start(int(game.state.seed),5)
	paper(Rect2(267,0,355,230),party_layer)
	text("COMPANION DETAILS · SCROLL FOR MORE",Rect2(278,10,330,14),party_layer)
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	put(scroll,Rect2(278,30,330,190),party_layer)
	var rows:=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",5)
	scroll.add_child(rows)
	companion=select_box(["TRAVELER 2","TRAVELER 3","TRAVELER 4","TRAVELER 5"],rows)
	companion.item_selected.connect(func(index: int):
		_store_companion()
		edited_member=index+1
		_load_companion())
	generate_button=Button.new()
	generate_button.text="GENERATE A COMPANION"
	generate_button.tooltip_text="Replaces this draft companion's personality, background, relationship, specials, flaw and wage offer. No journey time or money passes."
	rows.add_child(generate_button)
	generate_button.pressed.connect(_generate_companion)
	text("Temperament / values",Rect2(),rows)
	personality=select_box(draft.catalog.data.temperaments.keys(),rows)
	values=select_box(draft.catalog.data.values.keys(),rows)
	text("Background / party benefit",Rect2(),rows)
	background_choice=select_box(draft.SKILLS,rows)
	text("Relationship to you",Rect2(),rows)
	relationship=select_box(draft.catalog.data.relationships.keys(),rows)
	for index in range(relationship.item_count):relationship.set_item_text(index,relationship.get_item_text(index).replace("_"," ").capitalize())
	character_summary=text("",Rect2(),rows)
	character_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text("Optional flaw (+1 special slot; maximum one)",Rect2(),rows)
	flaw_choice=select_box(["None"]+draft.FLAWS.keys(),rows)
	flaw_choice.item_selected.connect(_flaw_selected)
	flaw_description=text("",Rect2(),rows)
	flaw_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	special_count_label=text("Special traits",Rect2(),rows)
	# Each option in an open list explains itself on hover, not only the current choice.
	describe_items(personality,draft.catalog.data.temperaments.keys().map(func(key):return draft.catalog.data.temperaments[key].description))
	describe_items(values,draft.catalog.data.values.keys().map(func(key):return draft.catalog.data.values[key].description))
	describe_items(background_choice,draft.SKILLS.map(func(skill):return draft.background_benefit(skill)))
	describe_items(relationship,draft.catalog.data.relationships.keys().map(func(key):return draft.catalog.data.relationships[key].description))
	describe_items(flaw_choice,["No flaw: two special slots."]+draft.FLAWS.values())
	for special in draft.SPECIALS:
		var check:=CheckBox.new()
		check.text=special
		check.tooltip_text=draft.catalog.data.specials[special].description
		rows.add_child(check)
		special_checks[special]=check
	wage_quote_label=text("",Rect2(),rows)
	text("Mercenary wage per payment ($)",Rect2(),rows)
	wage=SpinBox.new()
	wage.min_value=7
	wage.max_value=1000
	wage.step=0.01
	wage.value=7
	rows.add_child(wage)
	text("Pay every (days)",Rect2(),rows)
	interval=SpinBox.new()
	interval.min_value=1
	interval.max_value=7
	interval.value=7
	rows.add_child(interval)
	interval.value_changed.connect(func(_days: float):_refresh_wage_quote())
	special_checks.Mercenary.toggled.connect(func(on: bool):
		wage.editable=on
		interval.editable=on)
	text("You lead; your decisions define your values.\nChoices stay with you when visiting the store.",Rect2(),rows)
	for box in [personality,values,background_choice,relationship]:box.item_selected.connect(func(_index: int):_refresh_wage_quote())
	for special in special_checks:special_checks[special].toggled.connect(_special_toggled.bind(special))
	_load_companion()

func _generate_companion() -> void:
	_store_companion()
	generation_index+=1
	var offer: Dictionary=draft.generate_candidate(int(game.state.seed),generation_index,"random")
	var profile: Dictionary=offer.profile
	profile.id=edited_member
	draft.profiles[edited_member]=profile
	var full_name: String=offer.name
	names[edited_member].text=full_name if full_name.length()<=14 else full_name.get_slice(" ",0)+" "+full_name.get_slice(" ",1).left(1)+"."
	draft_terms.erase(str(edited_member))
	if not offer.terms.is_empty():draft_terms[str(edited_member)]=offer.terms
	_load_companion()
	_update_quote()

func _special_toggled(on: bool, special: String) -> void:
	if loading_companion:return
	var selected:=0
	for check in special_checks.values():
		if check.button_pressed:selected+=1
	if on and selected>draft.MAX_CREATION_SPECIALS+(0 if accepted_flaw.is_empty() else 1):special_checks[special].set_pressed_no_signal(false)
	wage.editable=special_checks.Mercenary.button_pressed
	interval.editable=wage.editable
	_refresh_wage_quote()

func _flaw_selected(index: int) -> void:
	if loading_companion:return
	var selected:=0
	for check in special_checks.values():
		if check.button_pressed:selected+=1
	if index==0 and selected>draft.MAX_CREATION_SPECIALS:
		flaw_choice.select(draft.FLAWS.keys().find(accepted_flaw)+1)
		return
	accepted_flaw="" if index==0 else flaw_choice.get_item_text(index)
	_refresh_wage_quote()

func _refresh_special_limit() -> void:
	var selected:=0
	for check in special_checks.values():
		if check.button_pressed:selected+=1
	var limit: int=draft.MAX_CREATION_SPECIALS+(0 if accepted_flaw.is_empty() else 1)
	special_count_label.text="Special traits: %d / %d" % [selected,limit]
	for check in special_checks.values():check.disabled=not check.button_pressed and selected>=limit
	flaw_choice.set_item_disabled(0,selected>draft.MAX_CREATION_SPECIALS)
	flaw_choice.tooltip_text="One flaw grants one extra special slot. Remove an extra special before removing its flaw."
	if not accepted_flaw.is_empty():flaw_choice.tooltip_text+="\n"+draft.FLAWS[accepted_flaw]
	flaw_description.text="No flaw: two special slots." if accepted_flaw.is_empty() else draft.FLAWS[accepted_flaw]

func _refresh_wage_quote() -> void:
	if loading_companion:return
	_refresh_special_limit()
	var profile: Dictionary={"skill":draft.SKILLS[background_choice.selected],"traits":[personality.get_item_text(personality.selected),values.get_item_text(values.selected)],"specials":[]}
	for special in special_checks:
		if special_checks[special].button_pressed:profile.specials.append(special)
	var quote: Dictionary=draft.wage_quote(profile)
	personality.tooltip_text=draft.catalog.data.temperaments[profile.traits[0]].description
	values.tooltip_text=draft.catalog.data.values[profile.traits[1]].description
	var relation: String=draft.catalog.data.relationships.keys()[relationship.selected]
	relationship.tooltip_text=draft.catalog.data.relationships[relation].description
	var boundaries: Dictionary=draft.catalog.boundaries(profile.traits[1])
	if "Cannibal" in profile.specials:boundaries.forbidden.erase("cannibalism")
	character_summary.text="Starting trust: %d. Forbidden: %s." % [draft.RELATIONSHIPS[relation],", ".join(boundaries.forbidden) if not boundaries.forbidden.is_empty() else "None by default"]
	background_choice.tooltip_text=draft.background_benefit(profile.skill)
	wage.min_value=quote.daily_cents*interval.value/100.0
	wage_quote_label.text="Cash $%.2f/day + party food. Pay weekly or sooner.\nAbout $%.2f per 30 days.\n%s" % [quote.daily_cents/100.0,quote.daily_cents*30/100.0,"\n".join(quote.breakdown)]

func _store_companion() -> void:
	interval.apply()
	_refresh_wage_quote()
	wage.apply()
	var profile: Dictionary=draft.profiles[edited_member]
	profile.traits=[personality.get_item_text(personality.selected),values.get_item_text(values.selected)]
	profile.skill=draft.SKILLS[background_choice.selected]
	profile.relationship=draft.catalog.data.relationships.keys()[relationship.selected]
	profile.trust=draft.RELATIONSHIPS[profile.relationship]
	profile.specials=[]
	profile.erase("flaws")
	if not accepted_flaw.is_empty():profile.flaws=[accepted_flaw]
	for special in special_checks:
		if special_checks[special].button_pressed:profile.specials.append(special)
	profile.boundaries=draft.catalog.boundaries(profile.traits[1])
	draft_terms[str(edited_member)]={"wage_cents":roundi(wage.value*100),"interval_days":int(interval.value)}

func _load_companion() -> void:
	loading_companion=true
	var profile: Dictionary=draft.profiles[edited_member]
	var flaws: Array=profile.get("flaws",[])
	accepted_flaw="" if flaws.is_empty() else flaws[0]
	flaw_choice.select(0 if accepted_flaw.is_empty() else draft.FLAWS.keys().find(accepted_flaw)+1)
	personality.selected=draft.catalog.data.temperaments.keys().find(profile.traits[0])
	values.selected=draft.catalog.data.values.keys().find(profile.traits[1])
	background_choice.selected=draft.SKILLS.find(profile.skill)
	relationship.selected=draft.catalog.data.relationships.keys().find(profile.relationship)
	for special in special_checks:special_checks[special].button_pressed=special in profile.specials
	var terms: Dictionary=draft_terms.get(str(edited_member),{"wage_cents":draft.wage_quote(profile).daily_cents*7,"interval_days":7})
	interval.value=terms.interval_days
	wage.min_value=0.01
	wage.value=terms.wage_cents/100.0
	wage.editable="Mercenary" in profile.specials
	interval.editable=wage.editable
	loading_companion=false
	_refresh_wage_quote()

func customization() -> Dictionary:
	_store_companion()
	var contracts: Dictionary={}
	for profile in draft.profiles:
		if "Mercenary" in profile.specials:contracts[str(profile.id)]=draft_terms.get(str(profile.id),{"wage_cents":700,"interval_days":7}).duplicate(true)
	return {"profiles":draft.profiles.duplicate(true),"contracts":contracts}
