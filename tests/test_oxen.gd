extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	# A carpenter rather than a farmer: the farmer's Stockman skill changes butchering yields (tests/test_profession_skills.gd).
	game.depart("carpenter",["A","B","C","D","E"],5,{"oxen":6,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"salt":10})
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	game.seen.append("muddy_trail")
	return game
func run():
	var game=outfit()
	for count in range(7):
		var expected: float=[0.0,0.25,0.5,0.75,1.0,1.05,1.1][count]
		check(is_equal_approx(game.survival.movement_factor(count,100,0,0),expected),"Healthy clear-weather team factor for %d oxen" % count)
	check(game.survival.team_factor(20)==game.survival.team_factor(6),"More than six animals grant no further speed bonus")
	var daily_miles: Array=[]
	for count in [4,5,6,12]:
		var team_game=outfit()
		team_game.state.oxen=count
		team_game.travel()
		daily_miles.append(team_game.state.miles)
	check(daily_miles[0]<daily_miles[1] and daily_miles[1]<daily_miles[2] and daily_miles[2]==daily_miles[3],"Five and six oxen improve actual daily movement with the same load; reserves cap at six")
	var old_save: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-team-bonus-save-v1.json"))
	var old_store=Store.new()
	var upgraded=old_store.restore(old_save)
	check(upgraded!=null and upgraded.state==old_store.upgraded_state(old_save.state) and str(upgraded.rng.state)==old_save.random,"Real pre-bonus save retains animals, cargo, money, time and random state")
	check(upgraded!=null and is_equal_approx(upgraded.survival.team_factor(6),1.1),"Existing six-ox team gains the updated future movement rule")
	var other=outfit()
	other.state.oxen=12
	game.rest()
	other.rest()
	check(game.state.food==585 and other.state.food==585,"Extra oxen do not consume human meal supplies")
	game=outfit()
	game.open_trade()
	var cash: float=game.state.money
	game.choose(8)
	check(game.state.oxen==7 and is_equal_approx(game.state.money,cash-51.3) and game.state.day==1,"Trading companion discounts the passing traders' marked-up ox; the visit's day and ordinary meals pass")
	game=outfit()
	check(game.ox_slaughter_offer().meat==400 and game.ox_slaughter_offer().remaining==5,"Healthy spare ox offers four hundred usable pounds")
	check(game.slaughter_ox() and game.state.oxen==5 and game.state.bullets==199 and game.state.food==785 and game.state.day==1,"One animal costs exactly one bullet and one day; all meat credited before fifteen-pound meal")
	check(game.provisions.fresh_pounds(game.state.food)==185,"At-camp meat is fresh and bypasses hunting's one hundred pound cap")
	check(game.supply_history[0].event=="slaughter_ox" and game.supply_history[0].changes.food==200,"Journal ledger separates full yield from ordinary meals")
	check(game.preserve_meat(true) and game.provisions.preserved_pounds(game.state.food)==50,"Ox meat enters the existing salt-preservation model")
	var store=Store.new()
	var snapshot:=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null and store.capture(copy)==snapshot,"Animal loss, ammunition, meat batches and dated history survive loading")
	game=outfit()
	game.state.food=1800
	game.slaughter_ox()
	check(game.state.food==1985 and game.provisions.cargo(game.state)>2500,"Camp slaughter recovers all meat even if wagon becomes overloaded")
	game=outfit()
	game.state.food=0
	game.slaughter_ox()
	check(game.state.food==185 and game.state.party_size==5,"Same-day slaughter can feed a currently empty camp")
	game=outfit()
	game.state.ox_health=50
	check(game.ox_slaughter_offer().meat==300,"Worn team condition lowers the coarse usable-yield estimate")
	game=outfit()
	game.state.oxen=3
	game.slaughter_ox()
	check(game.state.oxen==2 and not game.ox_slaughter_offer().is_empty(),"Two-ox emergency camp can choose to sacrifice another animal")
	game.slaughter_ox()
	check(game.state.oxen==1 and not game.ox_slaughter_offer(true).is_empty(),"One ox remains available for the desperate final choice")
	game.slaughter_ox()
	check(game.state.oxen==0 and game.ox_slaughter_offer().is_empty() and game.ox_slaughter_offer(true).is_empty(),"Last ox may be slaughtered; empty herd cannot yield extra meat")
	var stranded_day: int=game.state.day
	game.pending.clear()
	game.travel()
	check(game.state.miles==0 and game.state.day==stranded_day and game.pending.id=="no_team","No animals blocks wagon travel without spending another day")
	game.choose(0)
	check(not game.preservation_offer().is_empty() and game.preserve_meat(),"Stranded party can preserve the camp meat")
	game.pending.clear()
	game.open_trade()
	while game.pending.title=="No traders nearby":
		game.choose(0)
		game.open_trade()
	game.choose(18)
	check(game.state.oxen==1,"Stranded party can barter meat for one replacement ox")
	game.pending.clear()
	var start_miles: int=game.state.miles
	game.travel()
	check(game.state.miles>start_miles,"One replacement ox restores actual forward travel")
	game=outfit()
	var full_team=outfit()
	game.state.oxen=1
	game.travel()
	full_team.travel()
	check(game.state.miles>0 and game.state.miles<full_team.state.miles/2,"One ox can pull the wagon but heavy cargo makes it very slow")
	check(game.provisions.team_capacity(1)==625 and game.provisions.team_capacity(2)==1250 and game.provisions.team_capacity(3)==1875 and game.provisions.team_capacity(6)==2500,"Working-load guidance scales below four animals and caps at wagon guideline")
	check(game.provisions.movement_factor(1200,1)<game.provisions.movement_factor(600,1),"Lightening a small team's load improves its actual load multiplier")
	check(game.outfitter.quote("farmer",{"oxen":1,"food":600}).valid,"A one-ox departure is allowed with an overload warning")
	game=outfit()
	game.state.bullets=0
	snapshot=store.capture(game)
	check(not game.slaughter_ox() and store.capture(game)==snapshot,"Shooting without ammunition spends nothing")
	game.provisions.data.ox_slaughter.hand_injury_chance=0
	check(game.slaughter_ox(true) and game.state.bullets==0 and game.state.oxen==5,"Hand tools work without ammunition")
	check(game.party_health.members.all(func(member):return member.conditions.is_empty()),"Zero-risk controlled scenario has no hand-tool wound")
	game=outfit()
	game.provisions.data.ox_slaughter.hand_injury_chance=1
	game.slaughter_ox(true)
	check(game.party_health.members.filter(func(member):return member.conditions.any(func(c):return c.id=="wound")).size()==1,"Forced hand-tool accident wounds one living traveler")
	var injured:=0
	for seed_value in range(40):
		game=outfit(seed_value)
		game.slaughter_ox(true)
		if game.party_health.members.any(func(member):return not member.conditions.is_empty()):injured+=1
	check(injured>0 and injured<40,"Authored hand-tool risk allows both injury and uninjured outcomes")
	game=outfit()
	game.pending={"id":"test","title":"Stop","text":"Resolve","choices":[{"label":"Continue","effects":{},"result":"Continue"}]}
	snapshot=store.capture(game)
	check(not game.slaughter_ox(true) and store.capture(game)==snapshot,"Unresolved events block slaughter without changing state")
	game=outfit()
	game.state.next_landmark="fort_hall"
	game._arrive_landmark()
	check(game.slaughter_ox() and game.pending.landmark=="fort_hall","Camp work preserves its unresolved landmark")
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-slaughter-save-v1.json"))
	game=store.restore(previous)
	check(game!=null and game.state==store.upgraded_state(previous.state) and game.provisions.fresh==store.normalize(previous.fresh),"Actual previous-version preserved save migrates without changing supplies or batches")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=outfit()
	screen._refresh()
	screen._show_supplies()
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ox-supplies.png")
	snapshot=store.capture(screen.game)
	screen._confirm_slaughter()
	check(screen.slaughter_confirmation.visible and store.capture(screen.game)==snapshot,"Opening review does not kill an animal or advance time")
	screen.slaughter_confirmation.get_cancel_button().pressed.emit()
	screen.slaughter_confirmation.hide()
	check(store.capture(screen.game)==snapshot,"Cancelling preserves the party and inventory")
	await process_frame
	screen._confirm_slaughter()
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/ox-slaughter.png")
	screen.slaughter_confirmation.confirmed.emit()
	screen.slaughter_confirmation.hide()
	check(screen.game.state.oxen==5 and screen.game.state.bullets==199,"Confirmed shooting consumes one ox and exactly one bullet through actual UI")
	screen.queue_free()
	await process_frame
	print("Oxen: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)


