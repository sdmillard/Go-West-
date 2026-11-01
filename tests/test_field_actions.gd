extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Store = preload("res://simulation/save_store.gd")
var failures := 0
var checks := 0
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func party(seed_value: int = 57):
	var game = Simulation.new(seed_value,"classic",true)
	var cart := {}
	for good in game.outfitter.goods: cart[good.id] = int(good.suggested)
	game.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	game.pending={}
	return game
func restored(game): return Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(game))))
func run():
	var game = party()
	var preview: Dictionary = Store.new().capture(game)
	check(game.open_forage(),"Foraging is available from camp")
	check(restored(game)!=null,"A foraging confirmation can be saved")
	check(game.choose(1) and Store.new().capture(game)==preview,"Canceling forage spends no day or RNG")
	var copy = party()
	game.open_forage()
	copy.open_forage()
	game.choose(0)
	copy.choose(0)
	check(game.state.day==1 and game.state.bullets==preview.state.bullets,"Foraging uses a day and no bullets")
	check(Store.new().capture(game)==Store.new().capture(copy),"Foraging is seeded and repeatable")
	check(game.provisions.fresh.any(func(batch):return batch.get("vitamin_c",false)),"Search gathers produce into the food ledger")
	check(restored(game)!=null,"Foraged produce round-trips with physical weight")
	game=party()
	game.party_health.days_without_fresh=60
	game.provisions.fresh.assign([{"pounds":100,"expires":2,"preserved":true},{"pounds":2,"expires":5,"mass_ratio":4.0,"vitamin_c":true}])
	game._tick_day(true)
	check(game.party_health.days_without_fresh==53 and game.provisions.fresh.back().pounds==1,"Meals share produce alongside dried meat and gradually restore depleted reserves")
	game=party()
	game.provisions.add_produce(8,0)
	game.state.food+=2
	game.party_health.days_without_fresh=60
	game._tick_day(true)
	check(game.party_health.days_without_fresh==53,"Actually eaten produce reduces deficiency without erasing its history")
	game=party()
	game.provisions.add_produce(8,0)
	check(game.provisions.processable()==0,"Meat drying does not process greens")
	check(game.provisions.spoil(4,game.state.food)==2,"Foraged produce spoils")
	game=party()
	game.state.departure_month=12
	check(not game.forage_offer().available,"Winter prevents gathering")
	game=party()
	for member in game.party_health.members: game.party_health.begin_condition(int(member.id),"broken_leg",0)
	check(not game.forage_offer().available,"A party with broken legs cannot forage")
	game=party()
	game.state.next_landmark="fort_bridger"
	game._arrive_landmark()
	game.open_crime()
	var legacy: Dictionary=Store.new().capture(game)
	legacy.rules="6f43bd401602cc22a233f5c087cd5bb07cd954b56eb63bbe94c51d5bf94100f3"
	legacy.pending.choices=legacy.pending.choices.filter(func(choice):return choice.crime_command!="assault")
	check(Store.new().restore(JSON.parse_string(JSON.stringify(legacy)))!=null,"Previous-rules open crime menu migrates with the new unarmed choice")
	game=party()
	game.provisions.add_produce(8,0)
	var bad: Dictionary=Store.new().capture(game)
	bad.fresh[0].vitamin_c="yes"
	check(Store.new().restore(bad)==null,"Invalid nutrition tag is rejected")
	var mishaps := 0
	for seed_value in range(40):
		game=party(seed_value)
		game.state.bullets=0
		check(game.open_attack(4),"Attack opens without ammunition")
		check(not game.can_choose(0) and game.can_choose(1),"Unarmed attack selectable without bullets; shot disabled")
		check(restored(game)!=null,"Unarmed companion preview round-trips")
		game.choose(1)
		check(game.state.bullets==0 and game.crime.record.attacks.back().weapon=="unarmed","Unarmed attack records method without consuming bullets")
		check(restored(game)!=null,"Companion unarmed outcomes round-trip")
		if game.journal.any(func(line):return "Hurt in the unarmed struggle" in line): mishaps+=1
		game=party(seed_value)
		game.state.next_landmark="fort_bridger"
		game._arrive_landmark()
		var bullets: int=game.state.bullets
		game.open_crime()
		var index: int=game.pending.choices.find_custom(func(choice):return choice.crime_command=="assault")
		game.crime.forced_strike="fight"
		check(index>=0 and game.choose(index),"Unarmed venue attack is selectable even with bullets")
		check(game.state.bullets==bullets and game.state.day==1,"Venue assault costs one day and no ammunition")
		check(restored(game)!=null,"Venue assault witnesses and outcomes round-trip")
	check(mishaps>0 and mishaps<40,"Unarmed attacks exercise the additional mishap risk")
	print("Field actions: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
