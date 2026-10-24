extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+text)
func calm(game) -> void:
	game.survival.forced_weather="clear"
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	for member in game.party_health.members:member.health=100
	game.state.health=100
func party(cart: Dictionary,seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	check(game.depart("banker",["Lead","A","B","C","D"],5,cart),"Party departs: "+game.departure_error)
	calm(game)
	return game
func wagon_with_horses(seed_value: int=57,horses: int=3):
	return party({"oxen":4,"horses":horses,"saddles":horses,"saddlebags":horses,"food":500,"clothing":5,"bullet_boxes":10,"wheels":1,"medicine":2,"salt":10},seed_value)
## At Fort Bridger's store with a quiet theft that was noticed, so the party has to run.
func noticed_theft(horses: int=3):
	for seed_value in range(1,80):
		var game=wagon_with_horses(seed_value,horses)
		game.route_path=game.route.main_path_to("fort_bridger")
		game.state.landmark="fort_bridger"
		game.state.next_landmark="fort_bridger"
		game.state.miles=int(game.route.node_miles()["fort_bridger"])
		game.state.leg_miles=0
		game.state.leg_length=0
		game.pending={}
		game._arrive_landmark(true,false)
		game.open_crime("fort_bridger")
		if game.steal({"bullets":5}) and game.crime.incident().attempt=="noticed":return game
	return null
func run():
	var store=Store.new()
	var Wanted=Simulation.new(1,"classic",true).crime.Wanted
	# Riders get a bonus to their escape odds, never a certainty.
	var riders=party({"wagon":0,"oxen":0,"horses":5,"saddles":5,"saddlebags":5,"food":40,"clothing":2})
	var walkers=party({"wagon":0,"oxen":0,"food":40,"clothing":2})
	var wagon=party({"oxen":4,"food":500,"clothing":5})
	var scene: Dictionary={"escape_capture":0.5}
	var on_horse: float=Wanted.flight_chance(riders.crime,riders,scene)
	check(on_horse>Wanted.flight_chance(wagon.crime,wagon,scene)+0.14 and on_horse>Wanted.flight_chance(walkers.crime,walkers,scene)+0.2,"Riders escape more often than a wagon or walkers (%.2f)" % on_horse)
	check(Wanted.flight_chance(riders.crime,riders,{"escape_capture":0.0})==0.85,"Even riders can be caught: the escape cap stays")
	riders.state["horse_health"]=20
	check(Wanted.flight_chance(riders.crime,riders,scene)<on_horse,"Worn-out horses help less")
	var short=party({"wagon":0,"oxen":0,"horses":3,"saddles":3,"saddlebags":3,"food":30,"clothing":2})
	check(Wanted.flight_plan(short).mode=="doubled" and Wanted.flight_bonus(short.crime,short)>0,"Running doubled up counts as riding")
	var before: int=short.Mounts.condition(short.state)
	Wanted.ride_hard(short)
	check(before-short.state.horse_health>=8 and short.state.double_up,"A doubled-up dash wears the horses hard and sets the party doubling")
	# A wagon party with enough horses for everyone, two to a saddle, can cut loose.
	check(Wanted.can_ride_off(wagon_with_horses()) and not Wanted.can_ride_off(wagon_with_horses(57,2)) and not Wanted.can_ride_off(riders),"Cutting loose needs a wagon and horses enough for everyone doubled up")
	var game=wagon_with_horses()
	var day: int=game.state.day
	var held: Dictionary={"food":game.state.food,"bullets":game.state.bullets,"clothing":game.state.clothing}
	check(Wanted.cut_loose(game.crime,game),"The party cuts loose from the wagon")
	check(game.state.vehicle=="foot" and game.state.horses==3 and game.state.double_up and game.mount_plan().mode=="doubled","They ride off doubled up on their horses")
	check(game.provisions.cargo(game.state)<=game.provisions.capacity(game.state) and not game.wagon_cache.is_empty() and game.state.day==day,"What they grabbed fits; the rest waits in the abandoned wagon; no extra day passes")
	check(game.state.wheels==0 and game.wagon_cache.inventory.wheels==1,"Spare wagon parts stay with the wagon")
	check(game.state.food<held.food and game.journal.any(func(line):return "Grabbed in a hurry" in line),"Nobody planned this: most of the food stays behind, and the journal says what was grabbed")
	var again=wagon_with_horses()
	Wanted.cut_loose(again.crime,again)
	check(again.state.food==game.state.food and again.state.bullets==game.state.bullets,"The same journey scrambles the same way")
	var copy=store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	check(copy!=null and copy.state.vehicle=="foot" and copy.wagon_cache.inventory.food==game.wagon_cache.inventory.food,"The getaway saves")
	# At a crime scene, a noticed party can ride for it.
	var thief=noticed_theft()
	check(thief!=null,"A seeded theft is noticed")
	if thief!=null:
		var labels: Array=thief.pending.choices.map(func(choice):return str(choice.get("crime_command","")))
		check("ride" in labels,"A noticed wagon party with horses can cut loose and ride")
		check(store.restore(JSON.parse_string(JSON.stringify(store.capture(thief))))!=null,"A save with the ride choice loads")
		check(thief.choose(labels.find("ride")) and thief.state.vehicle=="foot" and thief.crime.incident().resolution in ["escaped","captured"],"Riding off ends the escape one way or the other")
		check(store.restore(JSON.parse_string(JSON.stringify(store.capture(thief))))!=null,"The game saves after riding off")
	var no_horses=noticed_theft(0)
	if no_horses!=null:check(not no_horses.pending.choices.any(func(choice):return choice.get("crime_command","")=="ride"),"Without horses there is no riding off")
	# A save from before horse flight loads.
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-horse-flight-save-v1.json"))
	var upgraded=store.restore(old)
	check(upgraded!=null and upgraded.state==store.normalize(old.state),"A save from before horse flight loads")
	print("Horse flight: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
