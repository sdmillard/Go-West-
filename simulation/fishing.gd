extends RefCounted
## Seeded fishing activity and conservative access to river stops on the current leg.
var data: Dictionary={}
var error: String=""
func _init() -> void:
 load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/fishing.json")))
func load_data(value: Variant) -> bool:
 data={};error="Invalid fishing rules."
 if not value is Dictionary or not value.get("note") is String:return false
 for key in ["foot_radius","horse_radius","foot_mph","horse_mph","day_hours","duration","max_casts","bite_seconds","wait_min","wait_max","bite_chance","worker_hook_chance","kcal_per_lb","cold_factor"]:
  if not (value.get(key) is int or value.get(key) is float) or not is_finite(float(value[key])) or value[key]<=0:return false
 if value.foot_radius>value.horse_radius or value.wait_min>value.wait_max or value.bite_chance>1 or value.worker_hook_chance>1 or value.cold_factor>1 or value.max_casts!=floor(value.max_casts) or value.max_casts>20 or value.duration>120 or value.bite_seconds>value.duration:return false
 if not value.get("edible_lb") is Array or value.edible_lb.size()!=2:return false
 for amount in value.edible_lb:
  if not (amount is int or amount is float) or not is_finite(float(amount)) or amount<1 or amount>100 or amount!=floor(amount):return false
 if value.edible_lb[0]>value.edible_lb[1]:return false
 if not value.get("species") is Dictionary or value.species.is_empty() or not value.get("profiles") is Dictionary or value.profiles.is_empty() or not value.get("sites") is Dictionary or value.sites.is_empty():return false
 for id in value.species:
  var fish: Variant=value.species[id]
  if not fish is Dictionary or not fish.get("label") is String or not fish.get("nutrition_note") is String:return false
  for key in ["whole_lb","large_lb"]:
   if not fish.get(key) is Array or fish[key].size()!=2:return false
   for weight in fish[key]:
    if not number(weight) or weight<0.25 or weight>100 or not is_equal_approx(float(weight)*4,roundf(float(weight)*4)):return false
   if fish[key][0]>fish[key][1]:return false
  if fish.large_lb[0]<fish.whole_lb[1]:return false
  for key in ["large_chance","edible_fraction","kcal_per_lb"]:
   if not number(fish.get(key)):return false
  if fish.large_chance<0 or fish.large_chance>1 or fish.edible_fraction<=0 or fish.edible_fraction>1 or fish.kcal_per_lb<=0 or fish.kcal_per_lb>5000:return false
 for id in value.profiles:
  var profile: Variant=value.profiles[id]
  if not profile is Dictionary or not profile.get("label") is String or not monthly(profile.get("monthly_bite_factor")) or not profile.get("species") is Dictionary or profile.species.is_empty():return false
  for species in profile.species:
   var choice: Variant=profile.species[species]
   if not value.species.has(species) or not choice is Dictionary or not number(choice.get("weight")) or choice.weight<=0 or not monthly(choice.get("months")):return false
  for month in range(12):
   if profile.species.values().all(func(choice):return float(choice.months[month])==0):return false
 for site in value.sites:
  if not site is String or not value.profiles.has(value.sites[site]):return false
 data=value.duplicate(true);error=""
 return true
func number(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value))
func monthly(value: Variant) -> bool:
 return value is Array and value.size()==12 and value.all(func(v):return number(v) and v>=0 and v<=4)
func pool(site: String,month: int) -> Array:
 if data.is_empty() or not data.sites.has(site) or month<1 or month>12:return []
 var result: Array=[]
 var profile: Dictionary=data.profiles[data.sites[site]]
 for id in profile.species:
  var choice: Dictionary=profile.species[id]
  var weight: float=float(choice.weight)*float(choice.months[month-1])
  if weight>0:result.append({"id":id,"label":data.species[id].label,"weight":weight})
 return result
func seasonal_factor(site: String,month: int) -> float:
 return float(data.profiles[data.sites[site]].monthly_bite_factor[month-1]) if not data.is_empty() and data.sites.has(site) and month>=1 and month<=12 else 0.0
func access(game) -> Dictionary:
 var result: Dictionary={"visible":false,"walk":false,"horse":false,"distance":INF,"site":"","name":""}
 if data.is_empty() or not game.state.extended_route or game.state.status!="traveling":return result
 var here: Dictionary=game.CacheSupport.location(game)
 var edge: Dictionary=game.route.edge_between(here.from,here.to)
 if edge.get("hazard","") in ["river","waterless"]:return result
 var length: int=int(edge.get("miles",0))
 for pair in [[here.from,int(here.offset)],[here.to,maxi(0,length-int(here.offset))]]:
  if data.sites.has(pair[0]) and game.route.nodes[pair[0]].kind=="river" and float(pair[1])<float(result.distance):
   result.distance=float(pair[1]);result.site=pair[0];result.name=game.route.nodes[pair[0]].name
 var weather: String=str(game.survival.weather.id)
 if weather in ["blizzard","snow","thunderstorm"]:return result
 result.walk=result.distance<=float(data.foot_radius)
 result.horse=result.distance<=float(data.horse_radius) and int(game.state.get("horses",0))>0 and int(game.state.get("saddles",0))>0 and game.Mounts.condition(game.state)>=40
 result.visible=result.walk or result.horse
 return result
func quote(game,kit: String) -> Dictionary:
 var available: Dictionary=access(game)
 var fail: Dictionary={"valid":false,"message":"No fishable riverbank within reach with that transport."}
 if not game.can_service() or kit not in ["foot","ride_horse_light"]:return fail
 if (kit=="foot" and not available.walk) or (kit!="foot" and not available.horse):return fail
 var leader: int=game.camp_tasks.leader_id(game)
 if leader<0:return fail
 var offer: Dictionary=game.field_outings.Outfit.quote(game,[leader],kit,1,0,"ride","fish")
 if not offer.valid:return offer
 var speed: float=float(data.foot_mph if kit=="foot" else data.horse_mph)
 var hours: float=maxf(0,float(data.day_hours)-2.0*float(available.distance)/speed)
 offer.merge({"site":available.site,"site_name":available.name,"distance":available.distance,"fishing_hours":hours,"casts":maxi(1,floori(float(data.max_casts)*hours/float(data.day_hours)))})
 return offer
func begin(seed_value: int,outing: int,offer: Dictionary,month: int) -> Dictionary:
 var rng:=RandomNumberGenerator.new()
 rng.seed=seed_value+719*outing+1821377
 var casts: Array=[]
 var site: String=str(offer.get("site","wakarusa"))
 var available: Array=pool(site,month)
 var chance: float=clampf(float(data.bite_chance)*seasonal_factor(site,month),0,1)
 for index in range(int(offer.casts)):
  var wait: float=rng.randf_range(float(data.wait_min),float(data.wait_max))
  var bite: bool=not available.is_empty() and rng.randf()<chance
  var cast: Dictionary={"wait":wait,"bite":bite,"mass":0.0,"whole_lb":0.0,"label":"fish","kcal_per_lb":0.0,"species":""}
  if not available.is_empty():
   var total: float=available.reduce(func(n,item):return n+float(item.weight),0.0)
   var roll: float=rng.randf()*total
   var id: String=available.back().id
   for item in available:
    roll-=float(item.weight)
    if roll<=0:id=item.id;break
   var species: Dictionary=data.species[id]
   var limits: Array=species.large_lb if rng.randf()<float(species.large_chance) else species.whole_lb
   var whole: float=float(rng.randi_range(roundi(float(limits[0])*4),roundi(float(limits[1])*4)))/4.0
   cast.merge({"species":id,"label":species.label,"whole_lb":whole,"mass":float("%.6f" % (whole*float(species.edible_fraction))),"kcal_per_lb":float(species.kcal_per_lb)},true)
  casts.append(cast)
 return {"activity":"fish","field":offer,"casts":casts,"cast":0,"phase":"ready","phase_time":0.0,"elapsed":0.0,"ended":false,"message":"Click CAST. Wait for BITE, then click STRIKE!","shots":0,"meat":0.0,"animals":[],"targets":[],"catch_log":[]}
func tick(activity: Dictionary,delta: float) -> void:
 if activity.ended or not is_finite(delta) or delta<=0:return
 var remaining: float=minf(delta,maxf(0,float(data.duration)-float(activity.elapsed)))
 activity.elapsed+=remaining
 # Split at each transition so large frame steps cannot extend a bite window.
 while remaining>0 and not activity.ended:
  if activity.phase=="ready":break
  var limit: float=float(activity.casts[activity.cast].wait) if activity.phase=="waiting" else float(data.bite_seconds)
  var step: float=minf(remaining,maxf(0,limit-float(activity.phase_time)))
  activity.phase_time+=step;remaining-=step
  if activity.phase_time<limit:break
  if activity.phase=="waiting" and activity.casts[activity.cast].bite:
   activity.phase="bite";activity.phase_time=0.0;activity.message="BITE! Click STRIKE!"
  else:
   activity.message="The fish got away." if activity.phase=="bite" else "No bite this cast."
   next_cast(activity)
 if activity.elapsed>=float(data.duration):activity.ended=true;activity.message="Time to return to camp."
func next_cast(activity: Dictionary) -> void:
 activity.cast+=1;activity.phase="ready";activity.phase_time=0.0
 if activity.cast>=activity.casts.size():activity.ended=true;activity.message+=" Return to camp."
func click(activity: Dictionary) -> bool:
 if activity.is_empty() or activity.ended:return false
 if activity.phase=="ready":
  activity.phase="waiting";activity.phase_time=0.0;activity.shots+=1;activity.message="Wait for a bite..."
  return true
 if activity.phase=="bite":
  var cast: Dictionary=activity.casts[activity.cast]
  var mass: float=float(cast.mass)
  activity.targets.append(activity.animals.size())
  activity.animals.append({"kind":0,"meat":mass,"kcal_per_lb":float(cast.get("kcal_per_lb",data.kcal_per_lb))})
  activity.meat+=mass
  if not activity.has("catch_log"):activity.catch_log=[]
  activity.catch_log.append({"species":str(cast.get("species","")),"label":str(cast.get("label","fish")),"whole_lb":float(cast.get("whole_lb",mass)),"edible_lb":mass})
  activity.message="You caught a %s! (%.2f lbs)" % [str(cast.get("label","fish")),float(cast.get("whole_lb",mass))]
 else:activity.message="Struck too soon. Nothing hooked."
 next_cast(activity)
 return true

func camp_catch(game,index: int) -> Dictionary:
 var available: Dictionary=access(game)
 if not available.walk:return {"mass":0,"food":0}
 var hours: float=float(data.day_hours)-2.0*float(available.distance)/float(data.foot_mph)
 var offer: Dictionary={"site":available.site,"casts":maxi(1,floori(float(data.max_casts)*hours/float(data.day_hours)))}
 var activity: Dictionary=begin(int(game.state.seed)+index*3121,int(game.state.day),offer,int(game.calendar().month))
 var rng:=RandomNumberGenerator.new()
 rng.seed=int(game.state.seed)+index*4237+int(game.state.day)*7919
 var caught:=0.0;var calories:=0.0
 for cast in activity.casts:
  if cast.bite and rng.randf()<float(data.worker_hook_chance):caught+=float(cast.mass);calories+=float(cast.mass)*float(cast.kcal_per_lb)
 var carrying: float=float(game.hunting.data.carry_per_person_lb)*game.provisions.Carrying.factor(game.party_health.members[index],game.provisions.data.walking.health_load_curve)
 var room: float=maxf(0,game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state))
 var mass: float=minf(caught,maxf(0,minf(carrying,room)))
 var density: float=calories/caught if caught>0 else 0.0
 var units: int=game.provisions.add_meat(mass,int(game.state.day),density,false)
 game.state.food+=units
 return {"mass":mass if units>0 else 0.0,"retrieved":mass,"food":units,"left":caught-(mass if units>0 else 0.0),"retrieved_kcal":mass*density}
