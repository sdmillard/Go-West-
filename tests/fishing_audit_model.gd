extends "res://simulation/fishing.gd"
## Observe actual companion returns, without extra random draws or stock changes.
var returns: Array=[]
func camp_catch(game,index: int) -> Dictionary:
 var result: Dictionary=super.camp_catch(game,index)
 returns.append({"day":int(game.state.day),"member":index,"mass":float(result.mass),"food":int(result.food),"left":float(result.get("left",0)),"retrieved_kcal":float(result.get("retrieved_kcal",0))})
 return result
