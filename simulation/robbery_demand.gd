extends RefCounted
## Pure demand preview; actual goods transfer stays inside the witnessed crime incident.
static var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/robbery_demands.json"))
const GOODS=["food","bullets","clothing","oxen","wheels","axles","tongues","medicine","salt","wagon","horses","mules","saddles","pack_saddles","saddlebags","rifles","shotguns","pistols","revolvers","knives","hatchets"]
const Armory=preload("res://simulation/armory.gd")
const ANIMALS=["horses","mules"]
## Places with goods to pick from; a gate or ferry is robbed of its cash box and passage instead.
const STOCKED=["store","fort","traders","emigrants","household"]
static func valid_rules(v: Variant) -> bool:
 if not v is Dictionary or not v.get("note") is String:return false
 for key in ["value_penalty","wagon_penalty","mount_penalty","theft_value_penalty","animal_noise"]:
  var n: Variant=v.get(key)
  if not (n is int or n is float) or not is_finite(n) or n<0 or n>1:return false
 return true
## A household's horses are the herd its visit sells, so taking one is counted against that herd.
static func prefix(game,place: String) -> String:
 if game.crime.household(place):return "herders:"+game.crime.node_of(place)
 return place if game.crime.rules(place).kind in ["traders","emigrants"] else "post:"+place
static func stock(game,place: String,initial: bool=false) -> Dictionary:
 var crime=game.crime
 var kind: String=crime.rules(place).kind
 var result: Dictionary={"cash_cents":int(crime.rules(place).cash_cents) if initial else int(crime.service(place).cash_cents),"food":crime.food_capacity(game,place) if initial else crime.food_left(game,place)}
 if kind not in STOCKED:return result
 if kind in ["traders","emigrants"] and not initial:
  var purse: Dictionary=game.context.barter_goods(game,place) if kind=="traders" else game.context.camp_goods(game,place)
  result.cash_cents=mini(int(result.cash_cents),game._purse_left(place,int(purse.purse_cents)))
 var raw: Dictionary={}
 if kind=="traders":raw=game.context.barter_goods(game,place).stock
 elif kind=="emigrants":raw=game.context.camp_goods(game,place).stock
 elif kind=="household":
  # Only the preserved provisions (above) and the visit's own herd; fresh and dried baskets are not loot yet.
  var herd: Dictionary=game.context.data.horse_traders.get(game.crime.node_of(place),{})
  if not herd.is_empty():raw["horses"]=int(herd.horses)
 else:
  for lot in game.survival.data.trade_lots:raw[lot.item]=mini(int(game.context.data.post_lots),int(lot.get("post_lots",game.context.data.post_lots)))*int(lot.amount)
 if kind in ["store","fort","emigrants"]:raw["wagon"]=1
 for item in raw:
  if item=="food" or item not in GOODS:continue
  var key: String=prefix(game,place)+"|buy_"+item
  var lot_amount:=1
  for lot in game.survival.data.trade_lots:
   if lot.item==item:lot_amount=int(lot.amount)
  var used: int=0 if initial else game._units_used(key,lot_amount)
  # A frame legitimately sold to this post is available there too.
  var extra: int=game.context.record.spent.get(prefix(game,place)+"|sell_wagon|units",0) if item=="wagon" else 0
  result[item]=maxi(0,int(raw[item])+extra-used)
  if item=="wagon":result[item]=mini(1,int(result[item]))
 return result
## What a quiet theft can carry off: the goods, but not the cash box or a wagon.
static func theft_stock(game,place: String,initial: bool=false) -> Dictionary:
 var result: Dictionary=stock(game,place,initial)
 result.erase("cash_cents")
 result.erase("wagon")
 return result if game.crime.rules(place).kind in STOCKED else {}
static func animals(basket: Dictionary) -> int:return int(basket.get("horses",0))+int(basket.get("mules",0))
static func price(game,item: String) -> float:
 if item=="cash_cents":return 1.0
 if item=="wagon":return float(game.provisions.data.replacement_wagon.price_cents)
 for good in game.outfitter.goods:
  if good.id==item:return float(good.price_cents)
  if item=="bullets" and good.id=="bullet_boxes":return float(good.price_cents)/20.0
 for lot in game.survival.data.trade_lots:
  if lot.item==item:return float(lot.buy_cents)/int(lot.amount)
 return 0.0
static func value(game,basket: Dictionary) -> float:
 var total:=0.0
 for item in basket:total+=float(basket[item])*price(game,item)
 return total
static func quote(game,basket: Dictionary,place: String="",action: String="robbery") -> Dictionary:
 var theft: bool=action=="theft"
 var result: Dictionary={"valid":false,"message":"Choose goods to take from what they have." if theft else "Choose a demand within the target's available goods."}
 if place=="":place=game.crime.target(game)
 if place=="" or basket.is_empty():return result
 var available:=theft_stock(game,place) if theft else stock(game,place)
 var selected: Dictionary={}
 for item in basket:
  if not available.has(item) or not game.crime.whole(basket[item],0,int(available[item])):return result
  if int(basket[item])>0:selected[item]=int(basket[item])
 if selected.is_empty():return result
 var after: Dictionary=game.state.duplicate(true)
 for item in selected:
  if item not in ["cash_cents","wagon"]:after[item]=int(after.get(item,0))+int(selected[item])
 if selected.get("wagon",0)>0:
  if not game.provisions.WagonTrade.apply_inventory(game,after,int(selected.wagon)):
   result.message="Each seized wagon needs an available driver. Leave someone to manage it.";return result
  game.Train.balance(after,game.Train.drivers(game),game.team_conditions.record.oxen)
  if int(after.oxen)<game.Train.count(after):
   result.message="Each wagon needs its own draft animal. Demand oxen with the wagon.";return result
 var cargo: float=game.provisions.cargo(after)
 var capacity: float=game.provisions.storage_capacity(after)
 var loot_mass:=0.0
 for item in selected:
  if game.provisions.data.weights_lb.has(item):loot_mass+=int(selected[item])*float(game.provisions.data.weights_lb[item])
  elif Armory.data.weights_lb.has(item):loot_mass+=int(selected[item])*float(Armory.data.weights_lb[item])
 # Theft is carried off quietly by hand; a holdup can load alongside the wagon where the place allows it.
 var alongside: bool=not theft and after.vehicle=="wagon" and game.crime.rules(place).wagon_access
 var haul_limit: float=game.hauling_capacity("robbery")
 if not alongside and loot_mass>haul_limit:
  result.message="Not enough fit, willing helpers to haul the requested loot (%.1f / %.1f lb). Reduce your demand." % [loot_mass,haul_limit]
  return result
 var ratio: float=value(game,selected)/maxf(1.0,value(game,available))
 var floor_: float=float(game.crime.modifiers.floor)
 var ceiling: float=float(game.crime.modifiers.ceiling)
 var fits: bool=cargo<=capacity
 if theft:
  # Taking more of what is there is likelier to be missed, and every animal led off is noise in the dark.
  var base: float=float(game.crime.odds(game,place).theft_success)
  var unseen: float=game.crime.bounded(base,base-float(data.theft_value_penalty)*ratio-float(data.animal_noise)*animals(selected),floor_,ceiling)
  result.merge({"valid":fits,"basket":selected,"value_cents":roundi(value(game,selected)),"unseen":unseen,"cargo_lb":cargo,"capacity_lb":capacity,"message":"Taking more makes it likelier someone notices. Witnesses and escape risks still apply." if fits else "The goods would exceed your carrying limit. Take less."},true)
  return result
 # Taking a family's or a trading party's last saddle and pack animals strands them; they fight harder for them.
 var stranding: bool=game.crime.rules(place).kind in ["traders","emigrants"] and animals(selected)>0 and animals(selected)>=animals(available)
 var chance: float=clampf(float(game.crime.odds(game,place).compliance)-float(data.value_penalty)*ratio-(float(data.wagon_penalty) if selected.get("wagon",0)>0 else 0.0)-(float(data.mount_penalty) if stranding else 0.0),floor_,ceiling)
 result.merge({"valid":fits,"basket":selected,"value_cents":roundi(value(game,selected)),"compliance":chance,"cargo_lb":cargo,"capacity_lb":capacity,"message":"A larger demand makes resistance more likely. Resistance, injury, capture and witnesses still apply." if fits else "The demanded goods would exceed your carrying limit. Reduce the demand or include an available wagon."},true)
 return result
static func start(game,basket: Dictionary,action: String="robbery") -> bool:
 if not game.pending.get("crime_menu",false) or not game.crime.incident().is_empty() or not game.crime.can_choose(game,action):return false
 if action=="theft" and theft_stock(game,game.crime.target(game)).is_empty():return false
 var offer:=quote(game,basket,"",action)
 if not offer.valid:return false
 game.pending[action+"_demand"]=offer.basket.duplicate(true)
 return game.crime.choose(game,action)
static func loot(game,current: Dictionary) -> Dictionary:
 var offer:=quote(game,current.demand,str(current.place),str(current.action))
 var basket: Dictionary=current.demand
 return {"food":int(basket.get("food",0)) if offer.valid else 0,"money":int(basket.get("cash_cents",0)) if offer.valid else 0,"goods":basket.duplicate(true) if offer.valid else {},"valid":offer.valid,"message":offer.message,"wagon_access":int(basket.get("wagon",0))>0 or game.state.vehicle=="wagon","haul_limit_lb":game.hauling_capacity("robbery")}
static func take(game,current: Dictionary,goods: Dictionary) -> void:
 var actual: Dictionary={}
 for item in goods:
  if item in ["food","cash_cents"]:continue
  var amount: int=goods[item]
  if amount<=0:continue
  if item=="wagon":
   game.provisions.WagonTrade.apply_inventory(game,game.state,amount)
  else:game.state[item]=int(game.state.get(item,0))+amount
  var key: String=prefix(game,str(current.place))+"|buy_"+item
  var lot_amount:=1
  for lot in game.survival.data.trade_lots:
   if lot.item==item:lot_amount=int(lot.amount)
  var used: int=game._units_used(key,lot_amount)+amount
  game.context.record.spent[key+"|units"]=used
  if item!="wagon":game.context.record.spent[key]=ceili(float(used)/lot_amount)
  actual[item]=amount
 if actual.get("wagon",0)>0:
  game.Train.balance(game.state,game.Train.drivers(game),game.team_conditions.record.oxen)
  game.team_conditions.sync(game)
 current["taken_goods"]=actual
 game.state.parts=int(game.state.wheels)+int(game.state.axles)+int(game.state.tongues)
 if current.action=="theft":game.journal.append("Day %d · Carried off unseen: %s." % [game.state.day,describe(actual)])
 else:game.journal.append("Day %d · Seized demanded goods: %s. The wagon's former owners can still resist your escape." % [game.state.day,describe(actual)])
static func describe(basket: Dictionary) -> String:
 var lines: Array[String]=[]
 var ordered: Array=basket.keys()
 ordered.sort()
 for item in ordered:
  if int(basket[item])<=0:continue
  if item=="cash_cents":lines.append("$%.2f" % (int(basket[item])/100.0))
  elif item in Armory.NAMES:lines.append("%d %s" % [basket[item],Armory.NAMES[item][0 if int(basket[item])==1 else 1]])
  else:lines.append("%d %s" % [basket[item],{"medicine":"care kits","clothing":"clothing sets","food":"food units","pack_saddles":"pack saddles"}.get(item,item)])
 return ", ".join(lines) if not lines.is_empty() else "nothing"
static func valid(game,current: Dictionary) -> bool:
 if not current.has("demand"):return not current.has("taken_goods")
 if current.action not in ["robbery","theft"] or not current.demand is Dictionary or current.demand.is_empty():return false
 var available:=theft_stock(game,str(current.place),true) if current.action=="theft" else stock(game,str(current.place),true)
 for item in current.demand:
  if not available.has(item) or not game.crime.whole(current.demand[item],1,int(available[item])):return false
 if int(current.food)>int(current.demand.get("food",0)) or int(current.cash_cents)>int(current.demand.get("cash_cents",0)):return false
 if current.has("taken_goods"):
  if not current.taken_goods is Dictionary or int(current.food)!=int(current.demand.get("food",0)) or int(current.cash_cents)!=int(current.demand.get("cash_cents",0)):return false
  var expected: Dictionary=current.demand.duplicate(true)
  expected.erase("food")
  expected.erase("cash_cents")
  if expected!=current.taken_goods:return false
 elif int(current.food)>0 or int(current.cash_cents)>0:return false
 return true
