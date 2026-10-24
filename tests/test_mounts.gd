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
	var walking_cart: Dictionary={"wagon":0,"oxen":0,"food":95}
	var walking_quote: Dictionary=setup.outfitter.quote("farmer",walking_cart)
	check(walking_quote.valid and walking_quote.team_capacity_lb==170,"Walking outfit uses the starting party health, not full health")
	check(setup.depart("farmer",["A","B","C","D","E"],5,walking_cart) and setup.provisions.capacity(setup.state)==walking_quote.team_capacity_lb and setup.provisions.cargo(setup.state)==walking_quote.cargo_lb,"A boundary walking quote matches actual departure load and capacity")
	check(not setup.outfitter.quote("farmer",{"wagon":0,"food":96}).valid and not setup.outfitter.quote("farmer",{"wagon":0,"food":100}).valid,"Walking outfits above the real 170 lb limit are rejected")
	var packing_cart: Dictionary={"wagon":0,"horses":1,"mules":2,"pack_saddles":1,"food":295}
	check(setup.outfitter.quote("farmer",packing_cart).valid,"A working mule adds 200 lb to the starting walkers")
	packing_cart.food=296
	check(not setup.outfitter.quote("farmer",packing_cart).valid,"Packing quotes use starting health too")
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
	check(riding>walking*1.3,"Riding still covers more ground than a properly paced pack train (%d vs %d)" % [riding,walking])
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
	var working_mule=packers({"wagon":0,"horses":1,"mules":2,"pack_saddles":1,"food":80})
	var capacity_before: float=working_mule.provisions.capacity(working_mule.state)
	working_mule.Mounts.breakdown(working_mule)
	check(working_mule.state.horses==1 and working_mule.state.mules==1 and working_mule.provisions.capacity(working_mule.state)==capacity_before,"A working mule gives out before an unused led horse; another mule can take its pack")
	check("mule" in working_mule.journal.back() and working_mule.supply_history.back().changes=={"mules":-1},"Breakdown records the species actually lost")
	working_mule.Mounts.breakdown(working_mule)
	check(working_mule.state.mules==0 and working_mule.state.horses==1 and working_mule.provisions.capacity(working_mule.state)==capacity_before-25,"After both mules give out, the remaining horse takes the smaller pack load")
	var led=packers({"wagon":0,"horses":1,"food":80})
	var led_before: Dictionary=led.state.duplicate(true)
	led.Mounts.breakdown(led)
	check(led.state==led_before,"Led-only animals do not give out under a nonexistent load")
	var empty=packers({"wagon":0,"food":80})
	empty.Mounts.breakdown(empty)
	check(not empty.state.has("mules") and not empty.state.has("horses"),"An empty train never creates negative stock")
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
	var balanced: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-horse-balance-save-v1.json"))
	var rebalanced=store.restore(balanced)
	check(rebalanced!=null and rebalanced.state==store.normalize(balanced.state),"A mounted save from before the horse balance pass loads")
	# Balance pass: mules shrug off poor forage, and animals carry a fair load without slowing.
	var mount_rules: Dictionary=game.provisions.data.mounts
	check(game.Mounts.wear(mount_rules,{"mode":"packing","saddled_horses":0,"pack_horses":0},"sagebrush",0,0,1.0)==1 and game.Mounts.wear(mount_rules,{"mode":"packing","saddled_horses":0,"pack_horses":2},"sagebrush",0,0,1.0)==1+int(mount_rules.forage_strain.sagebrush),"An all-mule string takes no forage strain; horses do")
	var train=packers({"wagon":0,"oxen":0,"mules":4,"pack_saddles":4,"food":20,"clothing":5})
	train.survival.weather={"id":"clear","label":"Clear","speed":1.0}
	train.state.fatigue=0
	var light: int=train.walking_distance()
	train.state.food=int((train.provisions.capacity(train.state)*0.7-train.provisions.cargo(train.state))/float(train.provisions.data.weights_lb.food))+20
	check(train.provisions.cargo(train.state)/train.provisions.capacity(train.state)>0.6 and train.walking_distance()==light,"A pack train carrying two-thirds of its limit keeps its pace")
	snapshot.state.horse_health=101
	check(store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null,"Out-of-range horse condition is rejected")
	# No wagon, no wagon troubles: encounters speak of the party and strain the horses.
	game=packers()
	check("muddy_trail" in game.seen,"Packers never meet the cracked-wheel muddy trail")
	var bandits: Dictionary={}
	for event in game.trail_events.events:
		if event.id=="bandits":bandits=event.duplicate(true)
	game.adapt_travel_event(bandits)
	var words: String=JSON.stringify(bandits).to_lower()
	check(not "wagon" in words and not "ox_health" in words,"Bandit choices for packers mention no wagon or team")
	var flee: Dictionary=bandits.choices.filter(func(choice):return choice.label.begins_with("Flee"))[0]
	check(flee.effects.get("horse_health",0)==-15 and "horses strained" in flee.label,"Fleeing strains the horses instead of a team")
	game.state["horse_health"]=90
	game._apply(flee.effects)
	check(game.state.horse_health<=76 and game.state.ox_health==100,"Horse strain lands on the horses; the lost day is a camp day")
	var walkers=packers({"wagon":0,"food":65,"clothing":5})
	var riders: Dictionary={}
	for event in walkers.trail_events.events:
		if event.id=="riders":riders=event.duplicate(true)
	walkers.adapt_travel_event(riders)
	check(not "ox_health" in JSON.stringify(riders) and not "strain" in JSON.stringify(riders),"Walkers with no animals have no team to strain")
	walkers.survival.data.event_chance=1.0
	var seen_hail:=false
	for i in range(200):
		walkers.pending={}
		walkers._roll_trail_event()
		if walkers.pending.get("id","") in ["hail_damage","breakdown","wagon_fire","swamped_load","ox_injury","wandering_ox","stampede"]:seen_hail=true
	check(not seen_hail,"No wagon or oxen events reach a party without them")
	# Stock ford a low river and swim a high one: one choice, set by the water.
	for stage in ["low","high"]:
		game=packers()
		game.state.next_landmark="big_blue"
		game.state.river_stage=stage
		game._arrive_landmark(false,false)
		var methods: Array=game.pending.choices.map(func(choice):return choice.get("method",""))
		var horse: Dictionary=game.pending.choices.filter(func(choice):return choice.get("method","")=="horses")[0] if "horses" in methods else {}
		check(methods.count("horses")==1 and not "swim" in methods and not "ford" in methods,"Packers at a river get one horse crossing choice: "+stage)
		check(horse.get("label","").begins_with("Ford with the horses" if stage=="low" else "Swim the horses across"),"The horse crossing fords low water and swims high water: "+stage)
		check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"A save at the river with the horse choice loads: "+stage)
		var index: int=methods.find("horses")
		game.pending.choices[index].risk=100.0
		var stock: int=game.Mounts.animals(game.state)
		check(game.choose(index),"Packers cross with their horses: "+stage)
		check(game.last_crossing.mishap and game.Mounts.animals(game.state)==stock-(1 if stage=="high" else 0),"Only high water can drown an animal in a mishap: "+stage)
		check(("drowned" in game.last_crossing.summary)==(stage=="high"),"The crossing record names a drowned animal: "+stage)
	game=packers()
	game.state.next_landmark="big_blue"
	game.state.river_stage="low"
	game._arrive_landmark(false,false)
	game.survival.wet_ground=4
	game._update_river_stage()
	check(game.pending.choices.any(func(choice):return choice.get("label","").begins_with("Swim the horses")),"Rising water turns the horse ford into a swim")
	walkers=packers({"wagon":0,"food":65,"clothing":5})
	walkers.state.next_landmark="big_blue"
	walkers._arrive_landmark()
	check(walkers.pending.choices.any(func(choice):return choice.get("method","")=="swim") and not walkers.pending.choices.any(func(choice):return choice.get("method","")=="horses"),"Walkers without animals still swim with their packs")
	# The travel screen shows riders and pack animals.
	var main=Main.instantiate()
	root.add_child(main)
	await process_frame
	main.game=packers()
	main._refresh()
	await process_frame
	check(main.landscape.mount_rows().size()==8 and main.landscape.mount_rows().count(main.landscape.MOUNT_PACK_MULE)==3,"The travel view draws five riders and three pack mules")
	check(main.landscape.party_layout(Vector2(150,132)).on_foot==0,"Mounted parties draw no extra walkers")
	main.landscape.mount_plan=game.Mounts.plan(rules,{"vehicle":"foot","party_size":5,"mules":8,"pack_saddles":8})
	for origin in [Vector2(140,135),Vector2(147,131),Vector2(153,132)]:
		var layout: Dictionary=main.landscape.party_layout(origin)
		var people: Rect2=Rect2(layout.walkers-Vector2(5,26),Vector2(92,27))
		var visible: bool=Rect2(0,0,432,150).encloses(people)
		for animal in layout.animals:
			var bounds: Rect2=Rect2(animal-Vector2(0,39),Vector2(48,44))
			visible=visible and Rect2(0,0,432,150).encloses(bounds) and not bounds.intersects(people)
		check(visible and layout.animals.size()==8 and layout.on_foot==5,"All five walkers remain visible and clear of eight animals, moving or stopped")
	main.landscape.walkers=1
	main.landscape.mount_plan=game.Mounts.plan(rules,{"vehicle":"foot","party_size":1,"mules":1,"pack_saddles":1})
	var solo: Dictionary=main.landscape.party_layout(Vector2(140,135))
	check(solo.on_foot==1 and solo.animals.size()==1 and solo.walkers.x+11<solo.animals[0].x,"A lone walker stays separate from a single pack animal")
	main.landscape.mount_plan=game.Mounts.plan(rules,{"vehicle":"foot","party_size":5,"horses":3,"saddles":3,"double_up":true})
	check(main.landscape.party_layout(Vector2(150,132)).on_foot==0,"Doubled riders do not also appear on foot")
	main.landscape.walkers=5
	main.landscape.mount_plan=main.game.mount_plan()
	check("MOUNTED" in main.stats.text and "HORSES 5 MULES 3" in main.stats.text,"The ledger shows the mounted party and its animals")
	main.landscape.start_crossing({"method":"horses","stage":"high","place":"Big Blue River","mishap":false})
	main.landscape.crossing_elapsed=main.landscape.crossing_duration*0.5
	await process_frame
	check(main.landscape._riding() and not main.landscape.crossing.is_empty(),"The horse crossing plays with the riders on their horses")
	main.queue_free()
	print("Mounts: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
