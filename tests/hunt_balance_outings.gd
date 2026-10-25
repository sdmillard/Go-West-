extends "res://simulation/field_outings.gd"
## Private data is observed for reports, never supplied to the player policy.
var audit: Dictionary={"shots":0,"meat_food":0,"meat_lb":0.0,"returned_catch_units":0,"catch_left_units":0,"net_condition_loss":0,"mount_losses":0,"deaths":0,"days_away":0}
func _hunt(game,trip: Dictionary,random) -> bool:
 var food: int=trip.camp.inventory.food
 var bullets: int=trip.camp.inventory.bullets
 var okay: bool=super._hunt(game,trip,random)
 var units: int=maxi(0,int(trip.camp.inventory.food)-food)
 audit.shots+=bullets-int(trip.camp.inventory.bullets)
 audit.meat_food+=units
 if units>0:audit.meat_lb+=units*game.provisions.mass_ratio(trip.camp.fresh.back())
 return okay
func tick(game) -> void:
 var before: Array=[]
 for trip in record.trips:before.append({"trip":trip,"condition":int(trip.condition),"animals":game.Mounts.animals(trip.stock),"alive":trip.camp.guards[0].alive,"day":int(trip.camp.camp_day)})
 super.tick(game)
 for item in before:
  var trip: Dictionary=item.trip
  audit.net_condition_loss+=maxi(0,int(item.condition)-int(trip.condition))
  audit.mount_losses+=maxi(0,int(item.animals)-game.Mounts.animals(trip.stock))
  if item.alive and not trip.camp.guards[0].alive:audit.deaths+=1
  audit.days_away+=maxi(0,int(trip.camp.camp_day)-int(item.day))
func _return(game,trip: Dictionary) -> void:
 var caught: int=trip.camp.fresh.filter(func(b):return b.get("_outing_catch",false)).reduce(func(n,b):return n+int(b.pounds),0)
 var previous: int=game.supply_history.size()
 super._return(game,trip)
 for row in game.supply_history.slice(previous):
  if row.event=="outing_return":
   audit.catch_left_units+=int(row.catch_lost)
   audit.returned_catch_units+=caught-int(row.catch_lost)
 # Delivered catch excludes the amount left behind at actual reunion.
