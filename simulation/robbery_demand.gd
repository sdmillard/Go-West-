extends RefCounted
## Pure demand preview; actual goods transfer stays inside the witnessed crime incident.
static var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/robbery_demands.json"))
const GOODS=["food","bullets","clothing","oxen","wheels","axles","tongues","medicine","salt","wagon"]
static func valid_rules(v: Variant) -> bool:
 if not v is Dictionary or not v.get("note") is String:return false
 for key in ["value_penalty","wagon_penalty"]:
  var n: Variant=v.get(key)
  if not (n is int or n is float) or not is_finite(n) or n<0 or n>1:return false
 return true
static func prefix(game,place: String) -> String:return place if game.crime.rules(place).kind in ["traders","emigrants"] else "post:"+place
static func stock(game,place: String,initial: bool=false) -> Dictionary:
 var crime=game.crime
 var kind: String=crime.rules(place).kind
 var result: Dictionary={"cash_cents":int(crime.rules(place).cash_cents) if initial else int(crime.service(place).cash_cents),"food":crime.food_capacity(game,place) if initial else crime.food_left(game,place)}
 if kind not in ["store","fort","traders","emigrants"]:return result
 if kind in ["traders","emigrants"] and not initial:
  var purse: Dictionary=game.context.barter_goods(game,place) if kind=="traders" else game.context.camp_goods(game,place)
  result.cash_cents=mini(int(result.cash_cents),game._purse_left(place,int(purse.purse_cents)))
 var raw: Dictionary={}
 if kind=="traders":raw=game.context.barter_goods(game,place).stock
 elif kind=="emigrants":raw=game.context.camp_goods(game,place).stock
 else:
  for lot in game.survival.data.trade_lots:raw[lot.item]=int(game.context.data.post_lots)*int(lot.amount)
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
static func quote(game,basket: Dictionary,place: String="") -> Dictionary:
 var result: Dictionary={"valid":false,"message":"Choose a demand within the target's available goods."}
 if place=="":place=game.crime.target(game)
 if place=="" or basket.is_empty():return result
 var available:=stock(game,place)
 var selected: Dictionary={}
 for item in basket:
  if not available.has(item) or not game.crime.whole(basket[item],0,int(available[item])):return result
  if int(basket[item])>0:selected[item]=int(basket[item])
 if selected.is_empty():return result
 if selected.get("wagon",0)>0 and game.state.vehicle!="foot":
  result.message="You already have a wagon. This expedition cannot tow a second one."
  return result
 var after: Dictionary=game.state.duplicate(true)
 if selected.get("wagon",0)>0:
  after.vehicle="wagon"
  after.household_gear_lb=float(game.provisions.data.walking.personal_gear_lb_per_person)*int(after.party_size)
 for item in selected:
  if item not in ["cash_cents","wagon"]:after[item]=int(after.get(item,0))+int(selected[item])
 var cargo: float=game.provisions.cargo(after)
 var capacity: float=game.provisions.storage_capacity(after)
 var loot_mass:=0.0
 for item in selected:
  if game.provisions.data.weights_lb.has(item):loot_mass+=int(selected[item])*float(game.provisions.data.weights_lb[item])
 var alongside: bool=after.vehicle=="wagon" and game.crime.rules(place).wagon_access
 var haul_limit: float=game.hauling_capacity("robbery")
 if not alongside and loot_mass>haul_limit:
  result.message="Not enough fit, willing helpers to haul the requested loot (%.1f / %.1f lb). Reduce your demand." % [loot_mass,haul_limit]
  return result
 var ratio: float=value(game,selected)/maxf(1.0,value(game,available))
 var chance: float=clampf(float(game.crime.odds(game,place).compliance)-float(data.value_penalty)*ratio-(float(data.wagon_penalty) if selected.get("wagon",0)>0 else 0.0),float(game.crime.modifiers.floor),float(game.crime.modifiers.ceiling))
 result.merge({"valid":cargo<=capacity,"basket":selected,"value_cents":roundi(value(game,selected)),"compliance":chance,"cargo_lb":cargo,"capacity_lb":capacity,"message":"A larger demand makes resistance more likely. Resistance, injury, capture and witnesses still apply." if cargo<=capacity else "The demanded goods would exceed your carrying limit. Reduce the demand or include an available wagon."},true)
 return result
static func start(game,basket: Dictionary) -> bool:
 if not game.pending.get("crime_menu",false) or not game.crime.incident().is_empty() or not game.crime.can_choose(game,"robbery"):return false
 var offer:=quote(game,basket)
 if not offer.valid:return false
 game.pending["robbery_demand"]=offer.basket.duplicate(true)
 return game.crime.choose(game,"robbery")
static func loot(game,current: Dictionary) -> Dictionary:
 var offer:=quote(game,current.demand,str(current.place))
 var basket: Dictionary=current.demand
 return {"food":int(basket.get("food",0)) if offer.valid else 0,"money":int(basket.get("cash_cents",0)) if offer.valid else 0,"goods":basket.duplicate(true) if offer.valid else {},"valid":offer.valid,"message":offer.message,"wagon_access":int(basket.get("wagon",0))>0 or game.state.vehicle=="wagon","haul_limit_lb":game.hauling_capacity("robbery")}
static func take(game,current: Dictionary,goods: Dictionary) -> void:
 var actual: Dictionary={}
 for item in goods:
  if item in ["food","cash_cents"]:continue
  var amount: int=goods[item]
  if amount<=0:continue
  if item=="wagon":
   game.state.vehicle="wagon"
   game.state.household_gear_lb=float(game.provisions.data.walking.personal_gear_lb_per_person)*int(game.state.party_size)
  else:game.state[item]=int(game.state.get(item,0))+amount
  var key: String=prefix(game,str(current.place))+"|buy_"+item
  var lot_amount:=1
  for lot in game.survival.data.trade_lots:
   if lot.item==item:lot_amount=int(lot.amount)
  var used: int=game._units_used(key,lot_amount)+amount
  game.context.record.spent[key+"|units"]=used
  if item!="wagon":game.context.record.spent[key]=ceili(float(used)/lot_amount)
  actual[item]=amount
 current["taken_goods"]=actual
 game.state.parts=int(game.state.wheels)+int(game.state.axles)+int(game.state.tongues)
 game.journal.append("Day %d · Seized demanded goods: %s. The wagon's former owners can still resist your escape." % [game.state.day,describe(actual)])
static func describe(basket: Dictionary) -> String:
 var lines: Array[String]=[]
 var ordered: Array=basket.keys()
 ordered.sort()
 for item in ordered:
  if int(basket[item])<=0:continue
  if item=="cash_cents":lines.append("$%.2f" % (int(basket[item])/100.0))
  else:lines.append("%d %s" % [basket[item],{"medicine":"care kits","clothing":"clothing sets","food":"food units"}.get(item,item)])
 return ", ".join(lines) if not lines.is_empty() else "nothing"
static func valid(game,current: Dictionary) -> bool:
 if not current.has("demand"):return not current.has("taken_goods")
 if current.action!="robbery" or not current.demand is Dictionary or current.demand.is_empty():return false
 var available:=stock(game,str(current.place),true)
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
