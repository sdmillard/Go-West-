extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Main=preload("res://ui/main.tscn")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func outfit():
	var game=Simulation.new(57,"classic",true)
	game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":1000,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
	game.seen.append("muddy_trail")
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	return game
func run():
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=outfit()
	screen._refresh()
	var store=Store.new()
	var before=store.capture(screen.game)
	screen.rest_button.pressed.emit()
	await process_frame
	check(screen.camping and screen.landscape.scene_id=="camp" and screen.section_window.visible,"Camp button enters the camp location and activities")
	check(not screen.rest_window.visible and store.capture(screen.game)==before,"Entering camp does not rest, heal, feed, pay wages or advance RNG")
	check(not screen.ribbon_buttons.has("CAMP & CARE"),"There is one camp entry rather than a duplicate ribbon button")
	screen.section_window.hide()
	check(screen.camping and store.capture(screen.game)==before,"Closing camp activities leaves the party camped without time passing")
	screen._rest()
	await process_frame
	check(screen.rest_window.visible and store.capture(screen.game)==before,"Opening duration prompt spends no time, resources or randomness")
	# Headless display size is a dummy; use the game's logical canvas bounds.
	check(screen.rest_window.size.y<=root.content_scale_size.y and screen.rest_window.size.x<=root.content_scale_size.x,"Duration dialog fits the game window")
	check(screen.rest_days_input.get_rect().end.y<=screen.rest_quote.position.y,"Typed input and quote do not overlap")
	screen.rest_window.hide()
	check(store.capture(screen.game)==before,"Cancel leaves the journey unchanged")
	for invalid in ["", "0", "-1", "1.5", "abc", "31"]:
		screen.rest_days_input.text=invalid
		screen._confirm_rest()
		check(screen.rest_window.get_ok_button().disabled and store.capture(screen.game)==before,"Reject invalid duration: "+invalid)
	screen.rest_days_input.text="4"
	screen._update_rest_quote()
	check("60 food units" in screen.rest_quote.text,"Quote uses living party size and selected daily rations")
	if "--capture" in OS.get_cmdline_user_args():
		screen.rest_window.popup_centered(Vector2i(490,220))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/camp-rest.png")
		screen.rest_window.hide()
	var reference=outfit()
	for day in range(4):reference.rest()
	screen._confirm_rest()
	check(screen.game.state==reference.state and screen.game.state.day==4 and screen.game.state.miles==0,"Four selected days equal four ordinary rest days without travel")
	var actual=store.capture(screen.game)
	var expected=store.capture(reference)
	actual.erase("journal")
	expected.erase("journal")
	check(actual==expected,"Daily health, weather, provisions and random states match ordinary rest")
	check("4 of 4" in screen.record_notice.dialog_text and screen.camping,"Completion reports actual duration and shows camp")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/camp-rest-result.png")
	screen.record_notice.hide()
	screen.game=outfit()
	screen.game.state.food=60
	screen.last_food_alert=0
	screen.rest_days_input.text="10"
	screen._confirm_rest()
	check(screen.game.state.day==2 and screen.game.state.food==30 and screen.food_notice.visible,"New low-food warning interrupts before spending the next rest day")
	check("2 of 10" in screen.game.journal.back(),"Journal records incomplete rest duration")
	screen.food_notice.hide()
	screen.game=outfit()
	screen.game.seen.clear()
	screen.last_food_alert=0
	screen.rest_days_input.text="10"
	screen._confirm_rest()
	check(not screen.game.pending.is_empty() and screen.game.state.day<10,"Rest stops at a historical event without autochoosing its outcome")
	screen.record_notice.hide()
	screen.game=outfit()
	screen.game.state.next_landmark="fort_laramie"
	screen.game._arrive_landmark()
	screen._refresh()
	check(not screen.rest_button.disabled,"Camp is available while stopped at a landmark")
	screen.rest_days_input.text="3"
	screen._confirm_rest()
	check(screen.game.state.day==3 and screen.game.pending.get("landmark", "")=="fort_laramie","Landmark rest preserves stop choices after chosen duration")
	screen.record_notice.hide()
	var day: int=screen.game.state.day
	for index in range(screen.game.pending.choices.size()):
		if screen.game.pending.choices[index].get("action", "")=="rest":
			screen._choose(index)
			break
	check(screen.rest_window.visible and screen.game.state.day==day,"Landmark rest choice opens duration prompt rather than silently resting one day")
	screen.rest_window.hide()
	screen.game=outfit()
	screen.game.state.food=0
	for member in screen.game.party_health.members:member.health=1
	screen.game.state.health=1
	screen.last_food_alert=2
	screen.rest_days_input.text="30"
	screen._confirm_rest()
	check(screen.game.state.status=="lost" and screen.game.state.day==1,"Fatal daily consequences end the rest immediately")
	screen.record_notice.hide()
	screen.game=outfit()
	screen.game.state.food=0
	# A companion, not the leader: the leader's death would end the journey.
	screen.game.party_health.members[1].health=1
	screen.game.state.health=screen.game.party_health.average_health()
	screen.last_food_alert=2
	screen.rest_days_input.text="30"
	screen._confirm_rest()
	check(screen.game.state.status=="traveling" and screen.game.state.party_size==4 and screen.game.state.day==1,"A single death interrupts rest even when the journey can continue")
	screen.record_notice.hide()
	screen.game=outfit()
	screen.game.pending={"id":"test", "title":"Pending event", "choices":[]}
	before=store.capture(screen.game)
	check(not screen.game.rest_in_camp() and store.capture(screen.game)==before,"Simulation refuses camp rest through unresolved events")
	screen.queue_free()
	await process_frame
	print("Camp rest: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
