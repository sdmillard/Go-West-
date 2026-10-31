extends SceneTree
## The leader is the player: their death ends the journey. Older journeys where a companion already took over keep going.
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit():
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	return game
func run() -> void:
	var game=outfit()
	game.party_health.kill(game.party_health.members[1],int(game.state.day),"cholera")
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	game._check_health()
	check(game.state.status=="traveling","A companion's death does not end the journey")
	game.party_health.kill(game.party_health.members[0],int(game.state.day),"cholera")
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	game._check_health()
	check(game.state.status=="lost" and game.state.loss_reason=="A, the party's leader, died of cholera. The journey is over.","The leader's death ends the journey even with companions alive")
	check(not game.travel() and not game.rest(),"Nobody travels on after the leader dies")
	var store=Store.new()
	check(store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null,"A journey ended by the leader's death saves and loads")
	# A journey saved under the older rule, with a companion already leading.
	game=outfit()
	game.state.leader_succession=true
	game.party_health.kill(game.party_health.members[0],int(game.state.day),"cholera")
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	var snapshot: Dictionary=store.capture(game)
	snapshot.state.erase("leader_succession")
	var legacy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(legacy!=null and legacy.state.status=="traveling" and legacy.state.get("leader_succession",false),"An older journey led by a companion keeps going")
	if legacy!=null:
		legacy.party_health.daily_onset_chance=0
		legacy.survival.forced_weather="clear"
		legacy.survival.data.event_chance=0
		check(legacy.rest() and legacy.state.status=="traveling","It goes on after the next day")
		var copy: Dictionary=store.capture(legacy)
		check(store.restore(JSON.parse_string(JSON.stringify(copy)))!=null,"The older rule survives another save")
	snapshot=store.capture(outfit())
	snapshot.state.leader_succession=true
	check(store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null,"A save cannot claim a successor while the leader lives")
	print("Leader death: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
