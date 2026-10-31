extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func outfit():
	var game=Simulation.new(57,"classic",true)
	game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":1000,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
	game.seen.append("muddy_trail")
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	return game
func rest(game):
	game.pending={}
	game.rest()
func stop(game,id: String="fort_laramie"):
	game.pending={}
	game.state.next_landmark=id
	game._arrive_landmark()
func angry():
	var game=outfit()
	for companion in game.characters.profiles.slice(1):companion.skill="Hunting"
	game.characters.profiles[1].trust=20
	game.characters.review_exit(game,game.characters.profiles[1])
	rest(game)
	stop(game)
	return game
func run():
	var store=Store.new()
	var game=outfit()
	for companion in game.characters.profiles.slice(1):companion.skill="Hunting"
	var profile: Dictionary=game.characters.profiles[1]
	profile.skill="Caregiving"
	profile.trust=20
	check(not game.characters.willing(1,"care") and not game.characters.available(game,"Caregiving"),"Breaking-point companion refuses their optional work")
	profile.trust=50
	profile.boundaries.forbidden.append("care")
	check(not game.characters.willing(1,"care"),"Forbidden boundary prevents participation before loyalty threshold")
	profile.trust=80
	check(game.characters.willing(1,"care"),"High trust permits reluctant participation")
	for companion in game.characters.profiles.slice(1):companion.trust=20
	check(game.combat.risk(game,"defend",0.25)>0.25 and "refuse" in game.characters.concern(game,"defend"),"Refusing companions no longer count as willing defenders")
	game=angry()
	check(game.characters.departure_candidates(game)==[1],"Prior warning and notice period make settlement departure eligible")
	var before: Dictionary=store.capture(game)
	check(game.choose(0) and game.pending.choices[0].get("departure_review",false) and store.upgraded_state(game.state)==before.state,"Continue opens explicit belongings review without spending a day")
	var quote: Dictionary=store.capture(game)
	var restored=store.restore(JSON.parse_string(JSON.stringify(quote)))
	check(restored!=null and store.capture(restored)==quote,"Pending departure review round-trips")
	var food: int=game.state.food
	var clothing: int=game.state.clothing
	var cash: float=game.state.money
	var bullets: int=game.state.bullets
	var cargo: float=game.provisions.cargo(game.state)
	var day: int=game.state.day
	game.choose(0)
	var left: Dictionary=game.party_health.members[1]
	check(left.alive and left.get("departed",false) and left.death_day==-1 and left.cause=="","Departure records a living person rather than a synthetic death")
	check(game.state.party_size==4 and game.party_health.living_count()==4,"Active party count drops without deleting identity")
	check(game.state.food==food-9 and game.state.clothing==clothing-1 and game.state.money==cash and game.state.bullets==bullets,"Only stated meals and clothing leave communal stock")
	check(game.provisions.cargo(game.state)==cargo-30 and game.state.departed_gear_lb==15,"Personal gear and supplies are removed from wagon cargo exactly once")
	check(game.state.day==day and game.pending.landmark=="fort_laramie","Acknowledgement remains at settlement and costs no extra day")
	quote=store.capture(game)
	restored=store.restore(JSON.parse_string(JSON.stringify(quote)))
	check(restored!=null and store.capture(restored)==quote,"Living departed member, belongings and reduced count save/load exactly")
	var frozen: Dictionary=left.duplicate(true)
	food=game.state.food
	game._tick_day(true)
	check(left==frozen and game.state.food==food-12,"Departed member stops eating and receiving simulated health changes")
	check(not game.party_health.begin_condition(1,"broken_leg",game.state.day),"Departed person cannot receive new health events")
	check("Left party: B" in game.journey_summary() and "Deaths: None" in game.journey_summary(),"Journey recap separates departures from deaths")
	for field in ["departure_day","departure_place","departure_supplies"]:
		var bad: Dictionary=quote.duplicate(true)
		bad.party[1][field]="invalid"
		check(store.restore(bad)==null,"Reject corrupt departure field: "+field)
	var bad: Dictionary=quote.duplicate(true)
	bad.state.departed_gear_lb=0
	check(store.restore(bad)==null,"Reject gear/count inconsistency")
	game=angry()
	game.choose(0)
	game.choose(game.pending.choices.size()-1)
	check(game.state.party_size==5 and game.pending.landmark=="fort_laramie","Returning from review does not remove a companion")
	game.choose(0)
	check(game.pending.get("service_menu",false),"Continuing again cannot silently bypass outstanding departure")
	game=outfit()
	game.characters.profiles[1].trust=20
	game.characters.review_exit(game,game.characters.profiles[1])
	stop(game)
	check(game.characters.departure_candidates(game).is_empty(),"New warning includes a day of notice")
	rest(game)
	stop(game,"kansas_river")
	check(game.characters.departure_candidates(game).is_empty(),"No abandonment at a river crossing")
	stop(game,"fort_kearny")
	check(game.characters.departure_candidates(game).is_empty(),"Unbuilt early-1848 Fort Kearny is not a refuge")
	game=outfit()
	profile=game.characters.profiles[1]
	profile.specials=["Mercenary"]
	game.characters.start_contract(game,1,500,1)
	for index in range(5):rest(game)
	check(not profile.exit_warning.is_empty() and profile.exit_warning.reason=="repeated unpaid wages","Repeated missed wages create an explicit departure warning")
	stop(game)
	game.choose(0)
	check(game.characters.pay_wages(game,1) and profile.exit_warning.is_empty(),"Paying arrears can resolve the cause while review is open")
	check(game.health_events.any(func(message):return "is staying" in message),"Resolving a departure warning produces explicit reassuring party news")
	game.choose(0)
	check(game.state.party_size==5 and not game.party_health.members[1].get("departed",false),"Commit rechecks concerns after payment instead of enforcing stale departure")
	game=outfit()
	profile=game.characters.profiles[1]
	profile.specials=["Mercenary"]
	game.characters.start_contract(game,1,500,1)
	for index in range(5):rest(game)
	stop(game)
	game.choose(0)
	game.choose(0)
	var debt: int=profile.contract.arrears_cents
	game.characters.advance_contracts(game)
	check(profile.contract.arrears_cents==debt and game.characters.pay_wages(game,1),"Left mercenary stops accruing but can receive final debt at the same settlement")
	check(game.party_health.members[1].get("departed",false),"Final payment does not silently rehire")
	game=angry()
	for member in game.party_health.members:member.health=100
	game.state.health=100
	game.state.vehicle="foot"
	game.state.food=89
	game.state.bullets=10
	for key in ["wheels","axles","tongues","parts","medicine","salt"]:game.state[key]=0
	check(game.provisions.cargo(game.state)<=game.provisions.capacity(game.state),"Walking party fits packs before departure")
	game.choose(0)
	game.choose(0)
	check(game.provisions.capacity(game.state)==160 and game.provisions.cargo(game.state)>160,"Departure lowers walking capacity without deleting excess possessions")
	game.choose(0)
	day=game.state.day
	game.travel()
	check(game.state.day==day and not game.pending.is_empty(),"Overloaded remaining walkers must repack before another travel day")
	game=angry()
	game.characters.profiles[2].trust=20
	game.characters.review_exit(game,game.characters.profiles[2])
	game.rest_in_camp()
	game.state.food=5
	game.provisions.add_fresh(5,game.state.day)
	game.state.clothing=1
	var plan: Array=game.departure_plan()
	check(plan.size()==2 and plan[0].food==3 and plan[1].food==2,"Multiple departures split scarce food evenly with deterministic remainder")
	game.choose(0)
	game.choose(0)
	check(game.state.party_size==3 and game.state.food==0 and game.state.clothing==0 and game.provisions.fresh.is_empty(),"Scarce supplies and fresh-meat ledger transfer without creating or losing stock")
	game=outfit()
	game.characters.profiles[1].trust=20
	game.characters.review_exit(game,game.characters.profiles[1])
	for member in game.party_health.members:member.health=100
	game.state.health=100
	check(game.abandon_wagon({"food":90,"clothing":5,"bullets":10}),"Cache integration test packs a valid walking party")
	stop(game)
	var cache: Dictionary=game.wagon_cache.duplicate(true)
	game.choose(0)
	game.choose(0)
	quote=store.capture(game)
	check(game.wagon_cache==cache and store.restore(JSON.parse_string(JSON.stringify(quote)))!=null,"Departure preserves cached possessions and saves reduced walking party")
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-companion-departures-save-v1.json"))
	restored=store.restore(previous)
	check(restored!=null and restored.state==store.upgraded_state(previous.state) and restored.characters.profiles.all(func(p):return p.exit_warning.is_empty()),"Prior schema upgrades without invented departure warnings or state changes")
	var daily=outfit()
	var weekly=outfit()
	for journey in [daily,weekly]:journey.characters.profiles[1].specials=["Mercenary"]
	daily.characters.start_contract(daily,1,500,1)
	weekly.characters.start_contract(weekly,1,3500,7)
	var original_cash: float=daily.state.money
	for index in range(7):
		for journey in [daily,weekly]:
			rest(journey)
			journey.characters.pay_wages(journey,1)
	check(daily.characters.profiles[1].trust==52 and weekly.characters.profiles[1].trust==52,"Daily and weekly pay earn the same trust per fulfilled week")
	check(is_equal_approx(daily.state.money,original_cash-35) and is_equal_approx(weekly.state.money,original_cash-35),"Frequency normalization charges equal wages for equal work")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=angry()
	screen._refresh()
	screen._choose(0)
	check(screen.service_window.visible and screen.service_window.title=="Companions intend to leave","Actual continue button opens departure review")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/departure-review.png")
	screen._service_choice(0)
	screen._show_party()
	screen._select_member(1)
	check("LEFT THE PARTY" in screen.member_details.text and screen.party_rows.get_children().any(func(row):return row.has_meta("traveler_id") and row.get_meta("traveler_id")==1 and "LEFT PARTY" in row.text),"Party screen identifies a living departed traveler")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/departed-companion.png")
	screen.queue_free()
	await process_frame
	print("Departures: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

