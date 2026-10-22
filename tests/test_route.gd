extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Route = preload("res://simulation/route_catalog.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	var route = Route.new()
	check(route.error.is_empty() and route.total_miles == 1938, "Full corridor loads with 1938 reported guide miles")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/route.json"))
	var table: Array = JSON.parse_string(FileAccess.get_file_as_string("res://research/PALMER_DISTANCE_TABLE.json"))
	var mileage := 0
	var at: String = data.start
	for node in data.nodes:
		if node.next.is_empty():
			continue
		var edge: Dictionary = node.next[0]
		var sum := 0
		for row in edge.source_rows:
			sum += int(row)
		check(sum == edge.miles, "Segment matches cited mileage contributions: " + node.id)
		if not edge.has("allocation_note"):
			var primary_sum := 0
			for row_id in edge.source_table_rows:
				for row in table:
					if row.row == row_id:primary_sum+=int(row.cells[-1])
			check(primary_sum == edge.miles, "Direct leg matches the extracted primary-source row IDs: "+node.id)
	while not route.nodes[at].next.is_empty():
		var edge: Dictionary = route.nodes[at].next[0]
		mileage += int(edge.miles)
		at = edge.to
		if at == "kansas_river":
			check(mileage == 81, "Kaw is guide mile 81, not the game's 102")
		if at == "big_blue":
			check(mileage == 174 and not route.nodes[at].has("ferry_dollars"), "Big Blue is guide mile 174 without a post-1848 ferry")
	var invalid := data.duplicate(true)
	invalid.nodes[0].next[0].to = "missing"
	check(not route.load_data(invalid) and route.nodes.is_empty(), "Missing road endpoint fails atomically")
	invalid = data.duplicate(true)
	invalid.nodes[1].next[0].to = "independence"
	check(not route.load_data(invalid), "Route cycles rejected")
	invalid = data.duplicate(true)
	invalid.nodes[0].next[0].miles = -1
	check(not route.load_data(invalid), "Negative route distance rejected")
	var game = Simulation.new(41, "classic", true)
	game.depart("farmer", ["A", "B", "C", "D", "E"], 5,
		{"oxen": 6, "food": 600, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1})
	var stops: Array = []
	for step in range(400):
		if game.state.status != "traveling":
			break
		if game.pending.has("landmark"):
			var id: String = game.pending.landmark
			stops.append(id)
			var before: Dictionary = game.state.duplicate(true)
			check(not game.travel() and not game.rest() and game.state == before, "Landmark blocks ordinary travel/time: " + id)
			if id == "big_blue":
				check(game.state.miles == 174, "No overshoot at Big Blue")
				game.state.food = 0
				game.state.health = 1
				for member in game.party_health.members:
					member.health = 1
				game.choose(game.pending.choices.size() - 1)
				check(game.state.status == "lost" and game.pending.is_empty(), "Starving at landmark cannot heal or leave a stale encounter")
				break
			if id == "kansas_river":
				var day: int = game.state.day
				var food: int = game.state.food
				game.choose(game.pending.choices.size() - 1)
				check(game.state.day == day + 1 and game.state.food == food - 15 and game.pending.landmark == id, "Rest on bank consumes food and retains crossing")
				check(game.state.river_stage in ["low", "high"], "Rest retains valid weather-linked river conditions")
				check(game.state.status == "traveling", "Kaw arrival does not end the chapter")
			game.choose(0)
		else:
			preload("res://tests/survival_policy.gd").step(game)
	check(stops == ["elm_grove", "wakarusa", "kansas_river", "big_blue"], "Landmarks arrive in period-guide order")
	var replay_a = Simulation.new(1848, "classic", true, "platte")
	var replay_b = Simulation.new(1848, "classic", true, "platte")
	for replay in [replay_a, replay_b]:
		replay.depart("farmer", ["A", "B", "C", "D", "E"], 5,
			{"oxen": 6, "food": 600, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1})
	var matching := true
	for step in range(400):
		for replay in [replay_a, replay_b]:
			preload("res://tests/survival_policy.gd").step(replay)
		matching = matching and replay_a.state == replay_b.state and replay_a.pending == replay_b.pending and replay_a.journal == replay_b.journal
		if replay_a.state.status != "traveling":
			break
	check(matching and replay_a.state.status == "arrived", "Same seed and decisions reproduce full player corridor including river stages")
	for stage in ["low", "high"]:
		var crossing = Simulation.new(5, "classic", true)
		crossing.state.next_landmark = "big_blue"
		crossing.state.status = "traveling"
		# Find a seeded example of each assigned stage and check the decision tradeoff.
		for seed_value in range(20):
			crossing.rng.seed = seed_value
			crossing._arrive_landmark()
			if crossing.state.river_stage == stage:
				break
		check(crossing.state.river_stage == stage, "Seeded condition sample exists: " + stage)
		var ford: float = crossing.pending.choices[0].risk
		var floating: float = crossing.pending.choices[1].risk
		check((ford < floating) if stage == "low" else (ford > floating), "Water stage changes relative crossing risk: " + stage)
	print("Route: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
