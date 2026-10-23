extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Main=preload("res://ui/main.tscn")
const Ledger=preload("res://ui/inventory_ledger.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func party():
 var game=Simulation.new(57,"classic",true)
 game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":1700,"clothing":5,"bullet_boxes":2,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
 game.party_health.daily_onset_chance=0
 game.survival.data.event_chance=0
 game.survival.forced_weather="clear"
 game.seen.append("muddy_trail")
 return game
func run():
 var game=party()
 var rows: Array=Ledger.food_rows(game)
 check(rows[0].units==1700 and rows[0].mass==1700,"Staples appear in both the food-value and physical-weight ledger")
 var meat: int=game.provisions.add_meat(40,0)
 game.state.food+=meat
 var produce: int=game.provisions.add_produce(8,0)
 game.state.food+=produce
 game.provisions.fresh.append({"pounds":10,"mass_ratio":0.4,"preserved":true,"expires":20})
 game.state.food+=10
 rows=Ledger.food_rows(game)
 check(rows[1].units==20 and rows[1].mass==40 and rows[2].units==2 and rows[2].mass==8 and rows[3].mass==4,"Meat, produce and dried food preserve their own weight ratios")
 check(rows.reduce(func(total,row):return total+row.units,0)==game.state.food,"All food categories sum to actual provisions")
 var total_mass: float=rows.reduce(func(total,row):return total+row.mass,0.0)
 check(is_equal_approx(total_mass,game.state.food+game.provisions.tracked_mass(game.state.food)-game.provisions.tracked_food(game.state.food)),"Displayed food weight reconciles with the cargo calculation")
 game=party()
 game.abandon_wagon({"food":40,"clothing":5,"bullets":20,"medicine":1})
 game.pending={}
 var before: Dictionary=Store.new().capture(game)
 var ox_event: Dictionary=game.trail_events.events.filter(func(event):return event.id=="ox_injury")[0]
 game._present_trail_event(ox_event)
 check("on foot" in game.pending.text and not "pull more slowly" in game.pending.text,"Ox injury refers to herded animals rather than an absent pulling team")
 check(game.pending.choices[0].rest and game.state.ox_health==int(before.state.ox_health)-20,"Foot wording preserves the actual injury and rest mechanics")
 var restored=Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(game))))
 check(restored!=null and restored.pending.text==game.pending.text,"Foot-specific event text survives saving and loading")
 game.choose(1)
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 screen.departure_view.hide()
 screen.game=game
 screen._refresh()
 check(screen.landscape.herded_oxen==6 and "PACKS" in screen.ledger_title.text,"Walking view retains and identifies the actual oxen")
 screen._show_supplies()
 var tabs=screen.supplies_rows.find_child("InventoryLedger",true,false)
 check(screen.theme.get_stylebox("panel","TabContainer").bg_color==Color("f6e7bc"),"Inventory tables use readable dark text on parchment")
 check(tabs!=null and tabs.get_tab_count()==3 and tabs.get_tab_title(0)=="Food" and tabs.get_tab_title(1)=="Gear" and tabs.get_tab_title(2)=="Transport","Inventory exposes readable Food, Gear and Transport sections")
 screen.supplies_window.hide()
 # Move away from the cache, then reduce health until carrying is impossible.
 screen.game.CacheSupport.relocate(screen.game,27)
 for member in screen.game.party_health.members:member.health=20
 screen.game.state.health=20
 screen.game.provisions.carriers=screen.game.party_health.members
 var day: int=screen.game.state.day
 screen._recover_wagon()
 check(screen.game.state.day==day and screen.game.pending.id=="packs_too_heavy","Overloaded recovery does not secretly travel or recover the wagon")
 check("has not been reached" in screen.record_notice.dialog_text and not "Wagon found" in screen.record_notice.dialog_text,"The recovery report distinguishes an interrupted attempt from finding the cache")
 screen.record_notice.hide()
 screen._choose(0)
 check(screen.camping and screen.section_window.visible and screen.game.can_service(),"Return to camp opens the activities needed to fix excess pack weight")
 screen.section_window.hide()
 screen._show_supplies()
 check(screen.supplies_window.visible and screen.supplies_rows.find_child("DropSupplies",true,false)!=null,"An overweight party can reach the real discard controls after acknowledging the warning")
 screen.queue_free()
 await process_frame
 print("Inventory/walking presentation: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
