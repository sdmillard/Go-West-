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
 var g=Sim.new(5702,"classic",true)
 g.depart("banker",["Leader","Anne","Ben","Cara","Dan"],5,{"oxen":4,"horses":1,"food":600,"clothing":5,"medicine":4,"salt":10,"bullet_boxes":5})
 g.pending={}
 g.state.next_landmark="elm_grove";g.state.leg_length=20;g.state.leg_miles=1;g.state.miles=1
 g.seen.append("muddy_trail")
 g.party_health.daily_onset_chance=0
 g.survival.forced_weather="clear";g.survival.data.event_chance=0
 for p in g.characters.profiles:
  if int(p.id)>0:p.boundaries.forbidden=[];p.trust=50;p.skill="Trading";p.specials=[]
 return g
func rest(g):
 g.pending={}
 return g.rest()
func breakdown(g):
 for e in g.trail_events.events:
  if e.id=="breakdown":g._present_trail_event(e);break
 for i in range(g.pending.choices.size()):
  if g.pending.choices[i].has("camp_repair_part"):return g.choose(i)
 return false
func run():
 var store=Store.new()
 var g=party()
 check(breakdown(g) and g.camp_repair.blocked(g) and g.state.day==0,"Actual breakdown can defer to a crew without spending a day")
 var before: Dictionary=store.capture(g)
 check(not g.travel() and store.capture(g)==before,"Broken wagon cannot move or spend a phantom day")
 check(g.camp_tasks.assign(g,1,"repair_patch"),"Ordinary companion may patch")
 var kits: int=g.state.medicine
 rest(g)
 check(g.camp_repair.work.progress==1 and g.state.medicine==kits-1 and g.state.day==1,"First patch day reserves one kit and advances one work unit")
 check(g.party_health.members[1].health<=86 and g.party_health.members[2].health>86,"Repairer works while unassigned people rest")
 var saved: Dictionary=store.capture(g)
 var loaded=store.restore(JSON.parse_string(JSON.stringify(saved)))
 check(loaded!=null and loaded.camp_repair.work==g.camp_repair.work,"Partial paid repair round-trips")
 if loaded!=null:
  loaded.party_health.daily_onset_chance=0;loaded.survival.forced_weather="clear";loaded.survival.data.event_chance=0
  rest(g);rest(loaded)
  check(store.capture(g)==store.capture(loaded),"Remaining repair and random streams match after loading")
 check(not g.camp_repair.blocked(g) and g.state.medicine==kits-1,"Second patch day completes without a second kit")
 g.pending={}
 check(g.travel(),"Travel resumes after completion")
 g=party();breakdown(g)
 g.characters.profiles[1].skill="Carpentry"
 g.camp_tasks.assign(g,1,"repair_patch");rest(g)
 check(g.camp_repair.work.is_empty() and g.state.day==1,"Assigned Carpenter patches in one day")
 g=party();breakdown(g)
 g.camp_tasks.assign(g,1,"repair_wood")
 rest(g)
 check(g.camp_repair.work.progress==0,"Untrained companion cannot fabricate a wooden replacement")
 g.characters.profiles[1].skill="Carpentry"
 rest(g)
 check(g.camp_repair.work.progress==2 and g.camp_repair.work.method=="wood","Carpenter starts a wooden repair")
 g.camp_tasks.assign(g,1,"forage");rest(g)
 check(g.camp_repair.work.progress==2,"Interrupted work retains exact progress")
 g.camp_tasks.assign(g,1,"repair_wood");rest(g)
 check(not g.camp_repair.blocked(g) and g.state.medicine==4,"Wooden repair finishes on second working day without kits")
 g=party();breakdown(g)
 g.camp_tasks.assign(g,1,"repair_patch");g.camp_tasks.assign(g,2,"repair_patch")
 rest(g)
 check(g.camp_repair.work.progress==1 and g.state.medicine==3,"Two repairers cannot spend two kits or double-process a part")
 g=party();breakdown(g)
 g.camp_tasks.assign(g,1,"nurse",4);g.camp_tasks.assign(g,2,"repair_patch")
 g.state.medicine=1
 rest(g)
 check(g.state.medicine==0 and g.camp_repair.work.progress==0,"Nurse and repairer cannot spend the same final kit")
 g=party();breakdown(g)
 for i in range(3):
  g.pending={}
  check(g.camp_repair.leader_work(g,"wood"),"Leader retains an ordinary self-repair fallback")
 check(g.state.day==3 and g.camp_repair.work.is_empty(),"Leader's wooden fallback costs three days")
 g=party();breakdown(g)
 g.camp_tasks.assign(g,1,"repair_patch");rest(g)
 g.pending={}
 var part: String=g.camp_repair.work.part
 g.state[part]=1;g.state.parts=g.state.wheels+g.state.axles+g.state.tongues
 var day: int=g.state.day
 check(g.camp_repair.fit_spare(g) and g.state.day==day and g.state[part]==0 and g.camp_repair.work.is_empty(),"A real spare completes the deferred repair instantly and consumes the part")
 g=party();breakdown(g)
 g.camp_tasks.assign(g,1,"repair_patch");rest(g);g.pending={}
 check(g.abandon_wagon({"food":20,"clothing":5}),"Broken wagon may be abandoned")
 check(g.camp_repair.work.is_empty() and g.wagon_cache.camp_repair.progress==1,"Repair progress stays with the cached wagon")
 saved=store.capture(g);loaded=store.restore(JSON.parse_string(JSON.stringify(saved)))
 check(loaded!=null,"Cache containing a broken part loads")
 g.pending={}
 check(g.inspect_cached_wagon() and g.state.vehicle=="wagon" and g.camp_repair.work.progress==1,"Recovering a wagon does not magically repair it")
 g=party()
 g.state.fatigue=50
 g.state.night_guard=true
 g.camp_tasks.assign(g,1,"guard");g.camp_tasks.assign(g,2,"guard")
 rest(g)
 check(g.camp_tasks.stock_guarded(g) and g.state.camp_watch_member==1,"Exactly one eligible named guard covers the camp night")
 check(g.party_health.members[1].health<=86 and g.party_health.members[2].health>86,"Guard works; duplicate guard rests")
 check(g.state.fatigue==36,"Named guard does not also charge anonymous party-watch fatigue")
 saved=store.capture(g);loaded=store.restore(JSON.parse_string(JSON.stringify(saved)))
 check(loaded!=null and loaded.camp_tasks.stock_guarded(loaded),"Completed watch survives saves without an extra roll")
 var matches:=true
 for seed_value in range(30):
  var named=store.restore(JSON.parse_string(JSON.stringify(saved)))
  var legacy=store.restore(JSON.parse_string(JSON.stringify(saved)))
  named.pending={};legacy.pending={}
  legacy.camp_tasks.assignments={}
  named.survival.rng.seed=seed_value;legacy.survival.rng.seed=seed_value
  named._roll_trail_event();legacy._roll_trail_event()
  matches=matches and named.pending.get("id","")==legacy.pending.get("id","")
 check(matches,"Assigned watch and existing anonymous watch use exactly the same theft weighting, even when both flags exist")
 g.pending={}
 var fatigue_before: int=g.state.fatigue
 g.travel()
 check(g.state.fatigue==fatigue_before+2+int(g.state.pace)*2+int(g.provisions.data.mounts.guard_fatigue),"Travel watch pays the existing sleep cost exactly once")
 check(g.camp_tasks.stock_guarded(g),"Named guard still watches the stock on travel nights, without running other camp chores")
 g=party();g.camp_tasks.assign(g,1,"guard");g.characters.profiles[1].trust=0;rest(g)
 check(not g.camp_tasks.stock_guarded(g),"Refusing guard gives no protection")
 g=party();g.camp_tasks.assign(g,1,"guard");g.party_health.members[1].health=20;g.state.health=g.party_health.average_health();rest(g)
 check(not g.camp_tasks.stock_guarded(g),"Incapacitated guard gives no protection")
 g=party();g.camp_tasks.assign(g,1,"guard");g.camp_tasks.assign(g,2,"nurse",1);rest(g)
 check(not g.camp_tasks.stock_guarded(g),"A guard receiving nursing cannot also keep watch")
 g=party();breakdown(g);g.camp_tasks.assign(g,1,"repair_patch")
 g.characters.profiles[1].trust=0;rest(g)
 check(g.camp_repair.work.progress==0 and g.state.medicine==4,"Refusing repairer consumes neither a kit nor progress")
 g.characters.profiles[1].trust=50
 g.party_health.members[1].health=20;g.state.health=g.party_health.average_health();rest(g)
 check(g.camp_repair.work.progress==0,"Too-ill repairer cannot produce progress")
 g=party();breakdown(g);g.camp_tasks.assign(g,1,"repair_patch");g.camp_tasks.assign(g,2,"nurse",1);rest(g)
 check(g.camp_repair.work.progress==0,"A repairer receiving nursing is locked out of repairs")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-repair-guard-v4.json"))
 loaded=store.restore(old)
 check(loaded!=null and loaded.camp_repair.work.is_empty() and loaded.camp_tasks.snapshot()==store.normalize(old.camp_tasks),"Genuine prior schema-4 tasks migrate without invented repairs")
 if loaded!=null:check(loaded.state==store.normalize(old.state) and str(loaded.rng.state)==old.random,"Migration preserves actual supplies and RNG")
 g=party();breakdown(g);saved=store.capture(g)
 for bad in [{"part":"horses","method":"","progress":0,"kit_spent":false},{"part":"wheels","method":"patch","progress":1,"kit_spent":false},{"part":"wheels","method":"wood","progress":3,"kit_spent":false}]:
  var invalid: Dictionary=saved.duplicate(true);invalid.camp_repair=bad
  check(store.restore(invalid)==null,"Malformed or impossible repair project rejects")
 var screen=Main.instantiate();root.add_child(screen);await process_frame
 screen.departure_view.hide();screen.game=g;screen._refresh();screen._show_section("Companion tasks")
 var menu=screen.section_rows.find_child("CampTask1",true,false).get_popup()
 check(menu.has_node("RepairOptions"),"Roster offers cascading repair methods")
 screen._set_camp_task(1,"repair_patch",-1);await process_frame
 check(screen.game.camp_tasks.job(1).job=="repair_patch" and screen.travel_button.disabled,"UI assigns repair work and blocks the broken wagon's Continue button")
 screen.queue_free()
 print("Camp repair and guard: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
