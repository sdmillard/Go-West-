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
func command(game,name: String,id: int) -> int:
	for index in range(game.pending.choices.size()):
		var choice: Dictionary=game.pending.choices[index]
		if choice.get("remains_command","")==name and int(choice.get("remains_id",0))==id:return index
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
	bad.crime.record.erase("remains")
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
