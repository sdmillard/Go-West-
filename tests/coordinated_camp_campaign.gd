extends "res://tests/hunting_balance_campaign.gd"
const CampObserved=preload("res://tests/camp_balance_observer.gd")
var camp_policy: String="off"
func make_study_game(seed_value: int):return CampObserved.new(seed_value,"classic",true)
func extra_settings() -> Dictionary:return {"camp_work_policy":camp_policy,"camp_policy_version":1}
func extra_row(game,_count: Dictionary) -> Dictionary:return {"camp_work":game.camp_tasks.audit.duplicate(true),"camp_forage":game.forage_audit.duplicate(true)}
func severity(person: Dictionary) -> int:
 var worst:=0
 for condition in person.conditions:worst=maxi(worst,int(condition.severity))
 return worst
func workers(game) -> Array:
 var leader: int=game.camp_tasks.leader_id(game)
 return game.party_health.members.filter(func(m):return int(m.id)!=leader and game.party_health.is_active(m)).map(func(m):return int(m.id))
func choose_worker(game,free: Array,job: String,patient: int=-1) -> int:
 var chosen: int=-1;var score: float=-1
 for id in free:
  if id==patient or not game.camp_tasks.reason(game,int(id),job,patient).is_empty():continue
  var value: float=float(game.party_health.members[id].health)
  if job=="nurse" and game.camp_tasks.specialist(game,id,"Caregiving"):value+=100
  if job=="hunt_help" and game.camp_tasks.specialist(game,id,"Hunting"):value+=20
  if value>score:score=value;chosen=int(id)
 return chosen
func give(game,free: Array,job: String,patient: int=-1) -> int:
 var id: int=choose_worker(game,free,job,patient)
 if id>=0 and game.camp_tasks.assign(game,id,job,patient):free.erase(id);return id
 return -1
func plan_jobs(game) -> Dictionary:
 var info: Dictionary={"patient":-1,"nurse":-1,"dryer":-1,"foragers":[]}
 var free: Array=workers(game)
 # Clear old nurses/patient locks using actual public assignment actions.
 for id in free:game.camp_tasks.assign(game,id,"rest")
 var patients: Array=game.party_health.members.filter(func(m):return game.party_health.is_active(m) and (int(m.health)<35 or (severity(m)>=3 and m.health<70) or (severity(m)>=2 and m.health<55)))
 patients.sort_custom(func(a,b):return severity(a)*100+(100-int(a.health))>severity(b)*100+(100-int(b.health)))
 if game.state.medicine>0:
  for person in patients:
   var nurse: int=give(game,free,"nurse",int(person.id))
   if nurse>=0:
    info.patient=int(person.id);info.nurse=nurse;free.erase(int(person.id));break
 var urgent: bool=has_scurvy(game) or int(game.party_health.days_without_fresh)>=30
 var needs_greens: bool=produce_held(game)<3
 if urgent and needs_greens:
  var id: int=give(game,free,"forage")
  if id>=0:info.foragers.append(id)
 var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
 var meat: int=game.provisions.fresh.filter(func(b):return not b.get("preserved",false) and not b.get("vitamin_c",false)).reduce(func(n,b):return n+int(b.pounds),0)
 if meat>meal*3.3:
  var dry: String="salt_dry" if not game.preservation_offer(true,true).is_empty() else "dry"
  info.dryer=give(game,free,dry)
 if needs_greens and info.foragers.is_empty():
  var id: int=give(game,free,"forage")
  if id>=0:info.foragers.append(id)
 if needs_greens and not info.foragers.is_empty():
  var id: int=give(game,free,"forage")
  if id>=0:info.foragers.append(id)
 var helpers:=0
 while helpers<3:
  var id: int=give(game,free,"hunt_help")
  if id<0:break
  helpers+=1
 return info
func foot_offer(game) -> Dictionary:
 if camp_policy=="off":return super.foot_offer(game)
 var leader: int=game.camp_tasks.leader_id(game)
 var members: Array=hunters(game).filter(func(id):return id==leader or game.camp_tasks.job(id).job=="hunt_help")
 return {"members":members,"kit":"foot","bullets":mini(30,int(game.state.bullets))}
func dispatch_emergency(game,count: Dictionary) -> bool:
 if not game.field_outings.record.trips.is_empty():return false
 var candidates: Array=workers(game).filter(func(id):return game.camp_tasks.job(id).job not in ["nurse","forage"] and not game.camp_tasks.patient_nurses(game).has(id))
 candidates.sort_custom(func(a,b):return float(game.party_health.members[a].health)+(20 if game.camp_tasks.specialist(game,a,"Hunting") else 0)>float(game.party_health.members[b].health)+(20 if game.camp_tasks.specialist(game,b,"Hunting") else 0))
 for id in candidates:
  for kit in ["ride_horse","foot"]:
   if game.field_outings.start(game,id,kit,1,mini(5,int(game.state.bullets)),"lead" if kit=="ride_horse" else "ride"):
    bump(count,"dispatches");bump(count,"emergency_dispatches");return true
 return false
func act(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if camp_policy=="off" or not game.can_service():return super.act(game,p,aim,count)
 var plan: Dictionary=plan_jobs(game)
 if camp_policy=="coordinated" and game.pending.is_empty():
  var leader: int=game.camp_tasks.leader_id(game)
  var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
  var cannot_haul: bool=game.provisions.Carrying.factor(game.party_health.members[leader],game.provisions.data.walking.health_load_curve)<=0 or int(game.party_health.members[leader].health)<25
  if game.state.food<meal*2 and cannot_haul:
   if dispatch_emergency(game,count):return true
   if game.field_outings.record.trips.any(func(t):return int(game.state.day)<=game.field_outings.expected_day(t)+1):
    bump(count,"coordinated_waits");bump(count,"rests");return game.rest()
  if plan.nurse>=0 and plan.patient==leader and game.state.food>=meal and game.state.day-int(count.get("last_nurse_rest",-100))>=3:
   count.last_nurse_rest=int(game.state.day)
   bump(count,"coordinated_care_days");bump(count,"rests");return game.rest()
  if plan.dryer>=0:
   bump(count,"coordinated_drying_days");bump(count,"rests");return game.rest()
 return super.act(game,p,aim,count)
func run():
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--camp-work="):camp_policy=argument.get_slice("=",1)
 if camp_policy not in ["off","support","coordinated"]:printerr("Invalid camp-work policy");quit(1);return
 await super.run()
