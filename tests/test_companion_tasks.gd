extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party():
 var g=Sim.new(5701,"classic",true)
 g.depart("banker",["Leader","Anne","Ben","Cara","Dan"],5,{"oxen":4,"food":500,"clothing":5,"bullet_boxes":5,"medicine":3,"salt":10})
 g.pending={}
 g.party_health.daily_onset_chance=0
 g.survival.forced_weather="clear"
 g.survival.data.event_chance=0
 for p in g.characters.profiles:
  p.trust=50
  if int(p.id)>0:p.boundaries.forbidden=[]
 return g
func rest(g):
 g.pending={}
 return g.rest()
func run():
 var store=Store.new()
 var g=party()
 check(not g.camp_tasks.enabled(),"Old group actions remain default until a job is selected")
 var baseline: Dictionary=store.capture(g)
 check(not g.camp_tasks.assign(g,0,"forage") and not g.camp_tasks.assign(g,1,"unknown"),"Leader and unknown job reject")
 check(not g.camp_tasks.assign(g,1,"nurse",1) and not g.camp_tasks.assign(g,1,"nurse",99),"Invalid patients reject")
 check(store.capture(g)==baseline,"Invalid assignment consumes no time, supplies or randomness")
 check(g.camp_tasks.assign(g,1,"nurse",4),"Assign a named patient")
 check(g.camp_tasks.assign(g,2,"dry") and g.camp_tasks.assign(g,3,"forage"),"Different companions hold different standing jobs")
 g.characters.profiles[1].skill="Caregiving"
 g.party_health.members[4].health=60
 g.state.health=g.party_health.average_health()
 g.state.food+=g.provisions.add_meat(100,0)
 g.characters.profiles[2].specials=["Mercenary"]
 g.characters.start_contract(g,2,int(g.characters.wage_quote(g.characters.profiles[2]).daily_cents),1)
 g.characters.set_auto_pay(g,2,true)
 var money: int=roundi(g.state.money*100)
 var medicine: int=g.state.medicine
 check(g.start_hunt(),"Leader hunts while jobs are assigned")
 check(g.hunting_capacity()==42,"Nurse, drier, forager and resting patient do not haul a hunt")
 g.hunt.meat=200
 check(g.finish_hunt() and g.state.day==1,"All jobs and hunt share exactly one day")
 check(g.state.medicine==medicine-1,"Nurse uses exactly one kit")
 check(roundi(g.state.money*100)==money-int(g.characters.profiles[2].contract.wage_cents),"Shared day pays one actual daily wage")
 check(g.supply_history.filter(func(e):return e.event=="camp_nursing").size()==1,"Nursing has one transaction")
 check(g.supply_history.filter(func(e):return e.event=="camp_drying").size()==1,"Drying has one transaction")
 check(g.party_health.members[4].health>60,"Named patient gets care and rest")
 check(g.party_health.members[1].health<=86 and g.party_health.members[2].health<=86,"Workers miss rest recovery")
 check(g.provisions.fresh.any(func(b):return b.get("preserved",false)),"Morning meat dries during the hunting day")
 check(g.camp_tasks.day_plan.is_empty(),"Daily plan cannot resolve twice")
 var saved: Dictionary=store.capture(g)
 var loaded=store.restore(JSON.parse_string(JSON.stringify(saved)))
 check(loaded!=null and loaded.camp_tasks.snapshot()==g.camp_tasks.snapshot(),"Standing jobs and small greens survive JSON")
 if loaded!=null:
  loaded.party_health.daily_onset_chance=0;loaded.survival.forced_weather="clear";loaded.survival.data.event_chance=0
  rest(g);rest(loaded)
  check(store.capture(g)==store.capture(loaded),"Next camp day preserves exact state and random streams across JSON")
 g=party()
 g.camp_tasks.assign(g,1,"dry")
 g.start_hunt();g.hunt.meat=200;g.finish_hunt()
 check(not g.provisions.fresh.any(func(b):return b.get("preserved",false)),"Evening catch cannot become morning drying stock")
 g=party()
 g.camp_tasks.assign(g,1,"forage")
 var before_food: int=g.state.food
 rest(g)
 check(g.state.food==before_food-15,"Single small forage does not invent a food unit or charge a second meal")
 check(g.state.get("camp_greens_lb",0)>0 and g.state.camp_greens_lb<4,"Small searches preserve physical greens rather than round away nutrition")
 var cargo: float=g.provisions.cargo(g.state)
 var without: Dictionary=g.state.duplicate();without.camp_greens_lb=0
 check(is_equal_approx(cargo-g.provisions.cargo(without),g.state.camp_greens_lb),"Loose greens count against cargo")
 g.state.camp_greens_lb=3;g.state.camp_greens_expires=g.state.day+3
 g.party_health.days_without_fresh=20
 rest(g)
 check(g.party_health.days_without_fresh==0,"Actually eaten loose greens supply vitamin C")
 check(g.state.camp_greens_expires>g.state.day or g.state.camp_greens_lb==0,"New harvest gets a future spoil date")
 g=party()
 g.camp_tasks.assign(g,1,"nurse",4);g.camp_tasks.assign(g,2,"nurse",4)
 g.party_health.members[4].health=60;g.state.health=g.party_health.average_health()
 g.state.medicine=1
 rest(g)
 check(g.state.medicine==0 and g.supply_history.filter(func(e):return e.event=="camp_nursing").size()==1,"Two nurses cannot duplicate a patient or spend the same kit")
 g=party()
 g.camp_tasks.assign(g,1,"nurse",2);g.camp_tasks.assign(g,2,"forage")
 g.party_health.members[2].health=60;g.state.health=g.party_health.average_health()
 rest(g)
 check(not g.state.has("camp_greens_lb"),"A patient cannot also forage")
 g=party()
 g.camp_tasks.assign(g,1,"forage")
 g.characters.profiles[1].trust=0
 rest(g)
 check(not g.state.has("camp_greens_lb"),"Refusing workers contribute nothing")
 g=party()
 g.camp_tasks.assign(g,1,"forage")
 g.party_health.begin_condition(1,"broken_leg",0,1)
 rest(g)
 check(not g.state.has("camp_greens_lb"),"Broken legs block gathering")
 g=party()
 g.camp_tasks.assign(g,1,"forage")
 g.state.leg_length=20;g.state.next_landmark="elm_grove"
 check(g.travel(),"Travel remains available with standing jobs")
 check(not g.state.has("camp_greens_lb"),"Camp jobs do not also run during travel")
 g=party()
 g.camp_tasks.assign(g,1,"hunt_help")
 check(g.hunting_capacity()==85,"Only assigned helper adds a second person's health-scaled hauling")
 g.characters.profiles[1].skill="Hunting"
 check(g.characters.available(g,"Hunting"),"Assigned Hunter supplies minigame benefit")
 g.camp_tasks.assign(g,1,"forage")
 check(not g.characters.available(g,"Hunting"),"Working forager cannot also provide Hunter benefit")
 g=party()
 g.camp_tasks.assign(g,1,"hunt_help")
 g.party_health.members[1].health=30;g.state.health=g.party_health.average_health()
 check(g.hunting_capacity()==42,"A helper too ill to work cannot silently add hauling")
 g=party()
 g.camp_tasks.assign(g,1,"nurse",2);g.camp_tasks.assign(g,2,"hunt_help")
 g.party_health.members[2].health=60;g.state.health=g.party_health.average_health()
 g.start_hunt()
 check(g.hunting_capacity()==42,"A helper receiving nursing is reserved as a patient")
 g.hunt.meat=100;g.finish_hunt()
 check(g.last_hunt_recovery.retrieved==42,"Patient cannot reappear as a helper after daily work resolves")
 g=party()
 g.camp_tasks.assign(g,1,"dry");g.camp_tasks.assign(g,2,"forage")
 g.state.food+=g.provisions.add_meat(100,0)
 g.open_forage()
 check(g.choose(0) and g.state.day==1,"Leader forages through the real service menu")
 check(g.supply_history.any(func(e):return e.event=="camp_drying"),"Drying also runs while the leader's service menu is open")
 g=party()
 g.camp_tasks.assign(g,1,"nurse",4);g.camp_tasks.assign(g,2,"nurse",3)
 g.party_health.members[3].health=60;g.party_health.members[4].health=60
 g.state.health=g.party_health.average_health();g.state.medicine=1
 g.open_care()
 var choice: int=-1
 for i in range(g.pending.choices.size()):
  if g.pending.choices[i].get("member_id",-1)==4 and g.pending.choices[i].get("requires",{}).has("medicine"):choice=i;break
 check(choice>=0 and g.choose(choice) and g.state.medicine==0,"Leader care has priority; nurses cannot overspend the final kit")
 g=party()
 g.camp_tasks.assign(g,1,"forage")
 g.party_health.begin_condition(1,"broken_arm",0,1)
 g.party_health.begin_condition(2,"broken_arm",0,1)
 rest(g)
 check(g.party_health.members[1].conditions[0].elapsed==1 and g.party_health.members[2].conditions[0].elapsed==2,"Working and resting injuries advance their own recovery clocks")
 g=party()
 g.camp_tasks.assign(g,1,"dry");g.camp_tasks.assign(g,2,"salt_dry")
 g.state.food+=g.provisions.add_meat(100,0)
 rest(g)
 check(g.supply_history.filter(func(e):return e.event=="camp_drying").size()==1,"Multiple driers cannot process the same morning batch twice")
 g=party()
 g.camp_tasks.assign(g,1,"forage")
 g.state.camp_greens_lb=3;g.state.camp_greens_expires=1
 g.party_health.days_without_fresh=20
 rest(g)
 check(g.party_health.days_without_fresh==21,"Spoiled loose greens cannot cure vitamin deficiency")
 g=party()
 g.state.camp_greens_lb=3;g.state.camp_greens_expires=3
 var drop: Dictionary=load("res://simulation/discard_plan.gd").quote(g,{"camp_greens_lb":3})
 check(drop.valid and drop.dropped_lb==3 and g.discard_supplies({"camp_greens_lb":3}) and g.state.camp_greens_expires==0,"Loose greens can be dropped with an exact physical weight quote")
 check(store.restore(JSON.parse_string(JSON.stringify(store.capture(g))))!=null,"Discarding the last loose greens preserves save validity")
 g=party()
 g.camp_tasks.assign(g,1,"nurse",4);g.camp_tasks.assign(g,2,"nurse",4)
 g.camp_tasks.assign(g,3,"dry");g.camp_tasks.assign(g,4,"salt_dry")
 g.party_health.members[4].health=60;g.state.health=g.party_health.average_health()
 g.state.food+=g.provisions.add_meat(100,0)
 g.characters.profiles[2].specials=["Mercenary"]
 g.characters.start_contract(g,2,int(g.characters.wage_quote(g.characters.profiles[2]).daily_cents),1)
 baseline=store.capture(g)
 var costs: Dictionary=g.camp_tasks.quote(g)
 check(costs.days==1 and costs.meals==15 and costs.kits==1 and costs.meat_lb==70 and costs.salt==0,"Footer quote shares one day and counts reserved kits/meat once")
 check(costs.wages_cents==int(g.characters.profiles[2].contract.wage_cents) and not costs.notes.is_empty(),"Footer shows upcoming wage debt and explains blocked jobs")
 check(store.capture(g)==baseline and g.camp_tasks.day_plan.is_empty(),"Cost quote never changes real supplies, journal, day plan or RNG")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-camp-tasks-v3.json"))
 var legacy=store.restore(old)
 check(legacy!=null,"Genuine schema-3 save migrates")
 if legacy!=null:
  check(not legacy.camp_tasks.enabled() and legacy.state==store.normalize(old.state),"Migration preserves supplies and group-action behavior")
  check(str(legacy.rng.state)==old.random and str(legacy.party_health.rng.state)==old.health_random,"Migration does not consume randomness")
 g=party();g.camp_tasks.assign(g,1,"forage")
 saved=store.capture(g)
 for bad in [null,[],{"0":{"job":"forage","patient":-1}},{"1":{"job":"nurse","patient":1}},{"1":{"job":"forage","patient":2}},{"01":{"job":"rest","patient":-1}},{"1":{"job":"unknown","patient":-1}}]:
  var malformed: Dictionary=saved.duplicate(true);malformed.camp_tasks=bad
  check(store.restore(malformed)==null,"Malformed task record rejects")
 var malformed: Dictionary=saved.duplicate(true)
 malformed.state.camp_greens_lb=4;malformed.state.camp_greens_expires=4
 check(store.restore(malformed)==null,"Out-of-range loose greens reject")
 var screen=Main.instantiate();root.add_child(screen);await process_frame
 screen.departure_view.hide();screen.game=party();screen._refresh()
 baseline=store.capture(screen.game)
 screen._show_section("Companion tasks")
 check(screen.section_window.visible and screen.section_rows.find_child("CampTask1",true,false)!=null,"Camp task roster shows named companion controls")
 check(store.capture(screen.game)==baseline,"Opening roster has no simulation side effects")
 check(screen.section_rows.find_child("CampWorkCosts",true,false)!=null and not screen.section_rows.find_child("CampTask1",true,false).tooltip_text.is_empty(),"Roster keeps material costs in a footer and descriptions on hover")
 await process_frame
 var roster_row=screen.section_rows.find_child("CampCompanion1",true,false)
 check(roster_row!=null and roster_row.get_child(0).position.x<roster_row.get_child(1).position.x,"Roster pairs a companion name with their task in adjacent columns")
 screen._set_camp_task(1,"forage",-1);await process_frame
 check(screen.game.camp_tasks.job(1).job=="forage" and screen.game.state.day==0,"UI assigns work without spending a day")
 screen.section_window.hide()
 screen.game=party();screen.game.camp_tasks.assign(screen.game,1,"forage")
 screen.game.seen.append("muddy_trail")
 screen.last_food_alert=0
 screen.rest_days_input.text="3"
 screen._confirm_rest()
 check(screen.game.state.day==3 and screen.game.camp_tasks.job(1).job=="forage","Routine harvest reports do not interrupt a three-day assigned camp rest")
 check(screen.game.journal.filter(func(line):return "Foraged" in line or "Gathered" in line).size()==3,"Standing forage resolves on every selected day")
 screen.queue_free()
 print("Companion camp tasks: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
