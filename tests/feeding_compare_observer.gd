extends "res://tests/livestock_balance_observer.gd"
var feeding_samples: Array=[]
func _init(seed_value: int=1848,mode: String="classic",setup: bool=false,end_at: String=""):
 super(seed_value,mode,setup,end_at)
 livestock=preload("res://tests/feeding_compare_stock.gd").new()
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var old_deaths: int=deaths.size()
 super._tick_day(resting,team_working,camp_action)
 if int(state.day)%7!=0 and float(livestock.last_meal.get("eaten",0))>=float(livestock.last_meal.get("needed",0)) and deaths.size()==old_deaths:return
 feeding_samples.append({"day":int(state.day),"mile":int(state.miles),"food":int(state.food),"table_units":livestock.available_kcal()/1000.0,"cash":state.money,"health":int(state.health),"party":int(state.party_size),"hunger":float(state.get("hunger_days",0)),"vitamin_gap":int(party_health.days_without_fresh),"region":context.region_id(self),"weather":state.weather,"action":camp_action if not camp_action.is_empty() else ("travel" if team_working else "event"),"meal":livestock.last_meal.duplicate(true),"feeding":livestock.last.get("feeding",{}).duplicate(true),"animals":livestock.record.animals.duplicate(true)})
