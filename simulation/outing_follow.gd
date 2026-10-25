extends RefCounted
const Actor=preload("res://simulation/outing_actor.gd")
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
 var outfit=game.field_outings.Outfit
 var mass: float=outfit.mass(game,trip.camp.guards,trip.kit,trip.camp.inventory,trip.camp.fresh,trip.stock,outfit.mode(trip))
 var plan: Dictionary=game.Mounts.plan(game.provisions.data.mounts,outfit.transport(game,trip.camp.guards,trip.kit,trip.stock,outfit.mode(trip)))
 var profile: Dictionary=outfit.load_profile(game,trip.camp.guards,trip.kit,mass,trip.stock,outfit.mode(trip))
 var base: float=game.Mounts.base_miles(game.provisions.data.mounts,int(trip.condition),0) if game.Mounts.mounted(plan) else float(game.provisions.data.walking.packing_miles_per_day)
 var terrain: String=str(game.route.nodes[trip.origin.from].get("terrain","plains"))
 var terrain_factor: float=0.8 if terrain=="mountains" else (0.9 if terrain=="forest" else 1.0)
 var miles: int=maxi(1,floori(base*game.Mounts.speed_factor(plan,profile)*float(game.survival.weather.speed)*terrain_factor*float(game.seasonal_pressure().travel)))
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
 var child=Actor.build(game,trip,random)
 child.state.landmark=crossing.place;child.state.next_landmark=crossing.place;child.state.leg_miles=0;child.state.leg_length=0
 child.state.travel_direction=crossing.heading;child.state.river_stage=crossing.stage
 if child.route_path[-1]!=crossing.place:child.route_path.append(crossing.place)
 child._arrive_landmark(true,false)
 var option: int=child.pending.choices.find_custom(func(choice):return choice.get("method","")=="horses")
 if option<0:option=child.pending.choices.find_custom(func(choice):return choice.get("method","") in ["swim","wade"])
 var before: int=child.journal.size()
 if option<0 or not child.choose(option):
  trip.camp.camp_log.append("The hunter could not find a usable crossing and waited on the bank.")
  return
 random.state=child.rng.state
 var actual: Dictionary=child.party_health.members[int(trip.member)]
 if child.last_crossing.get("mishap",false) and actual.alive and random.randf()<float(game.field_outings.rules.lone_crossing_drowning_chance):
  actual.health=0;actual.alive=false;actual.death_day=int(game.state.day);actual.cause="drowning at "+game.route.nodes[crossing.place].name
 for line in child.journal.slice(before):trip.camp.camp_log.append(str(line))
 Actor.sync(game,trip,child)
 if not actual.alive:
  Actor.lost(game,trip,"The lone hunter did not survive the crossing. Their animal and remaining outfit were lost.")
 else:
  if not trip.camp.has("crossed"):trip.camp["crossed"]={}
  trip.camp.crossed[str(crossing.place)+str(crossing.heading)]=true
  move_to(game,trip,child.CacheSupport.location(child),int(child.state.miles))
  Actor.lost_mount(game,trip)
 trip.camp.erase("crossing")
static func valid(camp: Dictionary,game) -> bool:
 if camp.has("combat_history") and not game.combat.valid(camp.combat_history,int(game.state.day),game.characters.profiles.size()):return false
 if camp.has("return_mode") and camp.return_mode not in game.field_outings.Outfit.RETURN_MODES:return false
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
