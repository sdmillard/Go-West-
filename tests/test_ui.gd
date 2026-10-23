extends SceneTree
## Exercise actual setup widgets, timeouts and button signals in the main scene.
const Main = preload("res://ui/main.tscn")
var screen: Control
var failures := 0

func check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL UI: " + text)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	screen = Main.instantiate()
	root.add_child(screen)
	await process_frame
	check(screen.departure_view.visible and screen.game.state.status == "outfitting", "New game opens departure setup")
	check(root.content_scale_size == Vector2i(640, 360), "Native pixel canvas is 640 by 360")
	await capture("departure")
	screen.game.route.truncate_at("platte")
	var setup = screen.departure_view
	check(setup.scene_id == "town_setup" and setup.party_layer.visible and not setup.shop_layer.visible, "Party setup has the town background")
	var before_store: Dictionary = screen.game.state.duplicate(true)
	setup.next_button.pressed.emit()
	check(setup.scene_id == "store" and setup.shop_layer.visible and not setup.party_layer.visible, "Entering store reveals its own interior")
	await capture("store")
	setup.quantities.food.value = 650
	setup.back_button.pressed.emit()
	check(setup.scene_id == "town_setup" and setup.quantities.food.value == 650 and screen.game.state == before_store, "Going back preserves unpurchased cart without charging supplies")
	setup.next_button.pressed.emit()
	setup.profession.selected = 2
	setup.quantities.food.value = 2000
	check(setup.depart_button.disabled, "An overloaded suggested cart blocks departure")
	setup.quantities.food.value = 600
	setup.names[0].text = ""
	setup.names[0].text_changed.emit("")
	check(setup.depart_button.disabled and setup.next_button.disabled, "Empty party name blocks departure and store entry")
	setup.names[0].text = "ADA"
	setup.names[0].text_changed.emit("ADA")
	setup.month.selected = 5
	await process_frame
	setup.depart_button.pressed.emit()
	check(not setup.visible and screen.game.state.status == "traveling", "Valid setup enters travel screen")
	check(screen.game.state.party[0] == "ADA" and is_equal_approx(screen.game.state.money,279.4) and screen.game.state.salt == 10 and screen.game.state.bullets == 200, "UI forwards names and supplies")
	check(screen.date_label.text.begins_with("AUG 1, 1848"), "UI shows selected departure month")
	await capture("preview")
	screen.travel_timer.wait_time = 0.01
	screen.travel_button.pressed.emit()
	check(screen.traveling and screen.travel_button.text == "PAUSE", "Continue starts automatic travel")
	screen.travel_button.pressed.emit()
	await create_timer(0.08).timeout
	check(screen.game.state.day == 0 and not screen.traveling, "Pause prevents timer advancement")
	screen.travel_button.pressed.emit()
	await create_timer(0.15).timeout
	check(screen.game.state.day == 2 and not screen.traveling and screen.travel_timer.is_stopped(), "Actual timer advances daily and stops on an event")
	if screen.game.pending.get("landmark", "") == "elm_grove":
		screen.choices.get_child(0).pressed.emit()
	check(screen.game.pending.get("id", "") == "muddy_trail" and screen.choices.get_child_count() == 2 and screen.travel_button.disabled, "Historical choices block Continue")
	await capture("muddy-trail")
	screen.choices.get_child(0).pressed.emit()
	check(screen.game.state.wheels == 0 and screen.game.state.axles == 1 and not screen.traveling, "Choice consumes wheel and leaves wagon paused")
	screen.travel_button.pressed.emit()
	screen._show_journal()
	var day: int = screen.game.state.day
	await create_timer(0.08).timeout
	check(screen.journal_window.visible and not screen.traveling and screen.game.state.day == day, "Opening journal stops time")
	await capture("journal")
	screen.journal_window.hide()
	screen.travel_button.pressed.emit()
	screen._show_guide()
	await create_timer(0.08).timeout
	check(screen.guide.visible and not screen.traveling and screen.game.state.day == day, "Opening guide stops time")
	screen.guide.hide()
	screen.rest_button.pressed.emit()
	check(screen.rest_window.visible and screen.game.state.day == day, "Camp asks duration without spending time")
	screen.rest_window.hide()
	screen._confirm_rest()
	screen.record_notice.hide()
	check(screen.game.state.day == day + 1 and not screen.traveling, "Camp consumes one day and remains paused")
	check(screen.landscape.scene_id == "camp", "Resting between locations shows the camp scene")
	await capture("camp")
	for i in range(400):
		if screen.game.state.status != "traveling":
			break
		if screen.game.pending.is_empty():
			if screen.game.state.food < 120 and screen.game.state.bullets >= 3:
				preload("res://tests/survival_policy.gd").step(screen.game)
				screen._refresh()
				continue
			if screen.game.state.fatigue > 50 or screen.game.state.health < 70:
				screen._rest()
				screen.rest_window.hide()
				screen._confirm_rest()
				screen.record_notice.hide()
				continue
			if not screen.traveling:
				screen.travel_button.pressed.emit()
			screen._advance_day()
		else:
			if screen.game.pending.has("landmark"):
				check(screen.landscape.scene_id == screen.game.pending.landmark, "Actual arrival selects matching background: " + screen.game.pending.landmark)
				await capture("location-" + screen.game.pending.landmark)
			if screen.game.pending.get("landmark", "") == "kansas_river":
				await capture("kansas-river")
			if screen.game.pending.get("landmark", "") == "big_blue":
				await capture("big-blue")
			for option in screen.choices.get_children():
				if not option.disabled:
					option.pressed.emit()
					break
			if not screen.landscape.crossing.is_empty():
				check(screen.travel_button.disabled and screen.rest_button.disabled, "Crossing animation locks travel controls")
				var committed: Dictionary = screen.game.state.duplicate(true)
				screen._travel()
				screen._rest()
				screen._choose(0)
				check(screen.game.state == committed, "Animation cannot spend another day or repeat a crossing")
				screen.landscape.finish_crossing()
				if screen._reviewing_crossing():
					screen.choices.get_child(0).pressed.emit()
			if screen.game.pending.is_empty() and screen.game.state.status == "traveling":
				check(screen.landscape.scene_id.is_empty(), "Leaving a stop returns to the travel composition")
	check(screen.game.state.status == "arrived" and screen.travel_button.disabled and not screen.traveling, "Completion stops and locks travel")
	check(screen.landscape.scene_id == "platte", "Chapter endpoint retains Platte arrival illustration")
	await capture("platte-arrival")
	# Retain renderer coverage for the parked examples without exposing the mode.
	screen.game = screen.Simulation.new(1848, "unhinged")
	for event in screen.game.catalog.events:
		if event.category == "absurd":
			screen.game._present(event)
			screen._refresh()
			await capture(event.id)
			check(screen.choices.get_child_count() == 2 and screen.landscape.encounter == event.id, "Parked renderer: " + event.id)
			screen.choices.get_child(0).pressed.emit()
	screen._new_journey()
	check(screen.game.state.day == 0 and screen.game.state.status == "outfitting" and screen.departure_view.visible, "Restart returns to setup without old purchases")
	check(screen.mode.item_count == 1 and screen.mode.disabled, "Classic remains the only player mode")
	screen.departure_view.next_button.pressed.emit()
	screen.departure_view.depart_button.pressed.emit()
	screen.travel_button.pressed.emit()
	screen._new_journey()
	await create_timer(0.08).timeout
	check(screen.game.state.status == "outfitting" and screen.game.state.day == 0 and screen.travel_timer.is_stopped(), "Restart cancels a running travel timer")
	screen._show_guide()
	await process_frame
	check(screen.guide.visible, "Guide opens")
	check(screen.guide.size.y <= 340, "The guide scrolls inside the 360 px screen instead of running off it")
	await capture("guide")
	screen.guide.hide()
	# Readability: tooltips are parchment with dark ink and wrap to a fixed width; notices fit the screen.
	check(screen.theme.has_stylebox("panel", "TooltipPanel") and screen.theme.get_color("font_color", "TooltipLabel") == Color("45372f"), "Tooltips use the parchment theme")
	var hint: String = screen.wrap_text("Replaces this draft companion's personality, background, relationship, specials, flaw and wage offer. No journey time or money passes.", screen.TOOLTIP_WIDTH)
	check(hint.split("\n").size() > 1 and Array(hint.split("\n")).all(func(line): return screen.PIXEL_FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= screen.TOOLTIP_WIDTH), "Long tooltips wrap within the tooltip width")
	var tip := Label.new()
	tip.theme_type_variation = &"TooltipLabel"
	tip.text = "Bare 1, meager 2, filling 3 food units per living traveler per day. Low rations slow recovery even in camp."
	screen.add_child(tip)
	check("\n" in tip.text, "Godot's tooltip label is wrapped as it appears")
	tip.queue_free()
	screen.notice("TRAIL RECORD", "A short notice.")
	await process_frame
	var short_rect := Rect2(screen.record_notice.position, screen.record_notice.size)
	check(Rect2(0, 0, 640, 360).encloses(short_rect), "A notice opens centered on screen")
	screen.record_notice.hide()
	print("UI: %d failures" % failures)
	screen.queue_free()
	await process_frame
	quit(1 if failures else 0)

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/" + name + ".png")

