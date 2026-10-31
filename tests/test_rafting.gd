extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Model=preload("res://simulation/rafting.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func game(seed_value: int=805101):
 var g=Sim.new(seed_value,"classic",true)
 check(g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,{"oxen":4,"food":500,"clothing":5,"bullet_boxes":2,"medicine":2}),"Rafting fixture departs")
 g.party_health.daily_onset_chance=0;g.survival.data.event_chance=0;g.survival.forced_weather="clear"
 g.route_path=g.route.main_path_to("the_dalles");g.route_path.append("columbia_raft")
 g.state.landmark="columbia_raft";g.state.next_landmark="columbia_raft";g.state.leg_miles=0;g.state.leg_length=0;g.state.miles=1818
 g._arrive_landmark(true,false)
 return g
func launch(g) -> bool:
 for index in range(g.pending.choices.size()):
  if g.pending.choices[index].get("rafting",false):return g.choose(index)
 return false
func steer(model,session: Dictionary) -> float:
 var nearest: Dictionary={}
 for obstacle in session.obstacles:
  if obstacle.z>session.progress-3 and (nearest.is_empty() or obstacle.z<nearest.z):nearest=obstacle
 if nearest.is_empty():return 0
 return -0.65 if float(nearest.x)>0 else 0.65
func run():
 var model=Model.new()
 check(model.error.is_empty(),"Prototype rules load")
 var a: Dictionary=model.begin(805001,150);var b: Dictionary=model.begin(805001,150)
 check(a==b,"Course is repeatable from seed and departure day")
 check(a.obstacles.size()==13,"Pattern course contains its declared thirteen hazards")
 check(int(model.data.duration_seconds)==25 and model.data.speed==18 and model.data.speed*model.data.duration_seconds==450,"Pacing retains the twenty-five-second 450-unit course")
 check(a.sections.size()==6 and a.sections[0].pattern=="intro" and a.sections[2].pattern=="breather" and a.sections[-1].pattern=="exit","Gentle entry, middle breather and clear exit frame mixed challenges")
 check(a.sections[1].pattern!=a.sections[3].pattern and a.sections[-1].end==25,"Both challenge patterns appear once before the finish")
 var scene=preload("res://ui/rafting_scene.gd").new()
 var orders: Dictionary={};var mirrors: Dictionary={}
 for seed_value in range(807000,807080):
  var course: Dictionary=model.begin(seed_value,150)
  check(not course.is_empty() and course.validation.valid,"Generator supplies a reachable route")
  orders[course.sections[1].pattern]=true
  mirrors[signf(float(course.obstacles[1].base_x)-0.015)]=true
  var visible_warning:=true;var log_moved:=false
  var moving_count:=0;var motion_rates: Dictionary={}
  for obstacle in course.obstacles:
   for time in [0.0,8.0,20.0]:
    var point: Vector2=scene.project(model.obstacle_x(obstacle,time),float(model.data.speed)*2)
    if point.x<10 or point.x>422 or point.y<10 or point.y>170:visible_warning=false
   if obstacle.kind=="log":
    moving_count+=1;motion_rates[float(obstacle.omega)]=true
    log_moved=absf(model.obstacle_x(obstacle,0)-model.obstacle_x(obstacle,2))>0.01
  check(visible_warning and log_moved,"Hazards offer two seconds of visible warning and logs drift laterally")
  check(moving_count==4 and motion_rates.size()==4,"Each course mixes four log speeds with stationary rocks")
  var path: Array=course.validation.path
  while not course.ended:
   var drift_step: float=sin(float(course.progress)/43.0)*float(model.data.drift)*Model.STEP
   model.tick(course,Model.STEP,float(path[int(course.ticks)+1])-drift_step)
  check(course.ended and not course.wrecked and course.hits==0,"Reduced-speed witness replays collision-free in actual physics")
 check(orders.size()==2 and mirrors.size()==2,"Seeds vary pattern order and mirror direction")
 scene.free()
 var wall: Array=[]
 for lane in range(17):wall.append({"id":lane,"x":-1.2+lane*0.15,"z":90.0,"kind":"rock","hit":false})
 check(not model.validate_course(wall).valid,"Reachability rejects a wall spanning every passage")
 var moving_collision: Dictionary=model.begin(805001,150)
 moving_collision.obstacles=[{"id":0,"x":0.5,"base_x":0.5,"amplitude":0.5,"omega":0.9,"phase":-PI/2,"z":0.3,"kind":"log","hit":false}]
 model.tick(moving_collision,Model.STEP,0)
 check(moving_collision.hits==1 and absf(float(moving_collision.obstacles[0].x))<0.01,"Log collision follows the moving visible position rather than its original lane")
 var changed_motion: Dictionary=model.begin(805001,150)
 changed_motion.obstacles=[{"id":0,"x":0.0,"base_x":0.0,"amplitude":0.6,"omega":1.25,"phase":0.0,"z":100,"kind":"log","hit":false}]
 for tick in range(60):model.tick(changed_motion,Model.STEP,0)
 check(is_equal_approx(float(changed_motion.obstacles[0].x),0.6*sin(1.25)),"Actual simulation updates lateral log position from elapsed time")
 var cluster: Dictionary=model.begin(805001,150)
 cluster.obstacles=[{"id":0,"x":0.0,"z":0.3,"kind":"rock","hit":false},{"id":1,"x":0.05,"z":0.3,"kind":"rock","hit":false},{"id":2,"x":0.0,"z":18.0,"kind":"rock","hit":false}]
 model.tick(cluster,Model.STEP,0)
 check(cluster.hits==1,"One overlapping cluster causes one impact instead of stacked damage")
 for tick in range(65):model.tick(cluster,Model.STEP,0)
 check(cluster.hits==2,"A later encounter can damage the raft after collision grace")

 for i in range(120):model.tick(a,1.0/60.0,0.25)
 for i in range(60):model.tick(b,1.0/30.0,0.25)
 check(a.ticks==b.ticks and is_equal_approx(a.x,b.x) and a.hits==b.hits and a.obstacles==b.obstacles,"Physics is invariant between 30 and 60 fps")
 var before: Dictionary=a.duplicate(true)
 model.tick(a,NAN,0);model.tick(a,1.0/60.0,NAN);model.tick(a,-1,0)
 check(a==before,"Invalid controls and elapsed time are ignored")
 var clean:=0;var wrecks:=0
 for seed_value in range(805200,805240):
  a=model.begin(seed_value,150)
  for tick in range(1800):
   if a.ended:break
   model.tick(a,1.0/60.0,steer(model,a))
  if a.hits==0:clean+=1
  check(a.ended and not a.wrecked,"A readable avoidance policy can complete the course")
  b=model.begin(seed_value,150)
  for tick in range(1800):
   if b.ended:break
   model.tick(b,1.0/60.0,3.0)
  if b.wrecked:wrecks+=1
  check(b.ended and b.hits>=5,"Bank strikes punish a failed steering line")
 check(clean>0 and wrecks==40,"Clean finishes and failed runs are both possible")
 var delayed_finishes:=0
 for seed_value in range(805300,805340):
  a=model.begin(seed_value,150)
  var commands: Array=[]
  commands.resize(60);commands.fill(0.0)
  for tick in range(1800):
   if a.ended:break
   commands.append(steer(model,a))
   model.tick(a,1.0/60.0,float(commands.pop_front()))
  if a.ended and not a.wrecked:delayed_finishes+=1
 check(delayed_finishes==40,"Wider passages allow completion even with a one-second steering delay")
 var bank_huggers_hit:=0
 for seed_value in range(806000,806040):
  for side in [-1,1]:
   a=model.begin(seed_value,150)
   var edge: float=float(model.data.shore_left)+float(model.data.raft_half_width)+0.02 if side<0 else float(model.data.shore_right)-float(model.data.raft_half_width)-0.02
   for tick in range(1800):
    if a.ended:break
    model.tick(a,1.0/60.0,edge)
   var obstacle_hits: int=a.impacts.filter(func(hit):return hit.kind!="bank").size()
   if obstacle_hits>=2:bank_huggers_hit+=1
 check(bank_huggers_hit==80,"Hugging either shore meets actual obstacles rather than bypassing the course")
 var constant_routes_hit:=0
 for seed_value in range(806100,806108):
  for lane in range(13):
   a=model.begin(seed_value,150)
   var edge_left: float=float(model.data.shore_left)+float(model.data.raft_half_width)+0.02
   var edge_right: float=float(model.data.shore_right)-float(model.data.raft_half_width)-0.02
   var target: float=lerpf(edge_left,edge_right,lane/12.0)
   for tick in range(1800):
    if a.ended:break
    model.tick(a,1.0/60.0,target)
   if a.impacts.any(func(hit):return hit.kind!="bank"):constant_routes_hit+=1
 check(constant_routes_hit==104,"No sampled fixed lateral lane is an obstacle-free shortcut")


 a=model.begin(805001,150);a.obstacles=[{"id":0,"x":0.0,"z":0.3,"kind":"rock","hit":false}]
 model.tick(a,1.0/60.0,0)
 check(a.hits==1,"Overlapping collision is detected")
 for tick in range(5):model.tick(a,1.0/60.0,0)
 check(a.hits==1,"Same obstacle cannot deal damage every frame")
 a=model.begin(805500,150);a.obstacles=[]
 for tick in range(150):model.tick(a,1.0/60.0,1.05)
 check(a.hits==0,"Clear water beyond the removed guide line has no invisible collision boundary")
 for tick in range(180):model.tick(a,1.0/60.0,3.0)
 check(a.hits>0 and float(a.x)+float(model.data.raft_half_width)<=float(model.data.shore_right)+0.000001,"The visible shore stops the hull rather than letting it pass onto land")
 var g=game();var save=Save.new()
 var saved: Dictionary=save.capture(g)
 check(save.restore(JSON.parse_string(JSON.stringify(saved)))!=null,"Pre-launch choice saves normally")
 var day: int=g.state.day;var food: int=g.state.food;var core_rng: int=g.rng.state
 check(launch(g) and not g.raft.is_empty(),"Choosing rapids launches the actual activity")
 check(g.state.day==day and g.state.food==food and g.rng.state==core_rng,"Launch charges no day or supply and does not consume shared RNG")
 check(save.capture(g).is_empty() and not g.travel() and not g.rest() and not g.start_hunt() and not g.can_service(),"Active raft blocks saves and conflicting activities")
 check(not g.finish_rafting(),"Cannot settle an unfinished activity")
 for tick in range(1800):
  if g.raft.ended:break
  g.advance_rafting(1.0/60.0,steer(g.rafting,g.raft))
 check(g.finish_rafting(),"A completed activity settles")
 check(g.state.day==day+1 and g.state.next_landmark=="oregon_city" and g.rafting_history.size()==1,"Settlement charges one real day and opens the onward river leg")
 check(g.raft.is_empty() and not g.finish_rafting(),"Settlement cannot run twice")
 check(save.restore(JSON.parse_string(JSON.stringify(save.capture(g))))!=null,"Completed run and outcome history save")
 var old_pace: Dictionary=save.capture(g)
 old_pace.rules="b0ed795976c90830b575709ad6913719c4059b07e94438bd5c07f6d2746e1753"
 old_pace.rafting_history[0].elapsed_ticks=1800
 var old_pace_copy=save.restore(old_pace)
 check(old_pace_copy!=null and old_pace_copy.rafting_history[0].elapsed_ticks==1800,"Completed thirty-second runs remain loadable after the pace increase")

 check(g.supply_history.any(func(row):return row.event=="columbia_rapids"),"Real outcome enters supply history")
 # Controlled model input guarantees specific consequence branches; no UI supplies outcomes.
 g=game(805102);check(launch(g),"Second run launches")
 g.raft.ended=true;g.raft.wrecked=true;g.raft.hits=5;g.raft.integrity=0;g.raft.drowning_roll=0.0
 day=g.state.day
 check(g.finish_rafting() and g.state.day==day+1,"Wreck settles one day")
 check(g.last_rafting.food_lost==60 and g.last_rafting.clothing_lost==1,"Wreck records collision losses separately from meals")
 check(g.last_rafting.drowned>=0 and not g.party_health.members[int(g.last_rafting.drowned)].alive,"Drowning affects an actual traveler")
 check(g.party_health.members[int(g.last_rafting.drowned)].cause=="drowning in the Cascades","Drowning cause persists in individual history")
 var restored=save.restore(JSON.parse_string(JSON.stringify(save.capture(g))))
 check(restored!=null and restored.rafting_history==save.normalize(g.rafting_history),"Fatal outcome survives JSON save/load")
 g=game(805104)
 for person in g.party_health.members:person.health=10
 g.state.health=10;launch(g)
 g.raft.ended=true;g.raft.wrecked=true;g.raft.hits=5;g.raft.integrity=0;g.raft.drowning_roll=1.0
 check(g.finish_rafting() and g.last_rafting.deaths.size()==5 and g.state.status=="lost","Wreck records every weak traveler killed by the rapids")
 check(save.restore(JSON.parse_string(JSON.stringify(save.capture(g))))!=null,"Multiple-casualty lost journey remains saveable")
 g=game(805103);check(launch(g),"Injury run launches")
 g.raft.ended=true;g.raft.hits=2;g.raft.integrity=60
 check(g.finish_rafting() and g.last_rafting.injured>=0,"A serious impact causes an individual injury")
 var member: Dictionary=g.party_health.members[int(g.last_rafting.injured)]
 check(member.conditions.any(func(c):return c.id=="wound"),"Rafting wound participates in existing health system")
 check(g.last_rafting.food_lost==24,"Partial damage has bounded cargo loss")
 var bad: Dictionary=save.capture(g);bad.rafting_history[0].food_lost=1000000
 check(save.restore(bad)==null,"Malformed saved outcome rejected")
 for key in ["place","wrecked","hits","injured"]:
  var malformed: Dictionary=save.capture(g);malformed.rafting_history[0][key]="invalid" if key!="place" else 42
  check(save.restore(malformed)==null,"Wrong saved outcome type rejected: "+key)

 g=game();day=g.state.day
 check(g.choose(0) and g.raft.is_empty() and g.state.day==day+2,"Cautious portage remains a non-minigame two-day choice")
 g=game();var old: Dictionary=save.capture(g)
 old.rules="630ab7bf58c07580b290ff8846ec5c923991665e21b9ddb55c5edc87791b108b"
 old.erase("rafting_history")
 for choice in old.pending.choices:
  if choice.has("rafting"):choice.erase("rafting");choice["portage_risk"]=0.3
 restored=save.restore(old)
 check(restored!=null and restored.pending.choices.any(func(c):return c.get("rafting",false)),"Old saved Cascades menu upgrades to steering")
 check(restored!=null and restored.state.food==old.state.food and restored.state.day==old.state.day and restored.rafting_history.is_empty(),"Pre-rafting save retains supplies and time with no invented outcome")
 for key in ["duration_seconds","damage_per_hit","speed","raft_half_width","drowning_chance_on_wreck","route_speed_fraction","reaction_seconds","route_clearance","collision_grace_seconds"]:
  var invalid: Dictionary=model.data.duplicate(true);invalid[key]=-1
  check(not Model.new().load_data(invalid),"Malformed prototype rule rejected: "+key)
 for corruption in ["time","kind","width","count","sequence"]:
  var invalid: Dictionary=model.data.duplicate(true)
  match corruption:
   "time":invalid.patterns.intro.objects[0].at=9
   "kind":invalid.patterns.intro.objects[0].kind="unknown"
   "width":invalid.patterns.shore.objects[-1].amplitude=2
   "count":invalid.obstacles=12
   "sequence":invalid.sequence.reverse()
  check(not Model.new().load_data(invalid),"Malformed pattern rejected: "+corruption)
 var previous_patterns: Dictionary=saved.duplicate(true)
 previous_patterns.rules="320468b382a942fb8f23b0bc39b693e1408875100ec9763c8e6984c1791c71df"
 var previous_patterns_copy=save.restore(previous_patterns)
 check(previous_patterns_copy!=null and previous_patterns_copy.state.food==saved.state.food and previous_patterns_copy.state.day==saved.state.day,"One-log course saves retain supplies and time after moving-log expansion")
 var old_course: Dictionary=saved.duplicate(true)
 old_course.rules="46e1e3e5cecf05614c84f834290ca84ad07de779fa0d43339b60a10980335437"
 var migrated=save.restore(old_course)
 check(migrated!=null and migrated.state.food==saved.state.food and migrated.state.day==saved.state.day,"Previous uniform-course save keeps supplies and date")
 var failed_launch=game()
 failed_launch.rafting.error="Invalid rafting rules."
 var pending_before: Dictionary=failed_launch.pending.duplicate(true)
 check(not launch(failed_launch) and failed_launch.pending==pending_before and failed_launch.raft.is_empty(),"Failed generation preserves the uncharged portage choice")
 var panel=preload("res://ui/rafting_view.gd").new();root.add_child(panel);await process_frame
 check(not panel.visible,"Rafting window stays hidden until the activity opens")
 g=game();launch(g);panel.open(g)
 check(panel.scene.CROSS_AXIS.x*1.84>190,"Visible safe channel is wider relative to the same raft")
 check(panel.scene.DECK_CENTER_OFFSET+Vector2(22,-12)==Vector2.ZERO,"Visible deck center is aligned with the collision point")
 var bank_image: Image=panel.scene.BANK.get_image()
 for bank in [float(model.data.shore_left),float(model.data.shore_right)]:
  var direction: float=-1.0 if bank<0 else 1.0
  for offset in [-0.03,0.03]:
   var screen_point: Vector2=panel.scene.project(bank+offset*direction,0)
   var native_point:=Vector2i(roundi((panel.scene.BANK_ORIGIN.x-screen_point.x)/panel.scene.BANK_SCALE),roundi((screen_point.y-panel.scene.BANK_ORIGIN.y)/panel.scene.BANK_SCALE))
   var land: bool=bank_image.get_pixelv(native_point).a>0
   check(land==(offset>0),"Collision shore follows actual visible coast pixels, with water inside and land outside")

 check(absf(panel.scene.steering_at(panel.scene.project(0.5,80))-0.5)<0.02,"Mouse steering follows cross-channel position at any downstream distance")
 check(absf(panel.scene.steering_at(panel.scene.project(-0.5,10))+0.5)<0.02,"Inverse projection preserves the opposite steering direction")
 check(panel.visible and panel.paused and panel.finish_button.disabled,"Window starts paused with clear launch control")
 var elapsed: int=g.raft.ticks
 panel._process(1.0);check(g.raft.ticks==elapsed,"Paused window advances no simulation")
 panel.toggle_pause();panel._process(1.0/60.0)
 check(g.raft.ticks>elapsed,"Start button runs the steering model")
 panel.close_requested.emit();check(panel.visible and panel.paused,"Close pauses instead of discarding the run")
 panel.reset();panel.queue_free()
 print("Cascades rafting: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
