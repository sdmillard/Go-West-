extends "res://tests/fishing_audit_observer.gd"
var livestock_days: Array=[]
var purchases: Array=[]
var first_short: Dictionary={}
var deaths: Array=[]
var needed_units:=0
var short_units:=0.0
func _init(seed_value: int=1848,mode: String="classic",setup: bool=false,end_at: String=""):
 super(seed_value,mode,setup,end_at)
 livestock=preload("res://tests/livestock_balance_model.gd").new()
 provisions=preload("res://tests/livestock_balance_food.gd").new();provisions.carriers=party_health.members
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var required: int=int(state.party_size)*int(provisions.data.rations_lb[state.rations])
 var eaten: int=provisions.eaten_units
 var alive: Array=party_health.members.filter(func(m):return m.alive).map(func(m):return int(m.id))
 super._tick_day(resting,team_working,camp_action)
 var short: float=maxf(0,required-float(livestock.last_meal.get("eaten",int(provisions.eaten_units)-eaten)))
 needed_units+=required;short_units+=short
 if short>0 and first_short.is_empty():first_short={"day":int(state.day),"miles":int(state.miles),"food":int(state.food),"cash":state.money,"health":int(state.health),"short":short,"required":required}
 for m in party_health.members:
  if not m.alive and int(m.id) in alive:deaths.append({"id":int(m.id),"day":int(state.day),"miles":int(state.miles),"cause":str(m.cause)})
 if int(state.day)%7==0 or short>0:
  livestock_days.append({"day":int(state.day),"miles":int(state.miles),"food":int(state.food),"cash":state.money,"health":int(state.health),"party":int(state.party_size),"hunger":float(state.get("hunger_days",0)),"vitamin_gap":int(party_health.days_without_fresh),"fatigue":int(state.fatigue),"short":short,"milk_lb":float(livestock.last.get("milk_lb",0)),"care":float(livestock.last.get("care_factor",1)),"grain":int(state.get("poultry_feed",0))})
func counter_checkout(cart: Dictionary,venue: String="") -> bool:
 var quote: Dictionary=counter_quote(cart,venue)
 var before: int=state.day
 var okay: bool=super.counter_checkout(cart,venue)
 if okay:purchases.append({"day":int(state.day),"place":str(state.landmark),"cart":cart.duplicate(),"net_cents":int(quote.net_cents),"days":int(state.day)-before})
 return okay
