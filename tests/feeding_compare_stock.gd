extends "res://simulation/livestock.gd"
## Identical read-only instrumentation for pre/post mixed-feeding runtimes.
var audit: Dictionary={"herd_days":0,"care_short_days":0,"care_hours":0.0,"care_budget":0.0,"grain_lb":0.0,"fodder_lb":0.0,"scraps_kcal":0.0,"milk_lb":0.0,"eggs":0,"food_generated":0.0,"dairy_eaten":0.0,"meal_requested":0.0,"meal_eaten":0.0,"meal_short":0.0,"short_days":0,"raw_dairy_spoiled_kcal":0.0,"portion_spoiled_kcal":0.0,"table_left_kcal":0.0,"dairy_left_kcal":0.0,"condition_losses":{},"crossing_losses":{},"butchered":{}}
func feed_mass(game,kind: String) -> float:
 return int(game.state.get(kind,0))*(0.25 if kind=="poultry_feed" else 1.0)+float(game.state.get(kind+"_remainder_lb",0))
func dairy_kcal() -> float:return record.products.filter(func(p):return p.kind in ["milk","egg"]).reduce(func(n,p):return n+float(p.kcal),0.0)
func tick(game,resting: bool,working: bool) -> void:
 var held: Dictionary={}
 for kind in ANIMALS:held[kind]=count(game.state,kind)
 var grain: float=feed_mass(game,"poultry_feed");var fodder: float=feed_mass(game,"livestock_fodder")
 if held.values().any(func(n):return int(n)>0):
  var offer: Dictionary=outlook(game,resting)
  audit.herd_days+=1;audit.care_hours+=float(offer.hours);audit.care_budget+=minf(float(offer.hours),float(offer.budget))
  if float(offer.care_factor)<0.999:audit.care_short_days+=1
 for p in record.products:
  if int(p.expires)<=int(game.state.day):
   if p.kind in ["milk","egg"]:audit.raw_dairy_spoiled_kcal+=float(p.kcal)
   else:audit.portion_spoiled_kcal+=float(p.kcal)
 super.tick(game,resting,working)
 for kind in ANIMALS:audit.condition_losses[kind]=int(audit.condition_losses.get(kind,0))+maxi(0,int(held[kind])-count(game.state,kind))
 audit.grain_lb+=maxf(0,grain-feed_mass(game,"poultry_feed"));audit.fodder_lb+=maxf(0,fodder-feed_mass(game,"livestock_fodder"))
 if not last.is_empty():
  audit.food_generated+=float(last.food);audit.milk_lb+=float(last.milk_lb);audit.eggs+=int(last.eggs)
  audit.scraps_kcal+=float(last.get("feeding",{}).get("scraps_kcal",0))
func pack(game) -> void:
 var kcal: float=available_kcal();var dairy: float=dairy_kcal()
 super.pack(game)
 audit.table_left_kcal+=maxf(0,kcal-available_kcal());audit.dairy_left_kcal+=maxf(0,dairy-dairy_kcal())
func meal(game,needed: int,vitamin_offset: float=0.0) -> Dictionary:
 var result: Dictionary=super.meal(game,needed,vitamin_offset)
 audit.dairy_eaten+=float(result.dairy_eaten);audit.meal_requested+=needed;audit.meal_eaten+=float(result.eaten)
 var short: float=maxf(0,needed-float(result.eaten))
 audit.meal_short+=short
 if short>0.000000001:audit.short_days+=1
 game.provisions.dairy_eaten+=float(result.dairy_eaten)
 return result
func cross(game,result: Dictionary) -> void:
 var held: Dictionary={}
 for kind in ANIMALS:held[kind]=count(game.state,kind)
 super.cross(game,result)
 for kind in ANIMALS:audit.crossing_losses[kind]=int(audit.crossing_losses.get(kind,0))+maxi(0,int(held[kind])-count(game.state,kind))
func butcher(game,kind: String,by_hand: bool=false) -> bool:
 var okay: bool=super.butcher(game,kind,by_hand)
 if okay:audit.butchered[kind]=int(audit.butchered.get(kind,0))+1
 return okay
