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
var edit_buttons: Array[Button] = []
var editor_layer: Control
var editor_title: Label
var editor_scroll: ScrollContainer
var done_button: Button
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
var generate_party_button: Button
var generate_button: Button
var bonds_layer: Control
var bond_boxes: Array = []
var romance_check: CheckBox
var bond_feedback: Label
var appearance_window: AcceptDialog
var appearance_member := 0
var look_boxes: Dictionary={}
var heritage_entry: LineEdit
var look_preview: TextureRect
var loading_look := false
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
		entry.text_changed.connect(func(_value):
			_update_quote()
			_title_editor())
		# Companions get an EDIT button that opens their character sheet; the leader is defined by play.
		put(entry, Rect2(95, 48 + i * 23, 108, 21), party_layer)
		names.append(entry)
		if i > 0:
			var edit := Button.new()
			edit.text = "EDIT"
			edit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			edit.tooltip_text = "Set this companion's temperament, values, background, relationship, specials, flaw and wages."
			edit.pressed.connect(open_editor.bind(i))
			put(edit, Rect2(207, 48 + i * 23, 38, 21), party_layer)
			edit_buttons.append(edit)
		else:
			var look := Button.new()
			look.text="LOOK"
			look.pressed.connect(open_appearance.bind(0))
			put(look,Rect2(207,48,38,21),party_layer)
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
	generate_party_button=Button.new()
	generate_party_button.text="GENERATE PARTY"
	generate_party_button.tooltip_text="Generate all four companions: names, appearance, personality, backgrounds, relationships, specials, flaws and wage offers. Your leader, profession, month and supply cart stay. Custom companion bonds reset."
	generate_party_button.pressed.connect(_generate_party)
	put(generate_party_button,Rect2(267,240,110,25),party_layer)
	next_button = Button.new()
	next_button.text = "ENTER THE STORE >"
	next_button.pressed.connect(show_store)
	put(next_button, Rect2(495, 240, 115, 25), party_layer)
	_build_companions()
	_build_bonds()
	_build_appearance()
	# Keep the left half of the store painting visible: shelves, attendant and counter.
	paper(Rect2(267, 0, 355, 236), shop_layer)
	paper(Rect2(0, 236, 622, 37), shop_layer)
	text("THE GENERAL STORE", Rect2(278, 10, 320, 12), shop_layer)
	text("Wagon/gear owned. Buy trail supplies.", Rect2(278, 30, 330, 12), shop_layer)
	var stock_scroll:=ScrollContainer.new()
	stock_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	put(stock_scroll,Rect2(278,44,334,162),shop_layer)
	var stock_rows:=Control.new()
	stock_rows.custom_minimum_size=Vector2(314,game.outfitter.goods.size()*18)
	stock_scroll.add_child(stock_rows)
	for i in range(game.outfitter.goods.size()):
		var good: Dictionary = game.outfitter.goods[i]
		var caption=text(good.label, Rect2(0, 2 + i * 18, 230, 18), stock_rows)
		if good.id in ["produce","dried_produce"]:caption.tooltip_text="Each basket supplies 1 food unit from 4 lb fresh produce. "+("Fresh lasts 3 days." if good.id=="produce" else "Dried weighs 0.7 lb and lasts up to 90 days, with less vitamin C.")
		var quantity := SpinBox.new()
		quantity.min_value = 0
		quantity.max_value = good.maximum
		quantity.step = good.step
		quantity.value = good.suggested
		quantity.get_line_edit().add_theme_constant_override("minimum_character_width", 1)
		quantity.value_changed.connect(func(_value): _update_quote())
		put(quantity, Rect2(236, i * 18, 78, 18), stock_rows)
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
	if editor_layer.visible:close_editor()
	bonds_layer.hide()
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
	if bonds_layer!=null and not preload("res://simulation/party_social.gd").valid_commitments(selected_bonds(),draft.profiles):
		depart_button.disabled=true
		feedback.text="Conflicting partners: check PARTY RELATIONSHIPS and EDIT."
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
	# The character sheet stays closed until an EDIT button opens it, leaving the town in view.
	editor_layer=Control.new()
	put(editor_layer,Rect2(267,0,355,236),party_layer)
	paper(Rect2(0,0,355,236),editor_layer)
	editor_title=text("",Rect2(11,10,270,14),editor_layer)
	editor_title.clip_text=true
	done_button=Button.new()
	done_button.text="DONE"
	done_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	done_button.tooltip_text="Close the character sheet. Your choices are kept."
	done_button.pressed.connect(close_editor)
	put(done_button,Rect2(289,6,56,18),editor_layer)
	editor_scroll=ScrollContainer.new()
	editor_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	put(editor_scroll,Rect2(11,30,333,198),editor_layer)
	var rows:=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",5)
	editor_scroll.add_child(rows)
	generate_button=Button.new()
	generate_button.text="GENERATE A COMPANION"
	generate_button.tooltip_text="Replaces this draft companion's personality, background, relationship, specials, flaw and wage offer. No journey time or money passes."
	rows.add_child(generate_button)
	generate_button.pressed.connect(_generate_companion)
	var appearance_button := Button.new()
	appearance_button.text="APPEARANCE & PERSONAL BACKGROUND"
	appearance_button.pressed.connect(open_appearance.bind(-1))
	rows.add_child(appearance_button)
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
	editor_layer.hide()

## Opens the character sheet for one companion (1-4), saving whichever companion was open before.
func open_editor(member: int) -> void:
	bonds_layer.hide()
	_store_companion()
	edited_member=member
	_load_companion()
	_title_editor()
	editor_scroll.scroll_vertical=0
	editor_layer.show()

func close_editor() -> void:
	_store_companion()
	editor_layer.hide()
	_update_quote()

func _title_editor() -> void:
	if editor_title!=null:editor_title.text="EDITING %s · SCROLL FOR MORE" % names[edited_member].text.strip_edges().to_upper()

func _apply_generated_member(member: int) -> void:
	generation_index+=1
	var offer: Dictionary=draft.generate_candidate(int(game.state.seed),generation_index,"random")
	var profile: Dictionary=offer.profile
	profile.id=member
	draft.profiles[member]=profile
	var full_name: String=offer.name
	names[member].text=full_name if full_name.length()<=14 else full_name.get_slice(" ",0)+" "+full_name.get_slice(" ",1).left(1)+"."
	draft_terms.erase(str(member))
	if not offer.terms.is_empty():draft_terms[str(member)]=offer.terms

func _generate_companion() -> void:
	_store_companion()
	_apply_generated_member(edited_member)
	_load_companion()
	_title_editor()
	_update_quote()

func _generate_party() -> void:
	_store_companion()
	for member in range(1,5):_apply_generated_member(member)
	for pair in bond_boxes:
		pair.box.select(0)
		pair.previous=0
	bonds_layer.hide()
	editor_layer.hide()
	bond_feedback.text="Friends/rivals evolve; partners leave together."
	_load_companion()
	_title_editor()
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
	return {"profiles":draft.profiles.duplicate(true),"contracts":contracts,"bonds":selected_bonds(),"romance":romance_check.button_pressed}


func _build_bonds() -> void:
	var open_button := Button.new()
	open_button.text="RELATIONSHIPS"
	open_button.tooltip_text="Set bonds between your four companions. EDIT sets each companion’s relationship with you."
	open_button.pressed.connect(open_bonds)
	put(open_button,Rect2(381,240,110,25),party_layer)
	bonds_layer=Control.new()
	put(bonds_layer,Rect2(267,0,355,236),party_layer)
	paper(Rect2(0,0,355,236),bonds_layer)
	text("COMPANION RELATIONSHIPS",Rect2(10,9,280,14),bonds_layer)
	var done := Button.new()
	done.text="DONE"
	done.pressed.connect(func():bonds_layer.hide())
	put(done,Rect2(293,5,55,22),bonds_layer)
	var initial: Array=game.crime.roll_bonds(int(game.state.seed))
	for a in range(1,4):
		for b in range(a+1,5):
			var row: int=bond_boxes.size()
			var label := text("",Rect2(10,34+row*27,172,22),bonds_layer)
			label.clip_text=true
			var box := OptionButton.new()
			for title in ["Unrelated","Family","Friends","Partners / spouses","Rivals"]:box.add_item(title)
			var chosen := 0
			for item in initial:
				if int(item.a)==a and int(item.b)==b:chosen=preload("res://simulation/party_social.gd").START_KINDS.find(item.kind)
			box.select(chosen)
			put(box,Rect2(187,32+row*27,158,22),bonds_layer)
			bond_boxes.append({"a":a,"b":b,"label":label,"box":box,"previous":chosen})
			box.item_selected.connect(_change_bond.bind(row))
	bond_feedback=text("Friends/rivals evolve; partners leave together.",Rect2(10,195,335,12),bonds_layer)
	romance_check=CheckBox.new()
	romance_check.text="Allow new romances on the trail"
	romance_check.tooltip_text="This controls new romances only. Friendships and rivalries can develop whether it is checked or not."
	romance_check.button_pressed=true
	put(romance_check,Rect2(7,208,340,22),bonds_layer)
	bonds_layer.hide()

func open_bonds() -> void:
	close_editor()
	for pair in bond_boxes:
		pair.label.text=names[int(pair.a)].text+" / "+names[int(pair.b)].text
		pair.label.tooltip_text=pair.label.text
	bonds_layer.show()

func selected_bonds() -> Array:
	var result := []
	for pair in bond_boxes:
		if pair.box.selected>0:result.append({"a":int(pair.a),"b":int(pair.b),"kind":preload("res://simulation/party_social.gd").START_KINDS[pair.box.selected]})
	return result

func _change_bond(_selected: int, row: int) -> void:
	var pair: Dictionary=bond_boxes[row]
	if not preload("res://simulation/party_social.gd").valid_bonds(selected_bonds()) or not preload("res://simulation/party_social.gd").valid_commitments(selected_bonds(),draft.profiles):
		pair.box.select(int(pair.previous))
		bond_feedback.text="Only one partner, including the leader."
	else:
		pair.previous=pair.box.selected
		bond_feedback.text="Friends/rivals evolve; partners leave together."


func _build_appearance() -> void:
	appearance_window=AcceptDialog.new()
	appearance_window.title="APPEARANCE & PERSONAL BACKGROUND"
	appearance_window.get_ok_button().text="DONE"
	add_child(appearance_window)
	var content := Control.new()
	content.custom_minimum_size=Vector2(460,218)
	appearance_window.add_child(content)
	look_preview=TextureRect.new()
	look_preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	look_preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	look_preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	put(look_preview,Rect2(8,12,80,120),content)
	var data: Dictionary=preload("res://simulation/traveler_appearance.gd").catalog()
	var row := 0
	for key in ["skin","hair","clothing","outfit"]:
		text(key.capitalize(),Rect2(104,8+row*31,86,18),content)
		var box := OptionButton.new()
		var choices: Array=data.outfits if key=="outfit" else data[key].keys()
		for title in choices:box.add_item(title)
		put(box,Rect2(194,5+row*31,254,23),content)
		look_boxes[key]=box
		box.item_selected.connect(func(_index):_store_appearance())
		row+=1
	text("Heritage / upbringing (optional)",Rect2(104,134,340,16),content)
	heritage_entry=LineEdit.new()
	heritage_entry.max_length=64
	heritage_entry.placeholder_text="Describe their personal background"
	heritage_entry.text_changed.connect(func(_value):_store_appearance())
	put(heritage_entry,Rect2(104,153,344,23),content)
	var note := text("Appearance and heritage do not set traits or skills.\nGenerated companions get these details too.",Rect2(8,187,440,24),content)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func open_appearance(member: int = -1) -> void:
	_store_companion()
	appearance_member=edited_member if member<0 else member
	var profile: Dictionary=draft.profiles[appearance_member]
	var data: Dictionary=preload("res://simulation/traveler_appearance.gd").catalog()
	var look: Dictionary=profile.get("appearance",preload("res://simulation/traveler_appearance.gd").default_for(appearance_member))
	loading_look=true
	for key in look_boxes:
		look_boxes[key].select(int(look.outfit) if key=="outfit" else data[key].keys().find(look[key]))
	heritage_entry.text=look.heritage
	loading_look=false
	appearance_window.title="APPEARANCE: "+names[appearance_member].text.to_upper()
	_update_look_preview()
	appearance_window.popup_centered()

func _store_appearance() -> void:
	if loading_look:return
	var data: Dictionary=preload("res://simulation/traveler_appearance.gd").catalog()
	var look := {"heritage":heritage_entry.text.strip_edges() if not heritage_entry.text.strip_edges().is_empty() else "Not specified"}
	for key in look_boxes:look[key]=look_boxes[key].selected if key=="outfit" else data[key].keys()[look_boxes[key].selected]
	draft.profiles[appearance_member]["appearance"]=look
	_update_look_preview()

func _update_look_preview() -> void:
	var profile: Dictionary=draft.profiles[appearance_member]
	var atlas := AtlasTexture.new()
	atlas.atlas=preload("res://ui/traveler_palette.gd").texture(preload("res://art/pixels/walker.png"),profile)
	atlas.region=Rect2(0,int(profile.appearance.outfit)*24,16,24)
	look_preview.texture=atlas
