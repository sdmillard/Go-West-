extends "res://tests/income_followup_observer.gd"
var hired:=false
var craft_income:=false
var opening_party: Dictionary={}
var crew_days: Array=[]
var crew_launch: Dictionary={}
var trade_sales: Array=[]
var day_costs: Array=[]
func depart(profession: String,names: Array,month: int,cart: Dictionary,customization: Dictionary={}) -> bool:
 characters.start(int(state.seed),names.size())
 var profiles: Array=characters.profiles.duplicate(true)
 for i in range(profiles.size()):
  profiles[i].specials=[];profiles[i].flaws=[]
 for i in range(1,5):profiles[i].skill=["Carpentry","Leatherworking","Hunting","Caregiving"][i-1]
 profiles[4].specials=["Haggler"]
 profiles[2].specials=["Veteran","Loyal"];profiles[2].flaws=["Proud"]
 var contracts: Dictionary={}
 if hired:
  profiles[2].specials.append("Mercenary")
  contracts["2"]={"wage_cents":characters.wage_quote(profiles[2]).daily_cents*7,"interval_days":7,"auto_pay":true}
 var okay: bool=super.depart(profession,names,month,cart,{"profiles":profiles,"contracts":contracts})
 if okay:opening_party={"profiles":characters.profiles.duplicate(true),"cash":state.money,"inventory":state.duplicate(true)}
 return okay
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var requested: int=int(state.party_size)*int(provisions.data.rations_lb[state.rations])
 var place: String=str(state.landmark)
 super._tick_day(resting,team_working,camp_action)
 var cost: Dictionary={"day":int(state.day),"action":camp_action,"requested":requested,"eaten":float(livestock.last_meal.get("eaten",0))}
 day_costs.append(cost)
 if camp_action=="settlement_work":
  var entry: Dictionary=crew_launch.duplicate(true)
  entry.merge(cost,true);entry.place=place;crew_days.append(entry)
func counter_checkout(cart: Dictionary,venue: String="") -> bool:
 var goods: Array=[]
 for row in trade_counter(venue).get("rows",[]):
  var n: int=-int(cart.get(row.item,0))
  if n>0 and (row.item in provisions.data.pelts.goods or income.is_keepsake(row.item) or leathercraft.is_good(row.item)):
   goods.append({"item":row.item,"quantity":n,"cents":roundi(float(n*int(row.sell_cents))/int(row.amount))})
 var before: int=int(state.day)
 var okay: bool=super.counter_checkout(cart,venue)
 if okay and not goods.is_empty():trade_sales.append({"day":int(state.day),"place":str(state.landmark),"venue":venue,"days":int(state.day)-before,"goods":goods})
 return okay
func skin_selection() -> Dictionary:
 var meal: int=int(state.party_size)*int(provisions.data.rations_lb[state.rations])
 if not use_income:return {}
 var why: String="cash_at_least_20" if float(state.money)>=20 else "considered"
 skin_decisions[why]=int(skin_decisions.get(why,0))+1
 if why!="considered":return {}
 var available: Dictionary=pelt_quote({}).available
 var best: Dictionary={};var margin:=0.0
 var price: float=5.0*float(context.region(self).price)
 var haul: float=hunting_capacity();var meat: float=float(hunt.get("meat",0));var density: float=hunt_calorie_density()/1000.0
 for bison in range(mini(2,int(available.bison_hide))+1):
  for deer in range(mini(5,int(available.deer_hide))+1):
   for rabbit in range(mini(5,int(available.rabbit_pelt))+1):
    var basket: Dictionary={"bison_hide":bison,"deer_hide":deer,"rabbit_pelt":rabbit}
    var quote: Dictionary=pelt_quote(basket)
    if not quote.valid or quote.selected==0:continue
    var carried: int=int(state.food)+int(hunt.get("field",{}).get("inventory",{}).get("food",0))
    var recovered: int=roundi(minf(maxf(0,haul-quote.raw_lb),meat)*density)
    if carried+recovered<meal*4:continue
    var gross:=0.0
    for item in basket:
     var price_cents: int=int(provisions.data.pelts.goods[item].sell_cents)
     if craft_income and item=="deer_hide" and party_health.is_active(party_health.members[2]):price_cents=int(leathercraft.data.goods.buckskin_gloves.sell_cents)*4
     gross+=int(basket[item])*floori(price_cents*0.75)
    var displaced: float=maxf(0,minf(haul,meat)-minf(maxf(0,haul-quote.raw_lb),meat))*density
    var estimated: float=gross-(meal+displaced)*price
    if estimated>margin:margin=estimated;best=basket
 if best.is_empty():skin_decisions["no_positive_estimated_margin"]=int(skin_decisions.get("no_positive_estimated_margin",0))+1
 return best
