extends RefCounted
## Per-person state, independent of UI. All numbers are provisional gameplay tuning.
const VITAMIN_REPLENISHMENT_RATIO=8
var members: Array[Dictionary] = []
var conditions: Dictionary = {}
var daily_onset_chance := 0.0
var scurvy: Dictionary = {}
var wound_infection: Dictionary = {}
# Consecutive days without sufficient vitamin-C produce eaten; legacy save field name.
var days_without_fresh := 0
var notices: Array[String] = []
var error := ""
var rng := RandomNumberGenerator.new()
# Derived reference to the character profiles; saves store flaws only in that roster.
var character_profiles: Array[Dictionary]=[]
var character_catalog

func _init() -> void:
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/health_conditions.json")))

func load_data(data: Variant) -> bool:
	conditions.clear()
	error = ""
	if not data is Dictionary or not data.get("conditions") is Array or data.conditions.is_empty():
		return _fail("Expected health condition data")
	var chance: Variant = data.get("daily_onset_chance")
	if not _number(chance) or chance < 0 or chance > 1:
		return _fail("Invalid health event chance")
	for entry in data.conditions:
		if not entry is Dictionary:
			return _fail("Invalid health condition")
		for key in ["id", "name", "kind"]:
			if not entry.get(key) is String or entry[key].is_empty():
				return _fail("Missing health condition field")
		if conditions.has(entry.id) or entry.kind not in ["illness", "injury"]:
			return _fail("Duplicate or invalid health condition")
		if entry.has("from_year") and (not _number(entry.from_year) or entry.from_year != floor(entry.from_year) or entry.from_year < 1):
			return _fail("Invalid condition chronology")
		for key in ["daily_damage", "recovery_days"]:
			if not _number(entry.get(key)) or entry[key] != floor(entry[key]) or entry[key] <= 0:
				return _fail("Invalid health progression")
		if entry.has("fed_daily_damage") and (not entry.get("needs_fresh_food",false) or not _number(entry.fed_daily_damage) or entry.fed_daily_damage!=floor(entry.fed_daily_damage) or entry.fed_daily_damage<0 or entry.fed_daily_damage>entry.daily_damage):
			return _fail("Invalid nutritional recovery damage")
		if not _valid_spread(entry):
			return _fail("Invalid disease onset or spread")
		conditions[entry.id] = entry.duplicate(true)
	var deficiency: Variant = data.get("scurvy", {})
	if not deficiency is Dictionary or (not deficiency.is_empty() and not _valid_deficiency(deficiency)):
		return _fail("Invalid scurvy rules")
	var infection: Variant=data.get("wound_infection",{})
	if not infection is Dictionary or (not infection.is_empty() and not _valid_infection(infection)):
		return _fail("Invalid wound infection rules")
	wound_infection=infection.duplicate(true)
	daily_onset_chance = float(chance)
	scurvy = deficiency.duplicate(true)
	return true

func _valid_infection(rules: Dictionary) -> bool:
	if rules.get("source")!="wound" or rules.get("condition")!="wound_infection" or not conditions.has(rules.source) or conditions[rules.source].kind!="injury" or not conditions.has(rules.condition) or conditions[rules.condition].kind!="illness" or not conditions[rules.condition].get("complication",false):return false
	if not rules.get("until_healed") is bool or not rules.until_healed:return false
	for key in ["min_days"]:
		if not _number(rules.get(key)) or rules[key]!=floor(rules[key]) or rules[key]<1 or rules[key]>365:return false
	for key in ["daily_chance","rest_factor","dressed_factor"]:
		if not _number(rules.get(key)) or rules[key]<0 or rules[key]>1:return false
	return true

func dress_wound(member_id: int,day: int) -> bool:
	if member_id<0 or member_id>=members.size() or not is_active(members[member_id]):return false
	for active in members[member_id].conditions:
		if active.id==wound_infection.get("source",""):
			active["dressed_until_day"]=day
			return true
	return false

func infection_chance(member_id: int,day: int,resting: bool=false) -> float:
	if wound_infection.is_empty() or member_id<0 or member_id>=members.size():return 0
	var member: Dictionary=members[member_id]
	if not is_active(member) or member.conditions.any(func(c):return c.id==wound_infection.condition):return 0
	for active in member.conditions:
		var age: int=day-int(active.started_day)
		if active.id==wound_infection.source and age>=wound_infection.min_days and int(active.elapsed)<int(conditions[active.id].recovery_days):
			return float(wound_infection.daily_chance)*(float(wound_infection.rest_factor) if resting else 1.0)*(float(wound_infection.dressed_factor) if int(active.get("dressed_until_day",-1))>=day else 1.0)
	return 0

func _wound_complications(day: int,rations: int,resting: bool,rest_by_member: Dictionary) -> void:
	for member in members:
		var chance: float=infection_chance(int(member.id),day,rest_by_member.get(int(member.id),resting))
		if chance>0 and rng.randf()<chance:
			begin_condition(int(member.id),wound_infection.condition,day,roll_severity(rations))

func _valid_deficiency(rules: Dictionary) -> bool:
	if not conditions.has(rules.get("condition")) or not conditions[rules.condition].get("deficiency", false):
		return false
	if not _number(rules.get("onset_days")) or rules.onset_days < 1 or rules.onset_days != floor(rules.onset_days):
		return false
	for key in ["base_chance", "chance_per_15_days", "max_chance"]:
		if not _number(rules.get(key)) or rules[key] < 0 or rules[key] > 1:
			return false
	if rules.has("floor_drain_days") and (not _number(rules.floor_drain_days) or rules.floor_drain_days < 1 or rules.floor_drain_days != floor(rules.floor_drain_days)):
		return false
	if rules.has("health_floor") and (not _number(rules.health_floor) or rules.health_floor < 0 or rules.health_floor > 99 or rules.health_floor != floor(rules.health_floor)):
		return false
	return true

func _valid_spread(entry: Dictionary) -> bool:
	for key in ["weight", "region_default"]:
		if entry.has(key) and (not _number(entry[key]) or entry[key] < 0):
			return false
	if entry.has("spread_chance") and (not _number(entry.spread_chance) or entry.spread_chance < 0 or entry.spread_chance > 1):
		return false
	for key in ["immunizing", "deficiency", "needs_fresh_food", "complication", "calendar_course"]:
		if entry.has(key) and not entry[key] is bool:
			return false
	if entry.get("calendar_course",false) and (entry.kind!="illness" or entry.get("needs_fresh_food",false)):return false
	if entry.has("incubation_days"):
		var bounds: Variant=entry.incubation_days
		if not bounds is Array or bounds.size()!=2 or entry.kind!="illness" or float(entry.get("spread_chance",0))<=0:return false
		for days in bounds:
			if not _number(days) or days!=floor(days) or days<1 or days>60:return false
		if bounds[0]>bounds[1]:return false
	if entry.has("contagious_after_days") and (not _number(entry.contagious_after_days) or entry.contagious_after_days!=floor(entry.contagious_after_days) or entry.contagious_after_days<0 or entry.contagious_after_days>=entry.recovery_days):return false
	if entry.has("months"):
		if not entry.months is Array or entry.months.size() != 12:
			return false
		for factor in entry.months:
			if not _number(factor) or factor < 0:
				return false
	if entry.has("regions"):
		if not entry.regions is Dictionary:
			return false
		for region in entry.regions:
			if not region is String or not _number(entry.regions[region]) or entry.regions[region] < 0:
				return false
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _fail(message: String) -> bool:
	conditions.clear()
	daily_onset_chance = 0.0
	scurvy = {}
	wound_infection = {}
	error = message
	return false

func start(names: Array, seed_value: int) -> void:
	members.clear()
	notices.clear()
	days_without_fresh = 0
	rng.seed = seed_value ^ 0x50415254
	for index in range(names.size()):
		members.append({"id": index, "name": names[index], "health": 85,
			"alive": true, "conditions": [], "history": [], "death_day": -1, "cause": ""})

static func condition_label(health: int) -> String:
	if health >= 80:
		return "GOOD"
	if health >= 50:
		return "FAIR"
	if health >= 20:
		return "POOR"
	return "VERY POOR"

static func is_active(member: Dictionary) -> bool:
	return member.alive and not member.get("departed",false) and not member.get("guarding",false) and not member.get("away",false)

func living_count() -> int:
	var count := 0
	for member in members:
		count += 1 if is_active(member) else 0
	return count

func average_health() -> int:
	var total := 0
	for member in members:
		if is_active(member):
			total += int(member.health)
	return roundi(float(total) / living_count()) if living_count() else 0

func _record(member: Dictionary, day: int, text: String) -> void:
	var entry := "Day %d · %s" % [day, text]
	member.history.append(entry)
	notices.append(entry)

func affect(member: Dictionary, delta: int, day: int, cause: String) -> void:
	if not is_active(member):
		return
	if character_catalog!=null and int(member.id)<character_profiles.size():delta=character_catalog.health_delta(character_profiles[int(member.id)],delta,cause,conditions)
	member.health = clampi(int(member.health) + delta, 0, 100)
	if delta < 0 and cause == "crossing injuries" and member.health > 0:
		member.history.append("Day %d · Suffered injuries during a river crossing." % day)
	if member.health == 0:kill(member,day,cause)

func kill(member: Dictionary,day: int,cause: String) -> void:
	if not is_active(member):return
	member.health=0
	member.alive=false
	member.death_day=day
	member.cause=cause
	_record(member,day,"%s died from %s." % [member.name,cause])

func affect_all(delta: int, day: int, cause: String) -> void:
	for member in members:
		affect(member, delta, day, cause)

func begin_condition(member_id: int, condition_id: String, day: int, severity: int = 1, source: String = "") -> bool:
	if member_id < 0 or member_id >= members.size() or not conditions.has(condition_id):
		return false
	var member: Dictionary = members[member_id]
	if not is_active(member):
		return false
	for active in member.conditions:
		if active.id == condition_id:
			return false
	var definition: Dictionary = conditions[condition_id]
	if definition.get("complication",false) and (wound_infection.is_empty() or not member.conditions.any(func(c):return c.id==wound_infection.source)):return false
	if condition_id in member.get("immune", []):
		return false
	if member.has("exposures"):
		member.exposures=member.exposures.filter(func(e):return e.id!=condition_id)
		if member.exposures.is_empty():member.erase("exposures")
	member.conditions.append({"id": condition_id, "started_day": day, "elapsed": 0, "severity": clampi(severity, 1, 3)})
	_record(member, day, ("%s has %s." % [member.name, definition.name.to_lower()]) if source.is_empty() else ("%s caught %s from %s." % [member.name, definition.name.to_lower(), source]))
	return true

func susceptible(member: Dictionary,id: String) -> bool:
	return is_active(member) and id not in member.get("immune",[]) and not member.conditions.any(func(c):return c.id==id) and not member.get("exposures",[]).any(func(e):return e.id==id)

func support_condition(active: Dictionary,steps: int) -> void:
	if not conditions[active.id].get("calendar_course",false):active.elapsed+=steps
	active.severity=maxi(1,int(active.get("severity",1))-1)

func expose(member_id: int,id: String,day: int,severity: int=1,source: String="") -> bool:
	if member_id<0 or member_id>=members.size() or not conditions.has(id) or not susceptible(members[member_id],id):return false
	var bounds: Array=conditions[id].get("incubation_days",[])
	if bounds.is_empty():return begin_condition(member_id,id,day,severity,source)
	var member: Dictionary=members[member_id]
	if not member.has("exposures"):member.exposures=[]
	member.exposures.append({"id":id,"exposed_day":day,"onset_day":day+rng.randi_range(int(bounds[0]),int(bounds[1])),"severity":clampi(severity,1,3),"source":source})
	return true

func _mature_exposures(day: int) -> void:
	for member in members:
		if not is_active(member):continue
		for exposure in member.get("exposures",[]).duplicate():
			if day>=int(exposure.onset_day):
				member.exposures.erase(exposure)
				if member.exposures.is_empty():member.erase("exposures")
				begin_condition(int(member.id),exposure.id,day,int(exposure.severity),str(exposure.source))

func valid_exposures(member: Dictionary,day: int) -> bool:
	if not member.has("exposures"):return true
	if not member.exposures is Array or member.exposures.size()>conditions.size():return false
	if member.has("immune") and not member.immune is Array:return false
	var seen: Array=[]
	for e in member.exposures:
		if not e is Dictionary or e.size()!=5 or not e.get("id") is String or not conditions.has(e.id) or not conditions[e.id].has("incubation_days") or e.id in seen:return false
		if e.id in member.get("immune",[]) or member.conditions.any(func(c):return c is Dictionary and c.get("id")==e.id):return false
		for key in ["exposed_day","onset_day","severity"]:
			if not _number(e.get(key)) or e[key]!=floor(e[key]):return false
		var bounds: Array=conditions[e.id].incubation_days
		if e.exposed_day<0 or e.exposed_day>day or e.onset_day<e.exposed_day+bounds[0] or e.onset_day>e.exposed_day+bounds[1] or e.severity<1 or e.severity>3 or not e.get("source") is String or e.source.length()>120:return false
		seen.append(e.id)
	return true

func roll_severity(rations: int) -> int:
	# BASIC 6300–6360 conditional severity branching, using our 0–2 ration index.
	if rng.randf() * 100 < 10 + 35 * clampi(rations, 0, 2):
		return 1
	return 3 if rng.randf() * 100 >= 100 - 40.0 / pow(4, clampi(rations, 0, 2)) else 2

func automatic_conditions(year: int) -> Array[String]:
	var candidates: Array[String] = []
	for id in conditions:
		if conditions[id].kind == "illness" and not conditions[id].get("deficiency", false) and not conditions[id].get("complication",false) and year >= int(conditions[id].get("from_year", 0)):
			candidates.append(id)
	return candidates

# Relative chance that a spontaneous illness is this one, given the month and
# the broad region. Month 0 or an empty region skips that factor.
func onset_weight(id: String, month: int = 0, region: String = "") -> float:
	var definition: Dictionary = conditions[id]
	var weight := float(definition.get("weight", 1.0))
	if month >= 1 and month <= 12 and definition.has("months"):
		weight *= float(definition.months[month - 1])
	if not region.is_empty():
		weight *= float(definition.get("regions", {}).get(region, definition.get("region_default", 1.0)))
	return weight

func _pick_condition(available: Array[String], month: int, region: String) -> String:
	var total := 0.0
	for id in available:
		total += onset_weight(id, month, region)
	var roll := rng.randf() * total
	if total <= 0.0:
		return ""
	for id in available:
		roll -= onset_weight(id, month, region)
		if roll < 0.0:
			return id
	return available[-1]

# Susceptibility depends on this disease and immunity, not unrelated conditions.
# Pending exposures are asymptomatic and cannot transmit.
# Daily chance that each well traveler develops scurvy after a long run of
# meals without vitamin-C foods. It rises every 15 days past onset_days.
func scurvy_chance(days_without_fresh: int) -> float:
	if scurvy.is_empty() or days_without_fresh <= int(scurvy.onset_days):
		return 0.0
	var steps := floori(float(days_without_fresh - int(scurvy.onset_days)) / 15.0)
	return minf(float(scurvy.max_chance), float(scurvy.base_chance) + steps * float(scurvy.chance_per_15_days))

# Fixed-point deficiency debt: zero is full reserve; onset_days is depleted.
# The existing serving is a replenishing portion. Maintenance is one eighth
# (authored approximation of deficiency prevention versus recommended intake).
func feed_vitamins(coverage: float) -> void:
	var change: int=1000-VITAMIN_REPLENISHMENT_RATIO*clampi(roundi(coverage*1000.0),0,1000)
	var worst:=0
	for member in members:
		if not is_active(member):continue
		var debt: int=int(member.get("vitamin_debt_milli",int(member.get("vitamin_days",days_without_fresh))*1000))
		member["vitamin_debt_milli"]=clampi(debt+change,0,100000000)
		member["vitamin_days"]=ceili(int(member.vitamin_debt_milli)/1000.0)
		worst=maxi(worst,int(member.vitamin_days))
	days_without_fresh=worst

static func valid_reserve(member: Dictionary) -> bool:
	if not member.has("vitamin_debt_milli"):return true
	var value: Variant=member.vitamin_debt_milli
	return (value is int or value is float) and is_finite(value) and value==floor(value) and value>=0 and value<=100000000

func _deficiency(day: int, rations: int, days_without_fresh: int, vitamin_coverage: float=-1.0) -> void:
	# A sufficient current meal prevents a new deficiency case while reserves rebuild.
	if vitamin_coverage>=1.0/VITAMIN_REPLENISHMENT_RATIO:return
	for member in members:
		var chance := scurvy_chance(floori(int(member.vitamin_debt_milli)/1000.0) if member.has("vitamin_debt_milli") else int(member.get("vitamin_days",days_without_fresh)))
		if chance>0 and susceptible(member,scurvy.condition) and rng.randf() < chance:
			begin_condition(int(member.id), scurvy.condition, day, roll_severity(rations))

func _spread(day: int, rations: int) -> void:
	var sources: Array = []
	for member in members:
		if is_active(member):
			for active in member.conditions:
				if float(conditions[active.id].get("spread_chance", 0.0)) > 0.0 and day-int(active.started_day)>=int(conditions[active.id].get("contagious_after_days",0)):
					sources.append([member.name, active.id])
	for source in sources:
		var chance := float(conditions[source[1]].spread_chance)
		for member in members:
			if susceptible(member,source[1]) and rng.randf() < chance:
				expose(int(member.id), source[1], day, roll_severity(rations), source[0])

func tick(day: int, resting: bool, risk_multiplier: float = 1.0, rations: int = 2, year: int = 1848, month: int = 0, region: String = "", days_without_fresh: int = 0, rest_by_member: Dictionary = {}, vitamin_coverage: float = -1.0) -> void:
	for member in members:
		if not is_active(member):
			continue
		for active in member.conditions.duplicate():
			var definition: Dictionary = conditions[active.id]
			var nourished: bool=int(member.get("vitamin_days",days_without_fresh))==0
			var rate: int=2 if rest_by_member.get(int(member.id),resting) and not definition.get("calendar_course",false) else 1
			var damage: int=int(definition.get("fed_daily_damage",definition.daily_damage)) if nourished else int(definition.daily_damage)
			if definition.get("needs_fresh_food",false):
				# Shared actual intake earns proportional treatment, retaining sub-step
				# progress and damage so repeated small servings are never rounded away.
				var coverage: int=clampi(roundi(vitamin_coverage*1000.0),0,1000) if vitamin_coverage>=0.0 else (1000 if nourished else 0)
				var progress: int=int(active.get("nutrition_progress_milli",0))+rate*coverage
				var harm: int=int(active.get("nutrition_damage_milli",0))+int(active.get("severity",1))*(int(definition.daily_damage)*(1000-coverage)+int(definition.get("fed_daily_damage",definition.daily_damage))*coverage)
				active.elapsed+=floori(progress/1000.0)
				active["nutrition_progress_milli"]=progress%1000
				active["nutrition_damage_milli"]=harm%1000
				active["treatment_coverage_milli"]=coverage
				damage=floori(harm/1000.0)
				# Scurvy alone wears a traveler down slowly; it weakens rather than kills outright.
				# Below the floor it keeps draining one point every few days, so it can still kill over months.
				if active.id==str(scurvy.get("condition","")) and scurvy.has("health_floor") and int(member.health)-damage<int(scurvy.health_floor):
					var slow: int=maxi(1,int(scurvy.get("floor_drain_days",4)))
					var above: int=maxi(0,int(member.health)-int(scurvy.health_floor))
					damage=above if above>0 else (1 if coverage<1000 and (day-int(active.started_day))%slow==0 else 0)
			else:
				damage*=int(active.get("severity",1))
			affect(member,-damage,day,definition.name.to_lower())
			if not is_active(member):
				break
			if not definition.get("needs_fresh_food",false):active.elapsed+=rate
			if active.elapsed >= definition.recovery_days:
				member.conditions.erase(active)
				_record(member, day, "%s recovered from %s." % [member.name, definition.name.to_lower()])
				if definition.get("immunizing", false):
					if not member.has("immune"):
						member.immune = []
					member.immune.append(active.id)
	_mature_exposures(day)
	_wound_complications(day,rations,resting,rest_by_member)
	_spread(day, rations)
	_deficiency(day, rations, days_without_fresh,vitamin_coverage)
	# One provisional party-level onset roll per day; a separate seeded stream
	# keeps watching the party and opening dialogs from changing any outcomes.
	if living_count() == 0 or rng.randf() >= clampf(daily_onset_chance * risk_multiplier, 0, 1):
		return
	var candidates: Array[int] = []
	var options: Dictionary={}
	for member in members:
		var eligible: Array[String]=[]
		for id in automatic_conditions(year):
			if susceptible(member,id) and onset_weight(id,month,region)>0:eligible.append(id)
		if not eligible.is_empty():candidates.append(int(member.id));options[int(member.id)]=eligible
	if not candidates.is_empty():
		var person: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		var picked := _pick_condition(options[person], month, region)
		if not picked.is_empty():
			begin_condition(person, picked, day, roll_severity(rations))

func description(member_id: int) -> String:
	var member: Dictionary = members[member_id]
	if member.get("away",false):return member.name.to_upper()+"\n\nAWAY HUNTING\nLast known condition: "+condition_label(int(member.health))+"\nTheir slot, supplies and animals remain reserved. Check field trips or the map."
	if member.get("guarding",false):return member.name.to_upper()+"\n\nGUARDING THE WAGON\nLast known condition: "+condition_label(int(member.health))+"\nReturn to the map marker to learn what happened.\nTheir party slot remains reserved."
	if member.get("departed",false):
		return "%s\n\nLEFT THE PARTY · DAY %d\nLocation: %s\n\n%s" % [member.name.to_upper(),member.departure_day,member.departure_place,"\n".join(member.history)]
	var lines: Array[String] = [member.name.to_upper()]
	if not is_active(member):
		lines.append("DIED · DAY %d\nCause: %s" % [member.death_day, member.cause])
	else:
		lines.append("Condition: " + condition_label(member.health))
		var debt: float=int(member.get("vitamin_debt_milli",int(member.get("vitamin_days",days_without_fresh))*1000))/1000.0
		var capacity: float=float(scurvy.get("onset_days",45))
		lines.append("Vitamin reserve: %s. Regular fruit and greens help maintain it." % ("DEPLETED" if debt>=capacity else ("LOW" if debt>=capacity*0.75 else ("ADEQUATE" if debt>capacity*0.25 else "WELL SUPPLIED"))))
		if member.conditions.is_empty():
			lines.append("No current illness or injury.")
		for active in member.conditions:
			lines.append("%s · %s · since day %d%s" % [conditions[active.id].name, ["Mild", "Bad", "Serious"][int(active.get("severity", 1)) - 1], active.started_day, " · mends only with vitamin-C foods" if conditions[active.id].get("needs_fresh_food", false) else ""])
			if active.id==wound_infection.get("source",""):
				lines.append("Open wound: infection remains possible until it heals. Nursing cleans and bandages wounds; rest and care reduce the risk.")
			if active.id==wound_infection.get("condition",""):
				lines.append("An infected wound can worsen after the original injury heals. Care and rest help, but recovery is not guaranteed.")
			if conditions[active.id].get("calendar_course",false):lines.append("Rest and nursing support health; this illness still runs its course.")
			if active.id=="smallpox":lines.append("Close-contact spread is possible as the rash develops. Survivors become immune.")
			if conditions[active.id].get("needs_fresh_food",false):
				var progress: float=int(active.elapsed)+int(active.get("nutrition_progress_milli",0))/1000.0
				lines.append("Treatment progress: %.1f / %d. Fruit and greens support recovery; rest helps." % [progress,int(conditions[active.id].recovery_days)])
				if active.has("treatment_coverage_milli"):lines.append("Last meal's vitamin-C coverage: %d%%. Partial servings still help." % roundi(int(active.treatment_coverage_milli)/10.0))
	lines.append("PERSONAL HISTORY")
	lines.append("\n".join(member.history) if not member.history.is_empty() else "No health events recorded.")
	return "\n\n".join(lines)


# Optional fixed-point state preserves existing saves and exact JSON round trips.
static func valid_treatment(condition: Variant,day: int=-1) -> bool:
	if not condition is Dictionary:return false
	if condition.has("dressed_until_day"):
		var value: Variant=condition.dressed_until_day
		if condition.get("id")!="wound" or not (value is int or value is float) or not is_finite(value) or value!=floor(value) or value<0 or value>1000000:return false
		if day>=0 and (value<int(condition.get("started_day",0)) or value>day+1):return false
	for key in ["nutrition_progress_milli","nutrition_damage_milli","treatment_coverage_milli"]:
		if not condition.has(key):continue
		var value: Variant=condition[key]
		if condition.get("id")!="scurvy" or not (value is int or value is float) or not is_finite(value) or value!=floor(value) or value<0 or value>(1000 if key=="treatment_coverage_milli" else 999):return false
	return true
