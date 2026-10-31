extends SceneTree
## Winter on the Columbia: wind, cold and icy water make the raft harder, and a hard winter freezes it shut
## (Spencer, October 31).
const Simulation=preload("res://simulation/trail_engine.gd")
const Route=preload("res://simulation/route_catalog.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func at_dalles(date: String,seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],6,cart)
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	game.state.day=int((Time.get_unix_time_from_datetime_string(date+"T00:00:00")-Time.get_unix_time_from_datetime_string("1848-06-01T00:00:00"))/86400)
	game.state.next_landmark="the_dalles"
	game._arrive_landmark()
	return game
func raft_choice(game) -> int:
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("river_leg",false):return index
	return -1
## A seed whose winter of 1849 is hard, or not.
func seed_for(hard: bool) -> int:
	for seed_value in range(1,400):
		var game=at_dalles("1849-01-10",seed_value)
		if game.hard_winter(1849)==hard:return seed_value
	return -1
func run():
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/route.json"))
	var route=Route.new()
	check(route.nodes.columbia_raft.has("river_winter"),"The Columbia has winter rules")
	for change in [{"key":"frozen_months","value":[7]},{"key":"hard_winter_chance","value":1.5},{"key":"chill_damage","value":-1}]:
		var bad: Dictionary=data.duplicate(true)
		for node in bad.nodes:if node.id=="columbia_raft":node.river_winter[change.key]=change.value
		check(not Route.new().load_data(bad),"Malformed river winter rejected: %s" % change.key)
	# Summer: nothing changes.
	var summer=at_dalles("1848-08-10")
	check(summer.river_winter().is_empty() and not summer.river_frozen(),"No river winter in August")
	var raft: int=raft_choice(summer)
	check(raft>=0 and summer.can_choose(raft) and not ("winter" in summer.pending.choices[raft].label),"The raft is open in summer with no warning")
	# Hard and mild winters.
	var hard_seed: int=seed_for(true)
	var mild_seed: int=seed_for(false)
	check(hard_seed>0 and mild_seed>0,"Some winters are hard and some are not")
	var shares:=0
	for seed_value in range(200):
		var g=Simulation.new(seed_value,"classic",true)
		if g.hard_winter(1849):shares+=1
	check(shares>25 and shares<75,"About one winter in four freezes the river (%d of 200)" % shares)
	var mild=at_dalles("1849-01-10",mild_seed)
	raft=raft_choice(mild)
	check(not mild.river_frozen() and mild.can_choose(raft) and "winter wind and cold" in mild.pending.choices[raft].label,"In a mild winter the raft still goes, with a warning")
	check("Winter on the Columbia" in mild.season_notice(),"The season notice explains the river winter")
	var frozen=at_dalles("1849-01-10",hard_seed)
	raft=raft_choice(frozen)
	check(frozen.river_frozen() and not frozen.can_choose(raft) and "frozen" in frozen.pending.choices[raft].label,"In a hard January no raft is launched")
	check("frozen over" in frozen.season_notice(),"The notice says the river is frozen")
	check(frozen.pending.choices.any(func(c):return c.get("action","")=="rest"),"The party can winter at The Dalles")
	var december=at_dalles("1848-12-20",hard_seed)
	check(not december.river_frozen() and december.can_choose(raft_choice(december)),"Even a hard winter does not freeze the river before January")
	var march=at_dalles("1849-03-05",hard_seed)
	check(march.river_winter().is_empty() and march.can_choose(raft_choice(march)),"The ice is gone by March")
	var same: bool=frozen.river_frozen()
	frozen.rest()
	check(frozen.river_frozen()==same,"Waiting a day does not reroll the winter")
	# Afloat in winter: cold, and the wind pins the raft some days.
	var pinned:=0
	var days:=0
	var colder:=0
	var arrived:=0
	var told:=false
	for seed_value in range(1,9):
		var afloat=at_dalles("1848-12-01",seed_value)
		afloat.choose(raft_choice(afloat))
		afloat.pending={}
		var health: int=afloat.party_health.average_health()
		var steps:=0
		while afloat.state.landmark=="the_dalles" and steps<40 and afloat.state.status=="traveling":
			var miles: int=afloat.state.miles
			afloat.travel()
			afloat.pending={}
			steps+=1
			if afloat.state.miles==miles:pinned+=1
		days+=steps
		if afloat.state.landmark=="columbia_raft":arrived+=1
		if afloat.party_health.average_health()<health:colder+=1
		if afloat.journal.any(func(line):return "pins the raft" in line):told=true
	check(arrived==8,"Every raft reaches the Cascades in December")
	check(pinned>0 and pinned<days*0.6,"Wind pins the raft some winter days but not most (%d of %d)" % [pinned,days])
	check(told,"The journal says why the raft made no miles")
	check(colder==8,"The cold wears on everyone afloat")
	# Rapids: icy water drowns a wreck more often; in a frozen month nobody runs them.
	var cascades=at_dalles("1848-12-01",mild_seed)
	cascades.state.landmark="columbia_raft";cascades.state.next_landmark="columbia_raft"
	cascades.state.landmark="the_dalles";cascades.state.next_landmark="columbia_raft"
	cascades._arrive_landmark()
	var run_index: int=-1
	for index in range(cascades.pending.choices.size()):if cascades.pending.choices[index].get("rafting",false):run_index=index
	check(run_index>=0 and "icy water" in cascades.pending.choices[run_index].label,"Running the rapids in winter warns of icy water")
	check(cascades.start_rafting(),"The run still launches in a mild winter")
	cascades.raft.ended=true;cascades.raft.wrecked=true;cascades.raft.hits=5;cascades.raft.integrity=0
	cascades.raft.drowning_roll=float(cascades.rafting.data.drowning_chance_on_wreck)*1.5
	var alive: int=cascades.party_health.living_count()
	cascades.finish_rafting()
	check(cascades.party_health.living_count()==alive-1 or cascades.last_rafting.drowned>=0,"A wreck that summer water would spare drowns someone in icy water")
	var icy=at_dalles("1849-01-10",hard_seed)
	icy.state.landmark="the_dalles";icy.state.next_landmark="columbia_raft"
	icy._arrive_landmark()
	for index in range(icy.pending.choices.size()):
		if icy.pending.choices[index].get("rafting",false):check(not icy.can_choose(index),"Nobody runs frozen rapids")
		if icy.pending.choices[index].get("river_leg",false):check(not icy.can_choose(index),"Nor floats on below the Cascades")
	check(Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(icy))))!=null,"A frozen winter saves and loads")
	print("River winter: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
