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
				elif key=="legacy_only":
					if category!="specials" or not amount is bool:return false
				elif key=="assists":
					if amount not in ["Hunting","Carpentry","Caregiving","Trading","Leatherworking"]:return false
				else:
					if not (amount is int or amount is float) or not is_finite(amount):return false
					if key in HEALTH_KEYS+["trust_loss","trust_gain","hardship_trust_loss"]:
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
	var given_names: Variant=value.get("given_names",{"women":value.first_names,"men":value.first_names})
	if not given_names is Dictionary:return false
	for field in ["women","men"]:
		if not given_names.get(field) is Array or given_names[field].is_empty() or given_names[field].size()>200:return false
		for name in given_names[field]:
			if not name is String or name.is_empty() or name.length()>24:return false
	var heritage_names: Variant=value.get("heritage_names",{})
	if not heritage_names is Dictionary or heritage_names.size()>32:return false
	for heritage in heritage_names:
		var pool: Variant=heritage_names[heritage]
		if not heritage is String or heritage.length()>64 or not pool is Dictionary:return false
		var chance: Variant=pool.get("own_given_chance",1.0)
		if not (chance is float or chance is int) or not is_finite(chance) or chance<0 or chance>1:return false
		for field in ["women","men","surnames"]:
			if not pool.get(field) is Array or pool[field].is_empty() or pool[field].size()>200:return false
			for name in pool[field]:
				if not name is String or name.is_empty() or name.length()>24:return false
	var native_names: Variant=value.get("native_names",{"pools":{},"heritages":{}})
	if not native_names is Dictionary or not native_names.get("pools") is Dictionary or not native_names.get("heritages") is Dictionary:return false
	for pool in native_names.pools.values():
		if not pool is Dictionary:return false
		var lists: Array=["women","men"]+(["mission_women","mission_men"] if pool.has("mission_men") or pool.has("mission_women") else [])
		for field in lists:
			if not pool.get(field) is Array or pool[field].is_empty() or pool[field].size()>200:return false
			for name in pool[field]:
				if not name is String or name.is_empty() or name.length()>14:return false
	for heritage in native_names.heritages:
		if not native_names.pools.has(native_names.heritages[heritage]):return false
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
## Draws a full name that fits the traveler: women's or men's given names (from the outfit), and the heritage's pool.
## Surnames come from the heritage pool; given names from it or, Americanized, from the general pool.
## "Mixed heritage" takes the given name and surname from two random pools; other labels use the general pool.
func generated_name(random: RandomNumberGenerator, heritage: String, woman: bool) -> String:
	var native: Dictionary=data.get("native_names",{})
	if native.get("heritages",{}).has(heritage):
		# One name, as emigrants and traders recorded it: sometimes a mission or trade name, usually an English rendering.
		var pool: Dictionary=native.pools[native.heritages[heritage]]
		var prefix: String="mission_" if pool.has("mission_men") and random.randf()<float(pool.get("mission_chance",0.0)) else ""
		var names: Array=pool[prefix+("women" if woman else "men")]
		return names[random.randi_range(0,names.size()-1)]
	var pools: Dictionary=data.get("heritage_names",{})
	var general_given: Dictionary=data.get("given_names",{"women":data.first_names,"men":data.first_names})
	var general: Dictionary={"women":general_given.women,"men":general_given.men,"surnames":data.surnames}
	var given_pool: Dictionary=general
	var surname_pool: Dictionary=general
	if heritage=="Mixed heritage":
		var choices: Array=[general]+pools.values()
		given_pool=choices[random.randi_range(0,choices.size()-1)]
		surname_pool=choices[random.randi_range(0,choices.size()-1)]
	elif pools.has(heritage):
		surname_pool=pools[heritage]
		given_pool=pools[heritage] if random.randf()<float(pools[heritage].get("own_given_chance",1.0)) else general
	var given: Array=given_pool.women if woman else given_pool.men
	var surnames: Array=surname_pool.surnames
	return "%s %s" % [given[random.randi_range(0,given.size()-1)],surnames[random.randi_range(0,surnames.size()-1)]]
