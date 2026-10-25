extends RefCounted
## The same people/equipment/load calculation serves player and delegated hunts.
const KITS=["foot","ride_horse","pack_horse","ride_mule","pack_mule","horse_and_mule","ride_horse_light","ride_mule_light","wagon"]
const RETURN_MODES=["ride","ride_strenuous","lead","lead_strenuous"]
static func rides(kit: String) -> bool:return kit in ["ride_horse","ride_mule","horse_and_mule","ride_horse_light","ride_mule_light"]
static func mode(trip: Dictionary) -> String:return str(trip.camp.get("return_mode","ride"))
static func stock(kit: String) -> Dictionary:
 var result: Dictionary={"horses":0,"mules":0,"saddles":0,"pack_saddles":0,"saddlebags":0}
 match kit:
  "ride_horse_light":result.horses=1;result.saddles=1
  "ride_mule_light":result.mules=1;result.saddles=1
  "ride_horse":result.horses=1;result.saddles=1;result.saddlebags=1
  "pack_horse":result.horses=1;result.pack_saddles=1
  "ride_mule":result.mules=1;result.saddles=1;result.saddlebags=1
  "pack_mule":result.mules=1;result.pack_saddles=1
  "horse_and_mule":result.horses=1;result.mules=1;result.saddles=1;result.saddlebags=1;result.pack_saddles=1
 return result
static func transport(game,members: Array,kit: String,allocated: Dictionary={},return_mode: String="ride") -> Dictionary:
 var inventory: Dictionary=stock(kit) if allocated.is_empty() else allocated.duplicate()
 inventory.merge({"vehicle":"foot","party_size":members.size(),"lead_mounts":return_mode.begins_with("lead"),"strenuous_load":return_mode.ends_with("strenuous")})
 return inventory
static func people(game,members: Array,riding: int) -> float:
 var actual: Array=[]
 for id in members:actual.append(id if id is Dictionary else game.party_health.members[int(id)])
 return minf(float(game.hunting.data.carry_limit),game.provisions.Carrying.capacity(game.Mounts.walking_members(actual,riding),float(game.hunting.data.carry_per_person_lb),game.provisions.data.walking.health_load_curve))
static func capacity(game,members: Array,kit: String,allocated: Dictionary={},return_mode: String="ride") -> float:
 if kit=="wagon":return float(game.provisions.data.cargo_guideline_lb)
 var plan: Dictionary=game.Mounts.plan(game.provisions.data.mounts,transport(game,members,kit,allocated,return_mode))
 return people(game,members,int(plan.riding_people))+game.Mounts.freight_limit(plan)
static func mass(game,members: Array,kit: String,inventory: Dictionary,fresh: Array,allocated: Dictionary={},return_mode: String="ride") -> float:
 var food=game.provisions.get_script().new();food.data=game.provisions.data;food.fresh.assign(fresh)
 var load: Dictionary=inventory.duplicate()
 load.merge(transport(game,members,kit,allocated,return_mode))
 return food.cargo(load)
static func load_profile(game,members: Array,kit: String,cargo: float,allocated: Dictionary={},return_mode: String="ride") -> Dictionary:
 var plan: Dictionary=game.Mounts.plan(game.provisions.data.mounts,transport(game,members,kit,allocated,return_mode))
 return game.Mounts.burden(game.provisions.data.mounts,plan,cargo,people(game,members,int(plan.riding_people)))
static func search_plan(game,members: Array,kit: String,allocated: Dictionary,return_mode: String,pack_lb: float,condition: int=-1,already_out: bool=false) -> Dictionary:
 var result: Dictionary={"search_factor":1.0,"search_hours":0.0,"return_hours":0.0,"extra_return_hours":0.0}
 if not rides(kit):return result
 var rules: Dictionary=game.hunting.data.return_time
 var healthy: int=game.Mounts.condition(game.state) if condition<0 else condition
 var base: Dictionary=game.Mounts.plan(game.provisions.data.mounts,transport(game,members,kit,allocated,"ride"))
 var chosen: Dictionary=game.Mounts.plan(game.provisions.data.mounts,transport(game,members,kit,allocated,return_mode))
 var normal_load: Dictionary=load_profile(game,members,kit,capacity(game,members,kit,allocated,"ride"),allocated,"ride")
 var chosen_load: Dictionary=load_profile(game,members,kit,capacity(game,members,kit,allocated,return_mode),allocated,return_mode)
 var outbound_load: Dictionary=load_profile(game,members,kit,pack_lb,allocated,"ride")
 var ride_speed: float=planning_speed(game,base,healthy)/float(rules.travel_hours_per_day)
 var chosen_speed: float=planning_speed(game,chosen,healthy)/float(rules.travel_hours_per_day)
 var outbound_hours: float=0.0 if already_out else float(rules.radius_miles)/maxf(0.1,ride_speed*game.Mounts.speed_factor(base,outbound_load))
 var baseline_return: float=float(rules.radius_miles)/maxf(0.1,ride_speed*game.Mounts.speed_factor(base,normal_load))
 var chosen_return: float=float(rules.radius_miles)/maxf(0.1,chosen_speed*game.Mounts.speed_factor(chosen,chosen_load))
 var normal_search: float=maxf(1.0,float(rules.outing_hours)-outbound_hours-baseline_return)
 var extra: float=maxf(0,chosen_return-baseline_return)
 var fraction: float=clampf((normal_search-extra)/normal_search,float(rules.minimum_search_fraction),1.0)
 return {"search_factor":fraction,"search_hours":normal_search*fraction,"return_hours":chosen_return,"extra_return_hours":extra}
static func planning_speed(game,plan: Dictionary,condition: int) -> float:
 if game.Mounts.mounted(plan):return game.Mounts.base_miles(game.provisions.data.mounts,condition,0)
 return float(game.provisions.data.walking.packing_miles_per_day if plan.mode=="packing" else game.provisions.data.walking.miles_per_day)
static func wagon_quote(game,members: Array) -> Dictionary:
 var fail: Dictionary={"valid":false,"message":"Take everyone currently with you to bring the wagon."}
 var active: Array=game.party_health.members.filter(func(p):return game.party_health.is_active(p)).map(func(p):return int(p.id))
 if members.size()!=active.size() or not active.all(func(id):return id in members):return fail
 if game.state.vehicle!="wagon" or game.team_conditions.pulling(game.state)<1 or game.state.ox_health<1:fail.message="A wagon and a working ox team are required.";return fail
 var region: String=game.context.region_id(game)
 if not game.hunting.data.regions[region].wagon_access:fail.message="The wagon cannot reach this hunting ground. Use people or animals here.";return fail
 var crew: Array=active.filter(func(id):return game.provisions.Carrying.factor(game.party_health.members[id],game.provisions.data.walking.health_load_curve)>0 and game.characters.willing(id,"hunt"))
 if crew.is_empty() or active[0] not in crew:fail.message="The leader must be able and willing to hunt.";return fail
 if game.state.bullets<1:fail.message="Bring ammunition to hunt.";return fail
 var inventory: Dictionary={}
 for key in game.provisions.data.weights_lb:inventory[key]=0
 var used: float=game.provisions.cargo(game.state)
 var limit: float=game.provisions.storage_capacity(game.state)
 return {"valid":used<limit,"message":"Ready." if used<limit else "The wagon has no cargo room. Drop supplies first.","members":active,"crew":crew,"kit":"wagon","days":1,"inventory":inventory,"stock":stock("foot"),"fresh":[],"pack_lb":used,"capacity_lb":limit,"working_lb":game.provisions.team_capacity(game.team_conditions.pulling(game.state)),"catch_lb":maxi(0,floori(limit-used)),"mounted":false,"return_mode":"ride","rider_lb":0.0,"tack_lb":0.0}
static func quote(game,members: Array,kit: String,days: int,bullets: int,return_mode: String="ride",activity: String="hunt") -> Dictionary:
 var result: Dictionary={"valid":false,"message":"Choose a healthy, willing outing party and real equipment."}
 if kit=="wagon":return wagon_quote(game,members)
 if return_mode not in RETURN_MODES:return result
 if activity not in ["hunt","fish"]:return result
 if kit not in KITS or days<1 or days>3 or bullets<(0 if activity=="fish" else 1) or bullets>30 or members.is_empty() or members.size()>5:return result
 var seen: Array=[]
 for id in members:
  if not game.crime.whole(id,0,game.party_health.members.size()-1) or int(id) in seen:return result
  var person: Dictionary=game.party_health.members[int(id)]
  if not game.party_health.is_active(person) or game.provisions.Carrying.factor(person,game.provisions.data.walking.health_load_curve)<=0 or not game.characters.willing(int(id),"forage" if activity=="fish" else "hunt"):return result
  if int(id)!=game.camp_tasks.leader_id(game) and game.camp_tasks.patient_nurses(game).has(int(id)):result.message="A patient receiving nursing must rest.";return result
  seen.append(int(id))
 var animals: Dictionary=stock(kit)
 for key in animals:
  if int(game.state.get(key,0))<int(animals[key]):result.message="The selected animal or tack is unavailable.";return result
 if kit!="foot" and game.Mounts.condition(game.state)<40:result.message="The animals are too worn for an outing.";return result
 var size: int=members.size()
 var rations: int=int(game.provisions.data.rations_lb[game.state.rations])
 # A same-day hunt can be a last attempt to obtain food. Pack only real stock;
 # a longer expedition still needs its meals, clothing and a reserve day.
 var requested_food: int=rations*size*(days+1)
 var food: int=mini(int(game.state.food),requested_food) if days==1 else requested_food
 var clothing: int=mini(int(game.state.clothing),size) if days==1 else size
 var inventory: Dictionary={}
 for key in game.provisions.data.weights_lb:inventory[key]=0
 inventory.food=food;inventory.clothing=clothing;inventory.bullets=bullets
 if int(game.state.food)<food or int(game.state.clothing)<clothing or int(game.state.bullets)<bullets:
  result.message="Not enough supplies for the selected ammunition or a longer trip with its reserve."
  return result
 var short_provisions: bool=food<requested_food or clothing<size
 var model=game.provisions.get_script().new()
 model.data=game.provisions.data.duplicate(true);model.fresh.assign(game.provisions.fresh.duplicate(true))
 # Actual tracked food is packed first, preserving its physical weight and expiry.
 model.fresh.sort_custom(func(a,b):return a.expires<b.expires)
 var carried: Array=[]
 var need: int=food
 for batch in model.fresh:
  var used: int=mini(need,int(batch.pounds))
  if used>0:
   var piece: Dictionary=batch.duplicate(true);piece.pounds=used;carried.append(piece)
   need-=used
 model.fresh.assign(carried)
 var pack: float=mass(game,members,kit,inventory,carried,animals,return_mode)
 var limit: float=capacity(game,members,kit,animals,return_mode)
 var normal: String="lead" if return_mode.begins_with("lead") else "ride"
 var working: float=capacity(game,members,kit,animals,normal)
 var profile: Dictionary=load_profile(game,members,kit,pack,animals,return_mode)
 var room: int=maxi(0,floori(limit-pack))
 result.merge(search_plan(game,members,kit,animals,return_mode,pack,-1,days>1),true)
 result.merge({"valid":room>0,"message":"Ready." if room>0 else "The outbound pack fills this party's carrying allowance.","short_provisions":short_provisions,"members":seen,"kit":kit,"days":days,"inventory":inventory,"stock":animals,"fresh":carried,"pack_lb":pack,"capacity_lb":limit,"working_lb":working,"catch_lb":room,"mounted":rides(kit),"return_mode":return_mode,"rider_lb":profile.rider_lb,"tack_lb":profile.tack_lb},true)
 return result
static func reserve(game,offer: Dictionary) -> void:
 if offer.kit=="wagon":return
 var selected: Array=[]
 offer["animal_conditions"]={"horses":[],"mules":[]}
 for kind in ["horses","mules"]:
  var n: int=int(offer.stock.get(kind,0))
  for i in range(n):
   if not game.team_conditions.record[kind].is_empty():
    var best: int=game.team_conditions.record[kind].find(game.team_conditions.record[kind].max())
    var health: int=game.team_conditions.record[kind][best]
    game.team_conditions.record[kind].remove_at(best)
    selected.append(health);offer.animal_conditions[kind].append(health)
 if not selected.is_empty():offer["condition"]=game.team_conditions.mean(selected)
 offer["condition_base"]=int(offer.get("condition",100))
 game.provisions.remove(int(offer.inventory.food))
 for key in offer.inventory:game.state[key]-=int(offer.inventory[key])
 for key in offer.stock:game.state[key]=int(game.state.get(key,0))-int(offer.stock[key])
 game.team_conditions.sync(game)
static func restore_stock(game,animals: Dictionary,condition: int,original: Dictionary={},base: int=100) -> void:
 var before: int=game.Mounts.animals(game.state)
 var incoming: int=int(animals.get("horses",0))+int(animals.get("mules",0))
 var current: int=game.Mounts.condition(game.state)
 for key in animals:game.state[key]=int(game.state.get(key,0))+int(animals[key])
 if incoming>0:
  for kind in ["horses","mules"]:
   for i in range(int(animals.get(kind,0))):game.team_conditions.record[kind].append(clampi(int(original[kind][i])+condition-base,0,100) if original.has(kind) and i<original[kind].size() else condition)
  game.team_conditions.sync(game)

static func wear(game,kit: String,size: int,habitat: String,load_ratio: float,allocated: Dictionary={},return_mode: String="ride") -> int:
 var inventory: Dictionary=transport(game,range(size),kit,allocated,return_mode)
 var base: int=int(game.context.data.regions[habitat].strain)+int(game.seasonal_pressure().working_strain)+int(game.survival.weather.get("ox_strain",0))
 return game.Mounts.wear(game.provisions.data.mounts,game.Mounts.plan(game.provisions.data.mounts,inventory),habitat,base,0,load_ratio)
