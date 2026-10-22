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
func willing(game):
	for profile in game.characters.profiles.slice(1):profile.boundaries=game.characters.catalog.boundaries("Opportunistic")
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
	bad.crime.record.services.fort_bridger.cash_cents=5001
	check(store.restore(bad)==null,"Invented actor cash rejects")
	bad=good.duplicate(true)
	bad.pending.choices[0].crime_command="take"
	check(store.restore(bad)==null,"Saved command injection rejects against authoritative stage menu")
	bad=good.duplicate(true)
	bad.crime.record.incidents[0].attempt="unseen"
	check(store.restore(bad)==null,"Impossible attempt/outcome combinations reject")
	bad=good.duplicate(true)
	bad.crime.record.services.fort_bridger.alarmed=false
	check(store.restore(bad)==null,"A witnessed attack cannot erase the local alarm")
	# Named staff witnesses replace the old aggregate observer.
	var witnessed: Dictionary={}
	for action in ["theft","robbery","shoot"]:
		for seed_value in range(30):
			game=outfit(seed_value)
			game.open_crime()
			choose(game,action)
			var current: Dictionary=game.crime.incident()
			var local: Array=game.crime.local_witnesses(current)
			witnessed[current.attempt]=local
			if current.attempt=="unseen":check(local.is_empty(),"Nobody at the store knows of an unseen theft")
			else:
				check("hand:fort_bridger" in local,"The hired hand personally witnesses a noticed attempt")
				check(("keeper:fort_bridger" in local)==(current.attempt!="killed"),"A keeper killed by the shot learns nothing; a living keeper is a witness")
			check(not current.knowledge.has("staff:fort_bridger"),"No aggregate staff observer remains")
	for outcome in ["unseen","noticed","killed"]:check(witnessed.has(outcome),"Witness sample exercises "+outcome)
	game=outfit()
	check(game.crime.record.actors.size()==2 and game.crime.service("fort_bridger").owner=="keeper:fort_bridger" and game.crime.service("fort_bridger").staff==["keeper:fort_bridger","hand:fort_bridger"],"Store service is owned by the keeper and staffed by separate people")
	game.crime.scenes.fort_bridger.shot_hit=1
	game.crime.scenes.fort_bridger.shot_fatal=1
	game.open_crime()
	choose(game,"shoot")
	check(game.crime.owner("fort_bridger").health==0 and game.crime.record.actors["hand:fort_bridger"].health==100,"Killing the keeper does not kill or silence the other staff")
	good=store.capture(game)
	bad=good.duplicate(true)
	bad.crime.record.incidents[0].knowledge.erase("hand:fort_bridger")
	check(store.restore(bad)==null,"A living witness cannot be edited out of a saved incident")
	bad=good.duplicate(true)
	bad.crime.record.incidents[0].knowledge["keeper:fort_bridger"]=["attempt"]
	check(store.restore(bad)!=null,"A dead person's earlier knowledge is allowed to remain on record")
	bad=good.duplicate(true)
	bad.crime.record.incidents[0].knowledge["hand:fort_hall"]=["attempt"]
	check(store.restore(bad)==null,"Witnesses from another place are rejected")
	bad=good.duplicate(true)
	bad.crime.record.actors["hand:fort_bridger"].health=150
	check(store.restore(bad)==null,"Staff health is bounded per person")
	bad=good.duplicate(true)
	bad.crime.record.actors.erase("hand:fort_bridger")
	check(store.restore(bad)==null,"A staff member cannot be deleted from the record")
	bad=good.duplicate(true)
	bad.crime.record.actors["clerk:fort_bridger"]={"uid":"clerk:fort_bridger","place":"fort_bridger","role":"clerk","health":100}
	check(store.restore(bad)==null,"Extra invented people are rejected")
	# Genuine save written by the previous (aggregate observer) version, mid-escape after resisted robbery.
	previous=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-witness-save-v1.json"))
	check(previous.crime.record.version==1 and previous.crime.record.incidents[0].knowledge.has("staff:fort_bridger"),"Fixture is a real version 1 crime record")
	restored=store.restore(previous)
	check(restored!=null,"Version 1 crime save migrates")
	if restored!=null:
		var migrated: Dictionary=restored.crime.incident()
		check(restored.crime.record.version==2 and migrated.stage=="escape" and migrated.attempt=="resisted","Active incident survives migration at the same stage")
		check(migrated.knowledge.get("keeper:fort_bridger",[])==["attempt"] and migrated.knowledge.get("hand:fort_bridger",[])==["attempt"] and not migrated.knowledge.has("staff:fort_bridger"),"Aggregate staff knowledge becomes each living staff member's knowledge")
		check(restored.crime.service("fort_bridger").alarmed and restored.crime.service("fort_bridger").cash_cents==5000 and restored.state==store.normalize(previous.state),"Stock, cash, alarm and party state are unchanged by migration")
		check(restored.crime.rng.state==int(previous.crime.random) and restored.pending==restored.crime.menu(restored),"Crime random stream and authoritative menu carry over")
		check(store.restore(JSON.parse_string(JSON.stringify(store.capture(restored))))!=null,"Migrated record saves again in the new format")
		check(choose(restored,"flee") and restored.crime.valid(restored.crime.snapshot(),restored),"Migrated encounter can be finished")
	var malformed: Dictionary=previous.duplicate(true)
	malformed.crime.record.actors.fort_bridger.uid="keeper:elsewhere"
	check(store.restore(malformed)==null,"Malformed version 1 record still rejects")
	# Situational odds: experience and condition shift intimidation, aim and escape, never noticing.
	game=outfit()
	check(game.crime.able(game,"robbery")==1 and game.crime.odds(game,"fort_bridger").edge<0,"A leader with only objecting companions has no willing help")
	for profile in game.characters.profiles.slice(1):profile.boundaries=game.characters.catalog.boundaries("Opportunistic")
	check(game.crime.able(game,"robbery")==5 and game.crime.able(game,"murder")==1,"Willing participants depend on each companion's own boundaries for the act")
	var base: Dictionary=game.crime.scenes.fort_bridger
	var base_theft: float=base.theft_success
	var even: Dictionary=game.crime.odds(game,"fort_bridger")
	check(is_zero_approx(even.edge) and even.compliance==base.compliance and even.shot_hit==base.shot_hit and even.escape_capture==base.escape_capture and even.theft_success==base.theft_success,"Healthy, inexperienced, full-staff odds equal the authored scene values")
	preview=store.capture(game)
	game.crime.odds(game,"fort_bridger")
	check(store.capture(game)==preview,"Computing odds is pure")
	for member in game.party_health.members:member.health=30
	var weak: Dictionary=game.crime.odds(game,"fort_bridger")
	check(weak.compliance<even.compliance and weak.shot_hit<even.shot_hit and weak.escape_capture>even.escape_capture and weak.escape_injury>even.escape_injury,"A party in poor condition intimidates, aims and escapes worse")
	check(weak.theft_success==even.theft_success,"Party condition does not change whether a theft is noticed")
	game=willing(outfit())
	game.crime.scenes.fort_bridger.theft_success=1
	game.open_crime()
	choose(game,"theft")
	choose(game,"take")
	choose(game,"finish")
	check(game.crime.experience(game)==1,"Getting away with a job counts as experience")
	var seasoned: Dictionary=game.crime.odds(game,"fort_bridger")
	check(seasoned.compliance>even.compliance and seasoned.escape_capture<even.escape_capture,"Experience improves intimidation and escape")
	game.crime.scenes.fort_bridger.theft_success=base_theft
	check(is_equal_approx(game.crime.odds(game,"fort_bridger").theft_success,base_theft+game.crime.modifiers.stealth_step),"Experience gives a smaller bonus to going unnoticed")
	game.crime.scenes.fort_bridger.theft_success=1
	check(is_equal_approx(game.crime.odds(game,"fort_bridger").theft_success,minf(1.0,1.0)),"Authored certainty is kept")
	game.open_crime()
	choose(game,"theft")
	choose(game,"take")
	choose(game,"finish")
	check(game.crime.experience(game)==1,"The same resolved target never counts twice")
	game=willing(outfit())
	game.crime.scenes.fort_bridger.compliance=0
	game.open_crime()
	choose(game,"robbery")
	game.crime.scenes.fort_bridger.escape_capture=0
	choose(game,"flee")
	check(game.crime.experience(game)==0,"Escaping a resisted robbery is not a successful job")
	game=willing(outfit())
	for day in range(6):game.combat.history.append({"day":0,"event":"bandits","tactic":"defend","outcome":"won","victim":0,"risk":0.2})
	check(game.crime.experience(game)==int(game.crime.modifiers.experience_cap),"Defensive victories count toward a capped total")
	var veteran: Dictionary=game.crime.odds(game,"fort_bridger")
	check(veteran.escape_capture>=game.crime.modifiers.floor and veteran.compliance<=game.crime.modifiers.ceiling and veteran.compliance<1,"A capped veteran is still never certain to succeed or escape")
	game.open_crime()
	check("Prior successful jobs counted: 3 of 3" in game.pending.text and "Staff on hand: 2" in game.pending.text,"The store menu shows the factors behind the odds")
	game=willing(outfit())
	game.crime.scenes.fort_bridger.shot_hit=1
	game.crime.scenes.fort_bridger.shot_fatal=1
	game.open_crime()
	choose(game,"shoot")
	check(game.crime.odds(game,"fort_bridger").escape_capture<even.escape_capture,"A dead keeper leaves fewer people to stop the escape")
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


