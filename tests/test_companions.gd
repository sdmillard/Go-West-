extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
## A party on the road with chosen temperaments and values, and chosen bonds.
func party(values: Array,bonds: Array=[],temperaments: Array=["Cautious","Cautious","Cautious","Cautious"],seed_value: int=57):
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
		profile.traits=[temperaments[index-1],values[index-1]]
		profile.boundaries=game.characters.catalog.boundaries(values[index-1])
	game.crime.record.bonds=bonds
	return game
func attack(game,target: int) -> bool:
	return game.open_attack(target) and game.choose(0)
func round_trip(store,game) -> bool:
	return store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))!=null
func run():
	var store=Store.new()
	# Bonds: drawn once per new journey, sparse, at most one partner each.
	var kinds: Dictionary={}
	for seed_value in range(60):
		var game=Simulation.new(seed_value,"classic",true)
		var cart: Dictionary={}
		for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
		game.depart("banker",["A","B","C","D","E"],5,cart)
		for item in game.crime.record.bonds:kinds[item.kind]=int(kinds.get(item.kind,0))+1
		check(game.crime.valid(game.crime.snapshot(),game),"Generated bonds validate")
		if seed_value==7:
			var again=Simulation.new(seed_value,"classic",true)
			again.depart("banker",["A","B","C","D","E"],5,cart)
			check(again.crime.record.bonds==game.crime.record.bonds,"The same journey draws the same bonds")
			check(again.crime.rng.state==Simulation.new(seed_value,"classic",true).crime.rng.state,"Drawing bonds does not disturb the crime random stream")
	for kind in ["family","partner","friend","rival"]:check(kinds.has(kind),"Sample journeys include %s bonds" % kind)
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-venues-save-v1.json"))
	var restored=store.restore(previous)
	check(restored!=null and restored.crime.record.bonds.is_empty() and restored.crime.record.attacks.is_empty(),"Older saves gain no invented bonds")
	# The menu is pure and shows who joins and who refuses.
	var game=party(["Ruthless","Compassionate","Ruthless","Ruthless"],[{"a":1,"b":2,"kind":"family"}])
	var before: Dictionary=store.capture(game)
	check(game.open_attack(2) and game.pending.title=="Attack Ben" and "Joining you: Lead, Cora, Dell" in game.pending.text and "Refusing: Ada" in game.pending.text and "Ada and Ben: family" in game.pending.text,"The attack menu names the target, helpers, refusers and bonds")
	check(round_trip(store,game),"An open attack menu restores")
	check(game.choose(1) and store.capture(game)==before,"Backing out of an attack changes nothing")
	# A killing: the bold family member fights back and leaves; objectors who saw a death flee.
	game=party(["Ruthless","Compassionate","Compassionate","Compassionate"],[{"a":1,"b":2,"kind":"family"}],["Bold","Cautious","Cautious","Cautious"])
	game.crime.companion_rules.hit=1
	game.crime.companion_rules.fatal=1
	game.crime.companion_rules.retaliate_hit=1
	var bullets: int=game.state.bullets
	var food: int=game.state.food
	var leader: int=game.party_health.members[0].health
	check(attack(game,2),"The leader can shoot a companion")
	var record: Dictionary=game.crime.record.attacks[0]
	check(record.attempt=="killed" and not game.party_health.members[2].alive and "Lead" in game.party_health.members[2].cause,"The target can be killed, and the cause names the killer")
	check(game.state.bullets==bullets-1 and game.state.day==0,"An attack spends one bullet and no day")
	check(record.responses=={"1":"retaliated","3":"fled","4":"fled"},"Family fights back; objectors who saw a killing flee")
	check(game.party_health.members[0].health==leader-30,"The retaliating relative wounds the leader")
	check(game.party_health.members[1].get("fled",false) and game.party_health.members[3].get("fled",false) and game.state.party_size==1,"Those who leave are gone at once, away from any settlement")
	check(game.state.food<food,"Those who flee take food with them")
	check(game.characters.profiles[1].memories.back().get("attack_id",0)==1,"Each witness remembers the attack itself")
	check(round_trip(store,game),"A killing and its flight round-trip through saves")
	var saved: Dictionary=store.capture(game)
	var bad: Dictionary=saved.duplicate(true)
	bad.crime.record.attacks=[]
	check(store.restore(bad)==null,"Flight cannot exist without the attack that caused it")
	bad=saved.duplicate(true)
	bad.crime.record.attacks[0].attempt="missed"
	check(store.restore(bad)==null,"A killing cannot be rewritten as a miss")
	bad=saved.duplicate(true)
	bad.crime.record.bonds.append({"a":3,"b":4,"kind":"partner"})
	bad.crime.record.bonds.append({"a":1,"b":3,"kind":"partner"})
	check(store.restore(bad)==null,"Nobody has two partners")
	# A miss: the target leaves; objectors who saw only an attempt object and stay; a rival is unmoved.
	game=party(["Compassionate","Compassionate","Compassionate","Ruthless"],[{"a":1,"b":2,"kind":"rival"}])
	game.crime.companion_rules.hit=0
	var rival: float=game.characters.profiles[1].trust
	var objector: float=game.characters.profiles[3].trust
	check(attack(game,2) and game.crime.record.attacks[0].attempt=="missed" and game.party_health.members[2].alive,"A miss leaves the target alive")
	check(game.crime.record.attacks[0].responses=={"1":"stood by","2":"fled","3":"objected"},"The target flees; a rival stands by; an objector stays after a failed attempt")
	check(game.characters.profiles[1].trust==rival and game.characters.profiles[3].trust<objector,"A rival does not lose trust; an objector does")
	check(game.party_health.members[2].get("fled",false) and game.party_health.members[2].history.back().contains("fled after you shot at Ben"),"The target's own history says why they left")
	check(attack(game,3) and game.characters.profiles[3].memories.filter(func(memory):return memory.get("attack_id",0)>0).size()==2,"A second attack the same day is remembered separately")
	check(round_trip(store,game),"Two attacks round-trip through saves")
	# Without a bullet there is no attack.
	game=party(["Ruthless","Ruthless","Ruthless","Ruthless"])
	game.state.bullets=0
	check(not game.open_attack(1),"No bullets, no attack")
	game.state.bullets=5
	check(not game.open_attack(0) and not game.open_attack(9),"Only a companion with the party can be attacked")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=party(["Ruthless","Ruthless","Ruthless","Ruthless"])
	screen._refresh()
	screen._select_member(2)
	check(screen.attack_button.visible and not screen.attack_button.disabled and screen.attack_button.text=="SHOOT BEN","The party view offers the attack for a companion")
	screen._attack_selected()
	check(screen.service_window.visible and screen.service_window.title=="Attack Ben","The attack menu opens in the native UI")
	screen.queue_free()
	await process_frame
	print("Companions: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
