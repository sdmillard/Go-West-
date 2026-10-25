extends "res://tests/camp_balance_observer.gd"
var motion: Dictionary={"travel_attempt_days":0,"distance_progress_days":0,"away_travel_days":0,"moving_hunt_days":0,"moving_hunt_food_units":0,"moving_returned_food_units":0,"stationary_days":0,"camp_action_days":0,"multi_job_days":0,"support_during_hunts":0,"actions":{}}
func travel() -> bool:
 var mile: int=int(state.miles)
 var returned: int=int(field_outings.audit.returned_catch_units)
 var okay: bool=super.travel()
 motion.moving_returned_food_units+=int(field_outings.audit.returned_catch_units)-returned
 if int(state.miles)>mile:motion.distance_progress_days+=1
 return okay
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var moving: bool=field_outings.moving
 var away: bool=not field_outings.record.trips.is_empty()
 var before: Dictionary=camp_tasks.audit.duplicate(true)
 var shots: int=int(field_outings.audit.shots)
 var caught: int=int(field_outings.audit.meat_food)
 super._tick_day(resting,team_working,camp_action)
 if moving:
  motion.travel_attempt_days+=1
  if away:motion.away_travel_days+=1
  if int(field_outings.audit.shots)>shots:motion.moving_hunt_days+=1
  motion.moving_hunt_food_units+=int(field_outings.audit.meat_food)-caught
 else:motion.stationary_days+=1
 if not camp_action.is_empty():motion.camp_action_days+=1
 var label: String="travel" if moving else (camp_action if not camp_action.is_empty() else "event_or_other")
 motion.actions[label]=int(motion.actions.get(label,0))+1
 var jobs: int=int(camp_tasks.audit.nursing_visits)-int(before.nursing_visits)+int(camp_tasks.audit.drying_batches)-int(before.drying_batches)+int(camp_tasks.audit.forager_days)-int(before.forager_days)
 if jobs>=2:motion.multi_job_days+=1
 if camp_action=="hunt" and jobs>0:motion.support_during_hunts+=1
