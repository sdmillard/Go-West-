extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	game.state.next_landmark="fort_bridger"
	game._arrive_landmark()
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	for profile in game.characters.profiles.slice(1):
		profile.traits=["Cautious","Compassionate"]
		profile.boundaries=game.characters.catalog.boundaries("Compassionate")
	return game
func choose(game,command: String) -> bool:
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("crime_command","")==command:return game.choose(index)
	return false
func run():
	var store=Store.new()
	var game=outfit()
	var start: Dictionary=store.capture(game)
	check(game.crime.valid(game.crime.snapshot(),game),"New persistent actor/person record validates")
	check(game.open_crime(),"Store action opens at the actual stop")
	var preview: Dictionary=store.capture(game)
	check(game.open_crime() and store.capture(game)==preview,"Inspecting an open menu is pure")
	check(store.restore(JSON.parse_string(JSON.stringify(preview)))!=null,"Preview restores exactly")
	check(choose(game,"back") and store.capture(game)==start,"Back before an attempt spends no time, supplies or RNG")
	var outcomes: Dictionary={}
	for action in ["theft","robbery","shoot"]:
		for seed_value in range(30):
			game=outfit(seed_value)
			var bullets: int=game.state.bullets
			var trust: float=game.characters.profiles[1].trust
			game.open_crime()
			check(choose(game,action) and game.state.day==1,"Committed attempt costs one actual day")
			var current: Dictionary=game.crime.incident()
			outcomes[current.attempt]=true
			check(game.state.bullets==bullets-(1 if action=="shoot" else 0),"Shots consume ammunition; threats do not")
			check(game.characters.profiles[1].trust==trust-12,"Witnessed forbidden attempt damages trust even on failure")
			var snapshot: Dictionary=store.capture(game)
			var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
			check(copy!=null and store.capture(copy)==snapshot,"Committed incident stage round-trips exactly")
			if copy==null:continue
			copy.party_health.daily_onset_chance=0
			copy.survival.forced_weather="clear"
			copy.survival.data.event_chance=0
			check(not choose(game,"back") and not game.travel() and not game.rest() and not game.open_trade(),"Unresolved danger cannot be canceled into ordinary travel or services")
			if current.stage=="loot":
				var quote: Dictionary=game.crime.loot_quote(game,"fort_bridger")
				var food: int=game.state.food
				var cash: float=game.state.money
				check(choose(game,"take") and choose(copy,"take"),"Loot can be committed once from a successful attempt")
				check(game.state.food==food+int(quote.food)-15 and is_equal_approx(game.state.money,cash+quote.money/100.0),"Loot respects cargo and spends an ordinary day's meals")
				check(not choose(game,"take"),"Already taken loot cannot be claimed again")
			if game.crime.incident().stage=="escape":
				choose(game,"flee")
				choose(copy,"flee")
			check(store.capture(game)==store.capture(copy),"Save/load preserves committed random outcomes and future escape")
			check(game.crime.valid(game.crime.snapshot(),game),"Resolved ledger conserves cash and stock")
			check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"Final report or capture round-trips")
			if game.state.status=="traveling":
				choose(game,"finish")
				check(game.pending.landmark=="fort_bridger","Acknowledgement returns to the same stop")
				if game.crime.closed("fort_bridger"):
					game.open_trade()
					check(game.pending.title=="The store is closed","Alerted staff do not reopen normal trade")
	for outcome in ["unseen","noticed","complied","resisted","missed","wounded","killed"]:check(outcomes.has(outcome),"Seed sample exercises "+outcome)
	game=outfit()
	game.state.bullets=0
	game.open_crime()
	preview=store.capture(game)
	check(not choose(game,"shoot") and not choose(game,"robbery") and store.capture(game)==preview,"Empty gun blocks armed actions atomically")
	game=outfit()
	game.characters.react_to_incident(game,"robbery",1)
	game.characters.react_to_incident(game,"robbery",1)
	game.characters.react_to_incident(game,"robbery",2)
	check(game.characters.profiles[1].trust==26,"Incident reaction is once per incident, not once per day")
	game=outfit()
	game.crime.scenes.fort_bridger.theft_success=1
	game.open_crime()
	choose(game,"theft")
	choose(game,"take")
	choose(game,"finish")
	var remaining: int=game.crime.food_left(game,"fort_bridger")
	game.open_trade()
	var consumed:=0
	while game.can_choose(0):
		game.choose(0)
		consumed+=200
		game.open_trade()
	check(consumed<=remaining and game.crime.food_left(game,"fort_bridger")<200,"Theft and legitimate purchases share a finite food source")
	game=outfit()
	game.open_trade()
	var barter: int=-1
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].effects.get("food",0)==40:barter=index
	check(barter>=0 and game.choose(barter) and game.crime.food_left(game,"fort_bridger")==1560,"Barter transfers forty physical pounds rather than deleting a full bulk lot")
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"Exact purchase/barter depletion round-trips")
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-crime-save-v1.json"))
	var restored=store.restore(previous)
	check(restored!=null and restored.state==store.normalize(previous.state) and restored.characters.profiles==store.normalize(previous.characters),"Authentic old save keeps people, contract and inventory without invented incidents")
	game=outfit()
	game.open_crime()
	choose(game,"shoot")
	var good: Dictionary=store.capture(game)
	for field in ["random","record"]:
		var bad: Dictionary=good.duplicate(true)
		bad.crime[field]=null
		check(store.restore(bad)==null,"Malformed crime root rejects")
	var bad: Dictionary=good.duplicate(true)
	bad.crime.record.actors.fort_bridger.cash_cents=5001
	check(store.restore(bad)==null,"Invented actor cash rejects")
	bad=good.duplicate(true)
	bad.pending.choices[0].crime_command="take"
	check(store.restore(bad)==null,"Saved command injection rejects against authoritative stage menu")
	bad=good.duplicate(true)
	bad.crime.record.incidents[0].attempt="unseen"
	check(store.restore(bad)==null,"Impossible attempt/outcome combinations reject")
	bad=good.duplicate(true)
	bad.crime.record.actors.fort_bridger.alarmed=false
	check(store.restore(bad)==null,"A witnessed attack cannot erase the local alarm")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=outfit()
	screen._refresh()
	screen._open_crime()
	check(screen.service_window.visible and screen.service_window.title=="The trading store","Actual store menu is reachable in the native UI")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/store-actions.png")
	screen.game.crime.scenes.fort_bridger.escape_capture=1
	screen._service_choice(1)
	if screen.game.crime.incident().stage=="loot":choose(screen.game,"flee")
	if screen.game.state.status=="traveling" and screen.game.crime.incident().stage=="escape":choose(screen.game,"surrender")
	if screen.game.state.status=="lost":
		screen.service_window.hide()
		screen._refresh()
		check(not screen.choices.get_children().any(func(child):return child is Button and child.text=="LEAVE A GRAVESTONE"),"Living captured party does not receive a false grave prompt")
	screen.queue_free()
	await process_frame
	print("Store crime: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)


