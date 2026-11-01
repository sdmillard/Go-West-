extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Wanted=preload("res://simulation/wanted_system.gd")
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
	game.state.next_landmark="fort_bridger"
	game._arrive_landmark()
	game.state.miles=int(game.route.node_miles().fort_bridger)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	for profile in game.characters.profiles.slice(1):
		profile.boundaries=game.characters.catalog.boundaries("Opportunistic")
		profile.trust=80
	return game
func pick(game,command: String) -> bool:
	for index in range(game.pending.get("choices",[]).size()):
		if game.pending.choices[index].get("crime_command","")==command:return game.choose(index)
	return false
func robbery(seed_value: int=57):
	var game=outfit(seed_value)
	game.crime.scenes.fort_bridger.compliance=1
	game.crime.scenes.fort_bridger.escape_capture=0
	game.crime.scenes.fort_bridger.escape_injury=0
	check(game.open_crime() and pick(game,"robbery") and pick(game,"take") and pick(game,"flee") and pick(game,"finish"),"Prepare a witnessed robbery through public actions")
	return game
func violence(killed: bool=false):
	var game=outfit()
	game.crime.scenes.fort_bridger.shot_hit=1
	game.crime.scenes.fort_bridger.shot_fatal=1 if killed else 0
	game.crime.scenes.fort_bridger.escape_capture=0
	game.crime.scenes.fort_bridger.escape_injury=0
	game.open_crime()
	pick(game,"shoot")
	if game.crime.incident().stage=="loot":pick(game,"flee")
	elif game.crime.incident().stage=="escape":pick(game,"flee")
	pick(game,"finish")
	return game
## Custody comes before every sentence. Tests force a conviction unless they set the odds themselves.
func hear(game,odds: float=1.0) -> bool:
	for key in game.crime.detention_data.conviction:game.crime.detention_data.conviction[key]=odds
	return game.crime.incident().get("stage","")=="custody" and pick(game,"wait")
func roundtrip(game,label: String) -> void:
	var store=Store.new()
	var snapshot: Dictionary=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null,label+" restores")
	if copy!=null:check(store.capture(copy)==snapshot,label+" restores exactly")
func run() -> void:
	var game=outfit()
	check(game.error.is_empty() and game.crime.record.version==10,"Wanted rules and v10 load")
	var random: int=game.crime.rng.state
	check(not game.crime.check_wanted(game) and game.crime.rng.state==random,"Lawful party does not roll or alter the crime RNG")
	check(game.crime.notoriety(game)==0 and game.crime.wanted_label(game)=="Wanted: not known","Lawful party has no notoriety")
	game=robbery()
	check(game.crime.notoriety(game,"fort_bridger")==2,"Known robbery weighs two")
	check(game.crime.notoriety(game,"fort_hall")==0,"News does not arrive before its travel delay")
	var report: Dictionary=game.crime.record.reports[0]
	game.state.day=game.crime.arrival(game,report,"fort_hall")
	check(game.crime.notoriety(game,"fort_hall")==2,"Arrived robbery report counts")
	Wanted.post_bounties(game.crime,game)
	check(game.crime.record.bounties.size()==1,"A robbery over fifty dollars earns one posting")
	Wanted.post_bounties(game.crime,game)
	check(game.crime.record.bounties.size()==1,"Repeated checks do not repost the same crime")
	roundtrip(game,"Bounty posting")
	var store=Store.new()
	var bad: Dictionary=store.capture(game)
	bad.crime.record.bounties[0].incidents=[99999]
	check(store.restore(bad)==null,"Out-of-range bounty crime rejects")
	bad=store.capture(game)
	bad.crime.record.bounties[0].post="independence"
	check(store.restore(bad)==null,"A non-company post cannot issue a bounty")
	bad=store.capture(game)
	bad.crime.record.bounties[0].cleared_day=game.state.day
	check(store.restore(bad)==null,"A bounty cannot be silently cleared in a save")
	game=violence()
	check(game.crime.notoriety(game,"fort_bridger")==4,"A known nonfatal attack weighs four")
	check(Wanted.eligible(game.crime,game).has("regulators") and not Wanted.eligible(game.crime,game).has("posse"),"Regulators can pursue violence in the west, Missouri posse cannot")
	check(not Wanted.eligible(game.crime,game).has("bounty_hunters"),"Reward seekers need an actual posting")
	check(Wanted.start(game.crime,game,"regulators"),"Violence permits a regulator encounter")
	roundtrip(game,"Unresolved wanted standoff")
	check(not pick(game,"back") and not game.travel() and not game.rest(),"A pursuer encounter cannot be bypassed")
	var active: Dictionary=game.crime.incident()
	check(active.action=="wanted" and game.pending.choices.any(func(choice):return choice.crime_command=="flee"),"Wanted panel exposes encounter choices")
	var health: int=game.party_health.members[0].health
	check(pick(game,"surrender") and active.stage=="custody" and not active.has("sentence"),"Surrender leads to custody, not an instant sentence")
	check(active.custody.authority=="company" and active.custody.accused.size()==5,"Regulators hold the leader and the recorded helpers for an emigrant jury")
	roundtrip(game,"Held for an emigrant jury")
	check(hear(game) and game.state.status=="traveling","Surrender for a nonfatal attack continues the journey")
	check(active.sentence.kind=="assault" and active.sentence.surrendered and not game.party_health.members[0].conditions.any(func(item):return item.id=="wound"),"Voluntary surrender omits flogging")
	check(active.sentence.banished.size()==4 and game.state.party_size==1,"Only recorded helpers can be banished")
	roundtrip(game,"Sentence and banishment")
	check(pick(game,"finish") and Wanted.eligible(game.crime,game).is_empty(),"A served sentence does not punish the same charges again")
	check(game.crime.notoriety(game,"fort_bridger")==4,"Sentence settles charges without erasing historical notoriety")
	game=violence(true)
	Wanted.start(game.crime,game,"regulators")
	check(pick(game,"surrender") and hear(game) and game.state.status=="lost" and game.state.loss_reason=="The party's leader was hanged for murder.","A known killing leads to hanging")
	roundtrip(game,"Terminal murder sentence")
	game=robbery()
	game.open_crime()
	pick(game,"robbery")
	health=game.party_health.members[0].health
	game.crime.result(game,"captured")
	hear(game)
	check(game.crime.incident().sentence.kind=="robbery" and game.party_health.members[0].health<health and game.party_health.members[0].conditions.any(func(item):return item.id=="wound"),"Captured robbers are wounded, rather than automatically losing")
	roundtrip(game,"Original crime capture sentence")
	game=outfit()
	game.crime.scenes.fort_bridger.theft_success=0
	game.open_crime()
	pick(game,"theft")
	check(game.crime.notoriety(game,"fort_bridger")==0,"A pending undisclosed incident has no traveling report")
	game.crime.scenes.fort_bridger.escape_capture=0
	game.crime.scenes.fort_bridger.escape_injury=0
	pick(game,"flee")
	check(game.crime.notoriety(game,"fort_bridger")==0.5,"An unidentified theft counts half")
	pick(game,"finish")
	game.open_crime()
	pick(game,"theft")
	check(pick(game,"surrender") and hear(game) and game.crime.incident().sentence.kind=="restitution" and game.state.status=="traveling","Theft capture leads to restitution")
	roundtrip(game,"Theft sentence")
	# Each escape/fight result is exercised with deterministic seeds, using public commands.
	var outcomes: Dictionary={}
	for seed_value in range(16):
		game=violence()
		game.crime.rng.seed=seed_value
		Wanted.start(game.crime,game,"regulators")
		var reports: int=game.crime.record.reports.size()
		check(pick(game,"flee"),"Flight is available without ammunition")
		active=game.crime.record.incidents.back()
		if active.stage=="custody":hear(game)
		outcomes[active.resolution]=true
		check(game.crime.record.reports.size()==reports,"Flight does not manufacture a crime report")
		roundtrip(game,"Flight outcome %d" % seed_value)
	check(outcomes.has("escaped") and outcomes.has("tried"),"Flight sample covers escape and capture")
	for seed_value in range(10):
		game=violence()
		game.crime.rng.seed=seed_value
		Wanted.start(game.crime,game,"regulators")
		var bullets: int=game.state.bullets
		check(pick(game,"breakout") and game.state.bullets==bullets-3,"Fighting consumes actual ammunition")
		if game.crime.incident().get("stage","")=="custody":hear(game)
		roundtrip(game,"Fight outcome %d" % seed_value)
	game=violence()
	game.state.day=100
	Wanted.post_bounties(game.crime,game)
	game.state.day=200
	check(Wanted.start(game.crime,game,"bounty_hunters"),"An arrived posting permits reward seekers")
	var cents: int=Wanted.payoff(game.crime,game.crime.incident())
	var money: float=game.state.money
	check(pick(game,"payoff") and is_equal_approx(game.state.money,money-cents/100.0),"Payoff costs the actual reward plus twenty percent")
	check(game.crime.record.bounties[0].cleared_day==200 and game.crime.notoriety(game,"fort_bridger")==4,"Payoff clears a posting without erasing crime history")
	roundtrip(game,"Paid reward")
	pick(game,"finish")
	random=game.crime.rng.state
	check(not game.crime.check_wanted(game) and game.crime.rng.state==random,"Cooldown blocks another roll")
	# Migration is idempotent and cannot erase an already-present posting.
	game=outfit()
	var legacy: Dictionary=game.crime.snapshot()
	legacy.record.version=8
	legacy.record.erase("bounties")
	var upgraded: Dictionary=game.crime.upgrade(legacy,game)
	check(upgraded.record.version==10 and upgraded.record.bounties==[] and upgraded.random==legacy.random and game.crime.valid(upgraded,game),"v8 upgrades without inventing rewards or consuming randomness")
	check(game.crime.upgrade(upgraded,game)==upgraded,"v10 upgrade is idempotent")
	# Identification and experience do not manufacture evidence.
	game=robbery()
	var score: float=game.crime.notoriety(game,"fort_bridger")
	game.combat.history.append({"outcome":"won"})
	check(game.crime.notoriety(game,"fort_bridger")==score,"Combat experience does not add notoriety")
	game.characters.profiles[1].boundaries=game.characters.catalog.boundaries("Compassionate")
	game.flee([1],"for the evidence test")
	check(game.crime.notoriety(game,"fort_bridger")==score,"A report and a companion's tale of the same robbery count once")
	game=robbery()
	game.crime.miles.fort_bridger=0
	game.state.miles=0
	check(Wanted.eligible(game.crime,game).has("posse"),"Missouri posse can answer a local report inside its boundary")
	game.state.miles=int(game.crime.wanted_data.posse_max_mile)+1
	game.state.day+=10
	check(not Wanted.eligible(game.crime,game).has("posse"),"A Missouri posse cannot follow beyond the state boundary")
	game=violence()
	var known: Array=Wanted.charges(game.crime,game,int(game.state.miles))
	var chance: float=Wanted.daily_chance(game.crime,game,known)
	game.state.day+=20
	check(is_equal_approx(Wanted.daily_chance(game.crime,game,known),chance*0.5),"Twenty quiet days halve the daily encounter chance")
	game=robbery()
	game.open_crime()
	pick(game,"robbery")
	game.party_health.members[0].health=2
	game.characters.profiles[0].flaws=["Frail"]
	game.crime.result(game,"captured")
	hear(game)
	check(game.party_health.members[0].alive and game.party_health.members[0].health==1 and game.state.status=="traveling","Frail or badly hurt leaders survive nonfatal punishment")
	game=violence()
	Wanted.start(game.crime,game,"regulators")
	game.state.bullets=0
	var before: Dictionary=Store.new().capture(game)
	check(not pick(game,"breakout") and Store.new().capture(game)==before,"An empty gun rejects a fight without spending time or supplies")
	game=outfit()
	game.state.departure_month=6
	game.state.next_landmark="fort_kearny"
	game._arrive_landmark()
	game.state.miles=int(game.route.node_miles().fort_kearny)
	game.crime.scenes.fort_kearny.compliance=1
	game.crime.scenes.fort_kearny.escape_capture=0
	game.crime.scenes.fort_kearny.escape_injury=0
	game.crime.scenes.fort_kearny.pursuit.daily=1
	game.open_crime()
	pick(game,"robbery")
	pick(game,"take")
	pick(game,"flee")
	pick(game,"finish")
	check(game.crime.check_pursuit(game),"The original army pursuit still creates a standoff")
	var army_save: Dictionary=Store.new().capture(game)
	check(game.pending.choices.any(func(choice):return choice.crime_command=="flee"),"A pursuing army detachment offers flight")
	check(pick(game,"surrender") and game.crime.incident().custody.authority=="army","Soldiers hold what happened at their own post")
	check(hear(game) and game.crime.record.incidents.back().sentence.kind=="sent_east" and not game.crime.record.incidents.back().sentence.charges.any(func(id):return int(Wanted.incident_evidence(game.crime,game,game.crime.record.incidents[int(id.get_slice(":",1))-1],true).severity)>2),"Being pursued without fighting is not charged as an assault")
	check(game.state.status=="lost" and game.state.loss_reason=="The party's leader was sent east under military escort to stand trial.","A leader sent east ends the journey")
	roundtrip(game,"Army surrender sentence")
	game=Store.new().restore(JSON.parse_string(JSON.stringify(army_save)))
	check(game!=null and pick(game,"flee"),"Flight from the army resolves through a public action")
	if game!=null:roundtrip(game,"Army flight result")
	army_save.rules="7b11c6894279c30b4dfe0a8cb9333dee8bc16853aa02b4ec7c5ce04a24dd8e81"
	army_save.crime.record.version=8
	army_save.crime.record.erase("bounties")
	army_save.pending.choices=army_save.pending.choices.filter(func(choice):return choice.crime_command!="flee")
	check(Store.new().restore(JSON.parse_string(JSON.stringify(army_save)))!=null,"An older pending army pursuit gains flight on migration")
	game=outfit()
	game.pending={}
	game.crime.scenes.passing_traders.shot_hit=1
	game.crime.scenes.passing_traders.shot_fatal=0
	game.crime.scenes.passing_traders.escape_capture=0
	game.crime.scenes.passing_traders.escape_injury=0
	check(game.open_crime() and pick(game,"shoot") and pick(game,"flee") and pick(game,"finish"),"Prepare a report from a transient trading party")
	game.state.day+=2
	Wanted.post_bounties(game.crime,game)
	check(not game.crime.record.bounties.is_empty(),"A nearby post hears the transient party's report")
	game.state.miles+=500
	game.state.day+=50
	roundtrip(game,"Transient-origin bounty after traveling away")
	game=robbery()
	game.open_crime()
	pick(game,"robbery")
	# Journeys saved before the leader-death rule let a companion take over.
	game.state.leader_succession=true
	game.party_health.kill(game.party_health.members[0],int(game.state.day),"confrontation injuries")
	game._collect_health_events()
	game.crime.result(game,"captured")
	hear(game)
	check(not game.party_health.members[0].alive and game.party_health.members[0].health==0,"A trial never gives health back to a leader already killed in the fight")
	roundtrip(game,"A survivor answers the nonfatal trial after the original leader died")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.game=violence()
	Wanted.start(screen.game.crime,screen.game,"regulators")
	screen._refresh()
	screen._show_service()
	await process_frame
	check(screen.service_window.visible and screen.service_rows.get_children().any(func(node):return node is Button and node.text.to_lower().begins_with("surrender")),"Wanted encounter reaches the existing graphical panel")
	screen._refresh_party()
	check(screen.member_details.text.begins_with("Wanted:"),"Party details show derived wanted status")
	screen.queue_free()
	await process_frame
	# Bug pass (November 2026): a companion who left on the day a bounty was posted, after the posting, told of acts
	# the bounty did not price in; the save was refused. A real chaos-bot save from that day now loads.
	var fixture: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/same-day-tale-bounty-v1.json"))
	var same_day=Store.new().restore(fixture)
	check(same_day!=null,"A bounty posted the day a companion left still loads")
	if same_day!=null:
		check(int(same_day.crime.record.bounties[0].cents)==16250 and Wanted.notoriety(same_day.crime,same_day,"fort_laramie",83)*2500>16250,"Its price left out the tale told that same day")
	print("Wanted system: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
