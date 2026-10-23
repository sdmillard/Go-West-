extends SceneTree
const Main=preload("res://ui/main.tscn")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func run():
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 var view=screen.departure_view
 screen.game.depart("banker",view.party_names(),5,view.cart(),view.customization())
 view.hide()
 screen.game.pending={}
 screen._refresh()
 var before: Dictionary=Store.new().capture(screen.game)
 for key in screen.ribbon_buttons:
  check(Rect2(640,9,150,342).encloses(screen.ribbon_buttons[key].get_global_rect()),key+" fits the right rail")
 var groups: Array=["Travel","Camp","Hunt & forage","Villainy","History"]
 for group in groups:
  screen._show_section(group)
  await process_frame
  check(screen.section_window.visible and screen.section_window.title==group.to_upper(),group+" opens its own tree")
  check(Store.new().capture(screen.game)==before,"Opening "+group+" spends no time or supplies")
  screen.section_window.hide()
 screen._show_section("Travel")
 check(is_instance_valid(screen.pace) and screen.pace.get_parent()==screen.section_rows,"Pace survives revisiting its section")
 screen.pace.select(2)
 screen.pace.item_selected.emit(2)
 check(screen.game.state.pace==2,"The moved pace control changes the actual journey setting")
 screen._show_section("Supplies")
 check(is_instance_valid(screen.pace) and not screen.pace.visible,"Leaving Travel preserves and hides its controls")
 check(not screen.section_window.visible and screen.supplies_window.visible,"Supplies opens the inventory directly without a one-button branch")
 check(screen.supplies_rows.get_child(0).text=="DROP SUPPLIES >" and "ABANDON WAGON" in screen.supplies_rows.get_child(1).text,"Drop and abandon actions are visible before the inventory details")
 screen.supplies_rows.get_child(0).pressed.emit()
 check(screen.section_window.title=="DROP SUPPLIES" and not screen.supplies_window.visible,"Drop supplies opens a distinct inventory action")
 var food: int=screen.game.state.food
 var day: int=screen.game.state.day
 screen.section_rows.get_children().filter(func(row):return row is Button and row.text=="DROP 50 FOOD")[0].pressed.emit()
 check(screen.game.state.food==food-50 and screen.game.state.day==day,"Dropping supplies changes the real inventory without spending time")
 screen.section_window.hide()
 screen.supplies_window.hide()
 screen._show_section("Hunt & forage")
 screen.section_rows.get_child(1).pressed.emit()
 check(screen.service_window.visible and screen.game.pending.title=="Foraging","Foraging is reachable from the ribbon tree")
 screen.service_window.hide()
 screen.game.choose(screen.game.pending.choices.size()-1)
 screen.game.state.next_landmark="fort_bridger"
 screen.game._arrive_landmark()
 for category in ["theft","robbery","attack"]:
  var day_before: int=screen.game.state.day
  screen._open_crime_category(category)
  var labels: Array=screen.service_rows.get_children().filter(func(row):return row is Button).map(func(row):return row.text)
  check(screen.service_window.visible and screen.game.state.day==day_before,"Opening "+category+" previews without committing a crime")
  var allowed: Array=["shoot","assault"] if category=="attack" else [category]
  for choice in screen.game.pending.choices:
   if choice.get("crime_command","") in ["theft","robbery","shoot","assault"]:
    check((choice.label in labels)==(choice.crime_command in allowed),category+" exposes only its own crime choices")
  screen._service_choice(screen.game.pending.choices.size()-1)
 screen._show_section("Party member")
 screen.section_window.confirmed.emit()
 await process_frame
 check(screen.section_window.title=="ATTACK SOMEONE","Back follows the attack hierarchy")
 screen.section_window.hide()
 screen._show_preferences()
 check(screen.options_window.visible and not screen.section_window.visible,"Options opens preferences separately")
 var original: Dictionary=Store.new().capture(screen.game)
 screen.preferences_path="user://ribbon-test-preferences.cfg"
 screen.travel_speed.select(2)
 screen._change_preferences()
 check(screen.travel_timer.wait_time==0.75 and Store.new().capture(screen.game)==original,"Display speed leaves daily simulation rules and state intact")
 screen.travel_speed.select(0)
 screen._load_preferences()
 check(screen.travel_speed.selected==2,"Preferences persist independently of journey saves")
 screen.options_window.hide()
 screen.game.pending={"id":"test","title":"Encounter","text":"Resolve first","choices":[{"label":"Continue","effects":{},"result":""}]}
 screen._refresh()
 check(screen.ribbon_buttons.SUPPLIES.disabled and not screen.options_button.disabled,"Encounters gate gameplay services while allowing preferences")
 screen._show_section("Supplies")
 check(not screen.section_window.visible,"Disabled service sections cannot bypass an encounter")
 screen.game.pending={}
 screen._refresh()
 screen._show_preferences()
 await process_frame
 check(not screen.options_window.get_ok_button().visible,"Preferences exit through the shared X rather than a second OK/Back button")
 check(screen.theme.get_icon("close","Window").get_size()==Vector2(14,14),"The small close glyph retains a usable shared hit area")
 screen.options_window.hide()
 screen._show_section("Villainy")
 await process_frame
 var click:=InputEventMouseButton.new()
 click.button_index=MOUSE_BUTTON_LEFT
 click.pressed=true
 click.position=Vector2(screen.section_window.position)+Vector2(screen.section_window.size.x-11,-8)
 root.push_input(click)
 click=click.duplicate()
 click.pressed=false
 root.push_input(click)
 await process_frame
 check(not screen.section_window.visible,"Clicking the embedded title-bar X closes the section")
 screen._rest()
 await process_frame
 check(screen.rest_window.get_ok_button().visible and not screen.rest_window.get_cancel_button().visible,"Confirmation retains its explicit action and uses X to cancel")
 screen.rest_window.hide()
 screen._show_map()
 check(screen.map_view.close_button.text=="X" and screen.map_view.close_button.position.y<30,"Map uses the same top-right X convention")
 screen.map_view.close_button.pressed.emit()
 check(not screen.map_view.visible,"Map X returns to the trail")
 screen.queue_free()
 await process_frame
 DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ribbon-test-preferences.cfg"))
 print("Ribbon: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
