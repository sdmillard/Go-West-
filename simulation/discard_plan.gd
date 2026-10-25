extends RefCounted
## Exact, side-effect-free preview, using the same batch order as actual discards.
static func quote(game,cart: Dictionary) -> Dictionary:
 var inventory: Dictionary=game.state.duplicate(true)
 var model=game.provisions.get_script().new()
 model.data=game.provisions.data.duplicate(true)
 model.fresh.assign(game.provisions.fresh.duplicate(true))
 var original: float=model.cargo(inventory)
 var result: Dictionary={"valid":false,"selected":0,"before_lb":original,"after_lb":original,"dropped_lb":0.0,"capacity_lb":game.provisions.storage_capacity(game.state),"message":"Choose how much to drop."}
 for item in cart:
  var amount: Variant=cart[item]
  if (item not in model.data.weights_lb and item not in game.Mounts.TACK and item!="camp_greens_lb") or not (amount is int or amount is float) or not is_finite(float(amount)) or amount!=floor(amount) or amount<0 or amount>int(inventory.get(item,0)):
   result.message="Enter whole quantities within the supplies you have."
   return result
  if item in game.Mounts.TACK and int(amount)>game.Mounts.loose_tack(game.provisions.data.mounts,game.state)[item]:return result
  inventory[item]=int(inventory.get(item,0))-int(amount)
  result.selected+=int(amount)
  if item=="food":model.remove(int(amount))
 result.after_lb=model.cargo(inventory)
 result.dropped_lb=snappedf(original-float(result.after_lb),0.1)
 result.valid=result.selected>0 and game.can_service()
 if result.selected>0:result.message="Selected supplies are lost permanently. No day passes."
 return result
static func stock(game) -> Array:
 var rows: Array=[]
 var titles: Dictionary={"food":"Food units","clothing":"Clothing sets","bullets":"Bullets","wheels":"Spare wheels","axles":"Spare axles","tongues":"Spare tongues","medicine":"Care kits","salt":"Salt (lb)"}
 for item in game.provisions.data.weights_lb:
  var amount: int=int(game.state.get(item,0))
  var mass: float=amount*float(game.provisions.data.weights_lb[item])
  if item=="food":mass+=game.provisions.tracked_mass(amount)-game.provisions.tracked_food(amount)
  rows.append({"id":item,"label":titles.get(item,str(item)),"amount":amount,"mass_lb":snappedf(mass,0.1),"unit_lb":mass/amount if amount>0 else float(game.provisions.data.weights_lb[item]),"average":item=="food" and not game.provisions.fresh.is_empty()})
 var loose: Dictionary=game.Mounts.loose_tack(game.provisions.data.mounts,game.state)
 for key in loose:
  var unit: float=float(game.provisions.data.mounts[{"saddles":"riding_tack_lb","pack_saddles":"pack_tack_lb","saddlebags":"loose_bags_lb"}[key]])
  if loose[key]>0:rows.append({"id":key,"label":"Loose "+str(key).replace("_"," "),"amount":int(loose[key]),"mass_lb":loose[key]*unit,"unit_lb":unit,"average":false})
 if int(game.state.get("camp_greens_lb",0))>0:rows.append({"id":"camp_greens_lb","label":"Loose greens","amount":int(game.state.camp_greens_lb),"mass_lb":float(game.state.camp_greens_lb),"unit_lb":1.0,"average":false})
 return rows
