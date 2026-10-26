extends RefCounted
## Finite local work and uniquely owned portable keepsakes. No independent RNG.
const MAX_OWNERS=32
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_income.json"))
var record: Dictionary={"keepsakes":{},"work":{}}
var worker: int=-1 # Only during one synchronous paid day; never saved.
static func all_keys() -> Array:
 var result: Array=[]
 for index in range(MAX_OWNERS):result.append(key(index))
 return result
static func key(owner: int) -> String:return "keepsake_%d" % owner
static func is_keepsake(item: String) -> bool:
 for index in range(MAX_OWNERS):
  if item==key(index):return true
 return false
static func valid_rules(value: Variant) -> bool:
 if not value is Dictionary or not value.get("note") is String or not value.get("keepsake") is Dictionary or not value.get("jobs") is Dictionary or not value.get("sites") is Dictionary:return false
 for field in ["sell_cents","arrival_points","consent_trust"]:
  if not preload("res://simulation/pelts.gd").whole(value.keepsake.get(field),1,10000):return false
 if value.keepsake.consent_trust>100:return false
 var weight: Variant=value.keepsake.get("weight_lb")
 if not (weight is int or weight is float) or not is_finite(weight) or weight<=0 or weight>5:return false
 if value.jobs.keys().size()!=3:return false
 for id in ["labor","carpentry","care"]:
  var job: Variant=value.jobs.get(id)
  if not job is Dictionary or not job.get("label") is String or not preload("res://simulation/pelts.gd").whole(job.get("cents"),1,10000) or job.get("background") not in ["","Carpentry","Caregiving"]:return false
 for site in value.sites:
  var row: Variant=value.sites[site]
  if not site is String or not row is Dictionary or not preload("res://simulation/pelts.gd").whole(row.get("days"),1,30) or not preload("res://simulation/pelts.gd").whole(row.get("first_month"),1,12):return false
 return true
static func configure(model) -> bool:
 var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_income.json"))
 if not valid_rules(rules):return false
 for index in range(MAX_OWNERS):model.data.weights_lb[key(index)]=float(rules.keepsake.weight_lb)
 return true
func valid_setup(value: Variant,count: int) -> bool:
 return value is Array and value.size()==count and value.all(func(v):return v is bool)
func start(game,selections: Array) -> void:
 record={"keepsakes":{},"work":{}}
 for index in range(selections.size()):
  if selections[index]:
   record.keepsakes[str(index)]={"consent":index==0}
   game.state[key(index)]=1
func label_for(game,item: String) -> String:
 if not is_keepsake(item):return item
 var index: int=int(item.trim_prefix("keepsake_"))
 return "%s's keepsake" % game.party_health.members[index].name if index<game.party_health.members.size() else "Family keepsake"
func can_consent(game,index: int) -> bool:
 if index==0:return true
 var member: Dictionary=game.party_health.members[index]
 return game.party_health.is_active(member) and game.characters.profiles[index].trust>=int(data.keepsake.consent_trust)
func consent(game,index: int,allow: bool) -> bool:
 if not game.can_service() or not record.keepsakes.has(str(index)) or (allow and not can_consent(game,index)):return false
 record.keepsakes[str(index)].consent=allow
 game.journal.append("Day %d · %s %s sale of their family keepsake." % [game.state.day,game.party_health.members[index].name,"agreed to" if allow else "withdrew permission for"])
 return true
func rows(game,venue: String,kind: String) -> Array:
 var result: Array=[]
 if kind not in ["post","traders"]:return result
 for owner in record.keepsakes:
  var index: int=int(owner);var item: String=key(index)
  if int(game.state.get(item,0))==0:continue
  var allowed: bool=not game.party_health.members[index].alive or (record.keepsakes[owner].consent and can_consent(game,index))
  var price: int=int(data.keepsake.sell_cents)
  if kind=="traders":price=floori(price*0.75)
  result.append({"item":item,"label":label_for(game,item),"amount":1,"buy_cents":0,"sell_cents":price,"can_buy":0,"can_sell":1 if allowed else 0,"held":1,"buy_key":venue+"|buy_"+item,"sell_key":venue+"|sell_"+item,"sells":false,"buys":true})
 return result
func points(game) -> int:
 if game.state.status!="arrived":return 0
 var count:=0
 for owner in record.keepsakes:
  count+=int(game.state.get(key(int(owner)),0))
 return count*int(data.keepsake.arrival_points)
func offers(game) -> Array:
 var result: Array=[]
 if not game.can_service() or not game.pending.has("landmark"):return result
 var site: String=str(game.state.landmark)
 if not data.sites.has(site) or int(game.calendar().month)<int(data.sites[site].first_month) or game.crime.closed(site) or game.crime.refuses(game,site):return result
 var left: int=maxi(0,int(data.sites[site].days)-int(record.work.get(site,0)))
 for id in data.jobs:
  var job: Dictionary=data.jobs[id]
  result.append({"id":id,"label":job.label,"cents":int(job.cents),"background":job.background,"left":left})
 return result
func quote(game,index: int,job_id: String) -> Dictionary:
 var result: Dictionary={"valid":false,"message":"No suitable local work available.","cents":0,"days":1,"meals":int(game.provisions.data.rations_lb[game.state.rations])*int(game.state.party_size)}
 var matching: Array=offers(game).filter(func(o):return o.id==job_id and o.left>0)
 if matching.is_empty() or index<0 or index>=game.party_health.members.size():return result
 var person: Dictionary=game.party_health.members[index];var offer: Dictionary=matching[0]
 if not game.party_health.is_active(person) or person.health<40 or person.conditions.any(func(c):return c.severity>=3 or c.id=="broken_leg"):
  result.message="This traveler is too ill, injured or absent to work.";return result
 if game.camp_tasks.patient_nurses(game).has(index):result.message="This traveler is being nursed and must rest.";return result
 if not offer.background.is_empty() and not game.camp_tasks.specialist(game,index,offer.background) and not (index==0 and game.state.profession=="carpenter" and offer.background=="Carpentry"):
  result.message="This job needs a suitable background.";return result
 result.valid=true;result.cents=offer.cents
 result.message="%s earns $%.2f. ONE DAY; party meals: %d food units, plus normal wages/weather. No employer board. Other companions follow their camp orders. %d local work day(s) remain." % [person.name,offer.cents/100.0,result.meals,offer.left]
 return result
func work(game,index: int,job_id: String) -> bool:
 var q: Dictionary=quote(game,index,job_id)
 if not q.valid:return false
 var site: String=str(game.state.landmark)
 record.work[site]=int(record.work.get(site,0))+1
 worker=index
 # Make the earned wage available for this day's existing automatic contract payments.
 game.state.money=snappedf(float(game.state.money)+q.cents/100.0,0.01)
 game._tick_day(false,false,"settlement_work")
 worker=-1
 # Payment is for the day begun; normal health hazards still occur during it.
 game.supply_history.append({"day":game.state.day,"event":"settlement_wages","worker":index,"changes":{"money":q.cents/100.0}})
 game.journal.append("Day %d · %s earned $%.2f doing %s at %s." % [game.state.day,game.party_health.members[index].name,q.cents/100.0,data.jobs[job_id].label,game.route.nodes[site].name])
 game.refresh_stop_offers()
 if game.state.status=="traveling" and not game.crime.check_pursuit(game):game.crime.check_wanted(game)
 return true
func valid(value: Variant,game) -> bool:
 if not value is Dictionary or value.size()!=2 or not value.get("keepsakes") is Dictionary or not value.get("work") is Dictionary:return false
 for owner in value.keepsakes:
  if not owner is String or not owner.is_valid_int() or str(int(owner))!=owner or int(owner)<0 or int(owner)>=game.party_health.members.size():return false
  var entry: Variant=value.keepsakes[owner]
  if not entry is Dictionary or entry.size()!=1 or not entry.get("consent") is bool:return false
 for site in value.work:
  if not data.sites.has(site) or not game.Pelts.whole(value.work[site],0,int(data.sites[site].days)):return false
 var inventories: Array=[game.state]
 if not game.wagon_cache.is_empty():inventories.append(game.wagon_cache.inventory)
 for trip in game.field_outings.record.trips:inventories.append(trip.camp.inventory)
 for inventory in inventories:
  for item in inventory:
   if str(item).begins_with("keepsake_") and not is_keepsake(str(item)):return false
 for index in range(MAX_OWNERS):
  var total:=0
  for inventory in inventories:
   var count: Variant=inventory.get(key(index),0)
   if not game.Pelts.whole(count,0,1):return false
   total+=int(count)
  if total>1 or (total>0 and not value.keepsakes.has(str(index))):return false
 return true
