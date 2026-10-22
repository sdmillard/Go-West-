extends SceneTree
const Main = preload("res://ui/main.tscn")
var screen: Control
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func prepare(method: String, risk: float = -1.0, food: int = 600, health: int = 85) -> void:
	screen._new_journey()
	screen.departure_view.next_button.pressed.emit()
	screen.departure_view.depart_button.pressed.emit()
	screen.game.survival.forced_weather = "clear"
	screen.game.survival.data.event_chance = 0
	screen.game.party_health.daily_onset_chance = 0
	screen.game.state.next_landmark = "kansas_river"
	screen.game.state.miles = 81
	screen.game.seen.append("muddy_trail")
	screen.game._arrive_landmark()
	screen._refresh()
	for index in range(screen.game.pending.choices.size()):
		if screen.game.pending.choices[index].get("method", "") == method:
			if risk >= 0:
				screen.game.pending.choices[index]["risk"] = risk
			screen.game.state.food = food
			screen.game.state.health = health
			for member in screen.game.party_health.members:
				member.health = health
			screen._choose(index)
			return
	check(false, "Fixture has crossing method: " + method)

func run() -> void:
	screen = Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.next_button.pressed.emit()
	screen.departure_view.depart_button.pressed.emit()
	screen.travel_timer.wait_time = 60.0
	screen.travel_button.pressed.emit()
	screen._advance_day()
	var before: Dictionary = screen.game.state.duplicate(true)
	var rng_before: int = screen.game.rng.state
	var offset: float = screen.landscape.scroll_distance
	screen.landscape._process(0.5)
	check(screen.landscape.scroll_distance > offset, "Travel scrolls scenery")
	screen.travel_button.pressed.emit()
	offset = screen.landscape.scroll_distance
	screen.landscape._process(0.5)
	check(screen.landscape.scroll_distance == offset, "Pause freezes scenery")
	check(screen.game.state == before and screen.game.rng.state == rng_before, "Scrolling is presentation only")
	for method in ["ford", "float", "ferry"]:
		prepare(method)
		check(screen.landscape.crossing.get("method") == method, "Selected method starts its animation: " + method)
		check(screen.travel_button.disabled and screen.rest_button.disabled and screen.pace.disabled, "Animation locks controls: " + method)
		before = screen.game.state.duplicate(true)
		rng_before = screen.game.rng.state
		screen.landscape._process(0.5)
		screen._show_guide()
		var elapsed: float = screen.landscape.crossing_elapsed
		screen.landscape._process(0.5)
		check(screen.landscape.crossing_elapsed == elapsed, "Guide pauses crossing: " + method)
		screen.guide.hide()
		screen.landscape._process(0.25)
		check(screen.landscape.crossing_elapsed > elapsed, "Closing guide resumes animation: " + method)
		screen._travel()
		screen._rest()
		screen._choose(0)
		check(screen.game.state == before and screen.game.rng.state == rng_before, "Watching/repeated input cannot alter resolved crossing: " + method)
		if "--capture" in OS.get_cmdline_user_args():
			await capture_animation(method)
		screen.choices.get_child(0).pressed.emit()
		check(screen.landscape.crossing.is_empty() and not screen.traveling, "Skip returns to paused travel: " + method)
		check(screen.game.state == before and screen.game.rng.state == rng_before, "Skipping does not reroll or recharge: " + method)
	prepare("ferry")
	screen.landscape.crossing_duration = 0.03
	await create_timer(0.15).timeout
	check(screen.landscape.crossing.is_empty() and not screen.travel_button.disabled and not screen.traveling, "Actual animation clock finishes and leaves travel paused")
	screen.landscape.crossing_duration = 2.8
	prepare("float")
	screen._new_journey()
	before = screen.game.state.duplicate(true)
	screen.landscape._process(10.0)
	check(screen.landscape.crossing.is_empty() and screen.game.state == before and screen.game.state.status == "outfitting", "Restart cancels animation without stale effects")
	for food in [600, 18]:
		prepare("float", 1.0, food)
		var result: Dictionary = screen.game.last_crossing.duplicate(true)
		check(result.mishap and result.food_lost == mini(30, food - 15) and result.health_lost == 15, "History records actual accident losses, excluding daily rations and clamping to stock")
		check(screen.game.crossing_history.size() == 1 and screen.game.crossing_history[0] == result, "Crossing history stores one complete outcome")
		check(screen.game.journal.any(func(entry): return result.summary in entry), "Exact result is preserved in trail journal")
		before = screen.game.state.duplicate(true)
		rng_before = screen.game.rng.state
		if "--capture" in OS.get_cmdline_user_args() and food == 600:
			await capture_animation("failure")
		screen.landscape.finish_crossing()
		check(screen.event_title.text == "Crossing mishap!" and ("%d lb" % result.food_lost) in screen.event_text.text, "Failure screen shows exact supplies lost after animation")
		if "--capture" in OS.get_cmdline_user_args() and food == 600:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/crossing-failure-result.png")
		screen._travel()
		screen._rest()
		check(screen.game.state == before and screen.travel_button.disabled, "Result must be acknowledged before more travel")
		screen._show_journal()
		check(result.summary in screen.journal.text, "History is readable from result screen")
		screen.journal_window.hide()
		screen.choices.get_child(0).pressed.emit()
		check(not screen._reviewing_crossing() and screen.game.state == before and screen.game.rng.state == rng_before and screen.game.crossing_history.size() == 1, "Acknowledgement never rerolls, charges time, or duplicates history")
	prepare("ford", 0.0)
	check(not screen.game.last_crossing.mishap and screen.game.last_crossing.food_lost == 0 and screen.game.last_crossing.health_lost == 0, "Safe crossing records zero accident losses")
	screen.landscape.finish_crossing()
	prepare("ford", 1.0, 600, 5)
	check(screen.game.last_crossing.lost and screen.game.last_crossing.health_lost == 6 and screen.game.crossing_history[0].lost, "Fatal mishap records clamped health loss and terminal outcome")
	screen.landscape.finish_crossing()
	check("journey ended" in screen.event_text.text and not "reached the far bank" in screen.event_text.text, "Fatal result cannot claim everyone arrived safely")
	screen._acknowledge_crossing()
	check(screen.game.state.status == "lost" and screen.travel_button.disabled, "Acknowledging fatal mishap cannot resume travel")
	screen._new_journey()
	# Starvation during crossing remains a loss even after the visual finishes.
	screen.departure_view.next_button.pressed.emit()
	screen.departure_view.depart_button.pressed.emit()
	screen.game.state.next_landmark = "kansas_river"
	screen.game._arrive_landmark()
	screen.game.state.health = 1
	for member in screen.game.party_health.members:
		member.health = 1
	screen.game.state.food = 0
	screen._refresh()
	screen._choose(0)
	check(screen.game.last_crossing.lost and screen.game.state.status == "lost", "Outcome record preserves loss during elapsed crossing time")
	screen.landscape.finish_crossing()
	check(screen.game.state.status == "lost" and screen.travel_button.disabled, "Visual completion cannot turn loss into success")
	print("Motion: %d checks, %d failures" % [checks, failures])
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)

func capture_animation(method: String) -> void:
	var folder := "res://.tools/animation-frames/" + method
	DirAccess.make_dir_recursive_absolute(folder)
	screen.landscape.crossing_paused = true
	for frame in range(42):
		screen.landscape.crossing_elapsed = float(frame) / 41.0 * 2.79
		screen.landscape.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var capture: Image = root.get_texture().get_image()
		var origin := Vector2i(screen.landscape.global_position)
		if frame == 0:
			check(capture.get_pixelv(origin + Vector2i(10, 140)).is_equal_approx(Color("ecd097")), "Near-bank pixels stay dry as sprites enter: " + method)
		if frame == 35 or frame == 41:
			check(capture.get_pixelv(origin + Vector2i(400, 140)).is_equal_approx(Color("8d9b53")), "Far-bank pixels stay dry as sprites leave: " + method)
		capture.save_png(folder + "/%03d.png" % frame)
		if frame == 21:
			capture.save_png("res://docs/crossing-" + method + ".png")
	screen.landscape.crossing_paused = false
