extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool, message: String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func party(bonds: Array=[], romance: bool=true):
	var game=Simulation.new(57,"classic",true)
	var setup={"profiles":[],"contracts":{},"bonds":bonds,"romance":romance}
	game.characters.start(57,5)
	setup.profiles=game.characters.profiles.duplicate(true)
	game.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,{"oxen":6,"food":1700,"clothing":5,"bullet_boxes":10},setup)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	return game
func restored(game):return Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(game))))
func stop(game):
	game.state.next_landmark="fort_bridger"
	game._arrive_landmark()
func run():
	var game=party([{ "a":1,"b":2,"kind":"partner"}])
	check(game.error.is_empty() and game.state.status=="traveling" and game.crime.bond(1,2)=="partner","Departure accepts custom partner bonds")
	check(game.social.pair_for(1,2).affinity==80,"Starting relationship sets closeness")
	check(not game.social.valid_bonds([{ "a":1,"b":2,"kind":"partner"},{"a":2,"b":3,"kind":"partner"}]),"One partner per companion")
	check(not game.social.valid_bonds([{ "a":1,"b":1,"kind":"family"}]),"No self bond")
	check(not game.social.valid_rules(null),"Missing social rules rejected")
	var invalid=game.social.rules.duplicate(true)
	invalid.romance_chance=2
	check(not game.social.valid_rules(invalid),"Invalid romance probability rejected")
	var before=Store.new().capture(game)
	game.social.description(game,1)
	check(Store.new().capture(game)==before,"Inspecting relationships does not change state or RNG")
	check(restored(game)!=null,"Social state round-trips")
	var old=Store.new().capture(game)
	old.erase("social")
	old.rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/save_migrations.json")).economy_v1.back()
	var legacy=Store.new().restore(JSON.parse_string(JSON.stringify(old)))
	check(legacy!=null and legacy.crime.bond(1,2)=="partner" and legacy.social.pair_for(1,2).affinity==80,"Old saves retain bonds without invented relationship history")
	var bad=Store.new().capture(game)
	bad.social.pairs[0].affinity=101
	check(Store.new().restore(bad)==null,"Invalid social state rejected")
	bad=Store.new().capture(game)
	bad.social.last_day=9999
	check(Store.new().restore(bad)==null,"Future social dates rejected")
	game.characters.profiles[1].trust=0
	game.characters.review_exit(game,game.characters.profiles[1])
	game.state.day=5
	stop(game)
	var plan=game.departure_plan()
	check(plan.map(func(item):return int(item.id))==[1,2],"A departing spouse takes their active partner into the joint plan")
	game.open_departure_review()
	check("will leave with their partner" in game.pending.text,"Joint departure is explained before confirmation")
	check(restored(game)!=null,"Joint departure review saves")
	game.choose(game.pending.choices.size()-1)
	check(game.party_health.living_count()==5,"Canceling joint departure leaves everyone present")
	game.open_departure_review()
	game.choose(0)
	check(game.party_health.members[1].departed and game.party_health.members[2].departed and game.state.party_size==3,"Confirming transfers supplies and departs both spouses")
	check(restored(game)!=null,"Joint departure outcome saves")
	game=party()
	var pair=game.social.pair_for(1,2)
	pair.affinity=80
	game.social.evolve(game,pair,0.0)
	check(game.crime.bond(1,2)=="partner" and game.journal.any(func(line):return "fallen in love" in line),"Close unpaired companions can fall in love")
	check(restored(game)!=null,"New romance saves")
	pair.affinity=-80
	game.social.evolve(game,pair,1.0)
	check(game.crime.bond(1,2)=="rival","Severe repeated conflict can end a partnership")
	check(game.social.exit_reason(game,1)=="hostile companion","Extreme hostility contributes to departure intent")
	game=party()
	game.characters.profiles[1].relationship="partner"
	pair=game.social.pair_for(1,2)
	pair.affinity=90
	game.social.evolve(game,pair,0.0)
	check(game.crime.bond(1,2)!="partner","An existing partnership with the leader blocks new romance")
	game=party()
	game.characters.profiles[1].relationship="sibling"
	game.characters.profiles[2].relationship="cousin"
	pair=game.social.pair_for(1,2)
	pair.affinity=90
	game.social.evolve(game,pair,0.0)
	check(game.crime.bond(1,2)!="partner","Known kin of the leader are excluded from romance")
	game=party([],false)
	pair=game.social.pair_for(1,2)
	pair.affinity=90
	game.social.evolve(game,pair,0.0)
	check(game.crime.bond(1,2)=="friend","Romance toggle prevents new partnerships but allows friendship")
	game=party([{ "a":1,"b":2,"kind":"family"},{"a":2,"b":3,"kind":"family"}])
	pair=game.social.pair_for(1,3)
	pair.affinity=90
	game.social.evolve(game,pair,0.0)
	check(game.crime.bond(1,3)!="partner","Family-connected companions cannot form romances")
	game=party([{ "a":1,"b":2,"kind":"partner"}])
	game.party_health.kill(game.party_health.members[2],0,"test")
	game._collect_health_events()
	game.state.party_size=4
	game.state.health=game.party_health.average_health()
	pair=game.social.pair_for(1,3)
	pair.affinity=90
	game.social.evolve(game,pair,0.0)
	check(game.crime.bond(1,3)=="partner" and game.crime.bond(1,2)!="partner" and restored(game)!=null,"A survivor can form a new partnership without duplicate spouses")
	game=party()
	var copy=party()
	for model in [game,copy]:
		model.characters.profiles[1].traits[1]="Compassionate"
		model.characters.profiles[2].traits[1]="Compassionate"
		model.state.day=7
		model.social.tick(model,true,true)
	check(Store.new().capture(game)==Store.new().capture(copy),"Social evolution is deterministic")
	check(game.social.pair_for(1,2).affinity>0,"Compatible values improve closeness")
	before=Store.new().capture(game)
	game.social.tick(game,true,true)
	check(Store.new().capture(game)==before,"One social update per weekly interval")
	check(restored(game)!=null,"Evolved feelings and dated memories save")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	var view=screen.departure_view
	view.open_bonds()
	check(view.bonds_layer.visible and not view.editor_layer.visible and view.bond_boxes.size()==6,"Departure UI exposes all six companion pairs")
	for row in view.bond_boxes:
		row.box.select(0)
		row.previous=0
	view.bond_boxes[0].box.select(3)
	view._change_bond(3,0)
	view.bond_boxes[1].box.select(3)
	view._change_bond(3,1)
	check(view.bond_boxes[1].box.selected!=3,"UI rejects a second simultaneous partner")
	check(view.customization().bonds==[{"a":1,"b":2,"kind":"partner"}],"Edited bonds reach the departure transaction")
	screen.queue_free()
	await process_frame
	print("Social: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
