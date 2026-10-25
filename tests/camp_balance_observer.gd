extends "res://tests/hunt_balance_observer.gd"
var forage_audit: Dictionary={"shared_calls":0,"shared_food":0,"shared_lb":0.0,"leader_calls":0,"leader_food":0,"leader_lb":0.0}
func _init(seed_value: int=1848,mode: String="classic",setup: bool=false,end_at: String=""):
 super(seed_value,mode,setup,end_at)
 camp_tasks=preload("res://tests/camp_work_audit.gd").new()
func _gather_forage(offer: Dictionary,shared: bool=false) -> void:
 var food: int=int(state.food)
 var loose: int=int(state.get("camp_greens_lb",0))
 super._gather_forage(offer,shared)
 var prefix: String="shared" if shared else "leader"
 forage_audit[prefix+"_calls"]+=1
 forage_audit[prefix+"_food"]+=int(state.food)-food
 forage_audit[prefix+"_lb"]+=(int(state.food)-food)*float(provisions.data.foraging.mass_ratio)+int(state.get("camp_greens_lb",0))-loose
