extends SceneTree
const Main=preload("res://ui/main.tscn")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func run():
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	var setup=screen.departure_view
	check(setup.interval.value==7,"Default wage interval stays weekly before any edits")
	check(not setup.editor_layer.visible and setup.edit_buttons.size()==4,"The character sheet starts closed; each companion has an EDIT button")
	setup.edit_buttons[0].pressed.emit()
	check(setup.editor_layer.visible and setup.edited_member==1 and setup.names[1].text.to_upper() in setup.editor_title.text,"EDIT opens that companion's sheet, named in its title")
	setup.done_button.pressed.emit()
	check(not setup.editor_layer.visible,"DONE closes the sheet")
	setup.edit_buttons[0].pressed.emit()
	check(setup.personality.get_popup().get_item_tooltip(1)==screen.game.characters.catalog.data.temperaments[setup.personality.get_item_text(1)].description and setup.flaw_choice.get_popup().get_item_tooltip(1)!="" and setup.background_choice.get_popup().get_item_tooltip(0)!="","Open trait lists describe every option on hover")
	var initial: Dictionary=screen.game.state.duplicate(true)
	var random: int=screen.game.rng.state
	setup.names[1].text="JANE"
	setup.personality.selected=1
	setup.values.selected=0
	setup.background_choice.selected=2
	setup.relationship.selected=2
	setup.special_checks.Loyal.button_pressed=true
	setup.special_checks.Mercenary.button_pressed=true
	setup.interval.value=5
	setup.wage.value=6.75
	await process_frame
	setup.edit_buttons[1].pressed.emit()
	setup.personality.selected=0
	setup.relationship.selected=1
	setup.edit_buttons[0].pressed.emit()
	await process_frame
	check(setup.personality.selected==1 and setup.values.selected==0 and setup.relationship.selected==2,"Companion switching retains independent traits and relationship")
	check(setup.special_checks.Loyal.button_pressed and setup.special_checks.Mercenary.button_pressed and setup.wage.value==6.75 and setup.interval.value==5,"Specials and wage terms survive switching")
	check(screen.game.state==initial and screen.game.rng.state==random and screen.game.characters.profiles.is_empty(),"Draft edits do not alter live state, money or random rolls")
	setup.next_button.pressed.emit()
	check("Wages average $9.45/week" in setup.feedback.text,"Store shows recurring wage commitment beside purchase decision")
	setup.quantities.food.value=600
	setup.back_button.pressed.emit()
	check(setup.names[1].text=="JANE" and setup.relationship.selected==2 and setup.quantities.food.value==600,"Store round trip retains party edits and cart")
	var choices: Dictionary=setup.customization()
	check(screen.game.characters.valid_setup(choices) and choices.profiles[1].trust==70 and choices.profiles[2].trust==60,"Setup applies family/friend starting trust with a valid profile")
	check(choices.contracts["1"].wage_cents==675 and choices.contracts["1"].interval_days==5,"Contract uses exact agreed cents and interval")
	var bad: Dictionary=choices.duplicate(true)
	bad.contracts["1"].wage_cents=1
	var purchases: Dictionary=setup.cart()
	var profession: String=screen.game.outfitter.professions[setup.profession.selected].id
	check(not screen.game.depart(profession,setup.party_names(),4,purchases,bad) and screen.game.state==initial and screen.game.rng.state==random,"Invalid wage agreement rejects the whole departure without spending resources")
	bad=choices.duplicate(true)
	bad.contracts["1"]={"wage_cents":10000,"interval_days":8}
	check(not screen.game.depart(profession,setup.party_names(),4,purchases,bad),"Large offer cannot bypass maximum payment interval")
	check(not screen.game.characters.acceptable_terms(39,1) and screen.game.characters.acceptable_terms(280,7),"Acceptance compares daily-equivalent wages and permits the stated floor")
	bad=choices.duplicate(true)
	bad.profiles[1].trust=100
	check(not screen.game.depart(profession,setup.party_names(),4,purchases,bad) and screen.game.state==initial,"Customized trust cannot bypass relationship starting rules")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/party-customization.png")
		var scroll: ScrollContainer=setup.wage_quote_label.get_parent().get_parent()
		scroll.ensure_control_visible(setup.wage_quote_label)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/mercenary-wage-quote.png")
	setup.next_button.pressed.emit()
	setup.depart_button.pressed.emit()
	check(screen.game.state.status=="traveling" and not setup.visible,"Actual departure button commits customized party")
	var character: Dictionary=screen.game.characters.profiles[1]
	check(screen.game.state.party[1]=="JANE" and character.traits==["Bold","Compassionate"] and character.skill=="Caregiving" and character.trust==70,"Chosen identity, traits, background and relationship reach simulation")
	check(character.specials==["Loyal","Mercenary"] and character.contract.wage_cents==675 and character.contract.next_due_day==5,"Mercenary agreement starts on departure with selected terms")
	var quote: Dictionary=screen.game.outfitter.quote(profession,purchases)
	check(screen.game.state.money==quote.remaining_cents/100.0,"Future wages are not charged as an upfront purchase")
	setup.draft.profiles[1].trust=1
	check(character.trust==70,"Committed party is independent of its setup draft")
	var store=Store.new()
	var snapshot: Dictionary=store.capture(screen.game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null and store.capture(copy)==snapshot,"Customized party and contract save/load exactly")
	screen._new_journey()
	setup=screen.departure_view
	check(setup.customization().contracts.is_empty() and setup.customization().profiles.all(func(p):return p.specials.is_empty()),"New journey clears previous custom contracts and specials")
	setup.background_choice.selected=0
	setup.background_choice.item_selected.emit(0)
	setup.values.selected=0
	setup.values.item_selected.emit(0)
	setup.special_checks.Loyal.button_pressed=true
	check(setup.wage.min_value==3.15 and "Loyal: +$0.10" in setup.wage_quote_label.text,"Editor shows and enforces background/personality/Loyal quote")
	setup.special_checks.Veteran.button_pressed=true
	check(setup.wage.min_value==4.55 and "Veteran: +$0.20" in setup.wage_quote_label.text,"Selecting a premium special immediately raises the quote")
	check(setup.special_count_label.text=="Special traits: 2 / 2" and setup.special_checks.Mercenary.disabled and setup.special_checks.Cannibal.disabled and not setup.special_checks.Loyal.disabled,"Two choices show a count and block unused specials while retaining removal")
	setup.special_checks.Mercenary.button_pressed=true
	check(not setup.special_checks.Mercenary.button_pressed and not setup.wage.editable,"Third selection is rejected even if triggered programmatically")
	setup.special_checks.Loyal.button_pressed=false
	check(not setup.special_checks.Mercenary.disabled and setup.special_count_label.text=="Special traits: 1 / 2","Removing a special frees a slot")
	setup.special_checks.Mercenary.button_pressed=true
	check(setup.customization().profiles[1].specials==["Mercenary","Veteran"] and setup.wage.editable,"A different two-special combination remains usable")
	var capped: Dictionary=setup.customization()
	capped.profiles[1].specials.append("Loyal")
	check(not screen.game.characters.valid_setup(capped),"Departure validator rejects three creation specials")
	var before_invalid: Dictionary=screen.game.state.duplicate(true)
	check(not screen.game.depart("banker",setup.party_names(),4,setup.cart(),capped) and screen.game.state==before_invalid,"Over-limit departure is rejected without charging or starting")
	# The cap applies at creation; old saves and possible future earned specials retain runtime support.
	var old_party=Store.new().restore(snapshot)
	old_party.characters.profiles[1].specials.append("Veteran")
	var old_snapshot: Dictionary=Store.new().capture(old_party)
	var old_copy=Store.new().restore(JSON.parse_string(JSON.stringify(old_snapshot)))
	check(old_copy!=null and old_copy.characters.profiles[1].specials.size()==3,"Existing saved companions with three specials remain compatible")
	screen.queue_free()
	await process_frame
	print("Party setup: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)


