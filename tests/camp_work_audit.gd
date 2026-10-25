extends "res://simulation/camp_tasks.gd"
## Observe executed work, never manufacture benefits or charge an extra day.
var audit: Dictionary={"nursing_visits":0,"care_kits":0,"drying_batches":0,"food_processed":0,"food_retained":0,"salt_used":0,"forager_days":0,"rest_person_days":0}
func prepare(game) -> void:
 var previous: int=game.supply_history.size()
 super.prepare(game)
 for item in game.supply_history.slice(previous):
  if item.event=="camp_nursing":audit.nursing_visits+=1;audit.care_kits+=1
func finish(game) -> void:
 for job in day_plan.get("jobs",[]):
  if job.job=="forage" and game.party_health.is_active(game.party_health.members[int(job.member)]):audit.forager_days+=1
 for member in game.party_health.members:
  if game.party_health.is_active(member) and day_plan.get("rest",{}).get(int(member.id),false):audit.rest_person_days+=1
 var previous: int=game.supply_history.size()
 super.finish(game)
 for item in game.supply_history.slice(previous):
  if item.event=="camp_drying":
   audit.drying_batches+=1;audit.food_processed+=int(item.processed);audit.food_retained+=int(item.retained);audit.salt_used-=int(item.changes.salt)
