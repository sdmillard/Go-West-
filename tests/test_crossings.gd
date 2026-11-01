extends SceneTree
## River crossings on every road (Spencer, November 1): stops that sat on a real 1848 crossing
## but played as camps, new crossing stops inside older roads, and the crossing world's banks.
const Simulation=preload("res://simulation/trail_engine.gd")
const Route=preload("res://simulation/route_catalog.gd")
const Store=preload("res://simulation/save_store.gd")
## Crossings added in November 2026: none had a ferry in 1848.
const FORDS=["big_vermilion","laramie_ford","weber_river","bear_river_ford","white_river","gravelly_ford","klamath_river","rogue_valley","umpqua_valley"]
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func at(stop: String,date: String,foot: bool=false,seed: int=61):
	var game=Simulation.new(seed,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],6,cart)
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	if foot:game.state.vehicle="foot"
	game.state.day=int((Time.get_unix_time_from_datetime_string(date+"T00:00:00")-Time.get_unix_time_from_datetime_string("1848-06-01T00:00:00"))/86400)
	game.state.next_landmark=stop
	game._arrive_landmark()
	return game
func methods(game) -> Array:
	return game.pending.choices.map(func(c):return c.get("method","")).filter(func(m):return m!="")
func run():
	var route=Route.new()
	check(route.error.is_empty() and route.total_miles==1938,"The main road is still 1938 guide miles (%d)" % route.total_miles)
	for id in FORDS:
		check(route.nodes[id].kind=="river" and not route.nodes[id].has("ferry_dollars"),"%s is a crossing with no ferry in 1848" % id)
	# The new stops sit inside the roads they split, which keep their length.
	check(route.edge_between("scotts_bluff","laramie_ford").miles+route.edge_between("laramie_ford","fort_laramie").miles==36,"Scotts Bluff to Fort John is still 36 miles, by the Laramie ford")
	check(route.edge_between("fort_bridger","weber_river").miles+route.edge_between("weber_river","salt_lake").miles==121,"Bridger to the city is still Clayton's 121 miles, by the Weber")
	check(route.edge_between("salt_lake","bear_river_ford").miles+route.edge_between("bear_river_ford","raft_river").miles==230,"Hensley's cutoff is still 230 miles, by the Bear River")
	check(route.edge_between("the_dalles","white_river").miles+route.edge_between("white_river","barlow_pass").miles==70,"The Dalles to Barlow Pass is still 70 miles, by the White River")
	check(route.main_path_to("oregon_city").has("laramie_ford") and route.main_path_to("oregon_city").has("white_river"),"The main road fords the Laramie and the White River")
	check(not route.edge_between("salt_lake","bear_river_ford").get("wagon_opens","").is_empty(),"Hensley's pack trail still opens to wagons in September 1848")
	# Each one offers a ford and a float, and nothing to hire.
	for id in FORDS:
		var g=at(id,"1848-08-15")
		var m: Array=methods(g)
		check(g.pending.get("landmark","")==id and "ford" in m and "float" in m and not "ferry" in m,"%s offers a ford and a float, no ferry (%s)" % [id,m])
		var walker=at(id,"1848-08-15",true)
		check(methods(walker)==["swim"],"Walkers swim %s with their packs" % id)
	# Snow-fed rivers run high in the June melt.
	var june: int=0
	var august: int=0
	for seed in range(40):
		if at("laramie_ford","1848-06-10",false,seed).state.river_stage=="high":june+=1
		if at("laramie_ford","1848-08-20",false,seed).state.river_stage=="high":august+=1
	check(june>august,"The Laramie runs high more often in June than August (%d against %d)" % [june,august])
	# Crossing it and going on reaches the fort.
	var cross=at("laramie_ford","1848-08-15")
	cross.state.river_stage="low"
	var ford: int=-1
	for index in range(cross.pending.choices.size()):
		if cross.pending.choices[index].get("method","")=="ford":ford=index
	cross.rng.seed=3
	check(cross.choose(ford) and cross.state.next_landmark=="fort_laramie","Across the Laramie the road goes on to Fort John")
	check(cross.last_crossing.get("landmark","")=="laramie_ford","The crossing is recorded at the Laramie ford")
	# The Barlow road still warns of, and shuts to wagons in, its winter at The Dalles.
	var dalles=at("the_dalles","1848-12-05")
	var barlow: Dictionary=dalles.pending.choices.filter(func(c):return c.get("seasonal_road","")=="barlow_pass")[0] if dalles.pending.choices.any(func(c):return c.get("seasonal_road","")=="barlow_pass") else {}
	check(not barlow.is_empty() and "snowbound to wagons" in barlow.label and not dalles.can_choose(dalles.pending.choices.find(barlow)),"The Barlow road closes at The Dalles, before the White River")
	# The Mormon ferry at the upper crossing of the North Platte (1847 onward): a dollar and a half, more in high water.
	for stage in ["low","high"]:
		var np=at("north_platte","1848-07-01")
		np.state.river_stage=stage
		np._arrive_landmark(false,false)
		var ferry: Array=np.pending.choices.filter(func(c):return c.get("method","")=="ferry")
		check(ferry.size()==1 and is_equal_approx(-float(ferry[0].effects.money),(1.5 if stage=="low" else 3.0)*maxi(1,np.Train.count(np.state))+float(np.livestock.data.ferry_head_cents)/100.0*(np.livestock.count(np.state,"dairy_cows")+np.livestock.count(np.state,"goats"))),"The Mormon ferry on the North Platte charges by the water: %s" % stage)
	# Crossing banks by country.
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/route.json"))
	var bad: Dictionary=data.duplicate(true)
	for node in bad.nodes:if node.id=="gravelly_ford":node.crossing_country="jungle"
	check(not Route.new().load_data(bad),"An unknown crossing country is rejected")
	bad=data.duplicate(true)
	for node in bad.nodes:if node.id=="the_dalles":node.next[0].closed_with="laurel_hill"
	check(not Route.new().load_data(bad),"A road can only close with a stop that has a closed season")
	check(route.nodes.gravelly_ford.crossing_country=="sage" and route.nodes.klamath_river.crossing_country=="pine" and route.nodes.rogue_valley.crossing_country=="oak" and not route.nodes.kansas_river.has("crossing_country"),"Crossings are drawn in the country they lie in")
	var view=preload("res://ui/trail_view.gd").new()
	for country in ["sage","pine","oak"]:
		var tex: Texture2D=view.CROSSING_COUNTRY[country]
		check(tex.get_size()==view.CROSSING.get_size(),"The %s crossing world matches the prairie one" % country)
	view.free()
	# Records from before these crossings still load, and land on the right piece of a split road.
	var expect={"laramie_leg":["scotts_bluff","laramie_ford",20],"weber_leg":["weber_river","salt_lake",5],"hensley_leg":["bear_river_ford","raft_river",40],"barlow_leg":["white_river","barlow_pass",4]}
	for name in ["laramie_leg","weber_leg","hensley_leg","barlow_leg","big_vermilion_spare","gravelly_stop"]:
		var record: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-crossings-%s-v1.json" % name))
		var store=Store.new()
		var game=store.restore(record)
		check(game!=null,"A record from before the crossings loads: %s (%s)" % [name,store.error])
		if game==null:continue
		if expect.has(name):
			var e: Array=expect[name]
			check(game.state.landmark==e[0] and game.state.next_landmark==e[1] and int(game.state.leg_miles)==e[2],"%s lands between %s and %s at %d miles (%s>%s %d)" % [name,e[0],e[1],e[2],game.state.landmark,game.state.next_landmark,game.state.leg_miles])
			check(game.route_path[-1]==game.state.landmark,"%s keeps its road behind it" % name)
		if name=="big_vermilion_spare":
			check(not game.pending.has("day_miles_left") and game.pending.choices.all(func(c):return not "more miles today" in str(c.get("label",""))),"A record at Big Vermilion loses the minor camp's spare miles")
	print("Crossings: %d checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
