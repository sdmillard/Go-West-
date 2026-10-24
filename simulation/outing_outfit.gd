extends RefCounted
## The same people/equipment/load calculation serves player and delegated hunts.
const KITS=["foot","ride_horse","pack_horse","ride_mule","pack_mule","horse_and_mule"]
static func stock(kit: String) -> Dictionary:
 var result: Dictionary={"horses":0,"mules":0,"saddles":0,"pack_saddles":0,"saddlebags":0}
 match kit:
  "ride_horse":result.horses=1;result.saddles=1;result.saddlebags=1
  "pack_horse":result.horses=1;result.pack_saddles=1
  "ride_mule":result.mules=1;result.saddles=1;result.saddlebags=1
  "pack_mule":result.mules=1;result.pack_saddles=1
  "horse_and_mule":result.horses=1;result.mules=1;result.saddles=1;result.saddlebags=1;result.pack_saddles=1
 return result
static func capacity(game,members: Array,kit: String) -> float:
 var people:=0.0
 for id in members:
  var person: Dictionary=id if id is Dictionary else game.party_health.members[int(id)]
  people+=float(game.hunting.data.carry_per_person_lb)*game.provisions.Carrying.factor(person,game.provisions.data.walking.health_load_curve)
 var inventory: Dictionary=stock(kit)
 inventory.merge({"vehicle":"foot","party_size":members.size()})
 var animals: float=game.Mounts.plan(game.provisions.data.mounts,inventory).animal_lb
 return minf(float(game.hunting.data.carry_limit),people+animals)
static func quote(game,members: Array,kit: String,days: int,bullets: int) -> Dictionary:
 var result: Dictionary={"valid":false,"message":"Choose a healthy, willing outing party and real equipment."}
 if kit not in KITS or days<1 or days>3 or bullets<1 or bullets>30 or members.is_empty() or members.size()>5:return result
 var seen: Array=[]
 for id in members:
  if not game.crime.whole(id,0,game.party_health.members.size()-1) or int(id) in seen:return result
  var person: Dictionary=game.party_health.members[int(id)]
  if not game.party_health.is_active(person) or game.provisions.Carrying.factor(person,game.provisions.data.walking.health_load_curve)<=0 or not game.characters.willing(int(id),"hunt"):return result
  if int(id)>0 and game.camp_tasks.patient_nurses(game).has(int(id)):result.message="A patient receiving nursing must rest.";return result
  seen.append(int(id))
 var animals: Dictionary=stock(kit)
 for key in animals:
  if int(game.state.get(key,0))<int(animals[key]):result.message="The selected animal or tack is unavailable.";return result
 if kit!="foot" and game.Mounts.condition(game.state)<40:result.message="The animals are too worn for an outing.";return result
 var size: int=members.size()
 var rations: int=int(game.provisions.data.rations_lb[game.state.rations])
 # One extra day's provisions is real reserve for a delayed return.
 var food: int=rations*size*(days+1)
 var inventory: Dictionary={}
 for key in game.provisions.data.weights_lb:inventory[key]=0
 inventory.food=food;inventory.clothing=size;inventory.bullets=bullets
 if int(game.state.food)<food or int(game.state.clothing)<size or int(game.state.bullets)<bullets:
  result.message="Not enough food, clothing or ammunition for this party and a one-day reserve."
  return result
 var model=game.provisions.get_script().new()
 model.data=game.provisions.data.duplicate(true);model.fresh.assign(game.provisions.fresh.duplicate(true))
 # Actual tracked food is packed first, preserving its physical weight and expiry.
 model.fresh.sort_custom(func(a,b):return a.expires<b.expires)
 var carried: Array=[]
 var need: int=food
 for batch in model.fresh:
  var used: int=mini(need,int(batch.pounds))
  if used>0:
   var piece: Dictionary=batch.duplicate(true);piece.pounds=used;carried.append(piece)
   need-=used
 model.fresh.assign(carried)
 inventory.merge({"vehicle":"foot","party_size":size})
 var pack: float=model.cargo(inventory)
 var limit: float=capacity(game,members,kit)
 var room: int=maxi(0,floori(limit-pack))
 result.merge({"valid":room>0,"message":"Ready." if room>0 else "The outbound pack fills this party's carrying allowance.","members":seen,"kit":kit,"days":days,"inventory":inventory,"stock":animals,"fresh":carried,"pack_lb":pack,"capacity_lb":limit,"catch_lb":room,"mounted":kit in ["ride_horse","ride_mule","horse_and_mule"]},true)
 inventory.erase("vehicle");inventory.erase("party_size")
 return result
static func reserve(game,offer: Dictionary) -> void:
 game.provisions.remove(int(offer.inventory.food))
 for key in offer.inventory:game.state[key]-=int(offer.inventory[key])
 for key in offer.stock:game.state[key]=int(game.state.get(key,0))-int(offer.stock[key])
static func restore_stock(game,animals: Dictionary,condition: int) -> void:
 var before: int=game.Mounts.animals(game.state)
 var incoming: int=int(animals.get("horses",0))+int(animals.get("mules",0))
 var current: int=game.Mounts.condition(game.state)
 for key in animals:game.state[key]=int(game.state.get(key,0))+int(animals[key])
 if incoming>0:game.state.horse_health=roundi(float(current*before+condition*incoming)/(before+incoming))

static func wear(game,kit: String,size: int,habitat: String,load_ratio: float) -> int:
 var inventory: Dictionary=stock(kit)
 inventory.merge({"vehicle":"foot","party_size":size})
 var base: int=int(game.context.data.regions[habitat].strain)+int(game.seasonal_pressure().working_strain)+int(game.survival.weather.get("ox_strain",0))
 return game.Mounts.wear(game.provisions.data.mounts,game.Mounts.plan(game.provisions.data.mounts,inventory),habitat,base,0,load_ratio)
