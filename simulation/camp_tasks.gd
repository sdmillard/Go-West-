extends RefCounted
## Standing camp jobs. No clock, UI or random stream of its own.
const JOBS=["rest","forage","dry","salt_dry","nurse","hunt_help"]
const LABELS=["Rest","Forage","Dry meat","Salt + dry meat","Nurse a patient","Help leader hunt"]
var assignments: Dictionary={}
var quiet:=false
var planning_notes: Array[String]=[]
var day_plan: Dictionary={}
var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/camp_tasks.json"))
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
 if not game.can_service() or index<=0 or index>=game.party_health.members.size() or not game.party_health.is_active(game.party_health.members[index]):return false
 var candidate: Dictionary=assignments.duplicate(true)
 candidate[str(index)]={"job":task,"patient":patient}
 if not valid(candidate,game):return false
 assignments=candidate
 return true
func reason(game,index: int,task: String,patient: int=-1) -> String:
 var member: Dictionary=game.party_health.members[index]
 if not game.party_health.is_active(member):return "Not with the party."
 if task=="rest":return ""
 if member.health<int(rules.minimum_health) or member.conditions.any(func(c):return c.severity>=3):return "Too ill or injured to work."
 if not game.characters.willing(index,{"nurse":"care","dry":"preserve","salt_dry":"preserve","forage":"forage","hunt_help":"hunt"}.get(task,task)):return "Refuses at current trust or boundaries."
 if task in ["forage","hunt_help"] and member.conditions.any(func(c):return c.id=="broken_leg"):return "A broken leg prevents this work."
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
func begin(game,action: String) -> void:
 if not enabled() or not day_plan.is_empty():return
 day_plan={"rest":{},"jobs":[],"action":action}
 for member in game.party_health.members:
  if game.party_health.is_active(member):day_plan.rest[int(member.id)]=int(member.id)!=0 or action=="rest"
 var patients: Array=[]
 var kits: int=game.state.medicine
 # Nurses reserve patients first: a patient cannot also do another day's work.
 for index in range(1,game.party_health.members.size()):
  var task: Dictionary=job(index)
  if task.job!="nurse" or index in patients:continue
  var why: String=reason(game,index,task.job,int(task.patient))
  if not why.is_empty() or kits==0 or int(task.patient) in patients:
   report(game,"%s: %s Resting instead." % [game.party_health.members[index].name,why if not why.is_empty() else "Patient or care kit already reserved."])
   continue
  # Never use a person already nursing as a patient of another worker.
  if day_plan.jobs.any(func(j):return j.member==int(task.patient)):continue
  if int(task.patient)==0 and action!="rest":continue
  patients.append(int(task.patient));kits-=1
  day_plan.rest[int(task.patient)]=true
  day_plan.rest[index]=false
  day_plan.jobs.append({"member":index,"job":"nurse","patient":int(task.patient)})
 var drying_claimed:=false
 for member in game.party_health.members:
  var index: int=int(member.id)
  if index==0 or not game.party_health.is_active(member):continue
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
  day_plan.rest[index]=false
  day_plan.jobs.append(entry)
func prepare(game) -> void:
 if day_plan.is_empty():return
 for entry in day_plan.jobs:
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
 if day_plan.action=="forage" and game.party_health.is_active(game.party_health.members[0]):workers+=float(game.party_health.members[0].health)/100.0
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
 if not enabled() or index==0:return false
 if not reason(game,index,"hunt_help").is_empty():return true
 if not game.hunt.is_empty() and game.hunt.has("_camp_helpers"):return index not in game.hunt._camp_helpers
 return job(index).job!="hunt_help"

## Use the same reservation pass for a read-only roster quote.
func quote(game) -> Dictionary:
 var model=get_script().new()
 model.assignments=assignments.duplicate(true)
 model.rules=rules.duplicate(true)
 model.quiet=true
 model.begin(game,"rest")
 var result: Dictionary={"days":1,"meals":int(game.provisions.data.rations_lb[game.state.rations])*int(game.state.party_size),"kits":0,"meat_lb":0.0,"salt":0,"wages_cents":0,"notes":model.planning_notes.duplicate()}
 for entry in model.day_plan.get("jobs",[]):
  if entry.job=="nurse":result.kits+=1
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
