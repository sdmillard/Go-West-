extends RefCounted
## Authored capacity estimate: health scales a person's load; broken legs prevent hauling.
## Derived from current members, never serialized as a second health record.
static func factor(member: Dictionary) -> float:
	if not member.alive or member.get("departed",false):return 0.0
	if member.conditions.any(func(condition):return condition.id=="broken_leg"):return 0.0
	return clampf(float(member.health)/100.0,0.0,1.0)
static func capacity(members: Array,per_person: float) -> float:
	var total:=0.0
	for member in members:total+=per_person*factor(member)
	return snappedf(total,0.1)
