extends SceneTree
const Health = preload("res://simulation/party_health.gd")
const Simulation = preload("res://simulation/trail_engine.gd")
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
	game.depart("farmer", ["Ada", "Sam", "Jo", "Ada", "Pat"], 5,
		{"oxen": 6, "food": 600, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1})
	game.party_health.daily_onset_chance = 0.0
	game.survival.data.event_chance = 0.0
	game.survival.forced_weather = "clear"
	return game

func run() -> void:
	var health = Health.new()
	check(health.error.is_empty() and health.conditions.size() == 10, "Health JSON loads illnesses and injuries")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/health_conditions.json"))
	for field in ["daily_damage", "recovery_days"]:
		var invalid := data.duplicate(true)
		invalid.conditions[0][field] = -1
		check(not health.load_data(invalid) and health.conditions.is_empty(), "Invalid progression rejected atomically: " + field)
	var invalid := data.duplicate(true)
	invalid.conditions.append(invalid.conditions[0].duplicate())
	check(not health.load_data(invalid), "Duplicate diagnosis rejected")
	invalid = data.duplicate(true)
	invalid.daily_onset_chance = 2
	check(not health.load_data(invalid), "Invalid event chance rejected")
	check(health.load_data(data), "Valid reload clears content error")
	health.start(["Ada", "Sam", "Ada"], 1)
	health.daily_onset_chance = 0
	check(health.members[0].id != health.members[2].id, "Duplicate names still have stable distinct identities")
	check(health.begin_condition(1, "cholera", 0) and not health.begin_condition(1, "cholera", 0), "Diagnosis targets one member and cannot duplicate")
	check(not health.begin_condition(-1, "cholera", 0) and not health.begin_condition(0, "missing", 0), "Invalid health targets are rejected")
	health.tick(1, false)
	check(health.members[1].health == 76 and health.members[0].health == 85, "Illness changes only the affected person's health")
	check("Cholera" in health.description(1) and "No current illness" in health.description(0), "Personal descriptions show distinct conditions")
	health.members[1].health = 1
	health.tick(2, false)
	check(not health.members[1].alive and health.members[1].cause == "cholera" and health.members[1].death_day == 2, "Death records named person, day and cause")
	var dead_before: Dictionary = health.members[1].duplicate(true)
	health.affect_all(100, 3, "rest")
	check(health.members[1] == dead_before and not health.begin_condition(1, "measles", 3), "Rest and new conditions cannot revive the dead")
	check(health.living_count() == 2 and "DIED" in health.description(1), "Deceased remain inspectable and do not count as living")
	health.start(["Ada", "Sam"], 1)
	health.begin_condition(0, "exhaustion", 0)
	for day in range(1, 4):
		health.tick(day, true)
	check(health.members[0].conditions.is_empty() and "recovered" in health.description(0), "Rest advances recovery and preserves named history")
	var game = outfit()
	game.party_health.begin_condition(1, "dysentery", 0)
	game.travel()
	check(game.pending.id == "party_health" and "Sam" in game.pending.text and game.state.day == 1, "Personal health event interrupts travel with affected name")
	var day: int = game.state.day
	var food: int = game.state.food
	game.choose(0)
	check(game.state.day == day and game.state.food == food, "Acknowledging health news costs no extra day or food")
	check(game.state.health == game.party_health.average_health(), "Party condition derives from living members")
	game = outfit()
	game.party_health.begin_condition(1, "cholera", 0)
	game.party_health.members[1].health = 1
	game.travel()
	check(game.state.status == "traveling" and game.state.party_size == 4, "One death leaves surviving party able to continue")
	check(game.journal.any(func(entry): return "Sam died from cholera" in entry), "Named death persists in trail journal")
	game.choose(0)
	food = game.state.food
	game.travel()
	check(food - int(game.state.food) == 12, "Only four living travelers consume rations on subsequent days")
	game = outfit()
	for member in game.party_health.members:
		member.health = 1
	game.state.food = 0
	game.travel()
	check(game.state.status == "lost" and game.state.party_size == 0 and game.party_health.living_count() == 0, "No survivors ends journey")
	var replay_a = outfit(7)
	var replay_b = outfit(7)
	replay_a.party_health.daily_onset_chance = 1
	replay_b.party_health.daily_onset_chance = 1
	for step in range(8):
		for replay in [replay_a, replay_b]:
			if replay.pending.is_empty():
				replay.travel()
			else:
				replay.choose(0)
	check(replay_a.state == replay_b.state and replay_a.party_health.members == replay_b.party_health.members and replay_a.journal == replay_b.journal, "Health events reproduce from seed and decisions")
	var screen = Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.next_button.pressed.emit()
	screen.departure_view.depart_button.pressed.emit()
	screen.game.party_health.daily_onset_chance = 0
	screen.game.party_health.begin_condition(1, "broken_leg", 0)
	screen.game.party_health.begin_condition(2, "dysentery", 0)
	screen.game.party_health.members[2].health = 40
	screen.game.party_health.affect(screen.game.party_health.members[3], -100, 0, "cholera")
	screen.game.state.health = screen.game.party_health.average_health()
	screen.game.state.party_size = screen.game.party_health.living_count()
	screen._refresh()
	screen.travel_timer.wait_time = 60
	screen._travel()
	var before: Dictionary = screen.game.state.duplicate(true)
	var members_before: Array = screen.game.party_health.members.duplicate(true)
	var rng_before: int = screen.game.party_health.rng.state
	screen.party_button.pressed.emit()
	check(screen.party_window.visible and not screen.traveling and screen.party_rows.get_child_count() == 5, "View Party pauses travel and lists every traveler")
	check(screen.party_rows.get_global_rect().end.x < screen.member_details.get_global_rect().position.x, "Roster and detail columns do not overlap")
	screen.party_rows.get_child(1).pressed.emit()
	check("Broken leg" in screen.member_details.text and "SAM" in screen.member_details.text, "Selecting member shows their injury and personal record")
	screen.party_rows.get_child(3).pressed.emit()
	check("DIED" in screen.member_details.text and "cholera" in screen.member_details.text, "Deceased person's history stays accessible")
	screen.party_rows.get_child(2).pressed.emit()
	await create_timer(0.1).timeout
	check(screen.game.state == before and screen.game.party_health.members == members_before and screen.game.party_health.rng.state == rng_before, "Reading and selecting members never advances simulation or RNG")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/party.png")
	screen.party_window.hide()
	screen.crossing_result = {"method": "float", "place": "Kansas River", "mishap": false, "lost": false}
	screen.landscape.start_crossing(screen.crossing_result)
	screen._show_party()
	var elapsed: float = screen.landscape.crossing_elapsed
	screen.landscape._process(0.5)
	check(screen.landscape.crossing_elapsed == elapsed, "Party view also pauses crossing animation")
	screen._new_journey()
	check(not screen.party_window.visible and screen.game.party_health.members.is_empty(), "New journey clears personal state and closes old roster")
	screen.queue_free()
	await process_frame
	print("Health: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
