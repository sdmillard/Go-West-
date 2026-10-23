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
## Turns the companion in a slot against the party: allowed to betray, trust at zero.
func turn(game,slot: int) -> void:
	var profile: Dictionary=game.characters.profiles[slot]
	profile.can_betray=true
	profile.trust=0
func betrayal(store) -> void:
	# Theft in the night, unnoticed: the thief takes a share of the stores and is gone.
	var game=party(["Opportunistic","Compassionate","Compassionate","Compassionate"])
	var rules: Dictionary=game.crime.companion_rules.betrayal
	var random: String=str(game.crime.rng.state)
	game.crime.check_betrayal(game)
	check(not game.crime.betrayer(game,1) and str(game.crime.rng.state)==random,"Nobody near the betrayal point: no roll, no betrayal")
	game.characters.profiles[2].trust=0
	check(not game.crime.betrayer(game,2),"A companion who could never betray does not, however low their trust")
	turn(game,1)
	check(game.crime.betrayer(game,1) and "capable of betrayal" in game.characters.warning(1),"The betrayal point is the warning View Party already shows")
	rules.daily=1
	rules.notice=0
	var food: int=game.state.food
	var cents: int=roundi(game.state.money*100)
	var bullets: int=game.state.bullets
	game.crime.check_betrayal(game)
	var item: Dictionary=game.crime.record.betrayals[0]
	check(item.act=="theft" and item.attempt=="stole" and item.member==1 and item.noticed.is_empty(),"An opportunist robs the wagon when nobody wakes")
	check(item.taken=={"food":int(food*0.25),"cents":int(cents*0.5),"bullets":int(bullets*0.25)} and roundi(game.state.money*100)==cents-item.taken.cents and game.state.bullets==bullets-item.taken.bullets,"The thief takes the authored shares of food, cash and bullets")
	check(game.state.food<food-item.taken.food and game.party_health.members[1].get("fled",false) and game.state.party_size==4,"The thief also leaves with the usual flight share")
	check(game.health_events.any(func(text):return "Ada robbed the wagon" in text),"The party hears of it")
	check(round_trip(store,game),"A betrayal round-trips through saves")
	var saved: Dictionary=store.capture(game)
	var bad: Dictionary=saved.duplicate(true)
	bad.crime.record.betrayals=[]
	check(store.restore(bad)==null,"Flight needs a cause: an attack or a betrayal")
	bad=saved.duplicate(true)
	bad.crime.record.betrayals[0].attempt="stopped"
	check(store.restore(bad)==null,"A stopped theft takes nothing, and needs someone who woke")
	bad=saved.duplicate(true)
	bad.crime.record.betrayals.append(bad.crime.record.betrayals[0].duplicate(true))
	bad.crime.record.betrayals[1].id=2
	check(store.restore(bad)==null,"Nobody betrays the party twice")
	var old: Dictionary=game.crime.snapshot()
	old.record.version=7
	old.record.erase("betrayals")
	var upgraded: Variant=game.crime.upgrade(old,game)
	check(upgraded.record.version==game.crime.VERSION and upgraded.record.betrayals.is_empty(),"Version 7 records gain an empty betrayal list")
	# Someone wakes: the theft is stopped, but the thief still runs.
	game=party(["Opportunistic","Compassionate","Compassionate","Compassionate"])
	turn(game,1)
	game.crime.companion_rules.betrayal.daily=1
	game.crime.companion_rules.betrayal.notice=1
	cents=roundi(game.state.money*100)
	game.crime.check_betrayal(game)
	item=game.crime.record.betrayals[0]
	check(item.attempt=="stopped" and item.noticed==[2,3,4] and item.taken=={"food":0,"cents":0,"bullets":0} and roundi(game.state.money*100)==cents and game.party_health.members[1].get("fled",false),"Anyone who wakes stops the theft; the thief runs empty-handed")
	check(round_trip(store,game),"A stopped theft round-trips")
	# The ruthless shoot the leader first, then take what they can.
	game=party(["Ruthless","Ruthless","Ruthless","Ruthless"])
	turn(game,2)
	game.crime.companion_rules.betrayal.daily=1
	game.crime.companion_rules.betrayal.ambush_hit=1
	game.crime.companion_rules.betrayal.guard_step=0
	game.crime.companion_rules.fatal=1
	bullets=game.state.bullets
	game.crime.check_betrayal(game)
	item=game.crime.record.betrayals[0]
	check(item.act=="attack" and item.attempt=="killed" and not game.party_health.members[0].alive and "Ben" in game.party_health.members[0].cause,"A ruthless betrayer can kill the leader; the cause names them")
	check(item.noticed==[1,3,4] and game.state.bullets==bullets-1-item.taken.bullets and game.state.status=="traveling","The shot wakes the camp; the journey goes on without its leader")
	check(round_trip(store,game),"A killing betrayal round-trips")
	saved=store.capture(game)
	bad=saved.duplicate(true)
	bad.crime.record.betrayals[0].attempt="missed"
	check(store.restore(bad)==null,"A killing cannot be rewritten as a miss")
	game=party(["Ruthless","Ruthless","Ruthless","Ruthless"])
	turn(game,2)
	game.crime.companion_rules.betrayal.daily=1
	game.crime.companion_rules.betrayal.ambush_hit=0.3
	game.crime.companion_rules.betrayal.guard_step=0.1
	game.crime.check_betrayal(game)
	check(game.crime.record.betrayals[0].act=="attack" and game.crime.record.betrayals[0].attempt=="missed","Companions willing to defend the wagon spoil the shot")
	# It happens on the trail at night, through the ordinary day.
	game=party(["Opportunistic","Compassionate","Compassionate","Compassionate"])
	turn(game,1)
	game.crime.companion_rules.betrayal.daily=1
	game.rest()
	check(game.crime.record.betrayals.size()==1 and game.crime.record.betrayals[0].day==game.state.day,"A night in camp can bring the betrayal")
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
	check(game.choose(game.pending.choices.size()-1) and store.capture(game)==before,"Backing out of an attack changes nothing")
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
	var tellers: Array=game.crime.tales(game).map(func(told):return [told.teller,told.attacks])
	check(tellers==[[1,[1]],[3,[1]],[4,[1]]],"Everyone who fled tells others about the killing")
	game.state.day+=200
	check(game.crime.refuses(game,"fort_hall") and "has told people here that you shot at Ben" in game.crime.news_text(game,"fort_hall"),"Posts ahead hear it from them and refuse the party")
	game.state.day-=200
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
	# Without a bullet an unarmed attack is still available.
	game=party(["Ruthless","Ruthless","Ruthless","Ruthless"])
	game.state.bullets=0
	check(game.open_attack(1) and not game.can_choose(0) and game.can_choose(1),"Without bullets only unarmed attack is available")
	game.choose(game.pending.choices.size()-1)
	game.state.bullets=5
	check(not game.open_attack(0) and not game.open_attack(9),"Only a companion with the party can be attacked")
	betrayal(store)
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=party(["Ruthless","Ruthless","Ruthless","Ruthless"])
	screen._refresh()
	screen._select_member(2)
	check(screen.attack_button.visible and not screen.attack_button.disabled and screen.attack_button.text=="ATTACK BEN","The party view offers the attack for a companion")
	screen._attack_selected()
	check(screen.service_window.visible and screen.service_window.title=="Attack Ben","The attack menu opens in the native UI")
	screen.game.crime.companion_rules.hit=0
	screen._service_choice(0)
	check(screen.record_notice.visible and screen.record_notice.title=="YOU SHOT AT BEN" and "You shot at Ben: missed." in screen.record_notice.dialog_text and "Fled: Ben. They took " in screen.record_notice.dialog_text and not "(trust" in screen.record_notice.dialog_text,"The result of the shot is shown at once: the miss and who left")
	check(screen.record_notice.size.x<=640 and screen.record_notice.size.y<=330,"The shot notice fits the 640 x 360 screen")
	check("Joined you: Ada, Cora, Dell." in screen.record_notice.dialog_text,"Those who joined are named too")
	screen.record_notice.hide()
	screen.game=party(["Ruthless","Ruthless","Ruthless","Ruthless"])
	screen._refresh()
	screen._select_member(2)
	screen._attack_selected()
	screen._service_choice(1)
	check(screen.record_notice.title=="YOU ATTACKED UNARMED BEN" and "No ammunition used." in screen.record_notice.dialog_text and not "One bullet used" in screen.record_notice.dialog_text,"Unarmed result names the method and correct ammunition cost")
	screen.record_notice.hide()
	screen.queue_free()
	await process_frame
	print("Companions: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
