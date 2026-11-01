extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Policy = preload("res://tests/full_trail_policy.gd")
const Store = preload("res://simulation/save_store.gd")
const Main = preload("res://ui/main.tscn")
var checks := 0
var failures := 0
func check(value: bool,message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: "+message)
func _initialize() -> void:
	call_deferred("run")
func outfit(seed_value: int = 2,month: int = 3):
	var game = Simulation.new(seed_value,"classic",true)
	game.depart("banker",["ADA","SAM","JO","LEE","PAT"],month,{"oxen":6,"food":1700,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":4})
	return game
func run() -> void:
	var game = outfit()
	check(game.route.nodes.size() == 70 and game.destination() == 1938 and game.route.end_id == "oregon_city", "Full continuous corridor reaches Oregon City")
	game.state.next_landmark = "platte"
	game._arrive_landmark()
	check(game.state.status == "traveling" and game.pending.landmark == "platte", "Platte is now a stop, not a false Oregon arrival")
	game = outfit()
	game.state.next_landmark = "fort_hall"
	game._arrive_landmark()
	var before: Dictionary = game.state.duplicate(true)
	var notes := -1
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("action","") == "notes":notes=index
	check(notes >= 0 and game.choose(notes) and game.state == before, "Landmark advice is readable without spending time or changing supplies")
	game.open_trade()
	check(game.pending.choices[0].effects.food == 200 and game.pending.choices[0].requires.money == 38, "Hall bulk food base reference receives the trading companion's discount")
	var cash: float = game.state.money
	var food: int = game.state.food
	game.choose(0)
	check(game.state.money == cash-38 and game.state.food == food+185 and game.pending.landmark == "fort_hall", "Post resupply returns to stop and charges one day's meals once")
	game = outfit()
	game.state.next_landmark = "barlow_pass"
	game._arrive_landmark()
	check(is_equal_approx(game.pending.choices[0].requires.money,5.6), "Barlow tariff includes wagon and six oxen")
	game.open_trade()
	game.choose(8) # purchase one ox; returning rebuilds the live toll offer
	check(is_equal_approx(game.pending.choices[0].requires.money,5.7), "Toll updates when livestock changes at the stop")
	cash = game.state.money
	game.choose(0)
	check(is_equal_approx(game.state.money,cash-5.7) and game.state.next_landmark == "laurel_hill", "Paying the toll commits once before descending")
	game = outfit()
	game.party_health.daily_onset_chance = 0
	game.survival.forced_weather = "clear"
	game.state.next_landmark = "laurel_hill"
	game._arrive_landmark()
	var day: int = game.state.day
	food = game.state.food
	game.choose(0)
	check(game.state.day == day+2 and game.state.food == food-30 and game.state.next_landmark == "eagle_creek", "Careful descent spends two days and meals without arbitrary accident roll")
	game = outfit()
	game.party_health.daily_onset_chance = 0
	game.survival.forced_weather = "clear"
	game.state.food = 17
	game.state.wheels = 0
	game.state.next_landmark = "laurel_hill"
	game._arrive_landmark()
	game.pending.choices[1].descent_risk = 1.0
	game.choose(1)
	check(game.state.food == 0 and game.state.wheels == 0 and game.state.day == 1, "Hurried descent cannot lose more food or spares than were present after meals")
	check(game.journal.any(func(line): return "Lost 2 lb food and 0 spare wheel(s)" in line), "Descent narrative reports actual clamped accident losses separately from rations")
	for habitat in ["sagebrush","forest"]:
		var bison := false
		for outing in range(30):
			var hunt: Dictionary = game.hunting.begin(7,outing,1200,habitat)
			for animal in hunt.animals:bison = bison or animal.kind == 0
		check(not bison, "Western hunting pool does not promise bison: "+habitat)
	var comparison_store = Store.new()
	var results: Array = []
	var sample = null
	for month in [3,5]:
		var arrivals := 0
		for seed_value in range(6):
			game = outfit(seed_value,month)
			var travel_days := 0
			var stops: Array = []
			var copy = null
			for step in range(1800):
				if game.state.status != "traveling":break
				if game.pending.has("landmark") and game.pending.landmark not in stops:stops.append(game.pending.landmark)
				if game.state.miles > 900 and copy == null:
					var store = Store.new()
					copy = store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
					check(copy != null, "Full-route save restores beyond the old chapter")
				var miles: int = game.state.miles
				Policy.step(game)
				if copy != null:
					Policy.step(copy)
					check(comparison_store.capture(game) == comparison_store.capture(copy), "Western journey continues identically after save/load")
				if game.state.miles > miles:travel_days+=1
			check(game.state.status in ["arrived","lost"], "Long journey terminates without a routing or decision loop")
			if game.state.status == "arrived":
				arrivals+=1
				check(game.state.landmark == "oregon_city" and game.state.miles == (1894 if "columbia_raft" in stops else 1938) and not game.travel() and not game.rest(), "Actual arrival is final, locks time and uses complete guide distance")
				# A party reaching The Dalles in winter finds the Barlow road shut and floats the Columbia instead.
				check("fort_laramie" in stops and "the_dalles" in stops and ("laurel_hill" in stops or "columbia_raft" in stops), "Complete run visits western trading posts and the Barlow descent or the Columbia")
				check("TRAVELERS FINISHED WITH THE PARTY" in game.journey_summary(), "Arrival provides party and resource results")
				if seed_value == 2 and month == 3:sample=game
			results.append({"seed":seed_value,"month":month,"status":game.state.status,"days":game.state.day,"survivors":game.state.party_size,"travel_days":travel_days,"moving_miles_per_day":float(game.state.miles)/maxi(1,travel_days),"cash":game.state.money,"food":game.state.food})
		# A May start is late: the leader often dies on the road, which ends the journey.
		if month == 3:check(arrivals > 0, "Prepared parties can complete the entire road with an early departure")
	var file := FileAccess.open("res://.tools/full-route-runs.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"route_guide_miles":1938,"rules_signature":comparison_store.fingerprint(),"pace_miles":game.survival.data.pace_miles,"terrain_speed_factors":{"mountains":0.8,"forest":0.9,"desert":0.95},"seed_range":[0,5],"departure_months":[3,5],"policy":"banker, 1700 lb start, filling/steady, bulk resupply below 1250 lb at posts, rest below 75 condition or above 50 fatigue","runs":results},"\t"))
	if sample != null:
		var screen = Main.instantiate()
		root.add_child(screen)
		await process_frame
		screen.departure_view.hide()
		screen.game = sample
		screen._refresh()
		check(screen.landscape.scene_id == "oregon_city" and screen.travel_button.disabled, "Arrival UI uses Oregon City art and final state")
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/oregon-arrival.png")
		screen.game = outfit(2,3)
		screen.game.state.next_landmark = "fort_kearny"
		screen.game._arrive_landmark()
		screen._refresh()
		check(screen.landscape.scene_id == "fort_kearny_early", "Pre-June 1848 arrival shows the unbuilt post site")
		screen.game.state.next_landmark = "fort_laramie"
		screen.game._arrive_landmark()
		screen._refresh()
		check(not screen.game.pending.choices.any(func(choice): return choice.get("action","") == "trade"), "The post's store opens from the STORE button only, not a second stop choice")
		screen._open_trade()
		check(screen.post_store_window.visible and screen.landscape.scene_id == "fort_laramie", "Post store counter retains its own arrival background")
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/fort-trade.png")
		screen._close_post_store()
		check(screen.game.pending.landmark == "fort_laramie" and not screen.post_store_window.visible, "Closing the post returns to the unresolved landmark")
		screen.queue_free()
		await process_frame
	print("Full trail: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
