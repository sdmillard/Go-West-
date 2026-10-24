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
	for profile in game.characters.profiles.slice(1):profile.skill="Trading"
	return game
func encounter(game,id: String):
	for event in game.trail_events.events:
		if event.id==id:game._present_trail_event(event)
func run():
	var game=outfit()
	var store=Store.new()
	var rules: Dictionary=game.characters.benefits.duplicate(true)
	var bad_rules: Dictionary=rules.duplicate(true)
	bad_rules.hunter_reload_factor=0
	check(not game.characters.load_benefits(bad_rules),"Reject invalid reload modifier")
	bad_rules=rules.duplicate(true)
	bad_rules.care_health_bonus=-1
	check(not game.characters.load_benefits(bad_rules) and game.characters.load_benefits(rules),"Reject negative care bonus and restore valid rules")
	var before: Dictionary=store.capture(game)
	check(game.characters.available(game,"Trading") and not game.characters.available(game,"Caregiving") and store.capture(game)==before,"Availability query is pure")
	game.characters.profiles[1].skill="Hunting"
	check(game.characters.available(game,"Hunting"),"Fit hunter supplies background benefit")
	game.party_health.members[1].health=39
	check(not game.characters.available(game,"Hunting"),"Poor health disables background")
	game.party_health.members[1].health=85
	game.party_health.begin_condition(1,"broken_arm",0,3)
	check(not game.characters.available(game,"Hunting"),"Serious condition disables background")
	game.party_health.members[1].conditions.clear()
	game.party_health.members[1].alive=false
	check(not game.characters.available(game,"Hunting"),"Dead specialist does not supply benefits")
	game=outfit()
	game.characters.profiles[1].skill="Hunting"
	game.start_hunt()
	game.hunt_shot(-1)
	check(is_equal_approx(game.hunt.reload,game.hunting.data.reload_seconds*0.8) and game.hunt.shots==1,"Actual hunt reload is shortened without extra shots")
	check(game.hunting.data.carry_limit==200,"Hunter leaves shared party retrieval cap unchanged")
	game=outfit()
	game.characters.profiles[1].skill="Carpentry"
	encounter(game,"breakdown")
	check(game.pending.choices[1].effects.days==1 and game.pending.choices[2].effects.days==2,"Carpenter shortens both time-based repair offers")
	var spare: Dictionary=game.pending.choices[0].effects
	check(spare.values().has(-1) and not spare.has("days"),"Fitting a spare still consumes the part")
	game.choose(2)
	check(game.state.day==2,"Actual wooden repair spends reduced days")
	game=outfit()
	var baseline=outfit()
	game.characters.profiles[1].skill="Caregiving"
	for journey in [game,baseline]:
		journey.party_health.members[0].health=20
		journey.party_health.begin_condition(0,"broken_leg",0,2)
		journey.state.health=journey.party_health.average_health()
		journey.open_care()
	var quoted: Dictionary=store.capture(game)
	var restored=store.restore(JSON.parse_string(JSON.stringify(quoted)))
	check(restored!=null and restored.pending==game.pending,"Enhanced care quote survives save/load")
	var invalid_quote: Dictionary=quoted.duplicate(true)
	invalid_quote.pending.choices[0].care_bonus=100
	check(store.restore(invalid_quote)==null,"Reject corrupted care bonus")
	game.choose(0)
	baseline.choose(0)
	check(game.party_health.members[0].health==baseline.party_health.members[0].health+2,"Caregiver adds actual health recovery")
	check(game.party_health.members[0].conditions[0].elapsed==baseline.party_health.members[0].conditions[0].elapsed+1,"Caregiver advances condition recovery one extra day")
	check(game.state.medicine==1 and game.state.day==1,"Enhanced care still spends a kit, meals and day")
	game=outfit()
	game.state.next_landmark="fort_hall"
	game._arrive_landmark()
	game.open_trade()
	check(game.pending.choices[0].effects.money==-38 and game.pending.choices[1].effects.money==27,"Trader discounts buying while selling quote stays unchanged (Fort Hall pays its regional price)")
	game.choose(0)
	check(game.state.day==1 and game.context.record.spent.size()>0,"Discounted transaction consumes day and finite stock")
	game=outfit()
	for profile in game.characters.profiles.slice(1):profile.specials=["Veteran"]
	check(is_equal_approx(game.combat.risk(game,"defend",0.25),0.22),"Multiple veterans give one three-point reduction")
	check(is_equal_approx(game.combat.risk(game,"defend",0.05),0.15),"Veteran never bypasses confrontation risk floor")
	for member in game.party_health.members.slice(1):member.health=39
	check(not game.characters.available(game,"","Veteran"),"Incapacitated veterans cannot assist")
	game=outfit()
	game.characters.profiles[1].traits=["Cautious","Compassionate"]
	game.characters.profiles[1].trust=32
	game.party_health.begin_condition(0,"broken_leg",0,2)
	game.health_events.clear()
	game.state.pace=2
	game.travel()
	check(game.pending.get("id","")=="party_health" and "I object" in game.pending.text and "weakening" in game.pending.text,"Grueling travel surfaces named objection and approaching breaking point")
	var snapshot: Dictionary=store.capture(game)
	restored=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored!=null and restored.pending==game.pending,"Unacknowledged companion warning survives loading")
	before=store.capture(game)
	game.characters.concern(game,"push_sick")
	check(store.capture(game)==before,"Predecision concern does not change trust or random state")
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-background-benefits-save-v1.json"))
	restored=store.restore(old)
	check(restored!=null and restored.pending==store.normalize(old.pending) and restored.state==store.normalize(old.state) and restored.rng.state==int(old.random),"Real prior save preserves old quotes, supplies and random state during migration")
	if restored!=null:check(not restored.pending.choices[0].has("care_bonus"),"Old unquoted care is not retroactively enhanced")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=game
	screen._refresh()
	check("I object" in screen.event_text.text,"Companion objection is visible in actual event UI")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/companion-warning.png")
	screen.selected_member=1
	screen._show_party()
	check("PARTY BENEFIT" in screen.member_details.text,"Party details explain concrete background benefit and eligibility")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		screen.member_details.get_v_scroll_bar().value=screen.member_details.get_v_scroll_bar().max_value
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/party-benefits.png")
	screen.queue_free()
	await process_frame
	print("Party benefits: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
