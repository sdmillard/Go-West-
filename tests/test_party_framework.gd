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
func run():
	var store=Store.new()
	var game=outfit()
	var profile: Dictionary=game.characters.profiles[1]
	var priced: Dictionary=profile.duplicate(true)
	priced.skill="Hunting"
	priced.traits=["Cautious","Compassionate"]
	priced.specials=["Mercenary"]
	check(game.characters.wage_quote(priced).daily_cents==35,"Compassionate mercenary has a lower wage demand")
	priced.specials.append("Loyal")
	check(game.characters.wage_quote(priced).daily_cents==45,"Loyal adds ten cents per day")
	priced.specials.append("Veteran")
	check(game.characters.wage_quote(priced).daily_cents==65,"Veteran background adds its stated experience premium")
	priced.traits=["Bold","Pragmatic"]
	check(game.characters.wage_quote(priced).daily_cents==75,"Pragmatic paid-work preference commands a higher quote")
	priced.skill="Caregiving"
	check(game.characters.wage_quote(priced).daily_cents==85,"Background and special premiums combine")
	priced.specials.append("Cannibal")
	check(game.characters.wage_quote(priced).daily_cents==85,"Cannibal preference alone is not priced as a useful skill")
	var copy_of_profile: Dictionary=priced.duplicate(true)
	game.characters.wage_quote(priced)
	check(priced==copy_of_profile,"Quoting is pure and does not change a character")
	check(not game.characters.acceptable_terms(850,10,priced) and not game.characters.acceptable_terms(594,7,priced) and game.characters.acceptable_terms(595,7,priced),"Offer validation respects individual daily quote and weekly limit")
	var hiring=outfit()
	hiring.characters.profiles[1]=priced.duplicate(true)
	check(not hiring.characters.start_contract(hiring,1,84,1) and hiring.characters.start_contract(hiring,1,85,1),"Direct contract API cannot bypass character-specific minimum")
	var agreement: Dictionary=hiring.characters.profiles[1].contract.duplicate(true)
	hiring.characters.profiles[1].specials.erase("Veteran")
	check(hiring.characters.profiles[1].contract==agreement,"Later character changes do not rewrite an existing agreement")
	profile.specials=["Stoic"]
	game.characters.remember(game,profile,"defend",-1,"Ordinary disagreement.")
	check(profile.trust==49.5 and profile.memories.back().delta==-0.5,"Stoic preserves half-point hardship losses")
	rest(game)
	game.characters.remember(game,profile,"defend",-1,"Another disagreement.")
	check(profile.trust==49,"Repeated halves accumulate instead of rounding away")
	game.characters.remember(game,profile,"care",2,"Care.")
	check(profile.trust==51,"Stoic does not halve gains")
	# Loyal stays through worse instead of softening losses, and never betrays.
	var loyal: Dictionary=profile.duplicate(true)
	loyal.specials=["Loyal"]
	loyal.can_betray=true
	check(game.characters.breaking_point(loyal)==game.characters.breaking_point(profile)-10 and not game.characters.may_betray(loyal),"Loyal lowers the breaking point by ten and rules out betrayal")
	loyal.specials=[]
	check(game.characters.may_betray(loyal),"Without Loyal, a capable companion can still betray")
	var loyal_trust: float=profile.trust
	profile.specials=["Loyal"]
	game.characters.remember(game,profile,"rest_sick",-2,"A hard day.")
	check(profile.trust==loyal_trust-2,"Loyal takes ordinary losses in full")
	profile.trust=loyal_trust
	profile.specials=["Stoic"]
	game.characters.remember(game,profile,"wage_missed",-2,"Unpaid.")
	check(profile.trust==loyal_trust-2,"Stoic does not soften losses outside hardship")
	profile.trust=loyal_trust
	profile.boundaries={"approved":[],"disapproved":[],"forbidden":["robbery"]}
	profile.trust=90
	var before=store.capture(game)
	check(game.characters.response(1,"robbery")=="reluctant" and store.capture(game)==before,"High-trust forbidden-action preview is pure")
	game.characters.react_to_action(game,"robbery")
	check(profile.trust==78 and profile.memories.back().delta==-12,"Forbidden action bypasses mitigation even when reluctantly accepted")
	check(game.characters.response(1,"robbery")=="forbidden","Crossing the loyalty threshold changes later willingness")
	var snapshot=store.capture(game)
	var restored=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored!=null and store.capture(restored)==snapshot,"Boundary and special state round-trip")
	game=outfit()
	profile=game.characters.profiles[1]
	profile.specials=["Stoic"]
	game.characters.remember(game,profile,"defend",-1,"Half point.")
	snapshot=store.capture(game)
	restored=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored!=null and restored.characters.profiles[1].trust==49.5 and store.capture(restored)==snapshot,"Fractional trust and memory survive JSON without rounding")
	game=outfit()
	check(game.characters.set_relationship(game,1,"family") and game.characters.profiles[1].trust==70,"Family starts with higher trust")
	check(game.characters.set_relationship(game,2,"friend") and game.characters.profiles[2].trust==60,"Friends have intermediate starting trust")
	profile=game.characters.profiles[1]
	profile.trust=25
	check(game.characters.warning(1).is_empty(),"Family has a lower breaking threshold")
	profile.relationship="fellow_traveler"
	check(not game.characters.warning(1).is_empty(),"Unrelated companion reaches breaking point earlier")
	profile.trust=5
	check("betrayal" not in game.characters.warning(1),"Low trust alone does not grant betrayal capacity")
	profile.can_betray=true
	check("betrayal" in game.characters.warning(1),"Explicit capacity and low trust expose a betrayal warning without executing it")
	rest(game)
	check(not game.characters.set_relationship(game,2,"family"),"Relationships cannot be changed mid-journey to refill trust")
	game=outfit()
	profile=game.characters.profiles[1]
	profile.specials=["Cannibal"]
	profile.boundaries.forbidden=["cannibalism"]
	game.characters.profiles[2].boundaries.forbidden=["cannibalism"]
	game.characters.react_to_action(game,"cannibalism")
	check(profile.trust==50 and game.characters.profiles[2].trust==38,"Cannibal exception is personal and does not erase other companions' objections")
	game=outfit()
	profile=game.characters.profiles[1]
	profile.specials=["Mercenary","Loyal"]
	var cash: float=game.state.money
	check(game.characters.start_contract(game,1,500,2) and profile.contract.next_due_day==2 and game.state.money==cash,"Explicit agreement schedules debt without charging early")
	check(not game.characters.start_contract(game,1,100,1),"Existing agreement cannot be overwritten to erase debt")
	check(not game.characters.pay_wages(game,1),"No prepayment or gift-based trust farming")
	rest(game)
	check(profile.contract.arrears_cents==0 and profile.trust==50,"No wages accrue before agreed date")
	rest(game)
	check(profile.contract.arrears_cents==500 and profile.trust==50 and profile.contract.misses==0,"Due day gives an opportunity to pay before a penalty")
	check(game.characters.pay_wages(game,1,200) and profile.contract.arrears_cents==300 and game.state.money==cash-2 and profile.trust==50,"Partial payment reduces real debt without granting full-payment reward")
	rest(game)
	check(profile.contract.misses==1 and profile.trust==48 and profile.contract.arrears_cents==300,"Missed wages lose full trust even for Loyal and retain full debt")
	game.characters.advance_contracts(game)
	check(profile.contract.misses==1 and profile.trust==48,"Repeated daily checks do not duplicate a missed installment")
	check(game.characters.pay_wages(game,1) and profile.trust==49 and game.state.money==cash-5,"Paying arrears restores some trust and charges exact remaining cents")
	rest(game)
	check(profile.contract.arrears_cents==500,"Next scheduled wage still accrues after settling arrears")
	check(game.characters.pay_wages(game,1) and profile.trust==49 and profile.contract.reward_days==2,"Short-interval on-time pay accrues days toward a weekly trust gain")
	check(not game.characters.pay_wages(game,1) and profile.trust==49,"Paid bill cannot be rewarded twice")
	rest(game)
	rest(game)
	rest(game)
	check(profile.contract.misses==2 and profile.trust==45,"Repeated missed payment has a stronger penalty")
	profile.boundaries.forbidden.append("miss_wages")
	rest(game)
	rest(game)
	check(profile.contract.misses==3 and profile.trust==41,"Forbidden missed wage takes the full penalty")
	game.state.money=0
	var debt: int=profile.contract.arrears_cents
	check(not game.characters.pay_wages(game,1) and profile.contract.arrears_cents==debt,"Unaffordable payment cannot erase debt")
	snapshot=store.capture(game)
	restored=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored!=null and store.capture(restored)==snapshot,"Overdue wage schedule and fractional trust round-trip exactly")
	for field in profile.contract:
		var broken=snapshot.duplicate(true)
		broken.characters[1].contract[field]="invalid"
		check(store.restore(broken)==null,"Reject malformed wage field: "+field)
	var no_mercenary=snapshot.duplicate(true)
	no_mercenary.characters[1].specials=["Loyal"]
	check(store.restore(no_mercenary)==null,"Contract requires the Mercenary special")
	game.state.status="arrived"
	game.state.money=100
	check(game.characters.pay_wages(game,1),"Surviving mercenary can receive final wages after arrival")
	game=outfit()
	profile=game.characters.profiles[1]
	profile.specials=["Mercenary"]
	game.characters.start_contract(game,1,500,2)
	for day in range(4):rest(game)
	check(profile.contract.arrears_cents==1000 and game.characters.pay_wages(game,1) and profile.trust==49,"Settling old debt on a new bill's due day earns only the overdue reward")
	game=outfit()
	snapshot=store.capture(game)
	var legacy=snapshot.duplicate(true)
	legacy.erase("characters_version")
	legacy.erase("camp_tasks")
	legacy.erase("field_outings")
	for old_profile in legacy.characters:
		for key in game.characters.FRAMEWORK_FIELDS:old_profile.erase(key)
	legacy.characters[1].trust=48
	legacy.characters[1].memories=[{"day":0,"kind":"defend","delta":-2,"text":"An existing memory."}]
	restored=store.restore(JSON.parse_string(JSON.stringify(legacy)))
	check(restored!=null and restored.characters.profiles[1].trust==48 and restored.characters.profiles[1].memories==legacy.characters[1].memories and restored.characters.profiles[1].contract.is_empty(),"Legacy character records retain existing trust and memories without invented contracts")
	for field in game.characters.FRAMEWORK_FIELDS:
		var malformed=snapshot.duplicate(true)
		malformed.characters[1].erase(field)
		check(store.restore(malformed)==null,"Current records require framework field: "+field)
	for version in [0,6,"2",null]:
		var malformed=snapshot.duplicate(true)
		malformed.characters_version=version
		check(store.restore(malformed)==null,"Reject unknown or malformed character schema")
	var malformed=snapshot.duplicate(true)
	malformed.characters[1].trust=49.25
	check(store.restore(malformed)==null,"Reject unsupported fractional precision")
	malformed=snapshot.duplicate(true)
	malformed.characters[1].specials=["Loyal","Loyal"]
	check(store.restore(malformed)==null,"Reject duplicate specials")
	malformed=snapshot.duplicate(true)
	malformed.characters[1].thresholds.breaking=90
	check(store.restore(malformed)==null,"Reject inverted trust thresholds")
	malformed=snapshot.duplicate(true)
	malformed.characters[1].boundaries.approved=["murder"]
	check(store.restore(malformed)==null,"Reject contradictory action boundaries")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=outfit()
	profile=screen.game.characters.profiles[1]
	profile.specials=["Mercenary","Loyal"]
	screen.game.characters.start_contract(screen.game,1,500,2)
	screen.rest_days_input.text="10"
	screen._confirm_rest()
	check(screen.game.state.day==2 and profile.contract.arrears_cents==500 and "Wages are due" in screen.record_notice.dialog_text,"Multi-day camp rest stops at a wage due date")
	screen.record_notice.hide()
	screen.selected_member=1
	screen._show_party()
	check(screen.wages_button.visible and not screen.wages_button.disabled and "Loyal" in screen.member_details.text and "$5.00" in screen.member_details.text,"Party screen exposes specials, terms and real wage payment")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/party-framework.png")
	cash=screen.game.state.money
	screen.wages_button.pressed.emit()
	check(profile.contract.arrears_cents==0 and screen.game.state.money==cash-5 and profile.trust==50 and profile.contract.reward_days==2 and screen.wages_button.disabled,"Actual payment button settles wages exactly once")
	screen.party_window.hide()
	screen.game=outfit()
	profile=screen.game.characters.profiles[1]
	profile.specials=["Mercenary"]
	screen.game.characters.start_contract(screen.game,1,300,1)
	screen.traveling=true
	screen._advance_day()
	check(screen.game.state.day==1 and not screen.traveling and screen.record_notice.visible and screen.record_notice.title=="WAGES DUE","Automatic travel pauses with a due-date notice")
	screen.queue_free()
	await process_frame
	print("Party framework: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)



