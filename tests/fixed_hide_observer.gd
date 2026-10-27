extends "res://simulation/trail_engine.gd"
## Read-only post-checkpoint receipts. Base finish_hunt never auto-selects pelts.
var crew_launch: Dictionary={}
var days: Array=[]
var sales: Array=[]
var harvested_after_fork: Dictionary={}
func finish_hunt(pelt_cart: Dictionary={}) -> bool:
 var okay: bool=super.finish_hunt(pelt_cart)
 if okay:
  for key in last_hunt_recovery.get("pelts",{}):harvested_after_fork[key]=int(harvested_after_fork.get(key,0))+int(last_hunt_recovery.pelts[key])
 return okay
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var requested: int=int(state.party_size)*int(provisions.data.rations_lb[state.rations])
 super._tick_day(resting,team_working,camp_action)
 days.append({"day":int(state.day),"action":camp_action,"requested":requested,"eaten":float(livestock.last_meal.get("eaten",0)),"party":int(state.party_size)})
func counter_checkout(cart: Dictionary,venue: String="") -> bool:
 var goods: Array=[]
 for row in trade_counter(venue).get("rows",[]):
  var n: int=-int(cart.get(row.item,0))
  if n>0 and (row.item in provisions.data.pelts.goods or income.is_keepsake(row.item) or leathercraft.is_good(row.item)):
   goods.append({"item":row.item,"quantity":n,"cents":roundi(float(n*int(row.sell_cents))/int(row.amount))})
 var before: int=int(state.day)
 var okay: bool=super.counter_checkout(cart,venue)
 if okay and not goods.is_empty():sales.append({"day":int(state.day),"days":int(state.day)-before,"place":str(state.landmark),"goods":goods})
 return okay
