extends SceneTree
const Simulation = preload("res://simulation/trail_engine.gd")
const Graves = preload("res://simulation/grave_store.gd")
const Remains = preload("res://simulation/remains.gd")
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
func kill(game, id: int) -> void:
	game.party_health.affect(game.party_health.members[id],-200,game.state.day,"cholera")
	game._collect_health_events()
	game.state.party_size = game.party_health.living_count()
	game.state.health = game.party_health.average_health()
func bury_choice(game) -> int:
	for index in range(game.pending.choices.size()):
		if game.pending.choices[index].get("remains_command","") == "bury":
			return index
	return -1
func companion_graves(store) -> void:
	var game = outfit()
	game.party_health.daily_onset_chance = 0
	game.pending = {}
	game.state.day = 30
	game.state.miles = 140
	kill(game,2)
	var body: Dictionary = Remains.here(game)[0]
	check(store.make_record(game,"",body).is_empty() and not store.leave_memorial(game,"Too soon",body), "An unburied body takes no stone")
	check(game.open_remains() and game.choose(bury_choice(game)) and Remains.entry(game,int(body.id)).state == "buried", "The party buries its dead")
	var grave: Dictionary = Remains.entry(game,int(body.id))
	var record: Dictionary = store.make_record(game,"",grave)
	check(record.kind == "companion" and record.name == "JO" and record.miles == 140 and record.day == 30 and record.date == "1848-05-31" and record.epitaph == "Rest easy by the western road.", "A companion stone names the dead, the grave's mile and the day of death")
	check(game.state.status == "traveling" and store.leave_memorial(game,"Took the fever at the Blue.",grave) and store.read_records() and store.records.size() == 2, "A grave can be marked mid-journey beside the party stone")
	check(store.leave_memorial(game,"Took the fever at the Big Blue.",grave) and store.records.size() == 2 and store.records[1].epitaph == "Took the fever at the Big Blue.", "Re-marking the same grave edits its stone")
	check(store.along_route(130,150,[]).size() == 1 and store.records[0].get("kind","party") == "party", "Later journeys find the grave on the road; the older stone stays a party stone")
	var legacy := FileAccess.open(store.path,FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"format":"westward-memorials","version":1,"graves":[{"id":"old","name":"ADA","date":"1848-05-09","miles":8,"day":8,"epitaph":"Old stone."}]}))
	legacy.close()
	check(store.read_records() and store.records.size() == 1 and store.records[0].get("kind","party") == "party", "A book written before companion stones still reads")
	legacy = FileAccess.open(store.path,FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"format":"westward-memorials","version":1,"graves":[{"id":"odd","kind":"cairn","name":"ADA","date":"1848-05-09","miles":8,"day":8,"epitaph":"Odd."}]}))
	legacy.close()
	check(not store.read_records(), "An unknown stone kind is refused")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path))
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
	store.leave_memorial(game,"We should have packed more beans.")
	companion_graves(store)
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
	screen.game.party_health.daily_onset_chance = 0
	screen.game.pending = {}
	screen.game.state.miles = 60
	kill(screen.game,3)
	screen._open_remains()
	var burial := bury_choice(screen.game)
	screen._service_choice(burial)
	check(burial >= 0 and screen.grave_window.visible and screen.epitaph_input.visible and screen.grave_view.record.get("kind","") == "companion" and screen.grave_view.record.name == "E", "Burying a companion offers to mark the grave")
	screen.epitaph_input.text = "Kept the oxen fed."
	screen.epitaph_input.text_changed.emit(screen.epitaph_input.text)
	screen.grave_window.confirmed.emit()
	screen.grave_window.hide()
	var marked: Array = screen.grave_store.records.filter(func(record): return record.get("kind","") == "companion")
	check(marked.size() == 1 and marked[0].epitaph == "Kept the oxen fed." and marked[0].id in screen.visited_graves and screen.game.journal.back().begins_with("Marked E's grave"), "The stone is kept, noted in the journal and not re-read on this journey")
	await process_frame
	check(screen.service_window.visible and screen.game.pending.get("remains_menu",false), "The remains panel returns once the stone is set")
	screen.service_window.hide()
	if "--capture" in OS.get_cmdline_user_args():
		screen._read_gravestone(marked[0])
		await capture("companion-grave")
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
