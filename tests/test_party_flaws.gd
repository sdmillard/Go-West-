extends SceneTree
const Main=preload("res://ui/main.tscn")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	var setup=screen.departure_view
	setup.special_checks.Loyal.button_pressed=true
	setup.special_checks.Mercenary.button_pressed=true
	setup.flaw_choice.select(1)
	setup.flaw_choice.item_selected.emit(1)
	check(setup.special_count_label.text=="Special traits: 2 / 3" and not setup.special_checks.Veteran.disabled,"One flaw opens exactly one extra slot")
	setup.special_checks.Veteran.button_pressed=true
	check(setup.special_checks.Cannibal.disabled and setup.flaw_choice.is_item_disabled(0),"Three specials fill the flaw allowance and protect its prerequisite")
	setup.special_checks.Cannibal.button_pressed=true
	check(not setup.special_checks.Cannibal.button_pressed,"Fourth special is rejected despite having a flaw")
	setup.flaw_choice.select(0)
	setup.flaw_choice.item_selected.emit(0)
	check(setup.accepted_flaw=="Frail" and setup.flaw_choice.selected==1,"Cannot remove flaw while keeping its extra special")
	setup.companion.select(1)
	setup.companion.item_selected.emit(1)
	check(setup.accepted_flaw.is_empty() and setup.special_count_label.text=="Special traits: 0 / 2","Flaws and allowances belong to each companion")
	setup.companion.select(0)
	setup.companion.item_selected.emit(0)
	check(setup.accepted_flaw=="Frail" and setup.special_count_label.text=="Special traits: 3 / 3","Companion switching retains the flaw and three choices")
	var choices: Dictionary=setup.customization()
	var game=screen.game
	check(game.characters.valid_setup(choices),"Three specials with one real flaw pass engine validation")
	for flaws in [null,"Frail",["Unknown"],["Frail","Slow Healer"],["Frail","Frail"]]:
		var bad: Dictionary=choices.duplicate(true)
		bad.profiles[1].flaws=flaws
		check(not game.characters.valid_setup(bad),"Malformed, duplicate and excess flaws reject")
	var bad: Dictionary=choices.duplicate(true)
	bad.profiles[1].specials.append("Cannibal")
	check(not game.characters.valid_setup(bad),"One flaw cannot authorize all four specials")
	bad=choices.duplicate(true)
	bad.profiles[0].flaws=["Frail"]
	check(not game.characters.valid_setup(bad),"Companion-only creation cannot assign leader flaws")
	var before: Dictionary=game.state.duplicate(true)
	check(not game.depart("banker",setup.party_names(),4,setup.cart(),bad) and game.state==before,"Invalid flaw setup cannot spend cash or start the journey")
	setup.next_button.pressed.emit()
	setup.back_button.pressed.emit()
	check(setup.customization().profiles[1].flaws==["Frail"],"Store round trip retains flaw selection")
	if "--capture" in OS.get_cmdline_user_args():
		var scroll: ScrollContainer=setup.flaw_choice.get_parent().get_parent()
		scroll.scroll_vertical=maxi(0,int(setup.flaw_choice.position.y)-18)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/party-flaws.png")
	check(game.depart("banker",setup.party_names(),4,setup.cart(),choices),"Real departure accepts three-special companion with flaw")
	game._change_health(-4,"exposure")
	check(game.party_health.members[1].health==80 and game.party_health.members[2].health==81,"Frail takes five damage from a four-damage effect; others take four")
	game._change_health(-1,"hunger")
	check(game.party_health.members[1].health==78,"Frail rounds additional damage up, including hunger")
	check("Flaw: Frail" in game.characters.description(1),"Party view explains the companion's flaw")
	var store=Store.new()
	var snapshot: Dictionary=store.capture(game)
	var restored=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored!=null and store.capture(restored)==snapshot,"Flaws and extra specials round-trip without changing any state")
	if restored!=null:
		restored._change_health(-4,"crossing injuries")
		check(restored.party_health.members[1].health==73,"Loaded flaws still affect actual health changes")
	game.characters.profiles[1].flaws=["Slow Healer"]
	game._change_health(6,"care")
	check(game.party_health.members[1].health==81 and game.party_health.members[2].health==86,"Slow Healer receives half the care/rest health gain while others receive full gain")
	game._change_health(1,"rest")
	check(game.party_health.members[1].health==82,"Slow Healer retains a minimum one-point positive gain")
	game._change_health(-4,"illness")
	check(game.party_health.members[1].health==78,"Slow Healer does not also amplify damage")
	setup.special_checks.Veteran.button_pressed=false
	setup.flaw_choice.select(0)
	setup.flaw_choice.item_selected.emit(0)
	check(setup.accepted_flaw.is_empty() and setup.special_count_label.text=="Special traits: 2 / 2" and not setup.customization().profiles[1].has("flaws"),"Removing extra special allows removing flaw without losing remaining choices")
	screen._new_journey()
	check(screen.departure_view.accepted_flaw.is_empty(),"New journey resets flaw draft")
	screen.queue_free()
	await process_frame
	print("Party flaws: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

