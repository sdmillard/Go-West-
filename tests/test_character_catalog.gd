extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Catalog=preload("res://simulation/character_catalog.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfitted():
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	return game
func run():
	var catalog=Catalog.new()
	check(catalog.error.is_empty() and catalog.data.temperaments.size()==8 and catalog.data.values.size()==8 and catalog.data.specials.size()==17 and catalog.data.flaws.size()==12 and catalog.data.relationships.size()==13,"Expanded catalog loads complete categories")
	var original: Dictionary=catalog.data.duplicate(true)
	for category in Catalog.REQUIRED:
		var bad: Dictionary=original.duplicate(true)
		bad[category].erase(Catalog.REQUIRED[category][0])
		check(not catalog.load_data(bad) and catalog.data==original,"Missing legacy identifiers reject atomically")
	for malformed in [NAN,-1,0,4,"1.5"]:
		var bad: Dictionary=original.duplicate(true)
		bad.specials.Hardy.hurt_all=malformed
		check(not catalog.load_data(bad),"Unsafe health multipliers reject")
	var bad: Dictionary=original.duplicate(true)
	bad.values.Compassionate.approved=["murder"]
	check(not catalog.load_data(bad) and catalog.load_data(original),"Contradictory boundaries reject and valid catalog reloads")
	var game=outfitted()
	var store=Store.new()
	var before: Dictionary=store.capture(game)
	var seen_specials: Dictionary={}
	var seen_flaws: Dictionary={}
	for index in range(256):
		var offer: Dictionary=game.characters.generate_candidate(1848,index)
		check(offer==game.characters.generate_candidate(1848,index),"Candidate seed and identity reproduce all fields")
		var choices: Dictionary={"profiles":game.characters.profiles.duplicate(true),"contracts":{}}
		choices.profiles[1]=offer.profile
		if not offer.terms.is_empty():choices.contracts["1"]=offer.terms
		check(game.characters.valid_setup(choices),"Generated recruits obey creation budgets, boundaries, relations and wage minima")
		for name in offer.profile.specials:seen_specials[name]=true
		for name in offer.profile.get("flaws",[]):seen_flaws[name]=true
	check(seen_specials.size()==16 and not seen_specials.has("Leatherworker") and seen_flaws.size()==12,"Seeded sample includes every special and flaw")
	check(store.capture(game)==before,"Generating offers never changes an active journey, supplies or any random stream")
	check(game.characters.generate_candidate(1,-1).is_empty() and game.characters.generate_candidate(1,0,"self").is_empty(),"Invalid candidate requests reject")
	for relation in catalog.data.relationships:
		var profile: Dictionary=game.characters.generate_candidate(1848,0,relation).profile
		check(profile.trust==catalog.data.relationships[relation].trust and game.characters.breaking_point(profile)==20-int(catalog.data.relationships[relation].attachment),"Each relationship supplies its documented trust and attachment")
	var profile: Dictionary=game.characters.profiles[1]
	profile.traits=["Steady","Pacifist"]
	profile.boundaries=catalog.boundaries("Pacifist")
	check(not game.characters.willing(1,"defend"),"Pacifist actually refuses armed defense")
	profile.traits=["Bold","Compassionate"]
	profile.boundaries=catalog.boundaries("Compassionate")
	profile.specials=["Cannibal"]
	check(game.characters.response(1,"cannibalism")=="neutral" and game.characters.response(1,"murder")=="forbidden" and "cannibalism" not in game.characters.effective_forbidden(profile),"Cannibal exception does not erase murder boundary and displays accurately")
	profile.traits=["Steady","Pragmatic"]
	profile.specials=["Stoic"]
	var trust: float=profile.trust
	game.characters.remember(game,profile,"defend",-2,"A disagreement.")
	check(profile.trust==trust-1,"Stacked ordinary-loss reductions round to half-point trust")
	profile.flaws=["Distrustful"]
	trust=profile.trust
	game.characters.remember(game,profile,"care",2,"Care.")
	check(profile.trust==trust+1,"Distrustful halves earned trust")
	profile.flaws=["Restless"]
	profile.traits=["Bold","Pragmatic"]
	profile.specials=[]
	trust=profile.trust
	game.characters.daily(game,true,false,false)
	check(profile.trust==trust-1,"Restless creates an actual cost on an otherwise healthy rest day")
	profile.flaws=["Proud"]
	trust=profile.trust
	game.characters.care(game,1)
	check(profile.trust==trust,"Proud does not gain personal care trust")
	var health_profile: Dictionary={"traits":[],"specials":[],"flaws":[]}
	for row in [["Hardy",-10,"exhaustion",-8],["Quick Healer",6,"care",9],["Iron Stomach",-8,"lack of food",-6],["Sure-footed",-8,"crossing injuries",-6],["Cool-headed",-8,"confrontation injuries",-6],["Weatherwise",-8,"exposure",-6],["Tireless",-8,"exhaustion",-6]]:
		health_profile.specials=[row[0]]
		check(catalog.health_delta(health_profile,row[1],row[2],game.party_health.conditions)==row[3],"Personal resilience special applies only to its health context")
	health_profile.specials=[]
	for row in [["Frail",-8,"exhaustion",-10],["Slow Healer",6,"care",3],["Cold-sensitive",-8,"exposure",-12],["Delicate Stomach",-8,"lack of food",-12],["Poor Endurance",-8,"exhaustion",-12],["Clumsy",-8,"crossing injuries",-12],["Shaken by Gunfire",-8,"confrontation injuries",-12],["Sickly",-8,"cholera",-12]]:
		health_profile.flaws=[row[0]]
		check(catalog.health_delta(health_profile,row[1],row[2],game.party_health.conditions)==row[3],"Personal flaw applies its documented health context")
	health_profile.flaws=["Sickly"]
	check(catalog.health_delta(health_profile,-8,"crossing injuries",game.party_health.conditions)==-8,"Sickly does not worsen unrelated injury damage")
	for special in {"Field Medic":"Caregiving","Wagonwright":"Carpentry","Sharpshooter":"Hunting","Haggler":"Trading"}:
		game=outfitted()
		for person in game.characters.profiles.slice(1):person.skill="Trading"
		var target: String={"Field Medic":"Caregiving","Wagonwright":"Carpentry","Sharpshooter":"Hunting","Haggler":"Trading"}[special]
		game.characters.profiles[1].specials=[special]
		check(game.characters.available(game,target),"Cross-trained special grants a real background contribution")
		game.characters.profiles[1].trust=0
		if target!="Trading":check(not game.characters.available(game,target),"Refusing companion withholds cross-trained contribution")
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-character-catalog-save-v1.json"))
	var restored=store.restore(previous)
	check(restored!=null and restored.state==store.upgraded_state(previous.state) and restored.characters.profiles==store.normalize(previous.characters),"Authentic previous save preserves profiles, old flaw, contract and inventory")
	if restored!=null:check(store.restore(store.capture(restored))!=null,"Migrated old catalog save remains writable")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	var setup=screen.departure_view
	check(setup.personality.item_count==8 and setup.values.item_count==8 and setup.relationship.item_count==13 and setup.flaw_choice.item_count==13 and setup.special_checks.size()==16 and setup.background_choice.item_count==5,"Actual editor exposes the full catalog")
	var initial_state: Dictionary=screen.game.state.duplicate(true)
	var initial_rng: int=screen.game.rng.state
	setup.generate_button.pressed.emit()
	var choices: Dictionary=setup.customization()
	check(screen.game.characters.valid_setup(choices) and screen.game.state==initial_state and screen.game.rng.state==initial_rng,"Generate button creates valid draft without spending or rerolling journey")
	setup.personality.select(2)
	setup.values.select(6)
	setup.relationship.select(5)
	setup.flaw_choice.select(9)
	setup.flaw_choice.item_selected.emit(9)
	for button in setup.special_checks.values():button.button_pressed=false
	setup.special_checks["Field Medic"].button_pressed=true
	setup.special_checks["Hardy"].button_pressed=true
	setup.special_checks["Mercenary"].button_pressed=true
	setup.values.item_selected.emit(6)
	check("defend" in setup.character_summary.text and "75" in setup.character_summary.text,"Creation summary shows pacifist boundary and partner starting trust")
	if "--capture" in OS.get_cmdline_user_args():
		var scroll: ScrollContainer=setup.flaw_choice.get_parent().get_parent()
		scroll.scroll_vertical=maxi(0,int(setup.relationship.position.y)-12)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/expanded-character-creation.png")
	setup.next_button.pressed.emit()
	setup.depart_button.pressed.emit()
	check(screen.game.state.status=="traveling" and screen.game.characters.profiles[1].traits==["Steady","Pacifist"] and screen.game.characters.profiles[1].relationship=="partner","Expanded traits and relationship commit through actual departure")
	var snapshot: Dictionary=store.capture(screen.game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null and store.capture(copy)==snapshot,"Expanded character profile and wages round-trip")
	screen.queue_free()
	await process_frame
	print("Character catalog: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
