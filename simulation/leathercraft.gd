extends RefCounted
## Each physical item is a saved stage of work; no invisible detached project inventory.
var data: Dictionary=rules()
var worker: int=-1
var recipe: String=""
static func rules() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://data/leathercraft.json"))
static func items() -> Array:return ["hide_scraped","hide_softened","buckskin","glove_pieces","buckskin_gloves"]
static func is_good(item: String) -> bool:return item in items()
static func configure(model) -> bool:
 var value: Dictionary=rules()
 if not value.get("note") is String or not value.get("goods") is Dictionary or not value.get("recipes") is Dictionary:return false
 if value.goods.size()!=5 or value.recipes.size()!=2:return false
 for id in items():
  var row: Variant=value.goods.get(id)
  if not row is Dictionary or not row.get("label") is String or not (row.get("weight_lb") is int or row.get("weight_lb") is float) or not is_finite(row.weight_lb) or row.weight_lb<=0 or row.weight_lb>10:return false
  if row.has("sell_cents"):
   for key in ["sell_cents","post_demand","trader_demand"]:
    if not preload("res://simulation/pelts.gd").whole(row.get(key),1,10000):return false
 for id in ["tan_leather","make_gloves"]:
  var r: Variant=value.recipes.get(id)
  if not r is Dictionary or not r.get("label") is String or not r.get("steps") is Array or r.steps.size()!=(3 if id=="tan_leather" else 2):return false
  for step in r.steps:
   if not step is Dictionary or step.get("input") not in items()+["deer_hide"] or step.get("output") not in items() or not preload("res://simulation/pelts.gd").whole(step.get("amount"),1,10):return false
   var input_weight: float=float(model.data.weights_lb.deer_hide) if step.input=="deer_hide" else float(value.goods[step.input].weight_lb)
   if float(value.goods[step.output].weight_lb)*int(step.amount)>input_weight:return false
 for id in items():model.data.weights_lb[id]=float(value.goods[id].weight_lb)
 return true
func qualified(game,index: int) -> bool:return game.camp_tasks.specialist(game,index,"Leatherworking")
func next_step(inventory: Dictionary,job: String) -> Dictionary:
 if not data.recipes.has(job):return {}
 for step in data.recipes[job].steps:
  if int(inventory.get(step.input,0))>0:return step.duplicate()
 return {}
func reason(game,index: int,job: String) -> String:
 if index<0 or index>=game.party_health.members.size() or not game.party_health.is_active(game.party_health.members[index]):return "Traveler not available."
 var person: Dictionary=game.party_health.members[index]
 if not game.characters.willing(index,"repair"):return "Refuses this work at current trust or boundaries."
 if not qualified(game,index):return "Needs a Leatherworking background."
 if person.health<40 or person.conditions.any(func(c):return c.severity>=3):return "Too ill to work."
 if not data.recipes.has(job):return "Unknown leatherwork recipe."
 if game.current_edge().get("hazard","")=="river":return "Find a land camp before doing leatherwork."
 if job=="tan_leather" and game.on_dry_stretch():return "Hide dressing needs water; this is a waterless stretch."
 if next_step(game.state,job).is_empty():return "No suitable morning materials for this stage."
 return ""
func quote(game,index: int,job: String) -> Dictionary:
 var why: String=reason(game,index,job)
 var result: Dictionary={"valid":false,"message":why,"days":1}
 if not game.can_service():result.message="Stop and resolve the current event first.";return result
 if not why.is_empty():return result
 if game.camp_tasks.patient_nurses(game).has(index):result.message="This traveler is being nursed and must rest.";return result
 result.valid=true;result.step=next_step(game.state,job)
 result.message="One worker-day: 1 %s > %d %s. Party meals and normal wages still apply; other camp tasks continue." % [label_for(result.step.input),result.step.amount,label_for(result.step.output)]
 return result
func label_for(item: String) -> String:return data.goods.get(item,{}).get("label","Rough deer hide" if item=="deer_hide" else item)
func work(game,index: int,job: String) -> bool:
 if not quote(game,index,job).valid:return false
 worker=index;recipe=job
 game._tick_day(false,false,"leathercraft")
 worker=-1;recipe=""
 game.refresh_stop_offers()
 game._update_river_stage()
 if game.state.status=="traveling" and not game.crime.check_pursuit(game):game.crime.check_wanted(game)
 return true
func finish(game,index: int,step: Dictionary) -> void:
 if step.is_empty() or not game.party_health.is_active(game.party_health.members[index]) or int(game.state.get(step.input,0))<1:return
 game.state[step.input]=int(game.state.get(step.input,0))-1
 game.state[step.output]=int(game.state.get(step.output,0))+int(step.amount)
 game.supply_history.append({"day":int(game.state.day),"event":"leathercraft","worker":index,"changes":{step.input:-1,step.output:int(step.amount)}})
 game.journal.append("Day %d · %s worked leather: 1 %s > %d %s." % [game.state.day,game.party_health.members[index].name,label_for(step.input),step.amount,label_for(step.output)])
func rows(game,key: String,kind: String) -> Array:
 var result: Array=[]
 if kind not in ["post","traders"]:return result
 for item in data.goods:
  var r: Dictionary=data.goods[item];var held: int=int(game.state.get(item,0))
  if not r.has("sell_cents") or held<1:continue
  var sell_key: String=key+"|sell_"+item
  var left: int=maxi(0,int(r.post_demand if kind=="post" else r.trader_demand)-int(game.context.record.spent.get(sell_key+"|units",0)))
  result.append({"item":item,"label":r.label,"amount":1,"buy_cents":0,"sell_cents":int(r.sell_cents) if kind=="post" else floori(r.sell_cents*0.75),"can_buy":0,"can_sell":mini(held,left),"held":held,"buy_key":key+"|buy_"+item,"sell_key":sell_key,"sells":false,"buys":true})
 return result
func valid_inventory(inventory: Dictionary) -> bool:
 for item in items():
  if not preload("res://simulation/pelts.gd").whole(inventory.get(item,0),0,1000000):return false
 return true
