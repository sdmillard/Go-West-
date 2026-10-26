extends RefCounted
## Exact edible table products alongside the existing whole-unit staple/meat inventory.
## An uneaten part of the final whole serving remains physical food, never calorie credit.
static func serve(game,needed: int,vitamin_offset: float=0.0) -> Dictionary:
 var stock=game.livestock
 var provisions=game.provisions
 var unit: float=provisions.data.food_energy.unit_kcal
 var remaining: float=needed*unit
 var vitamin:=vitamin_offset
 var ordinary:=0
 var dairy:=0.0
 var hunt_fraction:=0.0
 stock.hunt_portion={}
 # Keep the established shared produce serving ahead of milk/meat.
 var target: float=int(game.state.party_size)*float(provisions.data.foraging.vitamin_c_lb_per_person)
 var vegetables:=0
 var planned:=vitamin
 for batch in provisions.fresh:
  if not batch.get("vitamin_c",false) or planned>=target:continue
  var per_unit: float=batch.get("vitamin_c_per_unit",provisions.mass_ratio(batch))
  var take: int=mini(int(batch.pounds),ceili((target-planned)/per_unit))
  vegetables+=take;planned+=take*per_unit
 vegetables=mini(mini(vegetables,needed),int(game.state.food))
 if vegetables>0:
  vitamin=provisions.eat(vegetables,int(game.state.party_size),int(game.state.food),vitamin)
  game.state.food-=vegetables;ordinary+=vegetables;remaining-=vegetables*unit
 stock.record.products.sort_custom(func(a,b):return a.expires<b.expires)
 for p in stock.record.products:
  if remaining<=0.000000001:break
  var used: float=minf(remaining,float(p.kcal))
  var fraction: float=used/float(p.kcal)
  if p.kind in ["milk","egg"]:dairy+=used
  var nutrient: float=float(p.get("vitamin_c_lb",0))*fraction
  vitamin+=nutrient
  p.lb*=1.0-fraction;p.kcal-=used
  if p.has("vitamin_c_lb"):p.vitamin_c_lb-=nutrient
  remaining=maxf(0,remaining-used)
 stock.record.products=stock.record.products.filter(func(p):return float(p.kcal)>0.000000001)
 var whole: int=mini(int(game.state.food),ceili(maxf(0,remaining-0.000000001)/unit))
 if whole>0:
  vitamin=provisions.eat(whole,int(game.state.party_size),int(game.state.food),vitamin)
  game.state.food-=whole;ordinary+=whole
  var excess: float=maxf(0,whole*unit-remaining)
  remaining=maxf(0,remaining-whole*unit)
  if excess>0.000000001:
   var source: Dictionary=provisions.last_serving
   var fraction: float=excess/unit
   var nutrient: float=float(source.vitamin_c_lb)*fraction
   var portion: Dictionary={"kind":"portion","lb":float(source.lb)*fraction,"kcal":excess,"expires":int(source.expires),"vitamin_c_lb":nutrient}
   stock.record.products.append(portion)
   if source.get("hunt",false):stock.hunt_portion=portion;hunt_fraction=fraction
   vitamin-=nutrient
 stock.product_mass(game)
 stock.last_meal={"eaten":needed-remaining/unit,"needed":needed,"vitamin":vitamin,"ordinary_removed":ordinary,"dairy_eaten":dairy/unit,"hunt_fraction":hunt_fraction}
 return stock.last_meal

static func forecast(game,horizon: int=3) -> int:
 # Only food already carried is promised; future milk, catches and chores are not.
 var model=game.provisions.get_script().new()
 model.data=game.provisions.data.duplicate(true);model.fresh.assign(game.provisions.fresh.duplicate(true))
 var stock=load("res://simulation/livestock.gd").new()
 stock.record=game.livestock.record.duplicate(true)
 var copy: Dictionary={"state":game.state.duplicate(true),"provisions":model,"livestock":stock}
 var needed: int=int(game.state.party_size)*int(model.data.rations_lb[game.state.rations])
 for offset in range(1,horizon+1):
  var day: int=int(game.state.day)+offset
  copy.state.food-=model.spoil(day,int(copy.state.food))
  stock.record.products=stock.record.products.filter(func(p):return int(p.expires)>day)
  var result: Dictionary=serve(copy,needed)
  if result.eaten<needed-0.000000001:return offset-1
 return horizon
