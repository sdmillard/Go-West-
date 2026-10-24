extends RefCounted
## Authored capacity estimate: health scales a person's load; broken legs prevent hauling.
## Derived from current members, never serialized as a second health record.
static func factor(member: Dictionary) -> float:
	if not member.alive or member.get("departed",false) or member.get("guarding",false):return 0.0
	if member.conditions.any(func(condition):return condition.id=="broken_leg"):return 0.0
	return clampf(float(member.health)/100.0,0.0,1.0)
static func capacity(members: Array,per_person: float,pack_relief_anchor: float=0.0) -> float:
	var total:=0.0
	for member in members:
		var strength: float=factor(member)
		# Health is an abstract condition score, not a direct percentage of lifting strength.
		# Moderate illness reduces sustainable packs without immediately consuming all food room.
		strength*=1.0+maxf(0.0,pack_relief_anchor-strength)
		total+=per_person*strength
	return snappedf(total,0.1)
