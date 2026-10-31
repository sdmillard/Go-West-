extends SceneTree
## New stops on the 1848 road, the Salt Lake branch and Native nations on the map (Spencer, October 31).
const Simulation=preload("res://simulation/trail_engine.gd")
const Route=preload("res://simulation/route_catalog.gd")
const Cabins=preload("res://simulation/cabins.gd")
const Store=preload("res://simulation/save_store.gd")
const NEW=["big_vermilion","little_blue","horseshoe_creek","deer_creek","willow_spring","bear_river","salt_lake","american_falls","raft_river","salmon_falls","malheur","umatilla_mouth"]
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func at(stop: String,date: String,foot: bool=false):
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],6,cart)
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	if foot:game.state.vehicle="foot"
	game.state.day=int((Time.get_unix_time_from_datetime_string(date+"T00:00:00")-Time.get_unix_time_from_datetime_string("1848-06-01T00:00:00"))/86400)
	if stop=="salt_lake":
		game.route_path=game.route.main_path_to("fort_bridger")
		game.state.landmark="fort_bridger"
	game.state.next_landmark=stop
	game._arrive_landmark()
	return game
func onward(game) -> int:
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("action","")=="leave":return index
	return -1
func run():
	var route=Route.new()
	check(route.error.is_empty() and route.total_miles==1938,"The main road is still 1938 guide miles")
	check(NEW.all(func(id):return route.nodes.has(id)),"Every new stop is on the route")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/route.json"))
	var path: Array=route.main_path_to("oregon_city")
	for id in ["big_vermilion","little_blue","horseshoe_creek","deer_creek","willow_spring","bear_river","american_falls","raft_river","salmon_falls","malheur","umatilla_mouth"]:
		check(id in path,"The main road passes %s" % id)
	check(not route.edge_between("greenwood_cutoff","bear_river").is_empty() and not route.edge_between("fort_walla_walla","umatilla_mouth").is_empty(),"Greenwood's cutoff and the Walla Walla road rejoin at the new junctions")
	# A minor camp reached early in the day costs no travel time if the party leaves at once.
	check(NEW.filter(func(id):return route.nodes[id].get("minor",false)).size()==11 and not route.nodes.salt_lake.get("minor",false),"The eleven road camps are minor stops; Salt Lake is not")
	var walk=at("kansas_river","1848-06-10")
	walk.pending={}
	walk.state.merge({"next_landmark":"big_vermilion","leg_length":79,"leg_miles":76},true)
	var day: int=walk.state.day
	walk.travel()
	check(walk.pending.get("landmark","")=="big_vermilion" and int(walk.pending.get("day_miles_left",0))>0,"Reaching Big Vermilion early leaves miles in the day")
	var spare: int=int(walk.pending.day_miles_left)
	var miles: int=walk.state.miles
	walk.choose(onward(walk))
	check(walk.state.day==day+1 and walk.state.miles==miles+mini(spare,13) and walk.state.next_landmark=="big_blue","Leaving at once makes the rest of the day's miles (day %d/%d miles %d/%d+%d next %s pending %s)" % [walk.state.day,day+1,walk.state.miles,miles,spare,walk.state.next_landmark,walk.pending.get("title","")])
	var stay=at("kansas_river","1848-06-10")
	stay.pending={}
	stay.state.merge({"next_landmark":"big_vermilion","leg_length":79,"leg_miles":76},true)
	stay.travel()
	for index in range(stay.pending.choices.size()):
		if stay.pending.choices[index].get("action","")=="rest":
			stay.choose(index)
			break
	stay.pending={"landmark":"big_vermilion"} if stay.pending.is_empty() else stay.pending
	var before: int=stay.state.miles
	stay.choose(onward(stay))
	check(stay.state.miles==before and stay.state.leg_miles==0,"A party that spends the day at the camp starts fresh tomorrow (%d/%d leg %d, pending %s)" % [stay.state.miles,before,stay.state.leg_miles,stay.pending.get("title","")])
	var saved_stop: Dictionary=Store.new().capture(walk)
	var forged: Dictionary=saved_stop.duplicate(true)
	forged.pending={"id":"x","title":"x","text":"x","choices":[{"label":"x"}],"day_miles_left":5}
	check(Store.new().restore(JSON.parse_string(JSON.stringify(forged)))==null,"Spare miles belong only to a minor camp's stop menu")
	# Salt Lake branch.
	var branch: Dictionary=route.edge_between("fort_bridger","salt_lake")
	var cutoff: Dictionary=route.edge_between("salt_lake","raft_river")
	check(not branch.is_empty() and not cutoff.is_empty() and route.nodes.fort_bridger.next[0].to=="bear_river","Salt Lake is a branch from Fort Bridger, not the main road")
	check(branch.miles+cutoff.miles>route.remaining("fort_bridger")-route.remaining("raft_river"),"The Salt Lake road is the longer way to the Raft River")
	var bad: Dictionary=data.duplicate(true)
	for node in bad.nodes:if node.id=="salt_lake":node.next[0].wagon_opens="1848-13-40"
	check(not Route.new().load_data(bad),"A malformed wagon-road opening date is rejected")
	var summer=at("salt_lake","1848-08-20")
	var leave: int=onward(summer)
	check(leave>=0 and not summer.can_choose(leave) and "September 15, 1848" in summer.pending.choices[leave].label,"Wagons cannot take Hensley's pack trail before mid-September 1848")
	check(summer.pending.choices.any(func(c):return c.get("action","")=="rest"),"A wagon party can wait in the valley")
	var walkers=at("salt_lake","1848-08-20",true)
	check(walkers.can_choose(onward(walkers)),"Walkers and riders can take the pack trail now")
	var autumn=at("salt_lake","1848-09-20")
	check(autumn.can_choose(onward(autumn)) and not ("pack animals" in autumn.pending.choices[onward(autumn)].label),"The wagon road is open from mid-September 1848")
	var later=at("salt_lake","1849-07-01")
	check(later.can_choose(onward(later)),"Later years have the wagon road from the start")
	check(Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(summer))))!=null,"A party at Salt Lake saves and loads")
	check(summer.open_trade() and summer.pending.title=="Trading post","Salt Lake has a trading house")
	summer.pending={"landmark":"salt_lake"}
	check(Cabins.settle_kind(summer)=="open" and Cabins.welcome(summer) and Cabins.timber(summer),"Salt Lake is open to settlers, with canyon timber")
	# A record made before the new stops, caught on the old Fort Hall to Snake River road.
	var old=at("fort_hall","1848-08-10")
	old.pending={}
	var saved: Dictionary=Store.new().capture(old)
	saved.rules="7d8de1181200cf9d018c29ef35f50f338a303b85a630590d1aff47db64ed1018"
	saved.state.next_landmark="snake_river"
	saved.state.leg_length=162
	saved.state.leg_miles=50
	saved.state.miles=int(saved.state.miles)+50
	saved.route_path=saved.route_path.filter(func(id):return id not in NEW)
	var upgraded=Store.new().restore(JSON.parse_string(JSON.stringify(saved)))
	check(upgraded!=null,"An older record on a road that now has stops still loads")
	if upgraded!=null:
		check(upgraded.state.landmark=="raft_river" and upgraded.state.next_landmark=="salmon_falls" and upgraded.state.leg_miles==9 and upgraded.state.leg_length==98,"Fifty miles past Fort Hall the party is nine miles past the Raft River")
		check("american_falls" in upgraded.route_path and "raft_river" in upgraded.route_path and "bear_river" in upgraded.route_path,"The new stops behind the party are filled into its route")
		check(upgraded.destination()==old.destination(),"The journey is no longer or shorter for the upgrade")
	# Every stop has a settle rule and the map knows every nation.
	check(Cabins.valid_rules(Cabins.data,route),"Settle rules cover every new stop once")
	var map: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json"))
	var peoples: Array=[]
	for id in Cabins.data.settle.peoples:
		if str(Cabins.data.settle.peoples[id]) not in peoples:peoples.append(str(Cabins.data.settle.peoples[id]))
	check(peoples.all(func(name):return map.nations.has(name)) and map.nations.keys().all(func(name):return name in peoples),"Every nation named on the road is labelled on the map, and only those")
	check(NEW.all(func(id):return map.stops.has(id)),"Every new stop has a map point")
	print("New stops: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
