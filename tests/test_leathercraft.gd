extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party():
 var g=Sim.new(570301,"classic",true)
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":400,"clothing":5,"bullet_boxes":5,"medicine":5}),"Leathercraft fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.survival.forced_weather="clear"
 g.characters.profiles[1].skill="Leatherworking";g.characters.profiles[1].specials=[];g.state.deer_hide=1
 return g
func run():
 var g=party()
 check(g.characters.background_benefit("Leatherworking").contains("buckskin") and g.characters.wage_quote(g.characters.profiles[1]).daily_cents>=70,"Leatherworking is a described and priced primary background")
 g._arrive_landmark(true,false)
 check(g.income.quote(g,1,"leatherwork").valid,"Background alone unlocks paid leather jobs")
 g.pending={}
 g.characters.profiles[2].skill="Carpentry";g.characters.profiles[2].specials=[]
 var before: Dictionary=Save.new().capture(g)
 check(not g.leathercraft.work(g,2,"tan_leather") and Save.new().capture(g)==before,"Carpentry alone cannot manufacture leather goods")
 var q: Dictionary=g.leathercraft.quote(g,1,"tan_leather")
 check(q.valid and q.step.input=="deer_hide" and q.step.output=="hide_scraped" and Save.new().capture(g)==before,"Read-only quote identifies exactly the next physical stage")
 var food: int=g.state.food;var start: int=g.state.day
 check(g.leathercraft.work(g,1,"tan_leather") and g.state.deer_hide==0 and g.state.hide_scraped==1,"First day consumes one real hide and leaves real unfinished cargo")
 check(not g.state.has("buckskin") and g.state.day==start+1 and g.state.food==food-15,"A raw hide does not become finished leather in one day; meals/time are real")
 var save: Dictionary=Save.new().capture(g)
 var loaded=Save.new().restore(JSON.parse_string(JSON.stringify(save)))
 check(loaded!=null and Save.new().capture(loaded)==save,"Unfinished stage saves and restores exactly")
 check(g.leathercraft.work(g,1,"tan_leather") and g.state.hide_scraped==0 and g.state.hide_softened==1,"Second day advances the existing unfinished skin")
 check(g.leathercraft.work(g,1,"tan_leather") and g.state.hide_softened==0 and g.state.buckskin==1,"Third day produces dressed buckskin")
 check(g.leathercraft.work(g,1,"make_gloves") and g.state.buckskin==0 and g.state.glove_pieces==1,"Glove cutting consumes actual buckskin")
 check(g.leathercraft.work(g,1,"make_gloves") and g.state.glove_pieces==0 and g.state.buckskin_gloves==4,"Sewing finishes exactly four glove pairs")
 check(g.state.day==start+5 and g.state.food==food-75,"Complete chain takes five real worker-days and ordinary meals")
 check(g.supply_history.filter(func(e):return e.event=="leathercraft").size()==5,"Every material conversion enters supply history")
 before=Save.new().capture(g)
 check(not g.leathercraft.work(g,1,"make_gloves") and Save.new().capture(g)==before,"Missing materials cannot create goods or consume a day")
 g._arrive_landmark(true,false);var money: float=g.state.money
 check(g.counter_checkout({"buckskin_gloves":-4}) and is_equal_approx(g.state.money-money,3.0) and g.state.buckskin_gloves==0,"Existing counter sells actual finished glove pairs at exact configured prices")
 check(Save.new().restore(Save.new().capture(g))!=null,"Craft and sale history remain a valid save")
 g=party();g.state.buckskin_gloves=20;g._arrive_landmark(true,false)
 check(g.counter_checkout({"buckskin_gloves":-20}) and Save.new().restore(Save.new().capture(g))!=null,"Full unit-based demand can sell twenty pairs without corrupting the legacy lot ledger")
 check(not g.counter_quote({"buckskin_gloves":-1}).valid,"Finite buyer demand remains spent after the full sale")
 g=party();g.characters.profiles[2].skill="Leatherworking";g.characters.profiles[2].specials=[]
 check(g.camp_tasks.assign(g,1,"tan_leather") and g.camp_tasks.assign(g,2,"tan_leather"),"Two background artisans may hold standing tasks")
 check(g.rest() and g.state.deer_hide==0 and g.state.hide_scraped==1 and int(g.state.get("hide_softened",0))==0,"Morning reservation prevents duplicate input or same-day stage chaining")
 check(g.rest() and g.state.hide_scraped==0 and g.state.hide_softened==1 and int(g.state.get("buckskin",0))==0,"Another day's standing work advances only one stage")
 g=party();g.state.landmark="south_pass";g.state.next_landmark="little_sandy";g.state.leg_miles=5
 var edge: Dictionary=g.current_edge()
 var saved_hazard: String=edge.get("hazard","");edge.hazard="waterless"
 check(not g.leathercraft.quote(g,1,"tan_leather").valid,"Hide dressing cannot pretend water exists on a waterless stretch")
 edge.hazard=saved_hazard
 g=party();g.party_health.members[1].health=60
 check(g.camp_tasks.assign(g,3,"nurse",1),"Nursing reserves an artisan as a patient")
 before=Save.new().capture(g)
 check(not g.leathercraft.work(g,1,"tan_leather") and Save.new().capture(g)==before,"Nursed artisan cannot also craft")
 g=party();g.camp_tasks.assign(g,1,"tan_leather")
 g._arrive_landmark(true,false);g.income.work(g,1,"leatherwork")
 check(g.state.deer_hide==1 and int(g.state.get("hide_scraped",0))==0,"A paid leatherworker cannot also use home materials that day")
 g=party();g.party_health.members[0].health=60;g.camp_tasks.assign(g,3,"nurse",0)
 var kits: int=g.state.medicine
 check(g.leathercraft.work(g,1,"tan_leather") and g.state.medicine==kits-1 and g.camp_tasks.job(3).patient==0,"Leader can remain nursed while a companion crafts")
 g=party();g.camp_tasks.assign(g,1,"tan_leather");g.camp_tasks.begin(g,"rest");g.camp_tasks.prepare(g);g.party_health.members[1].alive=false;g.camp_tasks.finish(g)
 check(g.state.deer_hide==1 and int(g.state.get("hide_scraped",0))==0,"Worker loss does not create output or destroy reserved input")
 g=party();g.leathercraft.work(g,1,"tan_leather")
 check(g.abandon_wagon({"food":20,"clothing":5,"bullets":20,"hide_scraped":1}),"Unfinished work is packable physical cargo")
 save=Save.new().capture(g);loaded=Save.new().restore(JSON.parse_string(JSON.stringify(save)))
 check(loaded!=null and loaded.state.hide_scraped==1,"Unfinished work survives pack/cache save paths")
 for bad_count in [-1,0.5,"one"]:
  var bad: Dictionary=save.duplicate(true);bad.state.hide_scraped=bad_count
  check(Save.new().restore(bad)==null,"Invalid crafted inventory count rejects")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-leathercraft-save-v1.json"))
 loaded=Save.new().restore(old)
 check(loaded!=null and loaded.state==Save.new().upgraded_state(old.state) and loaded.characters.profiles==Save.new().normalize(old.characters),"Actual old perk save preserves state and prior background")
 if loaded!=null:check(loaded.leathercraft.qualified(loaded,1),"Old Leatherworker cross-training retains its ability")
 var screen=load("res://ui/main.gd").new();root.add_child(screen);await process_frame
 var view=screen.departure_view
 view.use_preset_party()
 check(view.background_choice.item_count==7 and not view.special_checks.has("Leatherworker"),"Creation offers Leatherworking among backgrounds rather than specials")
 var found:=false
 for i in range(view.background_choice.item_count):
  if view.background_choice.get_item_text(i)=="Leatherworking":view.background_choice.select(i);found=true
 var custom: Dictionary=view.customization()
 check(found and custom.profiles[view.edited_member].skill=="Leatherworking" and screen.game.characters.valid_setup(custom),"Visible background selector produces valid character creation")
 screen.game=party();screen.departure_view.hide();screen.leathercraft_window.open(screen.game);await process_frame
 var actions: Array=screen.leathercraft_window.body.get_children().filter(func(n):return n is Button and not n.disabled)
 start=screen.game.state.day
 check(not actions.is_empty(),"Leatherwork window exposes an available crafting action")
 if not actions.is_empty():actions[0].pressed.emit()
 check(screen.game.state.day==start+1 and screen.game.state.hide_scraped==1,"Visible crafting action commits one real stage")
 screen.leathercraft_window.hide();screen.queue_free();await process_frame
 print("Leathercraft: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
