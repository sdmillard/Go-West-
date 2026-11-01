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
	print("Unhinged: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
