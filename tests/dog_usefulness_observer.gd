extends "res://simulation/trail_engine.gd"
## Read-only measurements around actual engine actions; no rule or outcome overrides.
var dog_kcal:=0.0
var dog_days:=0
var fit_hunt_days:=0
var fit_watch_days:=0
var warnings:=0
var dog_injuries:=0
var encounters: Dictionary={}
var hunts: Array=[]
var hunt_open: Dictionary={}
func _tick_day(resting: bool,team_working: bool=false,camp_action: String="") -> void:
 var day_before: int=state.day
 var first_journal: int=journal.size()
 var fit_hunt: bool=dogs.ready("hunt");var fit_watch: bool=dogs.ready("watch")
 super._tick_day(resting,team_working,camp_action)
 if state.day>day_before and int(dogs.last.get("day",-1))==int(state.day):
  dog_kcal+=float(dogs.last.eaten_kcal);dog_days+=1
  if fit_hunt:fit_hunt_days+=1
  if fit_watch:fit_watch_days+=1
func start_hunt(outfit: Dictionary={}) -> bool:
 if not super.start_hunt(outfit):return false
 hunt_open={"day":int(state.day),"dog":hunt.has("dog"),"located":bool(hunt.get("dog_located_game",false)),"initial_animals":hunt.animals.size()}
 return true
func finish_hunt(pelt_cart: Dictionary={}) -> bool:
 if hunt.is_empty():return false
 var row: Dictionary=hunt_open.duplicate(true)
 row.merge({"raw_lb":int(hunt.meat),"rabbit_lb":int(hunt.get("dog_rabbit_lb",0)),"elapsed":float(hunt.elapsed),"dog_attempt":hunt.get("dog_checked",false),"rabbit_opportunities":hunt.get("dog_seen_rabbits",[]).size(),"shots":int(hunt.shots)},true)
 var condition: float=float(dogs.record.dog.get("condition",0))
 if not super.finish_hunt(pelt_cart):return false
 row["stored_lb"]=float(last_hunt_recovery.get("mass",0));row["stored_units"]=int(last_hunt_recovery.get("food",0));row["human_hunt_meal_units"]=float(last_hunt_recovery.get("eaten_food",0));row["left_lb"]=float(last_hunt_recovery.get("left",0))
 if row.get("dog",false) and condition-float(dogs.record.dog.get("condition",0))>=20:dog_injuries+=1
 hunts.append(row);hunt_open={};return true
func _present_trail_event(event: Dictionary) -> void:
 encounters[event.id]=int(encounters.get(event.id,0))+1
 var first: int=journal.size()
 super._present_trail_event(event)
 # Event generation takes place after the day tick, so count these notices here.
 for index in range(first,journal.size()):
  if journal[index].contains("barks at movement") and not journal[index].contains("\n"):warnings+=1
