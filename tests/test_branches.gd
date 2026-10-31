extends SceneTree
const Route = preload("res://simulation/route_catalog.gd")
const Simulation = preload("res://simulation/trail_engine.gd")
const Store = preload("res://simulation/save_store.gd")
const Cache = preload("res://simulation/wagon_cache.gd")
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
	game.depart("banker", ["Ada", "Sam", "Jo", "Lou", "Pat"], 5,
		{"oxen": 6, "food": 1500, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1})
	game.party_health.daily_onset_chance = 0.0
	game.survival.data.event_chance = 0.0
	game.survival.forced_weather = "clear"
	return game

# Puts the party at the end of the South Pass leg and lets it arrive at the fork.
func at_fork(seed_value: int = 1848):
	var game = outfit(seed_value)
	game.route_path = game.route.main_path_to("south_pass")
	game.state.merge({"landmark": "south_pass", "next_landmark": "little_sandy", "leg_length": 25, "leg_miles": 25, "miles": 926}, true)
	game._schedule_event(false)
	return game

func node_by_id(data: Dictionary, id: String) -> Dictionary:
	for node in data.nodes:
		if node.id == id:
			return node
	return {}

func drive_to(game, target: String, limit: int = 300) -> void:
	for step in range(limit):
		if game.state.status != "traveling" or game.state.landmark == target and game.pending.has("landmark"):
			return
		if not game.pending.is_empty():
			game.choose(0)
		else:
			game.travel()

func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/route.json"))
	var route = Route.new()
	check(route.error.is_empty() and route.total_miles == 1938 and route.longest_miles == 1958, "Main road stays 1938 guide miles; the Walla Walla detour is the only longer road")
	check(route.nodes.little_sandy.next.size() == 2 and route.nodes.little_sandy.next[0].to == "green_river", "The southern road stays the first (main) road at the Little Sandy")
	check(route.remaining("greenwood_cutoff") == 1883 - 972, "Remaining miles follow the branch")
	check(route.main_path_to("fort_bridger").has("green_river") and route.main_path_to("greenwood_cutoff").is_empty(), "Main path excludes branch stops")
	check(route.node_miles().greenwood_cutoff == 972 and route.node_miles().soda_springs == 1151, "Stop mileage: branch stops measured along their branch, rejoining stops along the main road")
	check(route.valid_path(["independence", "elm_grove"]) and not route.valid_path(["independence", "wakarusa"]), "Paths must follow real roads")

	var invalid := data.duplicate(true)
	node_by_id(invalid, "green_river").next.append({"to": "soda_springs", "miles": 10})
	check(not route.load_data(invalid), "A crossing cannot fork")
	invalid = data.duplicate(true)
	node_by_id(invalid, "little_sandy").next[1].hazard = "lava"
	check(not route.load_data(invalid), "Unknown road hazard rejected")
	invalid = data.duplicate(true)
	node_by_id(invalid, "little_sandy").next[1].to = "green_river"
	check(not route.load_data(invalid), "Two roads to the same stop rejected")
	invalid = data.duplicate(true)
	node_by_id(invalid, "little_sandy").next.pop_back()
	check(not route.load_data(invalid), "Unreachable stops rejected")
	invalid = data.duplicate(true)
	node_by_id(invalid, "greenwood_cutoff").next[0].to = "little_sandy"
	check(not route.load_data(invalid), "Branch cycles rejected")
	check(route.load_data(data), "Valid route reloads")

	# The fork offers both roads; the main road comes first.
	var game = at_fork()
	check(game.pending.get("landmark", "") == "little_sandy", "Party arrives at the Little Sandy fork")
	var leaves: Array = game.pending.choices.filter(func(choice): return choice.get("action", "") == "leave")
	check(leaves.size() == 2 and not leaves[0].has("edge") and leaves[1].edge == 1 and "Greenwood" in leaves[1].label and "water" in leaves[1].label, "Both roads are offered with the cutoff's warning")
	check(game.destination() == 1938, "Before choosing, the journey shows the main road's length")
	var cutoff_index: int = game.pending.choices.find(leaves[1])
	game.choose(cutoff_index)
	check(game.state.next_landmark == "greenwood_cutoff" and game.state.leg_length == 46 and game.destination() == 1883, "Taking the cutoff sets the 46-mile dry leg and shortens the journey by 55 miles")
	check(game.journal.any(func(entry): return "Took the road toward" in entry), "The choice is recorded in the journal")

	# The waterless leg costs the team and the party more than the main road.
	var main = at_fork()
	main.choose(main.pending.choices.find(main.pending.choices.filter(func(choice): return choice.get("action", "") == "leave")[0]))
	var ox_before: int = game.state.ox_health
	var main_before: int = main.state.ox_health
	var health_before: int = game.party_health.members[0].health
	var main_health: int = main.party_health.members[0].health
	game.travel()
	main.travel()
	check(ox_before - int(game.state.ox_health) > main_before - int(main.state.ox_health), "The dry leg strains the team more than the southern road")
	check(health_before - int(game.party_health.members[0].health) > main_health - int(main.party_health.members[0].health), "The dry leg leaves the party thirsty")
	var resting_ox: int = game.state.ox_health
	game.rest()
	check(int(game.state.ox_health) <= resting_ox, "Resting on the dry leg gives the team no recovery")

	# Save mid-cutoff, then tamper.
	var store = Store.new()
	var copy = store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	check(copy != null and copy.state.next_landmark == "greenwood_cutoff" and copy.route_path[-1] == "little_sandy" and copy.destination() == game.destination(), "A save on the cutoff restores the road taken")
	var bad: Dictionary = JSON.parse_string(JSON.stringify(store.capture(game)))
	bad.route_path.append("greenwood_cutoff")
	check(store.restore(bad) == null, "A road history that does not end at the current stop is rejected")
	bad = JSON.parse_string(JSON.stringify(store.capture(game)))
	bad.route_path = ["independence", "wakarusa"]
	check(store.restore(bad) == null, "A road history that skips stops is rejected")
	var fork = at_fork()
	bad = JSON.parse_string(JSON.stringify(store.capture(fork)))
	for choice in bad.pending.choices:
		if choice.has("edge"):
			choice.edge = 5
	check(store.restore(bad) == null, "A saved road choice that does not exist is rejected")
	bad = JSON.parse_string(JSON.stringify(store.capture(fork)))
	bad.erase("route_path")
	var legacy = store.restore(bad)
	check(legacy != null and legacy.route_path == legacy.route.main_path_to("little_sandy"), "Older saves without a road history are on the main road")

	# Drive the cutoff to where it rejoins.
	drive_to(game, "soda_springs")
	check(game.state.landmark == "soda_springs" and game.route_path.has("greenwood_cutoff") and not game.route_path.has("fort_bridger"), "The cutoff reaches Soda Springs without passing Bridger")
	check(game.state.miles == 1096 and game.destination() == 1883, "Guide miles follow the shorter road")
	Cache.relocate(game, 1000)
	check(game.state.landmark == "greenwood_cutoff" and game.state.next_landmark == "soda_springs" and game.state.leg_miles == 28 and game.route_path[-1] == "greenwood_cutoff", "Walking back retraces the road actually taken")

	# The Columbia: raft from The Dalles, portage or run the Cascades.
	game = outfit(7)
	game.route_path = game.route.main_path_to("deschutes")
	game.state.merge({"landmark": "deschutes", "next_landmark": "the_dalles", "leg_length": 16, "leg_miles": 16, "miles": 1778}, true)
	game._schedule_event(false)
	leaves = game.pending.choices.filter(func(choice): return choice.get("action", "") == "leave")
	check(game.pending.get("landmark", "") == "the_dalles" and leaves.size() == 2 and "Barlow" in leaves[0].label and "raft" in leaves[1].label and int(leaves[1].effects.days) == 3, "The Dalles offers the Barlow road first and the raft second, with building days")
	var day: int = game.state.day
	game.choose(game.pending.choices.find(leaves[1]))
	check(int(game.state.day) == day + 3 and game.state.next_landmark == "columbia_raft" and game.destination() == 1894, "Building the raft takes three days; the river route is 1894 guide miles")
	while not game.pending.is_empty():
		game.choose(0)
	var team_before: int = game.state.ox_health
	game.state.oxen = 0
	var miles_before: int = game.state.miles
	game.travel()
	check(game.pending.get("id", "") != "no_team" and int(game.state.miles) > miles_before and int(game.state.ox_health) >= team_before, "On the river the current carries the party without a working team")
	game.state.oxen = 6
	drive_to(game, "columbia_raft")
	leaves = game.pending.choices.filter(func(choice): return choice.get("action", "") == "leave")
	check(game.state.landmark == "columbia_raft" and leaves.size() == 3 and "Portage" in leaves[0].label and leaves[1].get("rafting",false) and leaves[2].get("native_portage",false), "The Cascades offer a portage or running the rapids")
	copy = store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	check(copy != null and copy.pending.choices == store.normalize(game.pending.choices), "The Cascades choice survives a save")
	bad = JSON.parse_string(JSON.stringify(store.capture(game)))
	for choice in bad.pending.choices:
		if choice.has("rafting"):choice.rafting="yes"
	check(store.restore(bad)==null,"A malformed interactive rapids marker is rejected")
	var wreck=store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	var food_before: int=wreck.state.food
	wreck.choose(wreck.pending.choices.find(wreck.pending.choices.filter(func(choice):return choice.get("rafting",false))[0]))
	check(not wreck.raft.is_empty() and wreck.state.day==game.state.day,"Running rapids opens the activity before charging time")
	for tick in range(1800):
		if wreck.raft.ended:break
		wreck.advance_rafting(1.0/60.0,3.0)
	check(wreck.raft.wrecked and wreck.finish_rafting(),"Repeated impacts can wreck and settle the raft")
	check(food_before-wreck.state.food>=60 and wreck.rafting_history[0].wrecked,"Wreck losses are applied and recorded")
	day = game.state.day
	food_before = game.state.food
	var cash: float = game.state.money
	game.choose(game.pending.choices.find(leaves[0]))
	check(int(game.state.day) == day + 2 and game.state.next_landmark == "oregon_city", "Portaging takes two days")
	drive_to(game, "oregon_city")
	check(game.state.status == "arrived" and game.state.miles == 1894 and game.route_path.has("columbia_raft") and not game.route_path.has("barlow_pass") and is_equal_approx(float(game.state.money), cash), "The river reaches Oregon City without the Barlow road or its toll")

	# Fort Walla Walla: a dangerous detour through Cayuse War country.
	game = outfit(11)
	game.route_path = game.route.main_path_to("grande_ronde")
	game.state.merge({"landmark": "grande_ronde", "next_landmark": "blue_mountains", "leg_length": 27, "leg_miles": 27, "miles": 1647}, true)
	game._schedule_event(false)
	leaves = game.pending.choices.filter(func(choice): return choice.get("action", "") == "leave")
	check(game.pending.get("landmark", "") == "blue_mountains" and leaves.size() == 2 and "Umatilla" in leaves[0].label and "Cayuse War" in leaves[1].label, "The Blue Mountains offer the Umatilla first and the warned detour second")
	game.choose(game.pending.choices.find(leaves[1]))
	while not game.pending.is_empty():
		game.choose(0)
	check(game.state.next_landmark == "fort_walla_walla" and game.current_edge().hazard == "unrest" and game.destination() == 1958, "The detour adds 20 guide miles on an unsettled road")
	var war_ids := ["war_volunteers", "cayuse_riders", "waiilatpu_ruins"]
	var seen_war := {}
	# Sample on a copy: each rolled encounter applies its immediate losses.
	var sampler = store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
	for index in range(400):
		sampler.pending = {}
		sampler.survival.last_events.clear()
		sampler._roll_trail_event()
		if sampler.pending.get("id", "") in war_ids:
			seen_war[sampler.pending.id] = true
	check(seen_war.size() == 3, "All three Cayuse War encounters happen on the detour: %s" % [seen_war.keys()])
	var calm = outfit(11)
	calm.route_path = calm.route.main_path_to("blue_mountains")
	calm.state.merge({"landmark": "blue_mountains", "next_landmark": "umatilla", "leg_length": 16, "leg_miles": 2, "miles": 1649}, true)
	var war_on_main := false
	for index in range(400):
		calm.pending = {}
		calm.survival.last_events.clear()
		calm._roll_trail_event()
		war_on_main = war_on_main or calm.pending.get("id", "") in war_ids
	check(not war_on_main, "Cayuse War encounters never happen on the main road")
	drive_to(game, "fort_walla_walla")
	check(game.state.landmark == "fort_walla_walla" and game.context.market(game).post and not game.post_store().is_empty(), "Fort Walla Walla is a trading post")
	game.choose(game.pending.choices.find(game.pending.choices.filter(func(choice): return choice.get("action", "") == "leave")[0]))
	drive_to(game, "john_day")
	check(game.state.landmark == "john_day" and game.route_path.has("fort_walla_walla") and not game.route_path.has("umatilla") and game.state.miles == 1760, "The detour rejoins at the John Day, 20 miles later than the main road")

	print("Branch checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures else 0)
