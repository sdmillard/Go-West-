extends SceneTree
## Known criminals are recognized by chance, masks hide a clean getaway, and a known name cows ordinary victims
## (Spencer, October 31).
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	game.state.next_landmark="fort_bridger"
	game._arrive_landmark()
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	for profile in game.characters.profiles.slice(1):profile.boundaries=game.characters.catalog.boundaries("Opportunistic")
	var scene: Dictionary=game.crime.scenes.fort_bridger
	scene.compliance=1
	scene.escape_capture=0
	scene.escape_injury=0
	return game
func choose(game,command: String) -> bool:
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("crime_command","")==command:
			# The old hit roll: an attack that comes to a fight off the grid. New openings are tested in test_strike.gd.
			if command in ["shoot","assault"]:game.crime.forced_strike="fight"
			return game.choose(index)
	return false
## Rob Fort Bridger and get away; masked when asked.
func rob(game,masked: bool=false) -> Dictionary:
	game.open_crime()
	if masked:check(choose(game,"mask") and game.pending.get("crime_masked",false),"MASK ties kerchiefs on before the act")
	choose(game,"robbery")
	choose(game,"flee")
	choose(game,"finish")
	return game.crime.record.incidents[-1]
func at_hall(game,report: Dictionary) -> void:
	game.state.next_landmark="fort_hall"
	game._arrive_landmark()
	game.state.day=game.crime.arrival(game,report,"fort_hall")
func run():
	var store=Store.new()
	var game=outfit()
	check(not game.crime.recognition.is_empty() and not game.crime.reputation.is_empty(),"Recognition and reputation rules load")
	var bad: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/crime_scenes.json"))
	bad.recognition.acts.robbery=1.5
	check(not game.crime.load_data(bad),"A recognition chance above one is rejected")
	bad=JSON.parse_string(FileAccess.get_file_as_string("res://data/crime_scenes.json"))
	bad.reputation.kinds=["fort"]
	check(not game.crime.load_data(bad),"Soldiers cannot be cowed by a reputation")
	game=outfit()
	# A named robbery: recognized or not by one fixed draw per place.
	var robbed: Dictionary=rob(game)
	var report: Dictionary=game.crime.record.reports[0]
	check(report.identified and not robbed.has("mask"),"A bare-faced robbery names the party")
	at_hall(game,report)
	var chance: float=game.crime.recognition_chance(game,report)
	check(is_equal_approx(chance,0.65*game.crime.fade(game,int(robbed.day))) and chance<0.65 and chance>0.5,"A robbery is recognized about two times in three, a little less as the news ages")
	var answer: bool=game.crime.refuses(game,"fort_hall")
	check(range(5).all(func(_i):return game.crime.refuses(game,"fort_hall")==answer),"Asking again draws nothing new")
	var copy=store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	check(copy!=null and copy.crime.refuses(copy,"fort_hall")==answer,"A save keeps the answer")
	game.crime.recognition.acts.robbery=1.0
	game.crime.recognition.half_life_days=3650
	check(game.crime.refuses(game,"fort_hall") and game.open_trade() and game.pending.title=="The post will not trade","A post that knows the party refuses it")
	game.pending=game.service_return.duplicate(true)
	game.service_return={}
	game.crime.recognition.acts.robbery=0.0
	check(not game.crime.refuses(game,"fort_hall") and game.open_trade() and game.pending.title=="Trading post" and "nobody takes you for them" in game.pending.text,"A post that heard the news but does not know the party trades, and says so")
	game.pending={}
	# Fading: the chance halves every half life, so old news may stop closing a door it once closed.
	game.crime.recognition.acts.robbery=0.65
	game.crime.recognition.half_life_days=60
	var later: int=int(game.state.day)+int(game.crime.recognition.half_life_days)
	var now: float=game.crime.recognition_chance(game,report)
	game.state.day=later
	check(is_equal_approx(game.crime.recognition_chance(game,report),now*0.5),"The chance halves after the half life")
	# Across many places a known robbery closes most doors but not all.
	var known:=0
	var places: Array=game.crime.venues().filter(func(place):return place!="fort_bridger" and not game.crime.household(place))
	for seed_value in range(40):
		game.state.seed=seed_value
		for place in places:if game.crime.recognized(game,place,report):known+=1
	var share: float=known/float(40*places.size())
	check(share>0.15 and share<0.5,"Two months on, a robbery is still known in some places but not most (%.2f)" % share)
	# Killing is remembered best.
	var robbery_chance: float=game.crime.recognition_chance(game,report)
	robbed.attempt="killed"
	check(game.crime.act_of(robbed)=="killed" and game.crime.recognition_chance(game,report)>robbery_chance,"A killing is remembered better than a robbery")
	robbed.attempt="complied"
	# Masks.
	game=outfit()
	game.crime.recognition.mask_slip=0
	robbed=rob(game,true)
	report=game.crime.record.reports[0]
	check(robbed.get("mask","")=="hidden" and not report.identified,"A clean masked getaway leaves only a description")
	at_hall(game,report)
	check(is_equal_approx(game.crime.recognition_chance(game,report),0.65*0.25*game.crime.fade(game,int(robbed.day))),"A masked party is known only by its outfit, a quarter as often")
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"A masked incident saves and restores")
	var saved: Dictionary=store.capture(game)
	var forged: Dictionary=saved.duplicate(true)
	forged.crime.record.incidents[0].mask="covered"
	check(store.restore(forged)==null,"A finished getaway cannot keep an unsettled mask")
	forged=saved.duplicate(true)
	forged.crime.record.incidents[0].mask="slipped"
	check(store.restore(forged)==null,"The report must match whether the mask held")
	game.crime.recognition.masked_factor=1.0
	game.crime.recognition.acts.robbery=1.0
	game.crime.recognition.half_life_days=3650
	check(game.crime.refuses(game,"fort_hall") and "masked party" in game.crime.news_text(game,"fort_hall"),"A recognized masked party is refused, and told why")
	game=outfit()
	game.crime.recognition.mask_slip=1
	robbed=rob(game,true)
	check(robbed.mask=="slipped" and game.crime.record.reports[0].identified,"A slipped mask names the party")
	game=outfit()
	game.context.record.spent["post:fort_bridger|buy_food"]=1
	game.crime.service("fort_bridger")
	game.open_crime()
	choose(game,"mask")
	check("seen your faces" in game.pending.text,"The menu warns when the people here already know the party's faces")
	game.pending={}
	game.context.record.spent.erase("post:fort_bridger|buy_food")
	check(game.crime.faces_seen(game,"fort_bridger")==false,"Nobody here has seen the party before it trades")
	game.context.record.spent["post:fort_bridger|buy_food"]=1
	check(game.crime.faces_seen(game,"fort_bridger"),"Trading at a place shows the party's faces")
	game=outfit()
	game.crime.scenes.fort_bridger.escape_capture=1
	game.open_crime()
	choose(game,"mask")
	choose(game,"robbery")
	choose(game,"flee")
	check(game.crime.record.incidents[0].get("mask","")=="known","Anyone taken is seen bare-faced")
	# Reputation: ordinary victims give in more to a party whose name has reached them; a masked party is nobody.
	game=outfit()
	var base: float=game.crime.odds(game,"fort_hall").compliance
	rob(game)
	report=game.crime.record.reports[0]
	at_hall(game,report)
	var feared: Dictionary=game.crime.odds(game,"fort_hall")
	check(is_equal_approx(feared.fame,2*float(game.crime.reputation.step)) and feared.compliance>base,"A named robbery makes the next store likelier to give in")
	game.pending={"crime_masked":true}
	check(game.crime.fame(game,"fort_hall")==0.0,"Masked, the party's name does not help")
	game.pending={}
	check(game.crime.fame(game,"fort_kearny")==0.0,"Soldiers are not cowed")
	game.crime.reputation.step=0.1
	check(game.crime.fame(game,"fort_hall")<=float(game.crime.reputation.cap),"The benefit is capped")
	print("Recognition: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
