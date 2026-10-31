extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Catalog = preload("res://simulation/event_catalog.gd")
var checks := 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func _initialize() -> void:
	var setup_game = Simulation.new(1848, "classic", true)
	var outfit_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/outfitting.json"))
	var bad_outfitter = Simulation.Outfitting.new()
	var bad_data := outfit_data.duplicate(true)
	bad_data.goods[0].price_cents = -1
	check(not bad_outfitter.load_data(bad_data) and bad_outfitter.goods.is_empty(), "Malformed prices fail without a partially loaded shop")
	bad_data = outfit_data.duplicate(true)
	bad_data.goods.append(bad_data.goods[0].duplicate(true))
	check(not bad_outfitter.load_data(bad_data), "Duplicate shop IDs rejected")
	bad_data = outfit_data.duplicate(true)
	bad_data.professions.pop_back()
	check(not bad_outfitter.load_data(bad_data), "Incomplete profession data rejected")
	check(bad_outfitter.load_data(outfit_data) and bad_outfitter.error.is_empty(), "Valid shop reload clears earlier error")
	var cart := {"oxen": 6, "food": 600, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1}
	var names := ["Ada", "Sam", "Jo", "Lee", "Pat"]
	check(setup_game.state.status == "outfitting" and not setup_game.travel() and not setup_game.rest(), "Setup blocks time advancement")
	var quote: Dictionary = setup_game.outfitter.quote("farmer", cart)
	check(quote.valid and quote.total_cents == 38500 and quote.remaining_cents == 29000, "600 lb fixture outfit with its $75 wagon totals $385 with $290 remaining")
	var setup_before: Dictionary = setup_game.state.duplicate(true)
	var original_rng: int = setup_game.rng.state
	var expensive := cart.duplicate()
	expensive.clothing = 50
	check(not setup_game.depart("farmer", names, 4, expensive), "Over-budget departure rejected")
	check(not setup_game.depart("banker", ["", "Sam", "Jo", "Lee", "Pat"], 4, cart), "Empty names rejected")
	check(not setup_game.depart("banker", names, 2, cart), "Out-of-season departure rejected")
	check(not setup_game.depart("unknown", names, 4, cart), "Unknown profession rejected")
	for bad in [-1, 1.5, 2001, INF, NAN, "600"]:
		var invalid_cart := cart.duplicate()
		invalid_cart.food = bad
		check(not setup_game.depart("banker", names, 4, invalid_cart), "Invalid quantity rejected: " + str(bad))
	var unknown := cart.duplicate()
	unknown.free_money = 1
	check(not setup_game.depart("banker", names, 4, unknown), "Unknown goods rejected")
	var no_oxen := cart.duplicate()
	no_oxen.oxen = 0
	check(not setup_game.depart("banker", names, 4, no_oxen), "Wagon requires oxen")
	check(setup_game.state == setup_before and setup_game.rng.state == original_rng, "Rejected setups preserve state and RNG")
	cart.food = 601
	check(setup_game.depart("farmer", names, 8, cart), "Valid departure accepted")
	check(is_equal_approx(setup_game.state.money, 289.95) and setup_game.state.bullets == 200 and setup_game.state.parts == 3, "Cents, ammunition boxes and typed parts accounted")
	check(setup_game.calendar().month == 8 and setup_game.calendar().day == 1, "Chosen departure month drives calendar")
	names[0] = "Changed"
	cart.food = 0
	check(setup_game.state.party[0] == "Ada" and setup_game.state.food == 601, "Caller cannot mutate committed inventory or names")
	check(not setup_game.depart("banker", names, 3, cart) and is_equal_approx(setup_game.state.money, 289.95), "Departure cannot be charged twice")
	setup_game.travel()
	setup_game.travel()
	check(setup_game.state.food == 571 and setup_game.state.rations == 2 and setup_game.state.pace == 0, "Departure starts steady and filling; consumes 15 lb/day")
	setup_game.choose(0)
	if setup_game.pending.get("id", "") == "muddy_trail":
		setup_game.choose(0)
	check(setup_game.state.wheels == 0 and setup_game.state.axles == 1 and setup_game.state.tongues == 1 and setup_game.state.parts == 2, "Wheel encounter consumes only a wheel")
	for turn in range(80):
		if setup_game.pending.get("landmark", "") == "kansas_river":
			break
		if setup_game.pending.is_empty():
			setup_game.travel()
		else:
			setup_game.choose(0)
	setup_game.choose(0)
	check(is_equal_approx(setup_game.state.money, 288.95), "Period ferry payment preserves cents")
	var platte_arrivals := 0
	for occupation in ["banker", "carpenter", "farmer"]:
		for seed_value in range(20):
			var outfitted = Simulation.new(seed_value, "classic", true, "platte")
			var supplies := {"oxen": 6, "food": 600, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1}
			check(outfitted.depart(occupation, ["A", "B", "C", "D", "E"], 3 + seed_value % 6, supplies), "Seeded setup accepted")
			for turn in range(400):
				if outfitted.state.status != "traveling":
					break
				preload("res://tests/survival_policy.gd").step(outfitted)
			# The leader's death ends a journey; anything else must still reach the Platte.
			if outfitted.state.status == "arrived":platte_arrivals += 1
			check((outfitted.state.status == "arrived" and outfitted.state.miles == 317 and outfitted.state.money >= 0 and outfitted.state.party.size() == 5) or (outfitted.state.status == "lost" and not outfitted.party_health.members[0].alive), "Outfitted journey reaches Platte corridor unless the leader dies")
	check(platte_arrivals >= 54, "Nine in ten outfitted parties reach the Platte corridor")
	var game = Simulation.new()
	check(game.error.is_empty(), "Bundled JSON loads")
	check(game.travel(), "Travel accepted")
	check(game.state.day == 1 and game.state.food == 170, "Travel consumes one day of food for five")
	check(game.state.miles >= 16 and game.state.miles <= 20, "Strenuous wagon distance in bounds")
	var miles: int = game.state.miles
	var health: int = game.state.health
	game.rest()
	check(game.state.miles == miles and game.state.health == health + 7, "Rest heals without mileage")
	check(game.pending.id == "muddy_trail", "Historical day threshold triggers on rest too")
	var before: Dictionary = game.state.duplicate(true)
	check(not game.travel() and not game.rest(), "Pending event blocks time actions")
	check(not game.choose(-1) and not game.choose(99) and game.state == before, "Invalid choices cannot mutate state")
	check(game.choose(0) and game.state.parts == 1, "Spare part choice applies")
	check(not game.choose(0), "Choice cannot be applied twice")
	game.configure(99, -99)
	check(game.state.pace == 2 and game.state.rations == 0, "Settings are clamped")
	var hungry = Simulation.new()
	hungry.state.food = 0
	hungry.state.health = 10
	hungry.rest()
	check(hungry.state.status == "lost" and hungry.state.health == 0, "Rest cannot heal starvation")
	check(not hungry.travel() and not hungry.rest(), "Terminal loss blocks actions")
	var poor = Simulation.new()
	poor.state.miles = 102
	poor.state.day = 2
	poor.seen.append("muddy_trail")
	poor._schedule_event()
	poor.state.money = 0
	check(not poor.can_choose(0) and poor.can_choose(1), "River always offers a free choice")
	check(not poor.choose(0) and poor.state.money == 0, "Unaffordable ferry is rejected")
	poor.state.health = 1
	poor.state.food = 0
	poor.choose(1)
	check(poor.state.status == "lost", "Death during crossing cannot become victory")
	var classic = Simulation.new(42)
	for i in range(1000):
		check(classic.roll_absurd(0).is_empty(), "Classic hard-excludes absurd roll")
	var wild = Simulation.new(42, "unhinged")
	check(not wild.roll_absurd(0.009999).is_empty(), "Roll just below 1% selects content")
	check(wild.roll_absurd(0.01).is_empty() and wild.roll_absurd(0.99).is_empty(), "1% upper boundary excluded")
	for event in wild.catalog.events:
		if event.category != "absurd":
			continue
		var sample = Simulation.new(42, "unhinged")
		sample._present(event)
		sample.choose(0)
		match event.id:
			"found_lightsaber":
				check("lightsaber" in sample.state.items, "Lightsaber persists in inventory")
			"corolla":
				sample.seen.append("muddy_trail")
				sample.travel()
				check(sample.state.miles == 30 and sample.state.fuel == 2, "Corolla uses fuel and covers 30 miles")
				sample.state.fuel = 0
				sample.travel()
				check(sample.state.vehicle == "wagon", "Empty Corolla falls back to wagon")
			"elder_god":
				check(sample.state.food == 160 and sample.state.health == 95, "Elder god exchanges food for health")
		wild.seen.append(event.id)
	check(wild.roll_absurd(0).is_empty(), "Exhausted absurd pool returns no encounter")
	var a = Simulation.new(93, "unhinged")
	var b = Simulation.new(93, "unhinged")
	for i in range(8):
		for sim in [a, b]:
			if not sim.pending.is_empty():
				sim.choose(0)
			else:
				sim.travel()
		check(a.state == b.state and a.pending == b.pending and a.journal == b.journal, "Same seed/actions produce same run")
	var invalid = Catalog.new()
	check(not invalid.load_data({}), "Reject non-array content")
	var content: Array = game.catalog.events.duplicate(true)
	content.append(content[0].duplicate(true))
	check(not invalid.load_data(content) and invalid.events.is_empty(), "Duplicate IDs fail atomically")
	content = game.catalog.events.duplicate(true)
	content[0].choices[0].effects = {"execute": "code"}
	check(not invalid.load_data(content), "Unknown effects rejected")
	content = game.catalog.events.duplicate(true)
	content[0].choices[0].effects = {"days": -1}
	check(not invalid.load_data(content), "Negative delay rejected")
	content = game.catalog.events.duplicate(true)
	content[1].choices[1].risk.probability = 2
	check(not invalid.load_data(content), "Risk probability outside range rejected")
	check(not invalid.load_file("res://data/missing.json"), "Missing content gives useful failure")
	# Seed sweep exercises the actual scheduler and safe route completion, not a second model.
	var example_seeds: Dictionary = {}
	for seed_value in range(1000):
		var sim = Simulation.new(seed_value, "unhinged")
		var turns := 0
		while sim.state.status == "traveling" and turns < 40:
			turns += 1
			if not sim.pending.is_empty():
				if sim.pending.category == "absurd" and not example_seeds.has(sim.pending.id):
					example_seeds[sim.pending.id] = seed_value
				sim.choose(0 if sim.can_choose(0) else 1)
			else:
				sim.travel()
		check(sim.state.status == "arrived", "Safe policy completes seed %d" % seed_value)
		check(sim.state.food >= 0 and sim.state.health > 0 and sim.state.miles == 102, "Arrival invariants seed %d" % seed_value)
	# A deterministic grid verifies the configured probability without flaky statistical tolerances.
	var hits := 0
	var odds = Simulation.new(5, "unhinged")
	for i in range(10000):
		if not odds.roll_absurd(float(i) / 10000.0).is_empty():
			hits += 1
	check(hits == 100, "1% of uniformly spaced rolls selects absurd pool")
	print("Example seeds (default settings, first choices): ", example_seeds)
	print("Simulation: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

