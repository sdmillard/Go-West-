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
func choose_back(game) -> void:
	game.pending=game.service_return.duplicate(true)
	game.service_return={}
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
	check(game.crime.record.actors.size()==16 and game.crime.service("fort_bridger").owner=="keeper:fort_bridger" and game.crime.service("fort_bridger").staff==["keeper:fort_bridger","hand:fort_bridger"],"Store service is owned by the keeper and staffed by separate people")
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
		check(restored.crime.record.version==restored.crime.VERSION and migrated.stage=="escape" and migrated.attempt=="resisted","Active incident survives migration at the same stage")
		check(migrated.knowledge.get("keeper:fort_bridger",[])==["attempt"] and migrated.knowledge.get("hand:fort_bridger",[])==["attempt"] and not migrated.knowledge.has("staff:fort_bridger"),"Aggregate staff knowledge becomes each living staff member's knowledge")
		check(restored.crime.service("fort_bridger").alarmed and restored.crime.service("fort_bridger").cash_cents==5000 and restored.state==store.normalize(previous.state),"Stock, cash, alarm and party state are unchanged by migration")
		check(restored.crime.rng.state==int(previous.crime.random) and restored.pending==restored.crime.menu(restored),"Crime random stream and authoritative menu carry over")
		check(store.restore(JSON.parse_string(JSON.stringify(store.capture(restored))))!=null,"Migrated record saves again in the new format")
		check(choose(restored,"flee") and restored.crime.valid(restored.crime.snapshot(),restored),"Migrated encounter can be finished")
	# Genuine save from the previous rules (named witnesses, fixed odds) after a resolved escape.
	previous=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-report-save-v1.json"))
	restored=store.restore(previous)
	check(restored!=null and restored.state==store.normalize(previous.state) and restored.crime.record.incidents.size()==1,"Save from the previous crime rules restores unchanged")
	if restored!=null:
		var upgraded: Array=restored.crime.record.reports
		check(restored.crime.record.version==3 and upgraded.size()==1 and upgraded[0].day==restored.crime.record.incidents[0].day and upgraded[0].identified and upgraded[0].senders==["keeper:fort_bridger","hand:fort_bridger"],"An earlier witnessed escape gains its report, dated to the incident day")
	# Genuine save from the report rules, before the other venues existed: a reported robbery at Fort Bridger.
	previous=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-venues-save-v1.json"))
	check(previous.crime.record.services.size()==1 and previous.crime.record.reports.size()==1,"Fixture predates the other venues")
	restored=store.restore(previous)
	check(restored!=null and restored.state==store.normalize(previous.state) and restored.crime.record.reports==store.normalize(previous.crime.record.reports),"Save from before the other venues restores with its report unchanged")
	if restored!=null:
		check(restored.crime.record.services.size()==restored.crime.scenes.size() and not restored.crime.closed("fort_hall") and restored.crime.service("barlow_pass").cash_cents==4000,"Earlier saves gain the new venues untouched")
		check(store.restore(JSON.parse_string(JSON.stringify(store.capture(restored))))!=null,"The upgraded record saves again")
	var malformed: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-witness-save-v1.json"))
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
	# Witness reports travel down the road and close posts that hear the party named.
	game=willing(outfit())
	game.crime.scenes.fort_bridger.compliance=0
	game.crime.scenes.fort_bridger.escape_capture=0
	game.crime.scenes.fort_bridger.escape_injury=0
	game.open_crime()
	choose(game,"robbery")
	choose(game,"flee")
	check(game.crime.record.reports.size()==1,"A witnessed getaway sends one report")
	var report: Dictionary=game.crime.record.reports[0]
	check(report.identified and report.origin=="fort_bridger" and report.senders.size()==2 and report.facts==["attempt","escape"],"The report names the party and carries exactly what the living witnesses saw")
	check("People here who saw it: 2" in game.pending.text,"The outcome screen says how many people saw it")
	choose(game,"finish")
	var saved_with_report: Dictionary=store.capture(game)
	check(store.restore(JSON.parse_string(JSON.stringify(saved_with_report)))!=null,"Reports round-trip through saves")
	var hall: int=game.crime.arrival(game,report,"fort_hall")
	var miles_apart: int=game.crime.mile(game,"fort_hall")-game.crime.mile(game,"fort_bridger")
	check(miles_apart>0 and hall==report.day+int(game.crime.news_rules.delay_days)+ceili(miles_apart/float(game.crime.news_rules.miles_per_day)),"News reaches the next post after a delay set by distance")
	check(game.crime.arrival(game,report,"fort_laramie")>report.day,"News also travels back east")
	game.state.next_landmark="fort_hall"
	game._arrive_landmark()
	game.state.day=hall-1
	check(not game.crime.refuses(game,"fort_hall") and game.open_trade() and game.pending.title=="Trading post","A party that outruns the news can still trade")
	choose_back(game)
	game.state.day=hall
	check(game.crime.refuses(game,"fort_hall") and game.open_trade() and game.pending.title=="The post will not trade" and "Fort Bridger" in game.pending.text,"Once word arrives, the post refuses to trade and says why")
	choose_back(game)
	game.party_health.members[1].health=50
	check(game.open_care() and not game.pending.choices.any(func(choice):return choice.get("care",0)==12),"The post also refuses paid care; the party's own kits still work")
	choose_back(game)
	check(not game.crime.refuses(game,"fort_bridger"),"The origin store is handled by its own closure, not by the news")
	good=saved_with_report
	bad=good.duplicate(true)
	bad.crime.record.reports=[]
	check(store.restore(bad)==null,"A report cannot be deleted from a save")
	bad=good.duplicate(true)
	bad.crime.record.reports[0].identified=false
	check(store.restore(bad)==null,"A report cannot be downgraded to a vague description")
	bad=good.duplicate(true)
	bad.crime.record.reports[0].day=-1
	check(store.restore(bad)==null,"A report cannot predate its incident")
	bad=good.duplicate(true)
	bad.crime.record.reports[0].facts=["attempt"]
	check(store.restore(bad)==null,"Report facts must match what the witnesses know")
	game=willing(outfit())
	game.crime.scenes.fort_bridger.theft_success=0
	game.crime.scenes.fort_bridger.escape_capture=0
	game.crime.scenes.fort_bridger.escape_injury=0
	game.open_crime()
	choose(game,"theft")
	choose(game,"flee")
	choose(game,"finish")
	report=game.crime.record.reports[0]
	check(not report.identified,"A noticed theft only gives a description")
	game.state.next_landmark="fort_hall"
	game._arrive_landmark()
	game.state.day=game.crime.arrival(game,report,"fort_hall")
	check(not game.crime.refuses(game,"fort_hall") and game.open_trade() and game.pending.title=="Trading post" and "description" in game.pending.text,"A description makes people wary but does not close the post")
	choose_back(game)
	game=willing(outfit())
	game.crime.scenes.fort_bridger.theft_success=1
	game.open_crime()
	choose(game,"theft")
	choose(game,"take")
	check(game.crime.record.reports.is_empty(),"An unseen theft sends no report")
	game=willing(outfit())
	game.crime.scenes.fort_bridger.shot_hit=1
	game.crime.scenes.fort_bridger.shot_fatal=1
	game.crime.scenes.fort_bridger.escape_capture=0
	game.open_crime()
	choose(game,"shoot")
	choose(game,"take")
	choose(game,"flee")
	check(game.crime.record.reports.size()==1 and game.crime.record.reports[0].senders==["hand:fort_bridger"],"With the keeper dead, the hired hand's report still goes out")
	venue_checks(store)
	fort_checks(store)
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


func at(game,place: String):
	game.state.next_landmark=place
	game._arrive_landmark()
	return game
func stop_choice(game,predicate: Callable) -> int:
	for index in range(game.pending.choices.size()):
		if predicate.call(game.pending.choices[index]):return index
	return -1
func leave_index(game) -> int:return stop_choice(game,func(choice):return choice.get("action","")=="leave")
func ferry_index(game) -> int:return stop_choice(game,func(choice):return choice.get("method","")=="ferry")
func seized_index(game) -> int:return stop_choice(game,func(choice):return choice.get("method","")=="seized")
## Every trading post is a store; the Barlow toll gate and the Kansas River ferry are their own venues.
func venue_checks(store) -> void:
	var game=outfit()
	for place in ["fort_laramie","fort_hall","fort_boise"]:
		at(game,place)
		check(game.open_crime() and game.pending.title=="The trading store" and "Accessible food stock" in game.pending.text,"%s has a trading store" % place)
		choose_back(game)
	at(game,"fort_laramie")
	game.open_crime()
	check("Staff on hand: 3" in game.pending.text,"Fort John has a larger staff")
	choose_back(game)
	check(game.crime.valid(game.crime.snapshot(),game),"All venues validate in a new record")
	# Toll gate: getting through unseen waives the toll.
	game=at(willing(outfit()),"barlow_pass")
	var money: float=game.state.money
	check(float(game.pending.choices[leave_index(game)].requires.money)>0,"The toll is owed on arrival")
	game.crime.scenes.barlow_pass.theft_success=1
	check(game.open_crime() and game.pending.title=="The toll gate" and "Gatekeeper: uninjured. Cash box: $40.00." in game.pending.text and "Slip the wagons past" in game.pending.choices[0].label,"The toll gate has its own menu")
	choose(game,"theft")
	check(game.crime.incident().stage=="loot" and game.crime.can_choose(game,"take"),"Passing the gate is the prize even with nothing taken")
	choose(game,"take")
	check(game.crime.incident().resolution=="left" and game.state.money==money,"An unseen pass takes no money")
	choose(game,"finish")
	var leave: Dictionary=game.pending.choices[leave_index(game)]
	check(game.crime.passage("barlow_pass") and leave.requires.is_empty() and leave.effects.is_empty() and "not paid" in leave.label,"Slipping past the gate waives the toll")
	var saved: Dictionary=store.capture(game)
	check(store.restore(JSON.parse_string(JSON.stringify(saved)))!=null,"A waived toll round-trips through saves")
	check(game.choose(leave_index(game)) and game.state.money==money and game.state.next_landmark=="laurel_hill","The party continues without paying")
	game=at(willing(outfit()),"barlow_pass")
	game.crime.scenes.barlow_pass.theft_success=0
	game.crime.scenes.barlow_pass.escape_capture=0
	game.crime.scenes.barlow_pass.escape_injury=0
	game.open_crime()
	choose(game,"theft")
	choose(game,"flee")
	choose(game,"finish")
	check(not game.crime.passage("barlow_pass") and float(game.pending.choices[leave_index(game)].requires.money)>0,"A noticed attempt that runs off still owes the toll")
	game=at(willing(outfit()),"barlow_pass")
	game.crime.scenes.barlow_pass.compliance=1
	game.crime.scenes.barlow_pass.escape_capture=0
	game.crime.scenes.barlow_pass.escape_injury=0
	money=game.state.money
	game.open_crime()
	choose(game,"robbery")
	choose(game,"take")
	choose(game,"flee")
	check(is_equal_approx(game.state.money,money+40) and game.crime.service("barlow_pass").cash_cents==0,"Robbing the gate takes the toll box")
	choose(game,"finish")
	check(game.pending.choices[leave_index(game)].requires.is_empty(),"Robbing the gate also gets the party through")
	game=at(willing(outfit()),"barlow_pass")
	game.crime.scenes.barlow_pass.shot_hit=1
	game.crime.scenes.barlow_pass.shot_fatal=1
	game.crime.scenes.barlow_pass.escape_capture=0
	game.crime.scenes.barlow_pass.escape_injury=0
	game.open_crime()
	choose(game,"shoot")
	choose(game,"flee")
	choose(game,"finish")
	check(game.crime.passage("barlow_pass") and game.pending.choices[leave_index(game)].requires.is_empty(),"Nobody is left to collect the toll from a dead gatekeeper")
	check(game.crime.record.reports.is_empty(),"With the only witness dead, no report leaves the gate")
	# Ferry: taking it means crossing without the crew.
	game=at(willing(outfit()),"kansas_river")
	var hire: int=ferry_index(game)
	check(hire>=0 and game.can_choose(hire) and seized_index(game)==-1,"The crewed ferry is for hire on arrival")
	game.crime.scenes.kansas_river.compliance=1
	game.crime.scenes.kansas_river.escape_capture=0
	game.crime.scenes.kansas_river.escape_injury=0
	check(game.open_crime() and game.pending.title=="The ferry landing" and "Ferryman: uninjured" in game.pending.text and "Threaten the ferryman" in game.pending.choices[1].label,"The ferry has its own menu")
	choose(game,"robbery")
	check("the ferry will be yours" in game.pending.text,"The loot screen says the ferry is the prize")
	choose(game,"take")
	choose(game,"flee")
	choose(game,"finish")
	var seized: int=seized_index(game)
	check(ferry_index(game)==hire and not game.can_choose(hire),"The robbed crew will not carry the party, and earlier choices keep their places")
	check(seized==game.pending.choices.size()-1 and is_equal_approx(float(game.pending.choices[seized].risk),game.crime.seized_risk(game,"kansas_river")),"The taken ferry is offered with its own risk")
	check(game.crime.seized_risk(game,"kansas_river")>0.0,"Working a ferry without its crew is never safe")
	saved=store.capture(game)
	check(store.restore(JSON.parse_string(JSON.stringify(saved)))!=null,"A taken ferry round-trips through saves")
	game.refresh_stop_offers()
	check(game.pending.choices.filter(func(choice):return choice.get("method","")=="seized").size()==1,"Refreshing does not add the taken ferry twice")
	check(game.choose(seized) and game.last_crossing.method=="seized" and game.state.landmark=="kansas_river" and game.state.next_landmark!="kansas_river","The party crosses on the taken ferry")
	game=at(willing(outfit()),"kansas_river")
	game.crime.scenes.kansas_river.theft_success=1
	game.open_crime()
	choose(game,"theft")
	choose(game,"take")
	choose(game,"finish")
	check(seized_index(game)>=0 and not game.can_choose(ferry_index(game)),"A ferry taken unseen can no longer be hired")
	game=at(willing(outfit()),"kansas_river")
	game.crime.scenes.kansas_river.compliance=0
	game.crime.scenes.kansas_river.escape_capture=0
	game.crime.scenes.kansas_river.escape_injury=0
	game.open_crime()
	choose(game,"robbery")
	choose(game,"flee")
	choose(game,"finish")
	check(seized_index(game)==-1 and not game.can_choose(ferry_index(game)),"A failed robbery leaves the party with neither ferry")
	check(game.pending.choices.any(func(choice):return choice.get("method","") in ["ford","float"]),"The party can still ford or float")
	var report: Dictionary=game.crime.record.reports[0]
	at(game,"fort_laramie")
	game.state.day=game.crime.arrival(game,report,"fort_laramie")
	check(game.open_trade() and "robbed the ferry at Kansas River" in game.pending.text,"News names the venue")
	choose_back(game)
	# Saves from before these venues existed gain them untouched.
	game=willing(outfit())
	saved=store.capture(game)
	var old: Dictionary=saved.duplicate(true)
	for place in ["kansas_river","fort_kearny","fort_laramie","fort_hall","fort_boise","barlow_pass"]:
		old.crime.record.services.erase(place)
		for uid in game.crime.staff_ids(place):old.crime.record.actors.erase(uid)
	var restored=store.restore(JSON.parse_string(JSON.stringify(old)))
	check(restored!=null and restored.crime.record.services.size()==restored.crime.scenes.size() and restored.crime.service("fort_laramie").cash_cents==6000 and restored.crime.owner("barlow_pass").health==100,"A save made before the new venues gains them untouched")
	old.crime.record.actors["keeper:fort_laramie"]={"uid":"keeper:fort_laramie","place":"fort_laramie","role":"keeper","health":0}
	check(store.restore(JSON.parse_string(JSON.stringify(old)))==null,"A partial venue in an old save is rejected, not repaired")
	# Rules: every venue declares a kind; only stores hold food; only ferries can be taken.
	var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/crime_scenes.json"))
	var crime=game.crime.get_script().new()
	check(crime.load_data(rules.duplicate(true)),"Shipped venue rules load")
	var broken: Dictionary=rules.duplicate(true)
	broken.scenes.barlow_pass.kind="fort"
	check(not crime.load_data(broken),"An unknown venue kind is rejected")
	broken=rules.duplicate(true)
	broken.scenes.barlow_pass.food_lot=200
	check(not crime.load_data(broken),"A toll gate cannot hold food")
	broken=rules.duplicate(true)
	broken.scenes.kansas_river.erase("seized_risk_high")
	check(not crime.load_data(broken),"A ferry needs a risk for crossing without its crew")
	broken=rules.duplicate(true)
	broken.scenes.fort_hall["seized_risk_low"]=0.1
	check(not crime.load_data(broken),"Only a ferry has a taken-crossing risk")
## Fort Kearny: soldiers close in, and a failed escape becomes a standoff.
func fort_checks(store) -> void:
	var game=outfit()
	game.state.departure_month=3
	game.state.day=40
	at(game,"fort_kearny")
	check(not game.open_crime(),"Before June 1848 nobody is at the Fort Kearny site to rob")
	game=outfit()
	game.state.departure_month=5
	game.state.day=40
	at(willing(game),"fort_kearny")
	check(game.open_crime() and game.pending.title=="The commissary tent" and "Soldiers on duty nearby: 3" in game.pending.text and "shoot its way out" in game.pending.text,"Once soldiers are building the post, its commissary can be targeted")
	choose_back(game)
	game.crime.scenes.fort_kearny.compliance=1
	game.crime.scenes.fort_kearny.escape_capture=1
	game.open_crime()
	choose(game,"robbery")
	var food: int=game.state.food
	check(game.crime.loot_quote(game,"fort_kearny").food>0,"The commissary holds rations to take")
	choose(game,"take")
	check(game.state.food>food,"Rations taken from the commissary reach the wagon")
	choose(game,"flee")
	check(game.crime.incident().stage=="standoff" and game.state.status=="traveling","Soldiers who stop the escape force a standoff, not an instant capture")
	check(game.pending.choices.map(func(choice):return choice.crime_command)==["breakout","surrender","back"],"The standoff offers shooting out or surrender")
	var saved: Dictionary=store.capture(game)
	check(store.restore(JSON.parse_string(JSON.stringify(saved)))!=null,"A standoff round-trips through saves")
	var bullets: int=game.state.bullets
	var copy=store.restore(JSON.parse_string(JSON.stringify(saved)))
	copy.crime.scenes.fort_kearny.breakout=1
	copy.crime.scenes.fort_kearny.shot_hit=1
	copy.crime.scenes.fort_kearny.shot_fatal=1
	var health: int=copy.party_health.members[0].health
	check(choose(copy,"breakout") and copy.crime.incident().resolution=="escaped","A successful breakout gets the party away")
	check(copy.state.bullets==bullets-3 and copy.crime.incident().shots==3,"Shooting out spends the authored bullets")
	check(copy.party_health.members[0].health<health,"Soldiers fire back: someone in the party is hurt")
	check(copy.crime.living_staff("fort_kearny")==["keeper:fort_kearny"],"Each hit can kill a soldier, who stays dead")
	check(copy.crime.record.reports.size()==1 and copy.crime.record.reports[0].senders==["keeper:fort_kearny"] and copy.crime.record.reports[0].identified,"Surviving soldiers still report the party")
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(copy))))!=null,"A breakout round-trips through saves")
	copy=store.restore(JSON.parse_string(JSON.stringify(saved)))
	copy.crime.scenes.fort_kearny.breakout=0
	check(choose(copy,"breakout") and copy.state.status=="lost","A failed breakout ends the journey in custody")
	copy=store.restore(JSON.parse_string(JSON.stringify(saved)))
	check(choose(copy,"surrender") and copy.state.status=="lost","The party can surrender to the soldiers")
	copy=store.restore(JSON.parse_string(JSON.stringify(saved)))
	copy.state.bullets=0
	copy.pending=copy.crime.menu(copy)
	check(not copy.crime.can_choose(copy,"breakout") and copy.crime.can_choose(copy,"surrender"),"Without bullets the only way out is surrender")
	var bad: Dictionary=saved.duplicate(true)
	bad.crime.record.incidents[0].shots=9
	check(store.restore(bad)==null,"A breakout cannot claim more shots than the scene allows")
	# A standoff is a fort's alone.
	game=at(willing(outfit()),"fort_bridger")
	game.crime.scenes.fort_bridger.compliance=1
	game.crime.scenes.fort_bridger.escape_capture=1
	game.open_crime()
	choose(game,"robbery")
	choose(game,"flee")
	check(game.state.status=="lost","A store's staff simply catch the party; only soldiers force a standoff")
	var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/crime_scenes.json"))
	var crime=game.crime.get_script().new()
	var broken: Dictionary=rules.duplicate(true)
	broken.scenes.fort_kearny.erase("breakout")
	check(not crime.load_data(broken),"A fort needs a breakout chance")
	broken=rules.duplicate(true)
	broken.scenes.fort_bridger["food_stock"]=100
	check(not crime.load_data(broken),"Only a fort has its own food stock")
