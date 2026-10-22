extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Store = preload("res://simulation/save_store.gd")
const Policy = preload("res://tests/survival_policy.gd")
const Main = preload("res://ui/main.tscn")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func outfit(seed_value: int = 12):
	var game = Simulation.new(seed_value,"classic",true)
	game.depart("farmer",["A","B","C","D","E"],5,{"oxen":6,"food":800,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1})
	return game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var store = Store.new()
	for seed_value in range(8):
		var game = outfit(seed_value)
		for day in range(6):
			Policy.step(game)
		var original: Dictionary = store.capture(game)
		var copy = store.restore(JSON.parse_string(JSON.stringify(original)))
		check(copy != null and store.capture(copy) == original, "JSON round trip preserves entire simulation")
		if copy == null:
			continue
		for day in range(15):
			Policy.step(game)
			Policy.step(copy)
			check(store.capture(game) == store.capture(copy), "Restored RNG and state continue identically")
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/opening-save-v1.json"))
	var migrated = store.restore(previous)
	check(migrated != null and migrated.state.status == "traveling" and migrated.state.landmark == "platte" and migrated.state.next_landmark == "fort_kearny", "Previous Platte completion resumes onto expanded road")
	if migrated != null:
		check(migrated.state.day == previous.state.day and migrated.state.food == previous.state.food and migrated.rng.state == int(previous.random) and migrated.party_health.members == store.normalize(previous.party), "Opening-save upgrade preserves date, supplies, people and RNG without spending time")
		var upgraded: Dictionary = store.capture(migrated)
		check(upgraded.rules == store.fingerprint() and store.restore(JSON.parse_string(JSON.stringify(upgraded))) != null, "Upgraded journey can be saved and loaded under current rules")
	var game = outfit()
	game.state.money = 19.8
	game.provisions.add_fresh(20,0)
	game.party_health.begin_condition(2,"broken_leg",0,2)
	var original: Dictionary = store.capture(game)
	var copy = store.restore(JSON.parse_string(JSON.stringify(original)))
	check(copy != null and copy.provisions.fresh == game.provisions.fresh and copy.state.money == 19.8, "Fresh ages, conditions and fractional cash survive")
	for field in ["random","party","weather","pending","fresh"]:
		var bad := original.duplicate(true)
		bad[field] = null
		check(store.restore(bad) == null, "Malformed field rejected safely: " + field)
	var bad := original.duplicate(true)
	bad.version = 999
	check(store.restore(bad) == null, "Unknown save version rejected")
	bad = original.duplicate(true)
	bad.rules = "old"
	check(store.restore(bad) == null and "different game rules" in store.error, "Rules mismatch reports useful error")
	var river = outfit(22)
	river.state.next_landmark = "kansas_river"
	river._arrive_landmark()
	var river_copy = store.restore(JSON.parse_string(JSON.stringify(store.capture(river))))
	check(river_copy != null and river_copy.pending == store.normalize(river.pending), "Unresolved river crossing and its chosen stage survive loading")
	river.open_trade()
	river_copy = store.restore(JSON.parse_string(JSON.stringify(store.capture(river))))
	check(river_copy != null and not river_copy.service_return.is_empty(), "Trade menu retains the unresolved stop underneath it")
	if river_copy != null:
		river.choose(0)
		river_copy.choose(0)
		check(store.capture(river) == store.capture(river_copy), "Resumed trade spends money and one day identically")
	bad = original.duplicate(true)
	bad.pending = {"id":"bad","title":"Bad","text":"Bad","choices":[{"label":"Do","result":"Bad","effects":{"days":-2}}]}
	check(store.restore(bad) == null, "Malformed encounter effects cannot enter the engine through a save")
	var path := "user://test-journey.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	check(store.save_game(game,path), "Save writes a file")
	game.pending.clear()
	game.rest()
	check(store.save_game(game,path) and FileAccess.file_exists(path+".bak"), "Save replacement preserves previous file")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var recovered: Dictionary = store.load_game(path)
	check(not recovered.is_empty() and "backup" in recovered.message and store.capture(recovered.game) == original, "Damaged primary recovers previous backup explicitly")
	game = outfit()
	game.start_hunt()
	check(not store.save_game(game,path), "Active hunt cannot be saved halfway")
	var screen = Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.save_path = "user://test-ui-journey.json"
	screen._depart("farmer",["A","B","C","D","E"],5,{"oxen":6,"food":800,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1})
	screen.save_button.pressed.emit()
	check(FileAccess.file_exists(screen.save_path), "Save button persists the current journey")
	screen.record_notice.hide()
	screen._new_journey()
	screen.load_button.pressed.emit()
	check(screen.game.state.status == "traveling" and not screen.traveling and screen.game.state.food == 800 and not screen.departure_view, "Load works from setup and restores paused travel")
	screen.queue_free()
	await process_frame
	print("Saves: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
