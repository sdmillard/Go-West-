extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Graves = preload("res://simulation/grave_store.gd")
const Main = preload("res://ui/main.tscn")
var checks := 0
var failures := 0
func check(value: bool,message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _initialize() -> void:
	call_deferred("run")
func outfit():
	var game = Simulation.new(99,"classic",true)
	game.depart("farmer",["ADA","SAM","JO","LEE","PAT"],5,{"oxen":6,"food":800,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1})
	return game
func run() -> void:
	var store = Graves.new()
	store.path = "user://test-gravestones.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path + suffix))
	var game = outfit()
	check(not store.leave_memorial(game,"Not yet"), "Living parties cannot leave a terminal gravestone")
	game.state.miles = 8
	game._change_health(-100,"lack of food")
	game._check_health()
	check(game.state.status == "lost" and store.leave_memorial(game,"The road was longer than the pantry."), "Lost party can author a persistent epitaph")
	check(store.read_records() and store.records.size() == 1 and store.records[0].name == "ADA" and store.records[0].miles == 8, "Memorial keeps party name and actual guide mile")
	check(store.leave_memorial(game,"We should have packed more beans.") and store.records.size() == 1, "Editing same loss updates rather than duplicates its stone")
	var next = Graves.new()
	next.path = store.path
	check(next.read_records() and next.records[0].epitaph == "We should have packed more beans.", "Memorial survives a fresh store instance")
	check(next.along_route(0,12,[]).size() == 1 and next.along_route(0,12,[next.records[0].id]).is_empty(), "Later journey finds the stone once per visit list")
	check(next.make_record(game,"\n\t").epitaph == "They followed the western road." and next.make_record(game,"X".repeat(200)).epitaph.length() == 90, "Blank and long inscriptions stay readable")
	var file := FileAccess.open(store.path,FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(not store.leave_memorial(game,"New") and FileAccess.get_file_as_string(store.path) == "{broken", "Damaged archive is preserved without overwrite")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path))
	var screen = Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.grave_store.path = store.path
	screen._depart("farmer",["ADA","SAM","JO","LEE","PAT"],5,{"oxen":6,"food":800,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1})
	screen.game.state.miles = 8
	screen.game._change_health(-100,"lack of food")
	screen.game._check_health()
	screen._refresh()
	screen._edit_gravestone()
	screen.epitaph_input.text = "We should have packed more beans."
	screen.epitaph_input.text_changed.emit(screen.epitaph_input.text)
	check(screen.grave_window.visible and screen.grave_view.record.epitaph == screen.epitaph_input.text, "Editor previews the inscription on original pixel stone")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("gravestone")
	screen.grave_window.confirmed.emit()
	screen.grave_window.hide()
	check(screen.grave_store.records.size() == 1, "Leave This Stone persists from actual dialog")
	screen._new_journey()
	screen._depart("farmer",["B","C","D","E","F"],5,{"oxen":6,"food":800,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1})
	var before: Dictionary = screen.game.state.duplicate(true)
	screen._check_roadside_graves(0,12)
	check(screen.grave_window.visible and not screen.epitaph_input.visible and screen.game.state == before and not screen.traveling, "Next journey reads roadside memorial without time or inventory changes")
	screen.grave_window.hide()
	screen._show_supplies()
	if "--capture" in OS.get_cmdline_user_args():
		await capture("provisions")
	screen.queue_free()
	await process_frame
	print("Graves: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+name+".png")
