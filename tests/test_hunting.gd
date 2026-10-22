extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Hunting = preload("res://simulation/hunting.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _initialize() -> void:
	var model = Hunting.new()
	check(model.error.is_empty(), "Hunting JSON loads")
	var original: Dictionary = model.data.duplicate(true)
	for key in ["duration", "reload_seconds", "carry_limit", "shot_limit"]:
		var bad := original.duplicate(true)
		bad[key] = -1
		check(not model.load_data(bad) and model.data.is_empty(), "Bad rule rejected atomically: " + key)
	check(model.load_data(original), "Valid rules reload")
	var empty := 0
	var species: Array = []
	for seed_value in range(100):
		var a: Dictionary = model.begin(seed_value, 1, 0)
		var b: Dictionary = model.begin(seed_value, 1, 0)
		check(a == b, "Same seed and outing reproduce encounter")
		check(a.region == "woodland" and model.begin(seed_value, 1, 90).region == "plains", "Corridor determines habitat")
		if a.animals.is_empty():
			empty += 1
		for animal in a.animals:
			if animal.kind not in species:
				species.append(animal.kind)
	check(empty > 0 and empty < 100 and species.size() == 3, "Encounters vary and may contain no game")
	var game = Simulation.new(1848, "classic", true)
	game.depart("farmer", ["A", "B", "C", "D", "E"], 5, {"oxen":6,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1})
	game.party_health.daily_onset_chance = 0
	game.survival.data.event_chance = 0
	check(game.start_hunt(), "Start outing")
	game.hunt.animals = [{"kind":0,"x":100.0,"y":90,"direction":1,"escaped":false}]
	game.hunt.cover = [Rect2(108, 115, 12, 12)]
	game.hunt.hunter = Vector2(115, 140)
	game.hunt.destination = game.hunt.hunter
	var ammo: int = game.state.bullets
	check(game.hunt_fire_at(Vector2(115, 100)) and game.hunt.targets.is_empty(), "Cover blocks shot and costs ammunition")
	check(not game.hunt_fire_at(Vector2(115, 100)) and game.state.bullets == ammo - 1, "Reload blocks rapid fire without extra ammunition")
	game.move_hunter(Vector2(115, 80))
	game.advance_hunt(1.5)
	check(game.hunt.hunter.y > 127, "Hunter cannot walk through cover even with a large time step")
	game.hunt.cover.clear()
	var target: Vector2 = game.hunting.bounds(game.hunt, 0).get_center()
	check(game.hunt_fire_at(target) and game.hunt.meat == 300, "Clear shot obtains configured usable meat")
	game.advance_hunt(1.5)
	check(not game.hunt_shot(0), "Taken animal cannot yield meat twice")
	check(game.finish_hunt() and not game.finish_hunt(), "Return settles exactly once")
	game.pending.clear()
	check(game.start_hunt(), "Another outing begins")
	game.advance_hunt(31)
	ammo = game.state.bullets
	check(game.hunt.ended and not game.hunt_shot(-1) and game.state.bullets == ammo, "Time expires and disables firing")
	game.finish_hunt()
	game.pending.clear()
	game.start_hunt()
	game.hunt.animals = [{"kind":2,"x":431.0,"y":90,"direction":1,"escaped":false}]
	game.advance_hunt(1)
	check(game.hunt.animals[0].escaped and not game.hunt_shot(0), "Fleeing animal leaves play and cannot be hit")
	check(model.blocks(Rect2(10, 10, 10, 10), Vector2(0, 21), Vector2(21, 0)), "Cover corner crossing geometry")
	print("Hunting: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
