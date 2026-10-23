extends SceneTree
const Rules = preload("res://simulation/survival_rules.gd")
const Simulation = preload("res://simulation/trail_engine.gd")
const Store = preload("res://simulation/save_store.gd")
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
	game.depart("farmer", ["Ada", "Sam", "Jo", "Lou", "Pat"], 5,
		{"oxen": 6, "food": 600, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1})
	game.party_health.daily_onset_chance = 0.0
	game.survival.data.event_chance = 0.0
	return game

func region(id: String) -> Dictionary:
	var context: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_context.json"))
	var result: Dictionary = context.regions[id].duplicate()
	result.id = id
	return result

func sample(rules, month: int, region_id: String, days: int = 3000) -> Dictionary:
	rules.start(17)
	var counts := {}
	for day in range(days):
		rules.advance(month, "plains", region(region_id))
		counts[rules.weather.id] = int(counts.get(rules.weather.id, 0)) + 1
	return counts

func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/survival_rules.json"))
	var rules = Rules.new()
	check(rules.error.is_empty(), "Climate rules load")
	var storm_index := -1
	for index in range(data.weather.size()):
		if data.weather[index].id == "thunderstorm":
			storm_index = index
	for change in [["months", [13]], ["months", []], ["regions", {"plains": -1}], ["ox_strain", 9], ["illness_risk", 0]]:
		var invalid := data.duplicate(true)
		invalid.weather[storm_index][change[0]] = change[1]
		check(not rules.load_data(invalid), "Invalid weather climate rejected: %s" % [change])
	for bad in [{"rain": [0.5]}, {"glacier": data.seasonal.river_high_chance.rain}, {"rain": data.seasonal.river_high_chance.rain.map(func(_c): return 2)}]:
		var invalid := data.duplicate(true)
		invalid.seasonal.river_high_chance = bad
		check(not rules.load_data(invalid), "Invalid river stage table rejected")
	check(rules.load_data(data), "Valid climate rules reload")

	# Thunderstorms on the summer plains; heat in sagebrush; neither in winter.
	var platte_june := sample(rules, 6, "plains")
	var snake_july := sample(rules, 7, "sagebrush")
	var forest_july := sample(rules, 7, "forest")
	var winter := sample(rules, 1, "plains")
	check(int(platte_june.get("thunderstorm", 0)) > 200, "Thunderstorms are common on the Platte in June: %s" % [platte_june])
	check(int(platte_june.get("thunderstorm", 0)) > int(sample(rules, 6, "forest").get("thunderstorm", 0)) * 3, "Thunderstorms favour the plains over the western forest")
	check(int(snake_july.get("heat", 0)) > int(forest_july.get("heat", 0)) * 3, "Heat favours sagebrush country over the forest")
	check(not winter.has("thunderstorm") and not winter.has("heat"), "No thunderstorms or heat in January")
	check(not sample(rules, 4, "plains").has("heat"), "Heat is a June to August weather")
	var excluded := data.duplicate(true)
	excluded.weather[storm_index].regions.plains = 0
	rules.load_data(excluded)
	check(not sample(rules, 6, "plains").has("thunderstorm"), "A zero regional weight excludes the weather")
	rules.load_data(data)
	rules.start(17)
	rules.advance(6, "plains", {})
	check(rules.weather.has("id"), "Weather still works without a region id (legacy callers)")

	# Snowmelt rivers.
	check(rules.river_high_chance(6, "snowmelt") > rules.river_high_chance(6, "rain"), "Snow-fed rivers run higher than rain-fed ones in June")
	check(rules.river_high_chance(9, "snowmelt") < rules.river_high_chance(9, "rain"), "Snow-fed rivers fall low by September")
	check(rules.river_high_chance(6, "snowmelt") > rules.river_high_chance(9, "snowmelt") * 3, "The June melt is far above the autumn low")
	var game = outfit()
	check(game.route.nodes.green_river.get("river_source") == "snowmelt" and game.route.nodes.kansas_river.get("river_source", "rain") == "rain", "Green River is snow-fed; the Kansas is rain-fed")

	# Heat strains the team and raises illness risk; thunderstorms can stampede the herd.
	var hot = outfit(5)
	var mild = outfit(5)
	hot.survival.forced_weather = "heat"
	mild.survival.forced_weather = "clear"
	hot.travel(); mild.travel()
	check(int(hot.state.ox_health) < int(mild.state.ox_health), "A hot travel day strains the team more than a clear one")
	var stampede: Dictionary = {}
	for event in game.trail_events.events:
		if event.id == "stampede":
			stampede = event
	check(not stampede.is_empty() and "thunderstorm" in stampede.weather, "Stampede event loads, tied to thunderstorms")
	game = outfit()
	game._present_trail_event(stampede)
	check(int(game.state.oxen) == 4 and game.pending.id == "stampede", "A stampede scatters two oxen")
	var day: int = game.state.day
	game.choose(0)
	check(int(game.state.oxen) == 6 and int(game.state.day) == day + 2, "Two days of searching recovers both oxen")
	game = outfit()
	game.state.oxen = 1
	game.survival.forced_weather = "thunderstorm"
	game.survival.set_weather("thunderstorm")
	var offered := false
	for index in range(200):
		game.pending = {}
		game.survival.last_events.clear()
		game._roll_trail_event()
		offered = offered or game.pending.get("id", "") == "stampede"
	check(not offered, "No stampede with fewer than two oxen")

	# Weather ids survive a save.
	var store = Store.new()
	game = outfit()
	game.survival.set_weather("thunderstorm")
	var copy = store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	check(copy != null and copy.survival.weather.id == "thunderstorm", "New weather persists through save and load")

	print("Climate checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures else 0)
