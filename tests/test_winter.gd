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
	# Below the snow line: plain winter forage, without snow-country starvation.
	cold.state.landmark="fort_bridger"
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
		check(store.upgraded_state(copy.state)==store.upgraded_state(previous.state) and copy.pending==store.normalize(previous.pending) and str(copy.rng.state)==previous.random,"Migration preserves supplies, date, cash, pending choices and RNG")
		check(store.restore(store.capture(copy))!=null,"Migrated winter-rule save round trips")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=outfit(12)
	screen.game.state.landmark="fort_bridger"
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
	# Barlow road: wagons are shut out in winter, open in summer; walkers can still go around.
	for month in [12,8]:
		var g=outfit(month)
		g.state.next_landmark="the_dalles";g._arrive_landmark()
		var barlow: int=-1
		for index in range(g.pending.choices.size()):
			if g.pending.choices[index].get("seasonal_road","")=="barlow_pass":barlow=index
		check(barlow>=0 and "snowbound to wagons November to April" in g.pending.choices[barlow].label,"Barlow choice warns of its winter closure")
		check(g.can_choose(barlow)==(month==8),"Barlow road is closed to wagons in December and open in August")
		check(g.pending.choices.any(func(c):return c.get("action","")=="rest") and g.pending.choices.any(func(c):return c.get("hazard","")=="river" or str(c.get("label","")).contains("raft")),"A closed road still leaves wintering over or the river")
		if month==12:
			g.state.vehicle="foot"
			check(g.can_choose(barlow),"Walkers may still go around Mount Hood in winter")
	# Snow country: snowbound days and starving animals only in season, with a warning.
	var snowy=outfit(12)
	snowy.state.next_landmark="little_sandy"
	check(not snowy.snow_country().is_empty() and snowy.season_notice().contains("snow country"),"December at South Pass is snow country, and the notice says so")
	var july=outfit(7)
	july.state.next_landmark="little_sandy"
	check(july.snow_country().is_empty(),"July at South Pass is not snow country")
	var valley=outfit(12)
	valley.state.landmark="grande_ronde";valley.state.next_landmark="blue_mountains";valley.state.leg_miles=0
	check(valley.snow_country().get("sheltered",false) and float(valley.snow_country().snowbound_chance)==0.0 and int(valley.snow_country().animal_strain)>0,"The Grande Ronde valley below the pass is sheltered from drifts but still hard on animals")
	valley.state.leg_miles=5
	check(valley.snow_country().get("place","")=="blue_mountains","Once on the climb, the Blue Mountains snow applies")
	var stuck:=0
	var oxen_before: int=int(snowy.state.oxen)
	for day in range(40):
		snowy.pending={}
		var miles: int=int(snowy.state.miles)
		if not snowy.travel():break
		if int(snowy.state.miles)==miles and snowy.journal.back().contains("Snowbound"):stuck+=1
		if snowy.state.next_landmark!="little_sandy":snowy.state.landmark="south_pass";snowy.state.next_landmark="little_sandy";snowy.state.leg_miles=0
	check(stuck>0,"Drifts stop the wagon on some winter days: %d" % stuck)
	check(int(snowy.state.oxen)<oxen_before or int(snowy.state.ox_health)<40,"Forty winter days in snow country starve the team")
	# A starved animal can be butchered instead of wasted.
	var dead=outfit(12)
	dead.state.ox_health=0
	dead.state.leg_miles=5
	var team: int=int(dead.state.oxen)
	dead.route.nodes.south_pass.snow_country.death_chance=1.0
	dead._snow_starvation()
	check(int(dead.state.oxen)==team-1 and dead.pending.get("id","")=="snow_carcass","A starved ox offers its carcass")
	var food_before: int=int(dead.state.food)
	check(dead.choose(0) and int(dead.state.food)>food_before,"Butchering the dead ox adds meat: %d -> %d" % [food_before,int(dead.state.food)])
	check(dead.journal.any(func(line):return "Butchered the dead ox" in line),"Butchering the carcass is logged")
	var left=outfit(12)
	left.state.ox_health=0
	left.route.nodes.south_pass.snow_country.death_chance=1.0
	left._snow_starvation()
	var keep: int=int(left.state.food)
	var chose_leave: bool=left.choose(1)
	check(chose_leave and int(left.state.food)==keep and left.pending.get("id","")!="snow_carcass","Leaving the carcass adds no meat: %s %d->%d %s" % [chose_leave,keep,int(left.state.food),left.pending.get("id","")])
	print("Winter pressure: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
