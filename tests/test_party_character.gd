extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Policy=preload("res://tests/survival_policy.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func outfit(seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":1000,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
	game.seen.append("muddy_trail")
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	return game
func run():
	var game=outfit()
	var same=outfit()
	check(game.characters.profiles==same.characters.profiles,"Seed gives reproducible characters")
	check(game.characters.profiles!=outfit(58).characters.profiles,"Other seeds can give other personalities")
	check(game.characters.valid(game.characters.profiles,5,0),"Generated profiles meet schema")
	check(game.characters.profiles[0].traits.is_empty(),"Player has no assigned moral personality")
	var skills: Array=[]
	for profile in game.characters.profiles.slice(1):
		check(profile.traits.size()==2 and profile.trust==50 and profile.memories.is_empty(),"Companion starts with two traits and neutral trust")
		skills.append(profile.skill)
	check(skills.size()==4 and skills.all(func(skill):return skills.count(skill)==1),"Four companions have distinct practical backgrounds")
	game.characters.profiles[1].traits=["Cautious","Compassionate"]
	game.characters.profiles[2].traits=["Bold","Pragmatic"]
	game.party_health.begin_condition(2,"broken_leg",0,2)
	game.health_events.clear()
	game.rest()
	check(game.characters.profiles[1].trust==51 and game.characters.profiles[2].trust==50,"Sick-party rest earns compassionate approval without universal mood points")
	game.pending={}
	game.state.pace=2
	game.travel()
	check(game.characters.profiles[1].trust==49 and game.characters.profiles[2].trust==50,"Actual grueling travel with injury produces trait-specific objection")
	check(game.journal.any(func(line):return "pushed a grueling pace" in line),"Objection is explained in the journal")
	game.pending={}
	game.open_care()
	var care_index: int=-1
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("member_id",-1)==2 and game.pending.choices[index].get("care",0)==6:care_index=index
	check(care_index>=0 and game.choose(care_index),"Actual care choice reaches character reactions")
	check(game.characters.profiles[2].trust==52 and game.characters.profiles[1].trust>=51,"Patient and compassionate companions appreciate care")
	game=outfit()
	game.characters.profiles[1].traits=["Cautious","Compassionate"]
	game.characters.profiles[2].traits=["Bold","Pragmatic"]
	for event in game.trail_events.events:
		if event.id=="bandits":game._present_trail_event(event)
	check(game.choose(1),"Actual defense choice executes")
	check(game.characters.profiles[1].trust==49 and game.characters.profiles[2].trust==51,"Defense draws different responses from cautious and bold companions")
	var friendly=outfit()
	for event in friendly.trail_events.events:
		if event.id=="riders":friendly._present_trail_event(event)
	friendly.pending.friendly=true
	for choice in friendly.pending.choices:
		if choice.get("combat", "")=="defend":
			choice.risk.probability=0
	var defend_index: int=-1
	for index in range(friendly.pending.choices.size()):
		if friendly.pending.choices[index].get("combat", "")=="defend":defend_index=index
	check(defend_index>=0 and friendly.choose(defend_index) and friendly.characters.profiles.all(func(p):return p.memories.is_empty()),"Friendly riders do not generate memories of a hostile battle")
	var profile: Dictionary=game.characters.profiles[1]
	var trust: int=profile.trust
	game.characters.defense(game)
	check(profile.trust==trust,"Repeating a reaction on the same day cannot farm trust")
	profile.trust=100
	game.state.day+=1
	game.characters.remember(game,profile,"care",2,"Care.")
	check(profile.trust==100 and profile.memories.back().delta==0,"Trust clamps and memory records actual change")
	for day in range(2,25):
		game.state.day=day
		game.characters.remember(game,profile,"care",-2,"A test decision.")
	check(profile.memories.size()==12 and profile.memories[0].day==13,"Only twelve recent memories are retained")
	game=outfit()
	game.characters.profiles[1].traits=["Cautious","Compassionate"]
	game.party_health.affect(game.party_health.members[1],-100,0,"test")
	game._collect_health_events()
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	game.characters.defense(game)
	check(game.characters.profiles[1].memories.is_empty() and game.characters.profiles[0].memories.is_empty(),"Dead companions and the player do not react")
	var store=Store.new()
	game=outfit()
	game.characters.defense(game)
	var snapshot=store.capture(game)
	var restored=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored!=null and store.capture(restored)==snapshot,"Traits, trust and memories round-trip exactly")
	var old=snapshot.duplicate(true)
	old.erase("characters")
	old.erase("characters_version")
	old.erase("camp_tasks")
	old.erase("field_outings")
	restored=store.restore(old)
	var neutral_profiles: Array=outfit().characters.profiles.duplicate(true)
	for neutral_profile in neutral_profiles:neutral_profile.erase("appearance")
	check(restored!=null and restored.characters.profiles==neutral_profiles and restored.state==store.normalize(game.state) and restored.rng.state==game.rng.state,"Old saves gain neutral profiles without fictional memories, invented identity or simulation changes")
	for bad in [null,[],[{}]]:
		var malformed=snapshot.duplicate(true)
		malformed.characters=bad
		check(store.restore(malformed)==null,"Reject malformed character collection")
	for field in ["trust","traits","skill","memories"]:
		var malformed=snapshot.duplicate(true)
		malformed.characters[1][field]="invalid"
		check(store.restore(malformed)==null,"Reject malformed character field: "+field)
	for field in ["day","kind","delta","text"]:
		var malformed=snapshot.duplicate(true)
		malformed.characters[1].memories[0][field]=[]
		check(store.restore(malformed)==null,"Reject malformed memory field: "+field)
	for seed_value in range(8):
		game=outfit(seed_value)
		var baseline=outfit(seed_value)
		for day in range(35):
			Policy.step(game)
			Policy.step(baseline)
			check(game.state==baseline.state and game.pending==baseline.pending and game.party_health.members==baseline.party_health.members and game.rng.state==baseline.rng.state and game.survival.rng.state==baseline.survival.rng.state and game.party_health.rng.state==baseline.party_health.rng.state,"Benefits and companion news remain deterministic under identical policy decisions")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=outfit()
	screen.game.characters.profiles[1].traits=["Cautious","Compassionate"]
	screen.game.characters.defense(screen.game)
	screen.selected_member=1
	screen._show_party()
	check("Cautious" in screen.member_details.text and "Trust in you: 49" in screen.member_details.text and "armed defense" in screen.member_details.text,"Party screen exposes traits, trust and a concrete memory")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/companion-personality.png")
	screen.queue_free()
	await process_frame
	print("Party character: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
