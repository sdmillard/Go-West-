extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Provisions = preload("res://simulation/provisions.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func outfit():
	var game = Simulation.new(57, "classic", true)
	game.depart("banker", ["A","B","C","D","E"], 5, {"oxen":6,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1})
	game.party_health.daily_onset_chance = 0
	game.survival.data.event_chance = 0
	game.survival.forced_weather = "clear"
	return game
func _initialize() -> void:
	var provisions = Provisions.new()
	check(provisions.error.is_empty(), "Provisions data loads")
	var original: Dictionary = provisions.data.duplicate(true)
	var bad := original.duplicate(true)
	bad.weights_lb.wheels = -1
	check(not provisions.load_data(bad) and provisions.data.is_empty(), "Reject invalid weight atomically")
	check(provisions.load_data(original), "Reload valid weights")
	var game = outfit()
	var suggested := {}
	for good in game.outfitter.goods:
		suggested[good.id] = int(good.suggested)
	check(game.outfitter.quote("farmer",suggested).total_cents == 37560 and suggested.food == 1700 and suggested.medicine == 2, "Suggested outfit supplies 1700 lb and two kits and salt for $375.60 within the farmer budget")
	check(is_equal_approx(provisions.cargo(game.state), 1245.0), "Cargo counts food, clothing, ammunition, parts and household gear; excludes oxen")
	check(provisions.movement_factor(1250) > provisions.movement_factor(2500) and provisions.movement_factor(2500) > provisions.movement_factor(3000), "Increasing cargo smoothly slows progress")
	var cart := {"oxen":6,"food":2000,"clothing":50,"bullet_boxes":100,"wheels":3,"axles":3,"tongues":3}
	check(not game.outfitter.quote("banker", cart).valid, "Wealth does not permit an overloaded departure")
	game.state.food = 120
	game.provisions.add_fresh(100, 0)
	game.rest()
	check(game.state.food == 105 and game.provisions.fresh_pounds(game.state.food) == 85, "Eat oldest fresh meat before staples")
	game.pending.clear()
	game.rest()
	game.pending.clear()
	game.rest()
	check(game.state.food == 5 and game.provisions.fresh.is_empty(), "Unpreserved leftovers spoil after two food days; staples survive")
	check(game.supply_history.any(func(entry):return entry.event == "spoilage" and entry.changes.food == -70), "Spoilage records actual pounds lost")
	game = outfit()
	game.state.food = 14
	game.rest()
	var partial: int = game.state.health
	game = outfit()
	game.state.food = 0
	game.rest()
	check(partial > game.state.health and partial < 85, "Partial ration shortage is less severe than no food and does not heal")
	game = outfit()
	game.provisions.add_fresh(100, 0)
	var day: int = game.state.day
	check(game.discard_supply("food", 50) and game.state.food == 550 and game.provisions.fresh_pounds(550) == 50 and game.state.day == day, "Discarding cargo is free in time and removes tracked meat consistently")
	check(not game.discard_supply("oxen", 1) and not game.discard_supply("food", 1000), "Discard cannot mutate livestock or remove nonexistent cargo")
	game.start_hunt()
	game.hunt.meat = 500
	game.state.food = 1840 # gear and other items weigh 645, leaving 15 lb
	game.provisions.fresh.clear()
	check(game.finish_hunt() and game.state.food == 1848 and game.provisions.cargo(game.state)==2500, "Hunt return also respects free cargo space")
	check(game.provisions.expected_days(600,5,2) == 40, "Food estimate uses living party and ration level")
	print("Provisions: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

