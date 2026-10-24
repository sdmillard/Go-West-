extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
## Five riders, three pack mules: the packer's outfit from the design.
const PACKERS={"wagon":0,"oxen":0,"horses":5,"mules":3,"saddles":5,"pack_saddles":3,"saddlebags":5,"food":500,"clothing":5,"bullet_boxes":5,"medicine":2,"salt":5}
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func calm(game) -> void:
	for member in game.party_health.members:member.health=100
	game.state.health=100
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	game.seen.append("muddy_trail")
func packers(cart: Dictionary=PACKERS):
	var game=Simulation.new(57,"classic",true)
	check(game.depart("banker",["A","B","C","D","E"],5,cart),"Packer outfit departs: "+game.departure_error)
	calm(game)
	return game
func wagon_party(extra: Dictionary={}):
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={"oxen":6,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10}
	cart.merge(extra,true)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	calm(game)
	return game
func run():
	var store=Store.new()
	var setup=Simulation.new(57,"classic",true)
	var legacy: Dictionary={"oxen":6,"food":600}
	var listed: Dictionary={"wagon":1,"oxen":6,"food":600}
	check(setup.outfitter.quote("farmer",legacy).total_cents==setup.outfitter.quote("farmer",listed).total_cents,"A cart from before the wagon was listed still buys one")
	check(setup.outfitter.quote("farmer",{"wagon":0,"oxen":0,"food":100}).valid,"No wagon and no oxen is a valid walking outfit")
	check(not setup.outfitter.quote("farmer",{"wagon":1,"oxen":0,"food":100}).valid,"A wagon still needs an ox")
	check(not setup.outfitter.quote("farmer",{"wagon":0,"food":600}).valid,"Without animals, the outfit must fit five walkers' packs")
	var quote: Dictionary=setup.outfitter.quote("banker",PACKERS)
	check(quote.valid and quote.mounts.mode=="mounted" and quote.team_capacity_lb==800,"Five riders with bags and three pack mules carry 75 lb gear, 125 lb bags and 600 lb packs")
	check(setup.outfitter.quote("banker",{"wagon":0,"horses":3,"saddles":3,"food":100}).mounts.mode=="packing","Too few saddles means walking pace")
	var game=packers()
	check(game.state.vehicle=="foot" and game.state.horses==5 and game.state.mules==3 and game.state.saddles==5,"Packers leave Independence with their stock and tack and no wagon")
	check(game.provisions.capacity(game.state)==800 and game.mount_plan().mode=="mounted","Departed packers keep the outfit's carrying capacity")
	check(game.provisions.household_mass(game.state)==75,"Packers bring only personal gear")
	var plan: Dictionary=game.mount_plan()
	check(plan.saddled_horses==5 and plan.pack_mules==3 and plan.bags==5,"Horses go under the saddles and mules under the packs")
	# Same day, same everything: compare the planned distance for riding and walking.
	var riding: int=game.walking_distance()
	game.state.saddles=0
	var walking: int=game.walking_distance()
	game.state.saddles=5
	check(riding>walking*1.8,"Riding covers far more ground than walking (%d vs %d)" % [riding,walking])
	var wagon=wagon_party()
	var start: int=wagon.state.miles
	wagon.travel()
	var mounted=packers()
	mounted.travel()
	check(mounted.state.miles>wagon.state.miles-start,"A mounted party outpaces a loaded wagon on the same first day (%d vs %d)" % [mounted.state.miles,wagon.state.miles-start])
	check(mounted.state.horse_health<100,"Carrying riders and packs wears the animals")
	var worn: int=mounted.state.horse_health
	mounted.rest()
	check(mounted.state.horse_health>worn,"A rest day lets the animals recover")
	# Doubling up keeps riding pace at a steep cost in wear.
	var rules: Dictionary=game.provisions.data.mounts
	var three: Dictionary={"vehicle":"foot","party_size":5,"horses":3,"saddles":3,"double_up":true}
	var doubled: Dictionary=game.Mounts.plan(rules,three)
	check(doubled.mode=="doubled","Three saddled horses carry five when doubling up")
	three.double_up=false
	check(game.Mounts.plan(rules,three).mode=="packing","Without doubling, three saddles for five means walking")
	var full: Dictionary=game.Mounts.plan(rules,{"vehicle":"foot","party_size":5,"horses":5,"saddles":5})
	check(game.Mounts.wear(rules,doubled,"plains",0,0)==4*game.Mounts.wear(rules,full,"plains",0,0),"Doubling up wears the animals about four times as fast")
	check(game.Mounts.wear(rules,full,"sagebrush",1,0)>game.Mounts.wear(rules,full,"plains",1,0),"Dry sagebrush country is harder on horses")
	var pair=packers({"wagon":0,"horses":3,"saddles":3,"mules":1,"pack_saddles":1,"food":80,"clothing":5})
	check(pair.mount_plan().mode=="packing" and pair.set_double_up(true) and pair.mount_plan().mode=="doubled","The double-up order switches a short-saddled party to riding")
	var before: int=pair.Mounts.condition(pair.state)
	pair.travel()
	check(before-pair.state.horse_health>=4,"A doubled-up day costs the horses dearly")
	# A worn-out animal gives out under load.
	game=packers()
	game.state["horse_health"]=1
	game.travel()
	check(game.state.horses+game.state.mules==7 and game.state.horse_health==int(rules.breakdown_condition),"An animal ridden to nothing gives out and is left behind")
	check(game.journal.any(func(line):return "gave out" in line),"The journal records the lost animal")
	# Horses led behind a wagon neither wear nor change the wagon.
	wagon=wagon_party({"horses":2,"saddles":2})
	var wagon_speed: int=wagon.provisions.capacity(wagon.state)
	wagon.travel()
	check(wagon.Mounts.condition(wagon.state)==100 and wagon.mount_plan().mode=="wagon" and wagon.provisions.capacity(wagon.state)==wagon_speed,"Horses led behind a wagon add no capacity and no wear")
	# Leaving the wagon puts the animals to work.
	var offer: Dictionary=wagon.pack_quote({"food":80,"clothing":5,"bullets":20})
	check(offer.valid and offer.capacity_lb==200 and "walk" in offer.message,"Two saddle horses for five people: the party walks and bagless horses add nothing")
	wagon=wagon_party({"horses":5,"saddles":5,"saddlebags":5,"mules":2,"pack_saddles":2})
	offer=wagon.pack_quote({"food":400,"clothing":5,"bullets":20})
	check(offer.valid and offer.capacity_lb==75+125+400 and "ride" in offer.message,"Abandoning the wagon with horses and tack quotes the mounted carry limit")
	check(wagon.abandon_wagon({"food":400,"clothing":5,"bullets":20}) and wagon.state.vehicle=="foot" and wagon.state.horses==5 and wagon.mount_plan().mode=="mounted","The party rides on from the abandoned wagon")
	# Saves keep the animals, and records from before horses load with none.
	game=packers()
	game.travel()
	var snapshot: Dictionary=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null and copy.state.horses==5 and copy.state.mules==3 and copy.state.horse_health==game.state.horse_health and not copy.state.has("double_up"),"Saved packers load with their animals and condition")
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-horses-save-v1.json"))
	var upgraded=store.restore(old)
	check(upgraded!=null and upgraded.state==store.normalize(old.state) and upgraded.Mounts.animals(upgraded.state)==0 and str(upgraded.rng.state)==old.random,"A real save from before horses loads unchanged with no animals")
	snapshot.state.horse_health=101
	check(store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null,"Out-of-range horse condition is rejected")
	# The travel screen shows riders and pack animals.
	var main=Main.instantiate()
	root.add_child(main)
	await process_frame
	main.game=packers()
	main._refresh()
	await process_frame
	check(main.landscape.mount_rows().size()==8 and main.landscape.mount_rows().count(main.landscape.MOUNT_PACK_MULE)==3,"The travel view draws five riders and three pack mules")
	check("MOUNTED" in main.stats.text and "HORSES 5 MULES 3" in main.stats.text,"The ledger shows the mounted party and its animals")
	main.queue_free()
	print("Mounts: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
