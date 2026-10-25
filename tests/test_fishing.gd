extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Model=preload("res://simulation/fishing.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func make_game():
 var game=Sim.new(290001,"classic",true)
 game.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,{"oxen":4,"food":300,"clothing":5,"bullet_boxes":1,"horses":1,"saddles":1})
 game.pending={};game.survival.forced_weather="clear"
 game.state.landmark="elm_grove";game.state.next_landmark="wakarusa";game.state.leg_length=20
 game.state.leg_miles=0;game.state.miles=33
 game.party_health.daily_onset_chance=0.0
 return game
func _initialize():call_deferred("run")
func run():
 var g=make_game()
 check(not g.fishing_offer().visible,"No fishing button outside both ranges")
 g.state.leg_miles=8
 check(g.fishing_offer().visible and not g.fishing_offer().walk,"Horse-only access starts at mounted boundary")
 check(not g.fishing_quote("foot").valid and g.fishing_quote("ride_horse_light").valid,"Horse-only reach rejects foot launch in simulation")
 g.state.leg_miles=7
 check(not g.fishing_offer().visible,"One mile outside mounted range stays hidden")
 g.state.leg_miles=16
 check(g.fishing_offer().walk and g.fishing_quote("foot").valid,"Walking boundary is inclusive")
 g.state.leg_miles=15
 check(not g.fishing_quote("foot").valid,"Foot cannot reach one mile beyond boundary")
 g.state.horses=0
 check(not g.fishing_offer().visible and not g.fishing_quote("ride_horse_light").valid,"An unavailable or away horse cannot unlock fishing")
 g.state.horses=1;g.state.saddles=0
 check(not g.fishing_offer().visible,"Mounted access needs a real saddle")
 g.state.saddles=1;g.state.horse_health=39
 check(not g.fishing_offer().visible,"Unfit horse does not unlock distant water")
 g.state.horse_health=100;g.state.leg_miles=20
 var near: Dictionary=g.fishing_quote("foot")
 g.state.leg_miles=16
 check(g.fishing_quote("foot").casts<near.casts,"Round-trip travel leaves fewer casts")
 g.state.bullets=0;g.state.rations=0
 check(g.fishing_quote("foot").valid,"Fishing needs no gun ammunition")
 var before: Dictionary=Save.new().capture(g)
 check(g.start_fishing("foot"),"Launch fishing with no bullets")
 check(not g.can_service() and not g.travel() and Save.new().capture(g).is_empty(),"Activity blocks travel, services and mid-cast saves")
 check(not g.hunt_shot(0) and not g.hunt_fire_at(Vector2.ZERO),"Fishing cannot fire the rifle through hunting APIs")
 var casts: int=g.hunt.casts.size()
 for item in g.hunt.casts:item.bite=true;item.mass=4
 for index in range(casts):
  check(g.fishing_click(),"Cast accepted")
  g.advance_fishing(float(g.hunt.casts[g.hunt.cast].wait))
  check(g.hunt.phase=="bite" and g.fishing_click(),"Strike within real bite window lands fish")
 check(g.hunt.meat==casts*4 and g.state.bullets==0,"Edible catch accumulates without ammunition")
 check(not g.fishing_click(),"Finite casts cannot be repeated for unlimited catch")
 check(g.finish_fishing() and g.state.day==before.state.day+1,"Full outing settles exactly one day")
 check(g.last_hunt_recovery.retrieved==casts*4 and g.last_hunt_recovery.kcal_per_lb==600,"Fish applies calorie conversion after physical retrieval")
 check(g.journal.any(func(line):return "Fishing:" in line and "casts" in line),"Journal records casts and actual recovered catch")
 check(not g.finish_fishing(),"Closing again cannot duplicate catch or time")
 check(g.last_hunt_recovery.food>0 and is_equal_approx(g.provisions.tracked_mass(g.state.food),g.last_hunt_recovery.mass),"Uneaten fish keeps its actual physical mass")
 var fish_save: Dictionary=Save.new().capture(g)
 var fish_copy=Save.new().restore(JSON.parse_string(JSON.stringify(fish_save)))
 check(fish_copy!=null and Save.new().capture(fish_copy)==fish_save,"Retained fish mass and food round-trip exactly")
 g=make_game();g.state.leg_miles=20
 check(g.camp_tasks.assign(g,1,"fish"),"Companion can hold a standing fishing assignment")
 check(Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))!=null,"Fishing task persists in saves")
 check(g.rest_in_camp() and g.supply_history.any(func(row):return row.event=="camp_fishing"),"Companion fishes during shared camp day")
 g=make_game();g.state.leg_miles=8
 check(not g.camp_tasks.reason(g,1,"fish").is_empty(),"Companion cannot walk to horse-only water")
 g=make_game();g.state.leg_miles=16;g.state.travel_direction="east"
 check(g.fishing_offer().walk,"Turning east preserves access on the same road")

 var snapshot: Dictionary=Save.new().capture(g)
 check(Save.new().restore(JSON.parse_string(JSON.stringify(snapshot)))!=null,"Completed fishing survives JSON save/load")
 g=make_game();g.state.leg_miles=8
 var horses: int=g.state.horses
 check(g.start_fishing("ride_horse_light") and g.state.horses==horses-1 and g.state.saddles==0,"Mounted fishing reserves horse and tack")
 var day: int=g.state.day
 g.survival.forced_weather="heat"
 check(g.finish_fishing() and g.state.day==day+1 and g.state.horses==horses and g.state.saddles==1,"Early return still costs day and returns reserved stock")
 check(g.state.horse_health<100,"Mounted outing in heat applies existing animal wear")
 g=make_game();g.state.leg_miles=20;g.state.food=0
 check(g.start_fishing("foot") and g.finish_fishing(),"An empty-handed starving party can attempt fishing")
 check(g.state.food==0 and g.state.day==1,"Empty emergency return creates no food and still costs a day")
 g=make_game();g.state.leg_miles=16;g.party_health.begin_condition(0,"broken_leg",0,1)
 check(not g.fishing_quote("foot").valid,"A broken leg prevents a foot fishing expedition")
 g=make_game();g.state.leg_miles=16
 var note: String=str(g.rng.state)
 var first: Dictionary=g.fishing_offer()
 g.fishing_offer();g.fishing_quote("foot")
 check(str(g.rng.state)==note and first==g.fishing_offer(),"Access and setup previews do not reroll game randomness")
 g=make_game();g.state.leg_miles=16;g.survival.set_weather("thunderstorm")
 check(not g.fishing_offer().visible and not g.start_fishing("foot"),"Thunderstorm blocks unsafe riverbank fishing")
 var model=Model.new()
 var offer: Dictionary={"casts":3}
 var a: Dictionary=model.begin(123,2,offer,6)
 var b: Dictionary=model.begin(123,2,offer,6)
 check(a==b,"Same seed and outing replay the same fishing opportunities")
 a.casts[0].bite=true
 model.click(a);model.tick(a,float(a.casts[0].wait)+float(model.data.bite_seconds)+0.1)
 check(a.cast==1 and a.meat==0,"Large frame delta cannot extend a missed bite")
 model.click(a);model.click(a)
 check(a.cast==2 and a.meat==0,"Early strike consumes its cast")
 model.tick(a,1000)
 check(a.ended,"Time cap ends idle fishing")
 for key in ["duration","foot_radius","kcal_per_lb"]:
  var invalid: Dictionary=model.data.duplicate(true);invalid[key]=-1
  check(not Model.new().load_data(invalid),"Reject invalid fishing configuration")
 var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-fishing-v5.json"))
 var restored=Save.new().restore(previous)
 check(restored!=null,"Authentic previous-version save loads")
 if restored!=null:
  check(restored.state==Save.new().normalize(previous.state) and restored.field_outings.snapshot()==Save.new().normalize(previous.field_outings) and str(restored.rng.state)==previous.random,"Previous stock, away horse, trip and RNG are preserved")
  check(restored.state.horses==0,"Old reserved horse remains unavailable for fishing")
 # Actual menu visibility and horse-only choice restrictions.
 var screen=load("res://ui/main.tscn").instantiate()
 root.add_child(screen);await process_frame
 screen.departure_view.hide();screen.game=make_game()
 screen._show_section("Hunt & forage")
 check(not screen.section_rows.get_children().any(func(n):return n is Button and n.text.begins_with("FISH")),"UI hides Fishing out of range")
 screen.game.state.leg_miles=8;screen._show_section("Hunt & forage")
 check(screen.section_rows.get_children().any(func(n):return n is Button and n.text=="FISH · HORSE REQUIRED"),"UI labels horse-only fishing")
 screen._open_fishing()
 check(screen.fishing_window.choices.get_child(0).disabled and not screen.fishing_window.choices.get_child(1).disabled,"Horse-only setup disables foot choice")
 screen.queue_free();await process_frame
 print("Fishing: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
