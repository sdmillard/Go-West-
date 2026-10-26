extends "res://tests/dairy_balance_observer.gd"
## Study-only income decisions plus read-only receipts. Production rules stay unchanged.
var use_income:=false
var income_sales: Array=[]
var income_days: Array=[]
var pelt_recoveries: Array=[]
var skin_decisions: Dictionary={}
var sale_ticks: Array=[]
var recording_sale:=false
func depart(profession: String,names: Array,month: int,cart: Dictionary,customization: Dictionary={}) -> bool:
 var chosen: Dictionary=customization.duplicate(true)
 if chosen.is_empty():
  characters.start(int(state.seed),names.size())
  chosen={"profiles":characters.profiles.duplicate(true),"contracts":{}}
 chosen.keepsakes=[true,true,true,true,true]
 return super.depart(profession,names,month,cart,chosen)
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var requested: int=int(state.party_size)*int(provisions.data.rations_lb[state.rations])
 var place: String=str(state.landmark)
 super._tick_day(resting,team_working,camp_action)
 if recording_sale:sale_ticks.append({"day":int(state.day),"requested":requested,"eaten":float(livestock.last_meal.get("eaten",0))})
 if camp_action=="settlement_work":income_days.append({"worker":income.worker,"standing_job":camp_tasks.job(income.worker).job,"day":int(state.day),"place":place,"requested":requested,"eaten":float(livestock.last_meal.get("eaten",0)),"short":maxf(0,requested-float(livestock.last_meal.get("eaten",0)))})
func counter_checkout(cart: Dictionary,venue: String="") -> bool:
 var receipts: Array=[]
 for row in trade_counter(venue).get("rows",[]):
  var count: int=int(cart.get(row.item,0))
  if count<0 and (row.item in provisions.data.pelts.goods or income.is_keepsake(row.item)):
   receipts.append({"item":row.item,"quantity":-count,"cents":roundi(float(-count*int(row.sell_cents))/int(row.amount))})
 var before: int=int(state.day)
 recording_sale=not receipts.is_empty();sale_ticks=[]
 var okay: bool=super.counter_checkout(cart,venue)
 recording_sale=false
 if okay and not receipts.is_empty():income_sales.append({"day":int(state.day),"place":str(state.landmark),"venue":venue,"days":int(state.day)-before,"goods":receipts,"ticks":sale_ticks.duplicate(true)})
 return okay
func skin_selection() -> Dictionary:
 var meal: int=int(state.party_size)*int(provisions.data.rations_lb[state.rations])
 if not use_income:return {}
 var why: String="cash_at_least_20" if float(state.money)>=20 else ("fewer_than_four_meals" if int(state.food)<meal*4 else ("October_or_later" if int(calendar().month)>=10 else "considered"))
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
    var gross:=0.0
    for item in basket:gross+=int(basket[item])*floori(int(provisions.data.pelts.goods[item].sell_cents)*0.75)
    var displaced: float=maxf(0,minf(haul,meat)-minf(maxf(0,haul-quote.raw_lb),meat))*density
    var estimated: float=gross-(meal+displaced)*price
    if estimated>margin:margin=estimated;best=basket
 if best.is_empty():skin_decisions["no_positive_estimated_margin"]=int(skin_decisions.get("no_positive_estimated_margin",0))+1
 return best
func finish_hunt(pelt_cart: Dictionary={}) -> bool:
 var basket: Dictionary=skin_selection() if pelt_cart.is_empty() and not hunt.is_empty() else pelt_cart
 var quote: Dictionary=pelt_quote(basket)
 var day: int=int(state.day)
 var baseline_haul: float=minf(hunting_capacity(),float(hunt.get("meat",0)))
 var okay: bool=super.finish_hunt(basket)
 if okay and not basket.is_empty():pelt_recoveries.append({"day_start":day,"day_end":int(state.day),"selected":basket,"raw_haul_displaced_lb":maxf(0,baseline_haul-float(last_hunt_recovery.retrieved)),"quote":quote,"recovery":last_hunt_recovery.duplicate(true)})
 return okay
