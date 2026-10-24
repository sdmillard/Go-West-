extends RefCounted
## One continuous, data-driven health curve for walking packs and retrieval jobs.
## Health is an abstract condition score, not a measured percentage of strength.
static func valid_curve(curve: Variant) -> bool:
 if not curve is Array or curve.size()!=5:return false
 var healths: Array=[0,20,50,80,100]
 var previous: float=-1
 for i in range(curve.size()):
  var point: Variant=curve[i]
  if not point is Array or point.size()!=2 or point[0]!=healths[i]:return false
  if not (point[1] is int or point[1] is float) or not is_finite(float(point[1])) or point[1]<0 or point[1]>1 or point[1]<previous:return false
  previous=float(point[1])
 return curve[0][1]==0 and curve[2][1]==1 and curve[3][1]==1 and curve[4][1]==1
static func factor(member: Dictionary,curve: Array) -> float:
 if not member.alive or member.get("departed",false) or member.get("guarding",false) or member.get("away",false):return 0.0
 if member.conditions.any(func(condition):return condition.id=="broken_leg"):return 0.0
 var health: float=clampf(float(member.health),0,100)
 for i in range(1,curve.size()):
  if health<=float(curve[i][0]):
   var start: Array=curve[i-1];var finish: Array=curve[i]
   return lerpf(float(start[1]),float(finish[1]),(health-float(start[0]))/(float(finish[0])-float(start[0])))
 return 1.0
static func capacity(members: Array,per_person: float,curve: Array) -> float:
 var total:=0.0
 for member in members:total+=per_person*factor(member,curve)
 return snappedf(total,0.1)
