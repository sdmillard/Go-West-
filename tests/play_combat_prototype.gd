extends SceneTree
## Isolated tactical combat practice scenario. Launcher redirects user data; normal saves are untouched.
const Main = preload("res://ui/main.tscn")
var screen: Control
var restart_down := false
var restarting := false


func _initialize() -> void:
	process_frame.connect(practice_keys)
	call_deferred("start_practice")


func start_practice() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
		await process_frame
	screen = Main.instantiate()
	root.add_child(screen)
	await process_frame
	var game = screen.game
	game.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 3})
	for i in range(1, game.characters.profiles.size()):
		game.characters.profiles[i].boundaries.forbidden.clear()
	screen.departure_view.hide()
	game.route_path = game.route.main_path_to("fort_bridger")
	game.state.merge({"day": 58, "landmark": "fort_bridger", "next_landmark": "fort_bridger", "miles": 989, "leg_length": 0, "leg_miles": 0}, true)
	game._arrive_landmark(true, false)
	game.open_crime()
	screen._open_tactical_combat("shoot")
	root.title = "Westward, Probably · 1848 Isometric Combat Prototype · F6 restarts"


func practice_keys() -> void:
	var pressed: bool = Input.is_physical_key_pressed(KEY_F6)
	if pressed and not restart_down and not restarting and is_instance_valid(screen):
		restart_down = true
		restarting = true
		await start_practice()
		restarting = false
	elif not pressed:
		restart_down = false
