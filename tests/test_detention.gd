extends SceneTree
## Custody between capture and sentence: who holds the accused, the hearing, bail, vouching, jail days and prison.
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Wanted=preload("res://simulation/wanted_system.gd")
const Detention=preload("res://simulation/detention.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
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
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	for profile in game.characters.profiles.slice(1):
		profile.boundaries=game.characters.catalog.boundaries("Opportunistic")
		profile.trust=80
	return game
func at(game,place: String):
	game.state.next_landmark=place
	game._arrive_landmark()
	game.state.miles=int(game.route.node_miles()[place])
	return game
func odds(game,value: float) -> void:
	for key in game.crime.detention_data.conviction:game.crime.detention_data.conviction[key]=value
func pick(game,command: String) -> bool:
	for index in range(game.pending.get("choices",[]).size()):
		if game.pending.choices[index].get("crime_command","")==command:return game.choose(index)
	return false
func offers(game,command: String) -> bool:
	return game.pending.get("choices",[]).any(func(choice):return choice.get("crime_command","")==command)
func roundtrip(game,label: String) -> void:
	var store=Store.new()
	var snapshot: Dictionary=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null,label+" restores")
	if copy!=null:check(store.capture(copy)==snapshot,label+" restores exactly")
## A theft at the Independence store, caught in the act.
func town_theft(seed_value: int=57):
	var game=at(outfit(seed_value),"independence")
	check(game.state.landmark=="independence" and game.open_crime("independence"),"The Independence store can be targeted")
	game.crime.scenes.independence.theft_success=0
	pick(game,"theft")
	pick(game,"surrender")
	return game
func town_robbery():
	var game=at(outfit(),"independence")
	game.crime.scenes.independence.compliance=1
	game.open_crime("independence")
	pick(game,"robbery")
	game.crime.result(game,"captured")
	return game
func run() -> void:
	# Missouri: the county jail and court day.
	var game=town_theft()
	var current: Dictionary=game.crime.incident()
	check(current.stage=="custody" and current.custody.authority=="county","A capture in Independence goes to the Jackson County jail")
	check(current.custody.hearing_day==int(game.state.day)+3 and current.custody.accused==[0]+current.joining.filter(func(id):return int(id)>0),"Court sits in three days; the leader and those who took part are held")
	check(not game.travel() and not game.rest(),"Custody cannot be bypassed")
	check(offers(game,"bail") and offers(game,"wait") and not offers(game,"vouch"),"County custody offers waiting and bail; nobody who took part can vouch")
	roundtrip(game,"County custody")
	var store=Store.new()
	var bad: Dictionary=store.capture(game)
	bad.crime.record.incidents.back().custody.hearing_day+=5
	check(store.restore(bad)==null,"A save cannot postpone the hearing")
	bad=store.capture(game)
	bad.crime.record.incidents.back().custody.authority="company"
	check(store.restore(bad)==null,"A save cannot move the case to another authority")
	bad=store.capture(game)
	bad.crime.record.incidents.back().custody.accused=[0,0]
	check(store.restore(bad)==null,"The accused cannot be duplicated")
	# Bail: security that is forfeited when the party leaves Missouri.
	var money: float=game.state.money
	var cents: int=Detention.bail_cents(game.crime,Wanted.trial_charges(game.crime,game,current))
	check(cents==1000,"Bail for a small theft is the authored minimum")
	check(pick(game,"bail") and current.sentence.kind=="bailed" and is_equal_approx(game.state.money,money-cents/100.0),"Posting bail costs exactly the bail")
	check(current.stage=="report" and game.state.status=="traveling","Bail frees the accused at once")
	roundtrip(game,"Bail forfeited")
	check(pick(game,"finish") and Wanted.eligible(game.crime,game).is_empty(),"A forfeited bail answers the charge; the posse does not come back for it")
	# Waiting for court and a fine that cannot be paid.
	game=town_theft()
	current=game.crime.incident()
	odds(game,1.0)
	game.state.money=0
	var day: int=int(game.state.day)
	check(pick(game,"wait") and current.sentence.kind=="fine" and current.sentence.authority=="county","A conviction in the county court is a fine")
	check(current.sentence.jail_days>0 and int(game.state.day)==day+3+int(current.sentence.jail_days),"An unpaid fine is served in the county jail, a day at a time")
	check(game.state.status=="traveling" and game.party_health.members[0].alive,"Jail time does not end the journey")
	roundtrip(game,"Fine worked off in jail")
	# A fine the party can pay costs no jail time.
	game=town_theft()
	current=game.crime.incident()
	odds(game,1.0)
	check(pick(game,"wait") and current.sentence.kind=="fine" and current.sentence.jail_days==0 and current.sentence.cents==int(game.crime.detention_data.fine_min_cents),"A paid fine needs no jail time; a theft caught empty-handed still draws the smallest fine")
	# Thin evidence and a companion's word.
	game=town_theft()
	current=game.crime.incident()
	# Only the leader took part this time; the others stayed with the wagon.
	current.joining=[0]
	current.custody.accused=[0]
	game.pending=game.crime.menu(game)
	var known: Array=Wanted.trial_charges(game.crime,game,current)
	var base: float=Detention.conviction_chance(game.crime,current,known)
	check(pick(game,"vouch") and current.custody.vouched>0 and not offers(game,"vouch"),"One companion can speak for the accused, once")
	check(is_equal_approx(Detention.conviction_chance(game.crime,current,known),base-float(game.crime.detention_data.vouch_bonus)),"A companion's word lowers the odds of conviction")
	roundtrip(game,"Vouched custody")
	odds(game,0.0)
	check(pick(game,"wait") and current.sentence.kind=="discharged" and current.sentence.cents==0,"Weak evidence discharges the accused without payment")
	check(pick(game,"finish") and Wanted.eligible(game.crime,game).is_empty(),"A discharged charge is not tried again")
	# Companions who object to the crime will not vouch.
	game=town_theft()
	for profile in game.characters.profiles.slice(1):profile.boundaries=game.characters.catalog.boundaries("Compassionate")
	game.pending=game.crime.menu(game)
	check(not offers(game,"vouch") or Detention.voucher(game,game.crime.incident(),[])>0,"Only a willing companion can vouch")
	# Companions may give up on a jailed leader; Loyal ones never do.
	game=town_theft()
	current=game.crime.incident()
	current.joining=[0]
	current.custody.accused=[0]
	odds(game,0.0)
	game.crime.detention_data.abandon_daily=1.0
	for profile in game.characters.profiles.slice(1):profile.trust=10
	game.characters.profiles[1].specials=["Loyal"]
	game.pending=game.crime.menu(game)
	check("give up and leave" in game.pending.text,"The custody panel warns that companions may leave")
	check(pick(game,"wait") and current.custody.abandoned==[2,3,4] and game.party_health.members[1].get("departed",false)==false,"Companions with little trust leave a jailed leader; a Loyal one stays")
	check([2,3,4].all(func(id):return game.party_health.members[id].get("fled",false)) and game.state.status=="traveling","Those who left are departed, and the journey goes on")
	roundtrip(game,"Abandoned while in jail")
	bad=store.capture(game)
	bad.crime.record.incidents.back().custody.abandoned=[1,2,3,4]
	check(store.restore(bad)==null,"A save cannot list a companion who stayed as having left")
	game=town_theft()
	game.crime.detention_data.abandon_daily=1.0
	check(Detention.abandon_chance(game.crime,{"trust":100})==0.0 and is_equal_approx(Detention.abandon_chance(game.crime,{"trust":50}),1.0),"Full trust never abandons; the chance grows as trust falls")
	# Robbery in Missouri: the penitentiary. The leader is the player; the journey ends.
	game=town_robbery()
	current=game.crime.incident()
	check(current.stage=="custody" and current.custody.authority=="county","A robbery in Independence is held for the county court")
	odds(game,1.0)
	check(pick(game,"wait") and current.sentence.kind=="penitentiary" and 0 in current.sentence.imprisoned,"Robbery in Missouri means the penitentiary")
	check(game.state.status=="lost" and game.state.loss_reason==Detention.LOSS.penitentiary,"A leader sent to the penitentiary ends the journey")
	roundtrip(game,"Penitentiary")
	# A companion who answers for the party goes to prison; the rest go on.
	game=town_robbery()
	current=game.crime.incident()
	# Journeys saved before the leader-death rule let a companion take over.
	game.state.leader_succession=true
	game.party_health.kill(game.party_health.members[0],int(game.state.day),"confrontation injuries")
	game._collect_health_events()
	odds(game,1.0)
	var acting: int=Detention.acting_leader(game)
	current.custody.accused=[acting]
	check(pick(game,"wait") and acting in current.sentence.imprisoned and game.party_health.members[acting].get("departed",false),"A companion sent to the penitentiary leaves the party alive")
	check(game.state.status=="traveling" and game.party_health.members[acting].departure_supplies.food==0,"The prisoner takes nothing from the wagon and the others continue")
	roundtrip(game,"Companion in the penitentiary")
	# Regulators west of Missouri hear the case the next day.
	game=at(outfit(),"fort_bridger")
	game.crime.scenes.fort_bridger.compliance=1
	game.open_crime()
	pick(game,"robbery")
	game.crime.result(game,"captured")
	current=game.crime.incident()
	check(current.custody.authority=="company" and current.custody.hearing_day==int(game.state.day)+1 and not offers(game,"bail"),"A trading-post capture goes to an emigrant jury the next day, with no bail")
	odds(game,1.0)
	check(pick(game,"wait") and current.sentence.kind=="robbery" and game.state.status=="traveling","An emigrant jury keeps the frontier sentence for robbery")
	roundtrip(game,"Emigrant jury")
	# Version 9 sentences are kept as they were.
	game=outfit()
	var legacy: Dictionary=game.crime.snapshot()
	legacy.record.version=9
	var upgraded: Dictionary=game.crime.upgrade(legacy,game)
	check(upgraded.record.version==10 and game.crime.valid(upgraded,game) and upgraded.random==legacy.random,"v9 records upgrade to v10 without consuming randomness")
	# The custody panel reaches the graphical service window.
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.game=town_theft()
	screen._refresh()
	screen._show_service()
	await process_frame
	check(screen.service_window.visible and screen.service_rows.get_children().any(func(node):return node is Button and node.text.to_lower().begins_with("wait for the hearing")),"Custody reaches the existing graphical panel")
	screen.queue_free()
	await process_frame
	print("Detention: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
