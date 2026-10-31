extends RefCounted
## Fixed-step steering model. No nodes, wall clock, or shared RNG.
const STEP: float=1.0/60.0
var data: Dictionary={}
var error: String=""
func _init() -> void:
 load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/rafting.json")))
static func number(v: Variant) -> bool:
 return (v is int or v is float) and is_finite(float(v))
func load_data(v: Variant) -> bool:
 error="Invalid rafting rules."
 if not v is Dictionary or not v.get("note") is String:return false
 for key in ["course_version","duration_seconds","obstacles","damage_per_hit","food_per_hit","max_food_loss","injury_hits","clothing_hits","wreck_health_loss"]:
  if not number(v.get(key)) or v[key]!=floor(v[key]) or v[key]<1 or v[key]>600:return false
 if v.course_version!=4:return false
 for key in ["speed","steer_speed","drift","raft_half_width"]:
  if not number(v.get(key)) or v[key]<=0 or v[key]>30:return false
 for key in ["shore_left","shore_right"]:
  if not number(v.get(key)) or absf(float(v[key]))>3:return false
 if v.shore_left>=0 or v.shore_right<=0 or v.raft_half_width>0.5 or v.shore_right-v.shore_left<=2*v.raft_half_width:return false
 if not number(v.get("drowning_chance_on_wreck")) or v.drowning_chance_on_wreck<0 or v.drowning_chance_on_wreck>1:return false
 for key in ["collision_grace_seconds","route_speed_fraction","route_clearance","reaction_seconds"]:
  if not number(v.get(key)) or v[key]<=0 or v[key]>1:return false
 if not v.get("patterns") is Dictionary or not v.get("sequence") is Array or not v.get("challenge_pool") is Array:return false
 if v.sequence!=["intro","challenge","breather","challenge","shore","exit"] or v.challenge_pool!=["slalom","split"]:return false
 var duration: float=0;var count: int=0
 for name in ["intro","slalom","split","breather","shore","exit"]:
  var pattern: Variant=v.patterns.get(name)
  if not pattern is Dictionary or not number(pattern.get("duration")) or pattern.duration<=0 or pattern.duration>30 or not pattern.get("objects") is Array or pattern.objects.size()>20:return false
  duration+=float(pattern.duration);count+=pattern.objects.size()
  for obj in pattern.objects:
   if not obj is Dictionary or not number(obj.get("at")) or obj.at<=0 or obj.at>=pattern.duration-0.05:return false
   if not number(obj.get("x")) or obj.get("kind") not in ["rock","log"]:return false
   var amplitude: Variant=obj.get("amplitude",0.0)
   if not number(amplitude) or amplitude<0 or absf(float(obj.x))+amplitude>0.99:return false
   if amplitude>0 and (obj.kind!="log" or not number(obj.get("omega")) or obj.omega<0.1 or obj.omega>2):return false
 if duration!=v.duration_seconds or count!=v.obstacles or not v.patterns.breather.objects.is_empty() or not v.patterns.exit.objects.is_empty():return false
 data=v.duplicate(true);error="";return true
func begin(seed_value: int,day: int) -> Dictionary:
 var rng:=RandomNumberGenerator.new();rng.seed=seed_value+day*4903+2405831
 if not error.is_empty():return {}
 var obstacles: Array=[];var sections: Array=[];var proof: Dictionary={}
 var left: float=float(data.shore_left)+float(data.raft_half_width)
 var right: float=float(data.shore_right)-float(data.raft_half_width)
 var center: float=(left+right)/2;var half: float=(right-left)/2
 for attempt in range(8):
  obstacles=[];sections=[]
  var pool: Array=data.challenge_pool.duplicate()
  if rng.randf()<0.5:pool.reverse()
  var start: float=0
  for slot in data.sequence:
   var name: String=str(pool.pop_front()) if slot=="challenge" else str(slot)
   var pattern: Dictionary=data.patterns[name]
   var mirror: float=-1.0 if rng.randf()<0.5 else 1.0
   sections.append({"pattern":name,"start":start,"end":start+float(pattern.duration)})
   for obj in pattern.objects:
    var base: float=center+float(obj.x)*half*mirror
    var obstacle: Dictionary={"id":obstacles.size(),"x":base,"base_x":base,"z":(start+float(obj.at))*float(data.speed),"kind":obj.kind,"hit":false,"amplitude":float(obj.get("amplitude",0))*half,"omega":float(obj.get("omega",0)),"phase":rng.randf()*TAU,"pattern":name}
    obstacle.x=obstacle_x(obstacle,0);obstacles.append(obstacle)
   start+=float(pattern.duration)
  proof=validate_course(obstacles)
  if proof.valid:break
 if not proof.get("valid",false):return {}
 return {"ticks":0,"accumulator":0.0,"elapsed":0.0,"progress":0.0,"x":0.0,"integrity":100,"hits":0,"ended":false,"wrecked":false,"obstacles":obstacles,"sections":sections,"validation":proof,"impacts":[],"impact_until":0,"bank_cooldown":0,"drowning_roll":rng.randf(),"victim_roll":rng.randi(),"message":"Move the mouse left or right to steer. Avoid rocks, drifting logs and the shore."}
static func obstacle_x(obstacle: Dictionary,time: float) -> float:
 return float(obstacle.get("base_x",obstacle.x))+float(obstacle.get("amplitude",0))*sin(float(obstacle.get("phase",0))+float(obstacle.get("omega",0))*time)
static func collision_reach(obstacle: Dictionary) -> float:
 return 0.28 if obstacle.kind=="log" else 0.23
func validate_course(obstacles: Array) -> Dictionary:
 # Propagate all reachable lateral intervals, then backtrack a witness. Deliberately
 # reserve reaction time, steering headroom and clearance beyond actual hitboxes.
 var layers: Array=[[[0.0,0.0]]]
 var left: float=float(data.shore_left)+float(data.raft_half_width)+float(data.route_clearance)
 var right: float=float(data.shore_right)-float(data.raft_half_width)-float(data.route_clearance)
 for tick_index in range(1,int(data.duration_seconds)*60+1):
  var time: float=tick_index*STEP
  var drift_step: float=sin((tick_index-1)*STEP*float(data.speed)/43.0)*float(data.drift)*STEP
  var budget: float=float(data.steer_speed)*float(data.route_speed_fraction)*STEP if time>float(data.reaction_seconds) else 0.0
  var ranges: Array=[]
  for interval in layers[-1]:
   var lo: float=maxf(left,float(interval[0])+drift_step-budget)
   var hi: float=minf(right,float(interval[1])+drift_step+budget)
   if lo>hi:continue
   if not ranges.is_empty() and lo<=ranges[-1][1]:ranges[-1][1]=maxf(hi,ranges[-1][1])
   else:ranges.append([lo,hi])
  for obstacle in obstacles:
   if absf(float(obstacle.z)-time*float(data.speed))>=3.5:continue
   var x: float=obstacle_x(obstacle,time)
   var reach: float=collision_reach(obstacle)+float(data.route_clearance)
   var remaining: Array=[]
   for interval in ranges:
    if x+reach<interval[0] or x-reach>interval[1]:remaining.append(interval);continue
    if interval[0]<x-reach:remaining.append([interval[0],x-reach])
    if interval[1]>x+reach:remaining.append([x+reach,interval[1]])
   ranges=remaining
  if ranges.is_empty():return {"valid":false,"blocked_tick":tick_index}
  layers.append(ranges)
 var path: Array=[];path.resize(layers.size())
 path[-1]=clampf(0.0,layers[-1][0][0],layers[-1][0][1])
 for tick_index in range(layers.size()-1,0,-1):
  var drift_step: float=sin((tick_index-1)*STEP*float(data.speed)/43.0)*float(data.drift)*STEP
  var budget: float=float(data.steer_speed)*float(data.route_speed_fraction)*STEP if tick_index*STEP>float(data.reaction_seconds) else 0.0
  var wanted: float=float(path[tick_index])-drift_step
  var found: bool=false
  for interval in layers[tick_index-1]:
   var lo: float=maxf(interval[0],wanted-budget-0.000000001)
   var hi: float=minf(interval[1],wanted+budget+0.000000001)
   if lo<=hi:path[tick_index-1]=clampf(wanted,lo,hi);found=true;break
  if not found:return {"valid":false,"blocked_tick":tick_index}
 return {"valid":true,"path":path}
func impact(session: Dictionary,kind: String,id: int=-1) -> void:
 session.impact_until=int(session.ticks)+ceili(float(data.collision_grace_seconds)/STEP)
 session.hits+=1;session.integrity=maxi(0,int(session.integrity)-int(data.damage_per_hit))
 session.impacts.append({"tick":int(session.ticks),"kind":kind,"id":id})
 session.message="STRUCK %s · hull %d%%" % [kind.to_upper(),session.integrity]
 if session.integrity<=0:
  session.ended=true;session.wrecked=true;session.message="THE RAFT BREAKS APART · Review the losses before continuing."
func tick(session: Dictionary,delta: float,target: float) -> void:
 if session.is_empty() or session.ended or not is_finite(delta) or delta<=0 or not is_finite(target):return
 session.accumulator+=minf(delta,0.25)
 var ticks_total: int=int(data.duration_seconds)*60
 while session.accumulator+0.000000001>=STEP and not session.ended:
  session.accumulator=maxf(0,float(session.accumulator)-STEP)
  session.ticks+=1;session.elapsed=float(session.ticks)*STEP
  var drift: float=sin(float(session.progress)/43.0)*float(data.drift)
  session.x=move_toward(float(session.x),clampf(target,float(data.shore_left)-0.2,float(data.shore_right)+0.2),float(data.steer_speed)*STEP)+drift*STEP
  session.progress=float(session.elapsed)*float(data.speed)
  if session.bank_cooldown>0:session.bank_cooldown-=1
  var left: float=float(data.shore_left)+float(data.raft_half_width)
  var right: float=float(data.shore_right)-float(data.raft_half_width)
  if (float(session.x)<left or float(session.x)>right) and session.bank_cooldown==0:
   if int(session.ticks)>=int(session.get("impact_until",0)):impact(session,"bank")
   session.bank_cooldown=90
  session.x=clampf(float(session.x),left,right)
  for obstacle in session.obstacles:
   if session.ended:break
   obstacle.x=obstacle_x(obstacle,float(session.elapsed))
   var reach: float=collision_reach(obstacle)
   if not obstacle.hit and absf(float(obstacle.z)-float(session.progress))<3.0 and absf(float(obstacle.x)-float(session.x))<reach:
    obstacle.hit=true
    if int(session.ticks)>=int(session.get("impact_until",0)):impact(session,str(obstacle.kind),int(obstacle.id))
  if int(session.ticks)>=ticks_total and not session.ended:
   session.ended=true;session.message="CLEAR OF THE RAPIDS · Review the crossing before continuing."
func losses(session: Dictionary) -> Dictionary:
 var hits: int=session.hits
 return {"hits":hits,"wrecked":bool(session.wrecked),"food":mini(int(data.max_food_loss),hits*int(data.food_per_hit)),"clothing":1 if hits>=int(data.clothing_hits) else 0,"injury":hits>=int(data.injury_hits),"drowning":bool(session.wrecked) and float(session.drowning_roll)<float(data.drowning_chance_on_wreck)}
func valid_history(v: Variant,day: int,party_count: int) -> bool:
 if not v is Array or v.size()>32:return false
 for row in v:
  if not row is Dictionary or row.size()!=11 or not row.get("place") is String or row.place!="columbia_raft" or not row.get("wrecked") is bool:return false
  for key in ["day","hits","food_lost","clothing_lost","elapsed_ticks","integrity"]:
   if not number(row.get(key)) or row[key]!=floor(row[key]) or row[key]<0:return false
  # Completed runs from the earlier thirty-second course keep their earned history.
  if row.hits>64 or row.day>day or row.food_lost>int(data.max_food_loss) or row.clothing_lost>1 or row.elapsed_ticks>maxi(30,int(data.duration_seconds))*60 or row.integrity>100:return false
  if not row.get("deaths") is Array or row.deaths.size()>party_count:return false
  var ids: Array=[]
  for id in row.deaths:
   if not number(id) or id!=floor(id) or id<0 or id>=party_count or id in ids:return false
   ids.append(id)
  for key in ["injured","drowned"]:
   if not row.get(key) is int and not row.get(key) is float:return false
   if row[key]!=floor(row[key]) or row[key]<-1 or row[key]>=party_count:return false
 return true
