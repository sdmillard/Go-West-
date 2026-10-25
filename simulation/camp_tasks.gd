extends RefCounted
## Standing camp jobs. No clock, UI or random stream of its own.
const JOBS=["rest","forage","dry","salt_dry","nurse","hunt_help","repair_patch","repair_wood","guard"]
const LABELS=["Rest","Forage","Dry meat","Salt + dry meat","Nurse a patient","Help leader hunt","Patch wagon","Wooden wagon repair","Guard stock"]
var assignments: Dictionary={}
var quiet:=false
var planning_notes: Array[String]=[]
var day_plan: Dictionary={}
var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/camp_tasks.json"))
func leader_id(game) -> int:
 for member in game.party_health.members:
  if game.party_health.is_active(member):return int(member.id)
 return -1
func enabled() -> bool:return not assignments.is_empty()
func job(index: int) -> Dictionary:return assignments.get(str(index),{"job":"rest","patient":-1})
func snapshot() -> Dictionary:return assignments.duplicate(true)
func valid(value: Variant,game,count: int=-1) -> bool:
 if count<0:count=game.party_health.members.size()
 if not value is Dictionary or value.size()>count-1:return false
 for key in value:
  if not key is String or not key.is_valid_int() or str(int(key))!=key or int(key)<1 or int(key)>=count:return false
  var entry: Variant=value[key]
  if not entry is Dictionary or entry.size()!=2 or entry.get("job") not in JOBS:return false
  var patient: Variant=entry.get("patient")
  if not patient is int and not patient is float:return false
  if not is_finite(float(patient)) or patient!=floor(patient):return false
  if entry.job=="nurse":
   if patient<0 or patient>=count or patient==int(key):return false
  elif patient!=-1:return false
 return true
func assign(game,index: int,task: String,patient: int=-1) -> bool:
 if not game.can_service() or index==leader_id(game) or index<=0 or index>=game.party_health.members.size() or not game.party_health.is_active(game.party_health.members[index]):return false
 if task!="rest" and patient_nurses(game).has(index):return false
 var candidate: Dictionary=assignments.duplicate(true)
 candidate[str(index)]={"job":task,"patient":patient}
 if not valid(candidate,game):return false
 assignments=candidate
 return true
func reason(game,index: int,task: String,patient: int=-1) -> String:
 var member: Dictionary=game.party_health.members[index]
 if index==leader_id(game) and task!="rest":return "The leader uses the main camp action."
 if not game.party_health.is_active(member):return "Not with the party."
 if task=="rest":return ""
 if member.health<int(rules.minimum_health) or member.conditions.any(func(c):return c.severity>=3):return "Too ill or injured to work."
 if not game.characters.willing(index,{"nurse":"care","dry":"preserve","salt_dry":"preserve","forage":"forage","hunt_help":"hunt","repair_patch":"repair","repair_wood":"repair","guard":"defend"}.get(task,task)):return "Refuses at current trust or boundaries."
 if task in ["forage","hunt_help"] and member.conditions.any(func(c):return c.id=="broken_leg"):return "A broken leg prevents this work."
 if task=="guard" and game.Mounts.animals(game.state)==0:return "No horses or mules need a stock watch."
 if task in ["repair_patch","repair_wood"]:
  var why: String=game.camp_repair.reason(game,index,"patch" if task=="repair_patch" else "wood")
  if not why.is_empty():return why
 if task=="forage" and not game.forage_offer(true).available:return "No suitable gathering in this season or weather."
 if task in ["dry","salt_dry"] and game.preservation_offer(task=="salt_dry",true).is_empty():return "No suitable meat / salt after tomorrow's meals and spoilage."
 if task=="nurse":
  if patient<0 or patient>=game.party_health.members.size() or patient==index:return "Choose another traveler."
  var person: Dictionary=game.party_health.members[patient]
  if not game.party_health.is_active(person) or (person.health>=100 and person.conditions.is_empty()):return "Patient unavailable or already well."
  if game.state.medicine<1:return "Needs one care kit."
 return ""
func specialist(game,index: int,background: String) -> bool:
 var profile: Dictionary=game.characters.profiles[index]
 return profile.skill==background or profile.specials.any(func(s):return game.characters.catalog.data.specials[s].get("assists","")==background)
func begin(game,action: String,leader_patient: int=-1) -> void:
 if not enabled() or not day_plan.is_empty():return
 var leader: int=leader_id(game)
 day_plan={"rest":{},"jobs":[],"action":action,"leader":leader}
 for member in game.party_health.members:
  if game.party_health.is_active(member):day_plan.rest[int(member.id)]=int(member.id)!=leader or action=="rest"
 var patients: Array=[]
 if leader_patient>=0:
  patients.append(leader_patient)
  day_plan.rest[leader_patient]=true
 var kits: int=game.state.medicine
 # Nurses reserve patients first: a patient cannot also do another day's work.
 for index in range(1,game.party_health.members.size()):
  var task: Dictionary=job(index)
  if index==leader or task.job!="nurse" or index in patients:continue
  var why: String=reason(game,index,task.job,int(task.patient))
  if not why.is_empty() or kits==0 or int(task.patient) in patients:
   report(game,"%s: %s Resting instead." % [game.party_health.members[index].name,why if not why.is_empty() else "Patient or care kit already reserved."])
   continue
  # Never use a person already nursing as a patient of another worker.
  if day_plan.jobs.any(func(j):return j.member==int(task.patient)):continue
  if int(task.patient)==leader and action!="rest":continue
  patients.append(int(task.patient));kits-=1
  day_plan.rest[int(task.patient)]=true
  day_plan.rest[index]=false
  day_plan.jobs.append({"member":index,"job":"nurse","patient":int(task.patient)})
 var drying_claimed:=false
 var repair_claimed:=false
 var guard_claimed:=false
 for member in game.party_health.members:
  var index: int=int(member.id)
  if index==leader or not game.party_health.is_active(member):continue
  var task: Dictionary=job(index)
  if task.job in ["rest","nurse"]:continue
  var why: String=reason(game,index,task.job,int(task.patient))
  if not why.is_empty() or index in patients or (task.job=="hunt_help" and action!="hunt"):
   if not why.is_empty():report(game,"%s: %s Resting instead." % [member.name,why])
   continue
  var entry: Dictionary={"member":index,"job":task.job}
  if task.job in ["dry","salt_dry"]:
   if drying_claimed or action=="dry":
    report(game,"%s: another worker has the meat batch; resting instead." % member.name)
    continue
   entry.offer=game.preservation_offer(task.job=="salt_dry",true)
   drying_claimed=true
  if task.job in ["repair_patch","repair_wood"]:
   var method: String="patch" if task.job=="repair_patch" else "wood"
   var repair_why: String=game.camp_repair.reason(game,index,method,kits)
   if repair_claimed or action=="repair" or not repair_why.is_empty():
    report(game,"%s: %s Resting instead." % [member.name,repair_why if not repair_why.is_empty() else "Another worker has the wagon repair."])
    continue
   if method=="patch" and not game.camp_repair.work.kit_spent:kits-=1
   entry.method=method
   repair_claimed=true
  if task.job=="guard":
   if guard_claimed:continue
   guard_claimed=true
  day_plan.rest[index]=false
  day_plan.jobs.append(entry)
func prepare(game) -> void:
 if day_plan.is_empty():return
 for entry in day_plan.jobs:
  if entry.job in ["repair_patch","repair_wood"]:
   entry.ready=true
   if entry.method=="patch" and not game.camp_repair.work.kit_spent:
    if game.state.medicine<1:
     day_plan.rest[entry.member]=true;entry.ready=false
     continue
    game.state.medicine-=1
    game.camp_repair.work.kit_spent=true
    game.supply_history.append({"day":game.state.day,"event":"camp_repair_materials","changes":{"medicine":-1},"worker":entry.member})
   game.camp_repair.work.method=entry.method
  if entry.job!="nurse":continue
  if game.state.medicine<1:
   day_plan.rest[entry.member]=true
   report(game,"%s: no kit left after the leader's care; resting instead." % game.party_health.members[entry.member].name)
   continue
  game.state.medicine-=1
  var patient: Dictionary=game.party_health.members[entry.patient]
  if not game.party_health.is_active(patient):continue
  var expert: bool=specialist(game,int(entry.member),"Caregiving")
  game.party_health.affect(patient,int(rules.nurse_health)+(int(game.characters.benefits.care_health_bonus) if expert else 0),game.state.day,"care")
  for condition in patient.conditions:
   condition.elapsed+=int(rules.nurse_recovery)+(int(game.characters.benefits.care_recovery_bonus) if expert else 0)
   condition.severity=maxi(1,int(condition.severity)-1)
  game.characters.care(game,int(entry.patient))
  game.supply_history.append({"day":game.state.day,"event":"camp_nursing","changes":{"medicine":-1},"worker":entry.member,"patient":entry.patient})
  report(game,"%s nursed %s with one care kit%s." % [game.party_health.members[entry.member].name,patient.name," (caregiver)" if expert else ""])
func finish(game) -> void:
 if day_plan.is_empty():return
 var workers:=0.0
 for entry in day_plan.jobs:
  var member: Dictionary=game.party_health.members[entry.member]
  if not game.party_health.is_active(member):continue
  if entry.job in ["repair_patch","repair_wood"] and entry.get("ready",false):game.camp_repair.advance(game,int(entry.member))
  if entry.job=="guard":
   game.state["camp_watch_day"]=int(game.state.day)
   game.state["camp_watch_member"]=int(entry.member)
   report(game,"%s stood watch over the stock." % member.name)
  if entry.job=="forage":workers+=float(member.health)/100.0
  if entry.job in ["dry","salt_dry"]:
   # Today's catch is dinner, not a morning drying input.
   var catches: Array=game.provisions.fresh.filter(func(b):return b.get("_hunt_meal",false))
   game.provisions.fresh=game.provisions.fresh.filter(func(b):return not b.get("_hunt_meal",false))
   var amount: int=mini(int(entry.offer.input),game.provisions.processable())
   var salted: bool=entry.job=="salt_dry"
   while salted and amount>0 and ceili(game.provisions.fresh_mass(amount)*float(game.provisions.data.preservation.salt_per_food_lb))>int(game.state.salt):amount-=1
   var result: Dictionary=game.provisions.preserve(amount,int(game.state.day),salted)
   game.provisions.fresh.append_array(catches)
   game.state.food-=int(result.lost);game.state.salt-=int(result.salt)
   if result.input>0:
    game.supply_history.append({"day":game.state.day,"event":"camp_drying","changes":{"food":-int(result.lost),"salt":-int(result.salt)},"worker":entry.member,"processed":result.input,"retained":result.kept})
    report(game,"%s dried %.1f lb of morning meat into %d food units; %d lb salt used." % [member.name,result.mass,result.kept,result.salt])
 var leader: int=int(day_plan.get("leader",leader_id(game)))
 if day_plan.action=="forage" and leader>=0 and game.party_health.is_active(game.party_health.members[leader]):workers+=float(game.party_health.members[leader].health)/100.0
 if workers>0 and game.state.status=="traveling":
  var offer: Dictionary=game.forage_offer(true)
  offer.workers=workers
  if offer.available:game._gather_forage(offer,true)
  else:report(game,"Gathering was stopped by conditions; no harvest returned.")
 day_plan={}
func report(game,text: String) -> void:
 if quiet:planning_notes.append(text)
 else:game.journal.append("Day %d · Camp work: %s" % [game.state.day,text])
func excludes_helper(game,index: int) -> bool:
 if not enabled() or index==leader_id(game):return false
 if patient_nurses(game).has(index):return true
 if not reason(game,index,"hunt_help").is_empty():return true
 if not game.hunt.is_empty() and game.hunt.has("_camp_helpers"):return index not in game.hunt._camp_helpers
 return job(index).job!="hunt_help"

## Use the same reservation pass for a read-only roster quote.
func quote(game) -> Dictionary:
 var model=preview_day(game)
 var result: Dictionary={"days":1,"meals":int(game.provisions.data.rations_lb[game.state.rations])*int(game.state.party_size),"kits":0,"meat_lb":0.0,"salt":0,"wages_cents":0,"repair_kits":0,"watch":false,"notes":model.planning_notes.duplicate()}
 for entry in model.day_plan.get("jobs",[]):
  if entry.job=="nurse":result.kits+=1
  if entry.job=="repair_patch" and not game.camp_repair.work.kit_spent:result.kits+=1;result.repair_kits+=1
  if entry.job=="guard":result.watch=true
  if entry.job in ["dry","salt_dry"]:
   result.meat_lb+=float(entry.offer.mass)
   result.salt+=int(entry.offer.salt)
 for profile in game.characters.profiles:
  if profile.contract.is_empty():continue
  if not game.party_health.is_active(game.party_health.members[profile.id]) and not game.Guards.actual_alive(game,int(profile.id)):continue
  var contract: Dictionary=profile.contract
  var bills: int=maxi(0,floori(float(int(game.state.day)+1-int(contract.next_due_day))/int(contract.interval_days))+1)
  result.wages_cents+=int(contract.arrears_cents)+bills*int(contract.wage_cents)
 return result

func preview_day(game):
 var model=get_script().new()
 model.assignments=assignments.duplicate(true)
 model.rules=rules.duplicate(true)
 model.quiet=true
 model.begin(game,"rest")
 return model
func patient_nurses(game) -> Dictionary:
 var result: Dictionary={}
 var plan: Dictionary=day_plan if not day_plan.is_empty() else preview_day(game).day_plan
 for entry in plan.get("jobs",[]):
  if entry.job=="nurse":result[int(entry.patient)]=int(entry.member)
 return result
func end_leader_nursing(game) -> void:
 var leader: int=leader_id(game)
 if leader<0:return
 for key in assignments:
  var task: Dictionary=assignments[key]
  if task.job!="nurse" or int(task.patient)!=leader:continue
  assignments[key]={"job":"rest","patient":-1}
  report(game,"%s stopped nursing %s because the leader chose another activity." % [game.party_health.members[int(key)].name,game.party_health.members[leader].name])

func stock_guarded(game) -> bool:
 if not enabled():return bool(game.state.get("night_guard",false))
 if int(game.state.get("camp_watch_day",-1))!=int(game.state.day):return false
 var index: int=int(game.state.get("camp_watch_member",-1))
 return index>0 and index<game.party_health.members.size() and game.party_health.is_active(game.party_health.members[index])

func other_day_watch(game) -> void:
 # Travel/trading do not run camp chores, but the named night watch still has a job.
 if not enabled():return
 for member in game.party_health.members:
  var index: int=int(member.id)
  if index<=0 or index==leader_id(game) or job(index).job!="guard" or not reason(game,index,"guard").is_empty():continue
  game.state["camp_watch_day"]=int(game.state.day)
  game.state["camp_watch_member"]=index
  game.state.fatigue=mini(100,int(game.state.fatigue)+int(game.provisions.data.mounts.guard_fatigue))
  report(game,"%s stood night watch after the day's activity; the watch cost sleep." % member.name)
  return
