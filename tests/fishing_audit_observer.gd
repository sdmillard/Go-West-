extends "res://tests/mobile_camp_observer.gd"
var fishing_days: Array=[]
var launch: Dictionary={}
func _init(seed_value: int=1848,mode: String="classic",setup: bool=false,end_at: String=""):
 super(seed_value,mode,setup,end_at)
 fishing=preload("res://tests/fishing_audit_model.gd").new()
func start_fishing(kit: String) -> bool:
 var before: Dictionary={"day":int(state.day),"food":int(state.food),"bullets":int(state.bullets),"miles":int(state.miles),"party":int(state.party_size),"rations":int(state.rations)}
 var okay: bool=super.start_fishing(kit)
 if okay:
  launch=before
  launch.merge({"kit":kit,"site":hunt.field.site,"distance":hunt.field.distance,"casts_available":hunt.casts.size()})
 return okay
func finish_fishing() -> bool:
 if hunt.get("activity","")!="fish":return false
 var caught: int=int(hunt.meat);var casts: int=int(hunt.shots)
 var okay: bool=super.finish_fishing()
 if okay:
  var entry: Dictionary=launch.duplicate(true)
  entry.merge(last_hunt_recovery,true)
  entry.merge({"day_end":int(state.day),"casts_used":casts,"caught_edible_lb":caught,"party_food_delta":int(state.food)-int(launch.food),"bullets_delta":int(state.bullets)-int(launch.bullets),"miles_delta":int(state.miles)-int(launch.miles)})
  fishing_days.append(entry)
 launch={}
 return okay
