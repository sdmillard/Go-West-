extends RefCounted
## Mounted return navigation; isolated crossings use the actual river engine.
static func route_path(game,trip: Dictionary) -> Array:
 var hunter: Array=trip.origin.path.duplicate()
 if trip.origin.from!=trip.origin.to:hunter.append(trip.origin.to)
 var wagon: Array=game.travelled_path().duplicate()
 if game.state.next_landmark!=game.state.landmark:wagon.append(str(game.state.next_landmark))
 for i in range(mini(hunter.size(),wagon.size())):
  if hunter[i]!=wagon[i]:return []
 return hunter if hunter.size()>wagon.size() else wagon
static func point(game,path: Array,mile: int) -> Dictionary:
 var total:=0
 for i in range(path.size()-1):
  var length: int=int(game.route.edge_between(path[i],path[i+1]).miles)
  if mile<=total+length:return {"from":path[i],"to":path[i+1],"offset":mile-total,"path":path.slice(0,i+1)}
  total+=length
 return {"from":path[-1],"to":path[-1],"offset":0,"path":path.duplicate()}
static func move_to(game,trip: Dictionary,at: Dictionary,mile: int) -> void:
 trip.origin=at;trip.mile=mile;trip.camp.location=at.duplicate(true)
 trip.camp.habitat=game.route.nodes[at.from].get("hunting_region","plains")
static func advance(game,trip: Dictionary,random) -> String:
 var path: Array=route_path(game,trip)
 if path.is_empty():return "lost"
 var target: int=int(game.state.miles)
 var current: int=int(trip.mile)
 var west: bool=target>=current
 var food=game.provisions.get_script().new();food.data=game.provisions.data;food.fresh.assign(trip.camp.fresh)
 var load: Dictionary=trip.camp.inventory.duplicate();load.merge({"vehicle":"foot","party_size":1})
 var ratio: float=food.cargo(load)/maxf(1,game.field_outings.Outfit.capacity(game,trip.camp.guards,trip.kit,trip.stock))
 var miles: int=maxi(1,floori(game.Mounts.base_miles(game.provisions.data.mounts,int(trip.condition),0)*clampf(1.0-0.4*ratio,0.5,1.0)))
 var finish: int=mini(target,current+miles) if west else maxi(target,current-miles)
 var milestones: Array=[]
 var total:=0
 for i in range(path.size()):
  if i>0:total+=int(game.route.edge_between(path[i-1],path[i]).miles)
  milestones.append({"node":path[i],"mile":total,"index":i})
 if not west:milestones.reverse()
 for mark in milestones:
  var distance: int=int(mark.mile)
  if distance<mini(current,finish) or distance>maxi(current,finish):continue
  var node: Dictionary=game.route.nodes[mark.node]
  var crossed: Dictionary=trip.camp.get("crossed",{})
  var key: String=str(mark.node)+("west" if west else "east")
  var crossing: bool=node.kind=="river" and not crossed.get(key,false)
  if distance==current:crossing=crossing and ((west and trip.origin.to==mark.node and trip.origin.from!=mark.node) or (not west and trip.origin.from==mark.node))
  if crossing:
   var at: Dictionary=point(game,path,distance)
   if not west and int(mark.index)<path.size()-1:at={"from":mark.node,"to":path[int(mark.index)+1],"offset":0,"path":path.slice(0,int(mark.index)+1)}
   move_to(game,trip,at,distance)
   var stage: String="high" if random.randf()<game.survival.river_high_chance(int(game.calendar().month),node.get("river_source","rain")) else "low"
   trip.camp["crossing"]={"place":mark.node,"heading":"west" if west else "east","stage":stage}
   trip.camp.camp_log.append("Day %d: Reached %s; a river crossing is needed before following." % [game.state.day,node.name])
   return "crossing"
  if west and node.next.size()>1 and distance<int(game.state.miles):
   if not trip.camp.has("forks"):trip.camp["forks"]={}
   if not trip.camp.forks.has(mark.node):
    var follows: bool=random.randf()<float(game.field_outings.rules.fork_follow_chance)
    trip.camp.forks[mark.node]=follows
    if not follows:
     move_to(game,trip,point(game,path,distance),distance);trip.camp["wrong_turn"]=true
     trip.camp.camp_log.append("Day %d: Lost the wagon's trail at %s and returned to the fork to wait." % [game.state.day,node.name])
     return "lost"
 if finish==target:return "joined"
 move_to(game,trip,point(game,path,finish),finish)
 return "moving"
static func cross(game,trip: Dictionary,random) -> void:
 if not trip.camp.has("departure_kit"):trip.camp["departure_kit"]=trip.kit
 var crossing: Dictionary=trip.camp.crossing
 var child=load("res://simulation/trail_engine.gd").new(int(random.randi()),"classic",true)
 child.depart("banker",["One","Two","Three","Four","Five"],5,{"wagon":0,"food":0})
 child.state=game.state.duplicate(true)
 child.party_health.members.assign(game.party_health.members.duplicate(true))
 for person in child.party_health.members:person["guarding"]=true;person.erase("away")
 var actual: Dictionary=trip.camp.guards[0].duplicate(true)
 child.party_health.members[int(trip.member)]=actual
 child.characters.profiles.assign(game.characters.profiles.duplicate(true))
 child.state.day=int(game.state.day)-1;child.state.party_size=1;child.state.health=actual.health
 child.state.vehicle="foot";child.state.oxen=0;child.state.ox_health=100;child.state.money=0
 child.state.household_gear_lb=float(trip.camp.household_gear_lb);child.state.miles=int(trip.mile)
 for field in ["hunger_days","camp_greens_lb","camp_greens_expires","remains_lb","east_arrival"]:child.state.erase(field)
 if trip.camp.has("hunger_days"):child.state.hunger_days=trip.camp.hunger_days
 for good in trip.camp.inventory:child.state[good]=int(trip.camp.inventory[good])
 for good in trip.stock:child.state[good]=int(trip.stock[good])
 child.state.horse_health=int(trip.condition);child.state.rations=int(trip.camp.camp_rations);child.state.pace=0
 child.state.landmark=crossing.place;child.state.next_landmark=crossing.place;child.state.leg_miles=0;child.state.leg_length=0
 child.state.travel_direction=crossing.heading;child.state.river_stage=crossing.stage
 child.route_path=trip.origin.path.duplicate()
 if child.route_path[-1]!=crossing.place:child.route_path.append(crossing.place)
 child.provisions.fresh.assign(trip.camp.fresh.duplicate(true));child.provisions.carriers=child.party_health.members
 child.party_health.days_without_fresh=int(trip.camp.camp_deficiency)
 child.party_health.daily_onset_chance=game.party_health.daily_onset_chance
 child.survival.forced_weather=game.survival.forced_weather;child.rng.state=random.state
 child._arrive_landmark(true,false)
 var option: int=child.pending.choices.find_custom(func(choice):return choice.get("method","")=="horses")
 if option<0:option=child.pending.choices.find_custom(func(choice):return choice.get("method","") in ["swim","wade"])
 var before: int=child.journal.size()
 if option<0 or not child.choose(option):
  trip.camp.camp_log.append("The hunter could not find a usable crossing and waited on the bank.")
  return
 random.state=child.rng.state;actual=child.party_health.members[int(trip.member)]
 if child.last_crossing.get("mishap",false) and actual.alive and random.randf()<float(game.field_outings.rules.lone_crossing_drowning_chance):
  actual.health=0;actual.alive=false;actual.death_day=int(game.state.day);actual.cause="drowning at "+game.route.nodes[crossing.place].name
 for line in child.journal.slice(before):trip.camp.camp_log.append(str(line))
 trip.camp.guards[0]=actual.duplicate(true)
 for good in trip.camp.inventory:trip.camp.inventory[good]=int(child.state.get(good,0))
 trip.camp.fresh=child.provisions.fresh.duplicate(true);trip.camp.camp_deficiency=child.party_health.days_without_fresh
 if child.state.has("hunger_days"):trip.camp.hunger_days=child.state.hunger_days
 else:trip.camp.erase("hunger_days")
 for good in trip.stock:trip.stock[good]=int(child.state.get(good,0))
 trip.condition=game.Mounts.condition(child.state)
 if not actual.alive:
  for good in trip.camp.inventory:trip.camp.inventory[good]=0
  trip.camp.fresh=[];trip.camp.household_gear_lb=0
  trip.stock=game.field_outings.Outfit.stock("foot");trip.kit="foot"
  trip.camp["return_failed"]=true;trip.stage="stranded"
  trip.camp.camp_log.append("The lone hunter did not survive the crossing. Their animal and remaining outfit were lost.")
 else:
  if not trip.camp.has("crossed"):trip.camp["crossed"]={}
  trip.camp.crossed[str(crossing.place)+str(crossing.heading)]=true
  move_to(game,trip,child.CacheSupport.location(child),int(child.state.miles))
  if game.Mounts.animals(trip.stock)==0:trip.kit="foot";trip.stock=game.field_outings.Outfit.stock("foot");trip.stage="stranded"
 trip.camp.erase("crossing")
static func valid(camp: Dictionary,game) -> bool:
 if camp.has("departure_kit") and camp.departure_kit not in game.field_outings.Outfit.KITS:return false
 if camp.has("return_after_day") and not game.crime.whole(camp.return_after_day,0,int(game.state.day)+1):return false
 for field in ["wrong_turn","return_failed","missing_notified"]:
  if camp.has(field) and not camp[field] is bool:return false
 for field in ["crossed","forks"]:
  if not camp.has(field):continue
  if not camp[field] is Dictionary or camp[field].size()>100:return false
  for key in camp[field]:
   if not key is String or not camp[field][key] is bool:return false
   if field=="crossed" and camp[field][key]!=true:return false
   if field=="forks" and camp[field][key]==false and not camp.get("wrong_turn",false):return false
   if field=="forks":
    if not game.route.nodes.has(key) or game.route.nodes[key].next.size()<2:return false
   else:
    var node: String=key.trim_suffix("west").trim_suffix("east")
    if not game.route.nodes.has(node) or game.route.nodes[node].kind!="river" or key not in [node+"west",node+"east"]:return false
 if camp.has("crossing"):
  var crossing: Variant=camp.crossing
  if not crossing is Dictionary or crossing.size()!=3 or not game.route.nodes.has(crossing.get("place")) or game.route.nodes[crossing.place].kind!="river" or crossing.get("stage") not in ["low","high"] or crossing.get("heading") not in ["west","east"]:return false
  var at: Dictionary=camp.location
  if crossing.heading=="west" and (at.to!=crossing.place or int(at.offset)!=int(game.route.edge_between(at.from,at.to).get("miles",-1))):return false
  if crossing.heading=="east" and (at.from!=crossing.place or int(at.offset)!=0):return false
 return true
