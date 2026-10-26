extends "res://tests/dairy_balance_observer.gd"
## Read-only daily treatment history; never changes meals, disease, time or RNG.
var nutrition_trace: Array=[]
func people() -> Array:
 var result: Array=[]
 for m in party_health.members:
  result.append({"id":int(m.id),"active":party_health.is_active(m),"health":int(m.health),"gap":int(m.get("vitamin_days",party_health.days_without_fresh)),"scurvy":m.conditions.filter(func(c):return c.id=="scurvy").duplicate(true),"cause":str(m.get("cause",""))})
 return result
func produce() -> Dictionary:
 var result: Dictionary={"units":0,"vitamin_equivalent_lb":0.0}
 for b in provisions.fresh:
  if b.get("vitamin_c",false):
   result.units+=int(b.pounds);result.vitamin_equivalent_lb+=int(b.pounds)*float(b.get("vitamin_c_per_unit",provisions.mass_ratio(b)))
 return result
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var before: Array=people();var stock: Dictionary=produce();var size: int=state.party_size
 var loose: float=state.get("camp_greens_lb",0)
 super._tick_day(resting,team_working,camp_action)
 nutrition_trace.append({"day":int(state.day),"mile":int(state.miles),"region":context.region_id(self),"action":camp_action if not camp_action.is_empty() else ("travel" if team_working else "event"),"resting":resting,"party_before":size,"vitamin_target":size*float(provisions.data.foraging.vitamin_c_lb_per_person),"stock_before":stock,"stock_after":produce(),"loose_before":loose,"meal":livestock.last_meal.duplicate(true),"before":before,"after":people()})
