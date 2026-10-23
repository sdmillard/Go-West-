extends RefCounted
## Bounded authored risk, not a historical combat-frequency model.
var data: Dictionary={}
var history: Array[Dictionary]=[]
var error: String=""
func _init():
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json")))
func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
func load_data(value: Variant) -> bool:
	data={}
	error="Invalid combat rules"
	if not value is Dictionary:return false
	for key in ["poor_health","fair_health","poor_multiplier","fair_multiplier","experience_reduction","experience_cap","defense_floor","circle_floor","risk_cap","small_party_penalty","minimum_defenders"]:
		if not number(value.get(key)) or value[key]<0:return false
	if value.poor_health>=value.fair_health or value.fair_health>100 or value.fair_multiplier<1 or value.poor_multiplier<value.fair_multiplier or value.poor_multiplier>3:return false
	for key in ["experience_reduction","defense_floor","circle_floor","risk_cap","small_party_penalty"]:
		if value[key]>1:return false
	if value.defense_floor<=0 or value.circle_floor<=0 or value.risk_cap<maxf(value.defense_floor,value.circle_floor):return false
	for key in ["experience_cap","minimum_defenders","poor_health","fair_health"]:
		if value[key]!=int(value[key]):return false
	if value.experience_cap>10 or value.minimum_defenders<1 or value.minimum_defenders>5:return false
	data=value.duplicate(true)
	error=""
	return true
func victories() -> int:
	return history.filter(func(row):return row.outcome=="won").size()
func risk(game,tactic: String,base: float) -> float:
	var health: int=game.party_health.average_health()
	var multiplier: float=float(data.poor_multiplier) if health<int(data.poor_health) else (float(data.fair_multiplier) if health<int(data.fair_health) else 1.0)
	var able: int=game.party_health.members.filter(func(member):return game.party_health.is_active(member) and member.health>=int(data.poor_health) and game.characters.willing(int(member.id),"defend")).size()
	var chance: float=base*multiplier-mini(victories(),int(data.experience_cap))*float(data.experience_reduction)
	if able<int(data.minimum_defenders):chance+=float(data.small_party_penalty)
	if game.characters.available(game,"","Veteran"):chance-=float(game.characters.benefits.veteran_risk_reduction)
	return clampf(chance,float(data.circle_floor if tactic=="circle" else data.defense_floor),float(data.risk_cap))
func prepare(game,content: Dictionary) -> void:
	for choice in content.get("choices",[]):
		if not choice.has("combat"):continue
		choice.risk.probability=risk(game,choice.combat,float(choice.risk.probability))
		choice["quoted_risk"]=choice.risk.probability
		choice.label+=" · %d%% injury risk%s" % [roundi(choice.quoted_risk*100)," if hostile" if content.id=="riders" else ""]
func valid(value: Variant,day: int, count: int=5) -> bool:
	if not value is Array or value.size()>10000:return false
	for row in value:
		if not row is Dictionary or row.get("event","") not in ["bandits","riders"] or row.get("tactic","") not in ["defend","circle"] or row.get("outcome","") not in ["won","deterred","injured","fatal","friendly"]:return false
		for key in ["day","victim"]:
			if not number(row.get(key)) or row[key]!=int(row[key]):return false
		if row.day<0 or row.day>day or row.victim<0 or row.victim>=count or not number(row.get("risk")) or row.risk<0 or row.risk>1:return false
	return true
