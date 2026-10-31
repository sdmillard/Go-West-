extends SceneTree
## The leader is the player: their death ends the journey. Older journeys where a companion already took over keep going.
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit():
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	return game
func run() -> void:
	var game=outfit()
	game.party_health.kill(game.party_health.members[1],int(game.state.day),"cholera")
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	game._check_health()
	check(game.state.status=="traveling","A companion's death does not end the journey")
	game.party_health.kill(game.party_health.members[0],int(game.state.day),"cholera")
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	game._check_health()
	check(game.state.status=="lost" and game.state.loss_reason=="A, the party's leader, died of cholera. The journey is over.","The leader's death ends the journey even with companions alive")
	check(not game.travel() and not game.rest(),"Nobody travels on after the leader dies")
	var store=Store.new()
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"A journey ended by the leader's death saves and loads")
	# A journey saved under the older rule, with a companion already leading.
	game=outfit()
	game.state.leader_succession=true
	game.party_health.kill(game.party_health.members[0],int(game.state.day),"cholera")
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	var snapshot: Dictionary=store.capture(game)
	snapshot.state.erase("leader_succession")
	var legacy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(legacy!=null and legacy.state.status=="traveling" and legacy.state.get("leader_succession",false),"An older journey led by a companion keeps going")
	if legacy!=null:
		legacy.party_health.daily_onset_chance=0
		legacy.survival.forced_weather="clear"
		legacy.survival.data.event_chance=0
		check(legacy.rest() and legacy.state.status=="traveling","It goes on after the next day")
		var copy: Dictionary=store.capture(legacy)
		check(store.restore(JSON.parse_string(JSON.stringify(copy)))!=null,"The older rule survives another save")
	snapshot=store.capture(outfit())
	snapshot.state.leader_succession=true
	check(store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null,"A save cannot claim a successor while the leader lives")
	# The leader builds their character like a companion: specials and a flaw, but nothing about trust or wages.
	var fresh=Simulation.new(57,"classic",true)
	var sheet=preload("res://simulation/party_character.gd").new()
	sheet.start(57,5)
	var setup: Dictionary={"profiles":sheet.profiles.duplicate(true),"contracts":{}}
	check(fresh.characters.valid_setup(setup),"An unedited party is a valid setup")
	setup.profiles[0].specials=["Hardy","Quick Healer","Weatherwise"]
	setup.profiles[0].flaws=["Frail"]
	check(fresh.characters.valid_setup(setup),"The leader can take specials paid for with a flaw")
	setup.profiles[0].specials=["Hardy","Quick Healer","Weatherwise"]
	setup.profiles[0].erase("flaws")
	check(not fresh.characters.valid_setup(setup),"The leader has the same special limit as companions")
	for special in ["Mercenary","Loyal","Stoic","Cannibal","Field Medic","Veteran"]:
		setup.profiles[0].specials=[special]
		check(not fresh.characters.valid_setup(setup),"The leader cannot take the companion-only special "+special)
	setup.profiles[0].specials=["Hardy","Iron Stomach","Tireless"]
	setup.profiles[0].flaws=["Restless"]
	check(not fresh.characters.valid_setup(setup),"A trust flaw cannot buy the leader a free special")
	setup.profiles[0].flaws=["Sickly"]
	var cart: Dictionary={}
	for good in fresh.outfitter.goods:cart[good.id]=int(good.suggested)
	check(fresh.depart("banker",["A","B","C","D","E"],5,cart,setup) and "Hardy" in fresh.characters.profiles[0].specials and fresh.characters.profiles[0].flaws==["Sickly"],"The leader's chosen specials and flaw start the journey")
	var hurt: int=fresh.characters.catalog.health_delta(fresh.characters.profiles[0],-10,"exhaustion",fresh.party_health.conditions)
	check(hurt==-8,"Hardy protects the leader like anyone else")
	var screen=load("res://ui/main.gd").new()
	root.add_child(screen)
	await process_frame
	var view=screen.departure_view
	view.open_editor(0)
	check(not view.personality.visible and not view.relationship.visible and not view.wage.visible and not view.special_checks.Mercenary.visible and view.special_checks.Hardy.visible,"The leader's sheet shows only specials, a flaw and appearance")
	view.flaw_choice.select(view.draft.FLAWS.keys().find("Frail")+1)
	view._flaw_selected(view.draft.FLAWS.keys().find("Frail")+1)
	view.special_checks.Hardy.button_pressed=true
	view.close_editor()
	var made: Dictionary=view.customization()
	check("Hardy" in made.profiles[0].specials and made.profiles[0].flaws==["Frail"] and fresh.characters.valid_setup(made),"Leader choices reach the journey setup")
	view.open_editor(1)
	check(view.personality.visible and view.special_checks.Mercenary.visible,"Companion sheets keep every field")
	screen.queue_free()
	await process_frame
	print("Leader death: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
