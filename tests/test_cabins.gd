extends SceneTree
## Winter cabins, settling short of Oregon, and a score for every ending (Spencer, October 31).
const Simulation=preload("res://simulation/trail_engine.gd")
const Cabins=preload("res://simulation/cabins.gd")
const Scoring=preload("res://simulation/scoring.gd")
const Route=preload("res://simulation/route_catalog.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func at(stop: String,date: String="1848-08-10",seed_value: int=57,profession: String="banker"):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	cart["hatchets"]=1
	game.depart(profession,["A","B","C","D","E"],6,cart)
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	game.state.day=int((Time.get_unix_time_from_datetime_string(date+"T00:00:00")-Time.get_unix_time_from_datetime_string("1848-06-01T00:00:00"))/86400)
	game.state.next_landmark=stop
	game._arrive_landmark()
	for profile in game.characters.profiles.slice(1):profile.trust=90.0
	return game
func round_trip(game):
	var store=Store.new()
	return store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
func run():
	# Rules.
	var route=Route.new()
	check(Cabins.valid_rules(Cabins.data,route),"Cabin and settling rules cover every stop once")
	var bad: Dictionary=Cabins.data.duplicate(true)
	bad.settle.posts.append("fort_kearny")
	check(not Cabins.valid_rules(bad,route),"A stop cannot be both a post and somebody's country")
	bad=Cabins.data.duplicate(true)
	bad.timber.append("nowhere")
	check(not Cabins.valid_rules(bad,route),"Timber only at real stops")
	check(Scoring.valid_rules(Scoring.data),"Scoring rules load")
	# Where a cabin can go.
	var plains=at("courthouse_rock")
	check("no timber" in Cabins.reason(plains),"No cabin on the bare plains")
	var bridger=at("fort_bridger")
	check(Cabins.reason(bridger).is_empty(),"Fort Bridger's cottonwoods will do")
	bridger.state.hatchets=0
	check("hatchet" in Cabins.reason(bridger),"A cabin needs a hatchet")
	bridger.state.hatchets=1
	bridger.pending={}
	bridger.state.leg_miles=5
	check("at a stop" in Cabins.reason(bridger),"Not on the open road")
	bridger.state.leg_miles=0
	# Building: 15 worker-days; five hands take three days, food and time pass, no rest recovery.
	var game=at("fort_bridger")
	var hands: int=Cabins.workers(game).size()
	check(hands==5 and Cabins.days_left(game)==3,"Five fit hands need three days (%d hands, %d days)" % [hands,Cabins.days_left(game)])
	var day: int=game.state.day
	var food: int=game.state.food
	check(Cabins.build(game) and game.state.day==day+1 and game.state.food<food,"A building day costs a day and meals")
	check(Cabins.progress(game,"fort_bridger")==Cabins.workers(at("fort_bridger")).reduce(func(n,h):return n+int(h.units),0) and not Cabins.done(game,"fort_bridger"),"Progress is recorded per stop")
	var copy=round_trip(game)
	check(copy!=null and Cabins.progress(copy,"fort_bridger")==Cabins.progress(game,"fort_bridger"),"Progress saves and loads")
	var forged: Dictionary=Store.new().capture(game)
	forged.state.cabins["courthouse_rock"]=4
	check(Store.new().restore(JSON.parse_string(JSON.stringify(forged)))==null,"No cabin where there is no timber")
	while not Cabins.done(game,"fort_bridger") and game.state.status=="traveling":
		game.pending=game.pending if game.pending.has("landmark") else {"landmark":"fort_bridger"}
		if not Cabins.build(game):break
	check(Cabins.done(game,"fort_bridger") and game.journal.any(func(line):return "cabin at Fort Bridger is finished" in line),"The cabin is finished and the journal says so")
	check(not Cabins.build(game),"A finished cabin needs no more work")
	# A carpenter builds faster.
	var carpenter=at("fort_bridger","1848-08-10",57,"carpenter")
	check(Cabins.workers(carpenter)[0].units==3 and Cabins.days_left(carpenter)<=3,"The carpenter leader works half again as fast")
	# Shelter: no exposure in a December blizzard, everything else goes on.
	var winter_out=at("fort_bridger","1848-12-10")
	var winter_in=at("fort_bridger","1848-12-10")
	winter_in.state["cabins"]={"fort_bridger":Cabins.units_needed()}
	for g in [winter_out,winter_in]:
		g.state.clothing=0
		g.survival.forced_weather="blizzard"
		g.party_health.daily_onset_chance=0
		g.pending={}
	check(Cabins.sheltered(winter_in) and not Cabins.sheltered(winter_out),"Only the party with a cabin is sheltered")
	var food_in: int=winter_in.state.food
	for i in range(10):
		winter_out.rest();winter_in.rest()
	check(winter_in.party_health.average_health()>winter_out.party_health.average_health(),"The cabin keeps out the blizzard (%d vs %d)" % [winter_in.party_health.average_health(),winter_out.party_health.average_health()])
	check(winter_in.state.food<food_in,"Meals go on in the cabin")
	check(winter_in.journal.any(func(line):return line.begins_with("Day")) and winter_in.state.day>0,"Winter is lived day by day")
	# Settling: open, post, Native consent, run off.
	var home=at("elm_grove")
	check(Cabins.settle_kind(home)=="native" and Cabins.people(home)=="Shawnee","Elm Grove is Shawnee country")
	var oregon_edge=at("eagle_creek")
	check(Cabins.settle_kind(oregon_edge)=="open" and Cabins.welcome(oregon_edge),"The edge of the Willamette settlements is open")
	check(Cabins.settle(oregon_edge) and oregon_edge.state.status=="settled" and oregon_edge.state.settled.kind=="open","Settling there ends the journey")
	check(not oregon_edge.travel() and not oregon_edge.rest(),"A settled journey is over")
	check(round_trip(oregon_edge)!=null,"A settled ending saves and loads")
	var hall=at("fort_hall")
	check(Cabins.settle_kind(hall)=="post" and Cabins.welcome(hall) and "hands" in Cabins.settle_text(hall),"A post takes the party on")
	var yes:=0
	var asked:=0
	var welcome_seed:=-1
	var refused_seed:=-1
	for seed_value in range(60):
		var g=at("grande_ronde","1848-08-10",seed_value)
		asked+=1
		if Cabins.welcome(g):
			yes+=1
			if welcome_seed<0:welcome_seed=seed_value
		elif refused_seed<0:refused_seed=seed_value
	check(yes>5 and yes<35,"The people of a country agree now and then, more often not (%d of %d)" % [yes,asked])
	var refused=at("grande_ronde","1848-08-10",refused_seed)
	check("Nez Perce country" in Cabins.settle_text(refused) and "run you off" in Cabins.settle_text(refused),"The settle preview says the people refuse and what staying means")
	check(Cabins.welcome(refused)==Cabins.welcome(refused),"Asking again changes nothing")
	check(Cabins.settle(refused) and refused.state.settled.kind=="run_off" and "ran you off" in Cabins.ending_text(refused),"Staying anyway ends with the party run off")
	var welcomed=at("grande_ronde","1848-08-10",welcome_seed)
	welcomed.state["cabins"]={"grande_ronde":Cabins.units_needed()}
	check(Cabins.settle(welcomed) and welcomed.state.settled.kind=="cabin" and "Nez Perce" in Cabins.ending_text(welcomed),"A welcomed party settles in its own cabin")
	# Scoring for every ending.
	var arrived=at("eagle_creek")
	arrived.state.status="arrived"
	var settled=at("eagle_creek")
	Cabins.settle(settled)
	var lost=at("eagle_creek")
	lost.state.status="lost"
	var east=at("eagle_creek")
	east.state.status="returned_east"
	var a: Dictionary=Scoring.breakdown(arrived)
	check(a.total>0 and a.travelers==500 and a.ending=="arrived","Five healthy travelers who reach Oregon score 500 for themselves")
	check(Scoring.breakdown(settled).total<a.total and Scoring.breakdown(settled).total>Scoring.breakdown(refused).total,"Settling short scores below Oregon and above being run off")
	check(Scoring.breakdown(east).total<Scoring.breakdown(settled).total and Scoring.breakdown(lost).total==0,"Turning back scores little; a lost journey nothing")
	var farmer=at("eagle_creek","1848-08-10",57,"farmer")
	farmer.state.status="arrived"
	check(is_equal_approx(Scoring.profession_factor(farmer),2.2) and is_equal_approx(Scoring.profession_factor(arrived),1.0),"A farmer's score is multiplied by the banker's purse over the farmer's")
	check("SCORE" in Scoring.text(arrived) and "keepsakes" in Scoring.text(arrived),"The score explains itself")
	# The camp screen.
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.game=at("fort_bridger")
	screen._show_section("Cabin")
	await process_frame
	var build=screen.section_rows.find_child("CabinBuild",true,false)
	var settle=screen.section_rows.find_child("CabinSettle",true,false)
	check(build!=null and not build.disabled and settle!=null and not settle.disabled,"CAMP > CABIN offers building and settling")
	settle.pressed.emit()
	await process_frame
	check(screen.settle_confirmation.visible and "hands" in screen.settle_confirmation.dialog_text,"Settling asks for confirmation and says what it means")
	screen.settle_confirmation.confirmed.emit()
	await process_frame
	check(screen.game.state.status=="settled" and "Settled at Fort Bridger" in screen.event_title.text and "SCORE" in screen.event_text.text,"The ending screen shows the settling and the score")
	print("Cabins: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
