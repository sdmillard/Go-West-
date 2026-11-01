extends SceneTree
## The Applegates' South Road (1846) as a branch from the Raft River (Spencer, November 1, 2026).
const Simulation=preload("res://simulation/trail_engine.gd")
const Route=preload("res://simulation/route_catalog.gd")
const Cabins=preload("res://simulation/cabins.gd")
const Store=preload("res://simulation/save_store.gd")
const ROAD=["city_of_rocks","humboldt_wells","gravelly_ford","lassen_meadows","black_rock","high_rock_canyon","fandango_pass","goose_lake","tule_lake","klamath_river","green_springs","rogue_valley","canyon_creek","umpqua_valley","south_willamette"]
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func day_of(date: String) -> int:
	return int((Time.get_unix_time_from_datetime_string(date+"T00:00:00")-Time.get_unix_time_from_datetime_string("1848-06-01T00:00:00"))/86400)
## A banker's wagon party arriving at a stop on the South Road (or the Raft River) on a date.
func at(stop: String,date: String,food: int=1500):
	var game=Simulation.new(61,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],6,cart)
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	game.state.day=day_of(date)
	var path: Array=game.route.main_path_to("raft_river")
	if stop!="raft_river":
		path.append_array(ROAD.slice(0,ROAD.find(stop)))
	game.route_path=path
	game.state.landmark=path[-1] if stop!="raft_river" else path[-2]
	game.state.next_landmark=stop
	game.state.food=food
	game._arrive_landmark()
	return game
func onward(game,to: String) -> int:
	for index in range(game.pending.choices.size()):
		var choice: Dictionary=game.pending.choices[index]
		if choice.get("action","")=="leave" and game.route.nodes[game.state.landmark].next[int(choice.get("edge",0))].to==to:return index
	return -1
func run():
	var route=Route.new()
	check(route.error.is_empty() and route.total_miles==1938,"The main road is still 1938 guide miles")
	check(ROAD.all(func(id):return route.nodes.has(id)),"Every South Road stop is on the route")
	var branch: Dictionary=route.edge_between("raft_river","city_of_rocks")
	check(route.nodes.raft_river.next[0].to=="salmon_falls" and not branch.is_empty(),"The South Road is a branch at the Raft River, not the main road")
	var south: int=branch.miles
	var here: String="city_of_rocks"
	while here!="oregon_city":
		var edge: Dictionary=route.nodes[here].next[0]
		south+=int(edge.miles)
		here=edge.to
	var north: int=route.remaining("raft_river")
	check(south-north>=250 and south-north<=350,"The South Road is about 300 miles longer, as Huber and Adams reckoned (%d against %d)" % [south,north])
	check(route.edge_between("lassen_meadows","black_rock").get("hazard","")=="waterless","The drive to Black Rock is waterless")
	check(["black_rock","high_rock_canyon","fandango_pass","goose_lake","tule_lake","green_springs","rogue_valley"].all(func(id):return route.nodes[id].next[0].get("hazard","")=="raids"),"Raiders work the Paiute, Pit River, Modoc and Rogue country")
	check(route.nodes.fandango_pass.has("snow_country") and route.nodes.green_springs.has("snow_country") and route.nodes.canyon_creek.get("descent",false),"Snow on the two passes; Canyon Creek is let down like a descent")
	check(ROAD.all(func(id):return route.nodes[id].get("remote",false)==(id!="south_willamette")),"No traders on the road until the head of the Willamette")
	# The fork, early and late in the season.
	var early=at("raft_river","1848-08-10")
	var late=at("raft_river","1848-09-10")
	var turn: int=onward(early,"city_of_rocks")
	check(turn>=0 and early.can_choose(turn) and "South Road" in early.pending.choices[turn].label and not ("late in the year" in early.pending.choices[turn].label),"In August the fork offers the South Road")
	check("late in the year" in late.pending.choices[onward(late,"city_of_rocks")].label,"After August the fork warns that it is late for the South Road")
	var bad: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/route.json"))
	for node in bad.nodes:if node.id=="raft_river":node.next[1].late_after="13-40"
	check(not Route.new().load_data(bad),"A malformed late-season date is rejected")
	early.choose(turn)
	check(early.state.next_landmark=="city_of_rocks","Choosing the South Road heads for the City of Rocks")
	# No traders on the road.
	var rocks=at("city_of_rocks","1848-08-15")
	var market: Dictionary=rocks.context.market(rocks)
	check(not market.available and market.get("remote",false),"No passing traders on the South Road")
	check(rocks.open_trade() and rocks.pending.title=="No traders on this road","Asking for traders says none work this road")
	var valley=at("south_willamette","1848-10-01")
	check(valley.context.market(valley).get("remote",false)==false,"The Willamette settlements are not remote")
	# Camping at the Humboldt before the desert is not itself a dry camp; the desert is.
	var turnoff=at("lassen_meadows","1848-08-25")
	turnoff.state.next_landmark="black_rock"
	turnoff.state.leg_length=58
	check(not turnoff.on_dry_stretch() and turnoff.current_edge().get("hazard","")=="waterless","A camp on the Humboldt before the desert has water")
	var health: int=turnoff.state.health
	turnoff.rest()
	check(turnoff.state.health>=health,"Resting at the turnoff costs no thirst")
	turnoff.pending={}
	turnoff.state.leg_miles=20
	check(turnoff.on_dry_stretch(),"Out in the desert the party is on a dry stretch")
	# Arrows in the night: only on raided roads, and only with a team to shoot.
	var raided=at("black_rock","1848-09-01")
	raided.pending={}
	raided.state.next_landmark="high_rock_canyon"
	raided.state.leg_length=40
	raided.state.leg_miles=10
	raided.survival.data.event_chance=1.0
	var arrows: int=0
	var elsewhere: int=0
	for attempt in range(60):
		raided.pending={}
		raided.survival.last_events.clear()
		raided._roll_trail_event()
		if raided.pending.get("id","")=="arrows_in_the_stock":arrows+=1
	var plain=at("humboldt_wells","1848-08-20")
	plain.pending={}
	plain.state.next_landmark="gravelly_ford"
	plain.state.leg_length=90
	plain.state.leg_miles=10
	plain.survival.data.event_chance=1.0
	for attempt in range(60):
		plain.pending={}
		plain.survival.last_events.clear()
		plain._roll_trail_event()
		if plain.pending.get("id","")=="arrows_in_the_stock":elsewhere+=1
	check(arrows>0 and elsewhere==0,"Arrows in the night happen on raided roads only (%d raided, %d elsewhere)" % [arrows,elsewhere])
	var shot=at("black_rock","1848-09-01")
	shot.pending={}
	shot.state.next_landmark="high_rock_canyon"
	shot.state.leg_length=40
	shot.state.leg_miles=10
	var oxen: int=shot.state.oxen
	for event in shot.trail_events.events:
		if event.id=="arrows_in_the_stock":shot._present_trail_event(event)
	check(shot.pending.get("id","")=="arrows_in_the_stock","The raid event is presented")
	check(shot.state.oxen==oxen-1,"Raiders kill an ox")
	var butcher: int=shot.pending.choices.find(shot.pending.choices.filter(func(c):return c.has("carcass_meat"))[0])
	var food: int=shot.state.food
	shot.choose(butcher)
	check(shot.state.food>food,"The dead ox can be butchered for meat")
	# Relief from the settlements: once, late in the year, for a party in need.
	var hungry=at("rogue_valley","1848-11-20",40)
	check(hungry.pending.get("title","")=="Relief from the settlements","Settlers meet a late, hungry company in the Rogue valley")
	var before: int=hungry.state.food
	hungry.choose(0)
	check(hungry.state.food==before+40*int(hungry.state.party_size) and hungry.pending.get("landmark","")=="rogue_valley","They bring flour, and the party is back at its camp")
	hungry.state.landmark="rogue_valley"
	hungry.state.food=20
	check(hungry.relief_offer().is_empty(),"Relief comes only once")
	var fed=at("rogue_valley","1848-11-20",1500)
	check(fed.pending.get("landmark","")=="rogue_valley","A well-fed company with a sound team gets no relief")
	var summer=at("rogue_valley","1848-08-20",40)
	check(summer.pending.get("landmark","")=="rogue_valley","No relief rides out before October")
	var spent=at("umpqua_valley","1848-12-05",1500)
	spent.pending={}
	spent.state.oxen=2
	spent.state.ox_health=30
	var offer: Dictionary=spent.relief_offer()
	check(int(offer.get("oxen",0))==2 and int(offer.get("ox_health",0))>0,"A failing team gets fresh oxen")
	# Saves on the branch, mid-leg.
	var travel=at("klamath_river","1848-09-25")
	travel.pending={}
	travel.state.next_landmark="green_springs"
	travel.state.leg_length=25
	travel.state.leg_miles=10
	var copy=Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(travel))))
	check(copy!=null and copy.state.next_landmark=="green_springs" and "lassen_meadows" in copy.route_path,"A party on the South Road saves and loads")
	# Records from the two versions before the South Road (new stops; walking) still load.
	for rules in ["a258c092aa252cc9579024d72fc23e4ea1ad3662c0b695d85a0c0e653f78c815","345bc2eb1f1026e64ff834bf625a0f6fbee76f39398d15daa2f0362c5a4991f1"]:
		var older=at("fort_hall","1848-08-01")
		older.pending={}
		var record: Dictionary=Store.new().capture(older)
		record.rules=rules
		check(Store.new().restore(JSON.parse_string(JSON.stringify(record)))!=null,"A record from rules %s loads" % rules.left(8))
	# Settling and timber.
	valley.pending={"landmark":"south_willamette"}
	check(Cabins.settle_kind(valley)=="open" and Cabins.timber(valley),"The head of the Willamette is open to settlers, with timber")
	var map: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json"))
	check(ROAD.all(func(id):return map.stops.has(id)),"Every South Road stop has a map point")
	var news: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_news.json"))
	check(ROAD.all(func(id):return news.road.has(id)),"Travelers have something to say about every South Road stop")
	print("Applegate: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
