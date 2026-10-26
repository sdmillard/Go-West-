extends "res://tests/income_balance_observer.gd"
## Correct the study-only pre-harvest food gate; include known recoverable meat.
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
    for item in basket:gross+=int(basket[item])*floori(int(provisions.data.pelts.goods[item].sell_cents)*0.75)
    var displaced: float=maxf(0,minf(haul,meat)-minf(maxf(0,haul-quote.raw_lb),meat))*density
    var estimated: float=gross-(meal+displaced)*price
    if estimated>margin:margin=estimated;best=basket
 if best.is_empty():skin_decisions["no_positive_estimated_margin"]=int(skin_decisions.get("no_positive_estimated_margin",0))+1
 return best
