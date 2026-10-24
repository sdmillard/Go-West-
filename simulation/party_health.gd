extends RefCounted
## Per-person state, independent of UI. All numbers are provisional gameplay tuning.
var members: Array[Dictionary] = []
var conditions: Dictionary = {}
var daily_onset_chance := 0.0
var scurvy: Dictionary = {}
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
	daily_onset_chance = float(chance)
	scurvy = deficiency.duplicate(true)
	return true

func _valid_deficiency(rules: Dictionary) -> bool:
	if not conditions.has(rules.get("condition")) or not conditions[rules.condition].get("deficiency", false):
		return false
	if not _number(rules.get("onset_days")) or rules.onset_days < 1 or rules.onset_days != floor(rules.onset_days):
		return false
	for key in ["base_chance", "chance_per_15_days", "max_chance"]:
		if not _number(rules.get(key)) or rules[key] < 0 or rules[key] > 1:
			return false
	return true

func _valid_spread(entry: Dictionary) -> bool:
	for key in ["weight", "region_default"]:
		if entry.has(key) and (not _number(entry[key]) or entry[key] < 0):
			return false
	if entry.has("spread_chance") and (not _number(entry.spread_chance) or entry.spread_chance < 0 or entry.spread_chance > 1):
		return false
	for key in ["immunizing", "deficiency", "needs_fresh_food"]:
		if entry.has(key) and not entry[key] is bool:
			return false
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
	return member.alive and not member.get("departed",false) and not member.get("guarding",false)

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
	if condition_id in member.get("immune", []):
		return false
	member.conditions.append({"id": condition_id, "started_day": day, "elapsed": 0, "severity": clampi(severity, 1, 3)})
	_record(member, day, ("%s has %s." % [member.name, definition.name.to_lower()]) if source.is_empty() else ("%s caught %s from %s." % [member.name, definition.name.to_lower(), source]))
	return true

func roll_severity(rations: int) -> int:
	# BASIC 6300–6360 conditional severity branching, using our 0–2 ration index.
	if rng.randf() * 100 < 10 + 35 * clampi(rations, 0, 2):
		return 1
	return 3 if rng.randf() * 100 >= 100 - 40.0 / pow(4, clampi(rations, 0, 2)) else 2

func automatic_conditions(year: int) -> Array[String]:
	var candidates: Array[String] = []
	for id in conditions:
		if conditions[id].kind == "illness" and not conditions[id].get("deficiency", false) and year >= int(conditions[id].get("from_year", 0)):
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

# Contagious illness can pass to anyone in the party who is currently well and
# not immune. People who fell ill today do not pass it on until tomorrow.
# Daily chance that each well traveler develops scurvy after a long run of
# meals without vitamin-C foods. It rises every 15 days past onset_days.
func scurvy_chance(days_without_fresh: int) -> float:
	if scurvy.is_empty() or days_without_fresh <= int(scurvy.onset_days):
		return 0.0
	var steps := floori(float(days_without_fresh - int(scurvy.onset_days)) / 15.0)
	return minf(float(scurvy.max_chance), float(scurvy.base_chance) + steps * float(scurvy.chance_per_15_days))

func _deficiency(day: int, rations: int, days_without_fresh: int) -> void:
	for member in members:
		var chance := scurvy_chance(int(member.get("vitamin_days",days_without_fresh)))
		if is_active(member) and member.conditions.is_empty() and chance>0 and rng.randf() < chance:
			begin_condition(int(member.id), scurvy.condition, day, roll_severity(rations))

func _spread(day: int, rations: int) -> void:
	var sources: Array = []
	for member in members:
		if is_active(member):
			for active in member.conditions:
				if float(conditions[active.id].get("spread_chance", 0.0)) > 0.0:
					sources.append([member.name, active.id])
	for source in sources:
		var chance := float(conditions[source[1]].spread_chance)
		for member in members:
			if is_active(member) and member.conditions.is_empty() and source[1] not in member.get("immune", []) and rng.randf() < chance:
				begin_condition(int(member.id), source[1], day, roll_severity(rations), source[0])

func tick(day: int, resting: bool, risk_multiplier: float = 1.0, rations: int = 2, year: int = 1848, month: int = 0, region: String = "", days_without_fresh: int = 0, rest_by_member: Dictionary = {}) -> void:
	for member in members:
		if not is_active(member):
			continue
		for active in member.conditions.duplicate():
			var definition: Dictionary = conditions[active.id]
			var nourished: bool=int(member.get("vitamin_days",days_without_fresh))==0
			var damage: int=int(definition.get("fed_daily_damage",definition.daily_damage)) if nourished else int(definition.daily_damage)
			affect(member,-damage*int(active.get("severity",1)),day,definition.name.to_lower())
			if not is_active(member):
				break
			# Deficiency recovery still needs sustained vitamin-C meals; feeding stops its deterioration first.
			if int(member.get("vitamin_days",days_without_fresh)) == 0 or not definition.get("needs_fresh_food", false):
				active.elapsed += 2 if rest_by_member.get(int(member.id),resting) else 1
			if active.elapsed >= definition.recovery_days:
				member.conditions.erase(active)
				_record(member, day, "%s recovered from %s." % [member.name, definition.name.to_lower()])
				if definition.get("immunizing", false):
					if not member.has("immune"):
						member.immune = []
					member.immune.append(active.id)
	_spread(day, rations)
	_deficiency(day, rations, days_without_fresh)
	# One provisional party-level onset roll per day; a separate seeded stream
	# keeps watching the party and opening dialogs from changing any outcomes.
	if living_count() == 0 or rng.randf() >= clampf(daily_onset_chance * risk_multiplier, 0, 1):
		return
	var candidates: Array[int] = []
	for member in members:
		if is_active(member) and member.conditions.is_empty():
			candidates.append(int(member.id))
	var available: Array[String] = automatic_conditions(year)
	if not candidates.is_empty() and not available.is_empty():
		var person: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		var picked := _pick_condition(available, month, region)
		if not picked.is_empty():
			begin_condition(person, picked, day, roll_severity(rations))

func description(member_id: int) -> String:
	var member: Dictionary = members[member_id]
	if member.get("guarding",false):return member.name.to_upper()+"\n\nGUARDING THE WAGON\nLast known condition: "+condition_label(int(member.health))+"\nReturn to the map marker to learn what happened.\nTheir party slot remains reserved."
	if member.get("departed",false):
		return "%s\n\nLEFT THE PARTY · DAY %d\nLocation: %s\n\n%s" % [member.name.to_upper(),member.departure_day,member.departure_place,"\n".join(member.history)]
	var lines: Array[String] = [member.name.to_upper()]
	if not is_active(member):
		lines.append("DIED · DAY %d\nCause: %s" % [member.death_day, member.cause])
	else:
		lines.append("Condition: " + condition_label(member.health))
		if member.conditions.is_empty():
			lines.append("No current illness or injury.")
		for active in member.conditions:
			lines.append("%s · %s · since day %d%s" % [conditions[active.id].name, ["Mild", "Bad", "Serious"][int(active.get("severity", 1)) - 1], active.started_day, " · mends only with vitamin-C foods" if conditions[active.id].get("needs_fresh_food", false) else ""])
	lines.append("PERSONAL HISTORY")
	lines.append("\n".join(member.history) if not member.history.is_empty() else "No health events recorded.")
	return "\n\n".join(lines)

