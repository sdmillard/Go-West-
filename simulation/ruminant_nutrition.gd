extends RefCounted
## Dairy energy budget in pounds dry matter and TDN, separate from human calories.
## Pure calculations; no state, random draws, implicit fodder or body-reserve milk.
static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(v)
static func valid(v: Variant) -> bool:
 if not v is Dictionary or not v.get("note") is String or not v.get("animals") is Dictionary:return false
 for key in ["hay_dry_matter","hay_tdn"]:
  if not number(v.get(key)) or v[key]<=0 or v[key]>1:return false
 for key in ["travel_maintenance_bonus","grueling_maintenance_bonus"]:
  if not number(v.get(key)) or v[key]<0 or v[key]>1:return false
 if v.grueling_maintenance_bonus<v.travel_maintenance_bonus:return false
 for kind in ["dairy_cows","goats"]:
  var a: Variant=v.animals.get(kind)
  if not a is Dictionary:return false
  for key in ["body_lb","reference_body_lb","dm_body_fraction","maintenance_tdn_lb","milk_tdn_per_lb","natural_tdn"]:
   if not number(a.get(key)) or a[key]<=0:return false
  if a.body_lb>2500 or a.reference_body_lb>2500 or a.dm_body_fraction>0.1 or a.natural_tdn>1 or a.milk_tdn_per_lb>2:return false
  if a.maintenance_tdn_lb*pow(float(a.body_lb)/float(a.reference_body_lb),0.75)>=a.body_lb*a.dm_body_fraction:return false
 return true
static func budget(rules: Dictionary,kind: String,heads: int,milk_lb: float,natural: float,working: bool,pace: int) -> Dictionary:
 var a: Dictionary=rules.animals[kind]
 var bonus: float=(rules.grueling_maintenance_bonus if pace==2 else rules.travel_maintenance_bonus) if working else 0.0
 var capacity: float=heads*float(a.body_lb)*float(a.dm_body_fraction)
 var dm: float=capacity*clampf(natural,0,1)
 var maintenance: float=heads*float(a.maintenance_tdn_lb)*pow(float(a.body_lb)/float(a.reference_body_lb),0.75)*(1.0+bonus)
 var result: Dictionary={"capacity_dm_lb":capacity,"natural_dm_lb":dm,"natural_tdn_fraction":float(a.natural_tdn),"maintenance_tdn_lb":maintenance,"milk_target_lb":milk_lb,"milk_tdn_lb":milk_lb*float(a.milk_tdn_per_lb),"hay_dry_matter":float(rules.hay_dry_matter),"hay_tdn_fraction":float(rules.hay_tdn)}
 result["target_tdn_lb"]=maintenance+float(result.milk_tdn_lb)
 var desired:=0.0
 if dm*float(a.natural_tdn)<float(result.target_tdn_lb):
  # Fill free rumen capacity; replace forage only when the hay is richer.
  var limit: float=(capacity if float(rules.hay_tdn)>float(a.natural_tdn) else capacity-dm)/float(rules.hay_dry_matter)
  var lo:=0.0;var hi: float=maxf(0,limit)
  if energy(result,hi)<float(result.target_tdn_lb):desired=hi
  else:
   for i in range(48):
    var mid: float=(lo+hi)/2.0
    if energy(result,mid)<float(result.target_tdn_lb):lo=mid
    else:hi=mid
   desired=hi
 result["fodder_needed_lb"]=desired
 return result
static func energy(b: Dictionary,hay_lb: float) -> float:
 var hay_dm: float=minf(float(b.capacity_dm_lb),maxf(0,hay_lb)*float(b.hay_dry_matter))
 var natural_dm: float=minf(float(b.natural_dm_lb),maxf(0,float(b.capacity_dm_lb)-hay_dm))
 return hay_dm*float(b.hay_tdn_fraction)+natural_dm*float(b.natural_tdn_fraction)
static func supplied(b: Dictionary,hay_lb: float,maintenance_fraction: float) -> Dictionary:
 var hay_dm: float=minf(float(b.capacity_dm_lb),maxf(0,hay_lb)*float(b.hay_dry_matter))
 var dm: float=minf(float(b.natural_dm_lb),maxf(0,float(b.capacity_dm_lb)-hay_dm))
 var tdn: float=energy(b,hay_lb)
 var production: float=clampf((tdn-float(b.maintenance_tdn_lb))/float(b.milk_tdn_lb),0,1) if float(b.milk_tdn_lb)>0 else 1.0
 var maintenance: float=minf(1.0,tdn/float(b.maintenance_tdn_lb)) if float(b.maintenance_tdn_lb)>0 else 1.0
 var condition_intake: float=maintenance_fraction*maintenance if maintenance<1 else lerpf(maintenance_fraction,1.0,production)
 return {"natural_dm_eaten_lb":dm,"hay_dm_lb":hay_dm,"tdn_lb":tdn,"maintenance_coverage":maintenance,"intake":minf(1.0,tdn/float(b.target_tdn_lb)) if float(b.target_tdn_lb)>0 else 1.0,"production":production,"condition_intake":condition_intake}

static func stable(value: Variant) -> Variant:
 # Logs become part of saves. Canonical decimals avoid hidden binary drift on JSON reload.
 if value is float:return float("%.9f" % value)
 if value is Dictionary:
  var result: Dictionary={}
  for key in value:result[key]=stable(value[key])
  return result
 if value is Array:
  var result: Array=[]
  for entry in value:result.append(stable(entry))
  return result
 return value
