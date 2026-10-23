extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Survival = preload("res://simulation/survival_rules.gd")
const Main = preload("res://ui/main.tscn")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func outfit(seed_value: int = 1848):
	var game = Simulation.new(seed_value, "classic", true)
	game.depart("banker", ["Ada", "Sam", "Jo", "Lee", "Pat"], 4,
		{"oxen": 6, "food": 600, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1, "medicine": 4})
	game.survival.forced_weather = "clear"
	game.survival.data.event_chance = 0
	game.party_health.daily_onset_chance = 0
	game.seen.append("muddy_trail")
	return game

func run() -> void:
	var rules = Survival.new()
	check(rules.error.is_empty(), "Survival rules load")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/survival_rules.json"))
	var flat := data.duplicate(true)
	flat.team_speed_factors=[0,0.25,0.5,0.75,1,1,1]
	check(rules.load_data(flat) and rules.team_factor(6)==1,"Bonus can be disabled through data without changing the four-ox baseline")
	for factors in [[0,0.25,0.5,0.75,1,1.05], [0,0.25,0.5,0.75,1,1.1,1.05], [0,0.25,0.5,0.75,1,1.05,2], [0,0.25,0.5,0.75,0.9,1.05,1.1], [0,0.25,0.5,0.75,1,"bad",1.1]]:
		var malformed := data.duplicate(true)
		malformed.team_speed_factors=factors
		check(not rules.load_data(malformed) and rules.data.is_empty(),"Reject malformed team bonuses atomically")
	for bad in [-1, 2, "bad"]:
		var invalid := data.duplicate(true)
		invalid.event_chance = bad
		check(not rules.load_data(invalid) and rules.data.is_empty(), "Reject invalid event chance atomically")
	var invalid := data.duplicate(true)
	invalid.weather[0].speed = 0
	check(not rules.load_data(invalid), "Reject zero weather movement")
	invalid = data.duplicate(true)
	invalid.trade_lots[0].sell_cents = invalid.trade_lots[0].buy_cents
	check(not rules.load_data(invalid), "Reject a buy/sell arbitrage loop")
	check(rules.load_data(data), "Rules recover after rejected data")
	var events: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_events.json"))
	var catalog = Simulation.Catalog.new()
	var bad_events := events.duplicate(true)
	bad_events[0].erase("weight")
	check(not catalog.load_data(bad_events, true), "Repeatable catalog requires event weights")
	bad_events = events.duplicate(true)
	bad_events[0].choices[0]["rest"] = "yes"
	check(not catalog.load_data(bad_events, true), "Resting-day flag must be boolean")
	bad_events = events.duplicate(true)
	bad_events[0]["weather"] = ["typo"]
	check(not catalog.load_data(bad_events, true), "Unknown weather eligibility is rejected")
	check(catalog.load_data(events, true), "Complete repeatable catalog validates")
	invalid = data.duplicate(true)
	invalid.pace_miles = [16, 12, 24]
	check(not rules.load_data(invalid), "Nominal pace table must increase")
	invalid = data.duplicate(true)
	invalid.rest_recovery = [3, 5]
	check(not rules.load_data(invalid), "Recovery table must cover every ration level")
	rules.load_data(data)
	var recovery: Array[int] = []
	for rations in range(3):
		var resting = outfit()
		for member in resting.party_health.members:
			member.health = 50
		resting.state.health = 50
		resting.configure(0, rations)
		resting.rest()
		recovery.append(int(resting.state.health))
	check(recovery[0] < recovery[1] and recovery[1] < recovery[2], "Better rations improve actual rest recovery, not just the tooltip")
	var period = outfit()
	check("cholera" not in period.party_health.automatic_conditions(1848) and "cholera" in period.party_health.automatic_conditions(1849), "Automatic cholera respects the documented epidemic-year boundary")
	check(period.party_health.automatic_conditions(1848).all(func(id): return period.party_health.conditions[id].kind == "illness"), "Nutrition-linked illness rolls cannot spontaneously break limbs")
	var injury_types: Array = []
	var injuries_mild := true
	for seed_value in range(20):
		var accident = outfit(seed_value)
		var definition: Dictionary = accident.trail_events.events.filter(func(event): return event.id == "broken_arm")[0]
		accident._present_trail_event(definition)
		var patient: Dictionary = accident.party_health.members[accident.pending.member_id]
		injury_types.append(patient.conditions[0].id)
		injuries_mild = injuries_mild and patient.conditions[0].severity == 1
	check("broken_arm" in injury_types and "broken_leg" in injury_types and injuries_mild, "Accidents can injure either limb independently of the nutrition-severity formula")
	var game = outfit()
	check(game.state.medicine == 4 and is_equal_approx(game.state.money, 1070.0), "Care kits are purchased and charged at departure")
	var dry = outfit(1)
	var wet = outfit(1)
	wet.survival.forced_weather = "heavy_rain"
	dry.travel()
	wet.travel()
	check(wet.state.miles < dry.state.miles and wet.state.day == dry.state.day, "Heavy rain slows actual travel, not the clock")
	var clothed = outfit(2)
	var exposed = outfit(2)
	clothed.survival.forced_weather = "blizzard"
	exposed.survival.forced_weather = "blizzard"
	exposed.state.clothing = 0
	clothed.travel()
	exposed.travel()
	check(exposed.party_health.members[0].health < clothed.party_health.members[0].health, "Clothing protects individual health from exposure")
	check(exposed.survival.weather.id == "blizzard", "Deterministic scenario selects actual weather")
	var small = outfit(3)
	var strong = outfit(3)
	small.state.oxen = 2
	small.state.ox_health = 50
	small.travel()
	strong.travel()
	check(small.state.miles < strong.state.miles, "Team size and condition affect travel speed")
	var fatigue: int = strong.state.fatigue
	strong.state.ox_health = 50
	strong.rest()
	check(strong.state.fatigue < fatigue and strong.state.ox_health > 50, "Rest restores working team condition")
	rules.set_weather("clear")
	check(rules.movement_factor(6, 100, 0, 600, "mountains") < rules.movement_factor(6, 100, 0, 600), "Terrain model supports slower mountain travel before route extension")
	game = outfit()
	game.state.next_landmark = "kansas_river"
	game._arrive_landmark()
	game.survival.forced_weather = "heavy_rain"
	game.survival.wet_ground = 3
	game.choose(game.pending.choices.size() - 1)
	check(game.state.river_stage == "high" and game.pending.choices[1].risk == 0.65, "Rain while resting raises the river and changes crossing risk")
	var landmark: Dictionary = game.pending.duplicate(true)
	game.open_trade()
	var cash: float = game.state.money
	var food: int = game.state.food
	var day: int = game.state.day
	game.choose(0)
	check(game.state.money == cash - 17.1 and game.state.food == food + 50 - 15 and game.state.day == day + 1, "Trading companion's discount on the passing traders' markup charges money, inventory and one day's rations once")
	check(game.pending.landmark == landmark.landmark, "Trading returns to the unresolved river stop")
	game.open_trade()
	day = game.state.day
	food = game.state.food
	game.choose(0)
	check(game.state.day == day and game.state.food == food + 50, "Further trades on the same visit to passing traders take no extra day or meals")
	game.open_trade()
	game.state.money = 0
	var before: Dictionary = game.state.duplicate(true)
	var rng_before: int = game.survival.rng.state
	check(not game.choose(0) and game.state == before and game.survival.rng.state == rng_before, "Rejected unaffordable transaction changes nothing")
	game.choose(game.pending.choices.size() - 1)
	check(game.pending.has("landmark"), "Backing out preserves unresolved landmark")
	game.state.river_stage = "high"
	game.survival.wet_ground = 0
	before = game.state.duplicate(true)
	landmark = game.pending.duplicate(true)
	game.open_trade()
	game.choose(game.pending.choices.size() - 1)
	check(game.state == before and game.pending == landmark, "Opening and cancelling services cannot change dry-day river stage or odds for free")
	game = outfit()
	game.party_health.begin_condition(1, "cholera", 0, 3)
	game.party_health.members[1].health = 50
	game.open_care()
	# First pair belongs to Ada; Sam is the second pair.
	var care_index := -1
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("member_id", -1) == 1 and game.pending.choices[index].get("care", 0) == 6:
			care_index = index
	game.choose(care_index)
	check(game.state.medicine == 3 and game.state.day == 1 and game.party_health.members[1].conditions[0].severity == 2, "Care targets the selected traveler, consumes a kit and reduces severity")
	check("Received care" in game.party_health.description(1), "Medical care appears in personal history")
	if not game.pending.is_empty():
		game.choose(0)
	game.state.next_landmark="fort_laramie"
	game._arrive_landmark()
	game.open_care()
	cash = game.state.money
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("member_id", -1) == 1 and game.pending.choices[index].get("care", 0) == 12:
			game.choose(index)
			break
	check(game.state.money == cash - 20, "Medical attention charges BASIC's $20 bill through an explicit choice")
	game = outfit()
	food = game.state.food
	var ammo: int = game.state.bullets
	game.state.fatigue = 40
	check(game.start_hunt(), "Hunting can begin between landmarks")
	check(game.state.day == 1 and game.state.food == food - 15 and game.state.fatigue < 40 and not game.travel(), "Hunt consumes one day's rations, rests the team and locks travel")
	game.hunt.animals = [{"kind": 0, "x": 100.0, "y": 75, "direction": 1, "escaped": false}, {"kind": 1, "x": 200.0, "y": 98, "direction": 1, "escaped": false}, {"kind": 2, "x": 300.0, "y": 121, "direction": -1, "escaped": false}]
	check(game.hunt_shot(-1), "Miss consumes a shot")
	for target in range(3):
		game.advance_hunt(1.5)
		check(game.hunt_shot(target), "Distinct available target resolves after reload")
	check(not game.hunt_shot(0) and game.state.bullets == ammo - 4, "Already-taken target cannot duplicate meat or ammunition use")
	check(game.finish_hunt() and game.state.food == food - 15 + 100, "Healthy willing party hauls up to two hundred physical pounds for one hundred meal units")
	before = game.state.duplicate(true)
	check(not game.finish_hunt() and game.state == before, "Finishing hunting twice cannot duplicate food or time")
	game = outfit()
	game.state.bullets = 0
	before = game.state.duplicate(true)
	check(not game.start_hunt() and game.state == before, "No ammunition blocks hunting without spending time")
	game.state.oxen = 0
	game.travel()
	check(game.pending.id == "no_team" and game.state.day == 0, "No team blocks progress with a recoverable camp notice")
	game.choose(0)
	game.open_trade()
	game.choose(8)
	check(game.state.oxen == 1 and game.state.day == 1, "A replacement ox can be acquired after losing the team")
	game = outfit()
	check(game.trail_events.events.size() == 17, "All sixteen BASIC selector categories plus rider tactics are present")
	for event in game.trail_events.events:
		game = outfit()
		game._present_trail_event(event)
		check(not game.pending.is_empty() and game.pending.id == event.id, "Event is actually presentable: " + event.id)
		var selected := false
		for index in range(game.pending.choices.size()):
			if game.can_choose(index):
				selected = game.choose(index)
				break
		check(selected, "Event has a working available resolution: " + event.id)
		for branch in range(event.choices.size()):
			var sample = outfit()
			sample._present_trail_event(event)
			check(sample.can_choose(branch) and sample.choose(branch), "Every event branch is usable with adequate resources: %s/%d" % [event.id, branch])
	game = outfit()
	var fire: Dictionary = game.trail_events.events.filter(func(event): return event.id == "wagon_fire")[0]
	game.state.food = 3
	game._present_trail_event(fire)
	check(game.state.food == 0 and game.supply_history[0].changes.food == -3, "Event history records actual clamped supplies lost")
	check(not game.survival.eligible(fire, game.state.day + 1) and game.survival.eligible(fire, game.state.day + 5), "Repeated mishaps have a cooldown rather than a once-only seen flag")
	var screen = Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.next_button.pressed.emit()
	screen.departure_view.quantities.medicine.value = 2
	if "--capture" in OS.get_cmdline_user_args():
		await capture("store")
	screen.departure_view.depart_button.pressed.emit()
	screen.game.party_health.daily_onset_chance = 0
	screen.game.survival.data.event_chance = 0
	screen.game.survival.forced_weather = "clear"
	screen._show_options()
	check(screen.options_window.visible and not screen.traveling, "Trail Options opens a paused action menu")
	screen.hunt_button.pressed.emit()
	check(screen.hunt_window.visible and screen.game.state.day == 1, "Mouse menu starts the actual hunt")
	screen.hunt_view.set_process(false)
	if "--capture" in OS.get_cmdline_user_args():
		await capture("hunting")
	# Place the hunter next to a target to exercise the actual mouse hit path.
	screen.game.hunt.animals = [{"kind": 1, "x": 100.0, "y": 98, "direction": 1, "escaped": false}]
	screen.game.hunt.hunter = Vector2(114, 132)
	screen.game.hunt.cover = [Rect2(300, 90, 12, 14)]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = screen.hunt_view.target_rect(0).get_center()
	screen.hunt_view._gui_input(click)
	check(screen.game.hunt.targets == [0] and screen.game.hunt.shots == 1, "Clicking drawn animal reaches engine hit resolution")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("hunting-shot")
	screen._finish_hunt()
	check(screen.record_notice.visible and "lb brought to camp" in screen.record_notice.dialog_text, "Returning displays actual hunting yield and waste")
	screen.record_notice.hide()
	check(not screen.hunt_window.visible and screen.game.hunt.is_empty(), "Returning to camp finishes the hunt once")
	if not screen.game.pending.is_empty():
		screen._choose(0)
	screen.game.survival.forced_weather = "heavy_rain"
	screen._rest()
	screen.rest_window.hide()
	screen._confirm_rest()
	screen.record_notice.hide()
	check("HEAVY RAIN" in screen.stats.text and screen.landscape.weather_id == "heavy_rain", "Weather appears in the actual status and landscape")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("weather-rain")
	for notice in range(4):
		if screen.game.pending.is_empty():
			break
		screen._choose(0)
	screen._open_trade()
	check(screen.service_window.visible and screen.service_rows.get_child_count() > 10, "Trading opens a readable scrolling offers dialog")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("trail-trade")
	before = screen.game.state.duplicate(true)
	screen._cancel_service()
	check(not screen.service_window.visible and screen.game.state == before, "Closing trade costs no time or supplies")
	screen._new_journey()
	check(screen.game.hunt.is_empty() and not screen.hunt_window.visible and not screen.options_window.visible, "Restart cancels activity UI without stale completion")
	screen.queue_free()
	await process_frame
	print("Survival: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + name + ".png")

