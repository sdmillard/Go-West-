extends RefCounted
## Offscreen camp uses its own saved random stream and actual cached food.
## Real roster entries keep last-known health until the player returns.
const Health=preload("res://simulation/party_health.gd")
const Food=preload("res://simulation/provisions.gd")
const Carry=preload("res://simulation/carrying.gd")
static func valid_selection(game,ids: Array) -> bool:
 var seen: Array=[]
 for id in ids:
  if not (id is int or id is float) or id!=floor(id) or id<=0 or id>=game.party_health.members.size() or int(id) in seen:return false
  if not game.party_health.is_active(game.party_health.members[int(id)]):return false
  seen.append(int(id))
 return ids.size()<int(game.state.party_size)
static func assign(game,ids: Array) -> void:
 var cache: Dictionary=game.wagon_cache
 var random:=RandomNumberGenerator.new()
 random.seed=int(game.state.seed)^int(game.state.day)*104729^int(game.state.miles)*719^0x47554152
 cache["camp_random"]=str(random.state)
 cache["camp_day"]=int(game.state.day)
 cache["risk_cumulative"]=0.0
 cache["gone"]=false
 cache["guards"]=[]
 if not ids.is_empty() and game.state.has("hunger_days"):cache["hunger_days"]=float(game.state.hunger_days)
 cache["camp_log"]=[]
 cache["habitat"]=game.context.region_id(game)
 cache["camp_rations"]=int(game.state.rations)
 cache["camp_deficiency"]=int(game.party_health.days_without_fresh)
 for id in ids:
  var member: Dictionary=game.party_health.members[int(id)]
  member["guarding"]=true
  member["vitamin_days"]=int(member.get("vitamin_days",game.party_health.days_without_fresh))
  var actual: Dictionary=member.duplicate(true)
  actual.erase("guarding")
  cache.guards.append(actual)
  member.history.append("Day %d · Stayed to guard the wagon at mile %d. Current condition unknown until return." % [game.state.day,game.state.miles])
 game.state.party_size=game.party_health.living_count()
 game.state.health=game.party_health.average_health()
static func actual_alive(game,id: int) -> bool:
 for member in game.wagon_cache.get("guards",[]):
  if int(member.id)==id:return member.alive and not member.get("departed",false)
 return false
static func _log(cache: Dictionary,day: int,text: String) -> void:
 cache.camp_log.append("Day %d · %s" % [day,text])
static func _leave(game,cache: Dictionary,member: Dictionary,food,day: int,reason: String) -> void:
 var amount:=mini(12,int(cache.inventory.food))
 food.remove(amount)
 cache.inventory.food-=amount
 var clothes:=mini(1,int(cache.inventory.clothing))
 cache.inventory.clothing-=clothes
 cache.household_gear_lb=maxf(0.0,float(cache.household_gear_lb)-float(game.provisions.data.walking.personal_gear_lb_per_person))
 member["departed"]=true
 member["guard_departure"]=true
 member["departure_day"]=day
 member["departure_place"]=cache.location.from
 member["departure_supplies"]={"food":amount,"clothing":clothes,"gear_lb":int(game.provisions.data.walking.personal_gear_lb_per_person)}
 member.history.append("Day %d · Left the cached wagon: %s." % [day,reason])
 _log(cache,day,"%s left the wagon: %s; took %d food units and %d clothing set(s)." % [member.name,reason,amount,clothes])
static func protection(game,cache: Dictionary) -> float:
 var strength:=0.0
 for member in cache.get("guards",[]):
  if member.alive and not member.get("departed",false):strength+=float(member.health)/100.0
 var armed: bool=int(cache.inventory.bullets)>0
 return maxf(0.2,1.0/(1.0+strength*(2.0 if armed else 0.8)))
static func risk(game,cache: Dictionary,random) -> void:
 if cache.get("gone",false):return
 var rules: Dictionary=game.provisions.data.walking
 var age:=maxi(0,int(game.state.day)-int(cache.day))
 var cumulative:=minf(float(rules.cache_loss_cap),float(rules.cache_loss_base)+age*float(rules.cache_loss_daily))*protection(game,cache)
 var old: float=cache.get("risk_cumulative",0.0)
 var chance:=clampf((cumulative-old)/maxf(0.00001,1.0-old),0.0,1.0)
 cache.risk_cumulative=maxf(old,cumulative)
 if random.randf()>=chance:return
 cache.gone=true
 _log(cache,int(game.state.day),"The cached wagon was looted or ruined; its remaining cargo was lost.")
 var food:=Food.new()
 food.data=game.provisions.data.duplicate(true)
 food.fresh.assign(cache.fresh.duplicate(true))
 for member in cache.get("guards",[]):
  if member.alive and not member.get("departed",false):
   if random.randf()<float(game.provisions.data.wagon_guards.raid_injury):
    member.health=maxi(0,int(member.health)-random.randi_range(15,55))
    if member.health==0:
     member.alive=false
     member.death_day=int(game.state.day)
     member.cause="violence at the abandoned wagon"
     _log(cache,int(game.state.day),member.name+" died defending the wagon.")
   if member.alive:_leave(game,cache,member,food,int(game.state.day),"the wagon was lost")
 for key in cache.inventory:cache.inventory[key]=0
 cache.fresh=[]
 cache.household_gear_lb=0.0
static func tick(game) -> void:
 var cache: Dictionary=game.wagon_cache
 if cache.is_empty() or not cache.has("camp_random"):return
 var random:=RandomNumberGenerator.new()
 random.state=int(cache.camp_random)
 if int(cache.camp_day)<int(game.state.day):
  _day(game,cache,random)
  cache.camp_day=int(game.state.day)
 if not game.Direction.at_cache(game):risk(game,cache,random)
 cache.camp_random=str(random.state)
static func _day(game,cache: Dictionary,random) -> void:
 if cache.gone:return
 var day: int=game.state.day
 var food:=Food.new()
 food.data=game.provisions.data.duplicate(true)
 food.fresh.assign(cache.fresh.duplicate(true))
 var spoiled: int=food.spoil(day,int(cache.inventory.food))
 cache.inventory.food-=spoiled
 if spoiled>0:_log(cache,day,"%d food units spoiled at the wagon." % spoiled)
 var model:=Health.new()
 model.conditions=game.party_health.conditions.duplicate(true)
 model.daily_onset_chance=game.party_health.daily_onset_chance
 model.scurvy=game.party_health.scurvy.duplicate(true)
 model.character_profiles=game.characters.profiles
 model.character_catalog=game.characters.catalog
 model.members.assign(game.party_health.members.duplicate(true))
 for member in model.members:member["departed"]=true
 for member in cache.guards:model.members[int(member.id)]=member
 var count:=model.living_count()
 if count==0:
  cache.fresh=food.fresh.duplicate(true)
  return
 var ration: int=cache.camp_rations
 var needed:=count*int(food.data.rations_lb[ration])
 var hunted: bool=bool(cache.get("field_working",false))
 var rules: Dictionary=food.data.wagon_guards
 if int(cache.inventory.food)<needed*int(rules.hunt_below_days) and int(cache.inventory.bullets)>0 and Carry.capacity(model.members,float(game.hunting.data.carry_per_person_lb))>0:
  # One abstract outing: regional species, real ammunition, health-scaled haul.
  hunted=true
  cache.inventory.bullets-=1
  var region: Dictionary=game.hunting.data.regions[cache.habitat]
  var season: float=food.data.foraging.months[int(game.calendar().month)-1]
  if random.randf()>float(region.empty_chance) and random.randf()<float(rules.hunt_hit_chance)*(0.5+0.5*season):
   var total:=0
   for weight in region.weights:total+=int(weight)
   var roll: int=random.randi_range(1,total)
   var kind:=0
   for weight in region.weights:
    roll-=int(weight)
    if roll<=0:break
    kind+=1
   var species: Dictionary=game.hunting.data.species[kind]
   var pounds:=mini(random.randi_range(int(species.meat_min),int(species.meat_max)),floori(Carry.capacity(model.members,float(game.hunting.data.carry_per_person_lb))))
   var units: int=food.add_meat(pounds,day)
   cache.inventory.food+=units
   _log(cache,day,"Guards spent one bullet hunting; hauled %d lb meat (%d food units)." % [pounds,units])
  else:_log(cache,day,"Guards spent one bullet hunting and returned empty-handed.")
 var eaten:=mini(needed,int(cache.inventory.food))
 var vitamin: float=food.eat(eaten,count,int(cache.inventory.food))
 cache.inventory.food-=eaten
 var sufficient: bool=vitamin>=count*float(food.data.foraging.vitamin_c_lb_per_person)
 cache.camp_deficiency=0 if sufficient else int(cache.camp_deficiency)+1
 var fed: bool=eaten>=needed
 var shortage: Dictionary=food.Shortfall.step(food.data.shortfall,cache,eaten,needed,ration)
 for member in model.members:
  if not model.is_active(member):continue
  member["vitamin_days"]=0 if sufficient else int(member.get("vitamin_days",cache.camp_deficiency-1))+1
  model.affect(member,-int(shortage.damage) if not fed else (int(game.survival.data.rest_recovery[ration]) if not hunted and shortage.can_recover else 0),day,"lack of food" if not fed else "ill health")
  var month: int=game.calendar().month
  var cold: bool=month in [11,12,1,2] or (month in [3,10] and cache.habitat in ["forest","highcountry"])
  if cold:model.affect(member,-(1 if int(cache.inventory.clothing)>=count else 4),day,"winter exposure")
 model.rng.state=random.state
 model.tick(day,not hunted,0.6 if fed else 2.0,ration if fed else 0,int(game.calendar().year),int(game.calendar().month),cache.habitat,int(cache.camp_deficiency))
 random.state=model.rng.state
 for line in model.notices:cache.camp_log.append(line)
 for member in cache.guards:
  if not model.is_active(member):continue
  var profile: Dictionary=game.characters.profiles[int(member.id)]
  var desperate: bool=not fed or int(member.health)<20 or int(profile.trust)<=int(profile.thresholds.breaking)
  if desperate and random.randf()<float(rules.departure_chance):
   # Partners who were assigned together leave together.
   var group: Array=[member]
   for other in cache.guards:
    if int(other.id)!=int(member.id) and model.is_active(other) and game.crime.bond(int(other.id),int(member.id))=="partner":group.append(other)
   for leaving in group:_leave(game,cache,leaving,food,day,"hunger, failing health or broken trust")
 cache.fresh=food.fresh.duplicate(true)
static func reveal(game) -> bool:
 var cache: Dictionary=game.wagon_cache
 if not cache.has("camp_random"):return not cache.get("gone",false)
 var random:=RandomNumberGenerator.new()
 random.state=int(cache.camp_random)
 if not cache.found:risk(game,cache,random)
 cache.camp_random=str(random.state)
 for line in cache.camp_log:game.journal.append(line+" [Learned on return]")
 cache.camp_log=[]
 for actual in cache.guards:
  var id: int=actual.id
  var member: Dictionary=game.party_health.members[id]
  # Preserve assignment history, then append offscreen outcomes.
  var history: Array=member.history.duplicate()
  for line in actual.history:
   if line not in history:history.append(line)
  member.clear()
  member.merge(actual.duplicate(true))
  member.history=history
  if member.alive and not member.get("departed",false):
   if cache.has("hunger_days"):game.state["hunger_days"]=maxf(float(game.state.get("hunger_days",0)),float(cache.hunger_days))
   game.state.household_gear_lb=game.provisions.household_mass(game.state)+float(game.provisions.data.walking.personal_gear_lb_per_person)
   member.history.append("Day %d · Rejoined the travelers at the wagon." % game.state.day)
   game.journal.append("Day %d · %s rejoined the party." % [game.state.day,member.name])
   cache.household_gear_lb=maxf(0.0,float(cache.household_gear_lb)-float(game.provisions.data.walking.personal_gear_lb_per_person))
  elif member.get("departed",false):
   game.state["departed_gear_lb"]=int(game.state.get("departed_gear_lb",0))+int(member.departure_supplies.gear_lb)
  else:
   var uid: String=game.crime.person_id(int(game.state.seed),id)
   if not game.crime.record.remains.any(func(body):return body.person==uid):
    game.Remains.add(game,uid,member.name,member.cause,int(member.death_day),0,bool(cache.gone))
 for member in game.party_health.members:
  if game.party_health.is_active(member) and not member.has("vitamin_days"):member["vitamin_days"]=int(game.party_health.days_without_fresh)
 cache.guards=[]
 game.state.party_size=game.party_health.living_count()
 game.state.health=game.party_health.average_health()
 if game.state.vehicle=="foot":game.state.household_gear_lb=float(game.provisions.data.walking.personal_gear_lb_per_person)*int(game.state.party_size)
 return not cache.gone
static func valid(cache: Dictionary,game,day: int,party: Array=[]) -> bool:
 if not cache.has("camp_random"):return not cache.has("guards") and not party.any(func(member):return member.get("guarding",false))
 if not game.provisions.Shortfall.valid_state(cache):return false
 if not cache.camp_random is String or not cache.camp_random.is_valid_int() or str(int(cache.camp_random))!=cache.camp_random:return false
 if not game.crime.whole(cache.get("camp_day"),0,day) or not cache.get("gone") is bool or not cache.get("guards") is Array or cache.guards.size()>game.MAX_TRAVELERS-1 or not cache.get("camp_log") is Array or cache.camp_log.size()>20000:return false
 if not (cache.get("risk_cumulative") is float or cache.get("risk_cumulative") is int) or not is_finite(cache.risk_cumulative) or cache.risk_cumulative<0 or cache.risk_cumulative>1:return false
 if not game.hunting.data.regions.has(cache.get("habitat")) or not game.crime.whole(cache.get("camp_rations"),0,2) or not game.crime.whole(cache.get("camp_deficiency"),0,100000):return false
 for line in cache.camp_log:
  if not line is String:return false
 var ids: Array=[]
 for member in cache.guards:
  if not member is Dictionary or not game.crime.whole(member.get("id"),1,game.MAX_TRAVELERS-1) or int(member.id) in ids or not member.get("name") is String or not member.get("alive") is bool or not game.crime.whole(member.get("health"),0,100) or member.alive!=(member.health>0) or not member.get("conditions") is Array or not member.get("history") is Array or not member.get("cause") is String or not game.crime.whole(member.get("death_day"),-1,day) or not game.crime.whole(member.get("vitamin_days"),0,100000):return false
  if member.has("guarding") or (member.has("departed") and member.departed!=true):return false
  ids.append(int(member.id))
  for line in member.history:
   if not line is String:return false
  for condition in member.conditions:
   if not condition is Dictionary or not game.party_health.conditions.has(condition.get("id")) or not game.crime.whole(condition.get("started_day"),0,day) or not game.crime.whole(condition.get("elapsed"),0,100000) or not game.crime.whole(condition.get("severity"),1,3):return false
  if member.has("immune"):
   if not member.immune is Array:return false
   for id in member.immune:
    if not game.party_health.conditions.has(id) or not game.party_health.conditions[id].get("immunizing",false):return false
  if member.get("departed",false):
   if not member.alive or member.get("guard_departure")!=true or not game.crime.whole(member.get("departure_day"),0,day) or not game.route.nodes.has(member.get("departure_place")) or not member.get("departure_supplies") is Dictionary:return false
   var goods: Dictionary=member.departure_supplies
   if goods.size()!=3 or not game.crime.whole(goods.get("food"),0,12) or not game.crime.whole(goods.get("clothing"),0,1) or goods.get("gear_lb")!=game.provisions.data.walking.personal_gear_lb_per_person:return false
  if not party.is_empty() and (int(member.id)>=party.size() or not party[int(member.id)].get("guarding",false)):return false
 if not party.is_empty():
  for member in party:
   if member.get("guarding",false) and int(member.id) not in ids:return false
 return true
