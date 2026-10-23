extends SceneTree
const Main=preload("res://ui/main.tscn")
const Simulation=preload("res://simulation/trail_engine.gd")
const Plan=preload("res://simulation/discard_plan.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func party():
 var game=Simulation.new(57,"classic",true)
 game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":600,"clothing":5,"bullet_boxes":2,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
 game.seen.append("muddy_trail")
 return game
func run():
 var game=party()
 var rows: Array=Plan.stock(game)
 var bullets: Dictionary=rows.filter(func(row):return row.id=="bullets")[0]
 check(bullets.amount==40 and bullets.mass_lb==4 and bullets.unit_lb==0.1,"Stock shows real quantity, total mass and per-unit weight")
 game.state.food+=game.provisions.add_meat(40,0)
 var original: Dictionary=Store.new().capture(game)
 var plan: Dictionary=Plan.quote(game,{"food":7,"bullets":13})
 check(plan.valid and is_equal_approx(plan.dropped_lb,15.3),"Mixed food preview uses actual two-pound meat units rather than the overall food average")
 check(Store.new().capture(game)==original,"Editing and quoting consumes no time, goods or RNG")
 check(game.discard_supplies({"food":7,"bullets":13}),"Exact non-batch quantities can be committed together")
 check(game.state.food==613 and game.state.bullets==27,"Only the selected quantities leave inventory")
 check(is_equal_approx(game.provisions.cargo(game.state),plan.after_lb) and game.state.day==0,"Actual cargo matches the preview without spending a day")
 var before: Dictionary=Store.new().capture(game)
 for bad in [{"bullets":1000},{"food":-1},{"food":1.5},{"food":1,"unknown":2},{"food":0}]:
  check(not game.discard_supplies(bad) and Store.new().capture(game)==before,"Invalid quantities reject atomically: "+str(bad))
 game.pending={"id":"test","title":"Encounter","text":"Wait","choices":[{"label":"Continue","effects":{},"result":""}]}
 before=Store.new().capture(game)
 check(not game.discard_supplies({"bullets":1}) and Store.new().capture(game)==before,"Discard submission cannot bypass an encounter")
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 screen.departure_view.hide()
 screen.game=party()
 screen._refresh()
 before=Store.new().capture(screen.game)
 screen._show_drop_supplies()
 if not screen.drop_window.visible:await screen.drop_window.visibility_changed
 await process_frame
 check(screen.drop_window.size.y<root.content_scale_size.y and screen.drop_window.get_ok_button().get_rect().end.y<=screen.drop_window.size.y,"Table and confirmation fit the native game window")
 check(screen.drop_window.quantities.size()==8,"Every supply appears in the quantity table")
 check(screen.drop_window.get_ok_button().disabled,"An empty selection cannot be confirmed")
 screen.drop_window.quantities.bullets.value=13
 await process_frame
 check("DROP 1.3 LB" in screen.drop_window.preview.text and not screen.drop_window.get_ok_button().disabled,"Quantity edits update the live weight preview")
 screen.drop_window.hide()
 check(Store.new().capture(screen.game)==before,"Closing the edited form drops nothing")
 screen._show_drop_supplies()
 if not screen.drop_window.visible:await screen.drop_window.visibility_changed
 check(screen.drop_window.quantities.bullets.value==0,"Reopening starts with an empty selection")
 screen.drop_window.quantities.bullets.get_line_edit().text="17"
 screen.drop_window.quantities.bullets.get_line_edit().text_changed.emit("17")
 await process_frame
 check(screen.drop_window.quantities.bullets.value==17 and not screen.drop_window.get_ok_button().disabled,"Typed amounts update before the player leaves the field")
 screen.drop_window.get_ok_button().pressed.emit()
 check(screen.game.state.bullets==23 and screen.supplies_window.visible and not screen.drop_window.visible,"Confirm uses the typed amount and returns to the updated inventory")
 screen.supplies_window.hide()
 screen._enter_camp()
 check(not screen.section_rows.get_children().any(func(row):return row is Button and "CARGO" in row.text),"Camp no longer duplicates the permanent Supplies button")
 screen.queue_free()
 await process_frame
 print("Exact discards: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
