extends RefCounted
## Finite feed resources and limiting-factor production. No RNG or new clock.
const Ruminants=preload("res://simulation/ruminant_nutrition.gd")
static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(v)
static func valid(data: Dictionary) -> bool:
 var f: Variant=data.get("feeding")
 if not f is Dictionary or not f.get("note") is String or not f.get("habitats") is Dictionary:return false
 if not Ruminants.valid(f.get("ruminants")):return false
 for key in ["maintenance_fraction","full_production_fraction","moving_feed_time","grueling_feed_time","moving_scratch_time","grain_only_laying_cap","mixed_diet_fraction"]:
  if not number(f.get(key)) or f[key]<=0 or f[key]>1:return false
 if f.maintenance_fraction>=f.full_production_fraction:return false
 for key in ["scratch_lb","scrap_lb_per_person","feed_kcal_per_lb"]:
  if not number(f.get(key)) or f[key]<=0 or f[key]>10000:return false
 if not f.get("laying_months") is Array or f.laying_months.size()!=12:return false
 for n in f.laying_months:
  if not number(n) or n<0 or n>1:return false
 for region in ["woodland","plains","highcountry","sagebrush","forest"]:
  if not f.habitats.get(region) is Dictionary:return false
  for key in ["dairy_cows","goats","scratch"]:
   if not number(f.habitats[region].get(key)) or f.habitats[region][key]<0 or f.habitats[region][key]>1:return false
 if not f.get("condition_curve") is Array or f.condition_curve.size()<2:return false
 var health: float=-1;var factor: float=-1
 for point in f.condition_curve:
  if not point is Array or point.size()!=2 or not number(point[0]) or not number(point[1]) or point[0]<=health or point[0]>100 or point[1]<factor or point[1]>1:return false
  health=point[0];factor=point[1]
 if f.condition_curve[0][0]!=0 or f.condition_curve[0][1]!=0 or f.condition_curve[-1][0]!=100 or f.condition_curve[-1][1]!=1:return false
 if not data.get("supplies") is Dictionary:return false
 for key in ["poultry_feed","livestock_fodder"]:
  var rule: Variant=data.supplies.get(key)
  if not rule is Dictionary or not rule.get("label") is String:return false
  for field in ["unit_lb","price_cents","maximum","stock"]:
   if not number(rule.get(field)) or rule[field]<=0 or rule[field]>100000:return false
  for field in ["price_cents","maximum","stock"]:
   if rule[field]!=floor(rule[field]):return false
 if data.supplies.poultry_feed.unit_lb!=0.25 or data.supplies.livestock_fodder.unit_lb!=1:return false
 return true
static func capacity(data: Dictionary,condition: int) -> float:
 var points: Array=data.feeding.condition_curve
 for i in range(1,points.size()):
  if condition<=points[i][0]:return lerpf(float(points[i-1][1]),float(points[i][1]),clampf((condition-float(points[i-1][0]))/(float(points[i][0])-float(points[i-1][0])),0,1))
 return 1.0
static func surplus(data: Dictionary,intake: float) -> float:
 return clampf((intake-float(data.feeding.maintenance_fraction))/(float(data.feeding.full_production_fraction)-float(data.feeding.maintenance_fraction)),0,1)
static func scraps(game,wanted_kcal: float,commit: bool) -> Dictionary:
 var data: Dictionary=game.livestock.data
 var mass_left: float=int(game.state.party_size)*float(data.feeding.scrap_lb_per_person)
 var needed: float=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])*float(game.provisions.data.food_energy.unit_kcal)
 var surplus_kcal: float=maxf(0,int(game.state.food)*float(game.provisions.data.food_energy.unit_kcal)+game.livestock.available_kcal()-needed)
 var left: float=minf(wanted_kcal,surplus_kcal)
 var eaten:=0.0;var mass:=0.0
 # Missing setting belongs to older saves, whose effective choice was sharing on.
 if not game.livestock.record.get("share_scraps",true) or not game.livestock.record.care:return {"kcal":0.0,"lb":0.0}
 for p in game.livestock.record.products:
  if p.kind!="portion" or float(p.get("vitamin_c_lb",0))>0 or int(p.expires)<=int(game.state.day) or left<=0 or mass_left<=0:continue
  var fraction: float=minf(1.0,minf(left/float(p.kcal),mass_left/float(p.lb)))
  var calories: float=float(p.kcal)*fraction;var pounds: float=float(p.lb)*fraction
  eaten+=calories;mass+=pounds;left-=calories;mass_left-=pounds
  if commit:
   p.kcal-=calories;p.lb-=pounds
   if p.has("vitamin_c_lb"):p.vitamin_c_lb*=1.0-fraction
 if commit:
  game.livestock.record.products=game.livestock.record.products.filter(func(p):return float(p.kcal)>0.000000001)
  game.livestock.product_mass(game)
 return {"kcal":eaten,"lb":mass}
static func available(game,kind: String) -> float:
 return game.livestock.count(game.state,kind)*float(game.livestock.data.supplies[kind].unit_lb)+float(game.state.get(kind+"_remainder_lb",0))
static func use(game,kind: String,pounds: float) -> int:
 var unit: float=game.livestock.data.supplies[kind].unit_lb
 var previous: float=game.state.get(kind+"_remainder_lb",0)
 var opened: int=ceili(maxf(0,pounds-previous-0.000000001)/unit)
 if opened>0:game.state[kind]-=opened
 var left: float=float("%.12f" % maxf(0,previous+opened*unit-pounds))
 if left>0.000000001:game.state[kind+"_remainder_lb"]=left
 else:game.state.erase(kind+"_remainder_lb")
 return opened
static func plan(game,o: Dictionary,resting: bool,working: bool,commit: bool=false) -> Dictionary:
 var data: Dictionary=game.livestock.data;var f: Dictionary=data.feeding
 var region: String=game.context.region_id(game)
 var habitat: Dictionary=f.habitats.get(region,f.habitats.plains)
 var feed_time: float=float(f.grueling_feed_time if int(game.state.pace)==2 else f.moving_feed_time) if working else 1.0
 var result: Dictionary={"region":region,"grain_quarters":0,"fodder_lb":0.0,"fodder_units":0,"grain_lb":0.0,"scratch_lb":0.0,"scraps_lb":0.0,"scraps_kcal":0.0,"animals":{}}
 var budgets: Dictionary={}
 var shortfall:=0.0
 for kind in ["dairy_cows","goats"]:
  var heads: int=game.livestock.count(game.state,kind)
  var natural: float=0.0 if o.waterless else minf(float(o.season),minf(float(habitat[kind]),feed_time))
  var potential:=0.0;var recorded:=0
  for animal in game.livestock.record.animals:
   if animal.kind==kind:
    recorded+=1;potential+=float(data.animals[kind].daily_lb)*clampf(float(animal.remaining)/60.0,0,1)
  # Newly purchased headcounts can be previewed before sync creates their records.
  potential+=maxi(0,heads-recorded)*float(data.animals[kind].daily_lb)
  var budget: Dictionary=Ruminants.budget(f.ruminants,kind,heads,potential,natural,working,int(game.state.pace))
  budgets[kind]=budget;shortfall+=float(budget.fodder_needed_lb)
  var natural_tdn: float=float(budget.natural_dm_lb)*float(budget.natural_tdn_fraction)
  var full: float=budget.target_tdn_lb
  var ration: float=full/(float(f.ruminants.hay_dry_matter)*float(f.ruminants.hay_tdn))
  result.animals[kind]={"ration_lb":ration,"natural":minf(1.0,natural_tdn/full) if full>0 else 1.0,"intake":1.0,"production":1.0,"quality":1.0,"fodder_needed_lb":float(budget.fodder_needed_lb),"budget":budget}
 var hay: float=minf(available(game,"livestock_fodder"),maxf(0,shortfall))
 result.fodder_lb=hay
 for kind in ["dairy_cows","goats"]:
  var a: Dictionary=result.animals[kind];var budget: Dictionary=budgets[kind]
  var share: float=hay*float(budget.fodder_needed_lb)/shortfall if shortfall>0 else 0.0
  a.merge(Ruminants.supplied(budget,share,float(f.maintenance_fraction)),true)
  a["fodder_lb"]=share
 var ration: float=game.livestock.count(game.state,"hens")*float(data.animals.hens.daily_feed_lb)
 var scratch: float=minf(ration,float(f.scratch_lb)*minf(float(o.season),minf(float(habitat.scratch),float(f.moving_scratch_time) if working else 1.0))) if game.livestock.record.care and not o.waterless else 0.0
 var shared: Dictionary=scraps(game,maxf(0,ration-scratch)*float(f.feed_kcal_per_lb),commit) if ration>0 else {"kcal":0.0,"lb":0.0}
 var equivalent: float=float(shared.kcal)/float(f.feed_kcal_per_lb)
 var grain: float=minf(available(game,"poultry_feed"),maxf(0,ration-scratch-equivalent))
 var intake: float=minf(1.0,(scratch+equivalent+grain)/ration) if ration>0 else 1.0
 var diversity: float=minf(1.0,(scratch+equivalent)/(ration*float(f.mixed_diet_fraction))) if ration>0 else 1.0
 result.grain_quarters=ceili(maxf(0,grain-float(game.state.get("poultry_feed_remainder_lb",0))-0.000000001)/float(data.supplies.poultry_feed.unit_lb));result.grain_lb=grain;result.scratch_lb=scratch;result.scraps_lb=shared.lb;result.scraps_kcal=shared.kcal
 result.animals.hens={"ration_lb":ration,"natural":scratch+equivalent,"intake":intake,"production":surplus(data,intake),"quality":float(f.grain_only_laying_cap)+(1.0-float(f.grain_only_laying_cap))*diversity}
 result=Ruminants.stable(result)
 if commit:
  result.fodder_units=use(game,"livestock_fodder",float(result.fodder_lb))
  result.grain_quarters=use(game,"poultry_feed",float(result.grain_lb))
 return result
static func settle(data: Dictionary,current: int,carry: float,intake: float,waterless: bool,weather: String,resting: bool,working: bool,pace: int) -> Dictionary:
 var maintenance: float=data.feeding.maintenance_fraction
 var strain: float=maxf(0,maintenance-intake)/maintenance*6.0
 strain=maxf(strain,6.0 if waterless else 0.0)
 strain=maxf(strain,2.0 if weather in ["blizzard","heat"] else 0.0)
 strain=maxf(strain,1.0 if working and pace==2 else 0.0)
 var recovery: int=(2 if resting else 1) if strain==0 and intake>=float(data.feeding.full_production_fraction) else 0
 var total: float=carry+strain
 var whole: int=floori(total+0.000000001)
 var next_carry: float=float("%.12f" % maxf(0,total-whole)) if recovery==0 else 0.0
 return {"condition":clampi(current-whole+recovery,0,100),"strain_carry":next_carry}
static func condition(data: Dictionary,current: int,intake: float,waterless: bool,weather: String,resting: bool,working: bool,pace: int) -> int:
 return int(settle(data,current,0.0,intake,waterless,weather,resting,working,pace).condition)
