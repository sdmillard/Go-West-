extends "res://simulation/livestock.gd"
var audit: Dictionary={"herd_days":0,"care_short_days":0,"care_hours":0.0,"care_budget":0.0,"feed_short_days":0,"feed_quarters":0,"milk_lb":0.0,"eggs":0,"food_generated":0,"unconverted_spoiled_lb":0.0,"unconverted_spoiled_kcal":0.0,"food_left":0,"condition_losses":{},"crossing_losses":{},"butchered":{}}
func tick(game,resting: bool,working: bool) -> void:
 var before: Dictionary={}
 for kind in ANIMALS:before[kind]=count(game.state,kind)
 if before.values().any(func(n):return int(n)>0):
  var offer: Dictionary=outlook(game,resting)
  audit.herd_days+=1;audit.care_hours+=float(offer.hours);audit.care_budget+=minf(float(offer.hours),float(offer.budget))
  if offer.care_factor<0.999:audit.care_short_days+=1
  if offer.feed_held<offer.feed_needed:audit.feed_short_days+=1
 for p in record.products:
  if int(p.expires)<=int(game.state.day):audit.unconverted_spoiled_lb+=float(p.lb);audit.unconverted_spoiled_kcal+=float(p.kcal)
 super.tick(game,resting,working)
 for kind in ANIMALS:audit.condition_losses[kind]=int(audit.condition_losses.get(kind,0))+maxi(0,int(before[kind])-count(game.state,kind))
 if not last.is_empty():
  audit.feed_quarters+=int(last.feed_quarters);audit.milk_lb+=float(last.milk_lb);audit.eggs+=int(last.eggs);audit.food_generated+=float(last.food)
func pack(game) -> void:
 var food: int=game.state.food
 super.pack(game)
 audit.food_left+=maxi(0,food-int(game.state.food))
func cross(game,result: Dictionary) -> void:
 var before: Dictionary={}
 for kind in ANIMALS:before[kind]=count(game.state,kind)
 super.cross(game,result)
 for kind in ANIMALS:audit.crossing_losses[kind]=int(audit.crossing_losses.get(kind,0))+maxi(0,int(before[kind])-count(game.state,kind))
func butcher(game,kind: String,by_hand: bool=false) -> bool:
 var okay: bool=super.butcher(game,kind,by_hand)
 if okay:audit.butchered[kind]=int(audit.butchered.get(kind,0))+1
 return okay

func meal(game,needed: int,vitamin_offset: float=0.0) -> Dictionary:
 var result: Dictionary=super.meal(game,needed,vitamin_offset)
 game.provisions.dairy_eaten+=float(result.dairy_eaten)
 return result
