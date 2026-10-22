extends RefCounted
## Shared catalog and pure effects; candidate generation owns its own random stream.
const HEALTH_KEYS=["hurt_all","hurt_hunger","hurt_exposure","hurt_exhaustion","hurt_crossing","hurt_combat","hurt_illness","heal"]
const ACTIONS=["robbery","murder","cannibalism","miss_wages","hunt","repair","care","trade","defend"]
const REQUIRED={"temperaments":["Cautious","Bold"],"values":["Compassionate","Pragmatic"],"specials":["Loyal","Mercenary","Veteran","Cannibal"],"flaws":["Frail","Slow Healer"],"relationships":["fellow_traveler","friend","family"]}
var data: Dictionary={}
var error: String=""
func _init():load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/character_catalog.json")))
func load_data(value: Variant) -> bool:
	error="Invalid character catalog"
	if not value is Dictionary or value.get("version")!=1:return false
	for category in ["temperaments","values","specials","flaws","relationships"]:
		if not value.get(category) is Dictionary or value[category].is_empty() or value[category].size()>64:return false
		for name in value[category]:
			if not name is String or name.is_empty() or name.length()>40:return false
			var definition: Variant=value[category][name]
			if not definition is Dictionary or not definition.get("description") is String or definition.description.is_empty() or definition.description.length()>320:return false
			for key in definition:
				var amount: Variant=definition[key]
				if key=="description":continue
				if key in ["approved","disapproved","forbidden"]:
					if not amount is Array or amount.size()>ACTIONS.size():return false
					var seen: Array=[]
					for action in amount:
						if action not in ACTIONS or action in seen:return false
						seen.append(action)
				elif key=="assists":
					if amount not in ["Hunting","Carpentry","Caregiving","Trading"]:return false
				else:
					if not (amount is int or amount is float) or not is_finite(amount):return false
					if key in HEALTH_KEYS+["trust_loss","trust_gain"]:
						if amount<0.25 or amount>3:return false
					elif key in ["defense","push_sick","rest_sick","care_others","idle_trust","personal_care"]:
						if amount!=floor(amount) or amount< -2 or amount>2:return false
					elif key in ["trust","attachment","wage_cents"]:
						if amount!=floor(amount) or amount<0 or amount>100:return false
					else:return false
			if category=="relationships" and (not definition.has("trust") or not definition.has("attachment")):return false
	for field in ["first_names","surnames"]:
		if not value.get(field) is Array or value[field].is_empty() or value[field].size()>200:return false
		for name in value[field]:
			if not name is String or name.is_empty() or name.length()>24:return false
	for category in REQUIRED:
		for required in REQUIRED[category]:
			if not value[category].has(required):return false
	for definition in value.values.values():
		var seen: Array=[]
		for tier in ["approved","disapproved","forbidden"]:
			for action in definition.get(tier,[]):
				if action in seen:return false
				seen.append(action)
	data=value.duplicate(true)
	error=""
	return true
func definitions(profile: Dictionary) -> Array:
	var result: Array=[]
	for name in profile.get("traits",[]):
		for category in ["temperaments","values"]:
			if data[category].has(name):result.append(data[category][name])
	for category in ["specials","flaws"]:
		for name in profile.get(category,[]):
			if data[category].has(name):result.append(data[category][name])
	return result
func factor(profile: Dictionary,key: String) -> float:
	var result:=1.0
	for definition in definitions(profile):result*=float(definition.get(key,1))
	return clampf(result,0.25,3)
func reaction(profile: Dictionary,key: String,default: int=0) -> int:
	var result:=default
	for definition in definitions(profile):
		if definition.has(key):result=int(definition[key])
	return result
func boundaries(value_name: String) -> Dictionary:
	var definition: Dictionary=data.values[value_name]
	return {"approved":definition.get("approved",[]).duplicate(),"disapproved":definition.get("disapproved",[]).duplicate(),"forbidden":definition.get("forbidden",[]).duplicate()}
func health_delta(profile: Dictionary,delta: int,cause: String,conditions: Dictionary) -> int:
	if delta==0:return 0
	if delta>0:return maxi(1,floori(delta*factor(profile,"heal")))
	var key: String={"lack of food":"hurt_hunger","hunger":"hurt_hunger","exposure":"hurt_exposure","exhaustion":"hurt_exhaustion","crossing injuries":"hurt_crossing","confrontation injuries":"hurt_combat"}.get(cause,"")
	if key.is_empty():
		for condition in conditions.values():
			if condition.kind=="illness" and condition.name.to_lower()==cause:key="hurt_illness"
	return -maxi(1,ceili(absf(delta)*factor(profile,"hurt_all")*(factor(profile,key) if not key.is_empty() else 1.0)))
