extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Store = preload("res://simulation/save_store.gd")
const Main = preload("res://ui/main.tscn")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func outfit():
	var game=Simulation.new(57,"classic",true)
	game.depart("farmer",["A","B","C","D","E"],5,{"oxen":6,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"salt":10})
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	game.seen.append("muddy_trail")
	game.provisions.add_fresh(100,0)
	return game
func run() -> void:
	var game=outfit()
	var original: Dictionary=game.provisions.data.duplicate(true)
	for field in ["retained_food","salted_retained_food","dried_weight","salt_per_food_lb"]:
		var bad:=original.duplicate(true)
		bad.preservation[field]=1.1
		check(not game.provisions.load_data(bad),"Reject preservation ratio above one: "+field)
		check(game.provisions.load_data(original),"Valid preservation data recovers")
	check(game.preservation_offer().input==85 and game.preservation_offer(true).salt==5,"Preview accounts for meals before processing and rounds salt requirement up")
	check(game.preserve_meat() and game.state.day==1 and game.state.food==568 and game.state.salt==10,"Drying spends one day, fifteen meal pounds and seventeen processing pounds")
	check(game.provisions.fresh_pounds(568)==0 and game.provisions.preserved_pounds(568)==68,"Fresh batch converts to retained ration equivalents exactly once")
	check(is_equal_approx(game.provisions.cargo(game.state),1178.8),"Dried food mass is separate from retained meals and actual salt cargo")
	check(not game.preserve_meat() and game.state.day==1,"Already dried food cannot be processed again for an advantage")
	check(game.supply_history[-1].event=="preservation" and game.supply_history[-1].changes.food==-17,"Processing losses recorded separately from ordinary meals")
	check(game.provisions.fresh[0].expires==23,"Unsalted food has a finite twenty-one-day window after processing")
	game=outfit()
	check(game.preserve_meat(true) and game.state.food==576 and game.state.salt==5,"Salt improves retained yield, costs real stock and consumes one day")
	check(game.provisions.fresh[0].expires==32 and game.provisions.fresh[0].preserved,"Salted food has a finite thirty-day window after processing")
	var store=Store.new()
	game.party_health.daily_onset_chance=JSON.parse_string(FileAccess.get_file_as_string("res://data/health_conditions.json")).daily_onset_chance
	game.survival.data.event_chance=JSON.parse_string(FileAccess.get_file_as_string("res://data/survival_rules.json")).event_chance
	game.survival.forced_weather=""
	var snapshot:=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null and store.capture(copy)==snapshot and is_equal_approx(copy.provisions.cargo(copy.state),game.provisions.cargo(game.state)),"Preservation type, expiry, salt and cargo survive JSON save/load")
	var bad_save:=snapshot.duplicate(true)
	bad_save.fresh[0].preserved="yes"
	check(store.restore(bad_save)==null,"Malformed preservation flags cannot enter through saves")
	if copy!=null:
		for day in range(8):
			game.pending.clear()
			copy.pending.clear()
			game.rest()
			copy.rest()
			check(store.capture(copy)==store.capture(game),"Saved preserved meals continue deterministically")
	game=outfit()
	game.state.salt=0
	var before:=store.capture(game)
	check(not game.preserve_meat(true) and store.capture(game)==before,"Insufficient salt rejects without spending time, food or RNG")
	check(game.preserve_meat(false),"Drying remains available without salt")
	game=outfit()
	game.provisions.fresh.clear()
	before=store.capture(game)
	check(not game.preserve_meat() and store.capture(game)==before,"Staples cannot be dried into extra food or time")
	game=outfit()
	game.pending={"id":"test_event","title":"Stop","text":"Resolve first","choices":[{"label":"Continue","effects":{},"result":"Continue"}]}
	before=store.capture(game)
	check(not game.preserve_meat() and store.capture(game)==before,"An unresolved encounter blocks preservation")
	game=outfit()
	game.state.day=2
	before=store.capture(game)
	check(not game.preserve_meat() and store.capture(game)==before,"Cannot rescue a batch that spoils before processing day meals")
	game=outfit()
	game.provisions.fresh.clear()
	game.provisions.fresh.append({"pounds":60,"expires":10,"preserved":true})
	game.provisions.add_fresh(20,0)
	game.rest()
	check(game.provisions.fresh_pounds(game.state.food)==5 and game.provisions.preserved_pounds(game.state.food)==60,"Meals prefer sooner-spoiling fresh meat over older dried meat")
	check(game.provisions.spoil(10,game.state.food)==65,"Fresh and preserved leftovers both expire without creating food")
	game=outfit()
	game.state.next_landmark="fort_hall"
	game._arrive_landmark()
	check(game.preserve_meat(true) and game.pending.landmark=="fort_hall" and game.state.day==1,"Preserving at a stop retains its unresolved landmark")
	game.open_trade()
	var salt_before: int=game.state.salt
	var cash: float=game.state.money
	var found:=false
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("effects",{}).get("salt",0)>0:
			found=game.choose(index)
			break
	check(found and game.state.salt==salt_before+10 and is_equal_approx(game.state.money,cash-2.57) and game.state.day==2,"Salt at Hall carries the regional premium and trading discount, one day and ordinary meals")
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-economy-save-v1.json"))
	game=store.restore(previous)
	check(game!=null and game.state.salt==0 and game.state.money==previous.state.money and game.state.food==previous.state.food and game.state.day==previous.state.day,"Pre-economy saves keep cash, food and time; no salt retroactively granted")
	if game!=null:
		check(game.party_health.members==store.normalize(previous.party) and game.rng.state==int(previous.random),"Migration retains people and random sequence")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.show_store()
	await process_frame
	var salt_widget=screen.departure_view.quantities.salt
	# The longer list scrolls; bring the row into view as a player would.
	salt_widget.get_parent().get_parent().ensure_control_visible(salt_widget)
	await process_frame
	check(salt_widget.get_global_rect().end.y<=screen.departure_view.totals.get_global_rect().position.y,"Ninth store row fits above totals")
	var rows: Array=screen.departure_view.quantities.values()
	for index in range(rows.size()-1):
		check(rows[index].get_global_rect().end.y<=rows[index+1].get_global_rect().position.y,"Store quantity rows do not overlap")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/economy-store.png")
	screen.departure_view.hide()
	screen.game=outfit()
	screen._refresh()
	screen._show_section("Preserve meat")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/preservation-options.png")
	var pressed:=false
	for child in screen.section_rows.get_children():
		if child is Button and child.text.begins_with("SALT + DRY"):
			child.pressed.emit()
			pressed=true
			break
	check(pressed and screen.game.state.day==1 and screen.game.state.salt==5 and screen.game.provisions.preserved_pounds(screen.game.state.food)==76,"Actual provisions button invokes salted preservation")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/preservation.png")
	screen.queue_free()
	await process_frame
	print("Preservation: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
