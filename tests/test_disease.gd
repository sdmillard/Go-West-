extends SceneTree
const Health = preload("res://simulation/party_health.gd")
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
	game.survival.forced_weather = "clear"
	return game

# Counts which illness a lone healthy traveler catches on a guaranteed onset day.
func onset_counts(month: int, region: String, year: int = 1848, samples: int = 400) -> Dictionary:
	var counts := {}
	var health = Health.new()
	for index in range(samples):
		health.start(["Ada"], index)
		health.daily_onset_chance = 1.0
		health.tick(1, false, 1.0, 2, year, month, region)
		for active in health.members[0].conditions:
			counts[active.id] = int(counts.get(active.id, 0)) + 1
	return counts

func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/health_conditions.json"))
	var health = Health.new()
	check(health.error.is_empty() and health.conditions.has("mountain_fever"), "Disease data loads, including mountain fever")
	for change in [["months", [1, 1]], ["spread_chance", 1.5], ["immunizing", "yes"], ["weight", -1], ["regions", {"plains": -2}], ["region_default", "none"]]:
		var invalid := data.duplicate(true)
		invalid.conditions[0][change[0]] = change[1]
		check(not health.load_data(invalid) and health.conditions.is_empty(), "Invalid disease data rejected: " + change[0])
	check(health.load_data(data), "Valid disease data reloads")

	# Region and season decide which illness appears.
	check(health.onset_weight("mountain_fever", 7, "plains") == 0.0 and health.onset_weight("mountain_fever", 7, "highcountry") > 0.0, "Mountain fever belongs to high country")
	check(health.onset_weight("dysentery", 7, "plains") > health.onset_weight("dysentery", 1, "plains") * 2.0, "Waterborne illness peaks in hot months")
	check(health.onset_weight("measles", 4, "woodland") > health.onset_weight("measles", 8, "sagebrush") * 3.0, "Measles is an early-trail illness")
	check(health.onset_weight("exhaustion", 0, "") == 2.0, "Without month or region the base weight applies")
	var plains := onset_counts(7, "plains")
	var mountains := onset_counts(7, "highcountry")
	check(not plains.has("mountain_fever") and int(mountains.get("mountain_fever", 0)) > 80, "Mountain fever strikes only in the mountains: %s / %s" % [plains, mountains])
	check(int(plains.get("dysentery", 0)) > int(mountains.get("dysentery", 0)), "Dysentery is commoner on the Platte than in the mountains in July")
	check(not plains.has("cholera") and not mountains.has("cholera"), "Cholera stays locked in 1848")
	check(onset_counts(7, "plains", 1849).has("cholera"), "Cholera can appear from 1849")
	check(onset_counts(7, "plains") == plains, "Onset replays deterministically from the same seed")

	# Contagion: measles moves through the party, mountain fever does not.
	health.start(["Ada", "Sam", "Jo", "Lou", "Pat"], 7)
	health.daily_onset_chance = 0.0
	health.begin_condition(0, "measles", 0)
	for day in range(1, 31):
		health.tick(day, false)
	var caught := 0
	for member in health.members.slice(1):
		caught += 1 if member.history.any(func(entry): return "caught measles from" in entry) else 0
	check(caught >= 1, "Measles spreads to others in the party, with the source named")
	check(health.members[0].get("immune", []) == ["measles"], "Measles survivors become immune")
	check(not health.begin_condition(0, "measles", 31), "An immune survivor cannot catch measles again")
	check(health.begin_condition(0, "dysentery", 31), "Immunity covers only that illness")
	health.start(["Ada", "Sam", "Jo", "Lou", "Pat"], 7)
	health.daily_onset_chance = 0.0
	health.begin_condition(0, "mountain_fever", 0)
	for day in range(1, 12):
		health.tick(day, false)
	var spread := false
	for member in health.members.slice(1):
		spread = spread or not member.history.is_empty()
	check(not spread and health.members[0].get("immune", []).is_empty(), "Mountain fever is not passed person to person and leaves no immunity")
	health.start(["Ada", "Sam"], 3)
	health.daily_onset_chance = 0.0
	health.begin_condition(0, "dysentery", 0)
	health.members[1].conditions.append({"id": "broken_arm", "started_day": 0, "elapsed": 0, "severity": 1})
	health.conditions.dysentery.spread_chance=1.0
	health.tick(1,false)
	check(health.members[1].conditions.size() == 2, "An unrelated injury does not prevent another illness")

	# The engine passes the current region into the onset roll.
	var west := 0
	var east := 0
	for seed_value in range(60):
		var game = outfit(seed_value)
		game.party_health.daily_onset_chance = 1.0
		game.state.landmark = "south_pass"
		game._tick_day(true)
		for member in game.party_health.members:
			west += member.conditions.filter(func(active): return active.id == "mountain_fever").size()
		game = outfit(seed_value)
		game.party_health.daily_onset_chance = 1.0
		game._tick_day(true)
		for member in game.party_health.members:
			east += member.conditions.filter(func(active): return active.id == "mountain_fever").size()
	check(west > 0 and east == 0, "Travel days use the current region: mountain fever %d at South Pass, %d at Independence" % [west, east])

	# Immunity survives a save and malformed immunity is rejected.
	var store = Store.new()
	var game = outfit()
	game.party_health.members[2].immune = ["measles"]
	var copy = store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	check(copy != null and copy.party_health.members[2].get("immune") == ["measles"], "Immunity persists through save and load")
	for bad_value in [["dysentery"], ["missing"], "measles"]:
		var bad: Dictionary = JSON.parse_string(JSON.stringify(store.capture(game)))
		bad.party[2].immune = bad_value
		check(store.restore(bad) == null, "Malformed immunity rejected: %s" % [bad_value])

	# Scurvy: only after a long run without fresh meat, and it mends only with fresh food.
	health = Health.new()
	for change in [["condition", "measles"], ["onset_days", 0], ["max_chance", 2]]:
		var invalid := data.duplicate(true)
		invalid.scurvy[change[0]] = change[1]
		check(not health.load_data(invalid), "Invalid scurvy rules rejected: " + change[0])
	health.load_data(data)
	check(not health.automatic_conditions(1850).has("scurvy"), "Scurvy is never a random illness")
	check(health.scurvy_chance(45) == 0.0 and health.scurvy_chance(46) > 0.0 and health.scurvy_chance(90) > health.scurvy_chance(46) and health.scurvy_chance(1000) == float(data.scurvy.max_chance), "Scurvy risk starts after the onset period and rises to a cap")
	var scorbutic := 0
	for seed_value in range(40):
		health.start(["Ada", "Sam", "Jo", "Lou", "Pat"], seed_value)
		health.daily_onset_chance = 0.0
		health.tick(1, false, 1.0, 2, 1848, 7, "plains", 30)
		for member in health.members:
			check(member.conditions.is_empty(), "No scurvy within the onset period")
		health.tick(2, false, 1.0, 2, 1848, 7, "plains", 120)
		for member in health.members:
			scorbutic += member.conditions.filter(func(active): return active.id == "scurvy").size()
	check(scorbutic > 0, "Scurvy appears after months without fresh meat (%d cases)" % scorbutic)
	health.start(["Ada"], 1)
	health.daily_onset_chance = 0.0
	health.scurvy = {}
	health.begin_condition(0, "scurvy", 0)
	for day in range(1, 31):
		health.tick(day, true, 1.0, 2, 1848, 7, "plains", 50 + day)
	check(health.members[0].conditions.size() == 1 and "vitamin-C foods" in health.description(0), "Scurvy does not mend without fresh food")
	health.members[0].health = 85
	for day in range(31, 46):
		health.tick(day, false, 1.0, 2, 1848, 7, "plains", 0)
	check(health.members[0].conditions.is_empty(), "Fresh food lets scurvy mend")
	game = outfit()
	game._tick_day(true)
	check(game.party_health.days_without_fresh == 1, "Meals of staples count as days without fresh meat")
	game.provisions.add_meat(40, game.state.day)
	game.state.food += game.provisions.meat_units(40)
	game._tick_day(true)
	# Freshly killed meat carries a little vitamin C (balance pass, October 31): it holds off the deficit but is no full produce portion.
	check(game.party_health.days_without_fresh < 2 and float(game.livestock.last_meal.vitamin) < game.state.party_size*0.5, "Fresh meat slows the vitamin deficit without counting as a full produce portion")
	game.party_health.days_without_fresh = 70
	copy = store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	check(copy != null and copy.party_health.days_without_fresh == 70, "Days without fresh meat persist through save and load")

	print("Disease checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures else 0)
