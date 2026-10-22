extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Remains=preload("res://simulation/remains.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func party(values: Array=["Compassionate","Compassionate","Compassionate","Ruthless"],bonds: Array=[],seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	game.pending={}
	for index in range(1,5):
		var profile: Dictionary=game.characters.profiles[index]
		profile.traits=["Cautious",values[index-1]]
		profile.boundaries=game.characters.catalog.boundaries(values[index-1])
	game.crime.record.bonds=bonds
	return game
func kill(game,id: int,cause: String="cholera") -> void:
	game.party_health.affect(game.party_health.members[id],-200,game.state.day,cause)
	game._collect_health_events()
	game.state.party_size=game.party_health.living_count()
	game.state.health=game.party_health.average_health()
## Travels the given number of days, leaving any landmark it reaches.
func go(game,days: int) -> void:
	for day in range(days):
		if game.pending.has("landmark"):
			for index in range(game.pending.choices.size()):
				if game.pending.choices[index].get("action","") in ["leave","cross"]:
					game.choose(index)
					break
		game.pending={}
		game.travel()
	if not game.pending.has("landmark"):game.pending={}
func camp(game) -> void:
	game.pending={}
	game.rest()
	game.pending={}
func command(game,name: String,id: int) -> int:
	for index in range(game.pending.choices.size()):
		var choice: Dictionary=game.pending.choices[index]
		if choice.get("remains_command","")!=name:continue
		# Meal choices name an eater; the others name a body.
		if int(choice.get("member",-1) if name in Remains.MEAL_COMMANDS else choice.get("remains_id",0))==id:return index
	return -1
func act(game,name: String,id: int) -> bool:
	var index:=command(game,name,id)
	return index>=0 and game.choose(index)
func round_trip(store,game):
	return store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
func run():
	var store=Store.new()
	# No death, no remains; a death is recorded where it happened, once.
	var game=party()
	check(game.crime.record.remains.is_empty() and not game.open_remains(),"A journey begins with nobody to tend")
	go(game,3)
	var mile: int=game.state.miles
	var before: int=game.state.food
	kill(game,2)
	var body: Dictionary=game.crime.record.remains[0]
	check(game.crime.record.remains.size()==1 and body.person==game.crime.person_id(57,2) and body.name=="Ben" and body.cause=="cholera" and body.mile==mile and body.state=="lying","A companion's death enters the ledger where it happened")
	game._collect_health_events()
	check(game.crime.record.remains.size()==1,"The same death is never recorded twice")
	check(game.state.food==before and not game.state.has("remains_lb"),"Death grants nothing by itself")
	var food: int=game.state.food
	check(game.open_remains() and game.pending.title=="The dead" and "Ben, dead of cholera" in game.pending.text,"The dead can be tended where they lie")
	check(command(game,"bury",1)>=0 and command(game,"carry",1)>=0 and command(game,"search",1)<0,"A companion can be buried or carried; the party's goods are already shared")
	check(game.state.food==food,"Opening the list costs nothing")
	var restored=round_trip(store,game)
	check(restored!=null and restored.pending.get("remains_menu",false),"An open list of the dead restores")
	check(game.choose(game.pending.choices.size()-1) and game.pending.is_empty(),"Back returns to the trail")
	# Carrying weighs what a body weighs, and the body travels with the party.
	var cargo: float=game.provisions.cargo(game.state)
	check(game.open_remains() and act(game,"carry",1) and body.state=="carried" and game.state.remains_lb==150 and is_equal_approx(game.provisions.cargo(game.state),cargo+150),"A carried body is real cargo")
	check(round_trip(store,game)!=null,"A carried body round-trips through saves")
	game.choose(game.pending.choices.size()-1)
	go(game,2)
	check(game.state.miles>mile and game.open_remains() and command(game,"set_down",1)>=0,"A carried body is within reach after travel")
	var day: int=game.state.day
	check(act(game,"bury",1) and body.state=="buried" and body.mile==game.state.miles and game.state.remains_lb==0 and game.state.day==day+1,"Burial takes a day and frees the cargo")
	check(command(game,"bury",1)<0 and command(game,"disturb",1)>=0,"A grave cannot be dug twice")
	game.choose(game.pending.choices.size()-1)
	var grave_mile: int=game.state.miles
	go(game,4)
	check(game.state.miles>grave_mile and not game.open_remains(),"A grave left behind is out of reach")
	# Opening a grave: those close to the dead take it hardest; the callous do not care.
	game=party(["Compassionate","Compassionate","Compassionate","Ruthless"],[{"a":1,"b":2,"kind":"family"}])
	kill(game,2)
	game.open_remains()
	act(game,"bury",1)
	var trust: Array=[]
	for profile in game.characters.profiles:trust.append(float(profile.trust))
	check(act(game,"disturb",1) and game.crime.record.remains[0].state=="lying" and game.crime.record.remains[0].disturbed,"A grave can be opened")
	var profiles: Array=game.characters.profiles
	check(profiles[1].trust==trust[1]-12 and profiles[1].memories.back().get("remains_id",0)==1,"Family of the dead take an opened grave as a grievous wrong")
	check(profiles[3].trust<trust[3] and profiles[3].trust>trust[3]-12,"Others object less")
	check(profiles[4].trust==trust[4],"The Ruthless do not care")
	check(act(game,"bury",1) and game.crime.record.remains[0].state=="buried" and game.crime.record.remains[0].disturbed,"A reburied grave remembers it was opened")
	check(round_trip(store,game)!=null,"An opened grave and its memories round-trip")
	game.choose(game.pending.choices.size()-1)
	var saved: Dictionary=store.capture(game)
	var bad: Dictionary=saved.duplicate(true)
	bad.crime.record.remains[0].disturbed=false
	check(store.restore(bad)==null,"A remembered desecration cannot be erased from the ledger")
	bad=saved.duplicate(true)
	bad.crime.record.remains.append(bad.crime.record.remains[0].duplicate())
	bad.crime.record.remains[1].id=2
	check(store.restore(bad)==null,"Nobody has two bodies")
	bad=saved.duplicate(true)
	bad.crime.record.remains[0].person=game.crime.person_id(57,3)
	check(store.restore(bad)==null,"The living have no remains")
	bad=saved.duplicate(true)
	bad.crime.record.remains[0].state="carried"
	check(store.restore(bad)==null,"A carried body must weigh on the cargo")
	bad.state.remains_lb=150
	check(store.restore(bad)!=null,"A carried body with its weight is consistent")
	bad=saved.duplicate(true)
	bad.crime.record.remains[0].mile=game.state.miles+1
	check(store.restore(bad)==null,"Nobody lies ahead of the party")
	# Older records: known deaths join the ledger, but nobody knows where they lie.
	bad=saved.duplicate(true)
	bad.crime.record.version=4
	for key in ["remains","human_food","meals"]:bad.crime.record.erase(key)
	for profile in bad.characters:profile.memories=profile.memories.filter(func(memory):return not memory.has("remains_id"))
	restored=store.restore(bad)
	check(restored!=null and restored.crime.record.remains.size()==1 and restored.crime.record.remains[0].state=="lost" and not restored.open_remains(),"A death from before the ledger is recorded as lost")
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-venues-save-v1.json"))
	restored=store.restore(previous)
	check(restored!=null and restored.crime.record.remains.size()==restored.party_health.members.filter(func(member):return not member.alive).size(),"Older saves gain only lost remains")
	# Strangers: a keeper killed in a robbery can be searched once, but not while the staff guard their dead.
	game=party()
	game.crime.record.actors[game.crime.owner_id("fort_kearny")].health=0
	game.crime.record.services["fort_kearny"].alarmed=true
	Remains.sync(game)
	var keeper: Dictionary=game.crime.record.remains[0]
	check(keeper.name.begins_with("the commissary sergeant") and keeper.goods_cents==250,"A stranger killed by the party enters the ledger")
	check(not game.open_remains(),"Surviving soldiers keep their own dead")
	for uid in game.crime.staff_ids("fort_kearny"):game.crime.record.actors[uid].health=0
	Remains.sync(game)
	var money: float=game.state.money
	check(game.crime.record.remains.size()==4 and game.open_remains() and act(game,"search",1) and is_equal_approx(game.state.money,money+2.5) and keeper.goods_cents==0,"With nobody left, the dead can be searched")
	check(command(game,"search",1)<0,"Belongings are taken only once")
	check(round_trip(store,game)!=null,"Dead strangers round-trip through saves")
	# The carry limit and wagon room both apply.
	game=party()
	game.state.food=300
	game.provisions.fresh.clear()
	for id in [1,2,3]:kill(game,id)
	game.open_remains()
	check(act(game,"carry",1) and act(game,"carry",2) and command(game,"carry",3)>=0 and not game.can_choose(command(game,"carry",3)),"No more than two bodies ride with the party")
	# Butchering openly: a separate batch that the ordinary ration never touches.
	game=party(["Compassionate","Compassionate","Compassionate","Ruthless"],[{"a":1,"b":2,"kind":"family"}])
	kill(game,2)
	food=game.state.food
	trust=[]
	for profile in game.characters.profiles:trust.append(float(profile.trust))
	game.open_remains()
	check(command(game,"butcher_open",1)>=0 and command(game,"butcher_secret",1)>=0,"A body can be butchered with a full wagon of food; hunger is not a gate")
	day=game.state.day
	check(act(game,"butcher_open",1) and game.crime.record.remains[0].state=="processed" and game.state.day==day+1,"Butchering takes a day")
	var meat: Dictionary=game.crime.record.human_food[0]
	check(meat.remains==1 and meat.pounds==40 and not meat.preserved and meat.known==[0,1,3,4],"Done openly, everyone with the wagon knows what the meat is")
	check(game.state.food<food and game.state.food>=food-5*int(game.provisions.data.rations_lb[game.state.rations]) and game.state.remains_lb==40,"The meat is kept apart from ordinary food and weighs on the cargo")
	profiles=game.characters.profiles
	check(profiles[1].trust==trust[1]-24 and profiles[3].trust==trust[3]-12 and profiles[4].trust==trust[4],"Those who forbid it object; family also grieve the body; the Ruthless shrug")
	check(profiles[3].memories.back().kind=="action_cannibalism" and profiles[3].memories.back().remains_id==1,"The objection is remembered once, for this body")
	check(command(game,"eat",0)>=0 and command(game,"offer",4)>=0 and not game.can_choose(command(game,"offer",1)) and command(game,"deceive",1)<0,"Those who know cannot be deceived, and those who forbid it refuse")
	check(round_trip(store,game)!=null,"Butchered remains and their meat round-trip")
	check(act(game,"eat",0) and act(game,"offer",4) and game.crime.record.meals=={"0":"informed","4":"informed"},"Each eater is chosen by name")
	var ration: int=int(game.provisions.data.rations_lb[game.state.rations])
	game.choose(game.pending.choices.size()-1)
	food=game.state.food
	var human: int=meat.pounds
	camp(game)
	check(game.crime.record.human_food[0].pounds==human-2*ration and game.state.food==food-ration*(game.state.party_size-2),"Chosen eaters eat the meat; everyone else eats ordinary food")
	saved=store.capture(game)
	check(store.restore(saved)!=null,"A meal plan round-trips")
	bad=saved.duplicate(true)
	bad.crime.record.meals["1"]="deceived"
	check(store.restore(bad)==null,"Someone who knows cannot be listed as deceived")
	bad=saved.duplicate(true)
	bad.crime.record.human_food[0].known=[0,1,4]
	bad.crime.record.meals["3"]="informed"
	check(store.restore(bad)==null,"Nobody eats it knowingly without being told")
	bad=saved.duplicate(true)
	bad.crime.record.human_food[0].pounds=41
	check(store.restore(bad)==null,"A body yields no more than it can")
	bad=saved.duplicate(true)
	bad.crime.record.remains[0].state="buried"
	check(store.restore(bad)==null,"Meat needs a butchered body")
	bad=saved.duplicate(true)
	bad.state.remains_lb=0
	check(store.restore(bad)==null,"Human meat weighs what it weighs")
	# Those who know remember it after the meat is gone, and an objector who leaves tells others.
	check(game.crime.record.remains[0].witnesses==[1,3,4],"Every companion who learned of the butchering is a witness")
	bad=saved.duplicate(true)
	bad.crime.record.remains[0].witnesses=[1,4]
	check(store.restore(bad)==null,"Someone who knows where the meat came from is a witness")
	bad=saved.duplicate(true)
	bad.crime.record.version=6
	for item in bad.crime.record.remains:item.erase("witnesses")
	restored=store.restore(bad)
	check(restored!=null and restored.crime.record.remains[0].witnesses==[1,3,4],"Older records take their witnesses from the meat still held")
	check(game.crime.tales(game).is_empty(),"Nobody tells anything while they stay")
	# Drying keeps it longer and lighter; it is still human meat.
	game.open_remains()
	check(act(game,"dry",1) and game.crime.record.human_food[0].preserved and game.state.remains_lb==ceili(game.crime.record.human_food[0].pounds*float(game.provisions.data.preservation.dried_weight)),"Dried human meat stays apart and weighs less")
	check(round_trip(store,game)!=null,"Dried human meat round-trips")
	var witness_day: int=game.state.day
	game._depart(game.plan_for([1,4]),"")
	var tales: Array=game.crime.tales(game)
	check(tales.size()==1 and tales[0].teller==1 and tales[0].remains==[1],"An objector who leaves tells what they saw; the Ruthless keep quiet")
	var origin: String=game.state.landmark
	check(game.crime.refuses(game,origin) and "Ada, who left your party" in game.crime.news_text(game,origin) and "butchered Ben's remains" in game.crime.news_text(game,origin),"The place they left hears it at once")
	check(not game.crime.refuses(game,"fort_boise"),"Distant posts have not heard yet")
	game.state.day=witness_day+200
	check(game.crime.refuses(game,"fort_boise"),"The story travels along the road")
	# In secret, served without telling: the deceived may find out.
	game=party(["Compassionate","Compassionate","Compassionate","Compassionate"])
	game.crime.remains_rules.secret_notice=0
	kill(game,2)
	game.open_remains()
	act(game,"butcher_secret",1)
	check(game.crime.record.human_food[0].known==[0] and game.characters.profiles[1].memories.is_empty(),"Unseen butchering is known only to the leader")
	check(act(game,"deceive",1) and game.crime.record.meals=={"1":"deceived"},"A companion can be served it without being told")
	check(round_trip(store,game)!=null,"Deception round-trips")
	game.choose(game.pending.choices.size()-1)
	game.crime.remains_rules.deceit_notice=1
	trust=[]
	for profile in game.characters.profiles:trust.append(float(profile.trust))
	camp(game)
	profiles=game.characters.profiles
	check(game.crime.record.meals.is_empty() and 1 in game.crime.record.human_food[0].known and profiles[1].trust==trust[1]-24,"Discovered deception is its own wrong, on top of the boundary")
	check(profiles[1].memories.any(func(memory):return memory.kind=="meal_deceived" and memory.remains_id==1),"The deception is remembered")
	check(game.journal.any(func(text):return "discovered" in text),"The discovery is announced")
	check(round_trip(store,game)!=null,"A discovered deception round-trips")
	# Unpreserved meat spoils; the meal plan ends with it.
	game.open_remains()
	act(game,"eat",0)
	game.choose(game.pending.choices.size()-1)
	for rest_day in range(int(game.provisions.data.fresh_days)+2):camp(game)
	check(game.crime.record.human_food.is_empty() and game.crime.record.meals.is_empty() and game.state.remains_lb==0 and game.journal.any(func(text):return "spoiled meat from Ben" in text),"Fresh human meat spoils and the plan ends")
	# A stranger's body can be butchered once nobody is left to stop it.
	game=party()
	for uid in game.crime.staff_ids("fort_kearny"):game.crime.record.actors[uid].health=0
	game.crime.record.services["fort_kearny"].alarmed=true
	Remains.sync(game)
	check(game.open_remains() and act(game,"butcher_open",1) and game.crime.record.human_food.size()==1,"A dead stranger can be butchered")
	check(round_trip(store,game)!=null,"A stranger's butchered remains round-trip")
	# Native UI.
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=party()
	kill(screen.game,1)
	screen._refresh()
	screen._open_remains()
	check(screen.service_window.visible and screen.service_window.title=="The dead","The dead are tended in the native UI")
	screen.queue_free()
	await process_frame
	print("Remains: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
