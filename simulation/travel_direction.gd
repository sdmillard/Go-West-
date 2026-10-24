extends RefCounted
## Positions retain their west-to-east graph representation; heading changes movement.
static func heading(game) -> String:return str(game.state.get("travel_direction","west"))
static func remember(game) -> void:
 if not game.state.has("trail_history"):game.state["trail_history"]={}
 var path: Array=game.travelled_path()
 for index in range(path.size()-1):
  var edge: Dictionary=game.route.edge_between(path[index],path[index+1])
  game.state.trail_history[path[index]+">"+path[index+1]]=int(edge.miles)
 if game.state.next_landmark!="" and game.state.next_landmark!=game.state.landmark:
  var key: String=game.state.landmark+">"+game.state.next_landmark
  game.state.trail_history[key]=maxi(int(game.state.trail_history.get(key,0)),int(game.state.leg_miles))
static func can_turn(game,to: String) -> bool:
 if to not in ["east","west"] or not game.can_service():return false
 # The Columbia river branch models downstream rafting, not an upstream road.
 if to=="east" and game.current_edge().get("hazard","")=="river":return false
 if to=="east" and game.pending.has("landmark"):
  var path: Array=game.travelled_path()
  if path.size()>1 and game.route.edge_between(path[-2],path[-1]).get("hazard","")=="river":return false
 return true
static func turn(game,to: String) -> bool:
 if not can_turn(game,to) or heading(game)==to:return false
 remember(game)
 if not game.wagon_cache.is_empty() and not game.wagon_cache.has("location"):
  var old_cache:=cache_position(game)
  if not old_cache.is_empty():game.wagon_cache["location"]=old_cache
 var stopped: bool=game.pending.has("landmark")
 if stopped and not game.pending.has("approach_direction"):game.pending["approach_direction"]=heading(game)
 game.state["travel_direction"]=to
 game.journal.append("Day %d · Turned %s. Returning along the trail costs ordinary days, meals and crossings." % [game.state.day,to])
 if stopped:game._arrive_landmark(true,false)
 return true
static func next_east(game) -> void:
 var path: Array=game.travelled_path().duplicate()
 if path.size()<2:
  end_east(game)
  return
 var from: String=path[-2]
 var to: String=path[-1]
 var edge: Dictionary=game.route.edge_between(from,to)
 path.pop_back()
 game.route_path=path
 game.state.landmark=from
 game.state.next_landmark=to
 game.state.leg_length=int(edge.miles)
 game.state.leg_miles=int(edge.miles)
 game.state.terrain=game.route.nodes[from].get("terrain","plains")
 game.state.river_stage=""
static func end_east(game) -> void:
 game._tick_day(false,true)
 if game.state.status!="traveling":return
 game.state.status="returned_east"
 game.state.landmark=game.route.start
 game.state.next_landmark=""
 game.state.leg_length=0
 game.state.leg_miles=0
 game.state.miles=0
 game.route_path=[game.route.start]
 game.pending={}
 game.journal.append("The party decided to go back east.")
static func adapt_stop(game,menu: Dictionary,approach: String) -> void:
 var east: bool=heading(game)=="east"
 var node: Dictionary=game.route.nodes[game.state.landmark]
 menu["approach_direction"]=approach
 var retreat: bool=heading(game)!=approach
 if node.kind=="river" and not retreat:return
 # Turning away before crossing a river does not make you cross it first.
 var options: Array=menu.choices.filter(func(c):return c.get("action","") not in ["leave","cross"])
 var choice: Dictionary={"action":"leave"}
 if east:
  var path: Array=game.travelled_path()
  choice.label="Continue east beyond Independence" if path.size()<2 else "Head east toward "+game.route.nodes[path[-2]].name
  if not retreat and node.has("toll_dollars"):
   var toll: float=(0.0 if game.state.vehicle=="foot" else float(node.toll_dollars))+float(node.get("toll_per_ox",0))*int(game.state.oxen)
   choice.label+=" · toll $%.2f" % toll
   choice.requires={"money":toll}
   choice.effects={"money":-toll}
 elif node.kind=="river":
  choice.label="Turn back west without crossing again"
 else:
  if retreat and node.has("toll_dollars"):
   menu["retreat_without_crossing"]=true
   for option in menu.choices:
    if option.get("action","")=="leave":
     option.erase("requires")
     option.erase("effects")
     option.label="Turn back west"
  return
 options.push_front(choice)
 menu.choices=options
 if retreat:menu["retreat_without_crossing"]=true
static func cache_position(game) -> Dictionary:
 if game.wagon_cache.is_empty():return {}
 var cache: Dictionary=game.wagon_cache
 if cache.has("location"):return cache.location
 # Older cache saves only had mileage; use the road actually taken.
 var path: Array=game.travelled_path().duplicate()
 if game.state.next_landmark!="" and game.state.next_landmark!=path[-1]:path.append(game.state.next_landmark)
 var base:=0
 for index in range(path.size()-1):
  var edge: Dictionary=game.route.edge_between(path[index],path[index+1])
  if int(cache.mile)<=base+int(edge.miles):return {"from":path[index],"to":path[index+1],"offset":int(cache.mile)-base,"path":path.slice(0,index+1)}
  base+=int(edge.miles)
 return {}
static func clamp_at_cache(game,distance: int) -> int:
 if game.wagon_cache.is_empty():return distance
 var at:=cache_position(game)
 if at.is_empty() or at.from!=game.state.landmark or at.to!=game.state.next_landmark:return distance
 var gap: int=(int(game.state.leg_miles)-int(at.offset)) if heading(game)=="east" else (int(at.offset)-int(game.state.leg_miles))
 return mini(distance,gap) if gap>0 else distance
static func at_cache(game) -> bool:
 var at:=cache_position(game)
 if at.is_empty():return false
 if at.from==game.state.landmark and at.to==game.state.next_landmark and int(at.offset)==int(game.state.leg_miles):return true
 var edge: Dictionary=game.route.edge_between(at.from,at.to)
 var cache_node: String=at.from if int(at.offset)==0 else (at.to if int(at.offset)==int(edge.miles) else "")
 var here: String=str(game.state.landmark) if game.state.next_landmark==game.state.landmark or int(game.state.leg_miles)==0 else (str(game.state.next_landmark) if int(game.state.leg_miles)==int(game.state.leg_length) else "")
 return cache_node!="" and cache_node==here
static func cache_notice(game) -> bool:
 if not at_cache(game):return false
 game.pending={"id":"cache_reached","title":"The wagon's last camp","text":"You have reached the abandoned wagon's map marker. Inspect or repack it through Supplies before moving on.","choices":[{"label":"Stop here","effects":{},"result":"The party stops at the wagon's last camp."}]}
 return true
static func valid_state(s: Dictionary,route) -> bool:
 if s.has("travel_direction") and s.travel_direction not in ["east","west"]:return false
 if s.has("east_arrival") and not s.east_arrival is bool:return false
 if s.has("trail_history"):
  if not s.trail_history is Dictionary or s.trail_history.size()>100:return false
  for key in s.trail_history:
   if not key is String or key.get_slice_count(">")!=2:return false
   var edge: Dictionary=route.edge_between(key.get_slice(">",0),key.get_slice(">",1))
   var amount: Variant=s.trail_history[key]
   if edge.is_empty() or not (amount is int or amount is float) or not is_finite(amount) or amount!=floor(amount) or amount<0 or amount>int(edge.miles):return false
 return true
