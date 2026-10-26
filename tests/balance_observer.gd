extends "res://simulation/trail_engine.gd"
## Test-only observation of actual daily ticks, never a parallel survival model.
var audit: Dictionary={"days":0,"working_days":0,"rest_days":0,"other_days":0,"underfed_days":0,"vitamin_days":0,"scurvy_person_days":0,"max_vitamin_gap":0,"illness_person_days":0}
var last_underfed: int=-1
func _change_health(delta: int,cause: String) -> void:
 if cause=="lack of food" and int(state.day)!=last_underfed:
  audit.underfed_days+=1
  last_underfed=int(state.day)
 super._change_health(delta,cause)
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var meal_target: float=int(state.party_size)*float(provisions.data.foraging.vitamin_c_lb_per_person)
 super._tick_day(resting,team_working,camp_action)
 audit.days+=1
 audit["rest_days" if resting else ("working_days" if team_working else "other_days")]+=1
 if (float(livestock.last_meal.get("vitamin",0))>=meal_target if state.extended_route else party_health.days_without_fresh==0):audit.vitamin_days+=1
 audit.max_vitamin_gap=maxi(int(audit.max_vitamin_gap),int(party_health.days_without_fresh))
 for member in party_health.members:
  if not party_health.is_active(member):continue
  if member.conditions.any(func(c):return c.id=="scurvy"):audit.scurvy_person_days+=1
  if member.conditions.any(func(c):return party_health.conditions[c.id].kind=="illness"):audit.illness_person_days+=1
