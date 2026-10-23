extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Rules=preload("res://simulation/survival_rules.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(month: int=6):
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["A","B","C","D","E"],6,cart)
	game.state.day=int((Time.get_unix_time_from_datetime_string("1848-%02d-01T00:00:00" % month)-Time.get_unix_time_from_datetime_string("1848-06-01T00:00:00"))/86400)
	game.state.landmark="south_pass"
	game.state.terrain="mountains"
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	return game
func run():
	var rules=Rules.new()
	var data: Dictionary=rules.data.duplicate(true)
	for bad in [{},{"travel":[1]},null]:
		var malformed: Dictionary=data.duplicate(true)
		malformed.seasonal=bad
		check(not rules.load_data(malformed),"Reject missing/incomplete seasonal tables")
		check(rules.load_data(data),"Valid seasonal data restores")
	for key in ["travel","rest_ox_recovery","working_strain"]:
		var malformed: Dictionary=data.duplicate(true)
		malformed.seasonal[key][0]=-1
		check(not rules.load_data(malformed),"Reject negative seasonal effect")
		rules.load_data(data)
	var random: int=rules.rng.state
	var summer: Dictionary=rules.seasonal(6,"mountains",{"cold":1.7})
	var winter: Dictionary=rules.seasonal(12,"mountains",{"cold":1.7})
	check(rules.rng.state==random,"Calendar previews do not consume random outcomes")
	check(summer.travel==1 and winter.travel<rules.seasonal(12,"plains").travel,"Winter drag is stronger in uplands and leaves summer unchanged")
	check(winter.rest_ox_recovery<summer.rest_ox_recovery and winter.working_strain>summer.working_strain,"Winter forage slows recovery and increases work strain")
	var snow:=0
	for day in range(1000):
		rules.advance(7,"mountains",{"cold":1.7})
		if rules.weather.id=="blizzard":snow+=1
	check(snow==0,"Normal summer weather does not roll the winter blizzard event")
	for day in range(1000):
		rules.advance(12,"mountains",{"cold":1.7})
		if rules.weather.id=="blizzard":snow+=1
	check(snow>100,"Winter mountain blizzards are a substantial seeded hazard")
	var warm=outfit()
	var cold=outfit(12)
	warm.travel();cold.travel()
	check(cold.state.miles<warm.state.miles and cold.state.ox_health<warm.state.ox_health,"Actual winter travel slows and strains animals even between storms")
	warm=outfit();cold=outfit(12)
	warm.state.ox_health=50;cold.state.ox_health=50
	warm.rest();cold.rest()
	check(warm.state.ox_health==54 and cold.state.ox_health==52,"Actual winter rest has less forage recovery")
	warm=outfit();cold=outfit(12)
	warm.state.vehicle="foot";cold.state.vehicle="foot"
	check(cold.walking_distance()<warm.walking_distance(),"Winter road penalties also apply on foot")
	var clothed=outfit(12)
	var exposed=outfit(12)
	var calm=outfit(12)
	clothed.survival.forced_weather="blizzard";exposed.survival.forced_weather="blizzard"
	exposed.state.clothing=0
	clothed.travel();exposed.travel();calm.travel()
	check(clothed.party_health.members[0].health<calm.party_health.members[0].health,"Normal clothing does not erase winter storm exposure")
	check(exposed.party_health.members[0].health<clothed.party_health.members[0].health,"Clothing still materially protects travelers")
	var store=Store.new()
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-winter-save-v1.json"))
	var copy=store.restore(previous)
	check(copy!=null,"Authentic previous-rule save migrates")
	if copy!=null:
		check(store.normalize(copy.state)==store.normalize(previous.state) and copy.pending==store.normalize(previous.pending) and str(copy.rng.state)==previous.random,"Migration preserves supplies, date, cash, pending choices and RNG")
		check(store.restore(store.capture(copy))!=null,"Migrated winter-rule save round trips")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=outfit(12)
	screen._refresh()
	check("Winter:" in screen.event_text.text,"Winter warning is visible in the travel story")
	screen._rest()
	screen.rest_days_input.text="30"
	screen._update_rest_quote()
	check("Winter:" in screen.rest_quote.text and "450 food units" in screen.rest_quote.text,"Rest confirmation shows seasonal danger alongside actual meals")
	check(screen.rest_window.size.y<=root.content_scale_size.y,"Expanded warning fits the game window")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.tools/winter-rest-preview.png")
	print("Winter pressure: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
