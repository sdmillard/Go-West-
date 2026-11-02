extends SceneTree
## Unhinged mode (Spencer, November 1 2026): each seed deals its own assortment of impossible
## things. Places stand at a mile on one stretch and show on the map; road encounters wait at a
## guide mile. Classic deals nothing. Same seed, same oddities.
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func started(seed_value: int,mode: String="unhinged"):
	var game=Simulation.new(seed_value,mode,true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	return game
func event(game,id: String) -> Dictionary:
	for e in game.catalog.events:
		if e.id==id:return e
	return {}
## Leave a stop or cross its river; otherwise take the last (plainest) choice.
func pick(g) -> int:
	for action in ["leave","cross"]:
		for i in range(g.pending.choices.size()):
			if g.pending.choices[i].get("action","")==action and g.can_choose(i):return i
	for i in range(g.pending.choices.size()-1,-1,-1):
		if g.can_choose(i):return i
	return 0
func run():
	var classic=Simulation.new(7,"classic",true)
	check(classic.oddities.places.is_empty() and classic.oddities.road.is_empty(),"Classic deals no oddities")
	# Determinism, and every seed's deal is legal.
	var a=Simulation.new(4242,"unhinged",true)
	var b=Simulation.new(4242,"unhinged",true)
	check(a.oddities.places==b.oddities.places and a.oddities.road==b.oddities.road,"Same seed deals the same oddities")
	var counts: Array=[]
	var seen_ids: Dictionary={}
	var empty:=0
	for seed_value in range(400):
		var g=Simulation.new(seed_value,"unhinged",true)
		var n: int=g.oddities.places.size()+g.oddities.road.size()
		counts.append(n)
		if n==0:empty+=1
		for place in g.oddities.places:
			seen_ids[place.id]=true
			var edge: Dictionary=g.route.edge_between(place.from,place.to)
			check(not edge.is_empty() and int(place.at)>=1 and int(place.at)<int(edge.miles),"Seed %d: %s stands inside its stretch" % [seed_value,place.id])
			var allowed: Array=g.oddities.stretches_for(event(g,place.id),g.route).map(func(s):return s.from+">"+s.to)
			check(place.from+">"+place.to in allowed,"Seed %d: %s is on a stretch it may use" % [seed_value,place.id])
		for entry in g.oddities.road:
			seen_ids[entry.id]=true
			var window: Array=event(g,entry.id).get("miles",[50,1800])
			check(int(entry.mile)>=int(window[0]) and int(entry.mile)<=int(window[1]),"Seed %d: %s waits inside its miles" % [seed_value,entry.id])
	var total:=0
	for n in counts:total+=n
	for e in a.catalog.events:
		if e.category=="absurd":check(seen_ids.has(e.id),"Some seed deals "+e.id)
	check(empty<40,"Few seeds deal nothing at all (%d of 400)" % empty)
	print("Oddities per seed: mean %.2f, none %d of 400" % [float(total)/400.0,empty])
	# A dealt place stops the wagon at its mile, before the stop ahead, once.
	var seed_value:=0
	var g=null
	for s in range(2000):
		var probe=Simulation.new(s,"unhinged",true)
		if probe.oddities.places.any(func(p):return p.id=="taco_hut"):seed_value=s;break
	g=started(seed_value)
	var hut: Dictionary=g.oddities.places.filter(func(p):return p.id=="taco_hut")[0]
	var met:=false
	for step in range(400):
		if g.state.status!="traveling":break
		if not g.pending.is_empty():
			if g.pending.id=="taco_hut":
				met=true
				check(g.state.landmark==hut.from and g.state.next_landmark==hut.to and int(g.state.leg_miles)>=int(hut.at),"Taco Hut meets the party on its own stretch")
				check(g.state.leg_miles<g.state.leg_length or g.state.leg_miles>=int(hut.at),"Taco Hut comes before the stop ahead")
				var store=Store.new()
				var restored=store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))
				check(restored!=null and restored.pending.get("id","")=="taco_hut" and restored.oddities.places==g.oddities.places,"A save at Taco Hut reloads with the same deal")
				var money: float=float(g.state.money)
				g.choose(0)
				check(is_equal_approx(float(g.state.money),money-2.0),"Eating at Taco Hut costs $2")
				break
			g.choose(pick(g))
			continue
		if g.state.landmark==hut.to:break
		g.travel()
	check(met,"Seed %d meets its Taco Hut" % seed_value)
	check("taco_hut" in g.seen,"Taco Hut is marked as visited")
	var marks: Array=g.oddities.map_marks(g)
	check(marks.any(func(m):return m.id=="taco_hut" and m.seen and m.label=="TACO HUT" and m.fraction>0.0 and m.fraction<1.0),"The map marks Taco Hut on its road, visited")
	g.state.leg_miles=int(hut.at)
	g.pending={}
	g._schedule_event(false)
	check(g.pending.get("id","")!="taco_hut","Taco Hut does not come round twice")
	# The Civet replaces a wagon; on foot it waits further down the road.
	var walker=started(seed_value)
	walker.oddities.road=[{"id":"civet","mile":0}]
	walker.oddities.places=[]
	walker.state.vehicle="foot"
	check(walker.oddities.due(walker).is_empty(),"No Civet for a party with no wagon")
	walker.state.vehicle="wagon"
	check(walker.oddities.due(walker).get("id","")=="civet","The Civet waits for a wagon")
	walker._present(walker.oddities.due(walker))
	walker.choose(0)
	check(int(walker.state.fuel)==3 and walker.state.vehicle=="wagon","Taking the Civet reuses the vehicle slot and fills three days of fuel")
	var before: int=int(walker.state.miles)
	walker.pending={}
	walker.travel()
	check(int(walker.state.miles)-before==30 or int(walker.state.leg_miles)==int(walker.state.leg_length),"The Civet makes 30 miles a day (or reaches the stop)")
	# The Novablade: a pack item that is the best blade in any fight, weightless and never for sale.
	var armed=started(seed_value)
	var Armory=armed.Armory
	check(Armory.count(armed.state,"novablades")==0 and Armory.loadout(armed.state,2)[0].blade!="novablades","No Novablade until it is found")
	var weight: float=Armory.extra_weight(armed.state)
	armed._present(event(armed,"novablade"))
	armed.choose(0)
	check(Armory.count(armed.state,"novablades")==1 and Armory.loadout(armed.state,2)[0].blade=="novablades" and Armory.loadout(armed.state,2)[1].blade!="novablades","The leader carries the one Novablade")
	check(is_equal_approx(Armory.extra_weight(armed.state),weight),"The Novablade weighs nothing on the load")
	var blade: Dictionary=Armory.data.blades.novablades
	check(float(blade.hit)>=0.95 and int(blade.damage_min)>=int(Armory.data.blades.hatchets.damage_max)*2,"The Novablade outclasses every 1848 blade")
	# It sells at a post counter (Spencer: "you can sell it, sure").
	armed.pending={}
	armed.state.next_landmark="fort_laramie"
	armed._arrive_landmark()
	var store: Dictionary=armed.trade_counter()
	var row: Array=store.get("rows",[]).filter(func(r):return r.item=="novablades")
	check(row.size()==1 and int(row[0].sell_cents)==6000 and int(row[0].can_buy)==0,"A post will buy the Novablade for $60 and never sells one")
	var cash: float=float(armed.state.money)
	check(armed.counter_checkout({"novablades":-1}) and int(armed.state.novablades)==0 and float(armed.state.money)>cash+59.0,"Selling the Novablade pays for it and it is gone")
	check(Armory.loadout(armed.state,2)[0].blade!="novablades","Sold, it is out of the fight")
	# The Onyx Sphere seen from miles off: it grows as you near it and is gone past the horizon.
	var FarSphere=load("res://ui/far_sphere.gd")
	var stops: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json")).stops
	var there: Array=[lerpf(stops.salt_lake[0],stops.bear_river_ford[0],0.4),lerpf(stops.salt_lake[1],stops.bear_river_ford[1],0.4)]
	var near: Dictionary=FarSphere.view(stops.salt_lake,there)
	var far: Dictionary=FarSphere.view(stops.raft_river,there)
	check(not near.is_empty() and not far.is_empty() and int(near.size)>int(far.size)*3 and int(near.tier)<int(far.tier),"The sphere looms near Salt Lake and is a far grey dome from the Raft River")
	check(FarSphere.view(stops.fort_laramie,there).is_empty(),"It is out of sight from Fort Laramie")
	var plain:=Image.load_from_file("res://art/pixels/location_fort_hall.png")
	plain.convert(Image.FORMAT_RGBA8)
	var painted: Image=FarSphere.new().paint(plain,FarSphere.view(stops.fort_hall,there))
	var changed:=0
	var on_land:=0
	for y in plain.get_height():
		for x in plain.get_width():
			if painted.get_pixel(x,y)!=plain.get_pixel(x,y):
				changed+=1
				if not FarSphere._is_sky(plain.get_pixel(x,y)):on_land+=1
	check(changed>20 and on_land==0,"In a stop picture it is painted over the sky only (%d px, %d on land)" % [changed,on_land])
	test_sailor()
	test_novablade_custody()
	await test_cul_de_sac()
	test_laundry()
	test_civet_transport()
	await test_road_sprites()
	print("Unhinged: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func test_sailor():
	var g=started(4242)
	g._present(event(g,"beached_ship"))
	var index: int=-1
	for i in range(g.pending.choices.size()):
		if g.pending.choices[i].label=="Sign on the sailor":index=i
	check(index>=0 and g.can_choose(index),"The beached ship offers its sailor")
	var store=Store.new()
	var restored=store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))
	check(restored!=null and restored.can_choose(index),"The sailor offer survives a save")
	var day: int=g.state.day
	var food: int=g.state.food
	var money: float=g.state.money
	var bullets: int=g.state.bullets
	var clothing: int=g.state.clothing
	var gear: int=g.state.get("household_gear_lb",0)
	var dice=g.rng.state
	check(g.choose(index),"Signing on the sailor succeeds")
	check(g.party_health.members.size()==6 and g.party_health.members[5].id==5 and g.state.party_size==6 and g.current_party_slots().has(5),"The sailor joins the ordinary roster with a permanent id")
	check(g.party_health.members[5].name=="Hollis Venn" and g.characters.profiles[5].skill=="Carpentry" and g.characters.profiles[5].contract.is_empty(),"The ship's carpenter has an invented name, existing background and no wage contract")
	check(g.state.day==day and g.state.food==food and g.state.money==money and g.state.bullets==bullets and g.rng.state==dice,"Recruiting costs no day or cash and grants no provisions or main RNG draws")
	check(g.state.clothing==clothing+int(g.recruitment.rules.clothing) and g.state.recruited_gear_lb==int(g.recruitment.rules.personal_gear_lb) and (not g.state.has("household_gear_lb") or g.state.household_gear_lb==gear+int(g.recruitment.rules.personal_gear_lb)),"The sailor brings normal recruit clothing and personal gear")
	check(g.recruitment.valid(g.recruitment.snapshot(),g),"The sailor has a valid recruitment ledger")
	var after=store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))
	check(after!=null and after.recruitment.snapshot()==g.recruitment.snapshot() and after.party_health.members==g.party_health.members and after.social.snapshot()==g.social.snapshot(),"Sailor health, recruitment and relationships round-trip")
	if restored!=null:
		restored.choose(index)
		check(restored.characters.profiles[5]==g.characters.profiles[5],"Reloading the offer recruits the same sailor")
	g._present(event(g,"beached_ship"))
	check(not g.can_choose(index) and not g.choose(index) and g.party_health.members.size()==6,"A replayed ship cannot recruit a second sailor")
	var decline=started(4242)
	decline._present(event(decline,"beached_ship"))
	decline.choose(decline.pending.choices.size()-1)
	check(decline.party_health.members.size()==5 and decline.recruitment.record.searches.is_empty(),"Leaving the ship does not recruit anyone")
	var vacant=started(4242)
	vacant.party_health.members[2].alive=false
	vacant.state.party_size=vacant.party_health.living_count()
	vacant._present(event(vacant,"beached_ship"))
	vacant.choose(index)
	check(vacant.recruitment.record.slots[2]==5 and not vacant.party_health.members[2].alive and vacant.party_health.members.size()==6,"The sailor fills a vacancy without overwriting its history")
	var full=started(4242)
	while full.party_health.members.size()<full.MAX_TRAVELERS:full.party_health.members.append({})
	full._present(event(full,"beached_ship"))
	var before: Dictionary=full.recruitment.snapshot()
	check(not full.can_choose(index) and not full.choose(index) and full.recruitment.snapshot()==before,"The traveler cap rejects recruitment without changing the ledger")
	var plain=started(4242,"classic")
	plain._present(event(plain,"beached_ship"))
	check(not plain.can_choose(index),"Classic cannot sign on the sailor")

func crime_pick(game,command: String) -> bool:
	for i in range(game.pending.get("choices",[]).size()):
		if game.pending.choices[i].get("crime_command","")==command:return game.choose(i)
	return false

func take_civet():
	var game=started(57)
	for e in game.catalog.events:game.seen.append(e.id)
	game.oddities.places=[]
	game.oddities.road=[]
	game._present(event(game,"civet"))
	check(game.choose(0),"Take the Civet in place of the wagon")
	return game

func test_civet_transport():
	var store=Store.new()
	for with_oxen in [true,false]:
		var game=take_civet()
		check(game.oddities.civet_index(game.state)==0 and game.wagon_count()==1,"The Civet replaces one vehicle slot, without adding a wagon")
		if not with_oxen:
			game.state.oxen=0
			game.team_conditions.sync(game)
		check(game.Train.ready(game).is_empty() and game.provisions.capacity(game.state)>0,"Fuelled Civet has carrying capacity and does not require draft animals")
		for i in range(3):
			if not game.pending.is_empty():game.choose(pick(game))
			var before: int=game.state.miles
			check(game.travel() and game.state.miles>before and game.state.miles-before<=30,"Powered day %d makes up to thirty miles, including without oxen" % (i+1))
			check(game.state.fuel==2-i,"Each powered travel day consumes one day of fuel")
		check(game.oddities.civet_index(game.state)==0 and not game.oddities.powered_civet(game.state),"The empty Civet stays with the party")
		var saved: Dictionary=store.capture(game)
		var restored=store.restore(JSON.parse_string(JSON.stringify(saved)))
		check(restored!=null and store.capture(restored)==saved,"An empty Civet saves and restores exactly")
		if not game.pending.is_empty() and with_oxen:game.choose(pick(game))
		game.pending={}
		var before: int=game.state.miles
		var day: int=game.state.day
		check(game.travel(),"Try to move the empty Civet")
		if with_oxen:check(game.state.miles>before and game.state.fuel==0,"Surviving oxen pull the empty Civet at normal team speed")
		else:check(game.state.miles==before and game.state.day==day and game.pending.get("id","") in ["no_team","train_unready"],"Without oxen the empty Civet stops without spending another day")
	var legacy=take_civet()
	legacy.state.erase("civet_wagon_id")
	var saved: Dictionary=store.capture(legacy)
	saved.rules="e9c49cd422a9a7fa3178931a0ad99cbe2b2c8442c5c51b940bf815d038a514f8"
	var old=store.restore(JSON.parse_string(JSON.stringify(saved)))
	check(old!=null and old.oddities.powered_civet(old.state),"Previous master powered-Civet saves remain usable")
	if old!=null:
		old.pending={}
		old.travel()
		check(old.state.has("civet_wagon_id"),"An older powered Civet retains its identity before fuel is spent")
	var cached=take_civet()
	cached.state.fuel=0
	cached.pending={}
	check(cached.abandon_wagon({"food":30,"clothing":5}) and cached.oddities.civet_index(cached.state)==-1,"Leaving the Civet uses ordinary cache rules and removes its travel sprite")
	var replacement: Dictionary=cached.state.duplicate(true)
	check(cached.provisions.WagonTrade.apply_inventory(cached,replacement,1) and cached.oddities.civet_index(replacement)==-1,"Buying a different wagon does not turn it into the left-behind Civet")
	cached.pending={}
	check(cached.recover_wagon() and cached.oddities.civet_index(cached.state)==0,"Recovering the cached Civet restores its identity")
	var bad: Dictionary=store.capture(cached)
	bad.state.civet_wagon_id=int(bad.state.next_wagon_id)
	check(store.restore(bad)==null,"A save cannot invent an unknown Civet vehicle id")
	var plain=started(57,"classic")
	plain._present(event(plain,"civet"))
	check(not plain.choose(0),"Classic cannot acquire the Civet")
	var broken=started(57)
	broken.pending={}
	check(broken.camp_repair.queue(broken,"axles"),"Prepare a broken wagon before the car encounter")
	broken._present(event(broken,"civet"))
	check(broken.choose(0) and broken.state.wagon_train[0].condition==100 and broken.camp_repair.work.is_empty() and not broken.state.has("repair_wagon_id"),"A running replacement Civet does not inherit the abandoned wagon's broken part")

func test_road_sprites():
	var view_script=load("res://ui/trail_view.gd")
	for spec in [["road_vending_machine",28,36],["road_phone_booth",28,44],["road_frogs",64,12]]:
		var texture: Texture2D=load("res://art/pixels/%s.png" % spec[0])
		check(texture!=null and texture.get_size()==Vector2(spec[1],spec[2]),"New road sprite has its intended native size: "+spec[0])
		var image: Image=texture.get_image()
		var crisp: bool=true
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				if image.get_pixel(x,y).a not in [0.0,1.0]:crisp=false
		check(crisp,"New road sprite has crisp transparent edges: "+spec[0])
	check(view_script.CAR==load("res://art/pixels/corolla.png") and view_script.SABER==load("res://art/pixels/lightsaber.png") and view_script.ROAD_BISON==load("res://art/pixels/hunt_bison.png"),"Existing sedan, Novablade and bison artwork is reused")
	var screen=load("res://ui/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	for id in ["novablade","civet","vending_machine","french_bison","phone_booth","frog_rain","mirror_train"]:
		screen.game=started(57)
		screen.game.pending={}
		screen.game.travel()
		screen.game._present(event(screen.game,id))
		var dice=screen.game.rng.state
		var health_dice=screen.game.party_health.rng.state
		screen._refresh()
		screen.landscape.queue_redraw()
		await process_frame
		await process_frame
		check(screen.landscape.encounter==id and screen.landscape.scene_id.is_empty(),"Road oddity draws in the travel strip: "+id)
		check(screen.game.rng.state==dice and screen.game.party_health.rng.state==health_dice,"Road visuals do not roll simulation dice: "+id)
	screen.landscape.set_process(false)
	screen.landscape.clock_time=0
	var first: Array=screen.landscape.frog_particles()
	check(first==screen.landscape.frog_particles(),"Frog rain is deterministic at a fixed animation time")
	for time in [0.0,0.1,1.7,19.0]:
		screen.landscape.clock_time=time
		var valid: bool=true
		for frog in screen.landscape.frog_particles():
			if not Rect2(0,0,432,150).encloses(Rect2(frog.at,Vector2(16,12))):valid=false
			if frog.falling and frog.at.y<view_script.FROG_CLOUD_BASE:valid=false
			if not frog.falling and frog.at.y<126:valid=false
		check(valid,"Frogs emerge below clouds, land on the ground and remain inside the scene at %.1fs" % time)
	check(first!=screen.landscape.frog_particles(),"Falling and hopping frogs animate over time")
	screen.game=take_civet()
	screen.game.pending={}
	screen.game.travel()
	screen.game.state.fuel=0
	screen._refresh()
	check(screen.landscape.vehicle=="civet" and not screen.landscape.civet_powered and screen.landscape.civet_index==0,"The real travel view keeps the sedan and shows ox-drawn mode after fuel expires")
	screen.queue_free()
	await process_frame

func test_laundry():
	var game=started(57)
	game._present(event(game,"laundromat"))
	for member in game.party_health.members:member.health=70
	game.state.health=70
	var cash: float=game.state.money
	var day: int=game.state.day
	var dice=game.rng.state
	check(game.choose(0),"The party can wash at the laundromat")
	check(is_equal_approx(float(game.state.money),cash-1.0) and game.state.health>70 and event(game,"laundromat").choices[0].effects.health==6 and game.state.day==day,"Laundry keeps its $1 cost and existing health benefit without a day cost")
	check(game.state.clean_until==day+14 and game.rng.state==dice,"Laundry records a fortnight without drawing the journey dice")
	check(is_equal_approx(game.oddities.clean_onset_factor(game.state),0.8),"Clean clothes modestly reduce spontaneous onset")
	var store=Store.new()
	var saved: Dictionary=store.capture(game)
	var restored=store.restore(JSON.parse_string(JSON.stringify(saved)))
	check(restored!=null and store.capture(restored)==saved,"Laundry protection round-trips exactly")
	var state: Dictionary=game.state.duplicate(true)
	state.day=day+14
	check(is_equal_approx(game.oddities.clean_onset_factor(state),0.8),"Protection includes the fourteenth following day")
	state.day+=1
	check(game.oddities.clean_onset_factor(state)==1.0,"Protection expires on the fifteenth following day")
	state.mode="classic"
	state.day=day
	check(game.oddities.clean_onset_factor(state)==1.0,"Classic never gains laundry protection")
	var old: Dictionary=saved.duplicate(true)
	old.state.erase("clean_until")
	old.rules="38699226e287ddad9bbd5f7263b72d6bb8e0043ca78cfe3825800e953ba82c99"
	var legacy=store.restore(old)
	check(legacy!=null and not legacy.state.has("clean_until") and legacy.oddities.clean_onset_factor(legacy.state)==1.0,"An older save loads without free protection")
	for invalid in [-1,day+15,1.5,"14",true]:
		var bad: Dictionary=saved.duplicate(true)
		bad.state.clean_until=invalid
		check(store.restore(bad)==null,"Saves reject an invalid laundry expiry: "+str(invalid))
	var bad: Dictionary=saved.duplicate(true)
	bad.state.mode="classic"
	check(store.restore(bad)==null,"Classic saves cannot claim laundry protection")
	var declined=started(57)
	declined._present(event(declined,"laundromat"))
	check(declined.choose(1) and not declined.state.has("clean_until"),"Passing the laundromat grants no protection")
	var broke=started(57)
	broke.state.money=0
	broke._present(event(broke,"laundromat"))
	check(not broke.choose(0) and not broke.state.has("clean_until"),"Unaffordable laundry cannot grant protection")
	# A shared health-RNG draw between the two thresholds proves the real daily tick is wired.
	var seed_value: int=0
	var random=RandomNumberGenerator.new()
	for s in range(1000):
		random.seed=s
		var draw: float=random.randf()
		if draw>=0.7*0.6*0.8 and draw<0.7*0.6:seed_value=s;break
	var dirty=started(57)
	var clean=started(57)
	for g in [dirty,clean]:
		g.pending={}
		g.party_health.daily_onset_chance=1.0
		g.party_health.rng.seed=seed_value
	clean.state["clean_until"]=int(clean.state.day)+14
	dirty._tick_day(true)
	clean._tick_day(true)
	check(dirty.party_health.members.any(func(m):return not m.conditions.is_empty()) and clean.party_health.members.all(func(m):return m.conditions.is_empty()),"The actual daily illness roll is reduced while clean")
	# Expiry restores the same roll and outcome; merely having an old timestamp does nothing.
	var expired=started(57)
	var plain=started(57)
	for g in [expired,plain]:
		g.pending={}
		g.party_health.daily_onset_chance=1.0
		g.party_health.rng.seed=seed_value
	expired.state["clean_until"]=int(expired.state.day)
	expired._tick_day(true)
	plain._tick_day(true)
	check(expired.party_health.members==plain.party_health.members and expired.party_health.rng.state==plain.party_health.rng.state,"Expired protection leaves ordinary health outcomes and RNG unchanged")
	var sick_clean=started(57)
	var sick_plain=started(57)
	for g in [sick_clean,sick_plain]:
		g.pending={}
		g.party_health.begin_condition(0,"dysentery",int(g.state.day),1)
		g.party_health.begin_condition(1,"wound",int(g.state.day),1)
	sick_clean.state["clean_until"]=int(sick_clean.state.day)+14
	sick_clean._tick_day(true)
	sick_plain._tick_day(true)
	check(sick_clean.party_health.members==sick_plain.party_health.members and sick_clean.party_health.rng.state==sick_plain.party_health.rng.state,"Laundry does not alter existing disease, wound or spread clocks")
	var offer=started(57)
	offer._present(event(offer,"laundromat"))
	var pending_save: Dictionary=store.capture(offer)
	check(store.restore(pending_save)!=null,"An unchosen laundry offer saves and loads")
	pending_save.pending.choices[0].clean_days=1000
	check(store.restore(pending_save)==null,"A save cannot forge a longer laundry offer")
	offer.pending.choices[0].clean_days="forever"
	check(not offer.choose(0),"A malformed laundry offer is safely rejected")

func test_cul_de_sac():
	var game=started(4242)
	# A place is met inside a leg, not at a route stop.
	game.pending={}
	game.state.next_landmark="south_pass"
	game._arrive_landmark()
	game.choose(pick(game))
	game.state.leg_miles=10
	game.state.miles+=10
	game._present(event(game,"cul_de_sac"))
	var index: int=-1
	for i in range(game.pending.choices.size()):
		if game.pending.choices[i].label=="Move into a house":index=i
	check(index>=0 and game.can_choose(index),"The houses offer a permanent home")
	var store=Store.new()
	var offer: Dictionary=store.capture(game)
	var restored=store.restore(JSON.parse_string(JSON.stringify(offer)))
	check(restored!=null and restored.can_choose(index),"The settlement offer survives a save")
	var before: Dictionary=game.state.duplicate(true)
	var dice=game.rng.state
	check(game.choose(index) and game.state.status=="settled" and game.state.settled.kind=="cul_de_sac","Moving into a house ends the journey with its own settlement kind")
	check(game.pending.is_empty() and game.service_return.is_empty(),"The ending clears the event and service menus")
	for key in ["day","money","food","health","ox_health","miles","leg_miles","landmark","next_landmark"]:
		check(game.state[key]==before[key],"Settlement preserves "+key)
	check(game.rng.state==dice and not game.travel() and not game.rest() and not game.choose(index),"The finished party cannot keep traveling, resting or settling again")
	var score: Dictionary=game.Scoring.breakdown(game)
	check(score.ending=="cul_de_sac" and is_equal_approx(score.ending_factor,0.6) and score.total>0,"The houses score the same factor as an ordinary settlement")
	check("houses in the sage" in game.Cabins.ending_title(game) and "blue door" in game.Cabins.ending_text(game) and "houses in the sage" in game.Scoring.text(game),"The ending and score name the houses rather than the last stop")
	var saved: Dictionary=store.capture(game)
	var after=store.restore(JSON.parse_string(JSON.stringify(saved)))
	check(after!=null and store.capture(after)==saved,"A mid-leg cul-de-sac ending round-trips exactly")
	var bad: Dictionary=saved.duplicate(true)
	bad.state.mode="classic"
	check(store.restore(bad)==null,"Classic saves cannot claim this settlement")
	bad=saved.duplicate(true)
	bad.state.settled.people="somebody"
	check(store.restore(bad)==null,"The empty houses cannot claim a welcoming community")
	var old: Dictionary=offer.duplicate(true)
	old.rules="262c4869cdae6e1ba3d43eabfd4963beaaf028029e0f528acbca39f5dabab35a"
	check(store.restore(old)!=null,"The previous master fingerprint still loads")
	var plain=started(4242,"classic")
	plain._present(event(plain,"cul_de_sac"))
	check(not plain.can_choose(index),"Classic cannot settle in the houses")
	var lawn=started(4242)
	lawn._present(event(lawn,"cul_de_sac"))
	var day: int=lawn.state.day
	check(lawn.choose(0) and lawn.state.day==day+1 and lawn.state.status=="traveling","Resting on the lawn still spends one day and continues the journey")
	var screen=load("res://ui/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.game=game
	screen._refresh()
	check(screen.landscape.scene_id=="ending_cul_de_sac" and screen.landscape.scenes.textures.has("ending_cul_de_sac"),"The ending screen selects the registered cul-de-sac picture")
	check("houses in the sage" in screen.event_title.text and "SCORE" in screen.event_text.text,"The actual screen shows the settlement and score")
	screen.queue_free()
	await process_frame

func test_novablade_custody():
	var detention=preload("res://simulation/detention.gd")
	check(detention.valid_arms({"rifles":5,"knives":4,"novablades":1}),"Custody accepts a Novablade alongside ordinary arms")
	for invalid in [null,[],{"unknown_blade":1},{"novablades":0},{"novablades":2},{"novablades":-1},{"novablades":0.5},{"novablades":"1"},{"rifles":101}]:
		check(not detention.valid_arms(invalid),"Custody rejects malformed or excessive arms: "+str(invalid))
	var game=started(57)
	game._present(event(game,"novablade"))
	check(game.choose(0),"Find the Novablade before arrest")
	game.pending={}
	game.state.next_landmark="independence"
	game._arrive_landmark()
	check(game.open_crime("independence"),"Open the store crime with a Novablade")
	game.crime.scenes.independence.theft_success=0
	check(crime_pick(game,"theft") and crime_pick(game,"surrender"),"A caught thief surrenders with the Novablade equipped")
	var current: Dictionary=game.crime.incident()
	check(current.stage=="custody" and current.custody.arms.get("novablades",0)==1 and game.state.novablades==0,"Arrest holds the blade instead of leaving it in inventory")
	var store=Store.new()
	var saved: Dictionary=store.capture(game)
	var restored=store.restore(JSON.parse_string(JSON.stringify(saved)))
	check(restored!=null,"A save with the Novablade in custody restores")
	if restored==null:return
	check(store.capture(restored)==saved,"Custody preserves the whole save exactly")
	check(crime_pick(restored,"bail") and restored.state.novablades==1,"Release returns the one confiscated Novablade")
	var released: Dictionary=store.capture(restored)
	var after=store.restore(JSON.parse_string(JSON.stringify(released)))
	check(after!=null and store.capture(after)==released,"The custody record remains valid after the blade is returned")
	check(crime_pick(restored,"finish") and not crime_pick(restored,"bail") and restored.state.novablades==1,"Closing the hearing cannot return the blade twice")
	for invalid in [2,0,-1,0.5,"1"]:
		var bad: Dictionary=saved.duplicate(true)
		bad.crime.record.incidents.back().custody.arms.novablades=invalid
		check(store.restore(bad)==null,"Save validation rejects a forged custody blade count: "+str(invalid))
