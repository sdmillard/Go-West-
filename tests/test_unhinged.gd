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
	# The Civet needs a wagon to tow; on foot it waits further down the road.
	var walker=started(seed_value)
	walker.oddities.road=[{"id":"civet","mile":0}]
	walker.oddities.places=[]
	walker.state.vehicle="foot"
	check(walker.oddities.due(walker).is_empty(),"No Civet for a party with no wagon")
	walker.state.vehicle="wagon"
	check(walker.oddities.due(walker).get("id","")=="civet","The Civet waits for a wagon")
	walker._present(walker.oddities.due(walker))
	walker.choose(0)
	check(int(walker.state.fuel)==3 and walker.state.vehicle=="wagon","Taking the Civet keeps the wagon and fills three days of fuel")
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
